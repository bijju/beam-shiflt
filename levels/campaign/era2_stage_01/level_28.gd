extends LevelData
## Campaign Level 128 — "Reciprocal Signal". Two Receiver/Remote-Emitter
## chains that initially look like two separate systems - each has its
## own emitter, mirror, and receiver - but their two Remote Emitters
## cross through ONE shared gate cell, and Chain A's tail is a One-Way
## Reflector, not a plain mirror.

func _init() -> void:
	level_id = 28
	display_name = "Reciprocal Signal"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter_A(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - exits top instantly); correct BACKSLASH -> DOWN -> beam_receiver(3,2), powers link 'RA128'. emitter_B(0,9) RIGHT WHITE -> mirror(5,9) - deliberately column 5, not column 3, so emitter_A's own beam (which continues straight down column 3 after bouncing off mirror(3,0), since receivers don't stop a beam) can never also power receiver B by accident (the exact bug D81 found and fixed in Level 118). Starts BACKSLASH (WRONG - exits bottom edge instantly); correct SLASH -> UP -> beam_receiver(5,7), powers link 'RB128'. remote_emitter A(6,0) DOWN WHITE link 'RA128' -> switch(6,3), gate_id 'RC128' (doesn't stop the beam) -> gate(6,4), gate_id 'RC128' - THE SHARED CELL, sitting exactly where Remote A's vertical column crosses Remote B's horizontal row. Past the gate, Remote A continues to one_way_reflector(6,6), entering DOWN. Starts SLASH (WRONG - DOWN is pass-through under SLASH, the beam sails straight through and off the bottom edge, missing its target entirely); correct BACKSLASH -> DOWN is reflective -> bends RIGHT -> target(8,6) WHITE, Chain A's own objective. remote_emitter B(8,4) LEFT WHITE link 'RB128' -> row 4 leftward through the SAME shared gate(6,4) - closed until Remote A has independently reached and tripped the switch above it. Past the gate, continues to mirror(2,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> UP -> target(2,1) WHITE, Chain B's own objective. The two chains read as separate at first glance (own emitter, own mirror, own receiver each) - the coupling only becomes visible at the shared gate cell, and Chain A's own reflector adds a genuine reflect-vs-pass-through decision on top of the reciprocal structure. optimal_moves=4 (mirror(3,0), mirror(5,9), one_way_reflector(6,6), mirror(2,4) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "RA128"),

		TilePlacement.make_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(5, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_beam_receiver(Vector2i(5, 7), "RB128"),

		TilePlacement.make_remote_emitter(Vector2i(6, 0), GridTypes.Direction.DOWN, "RA128"),
		TilePlacement.make_switch(Vector2i(6, 3), "RC128"),
		TilePlacement.make_gate(Vector2i(6, 4), "RC128", false),
		TilePlacement.make_one_way_reflector(Vector2i(6, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 6), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(8, 4), GridTypes.Direction.LEFT, "RB128"),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 1), GridTypes.BeamColor.WHITE),
	]
