extends Control

## Main Menu Mobile Layout Correction (2026-09-28, real-device follow-up to the
## Main Menu Redesign pass): the logo/preview/button stack is sized here, in
## code, instead of fixed .tscn pixel values, so it adapts to the real safe
## area on any portrait aspect ratio instead of the single phone this pass
## was tuned against. See _layout_hero_elements() below.
##
## bs_logo_main_menu_portrait.png is 1215x1295 but the painted wordmark only
## occupies roughly x:6-1201 / y:211-1007 of that canvas (measured via an
## alpha-channel bounding-box scan) - the rest is baked-in transparent
## padding. Scaling the FULL texture to fit a box (the pre-existing
## behavior) scales that padding too, which is why the logo rendered as a
## small glyph inside a much bigger empty frame on a real device. LOGO_CROP
## (SafeMargin/Root/Logo's AtlasTexture region in main_menu.tscn) crops to
## that painted region - reusing the same source asset, never a new logo -
## so the aspect ratio this script sizes against matches what's actually
## visible.
const LOGO_CROP_SIZE := Vector2(1215.0, 810.0)
const LOGO_ASPECT := LOGO_CROP_SIZE.x / LOGO_CROP_SIZE.y

## The preview shows Level 3 ("Signal Path", 5x6 board - see menu_gameplay_preview.gd) inside a frame as wide as
## the primary buttons; the board keeps its own aspect and is centred inside the frame.

## Soft target fractions of the safe-area width (see CLAUDE.md's Responsive
## rules / UIConstants.BASELINE_MARGIN) - the logo is a hard 70%, the
## preview is a soft 84% that yields to whatever vertical budget remains
## after the logo and button stack, since Level 3's tall board means a
## preview sized purely by width would frequently blow the screen height.
const LOGO_WIDTH_FRACTION := 0.96
const LOGO_HEIGHT_FRACTION := 0.27
const MENU_SIDE_MARGIN := 40.0
## Nominal margin the logo/button sizes are derived from (kept so those sizes never change with the lift).
const MENU_VERTICAL_MARGIN := 32.0
const MAIN_BUTTON_WIDTH_FRACTION := 0.84
const PREVIEW_WIDTH_FRACTION := 0.86

## Matches Root's own theme_override_constants/separation in main_menu.tscn
## (the gap the removed flex Spacer used to paper over) and a small reserve
## for the breathing room below ButtonGroup, above the corner Settings icon.
## The logo sits this many px higher than the nominal margin (SafeMargin's top_margin_extra, main_menu.tscn); the
## preview floor grows by the same amount so the lift gives the preview room instead of moving the buttons.
const LOGO_LIFT := 16.0
const HERO_GAP := 20.0
const BOTTOM_BREATHING := 28.0

@onready var _safe_margin: MarginContainer = $SafeMargin
@onready var _logo: TextureRect = %Logo
@onready var _preview_frame: Control = %PreviewFrame
@onready var _button_group: VBoxContainer = %ButtonGroup
@onready var _play_button: MenuArtButton = %PlayButton
@onready var _continue_button: MenuArtButton = %ContinueButton
@onready var _tutorial_button: MenuArtButton = %TutorialButton
## Main Menu Redesign pass (2026-09-28): a compact icon button
## (bs_ui_icon_settings.png), not a full-width text Button - see
## scenes/ui/main_menu.tscn's CornerLayer/SettingsButton. Typed as
## BaseButton (the common ancestor of Button/TextureButton) so this
## reference works regardless of which control type the scene uses.
@onready var _settings_button: MenuArtButton = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _about_button: MenuArtButton = %AboutButton
@onready var _footer_row: HBoxContainer = %FooterRow
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
	_about_button.pressed.connect(func() -> void: GameManager.go_to_about())
	_qa_level_select_button.pressed.connect(func() -> void: GameManager.go_to_level_select())

	# Centralized UI SFX (see AUDIO_SYSTEM.md): one extra signal connection
	# per button, calling AudioManager directly - never a second navigation
	# path, never a duplicated AudioStreamPlayer.
	for button in [_play_button, _continue_button, _tutorial_button, _settings_button, _about_button, _quit_button, _qa_level_select_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)

	# Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md):
	# PLAY/CONTINUE now target procedural progression, not the legacy
	# Campaign - see GameManager.play_game()/continue_game(). Deliberately
	# NOT derived from unlock/completion progress - see SaveManager.
	# has_resumable_procedural_game()'s own doc comment for why.
	_continue_button.disabled = not SaveManager.has_resumable_procedural_game()
	for b in [_continue_button, _play_button, _tutorial_button, _about_button, _settings_button]:
		BeamButtonGlow.attach(b)

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

	_layout_hero_elements()
	get_viewport().size_changed.connect(_layout_hero_elements)


## Sizes Logo and PreviewFrame (see the constants above) to fill the real
## available vertical space between the safe-area edges and ButtonGroup's
## own (visibility-dependent - QA buttons above may or may not exist)
## measured height, instead of the fixed pixel sizes + expanding Spacer this
## replaced. Logo gets a hard width target; PreviewFrame's width target
## yields to whatever height remains so the tall Level 3 board never forces
## the button group off-screen or reopens the old giant empty gap.
func _layout_hero_elements() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_w := maxf(viewport_size.x - MENU_SIDE_MARGIN * 2.0, 1.0)
	var safe_h := maxf(viewport_size.y - MENU_VERTICAL_MARGIN * 2.0, 1.0)
	var sep := float(_button_group.get_theme_constant("separation"))
	var root_sep := float(_button_group.get_parent().get_theme_constant("separation"))

	# Three equal primary buttons (the QA/desktop extras below them are measured via the group's real height).
	# The art is never stretched: one shared box (identical for all three buttons) takes the narrowest of the
	# PNGs' own aspects, so every image fits inside it by width. Width is a fraction of the safe width.
	var art_buttons: Array[MenuArtButton] = [_continue_button, _play_button, _tutorial_button]
	var box_aspect := 1000.0
	for ab in art_buttons:
		box_aspect = minf(box_aspect, ab.art_aspect())
	var button_w := safe_w * MAIN_BUTTON_WIDTH_FRACTION
	var button_h := button_w / box_aspect
	var frame_w := safe_w * PREVIEW_WIDTH_FRACTION
	for b: MenuArtButton in art_buttons:
		b.custom_minimum_size = Vector2(button_w, button_h)
	# Footer row sits directly under TUTORIALS: two equal art buttons split the primary width around a centre gap.
	var footer_gap := float(_footer_row.get_theme_constant("separation"))
	var footer_w := (button_w - footer_gap) * 0.5
	var footer_h := footer_w / minf(_about_button.art_aspect(), _settings_button.art_aspect())
	_about_button.custom_minimum_size = Vector2(footer_w, footer_h)
	_settings_button.custom_minimum_size = Vector2(footer_w, footer_h)
	var group_h := _button_group.get_combined_minimum_size().y

	var logo_h := minf(safe_w * LOGO_WIDTH_FRACTION / LOGO_ASPECT, safe_h * LOGO_HEIGHT_FRACTION)
	var logo_w := logo_h * LOGO_ASPECT
	_logo.custom_minimum_size = Vector2(logo_w, logo_h)

	var gaps := root_sep * 2.0 + sep
	# Preview height is the flexible element: it gets whatever the REAL safe margins (incl. Android insets) leave,
	# so the stack can never overflow the bottom edge. All other sizes derive from the nominal safe_h above.
	var avail_h := viewport_size.y - float(_safe_margin.get_theme_constant("margin_top") + _safe_margin.get_theme_constant("margin_bottom"))
	var preview_h := maxf(avail_h - logo_h - group_h - gaps, safe_h * 0.2 + LOGO_LIFT)
	# The frame is exactly as wide as the primary buttons so both form one aligned column. The 5:6 board is never
	# stretched: PreviewViewportContainer resizes its viewport to the frame and GridManager fits square cells,
	# centring the board (side bands when the frame is wider than 5:6, top/bottom bands when taller).
	_preview_frame.custom_minimum_size = Vector2(frame_w, preview_h)


func _maybe_show_fusion_tutorial_nudge() -> void:
	if not LevelManager.should_show_fusion_tutorial_nudge():
		return
	SaveManager.fusion_tutorial_nudge_seen = true
	SaveManager.save_game()
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
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
	label.add_theme_font_size_override("font_size", 32)
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
# Art buttons (label baked in); content rects are the alpha-visible bounds, display width < the 900 px panel.
const CANCEL_ART := preload("res://assets/ui/dialogs/new_game/bs_btn_new_game_cancel.png")
const CONFIRM_ART := preload("res://assets/ui/dialogs/new_game/bs_btn_new_game_confirm.png")
const CANCEL_RECT := Rect2(0.0083, 0.1285, 0.9843, 0.7417)
const CONFIRM_RECT := Rect2(0.0078, 0.1257, 0.9848, 0.7459)
const CONFIRM_BUTTON_WIDTH := 780.0
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
	panel.theme_type_variation = &"DialogPanel"
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)
	var title := Label.new()
	title.text = "START NEW GAME?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)
	var body := Label.new()
	body.text = "Starting a new game will erase your current progress and begin again from Level 1.

Are you sure you want to continue?"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 34)
	box.add_child(body)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	var cancel := SettingsArtButton.new()
	cancel.name = "CancelNewGame"
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel.art = CANCEL_ART
	cancel.content_rect = CANCEL_RECT
	cancel.display_width = CONFIRM_BUTTON_WIDTH
	cancel.pressed.connect(AudioManager.play_ui_button_press)
	cancel.pressed.connect(_close_new_game_confirmation)
	row.add_child(cancel)
	BeamButtonGlow.attach(cancel)
	var confirm := SettingsArtButton.new()
	confirm.name = "ConfirmNewGame"
	confirm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm.art = CONFIRM_ART
	confirm.content_rect = CONFIRM_RECT
	confirm.display_width = CONFIRM_BUTTON_WIDTH
	confirm.pressed.connect(AudioManager.play_ui_button_press)
	confirm.pressed.connect(func() -> void:
		if _busy:
			return
		confirm.disabled = true
		_start_new_game()
		if not _busy and _confirm_layer != null:
			confirm.disabled = false)
	row.add_child(confirm)
	BeamButtonGlow.attach(confirm, BeamButtonGlow.RED_ORANGE)
	add_child(_confirm_layer)


func _close_new_game_confirmation() -> void:
	if _confirm_layer != null:
		_confirm_layer.queue_free()
		_confirm_layer = null


## project.godot sets quit_on_go_back=false project-wide (see game.gd,
## which needs to intercept this to open Pause instead of exiting) - so
## Main Menu must replicate the previous default behavior itself: the
## system Back gesture/button here should still quit, exactly like it did
## before that setting existed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _confirm_layer != null:
			if not InternetManager.is_blocking():
				_close_new_game_confirmation() # Back on the popup = CANCEL
			return
		GameManager.quit_game()
