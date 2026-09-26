extends TutorialLevelData
## Tutorial T13 — "Prism Colors". Teaches: unlike a WHITE beam, a
## COLORED beam entering a Prism only ever produces its own matching
## channel - never the other two. Two independent colored chains (red,
## green), each through its own Prism, contrast this directly against
## T12's white-beam three-way split.

func _init() -> void:
	level_id = 13
	display_name = "Prism Colors"
	grid_width = 7
	grid_height = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_prism(Vector2i(2, 1)),
		TilePlacement.make_target(Vector2i(4, 1), GridTypes.BeamColor.RED),

		TilePlacement.make_emitter(Vector2i(2, 5), GridTypes.Direction.UP, GridTypes.BeamColor.GREEN),
		TilePlacement.make_prism(Vector2i(2, 3)),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 5), GridTypes.BeamColor.GREEN),
	]
	steps = [
		TutorialStepData.message("A colored beam behaves differently in a Prism than a white one."),
		TutorialStepData.message("This red beam only ever produces a red output - no green, no blue. It already reached its target.", Vector2i(2, 1)),
		TutorialStepData.message("Same rule for this green beam below - only the green channel exists. Redirect it with the mirror.", Vector2i(4, 3)),
		TutorialStepData.require_tap(Vector2i(4, 3), "Tap the mirror."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Colored beams stay colored. Only white splits into all three."),
	]
