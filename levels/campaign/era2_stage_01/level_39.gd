extends LevelData
## Campaign Level 139 — "Fractured Network". NEAR-FINALE. Every
## mechanic is load-bearing: a cross-color gate dependency (GREEN needs
## RED's switch), a Receiver/Remote-Emitter chain isolated in its own
## column (no accidental cross-talk), a One-Way Reflector whose
## pass-through behavior is the correct answer, a Portal creating a
## non-local dependency, filter order mattering, and a near-solution
## where BLUE's own tempting default nearly reaches a colored decoy.

func _init() -> void:
	level_id = 39
	display_name = "Fractured Network"
	stage = "Advanced"
	developer_notes = "DESIGN INTENT: emitter(0,5) RIGHT WHITE -> prism(3,5). RED channel (straight) -> one_way_reflector(6,5), entering RIGHT (always reflective). Starts SLASH (WRONG - bends UP, exits top harmlessly); correct BACKSLASH -> bends DOWN -> switch(6,7), gate_id 'FN139' (doesn't stop the beam) -> continues to mirror(6,8). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> target(8,8) RED. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up, clear, into portal(3,0), pair 'FNP139' -> teleports to partner (0,8), direction preserved (UP) -> column 0 upward through filter(0,6) (recolors GREEN -> BLUE, continuing) -> passes the emitter's own cell harmlessly -> mirror(0,3). Starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT, exits left instantly); correct SLASH -> RIGHT -> row 3 through gate(2,3), gate_id 'FN139' - the SAME gate_id RED's switch opens, a genuine cross-color dependency. If open, continue to target(5,3), which requires BLUE - the post-filter color, not GREEN. BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7) - THE NEAR-SOLUTION. Starts SLASH (the tempting default - reflect(DOWN,SLASH)=LEFT sends the beam toward a real, color-matching but is_required=false decoy target(1,7), which DOES activate since the beam genuinely is BLUE at that point, making the level look closer to solved than it is); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> beam_receiver(5,7) - hit directly, powers link 'FNR139' - continues to mirror(7,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(7,8) BLUE, BLUE's own true second objective. remote_emitter(8,0) DOWN, color GREEN, link 'FNR139' only fires once BLUE has powered the Receiver -> column 8 down, deliberately isolated from every other channel -> one_way_reflector(8,9), entering DOWN. Starts BACKSLASH (WRONG - DOWN is reflective, bends RIGHT, exits right edge instantly); correct SLASH -> DOWN is pass-through -> continues straight down to target(8,10), which requires GREEN, matching the Remote Emitter's own explicit color (not the default WHITE, which RED's own beam reaches this exact column one row above and would otherwise satisfy by accident). optimal_moves=6 (one_way_reflector(6,5), mirror(6,8), mirror(0,3), mirror(3,7), mirror(7,7), one_way_reflector(8,9) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 11
	optimal_moves = 6
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 5), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 5)),

		TilePlacement.make_one_way_reflector(Vector2i(6, 5), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_switch(Vector2i(6, 7), "FN139"),
		TilePlacement.make_mirror(Vector2i(6, 8), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(8, 8), GridTypes.BeamColor.RED),

		TilePlacement.make_portal(Vector2i(3, 0), "FNP139"),
		TilePlacement.make_portal(Vector2i(0, 8), "FNP139"),
		TilePlacement.make_filter(Vector2i(0, 6), GridTypes.BeamColor.BLUE),
		TilePlacement.make_mirror(Vector2i(0, 3), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_gate(Vector2i(2, 3), "FN139", false),
		TilePlacement.make_target(Vector2i(5, 3), GridTypes.BeamColor.BLUE),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(1, 7), GridTypes.BeamColor.BLUE, false),
		TilePlacement.make_beam_receiver(Vector2i(5, 7), "FNR139"),
		TilePlacement.make_mirror(Vector2i(7, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(7, 8), GridTypes.BeamColor.BLUE),

		TilePlacement.make_remote_emitter(Vector2i(8, 0), GridTypes.Direction.DOWN, "FNR139", GridTypes.BeamColor.GREEN),
		TilePlacement.make_one_way_reflector(Vector2i(8, 9), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(8, 10), GridTypes.BeamColor.GREEN),
	]
