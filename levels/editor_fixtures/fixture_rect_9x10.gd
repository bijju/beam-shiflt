extends LevelData
## RECTANGULAR-GRID LAYOUT FIXTURE - development/layout testing only. See
## fixture_rect_5x8.gd for the full rationale (same pattern, different
## shape). 9 columns x 10 rows - close to square, checks the formula
## degrades correctly toward the near-square case (min() of the two
## per-axis candidates should pick whichever axis is actually tighter).

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Rectangular Layout 9x10"
	grid_width = 9
	grid_height = 10
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH), # wrong: RIGHT->UP goes off-grid
		TilePlacement.make_target(Vector2i(8, 9)),
	]
