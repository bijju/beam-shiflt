extends TutorialLevelData
## Tutorial T22 — "Output Direction". The node is already fusing RED +
## GREEN, but its output faces DOWN, away from the target. Turning it
## clockwise (DOWN -> LEFT -> UP -> RIGHT) walks the output through the
## two sides the inputs arrive on - each of which switches the node off,
## because a side that receives a beam cannot also be the output - before
## RIGHT finally works. Three forced taps, one explained per step.

func _init() -> void:
	level_id = 22
	display_name = "Output Side"
	grid_width = 6
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(3, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.GREEN),
		TilePlacement.make_fusion(Vector2i(3, 3), GridTypes.Direction.DOWN),
		TilePlacement.make_target(Vector2i(5, 3), GridTypes.BeamColor.YELLOW),
	]
	steps = [
		TutorialStepData.message("This node already works, but its beam points the wrong way.", Vector2i(3, 3)),
		TutorialStepData.message("The node's direction sets where its new beam leaves.", Vector2i(3, 3)),
		TutorialStepData.require_tap(Vector2i(3, 3), "Tap to turn its output."),
		TutorialStepData.require_tap(Vector2i(3, 3), "LEFT is where RED arrives. An input side can't be the output, so the node went dark. Tap again."),
		TutorialStepData.require_tap(Vector2i(3, 3), "UP is where GREEN arrives. Dark again. One more tap."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("RIGHT is free. Never point the output at an input."),
	]
