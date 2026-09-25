extends TutorialLevelData
## Tutorial T10 — "Graduation". Teaches: multiple emitters fire
## completely independent beams (LaserSystem already loops over every
## EMITTER tile with zero special-casing - proven by dev regression
## level 13 "Two Sources"), and serves as the tutorial's final,
## lightly-guided challenge. Deliberately minimal hand-holding - a
## single free-play step covers the whole puzzle, matching the brief's
## "by T10, reduce hand-holding" instruction. Still easier than any real
## Campaign level (Stage 1 Level 1 already used a comparable single-
## mirror route; this just does two of them).

func _init() -> void:
	level_id = 10
	display_name = "Graduation"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(2, 0)),
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 4)),
	]
	steps = [
		TutorialStepData.message("Final lesson: multiple emitters. Two completely independent beams, each needing its own route."),
		TutorialStepData.wait_for_solved("Use everything you've learned. Rotate both mirrors to activate both targets."),
		TutorialStepData.message("Tutorial complete. Every mechanic you just practiced shows up throughout the real campaign. Good luck out there."),
	]
