class_name LevelValidator
extends RefCounted
## Development-only structural validator. Deliberately separate from
## LevelSolver: this checks the level DATA is well-formed (no dangling
## references, no out-of-bounds tiles, etc.) without running any search.
## The one exception is the "trivial solution" warning, which needs a
## single LaserSystem call (not the full solver) to check the level's
## authored initial state.
##
## Result dictionary shape: { "errors": Array[String], "warnings": Array[String] }
## A level with any errors should not be considered playable/saveable as
## final; warnings are advisory only.

const MAX_SANE_GRID_DIMENSION := 20
const MANY_TILES_WARNING_THRESHOLD := 40


static func validate(level_data: LevelData) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	_check_grid_dimensions(level_data, errors)
	var occupied := _check_positions(level_data, errors)
	_check_emitters_and_targets(level_data, errors)
	_check_portals(level_data, errors)
	_check_switches_and_gates(level_data, errors, warnings)
	_check_receivers_and_remote_emitters(level_data, errors, warnings)

	if errors.is_empty():
		_check_rotatable_pieces(level_data, warnings)
		_check_tile_count(level_data, warnings)
		_check_trivial_solution(level_data, warnings)

	return {"errors": errors, "warnings": warnings}


static func _check_grid_dimensions(level_data: LevelData, errors: Array[String]) -> void:
	if level_data.grid_width <= 0 or level_data.grid_height <= 0:
		errors.append("Grid dimensions must be positive (got %dx%d)." % [level_data.grid_width, level_data.grid_height])
	elif level_data.grid_width > MAX_SANE_GRID_DIMENSION or level_data.grid_height > MAX_SANE_GRID_DIMENSION:
		errors.append("Grid dimensions look unreasonably large (%dx%d) - likely a mistake." % [level_data.grid_width, level_data.grid_height])


## Returns a position -> true map of occupied cells (for reuse by other
## checks) while also flagging out-of-bounds and duplicate placements.
static func _check_positions(level_data: LevelData, errors: Array[String]) -> Dictionary:
	var occupied := {}
	for t in level_data.tiles:
		if t.position.x < 0 or t.position.y < 0 or t.position.x >= level_data.grid_width or t.position.y >= level_data.grid_height:
			errors.append("Tile of type %s at %s is outside the %dx%d grid." % [_type_name(t.tile_type), t.position, level_data.grid_width, level_data.grid_height])
			continue
		if occupied.has(t.position):
			errors.append("Duplicate tile at %s (%s and %s both placed there)." % [t.position, _type_name(occupied[t.position]), _type_name(t.tile_type)])
			continue
		occupied[t.position] = t.tile_type
	return occupied


static func _check_emitters_and_targets(level_data: LevelData, errors: Array[String]) -> void:
	var emitters := level_data.get_tiles_of_type(GridTypes.TileType.EMITTER)
	if emitters.is_empty():
		errors.append("Level has no EMITTER tile - the puzzle has no laser source.")

	var required_targets := 0
	for t in level_data.get_tiles_of_type(GridTypes.TileType.TARGET):
		if t.required:
			required_targets += 1
	if required_targets == 0:
		errors.append("Level has no REQUIRED target - it can never be completed.")


static func _check_portals(level_data: LevelData, errors: Array[String]) -> void:
	var by_pair := {}
	for t in level_data.get_tiles_of_type(GridTypes.TileType.PORTAL):
		if t.pair_id == "":
			errors.append("Portal at %s has an empty pair_id." % t.position)
			continue
		if not by_pair.has(t.pair_id):
			by_pair[t.pair_id] = []
		by_pair[t.pair_id].append(t.position)

	for pair_id in by_pair:
		var positions: Array = by_pair[pair_id]
		if positions.size() != 2:
			errors.append("Portal pair \"%s\" has %d member(s) (needs exactly 2): %s." % [pair_id, positions.size(), positions])


static func _check_switches_and_gates(level_data: LevelData, errors: Array[String], warnings: Array[String]) -> void:
	var gate_ids := {}
	for t in level_data.get_tiles_of_type(GridTypes.TileType.GATE):
		if t.gate_id == "":
			errors.append("Gate at %s has an empty gate_id." % t.position)
			continue
		gate_ids[t.gate_id] = true

	var referenced_gate_ids := {}
	for t in level_data.get_tiles_of_type(GridTypes.TileType.SWITCH):
		if t.gate_id == "":
			errors.append("Switch at %s has an empty gate_id (doesn't link to any gate)." % t.position)
			continue
		referenced_gate_ids[t.gate_id] = true
		if not gate_ids.has(t.gate_id):
			errors.append("Switch at %s references gate_id \"%s\", which no GATE tile has." % [t.position, t.gate_id])

	for gate_id in gate_ids:
		if not referenced_gate_ids.has(gate_id):
			warnings.append("Gate \"%s\" has no switch that opens it - it will stay at its initial state forever." % gate_id)


## Era 2 ("Refractions") mirror of _check_switches_and_gates() for
## BEAM_RECEIVER -> REMOTE_EMITTER link_id linking - see
## ERA_2_DESIGN.md "Beam Receiver / Remote Emitter". An empty link_id on
## either tile type is an error (it can never participate in any link).
## A REMOTE_EMITTER whose link_id matches no BEAM_RECEIVER can never fire
## - error, not warning, since (unlike an always-open gate) there is no
## way for it to ever contribute to the puzzle, so any such level is
## broken by construction. A BEAM_RECEIVER with no REMOTE_EMITTER on its
## link_id is harmless (mirrors the existing gate-with-no-switch warning)
## - it still visually pulses when hit, it just powers nothing.
static func _check_receivers_and_remote_emitters(level_data: LevelData, errors: Array[String], warnings: Array[String]) -> void:
	var receiver_link_ids := {}
	for t in level_data.get_tiles_of_type(GridTypes.TileType.BEAM_RECEIVER):
		if t.link_id == "":
			errors.append("Beam Receiver at %s has an empty link_id." % t.position)
			continue
		receiver_link_ids[t.link_id] = true

	var remote_emitter_link_ids := {}
	for t in level_data.get_tiles_of_type(GridTypes.TileType.REMOTE_EMITTER):
		if t.link_id == "":
			errors.append("Remote Emitter at %s has an empty link_id." % t.position)
			continue
		remote_emitter_link_ids[t.link_id] = true
		if not receiver_link_ids.has(t.link_id):
			errors.append("Remote Emitter at %s references link_id \"%s\", which no Beam Receiver has - it can never fire." % [t.position, t.link_id])

	for link_id in receiver_link_ids:
		if not remote_emitter_link_ids.has(link_id):
			warnings.append("Beam Receiver link \"%s\" has no Remote Emitter - it will pulse when hit but power nothing." % link_id)


static func _check_rotatable_pieces(level_data: LevelData, warnings: Array[String]) -> void:
	if level_data.get_rotatable_tiles().is_empty():
		warnings.append("Level has no rotatable mirrors or splitters - the player cannot make any moves.")


static func _check_tile_count(level_data: LevelData, warnings: Array[String]) -> void:
	if level_data.tiles.size() > MANY_TILES_WARNING_THRESHOLD:
		warnings.append("Level has %d tiles, which is a lot - consider whether it could be simplified." % level_data.tiles.size())


static func _check_trivial_solution(level_data: LevelData, warnings: Array[String]) -> void:
	var orientations := level_data.get_initial_tile_orientations()
	var result := LaserSystem.simulate_until_stable(level_data, orientations)
	if result["solved"]:
		warnings.append("Level is already solved in its authored (zero-move) state - TRIVIAL SOLUTION.")


static func _type_name(tile_type: GridTypes.TileType) -> String:
	return GridTypes.TileType.keys()[tile_type]
