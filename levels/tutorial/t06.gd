extends TutorialLevelData
## Tutorial T06 — "True Color". Teaches: beams can be colored, and a
## colored target only accepts an exact color match - GridTypes.
## target_accepts_color() is the real, unmodified rule (WHITE is neutral
## on both ends, a colored target rejects anything else). The RED beam
## visibly crosses a non-required GREEN target without activating it
## (still WHITE... no, still RED, wrong color) before the player routes
## it to the matching RED target.

func _init() -> void:
	level_id = 6
	display_name = "True Color"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(2, 2), GridTypes.BeamColor.GREEN, false),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 4), GridTypes.BeamColor.RED),
	]
	steps = [
		TutorialStepData.message("This emitter fires a RED beam. Colored beams only activate matching colored targets.", Vector2i(0, 2)),
		TutorialStepData.message("Watch: the beam crosses this GREEN target and nothing happens. Wrong color, no activation - even though the beam passes right over it.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(3, 2), "This mirror redirects the beam toward the RED target instead - tap it."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Correct color, correct target. Color is part of the puzzle, not just decoration."),
	]
