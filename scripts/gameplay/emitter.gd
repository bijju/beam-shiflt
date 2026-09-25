class_name EmitterTile
extends TileVisual
## Placeholder emitter visual. Direction and beam color come from level
## data and are not player-rotatable.

var direction: GridTypes.Direction = GridTypes.Direction.UP:
	set(value):
		direction = value
		queue_redraw()

## WHITE (the Milestone 1 default) keeps the original warm-orange body
## color so existing levels render unchanged; RED/GREEN/BLUE emitters use
## GridTypes' color mapping so the player can see which beam color they fire.
var beam_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE:
	set(value):
		beam_color = value
		queue_redraw()

const COLOR_BODY_DEFAULT := Color(1.0, 0.55, 0.15)


func _draw() -> void:
	super._draw()
	var body_color := COLOR_BODY_DEFAULT if beam_color == GridTypes.BeamColor.WHITE else GridTypes.beam_color_to_render_color(beam_color)
	var center := Vector2(cell_size, cell_size) * 0.5
	var radius := cell_size * 0.28
	draw_circle(center, radius, body_color)

	var angle := GridTypes.direction_to_angle(direction)
	var tip := center + Vector2(cos(angle), sin(angle)) * (cell_size * 0.42)
	var left := center + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * (cell_size * 0.22)
	var right := center + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * (cell_size * 0.22)
	draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([body_color, body_color, body_color]))
