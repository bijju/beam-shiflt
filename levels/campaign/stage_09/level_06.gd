extends LevelData
## Campaign Level 86 — "Reciprocal Corridor". EXTREME+ TIER
## (Levels 81-90). Built by extending Level 78's already-validated
## shared-gate/portal geometry: emitter 1's final delivery now jumps
## through a SECOND portal that ends at a gate opened only by emitter
## 2's own post-target delayed consequence - so the shared-gate
## dependency that already let either emitter open the crossing for both
## is joined by a second, opposite-direction dependency (emitter 2's
## delayed consequence gates emitter 1's very last step).
## See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 6
	display_name = "Reciprocal Corridor"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical shared-gate core to Level 72/78 (gate (4,6) is a single shared corridor crossed by both emitters from perpendicular directions; EITHER emitter's own switch opens it for both) - but now emitter 1's final delivery, after the first portal jump, passes through a SECOND portal that ends at a gate only emitter 2's own post-target continuation can open, so the two emitters end up depending on each other in both directions (either can open the shared gate for both; only emitter 2's completion can release emitter 1's final delivery). Emitter 1 chain (identical to Level 78 up to the first portal jump): mirror (1,6) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,4) instead - filter (1,7) RED, mirror (1,9) flips to BACKSLASH (RIGHT), switch (2,9) [g1], mirror (3,9) is ALREADY correctly authored at SLASH (a genuine zero-move load-bearing piece), filter (3,7) BLUE (overwrites RED), mirror (3,6) flips to SLASH, through the shared gate (4,6) -> mirror (5,6) flips to BACKSLASH (DOWN), through the harmless shared transit cell (5,6), into portal (5,9)/pair A -> exits (8,9) still moving DOWN -> mirror (8,10) flips to BACKSLASH (RIGHT) -> mirror (9,10) flips to BACKSLASH (DOWN) -> mirror (9,11) flips to SLASH (LEFT), into portal (8,11)/pair B -> exits (2,11) still moving LEFT -> through gate (1,11) [g2, opened only by emitter 2's post-target continuation] -> target A (0,11, BLUE). Emitter 2 chain (identical core to Level 72/78, with a new delayed-consequence tail): switch (4,1) [g1], mirror (4,2) flips to BACKSLASH (RIGHT) -> mirror (5,2) flips to BACKSLASH (DOWN), filter (4,5) GREEN, mirror (5,4) flips to SLASH (LEFT), mirror (4,4) flips to SLASH (DOWN), through the SAME shared gate from the north -> mirror (4,7) flips to BACKSLASH (RIGHT) -> target B (6,7, GREEN), continues RIGHT past it (targets do not stop beams) into switch (7,7) [g2] -> blocker (8,7) stops the beam there, harmlessly, well clear of emitter 1's own portal-B corridor. INTENTIONAL DECOY: mirror (0,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 12
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 4)),
		TilePlacement.make_filter(Vector2i(1, 7), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 9), "g1"),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(4, 6), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(5, 9), "A"),
		TilePlacement.make_portal(Vector2i(8, 9), "A"),
		TilePlacement.make_mirror(Vector2i(8, 10), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(9, 10), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(9, 11), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_portal(Vector2i(8, 11), "B"),
		TilePlacement.make_portal(Vector2i(2, 11), "B"),
		TilePlacement.make_gate(Vector2i(1, 11), "g2", false),
		TilePlacement.make_target(Vector2i(0, 11), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(4, 1), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 5), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(7, 7), "g2"),
		TilePlacement.make_blocker(Vector2i(8, 7)),
		TilePlacement.make_mirror(Vector2i(0, 0), GridTypes.MirrorOrientation.SLASH),
	]
