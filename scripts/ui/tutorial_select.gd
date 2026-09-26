extends Control
## Displays one button per guided tutorial (T01-T10), built from
## LevelManager/SaveManager's tutorial_* state - a structural sibling of
## level_select.gd, kept as its own script/scene (rather than
## parameterizing level_select.gd) so Campaign's Level Select is never at
## risk of regressing while this is edited. See DECISIONS.md ("Guided
## tutorial system").

const TUTORIAL_BUTTON_SCENE := preload("res://scenes/ui/tutorial_button.tscn")

## Era 1's existing V2 background - kept as a fallback constant (not
## re-read from the .tscn) so _apply_era_background() can always restore
## it, the same "explicit default, not an assumption" pattern game.gd
## uses for its own HUD/background swap.
const DEFAULT_BACKGROUND := preload("res://assets/ui/backgrounds/bs_bg_tutorial_select_v2.png")

@onready var _tutorial_grid: GridContainer = %TutorialGrid
@onready var _back_button: Button = %BackButton
@onready var _background: TextureRect = %Background


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	_back_button.pressed.connect(AudioManager.play_ui_back)
	_apply_era_background()
	_populate_tutorials()


## Era 2: this screen shows T01-T20 together (both eras at once, unlike
## gameplay's one-level-at-a-time game.gd), so there's no single "current
## level" to theme against. Instead, the whole screen adopts the Era 2
## background once the player has real access to Era 2 content (their
## furthest unlocked tutorial is past T10) - before that, Era 2 tutorials
## are all shown locked anyway, so the Era 1 background stays accurate to
## what's actually playable. See ERA_2_DESIGN.md "Tutorial Select".
func _apply_era_background() -> void:
	var furthest_era := EraTheme.get_era_for_tutorial(SaveManager.tutorial_highest_unlocked_level)
	if furthest_era >= 2:
		var theme := EraTheme.for_era(furthest_era)
		_background.texture = theme.tutorial_select_background if theme.tutorial_select_background else DEFAULT_BACKGROUND
	else:
		_background.texture = DEFAULT_BACKGROUND


func _populate_tutorials() -> void:
	for child in _tutorial_grid.get_children():
		child.queue_free()

	for id in range(1, LevelManager.get_tutorial_level_count() + 1):
		var button := TUTORIAL_BUTTON_SCENE.instantiate()
		_tutorial_grid.add_child(button)
		button.setup(
			id,
			LevelManager.is_tutorial_level_selectable(id),
			SaveManager.is_tutorial_level_completed(id)
		)
		button.tutorial_selected.connect(_on_tutorial_selected)


func _on_tutorial_selected(tutorial_id: int) -> void:
	AudioManager.play_ui_level_select()
	GameManager.start_tutorial(tutorial_id)


## See main_menu.gd's _notification() - project.godot's quit_on_go_back=false
## means every top-level screen must replicate its own Back button's
## behavior for the system Back gesture/button itself.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.go_to_main_menu()
