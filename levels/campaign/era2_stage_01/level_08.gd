extends LevelData
## Campaign Level 108 — "Refracted Signal". First strong multi-system Era 2
## puzzle: one Prism branch activates a Receiver directly (no routing
## needed), a second Prism branch has its own independent target, and the
## Receiver's Remote Emitter opens a third, completely separate chain.

func _init() -> void:
	level_id = 8
	display_name = "Refracted Signal"
	stage = "Signal"
	developer_notes = "DESIGN INTENT: emitter(0,3) RIGHT WHITE -> prism(3,3). RED channel straight -> target(6,3) RED, free arrival, independent of everything else. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, straight into beam_receiver(3,0) - hit directly, no mirror needed, powers link 'L108'. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,6). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 6 to target(6,6) BLUE. Separately, remote_emitter(0,8) RIGHT WHITE link 'L108' only fires once the GREEN channel has powered the receiver -> row 8 to mirror(3,8). Starts BACKSLASH (WRONG - reflect(RIGHT,BACKSLASH)=DOWN, exits the bottom edge); correct SLASH -> reflect(RIGHT,SLASH)=UP -> column 3 up to target(3,7) WHITE, just above the remote emitter's own row. optimal_moves=2 (mirror(3,6) and mirror(3,8) both must be flipped) - the Receiver/Remote Emitter dependency itself costs no moves (GREEN always powers it), so the real puzzle is the two independent mirror decisions plus recognizing the third target only exists because of the Prism->Receiver link."
	is_campaign_level = true
	grid_width = 7
	grid_height = 9
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 3)),
		TilePlacement.make_target(Vector2i(6, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_beam_receiver(Vector2i(3, 0), "L108"),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_remote_emitter(Vector2i(0, 8), GridTypes.Direction.RIGHT, "L108"),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(3, 7), GridTypes.BeamColor.WHITE),
	]
