extends LevelData
## Campaign Level 95 — "Final Threshold". FINAL-EXAM CHECKPOINT
## (Levels 91-100). Built by extending Level 85's already-validated
## splitter/shared-mirror/target-continuation/third-emitter geometry:
## the straight branch's delivery now jumps through a portal into a
## distant, previously-unused corner of the board, gaining a THIRD
## filter in the process - four independent things must now be true at
## once for the two targets combined (the third emitter's gate, the
## straight branch's own switch, the shared mirror's fixed orientation,
## and the portal-routed color chain). This is the moment the player
## should recognize they are in the campaign's final stretch.
## See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 5
	display_name = "Final Threshold"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical splitter/shared-mirror/third-emitter core to Level 85 (reflected branch's early path gated by a third emitter; straight branch's switch gates reflected's final approach) - but the straight branch's own delivery, after tripping that switch, now jumps through a portal into the opposite corner of the board and picks up a THIRD filter before reaching its relocated target - so the straight branch's own final color can no longer be verified by local inspection near the switch. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - mirror (3,5) flips to BACKSLASH (RIGHT), filter (4,5) RED, into the shared mirror -> DOWN -> filter (5,6) BLUE (overwrites RED) -> mirror (5,7) flips to BACKSLASH (RIGHT) -> mirror (6,7) flips to BACKSLASH (DOWN) -> switch (6,8) [g1], into portal (6,9)/pair P -> exits (0,6) still moving DOWN -> mirror (0,7) flips to BACKSLASH (RIGHT) - if left at its authored SLASH the beam runs LEFT and exits the grid instead - filter (2,7) GREEN (overwrites BLUE) -> target A (4,7, GREEN). Reflected branch (identical to Level 85): splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), through gate (1,1) [g3, opened by the third emitter], mirror (1,0) flips to SLASH (RIGHT), filter (3,0) RED, mirror (4,0) flips to BACKSLASH (DOWN), filter (4,1) GREEN (overwrites RED), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> through gate (6,5) [g1, opened by the straight branch's switch] -> mirror (7,5) flips to SLASH (UP) -> mirror (7,4) flips to SLASH (RIGHT) -> target B (8,4, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. Third emitter (fires DOWN from (8,0), identical to Level 85): mirror (8,1) flips to SLASH (LEFT) - switch (3,1) [g3] -> blocker (2,1) stops the beam there, harmlessly. INTENTIONAL DECOY: mirror (0,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 15
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(0, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_filter(Vector2i(5, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 8), "g1"),
		TilePlacement.make_portal(Vector2i(6, 9), "P"),
		TilePlacement.make_portal(Vector2i(0, 6), "P"),
		TilePlacement.make_mirror(Vector2i(0, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(4, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(1, 1), "g3", false),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 1), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(6, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(7, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.GREEN),
		TilePlacement.make_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(8, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(3, 1), "g3"),
		TilePlacement.make_blocker(Vector2i(2, 1)),
	]
