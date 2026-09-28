extends Node
## The Firebase half of cloud save (Firebase Cloud Save Phase 2B). Behind the same four
## signals and five methods as play_games_cloud_backend.gd/game_center_cloud_backend.gd
## (is_available/service_name/sign_in/pull/push/resolve_conflict + last_error), so
## CloudSave cannot tell which backend it holds - see cloud_save.gd's own doc comment for
## the full contract this mirrors.
##
## Unlike the platform backends, availability depends on FIREBASE ACCOUNT STATE, not OS
## platform - is_available() is simply FirebaseAuth.is_signed_in(). A player who never
## creates a BeamShift account never sees this backend selected; CloudSave falls back to
## the platform-native backend exactly as before Phase 2B.
##
## Firestore transport is entirely delegated to FirebaseFirestoreREST (Phase 2A) - this
## file never duplicates token/refresh/HTTP/serialization logic, it only calls
## get_document/set_document. One document per user: users/{uid}/save/current. push()
## always does a full overwrite (SaveManager.to_dict() is already the complete canonical
## profile every time, so a partial merge would only risk leaving stale fields behind).
##
## Firestore has no native "two writers collided" conflict signal the way Play Games
## snapshots/Game Center saved games do (it is a single authoritative document, last
## write wins) - conflict_found is declared for contract symmetry but is never emitted by
## this backend; resolve_conflict() is kept only so CloudSave's uniform _backend.call(...)
## surface never needs a backend-specific branch.

signal sign_in_changed(is_signed_in: bool)
signal profile_loaded(profile: Dictionary)
signal conflict_found(profiles: Array)
signal push_finished(ok: bool)

const SAVE_SUBPATH := "save/current"

var last_error := ""
var _firestore: FirebaseFirestoreREST


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_firestore = FirebaseFirestoreREST.new(self)
	FirebaseAuth.auth_state_changed.connect(_on_auth_state_changed)


func is_available() -> bool:
	return FirebaseAuth.is_signed_in()


func service_name() -> String:
	return "BeamShift Cloud Account"


## Real Firebase sign-in happens through the future Account UI (Phase 3), not a generic
## "SIGN IN" button - this backend is only ever selected once a session already exists.
func sign_in() -> void:
	pass


func pull() -> void:
	var uid := FirebaseAuth.get_uid()
	if uid == "":
		return
	_firestore.get_document(
		_firestore.current_user_document_path(SAVE_SUBPATH),
		func(ok: bool, data: Dictionary, err: String, _code: int) -> void:
			if not ok:
				# NOT_FOUND = no cloud save exists yet for this account (a brand-new
				# Firebase sign-up, or the first time this account is used for cloud
				# save) - this is not a failure. CloudSave treats an empty/no profile
				# as "nothing to reconcile," so local progress is left untouched and
				# becomes the first push on its own regular push-cooldown cycle.
				if err != "NOT_FOUND":
					last_error = _describe_error(err)
				return
			last_error = ""
			if not data.is_empty():
				profile_loaded.emit(data)
	)


func push(payload: Dictionary, _played_ms: int) -> void:
	var uid := FirebaseAuth.get_uid()
	if uid == "":
		push_finished.emit(false)
		return
	_firestore.set_document(
		_firestore.current_user_document_path(SAVE_SUBPATH),
		payload,
		func(ok: bool, _data: Dictionary, err: String, _code: int) -> void:
			last_error = "" if ok else _describe_error(err)
			push_finished.emit(ok)
	)


## No native conflict path (see the file doc comment) - writing the winner back is the
## whole resolution, identical in spirit to play_games_cloud_backend.gd's own version.
func resolve_conflict(winner: Dictionary, played_ms: int) -> void:
	push(winner, played_ms)


func _on_auth_state_changed(_is_signed_in: bool) -> void:
	sign_in_changed.emit(FirebaseAuth.is_signed_in())


func _describe_error(err: String) -> String:
	match err:
		"OFFLINE":
			return "No internet connection."
		"NO_AUTH":
			return "Not signed in to a BeamShift account."
		"PERMISSION_DENIED":
			return "BeamShift Cloud Account access denied."
		"NETWORK_ERROR", "REQUEST_FAILED":
			return "Could not reach BeamShift Cloud Account."
		_:
			return "BeamShift Cloud Account sync failed (%s)." % err
