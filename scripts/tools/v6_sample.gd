extends Node
## Dev-only generator-V6 sample / bulk-QA tool (Stages C-E, D125). Never exported (scripts/tools/**).
## Every run has a hard budget (default 55 s) and prints QA_BUDGET_EXCEEDED instead of running on.
##
## Run: godot --headless --path . res://scripts/tools/v6_sample.tscn -- <args>
##   levels=1,50,701         explicit levels (default: the 42 fingerprint anchors)
##   from=1 to=4000 stride=1 a window: every `stride`-th level in [from, to]
##   ascii=1                 print each reported level's start board
##   quiet=1                 only the summary / validation
##   validate=1              (default) independent validation of every generated level (structure + real replay)
##   json=<abs path>         write the per-level records + the aggregate report as JSON
##   budget=55000            milliseconds
## Reported per level: band, archetype, board, atoms, moves, metrics, attempts, fallback, Phase count, time.
## Validation (independent of the generator's own gates): structural validity, mobile grid limits, pairing of
## portals / switches-gates / receivers-remotes, Phase / Selector / Fusion band rules, the known solution replayed
## through the real LaserSystem (solved, no hazard hit, no loop) and through a real GridManager-free simulation.

const ANCHORS := [1, 10, 20, 30, 40, 49, 50, 75, 100, 150, 200, 201, 300, 400, 500, 600, 680, 700, 701, 720, 800, 900, 1000, 1200, 1400, 1600, 1800, 1999, 2000, 2001, 2200, 2400, 2600, 2800, 3000, 3001, 3200, 3400, 3600, 3800, 3999, 4000]

var _budget := 55000


func _ready() -> void:
	var levels: Array = ANCHORS.duplicate()
	var from := 0
	var to := 0
	var stride := 1
	var ascii := false
	var quiet := false
	var hist := false
	var perf := false
	var json_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("from="):
			from = int(arg.substr(5))
		elif arg.begins_with("to="):
			to = int(arg.substr(3))
		elif arg.begins_with("stride="):
			stride = maxi(1, int(arg.substr(7)))
		elif arg == "ascii=1":
			ascii = true
		elif arg == "perf=1":
			perf = true
		elif arg == "hist=1":
			hist = true
		elif arg == "quiet=1":
			quiet = true
		elif arg.begins_with("json="):
			json_path = arg.substr(5)
		elif arg.begins_with("budget="):
			_budget = int(arg.substr(7))
	if from > 0:
		levels.clear()
		var n := from
		while n <= (to if to > 0 else from):
			levels.append(n)
			n += stride
	var t0 := Time.get_ticks_msec()
	var records: Array = []
	var agg := {"generated": 0, "fallback": 0, "validation_failures": 0, "attempts_sum": 0, "attempts_max": 0, "ms_sum": 0, "ms_max": 0, "phase_levels": 0, "selector_levels": 0, "fusion_levels": 0}
	for n in levels:
		if Time.get_ticks_msec() - t0 > _budget:
			print("QA_BUDGET_EXCEEDED after %d of %d levels" % [records.size(), levels.size()])
			break
		ProceduralProgressionV3.phase_us.clear()
		var g0 := Time.get_ticks_usec()
		var r := ProceduralLevelGenerator.generate(int(n), ProceduralLevelGenerator.GENERATOR_VERSION_V6)
		var ms := (Time.get_ticks_usec() - g0) / 1000
		var rec := _record(int(n), r, ms)
		if perf:
			var parts: Array[String] = []
			for k in ProceduralProgressionV3.phase_us:
				parts.append("%s=%d" % [k, int(ProceduralProgressionV3.phase_us[k]) / 1000])
			print("PERF L%d total=%dms attempts=%d  %s" % [int(n), ms, int(r.get("attempt", 0)) + 1, " ".join(parts)])
		var problems := validate(int(n), r)
		rec["problems"] = problems
		records.append(rec)
		agg["generated"] += 1
		agg["attempts_sum"] += int(r.get("attempt", 0))
		agg["attempts_max"] = maxi(agg["attempts_max"], int(r.get("attempt", 0)))
		agg["ms_sum"] += ms
		agg["ms_max"] = maxi(agg["ms_max"], ms)
		if r.get("fallback_used", false):
			agg["fallback"] += 1
		if not problems.is_empty():
			agg["validation_failures"] += 1
		if int(rec["phase_count"]) > 0:
			agg["phase_levels"] += 1
		if rec["selector"]:
			agg["selector_levels"] += 1
		if rec["fusion"]:
			agg["fusion_levels"] += 1
		if not quiet or not problems.is_empty():
			print(_line(rec))
			if not problems.is_empty():
				print("   PROBLEMS: %s" % "; ".join(problems))
				if r.get("fallback_used", false):
					print("   REJECTIONS: %s" % rejection_histogram(r))
			if hist and not r.get("rejections", []).is_empty():
				print("   REJECTIONS: %s" % rejection_histogram(r))
			if ascii:
				print((r["ascii"] if r.has("ascii") else ProceduralBoardV3.ascii(r["level_data"])))
	print("V6_SUMMARY generated=%d fallback=%d validation_failures=%d attempts_avg=%.2f attempts_max=%d ms_avg=%d ms_max=%d phase=%d selector=%d fusion=%d total_ms=%d" % [
		agg["generated"], agg["fallback"], agg["validation_failures"], float(agg["attempts_sum"]) / maxf(1.0, float(agg["generated"])), agg["attempts_max"],
		int(float(agg["ms_sum"]) / maxf(1.0, float(agg["generated"]))), agg["ms_max"], agg["phase_levels"], agg["selector_levels"], agg["fusion_levels"], Time.get_ticks_msec() - t0])
	if json_path != "":
		var f := FileAccess.open(json_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"aggregate": agg, "records": records}, "\t"))
		f.close()
	get_tree().quit(1 if agg["validation_failures"] > 0 or agg["fallback"] > 0 else 0)


func _record(n: int, r: Dictionary, ms: int) -> Dictionary:
	var ld: LevelData = r["level_data"]
	var m: Dictionary = r.get("metrics", {})
	var types := {}
	var rotatable := 0
	var emitters := 0
	var phase_count := 0
	var selectors := 0
	var fusions := 0
	for t in ld.tiles:
		types[t.tile_type] = int(types.get(t.tile_type, 0)) + 1
		if t.rotatable and t.tile_type in [GridTypes.TileType.MIRROR, GridTypes.TileType.SPLITTER, GridTypes.TileType.ONE_WAY_REFLECTOR, GridTypes.TileType.FUSION, GridTypes.TileType.SPLITTER_SELECTOR, GridTypes.TileType.PHASE_SHIFTER]:
			rotatable += 1
		if t.tile_type == GridTypes.TileType.EMITTER or t.tile_type == GridTypes.TileType.REMOTE_EMITTER:
			emitters += 1
		if t.tile_type == GridTypes.TileType.PHASE_SHIFTER:
			phase_count += 1
		elif t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			selectors += 1
		elif t.tile_type == GridTypes.TileType.FUSION:
			fusions += 1
	return {
		"level": n, "band": ProceduralContractV6.band_name(n), "code": ProceduralContractV6.band_code(n), "tier": ProceduralContractV6.tier(n),
		"archetype": r.get("v6_archetype", ""), "challenge": r.get("v6_challenge", false), "milestone": r.get("v6_milestone", false), "relief": r.get("v6_relief", false),
		"board": "%dx%d" % [ld.grid_width, ld.grid_height], "w": ld.grid_width, "h": ld.grid_height, "tiles": ld.tiles.size(), "rotatable": rotatable, "emitters": emitters,
		"atoms": "+".join(r.get("atoms", [])), "moves": int(r.get("intended_moves", 0)), "target_moves": int(r.get("v6_target_moves", 0)),
		"deps": int(m.get("meaningful_dependency_count", 0)), "depth": int(m.get("dependency_depth", 0)), "kinds": int(m.get("distinct_mechanic_kinds", 0)),
		"attempt": int(r.get("attempt", 0)), "fallback": bool(r.get("fallback_used", false)), "ms": ms,
		"phase_count": phase_count, "selector": selectors > 0, "selector_count": selectors, "fusion": fusions > 0, "hazards": int(r.get("hazard_count", 0)),
		"band_demoted": bool(r.get("band_demoted", false)), "moves_below_band": bool(r.get("moves_below_band", false)), "greedy_accepted": bool(r.get("greedy_accepted", false)),
		"phase_dropped": bool(r.get("phase_dropped", false)), "budget": int(r.get("v6_budget", 0)), "budget_points": int(r.get("budget_points", 0)),
		"fingerprint": GeneratorFingerprint.fingerprint(r, 6).substr(0, 16),
	}


func _line(rec: Dictionary) -> String:
	return "L%-4d %-3s %-13s %-5s mv=%2d/%2d dep=%d dp=%d k=%d tiles=%2d rot=%2d P=%d S=%d F=%s a=%d %dms %s%s%s%s [%s] %s" % [
		rec["level"], rec["code"], rec["archetype"], rec["board"], rec["moves"], rec["target_moves"], rec["deps"], rec["depth"], rec["kinds"], rec["tiles"], rec["rotatable"],
		rec["phase_count"], rec["selector_count"], "y" if rec["fusion"] else "n", rec["attempt"], rec["ms"],
		"CH " if rec["challenge"] else "", "MS " if rec["milestone"] else "", "RL " if rec["relief"] else "", "FALLBACK " if rec["fallback"] else "", rec["atoms"], rec["fingerprint"]]


## Independent validation of one generated level. Returns the list of problems (empty = valid).
static func validate(n: int, r: Dictionary) -> Array[String]:
	var p: Array[String] = []
	var ld: LevelData = r["level_data"]
	if not ProceduralContractV6.is_valid_level(n):
		p.append("level outside 1..%d" % ProceduralContractV6.MAX_LEVEL)
	if r.get("fallback_used", false):
		p.append("V2 fallback used")
	if ld.grid_width > GridManager.MAX_COLUMNS or ld.grid_width < 3 or ld.grid_height < 3:
		p.append("board %dx%d outside the mobile limits" % [ld.grid_width, ld.grid_height])
	var comfort: Dictionary = GridManager.is_board_profile_comfortable(ld.grid_width, ld.grid_height, ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE)
	if not comfort["comfortable"]:
		p.append("board not comfortable: %s" % comfort["reason"])
	var seen := {}
	var emitters := 0
	var targets := 0
	var portals: Dictionary = {}
	var switches: Dictionary = {}
	var gates: Dictionary = {}
	var receivers: Dictionary = {}
	var remotes: Dictionary = {}
	var phase := 0
	var selector := 0
	var fusion := 0
	for t in ld.tiles:
		if t.position.x < 0 or t.position.y < 0 or t.position.x >= ld.grid_width or t.position.y >= ld.grid_height:
			p.append("tile out of bounds %s" % t.position)
		if seen.has(t.position):
			p.append("duplicate tile at %s" % t.position)
		seen[t.position] = true
		match t.tile_type:
			GridTypes.TileType.EMITTER:
				emitters += 1
			GridTypes.TileType.TARGET:
				if t.required:
					targets += 1
			GridTypes.TileType.PORTAL:
				portals[t.pair_id] = int(portals.get(t.pair_id, 0)) + 1
			GridTypes.TileType.SWITCH:
				switches[t.gate_id] = true
			GridTypes.TileType.GATE:
				gates[t.gate_id] = true
			GridTypes.TileType.BEAM_RECEIVER:
				receivers[t.link_id] = true
			GridTypes.TileType.REMOTE_EMITTER:
				remotes[t.link_id] = true
			GridTypes.TileType.PHASE_SHIFTER:
				phase += 1
			GridTypes.TileType.SPLITTER_SELECTOR:
				selector += 1
			GridTypes.TileType.FUSION:
				fusion += 1
	if emitters == 0:
		p.append("no emitter")
	if targets == 0:
		p.append("no required target")
	for k in portals:
		if portals[k] != 2:
			p.append("portal pair %s has %d ends" % [k, portals[k]])
	for k in switches:
		if not gates.has(k):
			p.append("switch %s has no gate" % k)
	for k in gates:
		if not switches.has(k):
			p.append("gate %s has no switch" % k)
	for k in receivers:
		if not remotes.has(k):
			p.append("receiver %s has no remote" % k)
	for k in remotes:
		if not receivers.has(k):
			p.append("remote %s has no receiver" % k)
	# Band rules: no mechanic before its introduction level.
	if phase > 0 and n < ProceduralContractV6.PHASE_FIRST_LEVEL:
		p.append("Phase before Level 701")
	if selector > 0 and n < ProceduralContractV6.SELECTOR_FIRST_LEVEL:
		p.append("Selector before Level 2001")
	if fusion > 0 and n < ProceduralContractV6.FUSION_FIRST_LEVEL:
		p.append("Fusion before Level 401")
	if selector > 0 and phase > 0 and n < ProceduralContractV6.SELECTOR_PHASE_FIRST:
		p.append("Selector + Phase before Level 2401")
	if selector > 0 and fusion > 0 and n < ProceduralContractV6.SELECTOR_FUSION_FIRST:
		p.append("Selector + Fusion before Level 2601")
	var has_kind := func(tt: int) -> bool:
		for t in ld.tiles:
			if t.tile_type == tt:
				return true
		return false
	var gate_on_board: bool = has_kind.call(GridTypes.TileType.GATE)
	if gate_on_board and n < 50:
		p.append("switch/gate before Level 50")
	if has_kind.call(GridTypes.TileType.PRISM) and n < 101:
		p.append("prism before Level 101")
	if has_kind.call(GridTypes.TileType.ONE_WAY_REFLECTOR) and n < 151:
		p.append("one-way before Level 151")
	if has_kind.call(GridTypes.TileType.BEAM_RECEIVER) and n < 201:
		p.append("receiver before Level 201")
	if has_kind.call(GridTypes.TileType.PORTAL) and n < 41:
		p.append("portal before Level 41")
	if has_kind.call(GridTypes.TileType.FILTER) and n < 31 and n >= 1:
		p.append("filter before Level 31")
	if has_kind.call(GridTypes.TileType.SPLITTER) and n < 21:
		p.append("splitter before Level 21")
	if has_kind.call(GridTypes.TileType.HAZARD) and n < 76:
		p.append("hazard before Level 76")
	# The known solution replayed through the real simulation.
	var authored: Dictionary = ld.get_initial_tile_orientations()
	var solved: Dictionary = authored.duplicate()
	var sol: Dictionary = r.get("solution_orientations", {})
	for pos in sol:
		if not authored.has(pos):
			p.append("solution names a non-rotatable / missing tile at %s" % pos)
		solved[pos] = sol[pos]
	var res: Dictionary = LaserSystem.simulate_until_stable(ld, solved)
	if not res["solved"]:
		p.append("known solution does not solve")
	if res["looped"]:
		p.append("known solution loops")
	if res.get("hazard_hit", false):
		p.append("known solution hits a hazard")
	# Phase determinism: every Phase Shifter in the SOLVED state is met in PHASE A first (the straight beam) and then in PHASE B
	# (the reflected branch) - the documented LIFO ordering the gadget relies on, checked on the real simulation, not assumed.
	for t in ld.tiles:
		if t.tile_type != GridTypes.TileType.PHASE_SHIFTER:
			continue
		var st: Array = res.get("phase_in_states", {}).get(t.position, [])
		if st.size() < 2 or int(st[0]) != GridTypes.PHASE_A or int(st[1]) != GridTypes.PHASE_B:
			p.append("Phase Shifter at %s is not met A then B in the solved state (%s)" % [t.position, st])
	if LaserSystem.simulate_until_stable(ld, authored)["solved"]:
		p.append("start state already solved")
	var moves := 0
	var four := {}
	for t in ld.tiles:
		if t.tile_type == GridTypes.TileType.FUSION or t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			four[t.position] = true
	for pos in sol:
		if authored.get(pos, -1) != sol[pos]:
			moves += posmod(int(sol[pos]) - int(authored[pos]), 4) if four.has(pos) else 1
	if moves != int(r.get("intended_moves", -1)) and not r.get("fallback_used", false):
		p.append("intended_moves %d != replayed move count %d" % [int(r.get("intended_moves", -1)), moves])
	if moves < 1 or moves > 60:
		p.append("insane move count %d" % moves)
	return p


## Rejection histogram of one generation (stage + first reason), for diagnosing fallbacks.
static func rejection_histogram(r: Dictionary) -> String:
	var h := {}
	for rj in r.get("rejections", []):
		var reasons: Array = rj.get("reasons", [])
		var key := "%s: %s" % [rj.get("stage", "?"), str(reasons[0]) if not reasons.is_empty() else "?"]
		h[key] = int(h.get(key, 0)) + 1
	var out: Array[String] = []
	var keys := h.keys()
	keys.sort_custom(func(a, b): return h[a] > h[b])
	for k in keys.slice(0, 6):
		out.append("%dx %s" % [h[k], k])
	return " | ".join(out)
