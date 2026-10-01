extends Node
## Autoload: InternetManager - BeamShift REQUIRES a working internet connection at all
## times (local saves are unchanged; this is a product rule, not a sync feature).
## It owns the connectivity STATE only; InternetBlocker (autoload) owns the blocking UI
## and the SceneTree pause. A reachable network interface is not enough: the probe is a
## real HTTPS request, so a router/captive portal with no internet counts as offline.
## process_mode = ALWAYS so its timers keep running while the tree is paused.
##
## - Startup: gate_passed is false until the first successful probe; one failed probe
##   is enough to report offline (the player can RETRY, and a fast auto-retry runs).
## - Runtime: FAILURES_TO_DECLARE_LOST consecutive failures before internet_lost, so a
##   single dropped probe never flickers the blocker. One success restores.
## - App resume / RETRY: a single failure is trusted immediately (strict check).
## Play Games / Sign in with Apple state is deliberately unrelated to this.

signal check_completed(is_online: bool)
signal check_started
signal internet_lost
signal internet_restored

## Google's own connectivity-check target (what Android/Chrome OS use for exactly this),
## no personal/account data ever sent. A captive portal answers 200/302, not 204.
const CHECK_URL := "https://www.gstatic.com/generate_204"
const CHECK_TIMEOUT_SECONDS := 5.0
const PERIODIC_CHECK_INTERVAL_SECONDS := 8.0
const FAST_RETRY_INTERVAL_SECONDS := 2.0
const FAILURES_TO_DECLARE_LOST := 2

## Last CONFIRMED state (ads/purchases/sign-in read this).
var is_online: bool = true
## False until the first probe of this launch succeeded.
var gate_passed: bool = false
var check_in_progress: bool = false
var consecutive_failures: int = 0
## Test seam: false = never touch the network (a probe then stays "in flight" forever).
var network_probe_enabled: bool = true

var _has_checked_once := false
var _strict_check := false

var _http_request: HTTPRequest
var _timeout_timer: Timer
var _periodic_timer: Timer


## True while the game must not be usable: before the first successful probe, and while
## the connection is confirmed lost.
func is_blocking() -> bool:
	return not gate_passed or not is_online


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
	_periodic_timer.wait_time = FAST_RETRY_INTERVAL_SECONDS
	_periodic_timer.timeout.connect(_on_periodic_timer_timeout)
	add_child(_periodic_timer)
	_periodic_timer.start()

	request_check(true)


## Guarded by check_in_progress so the periodic timer and a resume check collapse into
## the ONE in-flight request - never two overlapping HTTPRequests. `strict` makes a
## failure count as lost immediately (resume / RETRY).
func request_check(strict: bool = false) -> void:
	if check_in_progress:
		_strict_check = _strict_check or strict
		return
	_strict_check = strict
	check_in_progress = true
	check_started.emit()
	if not network_probe_enabled:
		return
	var err := _http_request.request(CHECK_URL)
	if err != OK:
		check_in_progress = false
		_resolve_check(false)
		return
	_timeout_timer.start()


## The blocker's RETRY button.
func retry() -> void:
	request_check(true)


func _on_periodic_timer_timeout() -> void:
	request_check()


## App returning from background: the previous state is not trustworthy, so restart any
## in-flight probe (it may predate the resume) as a strict one. FOCUS_IN also covers a
## desktop window refocus; harmless either way.
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_RESUMED and what != NOTIFICATION_APPLICATION_FOCUS_IN:
		return
	if _http_request != null and check_in_progress:
		_http_request.cancel_request()
		_timeout_timer.stop()
		check_in_progress = false
	request_check(true)


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
	var strict := _strict_check
	_strict_check = false
	var was_online := is_online
	var was_gate := gate_passed
	var first := not _has_checked_once
	_has_checked_once = true

	var confirmed := was_online
	if online:
		consecutive_failures = 0
		confirmed = true
		gate_passed = true
	else:
		consecutive_failures += 1
		if not gate_passed or strict or consecutive_failures >= FAILURES_TO_DECLARE_LOST:
			confirmed = false
	is_online = confirmed

	# Probe quickly while anything is unsettled, slowly (battery/network) while healthy.
	var wait := PERIODIC_CHECK_INTERVAL_SECONDS if (confirmed and consecutive_failures == 0) else FAST_RETRY_INTERVAL_SECONDS
	if _periodic_timer != null and not is_equal_approx(_periodic_timer.wait_time, wait):
		_periodic_timer.start(wait)

	check_completed.emit(online)
	if confirmed and (not was_online or not was_gate or first):
		internet_restored.emit()
	elif not confirmed and (was_online or first):
		internet_lost.emit()
