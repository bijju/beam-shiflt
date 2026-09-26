extends TutorialLevelData
## Tutorial T25 — "Fusion + Filter". Both emitters shoot plain WHITE beams
## (which a Fusion Node cannot accept - only RED/GREEN/BLUE are valid
## inputs); a GREEN Filter and a BLUE Filter on the input paths recolor
## them into a valid pair. GREEN + BLUE = CYAN. The closing message notes
## the flip side: a Filter placed AFTER a node would repaint its output.

func _init() -> void:
	level_id = 25
	display_name = "Fusion Filter"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_filter(Vector2i(1, 2), GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(2, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_filter(Vector2i(2, 1), GridTypes.BeamColor.BLUE),
		TilePlacement.make_fusion(Vector2i(2, 2), GridTypes.Direction.UP),
		TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.CYAN),
	]
	steps = [
		TutorialStepData.message("These emitters shoot WHITE. A node only accepts RED, GREEN or BLUE.", Vector2i(1, 2)),
		TutorialStepData.message("Filters recolor the beams first: GREEN + BLUE = CYAN.", Vector2i(2, 1)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Turn the node toward the CYAN target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Put Filters BEFORE a node. After it, a Filter repaints the new color."),
	]
