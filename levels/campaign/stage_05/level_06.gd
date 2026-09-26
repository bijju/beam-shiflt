extends LevelData
## Campaign Level 46 (Stage 5 #6) — CROSS-BRANCH COLOR DEPENDENCY. First
## major Stage 5 challenge. The mirror at (3,2) is shared by BOTH the
## splitter's straight branch (arriving from the west, about to enter
## the BLUE filter) and its reflected branch (arriving from the north,
## after a full relay loop) - only one of its two orientations lets
## BOTH colored targets be reached at once. 6x7 grid. See
## CAMPAIGN_DESIGN.md section 11e.

func _init() -> void:
	level_id = 6
	display_name = "Frequency"
	stage = "Filters"
	developer_notes = "CROSS-BRANCH COLOR DEPENDENCY. Splitter (2,2): straight branch travels RIGHT into the shared mirror (3,2), then DOWN through the BLUE filter (3,4) to the BLUE target (3,6) - untouched by any rotation past the splitter itself. Reflected branch (needs SLASH, authored BACKSLASH - wrong sends it down into the non-required GREEN decoy at (2,6)) loops UP through mirror (2,0) and relay mirror (3,0) back DOWN into that SAME shared mirror (3,2), arriving from the opposite direction, then RIGHT/DOWN/RIGHT through mirrors (4,2)/(4,4) to the RED target at (5,4) - deliberately never touching the BLUE filter, preserving RED. The shared mirror must be BACKSLASH - SLASH satisfies neither branch, not just one, which is the trap: a player fixated on the straight branch alone can rotate it correctly by luck without ever noticing it also gates the reflected branch's target. Blocker (1,0) cleanly stops mirror (2,0)'s wrong-orientation exit. All six rotatable pieces are load-bearing. FILTER ESSENTIAL: removing the BLUE filter leaves the straight branch RED, which fails the BLUE target."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_splitter(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 6), GridTypes.BeamColor.GREEN, false),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.RED),
	]
