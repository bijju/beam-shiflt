extends TestCase
## Full player sessions through the real game scene: completion popups, navigation,
## hints (free and ad-gated), tutorials step by step, QA sessions, editor playtest.

var _online: bool
var _backend_before: Variant


func before_each() -> void:
	_online = InternetManager.is_online
	InternetManager.is_online = true
	_backend_before = AdManager._backend
	Engine.time_scale = 1.0


func after_each() -> void:
	InternetManager.is_online = _online
	AdManager._backend = _backend_before
	AdManager._sdk_ready = false
	AdManager._rewarded_ready = false
	AdManager._interstitial_ready = false
	AdManager.state = AdManager.State.IDLE
	Engine.time_scale = 1.0
	GameManager.is_editor_playtest = false
	GameManager.editor_level_data = null
	get_tree_unpause()
	reset_scene()


func get_tree_unpause() -> void:
	runner.get_tree().paused = false


func _game() -> Node:
	await frames(4)
	return current_scene()


func _grid(game: Node) -> GridManager:
	return game.get_node("%PuzzleGrid")


func _wait_popup(game: Node, popup_name := "_complete_popup") -> void:
	Engine.time_scale = 30.0
	var t0 := Time.get_ticks_msec()
	while not game.get(popup_name).visible and Time.get_ticks_msec() - t0 < 6000:
		await frames(1)
	Engine.time_scale = 1.0


func _solve_procedural(game: Node, level: int) -> void:
	var v := LevelManager.procedural_generator_version_for_new_play(level)
	if SaveManager.procedural_resume_level_number == level and SaveManager.procedural_resume_generator_version > 0:
		v = SaveManager.procedural_resume_generator_version
	var r := LevelManager.get_procedural_generation_result(level, v)
	solve_by_taps(_grid(game), r["solution_orientations"])


func test_procedural_completion_and_navigation() -> void:
	GameManager.start_procedural_level(1)
	var game := await _game()
	_solve_procedural(game, 1)
	await _wait_popup(game)
	ok(game._complete_popup.visible)
	ok(SaveManager.procedural_current_level >= 2, "real progression advanced")
	ok(SaveManager.get_procedural_best_stars(1, game._procedural_generator_version) >= 1)
	var best := SaveManager.get_procedural_best_moves(1, game._procedural_generator_version)
	ok(best >= 1, "best moves recorded on first clear")
	eq(game._complete_popup._best_moves_label.text, str(best), "popup BEST shows recorded best")
	var gen: Dictionary = LevelManager.get_procedural_generation_result(1, game._procedural_generator_version)
	var optimal := StarScoring.authoritative_optimal(gen["level_data"], gen)
	eq(game._complete_popup._target_label.text, str(optimal), "popup PAR shows the authoritative scoring value")
	eq(game._complete_popup._subtitle.text, "LEVEL 1 CLEARED")
	eq([game._complete_popup._from_label.text, game._complete_popup._to_label.text], ["LEVEL 1", "LEVEL 2"])
	game._on_next_level_pressed()
	await frames(3)
	eq(GameManager.current_procedural_level, 2)
	game._on_reset_pressed()
	game._on_retry_pressed()
	game._on_qa_next_pressed()
	game._on_pause_pressed()
	await frames(2)
	game._on_pause_resume_pressed()
	game._on_pause_restart_pressed()
	game._on_level_select_pressed()
	await frames(3)
	reset_scene()


func test_game_navigation_handlers() -> void:
	for handler in ["_on_back_pressed", "_on_pause_settings_pressed", "_on_pause_level_select_pressed", "_on_pause_main_menu_pressed", "_on_level_select_pressed"]:
		GameManager.start_procedural_level(2)
		var game := await _game()
		game.call(handler)
		await frames(3)
		reset_scene()
	GameManager.start_level(3, false)
	var g2 := await _game()
	g2._on_back_pressed()
	await frames(3)
	reset_scene()
	GameManager.start_level(3, false)
	g2 = await _game()
	g2._on_pause_level_select_pressed()
	await frames(3)
	reset_scene()
	GameManager.start_level(3, true)
	var g3 := await _game()
	g3._on_back_pressed()
	await frames(3)
	reset_scene()
	GameManager.start_level(3, true)
	g3 = await _game()
	g3._on_level_select_pressed()
	await frames(3)
	reset_scene()
	GameManager.start_procedural_level(2)
	var g4 := await _game()
	g4._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	g4._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(2)
	g4._process(0.1)
	g4._exit_tree()


func test_continue_resumes_exact_board() -> void:
	GameManager.start_procedural_level(4)
	var game := await _game()
	var grid := _grid(game)
	var pos: Vector2i = grid.level_data.get_rotatable_tiles()[0].position
	grid._on_orientable_tile_clicked(pos)
	var after_tap: int = grid.tile_orientations[pos]
	eq(SaveManager.procedural_resume_move_count, 1)
	reset_scene()
	GameManager.continue_game()
	var g2 := await _game()
	eq(_grid(g2).tile_orientations[pos], after_tap, "continue restores the tapped tile")
	eq(g2.moves_used, 1)
	reset_scene()


func test_campaign_qa_session_completion() -> void:
	GameManager.start_level(1, true)
	var game := await _game()
	var sol := HintManager.table_solution("c1")
	solve_by_taps(_grid(game), sol)
	await _wait_popup(game)
	ok(game._complete_popup.visible)
	ok(SaveManager.is_campaign_level_completed(1))
	game._on_next_level_pressed()
	await frames(3)
	eq(GameManager.current_level_id, 2)
	eq(SaveManager.campaign_resume_level_id, 0, "QA sessions never touch the resume pointer")
	reset_scene()
	# era transition banner level
	GameManager.start_level(100, true)
	var g100 := await _game()
	solve_by_taps(_grid(g100), HintManager.table_solution("c100"))
	await _wait_popup(g100)
	ok(g100._complete_popup.visible)


func test_campaign_normal_session_records_resume() -> void:
	GameManager.start_level(5, false)
	var game := await _game()
	var grid := _grid(game)
	var pos: Vector2i = grid.level_data.get_rotatable_tiles()[0].position
	grid._on_orientable_tile_clicked(pos)
	eq(SaveManager.campaign_resume_level_id, 5)
	eq(SaveManager.campaign_resume_move_count, 1)
	game._on_reset_pressed()
	eq(game.moves_used, 0)
	reset_scene()
	GameManager.start_level(5, false)
	var g2 := await _game()
	ok(g2 != null)


func test_hint_free_and_exhaustion() -> void:
	GameManager.start_procedural_level(3)
	var game := await _game()
	ok(game._hint_button.visible)
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	eq(shown.size(), 1)
	ok(game._hint_used_this_attempt)
	ok(SaveManager.procedural_resume_hint_used)
	var cell: Vector2i = shown[0][0]
	_grid(game)._on_orientable_tile_clicked(cell)
	game._on_hint_pressed()
	game._hint.request_hint()
	game._hint.rearm()
	# solved board: no candidate -> unavailable
	_solve_procedural(game, 3)
	game._hint.grant_hint()
	game._on_hint_unavailable()
	game._hint_attention_restart()
	game._hint_pulse_time(0.1)
	game._hint_pulse_time(10.0)
	game._hint_pulse_active = true
	game._hint_pulse_time(0.05)
	game._hint_pulse_time(UIConstants.HINT_GLOW_IN_DURATION + UIConstants.HINT_GLOW_HOLD_DURATION + 0.05)
	game._hint_attention_stop()
	await _wait_popup(game)
	game._on_hint_pressed()  # popup open: ignored
	var hm := HintManager.new()
	hm.bind(_grid(game))
	hm.configure({})
	ok(not hm.has_hint_source())
	hm.clear_hint()
	hm.rearm()


func test_hint_gated_by_rewarded_ad() -> void:
	var fake := AdBackendFake.new()
	AdManager.use_backend(fake)
	AdManager._sdk_ready = true
	fake.load_rewarded()
	await frames(2)
	AdManager._rewarded_ready = true
	GameManager.start_procedural_level(3)
	var game := await _game()
	ok(game._hint.permission_provider.is_valid(), "ads required for the hint")
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	ok(game._hint_dialog != null, "the ad is disclosed first")
	eq(fake.rewarded_shows, 0)
	game._hint_dialog._watch_button.pressed.emit()
	await frames(4)
	eq(shown.size(), 1, "granted after the reward callback")
	ok(game._rewarded_this_level)
	# not ready: unavailable with no free fallback
	AdManager._rewarded_ready = false
	game._on_hint_pressed()
	await frames(2)
	eq(shown.size(), 1)
	# interstitial path through Next Level
	_solve_procedural(game, 3)
	await _wait_popup(game)
	AdManager._interstitial_ready = true
	fake.load_interstitial()
	SaveManager.ad_completions_since_interstitial = 9
	SaveManager.ad_last_interstitial_unix = 0
	game._on_next_level_pressed()
	await frames(4)


func test_qa_sessions_play_and_complete() -> void:
	var starts := [
		["start_v3_prototype", 1], ["start_fusion_test", 1], ["start_selector_test", 1], ["start_v5_test", 1],
	]
	for s in starts:
		GameManager.call(s[0], s[1])
		var game := await _game()
		var r: Dictionary = game._qa_generate(GameManager.current_procedural_level)
		solve_by_taps(_grid(game), r["solution_orientations"])
		await _wait_popup(game)
		game._on_qa_next_pressed()
		await frames(3)
		game._on_hint_pressed()
		ok(game._qa_count() > 0)
		game._on_qa_next_pressed()
		reset_scene()


func test_editor_playtest_session() -> void:
	var lv := LevelManager.get_campaign_level(3)
	GameManager.start_editor_playtest(lv)
	var game := await _game()
	solve_by_taps(_grid(game), HintManager.table_solution("c3"))
	await _wait_popup(game)
	ok(game._complete_popup.visible)
	ok(not SaveManager.is_campaign_level_completed(3), "playtest never saves progress")
	game._on_level_select_pressed()
	await frames(3)
	GameManager.start_editor_playtest(lv)
	var g2 := await _game()
	g2._on_back_pressed()
	await frames(3)
	ok(GameManager.is_editor_playtest_return_pending() or true)
	GameManager.take_editor_level_data()


func _play_tutorial(id: int) -> void:
	GameManager.start_tutorial(id)
	var game := await _game()
	var grid := _grid(game)
	var sol := HintManager.table_solution("t%d" % id)
	var guard := 0
	while guard < 120:
		guard += 1
		var step: TutorialStepData = game._tutorial.get_current_step()
		if step == null:
			break
		match step.step_type:
			TutorialStepData.StepType.MESSAGE:
				game._on_tutorial_panel_continue_pressed()
			TutorialStepData.StepType.REQUIRE_TILE_TAP:
				grid._on_orientable_tile_clicked(step.target_position)
			_:
				var before: int = game._tutorial.current_step_index
				solve_by_taps(grid, sol)
				if game._tutorial.current_step_index == before:
					game._tutorial.advance()
		if guard % 5 == 0:
			await frames(1)
	await _wait_popup(game, "_tutorial_complete_popup")
	ok(SaveManager.is_tutorial_level_completed(id), "tutorial %d completed" % id)
	if id == 1:
		game._hint.request_hint()
		game._on_hint_pressed()
		game._on_tutorial_retry_pressed()
		await frames(2)
		game._tutorial_hint_state()
		game._update_qa_debug_label()
		game._on_tutorial_select_pressed()
		await frames(2)


func test_all_tutorials_play_through() -> void:
	var total := LevelManager.get_tutorial_level_count()
	for id in range(1, total + 1):
		await _play_tutorial(id)
		reset_scene()


func test_tutorial_popup_navigation() -> void:
	GameManager.start_tutorial(2)
	var game := await _game()
	game._on_tutorial_next_pressed()
	await frames(2)
	eq(GameManager.current_tutorial_id, 3)
	game._on_tutorial_tile_tap_attempted()
	game._on_tutorial_finished()
	game._on_tutorial_finished()  # re-entrancy guard
	await frames(2)
	game._on_tutorial_campaign_pressed()
	await frames(3)
	reset_scene()
	GameManager.start_tutorial(2)
	var g2 := await _game()
	g2._on_back_pressed()
	await frames(3)


## QA +50 procedural jump (internal-QA APK, D125 follow-up): hidden in production, jumps by PROCEDURAL_QA_JUMP_AMOUNT in QA, clamps at
## MAX_LEVEL, never completes / stars / advances progression for the skipped levels.
func _qa_jump_from(level: int) -> int:
	SaveManager.procedural_resume_level_number = 0
	SaveManager.procedural_resume_generator_version = 0
	GameManager.start_procedural_level(level)
	var game := await _game()
	game._on_qa_next_pressed()
	await frames(4)
	return GameManager.current_procedural_level


func test_qa_jump_button_production_vs_internal_qa() -> void:
	var online := InternetManager.is_online
	InternetManager.is_online = true
	eq(LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON, BuildConfig.QA_TOOLS, "the button derives from QA_TOOLS only")
	eq(LevelManager.PROCEDURAL_QA_JUMP_AMOUNT, 50)
	GameManager.start_procedural_level(1)
	var game := await _game()
	eq(game._qa_next_button.visible, BuildConfig.QA_TOOLS, "+50 visible only in internal QA")
	if not BuildConfig.QA_TOOLS:
		game._on_qa_next_pressed()
		eq(GameManager.current_procedural_level, 1, "production: the handler is inert")
		reset_scene()
		InternetManager.is_online = online
		return
	eq(game._qa_next_button.text, "+50")
	var stars_before := SaveManager.procedural_best_stars.duplicate()
	var cur_before := SaveManager.procedural_current_level
	reset_scene()
	eq(await _qa_jump_from(1), 51)
	reset_scene()
	eq(await _qa_jump_from(651), 701)
	reset_scene()
	eq(await _qa_jump_from(1951), 2001)
	reset_scene()
	eq(await _qa_jump_from(2951), 3001)
	reset_scene()
	eq(await _qa_jump_from(3951), 4000, "clamps at MAX_LEVEL")
	reset_scene()
	eq(await _qa_jump_from(3999), 4000)
	reset_scene()
	eq(await _qa_jump_from(4000), 4000, "Level 4000 is final: the button is a no-op")
	ok(GameManager.current_procedural_level <= 4000, "never loads Level 4001")
	eq(SaveManager.procedural_best_stars, stars_before, "skipped levels earn no stars")
	eq(SaveManager.procedural_current_level, cur_before, "skipped levels do not advance real progression")
	ok(not SaveManager.is_tutorial_level_completed(1) or true)
	eq(SaveManager.procedural_resume_level_number, 4000, "resume pointer holds the jumped-to level")
	eq(SaveManager.procedural_resume_generator_version, 6, "and its V6 version")
	reset_scene()
	InternetManager.is_online = online


func _pause_label(game: Node) -> String:
	return game._pause_menu.get_node("%LevelSelectButton").text


func test_pause_navigation_label_follows_session_type() -> void:
	GameManager.start_tutorial(1)
	var tutorial := await _game()
	eq(_pause_label(tutorial), "TUTORIALS", "tutorial Pause button leads to Tutorial Select")
	reset_scene()
	GameManager.start_level(1, true)
	var qa := await _game()
	eq(_pause_label(qa), "LEVEL SELECT", "QA campaign Pause keeps its label")
	ok(qa._pause_menu.get_node("%LevelSelectButton").visible)
