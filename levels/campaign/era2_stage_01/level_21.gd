extends LevelData
## Campaign Level 121 — "Shared Spectrum". THE FIRST WHOLE-BOARD-REASONING
## LEVEL IN ERA 2. A single One-Way Reflector is reused by the RED and
## GREEN Prism channels from two different directions - the SAME
## orientation must satisfy both. RED's own wrong-orientation stray beam
## cascades all the way back through GREEN's own approach mirrors and
## re-enters the Prism itself; traced end-to-end to confirm it always
## exits harmlessly rather than accidentally solving anything.

func _init() -> void:
	level_id = 21
	display_name = "Shared Spectrum"
	stage = "Convergence"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> one_way_reflector(6,4), entering RIGHT (always reflective). GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,0) -> row 0 to mirror(6,0) -> column 6 down, entering the SAME reflector from ABOVE, moving DOWN - the shared resource. Correct orientation for the reflector = BACKSLASH: RED (RIGHT) bends DOWN -> mirror(6,5) -> row 5 to target(7,5) RED; GREEN (DOWN, also reflective under BACKSLASH) bends RIGHT -> row 4 to target(7,4) GREEN. Wrong = SLASH: RED bends UP instead - cascades back through mirror(6,0) (LEFT), then mirror(3,0) (DOWN, since that mirror's own OWN correct orientation for GREEN's forward routing is SLASH, and reflect(LEFT,SLASH)=DOWN) and re-enters the Prism itself, continuing DOWN unchanged (RED channel, still RED) through the board's lower half - traced to confirm it only ever passes color-mismatched cells (BLUE's own target and mirror, both requiring BLUE) before exiting, never accidentally activating anything. GREEN (DOWN) under SLASH is pass-through (unaffected) -> continues straight down through RED's own target(7,5)'s row region [wait: continues down column 6] past y5 (RED's target sits at column 7, not 6, so no collision) to the bottom edge, harmless. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down, clear, to mirror(3,7). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 7 to target(4,7) BLUE - deliberately independent and simple, since the reflector puzzle above carries the level's real weight. optimal_moves=5 (the shared reflector, both of GREEN's approach mirrors, and both of RED/BLUE's tail mirrors must all be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 8
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(7, 4), GridTypes.BeamColor.GREEN),

		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(6, 0), GridTypes.MirrorOrientation.SLASH),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 7), GridTypes.BeamColor.BLUE),
	]
