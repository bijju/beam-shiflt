extends TestCase

const FakeFs := preload("res://tools/tests/fakes/fake_firestore.gd")

var _auth_state: Dictionary
var _online: bool


func before_each() -> void:
	_online = InternetManager.is_online
	InternetManager.is_online = true
	_auth_state = {
		"u": FirebaseAuth._uid, "e": FirebaseAuth._email, "i": FirebaseAuth._id_token,
		"r": FirebaseAuth._refresh_token, "x": FirebaseAuth._token_expires_at,
	}


func after_each() -> void:
	InternetManager.is_online = _online
	FirebaseAuth._uid = _auth_state["u"]
	FirebaseAuth._email = _auth_state["e"]
	FirebaseAuth._id_token = _auth_state["i"]
	FirebaseAuth._refresh_token = _auth_state["r"]
	FirebaseAuth._token_expires_at = _auth_state["x"]


func _sign_in_fake() -> void:
	FirebaseAuth._uid = "uid1"
	FirebaseAuth._id_token = "tok"
	FirebaseAuth._refresh_token = "rt"
	FirebaseAuth._token_expires_at = Time.get_unix_time_from_system() + 3600.0


func _wait_for(box: Array, max_frames := 120) -> void:
	var deadline := Time.get_ticks_msec() + (8000 if max_frames > 10 else 300)
	while box.is_empty() and Time.get_ticks_msec() < deadline:
		await frames(1)


func test_encode_decode_roundtrip() -> void:
	var fs := FirebaseFirestoreREST.new(runner)
	var data := {
		"s": "text", "b": true, "i": 7, "f": 1.5, "n": null,
		"m": {"k": "v", "deep": {"x": 1}}, "a": [1, "two", {"z": false}],
		"sn": &"name",
	}
	var enc := fs._encode_fields(data)
	var dec := fs._decode_fields(enc)
	eq(dec["s"], "text")
	eq(dec["b"], true)
	eq(dec["i"], 7)
	near(dec["f"], 1.5)
	eq(dec["n"], null)
	eq(dec["m"]["deep"]["x"], 1)
	eq(dec["a"][1], "two")
	eq(dec["sn"], "name")
	var odd := fs._encode_value(Vector2(1, 2))
	ok(odd.has("stringValue"), "unsupported types are visible, not dropped")
	eq(fs._decode_value({"weird": 1}), null)
	eq(fs._decode_document({}), {})


func test_response_and_error_mapping() -> void:
	var fs := FirebaseFirestoreREST.new(runner)
	var out := []
	var cb := func(ok_: bool, data: Dictionary, err: String, code: int) -> void: out.append([ok_, data, err, code])
	fs._handle_response(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray(), cb)
	eq(out[0][2], "NETWORK_ERROR")
	fs._handle_response(HTTPRequest.RESULT_SUCCESS, 200, '{"fields":{"a":{"integerValue":"3"}}}'.to_utf8_buffer(), cb)
	eq(out[1][1]["a"], 3)
	fs._handle_response(HTTPRequest.RESULT_SUCCESS, 403, '{"error":{"status":"PERMISSION_DENIED"}}'.to_utf8_buffer(), cb)
	eq(out[2][2], "PERMISSION_DENIED")
	for pair in [[404, "NOT_FOUND"], [403, "PERMISSION_DENIED"], [401, "UNAUTHENTICATED"], [0, "REQUEST_FAILED"], [500, "UNKNOWN_ERROR"]]:
		eq(fs._extract_error_code({}, pair[0]), pair[1])
	ok(fs._documents_base().contains(FirebaseConfig.PROJECT_ID))
	_sign_in_fake()
	eq(fs.current_user_document_path("save/current"), "users/uid1/save/current")


func test_request_guards() -> void:
	var fs := FakeFs.new(runner)
	var out := []
	var cb := func(ok_: bool, _d: Dictionary, err: String, code: int) -> void: out.append([ok_, err, code])
	InternetManager.is_online = false
	fs.get_document("p", cb)
	await _wait_for(out)
	eq(out[0][1], "OFFLINE")
	InternetManager.is_online = true
	FirebaseAuth._refresh_token = ""
	fs.delete_document("p", cb)
	await _wait_for(out, 5)
	eq(out[1][1], "NO_AUTH")
	# token fine but no uid
	FirebaseAuth._refresh_token = "rt"
	FirebaseAuth._id_token = "tok"
	FirebaseAuth._token_expires_at = Time.get_unix_time_from_system() + 3600.0
	FirebaseAuth._uid = ""
	fs.get_document("p", cb)
	await _wait_for(out, 5)
	eq(out[2][1], "NO_AUTH")


## Serves exactly one canned HTTP response on a local port, pumped from the wait loop.
func _serve(server: TCPServer, status: int, body: String) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		if server.is_connection_available():
			var peer := server.take_connection()
			var t0 := Time.get_ticks_msec()
			while peer.get_available_bytes() == 0 and Time.get_ticks_msec() - t0 < 2000:
				peer.poll()
				await frames(1)
			peer.get_data(peer.get_available_bytes())
			var resp := "HTTP/1.1 %d X\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [status, body.to_utf8_buffer().size(), body]
			peer.put_data(resp.to_utf8_buffer())
			await frames(2)
			peer.disconnect_from_host()
			return
		await frames(1)


func test_invalid_url_fails_fast() -> void:
	_sign_in_fake()
	var fs := FakeFs.new(runner)
	var out := []
	fs.set_document("users/uid1/save/current", {"a": 1}, func(ok_: bool, _d: Dictionary, err: String, _c: int) -> void: out.append([ok_, err]))
	await _wait_for(out)
	eq(out[0], [false, "REQUEST_FAILED"])
	fs.update_document("p", {"a": 1, "b": 2}, func(ok_: bool, _d: Dictionary, err: String, _c: int) -> void: out.append([ok_, err]))
	await _wait_for(out)


func test_real_request_against_local_server() -> void:
	_sign_in_fake()
	var server := TCPServer.new()
	var port := 18765
	var listen_err := server.listen(port, "127.0.0.1")
	if listen_err != OK:
		ok(true, "port busy, skipping")
		return
	var fs := FakeFs.new(runner)
	fs.base = "http://127.0.0.1:%d/documents" % port
	var out := []
	var cb := func(ok_: bool, d: Dictionary, err: String, code: int) -> void: out.append([ok_, d, err, code])
	fs.get_document("users/uid1/save/current", cb)
	_serve(server, 200, '{"fields":{"a":{"integerValue":"9"}}}')
	await _wait_for(out)
	eq(out[0][3], 200)
	eq(out[0][1].get("a"), 9)
	out.clear()
	fs.update_document("users/uid1/save/current", {"a": 1}, cb)
	_serve(server, 404, '{"error":{"status":"NOT_FOUND"}}')
	await _wait_for(out)
	eq(out[0][2], "NOT_FOUND")
	out.clear()
	fs.get_document("users/uid1/save/current", cb)
	await frames(1)
	FirebaseAuth._session_generation += 1  # sign-out while in flight
	_serve(server, 200, "{}")
	await _wait_for(out)
	eq(out[0][2], "STALE_SESSION")
	FirebaseAuth._session_generation -= 1
	server.stop()


func test_document_exists_outcomes() -> void:
	var fs := FakeFs.new(runner)
	fs.scripted = true
	var out := []
	var cb := func(ok_: bool, err: String) -> void: out.append([ok_, err])
	fs.queue.append([true, {"a": 1}, "", 200])
	fs.document_exists("p", cb)
	fs.queue.append([false, {}, "NOT_FOUND", 404])
	fs.document_exists("p", cb)
	fs.queue.append([false, {}, "PERMISSION_DENIED", 403])
	fs.document_exists("p", cb)
	eq(out, [[true, ""], [false, ""], [false, "PERMISSION_DENIED"]])
