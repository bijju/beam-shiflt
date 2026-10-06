extends TestCase
## Settings redesign: framed Audio/Account/Privacy & Info sections, new icons, tappable nav rows,
## and the unchanged toggle/navigation/persistence behaviour.

const DIR := "res://assets/ui/settings/"


func after_each() -> void:
	reset_scene()


func _open() -> Control:
	var s: Control = load("res://scenes/ui/settings_menu.tscn").instantiate()
	runner.add_child(s)
	await frames(4)
	return s


func _path(tr: TextureRect) -> String:
	return tr.texture.resource_path


func test_new_assets_are_referenced() -> void:
	var s := await _open()
	eq(_path(s.get_node("%SoundIcon")), DIR + "settings_icon_sound_effects.png")
	eq(_path(s.get_node("%MusicIcon")), DIR + "settings_icon_music.png")
	eq(_path(s.get_node("%PrivacyIcon")), DIR + "settings_icon_privacy.png")
	eq(_path(s.get_node("%PrivacyChevron")), DIR + "settings_icon_chevron_right.png")
	eq(_path(s.get_node("%AboutChevron")), DIR + "settings_icon_chevron_right.png")
	for panel in [s.get_node("SafeMargin/Layout/Scroll/Sections/AudioPanel"), s.get_node("%CloudSection"),
			s.get_node("SafeMargin/Layout/Scroll/Sections/PrivacyPanel")]:
		ok(panel is SettingsSectionFrame)
		eq(panel.frame.texture.resource_path, DIR + "settings_section_panel.png")
		ok(panel.frame is NinePatchRect, "stretch-safe frame")
	s.queue_free()


func test_icons_and_chevrons_ignore_input_and_keep_aspect() -> void:
	var s := await _open()
	for n in ["%SoundIcon", "%MusicIcon", "%PrivacyIcon", "%PrivacyChevron", "%AboutChevron"]:
		var tr: TextureRect = s.get_node(n)
		eq(tr.mouse_filter, Control.MOUSE_FILTER_IGNORE, n)
		eq(tr.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, n)
		ok(tr.size.x <= 96.0, n + " not shown at source size")
	s.queue_free()


func test_nav_rows_have_large_targets_and_whole_row_taps() -> void:
	var s := await _open()
	for b: Button in [s._privacy_policy, s._about]:
		ok(b.size.y >= 96.0, "row tall enough")
		ok(b.size.x >= 600.0, "row spans the panel")
		for c in b.get_node("Row").get_children():
			ok(c.mouse_filter == Control.MOUSE_FILTER_IGNORE, "child never eats the tap")
	s.queue_free()


func test_privacy_about_account_back_navigation() -> void:
	var s := await _open()
	s._privacy_policy.pressed.emit()
	await frames(4)
	eq(current_scene().scene_file_path, GameManager.PRIVACY_POLICY_SCENE)
	reset_scene()
	s.queue_free()
	var s2 := await _open()
	s2._about.pressed.emit()
	await frames(4)
	eq(current_scene().scene_file_path, GameManager.ABOUT_SCENE)
	reset_scene()
	s2.queue_free()
	var s3 := await _open()
	s3._cloud_sign_in.pressed.emit()
	await frames(4)
	eq(current_scene().scene_file_path, GameManager.ACCOUNT_SCENE)
	reset_scene()
	s3.queue_free()
	var s4 := await _open()
	s4._back_button.pressed.emit()
	await frames(4)
	eq(current_scene().scene_file_path, GameManager.MAIN_MENU_SCENE)
	s4.queue_free()


func test_toggles_work_and_persist() -> void:
	var sound_before := SaveManager.sound_enabled
	var music_before := SaveManager.music_enabled
	var s := await _open()
	s._sound_toggle.button_pressed = not sound_before
	s._music_toggle.button_pressed = not music_before
	eq(SaveManager.sound_enabled, not sound_before)
	eq(SaveManager.music_enabled, not music_before)
	s.queue_free()
	var s2 := await _open()
	eq(s2._sound_toggle.button_pressed, not sound_before, "sound state restored on reopen")
	eq(s2._music_toggle.button_pressed, not music_before, "music state restored on reopen")
	s2._sound_toggle.button_pressed = sound_before
	s2._music_toggle.button_pressed = music_before
	s2.queue_free()


func test_account_text_and_version() -> void:
	var s := await _open()
	ok(s._cloud_name.text != "", "account name shown")
	ok(s._cloud_status.text.contains("stored"), "local-progress wording kept")
	ok(not s._cloud_status.text.to_lower().contains("cloud"), "never implies cloud save")
	eq(s._version.text, "BeamShift v%s" % ProjectSettings.get_setting("application/config/version", "1.0.0"))
	s.queue_free()


func test_sections_do_not_expand_into_dead_space() -> void:
	var s := await _open()
	var audio: Control = s.get_node("SafeMargin/Layout/Scroll/Sections/AudioPanel")
	ok(audio.size.y < 400.0, "audio panel is compact: %s" % audio.size.y)
	ok(audio.size.y >= audio.get_combined_minimum_size().y)
	s.queue_free()
