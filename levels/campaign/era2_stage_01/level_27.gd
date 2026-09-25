extends LevelData
## Campaign Level 127 — "Fractured Circuit". Three spatially separated
## board regions linked only by a Portal jump and a shared One-Way
## Reflector that behaves differently for two different incoming routes
## - a Splitter's reflected branch is a genuine inert decoy.

func _init() -> void:
	level_id = 27
	display_name = "Fractured Circuit"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> one_way_reflector(6,4), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, exits top harmlessly); correct BACKSLASH -> bends DOWN -> column 6 down, clear, to target(6,6) RED - the reflector's first use. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,1). Starts SLASH (WRONG - reflect(UP,SLASH)=RIGHT, row 1 rightward, dead end); correct BACKSLASH -> reflect(UP,BACKSLASH)=LEFT -> portal(0,1), pair 'FC127' -> teleports to partner (8,1), direction preserved (LEFT) -> row 1 leftward to mirror(6,1). A blocker(5,1) sits between mirror(3,1) and mirror(6,1) specifically so the WRONG mirror(3,1) path (RIGHT along row 1) can never physically reach mirror(6,1) at all - an earlier draft omitted it, and the solver found mirror(6,1)'s own default orientation happened to also correctly redirect that stray RIGHT-entering beam DOWN into the shared reflector, creating a complete portal-bypassing shortcut (2 moves instead of 4). The blocker only ever intercepts the wrong-direction beam; the real portal-exit beam approaches from the opposite side (arriving at x6 moving LEFT from x7) and never reaches x5 at all. Starts BACKSLASH (WRONG - reflect(LEFT,BACKSLASH)=UP, exits the top boundary instantly); correct SLASH -> reflect(LEFT,SLASH)=DOWN -> column 6 down to the SAME one_way_reflector(6,4), entering from ABOVE, moving DOWN - the reflector's second use, this time reflective under BACKSLASH (RED's own correct orientation) and passing straight through under SLASH. Since RED needs BACKSLASH to reach ITS target, GREEN (entering DOWN under the same BACKSLASH) also reflects - bends RIGHT -> filter(8,4) (GREEN -> BLUE) -> target(9,4), requires BLUE. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to splitter(3,7) (FIXED, SLASH, non-rotatable). Reflected branch (reflect(DOWN,SLASH)=LEFT) fizzles harmlessly off row 7 to the left - a genuine inert decoy, not required. Straight-continuing branch (unchanged, DOWN) -> mirror(3,9). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(6,9) BLUE. Three spatially separated regions (top-left portal entry, middle-right reflector convergence, bottom splitter/mirror) linked only by the portal jump and the shared reflector. optimal_moves=4 (mirror(3,1), mirror(6,1), one_way_reflector(6,4), mirror(3,9) all must be flipped)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 10
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(0, 1), "FC127"),
		TilePlacement.make_portal(Vector2i(8, 1), "FC127"),
		TilePlacement.make_blocker(Vector2i(5, 1)),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(8, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(9, 4), GridTypes.BeamColor.BLUE),

		TilePlacement.make_splitter(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.BLUE),
	]
