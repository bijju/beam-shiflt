extends TutorialLevelData
## Tutorial T37 - "Phase Cycle". One tile, three visits: A (straight), B (reflect), A (straight again). The beam
## crosses the Phase Shifter (visit 1, A) into a splitter whose two beams run round the rectangular loop on the
## right in opposite directions. One of them returns to the shifter from the right while it is in PHASE B
## (visit 2) and is reflected; the other arrives next in PHASE A (visit 3) and passes straight through.
## "\" sends the visit-2 beam UP into the target; "/" sends it down off the board. Without the Phase Shifter
## nothing ever turns up, so the target stays dark - the tile is genuinely required.

func _init() -> void:
	level_id = 37
	display_name = "Phase Cycle"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_phase_shifter(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_splitter(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(2, 1)),
	]
	steps = [
		TutorialStepData.message("The first beam passes the Phase Shifter in PHASE A (straight). The splitter then sends beams round the loop on the right.", Vector2i(2, 2)),
		TutorialStepData.message("Visit 1: PHASE A, straight. Visit 2: PHASE B, reflect. Visit 3: PHASE A, straight again.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Choose the backslash '\\': the beam that meets the tile in PHASE B is reflected up into the target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("A, B, A, B... the phase alternates with every visit - and the tile was needed."),
	]
