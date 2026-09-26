extends LevelData
## Campaign Level 49 (Stage 5 #9) — EXPERT PRE-FINALE. Two distinct false
## routes, each demonstrating a different failure mode: one is
## geometrically perfect but produces the wrong final color (passes
## directly over BOTH required targets, still RED, activating neither);
## the other produces the objectively CORRECT color but is blocked
## immediately afterward. Only the true 6-move route satisfies both
## color and geometry for both targets. 6x7 grid. See
## CAMPAIGN_DESIGN.md section 11e.

func _init() -> void:
	level_id = 9
	display_name = "Vortex"
	stage = "Filters"
	developer_notes = "FALSE ROUTE A (color-invalid, geometrically perfect): mirror (2,2) authored BACKSLASH sends the beam through fixed mirror (2,6) straight across row 5, passing directly over BOTH the BLUE target (4,6) AND the GREEN target (5,6) while still RED - a route that LOOKS like it should work (it visits both targets!) but activates neither, since it never touches a filter. FALSE ROUTE B (color-valid, geometrically blocked): mirror (2,0) authored BACKSLASH sends the beam through the decoy GREEN filter at (1,0) - now genuinely GREEN, the objectively correct color for the GREEN target - but blocker (0,0) stops it one cell later. TRUE ROUTE: mirrors (2,2)/(2,0)->SLASH, splitter (3,0)->BACKSLASH. Straight branch runs through mirror (5,0) down through the GREEN filter (5,4) to the GREEN target (5,6). Reflected branch runs through mirrors (3,2)/(4,2) down through the BLUE filter (4,4) to the BLUE target (4,6) - a separate filter/target pair from the straight branch's, so neither branch's color can substitute for the other's target. FILTER ESSENTIAL for both real filters. All six rotatable pieces are load-bearing."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(1, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_blocker(Vector2i(0, 0)),
		TilePlacement.make_splitter(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 4), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.BLUE),
	]
