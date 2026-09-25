extends LevelData
## Campaign Level 72 — "Locked Corridor". Post-70 Levels 71-80, MASTER
## TIER. Two emitters cross the SAME physical gate cell from
## perpendicular directions (one horizontal, one vertical) - EITHER
## emitter's own switch opens it for both - while each independently
## carries its own filter-order color to its own target. Built directly
## on Level 68's verified geometry (filters added only at cells already
## confirmed to be pure pass-through transit for their own beam, no new
## mirrors) after a from-scratch first draft mixed up two different
## mirror positions and came back UNSOLVABLE. See CAMPAIGN_DESIGN.md
## section 11k.

func _init() -> void:
	level_id = 2
	display_name = "Locked Corridor"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: gate (4,5) is a single shared corridor - emitter 1 crosses it horizontally (RIGHT), emitter 2 vertically (DOWN) - and EITHER emitter's own switch opens it for both, while each independently tracks its own filter-order color to its own target. Emitter 1 chain: mirror (1,5) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,3) instead - filter (1,6) RED, mirror (1,7) flips to BACKSLASH (RIGHT), switch (2,7) [g1], mirror (3,7) is ALREADY correctly authored at SLASH (RIGHT->UP, a genuine zero-move load-bearing piece), filter (3,6) BLUE (overwrites RED), mirror (3,5) flips to SLASH (UP->RIGHT), through the shared gate -> mirror (5,5) flips to BACKSLASH (RIGHT->DOWN) -> target A (5,7, BLUE). Emitter 2 (fires DOWN from (4,0)) chain: switch (4,1) [g1], mirror (4,2) flips to BACKSLASH (DOWN->RIGHT), mirror (5,2) flips to BACKSLASH (RIGHT->DOWN), filter (4,4) GREEN, mirror (5,3) flips to SLASH (DOWN->LEFT), mirror (4,3) flips to SLASH (LEFT->DOWN), through the SAME shared gate from the north -> mirror (4,6) flips to BACKSLASH (DOWN->RIGHT) -> target B (6,6, GREEN) (passing harmlessly through the shared transit cell (5,6) along the way - the one cell both beams cross, deliberately left tile-free). (A first draft hand-derived a different path through this same idea from scratch and mixed up two mirror positions, coming back UNSOLVABLE - rebuilt directly on Level 68's already-solver-confirmed geometry, adding filters only at transit cells independently confirmed to belong to exactly one beam.) INTENTIONAL DECOY: mirror (7,8) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 9
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 3)),
		TilePlacement.make_filter(Vector2i(1, 6), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(1, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(2, 7), "g1"),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(3, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(4, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(4, 1), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 4), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(7, 8), GridTypes.MirrorOrientation.SLASH),
	]
