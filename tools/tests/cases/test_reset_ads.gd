extends TestCase
## Gameplay Back icon asset + repeated-Reset monetization: first Reset free, later Resets need a rewarded ad,
## one shared allowance (bottom RESET and Pause -> Restart), No Forced Ads / tutorials / QA sessions free.

var _online: bool
var _gate: bool
var _backend_before: Variant


func before_each() -> void:
	_online = InternetManager.is_online
	_gate = InternetManager.gate_passed
	InternetManager.is_online = true
	InternetManager.gate_passed = true
	_backend_before = AdManager._backend


func after_each() -> void:
	InternetManager.is_online = _online
	InternetManager.gate_passed = _gate
	AdManager._backend = _backend_before
	AdManager._sdk_ready = false
	AdManager._rewarded_ready = false
	AdManager._interstitial_ready = false
	AdManager.state = AdManager.State.IDLE
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, false)
	runner.get_tree().paused = false
	reset_scene()


func _ad_game(show_mode := "reward", level := 3) -> Array:
	var fake := AdBackendFake.new()
	fake.show_mode = show_mode
	AdManager.use_backend(fake)
	AdManager._sdk_ready = true
	fake.load_rewarded()
	await frames(2)
	AdManager._rewarded_ready = true
	GameManager.start_procedural_level(level)
	await frames(4)
	return [current_scene(), fake]


func _grid(game: Node) -> GridManager:
	return game.get_node("%PuzzleGrid")


func _tap_one(game: Node) -> Vector2i:
	var grid := _grid(game)
	var pos: Vector2i = grid.level_data.get_rotatable_tiles()[0].position
	grid._on_orientable_tile_clicked(pos)
	return pos


func _use_free_reset(game: Node) -> void:
	_tap_one(game)
	game._on_reset_pressed()
	eq(game._reset_count, 1)
	eq(game.moves_used, 0)


func test_back_button_matches_settings_art() -> void:
	GameManager.start_procedural_level(3)
	await frames(4)
	var game := current_scene()
	var back: Button = game._back_button
	ok(back is SettingsArtButton, "gameplay Back is the Settings art button")
	eq(back.art.resource_path, "res://assets/ui/settings/bs_btn_settings_back.png")
	ok(not back.has_node("BackIcon"), "round runtime icon no longer used")
	ok(back.size.x >= 96 and back.size.y >= 96, "large touch target kept")
	for c in back.get_children():
		ok(c.mouse_filter == Control.MOUSE_FILTER_IGNORE, "visual child ignores input")
	var art: TextureRect = back.get_child(0)
	ok(art.size.x > 0 and absf(art.size.x / art.size.y - 2171.0 / 724.0) < 0.01, "art not stretched")
	ok(back.pressed.is_connected(game._on_back_pressed), "back callback connected")
	var top: Control = game.get_node("SafeMargin/Layout/TopBar")
	var lvl: Label = game.get_node("%LevelLabel")
	ok(back.get_global_rect().end.x <= lvl.get_global_rect().position.x, "no overlap with LEVEL")
	ok(game.get_node("%MovesLabel") != null and top.get_global_rect().encloses(back.get_global_rect()), "moves label present, back inside HUD")


func test_first_reset_is_free_and_reloads_fresh() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var grid := _grid(game)
	var before := grid.tile_orientations.duplicate()
	_tap_one(game)
	ne(grid.tile_orientations, before)
	game._on_reset_pressed()
	await frames(2)
	ok(game._reset_dialog == null)
	eq(fake.rewarded_shows, 0)
	eq(grid.tile_orientations, before, "fresh puzzle")
	eq(game.moves_used, 0)
	eq(game._reset_count, 1)


func test_second_reset_asks_then_reward_resets() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var grid := _grid(game)
	var before := grid.tile_orientations.duplicate()
	_use_free_reset(game)
	_tap_one(game)
	game._on_reset_pressed()
	await frames(2)
	ok(game._reset_dialog != null)
	var texts: Array[String] = []
	for n in game._reset_dialog.find_children("*", "Label", true, false):
		texts.append(n.text)
	ok(texts.has("RESET LEVEL?"))
	eq(game._reset_dialog._cancel_button.label_text, "CANCEL")
	eq(game._reset_dialog._watch_button.label_text, "WATCH AD")
	eq(fake.rewarded_shows, 0, "no ad before WATCH AD")
	eq(game.moves_used, 1, "nothing reset yet")
	game._reset_dialog._watch_button.pressed.emit()
	await frames(5)
	eq(fake.rewarded_shows, 1)
	eq(game.moves_used, 0)
	eq(grid.tile_orientations, before)
	eq(game._reset_count, 2)
	ok(game._reset_dialog == null and not game._reset_ad_pending)
	# third reset needs another ad
	_tap_one(game)
	game._on_reset_pressed()
	await frames(2)
	ok(game._reset_dialog != null, "repeated reset after a rewarded reset asks again")
	game._reset_dialog._watch_button.pressed.emit()
	await frames(5)
	eq(fake.rewarded_shows, 2)
	eq(game._reset_count, 3)


func test_cancel_does_not_reset() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	_use_free_reset(game)
	_tap_one(game)
	game._on_reset_pressed()
	await frames(2)
	game._reset_dialog._cancel_button.pressed.emit()
	await frames(3)
	ok(game._reset_dialog == null)
	eq(game.moves_used, 1)
	eq(game._reset_count, 1)
	eq(fake.rewarded_shows, 0)
	# Android Back = CANCEL, and does not open Pause
	game._on_reset_pressed()
	await frames(2)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	ok(game._reset_dialog == null and not game._pause_menu.visible)
	eq(game.moves_used, 1)


func test_no_reward_or_failure_does_not_reset() -> void:
	for mode in ["close_no_reward", "fail"]:
		var pair := await _ad_game(mode)
		var game: Node = pair[0]
		_use_free_reset(game)
		_tap_one(game)
		game._on_reset_pressed()
		await frames(2)
		game._reset_dialog._watch_button.pressed.emit()
		await frames(5)
		eq(game.moves_used, 1, "%s must not reset" % mode)
		eq(game._reset_count, 1)
		ok(not game._reset_ad_pending, "state cleared")
		eq(AdManager.state, AdManager.State.IDLE)
		reset_scene()


func test_ad_not_available_shows_notice_and_never_resets() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	_use_free_reset(game)
	_tap_one(game)
	AdManager._rewarded_ready = false
	game._on_reset_pressed()
	await frames(2)
	ok(game._reset_dialog != null and game._reset_dialog.info_only)
	ok(game._reset_dialog._watch_button == null, "no WATCH AD without an ad")
	game._reset_dialog._cancel_button.pressed.emit()
	await frames(2)
	eq(game.moves_used, 1)
	eq(game._reset_count, 1)


func test_count_survives_fresh_load_and_next_level_zeroes_it() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	_use_free_reset(game)
	game._load_current_level(true)
	eq(game._reset_count, 1, "fresh reload keeps the count")
	GameManager.current_procedural_level += 1
	game._load_current_level()
	eq(game._reset_count, 0, "entering another level starts a new allowance")
	# a solved level also starts its Retry with a fresh allowance
	_use_free_reset(game)
	game._on_level_solved()
	eq(game._reset_count, 0)


func test_pause_restart_shares_the_allowance() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var grid := _grid(game)
	var before := grid.tile_orientations.duplicate()
	_tap_one(game)
	game._on_pause_pressed()
	game._on_pause_restart_pressed()
	await frames(2)
	eq(game._reset_count, 1, "Pause -> Restart is the free reset")
	eq(grid.tile_orientations, before, "and genuinely restarts")
	_tap_one(game)
	game._on_reset_pressed()
	await frames(2)
	ok(game._reset_dialog != null, "bottom RESET now needs the ad")
	game._reset_dialog._cancel_button.pressed.emit()
	await frames(2)
	game._on_pause_pressed()
	game._on_pause_restart_pressed()
	await frames(2)
	ok(game._reset_dialog != null, "Pause -> Restart asks too")
	game._reset_dialog._watch_button.pressed.emit()
	await frames(5)
	eq(fake.rewarded_shows, 1)
	eq(game._reset_count, 2)


func test_free_contexts() -> void:
	# No Forced Ads owner
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, true)
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	for i in 3:
		_tap_one(game)
		game._on_reset_pressed()
		eq(game.moves_used, 0)
	ok(game._reset_dialog == null)
	eq(fake.rewarded_shows, 0)
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, false)
	reset_scene()
	# tutorials
	GameManager.start_tutorial(1)
	await frames(4)
	var t := current_scene()
	for i in 3:
		t._on_reset_pressed()
	ok(t._reset_dialog == null and not t._reset_needs_ad())
	eq(fake.rewarded_shows, 0)
	reset_scene()
	# QA sandbox (V3 prototype) session and campaign QA Level Select
	GameManager.start_level(2, true)
	await frames(4)
	var c := current_scene()
	for i in 3:
		c._on_reset_pressed()
	ok(c._reset_dialog == null)
	reset_scene()
	# ads unsupported (desktop)
	AdManager._backend = null
	GameManager.start_procedural_level(3)
	await frames(4)
	var d := current_scene()
	for i in 3:
		d._on_reset_pressed()
	ok(d._reset_dialog == null)


func test_qa_sandbox_session_resets_free() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var was := GameManager.is_v3_prototype_mode
	game._reset_count = 5
	ok(game._reset_needs_ad(), "normal procedural play is gated")
	if LevelManager.SHOW_V3_PROTOTYPE_QA: # QA builds only; production has no such session
		GameManager.is_v3_prototype_mode = true
		ok(not game._reset_needs_ad(), "V3 TEST session never needs a reset ad")
		GameManager.is_v3_prototype_mode = was


func test_reset_ad_leaves_interstitial_counters_and_hint_flow_alone() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	var c0 := SaveManager.ad_completions_since_interstitial
	var t0 := SaveManager.ad_last_interstitial_unix
	_use_free_reset(game)
	game._on_reset_pressed()
	await frames(2)
	game._reset_dialog._watch_button.pressed.emit()
	await frames(5)
	eq(SaveManager.ad_completions_since_interstitial, c0)
	eq(SaveManager.ad_last_interstitial_unix, t0)
	eq(fake.interstitial_shows, 0)
	ok(not game._hint_used_this_attempt, "a reset ad is not a hint")
	# Hint flow unchanged: disclosure -> WATCH AD -> hint granted
	AdManager._rewarded_ready = true
	fake.load_rewarded()
	await frames(2)
	AdManager._rewarded_ready = true
	var shown := watch(game._hint.hint_shown)
	game._on_hint_pressed()
	await frames(2)
	ok(game._hint_dialog != null and game._reset_dialog == null)
	game._hint_dialog._watch_button.pressed.emit()
	await frames(5)
	eq(shown.size(), 1)
	ok(game._hint_used_this_attempt)


func test_double_tap_cannot_stack_dialogs_or_ads() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	_use_free_reset(game)
	_tap_one(game)
	for i in 4:
		game._on_reset_pressed()
	await frames(2)
	var dialogs := 0
	for ch in game.get_children():
		if ch is HintAdDialog and not ch.is_queued_for_deletion():
			dialogs += 1
	eq(dialogs, 1)
	var dlg: HintAdDialog = game._reset_dialog
	dlg._watch_button.pressed.emit()
	dlg._watch_button.pressed.emit()
	game._on_reset_pressed()
	game._on_reset_pressed()
	await frames(5)
	eq(fake.rewarded_shows, 1, "one ad")
	eq(game._reset_count, 2, "one reset")


func test_reset_dialog_respects_internet_blocker() -> void:
	var pair := await _ad_game()
	var game: Node = pair[0]
	var fake: AdBackendFake = pair[1]
	_use_free_reset(game)
	_tap_one(game)
	game._on_reset_pressed()
	await frames(2)
	var dlg: HintAdDialog = game._reset_dialog
	InternetManager.is_online = false
	dlg._watch_button.pressed.emit()
	dlg._cancel_button.pressed.emit()
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(2)
	eq(fake.rewarded_shows, 0)
	ok(game._reset_dialog == dlg)
	eq(game.moves_used, 1)
	InternetManager.is_online = true
	dlg._watch_button.pressed.emit()
	await frames(5)
	eq(fake.rewarded_shows, 1)
	eq(game.moves_used, 0)
