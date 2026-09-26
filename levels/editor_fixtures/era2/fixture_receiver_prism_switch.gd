extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A
## BEAM_RECEIVER (link "R2") powers a REMOTE_EMITTER whose WHITE beam
## enters a PRISM: the RED channel hits a SWITCH, which opens a GATE on
## the GREEN channel's own path to the required target. Covers "receiver
## -> remote emitter -> prism" and "-> switch/gate" together, and proves
## receiver_states and gate_states resolve correctly in the SAME
## simulate_until_stable() run (3 passes are required: 1) the real
## emitter powers the receiver, 2) the now-active remote emitter's RED
## branch hits the switch while GREEN finds the gate still closed, 3) the
## now-open gate lets GREEN through) - see ERA_2_DESIGN.md.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Receiver -> Remote Emitter -> Prism -> Switch/Gate"
	grid_width = 6
	grid_height = 7
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(3, 1), "R2"),

		TilePlacement.make_remote_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, "R2"),
		TilePlacement.make_prism(Vector2i(3, 6)),
		# RED channel (straight) -> SWITCH.
		TilePlacement.make_switch(Vector2i(5, 6), "RG2"),
		# GREEN channel (turn via SLASH = UP) -> GATE (opened by the
		# switch above) -> target.
		TilePlacement.make_gate(Vector2i(3, 4), "RG2", false),
		TilePlacement.make_target(Vector2i(3, 3), GridTypes.BeamColor.GREEN),
	]
