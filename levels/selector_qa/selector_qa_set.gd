class_name SelectorQaSet
extends RefCounted
## Splitter Selector QA puzzles (Selector Phase S1) - DEVELOPER/QA ONLY. Mechanic-validation boards
## reachable solely through Main Menu "SELECTOR TEST" / in-game "NEXT SELECTOR"
## (LevelManager.SHOW_SELECTOR_TEST_QA). They are NOT campaign levels, NOT part of any procedural
## progression and never touch saves, stars, ads or the completion counter.
## Each puzzle carries its own solution (cell -> solved orientation) for the Hint system - the
## exhaustive LevelSolver is binary-flip only and does not model a 4-state Selector/Fusion.
## scripts/tools/selector_verify.tscn brute-forces every orientation combination of every puzzle
## and asserts each has exactly ONE solved state (the authored solution).
##
## Coordinates (x, y) with y growing DOWN. Directions: UP=0 RIGHT=1 DOWN=2 LEFT=3.
## Mirror SLASH: R->U U->R L->D D->L. BACKSLASH: R->D D->R L->U U->L.

const _U := GridTypes.Direction.UP
const _R := GridTypes.Direction.RIGHT
const _D := GridTypes.Direction.DOWN
const _L := GridTypes.Direction.LEFT
const _S := GridTypes.MirrorOrientation.SLASH
const _B := GridTypes.MirrorOrientation.BACKSLASH
const _RED := GridTypes.BeamColor.RED
const _GREEN := GridTypes.BeamColor.GREEN
const _BLUE := GridTypes.BeamColor.BLUE

const COUNT := 6


static func _v(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)


static func _level(index: int, name: String, w: int, h: int, moves: int, tiles: Array[TilePlacement]) -> LevelData:
	var lv := LevelData.new()
	lv.level_id = index
	lv.display_name = name
	lv.stage = "selector_qa"
	lv.grid_width = w
	lv.grid_height = h
	lv.optimal_moves = moves
	lv.tiles = tiles
	return lv


## {level_data, solution_orientations, seed, generator_version, name}
static func get_puzzle(index: int) -> Dictionary:
	var i := clampi(index, 1, COUNT)
	var t: Array[TilePlacement] = []
	var sol := {}
	var lv: LevelData
	match i:
		1: # Emitter -> Selector -> Target. The middle state (RIGHT) runs into a hazard.
			t = [
				TilePlacement.make_emitter(_v(0, 2), _R),
				TilePlacement.make_splitter_selector(_v(2, 2), _U),
				TilePlacement.make_hazard(_v(4, 2)),
				TilePlacement.make_target(_v(2, 4)),
			]
			sol = {_v(2, 2): _D}
			lv = _level(i, "Selector 1", 5, 6, 2, t)
		2: # Selector -> Filter -> Mirror -> Target. Only the DOWN branch carries BLUE; the RIGHT
			# branch's RED filter leaves the decoy BLUE target dark.
			t = [
				TilePlacement.make_emitter(_v(0, 1), _R),
				TilePlacement.make_splitter_selector(_v(2, 1), _R),
				TilePlacement.make_filter(_v(3, 1), _RED),
				TilePlacement.make_target(_v(5, 1), _BLUE, false),
				TilePlacement.make_filter(_v(2, 3), _BLUE),
				TilePlacement.make_mirror(_v(2, 5), _S),
				TilePlacement.make_blocker(_v(1, 5)),
				TilePlacement.make_target(_v(4, 5), _BLUE),
			]
			sol = {_v(2, 1): _D, _v(2, 5): _B}
			lv = _level(i, "Selector 2", 6, 7, 2, t)
		3: # Selector -> Portal -> Target. RIGHT is the hazard decoy; the target sits below the
			# portal's EXIT, nowhere near the selector's own column.
			t = [
				TilePlacement.make_emitter(_v(0, 2), _R),
				TilePlacement.make_splitter_selector(_v(2, 2), _U),
				TilePlacement.make_hazard(_v(5, 2)),
				TilePlacement.make_portal(_v(2, 4), "sp"),
				TilePlacement.make_portal(_v(4, 0), "sp"),
				TilePlacement.make_target(_v(4, 4)),
			]
			sol = {_v(2, 2): _D}
			lv = _level(i, "Selector 3", 6, 6, 2, t)
		4: # Selector -> Switch -> Gate -> Target. The selector's beam only powers the Switch; the
			# second emitter then passes the opened Gate to the Target.
			t = [
				TilePlacement.make_emitter(_v(0, 2), _R),
				TilePlacement.make_splitter_selector(_v(2, 2), _U),
				TilePlacement.make_hazard(_v(4, 2)),
				TilePlacement.make_switch(_v(2, 4), "g"),
				TilePlacement.make_blocker(_v(2, 5)),
				TilePlacement.make_emitter(_v(0, 6), _R),
				TilePlacement.make_gate(_v(3, 6), "g"),
				TilePlacement.make_target(_v(5, 6)),
			]
			sol = {_v(2, 2): _D}
			lv = _level(i, "Selector 4", 6, 7, 2, t)
		5: # Selector -> Fusion input -> Fusion output -> Target. RED (turned DOWN by the selector) and
			# GREEN (direct) fuse to YELLOW; the Fusion must also face the target.
			t = [
				TilePlacement.make_emitter(_v(0, 1), _R, _RED),
				TilePlacement.make_splitter_selector(_v(2, 1), _U),
				TilePlacement.make_hazard(_v(4, 1)),
				TilePlacement.make_emitter(_v(0, 5), _R, _GREEN),
				TilePlacement.make_fusion(_v(2, 5), _L),
				TilePlacement.make_target(_v(5, 5), GridTypes.BeamColor.YELLOW),
			]
			sol = {_v(2, 1): _D, _v(2, 5): _R}
			lv = _level(i, "Selector 5", 6, 6, 4, t)
		_: # 6: Selector -> Receiver -> Remote (GREEN) + Portal (RED, past a Blocker) -> Fusion -> Target.
			t = [
				TilePlacement.make_emitter(_v(0, 1), _R),
				TilePlacement.make_splitter_selector(_v(2, 1), _U),
				TilePlacement.make_hazard(_v(5, 1)),
				TilePlacement.make_beam_receiver(_v(2, 3), "sr"),
				TilePlacement.make_remote_emitter(_v(4, 3), _D, "sr", _GREEN),
				TilePlacement.make_emitter(_v(0, 5), _R, _RED),
				TilePlacement.make_portal(_v(1, 5), "pr"),
				TilePlacement.make_blocker(_v(2, 5)),
				TilePlacement.make_portal(_v(3, 5), "pr"),
				TilePlacement.make_fusion(_v(4, 5), _L),
				TilePlacement.make_target(_v(6, 5), GridTypes.BeamColor.YELLOW),
			]
			sol = {_v(2, 1): _D, _v(4, 5): _R}
			lv = _level(i, "Selector 6", 7, 7, 4, t)
	return {
		"level_data": lv,
		"solution_orientations": sol,
		"seed": 0,
		"generator_version": 0,
		"name": lv.display_name,
	}
