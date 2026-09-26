extends Node
## The iOS half of cloud save: Game Center saved games (GKSavedGame).
##
## The twin of `play_games_cloud_backend.gd`, behind the same four signals and
## the same five methods, so [CloudSave] cannot tell which one it holds. Apple's
## saved games are the near-exact counterpart of Play's snapshots -- a named
## file per player, stored in their iCloud account, restored on a new device,
## and handed back as a list when two devices wrote without seeing each other.
##
## It drives the GodotApplePlugins GameCenter GDExtension by class name through
## [ClassDB] rather than by type, the same way `store_kit_backend.gd` drives
## StoreKit, so this script compiles on every platform and the extension only
## has to exist on the iOS build (CI downloads the pinned GodotApplePlugins release on
## the macOS runner; never vendored). Saved games live in iCloud, not Game Center: the
## App ID needs an iCloud container ASSIGNED, or every save fails (GKError 21/23).
## Every plugin signal is CONNECT_DEFERRED (SwiftGodot calls back off the main thread).
##
## The player is not asked to sign in: Game Center authenticates against the
## Apple ID already on the device, presenting Apple's own sheet if it needs to.
## [method sign_in] therefore only re-runs that, for a player who dismissed it.

const PLUGIN_CLASS := "GameCenterManager"

## The one saved game this game keeps, matching the Android snapshot name.
const SAVE_NAME := "beamshift_profile"

## GameKit answers an immediate fetch after authentication with an empty list
## on a fresh install -- a documented race, where the account's files are not
## in place yet -- so the first pull waits this long and the caller's one-shot
## pull is not spent on an empty answer. Later pulls go straight out.
const FIRST_FETCH_DELAY := 2.0

## `GKError.Code` in the plugin's own order, so a failure can be named rather
## than numbered. The three that matter most here sit at 21, 23 and 0: the
## first two are iCloud unavailable or iCloud Drive off, and the third is Game
## Center not recognising the app at all.
const ERROR_CODES := [
	"GAME_UNRECOGNIZED", "NOT_SUPPORTED", "APP_UNLISTED", "UNKNOWN", "CANCELLED",
	"COMMUNICATIONS_FAILURE", "INVALID_PLAYER", "INVALID_PARAMETER",
	"GAME_SESSION_REQUEST_INVALID", "API_NOT_AVAILABLE", "CONNECTION_TIMEOUT",
	"API_OBSOLETE", "USER_DENIED", "INVALID_CREDENTIALS", "NOT_AUTHENTICATED",
	"AUTHENTICATION_IN_PROGRESS", "PARENTAL_CONTROLS_BLOCKED",
	"PLAYER_STATUS_EXCEEDS_MAXIMUM_LENGTH", "PLAYER_STATUS_INVALID", "UNDERAGE",
	"PLAYER_PHOTO_FAILURE", "UBIQUITY_CONTAINER_UNAVAILABLE", "NOT_AUTHORIZED",
	"ICLOUD_UNAVAILABLE", "LOCKDOWN_MODE", "FRIEND_LIST_DESCRIPTION_MISSING",
	"FRIEND_LIST_RESTRICTED", "FRIEND_LIST_DENIED", "FRIEND_REQUEST_NOT_AVAILABLE",
	"MATCH_REQUEST_INVALID", "UNEXPECTED_CONNECTION", "INVITATIONS_DISABLED",
	"MATCH_NOT_CONNECTED", "RESTRICTED_TO_AUTOMATCH",
	"TURN_BASED_MATCH_DATA_TOO_LARGE", "TURN_BASED_TOO_MANY_SESSIONS",
	"TURN_BASED_INVALID_PARTICIPANT", "TURN_BASED_INVALID_TURN",
	"TURN_BASED_INVALID_STATE", "SCORE_NOT_SET", "CHALLENGE_INVALID", "DEBUG_MODE",
]

signal sign_in_changed(is_signed_in: bool)
signal profile_loaded(profile: Dictionary)
signal conflict_found(profiles: Array)
signal push_finished(ok: bool)

var _manager: Object = null
## GKLocalPlayer, once authentication has produced one.
var _player: Object = null
var _signed_in := false
var _fetched_once := false
## The GKSavedGame objects behind an open [signal conflict_found], which
## GameKit needs handed back to it verbatim to close the conflict out.
var _conflicts: Array = []

## Why the last operation failed, as GameKit described it, or "" after one that
## worked. Every call below used to throw its `GKError` away and report a bare
## false, which is nothing to work from when the device is an iPad and the desk
## is a Windows machine with no console attached. [CloudSave] carries this to
## the settings line so the reason is readable on the device itself.
var last_error := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() != "iOS" or not ClassDB.class_exists(PLUGIN_CLASS):
		return
	_manager = ClassDB.instantiate(PLUGIN_CLASS)
	if _manager == null:
		return
	_manager.connect("authentication_result", _on_authenticated, CONNECT_DEFERRED)
	_manager.connect("authentication_error", _on_auth_error, CONNECT_DEFERRED)
	_manager.call("authenticate")


## Whether this build can talk to Game Center at all -- false off iOS, or if
## the extension is not in this export.
func is_available() -> bool:
	return _manager != null


func service_name() -> String:
	return "Game Center"


## Re-runs authentication for a player who dismissed Apple's sheet. Game Center
## authenticates on its own at launch, so this is the only thing a SIGN IN
## button has left to do.
func sign_in() -> void:
	if _manager != null and not _signed_in:
		_manager.call("authenticate")


func pull() -> void:
	if _player == null:
		return
	if _fetched_once:
		_fetch()
		return
	_fetched_once = true
	get_tree().create_timer(FIRST_FETCH_DELAY).timeout.connect(_fetch)


func push(payload: Dictionary, _played_ms: int) -> void:
	# GameKit keeps no play-time field of its own; the profile carries its own,
	# which is what the merge rule reads on both platforms anyway.
	if _player == null:
		_fail("No Game Center local player, so there is nothing to sync to.")
		push_finished.emit(false)
		return
	_player.call("save_game_data", JSON.stringify(payload).to_utf8_buffer(), SAVE_NAME,
		func(_saved: Variant, error: Variant):
			if error == null:
				last_error = ""
			else:
				_fail("Cloud sync failed -- %s" % _error_text(error))
			push_finished.emit(error == null))


## Answers [signal conflict_found]: hands GameKit the winning bytes together
## with the files that were in conflict, which collapses them into one.
func resolve_conflict(winner: Dictionary, _played_ms: int) -> void:
	if _player == null or _conflicts.is_empty():
		return
	var conflicts := _conflicts
	_conflicts = []
	_player.call("resolve_conflicting_saved_games", conflicts,
		JSON.stringify(winner).to_utf8_buffer(),
		func(_games: Variant, error: Variant):
			if error == null:
				last_error = ""
			else:
				_fail("Could not settle the two cloud profiles -- %s" % _error_text(error))
			push_finished.emit(error == null))


func _on_authenticated(status: bool) -> void:
	if status and _player == null:
		_player = _manager.get("local_player")
		if _player != null:
			last_error = ""
			# Without a registered listener GameKit never reports a conflict.
			_player.call("register_listener")
			_player.connect("conflicting_saved_games", _on_conflicting, CONNECT_DEFERRED)
		else:
			# Authenticated with no local player is not a state the game can
			# use: every saved-game call below goes through it. Reporting it as
			# signed in would put SIGNED IN on the settings line over a service
			# that fails every sync, which is what it used to do.
			_fail("Game Center authenticated but returned no local player.")
	_signed_in = status and _player != null
	sign_in_changed.emit(_signed_in)


func _on_auth_error(message: String) -> void:
	_fail("Game Center sign-in failed -- %s" % message)
	_signed_in = false
	sign_in_changed.emit(false)


## One place for every failure: the console line for a build with a console
## attached, and the string the settings row can show for one that has not.
func _fail(reason: String) -> void:
	last_error = reason
	push_warning("CloudSave: %s" % reason)


## GameKit hands its errors back as the second callback argument, null on
## success, and otherwise a [code]GKError[/code] carrying `code`, `domain` and
## `message`.
##
## The first cut of this stringified the object, which produced "GameKit
## reported an unnamed error" on the iPad: `message` is often empty, and the
## code is the part that actually names the fault. Read the three members
## instead, and name the code, because "21" tells nobody that iCloud Drive is
## off. The type is reported too when the value is not an object at all, since
## a non-null non-error would mean the plugin signals success in a way this
## code reads as failure -- worth knowing rather than guessing.
func _error_text(error: Variant) -> String:
	if typeof(error) != TYPE_OBJECT or error == null:
		return "unexpected error value (type %d): %s" % [typeof(error), String(error)]
	var code := int(error.get("code"))
	var named := "unmapped"
	if code >= 0 and code < ERROR_CODES.size():
		named = ERROR_CODES[code]
	var text := "%s (code %d, %s)" % [named, code, String(error.get("domain"))]
	var message := String(error.get("message"))
	return text + (": " + message if message != "" else "")


func _fetch() -> void:
	if _player == null:
		return
	_player.call("fetch_saved_games", _on_fetched)


func _on_fetched(games: Variant, error: Variant) -> void:
	if error != null:
		_fail("Could not read the cloud save -- %s" % _error_text(error))
		return
	if typeof(games) != TYPE_ARRAY:
		return
	var ours := _ours(games)
	if ours.is_empty():
		return
	_read_all(ours, func(profiles: Array):
		if profiles.is_empty():
			return
		if profiles.size() == 1:
			profile_loaded.emit(profiles[0])
		else:
			# Two files under one name is GameKit's own conflict, arriving
			# through the fetch rather than through the listener.
			_conflicts = ours
			conflict_found.emit(profiles))


func _on_conflicting(_player_who: Variant, games: Variant) -> void:
	if typeof(games) != TYPE_ARRAY:
		return
	var ours := _ours(games)
	if ours.size() < 2:
		return
	_read_all(ours, func(profiles: Array):
		if profiles.size() < 2:
			return
		_conflicts = ours
		conflict_found.emit(profiles))


## The account may hold saved games this build did not write; only ours count.
func _ours(games: Array) -> Array:
	var mine: Array = []
	for game in games:
		if game != null and String(game.get("name")) == SAVE_NAME:
			mine.append(game)
	return mine


## Every file's bytes, parsed, handed over once the last one has answered.
## Each load is its own asynchronous call, so they are counted in rather than
## awaited in order, and an unreadable file drops out instead of sinking the
## whole pull.
func _read_all(games: Array, done: Callable) -> void:
	var profiles: Array = []
	var waiting := {"n": games.size()}
	for game in games:
		game.call("load_data", func(bytes: Variant, error: Variant):
			if error == null and bytes is PackedByteArray:
				var parsed: Variant = JSON.parse_string(
					(bytes as PackedByteArray).get_string_from_utf8())
				if typeof(parsed) == TYPE_DICTIONARY:
					profiles.append(parsed)
				else:
					push_warning("CloudSave: cloud save unreadable, keeping local profile.")
			waiting["n"] = int(waiting["n"]) - 1
			if int(waiting["n"]) == 0:
				done.call(profiles))
