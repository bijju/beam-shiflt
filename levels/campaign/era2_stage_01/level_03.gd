extends LevelData
## Campaign Level 103 — "Fractured Path". Prism + Splitter + Portal:
## three spatially separated branches. The GREEN channel must cross a
## portal to reach its target on the far side of the board; the BLUE
## channel passes through a splitter whose reflected branch is an inert
## decoy while its straight branch continues to the real objective.

func _init() -> void:
	level_id = 3
	display_name = "Fractured Path"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitter(0,3) RIGHT WHITE -> prism(3,3). RED channel straight -> row 3 to target(7,3) RED, free arrival. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,0). Starts SLASH (WRONG - reflect(UP,SLASH)=RIGHT, row 0 rightward, dead end, no target there); correct BACKSLASH -> reflect(UP,BACKSLASH)=LEFT -> row 0 leftward into portal(0,0) pair 'F' -> exits at partner (7,7) still moving LEFT (direction preserved through a portal jump) -> row 7 leftward, clear, to target(2,7) GREEN. This is the 'Prism branch that needs a portal before reaching its target' the brief asked for. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to FIXED (non-rotatable) splitter(3,5) SLASH: its reflected branch (reflect(DOWN,SLASH)=LEFT) fizzles harmlessly off row 5 to the left (no target there - an inert decoy branch, not a required piece), while the splitter's straight/unbent branch continues DOWN unchanged to mirror(3,6). Mirror starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 6 rightward to target(7,6) BLUE. optimal_moves=2 (mirror(3,0) and mirror(3,6) both must be flipped). Deliberately asymmetric structure per branch (portal / splitter-decoy+mirror / direct) so the three channels don't share one repeated shape."
	is_campaign_level = true
	grid_width = 8
	grid_height = 8
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 3)),
		TilePlacement.make_target(Vector2i(7, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(0, 0), "F"),
		TilePlacement.make_portal(Vector2i(7, 7), "F"),
		TilePlacement.make_target(Vector2i(2, 7), GridTypes.BeamColor.GREEN),
		TilePlacement.make_splitter(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH, false),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 6), GridTypes.BeamColor.BLUE),
	]
