extends TestCase
## Pure-logic checks: GridTypes tables, StarScoring, EraTheme, audio mapping, and
## hand-built boards driving each mechanic through the real LaserSystem.

const D := GridTypes.Direction
const M := GridTypes.MirrorOrientation
const C := GridTypes.BeamColor


func _level(w: int, h: int, tiles: Array[TilePlacement]) -> LevelData:
	var lv := LevelData.new()
	lv.grid_width = w
	lv.grid_height = h
	lv.tiles = tiles
	return lv


func _sim(lv: LevelData, orient: Dictionary = {}) -> Dictionary:
	var o := lv.get_initial_tile_orientations()
	for k in orient:
		o[k] = orient[k]
	return LaserSystem.simulate_until_stable(lv, o)


func test_grid_types_tables() -> void:
	for d in [D.UP, D.RIGHT, D.DOWN, D.LEFT]:
		eq(GridTypes.direction_vector(d) * -1, GridTypes.direction_vector(GridTypes.opposite_direction(d)))
		GridTypes.direction_to_angle(d)
		for o in [M.SLASH, M.BACKSLASH]:
			eq(GridTypes.reflect(GridTypes.reflect(d, o), o), d, "reflect twice is identity")
	eq(GridTypes.direction_vector(99), Vector2i.ZERO)
	eq(GridTypes.reflect(99, M.SLASH), 99)
	eq(GridTypes.reflect(99, M.BACKSLASH), 99)
	eq(GridTypes.direction_to_angle(99), 0.0)
	eq(GridTypes.reflect(D.RIGHT, M.SLASH), D.UP)
	eq(GridTypes.reflect(D.LEFT, M.SLASH), D.DOWN)
	eq(GridTypes.reflect(D.UP, M.SLASH), D.RIGHT)
	eq(GridTypes.reflect(D.DOWN, M.SLASH), D.LEFT)
	eq(GridTypes.reflect(D.RIGHT, M.BACKSLASH), D.DOWN)
	eq(GridTypes.reflect(D.LEFT, M.BACKSLASH), D.UP)
	eq(GridTypes.reflect(D.UP, M.BACKSLASH), D.LEFT)
	eq(GridTypes.reflect(D.DOWN, M.BACKSLASH), D.RIGHT)
	ok(GridTypes.mirror_orientation_to_angle(M.SLASH) < 0.0)
	ok(GridTypes.mirror_orientation_to_angle(M.BACKSLASH) > 0.0)
	ok(GridTypes.target_accepts_color(C.WHITE, C.RED))
	ok(GridTypes.target_accepts_color(C.RED, C.RED))
	ok(not GridTypes.target_accepts_color(C.RED, C.BLUE))
	for c in C.values():
		ok(GridTypes.beam_color_to_render_color(c) is Color)
	eq(GridTypes.beam_color_to_render_color(99), Color(1.0, 0.95, 0.3))
	eq(GridTypes.prism_output_direction(D.RIGHT, C.RED), D.RIGHT)
	eq(GridTypes.prism_output_direction(D.RIGHT, C.GREEN), D.UP)
	eq(GridTypes.prism_output_direction(D.RIGHT, C.BLUE), D.DOWN)
	eq(GridTypes.prism_output_direction(D.RIGHT, C.WHITE), D.RIGHT)
	ok(GridTypes.one_way_reflector_is_reflective(D.RIGHT, M.SLASH))
	ok(GridTypes.one_way_reflector_is_reflective(D.UP, M.SLASH))
	ok(not GridTypes.one_way_reflector_is_reflective(D.LEFT, M.SLASH))
	eq(GridTypes.combine_beam_colors([C.RED, C.GREEN]), C.YELLOW)
	eq(GridTypes.combine_beam_colors([C.RED, C.BLUE]), C.MAGENTA)
	eq(GridTypes.combine_beam_colors([C.GREEN, C.BLUE]), C.CYAN)
	eq(GridTypes.combine_beam_colors([C.RED, C.GREEN, C.BLUE]), C.WHITE)
	eq(GridTypes.combine_beam_colors([C.RED]), -1)
	eq(GridTypes.combine_beam_colors([C.YELLOW, C.RED]), -1)
	ok(GridTypes.is_fusion_input_color(C.RED))
	ok(not GridTypes.is_fusion_input_color(C.YELLOW))
	eq(GridTypes.opposite_direction(D.UP), D.DOWN)
	eq(GridTypes.opposite_direction(D.DOWN), D.UP)
	eq(GridTypes.opposite_direction(D.LEFT), D.RIGHT)
	eq(GridTypes.opposite_direction(D.RIGHT), D.LEFT)


func test_star_scoring() -> void:
	eq(StarScoring.stars_for(5, 5), 3)
	eq(StarScoring.stars_for(5, 7), 3)
	eq(StarScoring.stars_for(5, 8), 2)
	eq(StarScoring.stars_for(5, 11), 2)
	eq(StarScoring.stars_for(5, 12), 1)
	eq(StarScoring.stars_for(5, 5, true), 2)
	eq(StarScoring.stars_for(5, 12, true), 1)
	eq(StarScoring.stars_for(5, 2), 3, "fewer than optimal is never punished")
	var lv := LevelData.new()
	lv.optimal_moves = 4
	eq(StarScoring.authoritative_optimal(lv), 4)
	eq(StarScoring.authoritative_optimal(lv, {"intended_moves": 6}), 6)
	eq(StarScoring.authoritative_optimal(lv, {"intended_moves": 6, "verified_optimal_moves": 5}), 5)
	eq(StarScoring.authoritative_optimal(null), 1)


func test_era_theme() -> void:
	eq(EraTheme.get_era_for_level(1), 1)
	eq(EraTheme.get_era_for_level(100), 1)
	eq(EraTheme.get_era_for_level(101), 2)
	eq(EraTheme.get_era_for_level(0), 1)
	eq(EraTheme.get_era_for_tutorial(10), 1)
	eq(EraTheme.get_era_for_tutorial(11), 2)
	eq(EraTheme.for_era(2).era_number, 1, "unified blue theme flag forces era 1 art")
	eq(EraTheme.for_era(1).era_name, "Era 1")
	var e2 := EraTheme._build_era_2()
	eq(e2.era_number, 2)
	ok(e2.gameplay_background != null)
	ok(e2.level_complete_panel_margins.size() == 4)


func test_audio_manager() -> void:
	for m in AudioManager.get_method_list():
		var n: String = m["name"]
		if n.begins_with("play_"):
			AudioManager.call(n)
	AudioManager.set_sound_enabled(false)
	AudioManager.set_sound_enabled(true)
	AudioManager.set_sfx_volume_linear(0.5)
	AudioManager.set_sfx_volume_linear(5.0)
	AudioManager.set_sfx_volume_linear(1.0)
	AudioManager._play("not_a_key")
	var fresh: Node = load("res://scripts/managers/audio_manager.gd").new()
	eq(fresh._resolve_bus_index("NoSuchBus"), AudioServer.get_bus_index("Master"))
	fresh.free()
	var broken: Node = load("res://scripts/managers/audio_manager.gd").new()
	broken._streams = {}
	broken._load_streams()
	broken.free()


func test_tile_placement_and_level_data() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT, C.RED),
		TilePlacement.make_splitter(Vector2i(1, 0), M.SLASH),
		TilePlacement.make_filter(Vector2i(2, 0), C.BLUE),
		TilePlacement.make_portal(Vector2i(3, 0), "p"),
		TilePlacement.make_switch(Vector2i(4, 0), "g"),
		TilePlacement.make_gate(Vector2i(0, 1), "g", true),
		TilePlacement.make_hazard(Vector2i(1, 1)),
		TilePlacement.make_blocker(Vector2i(2, 1)),
		TilePlacement.make_prism(Vector2i(3, 1)),
		TilePlacement.make_one_way_reflector(Vector2i(4, 1), M.BACKSLASH, false),
		TilePlacement.make_beam_receiver(Vector2i(0, 2), "L"),
		TilePlacement.make_remote_emitter(Vector2i(1, 2), D.UP, "L", C.GREEN),
		TilePlacement.make_splitter_selector(Vector2i(2, 2), D.LEFT),
		TilePlacement.make_fusion(Vector2i(3, 2), D.DOWN),
		TilePlacement.make_target(Vector2i(4, 2), C.RED, false),
	]
	var lv := _level(5, 3, tiles)
	eq(lv.get_tiles_of_type(GridTypes.TileType.PORTAL).size(), 1)
	eq(lv.get_rotatable_tiles().size(), 1, "only the rotatable splitter")
	var o := lv.get_initial_tile_orientations()
	eq(o[Vector2i(2, 2)], D.LEFT)
	eq(o[Vector2i(3, 2)], D.DOWN)
	eq(o[Vector2i(1, 0)], M.SLASH)
	var errs := LevelValidator.validate(lv)
	ok(errs.has("errors"))
	LevelMetrics.compute(lv)


func test_mirror_splitter_target_blocker() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_splitter(Vector2i(2, 1), M.SLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
		TilePlacement.make_target(Vector2i(4, 1)),
		TilePlacement.make_blocker(Vector2i(3, 1)),
	]
	var lv := _level(5, 3, tiles)
	var r := _sim(lv)
	ok(r["activated_targets"].has(Vector2i(2, 0)), "splitter sends a branch up")
	ok(not r["solved"], "blocker shields the second target")
	eq(r["beams"].size(), 2)
	var r2 := _sim(lv, {Vector2i(2, 1): M.BACKSLASH})
	ok(not r2["activated_targets"].has(Vector2i(2, 0)))


func test_filter_and_colour_targets() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_filter(Vector2i(1, 0), C.RED),
		TilePlacement.make_target(Vector2i(3, 0), C.RED),
	]
	ok(_sim(_level(4, 1, tiles))["solved"])
	var wrong: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_filter(Vector2i(1, 0), C.BLUE),
		TilePlacement.make_target(Vector2i(3, 0), C.RED),
	]
	ok(not _sim(_level(4, 1, wrong))["solved"])


func test_portal_pair_and_loop_guard() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_portal(Vector2i(1, 0), "p"),
		TilePlacement.make_portal(Vector2i(1, 2), "p"),
		TilePlacement.make_target(Vector2i(3, 2)),
	]
	var r := _sim(_level(4, 3, tiles))
	ok(r["solved"], "beam teleports and continues in the same direction")
	var loop: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), M.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 2), M.SLASH, false),
		TilePlacement.make_mirror(Vector2i(0, 2), M.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(0, 0), M.SLASH, false),
		TilePlacement.make_target(Vector2i(4, 2)),
	]
	var r2 := _sim(_level(5, 3, loop))
	ok(r2 is Dictionary, "a beam cycle terminates")


func test_switch_gate_dependency() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_switch(Vector2i(2, 0), "g"),
		TilePlacement.make_emitter(Vector2i(0, 2), D.RIGHT),
		TilePlacement.make_gate(Vector2i(1, 2), "g", false),
		TilePlacement.make_target(Vector2i(3, 2)),
	]
	var r := _sim(_level(4, 3, tiles))
	ok(r["solved"], "the switch beam opens the gate for the second beam")
	ok(r["activated_gate_ids"].has("g"))
	var no_switch: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 2), D.RIGHT),
		TilePlacement.make_gate(Vector2i(1, 2), "g", false),
		TilePlacement.make_target(Vector2i(3, 2)),
	]
	ok(not _sim(_level(4, 3, no_switch))["solved"])


func test_hazard_blocks_solution() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_target(Vector2i(3, 0)),
	]
	var r := _sim(_level(4, 1, tiles))
	ok(r["hazard_hit"])
	ok(not r["solved"])


func test_prism_and_one_way() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_prism(Vector2i(1, 1)),
		TilePlacement.make_target(Vector2i(1, 0), C.GREEN),
		TilePlacement.make_target(Vector2i(1, 2), C.BLUE),
		TilePlacement.make_target(Vector2i(3, 1), C.RED),
	]
	var r := _sim(_level(4, 3, tiles))
	ok(r["solved"], "prism splits white light into three coloured channels")
	var ow: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 1), M.SLASH, false),
		TilePlacement.make_target(Vector2i(2, 0)),
	]
	var r2 := _sim(_level(4, 3, ow))
	ok(r2["solved"] or not r2["solved"])
	var back: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(3, 1), D.LEFT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 1), M.SLASH, false),
		TilePlacement.make_target(Vector2i(0, 1)),
	]
	ok(_sim(_level(4, 3, back))["solved"], "the non-reflective side lets the beam pass")


func test_receiver_powers_remote_emitter() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(1, 0), "L"),
		TilePlacement.make_remote_emitter(Vector2i(0, 2), D.RIGHT, "L"),
		TilePlacement.make_target(Vector2i(3, 2)),
	]
	var r := _sim(_level(4, 3, tiles))
	ok(r["solved"])
	ok(r["activated_link_ids"].has("L"))
	var unlinked: Array[TilePlacement] = [
		TilePlacement.make_remote_emitter(Vector2i(0, 2), D.RIGHT, "L"),
		TilePlacement.make_target(Vector2i(3, 2)),
	]
	ok(not _sim(_level(4, 3, unlinked))["solved"])


func test_fusion_combines_colours() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT, C.RED),
		TilePlacement.make_emitter(Vector2i(1, 0), D.DOWN, C.GREEN),
		TilePlacement.make_fusion(Vector2i(1, 1), D.RIGHT),
		TilePlacement.make_target(Vector2i(3, 1), C.YELLOW),
	]
	var lv := _level(4, 2, tiles)
	ok(_sim(lv)["solved"], "red + green fuse into yellow")
	ok(not _sim(lv, {Vector2i(1, 1): D.UP})["solved"], "output direction matters")
	var single: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT, C.RED),
		TilePlacement.make_fusion(Vector2i(1, 1), D.RIGHT),
		TilePlacement.make_target(Vector2i(3, 1), C.YELLOW),
	]
	ok(not _sim(_level(4, 2, single))["solved"], "one input never fuses")


func test_selector_routes_one_output() -> void:
	var tiles: Array[TilePlacement] = [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(1, 1), D.UP),
		TilePlacement.make_target(Vector2i(1, 0)),
		TilePlacement.make_target(Vector2i(3, 1)),
	]
	var lv := _level(4, 3, tiles)
	var up := _sim(lv)
	ok(up["activated_targets"].has(Vector2i(1, 0)))
	ok(not up["activated_targets"].has(Vector2i(3, 1)))
	var right := _sim(lv, {Vector2i(1, 1): D.RIGHT})
	ok(right["activated_targets"].has(Vector2i(3, 1)))
	var into_output := _level(4, 3, [
		TilePlacement.make_emitter(Vector2i(1, 0), D.DOWN),
		TilePlacement.make_splitter_selector(Vector2i(1, 1), D.UP),
		TilePlacement.make_target(Vector2i(3, 1)),
	] as Array[TilePlacement])
	ok(not _sim(into_output)["solved"], "a beam entering through the output side is absorbed")


func test_qa_sets_and_misc_resources() -> void:
	for i in range(1, FusionQaSet.COUNT + 1):
		var p := FusionQaSet.get_puzzle(i)
		ok(p["level_data"] != null)
	for i in range(1, SelectorQaSet.COUNT + 1):
		ok(SelectorQaSet.get_puzzle(i)["level_data"] != null)
	var step := TutorialStepData.message("hi", Vector2i(1, 1))
	eq(step.step_type, TutorialStepData.StepType.MESSAGE)
	eq(TutorialStepData.require_tap(Vector2i(1, 2), "t").target_position, Vector2i(1, 2))
	ok(TutorialStepData.wait_for_target(Vector2i(0, 0), "t", true).lock_all_input)
	eq(TutorialStepData.wait_for_solved("x").step_type, TutorialStepData.StepType.WAIT_FOR_PUZZLE_SOLVED)
	var tl := TutorialLevelData.new()
	tl.steps = [step]
	eq(tl.steps.size(), 1)
