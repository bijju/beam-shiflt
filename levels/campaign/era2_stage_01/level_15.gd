extends LevelData
## Campaign Level 115 — "Directional Prism". THE MID-BLOCK CHECKPOINT.
## All three Prism channels each meet their own One-Way Reflector.
## Treating any of them as an ordinary mirror fails on at least one
## channel - each requires real reflect-vs-pass-through reasoning about
## its own incoming direction.

func _init() -> void:
	level_id = 15
	display_name = "Directional Prism"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> one_way_reflector(6,4), entering RIGHT (always reflective in either orientation - the only question is which way it bends). Starts SLASH (WRONG - bends UP, column 6 up, exits the top boundary, nothing there); correct BACKSLASH -> bends DOWN -> column 6 down, clear, to target(6,7) RED. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to one_way_reflector(3,0), entering UP. Under SLASH, UP is in the {RIGHT,UP} reflective pair -> bends RIGHT; under BACKSLASH (the WRONG starting orientation), UP is in the {LEFT,UP} pass-through pair -> the beam keeps going straight UP and vanishes off the top edge instantly - correct = SLASH. Correct path -> row 0 to mirror(5,0). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top harmlessly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 5 down to target(5,3) GREEN. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to one_way_reflector(3,7), entering DOWN. Under BACKSLASH, DOWN is in the {RIGHT,DOWN} reflective pair -> bends RIGHT; under SLASH (the WRONG starting orientation), DOWN is in the {LEFT,DOWN} pass-through pair -> the beam sails straight through and off the bottom edge - correct = BACKSLASH. Correct path -> row 7 to mirror(5,7). Starts BACKSLASH (WRONG - reflect(RIGHT,BACKSLASH)=DOWN, row 7 is the bottom edge, exits instantly); correct SLASH -> reflect(RIGHT,SLASH)=UP -> column 5 up to target(5,6) BLUE. Two of the three One-Way Reflectors need OPPOSITE orientations to correctly bend (RED needs BACKSLASH, GREEN needs SLASH) even though both enter from the exact same relative geometry pattern - there is no single 'always rotate this way' shortcut. optimal_moves=5 (all five rotatable tiles must be flipped)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.RED),

		TilePlacement.make_one_way_reflector(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 3), GridTypes.BeamColor.GREEN),

		TilePlacement.make_one_way_reflector(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.BLUE),
	]
