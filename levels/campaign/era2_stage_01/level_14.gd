extends LevelData
## Campaign Level 114 — "Remote Loop". The first proper two-stage
## Receiver/Remote Emitter relay in the main campaign (Receiver A ->
## Remote Emitter A -> Portal -> Receiver B -> Remote Emitter B ->
## target), a pure linear chain with no circular dependency.

func _init() -> void:
	level_id = 14
	display_name = "Remote Loop"
	stage = "Circuit"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits the top boundary instantly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down, clear, to beam_receiver(3,3), powering link 'L114A'. remote_emitter(0,5) RIGHT WHITE link 'L114A' only fires once powered -> row 5 to mirror(3,5). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, travels up through the receiver's own cell harmlessly and back into mirror(3,0), which bends it again per its own current orientation and eventually exits somewhere harmlessly - never reaches the portal); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to portal(3,7), pair 'P114' -> teleports to partner (6,0), direction preserved (DOWN) -> column 6 down, clear, to beam_receiver(6,2), powering link 'L114B'. remote_emitter(0,9) RIGHT WHITE link 'L114B' only fires once THAT is powered -> row 9 to mirror(5,9). Starts BACKSLASH (WRONG - reflect(RIGHT,BACKSLASH)=DOWN, and row 9 is the bottom edge, exits instantly); correct SLASH -> reflect(RIGHT,SLASH)=UP -> column 5 up, clear, to target(5,6) WHITE - the final objective, three mechanic hops and two full simulate_until_stable() convergence steps away from the player's first tap. Pure linear chain, no circular dependency: each stage's prerequisite is fully resolved by an earlier, independent stage. optimal_moves=3 (all three mirrors must be flipped)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 10
	optimal_moves = 3
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 3), "L114A"),

		TilePlacement.make_remote_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, "L114A"),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 7), "P114"),
		TilePlacement.make_portal(Vector2i(6, 0), "P114"),
		TilePlacement.make_beam_receiver(Vector2i(6, 2), "L114B"),

		TilePlacement.make_remote_emitter(Vector2i(0, 9), GridTypes.Direction.RIGHT, "L114B"),
		TilePlacement.make_mirror(Vector2i(5, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(5, 6), GridTypes.BeamColor.WHITE),
	]
