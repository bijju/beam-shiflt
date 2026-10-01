extends TestCase

const FakeAuth := preload("res://tools/tests/fakes/fake_firebase_auth.gd")

var _online: bool
var _cache: Dictionary


func before_each() -> void:
	_online = InternetManager.is_online
	_cache = FirebaseConfig._cache
	FirebaseConfig._cache = {"web_api_key": "test-key"}
	InternetManager.is_online = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FakeAuth.SESSION_FILE))


func after_each() -> void:
	InternetManager.is_online = _online
	FirebaseConfig._cache = _cache
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FakeAuth.SESSION_FILE))


func _auth() -> Node:
	var a := FakeAuth.new()
	runner.add_child(a)
	return a


func _session(uid := "u1", email := "a@b.c") -> Dictionary:
	return {"ok": true, "json": {"localId": uid, "email": email, "idToken": "id", "refreshToken": "rt", "expiresIn": "3600"}}


func test_create_sign_in_and_out() -> void:
	var a := _auth()
	var created := watch(a.account_create_finished)
	var states := watch(a.auth_state_changed)
	a.queue.append(_session())
	a.create_account("a@b.c", "secret1")
	a.create_account("a@b.c", "secret1")  # in-flight: ignored
	await frames(2)
	eq(created.size(), 1)
	ok(created[0][0])
	ok(a.is_signed_in())
	eq(a.get_uid(), "u1")
	eq(a.get_email(), "a@b.c")
	eq(a.get_id_token(), "id")
	ok(a.has_refresh_token())
	ok(FileAccess.file_exists(FakeAuth.SESSION_FILE))
	var gen: int = a.get_session_generation()
	a.sign_out()
	ok(not a.is_signed_in())
	eq(a.get_session_generation(), gen + 1)
	ok(not FileAccess.file_exists(FakeAuth.SESSION_FILE))
	eq(states.size(), 2)
	var signed := watch(a.sign_in_finished)
	a.queue.append({"ok": false, "json": {"error": {"message": "INVALID_LOGIN_CREDENTIALS"}}, "err": "INVALID_LOGIN_CREDENTIALS"})
	a.sign_in("a@b.c", "bad")
	await frames(2)
	eq(signed[0][1], "INVALID_LOGIN_CREDENTIALS")
	a.queue.append(_session())
	a.sign_in("a@b.c", "good")
	a.sign_in("a@b.c", "good")
	await frames(2)
	ok(a.is_signed_in())
	a.queue_free()


func test_offline_and_config_missing() -> void:
	var a := _auth()
	var c := watch(a.account_create_finished)
	var s := watch(a.sign_in_finished)
	var r := watch(a.password_reset_finished)
	var g := watch(a.google_sign_in_finished)
	var ap := watch(a.apple_sign_in_finished)
	InternetManager.is_online = false
	a.create_account("a", "b")
	a.sign_in("a", "b")
	a.send_password_reset("a")
	a.sign_in_with_google_id_token("tok")
	a.sign_in_with_apple_id_token("tok")
	eq(c[0][1], "OFFLINE")
	eq(s[0][1], "OFFLINE")
	eq(r[0][1], "OFFLINE")
	eq(g[0][1], "OFFLINE")
	eq(ap[0][1], "OFFLINE")
	InternetManager.is_online = true
	FirebaseConfig._cache = {"web_api_key": ""}
	a.create_account("a", "b")
	a.sign_in("a", "b")
	a.send_password_reset("a")
	a.sign_in_with_google_id_token("tok")
	a.sign_in_with_apple_id_token("tok")
	eq(c[1][1], "CONFIG_MISSING")
	eq(s[1][1], "CONFIG_MISSING")
	eq(r[1][1], "CONFIG_MISSING")
	eq(g[1][1], "CONFIG_MISSING")
	eq(ap[1][1], "CONFIG_MISSING")
	FirebaseConfig._cache = {"web_api_key": "k"}
	a.sign_in_with_google_id_token("")
	a.sign_in_with_apple_id_token("")
	eq(g[2][1], "INVALID_IDP_RESPONSE")
	eq(ap[2][1], "INVALID_IDP_RESPONSE")
	a.queue_free()


func test_password_reset() -> void:
	var a := _auth()
	var r := watch(a.password_reset_finished)
	a.queue.append({"ok": true, "json": {}})
	a.send_password_reset("a@b.c")
	a.queue.append({"ok": false, "json": {}, "err": "EMAIL_NOT_FOUND"})
	a.send_password_reset("x@b.c")
	await frames(2)
	eq(r.size(), 2)
	ok(r[0][0])
	ok(not r[1][0])
	a.queue_free()


func test_google_flow_with_link() -> void:
	var a := _auth()
	var g := watch(a.google_sign_in_finished)
	var l := watch(a.google_link_finished)
	a.link_pending_google_credential()
	eq(l[0][1], "NO_PENDING_CREDENTIAL")
	a.queue.append({"ok": true, "json": {"needConfirmation": true, "email": "e@x.y"}})
	a.sign_in_with_google_id_token("gt")
	a.sign_in_with_google_id_token("gt")
	await frames(2)
	eq(g[0][1], "NEEDS_LINK")
	ok(a.has_pending_google_link())
	eq(a.pending_google_link_email(), "e@x.y")
	a.link_pending_google_credential()  # not signed in
	eq(l[1][1], "NOT_SIGNED_IN")
	ok(not a.has_pending_google_link())
	a.queue.append({"ok": true, "json": {"needConfirmation": true, "email": "e@x.y"}})
	a.sign_in_with_google_id_token("gt")
	await frames(2)
	a.queue.append(_session())
	a.sign_in("e@x.y", "pw")
	await frames(2)
	InternetManager.is_online = false
	a.link_pending_google_credential()
	eq(l[2][1], "OFFLINE")
	ok(a.has_pending_google_link(), "offline keeps pending")
	InternetManager.is_online = true
	FirebaseConfig._cache = {"web_api_key": ""}
	a.link_pending_google_credential()
	eq(l[3][1], "CONFIG_MISSING")
	FirebaseConfig._cache = {"web_api_key": "k"}
	a.queue.append({"ok": true, "json": {"needConfirmation": true, "email": "e@x.y"}})
	a.sign_in_with_google_id_token("gt2")
	await frames(2)
	a.queue.append(_session())
	a.link_pending_google_credential()
	a.link_pending_google_credential()
	await frames(2)
	ok(l[4][0])
	a.queue.append({"ok": true, "json": {"localId": "u2", "email": "n@x.y", "idToken": "i", "refreshToken": "r", "isNewUser": true}})
	a.sign_in_with_google_id_token("gt3")
	await frames(2)
	ok(g[g.size() - 1][0] and g[g.size() - 1][3])
	a.queue.append({"ok": false, "json": {}, "err": "BAD"})
	a.sign_in_with_google_id_token("gt4")
	await frames(2)
	eq(g[g.size() - 1][1], "BAD")
	a.queue.append({"ok": true, "json": {"needConfirmation": true}})
	a.sign_in_with_google_id_token("gt5")
	await frames(2)
	a.cancel_pending_google_link()
	ok(not a.has_pending_google_link())
	a.queue_free()


func test_apple_flow_with_link() -> void:
	var a := _auth()
	var g := watch(a.apple_sign_in_finished)
	var l := watch(a.apple_link_finished)
	a.link_pending_apple_credential()
	eq(l[0][1], "NO_PENDING_CREDENTIAL")
	a.queue.append({"ok": true, "json": {"needConfirmation": true, "email": "e@x.y"}})
	a.sign_in_with_apple_id_token("at", "nonce")
	a.sign_in_with_apple_id_token("at", "nonce")
	await frames(2)
	eq(g[0][1], "NEEDS_LINK")
	eq(a.pending_apple_link_email(), "e@x.y")
	a.link_pending_apple_credential()
	eq(l[1][1], "NOT_SIGNED_IN")
	a.queue.append({"ok": true, "json": {"needConfirmation": true}})
	a.sign_in_with_apple_id_token("at", "nonce")
	await frames(2)
	a.queue.append(_session())
	a.sign_in("e@x.y", "pw")
	await frames(2)
	InternetManager.is_online = false
	a.link_pending_apple_credential()
	eq(l[2][1], "OFFLINE")
	InternetManager.is_online = true
	FirebaseConfig._cache = {"web_api_key": ""}
	a.link_pending_apple_credential()
	eq(l[3][1], "CONFIG_MISSING")
	FirebaseConfig._cache = {"web_api_key": "k"}
	a.queue.append({"ok": true, "json": {"needConfirmation": true}})
	a.sign_in_with_apple_id_token("at2", "n2")
	await frames(2)
	a.queue.append({"ok": false, "json": {}, "err": "CREDENTIAL_ALREADY_IN_USE"})
	a.link_pending_apple_credential()
	a.link_pending_apple_credential()
	await frames(2)
	eq(l[4][1], "CREDENTIAL_ALREADY_IN_USE")
	a.queue.append({"ok": true, "json": {"localId": "u3", "email": "n@x.y", "idToken": "i", "refreshToken": "r", "isNewUser": true}})
	a.sign_in_with_apple_id_token("at3")
	await frames(2)
	ok(g[g.size() - 1][0])
	a.queue.append({"ok": false, "json": {}, "err": "BAD"})
	a.sign_in_with_apple_id_token("at4")
	await frames(2)
	eq(g[g.size() - 1][1], "BAD")
	a.queue.append({"ok": true, "json": {"needConfirmation": true}})
	a.sign_in_with_apple_id_token("at5")
	await frames(2)
	ok(a.has_pending_apple_link())
	a.cancel_pending_apple_link()
	ok(not a.has_pending_apple_link())
	a.queue_free()


func test_token_refresh_paths() -> void:
	var a := _auth()
	var t := watch(a.token_refresh_finished)
	a.refresh_token()
	eq(t[0][1], "NO_REFRESH_TOKEN")
	ok(not await a.ensure_valid_token())
	a.queue.append(_session())
	a.sign_in("a", "b")
	await frames(2)
	ok(await a.ensure_valid_token(), "fresh token needs no refresh")
	a._token_expires_at = 0.0
	InternetManager.is_online = false
	ok(not await a.ensure_valid_token())
	a.refresh_token()
	eq(t[1][1], "OFFLINE")
	InternetManager.is_online = true
	a.queue.append({"ok": true, "json": {"user_id": "u1", "id_token": "n", "refresh_token": "r2", "expires_in": "3600"}})
	ok(await a.ensure_valid_token())
	eq(a.get_id_token(), "n")
	a._token_expires_at = 0.0
	a.queue.append({"ok": false, "json": {}, "err": "NETWORK_ERROR"})
	a.refresh_token()
	await frames(2)
	ok(a.is_signed_in(), "network failure keeps the session")
	a.queue.append({"ok": false, "json": {}, "err": "TOKEN_EXPIRED"})
	a.refresh_token()
	await frames(2)
	ok(not a.is_signed_in(), "dead token clears it")
	a._refresh_token = "rt"
	FirebaseConfig._cache = {"web_api_key": ""}
	a.refresh_token()
	eq(t[t.size() - 1][1], "CONFIG_MISSING")
	a.queue_free()


func test_superseded_response_is_dropped() -> void:
	var a := _auth()
	var s := watch(a.sign_in_finished)
	a.queue.append(_session())
	a.sign_in("a", "b")
	a.sign_out()
	await frames(2)
	eq(s.size(), 0)
	a._refresh_token = "rt"
	a._uid = "u"
	var t := watch(a.token_refresh_finished)
	a.queue.append(_session())
	a.refresh_token()
	a.sign_out()
	await frames(2)
	eq(t[0][1], "SUPERSEDED")
	a.queue_free()


func test_session_restore_from_disk() -> void:
	var f := FileAccess.open(FakeAuth.SESSION_FILE, FileAccess.WRITE)
	f.store_string('{"uid":"u9","email":"z@z.z","refresh_token":"rtok"}')
	f.close()
	var a := FakeAuth.new()
	a.queue.append({"ok": true, "json": {"user_id": "u9", "id_token": "i", "refresh_token": "rtok2", "expires_in": "3600"}})
	var restored := watch(a.session_restore_finished)
	runner.add_child(a)
	await frames(3)
	ok(a.is_signed_in())
	eq(restored.size(), 1)
	a._on_internet_restored()
	a.queue_free()
	for bad in ["nope", "[]", '{"uid":"","refresh_token":""}']:
		var f2 := FileAccess.open(FakeAuth.SESSION_FILE, FileAccess.WRITE)
		f2.store_string(bad)
		f2.close()
		var b := _auth()
		ok(not b.is_signed_in())
		b.queue_free()


func test_http_helpers() -> void:
	var a := _auth()
	var out := []
	var cb := func(ok_: bool, json: Dictionary, err: String) -> void: out.append([ok_, json, err])
	a._handle_http_result(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray(), cb)
	eq(out[0][2], "NETWORK_ERROR")
	a._handle_http_result(HTTPRequest.RESULT_SUCCESS, 200, '{"a":1}'.to_utf8_buffer(), cb)
	ok(out[1][0])
	a._handle_http_result(HTTPRequest.RESULT_SUCCESS, 400, '{"error":{"message":"EMAIL_EXISTS : x"}}'.to_utf8_buffer(), cb)
	eq(out[2][2], "EMAIL_EXISTS")
	a._handle_http_result(HTTPRequest.RESULT_SUCCESS, 500, "garbage".to_utf8_buffer(), cb)
	eq(out[3][2], "UNKNOWN_ERROR")
	# the real transport: an invalid URL makes request() fail synchronously
	FirebaseAuth._post("", PackedStringArray(), "", cb)
	await frames(2)
	ok(out.size() >= 4)
	FirebaseAuth._post_json("", {}, cb)
	FirebaseAuth._post_form("", "x=1", cb)
	a.queue_free()
