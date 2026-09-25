extends LevelData
## EDITOR FIXTURE - development/validator testing only. Deliberately
## broken: a SWITCH whose gate_id doesn't match any GATE tile in the
## level. LevelValidator must flag this as an error.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Invalid Gate Reference"
	grid_width = 4
	grid_height = 3
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_switch(Vector2i(1, 1), "NO_SUCH_GATE"),
		TilePlacement.make_target(Vector2i(3, 1)),
	]
