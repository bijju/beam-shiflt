extends TestCase
## Direct unit tests for the procedural pipeline's rejection gates and plan data,
## using crafted inputs instead of waiting for the generator to happen upon them.

const D := GridTypes.Direction
const M := GridTypes.MirrorOrientation


func _lv(w: int, h: int, tiles: Array[TilePlacement]) -> LevelData:
	var lv := LevelData.new()
	lv.grid_width = w
	lv.grid_height = h
	lv.tiles = tiles
	return lv


func _profile() -> Dictionary:
	return {"tile_budget": 20, "optimal_moves_range": Vector2i(1, 4)}


func test_generator_verify_rejections() -> void:
	var gen := ProceduralLevelGenerator
	var ok_level := _lv(5, 7, [
		TilePlacement.make_emitter(Vector2i(0, 3), D.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), M.SLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
	] as Array[TilePlacement])
	var good_solution := {Vector2i(2, 3): M.SLASH}
	# start state is already the solution -> trivial
	var r := gen._verify(ok_level, _profile(), Vector2i(5, 7), good_solution)
	ok(not r["ok"] and r["reason"].contains("already solved"))
	# scramble it: start BACKSLASH, intended SLASH
	var scrambled := _lv(5, 7, [
		TilePlacement.make_emitter(Vector2i(0, 3), D.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), M.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
	] as Array[TilePlacement])
	var accepted := gen._verify(scrambled, _profile(), Vector2i(5, 7), good_solution)
	ok(accepted["ok"], str(accepted))
	eq(accepted["move_count"], 1)
	ok(not gen._verify(scrambled, _profile(), Vector2i(9, 7), good_solution)["ok"], "too many columns")
	var wide := gen._verify(scrambled, _profile(), Vector2i(8, 12), good_solution)
	ok(not wide["ok"] and wide["reason"].contains("comfortable"))
	var small_budget := _profile()
	small_budget["tile_budget"] = 1
	ok(gen._verify(scrambled, small_budget, Vector2i(5, 7), good_solution)["reason"].contains("budget"))
	var wrong_solution := {Vector2i(2, 3): M.BACKSLASH}
	ok(gen._verify(scrambled, _profile(), Vector2i(5, 7), wrong_solution)["reason"].contains("did not simulate"))
	var tight := _profile()
	tight["optimal_moves_range"] = Vector2i(0, 0)
	ok(gen._verify(scrambled, tight, Vector2i(5, 7), good_solution)["reason"].contains("out of range"))
	var oob := _lv(2, 2, [TilePlacement.make_emitter(Vector2i(5, 5), D.RIGHT)] as Array[TilePlacement])
	ok(gen._structural_check(oob).contains("out of bounds"))
	var dup := _lv(3, 3, [TilePlacement.make_blocker(Vector2i(1, 1)), TilePlacement.make_blocker(Vector2i(1, 1))] as Array[TilePlacement])
	ok(gen._structural_check(dup).contains("duplicate"))
	eq(gen._structural_check(scrambled), "")
	ok(not gen._verify(oob, _profile(), Vector2i(5, 7), {})["ok"])


func test_plan_v3_data() -> void:
	var p := ProceduralPlanV3.new()
	p.archetype = "X"
	p.add_stage("a", "trunk", false, 2)
	p.add_stage("b", "gate", true, 3, 1)
	p.add_stage("c", "receiver", true, 1)
	p.add_edge("a", "b", "unlocks")
	p.add_edge("b", "c", "unlocks")
	p.add_edge("a", "c", "feeds")
	eq(p.stage("b")["turns"], 3)
	eq(p.stage("zzz"), {})
	eq(p.total_turn_budget(), 6)
	eq(p.load_bearing_stage_ids(), ["b", "c"])
	eq(p.edge_count("unlocks"), 2)
	eq(p.edge_count("none"), 0)
	ok(p.summary().begins_with("X"))
	ok(p.summary().contains("gate"))


func _good_metrics(req: Dictionary = {}) -> Dictionary:
	var moves: int = maxi(int(req.get("min_optimal_moves", 10)), 1)
	return {
		"solved": true, "optimal_moves": moves, "intended_move_count": moves, "solver_states": -1,
		"meaningful_dependency_count": 99, "dependency_depth": 99, "mechanic_interaction_count": 999,
		"distinct_mechanic_kinds": 99, "padding_moves": 0, "padding_positions": [], "is_single_route": false,
		"required_rotatables": moves, "plain_route_moves": 0,
	}


func test_triviality_reasons() -> void:
	var req := ProceduralDifficultyContract.get_difficulty_requirements(1500)
	var base := ProceduralTriviality.evaluate(_good_metrics(req), req)
	ok(base["reasons"].is_empty(), str(base))
	var m := _good_metrics(req)
	m["solved"] = false
	ok(ProceduralTriviality.evaluate(m, req)["reasons"].has("NOT_SOLVED_BY_INTENDED_SOLUTION"))
	var cases := {
		ProceduralTriviality.TOO_FEW_MOVES: {"optimal_moves": 0},
		ProceduralTriviality.TOO_FEW_DEPENDENCIES: {"meaningful_dependency_count": 0},
		ProceduralTriviality.TOO_SHALLOW: {"dependency_depth": 0},
		ProceduralTriviality.MECHANICS_NOT_INTERACTING: {"mechanic_interaction_count": 0},
		ProceduralTriviality.LATE_GAME_SINGLE_MECHANIC: {"distinct_mechanic_kinds": 0},
		ProceduralTriviality.PADDING: {"padding_moves": 3, "padding_positions": [Vector2i(1, 1)]},
		ProceduralTriviality.SINGLE_OBVIOUS_ROUTE: {"is_single_route": true},
		ProceduralTriviality.INDEPENDENT_ROTATIONS: {"plain_route_moves": 10},
		ProceduralTriviality.SHORTCUT_SOLUTION: {"optimal_moves": 8, "solver_states": 100},
	}
	var forced := req.duplicate()
	forced["require_non_padding"] = true
	forced["reject_single_route"] = true
	forced["max_independent_move_fraction"] = 0.1
	for reason in cases:
		var mm := _good_metrics(forced)
		for k in cases[reason]:
			mm[k] = cases[reason][k]
		var verdict := ProceduralTriviality.evaluate(mm, forced)
		ok(verdict["reasons"].has(reason), "%s -> %s" % [reason, str(verdict["reasons"])])
		ok(ProceduralGeneratorV3._explain(reason, mm, forced) is String)
	var over := _good_metrics(forced)
	over["optimal_moves"] = 999
	ok(ProceduralTriviality.evaluate(over, forced)["notes"].has(ProceduralTriviality.OVER_MOVE_CAP))
	eq(ProceduralGeneratorV3._explain("UNKNOWN", over, forced), "")


func test_generator_v3_requirement_tables() -> void:
	ok(ProceduralGeneratorV3.phase2a_requirements() is Dictionary)
	for n in range(1, ProceduralGeneratorV3.PROTOTYPE_COUNT + 1):
		var arch := ProceduralPlannerV3.archetype_for_index(n)
		ok(ProceduralGeneratorV3.requirements_for(arch) is Dictionary)
	ok(ProceduralGeneratorV3.requirements_for("no_such_archetype") is Dictionary)
	var failed: Array = []
	# a prototype board that cannot satisfy an impossible requirement set is rejected with reasons
	var level := LevelManager.get_campaign_level(1)
	var board := ProceduralBoardV3.new(5, 8)
	var plan := ProceduralPlanV3.new()
	var req := ProceduralGeneratorV3.phase2a_requirements().duplicate()
	req["min_optimal_moves"] = 99
	var result := ProceduralGeneratorV3._check(level, board, plan, req)
	ok(result.has("ok"), str(failed))
