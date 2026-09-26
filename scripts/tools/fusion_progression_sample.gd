extends Node
## Dev-only Fusion Phase 2 sample tool (D100): generates a focused set of generator-V4 levels and prints
## the QA report (never exported: scripts/tools/**). NOT a range audit - seconds, hard 55 s budget.
##
## Run: godot --headless --path . res://scripts/tools/fusion_progression_sample.tscn
## Optional user args after `--`:
##   levels=199,200,201   levels to report in detail (default = the Phase 2 focused sample)
##   version=4            generator version (3 = frozen V3 for comparison)
##   freq=1               also print Fusion frequency per band over a deterministic stride sample
##   stride=8             stride of the frequency sample (default 8)
##   quiet=1              one summary line per level
##   ascii=1              print the start-state board of Fusion levels
##   stress=N from=K      generate N consecutive levels from K and report only problems

const BUDGET_MSEC := 55000
const DEFAULT_LEVELS := [199, 200, 201, 250, 300, 400, 401, 500, 700, 701, 850, 1000, 1001, 1200, 1300, 1301, 1450, 1600, 1601, 1700, 1800, 1801, 1900, 1950, 2000]
const BANDS := [[1, 200], [201, 400], [401, 700], [701, 1000], [1001, 1300], [1301, 1600], [1601, 1800], [1801, 2000]]


func _ready() -> void:
	var levels: Array = DEFAULT_LEVELS.duplicate()
	var version := ProceduralLevelGenerator.GENERATOR_VERSION_V4
	var show_freq := false
	var stride := 8
	var quiet := false
	var show_ascii := false
	var stress := 0
	var from := 1
	var find := ""
	var list_fusion := false
	var band_filter: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("version="):
			version = int(arg.substr(8))
		elif arg == "freq=1":
			show_freq = true
		elif arg.begins_with("stride="):
			stride = maxi(1, int(arg.substr(7)))
		elif arg == "quiet=1":
			quiet = true
		elif arg == "list=1":
			list_fusion = true
		elif arg == "ascii=1":
			show_ascii = true
		elif arg.begins_with("stress="):
			stress = int(arg.substr(7))
		elif arg.begins_with("from="):
			from = int(arg.substr(5))
		elif arg.begins_with("find="):
			find = arg.substr(5)
		elif arg.begins_with("bands="):
			for s in arg.substr(6).split(","):
				band_filter.append(int(s))

	var t0 := Time.get_ticks_msec()
	if find != "":
		_find(find, from, maxi(stress, 60), version, t0)
		get_tree().quit()
		return
	if stress > 0:
		_stress(from, stress, version, t0, list_fusion)
		get_tree().quit()
		return

	var failures: Array = []
	var fusion_levels := 0
	var greedy_levels: Array = []
	var fallbacks: Array = []
	var total_ms := 0
	var max_ms := 0
	for n in levels:
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED before level %d" % n)
			break
		var tg := Time.get_ticks_msec()
		var gen := ProceduralLevelGenerator.generate(n, version)
		var gen_ms := Time.get_ticks_msec() - tg
		total_ms += gen_ms
		max_ms = maxi(max_ms, gen_ms)
		var again := ProceduralLevelGenerator.generate(n, version)
		var level: LevelData = gen["level_data"]
		var deterministic: bool = gen["seed"] == again["seed"] and ProceduralBoardV3.ascii(level) == ProceduralBoardV3.ascii(again["level_data"]) and gen["solution_orientations"] == again["solution_orientations"]
		var problems := _independent_checks(n, gen)
		if not deterministic:
			problems.append("NOT DETERMINISTIC")
		if gen["fallback_used"]:
			fallbacks.append(n)
			problems.append("FALLBACK V2")
		var frag: String = gen.get("fusion_fragment", "")
		if frag != "":
			fusion_levels += 1
		if gen.get("greedy_solved", false):
			greedy_levels.append(n)
		var m: Dictionary = gen.get("metrics", {})
		var fr: Dictionary = gen.get("fusion_report", {})
		var ftxt := "-"
		if not fr.is_empty():
			var parts: Array = []
			for f in fr["fusions"]:
				parts.append("fused=%d in=%s req=%d/%d use=%s fb=%s" % [f["fused"], f["inputs"], f["inputs_required"], f["inputs"].size(), f["consumer"], f["feedback"]])
			ftxt = " ; ".join(parts) + " settled=%s nb_sims=%d passes<=%d variant=%s rejected=%s" % [fr["all_settled"], fr["neighbour_sims"], fr["max_passes"], _variant_label(gen), _rejection_histogram(gen)]
		print("L%d v%d [%s] recipe=%s fusion=%s moves=%s depth=%s deps=%s inter=%s kinds=%s branches=%s shared=%s tiles=%d board=%s greedy=%s attempt=%d ms=%d%s" % [
			n, gen["generator_version"], gen.get("difficulty_band", "?"), gen["template_id"], frag if frag != "" else "-",
			m.get("intended_move_count", "?"), m.get("dependency_depth", "?"), m.get("meaningful_dependency_count", "?"),
			m.get("mechanic_interaction_count", "?"), m.get("distinct_mechanic_kinds", "?"), m.get("required_branches", "?"),
			m.get("shared_resource_count", "?"), level.tiles.size(), gen["board_size"], gen.get("greedy_solved", "?"), gen["attempt"], gen_ms,
			(" PROBLEMS=" + str(problems)) if not problems.is_empty() else ""])
		if not quiet and frag != "":
			print("     fusion: %s" % ftxt)
			if show_ascii:
				print(ProceduralBoardV3.ascii(level))
		if not problems.is_empty():
			failures.append([n, problems])

	print("--- sample: %d levels, %d with Fusion, fallbacks=%s, greedy-solvable=%s, gen_ms total=%d max=%d" % [levels.size(), fusion_levels, fallbacks, greedy_levels, total_ms, max_ms])
	print("--- problems: %s" % [failures])
	if show_freq:
		_frequency(version, stride, t0, band_filter)
	var phases: Dictionary = {}
	for k in ProceduralProgressionV3.phase_us:
		phases[k] = int(ProceduralProgressionV3.phase_us[k]) / 1000
	print("phase ms (all generated levels incl. determinism re-runs): %s" % [phases])
	print("elapsed_msec=%d fallback_count=%d" % [Time.get_ticks_msec() - t0, ProceduralProgressionV3.fallback_count])
	get_tree().quit()


## Checks that do NOT reuse the generator's own gates: the intended solution solves, the start does
## not, columns/comfort, every Fusion node active with distinct primaries and exactly one tap from solved.
func _independent_checks(_n: int, gen: Dictionary) -> Array:
	var problems: Array = []
	var level: LevelData = gen["level_data"]
	var authored: Dictionary = level.get_initial_tile_orientations()
	if LaserSystem.simulate_until_stable(level, authored)["solved"]:
		problems.append("start already solved")
	var solved: Dictionary = authored.duplicate()
	for p in gen["solution_orientations"]:
		solved[p] = gen["solution_orientations"][p]
	var res := LaserSystem.simulate_until_stable(level, solved)
	if not res["solved"]:
		problems.append("intended solution does not solve")
	if not res["converged"]:
		problems.append("solved state did not converge")
	if level.grid_width > GridManager.MAX_COLUMNS:
		problems.append("columns %d > MAX_COLUMNS" % level.grid_width)
	var comfort := GridManager.is_board_profile_comfortable(level.grid_width, level.grid_height, ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE)
	if not comfort["comfortable"]:
		problems.append("board not comfortable")
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.FUSION:
			var colors: Array = res["fusion_input_colors"].get(t.position, [])
			if not res["fusion_colors"].has(t.position):
				problems.append("fusion at %s inactive when solved" % t.position)
			if colors.size() < 2:
				problems.append("fusion at %s has %d input(s)" % [t.position, colors.size()])
			if (int(t.direction) + 1) % 4 != int(gen["solution_orientations"].get(t.position, -1)):
				problems.append("fusion at %s is not exactly one tap from solved" % t.position)
	return problems


func _frequency(version: int, stride: int, t0: int, band_filter: Array = []) -> void:
	print("--- Fusion frequency (stride %d) ---" % stride)
	for bi in range(BANDS.size()):
		if not band_filter.is_empty() and not band_filter.has(bi):
			continue
		var band: Array = BANDS[bi]
		var n_levels := 0
		var n_fusion := 0
		var frags := {}
		var fb := 0
		var greedy := 0
		var ms := 0
		var rolled := 0
		var why := {}
		var lv: int = band[0]
		while lv <= band[1]:
			if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
				print("QA_BUDGET_EXCEEDED in band %s at %d" % [band, lv])
				return
			var tg := Time.get_ticks_msec()
			var gen := ProceduralLevelGenerator.generate(lv, version)
			ms += Time.get_ticks_msec() - tg
			n_levels += 1
			if gen["fallback_used"]:
				fb += 1
			if gen.get("greedy_solved", false):
				greedy += 1
			var did_roll := not ProceduralFragmentsV3.roll_fusion_recipe(lv, ProceduralSeed.rng_for_attempt(lv, version, ProceduralProgressionV3.FUSION_ROLL_STREAM)).is_empty()
			if did_roll:
				rolled += 1
			var frag: String = gen.get("fusion_fragment", "")
			if frag != "":
				n_fusion += 1
				var fkey: String = frag + ":" + _variant_label(gen)
				frags[fkey] = int(frags.get(fkey, 0)) + 1
			if did_roll and gen.get("fusion_fragment", "") == "":
				for r in gen.get("rejections", []):
					var rs: Array = r.get("reasons", [])
					if not rs.is_empty() and int(r["attempt"]) < 6:
						var k := "+".join(r.get("atoms", [])) + " | " + str(rs[0]).left(58)
						why[k] = int(why.get(k, 0)) + 1
			lv += stride
		print("band %s: %d sampled, %d rolled, %d Fusion (%.0f%%) %s fallbacks=%d greedy-solvable=%d avg_ms=%d" % [band, n_levels, rolled, n_fusion, 100.0 * float(n_fusion) / float(maxi(n_levels, 1)), frags, fb, greedy, ms / maxi(n_levels, 1)])
		if not why.is_empty():
			print("   unrealised-roll rejection reasons: %s" % [why])


func _stress(from: int, count: int, version: int, t0: int, list_fusion: bool = false) -> void:
	var bad := 0
	var fusion := 0
	for i in range(count):
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED at %d" % (from + i))
			break
		var n := from + i
		var gen := ProceduralLevelGenerator.generate(n, version)
		var problems := _independent_checks(n, gen)
		if gen["fallback_used"]:
			problems.append("FALLBACK")
		if gen.get("fusion_fragment", "") != "":
			fusion += 1
			if list_fusion:
				var fr: Dictionary = gen["fusion_report"]
				var m: Dictionary = gen["metrics"]
				var cols: Array = []
				for f in fr["fusions"]:
					cols.append("%s->%d" % [f["inputs"], f["fused"]])
				print("FUSIONLVL L%d %s/%s atoms=%s colors=%s board=%s tiles=%d moves=%d intended=%d depth=%d deps=%d inter=%d greedy=%s settle<=%d ms=%d attempt=%d" % [n, gen["fusion_fragment"], _variant_label(gen), "+".join(gen["atoms"]), cols, gen["board_size"], gen["level_data"].tiles.size(), m["intended_move_count"], gen["intended_moves"], m["dependency_depth"], m["meaningful_dependency_count"], m["mechanic_interaction_count"], gen.get("greedy_solved", false), fr["max_passes"], 0, gen["attempt"]])
		if not problems.is_empty():
			bad += 1
			print("L%d %s %s" % [n, gen.get("fusion_fragment", ""), problems])
	print("stress %d..%d: %d with Fusion, %d bad, fallback_count=%d, elapsed=%d" % [from, from + count - 1, fusion, bad, ProceduralProgressionV3.fallback_count, Time.get_ticks_msec() - t0])


## F5 has two recipe-level variants that the fusion atom itself cannot label.
func _variant_label(gen: Dictionary) -> String:
	if gen.get("fusion_fragment", "") == "F5":
		return "remote_gate" if gen.get("fusion_recipe", []).has("G") else "remote"
	return str(gen.get("fusion_variant", ""))


## "shortcut x3 gate x5"-style summary of why earlier attempts of this level were rejected.
func _rejection_histogram(gen: Dictionary) -> String:
	var h := {}
	for r in gen.get("rejections", []):
		var key: String = str(r["stage"])
		h[key] = int(h.get(key, 0)) + 1
	return str(h)


## Prints the first few levels in [from, from+count) that realise Fusion fragment `frag` (F1..F7), with their boards.
func _find(frag: String, from: int, count: int, version: int, t0: int) -> void:
	var shown := 0
	for i in range(count):
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC or shown >= 3:
			break
		var n := from + i
		var gen := ProceduralLevelGenerator.generate(n, version)
		if gen.get("fusion_fragment", "") != frag:
			continue
		shown += 1
		var m: Dictionary = gen["metrics"]
		print("L%d %s recipe=%s moves=%d depth=%d deps=%d kinds=%s start-visibility=%s" % [n, frag, gen["template_id"], m["intended_move_count"], m["dependency_depth"], m["meaningful_dependency_count"], m["mechanic_kinds"], gen["start_visibility"]])
		print(ProceduralBoardV3.ascii(gen["level_data"]))
		print("solution: %s" % [gen["solution_orientations"]])
