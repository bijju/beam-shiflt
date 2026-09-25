extends TutorialLevelData
## Tutorial T26 — "Fusion + Portal". The RED input has to travel through
## a portal pair (and needs one mirror turned to reach it) before it can
## arrive at the Fusion Node; the GREEN input arrives directly from
## below. Two forced taps: the mirror, then the node. The player has to
## trace an input back across the board, not just look next to the node.

func _init() -> void:
	level_id = 26
	display_name = "Fusion Portal"
	grid_width = 6
	grid_height = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(0, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 2), "T26"),
		TilePlacement.make_portal(Vector2i(2, 5), "T26"),
		TilePlacement.make_emitter(Vector2i(4, 6), GridTypes.Direction.UP, GridTypes.BeamColor.GREEN),
		TilePlacement.make_fusion(Vector2i(4, 5), GridTypes.Direction.UP),
		TilePlacement.make_target(Vector2i(5, 5), GridTypes.BeamColor.YELLOW),
	]
	steps = [
		TutorialStepData.message("GREEN arrives from below. Where is RED?", Vector2i(4, 5)),
		TutorialStepData.message("A portal sends a beam to its partner.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(0, 2), "Turn this mirror to send RED into the portal."),
		TutorialStepData.message("RED came out of the other portal. Both inputs arrive.", Vector2i(4, 5)),
		TutorialStepData.require_tap(Vector2i(4, 5), "Turn the node toward the target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("If a node stays dark, trace each input back to its emitter."),
	]
