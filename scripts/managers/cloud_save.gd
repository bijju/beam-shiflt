extends Node
## CloudSave - cross-device progress over the local SaveManager profile (7th autoload;
## earns rule 6 because the one-shot pull, the push throttle and a pending chooser question
## must survive scene changes). Full design: STORE_RELEASE.md "Cloud save".
##
## Backend loaded BY PATH per platform: Play Games Services Saved Games on Android, Game
## Center saved games (stored in iCloud) on iOS. Everywhere else it no-ops and the local
## file does everything, exactly as before.
##
## Merge = one rule: more play_time_seconds wins, ties on saved_at. A fresh install (zero
## local play time) adopts the cloud copy outright - asking would let "keep this device"
## push a blank profile over real progress. Past CHOOSER_THRESHOLD the player chooses.
## Entitlements, sound/music and ad cadence never travel (SaveManager.adopt_cloud_data).

const BACKENDS := {
	"Android": "res://scripts/cloud/play_games_cloud_backend.gd",
	"iOS": "res://scripts/cloud/game_center_cloud_backend.gd",
}
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

var _backend: Node = null
var _push_queued := false
var _push_accum := 0.0
var _pulled_once := false
## A cloud copy that arrived mid-level waits for the main menu (reconcile_held()).
var _held_cloud: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var path: String = BACKENDS.get(OS.get_name(), "")
	if path == "":
		return
	var node := Node.new()
	node.set_script(load(path))
	add_child(node)
	if not node.call("is_available"):
		node.queue_free()
		return
	_backend = node
	# Deferred: Game Center (SwiftGodot) calls back off the main thread, where add_child()
	# is refused and a menu rebuilt from the callback comes up half-drawn.
	_backend.sign_in_changed.connect(_on_sign_in_changed, CONNECT_DEFERRED)
	_backend.profile_loaded.connect(_on_profile_loaded, CONNECT_DEFERRED)
	_backend.conflict_found.connect(_on_conflict_found, CONNECT_DEFERRED)
	_backend.push_finished.connect(_on_push_finished, CONNECT_DEFERRED)
	SaveManager.saved.connect(_on_local_save)


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


func _on_sign_in_changed(authenticated: bool) -> void:
	is_signed_in = authenticated
	signed_in_changed.emit(authenticated)
	if authenticated and not _pulled_once:
		_pulled_once = true
		_backend.call("pull")


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
