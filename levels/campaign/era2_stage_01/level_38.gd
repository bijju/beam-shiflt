extends LevelData
## Campaign Level 138 — "Reciprocal Gates". Two Receiver/Remote-Emitter
## systems that read as independent at first glance (own emitter, own
## mirror, own receiver each) - the reciprocal coupling (Remote A's
## switch opens a gate on Emitter B's own path; Emitter B's switch opens
## a gate on Remote A's own path) only becomes visible where both beams
## cross through the SAME shared One-Way Reflector, approaching from
## OPPOSITE sides of it (Remote A from below, entering UP; Emitter B
## from the left, entering RIGHT) so their post-reflection exits never
## physically overlap - an earlier draft had Remote A approach from
## ABOVE the reflector while Emitter B's own exit also went UP into that
## exact same column, so Remote A's beam passed straight through a
## target meant only for Emitter B on its way down to the reflector,
## solving that half of the level with zero rotation at all (solver
## found a 2-move shortcut instead of the intended 3).

func _init() -> void:
	level_id = 38
	display_name = "Reciprocal Gates"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter_A(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - exits top instantly); correct BACKSLASH -> DOWN -> beam_receiver(3,2), powers link 'RG138A'. remote_emitter A(6,9) UP WHITE link 'RG138A' only fires once Receiver A is powered -> switch(6,8), gate_id 'GB138' (opens the gate on Emitter B's own path - trips unconditionally once Remote A fires at all) -> continues UP, clear, to one_way_reflector(6,4), entering UP - THE SHARED RESOURCE, approached from BELOW. Correct SLASH -> UP is in the {RIGHT,UP} reflective pair -> bends RIGHT -> row 4 to gate(7,4), gate_id 'GA138' - closed until Emitter B's own switch trips it. If open, continue to target(8,4) WHITE, Remote A's own objective. emitter_B(0,4) RIGHT WHITE -> switch(2,4), gate_id 'GA138' (opens the gate on Remote A's path - trips unconditionally, needs nothing but Emitter B firing) -> continues to gate(4,4), gate_id 'GB138' - closed until Remote A's own switch trips it (a genuine reciprocal dependency: neither can progress until the other has independently fired). If open, continue to the SAME one_way_reflector(6,4), entering RIGHT this time (always reflective) - approached from the LEFT, the opposite side from Remote A. Correct SLASH -> RIGHT is in the {RIGHT,UP} reflective pair too -> bends UP -> column 6 up, clear, to target(6,0) WHITE, Emitter B's own objective - reached by continuing ABOVE the reflector, the opposite direction from Remote A's own approach corridor below it, so the two beams' paths never cross. Wrong reflector orientation (BACKSLASH) makes Remote A's UP-entry pass-through instead of reflect (missing gate 'GA138' and its own target entirely) and makes Emitter B's RIGHT-entry reflect to DOWN instead of UP (missing target(6,0) entirely, landing instead on Remote A's own approach corridor below the reflector, confirmed harmless since nothing required sits there). No circular deadlock: switch 'GB138' needs only Receiver A powered; switch 'GA138' needs only Emitter B's own emission. optimal_moves=2 (mirror(3,0) and the shared reflector both must be flipped - Emitter B's own path needs no rotatable tile of its own beyond the shared reflector)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "RG138A"),

		TilePlacement.make_remote_emitter(Vector2i(6, 9), GridTypes.Direction.UP, "RG138A"),
		TilePlacement.make_switch(Vector2i(6, 8), "GB138"),
		TilePlacement.make_one_way_reflector(Vector2i(6, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(7, 4), "GA138", false),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.WHITE),

		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_switch(Vector2i(2, 4), "GA138"),
		TilePlacement.make_gate(Vector2i(4, 4), "GB138", false),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.WHITE),
	]
