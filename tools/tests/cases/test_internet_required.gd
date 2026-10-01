extends TestCase
## Mandatory-internet gate: InternetManager (state machine) + InternetBlocker (pause + overlay).
## No real network: probe results are injected through _resolve_check().

var _tree_paused_before: bool


func before_each() -> void:
	_tree_paused_before = runner.get_tree().paused
	_reset_manager()


func after_each() -> void:
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	InternetManager._resolve_check(true)
	InternetManager._periodic_timer.stop()
	runner.get_tree().paused = _tree_paused_before
	reset_scene()


## Back to a fresh launch: gate closed, nothing confirmed.
func _reset_manager() -> void:
	InternetManager._periodic_timer.stop()
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	InternetManager.gate_passed = false
	InternetManager.is_online = true
	InternetManager.consecutive_failures = 0
	InternetManager._has_checked_once = false
	InternetManager._strict_check = false
	InternetBlocker._refresh()


func _open_gate() -> void:
	InternetManager._resolve_check(true)


func _lose_connection() -> void:
	InternetManager._resolve_check(false)
	InternetManager._resolve_check(false)


func test_startup_online_proceeds() -> void:
	ok(InternetManager.is_blocking(), "held until the first probe answers")
	ok(runner.get_tree().paused)
	ok(not InternetBlocker.is_panel_visible(), "no flash while the first probe runs")
	var back := watch(InternetManager.internet_restored)
	_open_gate()
	ok(not InternetManager.is_blocking())
	ok(not runner.get_tree().paused)
	ok(not InternetBlocker.is_panel_visible())
	eq(back.size(), 1)


func test_startup_offline_shows_blocker() -> void:
	var lost := watch(InternetManager.internet_lost)
	InternetManager._resolve_check(false)
	ok(not InternetManager.is_online, "a single failed startup probe is enough")
	ok(InternetBlocker.is_panel_visible())
	ok(runner.get_tree().paused)
	eq(lost.size(), 1)
	ok(InternetBlocker._title.text.contains("REQUIRED"))


func test_retry_while_offline_stays_blocked_then_proceeds() -> void:
	InternetManager._resolve_check(false)
	InternetManager.retry()
	ok(InternetManager.check_in_progress and InternetManager._strict_check, "RETRY is a strict probe")
	ok(InternetBlocker._retry_button.disabled, "RETRY disabled while checking")
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	InternetManager._resolve_check(false)
	ok(InternetBlocker.is_panel_visible(), "still offline -> blocker stays")
	ok(not InternetBlocker._retry_button.disabled)
	_open_gate()
	ok(not InternetBlocker.is_panel_visible())
	ok(not runner.get_tree().paused)


func test_runtime_disconnect_on_menu_blocks() -> void:
	_open_gate()
	var lost := watch(InternetManager.internet_lost)
	InternetManager._resolve_check(false)
	ok(InternetManager.is_online, "one failed probe is not enough (false-positive protection)")
	ok(not InternetBlocker.is_panel_visible())
	InternetManager._resolve_check(false)
	ok(not InternetManager.is_online)
	ok(InternetBlocker.is_panel_visible())
	ok(runner.get_tree().paused)
	ok(InternetBlocker._title.text.contains("LOST"))
	eq(lost.size(), 1, "internet_lost fires once")


func test_transient_failure_does_not_flicker() -> void:
	_open_gate()
	InternetManager._resolve_check(false)
	InternetManager._resolve_check(true)
	InternetManager._resolve_check(false)
	ok(InternetManager.is_online and not runner.get_tree().paused, "failures must be consecutive")


func test_runtime_disconnect_pauses_gameplay_and_resume_keeps_state() -> void:
	_open_gate()
	GameManager.start_level(1)
	await frames(3)
	var game := current_scene()
	ok(game != null)
	var grid: GridManager = game.get_node_or_null("%GridManager") if game != null else null
	var before := {}
	if grid != null:
		before = grid.tile_orientations.duplicate()
	_lose_connection()
	ok(runner.get_tree().paused, "gameplay paused")
	await frames(2)
	_open_gate()
	ok(not runner.get_tree().paused)
	ok(current_scene() == game, "same scene, not reloaded")
	if grid != null:
		eq(grid.tile_orientations, before, "board state untouched")


func test_reconnect_restores_previous_pause_state() -> void:
	_open_gate()
	runner.get_tree().paused = true # e.g. the in-game Pause menu is open
	_lose_connection()
	_open_gate()
	ok(runner.get_tree().paused, "a game already paused by the Pause menu stays paused")
	runner.get_tree().paused = false


func test_settings_open_is_blocked_on_loss() -> void:
	_open_gate()
	GameManager.go_to_settings()
	await frames(3)
	_lose_connection()
	ok(InternetBlocker.is_panel_visible() and runner.get_tree().paused)
	_open_gate()
	ok(not InternetBlocker.is_panel_visible())


func test_nothing_unpauses_under_the_blocker() -> void:
	_open_gate()
	_lose_connection()
	runner.get_tree().paused = false # e.g. a screen's own resume handler
	InternetBlocker._process(0.0)
	ok(runner.get_tree().paused)


func test_play_games_failure_is_not_an_internet_failure() -> void:
	_open_gate()
	PlatformAccount.platform = PlatformAccount.Platform.ANDROID
	PlatformAccount._on_play_authenticated(false)
	ok(not PlatformAccount.connected)
	ok(InternetManager.is_online and not InternetManager.is_blocking())
	ok(not runner.get_tree().paused and not InternetBlocker.is_panel_visible())
	ok(SaveManager.save_game())


func test_foreground_triggers_strict_recheck() -> void:
	_open_gate()
	InternetManager._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ok(InternetManager.check_in_progress and InternetManager._strict_check)
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	# strict: a single failed probe after resume is trusted immediately
	InternetManager._strict_check = true
	InternetManager._resolve_check(false)
	ok(not InternetManager.is_online)
	ok(InternetBlocker.is_panel_visible())


func test_probe_interval_adapts() -> void:
	_open_gate()
	near(InternetManager._periodic_timer.wait_time, InternetManager.PERIODIC_CHECK_INTERVAL_SECONDS)
	InternetManager._resolve_check(false)
	near(InternetManager._periodic_timer.wait_time, InternetManager.FAST_RETRY_INTERVAL_SECONDS)


func test_probe_plumbing() -> void:
	InternetManager.check_in_progress = true
	InternetManager._on_request_completed(HTTPRequest.RESULT_SUCCESS, 204, PackedStringArray(), PackedByteArray())
	ok(InternetManager.is_online and InternetManager.gate_passed)
	# a captive portal answers 200, not 204 -> offline
	_reset_manager()
	InternetManager.check_in_progress = true
	InternetManager._on_request_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	ok(not InternetManager.is_online)
	InternetManager.check_in_progress = true
	InternetManager._on_check_timeout()
	InternetManager._on_check_timeout() # no probe in flight -> no-op
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false


func test_no_firebase_dependency_in_gate() -> void:
	for path in ["res://scripts/managers/internet_manager.gd", "res://scripts/managers/internet_blocker.gd"]:
		var text := FileAccess.get_file_as_string(path).to_lower()
		ok(not text.contains("firebase") and not text.contains("firestore"), path)
	ok(not ProjectSettings.has_setting("autoload/FirebaseAuth"))
	ok(ProjectSettings.has_setting("autoload/InternetBlocker"))
