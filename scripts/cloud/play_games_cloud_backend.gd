extends Node
## Android half of cloud save: Play Games Services Saved Games (GodotPlayGameServices 3.4.0,
## addons/GodotPlayGameServices). Loaded by path from CloudSave on Android only. Contract
## shared with game_center_cloud_backend.gd: 4 signals, is_available/service_name/sign_in/
## pull/push/resolve_conflict, plus a last_error string. Nothing Play-specific leaves here.
## Sign-in failures log nothing through Godot: filter adb logcat on
## SignInChimeraActivity|PlayerAgentHelper|SignInProxy (code 10002 = not a PGS tester).

signal sign_in_changed(is_signed_in: bool)
signal profile_loaded(profile: Dictionary)
signal conflict_found(profiles: Array)
signal push_finished(ok: bool)

const SNAPSHOT_NAME := "beamshift_profile"
const SNAPSHOT_DESC := "BeamShift progress"

var last_error := ""
var _sign_in: PlayGamesSignInClient
var _snapshots: PlayGamesSnapshotsClient


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() != "Android":
		return
	if GodotPlayGameServices.initialize() != GodotPlayGameServices.PlayGamesPluginError.OK:
		return
	_sign_in = PlayGamesSignInClient.new()
	_snapshots = PlayGamesSnapshotsClient.new()
	add_child(_sign_in)
	add_child(_snapshots)
	_sign_in.user_authenticated.connect(_on_user_authenticated)
	_snapshots.game_loaded.connect(_on_game_loaded)
	_snapshots.game_saved.connect(_on_game_saved)
	_snapshots.conflict_emitted.connect(_on_conflict_emitted)
	_sign_in.is_authenticated() # asks without prompting; answers via user_authenticated


func is_available() -> bool:
	return _snapshots != null


func service_name() -> String:
	return "Google Play Games"


func sign_in() -> void:
	if _sign_in:
		_sign_in.sign_in()


func pull() -> void:
	if _snapshots:
		_snapshots.load_game(SNAPSHOT_NAME, true)


func push(payload: Dictionary, played_ms: int) -> void:
	if _snapshots:
		_snapshots.save_game(SNAPSHOT_NAME, SNAPSHOT_DESC, JSON.stringify(payload).to_utf8_buffer(), played_ms)


## The wrapper has no resolve call: writing the winner under the same name resolves it.
func resolve_conflict(winner: Dictionary, played_ms: int) -> void:
	push(winner, played_ms)


func _on_user_authenticated(authenticated: bool) -> void:
	sign_in_changed.emit(authenticated)


func _on_game_loaded(snapshot: PlayGamesSnapshot) -> void:
	var parsed := _parse(snapshot)
	if not parsed.is_empty():
		profile_loaded.emit(parsed)


func _on_game_saved(is_saved: bool, _name: String, _description: String) -> void:
	last_error = "" if is_saved else "Google Play Games did not accept the save."
	push_finished.emit(is_saved)


func _on_conflict_emitted(conflict: PlayGamesSnapshotConflict) -> void:
	var profiles: Array = []
	for snapshot in [conflict.conflicting_snapshot, conflict.server_snapshot]:
		var parsed := _parse(snapshot)
		if not parsed.is_empty():
			profiles.append(parsed)
	if not profiles.is_empty():
		conflict_found.emit(profiles)


func _parse(snapshot: PlayGamesSnapshot) -> Dictionary:
	if snapshot == null or snapshot.content.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(snapshot.content.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("CloudSave: cloud snapshot unreadable, keeping the local profile.")
		return {}
	return parsed
