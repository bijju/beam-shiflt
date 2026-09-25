extends TutorialLevelData
## Tutorial T07 — "Recolor". Teaches: a FILTER repaints any beam that
## passes through it, unconditionally - it never bends the beam
## (direction is unchanged), it's fixed (never rotatable, no orientation
## at all), and mirrors/splitters downstream preserve whatever color the
## beam currently has. Uses the real Stage 5 filter mechanic directly
## (see DECISIONS.md D16/D59) - nothing tutorial-only.

func _init() -> void:
	level_id = 7
	display_name = "Recolor"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.RED),
	]
	steps = [
		TutorialStepData.message("This is a filter. Unlike a mirror, it never bends the beam - it repaints its color instead.", Vector2i(2, 1)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap this mirror to send the beam up, through the filter."),
		TutorialStepData.message("The beam is RED now. A filter overwrites color completely - it doesn't matter what color came in.", Vector2i(4, 0)),
		TutorialStepData.wait_for_solved("Rotate the last mirror yourself to reach the RED target."),
		TutorialStepData.message("Filter, then color change, then matching target. That's the whole trick."),
	]
