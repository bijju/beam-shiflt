extends TutorialLevelData
## Tutorial T20 — "Era 2 Graduation". Combines every Era 2 mechanic with
## an Era 1 one in a single puzzle, minimal hand-holding (one overview
## message, one free-play wait_for_solved step) - matching T10's own
## "reduce hand-holding by the final lesson" pattern. One WHITE beam
## enters a Prism: the RED channel needs a One-Way Reflector rotated
## correctly, the GREEN channel silently powers a Receiver -> Remote
## Emitter -> Filter chain that resolves on its own before the player
## ever taps anything, and the BLUE channel needs a plain mirror. Two
## required rotations total.

func _init() -> void:
	level_id = 20
	display_name = "Era 2 Graduation"
	grid_width = 9
	grid_height = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT),
		TilePlacement.make_prism(Vector2i(3, 4)),

		# RED channel (straight) -> One-Way Reflector -> target.
		TilePlacement.make_one_way_reflector(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH, true),
		TilePlacement.make_target(Vector2i(5, 1), GridTypes.BeamColor.RED),

		# GREEN channel (turn) -> Receiver -> Remote Emitter -> Filter -> target.
		# Fully self-resolving before the player's first move.
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "T20"),
		TilePlacement.make_remote_emitter(Vector2i(6, 8), GridTypes.Direction.RIGHT, "T20"),
		TilePlacement.make_filter(Vector2i(7, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(8, 8), GridTypes.BeamColor.GREEN),

		# BLUE channel (turn) -> Mirror -> target.
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.BLUE),
	]
	steps = [
		TutorialStepData.message("Graduation. Everything from this Era in one puzzle: Prism, One-Way Reflector, Receiver, Remote Emitter - plus the mechanics you already knew."),
		TutorialStepData.wait_for_solved("Three beams out of one Prism. Route them all - watch for which side of the One-Way Reflector actually reflects."),
		TutorialStepData.message("Era 2 complete. Every mechanic here will keep showing up as the campaign continues."),
	]
