extends Node
## Dev-only (never exported): builds levels/hint_solutions.json - the SOLVER-AUTHORED
## solved orientations the runtime Hint uses for handcrafted campaign levels ("c<id>")
## and tutorials ("t<id>"). Runs LevelSolver OFFLINE so no solver ever runs on a device.
## Each entry lists only the tiles the shortest solution flips: [x, y, solved_orientation].
## Run: godot --headless --path . res://scripts/tools/hint_solution_builder.tscn -- [from=1 to=140]
## A level the solver cannot finish (UNKNOWN) gets NO entry (Hint is then disabled there).

const OUT := "res://levels/hint_solutions.json"


func _ready() -> void:
	var table := {}
	if FileAccess.file_exists(OUT):
		table = JSON.parse_string(FileAccess.get_file_as_string(OUT))
	var kinds := ["c", "t"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			kinds = [arg.substr(5)]
	if "c" in kinds:
		for id in range(1, LevelManager.get_campaign_level_count() + 1):
			_solve("c%d" % id, LevelManager.get_campaign_level(id), table)
	if "t" in kinds:
		for id in range(1, LevelManager.TUTORIAL_LEVEL_PATHS.size() + 1):
			# T21+ (Fusion pack) have a 4-state node LevelSolver cannot model: their entries
			# are hand-authored in the JSON and verified by the tutorial replay driver.
			if id >= LevelManager.FUSION_TUTORIAL_FIRST:
				continue
			_solve("t%d" % id, LevelManager.get_tutorial_level(id), table)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(table))
	f.close()
	print("HINT_TABLE entries=%d" % table.size())
	get_tree().quit()


func _solve(key: String, level: LevelData, table: Dictionary) -> void:
	if level == null:
		return
	var r: Dictionary = LevelSolver.analyze(level, 300000)
	if r["status"] != "SOLVABLE":
		print("%s %s (no entry)" % [key, r["status"]])
		table.erase(key)
		return
	var orient: Dictionary = level.get_initial_tile_orientations()
	var flips := {}
	for step in r["solution_path"]:
		flips[step["position"]] = int(flips.get(step["position"], 0)) + 1
	var entries: Array = []
	for pos in flips:
		if flips[pos] % 2 == 1:
			var o: int = GridTypes.MirrorOrientation.BACKSLASH if orient[pos] == GridTypes.MirrorOrientation.SLASH else GridTypes.MirrorOrientation.SLASH
			entries.append([pos.x, pos.y, o])
	table[key] = entries
	print("%s ok flips=%d states=%d" % [key, entries.size(), r["states_explored"]])
