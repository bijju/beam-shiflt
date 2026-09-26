extends Node
## Dev-only generator-V5 sample/statistics tool (Selector Phase S3, D110). Never exported (scripts/tools/**).
## Every run has a hard budget (default 55 s) and prints QA_BUDGET_EXCEEDED instead of running on.
##
## Run: godot --headless --path . res://scripts/tools/v5_sample.tscn -- <args>
##   levels=2001,2050,...   detailed one-line reports (default = the 21 anchor levels)
##   from=2001 count=25 stride=8   band window: generates `count` levels starting at `from`, every `stride` levels
##   ascii=1                print the start-state board of every reported level
##   version=5              generator version (default 5)
##   wide=1                 extra WIDE shortcut probe on every reported level (independent of the generator's own)
##   budget=55000           milliseconds
##   quiet=1                only the summary
## Reported per level: band, board, seed, recipe, Selector family/count, intended moves, verified optimum
## (UNKNOWN unless v5_verify proved it), dependencies, depth, interactions, kinds, Selector metrics,
## greedy result, shortcut result, attempts, generation time, fallback flag.

const DEFAULT_LEVELS := [2001, 2050, 2100, 2150, 2200, 2250, 2300, 2350, 2400, 2450, 2500, 2550, 2600, 2650, 2700, 2750, 2800, 2850, 2900, 2950, 3000]

var _budget := 55000
var _wide_sims := 2500
var _wide_width := 40


func _ready() -> void:
	var levels: Array = DEFAULT_LEVELS.duplicate()
	var version := ProceduralLevelGenerator.GENERATOR_VERSION_V5
	var ascii := false
	var wide := false
	var diag := false
	var show_hist := false
	var sel_only := false
	var quiet := false
	var from := 0
	var count := 0
	var stride := 8
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("version="):
			version = int(arg.substr(8))
		elif arg == "ascii=1":
			ascii = true
		elif arg == "wide=1":
			wide = true
		elif arg == "wide=big":
			wide = true
			_wide_sims = 6000
			_wide_width = 80
		elif arg == "diag=1":
			diag = true
		elif arg.begins_with("restarts="):
			ProceduralFragmentsV3.v5_restarts = int(arg.substr(9))
		elif arg.begins_with("ops="):
			ProceduralFragmentsV3.v5_op_budget = int(arg.substr(4))
		elif arg.begins_with("walk="):
			ProceduralFragmentsV3.v5_walk_budget = int(arg.substr(5))
		elif arg == "selonly=1":
			sel_only = true
		elif arg == "nosel=1":
			ProceduralFragmentsV3.dev_disable_selector = true
		elif arg.begins_with("family="):
			ProceduralFragmentsV3.dev_force_family = arg.substr(7)
		elif arg.begins_with("histmax="):
			_hist_max_attempt = int(arg.substr(8))
		elif arg == "hist=1":
			show_hist = true
		elif arg == "quiet=1":
			quiet = true
		elif arg.begins_with("budget="):
			_budget = int(arg.substr(7))
		elif arg.begins_with("from="):
			from = int(arg.substr(5))
		elif arg.begins_with("count="):
			count = int(arg.substr(6))
		elif arg.begins_with("stride="):
			stride = maxi(1, int(arg.substr(7)))
	var t0 := Time.get_ticks_msec()
	if count > 0:
		levels.clear()
		for i in range(count):
			levels.append(from + i * stride)

	var stats := _new_stats()
	var problems_all: Array = []
	for n in levels:
		if Time.get_ticks_msec() - t0 > _budget:
			print("QA_BUDGET_EXCEEDED before level %d" % n)
			break
		var tg := Time.get_ticks_usec()
		var gen := ProceduralLevelGenerator.generate(n, version)
		var ms := int((Time.get_ticks_usec() - tg) / 1000)
		var problems := _independent_checks(gen, wide)
		_accumulate(stats, n, gen, ms, problems)
		_add_atoms(gen)
		_add_rolled(n, gen, version)
		if not sel_only or gen.get("selector_present", false) or gen.get("selector_dropped", false):
			_add_hist(gen)
		if not problems.is_empty():
			problems_all.append([n, problems])
		if not quiet:
			print(_line(n, gen, ms, problems))
			if ascii:
				print(ProceduralBoardV3.ascii(gen["level_data"]))
		if diag:
			print(_rejection_report(gen))
	print(_summary(stats, levels.size()))
	if show_hist:
		_print_hist()
	_print_atoms()
	_print_rolled()
	print("--- problems: %s" % [problems_all])
	var phases: Dictionary = {}
	for k in ProceduralProgressionV3.phase_us:
		phases[k] = int(ProceduralProgressionV3.phase_us[k]) / 1000
	print("phase ms: %s" % [phases])
	print("composer fail_stats: %s" % [ProceduralComposerV3.fail_stats])
	print("rejected attempts by stage (all levels): %s" % [_stage_counts])
	print("elapsed_msec=%d fallback_count=%d selector_dropped=%d band_demoted=%d" % [Time.get_ticks_msec() - t0, ProceduralProgressionV3.fallback_count, ProceduralProgressionV3.selector_dropped_count, ProceduralProgressionV3.band_demoted_count])
	get_tree().quit()


## Checks that do NOT reuse the generator's own gates: the intended solution solves, the start does not,
## columns/comfort, every Selector's start is 1-3 taps from solved and equals the intended tap distance,
## determinism is checked by the caller's two runs, and (wide=1) a much wider shortcut probe.
func _independent_checks(gen: Dictionary, wide: bool) -> Array:
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
		if t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			var taps := posmod(int(gen["solution_orientations"].get(t.position, -1)) - int(t.direction), 4)
			if taps < 1 or taps > 3:
				problems.append("selector at %s is %d taps from solved" % [t.position, taps])
	if gen["fallback_used"]:
		problems.append("FALLBACK")
	if wide and not gen["fallback_used"]:
		var probe := ProceduralShortcutProbe.probe(level, int(gen["intended_moves"]), gen["solution_orientations"], _wide_sims, _wide_width)
		if probe["shortcut"]:
			problems.append("WIDE PROBE shortcut in %d" % probe["depth"])
	return problems


func _new_stats() -> Dictionary:
	return {"n": 0, "ok": 0, "fallback": 0, "selector": 0, "selector_dropped": 0, "sel_count_sum": 0, "moves": [], "depth": [], "inter": [], "kinds": [],
		"deps": [], "greedy": 0, "attempts": [], "ms": [], "fusion": 0, "fragments": {}, "tiles": [], "boards": {}, "eq": 0, "conseq": 0, "ds_depth": []}


func _accumulate(s: Dictionary, n: int, gen: Dictionary, ms: int, problems: Array) -> void:
	s["n"] += 1
	if problems.is_empty():
		s["ok"] += 1
	if gen["fallback_used"]:
		s["fallback"] += 1
		return
	var m: Dictionary = gen["metrics"]
	if gen.get("selector_present", false):
		s["selector"] += 1
		s["sel_count_sum"] += int(m["selector_count"])
		var fr: String = gen.get("selector_fragment", "")
		s["fragments"][fr] = int(s["fragments"].get(fr, 0)) + 1
		s["eq"] += int(m["selector_equivalent_state_count"])
		s["conseq"] += int(m["selector"].get("consequential_count", 0))
		s["ds_depth"].append(int(m["selector_downstream_depth"]))
	if gen.get("selector_dropped", false):
		s["selector_dropped"] += 1
	if gen.get("fusion_present", false):
		s["fusion"] += 1
	if gen.get("greedy_solved", false):
		s["greedy"] += 1
	s["moves"].append(int(m["intended_move_count"]))
	s["depth"].append(int(m["dependency_depth"]))
	s["inter"].append(int(m["mechanic_interaction_count"]))
	s["kinds"].append(int(m["distinct_mechanic_kinds"]))
	s["deps"].append(int(m["meaningful_dependency_count"]))
	s["attempts"].append(int(gen["attempt"]))
	s["ms"].append(ms)
	s["tiles"].append(gen["level_data"].tiles.size())
	var b: String = "%dx%d" % [gen["board_size"].x, gen["board_size"].y]
	s["boards"][b] = int(s["boards"].get(b, 0)) + 1


func _rng(a: Array) -> String:
	if a.is_empty():
		return "-"
	var lo: int = a[0]
	var hi: int = a[0]
	var sum := 0
	for v in a:
		lo = mini(lo, int(v))
		hi = maxi(hi, int(v))
		sum += int(v)
	return "%d-%d (avg %.1f)" % [lo, hi, float(sum) / float(a.size())]


func _summary(s: Dictionary, requested: int) -> String:
	var n: int = s["n"]
	var gen_ok: int = n - int(s["fallback"])
	var lines: Array = []
	lines.append("--- V5 sample: %d generated (of %d requested), clean=%d, fallbacks=%d" % [n, requested, s["ok"], s["fallback"]])
	lines.append("    selector levels: %d/%d (%.0f%%), selector_dropped=%d, avg selector count %.2f, fragments=%s, fusion levels=%d" % [
		s["selector"], n, 100.0 * float(s["selector"]) / float(maxi(n, 1)), s["selector_dropped"], float(s["sel_count_sum"]) / float(maxi(s["selector"], 1)), s["fragments"], s["fusion"]])
	lines.append("    moves %s | depth %s | deps %s | interactions %s | kinds %s" % [_rng(s["moves"]), _rng(s["depth"]), _rng(s["deps"]), _rng(s["inter"]), _rng(s["kinds"])])
	lines.append("    selector downstream depth %s | consequential wrong states %d | equivalent states %d" % [_rng(s["ds_depth"]), s["conseq"], s["eq"]])
	lines.append("    greedy-solvable accepted: %d/%d | attempts %s | gen ms %s | tiles %s | boards %s" % [s["greedy"], gen_ok, _rng(s["attempts"]), _rng(s["ms"]), _rng(s["tiles"]), s["boards"]])
	return "\n".join(lines)


func _line(n: int, gen: Dictionary, ms: int, problems: Array) -> String:
	if gen["fallback_used"]:
		return "L%d [%s] FALLBACK (V5_GENERATION_FAILED) ms=%d rejections=%d" % [n, gen.get("difficulty_band", "?"), ms, gen.get("rejections", []).size()]
	var m: Dictionary = gen["metrics"]
	var verified: int = int(gen.get("verified_optimal_moves", -1))
	return "L%d [%s] board=%dx%d seed=%d recipe=%s sel=%s x%d moves=%d opt=%s deps=%d depth=%d inter=%d kinds=%d | sel: lb=%d dep=%d inter=%d eq=%d ds=%d | greedy=%s shortcut=no(probe) attempts=%d ms=%d tiles=%d fusion=%s%s" % [
		n, gen.get("difficulty_band", "?"), gen["board_size"].x, gen["board_size"].y, gen["seed"], gen["template_id"],
		gen.get("selector_fragment", "") if gen.get("selector_present", false) else "-", int(m["selector_count"]),
		int(m["intended_move_count"]), str(verified) if verified >= 0 else "UNKNOWN", int(m["meaningful_dependency_count"]), int(m["dependency_depth"]),
		int(m["mechanic_interaction_count"]), int(m["distinct_mechanic_kinds"]), int(m["selector_load_bearing_count"]),
		int(m["selector_dependency_count"]), int(m["selector_interaction_count"]), int(m["selector_equivalent_state_count"]),
		int(m["selector_downstream_depth"]), gen.get("greedy_solved", "?"), gen["attempt"], ms, gen["level_data"].tiles.size(),
		gen.get("fusion_fragment", "") if gen.get("fusion_present", false) else "-", (" PROBLEMS=" + str(problems)) if not problems.is_empty() else ""]


## Why earlier attempts of this level were rejected: "stage: reason" histogram (first reason of each attempt).
func _rejection_report(gen: Dictionary) -> String:
	var h := {}
	for r in gen.get("rejections", []):
		var rs: Array = r.get("reasons", [])
		var key := "%s: %s" % [r["stage"], str(rs[0]).left(90) if not rs.is_empty() else "?"]
		h[key] = int(h.get(key, 0)) + 1
	var lines: Array = []
	for k in h:
		lines.append("     %dx %s" % [h[k], k])
	return "\n".join(lines)


## Aggregated rejection reasons (digits/coordinates normalised) over the whole run: hist=1.
var _hist: Dictionary = {}
var _hist_max_attempt := 999
var _dens: Dictionary = {}


var _stage_counts: Dictionary = {}


func _add_hist(gen: Dictionary) -> void:
	for r0 in gen.get("rejections", []):
		_stage_counts[r0["stage"]] = int(_stage_counts.get(r0["stage"], 0)) + 1
	for r in gen.get("rejections", []):
		if r.has("density_est"):
			var dk: String = "dens_" + ("layout_fail" if r["stage"] == "layout" else "gate_fail")
			_dens[dk] = _dens.get(dk, []) + [float(r["density_est"])]
	if gen.has("density_est"):
		_dens["dens_accepted"] = _dens.get("dens_accepted", []) + [float(gen["density_est"])]
	for r in gen.get("rejections", []):
		if int(r["attempt"]) >= _hist_max_attempt:
			continue
		var rs: Array = r.get("reasons", [])
		var txt := str(rs[0]) if not rs.is_empty() else "?"
		var rx := RegEx.new()
		rx.compile("[0-9]+")
		txt = rx.sub(txt, "#", true)
		var key := "%s: %s" % [r["stage"], txt.left(80)]
		_hist[key] = int(_hist.get(key, 0)) + 1


func _print_hist() -> void:
	var keys: Array = _hist.keys()
	keys.sort_custom(func(a, b): return _hist[a] > _hist[b])
	for dk in _dens:
		var arr: Array = _dens[dk]
		var mn := 9.0
		var mx := 0.0
		var sm := 0.0
		for v in arr:
			mn = minf(mn, v)
			mx = maxf(mx, v)
			sm += v
		print("  %s: n=%d min=%.2f avg=%.2f max=%.2f" % [dk, arr.size(), mn, sm / arr.size(), mx])
	print("--- rejection histogram (all attempts, first reason) ---")
	for k in keys.slice(0, 16):
		print("  %4d  %s" % [_hist[k], k])


## Per-atom layout failure rate: attempts that reached layout, by atom (atoms=1).
var _atom_stats: Dictionary = {}


func _add_atoms(gen: Dictionary) -> void:
	var seen: Array = []
	for r in gen.get("rejections", []):
		if r.has("atoms") and (r["stage"] == "layout" or r["stage"] == "gate"):
			seen.append([r["atoms"], r["stage"] == "layout"])
	if gen.has("atoms") and not gen["fallback_used"]:
		seen.append([gen["atoms"], false])
	for e in seen:
		for a in e[0]:
			if not _atom_stats.has(a):
				_atom_stats[a] = [0, 0]
			_atom_stats[a][0] += 1
			if e[1]:
				_atom_stats[a][1] += 1


func _print_atoms() -> void:
	var keys: Array = _atom_stats.keys()
	keys.sort()
	var parts: Array = []
	for k in keys:
		parts.append("%s %d/%d (%.0f%%)" % [k, _atom_stats[k][1], _atom_stats[k][0], 100.0 * float(_atom_stats[k][1]) / float(_atom_stats[k][0])])
	print("--- layout failure rate per atom: " + ", ".join(parts))


## Rolled vs realised Selector family (frag=1): which families the composer can actually place.
var _rolled: Dictionary = {}


func _add_rolled(n: int, gen: Dictionary, version: int) -> void:
	var fusion_rolled := not ProceduralFragmentsV3.roll_fusion_recipe(n, ProceduralSeed.rng_for_attempt(n, version, ProceduralProgressionV3.FUSION_ROLL_STREAM)).is_empty()
	var spec := ProceduralFragmentsV3.roll_selector(n, ProceduralSeed.rng_for_attempt(n, version, ProceduralFragmentsV3.SELECTOR_ROLL_STREAM), fusion_rolled)
	if spec.is_empty():
		return
	var id: String = spec["fragment"]
	if not _rolled.has(id):
		_rolled[id] = [0, 0]
	_rolled[id][0] += 1
	if gen.get("selector_present", false):
		_rolled[id][1] += 1


func _print_rolled() -> void:
	var keys: Array = _rolled.keys()
	keys.sort()
	var parts: Array = []
	for k in keys:
		parts.append("%s %d/%d" % [k, _rolled[k][1], _rolled[k][0]])
	print("--- Selector family realised/rolled: " + ", ".join(parts))
