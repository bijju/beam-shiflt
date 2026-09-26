extends TutorialLevelData
## Tutorial T08 — "Through the Portal". Teaches: a beam entering one
## PORTAL of a paired pair instantly exits the other, preserving
## direction and color exactly (no portal orientation exists - see
## DECISIONS.md D17). Portals are not player-interactive (no tile_clicked
## - scripts/gameplay/portal.gd is purely visual); the player only
## controls whether the beam is routed INTO one.

func _init() -> void:
	level_id = 8
	display_name = "Through the Portal"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_portal(Vector2i(2, 0), "p1"),
		TilePlacement.make_portal(Vector2i(4, 4), "p1"),
		TilePlacement.make_target(Vector2i(4, 2)),
	]
	steps = [
		TutorialStepData.message("This is a portal.", Vector2i(2, 0)),
		TutorialStepData.message("It's paired with this one. A beam entering either portal instantly exits the other - same direction, same color, no matter how far apart they are.", Vector2i(4, 4)),
		TutorialStepData.require_tap(Vector2i(2, 2), "Tap this mirror to send the beam up, into the first portal."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("In one portal, out the other, straight to the target."),
	]
