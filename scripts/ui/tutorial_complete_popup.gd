extends Control
## scenes/ui/tutorial_complete_popup.tscn root script. Distinct from
## LevelCompletePopup on purpose - tutorials have no stars/best-moves to
## show (see SaveManager's tutorial_* field comments) and T10's
## graduation screen offers a CAMPAIGN button instead of NEXT TUTORIAL.
## Purely presentational - game.gd owns all navigation/save logic.

signal next_tutorial_pressed
signal retry_pressed
signal tutorial_select_pressed
signal campaign_pressed

@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _next_button: Button = %NextTutorialButton
@onready var _campaign_button: Button = %CampaignButton
@onready var _retry_button: Button = %RetryButton
@onready var _tutorial_select_button: Button = %TutorialSelectButton

## Captured before any era swap - this popup's title+3-buttons content is
## shorter than an Era 2 frame's own top+bottom crystal-ornament margins,
## which would otherwise overlap the frame art with the button text (see
## DECISIONS.md - found via RENDERED verification, not source review).
var _default_panel_min_size: Vector2


func _ready() -> void:
	_default_panel_min_size = _panel.custom_minimum_size
	_next_button.pressed.connect(func() -> void: next_tutorial_pressed.emit())
	_campaign_button.pressed.connect(func() -> void: campaign_pressed.emit())
	_retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	_tutorial_select_button.pressed.connect(func() -> void: tutorial_select_pressed.emit())

	for button in [_next_button, _campaign_button, _retry_button, _tutorial_select_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)


## `is_final`: true for T10 - shows CAMPAIGN instead of NEXT TUTORIAL,
## and a "TUTORIAL COMPLETE" graduation title instead of "LESSON
## COMPLETE".
func show_result(is_final: bool) -> void:
	_title_label.text = "TUTORIAL COMPLETE" if is_final else "LESSON COMPLETE"
	_next_button.visible = not is_final
	_campaign_button.visible = is_final
	show()


## Era 2+ QA/Hardening pass: same pattern as LevelCompletePopup.set_era_panel()
## - see its doc comment. T01-T10 (Era 1) always pass texture == null here
## and keep this popup's original flat StyleBoxFlat, byte-for-byte unchanged.
func set_era_panel(texture: Texture2D, margins: PackedFloat32Array) -> void:
	if texture == null or margins.size() < 4:
		_panel.remove_theme_stylebox_override("panel")
		_panel.custom_minimum_size = _default_panel_min_size
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margins[0]
	style.texture_margin_top = margins[1]
	style.texture_margin_right = margins[2]
	style.texture_margin_bottom = margins[3]
	# content_margin_* deliberately left at StyleBox's own default (-1,
	# "same as texture_margin") - an earlier draft hardcoded these to the
	# old flat style's small 40/48 values, which placed the buttons well
	# inside the new frame's much larger top/bottom crystal ornaments,
	# visibly overlapping them (found via RENDERED verification).
	_panel.add_theme_stylebox_override("panel", style)
	# Force the container at least as tall as the frame's own fixed top+
	# bottom corner art, or StyleBoxTexture squeezes those corners into
	# the middle stretch region and the ornaments overlap the button text.
	_panel.custom_minimum_size = Vector2(
		_default_panel_min_size.x,
		maxf(_default_panel_min_size.y, margins[1] + margins[3] + 40.0)
	)
