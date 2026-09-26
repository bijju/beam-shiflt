extends LevelData
## Campaign Level 112 — "Cross Signal". A single One-Way Reflector is
## genuinely reused by two different beams approaching from two
## different directions - Emitter A's beam (entering RIGHT, always
## reflective) and Remote Emitter B's beam (entering DOWN, whose
## reflect-vs-pass-through fate depends on the SAME orientation). One
## rotatable tile is a single point of failure for both signals.

func _init() -> void:
	level_id = 12
	display_name = "Cross Signal"
	stage = "Circuit"
	developer_notes = "DESIGN INTENT: emitter(0,3) RIGHT WHITE -> one_way_reflector(3,3), entering RIGHT (always reflective regardless of orientation). Starts SLASH (WRONG - bends UP, travels up column 3 through remote_emitter(3,0)'s own cell harmlessly (emitters are transparent to other beams) and exits the top boundary, never reaching the receiver); correct BACKSLASH -> bends DOWN -> column 3 down, clear, to beam_receiver(3,6), powering link 'L112A'. Beam A continues past the receiver (receivers don't stop beams) to mirror(3,7). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> to target(4,7) WHITE - deliberately NOT column 5, so beam B's own straight continuation down column 5 (past its own target at (5,5), since targets never stop a beam) can never also satisfy this one by accident. Separately, remote_emitter(3,0) DOWN WHITE link 'L112A' only fires once powered -> travels down column 3 through y1,2 into the SAME one_way_reflector(3,3), this time entering DOWN. Under the SAME BACKSLASH orientation beam A needs, DOWN is ALSO in the {RIGHT,DOWN} reflective pair -> reflects to RIGHT -> row 3 to mirror(5,3). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top harmlessly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 5 down to target(5,5) WHITE. The one_way_reflector is therefore a genuine shared directional resource: its single orientation gates BOTH whether the receiver ever powers (beam A) AND, once powered, whether the remote emitter's own beam bends correctly (beam B) - get it wrong and NEITHER of the two downstream mirrors' correctness matters, since nothing ever reaches them. optimal_moves=3 (the reflector and both mirrors must be flipped)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 8
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_one_way_reflector(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 6), "L112A"),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 7), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(3, 0), GridTypes.Direction.DOWN, "L112A"),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 5), GridTypes.BeamColor.WHITE),
	]
