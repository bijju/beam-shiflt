extends TestCase
## Loads every level script in the project and pushes it through the real simulator,
## validator, metrics and (bounded) solver. Covers levels/** and the dev tools.


func _all_level_scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		var n := f.trim_suffix(".remap")
		if n.ends_with(".gd"):
			out.append(dir + "/" + n)
	for d in DirAccess.get_directories_at(dir):
		_all_level_scripts(dir + "/" + d, out)


func test_every_level_script_loads_and_simulates() -> void:
	var paths: Array = []
	_all_level_scripts("res://levels", paths)
	ok(paths.size() > 200, "found level scripts")
	var loaded := 0
	for p in paths:
		if p.contains("_qa/"):
			continue  # QA set helpers, not LevelData; covered through the QA sessions
		var lv: LevelData = LevelManager.load_level_from_path(p)
		if lv == null:
			continue
		loaded += 1
		var orient := lv.get_initial_tile_orientations()
		var res := LaserSystem.simulate_until_stable(lv, orient)
		ok(res is Dictionary, p)
		lv.get_rotatable_tiles()
		for t in GridTypes.TileType.values():
			lv.get_tiles_of_type(t)
		var v := LevelValidator.validate(lv)
		ok(v.has("errors"), p)
		LevelMetrics.compute(lv)
	ok(loaded > 200, "loaded %d" % loaded)


func test_managers_level_tables() -> void:
	for i in range(1, LevelManager.get_level_count() + 1):
		ok(LevelManager.get_level(i) != null)
		LevelManager.calculate_stars(i, 3)
	ok(LevelManager.get_level(0) == null)
	ok(LevelManager.get_level(9999) == null)
	for i in range(1, LevelManager.get_campaign_level_count() + 1):
		ok(LevelManager.get_campaign_level(i) != null, "campaign %d" % i)
		LevelManager.calculate_campaign_stars(i, 5, i % 2 == 0)
		LevelManager.is_campaign_level_selectable(i)
	ok(LevelManager.get_campaign_level(0) == null)
	ok(LevelManager.get_campaign_level(100000) == null)
	for i in range(1, LevelManager.get_tutorial_level_count() + 1):
		ok(LevelManager.get_tutorial_level(i) != null, "tutorial %d" % i)
		LevelManager.is_tutorial_level_selectable(i)
	ok(LevelManager.get_tutorial_level(0) == null)
	LevelManager.get_continue_level_id()
	LevelManager.get_campaign_continue_level_id()
	LevelManager.should_show_fusion_tutorial_nudge()
	LevelManager.is_fusion_tutorial_selectable(LevelManager.FUSION_TUTORIAL_FIRST)
	LevelManager.is_selector_tutorial_selectable(LevelManager.SELECTOR_TUTORIAL_FIRST)


func test_solver_on_small_levels() -> void:
	for i in range(1, 16):
		var lv := LevelManager.get_level(i)
		var r := LevelSolver.analyze(lv, 4096)
		ok(r.has("status"), "level %d" % i)
		LevelMetrics.compute(lv, r)
