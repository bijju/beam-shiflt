extends TutorialLevelData
## Tutorial T17 — "Signal Receiver". Introduces the BEAM_RECEIVER alone,
## previewing what it does without yet requiring the player to route its
## effect - that's T18. The main beam (needing one familiar mirror
## rotation) already passes through the receiver on its way to the
## required target; a Remote Emitter it powers fires toward a second,
## OPTIONAL (not required) target purely as a preview.

func _init() -> void:
	level_id = 17
	display_name = "Signal Receiver"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(2, 2), "T17"),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 4)),

		TilePlacement.make_remote_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, "T17"),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.WHITE, false),
	]
	steps = [
		TutorialStepData.message("This is a Beam Receiver. Any beam that reaches it powers something else, somewhere on the board.", Vector2i(2, 2)),
		TutorialStepData.message("It doesn't block or bend the beam - just like a switch."),
		TutorialStepData.require_tap(Vector2i(4, 2), "Route the main beam to its target - watch the top of the board once the Receiver lights up."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Notice the second beam up top? That's what a Receiver powers. Next lesson, that becomes the whole puzzle."),
	]
