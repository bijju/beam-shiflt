extends LevelData
## Campaign Level 111 — "Split Decision". Prism + Splitter: the GREEN
## channel hits a splitter, creating a second layer of branching. One
## rotatable mirror's plausible-but-wrong orientation sends its beam
## through a real target cell with the WRONG required color (a
## true-positive decoy that still doesn't count) instead of continuing
## on to its actual target.

func _init() -> void:
	level_id = 11
	display_name = "Split Decision"
	stage = "Circuit"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel straight -> target(6,4) RED, free arrival. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,6). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 6 to target(6,6) BLUE. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up into splitter(3,1) (FIXED, SLASH, non-rotatable) - the 'second layer of branching' the brief asked for. Splitter's straight-continuing branch (direction unchanged, UP) -> mirror(3,0). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits left through the emitter's own cell, harmless); correct SLASH -> reflect(UP,SLASH)=RIGHT -> row 0 to target(6,0) GREEN. Splitter's reflected branch (reflect(UP,SLASH)=RIGHT) -> mirror(5,1). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP -> the beam travels one cell up to (5,0), which is a DECOY target requiring BLUE, is_required=false. The beam IS green, so it does NOT activate the decoy (color mismatch) - it just passes through it and exits the top boundary immediately after, a genuinely 'locally plausible' route that reaches a target-shaped cell and still fails, exactly the trap the brief asked for); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 5 down, clear, to the REAL target(5,7) GREEN. optimal_moves=3 (mirror(3,6), mirror(3,0), mirror(5,1) all must be flipped)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.BLUE),

		TilePlacement.make_splitter(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 0), GridTypes.BeamColor.BLUE, false),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.GREEN),
	]
