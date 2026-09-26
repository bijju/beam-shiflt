extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. One WHITE
## beam enters a PRISM; RED channel transits a PORTAL to reach its
## target ("Prism -> Portal"); GREEN channel hits a SWITCH that opens a
## GATE blocking the BLUE channel's own path ("Prism -> Switch", plus a
## real switch/gate multi-pass dependency exactly like Era 1's). The gate
## starts CLOSED, so LaserSystem must re-run simulate() a second pass
## (the switch is hit every pass, so once opened the gate never re-closes)
## before the BLUE target is reachable - solver/runtime parity on this
## fixture proves the multi-pass resolution still works with a Prism in
## the graph.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Prism -> Portal / Switch-Gate"
	grid_width = 6
	grid_height = 9
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_prism(Vector2i(3, 3)),

		# RED channel (straight) -> PORTAL -> target.
		TilePlacement.make_portal(Vector2i(5, 3), "PSW"),
		TilePlacement.make_portal(Vector2i(1, 6), "PSW"),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.RED),

		# GREEN channel (turn via SLASH = UP) -> SWITCH.
		TilePlacement.make_switch(Vector2i(3, 0), "GSW"),

		# BLUE channel (turn via BACKSLASH = DOWN) -> GATE (opened by the
		# switch above, not open initially) -> target.
		TilePlacement.make_gate(Vector2i(3, 5), "GSW", false),
		TilePlacement.make_target(Vector2i(3, 8), GridTypes.BeamColor.BLUE),
	]
