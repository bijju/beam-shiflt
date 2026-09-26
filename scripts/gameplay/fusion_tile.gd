class_name FusionTile
extends TileVisual
## Beam Fusion Node visual (Fusion Phase 1, D99). PURELY presentational: LaserSystem decides
## whether the node is active, which colours reached it and what it emits; GridManager copies
## that result onto `active` / `fused_color` / `input_sides` after every simulation. Never
## latches - it shows exactly the current stable state.
##
## The supplied art (bs_fusion_node*.png, used unmodified, scaled in code) is four-way
## symmetric, so it carries no direction. Direction is therefore drawn dynamically: a bright
## arrowhead on the OUTPUT side (in the fused colour while active, cyan when idle) and small
## port ticks on the three input sides (lit in a beam's colour while that input receives one;
## the output side accepts nothing). The node's own texture stays cyan (unified theme) - only
## the outgoing beam carries the fused colour.
##
## Interaction is the standard tap-to-rotate (one tap = one move, clockwise, 4 states); the
## `orientation` property holds the OUTPUT GridTypes.Direction so GridManager's shared restore
## path works unchanged.

signal tile_clicked(grid_position: Vector2i)

const TEXTURE_INACTIVE := preload("res://assets/gameplay/fusion/bs_fusion_node.png")
const TEXTURE_ACTIVE := preload("res://assets/gameplay/fusion/bs_fusion_node_active.png")
const LOCK_ICON_TEXTURE := preload("res://assets/ui/icons/bs_ui_icon_lock_runtime.png")

const INSET := 0.02 # fraction of the cell left empty on every side
const COLOR_IDLE := Color(0.35, 0.98, 1.0)
const TINT_FIXED := Color(0.72, 0.72, 0.76, 1)

## Output direction (GridTypes.Direction).
var orientation: int = GridTypes.Direction.RIGHT:
	set(value):
		orientation = value
		queue_redraw()

var rotatable: bool = true:
	set(value):
		rotatable = value
		queue_redraw()

var active: bool = false:
	set(value):
		if value != active:
			active = value
			queue_redraw()

## The fused colour being emitted (-1 while inactive).
var fused_color: int = -1:
	set(value):
		fused_color = value
		queue_redraw()

## incoming side (Direction) -> Array of BeamColor currently received there.
var input_sides: Dictionary = {}:
	set(value):
		input_sides = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var s := cell_size
	var inset := s * INSET
	var tint := Color.WHITE if rotatable else TINT_FIXED
	draw_texture_rect(TEXTURE_ACTIVE if active else TEXTURE_INACTIVE, Rect2(Vector2(inset, inset), Vector2(s - inset * 2.0, s - inset * 2.0)), false, tint)
	_draw_ports()
	if not rotatable:
		var lock_size := s * 0.26
		draw_texture_rect(LOCK_ICON_TEXTURE, Rect2(Vector2(s, s) - Vector2(lock_size, lock_size) * 1.05, Vector2(lock_size, lock_size)), false)


func _edge_point(dir: int, out_by: float) -> Vector2:
	var s := cell_size
	var c := Vector2(s, s) * 0.5
	var v := Vector2(GridTypes.direction_vector(dir))
	return c + v * (s * 0.5 - out_by)


func _draw_ports() -> void:
	var s := cell_size
	for dir in [GridTypes.Direction.UP, GridTypes.Direction.RIGHT, GridTypes.Direction.DOWN, GridTypes.Direction.LEFT]:
		var v := Vector2(GridTypes.direction_vector(dir))
		var perp := Vector2(-v.y, v.x)
		if dir == orientation:
			var col: Color = GridTypes.beam_color_to_render_color(fused_color) if active and fused_color >= 0 else COLOR_IDLE
			col.a = 1.0 if active else 0.55
			var base := _edge_point(dir, s * 0.09)
			var tip := _edge_point(dir, s * -0.0)
			draw_polygon(PackedVector2Array([base - perp * s * 0.11, base + perp * s * 0.11, tip]), PackedColorArray([col, col, col]))
		else:
			var colors: Array = input_sides.get(dir, [])
			if colors.is_empty():
				continue
			# One lit dot per distinct colour received on this side (normally one).
			var i := 0
			for c in colors:
				var p := _edge_point(dir, s * 0.06) + perp * (float(i) - float(colors.size() - 1) * 0.5) * s * 0.12
				draw_circle(p, s * 0.045, GridTypes.beam_color_to_render_color(c))
				i += 1


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not rotatable:
		accept_event()
		AudioManager.play_mirror_locked()
		return
	accept_event()
	tile_clicked.emit(grid_position)
