class_name SafeAreaMargin
extends MarginContainer
## Outer safe-margin for a top-level screen: a baseline minimum padding on
## every platform, widened on Android by the real display safe-area inset
## (notches, camera cutouts, rounded corners, gesture-nav areas) when the
## OS reports one. See ARCHITECTURE.md ("Safe area handling") for the
## limits of this approach and why it's gated to Android specifically.

## -1.0 (default) uses UIConstants.BASELINE_MARGIN for BOTH axes,
## unchanged from before either field existed - every menu screen's
## SafeAreaMargin instance is untouched. A value >= 0.0 overrides that
## axis for THIS instance only. Split into two axes (Final Gameplay
## Spacing Refinement, see DECISIONS.md D87) because the gameplay screen
## needs a genuinely different vertical margin than horizontal - Top/
## Bottom HUD should sit close to the screen edge, while left/right
## board margin was explicitly asked to stay as Full-Screen Board
## Correction (D86) left it. See UIConstants.GAMEPLAY_HORIZONTAL_MARGIN/
## GAMEPLAY_VERTICAL_MARGIN. Real Android safe-area insets still widen
## whichever baseline is in effect via maxf() below on every side,
## independently - overriding either never reduces protection near a
## real notch/cutout.
@export var horizontal_margin_override: float = -1.0
@export var vertical_margin_override: float = -1.0


## HUD edge mode (HUD Edge Spacing pass, D103): the gameplay HUD art carries ~20% transparent padding above/below its
## visible plates, so game.gd reports how many px of each bar's height is padding (set_hud_overhang). The vertical
## margins then become  safe inset + gap - overhang  (possibly negative: only transparent art hangs past the
## margin), which puts the VISIBLE plate exactly `vertical_margin_override` px inside the real safe area. Off (both
## 0, the default) = every menu screen's behaviour is unchanged.
var _hud_overhang_top := 0.0
var _hud_overhang_bottom := 0.0


func set_hud_overhang(top: float, bottom: float) -> void:
	if is_equal_approx(top, _hud_overhang_top) and is_equal_approx(bottom, _hud_overhang_bottom):
		return
	_hud_overhang_top = top
	_hud_overhang_bottom = bottom
	if is_inside_tree():
		_update_margins()

## Normal rule: the stack may never rise past the safe edge (shift <= top visible gap). QA-ONLY experiment (D107, NOT a
## production rule): UIConstants.ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET lifts that cap in QA builds only.
func _max_stack_shift() -> float:
	if UIConstants.ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET and BuildConfig.QA_TOOLS:
		return 100000.0
	return UIConstants.GAMEPLAY_TOP_VISIBLE_GAP

func _ready() -> void:
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


func _update_margins() -> void:
	var horizontal := UIConstants.BASELINE_MARGIN if horizontal_margin_override < 0.0 else horizontal_margin_override
	var vertical := UIConstants.BASELINE_MARGIN if vertical_margin_override < 0.0 else vertical_margin_override
	var left := horizontal
	var right := horizontal
	var top := vertical
	var bottom := vertical

	if OS.get_name() == "Android":
		var insets := _get_android_safe_insets()
		left = maxf(left, insets.position.x)
		right = maxf(right, insets.size.x)
		if _hud_overhang_top > 0.0 or _hud_overhang_bottom > 0.0:
			top = insets.position.y + UIConstants.GAMEPLAY_TOP_VISIBLE_GAP
			bottom = insets.size.y + UIConstants.GAMEPLAY_BOTTOM_VISIBLE_GAP
		else:
			top = maxf(top, insets.position.y)
			bottom = maxf(bottom, insets.size.y)

	if _hud_overhang_top > 0.0 or _hud_overhang_bottom > 0.0:
		if OS.get_name() != "Android":
			top = UIConstants.GAMEPLAY_TOP_VISIBLE_GAP
			bottom = UIConstants.GAMEPLAY_BOTTOM_VISIBLE_GAP
	if _hud_overhang_top > 0.0 or _hud_overhang_bottom > 0.0:
		# Whole-stack shift (D106): top margin shrinks and bottom margin grows by the SAME amount, so the HUD/board/HUD
		# stack keeps its height and moves up as one unit. shift = manual bias + half the physical top/bottom gap
		# difference (asymmetric Android insets), clamped to [0, top visible gap] so the HUD never enters the safe area.
		var inset_top := top - UIConstants.GAMEPLAY_TOP_VISIBLE_GAP
		var inset_bottom := bottom - UIConstants.GAMEPLAY_BOTTOM_VISIBLE_GAP
		var physical_diff := (inset_top + UIConstants.GAMEPLAY_TOP_VISIBLE_GAP) - (inset_bottom + UIConstants.GAMEPLAY_BOTTOM_VISIBLE_GAP)
		var shift := clampf(-UIConstants.GAMEPLAY_STACK_VERTICAL_OFFSET + physical_diff * 0.5, 0.0, _max_stack_shift())
		top -= shift
		bottom += shift
	top -= _hud_overhang_top
	bottom -= _hud_overhang_bottom
	add_theme_constant_override("margin_left", int(left))
	add_theme_constant_override("margin_top", int(top))
	add_theme_constant_override("margin_right", int(right))
	add_theme_constant_override("margin_bottom", int(bottom))


## Returns left/top insets in .position and right/bottom insets in .size,
## converted from real device pixels into this screen's own UI coordinate
## space. All-zero Rect2 if the OS reports no usable safe-area data (this
## is the "robust fallback" - callers always still apply BASELINE_MARGIN).
func _get_android_safe_insets() -> Rect2:
	var real_screen_size: Vector2 = DisplayServer.screen_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()

	if real_screen_size.x <= 0.0 or real_screen_size.y <= 0.0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Rect2()

	# This screen's own visible size is expressed in this project's UI
	# coordinate space (not necessarily equal to real device pixels, since
	# the "canvas_items" stretch mode scales rendering to fit the real
	# screen while keeping layout math resolution-independent). Comparing
	# it against the real screen size gives the actual runtime conversion
	# factor without assuming how the stretch scale was computed.
	var our_visible_size: Vector2 = get_viewport().get_visible_rect().size
	var scale: float = our_visible_size.x / real_screen_size.x

	var left: float = safe_area.position.x * scale
	var top: float = safe_area.position.y * scale
	var right: float = (real_screen_size.x - safe_area.end.x) * scale
	var bottom: float = (real_screen_size.y - safe_area.end.y) * scale
	return Rect2(Vector2(left, top), Vector2(right, bottom))
