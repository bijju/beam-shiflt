extends Node
## Autoload: InternetManager (Runtime Internet Loss Blocking pass).
## THE one place that performs BeamShift's real internet-reachability
## check and THE one place that shows the global "INTERNET CONNECTION
## LOST" overlay + pauses the SceneTree when connectivity drops during
## normal play. Scripts must never duplicate this check or build a
## second offline overlay - request_check()/is_online/the signals below
## are the whole surface.
##
## The startup gate (internet_gate.gd, earlier pass) still owns its own
## "INTERNET CONNECTION REQUIRED" full-scene UI for the pre-Main-Menu
## case, but now delegates the actual network check to this autoload
## instead of owning its own HTTPRequest - see request_check()/
## check_completed. GATE_SCENE_PATH is how this manager avoids ever
## stacking its own runtime overlay on top of that screen.
##
## process_mode = ALWAYS (same pattern as CloudSave/StoreManager/their
## backends) so this autoload - and the overlay/timers it owns - keep
## working while get_tree().paused is true; that is the entire mechanism
## the overlay relies on to detect a restored connection and un-pause.

signal check_completed(is_online: bool)
signal internet_lost
signal internet_restored

## Same endpoint/success code the startup gate used before this pass -
## Google's own connectivity-check target (what Android/Chrome OS use
## for exactly this purpose), no personal/account data ever sent.
const CHECK_URL := "https://www.gstatic.com/generate_204"
const CHECK_TIMEOUT_SECONDS := 6.0
const PERIODIC_CHECK_INTERVAL_SECONDS := 4.0

const GATE_SCENE_PATH := "res://scenes/ui/internet_gate.tscn"

## Studio Splash pass: run/main_scene now boots into studio_splash.tscn
## BEFORE this gate. The runtime overlay must not stack on top of the
## company logo sequence any more than it already avoids stacking on the
## gate itself - see _should_show_overlay().
const STUDIO_SPLASH_SCENE_PATH := "res://scenes/ui/studio_splash.tscn"

var is_online: bool = true
var check_in_progress: bool = false

var _has_checked_once := false
var _paused_by_connectivity_loss := false

var _http_request: HTTPRequest
var _timeout_timer: Timer
var _periodic_timer: Timer

var _overlay_layer: CanvasLayer
var _overlay_screen: ConnectivityScreenBuilder.Screen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_http_request = HTTPRequest.new()
	_http_request.request_completed.connect(_on_request_completed)
	add_child(_http_request)

	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = CHECK_TIMEOUT_SECONDS
	_timeout_timer.timeout.connect(_on_check_timeout)
	add_child(_timeout_timer)

	_periodic_timer = Timer.new()
	_periodic_timer.wait_time = PERIODIC_CHECK_INTERVAL_SECONDS
	_periodic_timer.timeout.connect(_on_periodic_timer_timeout)
	add_child(_periodic_timer)
	_periodic_timer.start()

	_build_overlay()
	check_completed.connect(_on_check_completed_reset_retry_ui)

	request_check()


## Guarded by check_in_progress so the periodic timer, a RETRY tap, and an
## app-resume check landing close together collapse into the ONE
## in-flight request - never a second overlapping HTTPRequest. Callers
## (the startup gate, the overlay's own RETRY button) just call this and
## listen to check_completed/internet_lost/internet_restored.
func request_check() -> void:
	if check_in_progress:
		return
	check_in_progress = true
	var err := _http_request.request(CHECK_URL)
	if err != OK:
		check_in_progress = false
		_resolve_check(false)
		return
	_timeout_timer.start()


func _on_periodic_timer_timeout() -> void:
	request_check()


## Android/iOS app returning from background - see the pasted spec's
## "do not depend only on the next periodic tick". FOCUS_IN also covers
## desktop window refocus for free; harmless either way.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		request_check()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if not check_in_progress:
		return # already resolved by the timeout
	_timeout_timer.stop()
	check_in_progress = false
	_resolve_check(result == HTTPRequest.RESULT_SUCCESS and response_code == 204)


func _on_check_timeout() -> void:
	if not check_in_progress:
		return
	_http_request.cancel_request()
	check_in_progress = false
	_resolve_check(false)


func _resolve_check(online: bool) -> void:
	check_completed.emit(online)
	var changed := online != is_online or not _has_checked_once
	is_online = online
	_has_checked_once = true
	if not changed:
		return
	if online:
		internet_restored.emit()
		_on_internet_restored()
	else:
		internet_lost.emit()
		_on_internet_lost()


func _on_internet_lost() -> void:
	if not _should_show_overlay():
		return
	if get_tree().paused:
		# Already paused for another reason (e.g. the player opened Pause
		# themselves) - leave that state alone, see _on_internet_restored.
		_paused_by_connectivity_loss = false
	else:
		get_tree().paused = true
		_paused_by_connectivity_loss = true
	_overlay_layer.visible = true


func _on_internet_restored() -> void:
	_overlay_layer.visible = false
	if _paused_by_connectivity_loss:
		get_tree().paused = false
		_paused_by_connectivity_loss = false


func _should_show_overlay() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path != GATE_SCENE_PATH and scene.scene_file_path != STUDIO_SPLASH_SCENE_PATH


func _build_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 100
	_overlay_layer.visible = false
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_layer)

	var dim := Color(0.0, 0.02, 0.08, 0.92)
	_overlay_screen = ConnectivityScreenBuilder.build(
		_overlay_layer,
		"INTERNET CONNECTION LOST",
		"BeamShift requires an active internet connection to continue.",
		dim
	)
	_overlay_screen.retry_button.pressed.connect(_on_overlay_retry_pressed)
	_overlay_screen.exit_button.pressed.connect(_on_overlay_exit_pressed)
	# The overlay has no "checking" state distinct from "offline" - it's
	# always the full panel, never the startup gate's bare loading label.
	_overlay_screen.loading_row.visible = false
	_overlay_screen.panel.visible = true


func _on_overlay_retry_pressed() -> void:
	AudioManager.play_ui_button_press()
	_overlay_screen.retry_button.disabled = true
	_overlay_screen.retry_button.text = "CHECKING..."
	request_check()


func _on_overlay_exit_pressed() -> void:
	AudioManager.play_ui_button_press()
	GameManager.quit_game()


func _on_check_completed_reset_retry_ui(_is_online: bool) -> void:
	_overlay_screen.retry_button.disabled = false
	_overlay_screen.retry_button.text = "RETRY"
