extends TutorialLevelData
## Tutorial T36 - "Phase Reflect". The beam passes the Phase Shifter (PHASE A), loops around fixed
## mirrors and a RED filter, and returns to the same tile, now in PHASE B, where it is reflected by the
## tile's orientation. The RED target above the tile can only be lit by the returning (red) beam; the
## white outbound beam crossing it does not count. One tap chooses the slash.
## Geometry: E(0,0) -> M1(3,0) down column 3 -> P(3,2) straight -> M2(3,4) -> M3(1,4) -> M4(1,2) -> Filter(2,2)
## -> P in phase B: "/" sends it UP through the target and out via M1; "\" sends it round again (PHASE A, straight on).

func _init() -> void:
	level_id = 36
	display_name = "Phase Reflect"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_phase_shifter(Vector2i(3, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_filter(Vector2i(2, 2), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(3, 1), GridTypes.BeamColor.RED),
	]
	steps = [
		TutorialStepData.message("The beam passes the Phase Shifter once, loops around and comes back to it.", Vector2i(3, 2)),
		TutorialStepData.message("On its return the tile is in PHASE B: it REFLECTS the beam, along the slash you choose.", Vector2i(3, 2)),
		TutorialStepData.require_tap(Vector2i(3, 2), "Only the returning RED beam lights the target. Tap to choose the reflection."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("PHASE B reflects like a mirror. The tile then flips back to PHASE A."),
	]
