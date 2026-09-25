extends LevelData
## Campaign Level 69 — "Color Conflict". Post-60 Levels 61-70, MASTER+
## TIER. Two emitters, each running its own independent 2-filter-order
## chain to its own colored target - emitter 2 physically gated behind
## emitter 1's switch, so neither chain's color puzzle even matters
## until the global dependency is understood first. See
## CAMPAIGN_DESIGN.md section 11j.

func _init() -> void:
	level_id = 9
	display_name = "Color Conflict"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 2 is gated at (2,1) until emitter 1's beam trips the switch at (3,5) - which itself only happens after four correctly-placed mirrors - so the player has to solve emitter 1's whole route before emitter 2's own independent filter-order puzzle (GREEN then RED, last wins) even becomes reachable. Emitter 1 chain: mirror (1,3) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,1) instead - mirror (1,4) flips to BACKSLASH (RIGHT), mirror (3,4) flips to BACKSLASH (DOWN), switch (3,5) [g1], mirror (3,6) flips to BACKSLASH (RIGHT), filter (4,6) RED, mirror (5,6) flips to BACKSLASH (DOWN), filter (5,7) BLUE (overwrites RED), mirror (5,8) flips to SLASH (LEFT), into target A (4,8, BLUE). Emitter 2 chain: through gate (2,1) [g1, opened by emitter 1's switch], mirror (2,2) flips to BACKSLASH (RIGHT), mirror (3,2) flips to BACKSLASH (DOWN), mirror (3,3) flips to BACKSLASH (RIGHT), filter (4,3) GREEN, mirror (5,3) flips to BACKSLASH (DOWN), filter (5,4) RED (overwrites GREEN), mirror (5,5) flips to BACKSLASH (RIGHT), into target B (6,5, RED). INTENTIONAL DECOY: mirror (7,0) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 1)),
		TilePlacement.make_mirror(Vector2i(7, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(3, 5), "g1"),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 8), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(2, 1), "g1", false),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 3), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 5), GridTypes.BeamColor.RED),
	]
