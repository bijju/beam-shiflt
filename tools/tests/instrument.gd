extends SceneTree
## Dev-only coverage instrumenter (tools/ is excluded from every export).
## Godot has no GDScript coverage, so this rewrites a COPY of the project:
## a `Cov.h(<id>)` call is inserted before every statement inside a function
## body of scripts/** and levels/**, and a cov_map.json (id -> file:line) is
## written beside project.godot. Never run against the real working tree -
## tools/tests/run_coverage.ps1 makes the copy first.
##   godot --headless --script res://tools/tests/instrument.gd -- <copy_dir>

const ROOTS := ["scripts", "levels"]

var _map: Array = []  # [file, line] per id
var _skipped: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: -- <copy_dir>")
		quit(2)
		return
	var base: String = args[0].replace("\\", "/")
	var files: Array = []
	for r in ROOTS:
		_collect(base + "/" + r, files)
	files.sort()
	for f in files:
		_instrument_file(f, base)
	var out := FileAccess.open(base + "/cov_map.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(_map))
	out.close()
	print("INSTRUMENTED files=%d statements=%d skipped=%s" % [files.size(), _map.size(), str(_skipped)])
	quit(0)


func _collect(dir: String, files: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			files.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_collect(dir + "/" + d, files)


func _indent(line: String) -> int:
	var n := 0
	while n < line.length() and line[n] == "\t":
		n += 1
	return n


## Returns [code_without_strings_and_comment, depth_after, in_multiline_after, first_colon_index_at_depth0]
## Strings are blanked so brackets/colons inside them are ignored.
func _scan(line: String, depth: int, in_ml: bool) -> Array:
	var code := ""
	var i := 0
	var n := line.length()
	var colon := -1
	while i < n:
		var c := line[i]
		if in_ml:
			if line.substr(i, 3) == '"""':
				in_ml = false
				code += "   "
				i += 3
			else:
				code += " "
				i += 1
			continue
		if c == "#":
			break
		if line.substr(i, 3) == '"""':
			in_ml = true
			code += "   "
			i += 3
			continue
		if c == '"' or c == "'":
			var q := c
			code += " "
			i += 1
			while i < n and line[i] != q:
				if line[i] == "\\":
					code += " "
					i += 1
				code += " "
				i += 1
			code += " "
			i += 1
			continue
		if c == "(" or c == "[" or c == "{":
			depth += 1
		elif c == ")" or c == "]" or c == "}":
			depth -= 1
		elif c == ":" and depth == 0 and colon < 0:
			colon = code.length()
		code += c
		i += 1
	return [code, depth, in_ml, colon]


func _instrument_file(path: String, base: String) -> void:
	var rel := path.substr(base.length() + 1)
	var text := FileAccess.get_file_as_string(path)
	var bom := text.begins_with("﻿")
	if bom:
		text = text.substr(1)
	var lines := text.split("\n")
	var out := PackedStringArray()
	var depth := 0
	var in_ml := false
	var cont := false
	var func_indent := -1
	var match_stack: Array = []
	var pending_header := false  # func signature spanning lines
	var pending_indent := 0
	for li in lines.size():
		var raw: String = lines[li]
		var line := raw.rstrip("\r")
		var eol := "\r" if raw.ends_with("\r") else ""
		var stripped := line.strip_edges()
		var start_depth := depth
		var start_ml := in_ml
		var scan := _scan(line, depth, in_ml)
		var code: String = scan[0]
		depth = scan[1]
		in_ml = scan[2]
		var was_cont := cont
		cont = line.rstrip(" \t").ends_with("\\") and not in_ml
		if start_ml or stripped == "" or stripped.begins_with("#"):
			out.append(raw)
			continue
		var ind := _indent(line)
		if line.begins_with(" "):
			_skipped.append(rel + ":" + str(li + 1))
			out.append(raw)
			continue
		var first := code.strip_edges().split(" ")[0].split("(")[0].split(":")[0]
		# Leaving a function body?
		if func_indent >= 0 and start_depth == 0 and not was_cont and not pending_header and ind <= func_indent:
			func_indent = -1
			match_stack.clear()
		# Continuation of a multi-line func signature.
		if pending_header:
			if depth == 0:
				pending_header = false
				func_indent = pending_indent
			out.append(raw)
			continue
		if start_depth > 0 or was_cont:
			out.append(raw)
			continue
		var is_func := first == "func" or (first == "static" and code.strip_edges().begins_with("static func"))
		if is_func:
			if depth > 0:
				pending_header = true
				pending_indent = ind
				out.append(raw)
				continue
			var colon: int = scan[3]
			if colon >= 0:
				var tail := code.substr(colon + 1).strip_edges()
				if tail != "":
					# One-line function: split header and body so the body can carry a hit.
					var head := line.substr(0, colon + 1)
					var body := line.substr(colon + 1).strip_edges()
					func_indent = ind
					out.append(head + eol)
					out.append("\t".repeat(ind + 1) + "Cov.h(%d)" % _next_id(rel, li + 1) + eol)
					out.append("\t".repeat(ind + 1) + body + eol)
					continue
			func_indent = ind
			out.append(raw)
			continue
		if func_indent < 0 or ind <= func_indent:
			out.append(raw)
			continue
		# Inside a function body, statement start at depth 0.
		while not match_stack.is_empty() and ind <= match_stack[-1]:
			match_stack.pop_back()
		var is_arm: bool = not match_stack.is_empty() and ind == match_stack[-1] + 1
		if first == "match":
			match_stack.append(ind)
		if first == "elif" or first == "else" or is_arm:
			out.append(raw)
			continue
		out.append("\t".repeat(ind) + "Cov.h(%d)" % _next_id(rel, li + 1) + eol)
		out.append(raw)
	var result := "\n".join(out)
	if bom:
		result = "﻿" + result
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(result)
	f.close()


func _next_id(rel: String, line: int) -> int:
	_map.append([rel, line])
	return _map.size() - 1
