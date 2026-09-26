class_name FilterTile
extends TileVisual
## Placeholder filter visual. Recolors any beam passing through to
## output_color, unconditionally - see LaserSystem/DECISIONS.md ("Filter
## rule"). Not interactive; orientation doesn't matter (see Part 8 of the
## milestone brief).

var output_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE:
	set(value):
		output_color = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var color := GridTypes.beam_color_to_render_color(output_color)
	var margin := cell_size * 0.22
	var rect := Rect2(Vector2(margin, margin), Vector2(cell_size - margin * 2, cell_size - margin * 2))
	draw_rect(rect, color, false, 5.0)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.18), true)
