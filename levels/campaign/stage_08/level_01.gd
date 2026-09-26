extends LevelData
## Campaign Level 71 — "Deliberate Detour". Post-70 Levels 71-80
## (internal folder stage_08), MASTER ENTRY, continuing directly from
## Level 70's difficulty - no mechanic-teaching reset. See
## CAMPAIGN_DESIGN.md section 11k.
##
## The straight branch's mandatory portal detour ends at a switch that
## opens the reflected branch's gate - and the reflected branch's own
## return path passes back through that same switch (a harmless
## retrigger) before converging with the straight branch on one shared
## fixed mirror.

func _init() -> void:
	level_id = 1
	display_name = "Deliberate Detour"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: fixed mirror (7,8) is hit by both branches from perpendicular directions - straight arrives DOWN (BACKSLASH: DOWN->RIGHT, to target A east of it), reflected arrives RIGHT (BACKSLASH: RIGHT->DOWN, to target B south of it) - and reflected's own return path happens to cross straight's switch a second time on the way, a harmless retrigger since gates are monotonic. Straight branch (unconditional RIGHT off splitter (1,4)): mirror (2,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (2,2) instead - mirror (2,5) flips to BACKSLASH (RIGHT), into portal (3,5)/pair A -> exits (5,7) still moving RIGHT -> switch (6,7) [g1] -> mirror (7,7) flips to BACKSLASH (DOWN), into the shared mirror -> RIGHT -> target A (8,8, WHITE). Reflected branch: splitter flips to SLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (2,0) GREEN, through gate (3,0) [g1, opened by the straight branch's switch], mirror (4,0) flips to BACKSLASH (DOWN), mirror (4,1) flips to BACKSLASH (RIGHT), mirror (5,1) flips to BACKSLASH (DOWN), mirror (5,3) flips to BACKSLASH (RIGHT), mirror (6,3) flips to BACKSLASH (DOWN) (passing harmlessly back through switch (6,7) along the way), mirror (6,8) flips to BACKSLASH (RIGHT), into the shared mirror from the west -> DOWN -> target B (7,9, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (1,6) instead. INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(1, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(1, 6)),
		TilePlacement.make_blocker(Vector2i(2, 2)),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 5), "A"),
		TilePlacement.make_portal(Vector2i(5, 7), "A"),
		TilePlacement.make_switch(Vector2i(6, 7), "g1"),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(8, 8), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(2, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_gate(Vector2i(3, 0), "g1", false),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 9), GridTypes.BeamColor.GREEN),
	]
