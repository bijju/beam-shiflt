extends LevelData
## Campaign Level 116 — "False Activation". The Receiver itself always
## activates correctly once its own mirror is set - the trap is
## realizing the Remote Emitter's own beam still has an independent
## switch-then-gate sequence to solve on its own path; powering the
## Receiver alone does not finish the puzzle.

func _init() -> void:
	level_id = 16
	display_name = "False Activation"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, exits top instantly); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down, clear, to beam_receiver(3,3) - it activates correctly the instant this one mirror is set, exactly as the brief required ('the Receiver itself should activate correctly'). Powers link 'L116'. A player who stops reasoning here and assumes the puzzle is basically solved is the trap: remote_emitter(0,5) RIGHT WHITE link 'L116' still needs its OWN beam routed through an independent switch-then-gate sequence on the SAME path. -> mirror(3,5). Starts SLASH (WRONG - reflect(RIGHT,SLASH)=UP, travels up through the receiver's cell harmlessly and back into mirror(3,0), bouncing around and exiting somewhere harmless - never reaches the switch); correct BACKSLASH -> reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to switch(3,6), gate_id 'G116' (doesn't stop the beam) -> continues to a FIXED (non-rotatable) mirror(3,7) BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 7 to gate(5,7), gate_id 'G116'. The switch and its own gate sit on the SAME beam's path in sequence (same convergence pattern as T09/Level109) - the gate is closed on the very pass it's first reached, and only opens for the NEXT pass, resolved automatically inside one simulate_until_stable() call, so the player never has to 'wait' for it. If open, continue to target(6,7) WHITE. optimal_moves=2 (both mirrors must be flipped) - deliberately few moves; the real difficulty is recognizing the Receiver's own success doesn't mean the puzzle is over."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 3), "L116"),

		TilePlacement.make_remote_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, "L116"),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(3, 6), "G116"),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_gate(Vector2i(5, 7), "G116", false),
		TilePlacement.make_target(Vector2i(6, 7), GridTypes.BeamColor.WHITE),
	]
