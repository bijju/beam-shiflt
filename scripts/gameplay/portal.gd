class_name PortalTile
extends TileVisual
## Placeholder portal visual. Two portals sharing pair_id teleport a beam
## between them, preserving direction and color - see LaserSystem/
## DECISIONS.md ("Portal direction behavior"). Not interactive.

var pair_id: String = "":
	set(value):
		pair_id = value
		queue_redraw()

const COLOR_RING := Color(0.75, 0.35, 1.0)

## Subtle idle pulse (Milestone 4A interaction feedback) - a single phase
## accumulator driving a low-cost sine-wave alpha wobble on the ring, since
## the portal stays procedurally drawn (see ARCHITECTURE.md). Cheap enough
## per-portal (a level has at most a handful) to leave running continuously.
var _pulse_phase: float = 0.0


func _process(delta: float) -> void:
	_pulse_phase = fmod(_pulse_phase + delta, TAU)
	queue_redraw()


func _draw() -> void:
	super._draw()
	var center := Vector2(cell_size, cell_size) * 0.5
	var pulse := 0.5 + 0.5 * sin(_pulse_phase * 2.0)
	draw_arc(center, cell_size * (0.30 + pulse * 0.03), 0, TAU, 28, COLOR_RING, 5.0, true)
	draw_arc(center, cell_size * 0.2, 0, TAU, 20, Color(COLOR_RING.r, COLOR_RING.g, COLOR_RING.b, 0.3 + pulse * 0.3), 3.0, true)

	if pair_id != "":
		var font := get_theme_default_font()
		var font_size := int(cell_size * 0.22)
		var label := pair_id.left(2)
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, COLOR_RING)
