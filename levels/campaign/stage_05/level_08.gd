extends LevelData
## Campaign Level 48 (Stage 5 #8) — GLOBAL COLOR NETWORK. The very first
## mirror (2,3) gates access to the entire rest of the board - the
## splitter, both filters, and both required targets - even though the
## failure (a wrong-color decoy touch) is only apparent several steps
## later. Each of the splitter's two branches needs its OWN filter to
## reach its OWN colored target; neither branch's filter helps the
## other. 6x7 grid. See CAMPAIGN_DESIGN.md section 11e.

func _init() -> void:
	level_id = 8
	display_name = "Waveform"
	stage = "Filters"
	developer_notes = "GLOBAL DEPENDENCY: mirror (2,3) authored BACKSLASH diverts the entire WHITE beam through fixed mirror (2,6) past the non-required RED decoy at (3,6) - the beam even passes directly over the BLUE target's cell (4,6) on the way out, still WHITE, still failing to activate it - before exiting the board. Nothing downstream (the splitter, either filter, either target) is ever reached this way. TRUE ROUTE: mirror (2,3)->SLASH, mirror (2,0)->SLASH, splitter (3,0)->BACKSLASH. Straight branch runs through mirror (5,0) down through the RED filter (5,2) to the RED target (5,4) - completely untouched by rotation past the splitter. Reflected branch runs through mirrors (3,3)/(4,3) down through the BLUE filter (4,4) to the BLUE target (4,6) - a deliberately separate filter/target pair so neither branch's color can accidentally satisfy the other's target. FILTER ESSENTIAL for both: removing either filter leaves its branch WHITE, which fails its target (WHITE beam, colored-required target). Blocker (1,0) cleanly stops mirror (2,0)'s wrong-orientation exit. All six rotatable pieces are load-bearing."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.RED, false),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(1, 0)),
		TilePlacement.make_splitter(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.BLUE),
	]
