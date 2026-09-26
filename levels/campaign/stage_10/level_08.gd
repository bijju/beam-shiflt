extends LevelData
## Campaign Level 98 — "Triple Inference". FINAL CAMPAIGN BLOCK
## (Levels 91-100), FINAL-EXAM+ TIER (backward reasoning + color/order
## logic). Built by extending Level 91's already-validated splitter/
## fixed-mirror/backward-reasoning geometry: the reflected branch's
## early path now ALSO passes through a gate opened only by a
## completely separate third emitter, deepening the backward-reasoning
## chain the player must trace (target <- fixed mirror <- filter order
## <- gate <- third emitter). See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 8
	display_name = "Triple Inference"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical fixed-mirror/backward-reasoning core to Level 91 - but the reflected branch's own early path now ALSO passes through a new gate (1,1) [g3, opened only by a third, completely separate emitter], so the full backward chain for target B becomes: target color <- fixed mirror's single fixed orientation <- filter order (BLUE then RED) <- gate g1 (from the straight branch's switch) <- gate g3 (from the third emitter) - five links deep. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - mirror (3,5) flips to BACKSLASH (RIGHT), filter (4,5) RED, into the shared fixed mirror -> DOWN -> filter (5,6) GREEN (overwrites RED) -> mirror (5,7) flips to BACKSLASH (RIGHT) -> mirror (6,7) flips to BACKSLASH (DOWN) -> switch (6,8) [g1] -> target A (6,9, GREEN). Reflected branch: splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), through gate (1,1) [g3, opened by the third emitter], mirror (1,0) flips to SLASH (RIGHT), filter (3,0) BLUE, mirror (4,0) flips to BACKSLASH (DOWN), filter (4,1) RED (overwrites BLUE), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), into the shared fixed mirror from the north -> RIGHT -> through gate (6,5) [g1, opened by the straight branch's switch] -> mirror (7,5) flips to SLASH (UP) -> mirror (7,4) flips to SLASH (RIGHT) -> target B (8,4, RED). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. Third emitter (fires DOWN from (8,0), a completely separate short chain kept clear of both branches' own rows/columns): mirror (8,1) flips to SLASH (LEFT) - if left at its authored BACKSLASH the beam runs RIGHT and exits the grid instead, and g3 never opens - switch (6,1) [g3] -> blocker (5,1) stops the beam there, harmlessly, well before it would otherwise reach the reflected branch's own filter (4,1). INTENTIONAL DECOY: mirror (0,9) is never touched by any beam in any configuration (solver-confirmed)."
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
		TilePlacement.make_filter(Vector2i(5, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 8), "g1"),
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(1, 1), "g3", false),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(6, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(7, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(8, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(6, 1), "g3"),
		TilePlacement.make_blocker(Vector2i(5, 1)),
	]
