extends LevelData
## Campaign Level 133 — "Spectral Lock". The GREEN channel crosses a
## Portal into a distant board region where a Filter recolors it to RED
## BEFORE a gate that only RED's own switch (a completely different
## Prism branch) can open - the player must reason backward from the
## final target's actual required color, through the filter, through
## the portal, to realize which Prism channel and which switch actually
## matter, since the channel's own starting color (GREEN) is a red
## herring once the filter has already changed it.

func _init() -> void:
	level_id = 33
	display_name = "Spectral Lock"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> mirror(5,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> switch(5,6), gate_id 'SL133' (doesn't stop the beam) -> continues down and off the bottom edge, harmlessly - RED's ONLY job is opening the gate GREEN's chain needs; deliberately given no separate target of its own, since an earlier draft's RED tail target sat directly in GREEN's own post-gate continuation path (GREEN, now recolored RED by the filter, would have reached RED's own target too via simple continuation - the exact D81 failure shape - removed rather than worked around). GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,1). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits the left boundary instantly); correct SLASH -> reflect(UP,SLASH)=RIGHT -> portal(5,1), pair 'SLP133' -> teleports to partner (0,7), direction preserved (RIGHT) -> row 7 rightward to filter(2,7) (recolors GREEN -> RED - the convincing trap: a player tracking 'the GREEN channel' expects to need a GREEN target eventually, but by the time this beam reaches anything, it is no longer GREEN at all) -> gate(4,7), gate_id 'SL133' - the SAME gate_id RED's own switch opens, a completely different Prism branch the player must connect backward from the final target's color. If open, continue to target(6,7), which requires RED - matching the post-filter color exactly. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> row 8, clear, to target(7,8) BLUE, independent. (An earlier draft added a second mirror at (5,8) to raise the rotatable count, but a mirror always bends - it cannot let a beam 'continue straight' - which made the target permanently unreachable and the whole level UNSOLVABLE; removed rather than reworked, since BLUE's role here is deliberately simple.) optimal_moves=3 (mirror(5,4), mirror(3,1), mirror(3,8) all must be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(5, 6), "SL133"),

		TilePlacement.make_mirror(Vector2i(3, 1), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_portal(Vector2i(5, 1), "SLP133"),
		TilePlacement.make_portal(Vector2i(0, 7), "SLP133"),
		TilePlacement.make_filter(Vector2i(2, 7), GridTypes.BeamColor.RED),
		TilePlacement.make_gate(Vector2i(4, 7), "SL133", false),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.BLUE),
	]
