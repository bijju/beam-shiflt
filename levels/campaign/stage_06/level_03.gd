extends LevelData
## Campaign Level 53 — "Shared Line". Post-reboot Levels 51-60.
## Two independent emitters share one filter corridor: emitter 1 must
## trip a switch before emitter 2's gate opens, and BOTH beams pass
## through the same filter (from different directions) to reach their
## own separate, differently-positioned targets. See CAMPAIGN_DESIGN.md
## section 11i.

func _init() -> void:
	level_id = 3
	display_name = "Shared Line"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 1's beam and emitter 2's beam are not independent mini-puzzles - emitter 2 is physically gated until emitter 1's switch opens it, AND both beams pass through the same shared filter (4,4) from perpendicular directions on their way to two separate targets, so the filter's color has to be reasoned about for both deliveries at once. Emitter 1 chain: mirror (1,4) flips to BACKSLASH (DOWN), into switch (1,5) [g1], mirror (1,6) flips to BACKSLASH (RIGHT), mirror (3,6) flips to SLASH (UP), mirror (3,4) flips to SLASH (RIGHT), through filter (4,4) BLUE, into target A (5,4, BLUE). Emitter 2 chain: mirror (2,0) flips to BACKSLASH (DOWN), through gate (2,1) [g1, opened by emitter 1's switch], mirror (2,2) flips to BACKSLASH (RIGHT), mirror (4,2) flips to BACKSLASH (DOWN), through the SAME filter (4,4) BLUE (arriving from the north this time), into target B (4,6, BLUE). Intentionally kept to 7 real moves rather than padded further - the reasoning load is in correctly identifying which emitter's switch gates the other and tracing one shared filter's color requirement for two independent deliveries, not in route length."
	is_campaign_level = true
	grid_width = 6
	grid_height = 7
	optimal_moves = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(1, 5), "g1"),
		TilePlacement.make_mirror(Vector2i(1, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(4, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(5, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(2, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(2, 1), "g1", false),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 6), GridTypes.BeamColor.BLUE),
	]
