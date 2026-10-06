extends TutorialLevelData
## Tutorial T35 - "Phase Pass". Introduces the Phase Shifter alone: in PHASE A a beam passes straight
## through it, whatever its orientation (so the tile is locked here). The beam then meets a mirror
## that needs one tap. The core art flips to PHASE B after the pass: a fresh simulation (every move)
## always starts in PHASE A again. See TUTORIAL_SYSTEM.md "Phase pack".

func _init() -> void:
	level_id = 35
	display_name = "Phase Pass"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_phase_shifter(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
	steps = [
		TutorialStepData.message("This is a Phase Shifter. A beam reaching it in PHASE A passes straight through.", Vector2i(2, 2)),
		TutorialStepData.message("After the beam passes, the core flips to PHASE B. Every move starts again in PHASE A.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(4, 2), "The beam went straight on. Tap the mirror to send it up."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("PHASE A: straight through. Next: what PHASE B does."),
	]
