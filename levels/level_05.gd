extends LevelData
## Test Level 5 - "Three Turns". Milestone 1 challenge level: three
## meaningful rotations plus a decoy mirror and a blocker on the "obvious
## wrong guess" branch, requiring the player to plan the full path before
## rotating. See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 5
	display_name = "Three Turns"
	grid_width = 5
	grid_height = 5
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_target(Vector2i(3, 4)),
	]
