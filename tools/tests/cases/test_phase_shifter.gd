extends TestCase
## Phase Shifter Stage A: the pure simulation contract (LaserSystem), the ordering contract, interaction
## with every neighbouring mechanic, loop termination, solver support and the GridManager move path.

const GRID_SCENE := preload("res://scenes/gameplay/grid.tscn")
const D := GridTypes.Direction
const SLASH := GridTypes.MirrorOrientation.SLASH
const BACK := GridTypes.MirrorOrientation.BACKSLASH
const A := GridTypes.PHASE_A
const B := GridTypes.PHASE_B


func _level(w: int, h: int, tiles: Array) -> LevelData:
	var l := LevelData.new()
	l.grid_width = w
	l.grid_height = h
	var typed: Array[TilePlacement] = []
	for t in tiles:
		typed.append(t)
	l.tiles = typed
	return l


func _sim(l: LevelData, orientations: Dictionary = {}) -> Dictionary:
	var o := l.get_initial_tile_orientations()
	for k in orientations:
		o[k] = orientations[k]
	return LaserSystem.simulate_until_stable(l, o)


## E1 (RED, from the left) and E2 (GREEN, from below) both meet the Phase Shifter at (2,2).
## Tile order [E1, E2] -> LIFO pops E2 first: E2 meets PHASE_A, E1 then meets PHASE_B.
func _two_beam(p_orientation: int, e2_first_in_array := false, extra: Array = []) -> LevelData:
	var e1 := TilePlacement.make_emitter(Vector2i(0, 2), D.RIGHT, GridTypes.BeamColor.RED)
	var e2 := TilePlacement.make_emitter(Vector2i(2, 4), D.UP, GridTypes.BeamColor.GREEN)
	var tiles: Array = [e2, e1] if e2_first_in_array else [e1, e2]
	tiles.append(TilePlacement.make_phase_shifter(Vector2i(2, 2), p_orientation))
	tiles.append_array(extra)
	return _level(5, 5, tiles)


func test_phase_a_passes_straight_then_becomes_b() -> void:
	var l := _level(5, 3, [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_phase_shifter(Vector2i(2, 1), SLASH),
		TilePlacement.make_target(Vector2i(4, 1)),
	])
	var r := _sim(l)
	ok(r["solved"], "phase A passes the beam straight to the target")
	eq(r["phase_in_states"][Vector2i(2, 1)], [A], "one interaction, met in phase A")
	eq(r["phase_final"][Vector2i(2, 1)], B, "after the interaction the tile is in phase B")
	eq(r["phase_hits"][Vector2i(2, 1)], 1)


func test_phase_b_reflects_slash() -> void:
	var l := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(2, 1), GridTypes.BeamColor.RED)])
	var r := _sim(l)
	eq(r["phase_in_states"][Vector2i(2, 2)], [A, B], "E2 (popped first) met A, E1 then met B")
	ok(r["solved"], "RED beam reflected UP by '/' in phase B reaches the RED target above")
	eq(r["phase_final"][Vector2i(2, 2)], A, "second interaction flips back to A")


func test_phase_b_reflects_backslash() -> void:
	var l := _two_beam(BACK, false, [TilePlacement.make_target(Vector2i(2, 3), GridTypes.BeamColor.RED)])
	var r := _sim(l)
	ok(r["solved"], "RED beam reflected DOWN by backslash in phase B reaches the RED target below")


func test_slash_orientation_does_not_reach_backslash_target() -> void:
	var l := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(2, 3), GridTypes.BeamColor.RED)])
	ok(not _sim(l)["solved"], "the selected Phase-B orientation decides where the reflected beam goes")


func test_ordering_is_the_documented_lifo_over_tile_order() -> void:
	# Same board, emitters listed the other way round: E1 is now popped first and meets PHASE_A.
	var l := _two_beam(SLASH, true, [TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.RED)])
	var r := _sim(l)
	eq(r["phase_in_states"][Vector2i(2, 2)], [A, B], "the first beam popped meets A whichever beam it is")
	ok(r["solved"], "E1 (now first) passes straight to the RED target at (4,2)")
	var l2 := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.RED)])
	ok(not _sim(l2)["solved"], "with the original order E1 meets B and is deflected away from (4,2)")


func test_recalculation_resets_phase() -> void:
	var l := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(2, 1), GridTypes.BeamColor.RED)])
	var first := _sim(l)
	var second := _sim(l)
	eq(str(first["phase_in_states"]), str(second["phase_in_states"]), "no phase leaks between simulations")
	eq(first["phase_final"], second["phase_final"])
	eq(second["phase_in_states"][Vector2i(2, 2)][0], A, "every simulation starts in phase A")


func test_repeated_simulation_is_bit_identical() -> void:
	var l := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(2, 1), GridTypes.BeamColor.RED)])
	var ref := var_to_str(_sim(l)["beams"])
	for i in 8:
		eq(var_to_str(_sim(l)["beams"]), ref, "run %d" % i)


func test_player_rotation_changes_phase_b_orientation() -> void:
	var l := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(2, 3), GridTypes.BeamColor.RED)])
	ok(not _sim(l)["solved"])
	ok(_sim(l, {Vector2i(2, 2): BACK})["solved"], "flipping the stored orientation re-routes the phase-B reflection")


func test_rotation_is_one_move_through_grid_manager() -> void:
	var grid: GridManager = GRID_SCENE.instantiate()
	runner.add_child(grid)
	await frames(2)
	var l := _two_beam(SLASH, false, [TilePlacement.make_target(Vector2i(2, 3), GridTypes.BeamColor.RED)])
	grid.load_level(l)
	await frames(2)
	var moves := watch(grid.move_made)
	ok(grid.has_orientable_tile(Vector2i(2, 2)), "a Phase Shifter is an orientable tile")
	grid._on_orientable_tile_clicked(Vector2i(2, 2))
	eq(moves.size(), 1, "one tap = exactly one move")
	eq(grid.tile_orientations[Vector2i(2, 2)], BACK)
	ok(grid.is_solved, "the tap re-routed the phase-B reflection onto the target")
	var node: PhaseShifterTile = grid._phase_nodes[Vector2i(2, 2)]
	eq(node.orientation, BACK, "visual orientation matches logical orientation")
	eq(node.phase, A, "tile displays the end-of-pass phase (two interactions -> back to A)")
	grid.reset_level()
	await frames(2)
	eq(grid.tile_orientations[Vector2i(2, 2)], SLASH, "Reset restores the authored orientation")
	grid.queue_free()


func test_phase_with_portal() -> void:
	var l := _level(6, 4, [
		TilePlacement.make_emitter(Vector2i(0, 0), D.RIGHT),
		TilePlacement.make_portal(Vector2i(1, 0), "p"),
		TilePlacement.make_portal(Vector2i(2, 2), "p"),
		TilePlacement.make_phase_shifter(Vector2i(3, 2), SLASH),
		TilePlacement.make_target(Vector2i(5, 2)),
	])
	var r := _sim(l)
	ok(r["solved"], "beam teleports, then meets the Phase Shifter in phase A and continues straight")
	eq(r["phase_hits"][Vector2i(3, 2)], 1)


func test_phase_with_splitter() -> void:
	var l := _level(5, 4, [
		TilePlacement.make_emitter(Vector2i(0, 2), D.RIGHT),
		TilePlacement.make_splitter(Vector2i(1, 2), SLASH),
		TilePlacement.make_phase_shifter(Vector2i(3, 2), SLASH),
		TilePlacement.make_phase_shifter(Vector2i(1, 0), SLASH),
		TilePlacement.make_target(Vector2i(4, 2)),
	])
	var r := _sim(l)
	eq(r["phase_hits"][Vector2i(3, 2)], 1, "main beam")
	eq(r["phase_hits"][Vector2i(1, 0)], 1, "split branch")
	ok(r["solved"])


func test_phase_with_gate() -> void:
	var l := _level(6, 3, [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_switch(Vector2i(1, 1), "g"),
		TilePlacement.make_gate(Vector2i(2, 1), "g"),
		TilePlacement.make_phase_shifter(Vector2i(3, 1), SLASH),
		TilePlacement.make_target(Vector2i(5, 1)),
	])
	var r := _sim(l)
	ok(r["solved"], "the gate opens on a later pass; phase state restarts each pass")
	eq(r["phase_hits"][Vector2i(3, 1)], 1, "the final pass met the tile exactly once")


func test_phase_with_receiver_and_remote_emitter() -> void:
	var l := _level(5, 5, [
		TilePlacement.make_emitter(Vector2i(0, 2), D.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(1, 2), "L"),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_remote_emitter(Vector2i(4, 0), D.DOWN, "L"),
		TilePlacement.make_phase_shifter(Vector2i(4, 2), SLASH),
		TilePlacement.make_target(Vector2i(4, 4)),
	])
	var r := _sim(l)
	ok(r["solved"], "remote emitter beam crosses the Phase Shifter in phase A")


func test_phase_with_fusion() -> void:
	var l := _level(5, 5, [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(2, 0), D.DOWN, GridTypes.BeamColor.GREEN),
		TilePlacement.make_fusion(Vector2i(2, 1), D.DOWN),
		TilePlacement.make_phase_shifter(Vector2i(2, 2), SLASH),
		TilePlacement.make_target(Vector2i(2, 4), GridTypes.BeamColor.YELLOW),
	])
	var r := _sim(l)
	ok(r["solved"], "fused YELLOW beam passes the Phase Shifter (phase A) and lights the target")
	ok(r["converged"])


func test_phase_with_selector() -> void:
	var l := _level(5, 5, [
		TilePlacement.make_emitter(Vector2i(0, 2), D.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(2, 2), D.DOWN),
		TilePlacement.make_phase_shifter(Vector2i(2, 3), SLASH),
		TilePlacement.make_target(Vector2i(2, 4)),
	])
	ok(_sim(l)["solved"], "selector routes DOWN through a Phase Shifter to the target")


func test_phase_reflection_into_hazard() -> void:
	var l := _two_beam(SLASH, false, [TilePlacement.make_hazard(Vector2i(2, 1)), TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.RED)])
	var r := _sim(l)
	ok(r["hazard_hit"], "the phase-B reflected beam hits the hazard")
	ok(not r["solved"], "a hazard hit never counts as solved")


## A rectangular loop around a splitter with the Phase Shifter on the top edge: lap 1 passes straight (A),
## lap 2 is reflected out of the loop (B, slash) - so the beam leaves through the target above it.
func _loop_level(p_orientation: int) -> LevelData:
	return _level(6, 5, [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_splitter(Vector2i(2, 1), SLASH, false),
		TilePlacement.make_phase_shifter(Vector2i(3, 1), p_orientation),
		TilePlacement.make_mirror(Vector2i(4, 1), BACK, false),
		TilePlacement.make_mirror(Vector2i(4, 3), SLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 3), BACK, false),
		TilePlacement.make_target(Vector2i(3, 0)),
	])


func test_loop_terminates_and_repeats_a_b_a() -> void:
	var r := _sim(_loop_level(SLASH))
	var states: Array = r["phase_in_states"][Vector2i(3, 1)]
	ok(states.size() >= 2, "the loop meets the tile repeatedly")
	eq(states[0], A)
	eq(states[1], B)
	ok(r["solved"], "lap 2 (phase B, slash) exits UP through the target")


func test_inescapable_loop_hits_the_guard_not_the_engine() -> void:
	var l := _loop_level(BACK)
	var t0 := Time.get_ticks_msec()
	var r := _sim(l)
	ok(Time.get_ticks_msec() - t0 < 500, "terminates quickly")
	ok(r["looped"] or not r["solved"], "no infinite loop; unsolved or guarded")


func test_solver_supports_phase_shifters() -> void:
	var l := _loop_level(BACK)
	var r := LevelSolver.analyze(l, 10000)
	eq(r["status"], "SOLVABLE", "LevelSolver replays the real LaserSystem, so Phase Shifters are supported")
	eq(r["optimal_moves"], 1, "one orientation flip solves it")


func test_non_phase_boards_keep_their_state_keys() -> void:
	var l := _level(4, 3, [
		TilePlacement.make_emitter(Vector2i(0, 1), D.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 1), SLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
	])
	var r := _sim(l)
	ok(r["solved"])
	eq(r["phase_hits"].size(), 0)
	eq(r["phase_final"].size(), 0)


func test_tile_type_appended_not_renumbered() -> void:
	eq(int(GridTypes.TileType.SPLITTER_SELECTOR) + 1, int(GridTypes.TileType.PHASE_SHIFTER))
	eq(GridTypes.TileType.keys()[GridTypes.TileType.PHASE_SHIFTER], "PHASE_SHIFTER")
