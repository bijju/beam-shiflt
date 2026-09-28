extends Node
## CloudSave - cross-device progress over the local SaveManager profile (7th autoload;
## earns rule 6 because the one-shot pull, the push throttle and a pending chooser question
## must survive scene changes). Full design: STORE_RELEASE.md "Cloud save".
##
## Two backend FAMILIES, both loaded by path, never both active as the one CloudSave talks
## to at once (Firebase Cloud Save Phase 2B):
## - Native (unchanged since Phase 1): Play Games Services Saved Games on Android, Game
##   Center saved games (stored in iCloud) on iOS - loaded once at _ready(), by OS platform.
## - Firebase (new): a BeamShift account, available purely by FirebaseAuth.is_signed_in()
##   (see firebase_cloud_backend.gd) - never tied to OS platform.
## Everywhere neither applies, CloudSave no-ops and the local file does everything, exactly
## as before Phase 2B.
##
## Selection priority (see _select_backend()): a signed-in Firebase account always wins
## over the platform-native backend - a player who never creates a BeamShift account keeps
## the exact pre-Phase-2B native-only behavior, byte-for-byte. Both backend nodes are
## created once at _ready() and kept alive for the whole session (switching never
## destroys/recreates a backend node, which would re-trigger its own sign-in/snapshot-load
## side effects) - only which one is "active" (receives pull()/push()/resolve_conflict()
## calls and has its profile_loaded/conflict_found/push_finished signals connected) changes.
## The native backend's sign_in_changed is listened to unconditionally for the backend's
## whole lifetime (not just while active), so a silent background Play Games/Game Center
## authentication is never missed while Firebase happens to be the active backend.
##
## Merge = one rule: more play_time_seconds wins, ties on saved_at. A fresh install (zero
## local play time) adopts the cloud copy outright - asking would let "keep this device"
## push a blank profile over real progress. Past CHOOSER_THRESHOLD the player chooses. This
## policy is entirely backend-agnostic (_reconcile()/_cloud_wins() never look at which
## backend is active) - Firebase reuses it unchanged. Entitlements, sound/music and ad
## cadence never travel (SaveManager.adopt_cloud_data).

const NATIVE_BACKENDS := {
	"Android": "res://scripts/cloud/play_games_cloud_backend.gd",
	"iOS": "res://scripts/cloud/game_center_cloud_backend.gd",
}
const FIREBASE_BACKEND_PATH := "res://scripts/cloud/firebase_cloud_backend.gd"
## Local writes inside this window collapse into one push (every move saves; both stores
## rate-limit commits).
const PUSH_COOLDOWN := 45.0
## Play-time gap (seconds) past which neither copy is picked silently.
const CHOOSER_THRESHOLD := 3600.0
const GAME_SCENE := "res://scenes/gameplay/game.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

signal signed_in_changed(is_signed_in: bool)
## The two copies differ by more than CHOOSER_THRESHOLD. They stay in pending_cloud /
## pending_local until take_cloud() / keep_local(), so a screen built later still finds it.
signal chooser_needed
signal synced(success: bool)

var is_signed_in := false
var last_synced_at := ""
var pending_cloud: Dictionary = {}
var pending_local: Dictionary = {}

## The backend CURRENTLY receiving pull()/push()/sign_in()/resolve_conflict() calls and
## whose profile_loaded/conflict_found/push_finished signals are connected - either
## _native_backend, _firebase_backend, or null. See _select_backend().
var _backend: Node = null
var _native_backend: Node = null
var _firebase_backend: Node = null
## Tracked independently of `_backend` so a native sign-in/out that happens while Firebase
## is the active backend is never lost - _select_backend() reads this the moment Firebase
## stops being available (an account sign-out) to decide whether native can take over.
var _native_authenticated := false

var _push_queued := false
var _push_accum := 0.0
var _pulled_once := false
## A cloud copy that arrived mid-level waits for the main menu (reconcile_held()).
var _held_cloud: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_native_backend()
	_load_firebase_backend()
	FirebaseAuth.auth_state_changed.connect(func(_authenticated: bool) -> void: _select_backend())
	SaveManager.saved.connect(_on_local_save)
	_select_backend()


func _load_native_backend() -> void:
	var path: String = NATIVE_BACKENDS.get(OS.get_name(), "")
	if path == "":
		return
	var node := Node.new()
	node.set_script(load(path))
	add_child(node)
	if not node.call("is_available"):
		node.queue_free()
		return
	_native_backend = node
	# Deferred: Game Center (SwiftGodot) calls back off the main thread, where add_child()
	# is refused and a menu rebuilt from the callback comes up half-drawn. Connected for
	# the backend's whole lifetime, independent of whether it is currently active - see
	# the class doc comment.
	_native_backend.sign_in_changed.connect(_on_native_sign_in_changed, CONNECT_DEFERRED)


func _load_firebase_backend() -> void:
	var node := Node.new()
	node.set_script(load(FIREBASE_BACKEND_PATH))
	add_child(node)
	_firebase_backend = node


## Firebase (if signed in) always wins over the platform-native backend; native wins over
## nothing. Re-entrant safe: called on every native sign-in change AND every Firebase
## auth-state change, and correctly no-ops if neither the active backend nor its signed-in
## state actually changed. Never destroys/recreates a backend node (see the class doc
## comment) - only (re)connects the active-only signal trio and updates `is_signed_in`.
func _select_backend() -> void:
	var desired: Node = null
	if _firebase_backend != null and bool(_firebase_backend.call("is_available")):
		desired = _firebase_backend
	elif _native_backend != null:
		desired = _native_backend

	if desired != _backend:
		_disconnect_active_signals()
		_backend = desired
		_pulled_once = false
		if _backend != null:
			_connect_active_signals()

	var new_signed_in := false
	if _backend == _firebase_backend and _backend != null:
		new_signed_in = true # only ever selected while FirebaseAuth.is_signed_in()
	elif _backend == _native_backend and _backend != null:
		new_signed_in = _native_authenticated

	if new_signed_in != is_signed_in:
		is_signed_in = new_signed_in
		signed_in_changed.emit(is_signed_in)

	if is_signed_in and not _pulled_once:
		_pulled_once = true
		_backend.call("pull")


func _connect_active_signals() -> void:
	if not _backend.profile_loaded.is_connected(_on_profile_loaded):
		_backend.profile_loaded.connect(_on_profile_loaded, CONNECT_DEFERRED)
	if not _backend.conflict_found.is_connected(_on_conflict_found):
		_backend.conflict_found.connect(_on_conflict_found, CONNECT_DEFERRED)
	if not _backend.push_finished.is_connected(_on_push_finished):
		_backend.push_finished.connect(_on_push_finished, CONNECT_DEFERRED)


func _disconnect_active_signals() -> void:
	if _backend == null:
		return
	if _backend.profile_loaded.is_connected(_on_profile_loaded):
		_backend.profile_loaded.disconnect(_on_profile_loaded)
	if _backend.conflict_found.is_connected(_on_conflict_found):
		_backend.conflict_found.disconnect(_on_conflict_found)
	if _backend.push_finished.is_connected(_on_push_finished):
		_backend.push_finished.disconnect(_on_push_finished)


func _on_native_sign_in_changed(authenticated: bool) -> void:
	_native_authenticated = authenticated
	_select_backend()


func _process(delta: float) -> void:
	if not _push_queued:
		return
	_push_accum += delta
	if _push_accum >= PUSH_COOLDOWN:
		_flush_push()


func _notification(what: int) -> void:
	# The last frame we are guaranteed before the OS may kill the process.
	if what == NOTIFICATION_APPLICATION_PAUSED and _push_queued:
		_flush_push()


func is_available() -> bool:
	return _backend != null


## "Google Play Games" / "Game Center"; "" where there is none.
func service_name() -> String:
	return str(_backend.call("service_name")) if _backend != null else ""


## The service's own words for why the last sync failed, "" otherwise.
func last_error() -> String:
	return str(_backend.get("last_error")) if _backend != null else ""


func sign_in() -> void:
	if _backend != null:
		_backend.call("sign_in")


## Firebase Account UI Phase 3: lets the Account screen offer a native-only fallback
## (Play Games / Game Center) alongside the primary Firebase account flow, without
## the UI needing to know which native backend exists or reach into CloudSave
## internals - see account_screen.gd's NativeContinueButton.
func has_native_backend() -> bool:
	return _native_backend != null


func native_service_name() -> String:
	return str(_native_backend.call("service_name")) if _native_backend != null else ""


func sync_now() -> void:
	if is_signed_in:
		_flush_push()


func has_pending_choice() -> bool:
	return not pending_cloud.is_empty()


func take_cloud() -> void:
	var cloud := pending_cloud
	_clear_pending()
	_adopt(cloud)


## Pushes the local copy so the cloud agrees - otherwise the question returns next boot.
func keep_local() -> void:
	_clear_pending()
	sync_now()


## Main menu calls this on build.
func reconcile_held() -> void:
	if _held_cloud.is_empty():
		return
	var cloud := _held_cloud
	_held_cloud = {}
	_reconcile(cloud)


static func play_time_of(profile: Dictionary) -> float:
	return float(profile.get("play_time_seconds", 0.0))


static func level_of(profile: Dictionary) -> int:
	return int(profile.get("procedural_current_level", 1))


func _on_profile_loaded(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	if _in_level():
		_held_cloud = profile
		return
	_reconcile(profile)


func _reconcile(cloud: Dictionary) -> void:
	var local := SaveManager.to_dict()
	if play_time_of(local) <= 0.0 and play_time_of(cloud) > 0.0:
		_adopt(cloud)
		return
	if absf(play_time_of(cloud) - play_time_of(local)) >= CHOOSER_THRESHOLD:
		pending_cloud = cloud
		pending_local = local
		chooser_needed.emit()
		return
	if _cloud_wins(cloud, local):
		_adopt(cloud)


func _cloud_wins(cloud: Dictionary, local: Dictionary) -> bool:
	if play_time_of(cloud) != play_time_of(local):
		return play_time_of(cloud) > play_time_of(local)
	return str(cloud.get("saved_at", "")) > str(local.get("saved_at", ""))


func _adopt(cloud: Dictionary) -> void:
	SaveManager.adopt_cloud_data(cloud)
	# Main menu shows CONTINUE / level state read at build time: rebuild it.
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path == MAIN_MENU_SCENE:
		get_tree().reload_current_scene.call_deferred() # may run inside the menu's _ready


func _clear_pending() -> void:
	pending_cloud = {}
	pending_local = {}


func _in_level() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == GAME_SCENE


func _on_local_save() -> void:
	if is_signed_in:
		_push_queued = true


func _flush_push() -> void:
	_push_accum = 0.0
	_push_queued = false
	if not is_signed_in or _backend == null:
		return
	var payload := SaveManager.to_dict()
	payload.erase("entitlements") # per store account; the store re-grants
	_backend.call("push", payload, int(play_time_of(payload) * 1000.0))


func _on_push_finished(ok: bool) -> void:
	if ok:
		last_synced_at = Time.get_datetime_string_from_system(false, true)
	synced.emit(ok)


## Two devices wrote without seeing each other: same rule, no question, winner written back.
func _on_conflict_found(profiles: Array) -> void:
	var winner: Dictionary = {}
	for entry in profiles:
		if typeof(entry) == TYPE_DICTIONARY and (winner.is_empty() or _cloud_wins(entry, winner)):
			winner = entry
	if winner.is_empty():
		return
	if _in_level():
		_held_cloud = winner # never swap the profile under a board in play
		return
	_adopt(winner)
	_backend.call("resolve_conflict", winner, int(play_time_of(winner) * 1000.0))
