extends LevelData
## Campaign Level 76 — "Reverse Relay". Post-70 Levels 71-80, MASTER+
## TIER. The same two-stage relay dependency proven in Level 70
## (emitter 1's switch opens emitter 2's early gate; only then can
## emitter 2's switch open emitter 1's later gate), but this time the
## player is expected to reason BACKWARD from both targets' required
## colors to deduce which gate must open first, before ever touching a
## mirror. See CAMPAIGN_DESIGN.md section 11k.

func _init() -> void:
	level_id = 6
	display_name = "Reverse Relay"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: the same two-stage relay structure as Level 70 (a second use of this pattern, deliberately, since it is proven and the brief calls for pushing relay logic further) - but the color assignments (target A needs BLUE from a single filter; target B needs BLUE too, from a 2-filter RED-then-BLUE order) mean the player has to work out both branches' full color chains BEFORE knowing whether the relay direction even matters for color, not just for gating. Emitter 1 chain: mirror (1,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - into portal (1,3)/pair A -> exits (5,1) still moving DOWN -> mirror (5,2) flips to BACKSLASH (RIGHT) -> mirror (6,2) flips to BACKSLASH (DOWN, NOT the tempting UP that hits the blocker at (6,0)) -> switch (6,3) [g1] -> filter (6,4) BLUE -> through gate (6,5) [g2, opened by emitter 2's switch] -> mirror (6,6) flips to BACKSLASH (RIGHT) -> mirror (7,6) flips to BACKSLASH (DOWN) -> target A (7,7, BLUE). Emitter 2 chain: mirror (1,7) flips to BACKSLASH (DOWN), through gate (1,8) [g1, opened by emitter 1's switch], mirror (1,9) flips to BACKSLASH (RIGHT), filter (2,9) RED, mirror (3,9) flips to SLASH (UP), switch (3,8) [g2], filter (3,7) BLUE (overwrites RED), mirror (3,6) flips to BACKSLASH (LEFT), mirror (2,6) flips to BACKSLASH (UP), mirror (2,5) flips to SLASH (RIGHT), into target B (4,5, BLUE). INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(8, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(1, 3), "A"),
		TilePlacement.make_portal(Vector2i(5, 1), "A"),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_blocker(Vector2i(6, 0)),
		TilePlacement.make_mirror(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 3), "g1"),
		TilePlacement.make_filter(Vector2i(6, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_gate(Vector2i(6, 5), "g2", false),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(1, 8), "g1", false),
		TilePlacement.make_mirror(Vector2i(1, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 9), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(3, 8), "g2"),
		TilePlacement.make_filter(Vector2i(3, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 5), GridTypes.BeamColor.BLUE),
	]
