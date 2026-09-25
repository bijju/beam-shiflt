extends LevelData
## Campaign Level 119 — "Refraction Relay". One Prism branch (GREEN)
## activates a Receiver directly; a second branch (BLUE) is routed to
## its own independent target AND trips a switch along the way; the
## Remote Emitter's own beam, arriving through a Portal, depends on
## that same switch's gate before it can reach its own target.

func _init() -> void:
	level_id = 19
	display_name = "Refraction Relay"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> mirror(5,4). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top harmlessly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 5 down, clear, to target(5,7) RED - a fully independent objective. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, straight into beam_receiver(3,1) - hit directly, no mirror needed, powers link 'L119'. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,6). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 6 through switch(6,6), gate_id 'GY119' (doesn't stop the beam) -> mirror(7,6). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top harmlessly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 7 down to target(7,7) BLUE - BLUE's own independent objective, on top of having tripped the switch along the way. Separately, remote_emitter(0,8) RIGHT WHITE link 'L119' only fires once GREEN has powered the receiver -> row 8 to portal(2,8), pair 'RP119' -> teleports to partner (6,2), direction preserved (RIGHT) -> row 2 to gate(7,2), gate_id 'GY119' - the SAME gate_id BLUE's switch opens, a shared resource between two completely different Prism branches. If open, continue to mirror(8,2). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits the top boundary instantly, nothing there); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 8 down, clear, to target(8,4) WHITE. optimal_moves=4 (mirror(5,4), mirror(3,6), mirror(7,6), mirror(8,2) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 9
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.RED),

		TilePlacement.make_beam_receiver(Vector2i(3, 1), "L119"),

		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 6), "GY119"),
		TilePlacement.make_mirror(Vector2i(7, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 7), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(0, 8), GridTypes.Direction.RIGHT, "L119"),
		TilePlacement.make_portal(Vector2i(2, 8), "RP119"),
		TilePlacement.make_portal(Vector2i(6, 2), "RP119"),
		TilePlacement.make_gate(Vector2i(7, 2), "GY119", false),
		TilePlacement.make_mirror(Vector2i(8, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.WHITE),
	]
