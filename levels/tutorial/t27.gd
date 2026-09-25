extends TutorialLevelData
## Tutorial T27 — "Fusion + Receiver". A Fusion Node's new beam passes
## through a Beam Receiver (which never blocks a beam), powering a Remote
## Emitter elsewhere on the board; that beam still needs one mirror turned
## to reach the target. Uses T17/T18's receiver rules unchanged - the
## Fusion output is just another beam as far as LaserSystem is concerned.

func _init() -> void:
	level_id = 27
	display_name = "Fusion Relay"
	grid_width = 5
	grid_height = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(2, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.GREEN),
		TilePlacement.make_fusion(Vector2i(2, 2), GridTypes.Direction.UP),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "T27"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "T27", GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.RED),
	]
	steps = [
		TutorialStepData.message("The node's beam can also power things. Here it passes a Receiver.", Vector2i(3, 2)),
		TutorialStepData.message("A Receiver powers a Remote Emitter elsewhere.", Vector2i(0, 4)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Turn the node so its beam passes through the Receiver."),
		TutorialStepData.message("The Remote Emitter fires. Guide its beam to the target.", Vector2i(4, 4)),
		TutorialStepData.require_tap(Vector2i(4, 4), "Turn this mirror."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("One lit node can wake up another part of the board."),
	]
