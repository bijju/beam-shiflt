class_name SplitterSelectorTile
extends TileVisual
## Splitter Selector visual (Selector Phase S1). PURELY presentational: LaserSystem decides which
## beams reach the node and where they leave; GridManager copies `active`/`routed_color` onto this
## tile after every simulation. Never latches - it shows exactly the current stable state.
##
## The supplied art (used unmodified, scaled/rotated in code) carries a centre triangle that points
## UP in the source image, so rotating the whole texture by `orientation` makes that triangle the
## selected OUTPUT direction. Interaction is the standard tap-to-rotate: one tap = one move, one
## clockwise quarter-turn, 4 states. `orientation` holds the OUTPUT GridTypes.Direction so
## GridManager's shared restore path works unchanged.

signal tile_clicked(grid_position: Vector2i)

const TEXTURE_INACTIVE := preload("res://assets/gameplay/splitter_selector/bs_splitter_selector.png")
const TEXTURE_ACTIVE := preload("res://assets/gameplay/splitter_selector/bs_splitter_selector_active.png")
const LOCK_ICON_TEXTURE := preload("res://assets/ui/icons/bs_ui_icon_lock_runtime.png")

const INSET := 0.04 # fraction of the cell left empty on every side
const TINT_FIXED := Color(0.72, 0.72, 0.76, 1)

## Selected output direction (GridTypes.Direction).
var orientation: int = GridTypes.Direction.UP:
	set(value):
		orientation = value
		queue_redraw()

var rotatable: bool = true:
	set(value):
		rotatable = value
		queue_redraw()

## True while a beam is being routed through the node this simulation.
var active: bool = false:
	set(value):
		if value != active:
			active = value
			queue_redraw()

## Colour of the routed beam (-1 while inactive); drawn as the output-side arrowhead.
var routed_color: int = -1:
	set(value):
		routed_color = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var s := cell_size
	var inset := s * INSET
	var tint := Color.WHITE if rotatable else TINT_FIXED
	var tex := TEXTURE_ACTIVE if active else TEXTURE_INACTIVE
	var half := (s - inset * 2.0) * 0.5
	draw_set_transform(Vector2(s, s) * 0.5, float(orientation) * PI * 0.5, Vector2.ONE)
	draw_texture_rect(tex, Rect2(Vector2(-half, -half), Vector2(half, half) * 2.0), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if active and routed_color >= 0:
		_draw_output_arrow()
	if not rotatable:
		var lock_size := s * 0.26
		draw_texture_rect(LOCK_ICON_TEXTURE, Rect2(Vector2(s, s) - Vector2(lock_size, lock_size) * 1.05, Vector2(lock_size, lock_size)), false)


func _draw_output_arrow() -> void:
	var s := cell_size
	var v := Vector2(GridTypes.direction_vector(orientation))
	var perp := Vector2(-v.y, v.x)
	var c := Vector2(s, s) * 0.5
	var col: Color = GridTypes.beam_color_to_render_color(routed_color)
	var base := c + v * (s * 0.40)
	var tip := c + v * (s * 0.50)
	draw_polygon(PackedVector2Array([base - perp * s * 0.10, base + perp * s * 0.10, tip]), PackedColorArray([col, col, col]))


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not rotatable:
		accept_event()
		AudioManager.play_mirror_locked()
		return
	accept_event()
	tile_clicked.emit(grid_position)
