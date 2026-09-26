extends LevelData
## Campaign Level 6 — "False Signal". Teaches that a mirror junction can
## offer two plausible-looking continuations where only one actually
## leads anywhere - the wrong choice at Mirror B just runs off the grid
## with nothing to show for it. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (3).

func _init() -> void:
	level_id = 6
	display_name = "False Signal"
	stage = "First Light"
	developer_notes = "Teaches: Mirror B is a real fork - one orientation continues the route to Mirror C, the other silently exits the grid to the left. No decoy tile; the false route is a wrong ORIENTATION choice, not an extra piece."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5)),
	]
