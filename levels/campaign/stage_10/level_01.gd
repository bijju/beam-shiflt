extends LevelData
## Campaign Level 91 — "Inferred Convergence". FINAL CAMPAIGN BLOCK
## (Levels 91-100), MASTER+ TIER. Built by recoloring Level 75's already-
## validated splitter/shared-fixed-mirror/target-continuation geometry:
## the fixed mirror at the convergence point cannot be rotated, so the
## player must reason BACKWARD from both targets' colors and approach
## directions to deduce the correct orientation for every mirror
## upstream of it, on both branches at once. See CAMPAIGN_DESIGN.md
## section 11m.

func _init() -> void:
	level_id = 1
	display_name = "Inferred Convergence"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: fixed mirror (5,5) cannot be rotated - it is hit by both branches from perpendicular directions, and its single fixed orientation only produces a correct delivery for ONE approach direction per branch, forcing the player to work backward from each target's required color and position through the fixed mirror to the mirrors they CAN rotate. Straight branch (unconditional RIGHT off splitter (2,4)): mirror (3,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the blocker at (3,2) instead - mirror (3,5) flips to BACKSLASH (RIGHT), filter (4,5) RED, into the shared fixed mirror -> DOWN -> filter (5,6) GREEN (overwrites RED) -> mirror (5,7) flips to BACKSLASH (RIGHT) -> mirror (6,7) flips to BACKSLASH (DOWN) -> switch (6,8) [g1] -> target A (6,9, GREEN). Reflected branch: splitter flips to SLASH (UP), mirror (2,2) flips to BACKSLASH (LEFT), mirror (1,2) flips to BACKSLASH (UP), mirror (1,0) flips to SLASH (RIGHT), filter (3,0) BLUE, mirror (4,0) flips to BACKSLASH (DOWN), filter (4,1) RED (overwrites BLUE), mirror (4,3) flips to BACKSLASH (RIGHT), mirror (5,3) flips to BACKSLASH (DOWN), into the shared fixed mirror from the north -> RIGHT -> through gate (6,5) [g1, opened by the straight branch's switch] -> mirror (7,5) flips to SLASH (UP) -> mirror (7,4) flips to SLASH (RIGHT) -> target B (8,4, RED). If the splitter is left at its authored BACKSLASH, the reflected branch runs DOWN into the hazard at (2,6) instead. INTENTIONAL DECOY: mirror (0,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 13
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_splitter(Vector2i(2, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_hazard(Vector2i(2, 6)),
		TilePlacement.make_blocker(Vector2i(3, 2)),
		TilePlacement.make_mirror(Vector2i(0, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(3, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 5), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(5, 5), GridTypes.MirrorOrientation.BACKSLASH, false),
		TilePlacement.make_filter(Vector2i(5, 6), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(6, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 8), "g1"),
		TilePlacement.make_target(Vector2i(6, 9), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(1, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(3, 0), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(4, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 1), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 3), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(6, 5), "g1", false),
		TilePlacement.make_mirror(Vector2i(7, 5), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(7, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.RED),
	]
