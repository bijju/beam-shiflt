extends Node
## Dev-only Phase 2B sample tool (D96): generates a focused set of V3 PROGRESSION
## levels and prints the human-readable QA report. Never exported
## (scripts/tools/**). NOT a range audit - ~25 levels, seconds.
##
## Run: godot --headless --path . res://scripts/tools/v3_progression_sample.tscn
## Optional user args after `--`:
##   levels=1,10,20   sample levels (default = the Phase 2B focused sample)
##   ascii=1          print each start-state board
##   solver=1 solver_levels=1,50,100 solver_states=20000
##       run LevelSolver on a SMALL subset; each call is state-capped, a level
##       that hits the cap reports UNKNOWN (never "unsolvable"), and the run
##       stops with QA_BUDGET_EXCEEDED past BUDGET_MSEC.
##   quiet=1          one summary line per level

const BUDGET_MSEC := 55000
const DEFAULT_LEVELS := [1, 10, 20, 25, 50, 75, 100, 150, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1200, 1400, 1600, 1750, 1850, 1900, 1950, 2000]


func _ready() -> void:
	var levels: Array = DEFAULT_LEVELS.duplicate()
	var solver_levels: Array = []
	var solver_states := 20000
	var show_ascii := false
	var quiet := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("solver_levels="):
			for s in arg.substr(14).split(","):
				solver_levels.append(int(s))
		elif arg.begins_with("solver_states="):
			solver_states = int(arg.substr(14))
		elif arg == "ascii=1":
			show_ascii = true
		elif arg == "quiet=1":
			quiet = true

	var t0 := Time.get_ticks_msec()
	var failed_levels: Array = []
	var greedy_solved_levels: Array = []
	var total_attempts := 0
	var pass_count := 0
	for n in levels:
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED before level %d" % n)
			break
		var tg := Time.get_ticks_msec()
		var gen := ProceduralProgressionV3.generate(n)
		var gen_ms := Time.get_ticks_msec() - tg
		var again := ProceduralProgressionV3.generate(n)
		var level: LevelData = gen["level_data"]
		var deterministic: bool = gen["seed"] == again["seed"] and ProceduralBoardV3.ascii(level) == ProceduralBoardV3.ascii(again["level_data"])
		var fallback: bool = gen["fallback_used"]
		total_attempts += int(gen["attempt"]) + 1
		if fallback:
			failed_levels.append(n)
			print("=== LEVEL %d  V3_GENERATION_FAILED (fallback V2) gen_ms=%d" % [n, gen_ms])
			for r in gen["rejections"]:
				print("   rejected attempt %d [%s] atoms=%s board=%s: %s" % [r["attempt"], r["stage"], r.get("atoms", []), r.get("board", ""), "; ".join(r["reasons"])])
			continue
		pass_count += 1
		var m: Dictionary = gen["metrics"]
		var req := ProceduralDifficultyContract.get_difficulty_requirements(n)
		var required: int = m["required_rotatables"]
		var meaningful_pct := 100.0 * float(m["dependent_moves"]) / float(maxi(required, 1))
		var sv: Dictionary = gen["start_visibility"]
		var states: int = int(sv["required_tiles"]) + int(sv["preserved_tiles"])
		var plausible_pct := 100.0 * float(sv["initially_plausible_required_states"]) / float(maxi(states, 1))
		var greedy := ProceduralComplexity.greedy_follow_solve(level)
		if greedy["solved"]:
			greedy_solved_levels.append(n)
		print("=== LEVEL %d  [%s]  board=%s  atoms=%s  attempt=%d  deterministic=%s  gen_ms=%d  fallback=no" % [
			n, gen["difficulty_band"], gen["board_size"], gen["atoms"], gen["attempt"], deterministic, gen_ms])
		print("  intended=%d (band %d-%d) keep_correct=%d rotatables=%d  meaningful=%.0f%% plain_route_moves=%d plain_turn_share=%.0f%% padding=%d" % [
			m["intended_move_count"], req["min_optimal_moves"], req["max_optimal_moves"], gen["keep_correct"], m["rotatable_count"],
			meaningful_pct, m["plain_route_moves"], 100.0 * float(gen["plain_turn_fraction"]), m["padding_moves"]])
		print("  deps=%d depth=%d interactions=%d kinds=%s  (band deps>=%d depth>=%d inter>=%d)" % [
			m["meaningful_dependency_count"], m["dependency_depth"], m["mechanic_interaction_count"], m["mechanic_kinds"],
			req["min_meaningful_dependencies"], req["min_dependency_depth"], req["min_mechanic_interactions"]])
		print("  branches=%d shared=%d convergence=%d prereq_chains=%d targets=%d emitters=%d  predicted(depth=%d deps=%d kinds=%d)" % [
			m["required_branches"], m["shared_resource_count"], m["convergence_count"], m["prerequisite_chains"],
			m["required_target_count"], m["emitter_count"], gen["predicted"]["depth"], gen["predicted"]["deps"], gen["predicted"]["kinds"]])
		print("  start: required=%d obvious_wrong=%d hidden=%d preserved=%d activations=%d plausible=%.0f%%  greedy_solved=%s(%d flips) policy=%s greedy_accepted=%s" % [
			sv["required_tiles"], sv["obvious_wrong_required_tiles"], sv["hidden_required_tiles"], sv["preserved_tiles"], sv["start_activations"],
			plausible_pct, greedy["solved"], greedy["steps"], req["greedy_policy"], gen.get("greedy_accepted", false)])
		print("  triviality=%s notes=%s  gate_rejections_before_accept=%d" % [gen["verdict"]["reasons"], gen["verdict"]["notes"], gen["rejections"].size()])
		var checks := _checks(n, gen, level, req, deterministic)
		print("  checks: %s   why-vs-previous-band: %s" % ["ALL PASS" if checks.is_empty() else "FAIL " + str(checks), _why(n, req, m)])
		if not quiet:
			for r in gen["rejections"]:
				print("     rej attempt %d [%s] %s: %s" % [r["attempt"], r["stage"], r.get("atoms", []), "; ".join(r["reasons"])])
		if show_ascii:
			print(gen["ascii"])
		if solver_levels.has(n):
			var ts := Time.get_ticks_msec()
			var sr: Dictionary = LevelSolver.analyze(level, solver_states)
			var validation := LevelValidator.validate(level)
			var line := "  solver: %s optimal=%s states=%s solutions=%s (%d ms)  validator_errors=%s" % [
				sr["status"], sr.get("optimal_moves", "-"), sr.get("states_explored", "-"), sr.get("shortest_solution_count", "-"),
				Time.get_ticks_msec() - ts, validation.get("errors", [])]
			if sr["status"] == "SOLVABLE" and int(sr["optimal_moves"]) < int(m["intended_move_count"]):
				line += "  SHORTCUT (optimal < intended)"
				var flips: Array = []
				for step in sr.get("solution_path", []):
					flips.append(step["position"])
				var intended_flips: Array = []
				var authored: Dictionary = level.get_initial_tile_orientations()
				for pos in gen["solution_orientations"]:
					if authored[pos] != gen["solution_orientations"][pos]:
						intended_flips.append(pos)
				line += "\n    solver flips=%s\n    intended flips=%s\n%s" % [flips, intended_flips, gen["ascii"]]
			print(line)
			if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
				print("QA_BUDGET_EXCEEDED after solver on level %d" % n)
				break
	print("PHASE_MS (all sampled levels): %s" % [ProceduralProgressionV3.phase_us.keys().map(func(k: String) -> String: return "%s=%d" % [k, ProceduralProgressionV3.phase_us[k] / 1000])])
	print("SUMMARY: sampled=%d passed_v3=%d fallback_levels=%s greedy_solved_levels=%s total_attempts=%d fallback_count=%d elapsed_msec=%d" % [
		levels.size(), pass_count, failed_levels, greedy_solved_levels, total_attempts, ProceduralProgressionV3.fallback_count, Time.get_ticks_msec() - t0])
	get_tree().quit()


## Independent re-checks of Part 27 (does not trust the generator's own gate):
## returns the list of FAILED check names (empty = all pass).
func _checks(n: int, gen: Dictionary, level: LevelData, req: Dictionary, deterministic: bool) -> Array:
	var failed: Array = []
	if gen["fallback_used"]:
		failed.append("fallback")
	if not deterministic:
		failed.append("determinism")
	var initial: Dictionary = level.get_initial_tile_orientations()
	if LaserSystem.simulate_until_stable(level, initial)["solved"]:
		failed.append("start_unsolved")
	var solved: Dictionary = initial.duplicate()
	for p in gen["solution_orientations"]:
		solved[p] = gen["solution_orientations"][p]
	if not LaserSystem.simulate_until_stable(level, solved)["solved"]:
		failed.append("intended_solves")
	if level.grid_width > GridManager.MAX_COLUMNS:
		failed.append("columns<=8")
	var comfort: Dictionary = GridManager.is_board_profile_comfortable(level.grid_width, level.grid_height, ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE)
	if not comfort["comfortable"]:
		failed.append("board_comfort")
	var verdict := ProceduralTriviality.evaluate(gen["metrics"], req)
	if not verdict["reasons"].is_empty():
		failed.append("contract:" + ",".join(verdict["reasons"]))
	if not LevelValidator.validate(level).get("errors", []).is_empty():
		failed.append("validator")
	var m: Dictionary = gen["metrics"]
	if int(m["intended_move_count"]) < int(req["min_optimal_moves"]) or int(m["intended_move_count"]) > int(req["max_optimal_moves"]):
		failed.append("moves_in_band")
	return failed


## One line on why this level should sit above the previous band (contract deltas).
func _why(n: int, req: Dictionary, m: Dictionary) -> String:
	var first_of_band := n
	while first_of_band > 1 and ProceduralDifficultyContract.get_difficulty_requirements(first_of_band - 1)["band_name"] == req["band_name"]:
		first_of_band -= 1
	if first_of_band == 1:
		return "first band (Foundation): learn mechanics, %d-%d moves, no dependency ceiling above 1" % [req["min_optimal_moves"], req["max_optimal_moves"]]
	var prev := ProceduralDifficultyContract.get_difficulty_requirements(first_of_band - 1)
	return "%s->%s: moves %d-%d (was %d-%d), depth>=%d (was >=%d), interactions>=%d (was >=%d), kinds>=%d (was >=%d); this level: %d moves, %d kinds, depth %d" % [
		prev["band_name"], req["band_name"], req["min_optimal_moves"], req["max_optimal_moves"], prev["min_optimal_moves"], prev["max_optimal_moves"],
		req["min_dependency_depth"], prev["min_dependency_depth"], req["min_mechanic_interactions"], prev["min_mechanic_interactions"],
		req["min_distinct_mechanics"], prev["min_distinct_mechanics"], m["intended_move_count"], m["distinct_mechanic_kinds"], m["dependency_depth"]]
