extends LevelData
## Campaign Level 70 — "Grand Convergence". MAJOR CAMPAIGN MILESTONE.
## Post-60 Levels 61-70 finale. Two emitters in a genuine TWO-STAGE
## relay dependency: emitter 1's switch opens the gate on emitter 2's
## EARLY path, and emitter 2's switch (reached only after that) opens
## the gate on emitter 1's OWN LATER path - neither branch can finish
## without the other going first, and E1 also needs the other to have
## already started. See CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 10
	display_name = "Grand Convergence"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: a two-stage relay - emitter 1's switch (g1) opens the gate blocking emitter 2's early path, and emitter 2's switch (g2), reached only after passing that gate, opens a SECOND gate blocking emitter 1's OWN later path - resolved automatically by simulate_until_stable's multi-pass evaluation (pass 1: switch1 trips, gate1 opens, but emitter 2 hasn't reached switch2 yet so gate2 stays closed and emitter 1 is blocked; pass 2: emitter 2 now passes gate1 and trips switch2; pass 3: emitter 1 now passes gate2 and reaches its target) - both emitters' entire routes must be wired correctly from the start for this cascade to complete. Emitter 1 chain: mirror (1,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - into portal (1,3)/pair A -> exits (5,1) still moving DOWN -> mirror (5,2) flips to BACKSLASH (RIGHT) -> mirror (6,2) flips to BACKSLASH (DOWN, NOT the tempting UP that hits the blocker at (6,0)) -> switch (6,3) [g1] -> filter (6,4) RED -> through gate (6,5) [g2, opened by emitter 2's switch] -> mirror (6,6) flips to BACKSLASH (RIGHT) -> mirror (7,6) flips to BACKSLASH (DOWN) -> target A (7,7, RED). Emitter 2 chain: mirror (1,7) flips to BACKSLASH (DOWN), through gate (1,8) [g1, opened by emitter 1's switch], mirror (1,9) flips to BACKSLASH (RIGHT), filter (2,9) GREEN, mirror (3,9) flips to SLASH (UP), switch (3,8) [g2], filter (3,7) BLUE (overwrites GREEN), mirror (3,6) flips to BACKSLASH (LEFT), mirror (2,6) flips to BACKSLASH (UP), mirror (2,5) flips to SLASH (RIGHT), into target B (4,5, BLUE). INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
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
		TilePlacement.make_filter(Vector2i(6, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_gate(Vector2i(6, 5), "g2", false),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(7, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 7), GridTypes.BeamColor.RED),
		TilePlacement.make_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(1, 8), "g1", false),
		TilePlacement.make_mirror(Vector2i(1, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(2, 9), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(3, 8), "g2"),
		TilePlacement.make_filter(Vector2i(3, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 5), GridTypes.BeamColor.BLUE),
	]
