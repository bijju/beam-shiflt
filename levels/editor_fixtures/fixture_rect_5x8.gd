extends LevelData
## RECTANGULAR-GRID LAYOUT FIXTURE - development/layout testing only. NOT a
## campaign or dev/regression level (never added to LevelManager.LEVEL_PATHS
## or CAMPAIGN_LEVEL_PATHS), never reachable by a player, excluded from the
## Android export like every other levels/editor_fixtures/ file.
##
## Portrait-tall 5x8 board (5 columns, 8 rows). Beam runs the full width
## (top-left emitter -> top-right mirror) then the full height (top-right
## mirror -> bottom-right target), so any per-axis cell_size/grid_origin
## misalignment in a rectangular (non-square) board shows up immediately as
## a visibly offset beam or a target that doesn't activate. One rotatable
## mirror authored in its WRONG orientation - a real 1-move puzzle, so a
## runtime-replay test also exercises input-to-cell mapping and the move
## counter, not just static layout. See CLAUDE.md's rectangular-grid rule.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Rectangular Layout 5x8"
	grid_width = 5
	grid_height = 8
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH), # wrong: RIGHT->UP goes off-grid
		TilePlacement.make_target(Vector2i(4, 7)),
	]
