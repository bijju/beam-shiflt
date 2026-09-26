extends TutorialLevelData
## Tutorial T29 — "Select Path". Introduces the Splitter Selector alone: one beam in,
## exactly ONE chosen output. The selector starts pointing RIGHT into a wall; UP is also
## walled, so the only useful output is DOWN, one tap away. Nothing else is asked of the
## player. The closing message separates it from the ordinary Splitter (T06+). See
## TUTORIAL_SYSTEM.md section 15.

func _init() -> void:
	level_id = 29
	display_name = "Select Path"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(2, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_blocker(Vector2i(2, 1)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_target(Vector2i(2, 4)),
	]
	steps = [
		TutorialStepData.message("This is a Splitter Selector.", Vector2i(2, 2)),
		TutorialStepData.message("It sends the beam through ONE selected path.", Vector2i(2, 2)),
		TutorialStepData.message("Rotate it to choose the correct output.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap the Selector."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("One beam in, one chosen output. A Splitter sends beams every way at once; a Selector never does."),
	]
