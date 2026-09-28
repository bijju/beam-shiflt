extends Node
## Dev-only FirebaseAuth REST manual test harness (Firebase REST Auth Phase 1).
## Never exported (scripts/tools/**), never referenced by game.gd/any autoload's normal
## play path. Exercises FirebaseAuth's real public API against the live "beamshift-game"
## Firebase project - use a disposable test email, never a real one, never paste a real
## password into a commit/log.
##
## Run (no run/main_scene edit needed - Godot can run a specific scene directly while
## still loading the full project, autoloads included):
##   "D:\Godot_v4.7.1-stable_win64.exe" --headless --path . res://scripts/tools/firebase_auth_test.tscn -- <args>
##
## Args:
##   action=create|sign_in|refresh|reset|sign_out|restore|status   (required)
##   email=you@example.com   password=Passw0rd!                    (create/sign_in/reset)
##
## Never prints password/id_token/refresh_token contents - only whether they are present.

var _timeout_timer: Timer


func _ready() -> void:
	var action := ""
	var email := ""
	var password := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("action="):
			action = arg.substr(7)
		elif arg.begins_with("email="):
			email = arg.substr(6)
		elif arg.begins_with("password="):
			password = arg.substr(9)

	print("[FirebaseAuthTest] action=%s" % action)
	_print_status("before")

	match action:
		"create":
			FirebaseAuth.account_create_finished.connect(_on_done)
			FirebaseAuth.create_account(email, password)
		"sign_in":
			FirebaseAuth.sign_in_finished.connect(_on_done)
			FirebaseAuth.sign_in(email, password)
		"refresh":
			FirebaseAuth.token_refresh_finished.connect(_on_done)
			FirebaseAuth.refresh_token()
		"reset":
			FirebaseAuth.password_reset_finished.connect(_on_done)
			FirebaseAuth.send_password_reset(email)
		"sign_out":
			FirebaseAuth.sign_out()
			_print_status("after")
			get_tree().quit()
			return
		"restore":
			if not FirebaseAuth.has_refresh_token():
				print("[FirebaseAuthTest] no stored session to restore.")
				get_tree().quit()
				return
			print("[FirebaseAuthTest] waiting for startup/manual restore result...")
			FirebaseAuth.session_restore_finished.connect(_on_done)
			FirebaseAuth.refresh_token() # deterministic: don't just wait on _ready's own startup timing
		"status":
			_print_status("after")
			get_tree().quit()
			return
		_:
			print("[FirebaseAuthTest] unknown or missing action= (create|sign_in|refresh|reset|sign_out|restore|status)")
			get_tree().quit()
			return

	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = 20.0
	_timeout_timer.timeout.connect(func() -> void:
		print("[FirebaseAuthTest] TIMED OUT waiting for a result.")
		get_tree().quit()
	)
	add_child(_timeout_timer)
	_timeout_timer.start()


func _on_done(success: bool, error_code: String) -> void:
	print("[FirebaseAuthTest] result: success=%s error=%s" % [success, error_code])
	_print_status("after")
	get_tree().quit()


func _print_status(when: String) -> void:
	print("[FirebaseAuthTest] status (%s): signed_in=%s uid=%s email=%s has_id_token=%s has_refresh_token=%s" % [
		when,
		FirebaseAuth.is_signed_in(),
		FirebaseAuth.get_uid(),
		FirebaseAuth.get_email(),
		FirebaseAuth.get_id_token() != "",
		FirebaseAuth.has_refresh_token(),
	])
