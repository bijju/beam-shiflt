extends TutorialLevelData
## Tutorial T21 — "Fusion Node". Introduces the Fusion Node alone: two
## different primary beams arrive, one new color leaves. RED from the
## left + GREEN from above = YELLOW. The node starts facing UP (the side
## GREEN arrives on), so it is dark until the player's single tap turns
## it to face the target. Output direction is only touched on lightly
## here - T22 is the lesson about it. See TUTORIAL_SYSTEM.md section 14.

func _init() -> void:
	level_id = 21
	display_name = "Fusion Node"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(2, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.GREEN),
		TilePlacement.make_fusion(Vector2i(2, 2), GridTypes.Direction.UP),
		TilePlacement.make_target(Vector2i(4, 2), GridTypes.BeamColor.YELLOW),
	]
	steps = [
		TutorialStepData.message("This is a Fusion Node. It merges two different colored beams into one.", Vector2i(2, 2)),
		TutorialStepData.message("RED + GREEN = YELLOW.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap the node to turn its output toward the target."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Two beams in, one new beam out."),
	]
