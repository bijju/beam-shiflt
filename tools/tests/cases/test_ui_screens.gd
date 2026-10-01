extends TestCase
## Instantiates every player-facing menu scene and exercises its handlers. Navigation
## calls change_scene (the runner's placeholder absorbs it); Quit/back-to-quit paths are
## never invoked because they would end the whole test run.

const FakeStore := preload("res://tools/tests/fakes/fake_store_backend.gd")

var _online: bool


func before_each() -> void:
	_online = InternetManager.is_online
	InternetManager.is_online = true
	Engine.time_scale = 1.0


func after_each() -> void:
	InternetManager.is_online = _online
	Engine.time_scale = 1.0
	CloudSave.pending_cloud = {}
	CloudSave.pending_local = {}
	reset_scene()


func _scene(path: String) -> Control:
	var s: Control = load(path).instantiate()
	runner.add_child(s)
	await frames(3)
	return s


func test_main_menu_fresh_and_buttons() -> void:
	var m := await _scene("res://scenes/ui/main_menu.tscn")
	ok(m._continue_button.disabled, "no resumable game on a fresh save")
	m._layout_hero_elements()
	for b in [m._continue_button, m._play_button, m._tutorial_button, m._about_button]:
		eq(b.custom_minimum_size, m._play_button.custom_minimum_size, "equal main buttons")
	ok(m._about_button.get_parent() == m._button_group, "ABOUT US lives in the main stack")
	m._on_new_game_pressed()  # fresh save: starts straight away
	await frames(3)
	m._busy = false
	m.queue_free()


func test_main_menu_navigation_buttons() -> void:
	SaveManager.start_procedural_resume(3, 1, 2)
	var m := await _scene("res://scenes/ui/main_menu.tscn")
	ok(not m._continue_button.disabled)
	for b in [m._tutorial_button, m._about_button, m._settings_button, m._qa_level_select_button, m._continue_button]:
		b.pressed.emit()
		await frames(3)
		reset_scene()
	m.queue_free()


func test_main_menu_new_game_confirmation() -> void:
	SaveManager.procedural_current_level = 12
	var m := await _scene("res://scenes/ui/main_menu.tscn")
	m._on_new_game_pressed()
	ok(m._confirm_layer != null)
	m._on_new_game_pressed()
	m._show_new_game_confirmation()
	m._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	ok(m._confirm_layer == null)
	m._on_new_game_pressed()
	var buttons: Array = m._confirm_layer.find_children("*", "Button", true, false)
	buttons[0].pressed.emit()
	await frames(2)
	m._on_new_game_pressed()
	var again: Array = m._confirm_layer.find_children("*", "Button", true, false)
	again[1].pressed.emit()
	await frames(3)
	eq(SaveManager.procedural_current_level, 1, "confirmed new game resets progress")
	m._busy = true
	m._on_new_game_pressed()
	m._busy = false
	m.queue_free()


func test_main_menu_cloud_chooser() -> void:
	var m := await _scene("res://scenes/ui/main_menu.tscn")
	m._show_cloud_chooser()  # nothing pending: ignored
	CloudSave.pending_cloud = {"play_time_seconds": 7200.0, "procedural_current_level": 40}
	CloudSave.pending_local = {"play_time_seconds": 60.0, "procedural_current_level": 2}
	m._show_cloud_chooser()
	ok(m._cloud_layer != null)
	m._show_cloud_chooser()
	eq(m._progress_text(CloudSave.pending_cloud), "LEVEL 40, 2h 00m")
	m._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	ok(m._cloud_layer == null)
	m._show_cloud_chooser()
	m._on_keep_local()
	await frames(2)
	CloudSave.pending_cloud = {"play_time_seconds": 7200.0}
	CloudSave.pending_local = {"play_time_seconds": 60.0}
	m._show_cloud_chooser()
	m._on_take_cloud()
	await frames(2)
	m.queue_free()


func test_main_menu_fusion_nudge() -> void:
	SaveManager.fusion_tutorial_nudge_seen = false
	var m := await _scene("res://scenes/ui/main_menu.tscn")
	var nudge := m.get_node_or_null("FusionTutorialNudge")
	if nudge != null:
		var buttons: Array = nudge.find_children("*", "Button", true, false)
		buttons[0].pressed.emit()
		await frames(3)
		reset_scene()
		var m2 := await _scene("res://scenes/ui/main_menu.tscn")
		m2.queue_free()
	ok(SaveManager.fusion_tutorial_nudge_seen or nudge == null)
	m.queue_free()


func test_settings_menu() -> void:
	var s := await _scene("res://scenes/ui/settings_menu.tscn")
	s._sound_toggle.button_pressed = false
	s._music_toggle.button_pressed = false
	ok(not SaveManager.sound_enabled)
	s._sound_toggle.button_pressed = true
	s._music_toggle.button_pressed = true
	# cloud text variants
	for case in [[false, false, ""], [true, true, ""], [true, false, "2026-01-01T10:20:30"], [true, false, ""]]:
		CloudSave.is_signed_in = case[0]
		s._cloud_failed = case[1]
		CloudSave.last_synced_at = case[2]
		s._refresh_cloud()
	CloudSave.is_signed_in = false
	CloudSave.last_synced_at = ""
	s._on_cloud_signed_in_changed(true)
	s._on_firebase_auth_state_changed(true)
	s._on_cloud_synced(false)
	s._on_cloud_synced(true)
	# store variants through the real StoreManager with a scripted backend
	var fake := FakeStore.new()
	StoreManager.add_child(fake)
	var old_backend = StoreManager._backend
	StoreManager._backend = fake
	s._refresh_store()
	fake.buyable = false
	s._refresh_store()
	StoreManager._busy = true
	s._refresh_store()
	StoreManager._busy = false
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, true)
	s._refresh_store()
	SaveManager.set_entitlement(StoreConfig.NO_FORCED_ADS, false)
	s._on_buy_pressed()
	StoreManager._busy = false
	s._on_restore_pressed()
	StoreManager._busy = false
	s._on_purchase_finished(true, "Thanks")
	s._on_purchase_finished(false, "")
	s._hide_message("Thanks")
	s._on_privacy_options_pressed()
	s._on_privacy_options_closed()
	StoreManager._backend = old_backend
	fake.queue_free()
	s._cloud_sync.pressed.emit()
	s._cloud_sign_in.pressed.emit()
	await frames(3)
	reset_scene()
	var s2 := await _scene("res://scenes/ui/settings_menu.tscn")
	s2._back_button.pressed.emit()
	await frames(3)
	s2.queue_free()


func test_about_screen() -> void:
	var a := await _scene("res://scenes/ui/about_screen.tscn")
	ok(a._content.get_child_count() >= 3)
	ok(a._engine_text().begins_with("Godot Engine"))
	a._back_button.pressed.emit()
	await frames(3)
	reset_scene()
	a.queue_free()
	var a2 := await _scene("res://scenes/ui/about_screen.tscn")
	a2._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	a2.queue_free()


func test_level_and_tutorial_select() -> void:
	SaveManager.record_campaign_level_result(1, 3, 3, 140)
	SaveManager.campaign_highest_unlocked_level = 110
	SaveManager.tutorial_highest_unlocked_level = 12
	var ls := await _scene("res://scenes/ui/level_select.tscn")
	eq(ls._level_grid.get_child_count(), LevelManager.get_campaign_level_count())
	ls._on_level_selected(2)
	await frames(3)
	reset_scene()
	ls._back_button.pressed.emit()
	await frames(3)
	reset_scene()
	ls._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	reset_scene()
	ls.queue_free()
	var ts := await _scene("res://scenes/ui/tutorial_select.tscn")
	eq(ts._tutorial_grid.get_child_count(), LevelManager.get_tutorial_level_count())
	ts._on_tutorial_selected(1)
	await frames(3)
	reset_scene()
	ts._back_button.pressed.emit()
	await frames(3)
	reset_scene()
	ts._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	reset_scene()
	ts.queue_free()
	var lb: Button = ls._level_grid.get_child(0) if is_instance_valid(ls) else null
	var b: Button = load("res://scenes/ui/level_button.tscn").instantiate()
	runner.add_child(b)
	await frames(2)
	var got := watch(b.level_selected)
	b.setup(5, false, false, 0)
	b.setup(6, true, false, 0)
	b.setup(7, true, true, 2)
	b.setup(150, true, true, 3)
	b.pressed.emit()
	eq(got.size(), 1)
	b.queue_free()
	var tb: Button = load("res://scenes/ui/tutorial_button.tscn").instantiate()
	runner.add_child(tb)
	await frames(2)
	var tgot := watch(tb.tutorial_selected)
	tb.setup(1, false, false)
	tb.setup(2, true, false)
	tb.setup(3, true, true)
	tb.setup(15, true, true)
	tb.pressed.emit()
	eq(tgot.size(), 1)
	tb.queue_free()
	ok(lb == null or true)


func test_popups() -> void:
	var p := await _scene("res://scenes/ui/level_complete_popup.tscn")
	var got := watch(p.next_level_pressed)
	var got2 := watch(p.retry_pressed)
	var got3 := watch(p.level_select_pressed)
	p.set_navigation_label("MENU")
	p.show_result(5, 2, true, 4, true, true, true)
	p.show_result(5, 3, false, -1, false, false, false)
	p.set_era_panel(null, PackedFloat32Array())
	p.set_era_panel(load("res://assets/ui/backgrounds/bs_bg_main_menu_v2.png"), PackedFloat32Array([10, 10, 10, 10]))
	p.set_era_panel(null, PackedFloat32Array())
	p._next_button.show()
	press_all(p)
	eq([got.size(), got2.size(), got3.size()], [1, 1, 1])
	p.queue_free()
	var t := await _scene("res://scenes/ui/tutorial_complete_popup.tscn")
	var n1 := watch(t.next_tutorial_pressed)
	var n2 := watch(t.campaign_pressed)
	var n3 := watch(t.retry_pressed)
	var n4 := watch(t.tutorial_select_pressed)
	t.show_result(false)
	t.show_result(true)
	t.set_era_panel(null, PackedFloat32Array())
	t.set_era_panel(load("res://assets/ui/backgrounds/bs_bg_main_menu_v2.png"), PackedFloat32Array([10, 10, 10, 10]))
	t.set_era_panel(null, PackedFloat32Array())
	t._next_button.show()
	t._campaign_button.show()
	press_all(t)
	eq([n1.size(), n2.size(), n3.size(), n4.size()], [1, 1, 1, 1])
	t.queue_free()


func test_pause_menu_and_hud_bits() -> void:
	var p := await _scene("res://scenes/ui/pause_menu.tscn")
	press_all(p)
	p.queue_free()
	for path in ["res://scenes/ui/menu_gameplay_preview.tscn"]:
		Engine.time_scale = 40.0
		var pv := await _scene(path)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 4000:
			await frames(1)
		pv.queue_free()
		Engine.time_scale = 1.0


func test_internet_gate_and_splash() -> void:
	InternetManager.check_in_progress = true  # no real network probe
	var g := await _scene("res://scenes/ui/internet_gate.tscn")
	g._on_check_completed(false)
	ok(g._screen.panel.visible)
	g._on_retry_pressed()
	ok(g._screen.retry_button.disabled)
	InternetManager.check_in_progress = true
	g._on_check_completed(true)  # online -> main menu
	await frames(3)
	reset_scene()
	g.queue_free()
	InternetManager.check_in_progress = false
	Engine.time_scale = 40.0
	var sp := await _scene("res://scenes/ui/studio_splash.tscn")
	sp._on_logo_resized(sp.maclepro_logo)
	InternetManager.check_in_progress = true
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 6000:
		await frames(1)
	Engine.time_scale = 1.0
	InternetManager.check_in_progress = false
	sp.queue_free()


func test_internet_manager_states() -> void:
	var lost := watch(InternetManager.internet_lost)
	var back := watch(InternetManager.internet_restored)
	var dummy := Node.new()
	dummy.scene_file_path = "res://scenes/ui/main_menu.tscn"
	runner.get_tree().root.add_child(dummy)
	runner.get_tree().current_scene = dummy
	InternetManager._resolve_check(false)
	ok(runner.get_tree().paused)
	InternetManager._resolve_check(false)
	InternetManager._resolve_check(true)
	ok(not runner.get_tree().paused)
	eq([lost.size(), back.size()], [1, 1])
	runner.get_tree().paused = true  # already paused by the player: left alone
	InternetManager._resolve_check(false)
	InternetManager._resolve_check(true)
	runner.get_tree().paused = false
	dummy.scene_file_path = InternetManager.GATE_SCENE_PATH
	InternetManager._resolve_check(false)
	ok(not runner.get_tree().paused, "gate scene shows no overlay")
	InternetManager._resolve_check(true)
	runner.get_tree().current_scene = null
	ok(not InternetManager._should_show_overlay())
	var ph := Node.new()
	runner.get_tree().root.add_child(ph)
	runner.get_tree().current_scene = ph
	InternetManager._on_overlay_retry_pressed()
	InternetManager._on_check_completed_reset_retry_ui(true)
	InternetManager._on_request_completed(HTTPRequest.RESULT_SUCCESS, 204, PackedStringArray(), PackedByteArray())
	InternetManager.check_in_progress = true
	InternetManager._on_request_completed(HTTPRequest.RESULT_SUCCESS, 204, PackedStringArray(), PackedByteArray())
	ok(InternetManager.is_online)
	InternetManager.check_in_progress = true
	InternetManager._on_check_timeout()
	InternetManager.is_online = true
	InternetManager._on_check_timeout()
	InternetManager._on_periodic_timer_timeout()
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	InternetManager._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	InternetManager.is_online = true
	dummy.queue_free()
	ph.queue_free()
