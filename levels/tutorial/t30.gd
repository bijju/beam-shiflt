extends TutorialLevelData
## Tutorial T30 — "Choose Output". Every output of the selector leads somewhere visible:
## LEFT is the side the beam arrives on (nothing leaves), UP lights a harmless decoy target,
## RIGHT hits a wall, DOWN reaches the real target. The selector starts on LEFT, so three
## forced taps walk the player through all four states, each explained in turn.

func _init() -> void:
	level_id = 30
	display_name = "Choose Output"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(2, 2), GridTypes.Direction.LEFT),
		TilePlacement.make_target(Vector2i(2, 0), GridTypes.BeamColor.WHITE, false),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_target(Vector2i(2, 4)),
	]
	steps = [
		TutorialStepData.message("Only ONE output is active at a time.", Vector2i(2, 2)),
		TutorialStepData.message("Each tap selects the next direction, clockwise.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "The output faces LEFT - back where the beam comes from - so nothing leaves. Tap."),
		TutorialStepData.require_tap(Vector2i(2, 2), "UP: the beam lights a decoy, not the goal. Tap again."),
		TutorialStepData.require_tap(Vector2i(2, 2), "RIGHT: a wall. Tap once more."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("DOWN reaches the goal. Only the chosen output ever carries the beam."),
	]
