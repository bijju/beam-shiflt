class_name ProceduralTemplates
extends RefCounted
## Solution-first puzzle templates for the procedural generator. Every
## template builds its INTENDED solved path first (using GridTypes.reflect()
## semantics via a shared zigzag-path helper - never inventing a new beam
## rule), places TilePlacements with that solution baked in as the
## authored (often scrambled-away-from-solution) state, and returns the
## solution's own rotatable orientations alongside the LevelData so the
## caller (ProceduralLevelGenerator) can self-verify via the real
## LaserSystem before ever presenting a candidate to a player. See
## PROCEDURAL_GENERATION.md "Generation templates".
##
## Geometry note: every path here is a monotonic "zigzag" - each leg moves
## strictly RIGHT, then strictly DOWN (or strictly UP), alternating. This
## guarantees no self-intersection and keeps every turn a single uniform
## MirrorOrientation (RIGHT->DOWN and DOWN->RIGHT are both BACKSLASH;
## RIGHT->UP and UP->RIGHT are both SLASH - see GridTypes.reflect()) by
## construction, with zero risk of the "stray beam crosses an unrelated
## tile" shortcut class CLAUDE.md's Era 2 lessons (D81/D82/D83) warn
## about, since a monotonic path can never re-enter a cell it already
## used for something else.

const TEMPLATE_IDS: Array[String] = [
	"simple_mirror_route", "multi_mirror_route", "splitter_branch",
	"color_filter_route", "portal_route", "switch_gate_dependency",
	"multiple_emitter", "one_way_directional_route", "prism_color_branch",
	"receiver_remote_emitter",
]


## Returns { "level_data": LevelData, "solution_orientations": Dictionary }.
## solution_orientations is Vector2i -> GridTypes.MirrorOrientation (int)
## for every ROTATABLE tile this template placed, holding the CORRECT
## (un-scrambled) orientation - never includes non-rotatable tiles (their
## authored orientation IS their only orientation).
static func build(template_id: String, rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	match template_id:
		"splitter_branch":
			return _build_splitter_branch(rng, profile, board_size)
		"color_filter_route":
			return _build_color_filter_route(rng, profile, board_size)
		"portal_route":
			return _build_portal_route(rng, profile, board_size)
		"switch_gate_dependency":
			return _build_switch_gate_dependency(rng, profile, board_size)
		"multiple_emitter":
			return _build_multiple_emitter(rng, profile, board_size)
		"one_way_directional_route":
			return _build_one_way_directional_route(rng, profile, board_size)
		"prism_color_branch":
			return _build_prism_color_branch(rng, profile, board_size)
		"receiver_remote_emitter":
			return _build_receiver_remote_emitter(rng, profile, board_size)
		_: # "simple_mirror_route", "multi_mirror_route", and any unknown id
			return _build_mirror_route(rng, profile, board_size)


# --- Templates ---------------------------------------------------------

static func _build_mirror_route(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var turn_count := _pick_turn_count(rng, profile)
	var path := _zigzag_path(rng, board_size, turn_count)
	var flip_chance: float = profile.get("flip_chance", 0.65)

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path["emitter_pos"], path["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path["target_pos"]))

	var solution := {}
	_place_mirror_turns(rng, level, path, solution, flip_chance)
	_add_decoys(rng, level, profile, path["occupied"], board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_splitter_branch(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var turn_count: int = maxi(_pick_turn_count(rng, profile), 1)
	var path := _zigzag_path(rng, board_size, turn_count)
	var turns: Array = path["turns"]
	var flip_chance: float = profile.get("flip_chance", 0.65)

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path["emitter_pos"], path["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path["target_pos"]))

	var solution := {}
	var splitter_index: int = rng.randi_range(0, turns.size() - 1)
	var authored := _scrambled_orientations(rng, path["orientation"], turns.size(), flip_chance)
	for i in range(turns.size()):
		var pos: Vector2i = turns[i]
		solution[pos] = path["orientation"]
		if i == splitter_index:
			level.tiles.append(TilePlacement.make_splitter(pos, authored[i], true))
		else:
			level.tiles.append(TilePlacement.make_mirror(pos, authored[i], true))

	_add_decoys(rng, level, profile, path["occupied"], board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_color_filter_route(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var turn_count: int = maxi(_pick_turn_count(rng, profile), 1)
	var path := _zigzag_path(rng, board_size, turn_count)
	var turns: Array = path["turns"]
	var path_cells: Array = path["path_cells"]

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path["emitter_pos"], path["emitter_dir"]))

	var colors := [GridTypes.BeamColor.RED, GridTypes.BeamColor.GREEN, GridTypes.BeamColor.BLUE]
	var chosen_color: int = colors[rng.randi_range(0, colors.size() - 1)]
	var straight_cells := _straight_cells(path_cells, turns, path["target_pos"])

	if straight_cells.size() > 0:
		var filter_pos: Vector2i = straight_cells[rng.randi_range(0, straight_cells.size() - 1)]
		level.tiles.append(TilePlacement.make_filter(filter_pos, chosen_color))
		level.tiles.append(TilePlacement.make_target(path["target_pos"], chosen_color))
	else:
		level.tiles.append(TilePlacement.make_target(path["target_pos"]))

	var solution := {}
	_place_mirror_turns(rng, level, path, solution, profile.get("flip_chance", 0.65))
	_add_decoys(rng, level, profile, path["occupied"], board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_portal_route(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var total_turns: int = maxi(_pick_turn_count(rng, profile), 2)
	var turns1: int = maxi(total_turns / 2, 1)
	# Forced even so num_legs1 = turns1+1 is odd -> path 1's LAST leg is
	# horizontal -> the beam always enters Portal A moving RIGHT. Portals
	# preserve direction (see laser_system.gd's simulate()), and path 2 is
	# always built via _zigzag_path(), which always starts its own first
	# leg moving RIGHT too - so this parity match is what makes "beam exits
	# Portal B and continues along path 2" true. Losing this (a prior
	# version dropped it entirely) let path 1 sometimes end moving DOWN/UP
	# into the portal, so the beam exited Portal B in the wrong direction
	# for path 2's geometry - found by this pass's own template sweep
	# smoke test (portal_route: solver sometimes SOLVABLE by an unintended
	# combination, but the template's OWN intended solution never simulated
	# as solved).
	turns1 = turns1 if turns1 % 2 == 0 else turns1 + 1
	var turns2: int = maxi(total_turns - turns1, 1)

	# Band-split the board exactly like _build_multiple_emitter() so path 2
	# always gets its own full-width room starting at x=0 - portal_b is
	# path2's own (unused-as-an-emitter) origin. A prior version tried to
	# place portal_b in path1's own column (board.x-1, the far-right edge),
	# which left path2 zero horizontal room and made it degenerate into a
	# clamped vertical wiggle that collided with portal_a/its own tiles -
	# found by this pass's own template sweep smoke test (30/30 portal_route
	# attempts failed validation). Band-splitting removes the root cause
	# instead of special-casing around it.
	var half_height: int = maxi(board_size.y / 2, 2)
	var other_height: int = maxi(board_size.y - half_height, 2)

	var path1 := _zigzag_path(rng, Vector2i(board_size.x, half_height), turns1)
	var path2 := _zigzag_path(rng, Vector2i(board_size.x, other_height), turns2)
	var offset_b := Vector2i(0, board_size.y - other_height)

	var portal_a: Vector2i = path1["target_pos"]
	var portal_b: Vector2i = path2["emitter_pos"] + offset_b

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path1["emitter_pos"], path1["emitter_dir"]))
	var pair_id: String = "P%d_%d" % [portal_a.x, portal_a.y]
	level.tiles.append(TilePlacement.make_portal(portal_a, pair_id))
	level.tiles.append(TilePlacement.make_portal(portal_b, pair_id))
	level.tiles.append(TilePlacement.make_target(path2["target_pos"] + offset_b))

	var solution := {}
	var flip_chance: float = profile.get("flip_chance", 0.65)
	_place_mirror_turns(rng, level, path1, solution, flip_chance)
	_place_mirror_turns_offset(rng, level, path2, offset_b, solution, flip_chance)

	var occupied: Dictionary = path1["occupied"].duplicate()
	for pos in path2["occupied"]:
		occupied[pos + offset_b] = true
	_add_decoys(rng, level, profile, occupied, board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_switch_gate_dependency(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var turn_count: int = maxi(_pick_turn_count(rng, profile), 2)
	var path := _zigzag_path(rng, board_size, turn_count)
	var turns: Array = path["turns"]
	var straight_cells := _straight_cells(path["path_cells"], turns, path["target_pos"])

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path["emitter_pos"], path["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path["target_pos"]))

	# Switch must land BEFORE the gate along the beam's path (straight_cells
	# is already in path order) - simulate_until_stable() only opens a gate
	# for the pass AFTER the one that hit its switch, so a gate positioned
	# earlier than its own switch would block the very beam that's supposed
	# to reach the switch, and the level would be permanently unsolvable.
	# See laser_system.gd's simulate_until_stable() doc comment.
	if straight_cells.size() >= 2:
		var gate_id: String = "G%d_%d" % [path["target_pos"].x, path["target_pos"].y]
		level.tiles.append(TilePlacement.make_switch(straight_cells[0], gate_id))
		level.tiles.append(TilePlacement.make_gate(straight_cells[straight_cells.size() - 1], gate_id, false))

	var solution := {}
	_place_mirror_turns(rng, level, path, solution, profile.get("flip_chance", 0.65))
	_add_decoys(rng, level, profile, path["occupied"], board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_multiple_emitter(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var total_turns: int = maxi(_pick_turn_count(rng, profile), 2)
	var turns_a: int = maxi(total_turns / 2, 1)
	var turns_b: int = maxi(total_turns - turns_a, 1)

	var half_height: int = maxi(board_size.y / 2, 2)
	var other_height: int = maxi(board_size.y - half_height, 2)

	var path_a := _zigzag_path(rng, Vector2i(board_size.x, half_height), turns_a)
	var path_b := _zigzag_path(rng, Vector2i(board_size.x, other_height), turns_b)
	var offset_b := Vector2i(0, board_size.y - other_height)

	var level := _new_level(board_size)

	level.tiles.append(TilePlacement.make_emitter(path_a["emitter_pos"], path_a["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path_a["target_pos"]))
	var solution := {}
	var flip_chance: float = profile.get("flip_chance", 0.65)
	_place_mirror_turns(rng, level, path_a, solution, flip_chance)

	level.tiles.append(TilePlacement.make_emitter(path_b["emitter_pos"] + offset_b, path_b["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path_b["target_pos"] + offset_b))
	_place_mirror_turns_offset(rng, level, path_b, offset_b, solution, flip_chance)

	var occupied: Dictionary = path_a["occupied"].duplicate()
	for pos in path_b["occupied"]:
		occupied[pos + offset_b] = true
	_add_decoys(rng, level, profile, occupied, board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_one_way_directional_route(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var turn_count: int = maxi(_pick_turn_count(rng, profile), 1)
	var path := _zigzag_path(rng, board_size, turn_count)
	var turns: Array = path["turns"]

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path["emitter_pos"], path["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path["target_pos"]))

	var solution := {}
	# A one-way reflector's reflective side depends on incoming direction
	# and orientation (see GridTypes.one_way_reflector_is_reflective()) -
	# every turn on this path is entered moving RIGHT, which is ALWAYS
	# reflective regardless of orientation, so it's a safe drop-in
	# replacement for exactly one mirror on the path (orientation still
	# fully controls which way it reflects, same puzzle value as a mirror).
	var one_way_index: int = rng.randi_range(0, turns.size() - 1)
	var authored := _scrambled_orientations(rng, path["orientation"], turns.size(), profile.get("flip_chance", 0.65))
	for i in range(turns.size()):
		var pos: Vector2i = turns[i]
		solution[pos] = path["orientation"]
		if i == one_way_index:
			level.tiles.append(TilePlacement.make_one_way_reflector(pos, authored[i], true))
		else:
			level.tiles.append(TilePlacement.make_mirror(pos, authored[i], true))

	_add_decoys(rng, level, profile, path["occupied"], board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_prism_color_branch(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var turn_count: int = maxi(_pick_turn_count(rng, profile), 1)
	var path := _zigzag_path(rng, board_size, turn_count)
	var turns: Array = path["turns"]
	var path_cells: Array = path["path_cells"]

	var level := _new_level(board_size)
	level.tiles.append(TilePlacement.make_emitter(path["emitter_pos"], path["emitter_dir"]))

	# A Prism is never rotatable - its RED channel always continues straight
	# in the beam's current direction (see GridTypes.prism_output_direction()),
	# so placing it one cell before the target on the path's own final leg
	# (which is already a straight run) needs no extra mirrors: the RED
	# channel walks straight into the target. Only used when that final leg
	# is at least 2 cells long, so the prism cell is distinct from both the
	# preceding turn and the target itself.
	var last_turn: Vector2i = turns[turns.size() - 1] if turns.size() > 0 else path["emitter_pos"]
	var prism_pos: Vector2i = path_cells[path_cells.size() - 2] if path_cells.size() >= 2 else Vector2i(-1, -1)
	var use_prism: bool = prism_pos != Vector2i(-1, -1) and prism_pos != last_turn and prism_pos != path["emitter_pos"]

	if use_prism:
		level.tiles.append(TilePlacement.make_prism(prism_pos))
		level.tiles.append(TilePlacement.make_target(path["target_pos"], GridTypes.BeamColor.RED))
	else:
		level.tiles.append(TilePlacement.make_target(path["target_pos"]))

	var solution := {}
	_place_mirror_turns(rng, level, path, solution, profile.get("flip_chance", 0.65))
	_add_decoys(rng, level, profile, path["occupied"], board_size)
	return {"level_data": level, "solution_orientations": solution}


static func _build_receiver_remote_emitter(rng: RandomNumberGenerator, profile: Dictionary, board_size: Vector2i) -> Dictionary:
	var total_turns: int = maxi(_pick_turn_count(rng, profile), 2)
	var turns_a: int = maxi(total_turns / 2, 1)
	var turns_b: int = maxi(total_turns - turns_a, 1)

	var half_height: int = maxi(board_size.y / 2, 2)
	var other_height: int = maxi(board_size.y - half_height, 2)

	var path_a := _zigzag_path(rng, Vector2i(board_size.x, half_height), turns_a)
	var path_b := _zigzag_path(rng, Vector2i(board_size.x, other_height), turns_b)
	var offset_b := Vector2i(0, board_size.y - other_height)

	var level := _new_level(board_size)

	# Main path (A): emitter -> ... -> Beam Receiver (mid-path, non-
	# blocking, like a switch) -> ... -> Target A.
	level.tiles.append(TilePlacement.make_emitter(path_a["emitter_pos"], path_a["emitter_dir"]))
	level.tiles.append(TilePlacement.make_target(path_a["target_pos"]))

	var link_id: String = "R%d_%d" % [path_a["target_pos"].x, path_a["target_pos"].y]
	var straight_cells_a := _straight_cells(path_a["path_cells"], path_a["turns"], path_a["target_pos"])
	if straight_cells_a.size() > 0:
		var receiver_pos: Vector2i = straight_cells_a[straight_cells_a.size() / 2]
		level.tiles.append(TilePlacement.make_beam_receiver(receiver_pos, link_id))

	var solution := {}
	var flip_chance: float = profile.get("flip_chance", 0.65)
	_place_mirror_turns(rng, level, path_a, solution, flip_chance)

	# Secondary path (B): Remote Emitter (only fires once the Receiver
	# above is hit - see laser_system.gd's simulate_until_stable()) -> ...
	# -> Target B. The Remote Emitter's own position/direction are fixed
	# by the generator like a real emitter; only the mirrors routing its
	# beam are player-rotatable.
	level.tiles.append(TilePlacement.make_remote_emitter(path_b["emitter_pos"] + offset_b, path_b["emitter_dir"], link_id))
	level.tiles.append(TilePlacement.make_target(path_b["target_pos"] + offset_b))
	_place_mirror_turns_offset(rng, level, path_b, offset_b, solution, flip_chance)

	var occupied: Dictionary = path_a["occupied"].duplicate()
	for pos in path_b["occupied"]:
		occupied[pos + offset_b] = true
	_add_decoys(rng, level, profile, occupied, board_size)
	return {"level_data": level, "solution_orientations": solution}


# --- Shared helpers ------------------------------------------------------

static func _new_level(board_size: Vector2i) -> LevelData:
	var level := LevelData.new()
	level.grid_width = board_size.x
	level.grid_height = board_size.y
	level.tiles = []
	return level


static func _pick_turn_count(rng: RandomNumberGenerator, profile: Dictionary) -> int:
	var r: Vector2i = profile.get("rotatable_range", Vector2i(1, 1))
	return rng.randi_range(r.x, maxi(r.x, r.y))


## Places a MIRROR at every turn of `path` with a scrambled (authored)
## orientation, and records the correct (solution) orientation for each.
## `flip_chance` defaults to 0.65 (V1's original hardcoded constant) so
## any caller that doesn't pass a profile-derived value keeps V1's exact
## behavior - see ProceduralDifficultyProfile's V1/V2 doc comment.
static func _place_mirror_turns(rng: RandomNumberGenerator, level: LevelData, path: Dictionary, solution: Dictionary, flip_chance: float = 0.65) -> void:
	var turns: Array = path["turns"]
	var authored := _scrambled_orientations(rng, path["orientation"], turns.size(), flip_chance)
	for i in range(turns.size()):
		var pos: Vector2i = turns[i]
		solution[pos] = path["orientation"]
		level.tiles.append(TilePlacement.make_mirror(pos, authored[i], true))


## Same as _place_mirror_turns(), offsetting every position by `offset` -
## used for a second path built on its own local sub-board (multiple
## emitters / receiver+remote-emitter) before being merged onto the shared
## board.
static func _place_mirror_turns_offset(rng: RandomNumberGenerator, level: LevelData, path: Dictionary, offset: Vector2i, solution: Dictionary, flip_chance: float = 0.65) -> void:
	var turns: Array = path["turns"]
	var authored := _scrambled_orientations(rng, path["orientation"], turns.size(), flip_chance)
	for i in range(turns.size()):
		var pos: Vector2i = turns[i] + offset
		solution[pos] = path["orientation"]
		level.tiles.append(TilePlacement.make_mirror(pos, authored[i], true))


## Path cells that are neither a turn nor the final target - i.e. cells on
## a straight leg, safe for a non-bending tile (Filter/Switch/Gate/Beam
## Receiver) that must sit ON the beam's path without being a turn point.
static func _straight_cells(path_cells: Array, turns: Array, target_pos: Vector2i) -> Array:
	var result: Array = []
	for cell in path_cells:
		if cell != target_pos and not turns.has(cell):
			result.append(cell)
	return result


## With probability `flip_chance` per tile, returns the OPPOSITE of
## `solution` (the puzzle's authored/scrambled state) instead of
## `solution` itself; guarantees at least one tile differs from the
## solution so no candidate is ever trivially pre-solved (zero-move).
static func _scrambled_orientations(rng: RandomNumberGenerator, solution: int, count: int, flip_chance: float = 0.65) -> Array:
	var result: Array = []
	var any_flipped := false
	for i in range(count):
		var flipped: bool = rng.randf() < flip_chance
		result.append(_opposite(solution) if flipped else solution)
		any_flipped = any_flipped or flipped
	if not any_flipped and count > 0:
		var idx := rng.randi_range(0, count - 1)
		result[idx] = _opposite(solution)
	return result


static func _opposite(orientation: int) -> int:
	return GridTypes.MirrorOrientation.SLASH if orientation == GridTypes.MirrorOrientation.BACKSLASH else GridTypes.MirrorOrientation.BACKSLASH


## Places up to profile.decoy_budget non-rotatable, off-path mirrors at
## random empty cells. Inert by construction (`occupied` already marks
## every cell any beam could ever reach, so no beam ever touches a decoy) -
## a deliberately conservative interpretation of "fair decoys" that can
## never create the "stray beam crosses an unrelated tile" shortcut class
## documented in CLAUDE.md's Era 2 lessons (D81-D83). Genuinely-reachable,
## rotatable decoys are a documented future extension - see
## PROCEDURAL_GENERATION.md "Generation templates" / decoys.
static func _add_decoys(rng: RandomNumberGenerator, level: LevelData, profile: Dictionary, occupied: Dictionary, board_size: Vector2i) -> void:
	var budget: int = int(profile.get("decoy_budget", 0))
	if budget <= 0:
		return
	var occ: Dictionary = occupied.duplicate()
	var placed := 0
	var attempts := 0
	while placed < budget and attempts < budget * 8:
		attempts += 1
		var pos := Vector2i(rng.randi_range(0, board_size.x - 1), rng.randi_range(0, board_size.y - 1))
		if occ.has(pos):
			continue
		occ[pos] = true
		var orientation: int = GridTypes.MirrorOrientation.SLASH if rng.randi_range(0, 1) == 0 else GridTypes.MirrorOrientation.BACKSLASH
		level.tiles.append(TilePlacement.make_mirror(pos, orientation, false))
		placed += 1


## Core monotonic path builder, starting at grid column 0. See the file's
## class doc comment for why a monotonic zigzag is always self-consistent
## and collision-free. Returns emitter_pos/emitter_dir/target_pos in
## addition to _zigzag_from()'s own fields.
static func _zigzag_path(rng: RandomNumberGenerator, board: Vector2i, turn_count: int) -> Dictionary:
	var start_y: int = rng.randi_range(0, maxi(board.y - 1, 0))
	var origin := Vector2i(0, start_y)
	var result := _zigzag_from(rng, board, turn_count, origin)
	result["emitter_pos"] = origin
	result["emitter_dir"] = GridTypes.Direction.RIGHT
	result["target_pos"] = result["end_pos"]
	return result


## General monotonic path builder starting at an arbitrary `origin`,
## always moving RIGHT first (the only start_dir this project's portal
## semantics ever need - see _build_portal_route()). Alternates
## RIGHT/DOWN (all turns BACKSLASH) or RIGHT/UP (all turns SLASH),
## whichever direction has more room from `origin`, so the path can never
## walk off the board by construction (clamping below is a pure safety
## net, not the primary bounds mechanism).
static func _zigzag_from(rng: RandomNumberGenerator, board: Vector2i, turn_count: int, origin: Vector2i) -> Dictionary:
	var room_below: int = board.y - 1 - origin.y
	var room_above: int = origin.y
	var go_down: bool = room_below >= room_above
	if room_below == room_above:
		go_down = rng.randi_range(0, 1) == 0

	var orientation: int = GridTypes.MirrorOrientation.BACKSLASH if go_down else GridTypes.MirrorOrientation.SLASH

	var h_room: int = maxi(board.x - 1 - origin.x, 0)
	var v_room: int = maxi(room_below if go_down else room_above, 0)

	# Clamp turn_count so num_h_legs (=ceil(num_legs/2)) fits within h_room
	# and num_v_legs (=floor(num_legs/2)) fits within v_room BEFORE laying
	# out legs - never after. A prior version only floored each leg's
	# distributed length at 1 (never raising num_legs beyond what room
	# allows), which could force more legs than the board could actually
	# hold; the per-step walk then clamped at the boundary, producing
	# duplicate turn/target positions - found by this pass's own template
	# sweep smoke test (multiple_emitter/receiver_remote_emitter/
	# portal_route all hit this on smaller band-split boards). Clamping the
	# turn count itself up front, not the symptom, removes the root cause:
	# num_legs = L needs ceil(L/2) <= h_room and floor(L/2) <= v_room, i.e.
	# L <= 2*h_room and L <= 2*v_room + 1.
	var max_legs: int = maxi(mini(h_room * 2, v_room * 2 + 1), 1)
	turn_count = mini(maxi(turn_count, 0), max_legs - 1)

	var num_legs: int = turn_count + 1
	var num_h_legs: int = int(ceil(num_legs / 2.0))
	var num_v_legs: int = num_legs - num_h_legs
	var h_budget: int = maxi(h_room, num_h_legs)
	var v_budget: int = maxi(v_room, num_v_legs)

	var h_legs := _distribute(rng, h_budget, num_h_legs)
	var v_legs := _distribute(rng, v_budget, num_v_legs)

	var pos := origin
	var occupied := {pos: true}
	var path_cells: Array[Vector2i] = []
	var turns: Array[Vector2i] = []
	var horizontal_turn := true # first leg is always horizontal (RIGHT)
	var h_index := 0
	var v_index := 0

	for leg_index in range(num_legs):
		var leg_length: int = maxi(h_legs[h_index] if horizontal_turn else v_legs[v_index], 1)
		if horizontal_turn:
			h_index += 1
		else:
			v_index += 1

		for _step in range(leg_length):
			var delta: Vector2i = Vector2i(1, 0) if horizontal_turn else Vector2i(0, 1 if go_down else -1)
			pos += delta
			pos.x = clampi(pos.x, 0, board.x - 1)
			pos.y = clampi(pos.y, 0, board.y - 1)
			occupied[pos] = true
			path_cells.append(pos)

		if leg_index < num_legs - 1:
			turns.append(pos)

		horizontal_turn = not horizontal_turn

	return {
		"origin": origin,
		"start_dir": GridTypes.Direction.RIGHT,
		"path_cells": path_cells,
		"turns": turns,
		"end_pos": pos,
		"orientation": orientation,
		"occupied": occupied,
	}


## Splits `total` across `count` legs, each at least 1, summing to
## max(total, count).
static func _distribute(rng: RandomNumberGenerator, total: int, count: int) -> Array:
	if count <= 0:
		return []
	var legs: Array = []
	for i in range(count):
		legs.append(1)
	var remaining: int = maxi(total - count, 0)
	while remaining > 0:
		var idx := rng.randi_range(0, count - 1)
		legs[idx] += 1
		remaining -= 1
	return legs
