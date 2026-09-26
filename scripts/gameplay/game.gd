extends Control
## Root of scenes/gameplay/game.tscn. Orchestrates one play session: loads
## the level requested by GameManager, tracks the move counter, reacts to
## grid_manager's signals, and drives the level-complete popup.

@onready var _grid: GridManager = %PuzzleGrid
@onready var _background: TextureRect = %Background
@onready var _top_bar: AspectBar = $SafeMargin/Layout/TopBar
@onready var _top_bar_background: TextureRect = $SafeMargin/Layout/TopBar/Background
@onready var _bottom_bar: AspectBar = $SafeMargin/Layout/BottomBar
@onready var _bottom_bar_background: TextureRect = $SafeMargin/Layout/BottomBar/Background
@onready var _safe_margin: SafeAreaMargin = $SafeMargin
@onready var _level_label: Label = %LevelLabel
@onready var _moves_label: Label = %MovesLabel
@onready var _complete_popup = %LevelCompletePopup
@onready var _pause_menu = %PauseMenu
@onready var _back_button: Button = %BackButton
@onready var _reset_button: Button = %ResetButton
@onready var _pause_button: Button = %PauseButton
## Phase 3 (Procedural Generator V1) - QA-only, see LevelManager.
## SHOW_PROCEDURAL_QA_NEXT_BUTTON's own doc comment for exactly what this
## does and does not touch.
@onready var _qa_next_button: Button = %QANextButton
## Global Hint System (D97): the shared HUD Hint button + one HintManager per game scene.
@onready var _hint_button: Button = %HintButton
var _hint: HintManager
## Hint attention pulse: one reusable halo layer and at most one live Tween (killed before every replacement).
@onready var _hint_icon: TextureRect = %HintButton/HintIcon
var _hint_glow: TextureRect
var _hint_attention_tween: Tween
var _hint_pulse_active := false
var _hint_ad_open := false
## Phase 4 (D102): a real gameplay Hint was GRANTED and shown during this attempt (caps stars at 2).
## Reset by every level load, persisted with the resume state (see SaveManager.mark_hint_used), never set by
## tutorial guidance, a V3/Fusion QA session or a Hint request that was not granted.
var _hint_used_this_attempt := false
## AdMob Foundation (D98): true once a rewarded ad was OPENED on this level (suppresses that
## level's interstitial opportunity - no back-to-back full-screen ads). Reset on every load.
var _rewarded_this_level: bool = false
@onready var _tutorial_panel = %TutorialPanel
@onready var _tutorial_complete_popup = %TutorialCompletePopup
## TEMPORARY, QA-build-only debug overlay - see DECISIONS.md ("Guided
## tutorial system" runtime fix) Part 18. Tutorial-only, never shown
## during Campaign/editor-playtest. Remove once the Tutorial has been
## manually approved and this is no longer needed for diagnosis.
@onready var _qa_debug_label: Label = %QADebugLabel
## TEMPORARY, QA-build-only - the step _update_qa_debug_label() last
## rendered, so a tap-attempt refresh (which doesn't carry a step of its
## own) can redraw the label without needing the step passed in again.
var _qa_last_step: TutorialStepData = null

var current_level_id: int = 1
var moves_used: int = 0

## Guided-tutorial state - only ever touched when GameManager.is_tutorial_
## mode is true (set exclusively by GameManager.start_tutorial(), see
## DECISIONS.md "Guided tutorial system"). A fresh TutorialManager per
## play session, never shared with Campaign/editor-playtest logic below.
var _tutorial: TutorialManager = null

## Top HUD's left slot is narrow (see game.tscn's AspectBar-driven TopBar);
## a long display_name would otherwise word-wrap to an awkward 3rd line.
## Truncating here keeps the label to exactly two clean lines ("LEVEL N" /
## name) - this is presentational string formatting, not gameplay logic.
const MAX_LEVEL_NAME_CHARS := 13

## How long the solved board stays visible (final beam + target-activation
## VFX) before the Level Complete popup appears. Presentation-only - the
## solve calculation itself (grid_manager.gd's is_solved) is already true
## the instant this timer starts; further mirror/splitter clicks are
## already rejected by GridManager._on_orientable_tile_clicked()'s own
## `if is_solved: return` guard, so no separate input-lock is needed here.
const LEVEL_COMPLETE_DELAY := 0.8

## Guards against a duplicate/stale delayed popup - see _on_level_solved()
## and _load_current_level().
var _completion_pending: bool = false
## Generator version of the procedural puzzle currently loaded (set by _load_current_level;
## the completion branch must read the SAME version the puzzle was generated with).
var _procedural_generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION

## Era 2: fallbacks _apply_era_theme() restores whenever the loaded
## level's era resolves to Era 1 (EraTheme.for_era(1) leaves every field
## null on purpose - see era_theme.gd). These match game.tscn's own
## ext_resource defaults exactly, so Era 1 play is visually byte-for-byte
## unchanged whether or not this scene instance has shown Era 2 content
## before (Reset/Next Level/Next Tutorial reuse the same scene instance,
## they don't reload game.tscn - see GameManager).
const DEFAULT_GAMEPLAY_BACKGROUND := preload("res://assets/backgrounds/gameplay/bs_bg_gameplay.png")
const DEFAULT_HUD_TOP := preload("res://assets/ui/hud/bs_hud_top_portrait.png")
const DEFAULT_HUD_BOTTOM := preload("res://assets/ui/hud/bs_hud_bottom_portrait.png")
const DEFAULT_TOP_BAR_ASPECT := 2.834899
const DEFAULT_BOTTOM_BAR_ASPECT := 2.838710


func _ready() -> void:
	current_level_id = GameManager.current_level_id

	_grid.move_made.connect(_on_move_made)
	_grid.level_solved.connect(_on_level_solved)
	_complete_popup.next_level_pressed.connect(_on_next_level_pressed)
	_complete_popup.retry_pressed.connect(_on_retry_pressed)
	_complete_popup.level_select_pressed.connect(_on_level_select_pressed)
	_complete_popup.hide()

	# HUD edge spacing (D103): one centralized rule for every gameplay session (procedural, campaign, tutorial, QA).
	_top_bar.minimum_size_changed.connect(_update_hud_edge_overhang)
	_bottom_bar.minimum_size_changed.connect(_update_hud_edge_overhang)
	_update_hud_edge_overhang()
	_back_button.pressed.connect(_on_back_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_qa_next_button.pressed.connect(_on_qa_next_pressed)
	_hint = HintManager.new()
	_hint.bind(_grid)
	_hint.hint_unavailable.connect(_on_hint_unavailable)
	_hint.hint_shown.connect(_on_hint_granted)
	_hint_button.pressed.connect(_on_hint_pressed)
	_build_hint_glow()
	AdManager.rewarded_opened.connect(_on_ad_rewarded_opened)
	AdManager.rewarded_closed.connect(_on_ad_rewarded_closed)
	_qa_next_button.text = "+%d" % LevelManager.PROCEDURAL_QA_JUMP_AMOUNT

	# Centralized UI SFX (see AUDIO_SYSTEM.md) - Back is a literal Back
	# affordance (sfx_ui_back); Reset/Pause/QA Next are ordinary action
	# buttons (sfx_ui_button_press). QA Next deliberately gets only this
	# subtle press feedback, never a gameplay/completion sound - see
	# _on_qa_next_pressed()'s own doc comment.
	_back_button.pressed.connect(AudioManager.play_ui_back)
	_reset_button.pressed.connect(AudioManager.play_ui_button_press)
	_pause_button.pressed.connect(AudioManager.play_ui_button_press)
	_qa_next_button.pressed.connect(AudioManager.play_ui_button_press)

	_pause_menu.resume_pressed.connect(_on_pause_resume_pressed)
	_pause_menu.restart_pressed.connect(_on_pause_restart_pressed)
	_pause_menu.settings_pressed.connect(_on_pause_settings_pressed)
	_pause_menu.level_select_pressed.connect(_on_pause_level_select_pressed)
	_pause_menu.main_menu_pressed.connect(_on_pause_main_menu_pressed)

	if GameManager.is_tutorial_mode:
		_tutorial = TutorialManager.new()
		_tutorial.active_grid = _grid
		_hint.tutorial_state = _tutorial_hint_state
		_tutorial.step_changed.connect(_on_tutorial_step_changed)
		_tutorial.tutorial_finished.connect(_on_tutorial_finished)
		_grid.simulation_updated.connect(_on_tutorial_simulation_updated)
		_grid.tile_tap_attempted.connect(_on_tutorial_tile_tap_attempted)
		_tutorial_panel.continue_pressed.connect(_on_tutorial_panel_continue_pressed)
		_tutorial_complete_popup.next_tutorial_pressed.connect(_on_tutorial_next_pressed)
		_tutorial_complete_popup.retry_pressed.connect(_on_tutorial_retry_pressed)
		_tutorial_complete_popup.tutorial_select_pressed.connect(_on_tutorial_select_pressed)
		_tutorial_complete_popup.campaign_pressed.connect(_on_tutorial_campaign_pressed)
		_qa_debug_label.visible = BuildConfig.QA_TOOLS

	_load_current_level()


## Android's system Back gesture/button (see project.godot's
## quit_on_go_back=false, set specifically so this milestone's Pause menu
## can intercept it instead of the OS silently exiting the app - see
## ARCHITECTURE.md "Pause menu"/"Android back handling"). Desktop's Esc
## key raises the same notification, so this doubles as the desktop
## shortcut for free.
## Real play time for the cloud-save merge rule (SaveManager.play_time_seconds): a board on
## screen, not paused, not solved, not an editor playtest.
func _process(delta: float) -> void:
	if get_tree().paused or GameManager.is_editor_playtest:
		return
	if _complete_popup.visible or _tutorial_complete_popup.visible:
		return
	SaveManager.add_play_time(delta)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _complete_popup.visible or _tutorial_complete_popup.visible:
		return
	if _pause_menu.visible:
		_on_pause_resume_pressed()
	else:
		_on_pause_pressed()


func _on_pause_pressed() -> void:
	if _complete_popup.visible or _tutorial_complete_popup.visible or is_inside_tree() == false:
		return
	get_tree().paused = true
	AudioManager.play_ui_popup()
	_pause_menu.show()
	# Pause has its own full-screen dim - stacking the tutorial board dim
	# on top of it would double-darken the board. See
	# GridManager.suspend_tutorial_focus() and DECISIONS.md "Guided
	# tutorial visual focus fix".
	if GameManager.is_tutorial_mode:
		_grid.suspend_tutorial_focus()


func _on_pause_resume_pressed() -> void:
	_pause_menu.hide()
	get_tree().paused = false
	if GameManager.is_tutorial_mode:
		_grid.resume_tutorial_focus()


func _on_pause_restart_pressed() -> void:
	get_tree().paused = false
	_pause_menu.hide()
	_load_current_level()


func _on_pause_settings_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to_settings()


func _on_pause_level_select_pressed() -> void:
	get_tree().paused = false
	_on_back_pressed()


func _on_pause_main_menu_pressed() -> void:
	get_tree().paused = false
	if GameManager.is_tutorial_mode:
		_clear_tutorial_focus_visuals()
	GameManager.go_to_main_menu()


## Guided-tutorial-only: the single authoritative place that clears all
## tutorial focus visuals (highlight + board dim) - see DECISIONS.md
## "Guided tutorial visual focus fix". GridManager.clear_highlight()
## already does this as a side effect of every step transition, but
## this is called explicitly at every tutorial exit/reset point too
## (completion, restart, leaving the scene) so stale focus state can
## never survive across one of those boundaries even if a future change
## adds a path that doesn't go through a normal step transition.
func _clear_tutorial_focus_visuals() -> void:
	if _grid != null:
		_grid.clear_highlight()


func _exit_tree() -> void:
	_clear_tutorial_focus_visuals()


## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85):
## force_fresh=true (Reset/Retry) always starts the current level over and
## resets its resume state to match, never restoring the pre-reset board.
## force_fresh=false (initial _ready(), Next Level) tries to resume - if
## SaveManager's tracked resume level matches current_level_id, the saved
## orientations/move count are restored; otherwise this level starts
## fresh tracking (this is also what naturally happens on Next Level,
## since the new level id never matches the just-solved one). QA Level
## Select sessions (GameManager.entered_via_level_select) never read or
## write campaign_resume_* at all - see that flag's own doc comment.
func _load_current_level(force_fresh: bool = false) -> void:
	moves_used = 0
	_hint_used_this_attempt = false
	_update_moves_label()
	_completion_pending = false
	_rewarded_this_level = false
	_tutorial_complete_popup.hide()
	_qa_next_button.visible = GameManager.is_procedural_mode and (LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON or _is_v3_session())
	_qa_next_button.text = ("NEXT V5" if _is_v5_session() else "NEXT SELECTOR" if _is_selector_session() else "NEXT FUSION" if _is_fusion_session() else "NEXT V3") if _is_v3_session() else "+%d" % LevelManager.PROCEDURAL_QA_JUMP_AMOUNT

	if GameManager.is_tutorial_mode:
		_apply_era_theme(EraTheme.get_era_for_tutorial(GameManager.current_tutorial_id))
		_clear_tutorial_focus_visuals()
		_tutorial.restart()
		var tutorial_level: TutorialLevelData = _tutorial.start(GameManager.current_tutorial_id)
		_level_label.text = "TUTORIAL\n%s" % _shorten_level_name(tutorial_level.display_name)
		_grid.load_level(tutorial_level)
		_tutorial.active_grid = _grid
		_complete_popup.hide()
		_tutorial.advance()
		_hint.configure(HintManager.table_solution("t%d" % GameManager.current_tutorial_id))
		_refresh_hint_button()
		_hint.permission_provider = Callable() # tutorials are ad-free (D98)
		_hint_attention_restart()
		return

	var level_data: LevelData
	if GameManager.is_editor_playtest and GameManager.editor_level_data != null:
		level_data = GameManager.editor_level_data
		_level_label.text = "EDITOR\n%s" % _shorten_level_name(level_data.display_name)
		_apply_era_theme(1) # the level editor is a dev-only tool, unthemed for now
		_grid.load_level(level_data)
		_hint.configure({})
	elif GameManager.is_procedural_mode:
		# Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md):
		# never entered_via_level_select (there is no procedural Level
		# Select - see LevelManager.get_procedural_level()'s own doc
		# comment), so Pause/Complete always route to Main Menu here,
		# mirroring the campaign branch's `not entered_via_level_select`
		# case exactly.
		var procedural_level_number: int = GameManager.current_procedural_level
		var v3_session := _is_v3_session()
		var is_resuming: bool = not v3_session and not force_fresh and SaveManager.procedural_resume_level_number == procedural_level_number
		# Generator versioning (Procedural Difficulty Tuning + QA Jump 50
		# pass, see PROCEDURAL_GENERATION.md "Generator versioning" and
		# DECISIONS.md D92): a RESUMED puzzle must regenerate under the
		# EXACT version it was originally built with
		# (SaveManager.procedural_resume_generator_version), never whatever
		# ProceduralLevelGenerator.GENERATOR_VERSION currently is - this is
		# what keeps an in-progress V1 puzzle reproducing identically even
		# after V2 becomes the default for brand-new levels. Before this
		# pass, this call site never passed a version at all (always
		# defaulted to the current GENERATOR_VERSION), which was harmless
		# while only one version had ever existed but would have silently
		# regenerated a resumed V1 puzzle under V2 rules the moment V2
		# shipped - fixed here, not left as a latent bug.
		var generator_version := SaveManager.procedural_resume_generator_version if is_resuming else LevelManager.procedural_generator_version_for_new_play(procedural_level_number)
		_procedural_generator_version = generator_version
		var gen_result: Dictionary = _qa_generate(procedural_level_number) if v3_session else LevelManager.get_procedural_generation_result(procedural_level_number, generator_version)
		level_data = gen_result["level_data"]
		_hint.configure(gen_result.get("solution_orientations", {}))
		var qa_title := "V5 TEST" if _is_v5_session() else "SELECTOR QA" if _is_selector_session() else "FUSION QA" if _is_fusion_session() else "V3 PROTO"
		_level_label.text = ("%s\n%d / %d" % [qa_title, procedural_level_number, _qa_count()]) if v3_session else ("LEVEL %d" % procedural_level_number)
		if _is_v5_session():
			# V5 TEST names the REAL level number and generator facts (the index alone says nothing).
			var qa_real: int = ProceduralV5QaSet.level_for(procedural_level_number)
			var qa_sel: String = gen_result.get("selector_fragment", "")
			_level_label.text = "V5 TEST %d/%d\nL%d %s%s%s" % [procedural_level_number, _qa_count(), qa_real, ProceduralDifficultyContract.band_code(qa_real), (" " + qa_sel) if qa_sel != "" else "", " ~DEMOTED" if gen_result.get("band_demoted", false) else ""]
		# QA-only tag (Phase 2B, D96): which generator/band this puzzle came from, so a tester can
		# judge difficulty per band and see a V3 generation failure (V2 fallback) on the device.
		if BuildConfig.QA_TOOLS and not v3_session and LevelManager.USE_V3_FOR_PROCEDURAL_QA and generator_version >= ProceduralLevelGenerator.GENERATOR_VERSION_V3:
			# Fusion Phase 2 (D100): "V4 HRD F2" = generator 4, band, Fusion fragment (F1-F7) when the level has one.
			var qa_tag := "V%d" % generator_version
			if gen_result.get("v3_generation_failed", false):
				_level_label.text += "\n%s FAILED>V2" % qa_tag
			else:
				var frag: String = gen_result.get("fusion_fragment", "")
				# Selector Phase S3 (D110): a V5 level also names its Selector family (SA-SP), e.g. "V5 SCQ F3 SL".
				var sel_frag: String = gen_result.get("selector_fragment", "")
				_level_label.text += "\n%s %s%s%s" % [qa_tag, ProceduralDifficultyContract.band_code(procedural_level_number), (" " + frag) if frag != "" else "", (" " + sel_frag) if sel_frag != "" else ""]
		_apply_era_theme(EraTheme.get_era_for_level(procedural_level_number))
		_grid.load_level(level_data)

		_pause_menu.set_level_select_visible(false)
		_complete_popup.set_navigation_label("MAIN MENU")

		if is_resuming:
			_grid.restore_orientations(SaveManager.get_procedural_resume_orientations())
			moves_used = SaveManager.procedural_resume_move_count
			_hint_used_this_attempt = SaveManager.procedural_resume_hint_used
			_update_moves_label()
		elif not v3_session:
			SaveManager.start_procedural_resume(procedural_level_number, gen_result["seed"], gen_result["generator_version"])
	else:
		level_data = LevelManager.get_campaign_level(current_level_id)
		var campaign_solution := HintManager.table_solution("c%d" % current_level_id)
		if campaign_solution.is_empty():
			push_warning("Hint disabled: no solver-authored solution for campaign level %d" % current_level_id)
		_hint.configure(campaign_solution)
		_level_label.text = "LEVEL %d\n%s" % [current_level_id, _shorten_level_name(level_data.display_name)]
		_apply_era_theme(EraTheme.get_era_for_level(current_level_id))
		_grid.load_level(level_data)

		# Phase 2: only the real campaign flow distinguishes a normal
		# PLAY/CONTINUE session from a QA Level Select one - Pause
		# already has a separate, dedicated Main Menu button (so its
		# Level Select button is simply hidden here), while Level
		# Complete has no separate Main Menu button (so its Level Select
		# button is relabeled instead). Tutorial/editor-playtest sessions
		# never reach this branch, so their own pre-existing Pause/
		# Complete navigation is completely untouched.
		_pause_menu.set_level_select_visible(GameManager.entered_via_level_select)
		_complete_popup.set_navigation_label("LEVEL SELECT" if GameManager.entered_via_level_select else "MAIN MENU")

		if not GameManager.entered_via_level_select:
			if not force_fresh and SaveManager.campaign_resume_level_id == current_level_id:
				_grid.restore_orientations(SaveManager.get_campaign_resume_orientations())
				moves_used = SaveManager.campaign_resume_move_count
				_hint_used_this_attempt = SaveManager.campaign_resume_hint_used
				_update_moves_label()
			else:
				SaveManager.start_campaign_resume(current_level_id)

	_complete_popup.hide()
	_refresh_hint_button()
	_configure_hint_permission()
	_hint_attention_restart()


## Era 2: applies the given era's themed gameplay background, HUD bars,
## and grid cell art (TileVisual.active_cell_background - read by
## GridManager.load_level() and every tile's own _draw(), so this MUST
## run before _grid.load_level() is called). Era 1 (EraTheme.for_era(1))
## has every field null, which this function reads as "use the Era 1
## default" - so calling this with era_number == 1 always restores
## exactly game.tscn's own original art, never leaves a stale Era 2
## texture behind from a previous level in the same scene instance (Next
## Level/Next Tutorial/Reset never reload game.tscn - see GameManager).
func _apply_era_theme(era_number: int) -> void:
	var theme := EraTheme.for_era(era_number)
	_background.texture = theme.gameplay_background if theme.gameplay_background else DEFAULT_GAMEPLAY_BACKGROUND
	_top_bar_background.texture = theme.hud_top if theme.hud_top else DEFAULT_HUD_TOP
	_bottom_bar_background.texture = theme.hud_bottom if theme.hud_bottom else DEFAULT_HUD_BOTTOM
	_top_bar.set_aspect_ratio(theme.hud_aspect_ratio if theme.hud_aspect_ratio > 0.0 else DEFAULT_TOP_BAR_ASPECT)
	_bottom_bar.set_aspect_ratio(theme.hud_aspect_ratio if theme.hud_aspect_ratio > 0.0 else DEFAULT_BOTTOM_BAR_ASPECT)
	TileVisual.active_cell_background = theme.grid_cell_empty if theme.grid_cell_empty else TileVisual.DEFAULT_CELL_BACKGROUND_TEXTURE
	_complete_popup.set_era_panel(theme.level_complete_panel, theme.level_complete_panel_margins)
	_tutorial_complete_popup.set_era_panel(theme.tutorial_complete_panel, theme.tutorial_complete_panel_margins)


## Keeps the top HUD's narrow left slot to exactly two clean lines -
## see MAX_LEVEL_NAME_CHARS.
func _shorten_level_name(display_name: String) -> String:
	if display_name.length() <= MAX_LEVEL_NAME_CHARS:
		return display_name
	return display_name.substr(0, MAX_LEVEL_NAME_CHARS - 1) + "…"



## Tells SafeAreaMargin how many px of each HUD bar is transparent art padding so the visible plates sit
## UIConstants.GAMEPLAY_VERTICAL_MARGIN inside the real safe area (see SafeAreaMargin.set_hud_overhang()).
func _update_hud_edge_overhang() -> void:
	_safe_margin.set_hud_overhang(
		_top_bar.custom_minimum_size.y * UIConstants.HUD_TOP_ART_PAD_FRACTION,
		_bottom_bar.custom_minimum_size.y * UIConstants.HUD_BOTTOM_ART_PAD_FRACTION
	)

func _update_moves_label() -> void:
	_moves_label.text = "MOVES: %d" % moves_used


func _on_move_made() -> void:
	moves_used += 1
	_update_moves_label()
	if GameManager.is_tutorial_mode:
		_tutorial.notify_move_made()
	elif GameManager.is_procedural_mode:
		# Phase 3: same event-driven persistence pattern as the campaign
		# branch below, against the procedural resume fields instead. A V3
		# QA prototype session (D94) never persists anything.
		if not _is_v3_session():
			SaveManager.update_procedural_resume_state(_grid.tile_orientations, moves_used)
	elif not GameManager.is_editor_playtest and not GameManager.entered_via_level_select:
		# Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85):
		# event-driven persistence - once per accepted move, never per
		# frame. Skipped for editor playtest (never writes save data,
		# same rule as record_campaign_level_result below) and QA Level
		# Select sessions (never touch the real player's resume state).
		SaveManager.update_campaign_resume_state(_grid.tile_orientations, moves_used)


## Fires the instant grid_manager.gd's simulation determines the puzzle
## is solved (is_solved is already true by this point - see
## LEVEL_COMPLETE_DELAY's doc comment). Only the popup presentation is
## delayed, so the player briefly sees the final beam/target-activation
## VFX on the solved board before it appears. _completion_pending guards
## against this firing twice (level_solved only emits once per solve, but
## defensively) and against a stale delayed popup appearing after the
## player has already Reset/Retried/advanced past this level - both of
## those call _load_current_level(), which clears the flag immediately.
func _on_level_solved() -> void:
	if GameManager.is_tutorial_mode:
		_hint_attention_stop()
		_tutorial.notify_puzzle_solved()
		return

	if _completion_pending:
		return
	_completion_pending = true
	_hint_attention_stop()

	var moves_snapshot := moves_used
	var stars := 1
	var show_stars := true
	var has_next := false
	var best_moves := -1
	# Era 2: must be read BEFORE record_campaign_level_result() below
	# marks this level completed, or "first time completing Level 100"
	# could never be detected (a replay would look identical to the
	# first clear otherwise). Deliberately NOT "current_level_id ==
	# get_campaign_level_count()" - that was correct back when Level 100
	# was the last implemented level, but broke the instant Levels
	# 101-110 were added (it would have silently shifted this banner to
	# fire at completing Level 110 instead of Level 100). Comparing eras
	# via EraTheme pins this to the real Level 100 -> Era 2 boundary and
	# generalizes automatically to a future Level 200 -> Era 3 boundary.
	# Phase 3: this banner points at the T11-T20 unlock, which is gated on
	# CAMPAIGN completion (see LevelManager.is_tutorial_level_selectable())
	# - it has no procedural equivalent, and current_level_id is meaningless
	# during a procedural session (GameManager tracks current_procedural_
	# level instead - see GameManager.start_procedural_level()), so this
	# must never evaluate for one.
	var era_transition := (
		not GameManager.is_editor_playtest
		and not GameManager.is_procedural_mode
		and EraTheme.get_era_for_level(current_level_id) < EraTheme.get_era_for_level(current_level_id + 1)
		and not SaveManager.is_campaign_level_completed(current_level_id)
	)

	if GameManager.is_editor_playtest:
		# Development playtest: never write to the player's save data, and
		# there's no "next level" for an in-progress/unsaved editor level.
		# Stars are computed against the editor level's own declared
		# optimal_moves using the same formula as real play, purely as a
		# design preview - LevelManager.calculate_stars() needs a saved
		# level_id, so the threshold math is duplicated here on purpose
		# (see LevelManager.TWO_STAR_MOVE_MARGIN for the source of truth).
		stars = StarScoring.stars_for(GameManager.editor_level_data.optimal_moves, moves_snapshot, false)
	elif GameManager.is_procedural_mode:
		# Star scoring is centralized in StarScoring (D102). A V3/Fusion QA session shows NO stars and records
		# nothing; a legitimate procedural completion scores against the authoritative optimal of the exact
		# (level, generator version) puzzle and keeps the best result per that identity.
		var procedural_level_number: int = GameManager.current_procedural_level
		if _is_v3_session():
			show_stars = false
			has_next = procedural_level_number < _qa_count()
		else:
			var gen_result: Dictionary = LevelManager.get_procedural_generation_result(procedural_level_number, _procedural_generator_version)
			var optimal := StarScoring.authoritative_optimal(gen_result["level_data"], gen_result)
			stars = StarScoring.stars_for(optimal, moves_snapshot, _hint_used_this_attempt)
			SaveManager.record_procedural_stars(procedural_level_number, _procedural_generator_version, stars)
			SaveManager.record_procedural_level_result(procedural_level_number)
			AdManager.register_completion(procedural_level_number)
			has_next = procedural_level_number < LevelManager.get_procedural_level_count()
	else:
		stars = LevelManager.calculate_campaign_stars(current_level_id, moves_snapshot, _hint_used_this_attempt)
		SaveManager.record_campaign_level_result(current_level_id, moves_snapshot, stars, LevelManager.get_campaign_level_count())
		has_next = current_level_id < LevelManager.get_campaign_level_count()
		best_moves = SaveManager.get_campaign_best_moves(current_level_id)

	await get_tree().create_timer(LEVEL_COMPLETE_DELAY).timeout

	if not is_inside_tree() or not _completion_pending:
		return # scene gone, or a Reset/Retry/Next Level already superseded this
	_completion_pending = false
	AudioManager.play_level_complete()
	_complete_popup.show_result(moves_snapshot, stars, has_next, best_moves, era_transition, _hint_used_this_attempt and show_stars, show_stars)


func _on_reset_pressed() -> void:
	_load_current_level(true)


func _on_back_pressed() -> void:
	if GameManager.is_tutorial_mode:
		_clear_tutorial_focus_visuals()
		GameManager.go_to_tutorial_select()
	elif GameManager.is_editor_playtest:
		GameManager.return_to_editor_from_playtest()
	elif GameManager.entered_via_level_select:
		GameManager.go_to_level_select()
	else:
		# Phase 2: a normal PLAY/CONTINUE session never exposes Level
		# Select - see DECISIONS.md D85.
		GameManager.go_to_main_menu()


func _on_next_level_pressed() -> void:
	# AdMob Foundation (D98): the natural transition. Only normal procedural progression ever
	# reaches an interstitial (never a V3 TEST session, tutorial, or campaign QA session).
	if _interstitial_eligible_session() and AdManager.maybe_show_interstitial_after_completion(_rewarded_this_level, _advance_to_next_level):
		return
	_advance_to_next_level()


func _advance_to_next_level() -> void:
	if GameManager.is_procedural_mode:
		GameManager.current_procedural_level += 1
	else:
		current_level_id += 1
		GameManager.current_level_id = current_level_id
	_load_current_level()


func _on_retry_pressed() -> void:
	_load_current_level(true)


## Phase 3 (Procedural Generator V1) - TEMPORARY QA-only skip button, see
## LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON's doc comment. Advances
## LevelManager.PROCEDURAL_QA_JUMP_AMOUNT levels ahead WITHOUT solving this one (Procedural
## Difficulty Tuning + QA Jump 50 pass - was +1, now +50, see
## DECISIONS.md D92): deliberately calls start_procedural_resume() (moving
## only the resume POINTER forward, exactly like entering any
## not-yet-resumed level would) and never record_procedural_level_result()
## - so this can never mark any of the skipped levels legitimately
## completed, award stars, or advance SaveManager.procedural_current_level.
## Clamped to ProceduralLevelGenerator.MAX_LEVEL - pressing it at or near
## Level 2000 safely lands on (or reloads fresh at) 2000, never attempts
## Level 2001+. A subsequent CONTINUE correctly returns to the skipped-to
## level (has_resumable_procedural_game() is still true), but none of the
## skipped levels count as "passed" for progression purposes - see
## PROCEDURAL_GENERATION.md "QA Next button".
## The jump size lives in LevelManager.PROCEDURAL_QA_JUMP_AMOUNT (single
## source, Difficulty System Phase 1). At MAX_LEVEL this is a true no-op -
## it does not reload/reset the level being played.
func _on_qa_next_pressed() -> void:
	if _is_v3_session():
		# D94: dev-only prototype cycle 1..6, no save access at all.
		GameManager.current_procedural_level = GameManager.current_procedural_level % _qa_count() + 1
		_load_current_level(true)
		return
	if not (LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON and GameManager.is_procedural_mode):
		return
	if GameManager.current_procedural_level >= ProceduralLevelGenerator.MAX_LEVEL:
		return
	GameManager.current_procedural_level = mini(
		GameManager.current_procedural_level + LevelManager.PROCEDURAL_QA_JUMP_AMOUNT, ProceduralLevelGenerator.MAX_LEVEL)
	_load_current_level(true)


## True only during the dev-only V3 prototype QA session (D94).
func _is_v3_session() -> bool:
	# "QA sandbox session": the V3 prototype selector OR the Fusion QA selector (D99) - both are
	# save-free, ad-free, counter-free and keep hints free.
	return GameManager.is_procedural_mode and ((GameManager.is_v3_prototype_mode and LevelManager.SHOW_V3_PROTOTYPE_QA) or _is_fusion_session() or _is_selector_session() or _is_v5_session())


func _is_fusion_session() -> bool:
	return GameManager.is_fusion_test_mode and LevelManager.SHOW_FUSION_TEST_QA and GameManager.is_procedural_mode


func _is_v5_session() -> bool:
	return GameManager.is_v5_test_mode and LevelManager.SHOW_V5_TEST_QA and GameManager.is_procedural_mode


func _is_selector_session() -> bool:
	return GameManager.is_selector_test_mode and LevelManager.SHOW_SELECTOR_TEST_QA and GameManager.is_procedural_mode


func _qa_count() -> int:
	return ProceduralV5QaSet.COUNT if _is_v5_session() else SelectorQaSet.COUNT if _is_selector_session() else FusionQaSet.COUNT if _is_fusion_session() else ProceduralGeneratorV3.PROTOTYPE_COUNT


func _qa_generate(n: int) -> Dictionary:
	return ProceduralV5QaSet.get_puzzle(n) if _is_v5_session() else SelectorQaSet.get_puzzle(n) if _is_selector_session() else FusionQaSet.get_puzzle(n) if _is_fusion_session() else ProceduralGeneratorV3.generate(n)


func _on_level_select_pressed() -> void:
	if GameManager.is_editor_playtest:
		GameManager.return_to_editor_from_playtest()
	elif GameManager.entered_via_level_select:
		GameManager.go_to_level_select()
	else:
		# Phase 2: LevelCompletePopup's button is relabeled "MAIN MENU"
		# for this case by _load_current_level() - see DECISIONS.md D85.
		GameManager.go_to_main_menu()


## --- Guided tutorial handlers. Only ever invoked when GameManager.
## is_tutorial_mode is true - see _ready()'s conditional signal wiring.

func _on_tutorial_step_changed(step: TutorialStepData) -> void:
	var show_continue := step.step_type == TutorialStepData.StepType.MESSAGE
	_tutorial_panel.show_step(step.text, show_continue)
	_qa_last_step = step
	_update_qa_debug_label()


## Guided-tutorial-QA-only - refreshes the debug overlay's LAST TAP/
## RESOLVED/RESULT line after every tap attempt (accepted or rejected),
## via GridManager.tile_tap_attempted - see DECISIONS.md ("Guided
## tutorial click input fix").
func _on_tutorial_tile_tap_attempted() -> void:
	_update_qa_debug_label()


## TEMPORARY, QA-build-only - see the _qa_debug_label field comment.
## Expanded (per the click-input fix) to also show the last tap attempt
## and its accept/reject result, so "nothing happens when I tap" is
## diagnosable directly from the screen instead of guessed at.
func _update_qa_debug_label() -> void:
	var step := _qa_last_step
	if step == null:
		return
	var mode_str := "MESSAGE(locked)"
	match step.step_type:
		TutorialStepData.StepType.REQUIRE_TILE_TAP:
			mode_str = "REQUIRE_TAP"
		TutorialStepData.StepType.WAIT_FOR_TARGET_ACTIVATION:
			mode_str = "WAIT_TARGET(%s)" % ("locked" if step.lock_all_input else "free")
		TutorialStepData.StepType.WAIT_FOR_PUZZLE_SOLVED:
			mode_str = "WAIT_SOLVED(%s)" % ("locked" if step.lock_all_input else "free")
	var last_tap_str := "none yet"
	if _grid.last_tap_cell != Vector2i(-1, -1):
		var result_str := "ACCEPTED" if _grid.last_tap_accepted else "REJECTED (%s)" % _grid.last_tap_rejection_reason
		last_tap_str = "%s -> %s" % [_grid.last_tap_cell, result_str]
	_qa_debug_label.text = "TUTORIAL QA\nSTEP: %d  MODE: %s\nHIGHLIGHT: %s  ALLOWED: %s\nLAST TAP: %s" % [
		_tutorial.current_step_index, mode_str, step.highlight_position, step.target_position, last_tap_str,
	]


func _on_tutorial_panel_continue_pressed() -> void:
	_tutorial.advance()


func _on_tutorial_simulation_updated() -> void:
	_tutorial.notify_simulation_updated()


## Mirrors _on_level_solved()'s own delay so the player briefly sees the
## solved board's final beam/target-activation state before the
## completion popup appears - same LEVEL_COMPLETE_DELAY, same
## _completion_pending guard against a stale popup after Restart/Back.
func _on_tutorial_finished() -> void:
	if _completion_pending:
		return
	_completion_pending = true
	_clear_tutorial_focus_visuals()

	var tutorial_id := GameManager.current_tutorial_id
	var total := LevelManager.get_tutorial_level_count()
	SaveManager.record_tutorial_level_result(tutorial_id, total)

	await get_tree().create_timer(LEVEL_COMPLETE_DELAY).timeout

	if not is_inside_tree() or not _completion_pending:
		return
	_completion_pending = false
	AudioManager.play_level_complete()
	_tutorial_panel.hide()
	_tutorial_complete_popup.show_result(tutorial_id >= total)


func _on_tutorial_next_pressed() -> void:
	GameManager.current_tutorial_id += 1
	_load_current_level()


func _on_tutorial_retry_pressed() -> void:
	_load_current_level()


func _on_tutorial_select_pressed() -> void:
	_clear_tutorial_focus_visuals()
	GameManager.go_to_tutorial_select()


func _on_tutorial_campaign_pressed() -> void:
	# Phase 2: this popup's button is relabeled "PLAY" (was "CAMPAIGN") -
	# a normal player finishing the tutorial pack should never land on
	# the now QA-only Level Select. See DECISIONS.md D85.
	_clear_tutorial_focus_visuals()
	GameManager.play_game()


# --- Global Hint System (D97) -----------------------------------------------------------
# The Hint button lives in the shared HUD (game.tscn); all logic is HintManager's. A press
# reveals ONE required tile (ring only) - it never rotates, counts a move, or touches saves.

func _refresh_hint_button() -> void:
	_hint_button.visible = _hint != null and _hint.has_hint_source()


func _on_hint_pressed() -> void:
	if _complete_popup.visible or _tutorial_complete_popup.visible:
		return
	AudioManager.play_ui_button_press()
	_hint_attention_restart()
	_hint.request_hint()


# --- Hint attention pulse ---------------------------------------------------------------------
# Purely visual: scales the HintIcon child about its centre and fades an additive halo copy of it.
# The Button, its container and the board are never touched, so no layout or touch target moves.

func _build_hint_glow() -> void:
	_hint_glow = TextureRect.new()
	_hint_glow.texture = _hint_icon.texture
	_hint_glow.expand_mode = _hint_icon.expand_mode
	_hint_glow.stretch_mode = _hint_icon.stretch_mode
	_hint_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_glow.set_anchors_preset(Control.PRESET_CENTER)
	_hint_glow.offset_left = _hint_icon.offset_left
	_hint_glow.offset_top = _hint_icon.offset_top
	_hint_glow.offset_right = _hint_icon.offset_right
	_hint_glow.offset_bottom = _hint_icon.offset_bottom
	_hint_glow.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_glow.grow_vertical = Control.GROW_DIRECTION_BOTH
	var half := Vector2(_hint_icon.offset_right - _hint_icon.offset_left, _hint_icon.offset_bottom - _hint_icon.offset_top) * 0.5
	_hint_glow.pivot_offset = half
	# Solid-colour silhouette (texture alpha only): multiplying the blue icon by gold would come out muddy.
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;
render_mode blend_add;
uniform vec3 glow_color : source_color;
void fragment() { COLOR = vec4(glow_color, COLOR.a); }"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("glow_color", Vector3(UIConstants.HINT_GLOW_COLOR.r, UIConstants.HINT_GLOW_COLOR.g, UIConstants.HINT_GLOW_COLOR.b))
	_hint_glow.material = mat
	_hint_glow.modulate = Color(UIConstants.HINT_GLOW_COLOR, 0.0)
	_hint_glow.visible = false
	_hint_icon.get_parent().add_child(_hint_glow)
	_hint_icon.get_parent().move_child(_hint_glow, _hint_icon.get_index())
	_hint_icon.pivot_offset = half


func _hint_attention_stop() -> void:
	if _hint_attention_tween != null:
		_hint_attention_tween.kill()
		_hint_attention_tween = null
	_hint_pulse_active = false
	_apply_hint_pulse(0.0)


func _hint_attention_restart() -> void:
	_hint_attention_stop()
	if not is_inside_tree():
		return
	var total := UIConstants.HINT_GLOW_IN_DURATION + UIConstants.HINT_GLOW_HOLD_DURATION + UIConstants.HINT_GLOW_OUT_DURATION
	_hint_attention_tween = create_tween().set_loops()
	_hint_attention_tween.tween_interval(UIConstants.HINT_ATTENTION_INTERVAL)
	_hint_attention_tween.tween_callback(func() -> void: _hint_pulse_active = _hint_attention_allowed())
	_hint_attention_tween.tween_method(_hint_pulse_time, 0.0, total, total)


func _hint_attention_allowed() -> bool:
	if not _hint_button.visible or _hint_button.disabled or _hint_ad_open or _completion_pending:
		return false
	if _complete_popup.visible or _tutorial_complete_popup.visible or _pause_menu.visible:
		return false
	if GameManager.is_tutorial_mode and _tutorial_hint_state().get("mode", "none") == "none":
		return false
	return true


func _hint_pulse_time(t: float) -> void:
	if not _hint_pulse_active:
		return
	var in_d := UIConstants.HINT_GLOW_IN_DURATION
	var hold_d := UIConstants.HINT_GLOW_HOLD_DURATION
	var out_d := UIConstants.HINT_GLOW_OUT_DURATION
	var k := 1.0
	if t < in_d:
		k = smoothstep(0.0, 1.0, t / in_d)
	elif t > in_d + hold_d:
		k = 1.0 - smoothstep(0.0, 1.0, (t - in_d - hold_d) / out_d)
	_apply_hint_pulse(k)


func _apply_hint_pulse(k: float) -> void:
	var s := lerpf(1.0, UIConstants.HINT_ATTENTION_SCALE, k)
	_hint_icon.scale = Vector2(s, s)
	_hint_glow.visible = k > 0.001
	_hint_glow.scale = Vector2.ONE * s * lerpf(1.0, UIConstants.HINT_GLOW_SCALE, k)
	_hint_glow.modulate.a = UIConstants.HINT_GLOW_ALPHA * k


## "No hint available": a brief dip of the button, no sound, no highlight.
## A Hint was really granted and shown (rewarded ad earned, or free where ads are unsupported). Tutorials, V3/Fusion QA
## sessions and editor playtest never count. Persisted immediately so Continue cannot regain 3-star eligibility.
func _on_hint_granted(_pos: Vector2i) -> void:
	if GameManager.is_tutorial_mode or GameManager.is_editor_playtest or _is_v3_session():
		return
	_hint_used_this_attempt = true
	if GameManager.is_procedural_mode:
		SaveManager.mark_hint_used(true)
	elif not GameManager.entered_via_level_select:
		SaveManager.mark_hint_used(false)


func _on_hint_unavailable() -> void:
	var tw := create_tween()
	tw.tween_property(_hint_button, "modulate:a", 0.35, 0.12)
	tw.tween_property(_hint_button, "modulate:a", 1.0, 0.25)


## Tutorial hook: a REQUIRE_TILE_TAP step exposes its own target; free-play steps use the
## table solution; message/locked steps allow no general hint (never bypasses a step).
func _tutorial_hint_state() -> Dictionary:
	var step := _tutorial.get_current_step() if _tutorial != null else null
	if step == null:
		return {"mode": "none"}
	match step.step_type:
		TutorialStepData.StepType.REQUIRE_TILE_TAP:
			return {"mode": "target", "pos": step.target_position}
		TutorialStepData.StepType.WAIT_FOR_TARGET_ACTIVATION, TutorialStepData.StepType.WAIT_FOR_PUZZLE_SOLVED:
			return {"mode": "none"} if step.lock_all_input else {"mode": "free"}
	return {"mode": "none"}


# --- AdMob Foundation (D98) ------------------------------------------------------------------
# Ads never run during active solving, in tutorials, in V3 TEST or in QA Level Select sessions.

func _interstitial_eligible_session() -> bool:
	return GameManager.is_procedural_mode and not _is_v3_session() and not GameManager.is_tutorial_mode


## Normal procedural play: a hint needs a rewarded ad (unless ads are unsupported here or
## the QA bypass is on). Everything else keeps the free Phase 1 hint.
func _configure_hint_permission() -> void:
	if _interstitial_eligible_session() and AdManager.hint_requires_ad():
		_hint.permission_provider = _hint_permission
	else:
		_hint.permission_provider = Callable()


func _hint_permission(hm: HintManager) -> void:
	var status := AdManager.show_rewarded_hint(func(granted: bool) -> void:
		if granted:
			hm.grant_hint())
	if status == "not_ready":
		_on_hint_unavailable() # no free fallback: unavailable for this attempt, a reload is running


func _on_ad_rewarded_opened() -> void:
	_rewarded_this_level = true
	_hint_ad_open = true
	_hint_attention_stop()


func _on_ad_rewarded_closed() -> void:
	_hint_ad_open = false
	_hint_attention_restart()
	_hint.rearm()
