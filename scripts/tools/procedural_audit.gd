class_name ProceduralAudit
extends RefCounted
## Development-only audit/QA tooling for the procedural generator
## (ProceduralLevelGenerator, Levels 1-2000). Dev-only, excluded from the
## Android export like every other scripts/tools/** file - see CLAUDE.md
## rule 9. This is the ONE place LevelSolver/LevelValidator are ever
## called against generated content; ProceduralLevelGenerator itself
## never calls them (see that file's own doc comment for why). See
## PROCEDURAL_GENERATION.md "Dev-time audit tooling".

const REPRESENTATIVE_RANGES: Array[Vector2i] = [
	Vector2i(1, 20), Vector2i(45, 55), Vector2i(95, 105), Vector2i(245, 255),
	Vector2i(495, 505), Vector2i(745, 755), Vector2i(995, 1005), Vector2i(1245, 1255),
	Vector2i(1495, 1505), Vector2i(1745, 1755), Vector2i(1990, 2000),
]

const DETERMINISM_SAMPLE: Array[int] = [1, 10, 100, 250, 500, 750, 1000, 1250, 1500, 1750, 2000]


## Full solver/validator report for one level - dev diagnostic, not shown
## to players. `generator_version` lets the Procedural Difficulty Tuning
## pass audit V1 and V2 independently (see DECISIONS.md D92) - defaults to
## whatever ProceduralLevelGenerator.GENERATOR_VERSION currently is, same
## as every pre-existing call site's expectation.
static func generate_level_report(level_number: int, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var result := ProceduralLevelGenerator.generate(level_number, generator_version)
	var gen_us := Time.get_ticks_usec() - t0

	var level: LevelData = result["level_data"]
	var validation := LevelValidator.validate(level)
	var t1 := Time.get_ticks_usec()
	var solver_result := LevelSolver.analyze(level)
	var solve_us := Time.get_ticks_usec() - t1

	return {
		"level_number": level_number,
		"template_id": result["template_id"],
		"board_size": result["board_size"],
		"seed": result["seed"],
		"attempt": result["attempt"],
		"fallback_used": result["fallback_used"],
		"tile_count": level.tiles.size(),
		"rotatable_count": level.get_rotatable_tiles().size(),
		"generation_us": gen_us,
		"solve_us": solve_us,
		"validator_errors": validation["errors"],
		"validator_warnings": validation["warnings"],
		"solver_status": solver_result["status"],
		"optimal_moves": solver_result["optimal_moves"],
		"generator_optimal_moves": level.optimal_moves,
		"states_explored": solver_result["states_explored"],
		"shortest_solution_count": solver_result["shortest_solution_count"],
	}


## Audits every level in [start, end] inclusive. Always runs
## LevelValidator; runs the full LevelSolver BFS only when `run_solver` is
## true (the expensive part - see PROCEDURAL_GENERATION.md "Performance").
## Returns a summary Dictionary; prints one compact line per FAILED level
## only (a clean run prints nothing per-level, just the summary), so a
## 1-2000 sweep's output stays readable.
static func audit_range(start: int, end: int, run_solver: bool = true, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> Dictionary:
	var total := 0
	var fail_count := 0
	var fallback_count := 0
	var template_counts: Dictionary = {}
	var board_counts: Dictionary = {}
	var move_counts: Array = []
	var state_counts: Array = []
	var gen_times_us: Array = []
	var solve_times_us: Array = []
	var failures: Array = []

	for n in range(start, end + 1):
		total += 1
		var t0 := Time.get_ticks_usec()
		var result := ProceduralLevelGenerator.generate(n, generator_version)
		gen_times_us.append(Time.get_ticks_usec() - t0)

		var level: LevelData = result["level_data"]
		var template_id: String = result["template_id"]
		template_counts[template_id] = int(template_counts.get(template_id, 0)) + 1
		var board_key := "%dx%d" % [level.grid_width, level.grid_height]
		board_counts[board_key] = int(board_counts.get(board_key, 0)) + 1
		if result["fallback_used"]:
			fallback_count += 1

		if level.grid_width > GridManager.MAX_COLUMNS:
			fail_count += 1
			failures.append({"level": n, "reason": "columns exceed MAX_COLUMNS"})
			continue
		var comfort: Dictionary = GridManager.is_board_profile_comfortable(level.grid_width, level.grid_height, ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE)
		if not comfort["comfortable"]:
			fail_count += 1
			failures.append({"level": n, "reason": "not comfortable: %s" % comfort["reason"]})
			continue

		var validation := LevelValidator.validate(level)
		if not validation["errors"].is_empty():
			fail_count += 1
			failures.append({"level": n, "reason": "validator: %s" % str(validation["errors"])})
			continue

		if run_solver:
			var t1 := Time.get_ticks_usec()
			var solver_result := LevelSolver.analyze(level)
			solve_times_us.append(Time.get_ticks_usec() - t1)
			if solver_result["status"] != "SOLVABLE":
				fail_count += 1
				failures.append({"level": n, "reason": "solver: %s" % solver_result["status"]})
				continue
			move_counts.append(solver_result["optimal_moves"])
			state_counts.append(solver_result["states_explored"])
			if solver_result["shortest_solution_count"] > 1:
				failures.append({"level": n, "reason": "non-unique shortest solution (%d)" % solver_result["shortest_solution_count"], "non_fatal": true})

	for f in failures:
		if not f.get("non_fatal", false):
			print("AUDIT FAIL level %d: %s" % [f["level"], f["reason"]])

	return {
		"start": start, "end": end, "total": total, "fail_count": fail_count,
		"fallback_count": fallback_count, "template_counts": template_counts,
		"board_counts": board_counts, "move_counts": move_counts, "state_counts": state_counts,
		"gen_times_us": gen_times_us, "solve_times_us": solve_times_us, "failures": failures,
	}


## Regenerates `level_number` twice independently and compares the
## resulting LevelData tile-by-tile (type/position/orientation/all
## per-type fields that matter) plus seed/template/board - true only if
## byte-for-byte identical.
static func determinism_check(level_number: int, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> bool:
	var a := ProceduralLevelGenerator.generate(level_number, generator_version)
	var b := ProceduralLevelGenerator.generate(level_number, generator_version)
	if a["seed"] != b["seed"] or a["template_id"] != b["template_id"] or a["board_size"] != b["board_size"]:
		return false
	var la: LevelData = a["level_data"]
	var lb: LevelData = b["level_data"]
	if la.grid_width != lb.grid_width or la.grid_height != lb.grid_height or la.tiles.size() != lb.tiles.size():
		return false
	for i in range(la.tiles.size()):
		var ta: TilePlacement = la.tiles[i]
		var tb: TilePlacement = lb.tiles[i]
		if ta.tile_type != tb.tile_type or ta.position != tb.position or ta.direction != tb.direction \
				or ta.mirror_orientation != tb.mirror_orientation or ta.rotatable != tb.rotatable \
				or ta.color != tb.color or ta.required != tb.required or ta.pair_id != tb.pair_id \
				or ta.gate_id != tb.gate_id or ta.initial_open_state != tb.initial_open_state or ta.link_id != tb.link_id:
			return false
	return true


static func mechanic_distribution_report(start: int, end: int, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> Dictionary:
	var counts: Dictionary = {}
	for n in range(start, end + 1):
		var result := ProceduralLevelGenerator.generate(n, generator_version)
		var level: LevelData = result["level_data"]
		for t in level.tiles:
			var name: String = GridTypes.TileType.keys()[t.tile_type]
			counts[name] = int(counts.get(name, 0)) + 1
	return counts


static func difficulty_distribution_report(start: int, end: int, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> Dictionary:
	var by_band: Dictionary = {}
	for n in range(start, end + 1):
		var profile := ProceduralDifficultyProfile.for_level(n, generator_version)
		var band: String = profile["band_name"]
		by_band[band] = int(by_band.get(band, 0)) + 1
	return by_band
