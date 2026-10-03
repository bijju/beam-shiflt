extends Control
## In-game Privacy Policy, rendered natively from PrivacyPolicyText (never opens a browser).
## The Back button lives in the fixed header, outside the ScrollContainer, so it stays visible
## and can never be triggered by a scroll drag. Every node inside the scroll is mouse-transparent
## so touch-drag and the mouse wheel always reach the ScrollContainer.

const FONT_BODY := 34
const FONT_SUB := 36
const FONT_META := 32
const COLOR_HEADING := BeamUI.CYAN
const COLOR_BODY := BeamUI.TEXT
const COLOR_DIM := BeamUI.TEXT_DIM

@onready var _back_button: Button = %BackButton
@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %Content


func _ready() -> void:
	_back_button.pressed.connect(AudioManager.play_ui_back)
	_back_button.pressed.connect(GameManager.go_to_settings)
	BeamButtonGlow.attach(_back_button)
	_content.add_child(_build_meta())
	for section: Dictionary in PrivacyPolicyText.SECTIONS:
		_content.add_child(_build_section(section))


func _build_meta() -> Control:
	var panel := _panel()
	var box := panel.get_child(0) as VBoxContainer
	box.add_child(_label(PrivacyPolicyText.GAME, 44, COLOR_HEADING))
	box.add_child(_label("Effective date: %s" % PrivacyPolicyText.EFFECTIVE_DATE, FONT_META, COLOR_DIM))
	box.add_child(_label("Last updated: %s" % PrivacyPolicyText.LAST_UPDATED, FONT_META, COLOR_DIM))
	box.add_child(_label("Publisher: %s" % PrivacyPolicyText.PUBLISHER, FONT_META, COLOR_BODY))
	box.add_child(_label("Developer: %s" % PrivacyPolicyText.DEVELOPER, FONT_META, COLOR_BODY))
	box.add_child(_label("Email: %s" % PrivacyPolicyText.EMAIL, FONT_META, COLOR_BODY))
	return panel


func _build_section(section: Dictionary) -> Control:
	var panel := _panel()
	var box := panel.get_child(0) as VBoxContainer
	box.add_child(_label(section["heading"], 42, COLOR_HEADING))
	var rule := ColorRect.new()
	rule.color = Color(0.28, 0.72, 0.95, 0.45)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	for block: Variant in section["blocks"]:
		if block is String:
			box.add_child(_label(block, FONT_BODY, COLOR_BODY))
		elif block is Dictionary:
			box.add_child(_label(block["sub"], FONT_SUB, COLOR_HEADING))
		elif block is Array:
			for item: String in block:
				box.add_child(_bullet(item))
	return panel


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	return panel


func _bullet(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := _label("•", FONT_BODY, COLOR_HEADING)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(dot)
	var body := _label(text, FONT_BODY, COLOR_BODY)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)
	return row


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if InternetManager.is_blocking():
			return # no navigation under the InternetBlocker
		GameManager.go_to_settings()
