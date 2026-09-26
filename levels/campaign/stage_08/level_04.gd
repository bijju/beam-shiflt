extends LevelData
## Campaign Level 74 — "Twin Portals". Post-70 Levels 71-80, MASTER+
## TIER. Emitter 1's beam continues past its own target (delayed
## consequence) to trip a switch that gates emitter 2's entire route.
## See CAMPAIGN_DESIGN.md section 11k.

func _init() -> void:
	level_id = 4
	display_name = "Twin Portals"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: emitter 1's beam doesn't stop at target A - it continues past it to trip a switch that gates emitter 2's entire route, so the player has to notice the beam's job isn't over at the target. Emitter 1 chain: mirror (1,4) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,1) instead - mirror (1,5) flips to BACKSLASH (RIGHT), mirror (2,5) flips to BACKSLASH (DOWN), mirror (2,6) flips to BACKSLASH (RIGHT), into portal (3,6)/pair A -> exits (4,8) still moving RIGHT -> filter (5,8) GREEN -> target A (6,8, GREEN), continues RIGHT past it into switch (7,8) [g1]. Emitter 2 (fires DOWN from (7,0)) chain: mirror (7,1) flips to BACKSLASH (RIGHT), mirror (8,1) flips to BACKSLASH (DOWN), through gate (8,3) [g1, opened by emitter 1's post-target continuation], mirror (8,4) flips to SLASH (LEFT), filter (5,4) RED, mirror (4,4) flips to BACKSLASH (UP), into target B (4,0, RED). INTENTIONAL DECOY: mirror (8,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 8
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 1)),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_portal(Vector2i(3, 6), "A"),
		TilePlacement.make_portal(Vector2i(4, 8), "A"),
		TilePlacement.make_filter(Vector2i(5, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(6, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(7, 8), "g1"),
		TilePlacement.make_emitter(Vector2i(7, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(7, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(8, 1), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(8, 3), "g1", false),
		TilePlacement.make_mirror(Vector2i(8, 4), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(5, 4), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(4, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(4, 0), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
	]
