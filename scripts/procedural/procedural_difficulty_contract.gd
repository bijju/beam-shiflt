class_name ProceduralDifficultyContract
extends RefCounted
## The ONE authoritative procedural difficulty contract (Difficulty System
## Phase 1, see DECISIONS.md D93 / PROCEDURAL_GENERATION.md "Difficulty
## contract"). Pure data lookup - no RNG, no state, no level-number branching
## anywhere else: templates, the generator and the triviality evaluator all
## read get_difficulty_requirements() instead of checking a level id.
##
## This is a PRODUCT CONTRACT ("what an accepted puzzle must look like"),
## deliberately separate from ProceduralDifficultyProfile ("how the current
## templates are configured to build one"). Phase 1 does not gate generation
## on it - it is what Phase 2's construction-by-design templates will target
## and what ProceduralTriviality checks a finished puzzle against.
##
## Permanent principle: a procedural puzzle is not accepted solely because
## it is solvable. Difficulty is determined by both optimal-move
## requirements AND meaningful reasoning complexity. After the early game,
## raising the move count through independent or obvious rotations is not
## valid difficulty. Every number below is an INITIAL target, tunable after
## Android testing - edit the table, never scatter a second copy.

## A "meaningful move" is a player rotation that a shortest valid solution
## requires. QA navigation, Reset, Pause, menus, automatic activation, beam
## simulation, animation and save restore are never moves.

## Cap value meaning "no upper bound" for the *_max fields.
const UNBOUNDED := -1

## Bands: [min_level, max_level, name, moves_min, moves_max, deps_min,
## deps_max, depth_min, depth_max, interactions_min, distinct_kinds_min,
## max_decoys, deps_soft]. deps_soft = the dependency floor is "where
## supported". Phase 2B (D96) replaced the Phase 1 numbers with the
## production progression targets. Interactions have NO maximum on purpose:
## the metric counts distinct mechanic-kind PAIRS per target, which are
## triangular numbers (0, 1, 3, 6, 10, ...), so a "4-5" ceiling is not
## attainable - only the floor is meaningful and only the floor is stored.
## Kept as a packed table (not eleven dictionaries) so the whole curve is
## readable at a glance.
const _BANDS: Array = [
	[1, 20, "Foundation", 3, 5, 0, 1, 1, 2, 0, 0, 0, false],
	[21, 50, "Early Thinking", 4, 6, 1, 2, 2, 3, 1, 2, 0, false],
	[51, 100, "Developing", 5, 7, 2, UNBOUNDED, 3, UNBOUNDED, 2, 3, 0, false],
	[101, 200, "Medium", 6, 9, 2, 3, 3, 4, 2, 3, 0, false],
	[201, 400, "Medium-Hard", 8, 11, 3, UNBOUNDED, 4, UNBOUNDED, 3, 3, 1, false],
	[401, 700, "Hard", 10, 14, 3, 4, 5, UNBOUNDED, 4, 4, 1, false],
	[701, 1000, "Hard+", 12, 16, 4, UNBOUNDED, 6, UNBOUNDED, 4, 4, 2, false],
	[1001, 1300, "Expert", 14, 18, 4, 5, 7, UNBOUNDED, 5, 4, 2, false],
	[1301, 1600, "Expert+", 16, 20, 5, UNBOUNDED, 8, UNBOUNDED, 6, 4, 2, false],
	[1601, 1800, "Master", 18, 22, 5, 6, 9, UNBOUNDED, 7, 5, 2, false],
	[1801, 2000, "Advanced Master", 20, 26, 6, UNBOUNDED, 10, UNBOUNDED, 8, 5, 2, false],
]

## Generator V3 policy per level range (Phase 2B, D96): [min_level, max_level,
## min_meaningful_move_fraction, max_plain_move_fraction, greedy_policy,
## keep_correct_fraction, min_plausible_fraction].
##   - meaningful: share of required moves the ablation metric calls dependent.
##   - plain: share of required turns that are interior route turns (not adjacent
##     to a mechanic) - a REJECTION threshold, never a padding target.
##   - greedy_policy: "allowed" / "track" / "prefer_reject" / "reject" for the
##     beam-following triviality heuristic (a heuristic, not human difficulty).
##   - keep_correct_fraction: share of extra mirrors that START already correct.
##   - plausible: share of required states that do not advertise "rotate me".
const _V3_POLICY: Array = [
	[1, 50, 0.5, 0.5, "allowed", 0.0, 0.0],
	[51, 200, 0.6, 0.4, "track", 0.10, 0.0],
	[201, 700, 0.7, 0.3, "prefer_reject", 0.15, 0.25],
	[701, 1300, 0.75, 0.25, "reject", 0.15, 0.3],
	[1301, 2000, 0.8, 0.2, "reject", 0.15, 0.35],
]

## First level at which each mechanic family may appear in a V3 puzzle
## (the user's Phase 2B archetype pools: the Guided Tutorial teaches every
## mechanic in isolation, so progression may combine them early).
const _UNLOCKS: Array = [
	[1, ["mirror", "filter", "portal", "splitter"]],
	[21, ["switch_gate"]],
	[51, ["prism", "shared_mirror"]],
	[101, ["receiver_remote", "one_way"]],
	[201, ["multiple_emitter", "fusion"]],
]

## Fusion progression (Fusion Phase 2, D100): the ONE table saying which Fusion fragments may appear
## where and how often. [min_level, max_level, fragments, probability]. Fragments (recipes in
## ProceduralFragmentsV3.FUSION_RECIPES): F1 basic 2-colour, F2 filter-made inputs, F3 portal on an
## input path, F4 fusion -> switch -> gate, F5 fusion -> receiver -> remote, F6 prism + fusion,
## F7 three-colour (RGB -> WHITE -> prism). `probability` = share of the range's levels that ROLL a
## Fusion recipe (deterministically, from the level's own rng) - never "every eligible level".
## Only generator version 4+ reads this; V1-V3 are frozen. The player-facing Fusion tutorial (T21-T28,
## D101) now exists and unlocks at procedural Level LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL (150),
## before the first Fusion roll at 201. Realised shares (D101 survey) sit inside each band's target range; the
## table is keyed on level number only, so a level past the last row reads the last row (post-2000 = data).
const _FUSION_PROGRESSION: Array = [
	[1, 200, [], 0.0],
	[201, 400, ["F1"], 0.10],
	[401, 700, ["F1", "F2", "F3"], 0.20],
	[701, 1000, ["F1", "F2", "F3", "F4"], 0.24],
	[1001, 1300, ["F2", "F3", "F4", "F5"], 0.26],
	[1301, 1600, ["F2", "F3", "F4", "F5", "F6"], 0.28],
	[1601, 1800, ["F2", "F3", "F4", "F5", "F6", "F7"], 0.28],
	[1801, 2000, ["F1", "F2", "F3", "F4", "F5", "F6", "F7"], 0.28],
]


## {fragments: Array[String], probability: float}. Beyond the last row the last row applies (post-2000
## progression is a data extension, see PROCEDURAL_GENERATION.md "Post-2000 readiness").
static func fusion_policy(level_number: int) -> Dictionary:
	var n := maxi(level_number, 1)
	var row: Array = _FUSION_PROGRESSION[_FUSION_PROGRESSION.size() - 1]
	for r in _FUSION_PROGRESSION:
		if n >= r[0] and n <= r[1]:
			row = r
			break
	return {"fragments": row[2].duplicate(), "probability": row[3]}


## Board shapes (columns x rows) preferred per band: taller portrait shapes,
## never more than GridManager.MAX_COLUMNS columns. Difficulty must never
## come from shrinking tiles - callers still verify comfort live through
## GridManager.is_board_profile_comfortable().
const _BOARDS: Array = [
	[1, 50, [Vector2i(5, 7), Vector2i(5, 8), Vector2i(6, 8)]],
	[51, 100, [Vector2i(5, 9), Vector2i(6, 9), Vector2i(6, 10)]],
	[101, 200, [Vector2i(6, 9), Vector2i(6, 10), Vector2i(7, 9)]],
	[201, 400, [Vector2i(6, 10), Vector2i(7, 9), Vector2i(7, 10)]],
	[401, 700, [Vector2i(6, 10), Vector2i(7, 10), Vector2i(7, 11)]],
	[701, 1600, [Vector2i(7, 10), Vector2i(7, 11), Vector2i(8, 10)]],
	[1601, 2000, [Vector2i(7, 11), Vector2i(8, 10), Vector2i(8, 11)]],
]


## Levels from which a puzzle that is one visible beam from emitter to
## target ("follow the beam, rotate the next mirror") is rejected outright.
const SINGLE_ROUTE_REJECTED_FROM := 30

## Levels from which independent plain-route rotations stop counting as
## difficulty (see ProceduralTriviality's TRIVIAL_INDEPENDENT_ROTATIONS).
const INDEPENDENT_ROTATIONS_REJECTED_FROM := 21


## Everything the generator/evaluator may ask about a level:
## {
##   level_number, band_name,
##   min_optimal_moves, max_optimal_moves,
##   min_meaningful_dependencies, max_meaningful_dependencies (UNBOUNDED = none),
##   dependencies_soft: bool,
##   min_dependency_depth, min_mechanic_interactions, min_distinct_mechanics,
##   max_decoys,
##   preferred_board_profiles: Array[Vector2i],
##   unlocked_mechanics: Array[String],
##   max_independent_move_fraction: float -- share of required moves that may
##       belong to plain (dependency-free) routes; 1.0 = no restriction,
##   reject_single_route: bool,
##   require_non_padding: bool,
##   max_dependency_depth (UNBOUNDED = none), V3 policy: min_meaningful_move_fraction,
##   max_plain_move_fraction, greedy_policy, keep_correct_fraction,
##   min_plausible_fraction (see _V3_POLICY),
## }
static func get_difficulty_requirements(level_number: int) -> Dictionary:
	var row: Array = _band_row(level_number)
	var policy: Array = _policy_row(level_number)
	return {
		"level_number": level_number,
		"band_name": row[2],
		"min_optimal_moves": row[3],
		"max_optimal_moves": row[4],
		"min_meaningful_dependencies": row[5],
		"max_meaningful_dependencies": row[6],
		"dependencies_soft": row[12],
		"min_dependency_depth": row[7],
		"max_dependency_depth": row[8],
		"min_mechanic_interactions": row[9],
		"min_distinct_mechanics": row[10],
		"max_decoys": row[11],
		"preferred_board_profiles": _boards_for(level_number),
		"unlocked_mechanics": unlocked_mechanics(level_number),
		"max_independent_move_fraction": _independent_fraction(level_number),
		"reject_single_route": level_number >= SINGLE_ROUTE_REJECTED_FROM,
		"require_non_padding": true,
		"min_meaningful_move_fraction": policy[2],
		"max_plain_move_fraction": policy[3],
		"greedy_policy": policy[4],
		"keep_correct_fraction": policy[5],
		"min_plausible_fraction": policy[6],
	}


static func _policy_row(level_number: int) -> Array:
	# Not clamped to the certified 2000: a level beyond the last row reads the LAST row (the curated
	# high-difficulty envelope, Fusion Phase 2 / D100) - post-2000 progression is a data extension,
	# never a generator rewrite.
	var n := maxi(level_number, 1)
	for row in _V3_POLICY:
		if n >= row[0] and n <= row[1]:
			return row
	return _V3_POLICY[_V3_POLICY.size() - 1] if n > 1 else _V3_POLICY[0]


static func unlocked_mechanics(level_number: int) -> Array[String]:
	var result: Array[String] = []
	for entry in _UNLOCKS:
		if level_number >= entry[0]:
			for m in entry[1]:
				result.append(m)
	return result


## Share of a puzzle's required moves allowed to sit on plain routes (a
## route whose target depends on nothing but mirrors - "obvious" rotations).
## Loosens to 1.0 in the Foundation band (nothing to enforce yet), then
## tightens with the curve so padding a late puzzle with obvious rotations
## cannot buy difficulty.
static func _independent_fraction(level_number: int) -> float:
	if level_number < INDEPENDENT_ROTATIONS_REJECTED_FROM:
		return 1.0
	if level_number <= 100:
		return 0.75
	if level_number <= 400:
		return 0.6
	if level_number <= 1000:
		return 0.5
	return 0.4


static func _band_row(level_number: int) -> Array:
	var n := maxi(level_number, 1)
	for row in _BANDS:
		if n >= row[0] and n <= row[1]:
			return row
	return _BANDS[_BANDS.size() - 1] if n > 1 else _BANDS[0]


static func _boards_for(level_number: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in _BOARDS:
		if level_number >= row[0] and level_number <= row[1]:
			for b in row[2]:
				result.append(b)
			return result
	for b in _BOARDS[_BOARDS.size() - 1][2]:
		result.append(b)
	return result


## Three-letter band code for the QA-only HUD tag ("V3 HRD" under the level number).
const _BAND_CODES := {
	"Foundation": "FND", "Early Thinking": "ERT", "Developing": "DEV", "Medium": "MED",
	"Medium-Hard": "MHD", "Hard": "HRD", "Hard+": "HD+", "Expert": "EXP", "Expert+": "EX+",
	"Master": "MST", "Advanced Master": "ADV",
}


static func band_code(level_number: int) -> String:
	return _BAND_CODES.get(_band_row(level_number)[2], "???")
