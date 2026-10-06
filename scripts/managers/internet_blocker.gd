extends CanvasLayer
## Autoload: InternetBlocker - the ONE global "internet required" gate. Sits above every
## scene (layer 128), pauses the SceneTree while InternetManager.is_blocking() and
## restores the previous pause state when connectivity is confirmed, so the current
## scene/level is never reloaded or lost. Scenes carry no offline code of their own.
## Before the first probe finishes the tree is held paused with NO panel (a connected
## launch never flashes it); the panel shows once the connection is confirmed lost.

const LAYER_ABOVE_ALL := 128

var _blocking := false
var _prior_paused := false

var _root: Control
var _title: Label
var _status: Label
var _retry_button: Button


func _ready() -> void:
	layer = LAYER_ABOVE_ALL
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	InternetManager.internet_lost.connect(_refresh)
	InternetManager.internet_restored.connect(_refresh)
	InternetManager.check_started.connect(_refresh_status)
	InternetManager.check_completed.connect(_on_check_completed)
	_refresh()


func is_panel_visible() -> bool:
	return _root.visible


func is_blocking() -> bool:
	return _blocking


func _process(_delta: float) -> void:
	# A screen's own Back/Pause handling must never unpause play underneath the gate.
	if _blocking and not get_tree().paused:
		get_tree().paused = true


func _refresh() -> void:
	var want := InternetManager.is_blocking()
	if want and not _blocking:
		_blocking = true
		_prior_paused = get_tree().paused
		get_tree().paused = true
	elif not want and _blocking:
		_blocking = false
		get_tree().paused = _prior_paused
	var show_panel := _blocking and not InternetManager.is_online
	if show_panel and not _root.visible:
		_title.text = "INTERNET CONNECTION REQUIRED" if not InternetManager.gate_passed else "INTERNET CONNECTION LOST"
		_root.show()
		_retry_button.grab_focus()
	elif not show_panel:
		_root.hide()
	_refresh_status()


func _on_check_completed(_online: bool) -> void:
	_refresh_status()


func _refresh_status() -> void:
	if _status == null:
		return
	if InternetManager.check_in_progress and _root.visible:
		_status.text = "Checking connection..."
	else:
		_status.text = "Check Wi-Fi or mobile data and try again."
	_retry_button.disabled = InternetManager.check_in_progress and _root.visible


func _on_retry_pressed() -> void:
	AudioManager.play_ui_button_press()
	InternetManager.retry()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.hide()
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(BeamUI.BLUE_DEEP, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, int(BeamUI.SCREEN_MARGIN))
	_root.add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"DialogPanel"
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)

	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 48)
	panel.add_child(inner)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	inner.add_child(box)

	_title = Label.new()
	_title.theme_type_variation = &"TitleLabel"
	_title.add_theme_font_size_override("font_size", 56)
	_title.add_theme_color_override("font_color", BeamUI.CYAN_BRIGHT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.text = "INTERNET CONNECTION REQUIRED"
	box.add_child(_title)

	var body := Label.new()
	body.text = "BeamShift requires an active internet connection to play."
	body.add_theme_font_size_override("font_size", BeamUI.FONT_BODY + 4)
	body.add_theme_color_override("font_color", BeamUI.TEXT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", BeamUI.FONT_SMALL)
	_status.add_theme_color_override("font_color", BeamUI.TEXT_DIM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)

	_retry_button = Button.new()
	_retry_button.text = "RETRY"
	_retry_button.custom_minimum_size = Vector2(0, BeamUI.BUTTON_HEIGHT)
	_retry_button.pressed.connect(_on_retry_pressed)
	box.add_child(_retry_button)
	var buttons: Array = [_retry_button]

	BeamUI.bind_dialog_button_fonts(_root, buttons)
