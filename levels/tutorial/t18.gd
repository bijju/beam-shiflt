extends TutorialLevelData
## Tutorial T18 — "Remote Power". The Receiver from T17 is now the whole
## puzzle: the main beam powers it automatically (zero moves), waking up
## a Remote Emitter whose own beam is what actually needs routing. Proves
## simulate_until_stable() already resolves the Receiver -> Remote
## Emitter dependency before the level is even shown - the Remote
## Emitter is visibly firing from the very first frame.

func _init() -> void:
	level_id = 18
	display_name = "Remote Power"
	grid_width = 4
	grid_height = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(3, 1), "T18"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "T18"),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 6)),
	]
	steps = [
		TutorialStepData.message("Last lesson's Receiver is now the whole puzzle. Power it, then route what it activates."),
		TutorialStepData.message("The Receiver up top is already being hit - nothing to do there. Below, a Remote Emitter just woke up.", Vector2i(3, 1)),
		TutorialStepData.require_tap(Vector2i(3, 4), "Route the Remote Emitter's beam into its target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("A Beam Receiver never moves the beam itself - it wakes up an emitter somewhere else on the board."),
	]
