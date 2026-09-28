extends Control
## Startup internet-required gate (Internet Gate pass, extended by the
## Runtime Internet Loss Blocking pass). Set as project.godot's
## run/main_scene - runs BEFORE Main Menu. Blocks entry into Main Menu/
## gameplay until InternetManager confirms real internet reachability;
## the player cannot bypass this screen.
##
## The actual network check is owned by the InternetManager autoload
## (shared with its own runtime "connection lost" overlay - see
## InternetManager.GATE_SCENE_PATH, which is how that overlay avoids ever
## stacking on top of THIS screen). This scene only owns its own UI state
## and reacts to InternetManager's check_completed signal.
##
## Still deliberately startup-only in its OWN UI: once the player reaches
## Main Menu, InternetManager's runtime overlay (not this scene) is what
## reacts if the connection later drops.

var _screen: ConnectivityScreenBuilder.Screen


func _ready() -> void:
	_screen = ConnectivityScreenBuilder.build(
		self,
		"INTERNET CONNECTION REQUIRED",
		"BeamShift requires an active internet connection to continue.",
		Color(0.015, 0.03, 0.08, 1)
	)
	_screen.retry_button.pressed.connect(_on_retry_pressed)
	_screen.exit_button.pressed.connect(_on_exit_pressed)

	InternetManager.check_completed.connect(_on_check_completed)
	if InternetManager.check_in_progress:
		_screen.loading_row.visible = true
	else:
		InternetManager.request_check()


func _on_check_completed(is_online: bool) -> void:
	_screen.retry_button.disabled = false
	_screen.retry_button.text = "RETRY"
	if is_online:
		get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)
		return
	_screen.loading_row.visible = false
	_screen.panel.visible = true


func _on_retry_pressed() -> void:
	AudioManager.play_ui_button_press()
	_screen.loading_row.visible = true
	_screen.retry_button.disabled = true
	_screen.retry_button.text = "CHECKING..."
	InternetManager.request_check()


func _on_exit_pressed() -> void:
	AudioManager.play_ui_button_press()
	GameManager.quit_game()


## project.godot sets quit_on_go_back=false project-wide (see game.gd/
## main_menu.gd's own identical handler) - without this override, Back
## would silently do nothing here rather than exit, leaving the player
## stuck on a screen they already can't otherwise bypass.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.quit_game()
