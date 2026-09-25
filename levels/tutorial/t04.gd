extends TutorialLevelData
## Tutorial T04 — "Both Lights". Teaches: some puzzles require MULTIPLE
## targets active simultaneously - activating one is not enough. The
## beam passes through target A on its way to target B (LaserSystem lets
## a beam activate several targets in sequence - see DECISIONS.md), so
## the player sees target A light up first and must notice the puzzle
## still isn't solved before finishing the route.

func _init() -> void:
	level_id = 4
	display_name = "Both Lights"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 1)),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
	steps = [
		TutorialStepData.message("Some puzzles need more than one target active at the same time."),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap this mirror to send the beam upward."),
		TutorialStepData.message("One target is active - but look at the second one. ALL required targets must be active to solve the puzzle.", Vector2i(4, 0)),
		TutorialStepData.wait_for_solved("Rotate the second mirror to finish the route."),
		TutorialStepData.message("Both targets active. Now the puzzle is solved."),
	]
