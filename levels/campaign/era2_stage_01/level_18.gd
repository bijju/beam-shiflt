extends LevelData
## Campaign Level 118 — "Remote Crossing". Two independent sources each
## power their own Receiver, but their two Remote Emitters' beams
## physically cross through ONE shared gate cell from perpendicular
## directions - genuinely interdependent, not two separate mini-puzzles.

func _init() -> void:
	level_id = 18
	display_name = "Remote Crossing"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter A(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top instantly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to beam_receiver(3,2), powering link 'LA118'. emitter B(0,9) RIGHT WHITE -> mirror(5,9) - deliberately column 5, not column 3, so emitter A's own beam (which continues straight down column 3 for the rest of the board after bouncing off mirror(3,0), since receivers don't stop a beam) can never also power receiver B by accident. Starts BACKSLASH (WRONG - reflect(RIGHT,BACKSLASH)=DOWN, row 9 is the bottom edge, exits instantly); correct SLASH -> reflect(RIGHT,SLASH)=UP -> column 5 up to beam_receiver(5,7), powering link 'LB118'. remote_emitter A(6,0) DOWN WHITE link 'LA118' -> column 6 down through switch(6,3), gate_id 'GX118' (doesn't stop the beam) -> continues to gate(6,4), gate_id 'GX118' - THIS IS THE SHARED CELL: it sits exactly where remote emitter A's vertical column crosses remote emitter B's horizontal row. On the pass remote emitter A first reaches it, the switch it just tripped one cell earlier hasn't taken effect yet (same convergence delay as every switch/gate pair in this project); it opens the NEXT pass and both beams pass through it in every pass after that. Past the gate, remote A continues to mirror(6,6). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> to target(8,6) WHITE. remote_emitter B(8,4) LEFT WHITE link 'LB118' -> row 4 leftward through x7 into the SAME gate(6,4) - if it isn't open yet (remote emitter A hasn't been resolved), remote B's beam simply stops there, even though remote B's OWN receiver/mirror chain was solved correctly - the two remotes genuinely depend on each other, not just their own halves. Past the gate, continues to mirror(2,4). Starts SLASH (WRONG - reflect(LEFT,SLASH)=DOWN, harmless miss); correct BACKSLASH -> reflect(LEFT,BACKSLASH)=UP -> column 2 up, clear, to target(2,1) WHITE. optimal_moves=4 (mirror(3,0), mirror(5,9), mirror(6,6), mirror(2,4) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "LA118"),

		TilePlacement.make_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(5, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_beam_receiver(Vector2i(5, 7), "LB118"),

		TilePlacement.make_remote_emitter(Vector2i(6, 0), GridTypes.Direction.DOWN, "LA118"),
		TilePlacement.make_switch(Vector2i(6, 3), "GX118"),
		TilePlacement.make_gate(Vector2i(6, 4), "GX118", false),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 6), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(8, 4), GridTypes.Direction.LEFT, "LB118"),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 1), GridTypes.BeamColor.WHITE),
	]
