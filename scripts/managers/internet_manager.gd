extends Node
## Autoload: InternetManager - a PASSIVE connectivity monitor. Gameplay and local saves
## never need the internet, so this never blocks or pauses anything; it only exposes
## is_online (ads, purchases and sign-in check it before trying the network).
## process_mode = ALWAYS so its timers keep running while the tree is paused.

signal check_completed(is_online: bool)
signal internet_lost
signal internet_restored

## Same endpoint/success code the startup gate used before this pass -
## Google's own connectivity-check target (what Android/Chrome OS use
## for exactly this purpose), no personal/account data ever sent.
const CHECK_URL := "https://www.gstatic.com/generate_204"
const CHECK_TIMEOUT_SECONDS := 6.0
const PERIODIC_CHECK_INTERVAL_SECONDS := 4.0

var is_online: bool = true
var check_in_progress: bool = false

var _has_checked_once := false

var _http_request: HTTPRequest
var _timeout_timer: Timer
var _periodic_timer: Timer


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

	request_check()


## Guarded by check_in_progress so the periodic timer and an app-resume check landing close together collapse into the ONE
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
	else:
		internet_lost.emit()
