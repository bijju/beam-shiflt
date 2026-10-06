extends TestCase
## Account screen + PlatformAccount: local-only profile, optional Play Games / Apple identity.

var _state: Dictionary


func before_each() -> void:
	var a := PlatformAccount
	_state = {"p": a.platform, "c": a.connected, "n": a.display_name, "b": a.busy, "m": a.last_message}


func after_each() -> void:
	var a := PlatformAccount
	a.platform = _state["p"]
	a.connected = _state["c"]
	a.display_name = _state["n"]
	a.busy = _state["b"]
	a.last_message = _state["m"]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlatformAccount.SESSION_PATH))
	reset_scene()


func _screen() -> Control:
	var s: Control = load("res://scenes/ui/account_screen.tscn").instantiate()
	runner.add_child(s)
	await frames(2)
	return s


func test_desktop_is_local_profile_only() -> void:
	PlatformAccount.platform = PlatformAccount.Platform.NONE
	PlatformAccount.connected = false
	var s := await _screen()
	ok(not PlatformAccount.is_supported())
	ok(not s._action_button.visible)
	ok(s._status_label.text.contains("stored locally"))
	PlatformAccount.sign_in() # no-op, must not crash or block
	ok(not PlatformAccount.connected)
	s.queue_free()


func test_android_states() -> void:
	SaveManager.age_group = AgeGroup.ADULT_18_PLUS # Play Games is only offered after a 13+ age choice
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	PlatformAccount.connected = false
	PlatformAccount.display_name = ""
	var s := await _screen()
	eq(s._service_label.text, "GOOGLE PLAY GAMES")
	ok(s._connect_button.visible and not s._retry_button.visible and not s._action_button.visible)
	eq(s._status_label.text, "Not connected")
	# plugin absent (no client): a connect attempt fails gracefully, gameplay unaffected
	PlatformAccount.sign_in()
	ok(PlatformAccount.last_message.contains("unavailable"))
	ok(not PlatformAccount.busy)
	ok(s._retry_button.visible and not s._connect_button.visible and not s._action_button.visible)
	# fake "available": authentication callbacks
	PlatformAccount._on_play_authenticated(true)
	PlatformAccount._on_player_loaded(PlayGamesPlayer.new({"displayName": "Pat"}))
	eq(s._status_label.text, "Connected")
	eq(s._name_label.text, "Pat")
	ok(not s._action_button.visible and not s._connect_button.visible and not s._retry_button.visible)
	# failed sign-in after an attempt
	PlatformAccount.connected = false
	PlatformAccount.busy = true
	PlatformAccount._on_play_authenticated(false)
	ok(PlatformAccount.last_message != "")
	ok(not PlatformAccount.connected)
	s.queue_free()


func _android_screen() -> Control:
	SaveManager.age_group = AgeGroup.ADULT_18_PLUS
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	PlatformAccount.connected = false
	PlatformAccount.display_name = ""
	PlatformAccount.last_message = ""
	PlatformAccount.busy = false
	return await _screen()


func test_back_button_matches_settings_art() -> void:
	var s := await _screen()
	var settings: Control = load("res://scenes/ui/settings_menu.tscn").instantiate()
	runner.add_child(settings)
	await frames(2)
	var b: SettingsArtButton = s._back_button
	ok(b is SettingsArtButton)
	eq(b.art.resource_path, "res://assets/ui/settings/bs_btn_settings_back.png")
	eq(b.art.resource_path, settings.find_child("BackButton", true, false).art.resource_path)
	eq(b.content_rect, settings.find_child("BackButton", true, false).content_rect)
	ok(b.size.x >= 100.0 and b.size.y >= 100.0, "Back touch target")
	ok(b.text == "")
	var wired := false
	for c in b.pressed.get_connections():
		if c["callable"] == Callable(GameManager, "go_to_settings"):
			wired = true
	ok(wired, "Back still goes to Settings")
	settings.queue_free()
	s.queue_free()


func test_connect_retry_art_input_and_targets() -> void:
	var s := await _android_screen()
	eq(s._connect_button.art.resource_path, "res://assets/ui/account/bs_btn_account_connect.png")
	eq(s._retry_button.art.resource_path, "res://assets/ui/account/bs_btn_account_retry.png")
	for b: SettingsArtButton in [s._connect_button, s._retry_button, s._back_button]:
		ok(b.size.y >= 96.0 and b.size.x >= 200.0, "touch target %s" % b.name)
		ok(b.text == "" and b.get_child(0).mouse_filter == Control.MOUSE_FILTER_IGNORE, "art ignores input")
		var glows := b.get_children().filter(func(c): return c is BeamButtonGlow)
		eq(glows.size(), 1)
		eq(glows[0].mouse_filter, Control.MOUSE_FILTER_IGNORE)
		ok(b.mouse_filter != Control.MOUSE_FILTER_IGNORE, "button owns input")
	ok(s.get_rect().encloses(s._connect_button.get_global_rect()))
	s.queue_free()


func test_connect_retry_flow_and_exclusivity() -> void:
	var s := await _android_screen()
	ok(s._connect_button.visible and not s._retry_button.visible)
	s._connect_button.pressed.emit() # no plugin client here: fails gracefully -> RETRY
	await frames(1)
	ok(PlatformAccount.last_message != "")
	ok(s._retry_button.visible and not s._connect_button.visible)
	ok(s._message_label.visible)
	s._retry_button.pressed.emit() # retry re-enters sign_in(): message cleared, then fails again
	await frames(1)
	ok(not (s._retry_button.visible and s._connect_button.visible))
	PlatformAccount.last_message = ""
	PlatformAccount.busy = true
	PlatformAccount.changed.emit()
	ok(s._connect_button.disabled)
	PlatformAccount.busy = false
	PlatformAccount.connected = true
	PlatformAccount.changed.emit()
	ok(not s._connect_button.visible and not s._retry_button.visible and not s._action_button.visible)
	PlatformAccount.connected = false
	PlatformAccount.last_message = ""
	PlatformAccount.changed.emit()
	ok(s._connect_button.visible and not s._retry_button.visible)
	ok(not s._message_label.visible)
	s.queue_free()


func test_failed_signin_keeps_local_progress_and_age_gate() -> void:
	var level_before := SaveManager.highest_unlocked_level
	SaveManager.age_group = AgeGroup.CHILD_12_OR_YOUNGER
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	var s := await _screen()
	ok(not PlatformAccount.is_supported())
	ok(not s._connect_button.visible and not s._retry_button.visible and not s._action_button.visible)
	s.queue_free()
	SaveManager.age_group = AgeGroup.ADULT_18_PLUS
	s = await _android_screen()
	s._connect_button.pressed.emit()
	ok(SaveManager.save_game(), "guest/local save works after a failed sign-in")
	eq(SaveManager.highest_unlocked_level, level_before)
	s.queue_free()


func test_ios_apple_flow() -> void:
	PlatformAccount.platform = PlatformAccount.Platform.IOS
	PlatformAccount.connected = false
	PlatformAccount.display_name = ""
	var s := await _screen()
	eq(s._service_label.text, "SIGN IN WITH APPLE")
	eq(s._action_button.text, "SIGN IN")
	PlatformAccount.sign_in() # no extension on desktop -> graceful failure
	ok(PlatformAccount.last_message.contains("unavailable"))
	# cancel: silent; real failure: message
	PlatformAccount.busy = true
	PlatformAccount._on_apple_failed("The user canceled the request")
	eq(PlatformAccount.last_message, "")
	PlatformAccount._on_apple_failed("boom")
	ok(PlatformAccount.last_message.contains("failed"))
	PlatformAccount._on_apple_completed(RefCounted.new()) # unsupported credential
	ok(not PlatformAccount.connected)
	PlatformAccount._on_apple_completed(FakeAppleCredential.new())
	ok(PlatformAccount.connected)
	eq(s._status_label.text, "Connected")
	eq(s._action_button.text, "SIGN OUT")
	# the identity persists; sign out clears only the identity, never local progress
	var level_before := SaveManager.highest_unlocked_level
	PlatformAccount.connected = false
	PlatformAccount._load_apple_session()
	ok(PlatformAccount.connected)
	s._on_action_pressed()
	ok(not PlatformAccount.connected)
	eq(SaveManager.highest_unlocked_level, level_before)
	s.queue_free()


func test_sign_in_is_optional_and_offline_safe() -> void:
	var online := InternetManager.is_online
	InternetManager.is_online = false
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	PlatformAccount.sign_in()
	ok(not PlatformAccount.connected)
	ok(SaveManager.save_game(), "local save works without any account or network")
	InternetManager.is_online = online


func test_no_firebase_runtime() -> void:
	ok(not ProjectSettings.has_setting("autoload/FirebaseAuth"))
	ok(not ProjectSettings.has_setting("autoload/CloudSave"))
	ok(not FileAccess.file_exists("res://scripts/managers/firebase_auth.gd"))
	ok(not DirAccess.dir_exists_absolute("res://scripts/firebase"))


class FakeAppleCredential extends RefCounted:
	var identity_token := PackedByteArray([1, 2, 3])
	var full_name = null

	func get_identity_token() -> PackedByteArray:
		return identity_token
