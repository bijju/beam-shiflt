class_name ProceduralGeneratorV3
extends RefCounted
## Generator V3 - DEPENDENCY FIRST (Difficulty System Phase 2A prototype,
## D94). Pipeline (each stage only consumes the previous one's output):
##
##   difficulty requirements -> ProceduralPlannerV3 (logical plan: which
##   mechanics are load-bearing, what enables what) -> ProceduralLayoutV3
##   (physical macro-layout on a portrait board) -> ProceduralBoardV3 beam
##   routing (mirror orientations computed from GridTypes.reflect) -> start
##   state (opposite of solved for every required move) -> gates.
##
## Difficulty comes from the plan, not from retries: a candidate is rebuilt
## only when a macro-layout cannot be placed (geometry) or a gate below
## rejects it; on the current archetypes attempt 0 is expected to pass.
##
## Runtime-safe: uses only LaserSystem (via ProceduralComplexity) - never
## LevelSolver/LevelValidator (dev-only, CLAUDE.md rule 9). Shortcut
## protection at runtime is therefore structural (disjoint arms on shared
## tiles, capped channels, colored targets, plus the ablation-based padding
## check); the exhaustive optimal-vs-intended comparison lives in the
## dev-only scripts/tools/v3_prototype_audit.gd and is run on the pinned
## prototype seeds.
##
## TEMPORARY PHASE 2A EXCEPTION: the acceptance profile targets ~8-12
## meaningful moves (not the contract's late-game 20-26) and applies to
## every level number it is asked for. V3 is NOT the default generator; it
## is reachable only by an explicit generator_version == 3 (saves) or the
## QA prototype selector. See PROCEDURAL_GENERATION.md section 18.

const GENERATOR_VERSION_V3 := 3
const MAX_ATTEMPTS := 12
const PROTOTYPE_COUNT := 6

## Phase 2A hard-prototype acceptance profile, in the same shape as
## ProceduralDifficultyContract's requirements so ProceduralTriviality can
## evaluate it unchanged.
static func phase2a_requirements() -> Dictionary:
	return {
		"min_optimal_moves": 8, "max_optimal_moves": 12,
		"min_meaningful_dependencies": 3, "max_meaningful_dependencies": -1,
		"min_dependency_depth": 4, "min_mechanic_interactions": 2,
		"min_distinct_mechanics": 3, "max_decoys": 2,
		"max_independent_move_fraction": 0.3,
		"reject_single_route": true, "require_non_padding": true,
		"min_meaningful_move_fraction": 0.7, "min_required_branches": 2,
	}


## Phase 2A.1: D/E/F are refined toward reasoning depth (not raw move count), so
## they carry their own stricter profile on top of the Phase 2A one. A/B/C keep
## the original profile untouched. `min_shared_resources` and
## `min_prerequisite_chains` (switch->gate + receiver->remote links) are extra
## keys only this function adds.
static func requirements_for(archetype: String) -> Dictionary:
	var r := phase2a_requirements()
	match archetype:
		"shared_one_way": # D - HARD
			r.merge({
				"min_optimal_moves": 8, "max_optimal_moves": 11,
				"min_meaningful_dependencies": 4, "min_dependency_depth": 5,
				"min_mechanic_interactions": 4, "min_required_branches": 2,
				"max_independent_move_fraction": 0.2, "min_meaningful_move_fraction": 0.8,
				"min_shared_resources": 1,
			}, true)
		"splitter_convergence": # E - HARD+
			r.merge({
				"min_optimal_moves": 10, "max_optimal_moves": 13,
				"min_meaningful_dependencies": 5, "min_dependency_depth": 7,
				"min_mechanic_interactions": 6, "min_required_branches": 3,
				"max_independent_move_fraction": 0.2, "min_meaningful_move_fraction": 0.8,
				"min_prerequisite_chains": 2,
			}, true)
		"mixed_chain": # F - hardest of the six
			r.merge({
				"min_optimal_moves": 10, "max_optimal_moves": 14,
				"min_meaningful_dependencies": 6, "min_dependency_depth": 9,
				"min_mechanic_interactions": 8, "min_required_branches": 3,
				"max_independent_move_fraction": 0.15, "min_meaningful_move_fraction": 0.85,
				"min_shared_resources": 1, "min_prerequisite_chains": 2,
			}, true)
	return r


## Returns the same core keys as ProceduralLevelGenerator.generate() plus
## V3 extras: plan, metrics, verdict, diagnostics (rejection reasons).
static func generate(level_number: int) -> Dictionary:
	var archetype := ProceduralPlannerV3.archetype_for_index(level_number)
	var requirements := requirements_for(archetype)
	var rejections: Array = []

	for attempt in range(MAX_ATTEMPTS):
		var rng := ProceduralSeed.rng_for_attempt(level_number, GENERATOR_VERSION_V3, attempt)
		var plan := ProceduralPlannerV3.plan(archetype, rng)
		var board := ProceduralLayoutV3.build(plan, rng)
		if board.failure != "":
			rejections.append({"attempt": attempt, "stage": "layout", "reasons": [board.failure]})
			continue

		var min_moves: int = requirements["min_optimal_moves"]
		board.apply_keep_correct(rng, mini(int(plan.params.get("keep_correct", 0)), maxi(0, board.solution.size() - min_moves)))
		var level := board.to_level_data(board.w, board.h)
		level.level_id = level_number
		level.display_name = "Level %d" % level_number
		level.stage = "procedural"
		level.is_campaign_level = false

		var reasons := _check(level, board, plan, requirements)
		var metrics: Dictionary = reasons["metrics"]
		if not reasons["ok"]:
			rejections.append({"attempt": attempt, "stage": "gate", "reasons": reasons["reasons"], "metrics": metrics, "ascii": ProceduralBoardV3.ascii(level)})
			continue

		level.optimal_moves = maxi(int(metrics["intended_move_count"]), 1)
		return {
			"level_data": level,
			"seed": ProceduralSeed.for_attempt(level_number, GENERATOR_VERSION_V3, attempt),
			"attempt": attempt,
			"generator_version": GENERATOR_VERSION_V3,
			"template_id": archetype,
			"board_size": Vector2i(board.w, board.h),
			"fallback_used": false,
			"rejections": rejections,
			"solution_orientations": board.solution,
			"intended_moves": level.optimal_moves,
			"plan": plan,
			"metrics": metrics,
			"verdict": reasons["verdict"],
			"start_visibility": ProceduralComplexity.start_state_visibility(level, board.solution),
			"ascii": ProceduralBoardV3.ascii(level),
		}

	# Every attempt rejected (never expected for the shipped archetypes):
	# the player still gets a valid, self-verified puzzle from V2 rather
	# than a broken level, and the diagnostics say why V3 declined.
	var fallback := ProceduralLevelGenerator.generate(level_number, 2)
	fallback["fallback_used"] = true
	fallback["rejections"] = rejections
	fallback["v3_declined"] = true
	return fallback


## Technical validity + the complexity/triviality gates. Returns
## {ok, reasons: Array[String], metrics, verdict}.
static func _check(level: LevelData, board: ProceduralBoardV3, plan: ProceduralPlanV3, req: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	var empty := {"ok": false, "reasons": reasons, "metrics": {}, "verdict": {}}

	if board.w > GridManager.MAX_COLUMNS:
		reasons.append("columns %d exceed MAX_COLUMNS" % board.w)
		return empty
	var comfort: Dictionary = GridManager.is_board_profile_comfortable(board.w, board.h, ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE)
	if not comfort["comfortable"]:
		reasons.append("board not comfortable: %s" % comfort["reason"])
		return empty

	var authored: Dictionary = level.get_initial_tile_orientations()
	if LaserSystem.simulate_until_stable(level, authored)["solved"]:
		reasons.append("start state is already solved")
		return empty
	var solved: Dictionary = authored.duplicate()
	for pos in board.solution:
		solved[pos] = board.solution[pos]
	var solved_result: Dictionary = LaserSystem.simulate_until_stable(level, solved)
	if not solved_result["solved"]:
		reasons.append("intended solution does not solve the puzzle")
		return empty
	if solved_result["looped"]:
		reasons.append("intended solution loops")
		return empty

	var metrics := ProceduralComplexity.analyze(level, board.solution)
	var verdict := ProceduralTriviality.evaluate(metrics, req)
	empty["metrics"] = metrics
	empty["verdict"] = verdict

	# Promised mechanics must be load-bearing on THIS board.
	for id in plan.load_bearing_stage_ids():
		var positions: Array = board.node_tiles.get(id, [])
		var found := false
		for unit in metrics["load_bearing_units"]:
			for p in unit["positions"]:
				if positions.has(p):
					found = true
		if not found:
			reasons.append("plan stage '%s' (%s) is not load-bearing" % [id, plan.stage(id)["role"]])

	for r in verdict["reasons"]:
		reasons.append("%s (%s)" % [r, _explain(r, metrics, req)])

	if ProceduralTriviality.OVER_MOVE_CAP in verdict["notes"]:
		reasons.append("moves %d exceed the Phase 2A cap %d" % [metrics["optimal_moves"], req["max_optimal_moves"]])

	var required: int = metrics["required_rotatables"]
	var meaningful_fraction := 1.0 if required == 0 else float(metrics["dependent_moves"]) / float(required)
	if meaningful_fraction < req["min_meaningful_move_fraction"]:
		reasons.append("only %d%% of required moves are meaningful" % int(meaningful_fraction * 100.0))
	if metrics["required_branches"] < req["min_required_branches"]:
		reasons.append("only %d beam branch(es)" % metrics["required_branches"])
	if metrics["shared_resource_count"] < int(req.get("min_shared_resources", 0)):
		reasons.append("only %d shared resource(s)" % metrics["shared_resource_count"])
	if metrics["prerequisite_chains"] < int(req.get("min_prerequisite_chains", 0)):
		reasons.append("only %d prerequisite chain(s)" % metrics["prerequisite_chains"])

	var result := {"ok": reasons.is_empty(), "reasons": reasons, "metrics": metrics, "verdict": verdict}
	return result


static func _explain(reason: String, m: Dictionary, req: Dictionary) -> String:
	match reason:
		ProceduralTriviality.TOO_FEW_MOVES:
			return "moves %d < required %d" % [m["optimal_moves"], req["min_optimal_moves"]]
		ProceduralTriviality.TOO_FEW_DEPENDENCIES:
			return "dependencies %d < required %d" % [m["meaningful_dependency_count"], req["min_meaningful_dependencies"]]
		ProceduralTriviality.TOO_SHALLOW:
			return "dependency depth %d < required %d" % [m["dependency_depth"], req["min_dependency_depth"]]
		ProceduralTriviality.MECHANICS_NOT_INTERACTING:
			return "%d mechanic interaction(s) < required %d" % [m["mechanic_interaction_count"], req["min_mechanic_interactions"]]
		ProceduralTriviality.LATE_GAME_SINGLE_MECHANIC:
			return "%d load-bearing mechanic kind(s) < required %d" % [m["distinct_mechanic_kinds"], req["min_distinct_mechanics"]]
		ProceduralTriviality.INDEPENDENT_ROTATIONS:
			return "%d of %d required moves are plain" % [m["plain_route_moves"], m["required_rotatables"]]
		ProceduralTriviality.PADDING:
			return "%d padding move(s) at %s" % [m["padding_moves"], m["padding_positions"]]
	return ""
