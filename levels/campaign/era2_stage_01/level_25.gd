extends LevelData
## Campaign Level 125 — "False Spectrum". THE MID-BLOCK CHECKPOINT. A
## deliberate near-solution trap: one mirror orientation reaches a
## real-looking (but optional) target directly; the other sends the beam
## through a Portal to the actual required target, whose color can only
## be worked out by reasoning backward from what the Portal-fed Filter
## produces. The RED channel demonstrates genuine target continuation -
## one beam, recolored twice, satisfying two sequential required targets.

func _init() -> void:
	level_id = 25
	display_name = "False Spectrum"
	stage = "Checkpoint"
	developer_notes = "DESIGN INTENT: emitter(0,4) RIGHT WHITE -> prism(3,4). RED channel (straight) -> filter(5,4) (WHITE... no, RED -> BLUE) -> target(6,4), requires BLUE, activates, then CONTINUES (targets never stop a beam) -> filter(7,4) (BLUE -> GREEN) -> target(8,4), requires GREEN, activates - a single beam satisfying two sequential required targets via continuation, the target-continuation requirement the brief asked for. GREEN channel = reflect(RIGHT,SLASH)=UP -> column 3 up to mirror(3,0) - THE TRAP. Starts SLASH (the tempting default) -> reflect(UP,SLASH)=RIGHT -> row 0 to target(6,0), which requires GREEN and DOES activate (the beam genuinely is GREEN) - is_required=false, so this is a true-positive, satisfying-looking, but entirely optional decoy. A player who stops here believes the puzzle is solved; it is not. Correct = BACKSLASH -> reflect(UP,BACKSLASH)=LEFT -> row 0 leftward to portal(0,0), pair 'FS125' -> teleports to partner (7,6), direction preserved (LEFT) -> row 6 leftward, clear, to mirror(5,6). Starts SLASH (WRONG - reflect(LEFT,SLASH)=DOWN, harmless miss); correct BACKSLASH -> reflect(LEFT,BACKSLASH)=UP -> column 5 up, clear, to filter(5,3) (GREEN -> RED) -> target(5,2), which requires RED - the color the player must reason backward from ('what color does the REQUIRED target need, and what filter produces it') rather than forward ('GREEN channel, so I need a GREEN target' - the exact assumption the decoy at (6,0) was built to encourage). BLUE channel = reflect(RIGHT,BACKSLASH)=DOWN -> column 3 down to mirror(3,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> RIGHT -> mirror(5,7). Starts SLASH (WRONG - harmless miss); correct BACKSLASH -> DOWN -> target(5,8) BLUE - independent, two-step, no trap, so the level isn't ALL misdirection. Note: GREEN's correct upward path through column 5 incidentally passes through RED channel's own filter(5,4) first (recoloring to BLUE), then through this branch's own filter(5,3) (recoloring to RED) - the second filter unconditionally overrides, so the final color reaching target(5,2) is still correctly RED; confirmed harmless, not a bug. optimal_moves=4 (mirror(3,0), mirror(5,6), mirror(3,7), mirror(5,7) all must be flipped)."
	is_campaign_level = true
	grid_width = 9
	grid_height = 9
	optimal_moves = 4
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 4)),

		TilePlacement.make_filter(Vector2i(5, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_target(Vector2i(6, 4), GridTypes.BeamColor.BLUE),
		TilePlacement.make_filter(Vector2i(7, 4), GridTypes.BeamColor.GREEN),
		TilePlacement.make_target(Vector2i(8, 4), GridTypes.BeamColor.GREEN),

		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.GREEN, false),
		TilePlacement.make_portal(Vector2i(0, 0), "FS125"),
		TilePlacement.make_portal(Vector2i(7, 6), "FS125"),
		TilePlacement.make_mirror(Vector2i(5, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_filter(Vector2i(5, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_target(Vector2i(5, 2), GridTypes.BeamColor.RED),

		TilePlacement.make_mirror(Vector2i(3, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(5, 7), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 8), GridTypes.BeamColor.BLUE),
	]
