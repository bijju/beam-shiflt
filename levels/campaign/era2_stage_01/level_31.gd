extends LevelData
## Campaign Level 131 — "Double Bind". THE FIRST ADVANCED-CONVERGENCE
## LEVEL. RED and GREEN share ONE One-Way Reflector from genuinely
## different directions (RIGHT vs DOWN, both reflective under BACKSLASH -
## the exact Level 121 pattern, re-verified safe). A second, independent
## reflector gives BLUE its own reflect-then-redirect chain, so the
## board carries two real reflector decisions without forcing an
## impossible reflection-geometry chain between them (a beam can never
## exit a reflector moving in the direction it entered from the far
## side - reflect() only ever pairs RIGHT with UP or RIGHT with DOWN,
## never UP with DOWN - so a single shared tile cannot bounce two colors
## back and forth between itself and a second shared tile; this design
## deliberately works within that constraint rather than against it).

func _init() -> void:
	level_id = 31
	display_name = "Double Bind"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> one_way_reflector(6,4), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, cascades back through GREEN's own fixed routing mirrors, re-enters the Prism moving DOWN as RED, unchanged color, continuing through the board's lower-left region; traced end to end to confirm it only ever crosses color-mismatched tiles before exiting); correct BACKSLASH -> bends DOWN -> mirror(6,6). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(8,6) RED. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to a FIXED (non-rotatable) mirror(3,1) SLASH -> reflect(UP,SLASH)=RIGHT -> row 1 to a FIXED mirror(6,1) BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 6 down to the SAME one_way_reflector(6,4), entering from ABOVE, moving DOWN - the shared resource, reflective under the identical BACKSLASH orientation RED needs. Bends RIGHT -> row 4 to mirror(7,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(7,6) GREEN. Since BOTH colors need the SAME BACKSLASH orientation at the shared reflector for their own, DIFFERENT reasons (RED bending RIGHT->DOWN, GREEN bending DOWN->RIGHT), there is exactly one globally-compatible configuration - flipping it to 'help' one color the other way breaks both. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> row 7 to one_way_reflector(6,7) - a SECOND, independent reflector - entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, harmless miss); correct BACKSLASH -> bends DOWN -> mirror(6,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(8,8) BLUE. optimal_moves=6 (one_way_reflector(6,4), mirror(6,6), mirror(7,4), mirror(3,7), one_way_reflector(6,7), mirror(6,8) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 9
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 6), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(6, 1), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 6), GridTypes.BeamColor.GREEN),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_one_way_reflector(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 8), GridTypes.BeamColor.BLUE),
	]
