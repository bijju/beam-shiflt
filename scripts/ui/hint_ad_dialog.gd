class_name HintAdDialog
extends Control
## Disclosure shown BEFORE a rewarded Hint ad starts ("Watch a short ad to reveal a hint."). Purely
## presentational: it only emits `confirmed` / `cancelled`; game.gd owns the existing rewarded flow.
## Modal (the dim swallows every tap) and sits in the normal scene tree, so the InternetBlocker (layer 128)
## covers and pauses it; its handlers also refuse to act while the blocker is active.

signal confirmed
signal cancelled

## Copy defaults to the rewarded-Hint disclosure; the repeated-Reset disclosure and the
## "ad not available" notice (info_only: a single OK button that emits `cancelled`) reuse it.
var title_text := "GET A HINT?"
var body_text := "Watch a short ad to reveal a hint."
var info_only := false
const ACTION_ART := preload("res://assets/ui/dialogs/bs_btn_dialog_action.png")
## Alpha-visible bounds of the PNG (normalized); the transparent glow padding is not part of the button.
const ACTION_RECT := Rect2(0.0170, 0.1561, 0.9650, 0.6713)
const ACTION_WIDTH := 390.0
const ACTION_ASPECT := 4.3
var _done := false
var _cancel_button: SettingsArtButton
var _watch_button: SettingsArtButton


func _ready() -> void:
	name = "HintAdDialog"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0.02, 0.08, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"DialogPanel"
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)
	var body := Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 38)
	box.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	_cancel_button = _make_button("OK" if info_only else "CANCEL", false, _cancel)
	_cancel_button.name = "CancelButton"
	row.add_child(_cancel_button)
	BeamButtonGlow.attach(_cancel_button)
	if info_only:
		_cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return
	_watch_button = _make_button("WATCH AD", true, _confirm)
	_watch_button.name = "WatchAdButton"
	row.add_child(_watch_button)
	BeamButtonGlow.attach(_watch_button)


## Art-backed action button: one texture for every action, WATCH AD (primary) at full brightness, CANCEL/OK dimmer.
## The button keeps a touch-sized height even though the visible art is shorter, so taps never need to hit the art.
func _make_button(text: String, primary: bool, handler: Callable) -> SettingsArtButton:
	var b := SettingsArtButton.new()
	b.art = ACTION_ART
	b.content_rect = ACTION_RECT
	b.display_width = ACTION_WIDTH * (1.0 if primary or info_only else 0.9)
	b.label_text = text
	b.label_font_size = BeamUI.dialog_button_font_size(get_viewport().get_visible_rect().size.x, ACTION_WIDTH / ACTION_ASPECT)
	b.base_modulate = Color.WHITE if primary or info_only else Color(0.72, 0.8, 0.9, 1.0)
	b.label_color = Color(0.92, 0.97, 1.0, 1.0) if primary or info_only else Color(0.8, 0.87, 0.95, 1.0)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = 1.15 if primary else 1.0
	b.pressed.connect(handler)
	b.min_height = UIConstants.MIN_TOUCH_TARGET
	return b


func _confirm() -> void:
	if _done or InternetManager.is_blocking():
		return
	_done = true
	AudioManager.play_ui_button_press()
	confirmed.emit()


func _cancel() -> void:
	if _done or InternetManager.is_blocking():
		return
	_done = true
	AudioManager.play_ui_button_press()
	cancelled.emit()


## Android Back while the dialog is open = CANCEL.
func request_cancel() -> void:
	_cancel()
