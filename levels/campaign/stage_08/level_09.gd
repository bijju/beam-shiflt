extends LevelData
## Campaign Level 79 — "Silent Third". Post-70 Levels 71-80, EXTREME
## TIER. The same mutual splitter-gate dependency and portal jump proven
## in Level 77, but the straight branch's final delivery now also
## depends on a completely separate THIRD emitter whose own short
## 2-mirror chain opens one more gate - a beam the player must notice
## and solve even though it has nothing to do with the splitter or the
## portal. True three-source whole-board dependency. Built by extending
## Level 77's already-validated geometry only past its portal tail,
## leaving the mutual-gate core, the whole reflected branch, and the
## portal jump byte-for-byte unchanged. See CAMPAIGN_DESIGN.md
## section 11k.

func _init() -> void:
	level_id = 9
	display_name = "Silent Third"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical mutual-gate-plus-portal core to Level 77 - but target A's final approach, after the portal jump, now also passes through a THIRD gate (g3) that only a completely separate third emitter can open, via its own 2-mirror chain. This is a genuinely independent beam source with no relationship to the splitter or the mutual g1/g2 dependency - the player must notice it exists and solve its own small 2-move puzzle before target A's route is complete, even though nothing about it interacts with the rest of the board except through gate g3. Splitter core and portal jump: byte-for-byte identical to Level 77 (mutual switch/gate dependency between the splitter's two branches, plus the straight branch's portal jump from (8,9) to (1,10)). New straight-branch tail: mirror (1,11) flips to BACKSLASH (RIGHT), through gate (3,11) [g3, opened by the third emitter] -> target A (8,11, BLUE). Third emitter (fires DOWN from (9,0)): mirror (9,2) flips to SLASH (DOWN->LEFT) - if left at its authored BACKSLASH the beam runs RIGHT and exits the grid immediately instead, and g3 never opens - switch (8,2) [g3] trips as soon as the beam reaches it, regardless of what happens next. Mirror (7,2) is a genuine decoy (solver-confirmed): its authored SLASH sends the beam DOWN column 7 toward gate (7,7) rather than further LEFT, so it can never reach the reflected branch's own switch (6,2) in column 6 - rotating it changes nothing about solvability, since nothing beyond the switch has any further purpose. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 13
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_blocker(Vector2i(3, 1)),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_switch(Vector2i(6, 7), "g1"),
		TilePlacement.make_gate(Vector2i(7, 7), "g2", false),
		TilePlacement.make_mirror(Vector2i(8, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(8, 9), "A"),
		TilePlacement.make_portal(Vector2i(1, 10), "A"),
		TilePlacement.make_mirror(Vector2i(1, 11), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(3, 11), "g3", false),
		TilePlacement.make_target(Vector2i(8, 11), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 2), "g2"),
		TilePlacement.make_gate(Vector2i(6, 4), "g1", false),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(9, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(9, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(8, 2), "g3"),
		TilePlacement.make_mirror(Vector2i(7, 2), GridTypes.MirrorOrientation.SLASH),
	]
