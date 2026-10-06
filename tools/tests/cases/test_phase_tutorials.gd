extends TestCase
## Phase Shifter tutorial pack (T35-T39): every board has exactly ONE solving orientation combination,
## equal to the hand-authored hint entry; forced taps never solve early; names fit; older tutorials unchanged.

const FIRST := LevelManager.PHASE_TUTORIAL_FIRST
const LAST := LevelManager.PHASE_TUTORIAL_LAST


func _solved(level: LevelData, o: Dictionary) -> bool:
	return LaserSystem.simulate_until_stable(level, o)["solved"]


func test_pack_is_registered_and_old_tutorials_untouched() -> void:
	eq(FIRST, 35)
	eq(LAST, 39)
	eq(LevelManager.get_tutorial_level_count(), 39)
	for id in range(1, 35):
		ok(LevelManager.get_tutorial_level(id) != null, "T%02d still loads" % id)
	eq(LevelManager.TUTORIAL_LEVEL_PATHS[33], "res://levels/tutorial/t34.gd", "T34 keeps its slot")


func test_every_phase_tutorial_has_exactly_one_solution() -> void:
	for id in range(FIRST, LAST + 1):
		var level: TutorialLevelData = LevelManager.get_tutorial_level(id)
		ok(level != null, "T%d loads" % id)
		eq(level.level_id, id)
		ok(level.display_name.length() <= 13, "T%d name fits the HUD (%s)" % [id, level.display_name])
		var start: Dictionary = level.get_initial_tile_orientations()
		ok(not _solved(level, start), "T%d does not start solved" % id)
		var cells: Array = []
		for t in level.get_rotatable_tiles():
			cells.append(t.position)
		var authored: Dictionary = start.duplicate()
		var table := HintManager.table_solution("t%d" % id)
		ok(not table.is_empty(), "T%d has a hint entry" % id)
		for p in table:
			authored[p] = table[p]
		var solutions := 0
		var matches := false
		for n in range(1 << cells.size()):
			var o: Dictionary = start.duplicate()
			for i in range(cells.size()):
				o[cells[i]] = (n >> i) & 1
			if _solved(level, o):
				solutions += 1
				matches = (o == authored)
		eq(solutions, 1, "T%d has exactly one solution" % id)
		ok(matches, "T%d: the unique solution equals the hint entry" % id)
		ok(_solved(level, authored), "T%d hint entry solves the board" % id)


func test_phase_shifter_is_load_bearing_in_every_tutorial() -> void:
	for id in range(FIRST, LAST + 1):
		var level: TutorialLevelData = LevelManager.get_tutorial_level(id)
		var authored: Dictionary = level.get_initial_tile_orientations()
		var table := HintManager.table_solution("t%d" % id)
		for p in table:
			authored[p] = table[p]
		var without := LevelData.new()
		without.grid_width = level.grid_width
		without.grid_height = level.grid_height
		var kept: Array[TilePlacement] = []
		for t in level.tiles:
			if t.tile_type != GridTypes.TileType.PHASE_SHIFTER:
				kept.append(t)
		without.tiles = kept
		if id == FIRST:
			# T35: the shifter only passes the beam straight, so the end state equals "no tile"; the
			# decision (which slash) is still real because the wrong one leaves the board.
			continue
		ok(not _solved(without, authored), "T%d needs the Phase Shifter (removing it loses the level)" % id)


func test_forced_taps_never_solve_early_and_are_possible() -> void:
	for id in range(FIRST, LAST + 1):
		var level: TutorialLevelData = LevelManager.get_tutorial_level(id)
		var o: Dictionary = level.get_initial_tile_orientations()
		var table := HintManager.table_solution("t%d" % id)
		for step in level.steps:
			if step.step_type != TutorialStepData.StepType.REQUIRE_TILE_TAP:
				continue
			var found := false
			for t in level.get_rotatable_tiles():
				if t.position == step.target_position:
					found = true
			ok(found, "T%d forced tap %s hits a rotatable tile" % [id, step.target_position])
			ok(not _solved(level, o), "T%d not solved before its forced tap" % id)
			o[step.target_position] = table.get(step.target_position, 1 - int(o[step.target_position]))


func test_phase_behaviour_taught_by_each_tutorial() -> void:
	# T35: the beam crosses the shifter in phase A exactly once.
	var r35 := LaserSystem.simulate_until_stable(LevelManager.get_tutorial_level(35), _with_hint(35))
	eq(r35["phase_in_states"][Vector2i(2, 2)], [GridTypes.PHASE_A])
	# T36: pass 1 straight (A), return reflects (B).
	var r36 := LaserSystem.simulate_until_stable(LevelManager.get_tutorial_level(36), _with_hint(36))
	eq(r36["phase_in_states"][Vector2i(3, 2)], [GridTypes.PHASE_A, GridTypes.PHASE_B])
	# T37: A, B, A.
	var r37 := LaserSystem.simulate_until_stable(LevelManager.get_tutorial_level(37), _with_hint(37))
	eq(r37["phase_in_states"][Vector2i(2, 2)].slice(0, 3), [GridTypes.PHASE_A, GridTypes.PHASE_B, GridTypes.PHASE_A])
	# T38: main beam first (A), the branch second (B).
	var r38 := LaserSystem.simulate_until_stable(LevelManager.get_tutorial_level(38), _with_hint(38))
	eq(r38["phase_in_states"][Vector2i(3, 2)], [GridTypes.PHASE_A, GridTypes.PHASE_B])


func test_t37_cycle_is_required_and_exercised() -> void:
	var level: LevelData = LevelManager.get_tutorial_level(37)
	var shifter := Vector2i(2, 2)
	var right := _with_hint(37)
	var r := LaserSystem.simulate_until_stable(level, right)
	ok(r["solved"], "T37 correct slash solves")
	eq(r["phase_in_states"][shifter], [GridTypes.PHASE_A, GridTypes.PHASE_B, GridTypes.PHASE_A], "A -> B -> A, exactly three visits")
	var wrong := right.duplicate()
	wrong[shifter] = 1 - int(right[shifter])
	var rw := LaserSystem.simulate_until_stable(level, wrong)
	ok(not rw["solved"], "T37 wrong slash fails")
	eq(rw["phase_in_states"][shifter], [GridTypes.PHASE_A, GridTypes.PHASE_B, GridTypes.PHASE_A], "wrong slash still cycles A, B, A")
	var without := LevelData.new()
	without.grid_width = level.grid_width
	without.grid_height = level.grid_height
	var kept: Array[TilePlacement] = []
	for t in level.tiles:
		if t.tile_type != GridTypes.TileType.PHASE_SHIFTER:
			kept.append(t)
	without.tiles = kept
	var oo: Dictionary = right.duplicate()
	oo.erase(shifter)
	ok(not LaserSystem.simulate_until_stable(without, oo)["solved"], "T37 without the Phase Shifter fails")


func _with_hint(id: int) -> Dictionary:
	var level: TutorialLevelData = LevelManager.get_tutorial_level(id)
	var o: Dictionary = level.get_initial_tile_orientations()
	var table := HintManager.table_solution("t%d" % id)
	for p in table:
		o[p] = table[p]
	return o


func test_old_save_data_with_34_tutorials_loads_and_new_ones_start_uncompleted() -> void:
	SaveManager.tutorial_completed_levels = {}
	for i in range(1, 35):
		SaveManager.tutorial_completed_levels[str(i)] = true
	SaveManager.tutorial_highest_unlocked_level = 34
	for id in range(FIRST, LAST + 1):
		ok(not SaveManager.is_tutorial_level_completed(id), "T%d starts uncompleted" % id)
	ok(SaveManager.is_tutorial_level_completed(34), "T34 history intact")
	SaveManager.record_tutorial_level_result(35, LevelManager.get_tutorial_level_count())
	ok(SaveManager.is_tutorial_level_completed(35))
	eq(SaveManager.tutorial_highest_unlocked_level, 36, "completing T35 unlocks T36 sequentially")
	SaveManager.record_tutorial_level_result(39, LevelManager.get_tutorial_level_count())
	ok(SaveManager.is_tutorial_level_completed(39))
	eq(SaveManager.tutorial_highest_unlocked_level, 36, "no T40 to unlock")
