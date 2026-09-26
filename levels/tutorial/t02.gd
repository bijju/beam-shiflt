extends TutorialLevelData
## Tutorial T02 — "Two Turns". Teaches both mirror orientations and how
## they change the beam's direction. The first mirror is forced (exactly
## like T01); the second is left to the player's own judgment once the
## lesson has been introduced, so they practice recognizing reflection
## rather than memorizing one forced tap. See DECISIONS.md "Guided
## tutorial system".

func _init() -> void:
	level_id = 2
	display_name = "Two Turns"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
	steps = [
		TutorialStepData.message("Every mirror has two orientations - '/' and '\\'. Each one bends the beam a different way."),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap this mirror to send the beam upward."),
		TutorialStepData.message("Good. Now a second mirror needs to redirect it again, toward the target.", Vector2i(2, 0)),
		TutorialStepData.wait_for_solved("This time, rotate it yourself - tap any mirror until the beam reaches the target."),
		TutorialStepData.message("You've now used both mirror orientations to build a route."),
	]
