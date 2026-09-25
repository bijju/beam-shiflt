class_name ProceduralDifficultyProfile
extends RefCounted
## Difficulty-band configuration for the procedural generator (Levels
## 1-2000). See PROCEDURAL_GENERATION.md "Difficulty bands" for the full
## table and reasoning. Pure data lookup, no RNG/state of its own -
## ProceduralLevelGenerator reads this once per generation attempt.
##
## Generator versioning (Procedural Difficulty Tuning + QA Jump 50 pass,
## see DECISIONS.md D92): for_level() takes an explicit generator_version
## and selects _BANDS_V1 (frozen, byte-for-byte the original V1 table) or
## _BANDS_V2 (the tuned table) - there is no implicit default, callers
## must decide which version they mean (ProceduralLevelGenerator.generate()
## is the only caller and always passes its own generator_version
## parameter through). _BANDS_V1 must never be edited again - any future
## tuning belongs in a new _BANDS_V3 (or later) table, following this same
## pattern, so an in-progress save built under an older version always
## keeps reproducing identically.

## Measured CenterArea size at the 1080x1920 reference floor (the
## project's guaranteed-minimum logical canvas under "canvas_items"/
## "expand" stretch mode - see CLAUDE.md rule 12b / DECISIONS.md D43: any
## taller or same-aspect device only ever reveals MORE of this canvas,
## never less, so a board profile comfortable here is comfortable on
## every real device by construction). Derived from game.tscn's own
## layout at the current (post D86/D87) constants: SafeMargin's
## UIConstants.GAMEPLAY_HORIZONTAL_MARGIN=32 / GAMEPLAY_VERTICAL_MARGIN=8,
## the Top/Bottom HUD bars' aspect ratios (2.834899 / 2.838710 - see
## game.gd's DEFAULT_TOP_BAR_ASPECT/DEFAULT_BOTTOM_BAR_ASPECT), and the
## Layout VBoxContainer's separation=16 (game.tscn). If game.tscn's
## structure or any of those constants ever change, re-derive this the
## same way TEST_PLAN.md's Phase 1 diagnostic did (drive a real
## GridManager at 1080x1920 and read get_layout_metrics()) rather than
## hand-adjusting this number.
const REFERENCE_PLAYABLE_SIZE := Vector2(1016.0, 1155.73)

## Hard ceiling confirmed against REFERENCE_PLAYABLE_SIZE above: at
## GridManager.MAX_COLUMNS=8 (or fewer columns), a board taller than this
## many rows drops cell_size below MIN_COMFORTABLE_CELL_SIZE at the
## reference floor (12 rows -> ~95px, one below the 96px floor; 11 rows ->
## ~103px, comfortable). Difficulty for higher bands comes from tile/
## mechanic density within this ceiling, per CLAUDE.md's "structure, not
## size" rule - never from exceeding it. Every board candidate list below
## is re-checked live through GridManager.is_board_profile_comfortable()
## in for_level() regardless, so this is a design ceiling, not the only
## safety net. Unchanged by the V2 tuning pass - V2 gets harder entirely
## within this same ceiling, per the pass's own explicit instruction.
const MAX_ROWS := 11

## V1 bands - FROZEN. Do not edit; see the file doc comment.
const _BANDS_V1: Array[Dictionary] = [
	{
		"min": 1, "max": 50, "name": "Introductory",
		"board_candidates": [Vector2i(5, 7), Vector2i(5, 8), Vector2i(6, 8)],
		"rotatable_range": Vector2i(1, 3), "tile_budget": 10, "decoy_budget": 1,
		"optimal_moves_range": Vector2i(1, 3), "states_ceiling": 256,
		"template_pool": ["simple_mirror_route"],
	},
	{
		"min": 51, "max": 150, "name": "Easy/Developing",
		"board_candidates": [Vector2i(6, 8), Vector2i(6, 9), Vector2i(7, 8)],
		"rotatable_range": Vector2i(2, 5), "tile_budget": 16, "decoy_budget": 2,
		"optimal_moves_range": Vector2i(2, 5), "states_ceiling": 2048,
		"template_pool": ["simple_mirror_route", "multi_mirror_route", "splitter_branch", "color_filter_route"],
	},
	{
		"min": 151, "max": 400, "name": "Medium",
		"board_candidates": [Vector2i(7, 9), Vector2i(7, 10), Vector2i(8, 9)],
		"rotatable_range": Vector2i(4, 8), "tile_budget": 22, "decoy_budget": 2,
		"optimal_moves_range": Vector2i(3, 8), "states_ceiling": 8192,
		"template_pool": ["multi_mirror_route", "splitter_branch", "color_filter_route", "portal_route", "switch_gate_dependency"],
	},
	{
		"min": 401, "max": 750, "name": "Medium-Hard",
		"board_candidates": [Vector2i(7, 10), Vector2i(8, 10), Vector2i(7, 11)],
		"rotatable_range": Vector2i(6, 10), "tile_budget": 28, "decoy_budget": 3,
		"optimal_moves_range": Vector2i(4, 10), "states_ceiling": 16384,
		"template_pool": ["multi_mirror_route", "splitter_branch", "color_filter_route", "portal_route", "switch_gate_dependency", "multiple_emitter", "one_way_directional_route"],
	},
	{
		"min": 751, "max": 1200, "name": "Hard",
		"board_candidates": [Vector2i(8, 10), Vector2i(8, 11)],
		"rotatable_range": Vector2i(8, 12), "tile_budget": 32, "decoy_budget": 3,
		"optimal_moves_range": Vector2i(5, 12), "states_ceiling": 32768,
		"template_pool": ["multi_mirror_route", "splitter_branch", "color_filter_route", "portal_route", "switch_gate_dependency", "multiple_emitter", "one_way_directional_route", "prism_color_branch", "receiver_remote_emitter"],
	},
	{
		"min": 1201, "max": 1600, "name": "Expert",
		"board_candidates": [Vector2i(8, 11)],
		"rotatable_range": Vector2i(10, 14), "tile_budget": 36, "decoy_budget": 4,
		"optimal_moves_range": Vector2i(6, 14), "states_ceiling": 49152,
		"template_pool": ["splitter_branch", "color_filter_route", "portal_route", "switch_gate_dependency", "multiple_emitter", "one_way_directional_route", "prism_color_branch", "receiver_remote_emitter"],
	},
	{
		"min": 1601, "max": 2000, "name": "Advanced Expert",
		"board_candidates": [Vector2i(8, 11)],
		"rotatable_range": Vector2i(10, 16), "tile_budget": 40, "decoy_budget": 4,
		"optimal_moves_range": Vector2i(6, 16), "states_ceiling": 65536,
		"template_pool": ["splitter_branch", "color_filter_route", "portal_route", "switch_gate_dependency", "multiple_emitter", "one_way_directional_route", "prism_color_branch", "receiver_remote_emitter"],
	},
]

## V2 bands (Procedural Difficulty Tuning pass, see PROCEDURAL_GENERATION.md
## "Generator V2 difficulty tuning" and DECISIONS.md D92 for the full
## reasoning/audit evidence behind every number here). Three levers, all
## within the existing profile/template system - no new mechanics, no
## smaller tiles, no board taller than MAX_ROWS:
##
## 1. `flip_chance` (new key, read by ProceduralTemplates' scrambling
##    helpers - defaults to 0.65 when absent, i.e. V1's original hardcoded
##    constant, so V1 bands above need no change to keep their exact
##    behavior). Raising it converts a larger fraction of placed rotatable
##    tiles into tiles that actually need a move - this is "more
##    MEANINGFUL rotations," not more tiles, and costs zero extra solver
##    states (BFS state space is 2^rotatable_count regardless of which
##    orientation is authored).
## 2. Modestly higher `rotatable_range` for bands with solver-state
##    headroom (Introductory through Medium-Hard) - each band's new max
##    checked to stay well under its `states_ceiling`. Hard/Expert kept
##    close to V1 (small +1 headroom bump, still well under ceiling).
##    Advanced Expert's ceiling is DELIBERATELY NARROWED (10-16 -> 11-15)
##    - V1's own audit showed a max states_explored of 65519 out of the
##    65536 practical ceiling at rotatable=16, i.e. already nearly
##    exhausting the solver's budget; combined with the flip_chance
##    increase already providing real extra difficulty for free, keeping
##    16 as an achievable value would risk a genuine "solver-pathological"
##    result the brief explicitly warns against. This is a deliberate
##    safety margin, not an oversight.
## 3. `template_pool` entries are duplicated (not a new selection
##    algorithm - see ProceduralLevelGenerator.generate()'s existing
##    `(level_number + attempt) % pool.size()` selection, unchanged) to
##    bias frequency toward the templates that carry a real dependency/
##    two-subsystem structure (portal_route, switch_gate_dependency,
##    multiple_emitter, receiver_remote_emitter, prism_color_branch) in
##    later bands, per the brief's "increase the probability of combining
##    unlocked mechanics" instruction - mechanic UNLOCK progression itself
##    (which template families exist at all in a band's pool) is
##    unchanged from V1.
## Board candidates prefer taller shapes (still <= MAX_ROWS, still
## comfort-filtered below exactly like V1) per the brief's board-profile
## guidance; decoy_budget is REDUCED relative to V1 to match the brief's
## own explicit decoy policy (0 early / 0-1 medium / 0-2 hard / 1-2
## expert) - V1's decoy numbers were higher than this policy recommends,
## since V1 predates the policy. tile_budget is a rejection CEILING, not a
## target - raised generously alongside the taller boards/higher
## rotatable ranges so it never spuriously rejects a valid candidate.
const _BANDS_V2: Array[Dictionary] = [
	{
		"min": 1, "max": 50, "name": "Introductory",
		"board_candidates": [Vector2i(5, 8), Vector2i(5, 9), Vector2i(6, 8)],
		"rotatable_range": Vector2i(2, 5), "tile_budget": 14, "decoy_budget": 0,
		"optimal_moves_range": Vector2i(1, 4), "states_ceiling": 256,
		"flip_chance": 0.85,
		"template_pool": ["simple_mirror_route"],
	},
	{
		"min": 51, "max": 150, "name": "Easy/Developing",
		"board_candidates": [Vector2i(6, 9), Vector2i(6, 10), Vector2i(7, 9)],
		"rotatable_range": Vector2i(3, 6), "tile_budget": 20, "decoy_budget": 0,
		"optimal_moves_range": Vector2i(3, 6), "states_ceiling": 2048,
		"flip_chance": 0.85,
		"template_pool": ["multi_mirror_route", "splitter_branch", "splitter_branch", "color_filter_route", "color_filter_route"],
	},
	{
		"min": 151, "max": 400, "name": "Medium",
		"board_candidates": [Vector2i(7, 10), Vector2i(7, 11), Vector2i(8, 9)],
		"rotatable_range": Vector2i(5, 8), "tile_budget": 26, "decoy_budget": 1,
		"optimal_moves_range": Vector2i(4, 7), "states_ceiling": 8192,
		"flip_chance": 0.85,
		"template_pool": ["multi_mirror_route", "splitter_branch", "color_filter_route", "color_filter_route", "portal_route", "portal_route", "switch_gate_dependency", "switch_gate_dependency"],
	},
	{
		"min": 401, "max": 750, "name": "Medium-Hard",
		"board_candidates": [Vector2i(7, 11), Vector2i(8, 10), Vector2i(8, 11)],
		"rotatable_range": Vector2i(7, 11), "tile_budget": 32, "decoy_budget": 1,
		"optimal_moves_range": Vector2i(5, 8), "states_ceiling": 16384,
		"flip_chance": 0.85,
		"template_pool": ["splitter_branch", "color_filter_route", "portal_route", "portal_route", "switch_gate_dependency", "switch_gate_dependency", "multiple_emitter", "multiple_emitter", "one_way_directional_route"],
	},
	{
		"min": 751, "max": 1200, "name": "Hard",
		"board_candidates": [Vector2i(8, 11)],
		"rotatable_range": Vector2i(8, 13), "tile_budget": 36, "decoy_budget": 2,
		"optimal_moves_range": Vector2i(6, 9), "states_ceiling": 32768,
		"flip_chance": 0.85,
		"template_pool": ["splitter_branch", "color_filter_route", "portal_route", "portal_route", "switch_gate_dependency", "switch_gate_dependency", "multiple_emitter", "multiple_emitter", "one_way_directional_route", "one_way_directional_route", "prism_color_branch", "prism_color_branch", "receiver_remote_emitter", "receiver_remote_emitter"],
	},
	{
		"min": 1201, "max": 1600, "name": "Expert",
		"board_candidates": [Vector2i(8, 11)],
		"rotatable_range": Vector2i(10, 15), "tile_budget": 40, "decoy_budget": 2,
		"optimal_moves_range": Vector2i(7, 10), "states_ceiling": 49152,
		"flip_chance": 0.85,
		"template_pool": ["splitter_branch", "color_filter_route", "portal_route", "portal_route", "switch_gate_dependency", "switch_gate_dependency", "multiple_emitter", "multiple_emitter", "one_way_directional_route", "prism_color_branch", "prism_color_branch", "receiver_remote_emitter", "receiver_remote_emitter", "receiver_remote_emitter"],
	},
	{
		"min": 1601, "max": 2000, "name": "Advanced Expert",
		"board_candidates": [Vector2i(8, 11)],
		"rotatable_range": Vector2i(11, 15), "tile_budget": 44, "decoy_budget": 2,
		"optimal_moves_range": Vector2i(8, 12), "states_ceiling": 65536,
		"flip_chance": 0.85,
		"template_pool": ["splitter_branch", "color_filter_route", "portal_route", "portal_route", "switch_gate_dependency", "switch_gate_dependency", "multiple_emitter", "multiple_emitter", "one_way_directional_route", "one_way_directional_route", "prism_color_branch", "prism_color_branch", "prism_color_branch", "receiver_remote_emitter", "receiver_remote_emitter", "receiver_remote_emitter"],
	},
]


## Returns this level's generation config for the given generator_version
## (1 = _BANDS_V1 exactly, anything else = _BANDS_V2). `board_candidates`
## is already filtered down to shapes GridManager.is_board_profile_comfortable()
## confirms comfortable at REFERENCE_PLAYABLE_SIZE - callers never need to
## re-check comfort for board SELECTION (ProceduralLevelGenerator still
## re-verifies the specific chosen shape as defense in depth).
static func for_level(level_number: int, generator_version: int) -> Dictionary:
	var bands: Array[Dictionary] = _BANDS_V1 if generator_version <= 1 else _BANDS_V2
	var band := _band_for_level(level_number, bands)

	var comfortable_candidates: Array[Vector2i] = []
	for candidate in band["board_candidates"]:
		var check: Dictionary = GridManager.is_board_profile_comfortable(candidate.x, candidate.y, REFERENCE_PLAYABLE_SIZE)
		if check["comfortable"]:
			comfortable_candidates.append(candidate)
	if comfortable_candidates.is_empty():
		comfortable_candidates.append(Vector2i(5, 7)) # guaranteed-safe fallback shape

	# Breather variation (spec "Difficulty scaling": a rising envelope with
	# occasional easier levels, never a strict staircase where N+1 is
	# always harder than N). Every 13th level from the Medium band onward
	# pulls from a reduced rotatable-count range.
	var rotatable_range: Vector2i = band["rotatable_range"]
	var is_breather: bool = level_number > 150 and level_number % 13 == 0
	if is_breather:
		rotatable_range = Vector2i(maxi(1, rotatable_range.x - 3), maxi(2, rotatable_range.y - 4))

	return {
		"level_number": level_number,
		"band_name": band["name"],
		"board_candidates": comfortable_candidates,
		"rotatable_range": rotatable_range,
		"tile_budget": band["tile_budget"],
		"decoy_budget": band["decoy_budget"],
		"optimal_moves_range": band["optimal_moves_range"],
		"states_ceiling": band["states_ceiling"],
		"template_pool": band["template_pool"],
		"is_breather": is_breather,
		"flip_chance": band.get("flip_chance", 0.65),
	}


static func _band_for_level(level_number: int, bands: Array[Dictionary]) -> Dictionary:
	for band in bands:
		if level_number >= band["min"] and level_number <= band["max"]:
			return band
	return bands[0] if level_number < bands[0]["min"] else bands[-1]
