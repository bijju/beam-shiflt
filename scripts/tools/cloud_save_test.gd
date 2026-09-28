extends Node
## Dev-only CloudSave backend-selection/integration test harness (Firebase Cloud Save
## Phase 2B). Never exported (scripts/tools/**), never referenced by any normal play path.
## Reads CloudSave's underscore-prefixed internals directly (GDScript has no real privacy -
## this is a dev harness, not production code) purely to make backend identity/signal-
## connection state observable without adding debug-only public API surface to CloudSave
## itself.
##
## Run:
##   "D:\Godot_v4.7.1-stable_win64.exe" --headless --path . res://scripts/tools/cloud_save_test.tscn -- action=<...>
##
## Actions:
##   status          print CloudSave/backend/FirebaseAuth state
##   wait            wait a few seconds for async pull/reconcile to settle, then status
##   push            force an immediate CloudSave.sync_now(), wait for synced(), report
##   payload_size    measure JSON.stringify(SaveManager.to_dict()) byte length
##   summary         print a few representative SaveManager fields (no full profile dump)
##   signals         print connection counts for the active-only signal trio on both backends
##
## Never logs password/token/API key/full save payload contents.

var _timeout_timer: Timer


func _ready() -> void:
	var action := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("action="):
			action = arg.substr(7)

	print("[CloudSaveTest] action=%s" % action)

	match action:
		"status":
			_print_status()
			_finish()
		"wait":
			_start_timeout(6.0, func() -> void:
				_print_status()
				_finish()
			)
		"push":
			_print_status()
			CloudSave.synced.connect(func(ok: bool) -> void:
				print("[CloudSaveTest] PUSH result: ok=%s last_error=%s" % [ok, CloudSave.last_error()])
				_print_status()
				_finish()
			, CONNECT_ONE_SHOT)
			CloudSave.sync_now()
			_start_timeout(15.0, func() -> void:
				print("[CloudSaveTest] PUSH TIMED OUT")
				_finish()
			)
		"payload_size":
			var bytes := JSON.stringify(SaveManager.to_dict()).to_utf8_buffer().size()
			print("[CloudSaveTest] SaveManager.to_dict() JSON size = %d bytes (%.2f KB)" % [bytes, bytes / 1024.0])
			_finish()
		"summary":
			_print_summary()
			_finish()
		"signals":
			_print_signal_counts()
			_finish()
		"stress_select":
			for i in range(20):
				CloudSave._select_backend()
			print("[CloudSaveTest] called CloudSave._select_backend() 20x in a row (same state each time):")
			_print_signal_counts()
			_finish()
		"offline_save":
			_do_offline_save()
		"stamp_and_push":
			SaveManager.add_play_time(1.0)
			SaveManager.save_game()
			_print_summary()
			CloudSave.synced.connect(func(ok: bool) -> void:
				print("[CloudSaveTest] STAMP_AND_PUSH result: ok=%s last_error=%s" % [ok, CloudSave.last_error()])
				_finish()
			, CONNECT_ONE_SHOT)
			CloudSave.sync_now()
			_start_timeout(15.0, func() -> void:
				print("[CloudSaveTest] STAMP_AND_PUSH TIMED OUT")
				_finish()
			)
		_:
			print("[CloudSaveTest] unknown or missing action=")
			_finish()


func _start_timeout(seconds: float, on_timeout: Callable) -> void:
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = seconds
	_timeout_timer.timeout.connect(on_timeout)
	add_child(_timeout_timer)
	_timeout_timer.start()


func _finish() -> void:
	get_tree().quit()


func _backend_name() -> String:
	if CloudSave._backend == null:
		return "none"
	if CloudSave._backend == CloudSave._firebase_backend:
		return "firebase"
	if CloudSave._backend == CloudSave._native_backend:
		return "native"
	return "unknown"


func _print_status() -> void:
	print("[CloudSaveTest] CloudSave: is_signed_in=%s is_available=%s service_name=%s active_backend=%s native_authenticated=%s last_error=%s" % [
		CloudSave.is_signed_in,
		CloudSave.is_available(),
		CloudSave.service_name(),
		_backend_name(),
		CloudSave._native_authenticated,
		CloudSave.last_error(),
	])
	print("[CloudSaveTest] FirebaseAuth: signed_in=%s uid=%s" % [FirebaseAuth.is_signed_in(), FirebaseAuth.get_uid()])
	print("[CloudSaveTest] pending_choice=%s held_cloud_empty=%s" % [CloudSave.has_pending_choice(), CloudSave._held_cloud.is_empty()])


func _print_summary() -> void:
	print("[CloudSaveTest] SaveManager summary: version=%s play_time_seconds=%.1f saved_at=%s campaign_highest_unlocked_level=%s procedural_current_level=%s campaign_completed_count=%d" % [
		SaveManager.SAVE_VERSION,
		SaveManager.play_time_seconds,
		SaveManager.saved_at,
		SaveManager.campaign_highest_unlocked_level,
		SaveManager.procedural_current_level,
		SaveManager.campaign_completed_levels.size(),
	])


## Simulates being offline while SaveManager still writes locally: forces
## InternetManager.is_online=false, performs a real local save, asks CloudSave to sync
## (which must fail safely, not block, not corrupt local data), then restores is_online.
func _do_offline_save() -> void:
	print("[CloudSaveTest] pre-check: CloudSave.is_signed_in=%s backend=%s" % [CloudSave.is_signed_in, _backend_name()])
	InternetManager.is_online = false
	var before_saved_at := SaveManager.saved_at
	var ok := SaveManager.save_game()
	print("[CloudSaveTest] OFFLINE local SaveManager.save_game() returned %s (saved_at %s -> %s)" % [ok, before_saved_at, SaveManager.saved_at])
	CloudSave.sync_now()
	# Read synchronously, right after sync_now() returns - the OFFLINE guard in
	# FirebaseFirestoreREST._request() fires before any `await`, so this reflects the
	# real fail-fast result. (Note: InternetManager's own real periodic connectivity
	# check runs independently every 4s and will silently overwrite this manual
	# override back to the true, real network state shortly after - a harness/test
	# artifact of poking a live autoload's monitored property, not a CloudSave bug.)
	print("[CloudSaveTest] immediately after sync_now(): last_error=%s (expect a fail-fast OFFLINE-derived error, no hang)" % CloudSave.last_error())
	InternetManager.is_online = true
	_print_summary()
	_finish()


func _print_signal_counts() -> void:
	for label in ["native", "firebase"]:
		var backend: Node = CloudSave._native_backend if label == "native" else CloudSave._firebase_backend
		if backend == null:
			print("[CloudSaveTest] %s backend: not loaded" % label)
			continue
		var profile_n: int = backend.profile_loaded.get_connections().size()
		var conflict_n: int = backend.conflict_found.get_connections().size()
		var push_n: int = backend.push_finished.get_connections().size()
		print("[CloudSaveTest] %s backend signal connections: profile_loaded=%d conflict_found=%d push_finished=%d (expect 1 if active, 0 if inactive)" % [label, profile_n, conflict_n, push_n])
