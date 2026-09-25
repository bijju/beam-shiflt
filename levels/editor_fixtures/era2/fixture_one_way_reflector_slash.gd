extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. Four
## independent, spatially-isolated chains cover all four incoming
## directions against a SLASH-oriented ONE_WAY_REFLECTOR: RIGHT and UP
## (the reflective pair - both must bend and reach their target) and
## LEFT and DOWN (the pass-through pair - both must continue straight,
## unaffected, and still reach their target). See
## GridTypes.one_way_reflector_is_reflective(). All reflectors are fixed
## (non-rotatable) so this fixture's authored state is itself the
## behavior under test.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: One-Way Reflector (SLASH, all 4 directions)"
	grid_width = 8
	grid_height = 9
	optimal_moves = 0
	tiles = [
		# RIGHT -> reflective -> bends to UP.
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(2, 0)),

		# UP -> reflective -> bends to RIGHT.
		TilePlacement.make_emitter(Vector2i(6, 3), GridTypes.Direction.UP),
		TilePlacement.make_one_way_reflector(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(7, 1)),

		# LEFT -> pass-through -> continues straight.
		TilePlacement.make_emitter(Vector2i(3, 6), GridTypes.Direction.LEFT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(0, 6)),

		# DOWN -> pass-through -> continues straight.
		TilePlacement.make_emitter(Vector2i(6, 5), GridTypes.Direction.DOWN),
		TilePlacement.make_one_way_reflector(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(6, 8)),
	]
