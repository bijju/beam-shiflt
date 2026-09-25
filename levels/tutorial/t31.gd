extends TutorialLevelData
## Tutorial T31 — "Sel + Filter". Each selector output crosses a different Filter. The
## target needs BLUE; the RIGHT output (its start state) carries RED into a decoy BLUE target
## that stays dark, UP carries GREEN off the board, and only DOWN carries BLUE to the goal.

func _init() -> void:
	level_id = 31
	display_name = "Sel + Filter"
	grid_width = 5
	grid_height = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(2, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_filter(Vector2i(2, 1), GridTypes.BeamColor.GREEN),
		TilePlacement.make_filter(Vector2i(3, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.BLUE, false),
		TilePlacement.make_filter(Vector2i(2, 3), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(2, 5), GridTypes.BeamColor.BLUE),
	]
	steps = [
		TutorialStepData.message("Check the target's color first: it needs BLUE.", Vector2i(2, 5)),
		TutorialStepData.message("Each output of the Selector passes a different Filter.", Vector2i(2, 2)),
		TutorialStepData.message("Choose the path that can supply BLUE.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "This path turns the beam RED, which the target rejects. Turn the Selector."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("The Selector chooses the route - and so the color that arrives."),
	]
