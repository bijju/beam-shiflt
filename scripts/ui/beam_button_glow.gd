class_name BeamButtonGlow
extends ColorRect
## Moving beam around a button's outline. Added as a child of an art button (MenuArtButton /
## SettingsArtButton); it sizes itself to the button's VISIBLE art rect, draws additive light only and
## never takes input. Use BeamButtonGlow.attach() so colour and idle timing are staggered consistently.

const SHADER := preload("res://scripts/ui/beam_button_glow.gdshader")
const PRESSED_SCALE := 0.97
const CYAN := Color(0.2, 0.85, 1.0, 1.0)
const RED_ORANGE := Color(1.0, 0.36, 0.1, 1.0)
## Successive glows start their idle cycle this far apart (wrapped into the idle interval), so a screen
## with several buttons never pulses all at once.
const STAGGER_STEP := 1.37

static var _attach_count := 0

@export var idle_interval := 4.2
@export var sweep_duration := 1.15
@export var idle_glow := 0.22
@export var hover_glow := 0.4
@export var beam_width := 0.035
@export var trail_length := 0.16
@export var corner_radius_fraction := 0.3

var _mat: ShaderMaterial
var _t := 0.0
var _sweeping := false
var _sweep_t := 0.0
var _flash := 0.0
var _hover := false
var _beam_color := CYAN
var _phase := 0.0


## Adds a glow to `button` (never blocks input) with a staggered idle phase. `color` defaults to cyan.
static func attach(button: Button, color: Color = CYAN) -> BeamButtonGlow:
	var glow := BeamButtonGlow.new()
	glow._beam_color = color
	glow._phase = fmod(_attach_count * STAGGER_STEP, glow.idle_interval - 0.9) + 0.6
	_attach_count += 1
	button.add_child(glow)
	return glow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	color = Color.WHITE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	_mat.set_shader_parameter("beam_width", beam_width)
	_mat.set_shader_parameter("trail_length", trail_length)
	_mat.set_shader_parameter("base_glow", idle_glow)
	resized.connect(_on_resized)
	_mat.set_shader_parameter("beam_color", _beam_color)
	var art = get_parent().get("art") as Texture2D
	if art != null:
		var cr: Rect2 = _content_rect()
		_mat.set_shader_parameter("art_tex", art)
		_mat.set_shader_parameter("art_rect", Vector4(cr.position.x, cr.position.y, cr.size.x, cr.size.y))
	var button := get_parent() as Button
	_fit_to_art()
	_on_resized()
	if button != null:
		button.resized.connect(_fit_to_art)
		button.mouse_entered.connect(_set_hover.bind(true))
		button.mouse_exited.connect(_set_hover.bind(false))
		button.button_down.connect(play_press_flash)
		button.button_down.connect(_set_pressed.bind(true))
		button.button_up.connect(_set_pressed.bind(false))
		button.mouse_exited.connect(_set_pressed.bind(false))
	visibility_changed.connect(_on_visibility_changed)
	start_idle()


func _content_rect() -> Rect2:
	var cr = get_parent().get("content_rect")
	return cr if cr is Rect2 else Rect2(0, 0, 1, 1)


## Covers exactly the displayed art (aspect-fit of the visible region inside the button, centred), so
## the beam hugs the art outline even when the button box is larger than the art.
func _fit_to_art() -> void:
	var button := get_parent() as Control
	var art = get_parent().get("art") as Texture2D
	if button == null or art == null:
		position = Vector2.ZERO
		size = button.size if button != null else size
		return
	if button is MenuArtButton:
		var vr: Rect2 = button.visible_rect()
		position = vr.position
		size = vr.size
		return
	var cr := _content_rect()
	var region := Vector2(art.get_width() * cr.size.x, art.get_height() * cr.size.y)
	var s := minf(button.size.x / region.x, button.size.y / region.y)
	var fitted := region * s
	position = (button.size - fitted) * 0.5
	size = fitted


func _on_resized() -> void:
	pivot_offset = size * 0.5
	if _mat != null:
		_mat.set_shader_parameter("rect_size", size)
		_mat.set_shader_parameter("corner_radius", size.y * corner_radius_fraction)
		_mat.set_shader_parameter("edge_inset", size.y * 0.06)
		_mat.set_shader_parameter("beam_softness", size.y * 0.05)


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree():
		start_idle()


func set_beam_color(c: Color) -> void:
	_beam_color = c
	_mat.set_shader_parameter("beam_color", c)


func start_idle() -> void:
	_t = idle_interval - _phase  # first sweep `_phase` seconds after the screen opens
	_sweeping = false
	_flash = 0.0
	_apply()


func play_sweep() -> void:
	_sweeping = true
	_sweep_t = 0.0


func play_press_flash() -> void:
	_flash = 1.0


func _set_hover(on: bool) -> void:
	_hover = on
	if on and not _sweeping:
		play_sweep()


func _set_pressed(down: bool) -> void:
	scale = Vector2.ONE * (PRESSED_SCALE if down else 1.0)


func _process(delta: float) -> void:
	_t += delta
	if not _sweeping and _t >= idle_interval:
		_t = 0.0
		play_sweep()
	if _sweeping:
		_sweep_t += delta
		if _sweep_t >= sweep_duration:
			_sweeping = false
	_flash = maxf(0.0, _flash - delta * 5.0)
	_apply()


func _apply() -> void:
	if _mat == null:
		return
	var button := get_parent() as Button
	if button != null and button.disabled:
		_mat.set_shader_parameter("beam_strength", 0.0)
		_mat.set_shader_parameter("base_glow", 0.0)
		_mat.set_shader_parameter("flash", 0.0)
		return
	var p := clampf(_sweep_t / sweep_duration, 0.0, 1.0)
	# ease so the beam accelerates through the straights and still reads at the corners
	_mat.set_shader_parameter("beam_progress", p)
	_mat.set_shader_parameter("beam_strength", 1.0 if _sweeping else 0.0)
	_mat.set_shader_parameter("base_glow", hover_glow if _hover else idle_glow)
	_mat.set_shader_parameter("flash", _flash)
