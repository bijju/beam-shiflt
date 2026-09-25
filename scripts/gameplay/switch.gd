class_name SwitchTile
extends TileVisual
## Placeholder switch visual. Activates (visually only - GridManager sets
## this after each simulate call) when a beam passes over it this
## evaluation. Not interactive by the player; only a laser triggers it.

var activated: bool = false:
	set(value):
		activated = value
		queue_redraw()

const COLOR_INACTIVE := Color(0.5, 0.45, 0.2)
const COLOR_ACTIVE := Color(1.0, 0.85, 0.3)


func _draw() -> void:
	super._draw()
	var color := COLOR_ACTIVE if activated else COLOR_INACTIVE
	var center := Vector2(cell_size, cell_size) * 0.5
	var r := cell_size * 0.26
	var points := PackedVector2Array([
		center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0, 0, 0, 0.35), 2.0, true)
