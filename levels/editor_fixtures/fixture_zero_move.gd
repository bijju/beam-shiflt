extends LevelData
## EDITOR FIXTURE - development/validator testing only. Already solved in
## its authored (zero-move) state - a straight, unobstructed shot from
## emitter to target with no mirrors at all. LevelValidator must warn
## "TRIVIAL SOLUTION"; LevelSolver must report trivial=true and
## optimal_moves=0.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Trivial Zero-Move Solution"
	grid_width = 4
	grid_height = 3
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_target(Vector2i(3, 1)),
	]
