extends LevelData
## Campaign Level 113 — "Spectral Gate". Prism + Filter + Switch/Gate:
## the RED channel must itself be routed (via a mirror) into a switch
## before the GREEN channel's gate will ever open, and the GREEN
## channel passes a true-positive decoy target (still GREEN at that
## point) before a filter silently changes its color for the real,
## gated target beyond.

func _init() -> void:
	level_id = 13
	display_name = "Spectral Gate"
	stage = "Circuit"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> mirror(5,4). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP -> travels up column 5, passing through filter(5,0) harmlessly on the way out (color no longer matters, the beam is about to exit) and out the top boundary - the switch never trips); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 5 down to switch(5,6), gate_id 'SG113' (doesn't stop the beam, continues down and off the bottom edge harmlessly). GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,0). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, harmless miss); correct SLASH -> reflect(UP,SLASH)=RIGHT -> row 0 rightward through target(4,0) GREEN (is_required=false - the beam genuinely IS green here, so this true-positive decoy DOES activate, but it doesn't matter for solving) -> filter(5,0) recolors to BLUE -> gate(6,0), gate_id 'SG113' (only open once RED's switch has tripped - an entirely separate, color-unrelated dependency the player must notice) -> if open, continue to target(7,0), which requires BLUE - matching the post-filter color, not the channel's original GREEN. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7). Starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 7 to target(6,7) BLUE, a third, fully independent objective. The puzzle can't be solved by color reasoning alone (the RED->switch mirror has nothing to do with color) or by gate reasoning alone (GREEN's own mirror and the filter's recolor still have to be understood) - both are required together, exactly as the brief asked. optimal_moves=3 (mirror(5,4), mirror(3,0), mirror(3,7) all must be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 8
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(5, 6), "SG113"),

		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.GREEN, false),
		TilePlacement.make_filter(Vector2i(5, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_gate(Vector2i(6, 0), "SG113", false),
		TilePlacement.make_target(Vector2i(7, 0), GridTypes.BeamColor.BLUE),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.BLUE),
	]
