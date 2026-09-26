extends Node
## Dev-only Phase 2A audit (D94): generates the six V3 prototypes and prints
## board, plan reasoning, metrics, gates and (capped) solver comparison. Never
## exported (scripts/tools/**). NOT a range audit - six levels, ~seconds.
##
## Run: godot --headless --path . res://scripts/tools/v3_prototype_audit.tscn
## Optional user args after `--`: "solver=0|1" "solver_states=16384" "levels=1,2"
## Each solver call is capped by states; a level that hits the cap reports
## UNKNOWN (never "unsolvable") and the run stops at BUDGET_MSEC with
## QA_BUDGET_EXCEEDED.

const BUDGET_MSEC := 55000


func _ready() -> void:
	var use_solver := true
	var solver_states := 16384
	var levels: Array[int] = [1, 2, 3, 4, 5, 6]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("solver="):
			use_solver = arg.substr(7) == "1"
		elif arg.begins_with("solver_states="):
			solver_states = int(arg.substr(14))
		elif arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))

	var t0 := Time.get_ticks_msec()
	for n in levels:
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED before prototype %d" % n)
			break
		var tg := Time.get_ticks_msec()
		var gen := ProceduralGeneratorV3.generate(n)
		var gen_ms := Time.get_ticks_msec() - tg
		var again := ProceduralGeneratorV3.generate(n)
		var level: LevelData = gen["level_data"]
		var deterministic: bool = gen["seed"] == again["seed"] and ProceduralBoardV3.ascii(level) == ProceduralBoardV3.ascii(again["level_data"])
		var plan: ProceduralPlanV3 = gen.get("plan")
		print("=== PROTOTYPE %d  %s  seed=%d attempt=%d board=%s fallback=%s deterministic=%s gen_ms=%d" % [
			n, gen["template_id"], gen["seed"], gen["attempt"], gen["board_size"], gen["fallback_used"], deterministic, gen_ms])
		for r in gen["rejections"]:
			print("   rejected attempt %d [%s]: %s" % [r["attempt"], r["stage"], "; ".join(r["reasons"])])
			if r["attempt"] == 0 and r.has("ascii"):
				var rm: Dictionary = r.get("metrics", {})
				print(r["ascii"])
				if rm.has("intended_move_count"):
					print("   (rej0) moves=%d deps=%d depth=%d inter=%d shared=%d branches=%d chains=%d kinds=%s lb=%s" % [rm["intended_move_count"], rm["meaningful_dependency_count"], rm["dependency_depth"], rm["mechanic_interaction_count"], rm["shared_resource_count"], rm["required_branches"], rm["prerequisite_chains"], rm["mechanic_kinds"], rm["load_bearing_units"]])
		if plan == null:
			continue
		print(plan.title)
		print(ProceduralBoardV3.ascii(level))
		var m: Dictionary = gen["metrics"]
		var required: int = m["required_rotatables"]
		var pct := 100.0 * float(m["dependent_moves"]) / float(maxi(required, 1))
		var solver_result := {}
		var solver_txt := "skipped"
		var ts := Time.get_ticks_msec()
		if use_solver:
			solver_result = LevelSolver.analyze(level, solver_states)
			solver_txt = "%s optimal=%s states=%s solutions=%s (%d ms)" % [
				solver_result["status"], solver_result.get("optimal_moves", "-"), solver_result.get("states_explored", "-"),
				solver_result.get("shortest_solution_count", "-"), Time.get_ticks_msec() - ts]
		var validation := LevelValidator.validate(level)
		var kinds: Array = m["mechanic_kinds"]
		print("  mechanics=%s" % [kinds])
		print("  intended=%d meaningful=%d plain=%d padding=%d meaningful%%=%.0f rotatables=%d" % [
			m["intended_move_count"], m["dependent_moves"], m["plain_route_moves"], m["padding_moves"], pct, m["rotatable_count"]])
		print("  deps=%d depth=%d interactions=%d shared=%d branches=%d convergence=%d targets=%d kinds=%d" % [
			m["meaningful_dependency_count"], m["dependency_depth"], m["mechanic_interaction_count"], m["shared_resource_count"],
			m["required_branches"], m["convergence_count"], m["required_target_count"], m["distinct_mechanic_kinds"]])
		print("  triviality=%s notes=%s  validator_errors=%s" % [gen["verdict"]["reasons"], gen["verdict"]["notes"], validation.get("errors", [])])
		var sv: Dictionary = gen["start_visibility"]
		print("  start: required=%d obvious_wrong=%d hidden=%d preserved=%d start_activations=%d plausible_states=%d" % [
			sv["required_tiles"], sv["obvious_wrong_required_tiles"], sv["hidden_required_tiles"], sv["preserved_tiles"], sv["start_activations"], sv["initially_plausible_required_states"]])
		print("  prerequisite_chains=%d color_deps=%d one_way_deps=%d portal_deps=%d" % [m["prerequisite_chains"], m["color_dependency_count"], m["one_way_dependency_count"], m["portal_dependency_count"]])
		var gr := ProceduralComplexity.greedy_follow_solve(level)
		print("  greedy beam-follower: solved=%s after %d flips (proxy for rotate-every-visibly-wrong-tile)" % [gr["solved"], gr["steps"]])
		print("  solver: %s" % solver_txt)
		if solver_result.get("status", "") == "SOLVABLE":
			var flips: Array = []
			for step in solver_result.get("solution_path", []):
				flips.append(step["position"])
			var intended_flips: Array = []
			var authored: Dictionary = level.get_initial_tile_orientations()
			for pos in gen["solution_orientations"]:
				if authored[pos] != gen["solution_orientations"][pos]:
					intended_flips.append(pos)
			print("  solver flips=%s" % [flips])
			print("  intended flips=%s" % [intended_flips])
			var shortcut: bool = int(solver_result["optimal_moves"]) < int(m["intended_move_count"])
			print("  shortcut check: optimal %d vs intended %d -> %s" % [
				solver_result["optimal_moves"], m["intended_move_count"], "SHORTCUT" if shortcut else "ok"])
		print("  reasoning: %s" % plan.reasoning)
	print("elapsed_msec=%d" % (Time.get_ticks_msec() - t0))
	get_tree().quit()
