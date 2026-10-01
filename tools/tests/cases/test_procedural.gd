extends TestCase
## Drives the real procedural generator across every version and band. Heavy paths
## are sampled (strided) - see tools/tests/README.md for the budget rationale.


func _check_result(r: Dictionary, label: String) -> void:
	ok(r.has("level_data"), label)
	var lv: LevelData = r["level_data"]
	ok(lv != null, label)
	ok(lv.grid_width <= GridManager.MAX_COLUMNS or r.get("fallback_used", false), label + " width")
	var sol: Dictionary = r.get("solution_orientations", {})
	var o := lv.get_initial_tile_orientations()
	for k in sol:
		o[k] = sol[k]
	var res := LaserSystem.simulate_until_stable(lv, o)
	ok(res is Dictionary, label)


func test_v1_v2_generation() -> void:
	for v in [1, 2]:
		for n in [1, 2, 3, 5, 8, 13, 25, 60, 120, 199, 260, 400, 640, 900, 1300, 1700, 2000]:
			var r := ProceduralLevelGenerator.generate(n, v)
			_check_result(r, "v%d L%d" % [v, n])
			var r2 := ProceduralLevelGenerator.generate(n, v)
			eq(r["seed"], r2["seed"], "deterministic")
			eq(r["level_data"].tiles.size(), r2["level_data"].tiles.size(), "deterministic tiles")


func test_v3_prototypes() -> void:
	for n in range(1, 13):
		var r := ProceduralGeneratorV3.generate(n)
		ok(r.has("level_data"), "proto %d" % n)
	ProceduralGeneratorV3.phase2a_requirements()


func test_v3_v4_progression() -> void:
	for v in [3, 4]:
		for n in [1, 40, 150, 201, 260, 340, 480, 700, 900, 1100, 1500, 1900]:
			_check_result(ProceduralLevelGenerator.generate(n, v), "v%d L%d" % [v, n])


func test_v5_generation() -> void:
	for n in ProceduralV5QaSet.LEVELS:
		_check_result(ProceduralLevelGenerator.generate(n, 5), "v5 L%d" % n)
	for i in range(1, ProceduralV5QaSet.COUNT + 1):
		ProceduralV5QaSet.get_puzzle(i)
	eq(ProceduralV5QaSet.level_for(0), 2001)
	eq(ProceduralV5QaSet.level_for(99), 3000)


func test_seed_and_contract() -> void:
	ne(ProceduralSeed.for_attempt(1, 2, 0), ProceduralSeed.for_attempt(2, 2, 0))
	ok(ProceduralSeed.rng_for_attempt(5, 3, 1) != null)
	for n in [1, 10, 50, 150, 200, 201, 500, 1000, 2000, 2001, 2500, 3000, 4000]:
		ProceduralDifficultyContract.get_difficulty_requirements(n)
		ProceduralDifficultyContract.fusion_policy(n)
		ProceduralDifficultyContract.selector_policy(n)
		ProceduralDifficultyProfile.for_level(n, 1)
		ProceduralDifficultyProfile.for_level(n, 2)


## Wider strided sweeps so rarely drawn templates, fragments and rejection branches run.
func test_v1_v2_wide_sweep() -> void:
	for v in [1, 2]:
		for n in range(3, 2001, 23):
			_check_result(ProceduralLevelGenerator.generate(n, v), "v%d L%d" % [v, n])


func test_v3_v4_wide_sweep() -> void:
	for v in [3, 4]:
		for n in range(7, 2001, 37):
			_check_result(ProceduralLevelGenerator.generate(n, v), "v%d L%d" % [v, n])


func test_v5_wide_sweep() -> void:
	for n in [2003, 2077, 2123, 2178, 2233, 2289, 2344, 2402, 2467, 2533, 2588, 2644, 2702, 2755, 2811, 2866, 2923, 2977]:
		_check_result(ProceduralLevelGenerator.generate(n, 5), "v5 L%d" % n)
