class_name GeneratorFingerprint
extends Node
## Dev-only generator fingerprint tool (Stage C, V6). Never exported (scripts/tools/**).
## Hashes the MEANINGFUL puzzle data of generated levels so any accidental change to a frozen generator
## (V1-V5) is caught: dimensions, every tile (type, position, direction, orientation, rotatable, colour,
## required, pair/gate/link ids, initial gate state), the generator's own intended solution (position ->
## orientation), the generator version and the intended move count. Presentation metadata (display name,
## developer notes, stage string, timings, rejections, ascii) is deliberately NOT hashed.
##
## Run: godot --headless --path . res://scripts/tools/generator_fingerprint.tscn -- version=5 levels=1,2,3 out=<abs path.json>
##   version=N      generator version (required)
##   levels=a,b,c   explicit levels (default = the built-in representative set for that version)
##   out=<path>     write {"<version>|<level>": "<sha256>"} JSON here (default: print only)
##   check=<path>   compare against a previously written JSON and exit non-zero on any difference
##   budget=55000   milliseconds

const DEFAULTS := {
	1: [1, 5, 10, 20, 30, 40, 50, 75, 100, 150, 200, 300, 500, 800, 1000, 1500, 2000],
	2: [1, 5, 10, 20, 30, 40, 50, 75, 100, 150, 200, 300, 500, 800, 1000, 1500, 2000],
	3: [1, 5, 10, 20, 30, 40, 50, 75, 100, 150, 200, 300, 500, 700, 1000, 1300, 1600, 2000],
	4: [1, 10, 20, 50, 100, 150, 200, 201, 220, 300, 400, 401, 500, 600, 700, 701, 800, 900, 1000, 1001, 1200, 1300, 1400, 1600, 1800, 2000],
	5: [2001, 2020, 2050, 2100, 2150, 2200, 2250, 2300, 2350, 2400, 2450, 2500, 2550, 2600, 2650, 2700, 2750, 2800, 2850, 2900, 2950, 3000, 1500, 2000],
	6: [1, 10, 20, 30, 40, 49, 50, 75, 100, 150, 200, 201, 300, 400, 500, 600, 680, 700, 701, 720, 800, 900, 1000, 1200, 1400, 1600, 1800, 1999, 2000, 2001, 2200, 2400, 2600, 2800, 3000, 3001, 3200, 3400, 3600, 3800, 3999, 4000],
}


static func fingerprint(result: Dictionary, version: int) -> String:
	var ld: LevelData = result["level_data"]
	var rows: Array[String] = []
	for t in ld.tiles:
		rows.append("%d,%d,%d,%d,%d,%d,%d,%d,%s,%s,%d,%s" % [t.tile_type, t.position.x, t.position.y, t.direction, t.mirror_orientation, int(t.rotatable), t.color, int(t.required), t.pair_id, t.gate_id, int(t.initial_open_state), t.link_id])
	rows.sort()
	var sol_rows: Array[String] = []
	var sol: Dictionary = result.get("solution_orientations", {})
	for p in sol:
		sol_rows.append("%d,%d=%d" % [p.x, p.y, int(sol[p])])
	sol_rows.sort()
	var canon := "v%d|%dx%d|moves=%d|fb=%d|%s|sol:%s" % [version, ld.grid_width, ld.grid_height, int(result.get("intended_moves", -1)), int(result.get("fallback_used", false)), ";".join(rows), ";".join(sol_rows)]
	return canon.sha256_text()


func _ready() -> void:
	var version := 0
	var levels: Array = []
	var out := ""
	var check := ""
	var budget := 55000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("version="):
			version = int(arg.substr(8))
		elif arg.begins_with("levels="):
			for s in arg.substr(7).split(","):
				levels.append(int(s))
		elif arg.begins_with("out="):
			out = arg.substr(4)
		elif arg.begins_with("check="):
			check = arg.substr(6)
		elif arg.begins_with("budget="):
			budget = int(arg.substr(7))
	if version == 0:
		printerr("version= is required")
		get_tree().quit(2)
		return
	if levels.is_empty():
		levels = DEFAULTS.get(version, [1, 10, 100]).duplicate()
	var t0 := Time.get_ticks_msec()
	var prints: Dictionary = {}
	for n in levels:
		if Time.get_ticks_msec() - t0 > budget:
			print("QA_BUDGET_EXCEEDED after %d of %d levels" % [prints.size(), levels.size()])
			break
		var r := ProceduralLevelGenerator.generate(int(n), version)
		var fp := fingerprint(r, version)
		prints["%d|%d" % [version, int(n)]] = fp
		print("FP v%d L%d %s%s" % [version, int(n), fp.substr(0, 16), " FALLBACK" if r.get("fallback_used", false) else ""])
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(prints, "\t"))
		f.close()
	var diffs := 0
	if check != "":
		var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(check))
		for k in prints:
			if not base.has(k):
				print("FP_MISSING_BASELINE %s" % k)
			elif base[k] != prints[k]:
				diffs += 1
				print("FP_DIFF %s" % k)
		print("FP_CHECK %d compared, %d differ" % [prints.size(), diffs])
	print("FP_DONE %d levels in %d ms" % [prints.size(), Time.get_ticks_msec() - t0])
	get_tree().quit(1 if diffs > 0 else 0)
