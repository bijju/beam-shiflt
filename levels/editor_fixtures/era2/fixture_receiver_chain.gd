extends LevelData
## EDITOR FIXTURE (Era 2) - development/validator testing only. A
## genuine two-hop receiver chain: the real emitter powers Receiver A,
## which powers Remote Emitter A, whose beam powers Receiver B, which
## powers Remote Emitter B, which finally reaches the required target.
## Requires 3 simulate() passes to stabilize (one per hop plus the
## initial real-emitter pass) - proves simulate_until_stable()'s pass
## budget (gate_count + receiver_count + 1 + MAX_EXTRA_PASSES) covers a
## genuinely chained (not just parallel) receiver dependency.

func _init() -> void:
	level_id = -1
	display_name = "FIXTURE: Receiver Chain (A -> B -> target)"
	grid_width = 4
	grid_height = 8
	optimal_moves = 0
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(3, 1), "RA"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "RA"),
		TilePlacement.make_beam_receiver(Vector2i(3, 4), "RB"),

		TilePlacement.make_remote_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, "RB"),
		TilePlacement.make_target(Vector2i(3, 7)),
	]
