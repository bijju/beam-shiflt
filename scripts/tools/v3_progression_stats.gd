extends Node
## Dev-only Phase 2B statistics tool (D96): shortcut / solver agreement over a
## RANGE of V3 progression levels - the levels are the seeds. Never exported.
##
## Run: godot --headless --path . res://scripts/tools/v3_progression_stats.tscn -- range=300-340
## Args: range=a-b  step=N  probe=0|1 (generate with/without the runtime probe)
##       solver_states=60000  (per-level state cap; over the cap = UNKNOWN)
##       max_rotatables=17    (skip the solver above this many rotatable tiles)
## Stops with QA_BUDGET_EXCEEDED after BUDGET_MSEC.

const BUDGET_MSEC := 55000


func _ready() -> void:
	var a := 300
	var b := 320
	var step := 1
	var probe_on := true
	var solver_states := 60000
	var max_rot := 17
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("range="):
			var parts := arg.substr(6).split("-")
			a = int(parts[0])
			b = int(parts[1])
		elif arg.begins_with("step="):
			step = int(arg.substr(5))
		elif arg.begins_with("alpha="):
			ProceduralComposerV3.compact_alpha = float(arg.substr(6))
		elif arg == "probe=0":
			probe_on = false
		elif arg.begins_with("solver_states="):
			solver_states = int(arg.substr(14))
		elif arg.begins_with("max_rotatables="):
			max_rot = int(arg.substr(15))
	ProceduralProgressionV3.shortcut_probe_enabled = probe_on

	var t0 := Time.get_ticks_msec()
	var n_levels := 0
	var n_fallback := 0
	var n_solved_checked := 0
	var n_shortcut := 0
	var n_unique := 0
	var n_unknown := 0
	var n_skipped := 0
	var n_probe_detects := 0
	var n_probe_misses := 0
	var n_probe_false_alarm := 0
	var probe_sims := 0
	var attempts_total := 0
	var gen_ms_total := 0
	var gen_ms_max := 0
	var n_validator_errors := 0
	var rej_hist := {}
	var agg := {"n": 0, "moves": 0.0, "depth": 0.0, "deps": 0.0, "inter": 0.0, "greedy": 0, "plaus": 0.0, "meaning": 0.0, "kinds": 0.0, "tiles": 0.0, "dens": 0.0}
	var atom_ok := {}
	var atom_fail := {}
	var bucket_ok := {}
	var bucket_fail := {}
	var ops_ok: Array = []
	var ops_fail: Array = []
	var n := a
	while n <= b:
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED at level %d" % n)
			break
		var tg := Time.get_ticks_msec()
		var gen := ProceduralProgressionV3.generate(n)
		var ms := Time.get_ticks_msec() - tg
		gen_ms_total += ms
		gen_ms_max = maxi(gen_ms_max, ms)
		n_levels += 1
		if not gen["fallback_used"]:
			for at in gen["atoms"]:
				atom_ok[at] = int(atom_ok.get(at, 0)) + 1
			var bk := int(gen["density_est"] * 20.0)
			bucket_ok[bk] = int(bucket_ok.get(bk, 0)) + 1
			ops_ok.append(gen["composer_ops"])
		for r in gen["rejections"]:
			if r.has("density_est"):
				for at in r.get("atoms", []):
					if r["stage"] == "layout":
						atom_fail[at] = int(atom_fail.get(at, 0)) + 1
					else:
						atom_ok[at] = int(atom_ok.get(at, 0)) + 1
				var bk2 := int(r["density_est"] * 20.0)
				if r["stage"] == "layout":
					bucket_fail[bk2] = int(bucket_fail.get(bk2, 0)) + 1
					ops_fail.append(r["ops"])
				else:
					bucket_ok[bk2] = int(bucket_ok.get(bk2, 0)) + 1
					ops_ok.append(r["ops"])
			for reason in r["reasons"]:
				var key: String = "%s: %s" % [r["stage"], str(reason).substr(0, 70)]
				rej_hist[key] = int(rej_hist.get(key, 0)) + 1
		if gen["fallback_used"]:
			n_fallback += 1
			print("L%d FALLBACK" % n)
			n += step
			continue
		attempts_total += int(gen["attempt"]) + 1
		var level: LevelData = gen["level_data"]
		var m: Dictionary = gen["metrics"]
		var intended: int = m["intended_move_count"]
		var pr := ProceduralShortcutProbe.probe(level, intended, gen["solution_orientations"])
		agg["n"] += 1
		var verr: Array = LevelValidator.validate(level).get("errors", [])
		if not verr.is_empty():
			n_validator_errors += 1
			print("L%d VALIDATOR_ERRORS %s" % [n, verr])
		agg["moves"] += intended
		agg["depth"] += m["dependency_depth"]
		agg["deps"] += m["meaningful_dependency_count"]
		agg["inter"] += m["mechanic_interaction_count"]
		agg["kinds"] += m["distinct_mechanic_kinds"]
		agg["meaning"] += float(m["dependent_moves"]) / float(maxi(m["required_rotatables"], 1))
		var svis: Dictionary = gen["start_visibility"]
		agg["plaus"] += float(svis.get("initially_plausible_required_states", 0)) / float(maxi(int(svis.get("required_tiles", 0)) + int(svis.get("preserved_tiles", 0)), 1))
		if ProceduralComplexity.greedy_follow_solve(level)["solved"]:
			agg["greedy"] += 1
		agg["tiles"] += gen["tile_count"]
		agg["dens"] += float(gen["tile_count"]) / float(level.grid_width * level.grid_height)
		probe_sims += int(pr["sims"])
		var line := "L%d %s intended=%d rot=%d attempt=%d probe=%s(d=%d,sims=%d) gen_ms=%d" % [n, gen["atoms"], intended, m["rotatable_count"], gen["attempt"], pr["shortcut"], pr["depth"], pr["sims"], ms]
		if m["rotatable_count"] <= max_rot:
			var sr: Dictionary = LevelSolver.analyze(level, solver_states)
			if sr["status"] == "SOLVABLE":
				n_solved_checked += 1
				var opt: int = sr["optimal_moves"]
				var is_short := opt < intended
				if int(sr["shortest_solution_count"]) == 1:
					n_unique += 1
				if is_short:
					n_shortcut += 1
					if pr["shortcut"]:
						n_probe_detects += 1
					else:
						n_probe_misses += 1
				elif pr["shortcut"]:
					n_probe_false_alarm += 1
				line += " solver=optimal %d states=%d%s" % [opt, sr["states_explored"], " SHORTCUT" if is_short else ""]
			else:
				n_unknown += 1
				line += " solver=%s" % sr["status"]
		else:
			n_skipped += 1
			line += " solver=skipped(rot>%d)" % max_rot
		line += " tiles=%d/%d(est %d) dens=%.0f%%" % [gen["tile_count"], level.grid_width * level.grid_height, gen["tile_estimate"], 100.0 * float(gen["tile_count"]) / float(level.grid_width * level.grid_height)]
		var hz: Dictionary = gen.get("hardening", {})
		line += " hz=%d/rep=%d/unrep=%d(cross=%d,same=%d,path=%d)" % [hz.get("hazards", 0), hz.get("repaired", 0), hz.get("unrepaired", 0), hz.get("cross_line", 0), hz.get("same_line", 0), hz.get("path_overlap", 0)]
		print(line)
		n += step
	for fk in ProceduralComposerV3.fail_stats:
		print("  COMPOSER_FAIL %5d  %s" % [ProceduralComposerV3.fail_stats[fk], fk])
	var ats: Array = atom_ok.keys()
	for k in atom_fail:
		if not ats.has(k):
			ats.append(k)
	for k in ats:
		print("  ATOM %-3s layout ok=%d fail=%d" % [k, atom_ok.get(k, 0), atom_fail.get(k, 0)])
	var bks: Array = []
	for k in bucket_ok:
		bks.append(k)
	for k in bucket_fail:
		if not bks.has(k):
			bks.append(k)
	bks.sort()
	for k in bks:
		print("  DENSITY_EST %2d-%2d%%: layout ok=%d fail=%d" % [k * 5, k * 5 + 5, bucket_ok.get(k, 0), bucket_fail.get(k, 0)])
	ops_ok.sort()
	ops_fail.sort()
	if not ops_ok.is_empty():
		print("  OPS ok: median=%d p90=%d max=%d ; fail: median=%d" % [ops_ok[ops_ok.size() / 2], ops_ok[int(ops_ok.size() * 0.9)], ops_ok[-1], ops_fail[ops_fail.size() / 2] if not ops_fail.is_empty() else -1])
	var keys: Array = rej_hist.keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return rej_hist[x] > rej_hist[y])
	for k in keys.slice(0, 12):
		print("  REJ %4d  %s" % [rej_hist[k], k])
	var nn := float(maxi(agg["n"], 1))
	print("BANDAVG n=%d moves=%.1f depth=%.1f deps=%.1f interactions=%.1f kinds=%.1f meaningful=%.0f%% plausible=%.0f%% greedy_solved=%d/%d(%.0f%%) tiles=%.1f density=%.0f%%" % [agg["n"], agg["moves"] / nn, agg["depth"] / nn, agg["deps"] / nn, agg["inter"] / nn, agg["kinds"] / nn, 100.0 * agg["meaning"] / nn, 100.0 * agg["plaus"] / nn, agg["greedy"], agg["n"], 100.0 * agg["greedy"] / nn, agg["tiles"] / nn, 100.0 * agg["dens"] / nn])
	print("VALIDATOR: levels_with_errors=%d" % n_validator_errors)
	print("STATS: levels=%d fallback=%d solver_checked=%d shortcut=%d (probe detected %d, missed %d, probe_flagged_non_shortcut %d) unique_solution=%d unknown=%d skipped=%d avg_attempts=%.2f gen_ms avg=%.1f max=%d probe_sims_total=%d elapsed_msec=%d" % [
		n_levels, n_fallback, n_solved_checked, n_shortcut, n_probe_detects, n_probe_misses, n_probe_false_alarm, n_unique, n_unknown, n_skipped,
		float(attempts_total) / float(maxi(n_levels - n_fallback, 1)), float(gen_ms_total) / float(maxi(n_levels, 1)), gen_ms_max, probe_sims, Time.get_ticks_msec() - t0])
	get_tree().quit()
