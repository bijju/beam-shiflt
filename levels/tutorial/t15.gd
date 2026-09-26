extends TutorialLevelData
## Tutorial T15 — "Direction Matters". Introduces the ONE_WAY_REFLECTOR.
## A beam travelling RIGHT is always reflective for this tile (see
## GridTypes.one_way_reflector_is_reflective()) - rotating it (the exact
## same tap-to-rotate interaction as a mirror) changes WHICH direction it
## bends to, not whether it bends. One required rotation.

func _init() -> void:
	level_id = 15
	display_name = "Direction Matters"
	grid_width = 4
	grid_height = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH, true),
		TilePlacement.make_target(Vector2i(3, 0)),
	]
	steps = [
		TutorialStepData.message("This looks like a mirror, but it's a One-Way Reflector.", Vector2i(3, 2)),
		TutorialStepData.message("It only reflects a beam that hits its reflective side. Hit the other side, and the beam passes straight through, untouched."),
		TutorialStepData.require_tap(Vector2i(3, 2), "Rotate it to bend this beam up, into the target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Same tap-to-rotate you already know - but now which side you hit really matters."),
	]
