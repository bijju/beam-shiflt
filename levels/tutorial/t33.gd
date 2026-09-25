extends TutorialLevelData
## Tutorial T33 — "Sel + Fusion". GREEN reaches the Fusion Node directly; RED can only reach
## it through the Selector (any other output misses the node - the Selector is genuinely
## load-bearing). The node already faces the target, so both taps go to the Selector
## (UP -> RIGHT wall -> DOWN). Existing Fusion rules unchanged: RED + GREEN = YELLOW.

func _init() -> void:
	level_id = 33
	display_name = "Sel + Fusion"
	grid_width = 6
	grid_height = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_splitter_selector(Vector2i(2, 1), GridTypes.Direction.UP),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.GREEN),
		TilePlacement.make_fusion(Vector2i(2, 5), GridTypes.Direction.RIGHT),
		TilePlacement.make_target(Vector2i(5, 5), GridTypes.BeamColor.YELLOW),
	]
	steps = [
		TutorialStepData.message("The Selector can control a Fusion input.", Vector2i(2, 1)),
		TutorialStepData.message("GREEN reaches the node directly. RED must arrive through the Selector.", Vector2i(2, 5)),
		TutorialStepData.message("RED + GREEN = YELLOW. Choose the path that completes it.", Vector2i(5, 5)),
		TutorialStepData.require_tap(Vector2i(2, 1), "Tap the Selector."),
		TutorialStepData.require_tap(Vector2i(2, 1), "RIGHT is a wall. Tap again."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("A Selector decides which beams a Fusion Node receives."),
	]
