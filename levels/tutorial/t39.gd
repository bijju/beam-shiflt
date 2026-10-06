extends TutorialLevelData
## Tutorial T39 - "Phase Trial". Phase + Splitter + Switch + Gate, free play (one overview message and one
## wait, like T28/T34). The straight beam passes the Phase Shifter (A) and stops at a closed Gate; the branch
## beam meets the tile in PHASE B and, with "/", returns through the splitter whose second branch goes DOWN onto
## a Switch that opens the Gate - so the straight beam reaches the target. Two taps: the mirror at (1,0) (so
## the branch reaches the tile at all) and the Phase Shifter.

func _init() -> void:
	level_id = 39
	display_name = "Phase Trial"
	grid_width = 6
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_splitter(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_phase_shifter(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(4, 2), "T39G"),
		TilePlacement.make_target(Vector2i(5, 2)),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_switch(Vector2i(1, 3), "T39G"),
	]
	steps = [
		TutorialStepData.message("Final test: a Phase Shifter, a Splitter, a Switch and a Gate."),
		TutorialStepData.wait_for_solved("The gate is shut. Find the beam that can reach the switch. Hint is available."),
		TutorialStepData.message("Phase Shifters are ready. Expect them in later levels."),
	]
