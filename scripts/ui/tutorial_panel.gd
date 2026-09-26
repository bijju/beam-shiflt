extends Control
## scenes/ui/tutorial_panel.tscn root script. Purely presentational -
## game.gd/TutorialManager own all tutorial state; this just renders the
## current step's text and emits continue_pressed when the player taps
## through a MESSAGE-type step. See DECISIONS.md ("Guided tutorial
## system").

signal continue_pressed

@onready var _text_label: Label = %InstructionLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	_continue_button.pressed.connect(AudioManager.play_tutorial_step)


## `show_continue_button`: true for a MESSAGE step (player taps through),
## false for a step that advances on its own from real gameplay action
## (REQUIRE_TILE_TAP / WAIT_FOR_TARGET_ACTIVATION / WAIT_FOR_PUZZLE_
## SOLVED) - the panel still shows the instruction text for those, just
## without a redundant continue affordance.
func show_step(text: String, show_continue_button: bool) -> void:
	_text_label.text = text
	_continue_button.visible = show_continue_button
	visible = text != ""
