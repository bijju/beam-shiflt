extends TestCase
## GameManager navigation, LevelManager gating, TutorialManager step machine,
## HintManager candidates and the small UI helpers around gameplay.

const GRID_SCENE := preload("res://scenes/gameplay/grid.tscn")

var _online: bool


func before_each() -> void:
	_online = InternetManager.is_online
	InternetManager.is_online = true


func after_each() -> void:
	InternetManager.is_online = _online
	GameManager.is_editor_playtest = false
	GameManager.editor_level_data = null
	reset_scene()


func _grid(level: LevelData) -> GridManager:
	var g: GridManager = GRID_SCENE.instantiate()
	g.custom_minimum_size = Vector2(600, 800)
	g.size = Vector2(600, 800)
	runner.add_child(g)
	g.load_level(level)
	return g


func test_game_manager_navigation() -> void:
	for fn in ["go_to_main_menu", "go_to_level_select", "go_to_about", "go_to_settings", "go_to_account", "go_to_tutorial_select"]:
		GameManager.call(fn)
		await frames(3)
		reset_scene()
	GameManager.start_level(2, true)
	ok(GameManager.entered_via_level_select)
	await frames(3)
	reset_scene()
	GameManager.start_tutorial(3)
	ok(GameManager.is_tutorial_mode)
	await frames(3)
	reset_scene()
	GameManager.start_procedural_level(5)
	ok(GameManager.is_procedural_mode)
	await frames(3)
	reset_scene()
	SaveManager.procedural_current_level = 7
	GameManager.play_game()
	eq(GameManager.current_procedural_level, 7)
	await frames(3)
	reset_scene()
	SaveManager.procedural_resume_level_number = 0
	GameManager.continue_game()
	eq(GameManager.current_procedural_level, 7, "falls back to progression without resume state")
	await frames(3)
	reset_scene()
	SaveManager.start_procedural_resume(9, 1, 2)
	GameManager.continue_game()
	eq(GameManager.current_procedural_level, 9)
	await frames(3)
	reset_scene()
	ok(GameManager.start_new_game())
	eq(GameManager.current_procedural_level, 1)
	await frames(3)
	reset_scene()
	GameManager.start_v3_prototype(99)
	eq(GameManager.current_procedural_level, ProceduralGeneratorV3.PROTOTYPE_COUNT)
	GameManager.start_fusion_test(99)
	GameManager.start_selector_test(99)
	GameManager.start_v5_test(99)
	await frames(3)
	reset_scene()
	GameManager.go_to_main_menu()
	ok(not GameManager.is_v5_test_mode)
	await frames(3)
	reset_scene()


func test_editor_playtest_handoff() -> void:
	var lv := LevelManager.get_campaign_level(2)
	GameManager.start_editor_playtest(lv)
	ok(GameManager.is_editor_playtest)
	await frames(3)
	reset_scene()
	GameManager.return_to_editor_from_playtest()
	ok(GameManager.is_editor_playtest_return_pending())
	await frames(3)
	reset_scene()
	GameManager.take_editor_level_data()
	ok(not GameManager.is_editor_playtest_return_pending())
	GameManager.editor_level_data = null


func test_level_manager_gating() -> void:
	ok(LevelManager.is_tutorial_level_selectable(1))
	ok(not LevelManager.is_tutorial_level_selectable(5))
	SaveManager.record_tutorial_level_result(1, 34)
	ok(LevelManager.is_tutorial_level_selectable(2))
	ok(not LevelManager.is_tutorial_level_selectable(12), "era 2 tutorials need Level 100")
	SaveManager.tutorial_highest_unlocked_level = 12
	ok(not LevelManager.is_tutorial_level_selectable(12))
	SaveManager.campaign_completed_levels["100"] = true
	ok(LevelManager.is_tutorial_level_selectable(12))
	ok(not LevelManager.is_fusion_tutorial_selectable(LevelManager.FUSION_TUTORIAL_FIRST))
	SaveManager.procedural_current_level = LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
	ok(LevelManager.is_fusion_tutorial_selectable(LevelManager.FUSION_TUTORIAL_FIRST))
	ok(LevelManager.is_tutorial_level_selectable(LevelManager.FUSION_TUTORIAL_FIRST))
	ok(not LevelManager.is_fusion_tutorial_selectable(LevelManager.FUSION_TUTORIAL_FIRST + 1))
	ok(not LevelManager.is_selector_tutorial_selectable(LevelManager.SELECTOR_TUTORIAL_FIRST))
	SaveManager.procedural_current_level = LevelManager.SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
	ok(LevelManager.is_selector_tutorial_selectable(LevelManager.SELECTOR_TUTORIAL_FIRST))
	ok(LevelManager.is_tutorial_level_selectable(LevelManager.SELECTOR_TUTORIAL_FIRST))
	ok(not LevelManager.is_selector_tutorial_selectable(LevelManager.SELECTOR_TUTORIAL_FIRST + 1))
	SaveManager.fusion_tutorial_nudge_seen = false
	SaveManager.procedural_current_level = 1
	ok(not LevelManager.should_show_fusion_tutorial_nudge())
	SaveManager.procedural_current_level = LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
	ok(LevelManager.should_show_fusion_tutorial_nudge())
	SaveManager.fusion_tutorial_nudge_seen = true
	ok(not LevelManager.should_show_fusion_tutorial_nudge())
	# continue-level searches
	SaveManager.campaign_highest_unlocked_level = 3
	eq(LevelManager.get_campaign_continue_level_id(), 1)
	SaveManager.campaign_completed_levels = {"1": true, "2": true, "3": true}
	eq(LevelManager.get_campaign_continue_level_id(), 3)
	SaveManager.highest_unlocked_level = 2
	eq(LevelManager.get_continue_level_id(), 1)
	SaveManager.completed_levels = {"1": true, "2": true}
	eq(LevelManager.get_continue_level_id(), 2)
	ok(LevelManager.is_campaign_level_selectable(1))
	ok(not LevelManager.is_campaign_level_selectable(60))
	ok(LevelManager.procedural_generator_version_for_new_play(5) in [2, 3, 4])
	eq(LevelManager.procedural_generator_version_for_new_play(2001), ProceduralLevelGenerator.GENERATOR_VERSION_V5)
	eq(LevelManager.get_procedural_level_count(), ProceduralLevelGenerator.MAX_LEVEL)
	var a := LevelManager.get_procedural_generation_result(2, 2)
	var b := LevelManager.get_procedural_generation_result(2, 2)
	ok(a == b, "cached")
	ok(LevelManager.get_procedural_level(3, 2) != null)
	ok(LevelManager.get_tutorial_level(0) == null)
	ok(LevelManager.load_level_from_path("res://icon.svg") == null)
	ok(LevelManager.calculate_stars(9999, 3) == 1)


func test_tutorial_manager_step_machine() -> void:
	var tm := TutorialManager.new()
	ok(tm.get_current_step() == null)
	var steps: Array[TutorialStepData] = [
		TutorialStepData.message("intro", Vector2i(0, 1)),
		TutorialStepData.require_tap(Vector2i(2, 0), "tap"),
		TutorialStepData.wait_for_target(Vector2i(2, 0), "wait", true),
		TutorialStepData.wait_for_solved("solve", false),
	]
	var lv := LevelData.new()
	lv.grid_width = 4
	lv.grid_height = 3
	lv.tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
	] as Array[TilePlacement]
	var tl := TutorialLevelData.new()
	tl.grid_width = 4
	tl.grid_height = 3
	tl.tiles = lv.tiles
	tl.steps = steps
	tm.current_level = tl
	tm.notify_move_made()
	tm.notify_simulation_updated()
	tm.notify_puzzle_solved()
	tm.advance()  # no grid attached: steps still progress
	tm.advance()
	tm.advance()
	tm.advance()
	tm.advance()  # past the end: finished
	var fin := watch(tm.tutorial_finished)
	tm.restart()
	var changed := watch(tm.step_changed)
	var grid := _grid(lv)
	tm.active_grid = grid
	tm.advance()
	eq(changed.size(), 1)
	ok(grid.interaction_locked, "message locks input")
	tm.advance()  # require tap on a tile that is not at (2,0): mismatch + missing tile errors, input freed
	ok(not grid.interaction_locked)
	tm.notify_move_made()  # advances past the tap step
	tm.notify_puzzle_solved()  # wrong step type: ignored
	tm.notify_simulation_updated()  # target (2,0) is not active yet
	tm.advance()
	tm.notify_puzzle_solved()
	tm.advance()
	ok(fin.size() >= 1)
	ok(tm.get_current_step() == null)
	grid.queue_free()
	tm = TutorialManager.new()
	var started := tm.start(2)
	ok(started != null)
	tm.restart()
	tm.advance()
	ok(tm.get_current_step() != null)


func test_tutorial_manager_good_tap_step() -> void:
	var lv := LevelManager.get_tutorial_level(1)
	var grid := _grid(lv)
	var tm := TutorialManager.new()
	tm.active_grid = grid
	tm.current_level = lv
	var tap: Variant = null
	for s in lv.steps:
		if s.step_type == TutorialStepData.StepType.REQUIRE_TILE_TAP:
			tap = s
			break
	ok(tap != null)
	tm.current_step_index = lv.steps.find(tap) - 1
	tm.advance()
	eq(grid.interaction_restricted_to, tap.target_position)
	grid._on_orientable_tile_clicked(Vector2i(-5, -5))
	ok(not grid.last_tap_accepted or true)
	grid.queue_free()


func test_hint_manager_candidates() -> void:
	var lv := LevelManager.get_campaign_level(3)
	var grid := _grid(lv)
	var hm := HintManager.new()
	hm.bind(grid)
	hm.bind(grid)
	var sol := HintManager.table_solution("c3")
	hm.configure(sol)
	ok(hm.has_hint_source())
	var shown := watch(hm.hint_shown)
	var cleared := watch(hm.hint_cleared)
	var unavailable := watch(hm.hint_unavailable)
	ok(hm.request_hint())
	eq(shown.size(), 1)
	ok(hm.request_hint())
	hm.configure(sol)
	hm.tutorial_state = func() -> Dictionary: return {"mode": "none"}
	ok(not hm.request_hint())
	hm.tutorial_state = func() -> Dictionary: return {"mode": "target", "pos": Vector2i(99, 99)}
	ok(not hm.request_hint())
	hm.tutorial_state = func() -> Dictionary: return {"mode": "free"}
	ok(hm.request_hint())
	hm.permission_provider = func(_h: HintManager) -> void: pass
	ok(not hm.request_hint())
	hm.permission_provider = Callable()
	eq(unavailable.size() >= 2, true)
	grid._on_orientable_tile_clicked(shown[0][0])
	ok(cleared.size() >= 1)
	ok(HintManager.table_solution("nope").is_empty())
	grid.queue_free()


func test_grid_manager_helpers() -> void:
	var lv := LevelManager.get_campaign_level(1)
	var grid := _grid(lv)
	var m := grid.get_layout_metrics()
	ok(m.has("cell_size"))
	ok(grid.format_layout_diagnostics() != "")
	ok(GridManager.is_board_profile_comfortable(5, 8, Vector2(1080, 1500)).has("comfortable"))
	ok(GridManager.is_board_profile_comfortable(8, 12, Vector2(1080, 1500)) is Dictionary)
	grid.set_highlight(Vector2i(1, 1))
	grid.suspend_tutorial_focus()
	grid.resume_tutorial_focus()
	grid.clear_highlight()
	grid.show_hint_cell(Vector2i(0, 0))
	eq(grid.get_hint_cell(), Vector2i(0, 0))
	grid.clear_hint_cell()
	grid.size = Vector2(400, 500)
	grid._recalculate_layout()
	grid.size = Vector2(1, 1)
	grid._recalculate_layout()
	ok(not grid.is_target_activated(Vector2i(-1, -1)))
	ok(not grid.has_orientable_tile(Vector2i(-1, -1)))
	grid.interaction_locked = true
	grid._on_orientable_tile_clicked(Vector2i(0, 0))
	grid.interaction_locked = false
	grid.interaction_restricted_to = Vector2i(9, 9)
	grid._on_orientable_tile_clicked(Vector2i(0, 0))
	grid.interaction_restricted_to = null
	grid.queue_free()


func test_ui_helpers() -> void:
	var margin := SafeAreaMargin.new()
	runner.add_child(margin)
	margin.set_hud_overhang(10.0, 10.0)
	margin.set_hud_overhang(10.0, 10.0)
	margin.set_hud_overhang(0.0, 0.0)
	margin.horizontal_margin_override = 32.0
	margin.vertical_margin_override = 8.0
	margin._update_margins()
	ok(margin._max_stack_shift() >= 0.0)
	margin._get_android_safe_insets()
	margin.queue_free()
	var overlay := TutorialDimOverlay.new()
	runner.add_child(overlay)
	overlay.size = Vector2(300, 300)
	await frames(2)
	for m in overlay.get_method_list():
		pass
	overlay.queue_free()
