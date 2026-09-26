class_name ProceduralProgressionV3
extends RefCounted
## Generator V3 as a real progression generator (Difficulty System Phase 2B,
## D96): (level number, seed, difficulty band) -> a dependency-first puzzle.
##
##   ProceduralDifficultyContract band -> ProceduralFragmentsV3 (atoms -> line
##   tree + required-move budget) -> ProceduralComposerV3 (portrait board layout)
##   -> gates: structural validity, ablation metrics vs the band contract,
##   load-bearing promises, plain/meaningful/plausible ratios, greedy resistance.
##
## Difficulty comes from the plan, not from retries; a candidate is rebuilt only
## when the plan cannot be placed or a gate rejects it. The attempt cap stays at
## the prototype's scale (12).
##
## Runtime-safe (CLAUDE.md rule 9): only LaserSystem (via ProceduralComplexity) -
## never LevelSolver/LevelValidator. Optimal-vs-intended shortcut proof is
## dev-time only (scripts/tools/v3_progression_sample.tscn on sampled levels).
##
## Fallback policy (D96): if every attempt fails, V2 supplies a valid puzzle so
## the game never breaks, but the result is flagged `v3_generation_failed` /
## `fallback_used`, a warning is printed, and `fallback_count` is incremented so QA
## sees it. A V2 fallback is NEVER counted as a successful V3 level.

const GENERATOR_VERSION := 3
## Fusion-capable progression (Fusion Phase 2, D100): the same pipeline with the Fusion fragments and
## their per-band unlock table enabled. V3 stays frozen; V4 has its own seed space (version in the key).
const GENERATOR_VERSION_FUSION := 4
## Selector-capable progression (Selector Phase S3, D110): the V4 pipeline + Splitter Selector fragments, Levels
## 2001-3000. A NEW version (not a mutation of V4): V1-V4 stay frozen and a saved puzzle regenerates under its own.
const GENERATOR_VERSION_SELECTOR := 5
## V5 boards carry up to ~34 required moves on 8x11/8x12, so more placement attempts are allowed than in V3/V4.
const MAX_ATTEMPTS_V5 := 64
## Attempts that keep trying the level's rolled Selector family before falling back to an ordinary V5 recipe
## (the level then carries no Selector: `selector_dropped`, counted and reported - never hidden).
const SELECTOR_ATTEMPTS := 30
## V5: from this attempt on the level may fall back to the reasoning floors of the band below (see generate()).
const V5_DEMOTE_AFTER := 32
const V5_DEMOTE_AFTER_SELECTOR := 32
const V5_DEMOTE_AFTER_K := 48
const V5_RELAX_GRACE := 3
## Consequence + Mastery bands: at least one Selector must have a wrong output that changes a state or meets a mechanic.
const V5_STRICT_SELECTOR_FROM := 2601
## Simulation budget / beam width of the ONE final shortcut probe a V5 candidate must survive.
const V5_FINAL_PROBE_SIMS := 3200
const V5_FINAL_PROBE_WIDTH := 48
const MAX_ATTEMPTS := 12
## Dense late plans (Level 1301+; from 1001 in generator V4, D100) get a few more tries: ~2% of them need >12 attempts.
const MAX_ATTEMPTS_LATE := 16
## Runtime shortcut-probe budget for boards with a Fusion node (plain boards keep the 420 / 12 default).
const FUSION_PROBE_SIMS := 1500
const FUSION_PROBE_WIDTH := 28
## Attempts that keep trying the level's rolled Fusion recipe before falling back to an ordinary recipe.
const FUSION_ATTEMPTS := 6
const FUSION_ATTEMPTS_LATE := 8
## rng stream index of the once-per-level Fusion roll (attempt streams start at _ATTEMPT_SEED_OFFSET).
const FUSION_ROLL_STREAM := 90
## Attempt seeds are offset so they can never collide with the six prototype
## fixtures' seeds (ProceduralGeneratorV3 uses attempts 0..11 of the same key).
const _ATTEMPT_SEED_OFFSET := 100

static var fallback_count: int = 0
## V5: levels whose rolled Selector family could not be placed/accepted and that therefore carry no Selector.
static var selector_dropped_count: int = 0
## V5: levels accepted only under the demoted (band below) reasoning floors.
static var band_demoted_count: int = 0
## Dev switch (v3_progression_sample.tscn `probe=0`) to measure the RAW shortcut rate
## of the composer without the runtime probe. Always true in the game.
static var shortcut_probe_enabled: bool = true


## Same core keys as ProceduralGeneratorV3.generate() plus band/composition
## metadata (see the returned dictionary below).
static func generate(level_number: int, version: int = GENERATOR_VERSION) -> Dictionary:
	var fusion_enabled := version >= GENERATOR_VERSION_FUSION
	# The level's ONE Fusion roll (dedicated rng stream, never re-rolled per attempt). The recipe is tried for
	# the first FUSION_ATTEMPTS attempts; if it cannot be placed/accepted the level falls back to an ordinary
	# recipe rather than to V2 (the realised Fusion share is reported by fusion_progression_sample).
	var fusion_recipe: Array[String] = []
	if fusion_enabled:
		fusion_recipe = ProceduralFragmentsV3.roll_fusion_recipe(level_number, ProceduralSeed.rng_for_attempt(level_number, version, FUSION_ROLL_STREAM))
	# Generator V5 (D110): the level's ONE Selector roll (dedicated stream). A Fusion family forces a Fusion recipe.
	var selector_spec: Dictionary = {}
	if version >= GENERATOR_VERSION_SELECTOR:
		selector_spec = ProceduralFragmentsV3.roll_selector(level_number, ProceduralSeed.rng_for_attempt(level_number, version, ProceduralFragmentsV3.SELECTOR_ROLL_STREAM), not fusion_recipe.is_empty())
		if not selector_spec.is_empty() and selector_spec["fusion"] and fusion_recipe.is_empty():
			fusion_recipe = ProceduralFragmentsV3.roll_fusion_recipe(level_number, ProceduralSeed.rng_for_attempt(level_number, version, FUSION_ROLL_STREAM + 1), true)
	var fusion_attempts := FUSION_ATTEMPTS_LATE if level_number >= 1301 else FUSION_ATTEMPTS
	var selector_attempts := SELECTOR_ATTEMPTS
	if not selector_spec.is_empty() and selector_spec["fusion"]:
		fusion_attempts = maxi(fusion_attempts, SELECTOR_ATTEMPTS) # a Fusion recipe FORCED by a Selector family gets the Selector's whole window
	# A level demotes its reasoning floors only after a strict search window. K gets a longer runway: S3.1's measured
	# failures were concentrated there, and delaying demotion preserves the band contract instead of lowering K's targets.
	var demote_at := V5_DEMOTE_AFTER_SELECTOR if not selector_spec.is_empty() else V5_DEMOTE_AFTER
	if level_number >= 2801:
		demote_at = V5_DEMOTE_AFTER_K
	var min_downstream := int(ProceduralDifficultyContract.selector_policy(level_number)["min_downstream_depth"])
	var no_fusion: Array[String] = []
	var req := ProceduralDifficultyContract.get_difficulty_requirements(level_number)
	req["min_required_branches"] = 1
	req["band_min_moves"] = req["min_optimal_moves"]
	var rejections: Array = []
	var layout_failures := 0
	var soft_pick: Dictionary = {} # first candidate that passed every hard gate but was greedy-solvable

	var max_attempts := MAX_ATTEMPTS_V5 if version >= GENERATOR_VERSION_SELECTOR else (MAX_ATTEMPTS_LATE if (level_number >= 1301 or (fusion_enabled and level_number >= 1001)) else MAX_ATTEMPTS)
	for attempt in range(max_attempts):
		var rng := ProceduralSeed.rng_for_attempt(level_number, version, _ATTEMPT_SEED_OFFSET + attempt)
		var t0 := Time.get_ticks_usec()
		# Generator V5 (D110): a plan that is physically too dense for the board lowers the MOVE target (each layout
		# failure by 1, at most V5_MOVE_RELAX_FRACTION of the band floor) - never the reasoning floors (depth,
		# dependencies, interactions, kinds, Selector rules). Moves are the least meaningful metric; a level that lands
		# below its band's move window is reported `moves_below_band` instead of padded.
		var ra := req
		var demoted := false
		if version >= GENERATOR_VERSION_SELECTOR:
			ra = req.duplicate()
			if attempt >= demote_at:
				# Last resort before the V2 fallback: the REASONING floors of the band below (never the Selector rules), so the
				# level is still a real V5 puzzle - flagged `band_demoted`, counted and reported, never silent.
				demoted = true
				var lower := ProceduralDifficultyContract.get_difficulty_requirements(ProceduralDifficultyContract.band_start(level_number) - 1)
				for key in ["min_optimal_moves", "max_optimal_moves", "min_meaningful_dependencies", "min_dependency_depth", "min_mechanic_interactions", "min_distinct_mechanics"]:
					ra[key] = lower[key]
				ra["band_min_moves"] = lower["min_optimal_moves"]
			# The first three layout failures are ordinary retries (as in V3/V4); only persistent ones shave the move floor.
			if layout_failures > V5_RELAX_GRACE:
				var cap := int(round(float(ra["min_optimal_moves"]) * ProceduralFragmentsV3.V5_MOVE_RELAX_FRACTION))
				ra["min_optimal_moves"] = maxi(3, int(ra["min_optimal_moves"]) - mini(cap, layout_failures - V5_RELAX_GRACE))
		var composed := ProceduralFragmentsV3.compose(level_number, ra, rng, layout_failures, fusion_recipe if attempt < fusion_attempts else no_fusion, selector_spec if attempt < selector_attempts else {})
		_tick("compose", t0)
		if not composed["ok"]:
			rejections.append({"attempt": attempt, "stage": "plan", "reasons": [composed["reason"]]})
			continue
		if version >= GENERATOR_VERSION_SELECTOR:
			ra = ra.duplicate()
			ra["min_optimal_moves"] = int(composed["min_moves"])
		var plan: ProceduralPlanV3 = composed["plan"]
		var boards: Array = req["preferred_board_profiles"]
		var size := _board_for(level_number, attempt, boards)
		t0 = Time.get_ticks_usec()
		var board := ProceduralComposerV3.build(plan, rng, size.x, size.y)
		_tick("build", t0)
		var density_est := float(composed["tile_estimate"]) / float(size.x * size.y)
		if board.failure != "":
			rejections.append({"attempt": attempt, "stage": "layout", "reasons": [board.failure], "atoms": composed["atoms"], "board": size, "density_est": float(composed["tile_estimate"]) / float(size.x * size.y), "ops": ProceduralComposerV3.last_ops})
			layout_failures += 1
			continue

		board.center_content()
		t0 = Time.get_ticks_usec()
		var hardened := ProceduralComposerV3.harden(board)
		_tick("harden", t0)
		board.apply_keep_correct(rng, mini(int(composed["keep"]), maxi(0, board.solution.size() - int(ra["min_optimal_moves"]))))
		var level := board.to_level_data(board.w, board.h)
		var tiles_used := board.tiles.size()
		level.level_id = level_number
		level.display_name = "Level %d" % level_number
		level.stage = "procedural"
		level.is_campaign_level = false

		t0 = Time.get_ticks_usec()
		var check := ProceduralGeneratorV3._check(level, board, plan, _req_for(ra, composed))
		_tick("check", t0)
		var metrics: Dictionary = check["metrics"]
		var reasons: Array = check["reasons"].duplicate()
		var visibility := {}
		var fusion_report := {}
		if check["ok"]:
			_extra_gates(level_number, level, board, req, metrics, composed, reasons)
			if version >= GENERATOR_VERSION_SELECTOR:
				# Splitter Selector (D110): every Selector load-bearing, non-equivalent, not mirror-like, with a live wrong
				# output; several Selectors must be coupled; the deepest decision must feed enough mechanics.
				var sel_metrics: Dictionary = metrics.get("selector", {})
				if not sel_metrics.is_empty():
					for sr in ProceduralSelectorCheck.reasons_for(sel_metrics, min_downstream, level_number >= V5_STRICT_SELECTOR_FROM and not demoted):
						reasons.append("selector: %s" % sr)
					if int(hardened.get("selector_unrepaired", 0)) > 0:
						reasons.append("selector: %d wrong output(s) solve the board and have no room for a blocker" % int(hardened["selector_unrepaired"]))
				if not composed["selectors"].is_empty() and sel_metrics.is_empty():
					reasons.append("selector: the rolled family placed none")
			if fusion_enabled and ProceduralFragmentsV3.fusion_fragment_of(composed["atoms"]) != "":
				# Fusion (D100): per-input ablation, colour consumption, feedback (cycle) rejection and
				# convergence of the start/solved/one-tap-away boards. Reject-and-retry, never "hope".
				t0 = Time.get_ticks_usec()
				fusion_report = ProceduralFusionCheck.evaluate(level, board.solution)
				_tick("fusion_check", t0)
				var expected_nodes := 0
				for st in plan.stages:
					if st["role"] == "fusion":
						expected_nodes += 1
				if fusion_report["fusions"].size() != expected_nodes:
					reasons.append("plan promised %d fusion node(s), board has %d" % [expected_nodes, fusion_report["fusions"].size()])
				for fr in fusion_report["reasons"]:
					reasons.append("fusion: %s" % fr)
				# A node turned to a wrong direction that meets a tile with no free cell to block would
				# throw its fused beam straight into it (an exact search found a target reachable this way).
				if int(hardened.get("fusion_unrepaired", 0)) > 0:
					reasons.append("fusion: %d wrong-direction output(s) hit a tile with no room for a blocker" % int(hardened["fusion_unrepaired"]))
			t0 = Time.get_ticks_usec()
			visibility = ProceduralComplexity.start_state_visibility(level, board.solution)
			_tick("visibility", t0)
			var required_states: int = int(visibility["required_tiles"]) + int(visibility["preserved_tiles"])
			var plausible := float(visibility["initially_plausible_required_states"]) / float(maxi(required_states, 1))
			if plausible < float(req["min_plausible_fraction"]):
				reasons.append("only %d%% of required states are plausible/hidden" % int(plausible * 100.0))
		if not reasons.is_empty():
			rejections.append({"attempt": attempt, "stage": "gate", "density_est": density_est, "ops": ProceduralComposerV3.last_ops, "reasons": reasons, "metrics": metrics, "atoms": composed["atoms"], "board": size, "ascii": ProceduralBoardV3.ascii(level)})
			continue

		# Bounded runtime shortcut probe (beam search over touched-tile flips): a cheaper
		# route than the intended one means the intended move count over-states difficulty.
		t0 = Time.get_ticks_usec()
		# Fusion boards get a wider probe: an exact/wide-probe study (D100) found alternate mirror
		# arrangements at ~11% of late Fusion levels versus ~4% plain, and the default 420-simulation
		# screen missed half of them.
		var probe := {"shortcut": false}
		if shortcut_probe_enabled:
			# Fusion and Selector boards (4-state tiles: alternate routes are likelier) get the wide probe. Generator V5 keeps the
			# cheap default here (a pre-filter) and runs ONE much wider probe on the candidate that survives every other gate (below).
			if fusion_report.is_empty() and (int(metrics["selector_count"]) == 0 or version >= GENERATOR_VERSION_SELECTOR):
				probe = ProceduralShortcutProbe.probe(level, int(metrics["intended_move_count"]), board.solution)
			else:
				probe = ProceduralShortcutProbe.probe(level, int(metrics["intended_move_count"]), board.solution, FUSION_PROBE_SIMS, FUSION_PROBE_WIDTH)
		_tick("probe", t0)
		if probe["shortcut"]:
			rejections.append({"attempt": attempt, "stage": "shortcut", "reasons": ["solvable in %d flips, intended %d" % [probe["depth"], metrics["intended_move_count"]]], "atoms": composed["atoms"], "board": size, "ascii": ProceduralBoardV3.ascii(level)})
			continue
		var greedy_solved := false
		var policy: String = req["greedy_policy"]
		if policy != "allowed": # "track" records the flag without acting on it
			t0 = Time.get_ticks_usec()
			greedy_solved = ProceduralComplexity.greedy_follow_solve(level)["solved"]
			_tick("greedy", t0)
		# Generator V5 (D110): the expensive last gate. A whole group of required-looking tiles that turns out superfluous (found
		# by real-GridManager replay: ~14% of unscreened Mastery boards) means the intended move count overstates the difficulty.
		if version >= GENERATOR_VERSION_SELECTOR:
			t0 = Time.get_ticks_usec()
			var minimal := ProceduralMinimality.find_cheaper(level, board.solution, board.tile_line)
			_tick("minimality", t0)
			if not minimal["cheaper"] and shortcut_probe_enabled:
				# The final, wide shortcut probe (D110): an independent 2500-simulation probe found 9-14-flip alternatives in ~2% of
				# Selector Entry/Branching boards that the runtime screens had accepted (whole sub-routes bypassed by a stray beam).
				t0 = Time.get_ticks_usec()
				var final_probe := ProceduralShortcutProbe.probe(level, int(metrics["intended_move_count"]), board.solution, V5_FINAL_PROBE_SIMS, V5_FINAL_PROBE_WIDTH)
				_tick("final_probe", t0)
				if final_probe["shortcut"]:
					rejections.append({"attempt": attempt, "stage": "shortcut", "reasons": ["final probe: solvable in %d flips, intended %d" % [final_probe["depth"], metrics["intended_move_count"]]], "atoms": composed["atoms"], "board": size})
					continue
			if minimal["cheaper"]:
				rejections.append({"attempt": attempt, "stage": "minimality", "reasons": ["solution not minimal: %d of %d required tiles are superfluous (%s)" % [minimal["saved"], minimal["required"], minimal["how"]]], "atoms": composed["atoms"], "board": size})
				continue
		level.optimal_moves = maxi(int(metrics["intended_move_count"]), 1)
		var result := _result(level_number, level, hardened, board, plan, composed, metrics, check["verdict"], visibility, attempt, rejections, req, version)
		result["greedy_solved"] = greedy_solved
		# The fragment id is the ROLLED recipe's (escalation may add unrelated atoms, e.g. a Receiver, to an F1 node).
		var rolled_used := attempt < fusion_attempts and not fusion_recipe.is_empty()
		result["fusion_recipe"] = fusion_recipe if rolled_used else no_fusion
		result["fusion_fragment"] = ProceduralFragmentsV3.fusion_fragment_of(fusion_recipe if rolled_used else composed["atoms"])
		result["fusion_variant"] = str(plan.params.get("fusion_variant", ""))
		result["fusion_report"] = fusion_report
		result["fusion_present"] = not fusion_report.is_empty()
		result["selector_present"] = ProceduralSelectorCheck.has_selector(level)
		result["moves_below_band"] = int(metrics["intended_move_count"]) < int(req["min_optimal_moves"])
		result["layout_failures"] = layout_failures
		result["band_demoted"] = demoted
		if demoted:
			band_demoted_count += 1
		result["selector_fragment"] = str(composed["selectors"].get("fragment", ""))
		result["selector_info"] = composed["selectors"]
		result["selector_dropped"] = not selector_spec.is_empty() and not bool(result["selector_present"])
		if result["selector_dropped"]:
			selector_dropped_count += 1
		if greedy_solved and (policy == "prefer_reject" or policy == "reject"):
			if soft_pick.is_empty() and (version < GENERATOR_VERSION_SELECTOR or level_number <= 2200):
				soft_pick = result
			continue
		return result

	if not soft_pick.is_empty():
		soft_pick["greedy_accepted"] = true
		soft_pick["rejections"] = rejections
		return soft_pick

	fallback_count += 1
	push_warning("%s level %d (%d attempts) - V2 fallback used" % ["V5_GENERATION_FAILED" if version >= GENERATOR_VERSION_SELECTOR else "V3_GENERATION_FAILED", level_number, max_attempts])
	var fallback := ProceduralLevelGenerator.generate(level_number, 2)
	fallback["fallback_used"] = true
	fallback["v3_generation_failed"] = true
	fallback["generator_version"] = version
	fallback["rejections"] = rejections
	fallback["difficulty_band"] = req["band_name"]
	fallback["target_move_range"] = Vector2i(req["min_optimal_moves"], req["max_optimal_moves"])
	fallback["verified_optimal_moves"] = -1
	return fallback


static func _result(level_number: int, level: LevelData, hardened: Dictionary, board: ProceduralBoardV3, plan: ProceduralPlanV3, composed: Dictionary, metrics: Dictionary, verdict: Dictionary, visibility: Dictionary, attempt: int, rejections: Array, req: Dictionary, version: int) -> Dictionary:
	return {
		"level_data": level,
		"seed": ProceduralSeed.for_attempt(level_number, version, _ATTEMPT_SEED_OFFSET + attempt),
		"attempt": attempt,
		"generator_version": version,
		"template_id": plan.archetype,
		"board_size": Vector2i(board.w, board.h),
		"fallback_used": false,
		"v3_generation_failed": false,
		"rejections": rejections,
		"solution_orientations": board.solution,
		"intended_moves": level.optimal_moves,
		# Star preparation (Phase 2B does NOT finalise star thresholds): the
		# accepted intended move count, the band's target window, and a slot for
		# the dev-time solver's verified optimum (-1 = not solver-verified).
		"verified_optimal_moves": -1,
		"target_move_range": Vector2i(req["min_optimal_moves"], req["max_optimal_moves"]),
		"difficulty_band": req["band_name"],
		"plan": plan,
		"atoms": composed["atoms"],
		"predicted": composed["predicted"],
		"plain_turn_fraction": composed["plain_fraction"],
		"keep_correct": composed["keep"],
		"tile_count": board.tiles.size(),
		"hardening": hardened,
		"density_est": float(composed["tile_estimate"]) / float(board.w * board.h),
		"composer_ops": ProceduralComposerV3.last_ops,
		"tile_estimate": composed["tile_estimate"],
		"metrics": metrics,
		"verdict": verdict,
		"start_visibility": visibility,
		"tile_line": board.tile_line,
		"ascii": ProceduralBoardV3.ascii(level),
	}


## Band gates beyond ProceduralGeneratorV3._check(): ceilings the early game
## must respect ("not too hard": Levels <= 200 enforce the dependency/depth
## maxima; later bands treat them as soft targets because the metric also counts
## convergence/shared resources the plan model cannot pre-count).
static func _extra_gates(level_number: int, level: LevelData, board: ProceduralBoardV3, req: Dictionary, metrics: Dictionary, composed: Dictionary, reasons: Array) -> void:
	if level_number <= 200:
		var max_depth: int = req["max_dependency_depth"]
		if max_depth != ProceduralDifficultyContract.UNBOUNDED and metrics["dependency_depth"] > max_depth:
			reasons.append("dependency depth %d exceeds the band ceiling %d" % [metrics["dependency_depth"], max_depth])
		var max_deps: int = req["max_meaningful_dependencies"]
		if max_deps != ProceduralDifficultyContract.UNBOUNDED and metrics["meaningful_dependency_count"] - metrics["convergence_count"] > max_deps:
			reasons.append("dependencies %d (excluding convergence) exceed the band ceiling %d" % [metrics["meaningful_dependency_count"] - metrics["convergence_count"], max_deps])
	if float(composed["plain_fraction"]) > float(req["max_plain_move_fraction"]) + 0.0001:
		reasons.append("plain-move share %.2f above the band cap" % composed["plain_fraction"])


## Board shape for an attempt. Early bands cycle through the band's pool. From Level
## 1001 (dense plans, where fitting is what fails) only the largest shapes (within
## 10% of the biggest area) are used; 401-1000 order the pool largest-first and each
## retry moves toward the biggest shape.
static func _board_for(level_number: int, attempt: int, boards: Array) -> Vector2i:
	if level_number < 401:
		return boards[(level_number + attempt) % boards.size()]
	var by_area: Array = boards.duplicate()
	by_area.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x * a.y > b.x * b.y)
	if level_number >= 1001:
		var top: Array = []
		var best: int = by_area[0].x * by_area[0].y
		for b in by_area:
			# V5 (D110) uses only the largest shape (the reasoning floors are what fill the board; no smaller variant).
			if b.x * b.y * 10 >= best * (10 if level_number > 2000 else 9):
				top.append(b)
		return top[(level_number + attempt) % top.size()]
	return by_area[maxi(0, (level_number % by_area.size()) - attempt)]


## A pure mirror route (the first Foundation levels) has no mechanic for a move to
## depend on, so the meaningful/independent ratios cannot apply to it.
static func _req_for(req: Dictionary, composed: Dictionary) -> Dictionary:
	if not composed["atoms"].is_empty():
		return req
	var r := req.duplicate()
	r["min_meaningful_move_fraction"] = 0.0
	r["max_independent_move_fraction"] = 1.0
	return r


## Dev profiling: microseconds spent per phase (read by v3_progression_sample.tscn).
static var phase_us: Dictionary = {}


static func _tick(phase: String, t0: int) -> void:
	phase_us[phase] = int(phase_us.get(phase, 0)) + (Time.get_ticks_usec() - t0)
