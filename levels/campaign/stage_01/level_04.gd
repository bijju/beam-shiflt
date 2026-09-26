extends LevelData
## Campaign Level 4 — "Blocked". Introduces the Blocker tile: the wrong
## rotation at the fork mirror sends the beam straight into a blocker,
## teaching that a plausible-looking guess can be a dead end. See
## CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (2).

func _init() -> void:
	level_id = 4
	display_name = "Blocked"
	stage = "First Light"
	developer_notes = "Teaches: a Blocker punishes the wrong fork at Mirror A (its SLASH guess runs straight into the blocker above). Both mirrors start wrong."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(2, 0)),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5)),
	]
