extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A single
## ROTATABLE one-way reflector, authored in the WRONG orientation
## (BACKSLASH - reflects the incoming RIGHT-travelling beam DOWN, away
## from the target). Rotating it once to SLASH reflects the same beam UP
## into the required target instead. Validates that LevelSolver (which is
## fully generic over LevelData.get_rotatable_tiles()) picks up
## ONE_WAY_REFLECTOR as a rotatable piece with zero solver code changes,
## and that rotation genuinely changes which side reflects - exactly the
## "player rotation changes which side reflects" requirement.
## optimal_moves == 1 is the assertion this fixture exists to check.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: One-Way Reflector Rotation (solver)"
	grid_width = 4
	grid_height = 4
	optimal_moves = 1
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(3, 3), GridTypes.MirrorOrientation.BACKSLASH, true),
		TilePlacement.make_target(Vector2i(3, 0)),
	]
