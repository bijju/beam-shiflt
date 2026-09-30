extends Control
## ABOUT US / credits. Panels are built from CREDITS below as plain Labels (no
## text is baked into any image) so names/roles stay editable in one place.
## Style mirrors account_screen.tscn's flat blue/cyan panel: no dedicated
## panel art exists and every existing panel texture paints its own title.

const CREDITS := [
	{
		"heading": "STUDIO",
		"groups": [
			{"role": "Publisher", "names": ["Maclepro Inc"]},
			{"role": "Production Studio", "names": ["4Sagez Studios Pvt. Ltd."]},
		],
	},
	{
		"heading": "DESIGN & CODE",
		"groups": [
			{"role": "Game Direction", "names": ["Praneeth B", "Abhilash D"]},
			{"role": "Gameplay Systems", "names": ["Praneeth B", "Abhilash D"]},
		],
	},
]

const COLOR_HEADING := Color(0.36, 0.85, 1.0, 1)
const COLOR_ROLE := Color(0.62, 0.78, 0.9, 1)
const COLOR_NAME := Color(0.94, 0.97, 1, 1)
const PANEL_PADDING := 44

@onready var _back_button: Button = %BackButton
@onready var _content: VBoxContainer = %Content


func _ready() -> void:
	_back_button.pressed.connect(AudioManager.play_ui_back)
	_back_button.pressed.connect(GameManager.go_to_main_menu)
	for section: Dictionary in CREDITS:
		_content.add_child(_build_panel(section["heading"], _credit_groups(section["groups"])))
	_content.add_child(_build_panel("BUILT WITH", _credit_groups([
		{"role": "Engine", "names": [_engine_text()]},
	])))
	var version := Label.new()
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "1.0.0")
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 28)
	version.add_theme_color_override("font_color", COLOR_ROLE)
	version.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.1, 0.9))
	version.add_theme_constant_override("outline_size", 6)
	_content.add_child(version)


func _engine_text() -> String:
	var info := Engine.get_version_info()
	return "Godot Engine %d.%d.%d-%s" % [info.major, info.minor, info.patch, info.status]


func _credit_groups(groups: Array) -> Array[Control]:
	var out: Array[Control] = []
	for group: Dictionary in groups:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		box.add_child(_label(str(group["role"]).to_upper(), 26, COLOR_ROLE))
		for n in group["names"]:
			box.add_child(_label(n, 36, COLOR_NAME))
		out.append(box)
	return out


func _build_panel(heading: String, groups: Array[Control]) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.125, 0.92)
	style.set_border_width_all(3)
	style.border_color = Color(0.28, 0.72, 0.95, 0.85)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.1, 0.55, 0.9, 0.35)
	style.shadow_size = 10
	style.set_content_margin_all(PANEL_PADDING)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)
	box.add_child(_label(heading, 44, COLOR_HEADING))
	var rule := ColorRect.new()
	rule.color = Color(0.28, 0.72, 0.95, 0.45)
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)
	for g in groups:
		box.add_child(g)
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.go_to_main_menu()
