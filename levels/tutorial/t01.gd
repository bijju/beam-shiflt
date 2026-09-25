extends TutorialLevelData
## Tutorial T01 — "First Light". Teaches: the emitter produces a laser,
## the target is the goal, a mirror redirects the beam, and tapping a
## mirror rotates it. Follows the brief's exact suggested 7-step
## sequence. See CLAUDE.md/DECISIONS.md "Guided tutorial system".

func _init() -> void:
	level_id = 1
	display_name = "First Light"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
	]
	steps = [
		TutorialStepData.message("Welcome to BeamShift."),
		TutorialStepData.message("This is the laser emitter. It fires a beam in one fixed direction.", Vector2i(0, 2)),
		TutorialStepData.message("This is the target. Guide the beam into it to solve the puzzle.", Vector2i(2, 0)),
		TutorialStepData.message("Mirrors redirect the beam. This one is in the way, but pointing the wrong way.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap the highlighted mirror to rotate it."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Target activated. You just solved your first puzzle."),
	]
