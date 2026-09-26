extends LevelData
## Campaign Level 59 — "Near Convergence". Post-reboot Levels 51-60,
## near-finale. Two independent emitters, each threading its own
## portal, one gated behind a switch tripped by the other's downstream
## path - whole-board planning across two separate mechanic chains.
## See CAMPAIGN_DESIGN.md section 11i.

func _init() -> void:
	level_id = 9
	display_name = "Near Convergence"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 2 is gated at (1,6) until emitter 1's beam crosses a portal AND trips a switch beyond it, while emitter 1's own beam has to be routed through a portal of its own, and emitter 2 (once through) has to be routed through a second portal AND a filter to match its target's color. Emitter 1 chain: mirror (1,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - mirror (1,3) flips to BACKSLASH (RIGHT), mirror (2,3) flips to BACKSLASH (DOWN), into portal (2,4)/pair A -> exits (4,7) still moving DOWN -> switch (4,8) [g1] -> mirror (4,9) flips to SLASH (LEFT) -> mirror (3,9) flips to BACKSLASH (UP) -> target A (3,6, WHITE). Emitter 2 chain: through gate (1,6) [g1, opened by emitter 1's switch], mirror (2,6) flips to BACKSLASH (DOWN), into portal (2,7)/pair B -> exits (5,0) still moving DOWN -> mirror (5,1) flips to BACKSLASH (RIGHT), mirror (6,1) flips to BACKSLASH (DOWN), through filter (6,3) RED, mirror (6,4) flips to SLASH (LEFT), mirror (5,4) flips to SLASH (DOWN), mirror (5,5) flips to SLASH (LEFT), into target B (3,5, RED). INTENTIONAL DECOY: mirror (7,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 10
	optimal_moves = 11
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_mirror(Vector2i(1, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 4), "A"),
		TilePlacement.make_portal(Vector2i(4, 7), "A"),
		TilePlacement.make_switch(Vector2i(4, 8), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(3, 6), GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(1, 6), "g1", false),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 7), "B"),
		TilePlacement.make_portal(Vector2i(5, 0), "B"),
		TilePlacement.make_mirror(Vector2i(5, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(6, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(6, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(3, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(7, 9), GridTypes.MirrorOrientation.SLASH),
	]
