class_name TutorialDimOverlay
extends Control
## Guided-tutorial-only board dim. Owned and shown/hidden by GridManager
## in lockstep with TutorialHighlight (set_highlight()/clear_highlight()
## are the only callers - see DECISIONS.md "Guided tutorial visual focus
## fix"), so dim state can never outlive or precede the highlight it
## exists to support.
##
## Draws a semi-transparent dim over the whole board EXCEPT a cutout
## rect around the currently-highlighted tile, left fully transparent so
## that tile stays at full board brightness. A flat full-screen dim
## would darken the very tile the player is meant to look at, which is
## exactly the "highlighted mirror is also darkened" bug this fixes.

const DIM_ALPHA := 0.52
const DIM_COLOR := Color(0, 0, 0, DIM_ALPHA)

var _cutout: Rect2 = Rect2()
var _has_cutout: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `rect` must be in this node's own local coordinate space (GridManager
## passes the same rect it positions TutorialHighlight at - see
## _position_highlight()), so the transparent hole and the pulsing ring
## drawn on top of it always align exactly.
func set_cutout(rect: Rect2) -> void:
	_cutout = rect
	_has_cutout = true
	queue_redraw()


func clear_cutout() -> void:
	_has_cutout = false
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if not _has_cutout:
		draw_rect(Rect2(Vector2.ZERO, size), DIM_COLOR)
		return
	var r := _cutout
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(size.x, r.position.y)), DIM_COLOR) # above cutout
	draw_rect(Rect2(Vector2(0.0, r.position.y + r.size.y), Vector2(size.x, size.y - r.position.y - r.size.y)), DIM_COLOR) # below cutout
	draw_rect(Rect2(Vector2(0.0, r.position.y), Vector2(r.position.x, r.size.y)), DIM_COLOR) # left of cutout
	draw_rect(Rect2(Vector2(r.position.x + r.size.x, r.position.y), Vector2(size.x - r.position.x - r.size.x, r.size.y)), DIM_COLOR) # right of cutout
