extends TutorialLevelData
## Tutorial T11 — "Welcome to Refractions". Era 2's first tutorial.
## Teaches nothing new mechanically - purely a recap of the tap-to-rotate
## interaction under the new Era 2 visual theme, exactly like T01 did for
## Era 1, before T12+ introduce the four new mechanics. See
## ERA_2_DESIGN.md "Guided tutorial progression".

func _init() -> void:
	level_id = 11
	display_name = "Welcome to Refractions"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 4)),
	]
	steps = [
		TutorialStepData.message("Welcome to Refractions. The rules you already know haven't changed - new mechanics are coming."),
		TutorialStepData.message("One mirror, in the wrong position.", Vector2i(2, 2)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap it to rotate, exactly like before."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Same beam, same targets, same mirrors. Now let's see what's new."),
	]
