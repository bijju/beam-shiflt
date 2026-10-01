class_name ConnectivityScreenBuilder
extends RefCounted
## Shared layout for BeamShift's two internet-required screens - the
## startup gate's full-scene UI (internet_gate.gd) and InternetManager's
## global runtime "connection lost" overlay - kept in ONE place so the
## dark-panel/title/body/RETRY-EXIT layout can never drift apart between
## the two call sites (Runtime Internet Loss Blocking pass). This builder
## only constructs nodes and returns references; callers own all
## behavior (signal wiring, visibility, pause).

class Screen:
	var root: Control
	var loading_row: Control
	var panel: Control
	var retry_button: Button
	var exit_button: Button


## background_color.a <= 0 draws no extra background layer - used by the
## runtime overlay, which sits as a dim scrim above already-rendered
## gameplay; the startup gate instead passes an opaque backdrop since
## nothing else is on screen behind it yet.
static func build(parent: Node, title_text: String, body_text: String, background_color: Color, loading_text: String = "Checking connection...") -> Screen:
	var screen := Screen.new()

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(root)
	screen.root = root

	if background_color.a > 0.0:
		var background := ColorRect.new()
		background.color = background_color
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(background)

	var safe_margin := MarginContainer.new()
	safe_margin.set_script(load("res://scripts/ui/safe_area_margin.gd"))
	safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(safe_margin)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_child(center)

	screen.loading_row = CenterContainer.new()
	var loading_label := Label.new()
	loading_label.text = loading_text
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 30)
	screen.loading_row.add_child(loading_label)
	center.add_child(screen.loading_row)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	panel.visible = false
	center.add_child(panel)
	screen.panel = panel

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 50)
	box.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 34)
	box.add_child(body)

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)

	var retry_button := Button.new()
	retry_button.text = "RETRY"
	retry_button.custom_minimum_size = Vector2(480, 132)
	retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_button.add_theme_font_size_override("font_size", 40)
	row.add_child(retry_button)
	screen.retry_button = retry_button

	var exit_button := Button.new()
	exit_button.text = "EXIT"
	exit_button.theme_type_variation = &"DangerButton"
	exit_button.custom_minimum_size = Vector2(480, 112)
	exit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exit_button.theme_type_variation = &"SecondaryButton"
	exit_button.add_theme_font_size_override("font_size", 36)
	row.add_child(exit_button)
	screen.exit_button = exit_button

	return screen
