class_name SettingsArtButton
extends Button
## Settings control whose whole look is a supplied PNG (label/icon baked in). The PNGs carry large,
## differing transparent padding, so the button is sized to the art's VISIBLE content rect
## (`content_rect`, normalized, measured from alpha) and the texture is placed so that rect fills the
## button uniformly: aspect preserved, nothing stretched, the visible art never cropped.

const PRESSED_SCALE := 0.97
const PRESSED_MODULATE := Color(0.82, 0.88, 1.0, 1.0)
const DISABLED_MODULATE := Color(0.5, 0.5, 0.55, 0.75)

@export var art: Texture2D
@export var content_rect := Rect2(0, 0, 1, 1)
## Displayed width of the visible content; height follows the content's own aspect.
@export var display_width := 300.0

var _art_rect: TextureRect
var _held := false


func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(s, empty)
	_art_rect = TextureRect.new()
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_art_rect)
	move_child(_art_rect, 0)  # art sits behind any child (e.g. a price label)
	resized.connect(_layout_art)
	button_down.connect(_set_held.bind(true))
	button_up.connect(_set_held.bind(false))
	mouse_exited.connect(_set_held.bind(false))
	set_art(art, content_rect)


func set_art(tex: Texture2D, rect: Rect2) -> void:
	art = tex
	content_rect = rect
	if art == null:
		return
	var cw := art.get_width() * rect.size.x
	var ch := art.get_height() * rect.size.y
	custom_minimum_size = Vector2(display_width, display_width * ch / cw)
	if _art_rect != null:
		_art_rect.texture = art
		_layout_art()
		_apply_visual_state()


func _layout_art() -> void:
	if _art_rect == null or art == null:
		return
	var tex_size := Vector2(art.get_width(), art.get_height())
	var cr := Rect2(content_rect.position * tex_size, content_rect.size * tex_size)
	var s := minf(size.x / cr.size.x, size.y / cr.size.y)
	_art_rect.size = tex_size * s
	var centre := (cr.position + cr.size * 0.5) * s
	_art_rect.position = size * 0.5 - centre
	_art_rect.pivot_offset = centre


func _set_held(held: bool) -> void:
	_held = held
	_apply_visual_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_ENABLED:
		_apply_visual_state()


func _apply_visual_state() -> void:
	if _art_rect == null:
		return
	var down := _held and not disabled
	_art_rect.scale = Vector2.ONE * (PRESSED_SCALE if down else 1.0)
	_art_rect.modulate = DISABLED_MODULATE if disabled else (PRESSED_MODULATE if down else Color.WHITE)
