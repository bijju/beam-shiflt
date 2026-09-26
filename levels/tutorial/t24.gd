extends TutorialLevelData
## Tutorial T24 — "Three Colors". RED + GREEN + BLUE = WHITE. A WHITE
## target would accept ANY beam, so the proof of a real WHITE output is
## a Prism: only WHITE splits into three channels, lighting a RED, a
## GREEN and a BLUE target (RED straight, GREEN turns up, BLUE turns
## down for a beam travelling right). The node starts facing UP - the
## GREEN input side - so only RED + BLUE merge (MAGENTA, which the
## Prism does not split) until the player's one tap frees all three.

func _init() -> void:
	level_id = 24
	display_name = "Three Colors"
	grid_width = 6
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(2, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(2, 4), GridTypes.Direction.UP, GridTypes.BeamColor.BLUE),
		TilePlacement.make_fusion(Vector2i(2, 2), GridTypes.Direction.UP),
		TilePlacement.make_prism(Vector2i(4, 2)),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(4, 1), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(4, 3), GridTypes.BeamColor.BLUE),
	]
	steps = [
		TutorialStepData.message("A node can merge all three colors: RED + GREEN + BLUE = WHITE.", Vector2i(2, 2)),
		TutorialStepData.message("The output faces GREEN's side, so GREEN can't enter. Only RED + BLUE merged: MAGENTA.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Turn the output to a free side so all three beams arrive."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("WHITE! The Prism splits it back into RED, GREEN and BLUE."),
	]
