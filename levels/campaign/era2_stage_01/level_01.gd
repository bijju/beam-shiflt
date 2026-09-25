extends LevelData
## Campaign Level 101 — "First Refraction". THE FIRST ERA 2 CAMPAIGN LEVEL.
## Player's first non-tutorial Prism puzzle: one WHITE beam splits into all
## three RGB channels, spread top/middle/bottom of the board. RED arrives
## for free (straight channel); GREEN and BLUE each need one mirror flip,
## each starting at the plausible-but-wrong orientation. See ERA_2_DESIGN.md
## "Prism" for the exact channel-direction rule this depends on.

func _init() -> void:
	level_id = 1
	display_name = "First Refraction"
	stage = "Spectrum"
	developer_notes = "DESIGN INTENT: emitter(0,3) RIGHT WHITE -> prism(3,3). RED channel = straight (incoming_dir unchanged) -> continues along row 3 to target(6,3) RED, no move needed - the free 'auto-arrives' channel, same pattern as T12. GREEN channel = reflect(RIGHT,SLASH) = UP -> column 3 upward to mirror(3,0). Mirror starts BACKSLASH (WRONG - reflect(UP,BACKSLASH)=LEFT sends the beam along row 0 away from the target, harmless miss); correct SLASH -> reflect(UP,SLASH)=RIGHT -> row 0 rightward to target(6,0) GREEN. BLUE channel = reflect(RIGHT,BACKSLASH) = DOWN -> column 3 downward to mirror(3,6). Mirror starts SLASH (WRONG - reflect(DOWN,SLASH)=LEFT, harmless miss); correct BACKSLASH -> reflect(DOWN,BACKSLASH)=RIGHT -> row 6 rightward to target(6,6) BLUE. Both wrong starting orientations are the 'plausible incorrect' pitfall the brief asked for - a player unfamiliar with reflect() has a 50/50 guess each time. optimal_moves=2 (both mirrors must be flipped). Three colors physically separated top/middle/bottom of a 7x7 board - full height and width utilization by construction, no wasted rows."
	is_campaign_level = true
	grid_width = 7
	grid_height = 7
	optimal_moves = 2
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 3), GridTypes.Direction.RIGHT, GridTypes.BeamColor.WHITE),
		TilePlacement.make_prism(Vector2i(3, 3)),
		TilePlacement.make_target(Vector2i(6, 3), GridTypes.BeamColor.RED),
		TilePlacement.make_mirror(Vector2i(3, 0), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(6, 0), GridTypes.BeamColor.GREEN),
		TilePlacement.make_mirror(Vector2i(3, 6), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(6, 6), GridTypes.BeamColor.BLUE),
	]
