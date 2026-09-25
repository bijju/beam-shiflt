extends TutorialLevelData
## Tutorial T34 — "Sel Trial". Free-play check for the whole Selector pack (one overview
## message, one wait_for_solved, like T10/T20/T28). RED (WHITE emitter -> Selector -> RED
## Filter -> mirror M1) and GREEN (WHITE emitter -> GREEN Filter -> Portal pair) meet at a
## Fusion Node; its YELLOW output must pass a Gate that an independent emitter opens through
## mirror M2 and a Switch. Five taps: Selector x2 (UP -> RIGHT wall -> DOWN), M1, the node,
## M2. The Selector is load-bearing (RIGHT is walled, UP leaves the board), and the node's
## RED input depends on its chosen route.

func _init() -> void:
	level_id = 34
	display_name = "Sel Trial"
	grid_width = 7
	grid_height = 8
	tiles = [
		# RED input: emitter -> Selector -> RED Filter -> mirror M1 -> node (left side).
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter_selector(Vector2i(2, 1), GridTypes.Direction.UP),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_filter(Vector2i(2, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),

		# GREEN input: emitter -> GREEN Filter -> Portal pair -> node (top side).
		TilePlacement.make_emitter(Vector2i(6, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_filter(Vector2i(6, 1), GridTypes.BeamColor.GREEN),
		TilePlacement.make_portal(Vector2i(6, 2), "T34"),
		TilePlacement.make_portal(Vector2i(4, 2), "T34"),

		TilePlacement.make_fusion(Vector2i(4, 4), GridTypes.Direction.UP),

		# YELLOW output -> Gate -> target.
		TilePlacement.make_gate(Vector2i(5, 4), "T34G"),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.YELLOW),

		# Independent beam: emitter -> mirror M2 -> Switch (opens the Gate).
		TilePlacement.make_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(5, 5), "T34G"),
	]
	steps = [
		TutorialStepData.message("Final test: Selector, Filter, Portal, Fusion, Switch and Gate."),
		TutorialStepData.wait_for_solved("Work backward from the target. Hint is available."),
		TutorialStepData.message("Selectors are ready. Expect them in later levels."),
	]
