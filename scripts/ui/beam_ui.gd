class_name BeamUI
extends RefCounted
## The BeamShift UI design system: ONE place for colours, sizes and the StyleBox recipes every screen
## uses. `build_theme()` assembles the shared Theme (themes/beamshift_theme.tres is generated from it by
## tools/ui_shots/build_theme.gd - edit the tokens here, then regenerate), and screens that build
## controls in code (popups, dialogs) call the same helpers so nothing drifts.
##
## Look: dark glass panels, a thin cyan "beam edge", a brighter illuminated base on buttons, restrained
## glow. Text is always a Label/Button (never baked into art). Fonts: Rajdhani (SIL OFL, assets/fonts).

# --- Palette -----------------------------------------------------------------------------------------
const CYAN := Color(0.30, 0.86, 1.0)
const CYAN_BRIGHT := Color(0.62, 0.95, 1.0)
const CYAN_DIM := Color(0.16, 0.52, 0.72)
const BLUE_DEEP := Color(0.02, 0.05, 0.11)
const GLASS := Color(0.035, 0.085, 0.165, 0.92)
const GLASS_LIGHT := Color(0.06, 0.14, 0.26, 0.94)
const TEXT := Color(0.93, 0.97, 1.0)
const TEXT_DIM := Color(0.60, 0.74, 0.88)
const DANGER := Color(1.0, 0.38, 0.38)
const GOLD := Color(1.0, 0.80, 0.25)
const SUCCESS := Color(0.45, 0.92, 0.62)

# --- Metrics (logical px at the 1080-wide reference canvas) -----------------------------------------
const RADIUS_BUTTON := 20
const RADIUS_PANEL := 26
const BORDER := 2
const BASE_EDGE := 6                ## thicker illuminated bottom edge of a button
const BUTTON_HEIGHT := 140.0        ## primary stack buttons
const BUTTON_HEIGHT_COMPACT := 104.0
const TOUCH_MIN := 96.0
const SCREEN_MARGIN := 40.0         ## left/right inset inside the safe area
const SECTION_GAP := 28
const CARD_GAP := 22
const FONT_BUTTON := 34
const FONT_TITLE := 64
const FONT_SECTION := 30
const FONT_BODY := 28
const FONT_SMALL := 24

const FONT_REGULAR := preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const FONT_BOLD := preload("res://assets/fonts/Rajdhani-Bold.ttf")


# --- StyleBox recipes ---------------------------------------------------------------------------------

static func _flat(fill: Color, border: Color, radius: int, border_w: int = BORDER, glow: Color = Color(0, 0, 0, 0), glow_size: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.corner_detail = 8
	s.anti_aliasing = true
	if glow_size > 0:
		s.shadow_color = glow
		s.shadow_size = glow_size
	return s


## kind: "primary" | "secondary" | "danger" | "ghost"; state: normal|hover|pressed|disabled|focus
static func button_box(kind: String, state: String) -> StyleBoxFlat:
	var edge := CYAN
	var fill := GLASS_LIGHT
	match kind:
		"secondary":
			fill = GLASS
			edge = CYAN_DIM
		"danger":
			edge = DANGER
			fill = Color(0.20, 0.06, 0.09, 0.94)
		"ghost":
			fill = Color(0.03, 0.07, 0.14, 0.55)
			edge = CYAN_DIM
	var s: StyleBoxFlat
	match state:
		"hover", "focus":
			s = _flat(fill.lightened(0.10), edge.lerp(Color.WHITE, 0.30), RADIUS_BUTTON, BORDER, Color(edge, 0.30), 14)
		"pressed":
			s = _flat(fill.darkened(0.25), edge.lerp(Color.WHITE, 0.15), RADIUS_BUTTON, BORDER, Color(edge, 0.12), 6)
		"disabled":
			s = _flat(Color(0.05, 0.08, 0.13, 0.70), Color(edge, 0.22), RADIUS_BUTTON, BORDER)
		_:
			s = _flat(fill, edge, RADIUS_BUTTON, BORDER, Color(edge, 0.18), 9)
	if state != "pressed" and state != "disabled":
		s.border_width_bottom = BASE_EDGE
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


## kind: "panel" (default glass) | "card" (lighter, for list rows) | "dialog" (opaque, cyan edge) | "header" (flat strip)
static func panel_box(kind: String = "panel") -> StyleBoxFlat:
	var s: StyleBoxFlat
	match kind:
		"card":
			s = _flat(GLASS_LIGHT, Color(CYAN_DIM, 0.55), 20, BORDER)
			s.content_margin_left = 28
			s.content_margin_right = 28
			s.content_margin_top = 20
			s.content_margin_bottom = 20
		"dialog":
			s = _flat(Color(0.03, 0.07, 0.14, 0.98), CYAN, RADIUS_PANEL, 3, Color(CYAN, 0.28), 22)
			s.content_margin_left = 48
			s.content_margin_right = 48
			s.content_margin_top = 44
			s.content_margin_bottom = 44
		"header":
			s = _flat(Color(0.02, 0.05, 0.11, 0.80), Color(CYAN_DIM, 0.45), 0, 0)
			s.border_width_bottom = 2
			s.content_margin_left = 24
			s.content_margin_right = 24
			s.content_margin_top = 14
			s.content_margin_bottom = 14
		_:
			s = _flat(GLASS, Color(CYAN, 0.55), RADIUS_PANEL, BORDER, Color(CYAN, 0.14), 16)
			s.content_margin_left = 34
			s.content_margin_right = 34
			s.content_margin_top = 28
			s.content_margin_bottom = 28
	return s


static func field_box(focused: bool) -> StyleBoxFlat:
	var s := _flat(Color(0.02, 0.05, 0.10, 0.95), CYAN if focused else CYAN_DIM, 16, BORDER, Color(CYAN, 0.25) if focused else Color(0, 0, 0, 0), 8 if focused else 0)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	return s


# --- Theme ----------------------------------------------------------------------------------------------

static func _apply_button(t: Theme, type_name: String, kind: String, base: String = "Button") -> void:
	if type_name != "Button":
		t.set_type_variation(type_name, base)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(st, type_name, button_box(kind, st))
	t.set_color("font_color", type_name, TEXT)
	t.set_color("font_hover_color", type_name, Color.WHITE)
	t.set_color("font_focus_color", type_name, Color.WHITE)
	t.set_color("font_pressed_color", type_name, CYAN_BRIGHT)
	t.set_color("font_disabled_color", type_name, Color(TEXT_DIM, 0.55))
	t.set_color("font_outline_color", type_name, Color(0.0, 0.03, 0.08, 0.9))
	t.set_constant("outline_size", type_name, 3)
	t.set_font_size("font_size", type_name, FONT_BUTTON)


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_REGULAR
	t.default_font_size = FONT_BODY

	_apply_button(t, "Button", "primary")
	_apply_button(t, "SecondaryButton", "secondary")
	_apply_button(t, "DangerButton", "danger")
	_apply_button(t, "GhostButton", "ghost")
	_apply_button(t, "RoundIconButton", "primary")
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(st, "RoundIconButton", round_box(st))
	t.set_font("font", "RoundIconButton", FONT_BOLD)
	t.set_type_variation("IconButton", "SecondaryButton")
	t.set_stylebox("normal", "IconButton", _icon_box("normal"))
	t.set_stylebox("hover", "IconButton", _icon_box("hover"))
	t.set_stylebox("pressed", "IconButton", _icon_box("pressed"))
	t.set_stylebox("focus", "IconButton", _icon_box("hover"))
	t.set_stylebox("disabled", "IconButton", _icon_box("disabled"))

	t.set_stylebox("panel", "PanelContainer", panel_box("panel"))
	t.set_stylebox("panel", "Panel", panel_box("panel"))
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", panel_box("card"))
	t.set_type_variation("DialogPanel", "PanelContainer")
	t.set_stylebox("panel", "DialogPanel", panel_box("dialog"))
	t.set_type_variation("HudPlate", "Panel")
	t.set_stylebox("panel", "HudPlate", hud_plate_box())
	t.set_type_variation("HeaderPanel", "PanelContainer")
	t.set_stylebox("panel", "HeaderPanel", panel_box("header"))

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0.0, 0.03, 0.08, 0.85))
	t.set_constant("outline_size", "Label", 3)
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", FONT_BOLD)
	t.set_font_size("font_size", "TitleLabel", FONT_TITLE)
	t.set_color("font_color", "TitleLabel", Color.WHITE)
	t.set_color("font_shadow_color", "TitleLabel", Color(CYAN, 0.55))
	t.set_constant("shadow_offset_y", "TitleLabel", 0)
	t.set_constant("shadow_outline_size", "TitleLabel", 12)
	t.set_type_variation("SectionLabel", "Label")
	t.set_font("font", "SectionLabel", FONT_BOLD)
	t.set_font_size("font_size", "SectionLabel", FONT_SECTION)
	t.set_color("font_color", "SectionLabel", CYAN)
	t.set_type_variation("DimLabel", "Label")
	t.set_font_size("font_size", "DimLabel", FONT_SMALL)
	t.set_color("font_color", "DimLabel", TEXT_DIM)

	t.set_stylebox("normal", "LineEdit", field_box(false))
	t.set_stylebox("focus", "LineEdit", field_box(true))
	t.set_stylebox("read_only", "LineEdit", field_box(false))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(TEXT_DIM, 0.6))
	t.set_color("caret_color", "LineEdit", CYAN)
	t.set_font_size("font_size", "LineEdit", FONT_BODY + 2)

	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_stylebox("scroll", "VScrollBar", _scroll_box())
	t.set_stylebox("grabber", "VScrollBar", _grab_box(0.55))
	t.set_stylebox("grabber_highlight", "VScrollBar", _grab_box(0.85))
	t.set_stylebox("grabber_pressed", "VScrollBar", _grab_box(1.0))
	return t


static func _icon_box(state: String) -> StyleBoxFlat:
	var s := button_box("secondary", state)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func _scroll_box() -> StyleBoxFlat:
	var s := _flat(Color(0.03, 0.07, 0.13, 0.5), Color(0, 0, 0, 0), 6, 0)
	s.content_margin_left = 6
	s.content_margin_right = 6
	return s


static func _grab_box(alpha: float) -> StyleBoxFlat:
	var s := _flat(Color(CYAN, alpha), Color(0, 0, 0, 0), 6, 0)
	s.content_margin_left = 6
	s.content_margin_right = 6
	return s


## Subtle readability strip used behind full-bleed backgrounds (replaces per-scene gradient scrims).
static func scrim_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.62, 1.0])
	g.colors = PackedColorArray([Color(0.01, 0.03, 0.08, 0.55), Color(0.01, 0.03, 0.08, 0.20), Color(0.01, 0.03, 0.08, 0.30), Color(0.01, 0.03, 0.08, 0.62)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 16
	tex.height = 256
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	return tex


## Level/tutorial card. status: "locked" | "open" | "done"; state: normal|hover|pressed|disabled
static func card_box(status: String, state: String = "normal") -> StyleBoxFlat:
	var fill := GLASS_LIGHT
	var edge := CYAN
	var glow := 8
	var border_w := BORDER
	match status:
		"locked":
			fill = Color(0.035, 0.055, 0.095, 0.82)
			edge = Color(0.26, 0.34, 0.44, 0.75)
			glow = 0
		"done":
			fill = Color(0.04, 0.20, 0.22, 0.95)
			edge = SUCCESS
			border_w = 3
	var s := _flat(fill, edge, 20, border_w, Color(edge, 0.22), glow)
	if state == "hover":
		s.bg_color = fill.lightened(0.10)
	elif state == "pressed":
		s.bg_color = fill.darkened(0.25)
	return s


static func apply_card_styles(button: Button, status: String) -> void:
	button.flat = false
	for st in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(st, card_box(status, st))
	button.add_theme_stylebox_override("disabled", card_box(status, "normal"))


## Gameplay HUD strip: a quiet glass plate that frames controls without competing with the board.
static func hud_plate_box() -> StyleBoxFlat:
	return _flat(Color(0.02, 0.05, 0.11, 0.86), Color(CYAN_DIM, 0.75), 22, BORDER, Color(CYAN, 0.12), 10)


## Circular icon button (Settings / About on the main menu).
static func round_box(state: String) -> StyleBoxFlat:
	var s := button_box("primary", state)
	s.set_corner_radius_all(120)
	s.set_border_width_all(3)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s
