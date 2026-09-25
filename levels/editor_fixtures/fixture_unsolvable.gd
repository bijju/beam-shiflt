extends LevelData
## EDITOR FIXTURE - development/validator testing only. Structurally
## valid but genuinely unsolvable: the emitter's beam is blocked
## immediately, and the one rotatable mirror present sits off to the side
## where the beam can never reach it, so no rotation can help.
## LevelSolver must report status="UNSOLVABLE" (not UNKNOWN - the full
## state space is small enough to exhaust) with optimal_moves == -1.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Unsolvable"
	grid_width = 4
	grid_height = 3
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_blocker(Vector2i(1, 1)),
		TilePlacement.make_target(Vector2i(3, 1)),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
	]
