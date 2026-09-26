extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. The
## reflective side of a ONE_WAY_REFLECTOR bends a beam directly into a
## HAZARD. Deliberately, permanently unsolvable by design (same
## convention as fixture_unsolvable.gd) - the required target sits where
## no beam can ever reach it. The assertion under test is
## hazard_hit == true and hit_hazard_positions containing the hazard's
## position, proving hazard detection still works correctly for a beam
## that reached the hazard via a one-way reflector's bend.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: One-Way Reflector -> Hazard"
	grid_width = 4
	grid_height = 3
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_hazard(Vector2i(2, 0)),
		TilePlacement.make_target(Vector2i(3, 2)), # unreachable by design
	]
