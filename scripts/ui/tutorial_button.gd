extends Button
## Single tutorial-select button. A simplified sibling of level_button.gd
## (same locked/unlocked/completed textures, reused directly) with no
## stars row - tutorials aren't scored, see SaveManager's tutorial_*
## field comments. Purely presentational; tutorial_select.gd decides
## lock/complete state from SaveManager.

const TEXTURE_LOCKED := preload("res://assets/ui/level_select/bs_ui_level_button_locked_runtime.png")
const TEXTURE_UNLOCKED := preload("res://assets/ui/level_select/bs_ui_level_button_unlocked_runtime.png")
const TEXTURE_COMPLETED := preload("res://assets/ui/level_select/bs_ui_level_button_completed_runtime.png")

signal tutorial_selected(tutorial_id: int)

var tutorial_id: int = 1

@onready var _background: TextureRect = %Background
@onready var _number_label: Label = %NumberLabel


func _ready() -> void:
	pressed.connect(func() -> void: tutorial_selected.emit(tutorial_id))


func setup(id: int, unlocked: bool, completed: bool) -> void:
	tutorial_id = id
	disabled = not unlocked
	_number_label.text = "T%02d" % id

	if not unlocked:
		_background.texture = TEXTURE_LOCKED
	elif completed:
		_background.texture = TEXTURE_COMPLETED
	else:
		_background.texture = TEXTURE_UNLOCKED

	## Era identity is communicated by tinting the SAME compact square
	## frame T01-T10 use (modulate), never by swapping in a differently-
	## shaped card texture - bs_level_card_era2.png is a 1024x1536 tall
	## poster/panel asset, not a button frame, and produced a cropped,
	## frame-less look when covered into this button's 240x253 box. Era
	## 1's accent_color is white (no-op tint). See DECISIONS.md.
	_background.modulate = EraTheme.for_era(EraTheme.get_era_for_tutorial(id)).accent_color
