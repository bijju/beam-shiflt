extends TutorialLevelData
## Tutorial T28 — "Fusion Challenge". Free-play comprehension check for
## the whole Fusion pack, matching T10/T20's "reduce hand-holding by the
## final lesson" pattern (one overview message, one wait_for_solved).
## GREEN (WHITE emitter + Filter) and BLUE (through a Portal pair and a
## mirror) fuse to CYAN; the CYAN beam powers a Receiver -> Remote
## Emitter (RED) whose beam must pass a Gate opened by a Switch that a
## third emitter reaches only after one more mirror is turned. Three
## required taps: mirror M1, the Fusion Node, mirror M2. No circular
## dependency: the Gate is opened by an independent beam.

func _init() -> void:
	level_id = 28
	display_name = "Fusion Trial"
	grid_width = 7
	grid_height = 9
	tiles = [
		# GREEN input: WHITE emitter -> GREEN Filter -> node (left side).
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT),
		TilePlacement.make_filter(Vector2i(1, 5), GridTypes.BeamColor.GREEN),

		# BLUE input: emitter -> portal pair -> mirror M1 -> node (bottom side).
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.BLUE),
		TilePlacement.make_portal(Vector2i(2, 0), "T28"),
		TilePlacement.make_portal(Vector2i(1, 8), "T28"),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.BACKSLASH),

		TilePlacement.make_fusion(Vector2i(3, 5), GridTypes.Direction.UP),

		# CYAN output -> Receiver -> Remote Emitter -> Gate -> RED target.
		TilePlacement.make_beam_receiver(Vector2i(5, 5), "T28"),
		TilePlacement.make_remote_emitter(Vector2i(6, 8), GridTypes.Direction.UP, "T28", GridTypes.BeamColor.RED),
		TilePlacement.make_gate(Vector2i(6, 3), "T28G"),
		TilePlacement.make_target(Vector2i(6, 1), GridTypes.BeamColor.RED),

		# Independent beam: emitter -> mirror M2 -> Switch (opens the Gate).
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(4, 1), "T28G"),
	]
	steps = [
		TutorialStepData.message("Final test: Fusion, Filter, Portal, Receiver, Remote Emitter and Gate."),
		TutorialStepData.wait_for_solved("Trace what each piece needs. Hint is available."),
		TutorialStepData.message("Fusion complete. Nodes now appear in the main levels."),
	]
