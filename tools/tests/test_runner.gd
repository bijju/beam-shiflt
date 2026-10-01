extends Node
## Test runner scene script (needs the real autoloads, so it is a scene, not a
## --script). Run:  godot --headless --path . res://tools/tests/test_runner.tscn
## Optional user args:  -- filter=<substr> report=<path>
## When the "Cov" autoload exists (instrumented copy) a coverage report is written.

const CASES_DIR := "res://tools/tests/cases"
const TEST_TIMEOUT_MS := 150000


func _ready() -> void:
	# Tests drive GameManager.go_to_*/start_*, which call change_scene_to_file. Park a
	# placeholder as the current scene so only IT is freed, never this runner.
	var placeholder := Node.new()
	placeholder.name = "Placeholder"
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	InternetManager._periodic_timer.stop()  # no real network checks mid-test
	InternetManager._http_request.cancel_request()
	InternetManager.check_in_progress = false
	InternetManager.is_online = true
	var filter := ""
	var report := ""
	var merge := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("filter="):
			filter = a.substr(7)
		elif a.begins_with("merge="):
			merge = a.substr(6)
		elif a.begins_with("report="):
			report = a.substr(7)
	var files := DirAccess.get_files_at(CASES_DIR)
	files.sort()
	var total := 0
	var failed := 0
	var asserts := 0
	for f in files:
		if not f.begins_with("test_") or not (f.ends_with(".gd") or f.ends_with(".gd.remap")):
			continue
		if filter != "" and not _matches(f, filter):
			continue
		var script: GDScript = load(CASES_DIR + "/" + f.trim_suffix(".remap"))
		if script == null or not script.can_instantiate():
			print("FAIL (load) ", f)
			failed += 1
			continue
		var probe: Object = script.new()
		for m in probe.get_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var tc: TestCase = script.new()
			tc.runner = self
			total += 1
			var t0 := Time.get_ticks_msec()
			SaveManager._apply_data(SaveManager._default_data())  # every test starts from a fresh profile
			var state := {"done": false}
			_run_one(tc, name, state)
			while not state["done"] and Time.get_ticks_msec() - t0 < TEST_TIMEOUT_MS:
				await get_tree().process_frame
			if not state["done"]:
				tc.failures.append("aborted or timed out (a script error after an await never resumes the test)")
			asserts += tc.assertions
			var dt := Time.get_ticks_msec() - t0
			if tc.failures.is_empty():
				if dt > 3000:
					print("slow %s::%s %d ms" % [f, name, dt])
			else:
				failed += 1
				print("FAIL %s::%s" % [f, name])
				for msg in tc.failures:
					print("    ", msg)
	print("TESTS total=%d failed=%d assertions=%d" % [total, failed, asserts])
	var cov := get_node_or_null("/root/Cov")
	if cov != null:
		if merge != "":
			cov.merge_file(merge)
		var head: String = cov.write_report(report if report != "" else "user://coverage_report.txt")
		print(head)
	get_tree().quit(1 if failed > 0 else 0)


## One test, bracketed by before/after. A GDScript error after an `await` kills the coroutine
## silently, so `state["done"]` never flips and the caller's watchdog reports it.
func _run_one(tc: TestCase, name: String, state: Dictionary) -> void:
	await tc.before_each()
	await tc.call(name)
	await tc.after_each()
	state["done"] = true


## `filter=a,b` runs every test file whose name contains any of the comma-separated parts.
func _matches(file: String, filter: String) -> bool:
	for part in filter.split(","):
		if part != "" and file.contains(part):
			return true
	return false
