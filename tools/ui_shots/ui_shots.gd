extends Node
## Dev-only render driver (tools/ is export-excluded). Run NON-headless so real frames exist:
##   godot --path . --resolution 1080x1920 res://tools/ui_shots/ui_shots.tscn -- out=<dir> [only=a,b]
## Saves one PNG per screen into <dir> named <screen>_<height>.png.

const SCREENS := ["main_menu", "settings", "settings_long", "tutorial_select", "level_select", "account", "account_connect", "account_retry", "account_connected", "about", "privacy_policy", "game", "game_tutorial", "pause", "level_complete", "level_complete_3", "level_complete_1", "level_complete_hint", "level_complete_peak", "level_complete_final", "tutorial_complete", "dialog_confirm", "internet_blocker", "age_selection", "hint_ad_dialog", "reset_ad_dialog", "reset_ad_unavailable"]

var _out := ""
var _only: PackedStringArray = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			_out = a.substr(4)
		elif a.begins_with("only="):
			_only = a.substr(5).split(",")
	print("SHOTS start out=", _out, " only=", _only)
	DirAccess.make_dir_recursive_absolute(_out)
	InternetManager._periodic_timer.stop()
	InternetManager._http_request.cancel_request()  # no real probe may overwrite the injected state
	InternetManager.check_in_progress = false
	InternetManager._resolve_check(true)
	SaveManager.campaign_highest_unlocked_level = 14
	SaveManager.record_campaign_level_result(1, 3, 3, 140)
	SaveManager.record_campaign_level_result(2, 6, 2, 140)
	SaveManager.record_campaign_level_result(3, 9, 1, 140)
	SaveManager.record_campaign_level_result(4, 9, 3, 140)
	SaveManager.campaign_highest_unlocked_level = 14
	SaveManager.record_tutorial_level_result(1, 34)
	SaveManager.record_tutorial_level_result(2, 34)
	var names: Array = SCREENS.duplicate()
	for o in _only:
		if not names.has(o):
			names.append(o) # dynamic names: v6_<level>, v6_complete_4000, t37_seq (Stage C-E)
	for s in names:
		if _only.size() > 0 and not (s in _only):
			continue
		await _shoot(s)
	InternetManager._http_request.cancel_request()
	get_tree().quit()
	OS.kill(OS.get_process_id())  # a pending connectivity probe can otherwise stall process exit


func _shoot(name: String) -> void:
	print("SHOTS shoot ", name)
	var node: Node = null
	match name:
		"main_menu": node = load("res://scenes/ui/main_menu.tscn").instantiate()
		"settings", "settings_long":
			# Screenshot tool only: a fake store backend so the store rows render on desktop (never in the shipped game).
			var fake: Node = load("res://tools/tests/fakes/fake_store_backend.gd").new()
			fake.live_price = "CA$1,299.99" if name == "settings_long" else "₹450.00"
			StoreManager._backend = fake
			node = load("res://scenes/ui/settings_menu.tscn").instantiate()
		"tutorial_select": node = load("res://scenes/ui/tutorial_select.tscn").instantiate()
		"level_select": node = load("res://scenes/ui/level_select.tscn").instantiate()
		"account": node = load("res://scenes/ui/account_screen.tscn").instantiate()
		"account_connect", "account_retry", "account_connected":
			# Screenshot tool only: force the Android identity states (isolated project copy).
			SaveManager.age_group = AgeGroup.ADULT_18_PLUS
			PlatformAccount.platform = PlatformAccount.Platform.ANDROID
			PlatformAccount.connected = name == "account_connected"
			PlatformAccount.display_name = "Pat" if PlatformAccount.connected else ""
			PlatformAccount.last_message = "Could not connect to Google Play Games." if name == "account_retry" else ""
			node = load("res://scenes/ui/account_screen.tscn").instantiate()
		"about": node = load("res://scenes/ui/about_screen.tscn").instantiate()
		"privacy_policy": node = load("res://scenes/ui/privacy_policy_screen.tscn").instantiate()
		"age_selection": node = load("res://scenes/ui/age_selection.tscn").instantiate()
		"game", "game_tutorial", "pause", "level_complete", "level_complete_3", "level_complete_1", "level_complete_hint", "level_complete_peak", "level_complete_final", "tutorial_complete", "hint_ad_dialog", "reset_ad_dialog", "reset_ad_unavailable":
			GameManager.is_tutorial_mode = name in ["game_tutorial", "tutorial_complete"]
			GameManager.is_procedural_mode = false
			GameManager.entered_via_level_select = true
			GameManager.current_level_id = 27
			GameManager.current_tutorial_id = 3
			node = load("res://scenes/gameplay/game.tscn").instantiate()
		"t37_seq":
			GameManager.is_tutorial_mode = true
			GameManager.is_procedural_mode = false
			GameManager.entered_via_level_select = true
			GameManager.current_tutorial_id = 37
			node = load("res://scenes/gameplay/game.tscn").instantiate()
		"v6_1", "v6_10", "v6_50", "v6_400", "v6_701", "v6_900", "v6_1400", "v6_2001", "v6_2400", "v6_3001", "v6_3400", "v6_3800", "v6_4000", "v6_complete_4000":
			GameManager.is_tutorial_mode = false
			GameManager.is_procedural_mode = true
			GameManager.entered_via_level_select = false
			GameManager.current_procedural_level = 4000 if name == "v6_complete_4000" else int(name.split("_")[-1])
			SaveManager.procedural_resume_level_number = 0
			SaveManager.procedural_resume_generator_version = 0
			node = load("res://scenes/gameplay/game.tscn").instantiate()
		"dialog_confirm", "internet_blocker":
			node = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(node)
	for i in 14:
		await get_tree().process_frame
	match name:
		"main_menu":
			node._layout_hero_elements()
		"v6_complete_4000":
			node._complete_popup.show_result(31, 3, false, 29, false, false, true, 29, 4000)
			node._complete_popup.skip_presentation()
		"t37_seq":
			await _t37_sequence(node)
		"pause": node._on_pause_pressed()
		"hint_ad_dialog": node.add_child(HintAdDialog.new())
		"reset_ad_dialog": node._open_reset_dialog("RESET LEVEL?", "You've already used your free reset.\n\nWatch a short ad to reset again.", false)
		"reset_ad_unavailable": node._open_reset_dialog("AD NOT AVAILABLE", "Please try again shortly.", true)
		"level_complete", "level_complete_3", "level_complete_1", "level_complete_hint", "level_complete_peak", "level_complete_final":
			var st := 3 if name in ["level_complete_3", "level_complete_peak"] else (1 if name == "level_complete_1" else 2)
			node._complete_popup.show_result(8, st, name != "level_complete_final", 7, false, name == "level_complete_hint", true, 10, 24)
			node._complete_popup.skip_presentation()
		"tutorial_complete": node._tutorial_complete_popup.show_result(false)
		"internet_blocker":
			InternetManager._resolve_check(false)
			InternetManager._resolve_check(false)
		"dialog_confirm":
			SaveManager.procedural_current_level = 12
			node._show_new_game_confirmation()
	for i in 10:
		await get_tree().process_frame
	if name == "level_complete_peak":
		for star in node._complete_popup._stars:
			star.scale = Vector2.ONE * 1.22
			star.rotation_degrees = 4.0
		await get_tree().process_frame
		for i in 3: print("PEAK ", node._complete_popup._stars[i].get_global_rect(), " slot ", node._complete_popup._stars[i].get_parent().get_parent().get_global_rect())
	if name == "pause":
		var glows := node.find_children("*", "ColorRect", true, false).filter(func(c): return c is BeamButtonGlow)
		print("GLOWDBG ", glows.size(), " ", glows[0].size, " ", glows[0].get_global_rect(), " ", glows[0].is_visible_in_tree(), " ", glows[0].material)
		for frac in [0.12, 0.3, 0.55, 0.8]:
			glows[0]._sweeping = true
			glows[0]._sweep_t = frac * glows[0].sweep_duration
			glows[0]._apply()
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/pause_sweep_%d_%d.png" % [_out, int(frac * 100), int(get_viewport().get_visible_rect().size.y)])
	if name == "main_menu":
		var gl := node.find_children("*", "ColorRect", true, false).filter(func(c): return c is BeamButtonGlow)
		for g in gl: print("MGLOW ", g.get_parent().name, " ", g.position, " ", g.size, " ", g.get_global_rect(), " ", g.is_visible_in_tree(), " ", g.get_parent().size)
		for frac in [0.2, 0.6]:
			for i in gl.size():
				gl[i]._sweeping = true
				gl[i]._sweep_t = fmod(frac + i * 0.17, 1.0) * gl[i].sweep_duration
				gl[i]._apply()
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/menu_sweep_%d_%d.png" % [_out, int(frac * 100), int(get_viewport().get_visible_rect().size.y)])
	var img := get_viewport().get_texture().get_image()
	print("SHOTS saving ", name, " ", img.get_size())
	img.save_png("%s/%s_%d.png" % [_out, name, int(get_viewport().get_visible_rect().size.y)])
	node.queue_free()
	InternetManager._resolve_check(true)
	await get_tree().process_frame
	SaveManager.procedural_current_level = 1


## Stage C-E T37 follow-up: renders every step of the Phase Cycle tutorial (the text panel, the highlighted tile, the board) and the
## solved state, one PNG per step, driving it exactly like a player (Continue on MESSAGE steps, the forced tap on REQUIRE_TILE_TAP).
func _t37_sequence(node: Node) -> void:
	var h := int(get_viewport().get_visible_rect().size.y)
	for i in range(8):
		for _f in range(10):
			await get_tree().process_frame
		var step: TutorialStepData = node._tutorial.get_current_step()
		if step == null:
			break
		get_viewport().get_texture().get_image().save_png("%s/t37_step%d_%d.png" % [_out, i, h])
		print("T37 step ", i, " type=", step.step_type, " text=", step.text)
		match step.step_type:
			TutorialStepData.StepType.MESSAGE:
				node._tutorial.advance()
			TutorialStepData.StepType.REQUIRE_TILE_TAP:
				node._grid._on_orientable_tile_clicked(step.target_position)
			_:
				pass
