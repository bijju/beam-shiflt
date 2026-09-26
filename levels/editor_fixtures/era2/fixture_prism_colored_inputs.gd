extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. Three
## independent chains, one per non-WHITE beam color, each firing directly
## into its own PRISM travelling RIGHT. Validates that a colored beam
## only ever produces its own matching channel (RED stays on the straight
## channel; GREEN/BLUE only reach their own turn) and never the other two
## channels - the "RED/GREEN/BLUE Prism input" test points.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Prism Colored Inputs"
	grid_width = 7
	grid_height = 10
	optimal_moves = 0
	tiles = [
		# RED in -> RED channel (straight) only.
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_prism(Vector2i(3, 1)),
		TilePlacement.make_target(Vector2i(6, 1), GridTypes.BeamColor.RED),

		# GREEN in -> GREEN channel (reflect SLASH = UP) only.
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.GREEN),
		TilePlacement.make_prism(Vector2i(3, 4)),
		TilePlacement.make_target(Vector2i(3, 2), GridTypes.BeamColor.GREEN),

		# BLUE in -> BLUE channel (reflect BACKSLASH = DOWN) only.
		TilePlacement.make_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, GridTypes.BeamColor.BLUE),
		TilePlacement.make_prism(Vector2i(3, 7)),
		TilePlacement.make_target(Vector2i(3, 9), GridTypes.BeamColor.BLUE),
	]
