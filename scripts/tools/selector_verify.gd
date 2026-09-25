extends Node
## Dev-only Splitter Selector QA verifier (Selector Phase S1). Never exported (scripts/tools/**).
## For each SelectorQaSet puzzle it brute-forces EVERY orientation combination through the real
## LaserSystem (4 states per Selector/Fusion, 2 per mirror) and checks:
##   * the start state is not solved
##   * exactly ONE combination solves it, and it is the authored solution
##   * the minimum tap count over solved states equals the authored optimal_moves
##   * every Selector orientation other than the solution fails (others held at the solution)
##   * a Selector replaced by a dead blocker (or removed) at the solved state loses the level
##   * the Selector's orientation changes downstream routing (>= 2 distinct beam signatures)
##   * statelessness: solving, un-solving and re-solving gives the identical result
## Run: godot --headless --path . res://scripts/tools/selector_verify.tscn


func _ready() -> void:
	var problems := 0
	for i in range(1, SelectorQaSet.COUNT + 1):
		problems += _verify(i)
	print("--- selector_verify: %d puzzle(s), %d problem(s)" % [SelectorQaSet.COUNT, problems])
	get_tree().quit()


func _tap_dist(kind: int, a: int, b: int) -> int:
	if kind == GridTypes.TileType.MIRROR or kind == GridTypes.TileType.SPLITTER or kind == GridTypes.TileType.ONE_WAY_REFLECTOR:
		return 0 if a == b else 1
	return (b - a + 4) % 4


func _signature(res: Dictionary) -> String:
	var cells := []
	for beam in res["beams"]:
		for seg in beam["segments"]:
			cells.append("%s@%d" % [str(seg), beam["color"]])
	cells.sort()
	return "|".join(cells)


func _verify(i: int) -> int:
	var bad := 0
	var gen := SelectorQaSet.get_puzzle(i)
	var level: LevelData = gen["level_data"]
	var sol: Dictionary = gen["solution_orientations"]
	var start: Dictionary = level.get_initial_tile_orientations()
	var rot := ProceduralComplexity.rotatable_types(level)
	var cells: Array = rot.keys()
	cells.sort()
	var sels: Array = []
	for p in cells:
		if rot[p] == GridTypes.TileType.SPLITTER_SELECTOR:
			sels.append(p)
	var lines: Array = []

	if LaserSystem.simulate_until_stable(level, start)["solved"]:
		lines.append("start state is already solved")
		bad += 1

	var total := 1
	var radix: Array = []
	for p in cells:
		var r := 2 if rot[p] == GridTypes.TileType.MIRROR else 4
		radix.append(r)
		total *= r
	var solved_states: Array = []
	var best := 1 << 30
	for n in range(total):
		var o: Dictionary = start.duplicate()
		var k := n
		var moves := 0
		for idx in range(cells.size()):
			var p: Vector2i = cells[idx]
			var v: int = k % radix[idx]
			k /= radix[idx]
			o[p] = v
			moves += _tap_dist(rot[p], start[p], v)
		if LaserSystem.simulate_until_stable(level, o)["solved"]:
			solved_states.append(o)
			best = mini(best, moves)
	var authored: Dictionary = start.duplicate()
	for p in sol:
		authored[p] = sol[p]
	if solved_states.size() != 1 or solved_states[0] != authored:
		lines.append("solved combinations: %d (expected exactly the authored one)" % solved_states.size())
		bad += 1
	if best != level.optimal_moves:
		lines.append("min moves %d != authored %d" % [best, level.optimal_moves])
		bad += 1

	var sig_set := {}
	for sp in sels:
		for v in range(4):
			var o2: Dictionary = authored.duplicate()
			o2[sp] = v
			var res := LaserSystem.simulate_until_stable(level, o2)
			sig_set[_signature(res)] = true
			if v != authored[sp] and res["solved"]:
				lines.append("selector %s orientation %d also solves" % [sp, v])
				bad += 1
	if sels.is_empty() or sig_set.size() < 2:
		lines.append("selector orientation does not change routing")
		bad += 1

	for mode in ["dead", "removed"]:
		var tiles: Array[TilePlacement] = []
		for t in level.tiles:
			if t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
				if mode == "dead":
					tiles.append(TilePlacement.make_blocker(t.position))
			else:
				tiles.append(t)
		var lv2 := LevelData.new()
		lv2.grid_width = level.grid_width
		lv2.grid_height = level.grid_height
		lv2.tiles = tiles
		if LaserSystem.simulate_until_stable(lv2, authored)["solved"]:
			lines.append("selector %s still solves (not load-bearing)" % mode)
			bad += 1

	var first := LaserSystem.simulate_until_stable(level, authored)
	var wrong: Dictionary = authored.duplicate()
	for sp in sels:
		wrong[sp] = (int(authored[sp]) + 1) % 4
	LaserSystem.simulate_until_stable(level, wrong)
	var again := LaserSystem.simulate_until_stable(level, authored)
	if _signature(first) != _signature(again) or first["solved"] != again["solved"] or not first["solved"]:
		lines.append("stateless re-solve mismatch")
		bad += 1

	print("S%d %-10s states=%d solved_states=%d min_moves=%d authored=%d signatures=%d converged=%s %s" % [
		i, gen["name"], total, solved_states.size(), best, level.optimal_moves, sig_set.size(),
		str(first["converged"]), "OK" if bad == 0 else "FAIL " + "; ".join(lines)])
	return bad
