extends TestCase

const FakeNative := preload("res://tools/tests/fakes/fake_native_auth.gd")

var _online: bool
var _auth_state: Dictionary


func before_each() -> void:
	_online = InternetManager.is_online
	_auth_state = {"u": FirebaseAuth._uid, "e": FirebaseAuth._email, "r": FirebaseAuth._refresh_token}


func after_each() -> void:
	InternetManager.is_online = _online
	FirebaseAuth._uid = _auth_state["u"]
	FirebaseAuth._email = _auth_state["e"]
	FirebaseAuth._refresh_token = _auth_state["r"]
	reset_scene()


func _screen() -> Control:
	var s: Control = load("res://scenes/ui/account_screen.tscn").instantiate()
	runner.add_child(s)
	await frames(2)
	return s


func _fill(s: Control, email: String, pw: String, confirm := "") -> void:
	s._email_field.text = email
	s._password_field.text = pw
	s._confirm_password_field.text = confirm


func test_validation_messages() -> void:
	var s := await _screen()
	for case in [["", "x", "Enter a valid email address."], ["nope", "x", "Enter a valid email address."], ["a@b.c", "", "Enter your password."]]:
		_fill(s, case[0], case[1])
		s._on_primary_pressed()
		eq(s._message_label.text, case[2])
	s._on_mode_toggle_pressed()
	ok(s._create_mode)
	_fill(s, "a@b.c", "123", "123")
	s._on_primary_pressed()
	ok(s._message_label.text.contains("at least"))
	_fill(s, "a@b.c", "123456", "654321")
	s._on_primary_pressed()
	eq(s._message_label.text, "Passwords do not match.")
	s._on_mode_toggle_pressed()
	ok(not s._create_mode)
	s._busy = true
	s._on_primary_pressed()
	s._on_forgot_password_pressed()
	s._on_google_continue_pressed()
	s._on_apple_continue_pressed()
	s._busy = false
	s.queue_free()


func test_offline_sign_in_create_and_reset() -> void:
	var s := await _screen()
	InternetManager.is_online = false
	_fill(s, "a@b.c", "secret1")
	s._on_primary_pressed()
	eq(s._message_label.text, "Internet connection required.")
	s._on_mode_toggle_pressed()
	_fill(s, "a@b.c", "secret1", "secret1")
	s._on_primary_pressed()
	eq(s._message_label.text, "Internet connection required.")
	s._on_mode_toggle_pressed()
	s._email_field.text = ""
	s._on_forgot_password_pressed()
	eq(s._message_label.text, "Enter your email address first.")
	s._email_field.text = "a@b.c"
	s._on_forgot_password_pressed()
	eq(s._message_label.text, "Internet connection required.")
	s._on_password_reset_finished(true, "")
	ok(s._message_label.text.contains("Password reset email sent"))
	s.queue_free()


func test_friendly_errors() -> void:
	var s := await _screen()
	for code in ["INVALID_LOGIN_CREDENTIALS", "INVALID_PASSWORD", "EMAIL_NOT_FOUND", "EMAIL_EXISTS", "INVALID_EMAIL", "WEAK_PASSWORD", "OFFLINE", "TOO_MANY_ATTEMPTS_TRY_LATER", "CONFIG_MISSING", "USER_DISABLED", "FEDERATED_USER_ID_ALREADY_LINKED", "CREDENTIAL_ALREADY_IN_USE", "INVALID_IDP_RESPONSE", "NOT_SIGNED_IN", "NO_PENDING_CREDENTIAL", "WHATEVER"]:
		var msg: String = s._friendly_error(code)
		ok(msg != "" and not msg.contains("_"), code)
	s.queue_free()


func test_result_handlers() -> void:
	var s := await _screen()
	s._on_sign_in_finished(false, "INVALID_LOGIN_CREDENTIALS")
	s._on_account_create_finished(false, "EMAIL_EXISTS")
	s._on_account_create_finished(true, "")
	s._pending_google_link = true
	s._on_sign_in_finished(true, "")
	s._pending_google_link = false
	s._pending_apple_link = true
	s._on_sign_in_finished(true, "")
	s._pending_apple_link = false
	s._on_google_sign_in_finished(false, "NEEDS_LINK", true, false)
	ok(s._pending_google_link)
	s._on_google_sign_in_finished(false, "BAD", false, false)
	s._on_google_sign_in_finished(true, "", false, true)
	ok(not s._pending_google_link)
	s._on_google_link_finished(true, "")
	s._on_google_link_finished(false, "OFFLINE")
	s._on_google_link_finished(false, "X")
	s._on_apple_sign_in_finished(false, "NEEDS_LINK", true, false)
	ok(s._pending_apple_link)
	s._on_apple_sign_in_finished(false, "BAD", false, false)
	s._on_apple_sign_in_finished(true, "", false, true)
	s._on_apple_link_finished(true, "")
	s._on_apple_link_finished(false, "OFFLINE")
	s._on_apple_link_finished(false, "X")
	s._pending_google_link = true
	s._pending_apple_link = true
	s._set_create_mode(true)
	ok(not s._pending_google_link and not s._pending_apple_link)
	s._on_auth_state_changed(false)
	s._on_cloud_synced(true)
	s._on_cloud_signed_in_changed(true)
	s._on_native_continue_pressed()
	s.queue_free()


func test_google_android_paths() -> void:
	var s := await _screen()
	s._on_google_continue_pressed()
	ok(s._message_label.text.contains("unavailable"))
	s._on_google_id_token_obtained("tok")
	s._on_google_plugin_failed("boom")
	s._on_google_plugin_cancelled()
	ok(s._google_plugin_instance() == null)
	s.queue_free()


func test_google_ios_paths() -> void:
	var s := await _screen()
	s._start_google_sign_in_ios()
	ok(s._message_label.text.contains("unavailable"))
	var fake := FakeNative.new()
	s._google_web_auth_checked = true
	s._google_web_auth = fake
	s._start_google_sign_in_ios()
	eq(fake.starts.size(), 1)
	ok(fake.starts[0][0].contains("response_type=id_token"))
	fake.start_result = false
	s._start_google_sign_in_ios()
	ok(s._message_label.text.contains("failed"))
	s._on_google_web_auth_completed("app:/cb#state=1&id_token=abc%2Fdef&x=2")
	s._on_google_web_auth_completed("app:/cb#state=1")
	s._on_google_web_auth_completed("app:/cb")
	s._on_google_web_auth_canceled()
	s._on_google_web_auth_failed("nope")
	eq(s._extract_fragment_param("u#a=1&b=2", "b"), "2")
	eq(s._extract_fragment_param("u#a=1", "zz"), "")
	eq(s._extract_fragment_param("nofrag", "a"), "")
	eq(s._random_token(4).length(), 8)
	s.queue_free()


func test_apple_paths() -> void:
	var s := await _screen()
	s._on_apple_continue_pressed()
	ok(s._message_label.text.contains("unavailable"))
	var fake := FakeNative.new()
	s._apple_auth_checked = true
	s._apple_auth = fake
	s._on_apple_continue_pressed()
	eq(fake.scopes_calls.size(), 1)
	fake.identity_token = "jwt".to_utf8_buffer()
	s._on_apple_authorization_completed(fake)
	s._on_apple_authorization_completed(null)
	s._on_apple_authorization_completed(RefCounted.new())
	s._on_apple_authorization_failed("User canceled the request")
	s._on_apple_authorization_failed("other failure")
	ok(s._message_label.text.contains("failed"))
	s.queue_free()


func test_signed_in_view_and_sign_out() -> void:
	FirebaseAuth._uid = "u"
	FirebaseAuth._email = "me@x.y"
	FirebaseAuth._refresh_token = "rt"
	var s := await _screen()
	ok(s._signed_in_view.visible)
	eq(s._email_value_label.text, "me@x.y")
	for case in [[false, true, ""], [true, false, ""], [true, true, ""], [true, true, "2026-01-01T10:20:30"]]:
		CloudSave.is_signed_in = case[0]
		InternetManager.is_online = case[1]
		CloudSave.last_synced_at = case[2]
		s._refresh_cloud_status()
		ok(s._cloud_status_value_label.text.begins_with("Cloud Save:"))
	CloudSave.is_signed_in = false
	CloudSave.last_synced_at = ""
	InternetManager.is_online = true
	s._on_sign_out_pressed()
	ok(s._sign_out_confirm_layer != null)
	s._on_sign_out_pressed()
	var buttons: Array = s._sign_out_confirm_layer.find_children("*", "Button", true, false)
	eq(buttons.size(), 2)
	buttons[0].pressed.emit()
	await frames(2)
	ok(s._sign_out_confirm_layer == null)
	s._on_sign_out_pressed()
	s._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	ok(s._sign_out_confirm_layer == null)
	s._on_sign_out_pressed()
	var b2: Array = s._sign_out_confirm_layer.find_children("*", "Button", true, false)
	b2[1].pressed.emit()
	await frames(2)
	ok(not FirebaseAuth.is_signed_in())
	ok(s._signed_out_view.visible)
	s.queue_free()


func test_focus_and_navigation() -> void:
	var s := await _screen()
	s._on_field_focus_entered(s._email_field)
	s._on_viewport_size_changed()
	await frames(2)
	s._process(0.1)
	s._on_field_focus_exited(s._email_field)
	s._on_viewport_size_changed()
	s._back_button.pressed.emit()
	await frames(3)
	s._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	s.queue_free()
