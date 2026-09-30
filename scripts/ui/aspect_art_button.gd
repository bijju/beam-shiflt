class_name AspectArtButton
extends Button
## Button whose art keeps the source PNG's aspect ratio. The shared theme's
## StyleBoxTexture draws its 70x32 px end caps unscaled, so on a short button
## (tutorial panel / lesson-complete) the caps consume the whole height and the
## middle is squashed. Here the art is one aspect-locked TextureRect behind a
## style-less Button; width is derived from the requested height.

const _ART := preload("res://assets/ui/buttons/bs_ui_button_primary.png")
const _REGION := Rect2(35, 165, 1705, 545)
## Fraction of width kept clear of the metallic end caps for the label.
const _TEXT_PAD_FRACTION := 0.12

@export var button_height: float = 96.0

var _art: TextureRect


func _ready() -> void:
	var aspect := _REGION.size.x / _REGION.size.y
	custom_minimum_size = Vector2(button_height * aspect, button_height)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pad := custom_minimum_size.x * _TEXT_PAD_FRACTION
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = pad
	empty.content_margin_right = pad
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, empty)
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	clip_text = false

	var atlas := AtlasTexture.new()
	atlas.atlas = _ART
	atlas.region = _REGION
	_art = TextureRect.new()
	_art.texture = atlas
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.show_behind_parent = true
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_art)

	button_down.connect(_refresh)
	button_up.connect(_refresh)
	mouse_entered.connect(_refresh)
	mouse_exited.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _art == null:
		return
	if disabled:
		_art.modulate = Color(1, 1, 1, 0.5)
	elif button_pressed or is_pressed():
		_art.modulate = Color(0.8, 0.8, 0.8, 1)
	elif is_hovered():
		_art.modulate = Color(1.15, 1.15, 1.15, 1)
	else:
		_art.modulate = Color.WHITE
