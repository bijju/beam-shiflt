extends Control

@onready var _play_button: Button = %PlayButton
@onready var _continue_button: Button = %ContinueButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _qa_spacer: Control = %QASpacer
## QA/dev-only - see DECISIONS.md D85. Not part of the normal player-
## facing flow; visibility is gated in _ready() below.
@onready var _qa_level_select_button: Button = %QALevelSelectButton


func _ready() -> void:
	_play_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(func() -> void: GameManager.continue_game())
	_tutorial_button.pressed.connect(func() -> void: GameManager.go_to_tutorial_select())
	_settings_button.pressed.connect(func() -> void: GameManager.go_to_settings())
	_quit_button.pressed.connect(func() -> void: GameManager.quit_game())
	_qa_level_select_button.pressed.connect(func() -> void: GameManager.go_to_level_select())

	# Centralized UI SFX (see AUDIO_SYSTEM.md): one extra signal connection
	# per button, calling AudioManager directly - never a second navigation
	# path, never a duplicated AudioStreamPlayer.
	for button in [_play_button, _continue_button, _tutorial_button, _settings_button, _quit_button, _qa_level_select_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)

	# Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md):
	# PLAY/CONTINUE now target procedural progression, not the legacy
	# Campaign - see GameManager.play_game()/continue_game(). Deliberately
	# NOT derived from unlock/completion progress - see SaveManager.
	# has_resumable_procedural_game()'s own doc comment for why.
	_continue_button.disabled = not SaveManager.has_resumable_procedural_game()
	_setup_cloud_chooser()

	# Godot's quit() call is intended for desktop; on mobile the OS back
	# gesture/button is the platform-expected way to leave the app.
	_quit_button.visible = not OS.has_feature("mobile")

	# Level Select is QA/dev-only now (Phase 2) - reuses the same "QA
	# build" signal UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING already gates
	# campaign-level selectability with, rather than inventing a second
	# QA flag. MUST read false (hiding this button) before any production
	# release, same as that flag's own existing requirement.
	_qa_level_select_button.visible = LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING
	_qa_spacer.visible = BuildConfig.QA_TOOLS

	# Difficulty System Phase 2A (D94): DEV-ONLY "V3 TEST" entry for the six
	# Generator V3 prototypes, built in code so the shared scene stays
	# untouched and removal is one flag flip (LevelManager.
	# SHOW_V3_PROTOTYPE_QA = false). Same styling as the QA Level Select
	# button; never touches save data (see GameManager.start_v3_prototype()).
	if LevelManager.SHOW_V3_PROTOTYPE_QA:
		var v3_button := Button.new()
		v3_button.text = "V3 TEST"
		v3_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v3_button.custom_minimum_size = Vector2(320, 72)
		v3_button.add_theme_font_size_override("font_size", 18)
		_qa_level_select_button.get_parent().add_child(v3_button)
		v3_button.pressed.connect(func() -> void: GameManager.start_v3_prototype(1))
		v3_button.pressed.connect(AudioManager.play_ui_button_press)

	# Fusion Node Phase 1 (D99): DEV-ONLY "FUSION TEST" (LevelManager.SHOW_FUSION_TEST_QA), same
	# containment as V3 TEST - never touches save data (see GameManager.start_fusion_test()).
	if LevelManager.SHOW_FUSION_TEST_QA:
		var fusion_button := Button.new()
		fusion_button.text = "FUSION TEST"
		fusion_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		fusion_button.custom_minimum_size = Vector2(320, 72)
		fusion_button.add_theme_font_size_override("font_size", 18)
		_qa_level_select_button.get_parent().add_child(fusion_button)
		fusion_button.pressed.connect(func() -> void: GameManager.start_fusion_test(1))
		fusion_button.pressed.connect(AudioManager.play_ui_button_press)

	# Splitter Selector Phase S1: DEV-ONLY "SELECTOR TEST" (LevelManager.SHOW_SELECTOR_TEST_QA), same containment.
	if LevelManager.SHOW_SELECTOR_TEST_QA:
		var selector_button := Button.new()
		selector_button.text = "SELECTOR TEST"
		selector_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		selector_button.custom_minimum_size = Vector2(320, 72)
		selector_button.add_theme_font_size_override("font_size", 18)
		_qa_level_select_button.get_parent().add_child(selector_button)
		selector_button.pressed.connect(func() -> void: GameManager.start_selector_test(1))
		selector_button.pressed.connect(AudioManager.play_ui_button_press)
	# Selector Phase S3 (D110): DEV-ONLY "V5 TEST" (LevelManager.SHOW_V5_TEST_QA) - a curated sample of generator-V5 levels.
	if LevelManager.SHOW_V5_TEST_QA:
		var v5_button := Button.new()
		v5_button.text = "V5 TEST"
		v5_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v5_button.custom_minimum_size = Vector2(320, 72)
		v5_button.add_theme_font_size_override("font_size", 18)
		_qa_level_select_button.get_parent().add_child(v5_button)
		v5_button.pressed.connect(func() -> void: GameManager.start_v5_test(1))
		v5_button.pressed.connect(AudioManager.play_ui_button_press)


	_maybe_show_fusion_tutorial_nudge()


## Phase 4 (D102): a one-time, non-blocking "NEW TUTORIAL: FUSION" note the first time the Fusion tutorial pack is
## available (LevelManager.should_show_fusion_tutorial_nudge()). Built from the shared theme (no new art), never
## blocks Play, never locks anything, and is marked seen the moment it is shown so it cannot repeat.
func _maybe_show_fusion_tutorial_nudge() -> void:
	if not LevelManager.should_show_fusion_tutorial_nudge():
		return
	SaveManager.fusion_tutorial_nudge_seen = true
	SaveManager.save_game()
	var panel := PanelContainer.new()
	panel.name = "FusionTutorialNudge"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 40.0
	panel.offset_right = -40.0
	panel.offset_top = 40.0
	panel.grow_vertical = Control.GROW_DIRECTION_END
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var label := Label.new()
	label.text = "NEW TUTORIAL: FUSION"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	row.add_child(label)
	var view := Button.new()
	view.text = "VIEW"
	view.custom_minimum_size = Vector2(150, 72)
	view.pressed.connect(AudioManager.play_ui_button_press)
	view.pressed.connect(func() -> void: GameManager.go_to_tutorial_select())
	row.add_child(view)
	var dismiss := Button.new()
	dismiss.text = "X"
	dismiss.custom_minimum_size = Vector2(72, 72)
	dismiss.pressed.connect(AudioManager.play_ui_button_press)
	dismiss.pressed.connect(panel.queue_free)
	row.add_child(dismiss)
	add_child(panel)



## NEW GAME (D107). Fresh/settings-only save: starts Level 1 immediately, no popup. Meaningful main progress: asks first;
## nothing is erased until START NEW GAME is confirmed. _busy blocks double taps / duplicate callbacks.
var _busy := false
# Matches the button art's ~3.13:1 region aspect (1705x545); full-width 9-slice stretched it to ~6.3:1.
const CONFIRM_BUTTON_SIZE := Vector2(480, 154)
var _confirm_layer: Control = null


func _on_new_game_pressed() -> void:
	if _busy:
		return
	if not SaveManager.has_meaningful_main_progress():
		_start_new_game()
		return
	_show_new_game_confirmation()


func _start_new_game() -> void:
	_busy = true
	if not GameManager.start_new_game():
		_busy = false # reset could not be saved: state restored, stay on the menu


func _show_new_game_confirmation() -> void:
	if _confirm_layer != null:
		return
	_confirm_layer = Control.new()
	_confirm_layer.name = "NewGameConfirm"
	_confirm_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP # taps outside the panel are swallowed, never a confirm
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0.02, 0.08, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)
	var title := Label.new()
	title.text = "START NEW GAME?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)
	var body := Label.new()
	body.text = "Your current game progress will be reset and you'll start again from Level 1.
This cannot be undone."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 30)
	box.add_child(body)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = "CANCEL"
	cancel.custom_minimum_size = CONFIRM_BUTTON_SIZE
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel.add_theme_font_size_override("font_size", 32)
	cancel.pressed.connect(AudioManager.play_ui_button_press)
	cancel.pressed.connect(_close_new_game_confirmation)
	row.add_child(cancel)
	var confirm := Button.new()
	confirm.name = "ConfirmNewGame"
	confirm.text = "START NEW GAME"
	confirm.custom_minimum_size = CONFIRM_BUTTON_SIZE
	confirm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm.add_theme_font_size_override("font_size", 26)
	confirm.pressed.connect(AudioManager.play_ui_button_press)
	confirm.pressed.connect(func() -> void:
		if _busy:
			return
		confirm.disabled = true
		_start_new_game()
		if not _busy and _confirm_layer != null:
			confirm.disabled = false)
	row.add_child(confirm)
	add_child(_confirm_layer)


func _close_new_game_confirmation() -> void:
	if _confirm_layer != null:
		_confirm_layer.queue_free()
		_confirm_layer = null


## Cloud save chooser (STORE_RELEASE.md): the device and cloud copies differ by more than
## CloudSave.CHOOSER_THRESHOLD of play time, so neither is picked silently. Built in code
## like the NEW GAME confirmation. Back/closing leaves the question pending for next time.
var _cloud_layer: Control = null


func _setup_cloud_chooser() -> void:
	CloudSave.chooser_needed.connect(_show_cloud_chooser)
	CloudSave.reconcile_held()
	if CloudSave.has_pending_choice():
		_show_cloud_chooser()


func _show_cloud_chooser() -> void:
	if _cloud_layer != null or not CloudSave.has_pending_choice():
		return
	_close_new_game_confirmation()
	_cloud_layer = Control.new()
	_cloud_layer.name = "CloudChooser"
	_cloud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cloud_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0.02, 0.08, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_cloud_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cloud_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)
	var title := Label.new()
	title.text = "WHICH PROGRESS?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)
	var body := Label.new()
	body.text = "Your %s save and this device have different progress. The one you don't pick will be replaced." % CloudSave.service_name()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 30)
	box.add_child(body)
	var cloud_button := Button.new()
	cloud_button.text = "CLOUD: %s" % _progress_text(CloudSave.pending_cloud)
	var device_button := Button.new()
	device_button.text = "THIS DEVICE: %s" % _progress_text(CloudSave.pending_local)
	for button: Button in [cloud_button, device_button]:
		button.custom_minimum_size = CONFIRM_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(AudioManager.play_ui_button_press)
		box.add_child(button)
	cloud_button.pressed.connect(_on_take_cloud)
	device_button.pressed.connect(_on_keep_local)
	add_child(_cloud_layer)


func _progress_text(profile: Dictionary) -> String:
	var minutes := int(CloudSave.play_time_of(profile) / 60.0)
	return "LEVEL %d, %dh %02dm" % [CloudSave.level_of(profile), minutes / 60, minutes % 60]


func _close_cloud_chooser() -> void:
	if _cloud_layer != null:
		_cloud_layer.queue_free()
		_cloud_layer = null


func _on_take_cloud() -> void:
	_close_cloud_chooser()
	CloudSave.take_cloud() # reloads this menu with the adopted profile


func _on_keep_local() -> void:
	_close_cloud_chooser()
	CloudSave.keep_local()

## project.godot sets quit_on_go_back=false project-wide (see game.gd,
## which needs to intercept this to open Pause instead of exiting) - so
## Main Menu must replicate the previous default behavior itself: the
## system Back gesture/button here should still quit, exactly like it did
## before that setting existed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _cloud_layer != null:
			_close_cloud_chooser() # the question stays pending for the next menu build
			return
		if _confirm_layer != null:
			_close_new_game_confirmation() # Back on the popup = CANCEL
			return
		GameManager.quit_game()
