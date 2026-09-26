class_name SplitterTile
extends TileVisual
## Rotatable/fixed splitter tile. Same tap-to-rotate interaction shape as
## MirrorTile, but a distinct class - splitter behavior (straight-through
## + a reflected branch) lives entirely in LaserSystem, never in this
## visual. See DECISIONS.md ("Splitter rule").

signal tile_clicked(grid_position: Vector2i)

var orientation: GridTypes.MirrorOrientation = GridTypes.MirrorOrientation.SLASH:
	set(value):
		orientation = value
		queue_redraw()

var rotatable: bool = true:
	set(value):
		rotatable = value
		queue_redraw()

const COLOR_ROTATABLE := Color(1.0, 0.7, 0.25)
const COLOR_FIXED := Color(0.6, 0.5, 0.35)


func _draw() -> void:
	super._draw()
	var color := COLOR_ROTATABLE if rotatable else COLOR_FIXED
	var center := Vector2(cell_size, cell_size) * 0.5
	var margin := cell_size * 0.2

	# Straight-through line, full diagonal length like a mirror.
	var p1: Vector2
	var p2: Vector2
	if orientation == GridTypes.MirrorOrientation.SLASH:
		p1 = Vector2(margin, cell_size - margin)
		p2 = Vector2(cell_size - margin, margin)
	else:
		p1 = Vector2(margin, margin)
		p2 = Vector2(cell_size - margin, cell_size - margin)
	draw_line(p1, p2, color, 4.0, true)

	# A short branch stub from the center, perpendicular-ish, to signal
	# "this tile also spawns a second beam" distinct from a plain mirror.
	var branch_end := center + (p1 - center).normalized() * (cell_size * 0.18)
	draw_line(center, branch_end, color, 6.0, true)
	draw_circle(center, cell_size * 0.07, color)

	if not rotatable:
		draw_circle(Vector2(cell_size * 0.5, cell_size * 0.5), cell_size * 0.06, Color(0.9, 0.2, 0.2))


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not rotatable:
		accept_event()
		AudioManager.play_mirror_locked()
		return
	accept_event()
	tile_clicked.emit(grid_position)
