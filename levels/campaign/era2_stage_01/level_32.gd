extends LevelData
## Campaign Level 132 — "Relay Exchange". A reciprocal relay: Chain A's
## own beam directly powers Receiver B; Chain B's beam then trips a
## switch that opens the gate blocking Chain A's own final tail. Chain
## A's Remote Emitter does NOT immediately reach its own objective - it
## stalls at the gate until Chain B has independently resolved.

func _init() -> void:
	level_id = 32
	display_name = "Relay Exchange"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - exits top instantly); correct BACKSLASH -> DOWN -> beam_receiver(3,2), powers link 'RXA132'. remote_emitter(0,4) RIGHT WHITE link 'RXA132' fires once powered -> mirror(3,4). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> column 3 down through beam_receiver(3,6) (hit directly, powers link 'RXB132') -> continues (receivers don't stop) to gate(3,7), gate_id 'RG132' - Chain A's own beam stalls here, NOT reaching its objective immediately, exactly as required. remote_emitter(6,0) DOWN WHITE link 'RXB132' only fires once Receiver B is powered (one pass after Remote A first reaches it) -> column 6 down through switch(6,3), gate_id 'RG132' (trips the gate blocking Chain A's tail, doesn't stop this beam) -> continues to mirror(6,5). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(7,5) WHITE, Chain B's own objective. Once gate 'RG132' opens, Chain A's own beam (refiring every pass) finally passes through to mirror(3,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(5,8) WHITE, Chain A's true final objective. No circular dependency: Receiver A needs only the real emitter; Receiver B needs only Chain A's beam; the gate needs only Chain B's switch - strictly earlier-stage dependencies throughout, resolved monotonically. optimal_moves=4 (all four mirrors must be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "RXA132"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "RXA132"),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 6), "RXB132"),
		TilePlacement.make_gate(Vector2i(3, 7), "RG132", false),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 8), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(6, 0), GridTypes.Direction.DOWN, "RXB132"),
		TilePlacement.make_switch(Vector2i(6, 3), "RG132"),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 5), GridTypes.BeamColor.WHITE),
	]
