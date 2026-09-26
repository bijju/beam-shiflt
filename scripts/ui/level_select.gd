extends Control
## Displays one button per level, built dynamically from LevelManager/
## SaveManager state. Scales to ~100 levels via ScrollContainer +
## GridContainer without any per-button hand authoring - see
## ARCHITECTURE.md for how stage grouping would extend this later.

const LEVEL_BUTTON_SCENE := preload("res://scenes/ui/level_button.tscn")

## Era 1's existing V2 background - see tutorial_select.gd's identical
## _apply_era_background() pattern for why this stays a fallback
## constant rather than being read back from the .tscn.
const DEFAULT_BACKGROUND := preload("res://assets/ui/backgrounds/bs_bg_campaign_select_v2.png")

@onready var _level_grid: GridContainer = %LevelGrid
@onready var _back_button: Button = %BackButton
@onready var _background: TextureRect = %Background


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	_back_button.pressed.connect(AudioManager.play_ui_back)
	_apply_era_background()
	_populate_levels()


## Era 2: mirrors tutorial_select.gd's _apply_era_background() exactly -
## this screen shows every campaign level at once, so it themes itself
## against the player's FURTHEST unlocked level's era, not any single
## level. Inert today (no campaign level exists past 100 yet), but
## correct and ready the moment Levels 101+ exist - see
## ERA_2_DESIGN.md "Level Select preparation".
func _apply_era_background() -> void:
	var furthest_era := EraTheme.get_era_for_level(SaveManager.campaign_highest_unlocked_level)
	if furthest_era >= 2:
		var theme := EraTheme.for_era(furthest_era)
		_background.texture = theme.level_select_background if theme.level_select_background else DEFAULT_BACKGROUND
	else:
		_background.texture = DEFAULT_BACKGROUND


func _populate_levels() -> void:
	for child in _level_grid.get_children():
		child.queue_free()

	for id in range(1, LevelManager.get_campaign_level_count() + 1):
		var button := LEVEL_BUTTON_SCENE.instantiate()
		_level_grid.add_child(button)
		button.setup(
			id,
			LevelManager.is_campaign_level_selectable(id),
			SaveManager.is_campaign_level_completed(id),
			SaveManager.get_campaign_best_stars(id)
		)
		button.level_selected.connect(_on_level_selected)


func _on_level_selected(level_id: int) -> void:
	# QA/dev-only entry point (Phase 2: Direct Play + Continue Flow, see
	# DECISIONS.md D85) - from_level_select=true so game.gd routes Back/
	# Pause/Level-Complete's "Level Select" button back here instead of
	# Main Menu, and skips writing campaign_resume_* state entirely.
	AudioManager.play_ui_level_select()
	GameManager.start_level(level_id, true)


## See main_menu.gd's _notification() - project.godot's quit_on_go_back=false
## means every top-level screen must replicate its own Back button's
## behavior for the system Back gesture/button itself.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.go_to_main_menu()
