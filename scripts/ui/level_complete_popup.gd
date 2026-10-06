extends Control
## scenes/ui/level_complete_popup.tscn root script.
## Presentation + input relay only - game.gd owns scoring, saving, progression and navigation, and passes in every
## number shown here (moves, stars, target, best, level number). The popup never recalculates any of them.
## Level Complete redesign: sequential star reveal, result badge, stats panel, progression row, staggered buttons.
## The action buttons relay nothing until the entrance ends (or is skipped with a tap on the backdrop/panel).

const UNEARNED_TINT := Color(0.3, 0.34, 0.44, 0.85)
const BRIGHT_PULSE := Color(1.9, 1.7, 1.2, 1.0)
const STAR_LAND_TIMES := [0.35, 0.6, 0.85]
const NEXT_PULSE_INTERVAL := 2.8
const MIN_BUTTON_GAP := 16.0
const MAX_BUTTON_GAP := 80.0

signal next_level_pressed
signal retry_pressed
signal level_select_pressed

@onready var _panel: PanelContainer = %Panel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _stars_holder: Control = %StarsHolder
@onready var _back_fx: Control = %BackFx
@onready var _front_fx: Control = %FrontFx
@onready var _badge_holder: Control = %BadgeHolder
@onready var _badge_fx: Control = %BadgeFx
@onready var _result_label: Label = %ResultLabel
@onready var _result_sub_label: Label = %ResultSubLabel
@onready var _era_transition_label: Label = %EraTransitionLabel
@onready var _hint_used_label: Label = %HintUsedLabel
@onready var _stats_holder: Control = %StatsHolder
@onready var _moves_label: Label = %MovesValueLabel
@onready var _target_label: Label = %TargetValueLabel
@onready var _best_moves_label: Label = %BestMovesValueLabel
@onready var _progress_row: HBoxContainer = %ProgressRow
@onready var _from_label: Label = %FromLabel
@onready var _arrow_label: Label = %ArrowLabel
@onready var _to_label: Label = %ToLabel
@onready var _stars: Array[TextureRect] = [%Star1, %Star2, %Star3]
@onready var _button_row: VBoxContainer = %ButtonRow
@onready var _next_button: Button = %NextLevelButton
@onready var _retry_button: Button = %RetryButton
@onready var _level_select_button: Button = %LevelSelectButton

## See TutorialCompletePopup._default_panel_min_size's doc comment - same
## fix, kept here too as a guard against future content changes shrinking
## this popup below a themed frame's own fixed top+bottom margins.
var _default_panel_min_size: Vector2
var _tweens: Array[Tween] = []
var _input_locked := false
var _final_moves := 0
var _earned := 0
var _show_stars := true
var _show_progress := false


func _ready() -> void:
	_default_panel_min_size = _panel.custom_minimum_size
	_next_button.pressed.connect(_relay.bind(next_level_pressed))
	_retry_button.pressed.connect(_relay.bind(retry_pressed))
	_level_select_button.pressed.connect(_relay.bind(level_select_pressed))

	for button in _action_buttons():
		button.pressed.connect(_play_button_sound)
	BeamButtonGlow.attach(_next_button)
	BeamButtonGlow.attach(_retry_button).idle_glow = 0.12
	var menu_glow := BeamButtonGlow.attach(_level_select_button, BeamButtonGlow.RED_ORANGE)
	menu_glow.idle_glow = 0.06
	menu_glow.hover_glow = 0.25

	# Pivots follow the laid-out size so scale/rotation animate around each element's centre.
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size * 0.5)
	_badge_holder.resized.connect(func() -> void: _badge_holder.pivot_offset = _badge_holder.size * 0.5)
	for star in _stars:
		star.resized.connect(func() -> void: star.pivot_offset = star.size * 0.5)
	for button in _action_buttons():
		button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	_button_row.resized.connect(_fit_button_gaps)
	_next_button.visibility_changed.connect(_fit_button_gaps)
	# A tap on the backdrop/panel during the entrance settles the presentation. Buttons are locked and the tap is
	# consumed here, so it can never also activate one.
	$Dim.gui_input.connect(_on_tap)
	_panel.gui_input.connect(_on_tap)
	visibility_changed.connect(_on_visibility_changed)


## Spreads the action buttons over the space the row actually has (taller screens = larger gaps), keeping them one group.
func _fit_button_gaps() -> void:
	var used := 0.0
	var count := 0
	for b in _action_buttons():
		if b.visible:
			used += b.get_combined_minimum_size().y
			count += 1
	if count < 2:
		return
	var free := _button_row.size.y - used
	var gap := clampf(free / (count + 1), MIN_BUTTON_GAP, MAX_BUTTON_GAP)
	_button_row.add_theme_constant_override("separation", int(gap))


func _relay(sig: Signal) -> void:
	if not _input_locked:
		sig.emit()


func _play_button_sound() -> void:
	if not _input_locked:
		AudioManager.play_ui_button_press()


func _on_tap(event: InputEvent) -> void:
	if _input_locked and event is InputEventMouseButton and event.pressed:
		skip_presentation()
		accept_event()


func _on_visibility_changed() -> void:
	if not visible:
		_kill_tweens()


## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): game.gd
## sets this once per level load to "MAIN MENU" or "LEVEL SELECT"
## depending on GameManager.entered_via_level_select, so the button's
## label always matches where level_select_pressed will actually
## navigate to - purely presentational, this popup still has no
## navigation logic of its own.
## The button is baked-in MAIN MENU art (no text), so only the tooltip tracks the real destination.
func set_navigation_label(text: String) -> void:
	_level_select_button.tooltip_text = text


## best_moves / target_moves < 0 show "--". level_number < 0 omits the subtitle and the progression row.
## era_transition (Era 2): true exactly once, the first time Level 100 is completed - banner only; changes no
## progression/unlock logic.
## hint_used shows the "max 2 stars" note (a Hint caps stars at 2 in StarScoring); show_stars=false hides the star
## row, badge and note (V3/Fusion QA sessions have no stars).
func show_result(moves_used: int, stars: int, has_next_level: bool, best_moves: int = -1, era_transition: bool = false, hint_used: bool = false, show_stars: bool = true, target_moves: int = -1, level_number: int = -1) -> void:
	_kill_tweens()
	_clear_fx()
	_final_moves = moves_used
	_earned = clampi(stars, 0, 3) if show_stars else 0
	_show_stars = show_stars
	_show_progress = level_number >= 0

	_subtitle.visible = level_number >= 0
	_subtitle.text = "LEVEL %d CLEARED" % level_number
	for i in _stars.size():
		_stars[i].modulate = Color.WHITE if i < _earned else UNEARNED_TINT
	_stars_holder.visible = show_stars
	_badge_holder.visible = show_stars
	_result_label.text = ["LEVEL CLEARED", "LEVEL CLEARED", "GREAT CLEAR!", "PERFECT CLEAR!"][_earned]
	_result_label.add_theme_color_override("font_color", Color(1, 0.83, 0.3) if _earned == 3 else Color(0.85, 0.95, 1))
	_result_sub_label.text = "%d STAR CLEAR" % maxi(_earned, 1)
	_hint_used_label.visible = hint_used and show_stars
	_era_transition_label.visible = era_transition
	_moves_label.text = str(moves_used)
	_target_label.text = str(target_moves) if target_moves >= 0 else "--"
	_best_moves_label.text = str(best_moves) if best_moves >= 0 else "--"
	if _show_progress:
		_to_label.visible = has_next_level
		_arrow_label.visible = has_next_level
		_from_label.text = "LEVEL %d" % level_number if has_next_level else "LEVEL %d COMPLETE" % level_number
		_to_label.text = "LEVEL %d" % (level_number + 1)
	_progress_row.visible = _show_progress
	_next_button.visible = has_next_level

	_input_locked = true
	_set_hidden_state()
	show()
	_play_entrance()


## Settles every cosmetic element and unlocks the buttons. Shared by tap-to-skip and tests.
func skip_presentation() -> void:
	if not _input_locked:
		return
	_kill_tweens()
	_clear_fx()
	_set_final_state()
	_input_locked = false


func is_input_locked() -> bool:
	return _input_locked


func _kill_tweens() -> void:
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()


func _clear_fx() -> void:
	for host in [_back_fx, _front_fx, _badge_fx]:
		for c in host.get_children():
			c.free()


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


func _action_buttons() -> Array[Button]:
	return [_next_button, _retry_button, _level_select_button]


func _set_hidden_state() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2.ONE * 0.94
	for i in _stars.size():
		var star := _stars[i]
		star.rotation = 0.0
		star.scale = Vector2.ONE * 0.1 if i < _earned else Vector2.ONE
		if i < _earned:
			star.modulate.a = 0.0
	_badge_holder.modulate.a = 0.0
	_badge_holder.scale = Vector2.ONE * 0.88
	_stats_holder.modulate.a = 0.0
	_moves_label.text = "0"
	_progress_row.modulate.a = 0.0
	_arrow_label.scale = Vector2.ONE
	_hint_used_label.modulate.a = 0.0
	_era_transition_label.modulate.a = 0.0
	for b in _action_buttons():
		b.modulate = Color(1, 1, 1, 0)
		b.scale = Vector2.ONE * 0.92
		b.disabled = true


func _set_final_state() -> void:
	_panel.modulate.a = 1.0
	_panel.scale = Vector2.ONE
	for i in _stars.size():
		_stars[i].scale = Vector2.ONE
		_stars[i].rotation = 0.0
		_stars[i].modulate = Color.WHITE if i < _earned else UNEARNED_TINT
	_badge_holder.modulate.a = 1.0
	_badge_holder.scale = Vector2.ONE
	_stats_holder.modulate.a = 1.0
	_moves_label.text = str(_final_moves)
	_progress_row.modulate.a = 1.0
	_arrow_label.scale = Vector2.ONE
	_hint_used_label.modulate.a = 1.0
	_era_transition_label.modulate.a = 1.0
	for b in _action_buttons():
		b.modulate = Color.WHITE
		b.scale = Vector2.ONE
		b.disabled = false


func _at(delay: float, fn: Callable) -> void:
	var tw := _tween()
	tw.tween_interval(delay)
	tw.tween_callback(fn)


func _play_entrance() -> void:
	AudioManager.play_ui_popup()
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var t := 0.3
	if _show_stars:
		for i in _earned:
			_at(STAR_LAND_TIMES[i], _reveal_star.bind(i))
		t = STAR_LAND_TIMES[maxi(_earned - 1, 0)] + 0.3
		if _earned == 3:
			_at(t - 0.05, _grand_finale)
			t += 0.1
		_at(t, _reveal_badge)
		t += 0.3
	_at(t, _reveal_stats)
	t += 0.2
	_at(t, _reveal_progress)
	t += 0.15
	for i in 3:
		_at(t + 0.1 * i, _reveal_button.bind(i))
	_at(t + 0.5, _unlock)


func _star_slot_center(i: int) -> Vector2:
	var slot: Control = _stars[i].get_parent().get_parent()
	return slot.position + slot.size * 0.5 + slot.get_parent().position


func _reveal_star(i: int) -> void:
	AudioManager.play_star_appear(1.0 + 0.12 * i)
	var star := _stars[i]
	star.rotation_degrees = -7.0
	star.modulate = BRIGHT_PULSE
	star.modulate.a = 0.0
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(star, "scale", Vector2.ONE * 1.22, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "rotation_degrees", 4.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "modulate:a", 1.0, 0.08)
	tw.chain().set_parallel(true)
	tw.tween_property(star, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(star, "rotation_degrees", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(star, "modulate", Color.WHITE, 0.22)
	var c := _star_slot_center(i)
	var radius := star.size.y * 0.5
	LevelCompleteFx.spawn(_back_fx, LevelCompleteFx.Kind.RING, c, radius, 0.32)
	LevelCompleteFx.spawn(_front_fx, LevelCompleteFx.Kind.SPARKS, c, radius, 0.36, Vector2.ZERO, 0.2 * i)


func _grand_finale() -> void:
	AudioManager.play_level_complete()
	for i in 3:
		var star := _stars[i]
		var tw := _tween()
		tw.tween_property(star, "scale", Vector2.ONE * 1.1, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(star, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		LevelCompleteFx.spawn(_front_fx, LevelCompleteFx.Kind.SPARKS, _star_slot_center(i), star.size.y * 0.62, 0.45, Vector2.ZERO, 0.5)
	LevelCompleteFx.spawn(_front_fx, LevelCompleteFx.Kind.SWEEP, Vector2.ZERO, 0.0, 0.5, _stars_holder.size)


func _reveal_badge() -> void:
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(_badge_holder, "modulate:a", 1.0, 0.18)
	tw.tween_property(_badge_holder, "scale", Vector2.ONE * 1.05, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(_badge_holder, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_hint_used_label, "modulate:a", 1.0, 0.25)
	tw.tween_property(_era_transition_label, "modulate:a", 1.0, 0.25)
	if _earned == 3:
		LevelCompleteFx.spawn(_badge_fx, LevelCompleteFx.Kind.SWEEP, Vector2.ZERO, 0.0, 0.5, _badge_holder.size)


func _reveal_stats() -> void:
	_hint_used_label.modulate.a = 1.0
	_era_transition_label.modulate.a = 1.0
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(_stats_holder, "modulate:a", 1.0, 0.2)
	tw.tween_method(func(v: float) -> void: _moves_label.text = str(roundi(v)), 0.0, float(_final_moves), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _reveal_progress() -> void:
	var tw := _tween()
	tw.tween_property(_progress_row, "modulate:a", 1.0, 0.2)
	if _arrow_label.visible:
		_arrow_label.pivot_offset = _arrow_label.size * 0.5
		tw.tween_property(_arrow_label, "scale", Vector2.ONE * 1.3, 0.1)
		tw.tween_property(_arrow_label, "scale", Vector2.ONE, 0.12)


func _reveal_button(i: int) -> void:
	var b := _action_buttons()[i]
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(b, "modulate:a", 1.0, 0.2)
	tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unlock() -> void:
	_input_locked = false
	for b in _action_buttons():
		b.disabled = false
	if _next_button.visible:
		var tw := _tween()
		tw.set_loops()
		tw.tween_interval(NEXT_PULSE_INTERVAL)
		tw.tween_property(_next_button, "modulate", Color(0.85, 1.12, 1.25), 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_next_button, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE)


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
