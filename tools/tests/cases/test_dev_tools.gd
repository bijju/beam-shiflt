extends TestCase
## Dev-only audit/verification tools. Most are scenes that call get_tree().quit() when done,
## so each runs as a child Godot process with tiny arguments; its coverage counts come back
## through Cov's cov_dump file and are merged here.


func _run_tool(scene: String, args: Array, expect: String = "") -> String:
	var dump := ProjectSettings.globalize_path("user://cov_%d.json" % Time.get_ticks_usec())
	var argv := ["--headless", "--path", ProjectSettings.globalize_path("res://"), scene, "--", "cov_dump=" + dump]
	argv.append_array(args)
	var out := []
	var code := OS.execute(OS.get_executable_path(), argv, out, true)
	var text := "\n".join(out)
	var cov := runner.get_node_or_null("/root/Cov")
	if cov != null:
		cov.merge_file(dump)
	DirAccess.remove_absolute(dump)
	eq(code, 0, "%s exit code" % scene)
	ok(not text.contains("SCRIPT ERROR"), "%s script errors: %s" % [scene, text.substr(0, 400)])
	if expect != "":
		ok(text.contains(expect), "%s output has '%s'" % [scene, expect])
	return text


func test_difficulty_inspect() -> void:
	_run_tool("res://scripts/tools/difficulty_inspect.tscn", ["levels=1,300,1200", "version=2", "solver=1", "solver_states=512"], "elapsed_msec")
	_run_tool("res://scripts/tools/difficulty_inspect.tscn", ["levels=2", "solver=0"], "elapsed_msec")


func test_fusion_verify() -> void:
	_run_tool("res://scripts/tools/fusion_verify.tscn", ["window=401,460", "max=1", "states=1500"])
	_run_tool("res://scripts/tools/fusion_verify.tscn", ["levels=401"])


func test_selector_verifiers() -> void:
	_run_tool("res://scripts/tools/selector_verify.tscn", [])
	_run_tool("res://scripts/tools/selector_tutorial_verify.tscn", [])


func test_v3_tools() -> void:
	_run_tool("res://scripts/tools/v3_prototype_audit.tscn", ["solver=1", "solver_states=1024", "levels=1,2,3"])
	_run_tool("res://scripts/tools/v3_prototype_audit.tscn", ["solver=0"])
	_run_tool("res://scripts/tools/v3_progression_sample.tscn", ["levels=10,150,600", "solver_levels=10", "solver_states=1024"])
	_run_tool("res://scripts/tools/v3_progression_stats.tscn", ["range=300-306", "step=3", "solver_states=1024", "max_rotatables=10"])


func test_fusion_and_v5_tools() -> void:
	_run_tool("res://scripts/tools/fusion_progression_sample.tscn", ["levels=201,401", "version=4"])
	_run_tool("res://scripts/tools/v5_verify.tscn", ["levels=2001,2050", "states=2000", "secs=3", "budget=40000"])
	_run_tool("res://scripts/tools/v5_sample.tscn", ["levels=2001,2201", "budget=40000"])


func test_hint_solution_builder_helpers() -> void:
	var tool: Node = load("res://scripts/tools/hint_solution_builder.gd").new()
	var table := {"c1": [[0, 0, 0]]}
	tool._solve("c1", LevelManager.get_campaign_level(1), table)
	ok(table.has("c1"))
	tool._solve("cX", null, table)
	var unsolvable := LevelData.new()
	unsolvable.grid_width = 3
	unsolvable.grid_height = 1
	unsolvable.tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_blocker(Vector2i(1, 0)),
		TilePlacement.make_target(Vector2i(2, 0)),
	] as Array[TilePlacement]
	tool._solve("cU", unsolvable, table)
	ok(not table.has("cU"))
	tool.free()


func test_procedural_audit_static_api() -> void:
	var r := ProceduralAudit.generate_level_report(5, 2)
	ok(r is Dictionary)
	var a := ProceduralAudit.audit_range(1, 6, true, 2)
	ok(a is Dictionary)
	ok(ProceduralAudit.determinism_check(7, 2))
	ok(ProceduralAudit.mechanic_distribution_report(1, 20, 2) is Dictionary)
	ok(ProceduralAudit.difficulty_distribution_report(1, 20, 2) is Dictionary)


func test_live_harness_offline_actions() -> void:
	# Only the actions that never reach the network (no session exists in the isolated user dir).
	for action in ["status", "sign_out", "restore"]:
		_run_tool("res://scripts/tools/firebase_auth_test.tscn", ["action=" + action])
	_run_tool("res://scripts/tools/firebase_firestore_test.tscn", ["action=status"])
	for action in ["status", "summary", "payload_size", "signals"]:
		_run_tool("res://scripts/tools/cloud_save_test.tscn", ["action=" + action])


func test_tool_option_branches() -> void:
	var fps := "res://scripts/tools/fusion_progression_sample.tscn"
	_run_tool(fps, ["levels=401", "ascii=1", "quiet=1"])
	_run_tool(fps, ["levels=201", "freq=1", "stride=250", "bands=1,2"])
	_run_tool(fps, ["stress=2", "from=401", "list=1"])
	_run_tool(fps, ["levels=299", "version=3"])
	var v5s := "res://scripts/tools/v5_sample.tscn"
	_run_tool(v5s, ["from=2001", "count=2", "stride=60", "ascii=1", "wide=1", "budget=30000"])
	_run_tool(v5s, ["levels=2201", "hist=1", "histmax=2", "diag=1", "quiet=1", "budget=30000"])
	_run_tool(v5s, ["levels=2001", "nosel=1", "family=S-A", "selonly=1", "budget=30000"])
	var v3s := "res://scripts/tools/v3_progression_sample.tscn"
	_run_tool(v3s, ["levels=50,300", "solver_levels=50", "solver_states=512"])
	var v3st := "res://scripts/tools/v3_progression_stats.tscn"
	_run_tool(v3st, ["range=100-104", "step=2", "alpha=0.5", "solver_states=512", "max_rotatables=8"])
	_run_tool("res://scripts/tools/v5_verify.tscn", ["levels=2001", "states=500", "secs=2", "budget=20000", "version=5"])
	_run_tool("res://scripts/tools/fusion_verify.tscn", ["levels=401,450", "max=1", "states=800"])
