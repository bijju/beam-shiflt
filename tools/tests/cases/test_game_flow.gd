extends TestCase
## Boots the real game scene through GameManager and plays levels with real taps.


func _enter_and_get_grid() -> GridManager:
	await frames(4)
	var game := current_scene()
	if game == null:
		return null
	return game.get_node_or_null("%PuzzleGrid")


func _solve_campaign(id: int) -> void:
	GameManager.start_level(id, true)
	var grid := await _enter_and_get_grid()
	ok(grid != null, "grid for campaign %d" % id)
	if grid == null:
		return
	var lv := LevelManager.get_campaign_level(id)
	var sol := LevelSolver.analyze(lv, 20000)
	if sol["status"] == "SOLVABLE":
		for step in sol["solution_path"]:
			grid._on_orientable_tile_clicked(step["position"])
		ok(grid.is_solved, "campaign %d solved by taps" % id)
	await frames(3)


func test_campaign_levels_play() -> void:
	GameManager.start_level(1, true)
	await frames(2)
	for id in [1, 5, 12, 20, 27, 33, 44, 50, 52, 66, 78, 90, 100]:
		await _solve_campaign(id)


func test_legacy_levels_play() -> void:
	for id in [1, 6, 9, 13, 15]:
		GameManager.start_level(id, false)
		var grid := await _enter_and_get_grid()
		ok(grid != null)
		if grid:
			grid.reset_level()
			grid.get_layout_metrics()
			grid.format_layout_diagnostics()
			grid.get_last_simulation()


func test_procedural_levels_play() -> void:
	for n in [1, 2, 7, 30, 120, 260, 700, 1300]:
		GameManager.start_procedural_level(n)
		var grid := await _enter_and_get_grid()
		ok(grid != null, "procedural %d" % n)
		if grid == null:
			continue
		var v := LevelManager.procedural_generator_version_for_new_play(n)
		var r := LevelManager.get_procedural_generation_result(n, v)
		solve_by_taps(grid, r["solution_orientations"])
		ok(grid.is_solved, "procedural %d solved" % n)
		await frames(3)


func test_qa_sessions() -> void:
	GameManager.start_v3_prototype(1)
	var g := await _enter_and_get_grid()
	ok(g != null)
	GameManager.start_fusion_test(1)
	g = await _enter_and_get_grid()
	ok(g != null)
	GameManager.start_selector_test(1)
	g = await _enter_and_get_grid()
	ok(g != null)
	GameManager.start_v5_test(1)
	g = await _enter_and_get_grid()
	ok(g != null)
	var game := current_scene()
	if game != null and game.has_method("_on_qa_next_pressed"):
		game._on_qa_next_pressed()
		await frames(3)


func test_tutorials_load() -> void:
	for t in range(1, LevelManager.get_tutorial_level_count() + 1):
		GameManager.start_tutorial(t)
		var grid := await _enter_and_get_grid()
		ok(grid != null, "tutorial %d" % t)
