extends LevelData
## Test Level 6 - "Twin Targets". Introduces multiple required targets: a
## single beam continues past the first target (Milestone 2 behavior - see
## ARCHITECTURE.md) and must also reach a second target via one mirror
## rotation. See TEST_PLAN.md for the verified solution trace.

func _init() -> void:
	level_id = 6
	display_name = "Twin Targets"
	grid_width = 5
	grid_height = 5
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_target(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
