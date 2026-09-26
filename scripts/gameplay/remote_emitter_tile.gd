class_name RemoteEmitterTile
extends TileVisual
## Remote Emitter visual (Era 2). Not player-interactive. `active` is set
## by GridManager from LaserSystem's stabilized "receiver_states" dict,
## looked up by this tile's own link_id - true only once its linked Beam
## Receiver(s) have been powered (see ERA_2_DESIGN.md "Beam Receiver /
## Remote Emitter"). Direction/beam_color are drawn procedurally (same
## technique as EmitterTile's arrow) on top of the base/inactive body art
## so real per-level direction/color data is never misrepresented by a
## texture rotation guess - see CLAUDE.md rule 10.

const REMOTE_EMITTER_ACTIVE_TEXTURE := preload("res://assets/gameplay/remote_emitter/bs_tile_remote_emitter_base_era2.png")
const REMOTE_EMITTER_INACTIVE_TEXTURE := preload("res://assets/gameplay/remote_emitter/bs_tile_remote_emitter_inactive_era2.png")

var active: bool = false:
	set(value):
		active = value
		queue_redraw()

var direction: GridTypes.Direction = GridTypes.Direction.UP:
	set(value):
		direction = value
		queue_redraw()

var beam_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE:
	set(value):
		beam_color = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var tex := REMOTE_EMITTER_ACTIVE_TEXTURE if active else REMOTE_EMITTER_INACTIVE_TEXTURE
	draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false)

	if not active:
		return

	var arrow_color := GridTypes.beam_color_to_render_color(beam_color)
	var center := Vector2(cell_size, cell_size) * 0.5
	var angle := GridTypes.direction_to_angle(direction)
	var tip := center + Vector2(cos(angle), sin(angle)) * (cell_size * 0.46)
	var left := center + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * (cell_size * 0.2)
	var right := center + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * (cell_size * 0.2)
	draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([arrow_color, arrow_color, arrow_color]))
