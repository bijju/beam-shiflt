extends TestCase
## Generator V6 (Stages C-E, D125): the contract (bands, introduction table, archetypes, challenge / relief /
## complexity budget, Level 4000), generation + independent validation of representative levels, the Phase
## gadget through the REAL LaserSystem, V6 routing / save isolation / final-level behaviour.

const _V6_TOOL := "res://scripts/tools/v6_sample.gd"


func _validate(n: int, r: Dictionary) -> Array:
	var tool: GDScript = load(_V6_TOOL)
	return tool.validate(n, r)


func _generate_and_validate(n: int) -> Dictionary:
	var r := ProceduralLevelGenerator.generate(n, ProceduralLevelGenerator.GENERATOR_VERSION_V6)
	var problems := _validate(n, r)
	ok(problems.is_empty(), "V6 L%d valid: %s" % [n, "; ".join(problems)])
	return r


# --- Contract ---------------------------------------------------------------------------

func test_bands_cover_1_to_4000_contiguously() -> void:
	var expected_from := 1
	var names := {}
	for i in range(ProceduralContractV6.band_count()):
		var b := ProceduralContractV6.band_row(i)
		eq(int(b["from"]), expected_from, "band %s starts where the previous ended" % b["name"])
		ok(int(b["to"]) >= int(b["from"]))
		ok(not names.has(b["name"]), "unique band name %s" % b["name"])
		names[b["name"]] = true
		expected_from = int(b["to"]) + 1
	eq(expected_from, ProceduralContractV6.MAX_LEVEL + 1, "bands end exactly at 4000")
	eq(ProceduralContractV6.MAX_LEVEL, 4000)
	eq(ProceduralLevelGenerator.MAX_LEVEL, 4000)
	ok(not ProceduralContractV6.is_valid_level(4001), "4001 is not a production level")
	ok(not ProceduralContractV6.is_valid_level(0))
	ok(ProceduralContractV6.is_valid_level(4000))
	for n in [1, 49, 50, 100, 400, 700, 701, 2000, 2001, 3000, 3001, 3999, 4000]:
		ok(not ProceduralContractV6.band_name(n).is_empty(), "band for %d" % n)


func test_medium_starts_at_level_50() -> void:
	eq(ProceduralContractV6.tier(1), "Foundation")
	eq(ProceduralContractV6.tier(49), "Foundation")
	eq(ProceduralContractV6.tier(50), "Medium")
	eq(ProceduralContractV6.tier(100), "Medium")
	eq(ProceduralContractV6.tier(101), "Hard")
	ok(not ProceduralContractV6.is_medium_or_harder(49))
	ok(ProceduralContractV6.is_medium_or_harder(50))
	eq(ProceduralContractV6.band_name(49), "Portal", "49 is still pre-Medium (portal transition)")
	eq(ProceduralContractV6.band_name(50), "Switch Gate", "Medium begins with switch / gate")
	ok(ProceduralContractV6.mechanic_available(50, "switch"))
	ok(not ProceduralContractV6.mechanic_available(49, "switch"))
	ok(not ProceduralContractV6.mechanic_available(49, "gate"))


func test_mechanic_introduction_table() -> void:
	var first := {"splitter": 21, "filter": 31, "portal": 41, "switch": 50, "hazard": 76, "prism": 101, "one_way": 151, "receiver": 201, "multi_emitter": 351, "fusion": 401, "phase": 701, "selector": 2001}
	for m in first:
		ok(ProceduralContractV6.mechanic_available(int(first[m]), m), "%s available at %d" % [m, first[m]])
		ok(not ProceduralContractV6.mechanic_available(int(first[m]) - 1, m), "%s NOT available at %d" % [m, int(first[m]) - 1])
	# Atoms follow the mechanics: no Phase atom before 701, no prism atom before 101, ...
	ok(not ProceduralContractV6.allowed_atoms(700).has("PH"))
	ok(ProceduralContractV6.allowed_atoms(701).has("PH"))
	ok(not ProceduralContractV6.allowed_atoms(100).has("PR"))
	ok(ProceduralContractV6.allowed_atoms(101).has("PR"))
	ok(not ProceduralContractV6.allowed_atoms(40).has("P"))
	ok(ProceduralContractV6.allowed_atoms(41).has("P"))
	ok(not ProceduralContractV6.allowed_atoms(49).has("G"))
	ok(ProceduralContractV6.allowed_atoms(50).has("G"))
	ok(not ProceduralContractV6.allowed_atoms(350).has("SH"), "shared pieces need the multi-emitter band")
	ok(ProceduralContractV6.allowed_atoms(351).has("SH"))
	# Early levels never receive a late mechanic.
	for n in [1, 5, 10, 20, 30, 40, 49]:
		for a in ProceduralContractV6.allowed_atoms(n):
			ok(a in ["TM", "SB", "F", "F2", "P"], "L%d offers only early atoms (%s)" % [n, a])
	# Phase begins at 701, Selector at 2001, Fusion at 401 in the policies.
	eq(ProceduralContractV6.phase_policy(700)["probability"], 0.0)
	ok(float(ProceduralContractV6.phase_policy(701)["probability"]) > 0.0)
	ok(not bool(ProceduralContractV6.selector_policy(2000)["has_selector"]))
	ok(bool(ProceduralContractV6.selector_policy(2001)["has_selector"]), "Level 2001 always introduces the Selector")
	eq(ProceduralContractV6.fusion_policy(400)["probability"], 0.0)
	ok(float(ProceduralContractV6.fusion_policy(401)["probability"]) > 0.0)


func test_isolate_then_combine_introduction_stages() -> void:
	# The first levels of a band that introduces a mechanic are stage 0 (isolated), whatever the modifiers say.
	for n in [21, 31, 41, 50, 101, 151, 201, 276, 351, 401, 701, 2001]:
		eq(ProceduralContractV6.core_stage(n), 0, "L%d is an introduction level" % n)
		ok(ProceduralContractV6.is_intro_window(n))
	# Later in a band the stage rises (+1 familiar, then +2).
	ok(ProceduralContractV6.core_stage(74) >= 1, "late in the Switch Gate band the cores combine systems")
	var iso: Array = ProceduralContractV6.cores(50)
	for core in iso:
		ok(core.size() <= 1, "L50 core isolates the mechanic: %s" % [core])


func test_phase_selector_fusion_combination_rules() -> void:
	var phase_levels := 0
	var selector_levels := 0
	var both := 0
	for n in range(1, 4001, 3):
		var ctx := ProceduralProgressionV3._v6_context(n, 6)
		var phase: bool = ctx["phase_roll"]
		var sel: bool = not (ctx["selector_spec"] as Dictionary).is_empty()
		var fus: bool = not (ctx["fusion_recipe"] as Array).is_empty()
		if phase:
			phase_levels += 1
			ok(n >= 701, "Phase before 701 at L%d" % n)
		if sel:
			selector_levels += 1
			ok(n >= 2001, "Selector before 2001 at L%d" % n)
		if fus:
			ok(n >= 401, "Fusion before 401 at L%d" % n)
		if phase and sel:
			both += 1
			ok(n >= 2401, "Selector + Phase before 2401 at L%d" % n)
		if sel and fus:
			ok(n >= 2601, "Selector + Fusion before 2601 at L%d" % n)
		if sel and fus and phase:
			ok(n >= 2801, "Selector + Phase + Fusion before 2801 at L%d" % n)
	ok(phase_levels > 150, "Phase is common in its bands (%d)" % phase_levels)
	ok(selector_levels > 150, "Selector is common in its bands (%d)" % selector_levels)
	ok(both > 20, "Selector + Phase combine in the intended later bands (%d)" % both)
	# Level 2001: exactly one simple Selector, no Phase / Fusion beside it.
	var c2001 := ProceduralProgressionV3._v6_context(2001, 6)
	eq((c2001["selector_spec"] as Dictionary)["count"], 1)
	ok(not bool(c2001["phase_roll"]))


func test_archetypes_are_deterministic_and_varied() -> void:
	var seen := {}
	for n in range(1, 4001):
		var a := ProceduralContractV6.archetype(n)
		eq(a, ProceduralContractV6.archetype(n), "same level + V6 -> same archetype")
		seen[a] = int(seen.get(a, 0)) + 1
	for a in ProceduralContractV6.ALL_ARCHETYPES:
		ok(seen.has(a), "archetype %s occurs" % a)
	for n in range(1, 31):
		ok(ProceduralContractV6.archetype(n) != ProceduralContractV6.ARCH_COLOR, "no COLOR archetype before filters (L%d)" % n)
	for n in range(1, 701):
		ok(ProceduralContractV6.archetype(n) != ProceduralContractV6.ARCH_PHASE, "no PHASE archetype before 701 (L%d)" % n)
	for n in range(1, 50):
		ok(ProceduralContractV6.archetype(n) != ProceduralContractV6.ARCH_DEPENDENCY, "no DEPENDENCY archetype before switch / gate (L%d)" % n)
	eq(ProceduralContractV6.archetype(4000), ProceduralContractV6.ARCH_GRAND)


func test_challenge_milestone_and_relief_modifiers() -> void:
	# Modifier flags.
	for n in [10, 20, 100, 500, 1000, 2000, 3000, 3500]:
		ok(ProceduralContractV6.is_challenge(n) or ProceduralContractV6.is_milestone(n), "L%d is a challenge/milestone" % n)
	for n in [50, 100, 500, 1000, 2000, 3000, 3500]:
		ok(ProceduralContractV6.is_milestone(n), "L%d is a milestone (every 50th)" % n)
	for n in [10, 20, 30, 110, 1010, 3010]:
		ok(ProceduralContractV6.is_challenge(n) and not ProceduralContractV6.is_milestone(n), "L%d is a modest challenge" % n)
	ok(bool(ProceduralContractV6.profile(4000)["master"]) and not ProceduralContractV6.is_challenge(4000), "4000 is its own master profile")
	# The modifiers change the intended complexity target, not just a flag: a milestone raises the move floor by 2 and the
	# budget by 2 inside its band (outside an introduction window); a challenge raises the floor by 1 and the budget by 1.
	for n in [100, 500, 1000, 2000, 3000, 3500]:
		var band := ProceduralContractV6.band_row(0)
		for i in range(ProceduralContractV6.band_count()):
			var row := ProceduralContractV6.band_row(i)
			if n >= int(row["from"]) and n <= int(row["to"]):
				band = row
		var w := ProceduralContractV6.move_window(n)
		eq(w.x, int(band["moves"][0]) + 2, "milestone L%d raises the move floor by 2" % n)
		eq(ProceduralContractV6.budget(n), int(band["budget"]) + 2 - (1 if ProceduralContractV6.is_relief(n) and int(band["budget"]) + 2 >= 8 else 0), "milestone L%d budget" % n)
		var req := ProceduralContractV6.requirements(n)
		eq(req["min_optimal_moves"], w.x, "requirements carry the modified floor")
		ok(int(ProceduralContractV6.profile(n)["target_moves"]) >= w.x and int(ProceduralContractV6.profile(n)["target_moves"]) <= w.y)
	for n in [110, 1010, 2210, 3010]:
		var row2 := ProceduralContractV6.band_row(0)
		for i in range(ProceduralContractV6.band_count()):
			var r2 := ProceduralContractV6.band_row(i)
			if n >= int(r2["from"]) and n <= int(r2["to"]):
				row2 = r2
		eq(ProceduralContractV6.move_window(n).x, int(row2["moves"][0]) + 1, "challenge L%d raises the floor by 1" % n)
	# Relief: never on a challenge/milestone level, never in an introduction window or the first levels of a band, share ~1 in 6.
	var relief := 0
	for n in range(1, 4001):
		if ProceduralContractV6.is_relief(n):
			relief += 1
			ok(n % 10 != 0, "relief never on a challenge/milestone (L%d)" % n)
			ok(not ProceduralContractV6.is_intro_window(n), "relief never inside an introduction window (L%d)" % n)
			ok(n - ProceduralContractV6.band_start(n) >= 3)
	ok(relief > 400 and relief < 900, "relief share is around one in six (%d / 4000)" % relief)
	# A relief level is smaller / cleaner: its move window ceiling is lower than the band's.
	for n in range(100, 400):
		if ProceduralContractV6.is_relief(n):
			var base := ProceduralContractV6.requirements(n)
			ok(int(base["max_optimal_moves"]) <= int(ProceduralContractV6.band_row(0)["moves"][1]) + 40)
			break


func test_complexity_budget_is_obeyed() -> void:
	# For a spread of levels the atom recipe the planner picks never exceeds the level's budget (points of distinct mechanic kinds).
	for n in [3, 25, 45, 60, 90, 120, 180, 230, 300, 380, 450, 650, 720, 900, 1100, 1500, 1900, 2100, 2500, 2900, 3300, 3700, 3999, 4000]:
		var ctx := ProceduralProgressionV3._v6_context(n, 6)
		var req: Dictionary = ctx["req"]
		for seed_i in range(4):
			var rng := ProceduralSeed.rng_for_attempt(n, 6, 100 + seed_i)
			var atoms := ProceduralFragmentsV3.choose_atoms(n, req, rng, ctx["fusion_recipe"], ctx["selector_spec"])
			if atoms.is_empty():
				continue
			var kinds: Array = ProceduralFragmentsV3.predict(atoms, int((ctx["selector_spec"] as Dictionary).get("count", 0)))["kind_set"]
			ok(ProceduralContractV6.points_of_kinds(kinds) <= int(req["v6_budget"]), "L%d atoms %s (%d pts) fit the budget %d" % [n, atoms, ProceduralContractV6.points_of_kinds(kinds), int(req["v6_budget"])])
			for a in atoms:
				ok(a in ["TM", "OH", "F2"] or ProceduralContractV6.atom_allowed(a, n) or a in ProceduralFragmentsV3.FUSION_ATOMS, "L%d atom %s is introduced by then" % [n, a])


func test_phase_atom_points() -> void:
	# The Phase atom is never offered before 701 and the gadget keeps its own splitter (4 points).
	eq(ProceduralContractV6.points_of_kinds(ProceduralFragmentsV3.predict(["PH"])["kind_set"]), 4)
	ok(not ProceduralContractV6.atom_allowed("PH", 700))
	ok(ProceduralContractV6.atom_allowed("PH", 701))


# --- Generation (independent validation + determinism) ----------------------------------------

func test_v6_generation_foundation_to_medium() -> void:
	for n in [1, 2, 10, 20, 30, 40, 49, 50, 51, 75, 100]:
		var r := _generate_and_validate(n)
		eq(r["generator_version"], 6)
		ok(not r["fallback_used"], "no fallback at L%d" % n)
		var again := ProceduralLevelGenerator.generate(n, 6)
		eq(GeneratorFingerprint.fingerprint(r, 6), GeneratorFingerprint.fingerprint(again, 6), "deterministic L%d" % n)
	var l1 := ProceduralLevelGenerator.generate(1, 6)
	ok(int(l1["intended_moves"]) >= 3, "Level 1 is not a one-mirror level")
	ok((l1["level_data"] as LevelData).grid_width <= GridManager.MAX_COLUMNS)


func test_v6_generation_hard_bands() -> void:
	for n in [150, 200, 201, 300, 400, 500, 600, 700]:
		var r := _generate_and_validate(n)
		ok(not r["fallback_used"], "no fallback at L%d" % n)


func test_v6_phase_levels_use_the_real_simulation() -> void:
	for n in [701, 705, 720, 800, 900]:
		var r := _generate_and_validate(n)
		var level: LevelData = r["level_data"]
		var phase_tiles := 0
		for t in level.tiles:
			if t.tile_type == GridTypes.TileType.PHASE_SHIFTER:
				phase_tiles += 1
		if n == 701 or n == 705 or n == 720:
			ok(phase_tiles >= 1, "Phase introduction L%d carries a Phase Shifter" % n)
		if phase_tiles == 0:
			continue
		# The known solution solves; the Phase Shifter is load-bearing (removing it loses a target); the wrong Phase B
		# orientation does not solve.
		var solved: Dictionary = level.get_initial_tile_orientations()
		for pos in r["solution_orientations"]:
			solved[pos] = r["solution_orientations"][pos]
		ok(LaserSystem.simulate_until_stable(level, solved)["solved"], "L%d solution solves" % n)
		var m := ProceduralComplexity.analyze(level, r["solution_orientations"])
		ok(int(m["phase_dependency_count"]) >= 1, "L%d: the Phase Shifter is load-bearing" % n)
		var flipped := solved.duplicate()
		for t in level.tiles:
			if t.tile_type == GridTypes.TileType.PHASE_SHIFTER:
				flipped[t.position] = ProceduralBoardV3.opposite(solved[t.position])
		ok(not LaserSystem.simulate_until_stable(level, flipped)["solved"], "L%d: flipping a Phase Shifter breaks the solution" % n)


func test_v6_expert_phase_bands() -> void:
	for n in [1000, 1200, 1400, 1600, 1800, 1999, 2000]:
		var r := _generate_and_validate(n)
		ok(not r["fallback_used"], "no fallback at L%d" % n)


func test_v6_selector_era() -> void:
	for n in [2001, 2200, 2400, 2800]:
		var r := _generate_and_validate(n)
		ok(not r["fallback_used"], "no fallback at L%d" % n)
	var r2001 := ProceduralLevelGenerator.generate(2001, 6)
	ok(r2001["selector_present"], "Level 2001 introduces the Splitter Selector")


func test_v6_grandmaster_and_master() -> void:
	for n in [3000, 3001, 3400, 3999]:
		var r := _generate_and_validate(n)
		ok(not r["fallback_used"], "no fallback at L%d" % n)


func test_level_4000_master_puzzle() -> void:
	var r := _generate_and_validate(4000)
	ok(not r["fallback_used"])
	ok(r["selector_present"], "the Master Puzzle carries Splitter Selectors")
	ok(int(r["phase_count"]) >= 1, "the Master Puzzle carries a Phase Shifter")
	eq(ProceduralContractV6.archetype(4000), ProceduralContractV6.ARCH_GRAND)
	ok(int(r["intended_moves"]) >= 20, "a long-form final puzzle")
	var again := ProceduralLevelGenerator.generate(4000, 6)
	eq(GeneratorFingerprint.fingerprint(r, 6), GeneratorFingerprint.fingerprint(again, 6), "Level 4000 regenerates identically")
	# Authoritative optimal for scoring falls back to the intended moves (never claimed as proven optimal).
	eq(int(r["verified_optimal_moves"]), -1)
	var par := StarScoring.authoritative_optimal(r["level_data"], r)
	eq(par, int(r["intended_moves"]), "PAR uses the intended solution length when no solver proof exists")


func test_v6_routing_and_old_generators_unchanged() -> void:
	eq(LevelManager.procedural_generator_version_for_new_play(1), 6)
	eq(LevelManager.procedural_generator_version_for_new_play(2001), 6)
	eq(LevelManager.procedural_generator_version_for_new_play(4000), 6)
	eq(LevelManager.get_procedural_level_count(), 4000)
	# A saved V1-V5 version still means exactly that generator (dispatch is by version, never by level).
	for v in [1, 2, 3, 4, 5]:
		eq(ProceduralLevelGenerator.generate(120, v)["generator_version"], v, "a saved V%d puzzle regenerates under V%d" % [v, v])
	ok(ProceduralLevelGenerator.generate(40, 3)["generator_version"] == 3)
	ok(ProceduralLevelGenerator.generate(40, 4)["generator_version"] == 4)
	# V6 at the same level is a different puzzle from V5 at that level (identities never collide).
	ne(GeneratorFingerprint.fingerprint(ProceduralLevelGenerator.generate(40, 4), 4), GeneratorFingerprint.fingerprint(ProceduralLevelGenerator.generate(40, 6), 6))


# --- Saves ------------------------------------------------------------------------------------

func test_best_records_do_not_collide_between_v5_and_v6() -> void:
	SaveManager.record_procedural_best_moves(750, 5, 14)
	SaveManager.record_procedural_best_moves(750, 6, 9)
	SaveManager.record_procedural_stars(750, 5, 2)
	SaveManager.record_procedural_stars(750, 6, 3)
	eq(SaveManager.get_procedural_best_moves(750, 5), 14)
	eq(SaveManager.get_procedural_best_moves(750, 6), 9)
	eq(SaveManager.get_procedural_best_stars(750, 5), 2)
	eq(SaveManager.get_procedural_best_stars(750, 6), 3)
	SaveManager.record_procedural_best_moves(750, 6, 12)
	eq(SaveManager.get_procedural_best_moves(750, 6), 9, "a worse V6 replay never raises the best")
	eq(SaveManager.get_procedural_best_moves(750, 5), 14)
	# Persisted and reloaded under the same identities.
	ok(SaveManager.save_game())
	SaveManager.load_game()
	eq(SaveManager.get_procedural_best_moves(750, 5), 14)
	eq(SaveManager.get_procedural_best_moves(750, 6), 9)


func test_progression_never_advances_past_4000() -> void:
	SaveManager.procedural_current_level = 3000
	SaveManager.record_procedural_level_result(3000)
	eq(SaveManager.procedural_current_level, 3001, "3001 persists as the next level")
	ok(SaveManager.save_game())
	SaveManager.load_game()
	eq(SaveManager.procedural_current_level, 3001)
	SaveManager.procedural_current_level = 3999
	SaveManager.record_procedural_level_result(3999)
	eq(SaveManager.procedural_current_level, 4000)
	SaveManager.record_procedural_level_result(4000)
	eq(SaveManager.procedural_current_level, 4000, "completing Level 4000 does not point at a Level 4001")
	ok(SaveManager.save_game())
	SaveManager.load_game()
	eq(SaveManager.procedural_current_level, 4000, "Level 4000 persists")
	SaveManager.record_procedural_level_result(4000)
	eq(SaveManager.procedural_current_level, 4000)


func test_new_game_semantics_with_v6() -> void:
	SaveManager.procedural_current_level = 3001
	SaveManager.record_procedural_stars(3000, 6, 3)
	SaveManager.record_procedural_best_moves(3000, 6, 20)
	SaveManager.tutorial_completed_levels = {"1": true, "35": true, "39": true}
	SaveManager.tutorial_highest_unlocked_level = 39
	ok(SaveManager.has_meaningful_main_progress())
	ok(SaveManager.reset_main_progress_for_new_game())
	eq(SaveManager.procedural_current_level, 1, "NEW GAME restarts the main run")
	eq(SaveManager.procedural_resume_generator_version, 0)
	eq(SaveManager.get_procedural_best_stars(3000, 6), 0, "main-run records reset (existing semantics)")
	ok(SaveManager.is_tutorial_level_completed(35) and SaveManager.is_tutorial_level_completed(39), "Phase tutorial history survives NEW GAME")
	ok(SaveManager.is_tutorial_level_completed(1), "tutorial history survives NEW GAME")
	eq(LevelManager.procedural_generator_version_for_new_play(1), 6, "the first level after NEW GAME is a V6 puzzle")


func test_tutorial_unlock_alignment() -> void:
	eq(LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL, 380)
	eq(LevelManager.PHASE_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL, 680)
	eq(LevelManager.SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL, 1980)
	ok(LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL < ProceduralContractV6.FUSION_FIRST_LEVEL)
	ok(LevelManager.PHASE_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL < ProceduralContractV6.PHASE_FIRST_LEVEL)
	ok(LevelManager.SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL < ProceduralContractV6.SELECTOR_FIRST_LEVEL)
	ok(ProceduralContractV6.FUSION_FIRST_LEVEL - LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL <= 30, "Fusion pack opens shortly before Fusion")
	ok(ProceduralContractV6.SELECTOR_FIRST_LEVEL - LevelManager.SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL <= 30, "Selector pack opens shortly before Selector")
	# Never a hard gate: no level is locked behind a tutorial (levels are generated on demand).
	SaveManager.procedural_current_level = 200
	ok(not LevelManager.is_fusion_tutorial_selectable(LevelManager.FUSION_TUTORIAL_FIRST) or LevelManager.UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING)
	SaveManager.procedural_current_level = 380
	ok(LevelManager.is_fusion_tutorial_selectable(LevelManager.FUSION_TUTORIAL_FIRST))
	# A save that EARNED a pack under the old thresholds (150 / 1900) keeps it after loading.
	SaveManager.procedural_current_level = 160
	SaveManager.tutorial_highest_unlocked_level = 1
	ok(SaveManager.save_game())
	SaveManager.load_game()
	ok(SaveManager.tutorial_highest_unlocked_level >= LevelManager.FUSION_TUTORIAL_FIRST, "earned Fusion unlock is never revoked")
	# Completed tutorial history stays valid.
	SaveManager.tutorial_completed_levels = {"21": true, "34": true, "35": true}
	ok(SaveManager.save_game())
	SaveManager.load_game()
	ok(SaveManager.is_tutorial_level_completed(21) and SaveManager.is_tutorial_level_completed(34) and SaveManager.is_tutorial_level_completed(35))


# --- Real game session: a V6 puzzle, resume isolation, final level ----------------------------------

func _wait_popup(game: Node) -> void:
	Engine.time_scale = 30.0
	var t0 := Time.get_ticks_msec()
	while not game._complete_popup.visible and Time.get_ticks_msec() - t0 < 8000:
		await frames(1)
	Engine.time_scale = 1.0


func test_new_play_is_v6_and_saved_runs_keep_their_version() -> void:
	var online := InternetManager.is_online
	InternetManager.is_online = true
	# A saved V5 run resumes as V5.
	var r5 := ProceduralLevelGenerator.generate(2100, 5)
	SaveManager.start_procedural_resume(2100, r5["seed"], 5)
	GameManager.start_procedural_level(2100)
	await frames(4)
	var game := current_scene()
	eq(game._procedural_generator_version, 5, "a saved V5 puzzle keeps regenerating as V5")
	eq((game._grid.level_data as LevelData).tiles.size(), (r5["level_data"] as LevelData).tiles.size())
	reset_scene()
	# Without a saved run the same level is a V6 puzzle.
	SaveManager.procedural_resume_level_number = 0
	SaveManager.procedural_resume_generator_version = 0
	GameManager.start_procedural_level(2100)
	await frames(4)
	var game2 := current_scene()
	eq(game2._procedural_generator_version, 6, "new play is V6")
	reset_scene()
	InternetManager.is_online = online


func test_level_4000_final_completion_flow() -> void:
	var online := InternetManager.is_online
	InternetManager.is_online = true
	SaveManager.procedural_current_level = 4000
	GameManager.start_procedural_level(4000)
	await frames(4)
	var game := current_scene()
	var grid: GridManager = game.get_node("%PuzzleGrid")
	eq(game._procedural_generator_version, 6)
	eq(game._level_label.text.begins_with("LEVEL 4000"), true, "HUD shows LEVEL 4000")
	var r := LevelManager.get_procedural_generation_result(4000, 6)
	ok(game._hint.has_hint_source(), "Hint works on Level 4000 (known solution)")
	var hint_cell: Variant = game._hint.get_hint_candidate()
	ok(hint_cell != null and r["solution_orientations"].has(hint_cell), "the hint points at a tile of the known solution")
	solve_by_taps(grid, r["solution_orientations"])
	ok(grid.is_solved, "Level 4000 is solved by its known solution")
	await _wait_popup(game)
	ok(game._complete_popup.visible)
	ok(not game._complete_popup._next_button.visible, "no NEXT LEVEL after the final level")
	eq(game._complete_popup._from_label.text, "LEVEL 4000 COMPLETE")
	ok(not game._complete_popup._to_label.visible, "no Level 4001 progression row")
	ok(SaveManager.get_procedural_best_stars(4000, 6) >= 1, "completion saved under the V6 identity")
	ok(SaveManager.get_procedural_best_moves(4000, 6) >= 1, "BEST moves saved under the V6 identity")
	eq(SaveManager.get_procedural_best_stars(4000, 5), 0, "nothing under the V5 identity")
	eq(SaveManager.procedural_current_level, 4000, "progression never advances to 4001")
	eq(SaveManager.procedural_resume_level_number, 0, "the final level leaves no solved board to resume")
	reset_scene()
	# PLAY / CONTINUE clamp: a stray pointer past the end never loads Level 4001.
	SaveManager.procedural_current_level = 9999
	GameManager.play_game()
	await frames(4)
	eq(GameManager.current_procedural_level, 4000)
	ok(not (current_scene().get_node("%PuzzleGrid") as GridManager).is_solved, "PLAY after the end starts Level 4000 fresh, never as an instantly solved board")
	reset_scene()
	InternetManager.is_online = online
