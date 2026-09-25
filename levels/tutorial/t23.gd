extends TutorialLevelData
## Tutorial T23 — "Color Recipes". Two Fusion Nodes, one lesson each:
## RED + BLUE = MAGENTA (top node) and GREEN + BLUE = CYAN (bottom
## node). Both start facing UP, the side their BLUE beam arrives on, so
## each needs exactly one tap; the steps deal with them one at a time.

func _init() -> void:
	level_id = 23
	display_name = "Color Recipes"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(2, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.BLUE),
		TilePlacement.make_fusion(Vector2i(2, 1), GridTypes.Direction.UP),
		TilePlacement.make_target(Vector2i(4, 1), GridTypes.BeamColor.MAGENTA),

		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(2, 3), GridTypes.Direction.DOWN, GridTypes.BeamColor.BLUE),
		TilePlacement.make_fusion(Vector2i(2, 4), GridTypes.Direction.UP),
		TilePlacement.make_target(Vector2i(4, 4), GridTypes.BeamColor.CYAN),
	]
	steps = [
		TutorialStepData.message("Different pairs make different colors. This node mixes RED and BLUE.", Vector2i(2, 1)),
		TutorialStepData.message("RED + BLUE = MAGENTA.", Vector2i(4, 1)),
		TutorialStepData.require_tap(Vector2i(2, 1), "Turn it toward the MAGENTA target."),
		TutorialStepData.message("This node mixes GREEN and BLUE.", Vector2i(2, 4)),
		TutorialStepData.require_tap(Vector2i(2, 4), "GREEN + BLUE = CYAN. Turn it toward the CYAN target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Every recipe needs BOTH colors."),
	]
