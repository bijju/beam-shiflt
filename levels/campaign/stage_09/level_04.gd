extends LevelData
## Campaign Level 84 — "Distant Relay". EXTREME+ TIER (Levels 81-90).
## Built by extending Level 76's already-validated two-stage relay
## geometry: emitter 1's final approach now jumps through a second
## portal into a totally separate corner of the board before reaching
## its target - a portal layered directly onto the relay pattern itself,
## which had only been recolored (not extended) before this pass.
## See CAMPAIGN_DESIGN.md section 11l.

func _init() -> void:
	level_id = 4
	display_name = "Distant Relay"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: identical two-stage relay core to Level 70/76 (emitter 1's switch opens emitter 2's early gate; only then can emitter 2's own switch open emitter 1's later gate) - but emitter 1's final approach, after clearing gate (6,5), now jumps through a SECOND portal at (7,7) into the opposite corner of the board before reaching its relocated target. Emitter 1 chain: mirror (1,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - into portal (1,3)/pair A -> exits (5,1) still moving DOWN -> mirror (5,2) flips to BACKSLASH (RIGHT) -> mirror (6,2) flips to BACKSLASH (DOWN, NOT the tempting UP that hits the blocker at (6,0)) -> switch (6,3) [g1] -> filter (6,4) BLUE -> through gate (6,5) [g2, opened by emitter 2's switch] -> mirror (6,6) flips to BACKSLASH (RIGHT) -> mirror (7,6) flips to BACKSLASH (DOWN), into portal (7,7)/pair B -> exits (5,8) still moving DOWN -> mirror (5,9) flips to BACKSLASH (RIGHT) -> target A (7,9, BLUE). Emitter 2 chain (identical to Level 70/76): mirror (1,7) flips to BACKSLASH (DOWN), through gate (1,8) [g1, opened by emitter 1's switch], mirror (1,9) flips to BACKSLASH (RIGHT), filter (2,9) RED, mirror (3,9) flips to SLASH (UP), switch (3,8) [g2], filter (3,7) BLUE (overwrites RED), mirror (3,6) flips to BACKSLASH (LEFT), mirror (2,6) flips to BACKSLASH (UP), mirror (2,5) flips to SLASH (RIGHT), into target B (4,5, BLUE). INTENTIONAL DECOY: mirror (8,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 12
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
		TilePlacement.make_portal(Vector2i(7, 7), "B"),
		TilePlacement.make_portal(Vector2i(5, 8), "B"),
		TilePlacement.make_mirror(Vector2i(5, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 9), GridTypes.BeamColor.BLUE),
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
