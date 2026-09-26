extends LevelData
## Campaign Level 2 — "First Turn". Teaches chaining two reflections:
## both mirrors start wrong, so the player must reason about the full
## two-bounce path before rotating either one. See CAMPAIGN_DESIGN.md.
## PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an
## order-preserving coordinate remap (see DECISIONS.md D73) - identical
## puzzle topology/solution, solver-confirmed optimal_moves unchanged (2).

func _init() -> void:
	level_id = 2
	display_name = "First Turn"
	stage = "First Light"
	developer_notes = "Teaches: a two-mirror chained path. Both mirrors start wrong (each dead-ends off-grid alone) so the player must plan both turns together. No decoys."
	is_campaign_level = true
	grid_width = 5
	grid_height = 6
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5)),
	]
