extends LevelData
## Campaign Level 105 — "False Reflection". Prism + One-Way Reflector:
## each of the three RGB channels meets its own One-Way Reflector at the
## top/bottom edge of the board. Treating either reflector as an ordinary
## mirror (assuming it always bends) is the false route - the wrong
## orientation lets the beam pass straight through and off the board.

func _init() -> void:
	level_id = 5
	display_name = "False Reflection"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitter(0,3) RIGHT WHITE -> prism(3,3). RED channel straight -> target(6,3) RED, free arrival. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to one_way_reflector(3,0) at the very top row. Entering UP: under SLASH, UP is in the {RIGHT,UP} reflective pair -> reflect(UP,SLASH)=RIGHT -> row 0 rightward to target(6,0) GREEN. Under BACKSLASH (the WRONG starting orientation), UP is in the {LEFT,UP} pass-through pair -> the beam keeps going straight UP and immediately exits the top boundary - a player who assumes 'it's basically a mirror, it must bend' is caught out, since leaving it unrotated is exactly what makes the beam vanish off the board. Correct = SLASH. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to one_way_reflector(3,6) at the very bottom row. Entering DOWN: under BACKSLASH, DOWN is in the {RIGHT,DOWN} reflective pair -> reflect(DOWN,BACKSLASH)=RIGHT -> row 6 rightward to target(6,6) BLUE. Under SLASH (the WRONG starting orientation), DOWN is in the {LEFT,DOWN} pass-through pair -> the beam sails straight through and off the bottom edge. Correct = BACKSLASH. optimal_moves=2 (both reflectors must be flipped). Full 7x7 board utilization: RGB channels land on the exact top/middle/bottom rows."
	is_campaign_level = true
	grid_width = 7
	grid_height = 7
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 3)),
		TilePlacement.make_target(Vector2i(6, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_one_way_reflector(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_one_way_reflector(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.BLUE),
	]
