class_name OneWayReflectorTile
extends TileVisual
## One-Way Reflector visual (Era 2). Rotatable via the identical tap-to-
## rotate interaction as MirrorTile/SplitterTile (same tile_clicked signal,
## same GridManager._on_orientable_tile_clicked() handler, same
## GridTypes.MirrorOrientation field) - see ERA_2_DESIGN.md "One-Way
## Reflector" and GridTypes.one_way_reflector_is_reflective().
##
## Visual design deliberately does not rely on color alone (spec
## requirement): the wedge-shaped "_base" source art (asymmetric, unlike
## Mirror's symmetric diagonal bar) rotates with orientation exactly like
## Mirror's texture does, AND two small bright chevrons are drawn on the
## two cell edges a beam must enter from to actually be reflected
## (derived directly from one_way_reflector_is_reflective() - always
## correct, never guessed from the art) with the other two edges left
## dim - see _reflective_entry_edges().

signal tile_clicked(grid_position: Vector2i)

const REFLECTOR_TEXTURE := preload("res://assets/gameplay/one_way_reflector/bs_tile_one_way_reflector_base_era2.png")
const LOCK_ICON_TEXTURE := preload("res://assets/ui/icons/bs_ui_icon_lock_runtime.png")

const COLOR_REFLECTIVE_EDGE := Color(0.75, 0.4, 1.0, 0.95)
const COLOR_PASSTHROUGH_EDGE := Color(0.75, 0.4, 1.0, 0.18)
const TINT_ROTATABLE := Color(1, 1, 1, 1)
const TINT_FIXED := Color(0.72, 0.72, 0.76, 1)

var orientation: GridTypes.MirrorOrientation = GridTypes.MirrorOrientation.SLASH:
	set(value):
		orientation = value
		queue_redraw()

var rotatable: bool = true:
	set(value):
		rotatable = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var half := Vector2(cell_size, cell_size) * 0.5
	var angle := 0.0 if orientation == GridTypes.MirrorOrientation.SLASH else PI * 0.5
	draw_set_transform(half, angle, Vector2.ONE)
	var tint := TINT_ROTATABLE if rotatable else TINT_FIXED
	draw_texture_rect(REFLECTOR_TEXTURE, Rect2(-half, Vector2(cell_size, cell_size)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_edge_indicators()

	if not rotatable:
		var lock_size := cell_size * 0.3
		var lock_pos := Vector2(cell_size, cell_size) - lock_size * Vector2(1.05, 1.05)
		draw_texture_rect(LOCK_ICON_TEXTURE, Rect2(lock_pos, Vector2(lock_size, lock_size)), false)


## Draws a short bright chevron pointing INTO the cell on each edge a
## beam must enter from to be reflected, and a dim flat tick on each edge
## that passes straight through - shape/position-based, not color-only.
func _draw_edge_indicators() -> void:
	for dir in [GridTypes.Direction.UP, GridTypes.Direction.RIGHT, GridTypes.Direction.DOWN, GridTypes.Direction.LEFT]:
		var reflective: bool = GridTypes.one_way_reflector_is_reflective(dir, orientation)
		var entry_edge_dir := _opposite_direction(dir)
		var edge_center := _edge_midpoint(entry_edge_dir)
		var inward := (Vector2(cell_size, cell_size) * 0.5 - edge_center).normalized()
		var perpendicular := Vector2(-inward.y, inward.x)
		if reflective:
			var tip := edge_center + inward * (cell_size * 0.16)
			var side := perpendicular * (cell_size * 0.07)
			draw_polygon(PackedVector2Array([edge_center - side, edge_center + side, tip]), PackedColorArray([COLOR_REFLECTIVE_EDGE, COLOR_REFLECTIVE_EDGE, COLOR_REFLECTIVE_EDGE]))
		else:
			var side2 := perpendicular * (cell_size * 0.09)
			draw_line(edge_center - side2, edge_center + side2, COLOR_PASSTHROUGH_EDGE, 3.0)


func _opposite_direction(dir: GridTypes.Direction) -> GridTypes.Direction:
	match dir:
		GridTypes.Direction.UP:
			return GridTypes.Direction.DOWN
		GridTypes.Direction.DOWN:
			return GridTypes.Direction.UP
		GridTypes.Direction.LEFT:
			return GridTypes.Direction.RIGHT
	return GridTypes.Direction.LEFT


func _edge_midpoint(edge_dir: GridTypes.Direction) -> Vector2:
	var s := cell_size
	match edge_dir:
		GridTypes.Direction.UP:
			return Vector2(s * 0.5, 0.0)
		GridTypes.Direction.RIGHT:
			return Vector2(s, s * 0.5)
		GridTypes.Direction.DOWN:
			return Vector2(s * 0.5, s)
	return Vector2(0.0, s * 0.5)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not rotatable:
		accept_event()
		AudioManager.play_mirror_locked()
		return
	accept_event()
	tile_clicked.emit(grid_position)
