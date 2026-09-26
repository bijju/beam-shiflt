extends LevelData
## Campaign Level 117 — "Split Spectrum". GREEN routes through a Portal
## before a Filter; BLUE routes through a Splitter, and BOTH resulting
## branches are meaningful (not a decorative decoy) - whole-board
## reasoning across a deliberately asymmetric layout.

func _init() -> void:
	level_id = 17
	display_name = "Split Spectrum"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,3) RIGHT WHITE -> prism(3,3). RED channel straight -> target(7,3) RED, free arrival. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,0). Starts SLASH (WRONG - reflect(UP,SLASH)=RIGHT, harmless miss along row 0); correct BACKSLASH -> reflect(UP,BACKSLASH)=LEFT -> row 0 leftward to portal(0,0), pair 'F117' -> teleports to partner (7,7), direction preserved (LEFT) -> row 7 leftward, clear, through x6,5,4,3 (empty transit only, BLUE's splitter lives one row up at (3,6)) to filter(2,7) (recolors GREEN -> BLUE) -> target(1,7), which requires BLUE - matching the post-filter color, not the channel's original GREEN. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to splitter(3,6) (FIXED, SLASH, non-rotatable) - creates two genuinely meaningful branches, not a decorative decoy. Reflected branch (reflect(DOWN,SLASH)=LEFT) -> row 6 to mirror(1,6). Starts SLASH (WRONG - reflect(LEFT,SLASH)=DOWN, harmless miss); correct BACKSLASH -> reflect(LEFT,BACKSLASH)=UP -> column 1 up, clear, to target(1,0) BLUE. Straight-continuing branch (direction unchanged, DOWN) -> column 3 down to mirror(3,8). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 8 to target(6,8) BLUE. optimal_moves=3 (mirror(3,0), mirror(1,6), mirror(3,8) all must be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 3)),
		TilePlacement.make_target(Vector2i(7, 3), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(0, 0), "F117"),
		TilePlacement.make_portal(Vector2i(7, 7), "F117"),
		TilePlacement.make_filter(Vector2i(2, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(1, 7), GridTypes.BeamColor.BLUE),

		TilePlacement.make_splitter(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(1, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.BLUE),
	]
