extends TutorialLevelData
## Tutorial T16 — "Two Sides". One rotatable One-Way Reflector, shared by
## TWO beams from different directions - rotating it affects both beams
## differently at once. The rightward beam always reflects (only the
## bend direction changes); the downward beam only reflects in ONE of
## the two orientations, passing straight through in the other. Only one
## orientation (BACKSLASH) satisfies both required targets simultaneously
## - requires genuine "will this side reflect or not" reasoning about
## both beams before rotating, per the brief's "pass-through vs
## reflection reasoning" requirement.

func _init() -> void:
	level_id = 16
	display_name = "Two Sides"
	grid_width = 8
	grid_height = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN),
		TilePlacement.make_one_way_reflector(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH, true),
		TilePlacement.make_target(Vector2i(4, 6)),
		TilePlacement.make_target(Vector2i(7, 4)),
	]
	steps = [
		TutorialStepData.message("One reflector, two beams, from two different directions.", Vector2i(4, 4)),
		TutorialStepData.message("The right-moving beam always reflects - rotating only changes which way it bends. The downward beam only reflects in ONE orientation - the other, it passes straight through."),
		TutorialStepData.require_tap(Vector2i(4, 4), "Rotate it. Think about BOTH beams before you commit."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Same tile, two completely different effects, depending on which side each beam hits."),
	]
