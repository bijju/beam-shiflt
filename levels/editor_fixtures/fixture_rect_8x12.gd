extends LevelData
## RECTANGULAR-GRID LAYOUT FIXTURE - development/layout testing only. See
## fixture_rect_5x8.gd for the full rationale (same pattern, different
## shape). 8 columns x 12 rows - the tallest/largest fixture in this set,
## for checking minimum resulting cell_size on a small phone width.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Rectangular Layout 8x12"
	grid_width = 8
	grid_height = 12
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(7, 0), GridTypes.MirrorOrientation.SLASH), # wrong: RIGHT->UP goes off-grid
		TilePlacement.make_target(Vector2i(7, 11)),
	]
