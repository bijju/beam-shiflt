extends Node
## Dev-only Fusion Phase 2 verification tool (D100). Never exported (scripts/tools/**).
##
## For generated V4 levels that contain Fusion it runs the shortcut/bypass experiments the runtime
## generator cannot afford, and - where the state space is small enough - an EXACT search:
##   * bypass: the Fusion node removed (solved state) must NOT solve the level
##   * omitted input: per-input cut (ProceduralFusionCheck) must NOT solve the level
##   * raw Prism / WHITE shortcut: no required WHITE target may sit downstream of a Fusion node;
##     a Prism removed must not solve; remote emitters must carry an explicit (non-WHITE) colour
##   * gate bypass / direct target: exact search over EVERY tile orientation (Fusion is 4-state, so the
##     binary LevelSolver cannot be used) -> PROVEN OPTIMAL when the space fits, else a wide probe
##     (STRUCTURALLY VALID / PROBE PASSED - never called "proven").
## Run: godot --headless --path . res://scripts/tools/fusion_verify.tscn -- window=401,700 max=4 states=40000
##   levels=250,410   explicit levels (instead of a window)     probe=1 (also run the wide probe)

const BUDGET_MSEC := 55000


func _ready() -> void:
	var levels: Array = []
	var window := Vector2i(401, 700)
	var max_levels := 4
	var max_states := 40000
	var wide_probe := true
	var plain_only := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("window="):
			var p := arg.substr(7).split(",")
			window = Vector2i(int(p[0]), int(p[1]))
		elif arg.begins_with("max="):
			max_levels = int(arg.substr(4))
		elif arg.begins_with("states="):
			max_states = int(arg.substr(7))
		elif arg == "probe=0":
			wide_probe = false
		elif arg == "plain=1":
			plain_only = true
	var t0 := Time.get_ticks_msec()
	var version := ProceduralLevelGenerator.GENERATOR_VERSION_V4
	var checked := 0
	var problems := 0
	var candidates: Array = levels if not levels.is_empty() else range(window.x, window.y + 1)
	for n in candidates:
		if Time.get_ticks_msec() - t0 > BUDGET_MSEC:
			print("QA_BUDGET_EXCEEDED at level %d" % n)
			break
		if checked >= max_levels:
			break
		var gen := ProceduralLevelGenerator.generate(n, version)
		var frag: String = gen.get("fusion_fragment", "")
		if (frag == "") != plain_only:
			continue
		var level: LevelData = gen["level_data"]
		var rot := ProceduralComplexity.rotatable_types(level)
		var states := 1
		for p in rot:
			states *= 4 if rot[p] == GridTypes.TileType.FUSION else 2
		if levels.is_empty() and max_states > 0 and states > max_states:
			continue
		checked += 1
		problems += _verify(n, gen, frag, states, max_states, wide_probe)
	print("--- fusion_verify: %d levels, %d problem(s), elapsed_msec=%d" % [checked, problems, Time.get_ticks_msec() - t0])
	get_tree().quit()


func _verify(n: int, gen: Dictionary, frag: String, states: int, max_states: int, wide_probe: bool) -> int:
	var bad := 0
	var level: LevelData = gen["level_data"]
	var solution: Dictionary = gen["solution_orientations"]
	var authored: Dictionary = level.get_initial_tile_orientations()
	var solved: Dictionary = authored.duplicate()
	for p in solution:
		solved[p] = solution[p]
	var lines: Array = []

	# 1. bypass: remove every Fusion node (an empty cell) in the solved state.
	# Phase 3 (D101): the COUNTED test is a DEAD node (a blocker: it still absorbs beams, emits nothing) -
	# the only counterfactual a player could ever reach. An empty cell would let the node's raw input
	# beams run straight on through it into a collinear consumer, a state no rotation can produce;
	# it is printed for information only (the exact search below is what proves/refutes a real bypass).
	var no_fusion := _without_types(level, [GridTypes.TileType.FUSION])
	var r1 := LaserSystem.simulate_until_stable(no_fusion, solved)
	var dead := level.duplicate()
	var dead_tiles: Array[TilePlacement] = []
	for t in level.tiles:
		dead_tiles.append(TilePlacement.make_blocker(t.position) if t.tile_type == GridTypes.TileType.FUSION else t)
	dead.tiles = dead_tiles
	var r1b := LaserSystem.simulate_until_stable(dead, solved)
	lines.append("bypass(dead node)=%s ; info: node-as-empty-cell=%s" % ["SOLVED!" if r1b["solved"] else "unsolved", "solved" if r1["solved"] else "unsolved"])
	if r1b["solved"]:
		bad += 1

	# 2. every Prism removed must not solve (a Prism carrying the level must be load-bearing when present).
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.PRISM:
			var r2 := LaserSystem.simulate_until_stable(_without_positions(level, [t.position]), solved)
			lines.append("prism@%s removed=%s" % [t.position, "SOLVED!" if r2["solved"] else "unsolved"])
			if r2["solved"]:
				bad += 1

	# 3. WHITE / colour bypass: required WHITE targets, remote colours.
	var white_targets := 0
	for t in level.tiles:
		if t.tile_type == GridTypes.TileType.TARGET and t.required and t.color == GridTypes.BeamColor.WHITE:
			white_targets += 1
		if t.tile_type == GridTypes.TileType.REMOTE_EMITTER and t.color == GridTypes.BeamColor.WHITE:
			lines.append("WHITE remote emitter at %s" % t.position)
			bad += 1
	lines.append("required WHITE targets=%d" % white_targets)
	var fr: Dictionary = gen.get("fusion_report", {})
	for f in fr.get("fusions", []):
		lines.append("fusion@%s fused=%d inputs=%s required=%d/%d consumer=%s feedback=%s" % [f["pos"], f["fused"], f["inputs"], f["inputs_required"], f["inputs"].size(), f["consumer"], f["feedback"]])
		if f["inputs_required"] != f["inputs"].size() or f["feedback"] or f["consumer"] == "":
			bad += 1
	if white_targets > 0:
		# A WHITE target accepts any beam: it must not depend on a Fusion output.
		var solved_res := LaserSystem.simulate_until_stable(level, solved)
		var lost: Array = []
		var r3 := LaserSystem.simulate_until_stable(no_fusion, solved)
		for tp in solved_res["activated_targets"]:
			if not r3["activated_targets"].has(tp):
				lost.append(tp)
		for tp in lost:
			for t in level.tiles:
				if t.position == tp and t.color == GridTypes.BeamColor.WHITE:
					lines.append("WHITE target %s depends on a Fusion output (accepts any colour)" % tp)
					bad += 1

	# 4. wide probe (bounded beam search, fewer moves than intended?).
	if wide_probe:
		var probe := ProceduralShortcutProbe.probe(level, int(gen["metrics"]["intended_move_count"]), solution, 4000, 40)
		lines.append("wide probe: shortcut=%s sims=%d exhausted=%s" % [probe["shortcut"], probe["sims"], probe["exhausted"]])
		if probe["shortcut"] and probe.has("orientations"):
			var pd: Array = []
			for p in probe["orientations"]:
				if probe["orientations"][p] != solved[p]:
					pd.append("%s: start %s intended %s shortcut %s" % [p, authored[p], solved[p], probe["orientations"][p]])
			lines.append("probe shortcut (depth %d) differs from intended at: %s" % [probe["depth"], pd])
		if probe["shortcut"]:
			bad += 1

	# 5. exact search over every orientation (Fusion 4-state).
	var exact := exact_search(level, max_states)
	if exact["status"] == "SOLVED":
		var verdict := "PROVEN OPTIMAL" if exact["optimal"] == int(gen["metrics"]["intended_move_count"]) else "SHORTCUT/MISMATCH"
		lines.append("exact: %s optimal=%d intended=%d shortest_solutions=%d states=%d -> %s" % [exact["status"], exact["optimal"], gen["metrics"]["intended_move_count"], exact["shortest_count"], exact["states"], verdict])
		if verdict != "PROVEN OPTIMAL":
			bad += 1
		if verdict != "PROVEN OPTIMAL":
			var diff: Array = []
			for p in exact["state"]:
				if exact["state"][p] != solved[p]:
					diff.append("%s: start %s intended %s shortcut %s" % [p, authored[p], solved[p], exact["state"][p]])
			lines.append("shortcut differs from intended at: %s" % [diff])
	else:
		lines.append("exact: %s (%d states) - STRUCTURALLY VALID / PROBE PASSED only" % [exact["status"], states])
	print("L%d %s %s moves=%d tiles=%d rotatable_states=%d %s" % [n, frag, gen["template_id"], gen["metrics"]["intended_move_count"], level.tiles.size(), states, "OK" if bad == 0 else "PROBLEMS=%d" % bad])
	for l in lines:
		print("     " + l)
	return bad


## Exhaustive search over every rotatable tile's orientations (binary tiles 2 values, Fusion 4).
## cost = flips (binary) + clockwise taps (Fusion) from the authored start.
static func exact_search(level: LevelData, max_states: int) -> Dictionary:
	var rot := ProceduralComplexity.rotatable_types(level)
	var keys: Array = rot.keys()
	keys.sort()
	var radix: Array = []
	var total := 1
	for p in keys:
		var r := 4 if rot[p] == GridTypes.TileType.FUSION else 2
		radix.append(r)
		total *= r
	if total > max_states:
		return {"status": "UNKNOWN", "states": total}
	var start: Dictionary = level.get_initial_tile_orientations()
	var best := 1 << 30
	var best_count := 0
	var best_state: Dictionary = {}
	var counter: Array = []
	counter.resize(keys.size())
	counter.fill(0)
	for _s in range(total):
		var orient: Dictionary = start.duplicate()
		var cost := 0
		for i in range(keys.size()):
			var p: Vector2i = keys[i]
			orient[p] = counter[i]
			if rot[p] == GridTypes.TileType.FUSION:
				cost += (int(counter[i]) - int(start[p]) + 4) % 4
			elif int(counter[i]) != int(start[p]):
				cost += 1
		if cost <= best and LaserSystem.simulate_until_stable(level, orient)["solved"]:
			if cost < best:
				best = cost
				best_count = 1
				best_state = orient.duplicate()
			else:
				best_count += 1
		# increment the mixed-radix counter
		var j := 0
		while j < keys.size():
			counter[j] = int(counter[j]) + 1
			if int(counter[j]) < radix[j]:
				break
			counter[j] = 0
			j += 1
	if best == 1 << 30:
		return {"status": "UNSOLVABLE", "states": total}
	return {"status": "SOLVED", "optimal": best, "shortest_count": best_count, "states": total, "state": best_state}


static func _without_types(level: LevelData, types: Array) -> LevelData:
	var copy: LevelData = level.duplicate()
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if not types.has(t.tile_type):
			kept.append(t)
	copy.tiles = kept
	return copy


static func _without_positions(level: LevelData, positions: Array) -> LevelData:
	var copy: LevelData = level.duplicate()
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if not positions.has(t.position):
			kept.append(t)
	copy.tiles = kept
	return copy
