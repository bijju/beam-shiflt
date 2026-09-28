extends Node
## FirebaseAuth - Firebase Identity Toolkit REST authentication (Firebase REST Auth
## Phase 1). 10th autoload; earns rule 6's bar the same way CloudSave/StoreManager do -
## authenticated session state must survive every scene change and will be consumed by
## the future Account screen, Settings, CloudSave and the Firestore backend (Phase 2).
##
## REST-only by design: no google-services.json, no Firebase Android/iOS SDK, no
## google-services Gradle plugin. Every request goes straight to Google's Identity
## Toolkit / Secure Token REST endpoints via a plain HTTPRequest child node. All
## project configuration (the Web API key) is centralized in FirebaseConfig - never
## hardcode a key here.
##
## Firestore is Phase 2 and is NOT touched by this file. CloudSave's existing
## Play Games / Game Center backends are untouched; this autoload is additive.
##
## Session persistence: user://firebase_session.json stores ONLY uid/email/refresh_token
## (never the password, never the id_token). KNOWN LIMITATION: Godot's user:// storage
## is plain application-sandboxed storage, not the Android Keystore or iOS Keychain - a
## refresh token stored here is only as safe as the device's own app-data sandbox. This
## is an accepted, documented limitation for Phase 1, matching the value's own real-world
## exposure window (Firebase refresh tokens are long-lived until revoked).
##
## Concurrency safety: a monotonic _session_generation counts every sign_out(); every
## in-flight request captures it at start and discards its result if it no longer
## matches, so a slow sign-in/refresh response can never resurrect state after the
## player has explicitly signed out. _create_in_progress/_sign_in_in_progress/
## _refresh_in_progress (with _refresh_waiters) collapse duplicate/overlapping requests
## into the one in-flight call.

signal auth_state_changed(is_signed_in: bool)
signal account_create_finished(success: bool, error_code: String)
signal sign_in_finished(success: bool, error_code: String)
signal password_reset_finished(success: bool, error_code: String)
signal token_refresh_finished(success: bool, error_code: String)
signal session_restore_finished(success: bool, error_code: String)
## Google Sign-In (Phase 4A). needs_link=true means the Google credential's email
## already owns a different-provider (password) account and was NOT signed in - the
## caller must get the player to sign in with that existing account, then call
## link_pending_google_credential() to attach Google to the same UID. is_new_user is only
## meaningful when success=true.
signal google_sign_in_finished(success: bool, error_code: String, needs_link: bool, is_new_user: bool)
signal google_link_finished(success: bool, error_code: String)

const SESSION_FILE := "user://firebase_session.json"
const REQUEST_TIMEOUT_SECONDS := 12.0
## Refresh once the cached ID token is within this many seconds of expiring - never
## wait for the exact expiry second (Firebase ID tokens last ~1 hour).
const TOKEN_REFRESH_MARGIN_SECONDS := 300.0

const IDENTITY_BASE := "https://identitytoolkit.googleapis.com/v1/accounts"
const TOKEN_URL := "https://securetoken.googleapis.com/v1/token"

## Firebase error codes that mean the stored refresh token itself is dead - only these
## clear a persisted session. Every other failure (network/timeout/unknown) leaves the
## refresh token intact; the player may simply be offline.
const _FATAL_REFRESH_ERRORS := [
	"TOKEN_EXPIRED", "USER_NOT_FOUND", "USER_DISABLED", "INVALID_REFRESH_TOKEN",
]

var _uid := ""
var _email := ""
var _id_token := ""
var _refresh_token := ""
var _token_expires_at := 0.0 # Unix seconds

var _session_generation := 0
var _create_in_progress := false
var _sign_in_in_progress := false
var _refresh_in_progress := false
var _refresh_waiters: Array[Callable] = []

## Google Sign-In / account-linking state (Phase 4A). _pending_google_id_token holds a
## Google ID token ONLY while a needs_link flow is in progress (the player must sign in
## with their existing password account before it can be attached) - never persisted to
## disk, never logged, cleared on success, failure, cancel, or sign_out().
var _google_sign_in_in_progress := false
var _link_in_progress := false
var _pending_google_id_token := ""
var _pending_google_email := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # HTTPRequest children must keep polling through InternetManager's pause overlay, same as CloudSave/StoreManager.
	_load_session_from_disk()
	if is_signed_in():
		auth_state_changed.emit(true) # optimistic: uid/email/refresh_token are on disk, id_token is refreshed in the background below.
	InternetManager.internet_restored.connect(_on_internet_restored)
	if InternetManager.is_online:
		_attempt_startup_restore()


func _on_internet_restored() -> void:
	_attempt_startup_restore()


func _attempt_startup_restore() -> void:
	if _refresh_token == "" or _id_token != "":
		return # no stored session, or already restored this run
	_do_refresh(func(ok: bool, err: String) -> void:
		if ok:
			print("[FirebaseAuth] Session restored.")
		session_restore_finished.emit(ok, err)
	)


## ---- Public API ----

func is_signed_in() -> bool:
	return _uid != "" and _refresh_token != ""


func has_refresh_token() -> bool:
	return _refresh_token != ""


## Monotonic, bumped by every sign_out() - lets a caller with a long-lived
## in-flight request (e.g. a Firestore REST call, Phase 2A) detect that the
## session it started under is gone and discard a stale response instead of
## applying it to whatever session (or lack of one) exists now.
func get_session_generation() -> int:
	return _session_generation


func get_uid() -> String:
	return _uid


func get_email() -> String:
	return _email


## Cached token only - may be stale/near-expiry. Callers that need a guaranteed-valid
## token (e.g. a future Firestore request) must `await ensure_valid_token()` first.
func get_id_token() -> String:
	return _id_token


## Returns true once a valid (or freshly refreshed) ID token is available; false if
## signed out, offline with no valid cached token, or the refresh failed.
func ensure_valid_token() -> bool:
	if _refresh_token == "":
		return false
	var now := Time.get_unix_time_from_system()
	if _id_token != "" and _token_expires_at - now > TOKEN_REFRESH_MARGIN_SECONDS:
		return true
	if not InternetManager.is_online:
		return false
	# GDScript lambdas capture outer locals BY VALUE, not by reference - a
	# plain `var done := false` mutated inside the callback would never be
	# seen by this loop (confirmed directly; this masked a real hang here
	# whenever a refresh was still in flight from another caller, e.g. the
	# Phase 2A Firestore wrapper racing FirebaseAuth's own startup restore).
	# A Dictionary is a reference type, so mutating a key inside it DOES
	# propagate back - keep this as a single shared Dictionary, not a bool.
	var result := {"ok": false, "done": false}
	_do_refresh(func(ok: bool, _err: String) -> void:
		result["ok"] = ok
		result["done"] = true
	)
	while not result["done"]:
		await get_tree().process_frame
	return result["ok"]


func create_account(email: String, password: String) -> void:
	if _create_in_progress:
		return
	var api_key := FirebaseConfig.web_api_key()
	if api_key == "":
		push_warning("[FirebaseAuth] Web API key not configured (config/firebase_config.local.json).")
		account_create_finished.emit(false, "CONFIG_MISSING")
		return
	if not InternetManager.is_online:
		account_create_finished.emit(false, "OFFLINE")
		return
	_create_in_progress = true
	var gen := _session_generation
	_post_json(
		"%s:signUp?key=%s" % [IDENTITY_BASE, api_key],
		{"email": email, "password": password, "returnSecureToken": true},
		func(ok: bool, json: Dictionary, err: String) -> void:
			_create_in_progress = false
			if gen != _session_generation:
				return
			if ok:
				_apply_auth_response(json)
				print("[FirebaseAuth] Account created.")
			else:
				print("[FirebaseAuth] Request failed: %s" % err)
			account_create_finished.emit(ok, err)
	)


func sign_in(email: String, password: String) -> void:
	if _sign_in_in_progress:
		return
	var api_key := FirebaseConfig.web_api_key()
	if api_key == "":
		push_warning("[FirebaseAuth] Web API key not configured (config/firebase_config.local.json).")
		sign_in_finished.emit(false, "CONFIG_MISSING")
		return
	if not InternetManager.is_online:
		sign_in_finished.emit(false, "OFFLINE")
		return
	_sign_in_in_progress = true
	var gen := _session_generation
	_post_json(
		"%s:signInWithPassword?key=%s" % [IDENTITY_BASE, api_key],
		{"email": email, "password": password, "returnSecureToken": true},
		func(ok: bool, json: Dictionary, err: String) -> void:
			_sign_in_in_progress = false
			if gen != _session_generation:
				return
			if ok:
				_apply_auth_response(json)
				print("[FirebaseAuth] Sign-in succeeded.")
			else:
				print("[FirebaseAuth] Request failed: %s" % err)
			sign_in_finished.emit(ok, err)
	)


func send_password_reset(email: String) -> void:
	var api_key := FirebaseConfig.web_api_key()
	if api_key == "":
		push_warning("[FirebaseAuth] Web API key not configured (config/firebase_config.local.json).")
		password_reset_finished.emit(false, "CONFIG_MISSING")
		return
	if not InternetManager.is_online:
		password_reset_finished.emit(false, "OFFLINE")
		return
	_post_json(
		"%s:sendOobCode?key=%s" % [IDENTITY_BASE, api_key],
		{"requestType": "PASSWORD_RESET", "email": email},
		func(ok: bool, _json: Dictionary, err: String) -> void:
			if ok:
				print("[FirebaseAuth] Password reset requested.")
			else:
				print("[FirebaseAuth] Request failed: %s" % err)
			password_reset_finished.emit(ok, err)
	)


## ---- Google Sign-In (Phase 4A) ----

## id_token is the Google ID token obtained from Android Credential Manager (native
## plugin). This is the ONE place accounts:signInWithIdp is called - never duplicate this
## HTTP call elsewhere. On success, behaves exactly like sign_in()/create_account()
## (applies the returned Firebase session). If the account already exists under a
## different provider (email/password) for the same email, Firebase returns
## needConfirmation instead of a session - that email/idToken are cached in-memory only
## and google_sign_in_finished fires with needs_link=true so the caller can prompt a
## normal password sign-in, then call link_pending_google_credential().
func sign_in_with_google_id_token(id_token: String) -> void:
	if _google_sign_in_in_progress:
		return
	var api_key := FirebaseConfig.web_api_key()
	if api_key == "":
		push_warning("[FirebaseAuth] Web API key not configured (config/firebase_config.local.json).")
		google_sign_in_finished.emit(false, "CONFIG_MISSING", false, false)
		return
	if not InternetManager.is_online:
		google_sign_in_finished.emit(false, "OFFLINE", false, false)
		return
	if id_token == "":
		google_sign_in_finished.emit(false, "INVALID_IDP_RESPONSE", false, false)
		return
	_google_sign_in_in_progress = true
	var gen := _session_generation
	_post_json(
		"%s:signInWithIdp?key=%s" % [IDENTITY_BASE, api_key],
		{
			"postBody": "id_token=%s&providerId=google.com" % id_token,
			"requestUri": "https://%s.firebaseapp.com" % FirebaseConfig.PROJECT_ID,
			"returnIdpCredential": true,
			"returnSecureToken": true,
		},
		func(ok: bool, json: Dictionary, err: String) -> void:
			_google_sign_in_in_progress = false
			if gen != _session_generation:
				return
			if ok and bool(json.get("needConfirmation", false)):
				_pending_google_id_token = id_token
				_pending_google_email = str(json.get("email", ""))
				print("[FirebaseAuth] Google sign-in needs account linking.")
				google_sign_in_finished.emit(false, "NEEDS_LINK", true, false)
				return
			if ok:
				var is_new_user := bool(json.get("isNewUser", false))
				_apply_auth_response(json)
				print("[FirebaseAuth] Google sign-in succeeded (new_user=%s)." % is_new_user)
				google_sign_in_finished.emit(true, "", false, is_new_user)
			else:
				print("[FirebaseAuth] Request failed: %s" % err)
				google_sign_in_finished.emit(false, err, false, false)
	)


## Attaches the Google credential cached by a prior NEEDS_LINK response to the CURRENTLY
## signed-in account (must already be signed in - normally via a fresh password
## sign_in()). Uses accounts:update, which links a new provider to the existing UID
## rather than creating a second Firebase account. Clears the pending token whether it
## succeeds or fails - a stale pending token must never be replayed against a different
## account.
func link_pending_google_credential() -> void:
	if _link_in_progress:
		return
	if _pending_google_id_token == "":
		google_link_finished.emit(false, "NO_PENDING_CREDENTIAL")
		return
	if not is_signed_in():
		_clear_pending_google_link()
		google_link_finished.emit(false, "NOT_SIGNED_IN")
		return
	var api_key := FirebaseConfig.web_api_key()
	if api_key == "":
		_clear_pending_google_link()
		google_link_finished.emit(false, "CONFIG_MISSING")
		return
	if not InternetManager.is_online:
		# Do NOT clear the pending token here - the player is already signed in via
		# password, offline is transient, and a retry (e.g. reopening the Account
		# screen) should be able to complete the link without redoing Google Sign-In.
		google_link_finished.emit(false, "OFFLINE")
		return
	_link_in_progress = true
	var gen := _session_generation
	var id_token := _pending_google_id_token
	_post_json(
		"%s:update?key=%s" % [IDENTITY_BASE, api_key],
		{
			"idToken": _id_token,
			"postBody": "id_token=%s&providerId=google.com" % id_token,
			"requestUri": "https://%s.firebaseapp.com" % FirebaseConfig.PROJECT_ID,
			"returnSecureToken": true,
		},
		func(ok: bool, json: Dictionary, err: String) -> void:
			_link_in_progress = false
			_clear_pending_google_link()
			if gen != _session_generation:
				return
			if ok:
				_apply_auth_response(json)
				print("[FirebaseAuth] Google account linked.")
			else:
				print("[FirebaseAuth] Request failed: %s" % err)
			google_link_finished.emit(ok, err)
	)


func has_pending_google_link() -> bool:
	return _pending_google_id_token != ""


func pending_google_link_email() -> String:
	return _pending_google_email


func cancel_pending_google_link() -> void:
	_clear_pending_google_link()


func _clear_pending_google_link() -> void:
	_pending_google_id_token = ""
	_pending_google_email = ""


## Force a refresh right now (e.g. a manual "Test Refresh" QA action). Normal callers
## should prefer ensure_valid_token().
func refresh_token() -> void:
	_do_refresh(func(ok: bool, err: String) -> void:
		token_refresh_finished.emit(ok, err)
	)


## Local sign-out. Works even if Firebase cannot be reached - it never makes a network
## request. Bumps _session_generation so any still-in-flight request from before this
## call is discarded when it completes.
func sign_out() -> void:
	_session_generation += 1
	_clear_session_state()
	_clear_pending_google_link()
	auth_state_changed.emit(false)
	print("[FirebaseAuth] Signed out.")


## ---- Internal: session state ----

func _apply_auth_response(json: Dictionary) -> void:
	_uid = str(json.get("localId", _uid))
	_email = str(json.get("email", _email))
	_id_token = str(json.get("idToken", ""))
	_refresh_token = str(json.get("refreshToken", ""))
	_token_expires_at = Time.get_unix_time_from_system() + float(str(json.get("expiresIn", "3600")))
	_save_session()
	auth_state_changed.emit(true)


func _clear_session_state() -> void:
	_uid = ""
	_email = ""
	_id_token = ""
	_refresh_token = ""
	_token_expires_at = 0.0
	_create_in_progress = false
	_sign_in_in_progress = false
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)


func _save_session() -> void:
	var f := FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"uid": _uid, "email": _email, "refresh_token": _refresh_token}))
	f.close()


func _load_session_from_disk() -> void:
	if not FileAccess.file_exists(SESSION_FILE):
		return
	var f := FileAccess.open(SESSION_FILE, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var uid := str(parsed.get("uid", ""))
	var refresh_token := str(parsed.get("refresh_token", ""))
	if uid == "" or refresh_token == "":
		return
	_uid = uid
	_email = str(parsed.get("email", ""))
	_refresh_token = refresh_token


## ---- Internal: token refresh (shared by refresh_token(), ensure_valid_token(), startup restore) ----

func _do_refresh(on_done: Callable) -> void:
	if _refresh_token == "":
		on_done.call(false, "NO_REFRESH_TOKEN")
		return
	if not InternetManager.is_online:
		on_done.call(false, "OFFLINE")
		return
	_refresh_waiters.append(on_done)
	if _refresh_in_progress:
		return
	var api_key := FirebaseConfig.web_api_key()
	if api_key == "":
		push_warning("[FirebaseAuth] Web API key not configured (config/firebase_config.local.json).")
		_flush_refresh_waiters(false, "CONFIG_MISSING")
		return
	_refresh_in_progress = true
	var gen := _session_generation
	var body := "grant_type=refresh_token&refresh_token=%s" % _refresh_token.uri_encode()
	_post_form(
		"%s?key=%s" % [TOKEN_URL, api_key],
		body,
		func(ok: bool, json: Dictionary, err: String) -> void:
			_refresh_in_progress = false
			if gen != _session_generation:
				_flush_refresh_waiters(false, "SUPERSEDED")
				return
			if ok:
				_uid = str(json.get("user_id", _uid))
				_id_token = str(json.get("id_token", _id_token))
				_refresh_token = str(json.get("refresh_token", _refresh_token))
				_token_expires_at = Time.get_unix_time_from_system() + float(str(json.get("expires_in", "3600")))
				_save_session()
				_flush_refresh_waiters(true, "")
				return
			print("[FirebaseAuth] Request failed: %s" % err)
			if _FATAL_REFRESH_ERRORS.has(err):
				_clear_session_state()
				auth_state_changed.emit(false)
			_flush_refresh_waiters(false, err)
	)


func _flush_refresh_waiters(ok: bool, err: String) -> void:
	var waiters := _refresh_waiters
	_refresh_waiters = []
	for w: Callable in waiters:
		w.call(ok, err)


## ---- Internal: HTTP ----

func _post_json(url: String, payload: Dictionary, on_done: Callable) -> void:
	_post(url, ["Content-Type: application/json"], JSON.stringify(payload), on_done)


func _post_form(url: String, form_body: String, on_done: Callable) -> void:
	_post(url, ["Content-Type: application/x-www-form-urlencoded"], form_body, on_done)


## on_done(success: bool, json: Dictionary, error_code: String). A fresh HTTPRequest
## per call keeps concurrent requests (e.g. sign-in racing a refresh) from ever
## confusing each other's response, and frees itself once done.
func _post(url: String, headers: PackedStringArray, body: String, on_done: Callable) -> void:
	var req := HTTPRequest.new()
	req.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(req)
	var err := req.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		req.queue_free()
		on_done.call(false, {}, "REQUEST_FAILED")
		return
	req.request_completed.connect(
		func(result: int, response_code: int, _resp_headers: PackedStringArray, resp_body: PackedByteArray) -> void:
			req.queue_free()
			_handle_http_result(result, response_code, resp_body, on_done),
		CONNECT_ONE_SHOT
	)


func _handle_http_result(result: int, response_code: int, body: PackedByteArray, on_done: Callable) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		on_done.call(false, {}, "NETWORK_ERROR")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var json: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	if response_code >= 200 and response_code < 300:
		on_done.call(true, json, "")
		return
	on_done.call(false, json, _extract_error_code(json))


## Firebase's stable, all-caps error code (e.g. EMAIL_EXISTS, INVALID_LOGIN_CREDENTIALS,
## WEAK_PASSWORD : ...). Never surfaces the raw JSON to callers.
func _extract_error_code(json: Dictionary) -> String:
	var error_obj: Dictionary = json.get("error", {})
	var message := str(error_obj.get("message", ""))
	if message == "":
		return "UNKNOWN_ERROR"
	return message.split(" ")[0].split(":")[0]
