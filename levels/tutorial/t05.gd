extends TutorialLevelData
## Tutorial T05 — "Split Path". Teaches: a SPLITTER sends the beam two
## ways at once - one branch continues straight, unconditionally,
## regardless of the splitter's orientation; the other branch reflects
## exactly like a mirror, and IS controlled by rotating it. Uses the
## real LaserSystem/GridManager splitter behavior directly (see
## DECISIONS.md D15/D56) - nothing here is a tutorial-only simplification.

func _init() -> void:
	level_id = 5
	display_name = "Split Path"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 2)),
		TilePlacement.make_target(Vector2i(2, 0)),
	]
	steps = [
		TutorialStepData.message("This is a splitter. It sends the beam two ways at once.", Vector2i(2, 2)),
		TutorialStepData.message("Look - one branch already reached this target, without you touching anything. The straight path continues automatically, no matter how the splitter is rotated.", Vector2i(4, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "The OTHER branch reflects like a mirror, and that direction depends on the splitter's rotation. Tap it to send that branch toward the second target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("One splitter, two beams, two targets."),
	]
