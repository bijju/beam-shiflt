extends Node
## Dev-only fast inspection (Difficulty System Phase 1, D93): generates a
## short list of procedural levels and prints, per level, the difficulty
## contract, ProceduralComplexity metrics and ProceduralTriviality verdict.
## Excluded from the Android export like every scripts/tools/** file.
##
## Run: godot --headless --path . res://scripts/tools/difficulty_inspect.tscn  (a scene, not --script: GridManager needs the AudioManager autoload)
## Optional user args after `--`: "levels=1,25,50" "version=2" "solver=0|1"
## "solver_states=4096". Deliberately NOT a range audit - a full 1-2000 sweep
## is a separate, slow, explicit decision (see TEST_PLAN.md time budget).

const DEFAULT_LEVELS: Array[int] = [1, 25, 50, 100, 500, 1000, 1500, 1900, 2000]
const BUDGET_MSEC := 55000


func _ready() -> void:
	var levels: Array[int] = DEFAULT_LEVELS.duplicate()
	var version := ProceduralLevelGenerator.GENERATOR_VERSION
	var use_solver := true
	var solver_states := 4096
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("version="):
			version = int(arg.substr(8))
		elif arg.begins_with("solver="):
			use_solver = arg.substr(7) == "1"
		elif arg.begins_with("solver_states="):
			solver_states = int(arg.substr(14))

	var t0 := Time.get_ticks_msec()
	for n in levels:
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED before level %d" % n)
			break
		var gen := ProceduralLevelGenerator.generate(n, version)
		var level: LevelData = gen["level_data"]
		var solver_result := {}
		if use_solver:
			solver_result = LevelSolver.analyze(level, solver_states)
		var report := ProceduralTriviality.evaluate_generated(n, gen, solver_result)
		var m: Dictionary = report["metrics"]
		var req: Dictionary = report["requirements"]
		var v: Dictionary = report["verdict"]
		print("L%d [%s] template=%s board=%s fallback=%s rejections=%d" % [
			n, req["band_name"], gen["template_id"], gen["board_size"], gen["fallback_used"], gen["rejections"].size()])
		print("   moves: intended=%d optimal=%d (contract %d-%d) solver=%s states=%d sols=%d | rotatables=%d required=%d padding=%d plain=%d dependent=%d" % [
			m["intended_move_count"], m["optimal_moves"], req["min_optimal_moves"], req["max_optimal_moves"],
			solver_result.get("status", "n/a"), m["solver_states"], m["shortest_solution_count"],
			m["rotatable_count"], m["required_rotatables"], m["padding_moves"], m["plain_route_moves"], m["dependent_moves"]])
		print("   reasoning: deps=%d (need %d) depth=%d (need %d) interactions=%d (need %d) kinds=%s branches=%d shared=%d convergence=%d targets=%d emitters=%d decoys=%d single_route=%s" % [
			m["meaningful_dependency_count"], req["min_meaningful_dependencies"],
			m["dependency_depth"], req["min_dependency_depth"],
			m["mechanic_interaction_count"], req["min_mechanic_interactions"],
			m["mechanic_kinds"], m["required_branches"], m["shared_resource_count"], m["convergence_count"],
			m["required_target_count"], m["emitter_count"], m["decoy_count"], m["is_single_route"]])
		print("   verdict: trivial=%s reasons=%s notes=%s" % [v["trivial"], v["reasons"], v["notes"]])
	print("elapsed_msec=%d" % (Time.get_ticks_msec() - t0))
	get_tree().quit()
