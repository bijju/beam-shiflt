extends TutorialLevelData
## Tutorial T03 — "Locked In". Teaches: BLOCKER tiles stop the beam
## completely, and FIXED mirrors (rotatable=false) redirect the beam
## exactly like normal ones but can never be rotated by the player -
## MirrorTile._gui_input() already rejects taps on them and shows a lock
## icon (scripts/gameplay/mirror.gd), so no tutorial-only interaction
## rule is needed here at all - the real game mechanic teaches itself
## once highlighted.

func _init() -> void:
	level_id = 3
	display_name = "Locked In"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_blocker(Vector2i(2, 3)),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_target(Vector2i(4, 0)),
	]
	steps = [
		TutorialStepData.message("Two new pieces this time: blockers and fixed mirrors."),
		TutorialStepData.message("This is a blocker. The beam stops here completely - nothing passes through.", Vector2i(2, 3)),
		TutorialStepData.message("This mirror has a lock icon - it's FIXED. It still redirects the beam, but you can never rotate it.", Vector2i(2, 0)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Only this mirror can be rotated. Tap it to send the beam up, toward the fixed mirror."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("The fixed mirror did the rest on its own. Not every piece is yours to control."),
	]
