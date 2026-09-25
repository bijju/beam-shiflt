extends LevelData
## Campaign Level 85 — "Convergence Threshold". MAJOR CHECKPOINT
## (Levels 81-90). Built by extending Level 75's already-validated
## splitter/shared-mirror/target-continuation geometry: the reflected
## branch's own early path now also passes through a NEW gate opened
## only by a completely separate third emitter, so the reflected
## branch's single target ends up depending on THREE independent
## sources - the third emitter (early), the straight branch's own
## switch (late), and its own filter-order color chain throughout.
## See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 5
	display_name = "Convergence Threshold"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: fixed mirror (5,5) is hit by both branches from perpendicular directions carrying independently-tracked colors (straight: RED then BLUE; reflected: RED then GREEN), the straight branch's beam continues past its own target to trip switch (6,8) [g1] gating the reflected branch's final approach through gate (6,5) - exactly as in Level 75 - AND the reflected branch's own early path, before it ever reaches the shared mirror, now also passes through a NEW gate (1,1) [g3, opened only by a third, completely separate emitter]. The reflected branch's single target therefore depends on three independent things being true at once: the third emitter's short chain, the straight branch's entire chain (not just its own switch), and its own two-filter color order. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - mirror (3,5) flips to BACKSLASH (RIGHT), filter (4,5) RED, into the shared mirror -> DOWN -> filter (5,6) BLUE (overwrites RED) -> mirror (5,7) flips to BACKSLASH (RIGHT) -> mirror (6,7) flips to BACKSLASH (DOWN) -> switch (6,8) [g1] -> target A (6,9, BLUE). Reflected branch: splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), through gate (1,1) [g3, opened by the third emitter], mirror (1,0) flips to SLASH (RIGHT), filter (3,0) RED, mirror (4,0) flips to BACKSLASH (DOWN), filter (4,1) GREEN (overwrites RED), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), into the shared mirror from the north -> RIGHT -> through gate (6,5) [g1, opened by the straight branch's switch] -> mirror (7,5) flips to SLASH (UP) -> mirror (7,4) flips to SLASH (RIGHT) -> target B (8,4, GREEN). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. Third emitter (fires DOWN from (8,0), a completely separate short chain passing harmlessly through the reflected branch's own filter (4,1) along the way): mirror (8,1) flips to SLASH (LEFT) - if left at its authored BACKSLASH the beam runs RIGHT and exits the grid immediately, and g3 never opens - switch (3,1) [g3] -> blocker (2,1) stops the beam there, harmlessly, well before it would otherwise reach gate (1,1). INTENTIONAL DECOY: mirror (0,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 14
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
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.BLUE),
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
