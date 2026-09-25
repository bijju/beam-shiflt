class_name GridTypes
extends RefCounted
## Centralized enums and pure helper functions for the puzzle grid.
## No gameplay state lives here - only deterministic lookups shared by
## the laser simulation, tile scripts, and the grid manager.

enum TileType {
	EMPTY, EMITTER, MIRROR, TARGET, BLOCKER,
	SPLITTER, FILTER, PORTAL, SWITCH, GATE, HAZARD,
	## Era 2 ("Refractions") mechanics - see ERA_2_DESIGN.md for the exact
	## deterministic rules. Appended at the end of the enum so every
	## existing Era 1 TileType value keeps its numeric identity.
	PRISM, ONE_WAY_REFLECTOR, BEAM_RECEIVER, REMOTE_EMITTER,
	## Beam Fusion Node (Fusion Phase 1, D99): appended, existing values keep their identity.
	FUSION,
}

enum Direction { UP, RIGHT, DOWN, LEFT }

enum MirrorOrientation { SLASH, BACKSLASH } ## "/" and "\". Also used by SPLITTER tiles - see DECISIONS.md.

## WHITE is the default/neutral color: emitters default to it (so Milestone 1
## levels are unaffected), and a WHITE-required target accepts a beam of any
## color (see target_accepts_color()). See DECISIONS.md for the color model.
## YELLOW/MAGENTA/CYAN (Fusion Phase 1, D99) are appended so WHITE/RED/GREEN/BLUE keep their
## numeric identity. They exist as FUSION OUTPUT colours (and as Filter/Target/Emitter colours
## like any other); only RED/GREEN/BLUE are valid Fusion INPUT colours.
enum BeamColor { WHITE, RED, GREEN, BLUE, YELLOW, MAGENTA, CYAN }


static func direction_vector(dir: Direction) -> Vector2i:
	match dir:
		Direction.UP:
			return Vector2i(0, -1)
		Direction.RIGHT:
			return Vector2i(1, 0)
		Direction.DOWN:
			return Vector2i(0, 1)
		Direction.LEFT:
			return Vector2i(-1, 0)
	return Vector2i.ZERO


## Centralized reflection rule. Do not duplicate this logic elsewhere.
static func reflect(dir: Direction, orientation: MirrorOrientation) -> Direction:
	if orientation == MirrorOrientation.SLASH:
		match dir:
			Direction.RIGHT:
				return Direction.UP
			Direction.LEFT:
				return Direction.DOWN
			Direction.UP:
				return Direction.RIGHT
			Direction.DOWN:
				return Direction.LEFT
	else: # BACKSLASH
		match dir:
			Direction.RIGHT:
				return Direction.DOWN
			Direction.LEFT:
				return Direction.UP
			Direction.UP:
				return Direction.LEFT
			Direction.DOWN:
				return Direction.RIGHT
	return dir


static func direction_to_angle(dir: Direction) -> float:
	match dir:
		Direction.UP:
			return -PI / 2.0
		Direction.RIGHT:
			return 0.0
		Direction.DOWN:
			return PI / 2.0
		Direction.LEFT:
			return PI
	return 0.0


static func mirror_orientation_to_angle(orientation: MirrorOrientation) -> float:
	# Visual rotation for a line segment representing the mirror.
	return -PI / 4.0 if orientation == MirrorOrientation.SLASH else PI / 4.0


## Centralized target/beam color-matching rule. Do not duplicate this
## logic elsewhere. WHITE is neutral: a WHITE-required target accepts any
## beam color (this is what keeps Milestone 1's uncolored targets working
## unchanged - they default to WHITE and so accept the default WHITE beam,
## but the same rule also lets a WHITE target accept a colored beam if a
## level ever wants a color-agnostic target among colored ones).
static func target_accepts_color(required_color: BeamColor, beam_color: BeamColor) -> bool:
	return required_color == BeamColor.WHITE or required_color == beam_color


## Placeholder render color per beam color. WHITE intentionally matches
## Milestone 1's original beam color (warm yellow-white) so uncolored
## beams look unchanged.
static func beam_color_to_render_color(color: BeamColor) -> Color:
	match color:
		BeamColor.RED:
			return Color(1.0, 0.3, 0.3)
		BeamColor.GREEN:
			return Color(0.35, 1.0, 0.45)
		BeamColor.BLUE:
			return Color(0.4, 0.6, 1.0)
		BeamColor.YELLOW:
			return Color(1.0, 0.68, 0.08) # amber - kept distinct from the warm-white WHITE beam
		BeamColor.MAGENTA:
			return Color(1.0, 0.3, 0.9)
		BeamColor.CYAN:
			return Color(0.15, 0.95, 1.0)
	return Color(1.0, 0.95, 0.3)


## PRISM rule (Era 2, see ERA_2_DESIGN.md "Prism"). A prism is
## non-rotatable and never stores orientation state - each of the three
## color channels has a direction fully derived from the beam's own
## incoming direction, reusing reflect() rather than a new table:
##   RED   channel = incoming_dir unchanged (the "straight" channel)
##   GREEN channel = reflect(incoming_dir, SLASH)  (one turn)
##   BLUE  channel = reflect(incoming_dir, BACKSLASH) (the other turn)
## A WHITE beam entering a prism produces all three channel branches at
## once. A RED/GREEN/BLUE beam entering a prism produces exactly one
## output branch, in that color's own channel direction, unchanged color
## - i.e. a colored beam only ever uses its own matching channel. This
## is fully deterministic (no hidden/random behavior) and needs no new
## solver support, since the prism itself is never a rotatable tile.
static func prism_output_direction(incoming_dir: Direction, channel_color: BeamColor) -> Direction:
	match channel_color:
		BeamColor.GREEN:
			return reflect(incoming_dir, MirrorOrientation.SLASH)
		BeamColor.BLUE:
			return reflect(incoming_dir, MirrorOrientation.BACKSLASH)
		_: # RED (and WHITE, unused as a channel color)
			return incoming_dir


## ONE-WAY REFLECTOR rule (Era 2, see ERA_2_DESIGN.md "One-Way
## Reflector"). Reuses the exact Mirror rotation model (a single
## MirrorOrientation field, toggled by the same tap-to-rotate handler as
## MIRROR/SPLITTER - see GridManager._on_orientable_tile_clicked()) - no
## second stored bit for "which side is reflective". Instead, the
## reflective side is DERIVED from orientation: reflect() already pairs
## each orientation's four incoming directions into two 2-element groups
## (SLASH: {RIGHT,UP} and {LEFT,DOWN}; BACKSLASH: {RIGHT,DOWN} and
## {LEFT,UP} - RIGHT and UP/DOWN are mutual reflect() partners for their
## orientation). This function defines "reflective" as whichever pair
## contains RIGHT for the tile's current orientation; the other pair
## passes straight through untouched, like an empty cell. Rotating the
## tile (the existing SLASH/BACKSLASH toggle) changes BOTH the drawn
## diagonal AND which pair is reflective in one action - satisfying
## "player rotation changes which side reflects" with zero new input
## code or stored state.
static func one_way_reflector_is_reflective(incoming_dir: Direction, orientation: MirrorOrientation) -> bool:
	return incoming_dir == Direction.RIGHT or reflect(incoming_dir, orientation) == Direction.RIGHT


## FUSION color rule (Fusion Phase 1, D99) - the ONE place the mixing table lives.
## Inputs are treated as a SET of distinct primaries (order and duplicates never matter):
##   RED+GREEN -> YELLOW, RED+BLUE -> MAGENTA, GREEN+BLUE -> CYAN, RED+GREEN+BLUE -> WHITE.
## One distinct primary (RED alone, RED+RED, ...), no input, or any non-primary input
## colour (WHITE/YELLOW/MAGENTA/CYAN are not valid inputs in Phase 1) -> -1 (invalid).
## Non-primary colours in the list are ignored, not fatal.
static func combine_beam_colors(colors: Array) -> int:
	var mask := 0
	for c in colors:
		match int(c):
			BeamColor.RED:
				mask |= 1
			BeamColor.GREEN:
				mask |= 2
			BeamColor.BLUE:
				mask |= 4
	match mask:
		3:
			return BeamColor.YELLOW
		5:
			return BeamColor.MAGENTA
		6:
			return BeamColor.CYAN
		7:
			return BeamColor.WHITE
	return -1


static func is_fusion_input_color(color: int) -> bool:
	return color == BeamColor.RED or color == BeamColor.GREEN or color == BeamColor.BLUE


static func opposite_direction(dir: int) -> int:
	match dir:
		Direction.UP:
			return Direction.DOWN
		Direction.DOWN:
			return Direction.UP
		Direction.LEFT:
			return Direction.RIGHT
	return Direction.LEFT
