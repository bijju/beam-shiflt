extends TutorialLevelData
## Tutorial T32 — "Sel + Portal". The selector's DOWN output enters a Portal and leaves the
## partner (row 0) still travelling DOWN, to the real target. The selector starts UP; the
## middle state, RIGHT, is a plausible-but-wrong route that lights a decoy target on the
## same board. Two forced taps.

func _init() -> void:
	level_id = 32
	display_name = "Sel + Portal"
	grid_width = 6
	grid_height = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(2, 2), GridTypes.Direction.UP),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.WHITE, false),
		TilePlacement.make_portal(Vector2i(2, 4), "T32"),
		TilePlacement.make_portal(Vector2i(4, 0), "T32"),
		TilePlacement.make_target(Vector2i(4, 4)),
	]
	steps = [
		TutorialStepData.message("The selected path can continue through a Portal.", Vector2i(2, 4)),
		TutorialStepData.message("A beam entering one Portal leaves the other, same direction.", Vector2i(4, 0)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap the Selector."),
		TutorialStepData.require_tap(Vector2i(2, 2), "RIGHT lights a side target, but that is not the goal. Tap again."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Where the beam comes out of a Portal matters as much as where it goes in."),
	]
