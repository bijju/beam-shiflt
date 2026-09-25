class_name GateTile
extends TileVisual
## Gate visual. is_open is set by GridManager after each simulate call,
## derived from the stabilized switch/gate state - a gate has no
## independent persistent state of its own beyond level data's
## initial_open_state (see DECISIONS.md "Switch/gate simulation
## strategy"). A closed gate blocks the beam like a blocker; an open gate
## passes it through. Milestone 4A: swaps between the final closed/open
## gate art (a matched, beam-free pair) instead of drawing bars.

const GATE_CLOSED_TEXTURE := preload("res://assets/gameplay/gate/bs_tile_gate_closed_runtime.png")
const GATE_OPEN_TEXTURE := preload("res://assets/gameplay/gate/bs_tile_gate_open_runtime.png")

var is_open: bool = false:
	set(value):
		is_open = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var tex := GATE_OPEN_TEXTURE if is_open else GATE_CLOSED_TEXTURE
	draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false)
