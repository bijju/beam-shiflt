extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A single
## WHITE beam enters a PRISM and must produce exactly three branches
## (RED straight, GREEN via SLASH turn, BLUE via BACKSLASH turn), each
## reaching its own correctly-colored required target. Validates the
## "WHITE Prism split" and "Multiple branches simultaneously" test points
## from ERA_2_DESIGN.md.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Prism WHITE Split"
	grid_width = 7
	grid_height = 7
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_prism(Vector2i(3, 3)),
		# RED channel = straight (RIGHT unchanged).
		TilePlacement.make_target(Vector2i(6, 3), GridTypes.BeamColor.RED),
		# GREEN channel = reflect(RIGHT, SLASH) = UP.
		TilePlacement.make_target(Vector2i(3, 0), GridTypes.BeamColor.GREEN),
		# BLUE channel = reflect(RIGHT, BACKSLASH) = DOWN.
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.BLUE),
	]
