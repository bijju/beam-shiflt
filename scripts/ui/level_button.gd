extends Button
## Single level-select button. Purely presentational; level_select.gd
## decides lock/complete/star state from SaveManager and LevelManager.
## Milestone 4A: swaps a background texture per state and a row of star
## icons instead of composing everything as button text - see
## ARCHITECTURE.md "Level Select".

const TEXTURE_LOCKED := preload("res://assets/ui/level_select/bs_ui_level_button_locked_runtime.png")
const TEXTURE_UNLOCKED := preload("res://assets/ui/level_select/bs_ui_level_button_unlocked_runtime.png")
const TEXTURE_COMPLETED := preload("res://assets/ui/level_select/bs_ui_level_button_completed_runtime.png")
const TEXTURE_STAR_EARNED := preload("res://assets/ui/level_select/bs_ui_star_earned_runtime.png")
const TEXTURE_STAR_UNEARNED := preload("res://assets/ui/level_select/bs_ui_star_unearned_runtime.png")

signal level_selected(level_id: int)

var level_id: int = 1

@onready var _background: TextureRect = %Background
@onready var _number_label: Label = %NumberLabel
@onready var _stars: Array[TextureRect] = [%Star1, %Star2, %Star3]


func _ready() -> void:
	pressed.connect(func() -> void: level_selected.emit(level_id))


func setup(id: int, unlocked: bool, completed: bool, stars: int) -> void:
	level_id = id
	disabled = not unlocked
	_number_label.text = str(id)

	if not unlocked:
		_background.texture = TEXTURE_LOCKED
	elif completed:
		_background.texture = TEXTURE_COMPLETED
	else:
		_background.texture = TEXTURE_UNLOCKED

	## Era identity is communicated by tinting the SAME compact square
	## frame Levels 1-100 use (modulate), never by swapping in a
	## differently-shaped card texture - bs_level_card_era2.png is a
	## 1024x1536 tall poster/panel asset, not a button frame (same bug
	## tutorial_button.gd had for T11-T20 - see DECISIONS.md). Era 1's
	## accent_color is white (no-op tint).
	_background.modulate = EraTheme.for_era(EraTheme.get_era_for_level(id)).accent_color

	for i in _stars.size():
		_stars[i].visible = completed
		_stars[i].texture = TEXTURE_STAR_EARNED if i < stars else TEXTURE_STAR_UNEARNED
