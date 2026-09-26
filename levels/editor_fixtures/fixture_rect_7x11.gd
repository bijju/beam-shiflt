extends LevelData
## RECTANGULAR-GRID LAYOUT FIXTURE - development/layout testing only. See
## fixture_rect_5x8.gd for the full rationale (same pattern, different
## shape). 7 columns x 11 rows - a tall portrait board.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Rectangular Layout 7x11"
	grid_width = 7
	grid_height = 11
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(6, 0), GridTypes.MirrorOrientation.SLASH), # wrong: RIGHT->UP goes off-grid
		TilePlacement.make_target(Vector2i(6, 10)),
	]
