extends Node
## PlatformAccount - the optional, platform-native player identity (autoload).
##
## Android: Google Play Games Services. iOS: Sign in with Apple. Desktop/editor: none.
## It is identity DISPLAY only: progress always lives in the local SaveManager profile,
## nothing is uploaded or synced anywhere, and a failed/cancelled/unavailable sign-in
## never blocks play. Android and iOS progression are intentionally separate.
##
## Apple has no "sign out" API: signing out only forgets the stored Apple identity here.

signal changed

enum Platform { NONE, ANDROID, IOS }

const SESSION_PATH := "user://platform_account.json"
const APPLE_AUTH_CLASS := "ASAuthorizationController"

var platform: Platform = Platform.NONE
## True once the platform identity is established (Play Games authenticated / Apple signed in).
var connected := false
var display_name := ""
## True while a sign-in attempt is in flight.
var busy := false
## Short, player-safe text for the last failed attempt ("" when none).
var last_message := ""

var _sign_in: PlayGamesSignInClient
var _players: PlayGamesPlayersClient
var _apple_auth: Object = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	match OS.get_name():
		"Android":
			platform = Platform.ANDROID
			_setup_play_games()
		"iOS":
			platform = Platform.IOS
			_load_apple_session()


## True when this platform has a native identity to offer at all.
func is_supported() -> bool:
	return platform != Platform.NONE


func service_name() -> String:
	match platform:
		Platform.ANDROID:
			return "Google Play Games"
		Platform.IOS:
			return "Sign in with Apple"
	return ""


## Connect (Android) / Sign in (iOS). Always safe to call; failures only set last_message.
func sign_in() -> void:
	if busy or connected:
		return
	last_message = ""
	match platform:
		Platform.ANDROID:
			if _sign_in == null:
				_fail("Google Play Games is unavailable on this device.")
				return
			_set_busy(true)
			_sign_in.sign_in()
		Platform.IOS:
			var auth := _apple_auth_instance()
			if auth == null:
				_fail("Sign in with Apple is unavailable on this build.")
				return
			_set_busy(true)
			auth.call("signin_with_scopes", ["email", "full_name"])


## iOS only: forget the stored Apple identity (local progress is untouched).
func sign_out() -> void:
	if platform != Platform.IOS:
		return
	connected = false
	display_name = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
	changed.emit()


## ---- Android: Play Games ----

func _setup_play_games() -> void:
	if GodotPlayGameServices.initialize() != GodotPlayGameServices.PlayGamesPluginError.OK:
		return
	_sign_in = PlayGamesSignInClient.new()
	_players = PlayGamesPlayersClient.new()
	add_child(_sign_in)
	add_child(_players)
	_sign_in.user_authenticated.connect(_on_play_authenticated)
	_players.current_player_loaded.connect(_on_player_loaded)
	_sign_in.is_authenticated() # asks without prompting; answers via user_authenticated


func _on_play_authenticated(authenticated: bool) -> void:
	var was_busy := busy
	_set_busy(false)
	connected = authenticated
	if authenticated:
		last_message = ""
		if _players != null:
			_players.load_current_player(false)
	else:
		display_name = ""
		if was_busy:
			last_message = "Could not connect to Google Play Games."
	changed.emit()


func _on_player_loaded(player: PlayGamesPlayer) -> void:
	if player != null:
		display_name = player.display_name
		changed.emit()


## ---- iOS: Sign in with Apple ----

func _apple_auth_instance() -> Object:
	if _apple_auth == null and platform == Platform.IOS and ClassDB.class_exists(APPLE_AUTH_CLASS):
		_apple_auth = ClassDB.instantiate(APPLE_AUTH_CLASS)
		if _apple_auth != null:
			# SwiftGodot calls back off the main thread - always deferred.
			_apple_auth.connect("authorization_completed", _on_apple_completed, CONNECT_DEFERRED)
			_apple_auth.connect("authorization_failed", _on_apple_failed, CONNECT_DEFERRED)
	return _apple_auth


## credential is an ASAuthorizationAppleIDCredential; checked structurally so this script
## compiles where the extension is absent. Tokens are never read, stored or logged.
func _on_apple_completed(credential: Object) -> void:
	_set_busy(false)
	if credential == null or not credential.has_method("get_identity_token"):
		_fail("Sign in with Apple failed. Please try again.")
		return
	var name_text := ""
	var full_name: Variant = credential.get("full_name")
	if full_name != null and typeof(full_name) == TYPE_OBJECT:
		var given: Variant = full_name.get("given_name")
		var family: Variant = full_name.get("family_name")
		name_text = ("%s %s" % [given if given != null else "", family if family != null else ""]).strip_edges()
	# Apple only returns the name on the FIRST authorization; keep a previously stored one.
	if name_text == "":
		name_text = display_name
	display_name = name_text
	connected = true
	last_message = ""
	_save_apple_session()
	changed.emit()


## Apple reports cancellation through the same failed signal (message heuristic, unverified
## on a real device): a cancel is not an error to show.
func _on_apple_failed(error_message: String) -> void:
	_set_busy(false)
	if error_message.to_lower().contains("cancel"):
		last_message = ""
		changed.emit()
		return
	_fail("Sign in with Apple failed. Please try again.")


func _save_apple_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"apple": true, "name": display_name}))


func _load_apple_session() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
	if typeof(parsed) == TYPE_DICTIONARY and bool(parsed.get("apple", false)):
		connected = true
		display_name = str(parsed.get("name", ""))


func _set_busy(value: bool) -> void:
	busy = value
	changed.emit()


func _fail(message: String) -> void:
	busy = false
	last_message = message
	changed.emit()
