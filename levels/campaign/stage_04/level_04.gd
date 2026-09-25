extends LevelData
## Campaign Level 34 — "Snare". DIFFICULTY REWORK PASS 2.
## Portal into a switch that opens its own downstream gate, resolved by
## simulate_until_stable's multi-pass loop; the returning beam is turned
## into the target by a DEDICATED mirror never touched on the outbound
## leg. A wrong junction mirror produces a genuine color false-
## confirmation on a non-required target.
## See CAMPAIGN_DESIGN.md section 11g (Pass 2).

func _init() -> void:
	level_id = 4
	display_name = "Snare"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: the beam crosses its own switch before its own gate, via a portal in between - the gate is closed on the first evaluation pass, but since the switch that opens it sits upstream of the gate on the SAME beam, simulate_until_stable's second pass finds it open. Chain: emitter (0,4) RIGHT WHITE -> mirror (1,4) flips to BACKSLASH (DOWN) -> mirror (1,5) flips to BACKSLASH (RIGHT) -> mirror (2,5) flips to BACKSLASH (DOWN) -> portal (2,7)/pair A -> exits (4,0) still moving DOWN -> switch (4,2) -> mirror (4,4) flips to SLASH (LEFT) -> through gate (3,4), now open -> mirror (2,4) flips to BACKSLASH (UP) -> target A (2,0, WHITE). FALSE CONFIRMATION: if mirror (4,4) is left at its authored BACKSLASH, the beam deflects RIGHT through filter (5,4) (RED) into non-required target (6,4, RED) instead - a plausible-looking solve that isn't one, since the real target never lights. (A first draft reused mirror (1,4) for both the outbound turn and the inbound turn into a target directly above it at (1,0) - the solver caught a 0-move trivial solve, because that mirror's authored SLASH orientation ALSO sends a RIGHT-incoming beam straight UP into that same column on the very first touch, before any move is made. Fixed with a dedicated return-leg mirror at (2,4) that the outbound beam never crosses.) No decoys - every rotatable piece on the true path is load-bearing (solver-confirmed)."
	is_campaign_level = true
	grid_width = 7
	grid_height = 8
	optimal_moves = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(2, 0), GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(2, 7), "A"),
		TilePlacement.make_portal(Vector2i(4, 0), "A"),
		TilePlacement.make_switch(Vector2i(4, 2), "g1"),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(5, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.RED, false),
		TilePlacement.make_gate(Vector2i(3, 4), "g1", false),
	]
