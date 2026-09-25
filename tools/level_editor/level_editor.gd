extends Control
## Root of tools/level_editor/level_editor.tscn - the Milestone 3
## development-only level editor. NOT part of the shipped player
## gameplay UI; open it by running this scene directly in the Godot
## editor (F6). See LEVEL_EDITOR.md for the full usage guide.
##
## Architecture: a normal runtime Godot scene (no @tool, no EditorPlugin)
## that happens to be a level-authoring application, reusing LevelData/
## TilePlacement/LaserSystem/LevelValidator/LevelSolver directly. See
## DECISIONS.md ("Level editor architecture") for why this was chosen
## over an EditorPlugin/dock.

const TOOL_SELECT := -2
const TOOL_ERASE := -1

## Palette entries: [tool_id, label]. tool_id is a GridTypes.TileType
## value for placement tools, or one of the TOOL_* sentinels above.
const PALETTE_ENTRIES := [
	[TOOL_SELECT, "Select / Inspect"],
	[TOOL_ERASE, "Eraser"],
	[GridTypes.TileType.EMITTER, "Emitter"],
	[GridTypes.TileType.MIRROR, "Mirror"],
	[GridTypes.TileType.BLOCKER, "Blocker"],
	[GridTypes.TileType.TARGET, "Target"],
	[GridTypes.TileType.SPLITTER, "Splitter"],
	[GridTypes.TileType.FILTER, "Filter"],
	[GridTypes.TileType.PORTAL, "Portal"],
	[GridTypes.TileType.SWITCH, "Switch"],
	[GridTypes.TileType.GATE, "Gate"],
	[GridTypes.TileType.HAZARD, "Hazard"],
]

const CELL_SIZE := 56.0

const COLOR_NAMES := ["WHITE", "RED", "GREEN", "BLUE"]
const DIRECTION_NAMES := ["UP", "RIGHT", "DOWN", "LEFT"]
const ORIENTATION_NAMES := ["/", "\\"]

@onready var _id_spin: SpinBox = %IdSpin
@onready var _name_edit: LineEdit = %NameEdit
@onready var _width_spin: SpinBox = %WidthSpin
@onready var _height_spin: SpinBox = %HeightSpin
@onready var _optimal_spin: SpinBox = %OptimalSpin
@onready var _new_button: Button = %NewButton
@onready var _stage_edit: LineEdit = %StageEdit
@onready var _notes_edit: LineEdit = %NotesEdit
@onready var _difficulty_label: Label = %DifficultyLabel
@onready var _palette_container: VBoxContainer = %PaletteContainer
@onready var _grid_container: GridContainer = %GridContainer
@onready var _properties_panel: VBoxContainer = %PropertiesPanel
@onready var _load_option: OptionButton = %LoadOption
@onready var _load_button: Button = %LoadButton
@onready var _save_path_edit: LineEdit = %SavePathEdit
@onready var _save_button: Button = %SaveButton
@onready var _validate_button: Button = %ValidateButton
@onready var _solve_button: Button = %SolveButton
@onready var _playtest_button: Button = %PlaytestButton
@onready var _quit_button: Button = %QuitButton
@onready var _output_label: RichTextLabel = %OutputLabel

var current_level: LevelData
var selected_tool: int = GridTypes.TileType.EMITTER
var selected_tile: TilePlacement = null

var _cell_buttons: Dictionary = {} # Vector2i -> Button
var _palette_buttons: Dictionary = {} # tool_id -> Button
var _palette_button_group := ButtonGroup.new()
var _last_solver_result: Dictionary = {}
var _load_paths: Array[String] = []


func _ready() -> void:
	_build_palette()
	_new_button.pressed.connect(_on_new_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_validate_button.pressed.connect(_on_validate_pressed)
	_solve_button.pressed.connect(_on_solve_pressed)
	_playtest_button.pressed.connect(_on_playtest_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_populate_load_dropdown()

	if GameManager.is_editor_playtest_return_pending():
		current_level = GameManager.take_editor_level_data()
		_log("[color=aqua]Returned from playtest.[/color] Editing resumed on \"%s\"." % current_level.display_name)
		_load_fields_from_level()
	else:
		_new_level_from_fields()

	_rebuild_grid_view()


# ---------------------------------------------------------------------------
# Palette
# ---------------------------------------------------------------------------

func _build_palette() -> void:
	for entry in PALETTE_ENTRIES:
		var tool_id: int = entry[0]
		var label: String = entry[1]
		var button := Button.new()
		button.text = label
		button.toggle_mode = true
		button.button_group = _palette_button_group
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_tool_selected.bind(tool_id))
		_palette_container.add_child(button)
		_palette_buttons[tool_id] = button

	_palette_buttons[selected_tool].button_pressed = true


func _on_tool_selected(tool_id: int) -> void:
	selected_tool = tool_id


# ---------------------------------------------------------------------------
# Level lifecycle
# ---------------------------------------------------------------------------

func _new_level_from_fields() -> void:
	var level := LevelData.new()
	level.level_id = int(_id_spin.value)
	level.display_name = _name_edit.text
	level.grid_width = int(_width_spin.value)
	level.grid_height = int(_height_spin.value)
	level.optimal_moves = int(_optimal_spin.value)
	level.stage = _stage_edit.text
	level.developer_notes = _notes_edit.text
	current_level = level
	selected_tile = null
	_last_solver_result = {}
	_difficulty_label.text = "Difficulty: (run Analyze)"


func _on_new_pressed() -> void:
	var old_tiles: Array[TilePlacement] = current_level.tiles if current_level != null else []
	_new_level_from_fields()

	# Carry over any tiles that still fit inside the new dimensions rather
	# than discarding everything on a pure resize (only "New" with an
	# empty canvas discards - this button doubles as both per Part 2's
	# "choose grid dimensions" + practical resizing needs).
	var kept: Array[TilePlacement] = []
	var dropped := 0
	for t in old_tiles:
		if t.position.x < current_level.grid_width and t.position.y < current_level.grid_height:
			kept.append(t)
		else:
			dropped += 1
	current_level.tiles = kept

	_rebuild_grid_view()
	if dropped > 0:
		_log("[color=yellow]Resized grid - %d tile(s) outside the new bounds were dropped.[/color]" % dropped)
	else:
		_log("Grid set to %dx%d." % [current_level.grid_width, current_level.grid_height])


func _load_fields_from_level() -> void:
	_id_spin.value = current_level.level_id
	_name_edit.text = current_level.display_name
	_width_spin.value = current_level.grid_width
	_height_spin.value = current_level.grid_height
	_optimal_spin.value = current_level.optimal_moves
	_stage_edit.text = current_level.stage
	_notes_edit.text = current_level.developer_notes
	selected_tile = null
	_last_solver_result = {}
	_difficulty_label.text = "Difficulty: (run Analyze)"


func _sync_level_metadata_from_fields() -> void:
	current_level.level_id = int(_id_spin.value)
	current_level.display_name = _name_edit.text
	current_level.optimal_moves = int(_optimal_spin.value)
	current_level.stage = _stage_edit.text
	current_level.developer_notes = _notes_edit.text


# ---------------------------------------------------------------------------
# Grid view
# ---------------------------------------------------------------------------

func _rebuild_grid_view() -> void:
	for child in _grid_container.get_children():
		child.queue_free()
	_cell_buttons.clear()

	_grid_container.columns = current_level.grid_width

	for y in range(current_level.grid_height):
		for x in range(current_level.grid_width):
			var pos := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			button.pressed.connect(_on_cell_clicked.bind(pos))
			_grid_container.add_child(button)
			_cell_buttons[pos] = button

	for t in current_level.tiles:
		_refresh_cell_visual(t.position)


func _tile_at(pos: Vector2i) -> TilePlacement:
	for t in current_level.tiles:
		if t.position == pos:
			return t
	return null


func _on_cell_clicked(pos: Vector2i) -> void:
	if selected_tool == TOOL_SELECT:
		selected_tile = _tile_at(pos)
		_rebuild_properties_panel()
		return

	if selected_tool == TOOL_ERASE:
		var existing := _tile_at(pos)
		if existing != null:
			current_level.tiles.erase(existing)
			if selected_tile == existing:
				selected_tile = null
				_rebuild_properties_panel()
			_refresh_cell_visual(pos)
		return

	# Placement tool: replace whatever's there (if anything) with a fresh
	# default tile of the chosen type.
	var existing := _tile_at(pos)
	if existing != null:
		current_level.tiles.erase(existing)

	var new_tile := _make_default_tile(selected_tool as GridTypes.TileType, pos)
	current_level.tiles.append(new_tile)
	selected_tile = new_tile
	_refresh_cell_visual(pos)
	_rebuild_properties_panel()


func _make_default_tile(tile_type: GridTypes.TileType, pos: Vector2i) -> TilePlacement:
	match tile_type:
		GridTypes.TileType.EMITTER:
			return TilePlacement.make_emitter(pos, GridTypes.Direction.RIGHT)
		GridTypes.TileType.MIRROR:
			return TilePlacement.make_mirror(pos, GridTypes.MirrorOrientation.SLASH)
		GridTypes.TileType.BLOCKER:
			return TilePlacement.make_blocker(pos)
		GridTypes.TileType.TARGET:
			return TilePlacement.make_target(pos)
		GridTypes.TileType.SPLITTER:
			return TilePlacement.make_splitter(pos, GridTypes.MirrorOrientation.SLASH)
		GridTypes.TileType.FILTER:
			return TilePlacement.make_filter(pos, GridTypes.BeamColor.RED)
		GridTypes.TileType.PORTAL:
			return TilePlacement.make_portal(pos, "A")
		GridTypes.TileType.SWITCH:
			return TilePlacement.make_switch(pos, "G")
		GridTypes.TileType.GATE:
			return TilePlacement.make_gate(pos, "G", false)
		GridTypes.TileType.HAZARD:
			return TilePlacement.make_hazard(pos)
	return TilePlacement.make_blocker(pos)


func _refresh_cell_visual(pos: Vector2i) -> void:
	var button: Button = _cell_buttons.get(pos)
	if button == null:
		return
	var t := _tile_at(pos)
	if t == null:
		button.text = ""
		button.modulate = Color.WHITE
		return

	button.modulate = Color.WHITE
	match t.tile_type:
		GridTypes.TileType.EMITTER:
			button.text = "E\n%s" % _direction_arrow(t.direction)
			button.modulate = _color_tint(t.color)
		GridTypes.TileType.MIRROR:
			button.text = ORIENTATION_NAMES[t.mirror_orientation]
			button.modulate = Color.WHITE if t.rotatable else Color(0.6, 0.6, 0.6)
		GridTypes.TileType.BLOCKER:
			button.text = "X"
		GridTypes.TileType.TARGET:
			button.text = "T%s" % ("" if t.required else "\n(opt)")
			button.modulate = _color_tint(t.color)
		GridTypes.TileType.SPLITTER:
			button.text = "S" + ORIENTATION_NAMES[t.mirror_orientation]
			button.modulate = Color.WHITE if t.rotatable else Color(0.6, 0.6, 0.6)
		GridTypes.TileType.FILTER:
			button.text = "F"
			button.modulate = _color_tint(t.color)
		GridTypes.TileType.PORTAL:
			button.text = "P:%s" % t.pair_id.left(4)
		GridTypes.TileType.SWITCH:
			button.text = "SW:%s" % t.gate_id.left(4)
		GridTypes.TileType.GATE:
			button.text = "G:%s\n%s" % [t.gate_id.left(4), "OPEN" if t.initial_open_state else "SHUT"]
		GridTypes.TileType.HAZARD:
			button.text = "!"
			button.modulate = Color(1.0, 0.4, 0.4)


func _direction_arrow(dir: GridTypes.Direction) -> String:
	match dir:
		GridTypes.Direction.UP: return "^"
		GridTypes.Direction.RIGHT: return ">"
		GridTypes.Direction.DOWN: return "v"
		GridTypes.Direction.LEFT: return "<"
	return "?"


func _color_tint(color: GridTypes.BeamColor) -> Color:
	var c := GridTypes.beam_color_to_render_color(color)
	return Color(c.r, c.g, c.b, 1.0)


# ---------------------------------------------------------------------------
# Properties panel
# ---------------------------------------------------------------------------

func _rebuild_properties_panel() -> void:
	for child in _properties_panel.get_children():
		child.queue_free()

	if selected_tile == null:
		var label := Label.new()
		label.text = "No tile selected.\nUse Select/Inspect and click a placed tile, or place a new one."
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_properties_panel.add_child(label)
		return

	var title := Label.new()
	title.text = "%s at %s" % [GridTypes.TileType.keys()[selected_tile.tile_type], selected_tile.position]
	_properties_panel.add_child(title)

	match selected_tile.tile_type:
		GridTypes.TileType.EMITTER:
			_add_direction_field("Direction", selected_tile.direction, func(v): selected_tile.direction = v)
			_add_color_field("Beam Color", selected_tile.color, func(v): selected_tile.color = v)
		GridTypes.TileType.MIRROR, GridTypes.TileType.SPLITTER:
			_add_orientation_field("Orientation", selected_tile.mirror_orientation, func(v): selected_tile.mirror_orientation = v)
			_add_bool_field("Rotatable", selected_tile.rotatable, func(v): selected_tile.rotatable = v)
		GridTypes.TileType.TARGET:
			_add_bool_field("Required", selected_tile.required, func(v): selected_tile.required = v)
			_add_color_field("Required Color (WHITE = any)", selected_tile.color, func(v): selected_tile.color = v)
		GridTypes.TileType.FILTER:
			_add_color_field("Output Color", selected_tile.color, func(v): selected_tile.color = v)
		GridTypes.TileType.PORTAL:
			_add_string_field("Pair ID", selected_tile.pair_id, func(v): selected_tile.pair_id = v)
		GridTypes.TileType.SWITCH:
			_add_string_field("Opens Gate ID", selected_tile.gate_id, func(v): selected_tile.gate_id = v)
		GridTypes.TileType.GATE:
			_add_string_field("Gate ID", selected_tile.gate_id, func(v): selected_tile.gate_id = v)
			_add_bool_field("Starts Open", selected_tile.initial_open_state, func(v): selected_tile.initial_open_state = v)
		GridTypes.TileType.BLOCKER, GridTypes.TileType.HAZARD:
			var none_label := Label.new()
			none_label.text = "(no properties)"
			_properties_panel.add_child(none_label)

	var remove_button := Button.new()
	remove_button.text = "Remove This Tile"
	remove_button.pressed.connect(_on_remove_selected_pressed)
	_properties_panel.add_child(remove_button)


func _on_remove_selected_pressed() -> void:
	if selected_tile == null:
		return
	var pos := selected_tile.position
	current_level.tiles.erase(selected_tile)
	selected_tile = null
	_refresh_cell_visual(pos)
	_rebuild_properties_panel()


func _add_string_field(label_text: String, value: String, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	_properties_panel.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.text_changed.connect(func(new_text: String) -> void:
		on_change.call(new_text)
		_refresh_cell_visual(selected_tile.position)
	)
	_properties_panel.add_child(edit)


func _add_bool_field(label_text: String, value: bool, on_change: Callable) -> void:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = value
	check.toggled.connect(func(pressed: bool) -> void:
		on_change.call(pressed)
		_refresh_cell_visual(selected_tile.position)
	)
	_properties_panel.add_child(check)


func _add_direction_field(label_text: String, value: GridTypes.Direction, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	_properties_panel.add_child(label)
	var option := OptionButton.new()
	for name in DIRECTION_NAMES:
		option.add_item(name)
	option.selected = value
	option.item_selected.connect(func(index: int) -> void:
		on_change.call(index)
		_refresh_cell_visual(selected_tile.position)
	)
	_properties_panel.add_child(option)


func _add_color_field(label_text: String, value: GridTypes.BeamColor, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	_properties_panel.add_child(label)
	var option := OptionButton.new()
	for name in COLOR_NAMES:
		option.add_item(name)
	option.selected = value
	option.item_selected.connect(func(index: int) -> void:
		on_change.call(index)
		_refresh_cell_visual(selected_tile.position)
	)
	_properties_panel.add_child(option)


func _add_orientation_field(label_text: String, value: GridTypes.MirrorOrientation, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	_properties_panel.add_child(label)
	var option := OptionButton.new()
	for name in ORIENTATION_NAMES:
		option.add_item(name)
	option.selected = value
	option.item_selected.connect(func(index: int) -> void:
		on_change.call(index)
		_refresh_cell_visual(selected_tile.position)
	)
	_properties_panel.add_child(option)


# ---------------------------------------------------------------------------
# Load / Save
# ---------------------------------------------------------------------------

func _populate_load_dropdown() -> void:
	_load_option.clear()
	_load_paths.clear()

	for path in LevelManager.LEVEL_PATHS:
		_load_paths.append(path)
		_load_option.add_item(path.get_file())

	var fixtures_dir := "res://levels/editor_fixtures"
	var dir := DirAccess.open(fixtures_dir)
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		var fixture_files: Array[String] = []
		while file_name != "":
			if file_name.ends_with(".gd") or file_name.ends_with(".tres"):
				fixture_files.append(file_name)
			file_name = dir.get_next()
		fixture_files.sort()
		for f in fixture_files:
			var full_path := fixtures_dir + "/" + f
			_load_paths.append(full_path)
			_load_option.add_item("[fixture] " + f)


func _on_load_pressed() -> void:
	var index := _load_option.selected
	if index < 0 or index >= _load_paths.size():
		_log("[color=yellow]Nothing selected to load.[/color]")
		return

	var path := _load_paths[index]
	var loaded := LevelManager.load_level_from_path(path)
	if loaded == null:
		_log("[color=red]Failed to load %s.[/color]" % path)
		return

	current_level = loaded
	_load_fields_from_level()
	_rebuild_grid_view()
	_save_path_edit.text = path if path.ends_with(".tres") else "res://levels/level_%02d.tres" % current_level.level_id
	_log("Loaded \"%s\" from %s." % [current_level.display_name, path])


func _on_save_pressed() -> void:
	_sync_level_metadata_from_fields()

	var validation := LevelValidator.validate(current_level)
	if not validation["errors"].is_empty():
		_log("[color=red]Save blocked - fix these errors first:[/color]")
		for e in validation["errors"]:
			_log("  - %s" % e)
		return

	for w in validation["warnings"]:
		_log("[color=yellow]Warning:[/color] %s" % w)

	var path: String = _save_path_edit.text
	if not path.ends_with(".tres"):
		_log("[color=red]Save path must end in .tres[/color]")
		return

	var err := ResourceSaver.save(current_level, path)
	if err == OK:
		_log("[color=lime]Saved to %s.[/color]" % path)
		_populate_load_dropdown()
	else:
		_log("[color=red]Save failed (error code %d).[/color]" % err)


# ---------------------------------------------------------------------------
# Validate / Solve / Playtest
# ---------------------------------------------------------------------------

func _on_validate_pressed() -> void:
	_sync_level_metadata_from_fields()
	var validation := LevelValidator.validate(current_level)

	_log("[b]--- VALIDATION ---[/b]")
	if validation["errors"].is_empty():
		_log("[color=lime]Structural Validation: PASS[/color]")
	else:
		_log("[color=red]Structural Validation: FAIL[/color]")
		for e in validation["errors"]:
			_log("  ERROR: %s" % e)

	for w in validation["warnings"]:
		_log("[color=yellow]  WARNING: %s[/color]" % w)


func _on_solve_pressed() -> void:
	_sync_level_metadata_from_fields()
	var validation := LevelValidator.validate(current_level)
	if not validation["errors"].is_empty():
		_log("[color=red]Cannot run solver - level has structural errors. Run Validate first.[/color]")
		return

	_log("[b]--- SOLVER ---[/b]")
	_log("Analyzing (this may take a moment)...")

	var result := LevelSolver.analyze(current_level)
	_last_solver_result = result

	_log("Solvability: [b]%s[/b]" % result["status"])
	if result["trivial"]:
		_log("[color=yellow]TRIVIAL SOLUTION - 0 MOVES[/color]")

	if result["status"] == "SOLVABLE":
		_log("Declared Optimal Moves: %d" % current_level.optimal_moves)
		_log("Calculated Optimal Moves: %d" % result["optimal_moves"])
		if result["optimal_moves"] != current_level.optimal_moves:
			_log("[color=yellow]WARNING: declared optimal_moves does not match the solver. %s[/color]" % (
				"A shorter solution exists." if result["optimal_moves"] < current_level.optimal_moves else "The declared value is optimistic - no solution that short was found."
			))
		_log("Shortest Solutions Found: %d" % result["shortest_solution_count"])
		_log("States Explored: %d (elapsed %dms)" % [result["states_explored"], result["elapsed_ms"]])

		if result["solution_path"].size() > 0:
			_log("[b]Example shortest solution:[/b]")
			var step_num := 1
			for step in result["solution_path"]:
				_log("  Move %d: tile at %s -> orientation %s" % [step_num, step["position"], ORIENTATION_NAMES[step["to"]]])
				step_num += 1
		else:
			_log("(zero-move solution - nothing to rotate)")

		if result["possible_decoys"].size() > 0:
			_log("[color=yellow]Possible unused/decoy piece(s): %s[/color]" % [result["possible_decoys"]])
	elif result["status"] == "UNSOLVABLE":
		_log("[color=red]No solution exists using only the rotatable mirrors/splitters in this level.[/color]")
		_log("States Explored: %d (full state space exhausted)" % result["states_explored"])
	else:
		_log("[color=yellow]UNKNOWN - search limit (%d states) reached before the search could finish.[/color]" % LevelSolver.DEFAULT_MAX_STATES)
		_log("This does NOT mean the level is unsolvable - only that this many rotatable pieces need a larger search budget than the default.")

	var metrics := LevelMetrics.compute(current_level, result)
	_difficulty_label.text = "Difficulty: %s (estimate)" % metrics["difficulty_label"]

	_log("[b]--- METRICS ---[/b]")
	_log("Grid: %dx%d | Rotatable: %d | Fixed: %d" % [metrics["grid_width"], metrics["grid_height"], metrics["rotatable_pieces"], metrics["fixed_pieces"]])
	_log("Emitters: %d | Targets: %d | Mechanics: %s" % [metrics["emitters"], metrics["targets"], ", ".join(metrics["mechanics_used"])])
	_log("Difficulty Estimate: [b]%s[/b] (heuristic only - see DECISIONS.md)" % metrics["difficulty_label"])


func _on_playtest_pressed() -> void:
	_sync_level_metadata_from_fields()
	var validation := LevelValidator.validate(current_level)
	if not validation["errors"].is_empty():
		_log("[color=red]Cannot playtest - level has structural errors. Run Validate first.[/color]")
		return

	_log("Launching playtest with the real gameplay system...")
	GameManager.start_editor_playtest(current_level)


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)


# ---------------------------------------------------------------------------
# Output log
# ---------------------------------------------------------------------------

func _log(text: String) -> void:
	_output_label.append_text(text + "\n")
