extends LevelData
## Campaign Level 3 — "Signal Path". Teaches multiple mirrors on one
## route: three mirrors in a staircase, two of them start wrong. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (2).

func _init() -> void:
	level_id = 3
	display_name = "Signal Path"
	stage = "First Light"
	developer_notes = "Teaches: a three-mirror staircase route. Mirror C is already correctly oriented (not every piece needs touching); A and B start wrong. No decoys."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 5)),
	]
