class_name TutorialHighlight
extends Control
## Reusable pulsing highlight overlay for the guided tutorial's forced-
## interaction/focus steps. Purely visual, owned and positioned by
## GridManager (set_highlight()/clear_highlight()) - mouse_filter is
## IGNORE so it never intercepts a tap meant for the tile underneath,
## and it draws an outline only (never a filled overlay) so the tile's
## own art stays fully visible.
##
## Sized FOCUS_PADDING larger than the tile on every side and drawn
## inside TutorialDimOverlay's matching transparent cutout (both read
## this same constant via GridManager._position_highlight(), so the
## ring and the cutout can never drift apart) - the ring reads clearly
## because it's drawn against full board brightness, not a dimmed
## background. See DECISIONS.md "Guided tutorial visual focus fix".

const HIGHLIGHT_COLOR := Color(0.35, 0.98, 1.0) # cyan-white - BeamShift's sci-fi accent
const PULSE_SPEED := 3.2
const MIN_ALPHA := 0.55
const MAX_ALPHA := 1.0
const BORDER_WIDTH := 6.0
## How much larger than the tile's own cell_size this ring (and the
## matching TutorialDimOverlay cutout) extends on every side.
const FOCUS_PADDING := 10.0

var cell_size: float = 64.0:
	set(value):
		cell_size = value
		size = Vector2(value, value) + Vector2(FOCUS_PADDING, FOCUS_PADDING) * 2.0
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var alpha: float = lerpf(MIN_ALPHA, MAX_ALPHA, (sin(t * PULSE_SPEED) + 1.0) * 0.5)
	var half_border := BORDER_WIDTH * 0.5
	var rect := Rect2(Vector2(half_border, half_border), size - Vector2(BORDER_WIDTH, BORDER_WIDTH))
	draw_rect(rect, Color(HIGHLIGHT_COLOR.r, HIGHLIGHT_COLOR.g, HIGHLIGHT_COLOR.b, alpha), false, BORDER_WIDTH)
