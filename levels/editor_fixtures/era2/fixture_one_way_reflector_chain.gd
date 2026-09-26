extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A single
## chain starting with a ONE_WAY_REFLECTOR (reflective-side hit) that then
## transits, in order: a FILTER (recolor to RED), a PORTAL, a SWITCH
## (opens a GATE on a side branch), a SPLITTER, and a PRISM, before
## reaching its required target - covering the "One-Way Reflector
## interacts with filters/portals/switches/splitters/Prism" test points
## in one solver/runtime-checked fixture. All mirrors/splitters/
## reflectors are fixed (non-rotatable); optimal_moves == 0 (already
## solved in its authored state) is itself the assertion under test.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: One-Way Reflector Chain (Filter/Portal/Switch/Splitter/Prism)"
	grid_width = 9
	grid_height = 5
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT),
		TilePlacement.make_one_way_reflector(Vector2i(2, 3), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_filter(Vector2i(2, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_portal(Vector2i(2, 0), "OWC"),
		TilePlacement.make_portal(Vector2i(6, 4), "OWC"),
		TilePlacement.make_switch(Vector2i(6, 3), "OWG"),
		TilePlacement.make_splitter(Vector2i(6, 2), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_prism(Vector2i(6, 1)),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.RED),
		# Splitter's reflected (RIGHT) branch - exercises the switch/gate
		# dependency without gating the main required target.
		TilePlacement.make_gate(Vector2i(8, 2), "OWG", false),
	]
