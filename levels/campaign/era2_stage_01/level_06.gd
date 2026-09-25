extends LevelData
## Campaign Level 106 — "Remote Signal". First campaign use of Beam
## Receiver / Remote Emitter as the primary mechanic: the main beam must
## be routed down to a receiver well away from the emitter, which wakes a
## second, independent beam elsewhere on the board that still needs its
## own routing to reach the final target.

func _init() -> void:
	level_id = 6
	display_name = "Remote Signal"
	stage = "Signal"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> mirror(4,0). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, beam exits the top boundary immediately since row 0 is the top edge, never reaching the receiver); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 4 down to beam_receiver(4,4), 4 rows below the mirror and 4 columns from the emitter - deliberately not adjacent to the source, per the brief. Powers link 'L106' for the NEXT simulation pass. remote_emitter(0,6) RIGHT WHITE link 'L106' only fires once the receiver has been powered - completely inert (and completely unreachable-looking) until then. Its beam -> mirror(4,6). Starts SLASH (WRONG, same top-edge-style miss reasoning, sends the beam UP into column 4, which happens to re-hit mirror(4,0) and bounce around harmlessly - confirmed no accidental target activation); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> to target(4,7) WHITE. optimal_moves=2 (both mirrors must be flipped) - AND the receiver must be powered first, or the remote emitter never fires at all regardless of mirror(4,6)'s orientation, so the two decisions have a real order dependency even though the solver just searches final states."
	is_campaign_level = true
	grid_width = 5
	grid_height = 8
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(4, 4), "L106"),
		TilePlacement.make_remote_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, "L106"),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 7), GridTypes.BeamColor.WHITE),
	]
