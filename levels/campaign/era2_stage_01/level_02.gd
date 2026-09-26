extends LevelData
## Campaign Level 102 — "Spectrum Route". Prism + Filter + Mirror reasoning:
## a route that visually looks correct (GREEN channel ending at a
## GREEN-labeled target) is actually a trap because a FILTER silently
## recolors the beam to RED before it arrives - the target never activates
## despite the beam physically reaching it. The real GREEN target sits
## down a different fork the player must choose instead.

func _init() -> void:
	level_id = 2
	display_name = "Spectrum Route"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel straight -> target(6,4) RED, free arrival, no decision. BLUE channel = reflect(RIGHT,BACKSLASH) = DOWN -> column 3 down to FIXED (non-rotatable) mirror(3,7) BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 7 to target(6,7) BLUE, also a free arrival (pure channel routing, no decision - matches the 'one channel auto-arrives' T12 pattern, here doubled). GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,1). Two real decisions: mirror(3,1) starts SLASH (WRONG) -> reflect(UP,SLASH)=RIGHT -> row 1 rightward through filter(5,1) which force-recolors to RED -> arrives at target(6,1) as RED, but that target requires GREEN, so it silently fails to activate despite the beam visibly reaching it - the 'looks promising but produces the wrong color' trap the brief asked for. Target(6,1) is deliberately NOT required (is_required=false) so it can never become an impossible-to-satisfy target - it exists purely as the visual trap, no valid route ever legitimately colors it GREEN. Correct choice: mirror(3,1) rotated to BACKSLASH -> reflect(UP,BACKSLASH)=LEFT -> row 1 leftward to a SECOND rotatable mirror(1,1), which starts SLASH (WRONG - reflect(LEFT,SLASH)=DOWN, sends the beam down column 1 into nothing, harmless miss) and must be rotated to BACKSLASH -> reflect(LEFT,BACKSLASH)=UP -> column 1 upward to the REAL target(1,0) GREEN, required=true. optimal_moves=2 (mirror(3,1) and mirror(1,1) both must end at BACKSLASH). shortest_solution_count should be 1 - no other combination activates target(1,0)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(6, 1), GridTypes.BeamColor.GREEN, false),
		TilePlacement.make_mirror(Vector2i(1, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(1, 0), GridTypes.BeamColor.GREEN),
	]
