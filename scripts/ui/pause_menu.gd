extends Control
## scenes/ui/pause_menu.tscn root script (Milestone 4A - new this
## milestone, see ARCHITECTURE.md "Pause menu"). Purely presentational +
## input relay, exactly like LevelCompletePopup - game.gd owns actually
## pausing the SceneTree and all navigation. process_mode is set to
## ALWAYS on this scene's root node so its buttons stay clickable while
## get_tree().paused is true.

signal resume_pressed
signal restart_pressed
signal settings_pressed
signal level_select_pressed
signal main_menu_pressed

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _level_select_button: Button = %LevelSelectButton
@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_settings_button.pressed.connect(func() -> void: settings_pressed.emit())
	_level_select_button.pressed.connect(func() -> void: level_select_pressed.emit())
	_main_menu_button.pressed.connect(func() -> void: main_menu_pressed.emit())

	for button in [_resume_button, _restart_button, _settings_button, _level_select_button, _main_menu_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)

	hide()


## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): unlike
## LevelCompletePopup (which has no separate Main Menu button, so its own
## Level Select button gets relabeled instead), Pause already has BOTH a
## dedicated LEVEL SELECT and a dedicated MAIN MENU button - so a normal
## (non-QA) session simply hides Level Select here rather than duplicating
## Main Menu under a second label. game.gd calls this once per level load.
func set_level_select_visible(is_visible: bool) -> void:
	_level_select_button.visible = is_visible
