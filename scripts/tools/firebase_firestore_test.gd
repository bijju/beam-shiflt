extends Node
## Dev-only FirebaseFirestoreREST manual/live test harness (Firebase REST Cloud
## Save Phase 2A). Never exported (scripts/tools/**), never referenced by
## game.gd/any autoload's normal play path. Exercises FirebaseFirestoreREST's
## real public API against the live "beamshift-game" Firestore database -
## requires a FirebaseAuth session already signed in (run
## firebase_auth_test.tscn action=sign_in first; the stored session then
## restores automatically on every later run of this harness, same as any
## other BeamShift restart).
##
## Run:
##   "D:\Godot_v4.7.1-stable_win64.exe" --headless --path . res://scripts/tools/firebase_firestore_test.tscn -- action=<...>
##
## Actions:
##   status                unsigned status print only
##   write                 PATCH (full overwrite) the test document
##   read                  GET the test document, print decoded fields
##   update                PATCH+updateMask counter->2, preserving other fields
##   read_other_uid        attempt a different UID's path - expect PERMISSION_DENIED
##   raw_unauth_read       raw HTTPRequest with NO Authorization header - expect server-side deny
##   token_refresh_read    force a token refresh, then read - proves no manual refresh needed by caller
##   offline_read          simulate InternetManager offline, attempt read - expect fast OFFLINE, no corruption
##   stale_test            start a read, sign out mid-flight - expect the response discarded
##   delete                delete the test document (cleanup)
##
## Never prints the ID token, refresh token, password, or Authorization header value.

const TEST_DOC_SUBPATH := "save/current"
const OTHER_UID_PATH := "users/not-the-current-user/save/current"

var _timeout_timer: Timer
var _firestore: FirebaseFirestoreREST


func _ready() -> void:
	_firestore = FirebaseFirestoreREST.new(self)

	var action := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("action="):
			action = arg.substr(7)

	print("[FirestoreTest] action=%s" % action)
	_print_auth_status()

	_start_timeout()

	match action:
		"status":
			_finish()
		"write":
			_do_write()
		"read":
			_do_read("read")
		"update":
			_do_update()
		"read_other_uid":
			_do_read_other_uid()
		"raw_unauth_read":
			_do_raw_unauth_read()
		"token_refresh_read":
			_do_token_refresh_read()
		"offline_read":
			_do_offline_read()
		"stale_test":
			_do_stale_test()
		"delete":
			_do_delete()
		_:
			print("[FirestoreTest] unknown or missing action=")
			_finish()


func _start_timeout() -> void:
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = 20.0
	_timeout_timer.timeout.connect(func() -> void:
		print("[FirestoreTest] TIMED OUT waiting for a result.")
		_finish()
	)
	add_child(_timeout_timer)
	_timeout_timer.start()


func _finish() -> void:
	get_tree().quit()


func _print_auth_status() -> void:
	print("[FirestoreTest] auth status: signed_in=%s uid=%s has_id_token=%s online=%s" % [
		FirebaseAuth.is_signed_in(),
		FirebaseAuth.get_uid(),
		FirebaseAuth.get_id_token() != "",
		InternetManager.is_online,
	])


## ---- Actions ----

func _do_write() -> void:
	var payload := {
		"schema_version": 1,
		"test_value": "beamshift_firestore_live",
		"counter": 1,
		"enabled": true,
	}
	_firestore.set_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		payload,
		func(ok: bool, data: Dictionary, err: String, code: int) -> void:
			print("[FirestoreTest] WRITE result: ok=%s http=%s err=%s data=%s" % [ok, code, err, JSON.stringify(data)])
			_finish()
	)


func _do_read(label: String) -> void:
	_firestore.get_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		func(ok: bool, data: Dictionary, err: String, code: int) -> void:
			print("[FirestoreTest] %s result: ok=%s http=%s err=%s data=%s" % [label.to_upper(), ok, code, err, JSON.stringify(data)])
			_finish()
	)


func _do_update() -> void:
	_firestore.update_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		{"counter": 2},
		func(ok: bool, data: Dictionary, err: String, code: int) -> void:
			print("[FirestoreTest] UPDATE result: ok=%s http=%s err=%s data=%s" % [ok, code, err, JSON.stringify(data)])
			_finish()
	)


func _do_read_other_uid() -> void:
	_firestore.get_document(
		OTHER_UID_PATH,
		func(ok: bool, data: Dictionary, err: String, code: int) -> void:
			print("[FirestoreTest] READ_OTHER_UID result: ok=%s http=%s err=%s (expect ok=false, PERMISSION_DENIED/403)" % [ok, code, err])
			_finish()
	)


## Bypasses FirebaseFirestoreREST entirely (it always attaches a valid
## Authorization header by design) to prove Firestore's OWN rules reject a
## request with none, independent of our client-side guard.
func _do_raw_unauth_read() -> void:
	var uid := FirebaseAuth.get_uid()
	if uid == "":
		print("[FirestoreTest] raw_unauth_read: no uid on record locally (fine - proves nothing is signed in), request still sent to check server-side behavior with zero auth context.")
		uid = "no-local-session"
	var url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s/save/current" % [FirebaseConfig.PROJECT_ID, uid]
	var req := HTTPRequest.new()
	req.timeout = 12.0
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
		print("[FirestoreTest] RAW_UNAUTH_READ result: http=%s network_result=%s (expect 401/403 deny)" % [response_code, result])
		_finish()
	)
	var err := req.request(url) # deliberately no Authorization header
	if err != OK:
		print("[FirestoreTest] RAW_UNAUTH_READ request() failed to start: %s" % err)
		_finish()


func _do_token_refresh_read() -> void:
	FirebaseAuth.token_refresh_finished.connect(func(ok: bool, err: String) -> void:
		print("[FirestoreTest] forced token refresh: ok=%s err=%s" % [ok, err])
		_do_read("token_refresh_read")
	, CONNECT_ONE_SHOT)
	FirebaseAuth.refresh_token()


func _do_offline_read() -> void:
	InternetManager.is_online = false
	var start_ms := Time.get_ticks_msec()
	_firestore.get_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		func(ok: bool, _data: Dictionary, err: String, code: int) -> void:
			var elapsed_ms := Time.get_ticks_msec() - start_ms
			InternetManager.is_online = true # restore before reporting session state
			print("[FirestoreTest] OFFLINE_READ result: ok=%s err=%s http=%s elapsed_ms=%s (expect ok=false OFFLINE, elapsed near-zero)" % [ok, err, code, elapsed_ms])
			print("[FirestoreTest] session preserved after offline attempt: signed_in=%s has_refresh_token=%s" % [FirebaseAuth.is_signed_in(), FirebaseAuth.has_refresh_token()])
			_finish()
	)


func _do_stale_test() -> void:
	# Prime a fresh cached ID token first (a throwaway read) so the REAL test
	# read below resolves ensure_valid_token() synchronously and starts its
	# HTTPRequest immediately - otherwise the sign_out race below tends to
	# interrupt FirebaseAuth's own token refresh instead of the Firestore
	# document request this test actually means to target.
	_firestore.get_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		func(_ok: bool, _data: Dictionary, _err: String, _code: int) -> void:
			print("[FirestoreTest] stale_test: token primed, has_id_token=%s. Starting real test read." % (FirebaseAuth.get_id_token() != ""))
			_do_stale_test_real()
	)


func _do_stale_test_real() -> void:
	var gen_before := FirebaseAuth.get_session_generation()
	print("[FirestoreTest] stale_test: starting read at session_generation=%s, will sign_out shortly after." % gen_before)
	_firestore.get_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		func(ok: bool, _data: Dictionary, err: String, code: int) -> void:
			print("[FirestoreTest] STALE_TEST result: ok=%s err=%s http=%s (expect ok=false STALE_SESSION, never applied to post-sign-out state)" % [ok, err, code])
			_finish()
	)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 0.02
	t.timeout.connect(func() -> void:
		print("[FirestoreTest] stale_test: signing out mid-flight now.")
		FirebaseAuth.sign_out()
	)
	add_child(t)
	t.start()


func _do_delete() -> void:
	_firestore.delete_document(
		_firestore.current_user_document_path(TEST_DOC_SUBPATH),
		func(ok: bool, _data: Dictionary, err: String, code: int) -> void:
			print("[FirestoreTest] DELETE result: ok=%s http=%s err=%s" % [ok, code, err])
			_do_read("delete_verify")
	)
