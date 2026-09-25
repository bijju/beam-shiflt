extends Node
## Dev-only generator-V5 verifier (Selector Phase S3, D110). Never exported (scripts/tools/**).
## LevelSolver models neither 4-state Selectors nor Fusion, so this tool brings its own exact search. It never
## claims more than it proved: a level's optimum is "PROVEN" only when the search exhausted every state cheaper
## than the intended solution inside the state budget; otherwise it says UNKNOWN (with the reason).
##
## Per level (default: the 21 anchor levels):
##   1. structure: start unsolved, intended solves, columns, determinism (two generations identical)
##   2. Selector brute force (independent of ProceduralSelectorCheck): every Selector held at each of its 4
##      orientations with all else solved - exactly ONE (the intended) solves; a dead blocker loses the level
##   3. exact search: breadth-first over states reachable by tapping only tiles a beam CURRENTLY touches. This is
##      exact for the shortest solution: in any unsolved state at least one tile that still differs from a solved
##      target state is touched (untouched tiles cannot influence the simulation), so a shortest path never needs
##      to tap an untouched tile.
## Run: godot --headless --path . res://scripts/tools/v5_verify.tscn -- levels=2001,2050 states=60000 secs=12 budget=55000

const DEFAULT_LEVELS := [2001, 2050, 2100, 2150, 2200, 2250, 2300, 2350, 2400, 2450, 2500, 2550, 2600, 2650, 2700, 2750, 2800, 2850, 2900, 2950, 3000]


func _ready() -> void:
	var levels: Array = DEFAULT_LEVELS.duplicate()
	var max_states := 60000
	var secs := 12
	var budget := 55000
	var version := ProceduralLevelGenerator.GENERATOR_VERSION_V5
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("levels="):
			levels.clear()
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("states="):
			max_states = int(arg.substr(7))
		elif arg.begins_with("secs="):
			secs = int(arg.substr(5))
		elif arg.begins_with("budget="):
			budget = int(arg.substr(7))
		elif arg.begins_with("version="):
			version = int(arg.substr(8))
	var t0 := Time.get_ticks_msec()
	var proven := 0
	var unknown := 0
	var bad := 0
	for n in levels:
		if Time.get_ticks_msec() - t0 > budget:
			print("QA_BUDGET_EXCEEDED before level %d" % n)
			break
		var gen := ProceduralLevelGenerator.generate(n, version)
		var r := _verify(n, gen, max_states, secs)
		bad += int(r["problems"].size() > 0)
		if r["status"] == "PROVEN":
			proven += 1
		else:
			unknown += 1
		var sel_count := 0 if gen["fallback_used"] else int(gen["metrics"]["selector_count"])
		print("L%d [%s] sel=%s x%d intended=%d exact=%s (%s) states=%d sel_check=%s%s" % [n, gen.get("difficulty_band", "?"), gen.get("selector_fragment", "-") if gen.get("selector_present", false) else "-",
			sel_count, int(gen["intended_moves"]), r["optimal"], r["status"], r["states"], r["sel_summary"],
			(" PROBLEMS=" + str(r["problems"])) if not r["problems"].is_empty() else ""])
	print("--- v5_verify: proven=%d unknown=%d with_problems=%d elapsed=%d ms" % [proven, unknown, bad, Time.get_ticks_msec() - t0])
	get_tree().quit()


func _verify(n: int, gen: Dictionary, max_states: int, secs: int) -> Dictionary:
	var out := {"problems": [], "status": "UNKNOWN", "optimal": "UNKNOWN", "states": 0, "sel_summary": "-"}
	if gen["fallback_used"]:
		out["problems"].append("FALLBACK")
		return out
	var level: LevelData = gen["level_data"]
	var again := ProceduralLevelGenerator.generate(n, int(gen["generator_version"]))
	if again["seed"] != gen["seed"] or ProceduralBoardV3.ascii(again["level_data"]) != ProceduralBoardV3.ascii(level) or again["solution_orientations"] != gen["solution_orientations"]:
		out["problems"].append("NOT DETERMINISTIC")
	var start: Dictionary = level.get_initial_tile_orientations()
	if LaserSystem.simulate_until_stable(level, start)["solved"]:
		out["problems"].append("start already solved")
	var solved: Dictionary = start.duplicate()
	for p in gen["solution_orientations"]:
		solved[p] = gen["solution_orientations"][p]
	if not LaserSystem.simulate_until_stable(level, solved)["solved"]:
		out["problems"].append("intended solution does not solve")
	if level.grid_width > GridManager.MAX_COLUMNS:
		out["problems"].append("columns > MAX_COLUMNS")
	var rot := ProceduralComplexity.rotatable_types(level)

	# 2. Selector brute force.
	var sel_notes: Array = []
	for pos in rot:
		if rot[pos] != GridTypes.TileType.SPLITTER_SELECTOR:
			continue
		var solving := 0
		for o in range(4):
			var trial: Dictionary = solved.duplicate()
			trial[pos] = o
			if LaserSystem.simulate_until_stable(level, trial)["solved"]:
				solving += 1
		var dead: LevelData = level.duplicate()
		var kept: Array[TilePlacement] = []
		for t in level.tiles:
			kept.append(TilePlacement.make_blocker(pos) if t.position == pos else t)
		dead.tiles = kept
		var dead_solves: bool = LaserSystem.simulate_until_stable(dead, solved)["solved"]
		if solving != 1:
			out["problems"].append("selector %s: %d orientations solve" % [pos, solving])
		if dead_solves:
			out["problems"].append("selector %s not load-bearing" % pos)
		sel_notes.append("%s:%d-taps%s" % [pos, posmod(int(solved[pos]) - int(start[pos]), 4), "" if solving == 1 and not dead_solves else "!"])
	out["sel_summary"] = ",".join(sel_notes) if not sel_notes.is_empty() else "-"

	# 3. exact search (touched-BFS).
	var intended: int = int(gen["metrics"]["intended_move_count"])
	var res := _exact(level, rot, start, intended, max_states, secs)
	out["states"] = res["states"]
	if res["found"] >= 0:
		out["optimal"] = str(res["found"])
		out["status"] = "SHORTCUT (cheaper than intended)"
		out["problems"].append("solver found %d < intended %d" % [res["found"], intended])
	elif res["complete"]:
		out["optimal"] = str(intended)
		out["status"] = "PROVEN"
	else:
		out["status"] = "UNKNOWN (%s)" % res["why"]
	return out


## BFS by tap count over states reachable via taps of currently-touched tiles, up to depth `intended - 1`
## (a solution cheaper than intended). found = depth of a cheaper solution, -1 if none;
## complete = every state cheaper than intended was visited within the budgets.
func _exact(level: LevelData, rot: Dictionary, start: Dictionary, intended: int, max_states: int, secs: int) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var keys: Array = rot.keys()
	keys.sort()
	var seen := {_key(start, keys): true}
	var frontier: Array = [start]
	var states := 1
	for depth in range(1, intended):
		var next: Array = []
		for o in frontier:
			var res: Dictionary = LaserSystem.simulate_until_stable(level, o)
			var touched := {}
			for beam in res["beams"]:
				touched.merge(ProceduralComplexity.touched_cells(beam))
			for pos in keys:
				if not touched.has(pos):
					continue
				var o2: Dictionary = o.duplicate()
				o2[pos] = ProceduralComplexity.tap_orientation(rot[pos], o2[pos])
				var k := _key(o2, keys)
				if seen.has(k):
					continue
				seen[k] = true
				states += 1
				if LaserSystem.simulate_until_stable(level, o2)["solved"]:
					return {"found": depth, "complete": false, "states": states, "why": ""}
				next.append(o2)
				if states >= max_states:
					return {"found": -1, "complete": false, "states": states, "why": "state budget %d at depth %d" % [max_states, depth]}
			if Time.get_ticks_msec() - t0 > secs * 1000:
				return {"found": -1, "complete": false, "states": states, "why": "time budget %d s at depth %d" % [secs, depth]}
		if next.is_empty():
			break
		frontier = next
	return {"found": -1, "complete": true, "states": states, "why": ""}


func _key(o: Dictionary, keys: Array) -> String:
	var s := ""
	for p in keys:
		s += str(int(o[p]))
	return s
