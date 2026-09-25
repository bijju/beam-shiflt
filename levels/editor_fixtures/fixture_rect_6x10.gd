extends LevelData
## RECTANGULAR-GRID LAYOUT FIXTURE - development/layout testing only. See
## fixture_rect_5x8.gd for the full rationale (same pattern, different
## shape). 6 columns x 10 rows - a taller portrait board.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Rectangular Layout 6x10"
	grid_width = 6
	grid_height = 10
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH), # wrong: RIGHT->UP goes off-grid
		TilePlacement.make_target(Vector2i(5, 9)),
	]
