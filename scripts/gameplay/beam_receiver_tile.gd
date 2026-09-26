class_name BeamReceiverTile
extends TileVisual
## Beam Receiver visual (Era 2). Not player-interactive - only a laser
## triggers it, same interaction shape as SwitchTile. `active` is set by
## GridManager from LaserSystem's per-pass "activated_receiver_positions"
## result (true only while a beam is hitting it THIS evaluation - unlike
## Remote Emitter's `active`, which reflects the stabilized, persistent
## receiver_states dict). See ERA_2_DESIGN.md "Beam Receiver / Remote
## Emitter".

const RECEIVER_ACTIVE_TEXTURE := preload("res://assets/gameplay/beam_receiver/bs_tile_beam_receiver_base_era2.png")
const RECEIVER_INACTIVE_TEXTURE := preload("res://assets/gameplay/beam_receiver/bs_tile_beam_receiver_inactive_era2.png")

var active: bool = false:
	set(value):
		active = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var tex := RECEIVER_ACTIVE_TEXTURE if active else RECEIVER_INACTIVE_TEXTURE
	draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false)
