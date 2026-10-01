extends Node
## Autoload "Cov" - only ever registered in the instrumented COPY made by
## run_coverage.ps1 (never in the real project.godot). Counts statement hits.
## A child process (a dev tool scene started by a test) is launched with
## `cov_dump=<file>`: on exit it writes its counts there and the parent merges them.

var counts := PackedInt32Array()
var _dump_path := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("cov_dump="):
			_dump_path = a.substr(9)


func _exit_tree() -> void:
	if _dump_path == "":
		return
	var hits := {}
	for id in counts.size():
		if counts[id] > 0:
			hits[str(id)] = counts[id]
	var f := FileAccess.open(_dump_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(hits))
		f.close()


func merge_file(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	for key in parsed:
		var id := int(key)
		if id >= counts.size():
			counts.resize(id + 4096)
		counts[id] += int(parsed[key])
	return parsed.size()


func h(id: int) -> void:
	if id >= counts.size():
		counts.resize(id + 4096)
	counts[id] += 1


## Writes the report: totals, per-directory and per-file percentages, then the
## uncovered line numbers per file. Statement coverage over instrumented code.
func write_report(path: String) -> String:
	var map: Array = JSON.parse_string(FileAccess.get_file_as_string("res://cov_map.json"))
	var per_file := {}  # file -> [total, hit, uncovered lines]
	for id in map.size():
		var file: String = map[id][0]
		var e: Array = per_file.get(file, [0, 0, []])
		e[0] += 1
		if id < counts.size() and counts[id] > 0:
			e[1] += 1
		else:
			e[2].append(map[id][1])
		per_file[file] = e
	var groups := {}
	var all_t := 0
	var all_h := 0
	var rt_t := 0
	var rt_h := 0
	var files := per_file.keys()
	files.sort()
	var body := ""
	for f in files:
		var e: Array = per_file[f]
		var parts: PackedStringArray = f.split("/")
		var g := parts[0] + "/" + parts[1] if parts.size() > 2 else parts[0]
		var ge: Array = groups.get(g, [0, 0])
		ge[0] += e[0]
		ge[1] += e[1]
		groups[g] = ge
		all_t += e[0]
		all_h += e[1]
		if not f.begins_with("scripts/tools/"):
			rt_t += e[0]
			rt_h += e[1]
		body += "%6.1f%%  %4d/%-4d  %s\n" % [100.0 * e[1] / maxf(e[0], 1), e[1], e[0], f]
		if not e[2].is_empty():
			body += "          uncovered: %s\n" % _ranges(e[2])
	var head := "STATEMENT COVERAGE (instrumented scripts/** and levels/**)\n"
	head += "OVERALL            %6.2f%%  (%d/%d)\n" % [100.0 * all_h / maxf(all_t, 1), all_h, all_t]
	head += "EXCL scripts/tools %6.2f%%  (%d/%d)\n\n" % [100.0 * rt_h / maxf(rt_t, 1), rt_h, rt_t]
	var gk := groups.keys()
	gk.sort()
	for g in gk:
		var ge: Array = groups[g]
		head += "%6.1f%%  %5d/%-5d  %s\n" % [100.0 * ge[1] / maxf(ge[0], 1), ge[1], ge[0], g]
	var text := head + "\n" + body
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return head


func _ranges(lines: Array) -> String:
	var out: PackedStringArray = []
	var i := 0
	while i < lines.size():
		var j := i
		while j + 1 < lines.size() and lines[j + 1] - lines[j] <= 3:
			j += 1
		out.append(str(lines[i]) if i == j else "%d-%d" % [lines[i], lines[j]])
		i = j + 1
	return ", ".join(out)
