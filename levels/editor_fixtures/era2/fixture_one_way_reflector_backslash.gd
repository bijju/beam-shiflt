extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. Mirror of
## fixture_one_way_reflector_slash.gd for BACKSLASH orientation: RIGHT
## and DOWN are the reflective pair, LEFT and UP are the pass-through
## pair. See GridTypes.one_way_reflector_is_reflective().

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: One-Way Reflector (BACKSLASH, all 4 directions)"
	grid_width = 8
	grid_height = 9
	optimal_moves = 0
	tiles = [
		# RIGHT -> reflective -> bends to DOWN.
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 1), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(2, 2)),

		# DOWN -> reflective -> bends to RIGHT.
		TilePlacement.make_emitter(Vector2i(6, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_one_way_reflector(Vector2i(6, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(7, 2)),

		# LEFT -> pass-through -> continues straight.
		TilePlacement.make_emitter(Vector2i(3, 6), GridTypes.Direction.LEFT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(0, 6)),

		# UP -> pass-through -> continues straight.
		TilePlacement.make_emitter(Vector2i(6, 8), GridTypes.Direction.UP),
		TilePlacement.make_one_way_reflector(Vector2i(6, 6), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(6, 4)),
	]
