extends Control
## scenes/ui/level_complete_popup.tscn root script.
## Purely presentational + input relay - game.gd owns the actual
## level-advance/retry/navigation logic. Milestone 4A: stars render as
## icon textures instead of Unicode glyphs; a Best Moves row was added
## (existing star/best-move calculation in LevelManager/SaveManager is
## untouched - see CLAUDE.md rule "preserve the existing scoring/star
## algorithm exactly").

const TEXTURE_STAR_EARNED := preload("res://assets/ui/level_select/bs_ui_star_earned_runtime.png")
const TEXTURE_STAR_UNEARNED := preload("res://assets/ui/level_select/bs_ui_star_unearned_runtime.png")

signal next_level_pressed
signal retry_pressed
signal level_select_pressed

@onready var _panel: PanelContainer = %Panel
@onready var _moves_label: Label = %MovesValueLabel
@onready var _era_transition_label: Label = %EraTransitionLabel
@onready var _hint_used_label: Label = %HintUsedLabel
@onready var _best_moves_row: HBoxContainer = %BestMovesRow
@onready var _best_moves_label: Label = %BestMovesValueLabel
@onready var _stars: Array[TextureRect] = [%Star1, %Star2, %Star3]
@onready var _next_button: Button = %NextLevelButton
@onready var _retry_button: Button = %RetryButton
@onready var _level_select_button: Button = %LevelSelectButton

## See TutorialCompletePopup._default_panel_min_size's doc comment - same
## fix, kept here too as a guard against future content changes (e.g. a
## hidden Best Moves row) shrinking this popup below a themed frame's own
## fixed top+bottom margins.
var _default_panel_min_size: Vector2


func _ready() -> void:
	_default_panel_min_size = _panel.custom_minimum_size
	_next_button.pressed.connect(func() -> void: next_level_pressed.emit())
	_retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	_level_select_button.pressed.connect(func() -> void: level_select_pressed.emit())

	for button in [_next_button, _retry_button, _level_select_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)


## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): game.gd
## sets this once per level load to "MAIN MENU" or "LEVEL SELECT"
## depending on GameManager.entered_via_level_select, so the button's
## label always matches where level_select_pressed will actually
## navigate to - purely presentational, this popup still has no
## navigation logic of its own.
func set_navigation_label(text: String) -> void:
	_level_select_button.text = text


## best_moves < 0 hides the row entirely (used for editor-playtest levels,
## which have no saved best-moves record - see game.gd).
## era_transition (Era 2): true exactly once, the first time Level 100 is
## completed - see game.gd._on_level_solved(). Shows a small banner
## pointing the player at the newly-unlocked T11-T20 tutorial pack;
## purely presentational, changes no progression/unlock logic (that
## already happened in LevelManager.is_tutorial_level_selectable() the
## instant SaveManager recorded the completion).
## Phase 4 (D102): hint_used shows the small "HINT USED" note (a Hint caps stars at 2); show_stars=false hides the
## star row entirely (V3/Fusion QA sessions have no stars).
func show_result(moves_used: int, stars: int, has_next_level: bool, best_moves: int = -1, era_transition: bool = false, hint_used: bool = false, show_stars: bool = true) -> void:
	_moves_label.text = str(moves_used)
	for i in _stars.size():
		_stars[i].texture = TEXTURE_STAR_EARNED if i < stars else TEXTURE_STAR_UNEARNED
	_best_moves_row.visible = best_moves >= 0
	if best_moves >= 0:
		_best_moves_label.text = str(best_moves)
	_next_button.visible = has_next_level
	_era_transition_label.visible = era_transition
	_hint_used_label.visible = hint_used
	_stars[0].get_parent().visible = show_stars
	show()


## Era 2+ QA/Hardening pass: swaps this popup's panel art per the current
## era, exactly like game.gd._apply_era_theme() already swaps HUD/
## background art - CLAUDE.md rule 11's per-screen-art exception extended
## to be era-aware rather than a permanent one-off. `texture == null`
## (Era 1, or any era with no themed panel yet) restores the .tscn's own
## authored default style - never leaves a stale override behind.
func set_era_panel(texture: Texture2D, margins: PackedFloat32Array) -> void:
	if texture == null or margins.size() < 4:
		_panel.remove_theme_stylebox_override("panel")
		_panel.custom_minimum_size = _default_panel_min_size
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margins[0]
	style.texture_margin_top = margins[1]
	style.texture_margin_right = margins[2]
	style.texture_margin_bottom = margins[3]
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(
		_default_panel_min_size.x,
		maxf(_default_panel_min_size.y, margins[1] + margins[3] + 40.0)
	)
