extends LevelData
## Campaign Level 96 — "Chain of Custody". FINAL CAMPAIGN BLOCK
## (Levels 91-100), EXTREME+ TIER. Built by extending Level 87's already-
## validated three-stage relay geometry: emitter 2's switch is replaced
## by a target-continuation trigger (its beam reaches ITS OWN target
## first, then continues past it - targets do not stop beams - to the
## switch that unlocks emitter 3), and emitter 3 gains its own short
## detour instead of being a purely silent link. A genuine shared-state
## chain: emitter A's switch changes emitter B's conditions, B's own
## target activation is itself just a waypoint on the way to changing
## emitter C's conditions. See CAMPAIGN_DESIGN.md section 11m.

func _init() -> void:
	level_id = 6
	display_name = "Chain of Custody"
	stage = "Continuum"
	developer_notes = "DESIGN INTENT: switch (1,3) [gA] is reachable unconditionally on emitter 1's own path, opening gate (3,8) [gA] on emitter 2's path. Emitter 2 proceeds to its OWN target (7,8, GREEN) and, because targets do not stop beams, continues RIGHT past it into switch (8,8) [gB] - the player must recognize that reaching target B is not the end of emitter 2's job. Switch (8,8) opens gate (7,1) [gB] on emitter 3's path; emitter 3 now takes its own short detour (unlike Level 87's silent straight-line link) before reaching switch (5,3) [gC], which opens the FINAL gate (1,4) [gC] on emitter 1's own tail. Emitter 1 chain (confined to columns 2-8, rows 0-7): mirror (1,2) flips to BACKSLASH (DOWN) - if left at its authored SLASH the beam runs UP into the hazard at (1,0) instead - switch (1,3) [gA], through gate (1,4) [gC], mirror (1,5) flips to BACKSLASH (RIGHT), mirror (2,5) flips to BACKSLASH (DOWN), mirror (2,6) flips to BACKSLASH (RIGHT), filter (4,6) BLUE, mirror (5,6) flips to BACKSLASH (DOWN), mirror (5,7) flips to BACKSLASH (RIGHT) -> target A (7,7, BLUE). Emitter 2 chain (confined to columns 4-9, rows 7-9): mirror (3,7) flips to BACKSLASH (DOWN), through gate (3,8) [gA], mirror (3,9) flips to BACKSLASH (RIGHT), mirror (4,9) flips to SLASH (UP), mirror (4,8) flips to SLASH (RIGHT), filter (6,8) GREEN -> target B (7,8, GREEN), continues RIGHT past it into switch (8,8) [gB]. Emitter 3 (fires DOWN from (7,0), confined to column 6-8 rows 0-4, a genuine 2-move detour this time rather than a silent link): through gate (7,1) [gB], mirror (7,2) flips to SLASH (LEFT) - if left at its authored BACKSLASH the beam runs RIGHT and exits the grid instead, and gC never opens - mirror (5,2) flips to SLASH (DOWN) - if left at its authored BACKSLASH the beam runs UP and exits the grid instead - switch (5,3) [gC] -> blocker (5,4) stops the beam there, harmlessly. INTENTIONAL DECOY: mirror (8,9) is never touched by any beam in any configuration (solver-confirmed)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 10
	optimal_moves = 12
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(1, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(1, 0)),
		TilePlacement.make_switch(Vector2i(1, 3), "gA"),
		TilePlacement.make_gate(Vector2i(1, 4), "gC", false),
		TilePlacement.make_mirror(Vector2i(1, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(2, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(4, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 7), GridTypes.BeamColor.BLUE),
		TilePlacement.make_emitter(Vector2i(0, 7), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_gate(Vector2i(3, 8), "gA", false),
		TilePlacement.make_mirror(Vector2i(3, 9), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(4, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(4, 8), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_filter(Vector2i(6, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.GREEN),
		TilePlacement.make_switch(Vector2i(8, 8), "gB"),
		TilePlacement.make_emitter(Vector2i(7, 0), GridTypes.Direction.DOWN, GridTypes.BeamColor.WHITE),
		TilePlacement.make_gate(Vector2i(7, 1), "gB", false),
		TilePlacement.make_mirror(Vector2i(7, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_mirror(Vector2i(5, 2), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_switch(Vector2i(5, 3), "gC"),
		TilePlacement.make_blocker(Vector2i(5, 4)),
		TilePlacement.make_mirror(Vector2i(8, 9), GridTypes.MirrorOrientation.SLASH),
	]
