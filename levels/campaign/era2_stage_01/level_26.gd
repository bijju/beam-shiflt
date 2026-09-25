extends LevelData
## Campaign Level 126 — "Signal Cascade". A genuine activation cascade:
## Receiver A's power wakes Remote A, whose own beam directly powers
## Receiver B, waking Remote B, whose beam trips a switch that opens the
## gate on Remote A's own tail - six mechanic hops from the player's
## first tap to the final target. A separate Prism branch is fully
## independent, so the level isn't ONLY the cascade.

func _init() -> void:
	level_id = 26
	display_name = "Signal Cascade"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> target(6,4) RED, free arrival, fully independent of the cascade below. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, straight into beam_receiver(3,1) - hit directly, powers link 'CA126'. remote_emitter(0,6) RIGHT WHITE link 'CA126' only fires once powered -> mirror(3,6). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> column 3 down through beam_receiver(3,8) (hit directly, powers link 'CB126') -> continues (receivers don't stop) to gate(3,9), gate_id 'CASC126', initially closed. remote_emitter(6,6) DOWN WHITE link 'CB126' only fires once Receiver B is powered (one pass after Remote A first reaches it) -> column 6 down through switch(6,8), gate_id 'CASC126' (trips the gate blocking Remote A's own tail - a separate board region) -> continues to mirror(6,9). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(8,9) WHITE, Remote B's own objective. Once the gate opens, Remote A's own beam (refiring every pass since its own link stays powered) finally passes through to the final target(3,10) WHITE, straight ahead - the true finale of the whole cascade: Receiver A -> Remote A -> Receiver B -> Remote B -> Switch -> Gate -> target, six hops deep. optimal_moves=2 (only mirror(3,6) and mirror(6,9) are rotatable - the cascade's real difficulty is depth, not move count)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 11
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.RED),

		TilePlacement.make_beam_receiver(Vector2i(3, 1), "CA126"),

		TilePlacement.make_remote_emitter(Vector2i(0, 6), GridTypes.Direction.RIGHT, "CA126"),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 8), "CB126"),
		TilePlacement.make_gate(Vector2i(3, 9), "CASC126", false),
		TilePlacement.make_target(Vector2i(3, 10), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(6, 6), GridTypes.Direction.DOWN, "CB126"),
		TilePlacement.make_switch(Vector2i(6, 8), "CASC126"),
		TilePlacement.make_mirror(Vector2i(6, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 9), GridTypes.BeamColor.WHITE),
	]
