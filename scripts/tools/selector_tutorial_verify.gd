extends Node
## Dev-only Splitter Selector tutorial verifier (Selector Phase S2). Never exported (scripts/tools/**).
## LevelSolver is binary-flip only, so for each of T29-T34 this brute-forces EVERY orientation
## combination (4 states per Selector/Fusion, 2 per mirror) through the real LaserSystem and checks:
##   * the start state is unsolved
##   * exactly ONE combination solves it and it equals the hint_solutions.json entry (+ start values)
##   * min taps (state-space) == taps forced by the tutorial's require_tap steps (+ free taps of the solution)
##   * every tile in the solution matters (reverting any ONE tile to its start value un-solves it)
##   * each Selector as a dead blocker / removed loses the level
##   * replaying the require_tap steps in order never solves the board early
## Run: godot --headless --path . res://scripts/tools/selector_tutorial_verify.tscn


func _ready() -> void:
	var problems := 0
	for id in range(LevelManager.SELECTOR_TUTORIAL_FIRST, LevelManager.SELECTOR_TUTORIAL_LAST + 1):
		problems += _verify(id)
	print("--- selector_tutorial_verify: %d problem(s)" % problems)
	get_tree().quit()


func _tap(kind: int, cur: int) -> int:
	if kind == GridTypes.TileType.MIRROR:
		return 1 - cur
	return (cur + 1) % 4


func _dist(kind: int, a: int, b: int) -> int:
	return (0 if a == b else 1) if kind == GridTypes.TileType.MIRROR else (b - a + 4) % 4


func _verify(id: int) -> int:
	var bad := 0
	var lines: Array = []
	var level: TutorialLevelData = LevelManager.get_tutorial_level(id)
	var start: Dictionary = level.get_initial_tile_orientations()
	var rot := ProceduralComplexity.rotatable_types(level)
	var cells: Array = rot.keys()
	cells.sort()
	var table := HintManager.table_solution("t%d" % id)
	var authored: Dictionary = start.duplicate()
	for p in table:
		authored[p] = table[p]

	if LaserSystem.simulate_until_stable(level, start)["solved"]:
		lines.append("start already solved")
		bad += 1

	var total := 1
	var radix: Array = []
	for p in cells:
		var r := 2 if rot[p] == GridTypes.TileType.MIRROR else 4
		radix.append(r)
		total *= r
	var solved_count := 0
	var best := 1 << 30
	var unique_ok := false
	for n in range(total):
		var o: Dictionary = start.duplicate()
		var k := n
		var moves := 0
		for idx in range(cells.size()):
			var p: Vector2i = cells[idx]
			var v: int = k % radix[idx]
			k /= radix[idx]
			o[p] = v
			moves += _dist(rot[p], start[p], v)
		if LaserSystem.simulate_until_stable(level, o)["solved"]:
			solved_count += 1
			best = mini(best, moves)
			unique_ok = (o == authored)
	if solved_count != 1 or not unique_ok:
		lines.append("solved combinations=%d unique_is_table=%s" % [solved_count, str(unique_ok)])
		bad += 1

	var solution_moves := 0
	for p in cells:
		solution_moves += _dist(rot[p], start[p], authored[p])
	if best != solution_moves:
		lines.append("min moves %d != table moves %d" % [best, solution_moves])
		bad += 1

	for p in cells:
		if authored[p] != start[p]:
			var o2: Dictionary = authored.duplicate()
			o2[p] = start[p]
			if LaserSystem.simulate_until_stable(level, o2)["solved"]:
				lines.append("tile %s does not matter" % [p])
				bad += 1

	var sel_count := 0
	for mode in ["dead", "removed"]:
		var tiles: Array[TilePlacement] = []
		for t in level.tiles:
			if t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
				sel_count += 1
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

	# Step replay: forced taps in order; the board must not be solved before the last one.
	var forced := 0
	var replay: Dictionary = start.duplicate()
	var early := false
	var last_forced_idx := -1
	for i in range(level.steps.size()):
		if level.steps[i].step_type == TutorialStepData.StepType.REQUIRE_TILE_TAP:
			last_forced_idx = i
	for i in range(level.steps.size()):
		var s: TutorialStepData = level.steps[i]
		if s.step_type != TutorialStepData.StepType.REQUIRE_TILE_TAP:
			continue
		if not rot.has(s.target_position):
			lines.append("step %d targets non-rotatable %s" % [i, s.target_position])
			bad += 1
			continue
		forced += 1
		replay[s.target_position] = _tap(rot[s.target_position], replay[s.target_position])
		var solved_now: bool = LaserSystem.simulate_until_stable(level, replay)["solved"]
		if solved_now and i != last_forced_idx:
			early = true
	if early:
		lines.append("board solved before the last forced tap")
		bad += 1
	if forced > 0:
		var final_solved: bool = LaserSystem.simulate_until_stable(level, replay)["solved"]
		if not final_solved:
			lines.append("forced taps alone do not solve the board")
			bad += 1
		if forced != solution_moves:
			lines.append("forced taps %d != solution moves %d" % [forced, solution_moves])
			bad += 1

	print("T%d %-14s states=%d solved_states=%d min_moves=%d forced=%d selectors=%d %s" % [
		id, level.display_name, total, solved_count, best, forced, sel_count / 2,
		"OK" if bad == 0 else "FAIL " + "; ".join(lines)])
	return bad
