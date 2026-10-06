extends TutorialLevelData
## Tutorial T38 - "Split Phase". Phase + Splitter. The straight-ahead beam always goes first (the splitter's
## main beam is simulated before its branch), so it flips the Phase Shifter to B; the branch beam travels
## round the top and meets the tile in PHASE B from above. "/" turns it LEFT back through the splitter, whose
## second branch goes DOWN to the target. "\" turns it right into a wall. The straight beam ends at the wall
## (4,2), so only the reflected branch can reach the target.

func _init() -> void:
	level_id = 38
	display_name = "Split Phase"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_phase_shifter(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(4, 2)),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(1, 4)),
	]
	steps = [
		TutorialStepData.message("The splitter makes two beams. The straight one reaches the Phase Shifter first and flips it to PHASE B.", Vector2i(3, 2)),
		TutorialStepData.message("The second beam comes round the top and meets the tile in PHASE B, so it is reflected.", Vector2i(3, 2)),
		TutorialStepData.require_tap(Vector2i(3, 2), "Choose the slash that sends the reflected beam back toward the splitter."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("The order beams arrive in decides which phase they meet."),
	]
