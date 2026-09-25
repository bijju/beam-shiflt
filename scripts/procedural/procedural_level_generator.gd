class_name ProceduralLevelGenerator
extends RefCounted
## Procedural level generator V1 (Levels 1-2000). See
## PROCEDURAL_GENERATION.md for the full architecture writeup. Builds a
## LevelData for the given level_number using ProceduralDifficultyProfile
## (band/mechanic config) and ProceduralTemplates (solution-first puzzle
## construction), then self-verifies every candidate via the real
## LaserSystem before accepting it - never presents an unverified
## candidate. Deterministic: the same (level_number, generator_version)
## always yields the same accepted LevelData, since every random draw
## flows through ProceduralSeed.rng_for_attempt().
##
## Runtime vs. dev-time verification (important - see CLAUDE.md rule 9):
## this file is a normal RUNTIME dependency (scripts/procedural/, NOT
## excluded from the Android export) because PLAY/CONTINUE/QA-Next call it
## live on-device. It deliberately never calls LevelSolver/LevelValidator
## (scripts/tools/**, dev-only, excluded from export) - those keep proving
## the GENERATOR itself (every template/profile combination) exhaustively
## during this pass's dev-time audit (scripts/tools/procedural_audit.gd),
## exactly like LevelSolver once proved each of the 140 handcrafted
## campaign levels during authoring without game.gd ever calling it at
## runtime. The live per-level gate below instead confirms - via a single
## direct LaserSystem.simulate_until_stable() call, not a BFS search -
## that the SPECIFIC solution each template already constructed actually
## simulates as solved. This is fast (no search), safe (LaserSystem is
## core gameplay code), and keeps rule 9's dev-only boundary completely
## intact.
## Bumped 1 -> 2 for the Procedural Difficulty Tuning pass (see
## PROCEDURAL_GENERATION.md "Generator V2 difficulty tuning" and
## DECISIONS.md D92) - ProceduralDifficultyProfile.for_level() and every
## ProceduralTemplates flip_chance lookup are version-gated, so
## generate(level_number, 1) still reproduces EXACTLY what it always has
## (byte-for-byte, _BANDS_V1 is frozen) for any in-progress save built
## under V1; only a caller that explicitly passes (or defaults to) this
## constant gets V2's tuning. See game.gd's procedural branch for the
## resume-vs-fresh version decision that keeps this contract honest at
## the one real call site that matters.
const GENERATOR_VERSION := 2

## Named generator versions (Phase 2A, D94). GENERATOR_VERSION above stays the
## DEFAULT for new play (V2); V1/V2 stay frozen/reproducible for saves, and V3
## (ProceduralProgressionV3, the dependency-first progression generator - Phase 2B, D96) is
## reachable by passing 3 explicitly (a saved version-3 puzzle, or new play while
## LevelManager.USE_V3_FOR_PROCEDURAL_QA is on; the six prototypes live in ProceduralGeneratorV3).
const GENERATOR_VERSION_V1 := 1
const GENERATOR_VERSION_V2 := 2
const GENERATOR_VERSION_V3 := 3
## V4 = the V3 progression generator with Fusion fragments enabled (Fusion Phase 2, D100). A NEW version
## (not a mutation of V3) because Fusion changes what a level number generates: a saved version-3
## puzzle keeps regenerating byte-identically as V3, a saved version-4 puzzle as V4.
const GENERATOR_VERSION_V4 := 4

const MAX_ATTEMPTS := 40

const MIN_LEVEL := 1
## Initial production CERTIFICATION target (Levels 1-2000). NOT a permanent architectural ceiling: the
## difficulty contract, fragment planner and seed derivation are level-number-open (a level beyond the
## last band reads the last band) - see PROCEDURAL_GENERATION.md "Post-2000 readiness".
const INITIAL_CERTIFIED_LEVEL_TARGET := 2000
## The highest level the game currently EXPOSES (PLAY, Continue, QA jump). Equal to the certified
## target in this pass; raising it is a deliberate later phase, never a side effect.
const MAX_LEVEL := INITIAL_CERTIFIED_LEVEL_TARGET


## Returns:
## {
##   "level_data": LevelData,
##   "seed": int,
##   "attempt": int,
##   "generator_version": int,
##   "template_id": String,
##   "board_size": Vector2i,
##   "fallback_used": bool,
##   "rejections": Array[Dictionary],  # {attempt, template, board, reason} for every rejected candidate
##   "solution_orientations": Dictionary,  # Vector2i -> MirrorOrientation, the template's intended solution (read by ProceduralComplexity)
##   "intended_moves": int,  # == level_data.optimal_moves; Phase 2 star thresholds should use the solver-verified value
## }
static func generate(level_number: int, generator_version: int = GENERATOR_VERSION) -> Dictionary:
	if generator_version == GENERATOR_VERSION_V3 or generator_version == GENERATOR_VERSION_V4:
		return ProceduralProgressionV3.generate(level_number, generator_version)
	var profile := ProceduralDifficultyProfile.for_level(level_number, generator_version)
	var rejections: Array = []

	for attempt in range(MAX_ATTEMPTS):
		var rng := ProceduralSeed.rng_for_attempt(level_number, generator_version, attempt)
		var board_candidates: Array = profile["board_candidates"]
		var template_pool: Array = profile["template_pool"]
		# Selection is keyed off level_number (not just attempt) so different
		# LEVELS within the same band genuinely vary which template/board
		# they use - attempt=0 succeeds on the vast majority of candidates
		# (see PROCEDURAL_GENERATION.md "Generation attempts" audit numbers),
		# so keying purely on `attempt % pool.size()` would make attempt 0
		# always land on template_pool[0], and every level in a band would
		# end up using the SAME first template. Only ever discovered by
		# actually auditing the mechanic-frequency distribution across
		# 1-2000, not by reading this function in isolation - see
		# DECISIONS.md.
		var board_size: Vector2i = board_candidates[(level_number + attempt) % board_candidates.size()]
		var template_id: String = template_pool[(level_number + attempt) % template_pool.size()]

		var built := ProceduralTemplates.build(template_id, rng, profile, board_size)
		var candidate: LevelData = built["level_data"]
		candidate.level_id = level_number
		candidate.display_name = "Level %d" % level_number
		candidate.stage = "procedural"
		candidate.is_campaign_level = false

		var verdict := _verify(candidate, profile, board_size, built["solution_orientations"])
		if not verdict["ok"]:
			rejections.append({"attempt": attempt, "template": template_id, "board": board_size, "reason": verdict["reason"]})
			continue

		candidate.optimal_moves = maxi(verdict["move_count"], 1)
		return {
			"level_data": candidate,
			"seed": ProceduralSeed.for_attempt(level_number, generator_version, attempt),
			"attempt": attempt,
			"generator_version": generator_version,
			"template_id": template_id,
			"board_size": board_size,
			"fallback_used": false,
			"rejections": rejections,
			"solution_orientations": built["solution_orientations"],
			"intended_moves": candidate.optimal_moves,
		}

	# Every attempt was rejected - fall back to the simplest guaranteed-safe
	# shape (still self-verified, never skipped - see PROCEDURAL_GENERATION.md
	# "Fallback behavior"). Target across the whole 1-2000 audit is 0
	# fallbacks; this path exists purely as a safety net.
	var fallback_seed := ProceduralSeed.for_attempt(level_number, generator_version, MAX_ATTEMPTS)
	var fallback_rng := RandomNumberGenerator.new()
	fallback_rng.seed = fallback_seed
	var fallback_board := Vector2i(5, 7)
	var fallback_built := ProceduralTemplates.build("simple_mirror_route", fallback_rng, {
		"rotatable_range": Vector2i(1, 1), "decoy_budget": 0, "tile_budget": 6,
	}, fallback_board)
	var fallback_level: LevelData = fallback_built["level_data"]
	fallback_level.level_id = level_number
	fallback_level.display_name = "Level %d" % level_number
	fallback_level.stage = "procedural"

	var fallback_verdict := _verify(fallback_level, profile, fallback_board, fallback_built["solution_orientations"])
	fallback_level.optimal_moves = maxi(fallback_verdict.get("move_count", 1), 1)

	return {
		"level_data": fallback_level,
		"seed": fallback_seed,
		"attempt": MAX_ATTEMPTS,
		"generator_version": generator_version,
		"template_id": "simple_mirror_route_fallback",
		"board_size": fallback_board,
		"fallback_used": true,
		"rejections": rejections,
		"solution_orientations": fallback_built["solution_orientations"],
		"intended_moves": fallback_level.optimal_moves,
	}


## Runtime-safe candidate verification - see the file doc comment for why
## this never calls LevelSolver/LevelValidator. Returns
## { "ok": bool, "reason": String, "move_count": int }.
static func _verify(candidate: LevelData, profile: Dictionary, board_size: Vector2i, solution_orientations: Dictionary) -> Dictionary:
	if board_size.x > GridManager.MAX_COLUMNS:
		return {"ok": false, "reason": "columns exceed MAX_COLUMNS", "move_count": 0}

	var comfort: Dictionary = GridManager.is_board_profile_comfortable(board_size.x, board_size.y, ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE)
	if not comfort["comfortable"]:
		return {"ok": false, "reason": "board not comfortable: %s" % comfort["reason"], "move_count": 0}

	var tile_budget: int = int(profile.get("tile_budget", 999))
	if candidate.tiles.size() > tile_budget:
		return {"ok": false, "reason": "tile count (%d) exceeds budget (%d)" % [candidate.tiles.size(), tile_budget], "move_count": 0}

	var structural_error := _structural_check(candidate)
	if structural_error != "":
		return {"ok": false, "reason": structural_error, "move_count": 0}

	# Authored (scrambled) state must NOT already be solved - a candidate
	# that requires zero moves is rejected (see spec's "unintended
	# immediate solution" quality gate).
	var authored_orientations := candidate.get_initial_tile_orientations()
	var authored_result: Dictionary = LaserSystem.simulate_until_stable(candidate, authored_orientations)
	if authored_result["solved"]:
		return {"ok": false, "reason": "authored state is already solved (trivial)", "move_count": 0}

	# The solution this template intended must actually simulate as solved.
	var solved_orientations := candidate.get_initial_tile_orientations()
	for pos in solution_orientations:
		solved_orientations[pos] = solution_orientations[pos]
	var solved_result: Dictionary = LaserSystem.simulate_until_stable(candidate, solved_orientations)
	if not solved_result["solved"]:
		return {"ok": false, "reason": "intended solution did not simulate as solved", "move_count": 0}
	if solved_result["looped"]:
		return {"ok": false, "reason": "intended solution path looped", "move_count": 0}

	var move_count := 0
	for pos in solution_orientations:
		if authored_orientations.get(pos, GridTypes.MirrorOrientation.SLASH) != solution_orientations[pos]:
			move_count += 1

	var moves_range: Vector2i = profile.get("optimal_moves_range", Vector2i(1, 999))
	if move_count < 1 or move_count > moves_range.y * 2:
		# A modest overshoot past the band's declared range is accepted
		# (structure varies naturally); an extreme one usually means the
		# template degenerated (e.g. a clamped path collision) and should
		# retry with a different deterministic attempt instead.
		return {"ok": false, "reason": "move_count (%d) out of range" % move_count, "move_count": move_count}

	return {"ok": true, "reason": "", "move_count": move_count}


## Minimal structural sanity check the generator can own directly (no
## duplicate positions, everything in-bounds) - NOT a reimplementation of
## LevelValidator's full rule set (portal pairing, switch/gate/receiver
## dangling references, etc.), which stays dev-only and is exercised
## exhaustively against the generator's own output during the dev-time
## audit instead. This only guards the two failure modes ProceduralTemplates'
## own geometry (clamped/collided paths) could realistically produce.
static func _structural_check(candidate: LevelData) -> String:
	var seen: Dictionary = {}
	for t in candidate.tiles:
		if t.position.x < 0 or t.position.y < 0 or t.position.x >= candidate.grid_width or t.position.y >= candidate.grid_height:
			return "tile out of bounds at %s" % t.position
		if seen.has(t.position):
			return "duplicate tile at %s" % t.position
		seen[t.position] = true
	return ""
