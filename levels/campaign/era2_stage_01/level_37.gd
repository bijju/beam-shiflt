extends LevelData
## Campaign Level 137 — "Three-Way Refraction". All three Prism channels
## are meaningfully different: RED reaches its own colored objective via
## one mirror, GREEN directly activates a Receiver, and BLUE hits a
## Splitter creating two genuinely required routes - one of which is
## gated by the Remote Emitter's own switch, resolving a dependency that
## affects BLUE specifically, not a decorative fourth branch.

func _init() -> void:
	level_id = 37
	display_name = "Three-Way Refraction"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> mirror(5,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> column 5 down, clear, to target(5,7) RED - RED's own colored objective. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, straight into beam_receiver(3,1) - hit directly, powers link 'TW137'. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to splitter(3,6) (FIXED, SLASH, non-rotatable) - two genuinely required routes, not a decorative decoy. Reflected branch (reflect(DOWN,SLASH)=LEFT) -> row 6 to mirror(1,6). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> reflect(LEFT,BACKSLASH)=UP -> column 1 up, clear, to target(1,1) BLUE. Straight-continuing branch (unchanged, DOWN) -> mirror(3,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> row 8 to gate(5,8), gate_id 'TW137G' - closed until the Remote Emitter's own switch trips it. If open, continue to target(6,8) BLUE, the splitter's second required objective - then CONTINUES (targets never stop a beam) to (7,8), one cell further right. remote_emitter(0,9) RIGHT, color RED (deliberately not the WHITE default), link 'TW137' only fires once GREEN has powered the Receiver -> row 9 through switch(3,9), gate_id 'TW137G' (trips the gate on BLUE's straight-branch route - resolving a dependency that affects BLUE specifically, not a fourth decorative branch) -> continues to mirror(7,9). Starts BACKSLASH (WRONG - reflect(RIGHT,BACKSLASH)=DOWN, and row 9 is the bottom edge, exits instantly); correct SLASH -> reflect(RIGHT,SLASH)=UP -> column 7 up, clear, to target(7,8), requires RED, the Remote Emitter's own objective. The explicit RED (not WHITE) is load-bearing: BLUE's own straight-branch beam physically continues into this exact cell after activating target(6,8) - a first draft left this target at the make_target() default WHITE, which accepts any color, so BLUE's own continuation satisfied it for free regardless of whether the Remote Emitter ever fired at all (solver found a 3-move shortcut, skipping mirror(7,9) entirely). Requiring RED - a color neither the BLUE channel nor anything else on the board ever produces at that cell - closes it. optimal_moves=4 (mirror(5,4), mirror(1,6), mirror(3,8), mirror(7,9) all must be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 10
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.RED),

		TilePlacement.make_beam_receiver(Vector2i(3, 1), "TW137"),

		TilePlacement.make_splitter(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(1, 1), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(5, 8), "TW137G", false),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, "TW137", GridTypes.BeamColor.RED),
		TilePlacement.make_switch(Vector2i(3, 9), "TW137G"),
		TilePlacement.make_mirror(Vector2i(7, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.RED),
	]
