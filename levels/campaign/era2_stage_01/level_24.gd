extends LevelData
## Campaign Level 124 — "Directional Cross". Two emitters, two One-Way
## Reflectors: the first reflector is genuinely shared (Emitter A enters
## it RIGHT - always reflective; Emitter B enters it DOWN - orientation-
## dependent), and Emitter B's own success is what opens the gate
## blocking Emitter A's tail.

func _init() -> void:
	level_id = 24
	display_name = "Directional Cross"
	stage = "Convergence"
	developer_notes = "DESIGN INTENT: emitter_A(0,3) RIGHT WHITE -> one_way_reflector(4,3), entering RIGHT (always reflective). emitter_B(4,0) DOWN WHITE -> column 4 down, clear, into the SAME reflector, entering DOWN - the shared resource. Correct orientation = BACKSLASH: A (RIGHT) bends DOWN; B (DOWN, reflective under BACKSLASH too) bends RIGHT. Wrong = SLASH: A bends UP instead (exits the top boundary through B's own emitter cell harmlessly - emitters are transparent to other beams); B (DOWN, pass-through under SLASH) continues straight DOWN unchanged, through the closed gate below (harmless stop, since the gate can only ever be opened by B's own switch, which B never reaches this way). Correct path: A bends DOWN -> column 4 down to gate(4,6), gate_id 'DC124', initially closed -> if open, continue to mirror(4,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(6,7) WHITE, A's true objective. B bends RIGHT at the shared reflector -> row 3 to one_way_reflector(7,3), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, exits top harmlessly); correct BACKSLASH -> bends DOWN -> column 7 down to switch(7,5), gate_id 'DC124' (trips the gate on A's own tail - a completely separate board region) -> continues to mirror(7,6). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(9,6) WHITE, B's own objective. A's gate only opens once B has independently solved its own half - no circularity, since B's own chain never depends on anything from A's side. optimal_moves=4 (both reflectors and both tail mirrors must be flipped)."
	is_campaign_level = true
	grid_width = 10
	grid_height = 8
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_emitter(Vector2i(4, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_one_way_reflector(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),

		TilePlacement.make_gate(Vector2i(4, 6), "DC124", false),
		TilePlacement.make_mirror(Vector2i(4, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.WHITE),

		TilePlacement.make_one_way_reflector(Vector2i(7, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(7, 5), "DC124"),
		TilePlacement.make_mirror(Vector2i(7, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(9, 6), GridTypes.BeamColor.WHITE),
	]
