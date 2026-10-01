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

	# Redesign: the card is drawn by the shared BeamUI card style (no baked frame art).
	_background.visible = false
	BeamUI.apply_card_styles(self, "locked" if not unlocked else ("done" if completed else "open"))
	_number_label.modulate = Color(1, 1, 1, 0.4) if not unlocked else Color.WHITE
