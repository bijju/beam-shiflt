extends LevelData
## Campaign Level 122 — "Remote Pair". Two Receiver/Remote-Emitter chains
## that are NOT independent: Chain A's own beam directly powers Receiver
## B; Chain B's beam then trips a switch that opens the gate blocking
## Chain A's own final tail. Resolves monotonically across four
## simulate_until_stable() passes with no circular deadlock.

func _init() -> void:
	level_id = 22
	display_name = "Remote Pair"
	stage = "Convergence"
	developer_notes = "DESIGN INTENT: emitter(0,0) RIGHT WHITE -> mirror(3,0). Starts SLASH (WRONG - exits top instantly); correct BACKSLASH -> DOWN -> beam_receiver(3,2), powers link 'LA122'. remote_emitter(0,4) RIGHT WHITE link 'LA122' fires once powered -> mirror(3,4). Starts SLASH (WRONG - exits top, bounces harmlessly); correct BACKSLASH -> DOWN -> column 3 down through beam_receiver(3,6) (hit directly, powers link 'LB122') -> continues (receivers don't stop) to gate(3,7), gate_id 'GB122' - Chain A's own beam is blocked here until Chain B's switch trips it. remote_emitter(6,0) DOWN WHITE link 'LB122' only fires once Receiver B is powered (by Chain A's own beam, one pass later) -> column 6 down through switch(6,3), gate_id 'GB122' (trips the gate blocking Chain A's tail, doesn't stop the beam) -> continues to mirror(6,5). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(7,5) WHITE, Chain B's own objective. Once gate 'GB122' opens (the pass after Chain B's switch trips), Chain A's beam - still arriving fresh every pass - passes through to mirror(3,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(5,8) WHITE, Chain A's true final objective - reachable only after BOTH chains have independently done their own part. No circular dependency: Receiver A needs only the real emitter (always fires); Receiver B needs only Chain A's beam (fires once A is powered); the gate needs only Chain B's switch (fires once B is powered) - each stage depends strictly on an earlier one. optimal_moves=4 (all four mirrors must be flipped)."
	is_campaign_level = true
	grid_width = 8
	grid_height = 9
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 2), "LA122"),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "LA122"),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_beam_receiver(Vector2i(3, 6), "LB122"),
		TilePlacement.make_gate(Vector2i(3, 7), "GB122", false),
		TilePlacement.make_mirror(Vector2i(3, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 8), GridTypes.BeamColor.WHITE),

		TilePlacement.make_remote_emitter(Vector2i(6, 0), GridTypes.Direction.DOWN, "LB122"),
		TilePlacement.make_switch(Vector2i(6, 3), "GB122"),
		TilePlacement.make_mirror(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 5), GridTypes.BeamColor.WHITE),
	]
