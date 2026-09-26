class_name FusionQaSet
extends RefCounted
## Beam Fusion Node QA puzzles (Fusion Phase 1, D99) - DEVELOPER/QA ONLY. Mechanic-validation
## boards reachable solely through Main Menu "FUSION TEST" / in-game "NEXT FUSION"
## (LevelManager.SHOW_FUSION_TEST_QA). They are NOT campaign levels, NOT part of the 1-2000
## procedural progression and never touch saves, stars, ads or the completion counter.
## Each puzzle carries its own solution (cell -> solved orientation) for the Hint system -
## the exhaustive LevelSolver is binary-flip only and does not model a 4-state Fusion.
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
	lv.stage = "fusion_qa"
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
		1: # RED + GREEN -> YELLOW. Both inputs are needed; the Fusion must face RIGHT.
			t = [
				TilePlacement.make_emitter(_v(0, 3), _R, _RED),
				TilePlacement.make_emitter(_v(3, 0), _D, _GREEN),
				TilePlacement.make_fusion(_v(3, 3), _L),
				TilePlacement.make_target(_v(5, 3), GridTypes.BeamColor.YELLOW),
			]
			sol = {_v(3, 3): _R}
			lv = _level(i, "Fusion 1", 6, 5, 2, t)
		2: # RED + BLUE -> MAGENTA, one mirror turn needed before the node activates.
			t = [
				TilePlacement.make_emitter(_v(0, 0), _D, _RED),
				TilePlacement.make_mirror(_v(0, 2), _S),
				TilePlacement.make_emitter(_v(4, 5), _U, _BLUE),
				TilePlacement.make_fusion(_v(4, 2), _U),
				TilePlacement.make_target(_v(5, 2), GridTypes.BeamColor.MAGENTA),
			]
			sol = {_v(0, 2): _B, _v(4, 2): _R}
			lv = _level(i, "Fusion 2", 6, 6, 2, t)
		3: # GREEN + BLUE -> CYAN, then a CYAN Filter before the CYAN target.
			t = [
				TilePlacement.make_emitter(_v(2, 0), _D, _GREEN),
				TilePlacement.make_emitter(_v(0, 4), _U, _BLUE),
				TilePlacement.make_mirror(_v(0, 2), _B),
				TilePlacement.make_fusion(_v(2, 2), _U),
				TilePlacement.make_filter(_v(3, 2), GridTypes.BeamColor.CYAN),
				TilePlacement.make_target(_v(4, 2), GridTypes.BeamColor.CYAN),
			]
			sol = {_v(0, 2): _S, _v(2, 2): _R}
			lv = _level(i, "Fusion 3", 5, 5, 2, t)
		4: # RED + GREEN + BLUE -> WHITE. A Prism proves the output is truly WHITE: only a WHITE
			# beam splits into three channels that light three colour-specific targets.
			t = [
				TilePlacement.make_emitter(_v(0, 0), _D, _RED),
				TilePlacement.make_mirror(_v(0, 3), _S),
				TilePlacement.make_emitter(_v(3, 0), _D, _GREEN),
				TilePlacement.make_emitter(_v(0, 6), _R, _BLUE),
				TilePlacement.make_mirror(_v(3, 6), _B),
				TilePlacement.make_fusion(_v(3, 3), _U),
				TilePlacement.make_prism(_v(5, 3)),
				TilePlacement.make_target(_v(6, 3), _RED),
				TilePlacement.make_target(_v(5, 2), _GREEN),
				TilePlacement.make_target(_v(5, 4), _BLUE),
			]
			sol = {_v(0, 3): _B, _v(3, 6): _S, _v(3, 3): _R}
			lv = _level(i, "Fusion 4", 7, 7, 3, t)
		5: # Dependency chain: Prism colours -> two mirrored paths -> Fusion -> Receiver ->
			# Remote Emitter -> mirror -> Target.
			t = [
				TilePlacement.make_emitter(_v(0, 1), _R),
				TilePlacement.make_prism(_v(2, 1)),
				TilePlacement.make_blocker(_v(2, 0)),
				TilePlacement.make_mirror(_v(5, 1), _S),
				TilePlacement.make_mirror(_v(2, 3), _S),
				TilePlacement.make_fusion(_v(5, 3), _U),
				TilePlacement.make_beam_receiver(_v(6, 3), "fz"),
				TilePlacement.make_remote_emitter(_v(6, 5), _L, "fz"),
				TilePlacement.make_mirror(_v(3, 5), _S),
				TilePlacement.make_target(_v(3, 4)),
			]
			sol = {_v(5, 1): _B, _v(2, 3): _B, _v(5, 3): _R, _v(3, 5): _B}
			lv = _level(i, "Fusion 5", 7, 7, 4, t)
		_: # 6: Portal -> Fusion. RED crosses a portal pair, GREEN arrives directly.
			t = [
				TilePlacement.make_emitter(_v(0, 0), _R, _RED),
				TilePlacement.make_portal(_v(2, 0), "pf"),
				TilePlacement.make_portal(_v(2, 4), "pf"),
				TilePlacement.make_emitter(_v(4, 6), _U, _GREEN),
				TilePlacement.make_fusion(_v(4, 4), _U),
				TilePlacement.make_target(_v(5, 4), GridTypes.BeamColor.YELLOW),
			]
			sol = {_v(4, 4): _R}
			lv = _level(i, "Fusion 6", 6, 7, 1, t)
	return {
		"level_data": lv,
		"solution_orientations": sol,
		"seed": 0,
		"generator_version": 0,
		"name": lv.display_name,
	}
