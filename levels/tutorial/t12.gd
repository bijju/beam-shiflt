extends TutorialLevelData
## Tutorial T12 — "Prism Basics". Teaches: a PRISM splits one WHITE beam
## into three colored beams (RED/GREEN/BLUE) at once - see
## GridTypes.prism_output_direction() and ERA_2_DESIGN.md "Prism". The
## RED (straight) channel already reaches its target with zero moves,
## echoing T05 Split Path's "one branch arrives automatically" reveal;
## the GREEN channel needs one familiar mirror rotation. The BLUE channel
## is left unterminated on purpose - a beam not reaching a target is
## normal, not an error.

func _init() -> void:
	level_id = 12
	display_name = "Prism Basics"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_prism(Vector2i(2, 2)),
		TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(0, 1), GridTypes.BeamColor.GREEN),
	]
	steps = [
		TutorialStepData.message("This is a Prism. A white beam entering it splits into three colored beams at once.", Vector2i(2, 2)),
		TutorialStepData.message("The red beam already reached its target on its own - no rotation needed.", Vector2i(4, 2)),
		TutorialStepData.message("The green beam needs a push - this mirror is turned the wrong way.", Vector2i(2, 1)),
		TutorialStepData.require_tap(Vector2i(2, 1), "Tap it to rotate."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("One beam in, three beams out. Prisms will show up everywhere in Era 2."),
	]
