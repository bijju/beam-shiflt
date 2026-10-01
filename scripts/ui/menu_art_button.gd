class_name MenuArtButton
extends Button
## Main Menu primary button whose whole look is a supplied PNG (the label is baked into the art).
## The Button itself stays the touch target and covers the full displayed art rect; the art is a
## TextureRect inside it using KEEP_ASPECT_CENTERED, so it is never stretched or cropped.
## The PNGs differ by a few px in size; the caller sizes one shared box from the narrowest aspect.

const PRESSED_SCALE := 0.97
const PRESSED_MODULATE := Color(0.82, 0.88, 1.0, 1.0)
const DISABLED_MODULATE := Color(0.5, 0.5, 0.55, 0.75)

@export var art: Texture2D
## Normalized alpha bounding box of the painted art inside the (padded) texture; BeamButtonGlow hugs this.
@export var content_rect := Rect2(0, 0, 1, 1)

var _art_rect: TextureRect


func art_aspect() -> float:
	return art.get_width() / float(art.get_height())


## Where the visible art actually lands inside the button (texture aspect-fit and centred, then its content_rect).
func visible_rect() -> Rect2:
	var tex := Vector2(art.get_width(), art.get_height())
	var s := minf(size.x / tex.x, size.y / tex.y)
	var origin := (size - tex * s) * 0.5
	return Rect2(origin + content_rect.position * tex * s, content_rect.size * tex * s)


func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(s, empty)
	_art_rect = TextureRect.new()
	_art_rect.texture = art
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_art_rect)
	_art_rect.resized.connect(func() -> void: _art_rect.pivot_offset = _art_rect.size * 0.5)
	button_down.connect(_apply_visual_state)
	button_up.connect(_apply_visual_state)
	mouse_exited.connect(_apply_visual_state)
	_apply_visual_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_ENABLED:
		_apply_visual_state()


func _apply_visual_state() -> void:
	if _art_rect == null:
		return
	var down := button_pressed or (is_pressed() and not disabled)
	_art_rect.scale = Vector2.ONE * (PRESSED_SCALE if down else 1.0)
	_art_rect.modulate = DISABLED_MODULATE if disabled else (PRESSED_MODULATE if down else Color.WHITE)
