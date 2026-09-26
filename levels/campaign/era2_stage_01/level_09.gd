extends LevelData
## Campaign Level 109 — "Directional Chain". A full dependency chain not
## obvious from the initial board state: Emitter -> One-Way Reflector ->
## Receiver -> Remote Emitter -> Switch -> Gate -> final target. Only one
## tile is rotatable, but nothing downstream even exists (visibly or
## logically) until it is set correctly.

func _init() -> void:
	level_id = 9
	display_name = "Directional Chain"
	stage = "Signal"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> one_way_reflector(3,0) entering RIGHT (always reflective). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, and row 0 is the top edge, so the beam exits instantly and the whole chain below never starts); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down, clear, to beam_receiver(3,3). Powers link 'L109' for the next pass. remote_emitter(0,5) RIGHT WHITE link 'L109' only fires once powered -> row 5 to switch(3,5) gate_id 'G109' (doesn't stop the beam) -> continues to gate(4,5) gate_id 'G109', starts closed. On the pass where the remote emitter first fires, the gate is still closed from the switch's own trip that same pass (gate state only updates for the NEXT pass, same convergence strategy as every switch/gate pair in this project) - simulate_until_stable() re-runs until it settles, and once both the receiver and gate have converged the beam passes straight through to target(6,5) WHITE. optimal_moves=1 (only the reflector is rotatable) - the puzzle is entirely about following the chain through five different mechanics in sequence, not about move count; nothing past the reflector is visible as 'active' until it's set correctly."
	is_campaign_level = true
	grid_width = 7
	grid_height = 6
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_one_way_reflector(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 3), "L109"),
		TilePlacement.make_remote_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, "L109"),
		TilePlacement.make_switch(Vector2i(3, 5), "G109"),
		TilePlacement.make_gate(Vector2i(4, 5), "G109", false),
		TilePlacement.make_target(Vector2i(6, 5), GridTypes.BeamColor.WHITE),
	]
