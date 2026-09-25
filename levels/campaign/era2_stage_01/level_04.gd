extends LevelData
## Campaign Level 104 — "One Way". First campaign use of the One-Way
## Reflector as the primary mechanic: a single tile that must reflect one
## approaching beam while letting a second, perpendicular beam pass
## straight through it - the same orientation must satisfy both at once.

func _init() -> void:
	level_id = 4
	display_name = "One Way"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitter A(0,3) RIGHT WHITE approaches one_way_reflector(3,3) entering RIGHT - RIGHT is ALWAYS reflective regardless of orientation (GridTypes.one_way_reflector_is_reflective()), so beam A always bends; the only question is which way. emitter B(3,6) UP WHITE approaches the SAME tile entering UP, travelling straight up column 3 into it. Under BACKSLASH: beam A (RIGHT) reflects DOWN (reflect(RIGHT,BACKSLASH)=DOWN); beam B (UP) is in the {LEFT,UP} pass-through pair, so it continues straight UP through the tile unaffected. Under SLASH: beam A reflects UP instead (colliding with beam B's approach column, missing its real target), and beam B (now in the {RIGHT,UP} reflective pair for SLASH) instead REFLECTS to RIGHT - hits blocker(5,3) and stops harmlessly. So BACKSLASH is the single correct orientation that satisfies both beams at once - the reflect-one/pass-the-other duality the brief asked for, not a normal-mirror assumption. Starts SLASH (WRONG). Beam A's reflected DOWN path (correct) continues through emitter B's own cell at (3,6) harmlessly (emitters are transparent to other beams) down to mirror(3,7): starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, row 7 leftward, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 7 rightward to target A(5,7) WHITE. Beam B's pass-through path (correct) continues straight up through y=2,1,0 to target B(3,0) WHITE. optimal_moves=2 (the reflector and the mirror both must be flipped)."
	is_campaign_level = true
	grid_width = 6
	grid_height = 9
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_one_way_reflector(Vector2i(3, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_emitter(Vector2i(3, 6), GridTypes.Direction.UP, GridTypes.BeamColor.WHITE),
		TilePlacement.make_blocker(Vector2i(5, 3)),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 7), GridTypes.BeamColor.WHITE),
		TilePlacement.make_target(Vector2i(3, 0), GridTypes.BeamColor.WHITE),
	]
