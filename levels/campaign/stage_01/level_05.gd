extends LevelData
## Campaign Level 5 — "Alignment". Introduces a fixed (non-rotatable)
## mirror alongside two rotatable ones: the player must route around a
## piece they cannot touch. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (2).

func _init() -> void:
	level_id = 5
	display_name = "Alignment"
	stage = "First Light"
	developer_notes = "Teaches: a fixed mirror (locked icon, cannot rotate) anchors the start of the route; the player only controls the two mirrors after it."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5)),
	]
