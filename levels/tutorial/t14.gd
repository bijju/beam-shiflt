extends TutorialLevelData
## Tutorial T14 — "Prism Routing". Teaches: a Prism's channels combine
## naturally with mirrors - each colored branch can be routed completely
## independently to its own target. Two required rotations this time
## (one per routed channel); the third (blue) channel is left
## unterminated, same as T12.

func _init() -> void:
	level_id = 14
	display_name = "Prism Routing"
	grid_width = 7
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_prism(Vector2i(3, 2)),

		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 1), GridTypes.BeamColor.GREEN),
	]
	steps = [
		TutorialStepData.message("Prisms combine well with mirrors - each channel can be routed on its own."),
		TutorialStepData.require_tap(Vector2i(5, 2), "Fix the red channel's mirror first."),
		TutorialStepData.require_tap(Vector2i(3, 1), "Now the green channel's mirror."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Three channels, three routes. You choose where each color ends up."),
	]
