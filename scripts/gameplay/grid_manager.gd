class_name GridManager
extends Control
## Owns all authoritative puzzle state for the currently loaded level:
## mirror/splitter orientations, target/switch/gate/hazard state, and the
## simulated beam paths. Tile nodes are dumb views; this script is the
## only place that mutates gameplay state. See ARCHITECTURE.md.
##
## Gates and switches are intentionally stateless/derived rather than
## persisted here: every simulate call recomputes them fresh from
## level_data's initial_open_state plus whatever the CURRENT mirror/
## splitter configuration reaches this run. See DECISIONS.md ("Switch/
## gate simulation strategy") for why, and note this is what makes Reset
## work for free - nothing gate/switch-specific needs to be restored.
##
## Responsive layout: this control expands to fill the CENTER AREA given
## to it by game.tscn - the real playable rectangle between the Top HUD
## bar and Bottom HUD bar (game.tscn's VBoxContainer sizes CenterArea to
## whatever's left after the two aspect-locked HUD bars, so `size` here
## already IS that rectangle; no viewport math needed). On every resize
## it fits an arbitrary rows x columns board into that rectangle using
## independent per-axis cell-size candidates (see _recalculate_layout()),
## so a rectangular (non-square) board fills the available space instead
## of being constrained to the smaller of the two axes. Cells are always
## square (one scalar cell_size, never stretched per-axis) and the grid
## is centered in whatever space remains. See CLAUDE.md's rectangular-
## grid architecture rule and DECISIONS.md D72.

signal move_made
signal level_solved
## Fires at the end of every _simulate_and_draw() pass, AFTER target/
## switch/gate/hazard states are updated - unlike move_made (which fires
## BEFORE simulation runs, so it's only safe for "a move happened"
## checks, never for reading post-move target/gate state). Guided-
## tutorial-only consumer: TutorialManager's WAIT_FOR_TARGET_ACTIVATION
## steps need this exact ordering to see the move's actual effect. See
## DECISIONS.md "Guided tutorial system".
signal simulation_updated
## Fires at the very top of _on_orientable_tile_clicked(), for EVERY tap
## attempt on an orientable tile - accepted or rejected - unlike
## move_made (which only fires for an actually-accepted tap that
## rotates a tile). Guided-tutorial-QA-only consumer: game.gd's QA debug
## overlay uses this to show the result of a rejected tap too, which is
## exactly the case a "nothing happens when I tap" report needs
## visibility into. See DECISIONS.md ("Guided tutorial click input fix").
signal tile_tap_attempted

const EMITTER_SCENE := preload("res://scenes/tiles/emitter.tscn")
const MIRROR_SCENE := preload("res://scenes/tiles/mirror.tscn")
const TARGET_SCENE := preload("res://scenes/tiles/target.tscn")
const BLOCKER_SCENE := preload("res://scenes/tiles/blocker.tscn")
const SPLITTER_SCENE := preload("res://scenes/tiles/splitter.tscn")
const FILTER_SCENE := preload("res://scenes/tiles/filter.tscn")
const PORTAL_SCENE := preload("res://scenes/tiles/portal.tscn")
const SWITCH_SCENE := preload("res://scenes/tiles/switch.tscn")
const GATE_SCENE := preload("res://scenes/tiles/gate.tscn")
const HAZARD_SCENE := preload("res://scenes/tiles/hazard.tscn")
const PRISM_SCENE := preload("res://scenes/tiles/prism.tscn")
const ONE_WAY_REFLECTOR_SCENE := preload("res://scenes/tiles/one_way_reflector.tscn")
const FUSION_SCENE := preload("res://scenes/tiles/fusion.tscn")
const SPLITTER_SELECTOR_SCENE := preload("res://scenes/tiles/splitter_selector.tscn")
const BEAM_RECEIVER_SCENE := preload("res://scenes/tiles/beam_receiver.tscn")
const REMOTE_EMITTER_SCENE := preload("res://scenes/tiles/remote_emitter.tscn")
const MIRROR_IMPACT_FX_SCENE := preload("res://scenes/gameplay/laser_mirror_impact_fx.tscn")
const ERA2_ACTIVATION_FX_SCENE := preload("res://scenes/gameplay/era2_activation_fx.tscn")
## Skip impact bursts before the first real layout pass (cell_size is a
## placeholder then) and hard-cap them so a pathological board can never
## spawn an unbounded number of effect nodes on a phone.
const IMPACT_FX_MIN_CELL_SIZE := 8.0
const IMPACT_FX_MAX_COUNT := 40

## Single centralized inset between the grid and whatever surrounds
## CenterArea (Top/Bottom HUD bars, side safe margins), applied on all
## four sides. Deliberately small and deliberately one value, not
## separate top/bottom/left/right constants - see CLAUDE.md's
## rectangular-grid rule ("do not hardcode separate unrelated top/bottom
## gaps"). At the 1080-wide reference canvas this is comfortably inside
## the suggested 8-16px starting range; it's a floor on top of whatever
## gap game.tscn's VBoxContainer separation already provides, not a
## replacement for it.
const GRID_SAFETY_MARGIN := 8.0

## Phase 1 (Shared Adaptive Gameplay Layout Foundation, see DECISIONS.md D84):
## hard ceiling on columns for any NEW procedurally-generated board profile.
## This is a future-generator contract, not a retroactive rule - Campaign
## Levels 41-140 (and a handful of dev/tutorial/fixture levels) already
## exceed this and are grandfathered as legacy/regression content; see D84's
## column audit. A future procedural generator must never request more than
## this many columns.
const MAX_COLUMNS := 8

## Phase 1: the minimum cell_size (at the 1080-wide reference canvas) a
## board profile must produce to count as comfortably thumb-tappable.
## Android's Material Design minimum touch target is 48dp; at this
## project's ~2x reference-px-to-dp ratio (1080 reference width against a
## common ~360dp device width) that's ~96px. Deliberately NOT raised to
## match the campaign's own historical average (122.4px, per D76's audit) -
## this is a floor for future procedural profiles, not a claim that every
## existing level already clears it (the densest existing boards run as
## low as 87px and are left unchanged, per D84).
const MIN_COMFORTABLE_CELL_SIZE := 96.0

const COLOR_GRID_LINE := Color(0.2, 0.21, 0.25)
const BEAM_GLOW_WIDTH := 18.0
const BEAM_CORE_WIDTH := 5.0
const BEAM_GLOW_ALPHA := 0.3
## Core beam color is lerped toward white so it reads as a bright,
## saturated center rather than the same flat color as the glow - a cheap
## "bloom" look with zero extra draw calls or shader cost (Milestone 4A
## laser visual upgrade; the beam DATA - path/color/segments - is
## unchanged, see ARCHITECTURE.md/CLAUDE.md rule 1).
const BEAM_CORE_BRIGHTEN := 0.35

var level_data: LevelData

## Vector2i -> GridTypes.MirrorOrientation. Live/current orientation of
## every MIRROR and SPLITTER tile (both share this dict and this enum -
## see DECISIONS.md "Tile data model").
var tile_orientations: Dictionary = {}

var _orientable_nodes: Dictionary = {} # Vector2i -> node with a settable .orientation (Mirror/SplitterTile)
var _target_nodes: Dictionary = {} # Vector2i -> TargetTile
var _switch_nodes: Dictionary = {} # Vector2i -> SwitchTile
var _hazard_nodes: Dictionary = {} # Vector2i -> HazardTile
var _gate_nodes: Dictionary = {} # Vector2i -> GateTile
var _gate_id_by_position: Dictionary = {} # Vector2i -> String, for gate visuals only
var _receiver_nodes: Dictionary = {} # Vector2i -> BeamReceiverTile (Era 2)
var _remote_emitter_nodes: Dictionary = {} # Vector2i -> RemoteEmitterTile (Era 2)
var _remote_emitter_link_id_by_position: Dictionary = {} # Vector2i -> String (Era 2)
var _prism_positions: Dictionary = {} # Vector2i -> true (Era 2, VFX only)
var _fusion_nodes: Dictionary = {} # Vector2i -> FusionTile (Fusion Phase 1)
var _selector_nodes: Dictionary = {} # Vector2i -> SplitterSelectorTile (Selector Phase S1)
var _filter_positions: Dictionary = {} # Vector2i -> true (audio only - see _play_beam_interaction_audio())

var cell_size: float = 64.0
var grid_origin: Vector2 = Vector2.ZERO
var is_solved: bool = false

## Guided-tutorial-only interaction gates, applied exclusively by
## TutorialManager - both default to their inert values so Campaign and
## editor-playtest input are completely unaffected. See
## _on_orientable_tile_clicked() below and DECISIONS.md ("Guided
## tutorial system").
## true: every orientable-tile tap is ignored, no matter which tile.
var interaction_locked: bool = false
## non-null Vector2i: only a tap on this exact position is accepted;
## every other orientable tile is ignored. null: no restriction.
var interaction_restricted_to = null

## Guided-tutorial-QA-only: records the outcome of the most recent
## orientable-tile tap, read by game.gd's QA debug overlay - see
## DECISIONS.md ("Guided tutorial click input fix"). Purely diagnostic;
## nothing in gameplay logic reads these back.
var last_tap_cell: Vector2i = Vector2i(-1, -1)
var last_tap_accepted: bool = false
var last_tap_rejection_reason: String = ""

var _last_result: Dictionary = {}
var _background_root: Control
var _tiles_root: Control
var _beams_root: Control
var _impact_root: Control
var _highlight_node: TutorialHighlight
var _dim_overlay: TutorialDimOverlay
var _highlight_position: Vector2i = Vector2i(-1, -1)
## Global Hint System (D97): a second, dim-free copy of the tutorial ring owned by
## HintManager via show_hint_cell()/clear_hint_cell(); never touches the tutorial highlight/dim.
var _hint_node: TutorialHighlight
var _hint_position: Vector2i = Vector2i(-1, -1)
var _beam_line_pool: Array = [] # reused Line2D pairs, {glow, core}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_recalculate_layout)

	_background_root = Control.new()
	_background_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_root.name = "CellBackgrounds"
	add_child(_background_root)

	_tiles_root = Control.new()
	_tiles_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_tiles_root.name = "Tiles"
	add_child(_tiles_root)

	_beams_root = Control.new()
	_beams_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beams_root.name = "Beams"
	add_child(_beams_root)

	_impact_root = Control.new()
	_impact_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_impact_root.name = "ImpactFX"
	add_child(_impact_root)

	_dim_overlay = TutorialDimOverlay.new()
	_dim_overlay.name = "TutorialDimOverlay"
	_dim_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_overlay.visible = false
	add_child(_dim_overlay)

	_highlight_node = TutorialHighlight.new()
	_highlight_node.name = "TutorialHighlight"
	_highlight_node.visible = false
	add_child(_highlight_node)

	_hint_node = TutorialHighlight.new()
	_hint_node.name = "HintHighlight"
	_hint_node.visible = false
	add_child(_hint_node)


func load_level(data: LevelData) -> void:
	level_data = data
	is_solved = false
	interaction_locked = false
	interaction_restricted_to = null
	clear_highlight()
	clear_hint_cell()
	last_tap_cell = Vector2i(-1, -1)
	last_tap_accepted = false
	last_tap_rejection_reason = ""
	tile_orientations.clear()
	_orientable_nodes.clear()
	_target_nodes.clear()
	_switch_nodes.clear()
	_hazard_nodes.clear()
	_gate_nodes.clear()
	_gate_id_by_position.clear()
	_receiver_nodes.clear()
	_remote_emitter_nodes.clear()
	_remote_emitter_link_id_by_position.clear()
	_prism_positions.clear()
	_fusion_nodes.clear()
	_selector_nodes.clear()
	_filter_positions.clear()
	_last_result = {}

	for child in _tiles_root.get_children():
		child.queue_free()
	for child in _background_root.get_children():
		child.queue_free()

	for y in range(level_data.grid_height):
		for x in range(level_data.grid_width):
			var cell_bg := TextureRect.new()
			# Era 2: shares TileVisual's single active_cell_background
			# source of truth (set by game.gd before load_level() is
			# called) so this bare-cell layer and every tile's own
			# drawn background always agree - see ERA_2_DESIGN.md.
			cell_bg.texture = TileVisual.active_cell_background
			cell_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cell_bg.stretch_mode = TextureRect.STRETCH_SCALE
			cell_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell_bg.set_meta("grid_position", Vector2i(x, y))
			_background_root.add_child(cell_bg)

	for tile in level_data.tiles:
		match tile.tile_type:
			GridTypes.TileType.EMITTER:
				var node: EmitterTile = EMITTER_SCENE.instantiate()
				node.grid_position = tile.position
				node.direction = tile.direction
				node.beam_color = tile.color
				_tiles_root.add_child(node)

			GridTypes.TileType.MIRROR:
				var node: MirrorTile = MIRROR_SCENE.instantiate()
				node.grid_position = tile.position
				node.orientation = tile.mirror_orientation
				node.rotatable = tile.rotatable
				node.tile_clicked.connect(_on_orientable_tile_clicked)
				_tiles_root.add_child(node)
				tile_orientations[tile.position] = tile.mirror_orientation
				_orientable_nodes[tile.position] = node

			GridTypes.TileType.SPLITTER:
				var node: SplitterTile = SPLITTER_SCENE.instantiate()
				node.grid_position = tile.position
				node.orientation = tile.mirror_orientation
				node.rotatable = tile.rotatable
				node.tile_clicked.connect(_on_orientable_tile_clicked)
				_tiles_root.add_child(node)
				tile_orientations[tile.position] = tile.mirror_orientation
				_orientable_nodes[tile.position] = node

			GridTypes.TileType.TARGET:
				var node: TargetTile = TARGET_SCENE.instantiate()
				node.grid_position = tile.position
				node.required_color = tile.color
				node.required = tile.required
				_tiles_root.add_child(node)
				_target_nodes[tile.position] = node

			GridTypes.TileType.BLOCKER:
				var node: BlockerTile = BLOCKER_SCENE.instantiate()
				node.grid_position = tile.position
				_tiles_root.add_child(node)

			GridTypes.TileType.FILTER:
				var node: FilterTile = FILTER_SCENE.instantiate()
				node.grid_position = tile.position
				node.output_color = tile.color
				_tiles_root.add_child(node)
				_filter_positions[tile.position] = true

			GridTypes.TileType.PORTAL:
				var node: PortalTile = PORTAL_SCENE.instantiate()
				node.grid_position = tile.position
				node.pair_id = tile.pair_id
				_tiles_root.add_child(node)

			GridTypes.TileType.SWITCH:
				var node: SwitchTile = SWITCH_SCENE.instantiate()
				node.grid_position = tile.position
				_tiles_root.add_child(node)
				_switch_nodes[tile.position] = node

			GridTypes.TileType.GATE:
				var node: GateTile = GATE_SCENE.instantiate()
				node.grid_position = tile.position
				node.is_open = tile.initial_open_state
				_tiles_root.add_child(node)
				_gate_nodes[tile.position] = node
				_gate_id_by_position[tile.position] = tile.gate_id

			GridTypes.TileType.HAZARD:
				var node: HazardTile = HAZARD_SCENE.instantiate()
				node.grid_position = tile.position
				_tiles_root.add_child(node)
				_hazard_nodes[tile.position] = node

			GridTypes.TileType.PRISM:
				var node: PrismTile = PRISM_SCENE.instantiate()
				node.grid_position = tile.position
				_tiles_root.add_child(node)
				_prism_positions[tile.position] = true

			GridTypes.TileType.ONE_WAY_REFLECTOR:
				var node: OneWayReflectorTile = ONE_WAY_REFLECTOR_SCENE.instantiate()
				node.grid_position = tile.position
				node.orientation = tile.mirror_orientation
				node.rotatable = tile.rotatable
				node.tile_clicked.connect(_on_orientable_tile_clicked)
				_tiles_root.add_child(node)
				tile_orientations[tile.position] = tile.mirror_orientation
				_orientable_nodes[tile.position] = node

			GridTypes.TileType.FUSION:
				var node: FusionTile = FUSION_SCENE.instantiate()
				node.grid_position = tile.position
				node.orientation = tile.direction
				node.rotatable = tile.rotatable
				node.tile_clicked.connect(_on_orientable_tile_clicked)
				_tiles_root.add_child(node)
				tile_orientations[tile.position] = tile.direction
				_orientable_nodes[tile.position] = node
				_fusion_nodes[tile.position] = node

			GridTypes.TileType.SPLITTER_SELECTOR:
				var node: SplitterSelectorTile = SPLITTER_SELECTOR_SCENE.instantiate()
				node.grid_position = tile.position
				node.orientation = tile.direction
				node.rotatable = tile.rotatable
				node.tile_clicked.connect(_on_orientable_tile_clicked)
				_tiles_root.add_child(node)
				tile_orientations[tile.position] = tile.direction
				_orientable_nodes[tile.position] = node
				_selector_nodes[tile.position] = node

			GridTypes.TileType.BEAM_RECEIVER:
				var node: BeamReceiverTile = BEAM_RECEIVER_SCENE.instantiate()
				node.grid_position = tile.position
				_tiles_root.add_child(node)
				_receiver_nodes[tile.position] = node

			GridTypes.TileType.REMOTE_EMITTER:
				var node: RemoteEmitterTile = REMOTE_EMITTER_SCENE.instantiate()
				node.grid_position = tile.position
				node.direction = tile.direction
				node.beam_color = tile.color
				_tiles_root.add_child(node)
				_remote_emitter_nodes[tile.position] = node
				_remote_emitter_link_id_by_position[tile.position] = tile.link_id

	_recalculate_layout()
	_simulate_and_draw()


func reset_level() -> void:
	if level_data != null:
		load_level(level_data)


## Development-only diagnostic (never called from any player-facing UI -
## see CLAUDE.md's rectangular-grid rule "Part 16"). Reports the exact
## numbers the current layout pass computed, so a future pass choosing
## row/column counts for the campaign re-layout can check a candidate
## shape's resulting cell size and space utilization without eyeballing
## a screenshot. Safe to call any time after a level has been loaded at
## least once; returns an empty Dictionary before that (cell_size is
## still its 64.0 placeholder default).
func get_layout_metrics() -> Dictionary:
	if level_data == null:
		return {}
	var available := Vector2(
		maxf(size.x - GRID_SAFETY_MARGIN * 2.0, 0.0),
		maxf(size.y - GRID_SAFETY_MARGIN * 2.0, 0.0)
	)
	var grid_width_px: float = cell_size * level_data.grid_width
	var grid_height_px: float = cell_size * level_data.grid_height
	return {
		"columns": level_data.grid_width,
		"rows": level_data.grid_height,
		"cell_size": cell_size,
		"grid_width_px": grid_width_px,
		"grid_height_px": grid_height_px,
		"available_width": available.x,
		"available_height": available.y,
		"width_utilization": (grid_width_px / available.x) if available.x > 0.0 else 0.0,
		"height_utilization": (grid_height_px / available.y) if available.y > 0.0 else 0.0,
	}


## Development-only: formats get_layout_metrics() the way CLAUDE.md's
## rectangular-grid diagnostic example shows it, for a temporary print
## during layout/resolution testing. Never called from shipped UI.
func format_layout_diagnostics() -> String:
	var m := get_layout_metrics()
	if m.is_empty():
		return "GRID <no level loaded>"
	return "GRID %dx%d\nCELL %d\nWIDTH USE %.1f%%\nHEIGHT USE %.1f%%" % [
		m["columns"], m["rows"], int(m["cell_size"]),
		m["width_utilization"] * 100.0, m["height_utilization"] * 100.0,
	]


## Phase 1 (see DECISIONS.md D84): pure board-profile validity check for a
## future procedural generator (or a diagnostic script) to call BEFORE
## committing to a columns x rows shape - never instantiates a scene, takes
## the already-known playable rectangle directly so it's callable headlessly.
## Reuses the exact same cell_size formula _recalculate_layout() uses below,
## so "comfortable" here always matches what the real board would render at.
## Does not enforce MAX_COLUMNS/MIN_COMFORTABLE_CELL_SIZE on existing level
## data - callers decide what to do with an uncomfortable existing level;
## this is a gate for NEW profiles only, per this const's own doc comment.
static func is_board_profile_comfortable(columns: int, rows: int, playable_size: Vector2) -> Dictionary:
	if columns <= 0 or rows <= 0:
		return {"comfortable": false, "cell_size": 0.0, "reason": "non-positive columns/rows"}
	if columns > MAX_COLUMNS:
		return {"comfortable": false, "cell_size": 0.0, "reason": "columns (%d) exceeds MAX_COLUMNS (%d)" % [columns, MAX_COLUMNS]}

	var available := Vector2(
		maxf(playable_size.x - GRID_SAFETY_MARGIN * 2.0, 0.0),
		maxf(playable_size.y - GRID_SAFETY_MARGIN * 2.0, 0.0)
	)
	var candidate_cell_size := floorf(minf(available.x / columns, available.y / rows))
	if candidate_cell_size < MIN_COMFORTABLE_CELL_SIZE:
		return {
			"comfortable": false,
			"cell_size": candidate_cell_size,
			"reason": "cell_size (%d) below MIN_COMFORTABLE_CELL_SIZE (%d)" % [int(candidate_cell_size), int(MIN_COMFORTABLE_CELL_SIZE)],
		}
	return {"comfortable": true, "cell_size": candidate_cell_size, "reason": ""}


func _recalculate_layout() -> void:
	if level_data == null:
		return

	var columns: float = level_data.grid_width
	var rows: float = level_data.grid_height
	if columns <= 0.0 or rows <= 0.0:
		return

	# The playable rectangle is this control's own rect (see the class
	# doc comment above) minus a small safety inset on every side - NOT
	# min(size.x, size.y). A rectangular (columns != rows) board fits
	# each axis against its own available extent independently, so a
	# wide board uses the full width and a tall board uses the full
	# height, rather than both being squeezed to whichever axis is
	# smaller. Tiles stay square because cell_size is a single scalar
	# applied to both axes - see CLAUDE.md's rectangular-grid rule.
	var available := Vector2(
		maxf(size.x - GRID_SAFETY_MARGIN * 2.0, 0.0),
		maxf(size.y - GRID_SAFETY_MARGIN * 2.0, 0.0)
	)
	cell_size = maxf(floorf(minf(available.x / columns, available.y / rows)), 0.0)
	var grid_pixel_size := Vector2(cell_size * columns, cell_size * rows)
	grid_origin = (size - grid_pixel_size) * 0.5

	for child in _tiles_root.get_children():
		if child is TileVisual:
			var tv: TileVisual = child
			tv.cell_size = cell_size
			tv.position = grid_origin + Vector2(tv.grid_position.x, tv.grid_position.y) * cell_size

	for child in _background_root.get_children():
		var bg: TextureRect = child
		var pos: Vector2i = bg.get_meta("grid_position")
		bg.size = Vector2(cell_size, cell_size)
		bg.position = grid_origin + Vector2(pos.x, pos.y) * cell_size

	# In-flight impact bursts were positioned for the old layout; they're
	# ~0.3 s cosmetics, so dropping them is simpler than re-positioning.
	_clear_impact_fx()
	_redraw_beams()
	_position_highlight()
	_position_hint()
	queue_redraw()


func _draw() -> void:
	if level_data == null:
		return
	for x in range(level_data.grid_width + 1):
		var px := grid_origin.x + x * cell_size
		draw_line(Vector2(px, grid_origin.y), Vector2(px, grid_origin.y + cell_size * level_data.grid_height), COLOR_GRID_LINE, 1.0)
	for y in range(level_data.grid_height + 1):
		var py := grid_origin.y + y * cell_size
		draw_line(Vector2(grid_origin.x, py), Vector2(grid_origin.x + cell_size * level_data.grid_width, py), COLOR_GRID_LINE, 1.0)


## Shared click handler for both MirrorTile and SplitterTile - both are
## simple two-state (SLASH/BACKSLASH) rotatable tiles from the player's
## perspective, even though their simulation behavior differs completely.
func _on_orientable_tile_clicked(grid_position: Vector2i) -> void:
	last_tap_cell = grid_position
	var reason := ""
	if is_solved:
		reason = "puzzle already solved"
	elif interaction_locked:
		reason = "input locked"
	elif interaction_restricted_to != null and interaction_restricted_to != grid_position:
		reason = "restricted to %s" % [interaction_restricted_to]
	last_tap_accepted = reason == ""
	last_tap_rejection_reason = reason
	tile_tap_attempted.emit()
	if not last_tap_accepted:
		return
	var current: int = tile_orientations.get(grid_position, GridTypes.MirrorOrientation.SLASH)
	var new_orientation: int = (
		GridTypes.MirrorOrientation.BACKSLASH if current == GridTypes.MirrorOrientation.SLASH
		else GridTypes.MirrorOrientation.SLASH
	)
	if _fusion_nodes.has(grid_position) or _selector_nodes.has(grid_position):
		new_orientation = (int(current) + 1) % 4 # Fusion: 4-state, one clockwise step per tap (D99)
	tile_orientations[grid_position] = new_orientation
	if _orientable_nodes.has(grid_position):
		_orientable_nodes[grid_position].orientation = new_orientation

	# This is the one place a rotation is KNOWN accepted (is_solved/
	# interaction_locked/interaction_restricted_to already passed above) -
	# see AudioManager.play_mirror_rotate()'s own doc comment for why this
	# is the correct call site instead of the tile's own _gui_input
	# (which fires on every tap of a rotatable tile, accepted or not).
	AudioManager.play_mirror_rotate()

	move_made.emit()
	_simulate_and_draw(true)


## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): applies a
## saved mid-level resume state - `saved` is Vector2i -> GridTypes.
## MirrorOrientation (from SaveManager.get_campaign_resume_orientations()).
## Must be called AFTER load_level() so _orientable_nodes is already
## populated from the level's authored initial state. Updates
## tile_orientations and each node's .orientation together, exactly like
## load_level() itself does - never one without the other, which is what
## keeps the drawn glyph and the simulated result in agreement (see
## CLAUDE.md rule 12c / DECISIONS.md D40, the "visual doesn't match
## logical state" bug class). A single _simulate_and_draw() call at the
## end redraws beams/targets/gates to match, and - since it's the exact
## same path a real move uses - correctly re-fires level_solved if the
## restored state happens to already be solved (e.g. resuming right after
## solving but before "Next Level" was pressed). No impact VFX (this is a
## restore, not a player tap).
func restore_orientations(saved: Dictionary) -> void:
	for pos in saved:
		if _orientable_nodes.has(pos):
			tile_orientations[pos] = saved[pos]
			_orientable_nodes[pos].orientation = saved[pos]
	_simulate_and_draw(false)


## Guided-tutorial-only: does an orientable (MIRROR/SPLITTER) tile exist
## at `pos` right now? TutorialManager checks this before locking input
## to a REQUIRE_TILE_TAP step's target - see DECISIONS.md ("Guided
## tutorial system" runtime fix) for why this fail-safe exists.
func has_orientable_tile(pos: Vector2i) -> bool:
	return _orientable_nodes.has(pos)


## Guided-tutorial-only: is the TARGET at `pos` currently activated?
## Read-only - TutorialManager uses this to decide when a
## WAIT_FOR_TARGET_ACTIVATION step is satisfied. Returns false for a
## position with no target (never crashes on a bad tutorial-authored
## position).
func is_target_activated(pos: Vector2i) -> bool:
	return _target_nodes.has(pos) and _target_nodes[pos].activated


## Guided-tutorial-only: shows the pulsing cyan highlight over `pos`,
## and dims the rest of the board around it (TutorialDimOverlay's
## cutout always matches this highlight's rect exactly - see
## _position_highlight()). Both are shown/hidden together so dim state
## can never outlive or precede the highlight it exists to support.
func set_highlight(pos: Vector2i) -> void:
	_highlight_position = pos
	_highlight_node.visible = true
	_dim_overlay.visible = true
	_position_highlight()


## Guided-tutorial-only: hides the highlight and the board dim together.
func clear_highlight() -> void:
	_highlight_position = Vector2i(-1, -1)
	_highlight_node.visible = false
	_dim_overlay.visible = false
	_dim_overlay.clear_cutout()


## Guided-tutorial-only: temporarily hides the highlight/dim without
## forgetting the current highlight position - used while the Pause menu
## (which has its own full-screen dim) is open, so the two dims never
## stack into a near-black board. See resume_tutorial_focus() and
## DECISIONS.md "Guided tutorial visual focus fix".
func suspend_tutorial_focus() -> void:
	_highlight_node.visible = false
	_dim_overlay.visible = false


## Guided-tutorial-only: restores whatever suspend_tutorial_focus()
## hid, but only if a highlight is still actually active (a step
## transition or Reset that happened while suspended may have already
## cleared it via clear_highlight() - _highlight_position is the single
## source of truth for "should a highlight currently be showing").
func resume_tutorial_focus() -> void:
	if _highlight_position == Vector2i(-1, -1):
		return
	_highlight_node.visible = true
	_dim_overlay.visible = true
	_position_highlight()


func _position_highlight() -> void:
	if _highlight_node == null or not _highlight_node.visible:
		return
	_highlight_node.cell_size = cell_size
	var cell_origin := grid_origin + Vector2(_highlight_position.x, _highlight_position.y) * cell_size
	_highlight_node.position = cell_origin - Vector2(TutorialHighlight.FOCUS_PADDING, TutorialHighlight.FOCUS_PADDING)
	if _dim_overlay != null and _dim_overlay.visible:
		_dim_overlay.set_cutout(Rect2(_highlight_node.position, _highlight_node.size))


## `play_impacts` is true only for a player-initiated re-evaluation (a
## mirror/splitter tap): the board is presented silently on load/Reset, and
## the burst marks "your move just redirected the beam here".
func _simulate_and_draw(play_impacts: bool = false) -> void:
	# Snapshot the PREVIOUS pass's node states before they're overwritten
	# below - this is what lets _play_state_transition_audio() tell "just
	# became active" apart from "was already active," per CLAUDE.md's
	# audio transition-detection pattern (see AUDIO_SYSTEM.md). Cheap
	# (board-sized dictionaries) and only ever read, never persisted.
	var previous_targets: Dictionary = {}
	for pos in _target_nodes:
		previous_targets[pos] = _target_nodes[pos].activated
	var previous_switches: Dictionary = {}
	for pos in _switch_nodes:
		previous_switches[pos] = _switch_nodes[pos].activated
	var previous_hazards: Dictionary = {}
	for pos in _hazard_nodes:
		previous_hazards[pos] = _hazard_nodes[pos].triggered
	var previous_gates: Dictionary = {}
	for pos in _gate_nodes:
		previous_gates[pos] = _gate_nodes[pos].is_open
	var previous_receivers: Dictionary = {}
	for pos in _receiver_nodes:
		previous_receivers[pos] = _receiver_nodes[pos].active
	var previous_remote_emitters: Dictionary = {}
	for pos in _remote_emitter_nodes:
		previous_remote_emitters[pos] = _remote_emitter_nodes[pos].active

	_last_result = LaserSystem.simulate_until_stable(level_data, tile_orientations)

	var activated_targets: Array = _last_result["activated_targets"]
	for pos in _target_nodes:
		_target_nodes[pos].activated = activated_targets.has(pos)

	var activated_switch_positions: Array = _last_result["activated_switch_positions"]
	for pos in _switch_nodes:
		_switch_nodes[pos].activated = activated_switch_positions.has(pos)

	var hit_hazard_positions: Array = _last_result["hit_hazard_positions"]
	for pos in _hazard_nodes:
		_hazard_nodes[pos].triggered = hit_hazard_positions.has(pos)

	var gate_states: Dictionary = _last_result["gate_states"]
	for pos in _gate_nodes:
		var gate_id: String = _gate_id_by_position.get(pos, "")
		_gate_nodes[pos].is_open = gate_states.get(gate_id, false)

	var activated_receiver_positions: Array = _last_result["activated_receiver_positions"]
	for pos in _receiver_nodes:
		_receiver_nodes[pos].active = activated_receiver_positions.has(pos)

	var receiver_states: Dictionary = _last_result["receiver_states"]
	for pos in _remote_emitter_nodes:
		var link_id: String = _remote_emitter_link_id_by_position.get(pos, "")
		_remote_emitter_nodes[pos].active = receiver_states.get(link_id, false)

	var fusion_colors: Dictionary = _last_result["fusion_colors"]
	var fusion_sides: Dictionary = _last_result["fusion_input_sides"]
	var previous_fusions: Dictionary = {}
	for pos in _fusion_nodes:
		previous_fusions[pos] = _fusion_nodes[pos].active
		var fnode: FusionTile = _fusion_nodes[pos]
		fnode.active = fusion_colors.has(pos)
		fnode.fused_color = fusion_colors.get(pos, -1)
		var sides_view: Dictionary = {}
		for side in fusion_sides.get(pos, {}):
			sides_view[side] = fusion_sides[pos][side].keys()
		fnode.input_sides = sides_view

	var selector_hits: Dictionary = _last_result["selector_hits"]
	for pos in _selector_nodes:
		var snode: SplitterSelectorTile = _selector_nodes[pos]
		snode.active = selector_hits.has(pos)
		snode.routed_color = selector_hits[pos].keys()[0] if selector_hits.has(pos) else -1

	_redraw_beams()
	if play_impacts:
		_spawn_mirror_impacts()
		_spawn_era2_activation_fx(activated_receiver_positions)
		_play_state_transition_audio(previous_targets, previous_switches, previous_hazards, previous_gates, previous_receivers, previous_remote_emitters, previous_fusions)
		_play_beam_interaction_audio()
	simulation_updated.emit()

	if _last_result["solved"] and not is_solved:
		is_solved = true
		level_solved.emit()
		if play_impacts:
			AudioManager.play_puzzle_solved()


## Audio-only (see AUDIO_SYSTEM.md "Transition-state detection"): plays a
## semantic SFX for every inactive -> active transition this pass produced,
## by comparing the snapshots _simulate_and_draw() took before overwriting
## each node's state against the state it just wrote. Never fires for an
## already-active position holding steady, and - being called only from
## the play_impacts branch above - never fires for level load/restore/
## reset/QA-Next/procedural generation at all (see AudioManager's own
## class doc comment for why that's a structural guarantee, not a
## separate suppression flag).
func _play_state_transition_audio(previous_targets: Dictionary, previous_switches: Dictionary, previous_hazards: Dictionary, previous_gates: Dictionary, previous_receivers: Dictionary, previous_remote_emitters: Dictionary, previous_fusions: Dictionary = {}) -> void:
	# Fusion Phase 1 (D99): an inactive -> active Fusion Node reuses laser_split (no new SFX).
	for pos in _fusion_nodes:
		if _fusion_nodes[pos].active and not previous_fusions.get(pos, false):
			AudioManager.play_laser_split()
	for pos in _target_nodes:
		if _target_nodes[pos].activated and not previous_targets.get(pos, false):
			AudioManager.play_target_activate()
	for pos in _switch_nodes:
		if _switch_nodes[pos].activated and not previous_switches.get(pos, false):
			AudioManager.play_switch_activate()
	for pos in _hazard_nodes:
		if _hazard_nodes[pos].triggered and not previous_hazards.get(pos, false):
			AudioManager.play_hazard_hit()
	for pos in _gate_nodes:
		if _gate_nodes[pos].is_open and not previous_gates.get(pos, false):
			AudioManager.play_gate_open()
	# Era 2 reuse (see AUDIO_SYSTEM.md "Era 2 mapping"): a Beam Receiver hit
	# reuses switch_activate (same "power source hit" shape as a switch); a
	# Remote Emitter becoming active reuses laser_activate (its beam is
	# otherwise identical to a real emitter's - see laser_system.gd).
	for pos in _receiver_nodes:
		if _receiver_nodes[pos].active and not previous_receivers.get(pos, false):
			AudioManager.play_switch_activate()
	for pos in _remote_emitter_nodes:
		if _remote_emitter_nodes[pos].active and not previous_remote_emitters.get(pos, false):
			AudioManager.play_laser_activate()


## Audio-only companion to _spawn_mirror_impacts()/_spawn_era2_activation_fx()
## (deliberately a SEPARATE pass, not a tweak to either - see CLAUDE.md rule
## 14's "adding one is a new pass following the same pattern" spirit,
## applied here to audio instead of VFX). Reads the already-computed
## _last_result beam segments for THIS player move only - never re-runs or
## feeds the simulation. De-dupes by position (and, for portal traversal,
## by the entry/exit pair) so a beam that visits the same mirror/splitter/
## filter/prism/portal twice in one evaluation (a loop-guarded revisit, or
## two separate beam branches crossing the same cell) plays that cell's SFX
## once, not once per visit - see AUDIO_SYSTEM.md "Anti-spam".
func _play_beam_interaction_audio() -> void:
	if _last_result.is_empty():
		return

	var played: Dictionary = {}
	for beam in _last_result["beams"]:
		var segments: Array = beam["segments"]
		for segment in segments:
			for pos in segment:
				if _orientable_nodes.get(pos) is MirrorTile:
					_play_once(played, "mirror|%s" % pos, AudioManager.play_laser_reflect)
				elif _orientable_nodes.get(pos) is OneWayReflectorTile:
					# Era 2: a One-Way Reflector's REFLECTIVE hits are
					# recorded as an ordinary segment-corner point by
					# LaserSystem (pass-through hits record no point at
					# all - see laser_system.gd), so reaching this branch
					# already means a real reflection happened.
					_play_once(played, "one_way_reflector|%s" % pos, AudioManager.play_laser_reflect)
				elif _orientable_nodes.get(pos) is SplitterTile:
					_play_once(played, "splitter|%s" % pos, AudioManager.play_laser_split)
				elif _prism_positions.has(pos):
					# Era 2 reuse (see AUDIO_SYSTEM.md "Era 2 mapping"): a
					# Prism channel split is audibly the same event shape
					# as a Splitter branch.
					_play_once(played, "prism|%s" % pos, AudioManager.play_laser_split)
				elif _filter_positions.has(pos):
					_play_once(played, "filter|%s" % pos, AudioManager.play_filter_pass)

		# Portal traversal: LaserSystem only ever starts a new segment for a
		# portal jump (see laser_system.gd - grid edges/blockers/hazards/
		# closed gates all break WITHOUT appending a new segment), so a
		# segment boundary here always means "segment i's beam entered a
		# portal at its last point and segment i+1 is its exit." No
		# LaserSystem changes, no added delay - both sounds play
		# immediately, one at the entry cell and one at the exit cell.
		for i in range(segments.size() - 1):
			var entry_segment: Array = segments[i]
			var exit_segment: Array = segments[i + 1]
			if entry_segment.is_empty() or exit_segment.is_empty():
				continue
			var entry_pos: Vector2i = entry_segment[-1]
			var exit_pos: Vector2i = exit_segment[0]
			_play_once(played, "portal_enter|%s" % entry_pos, AudioManager.play_portal_enter)
			_play_once(played, "portal_exit|%s" % exit_pos, AudioManager.play_portal_exit)


func _play_once(played: Dictionary, key: String, play_fn: Callable) -> void:
	if played.has(key):
		return
	played[key] = true
	play_fn.call()


## Rebuilds the beam Line2D pairs from _last_result's per-beam segments.
## Each segment (a portal transit starts a new one) gets its own Line2D
## pair so a portal jump never draws a straight line across the map - see
## ARCHITECTURE.md "Laser visualization".
func _redraw_beams() -> void:
	for pair in _beam_line_pool:
		pair["glow"].queue_free()
		pair["core"].queue_free()
	_beam_line_pool.clear()

	if _last_result.is_empty():
		return

	for beam in _last_result["beams"]:
		var render_color: Color = GridTypes.beam_color_to_render_color(beam["color"])
		for segment in beam["segments"]:
			if segment.size() < 2:
				continue
			var glow := Line2D.new()
			glow.width = BEAM_GLOW_WIDTH
			glow.default_color = Color(render_color.r, render_color.g, render_color.b, BEAM_GLOW_ALPHA)
			glow.joint_mode = Line2D.LINE_JOINT_ROUND
			glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
			glow.end_cap_mode = Line2D.LINE_CAP_ROUND
			glow.antialiased = true
			var core := Line2D.new()
			core.width = BEAM_CORE_WIDTH
			core.default_color = render_color.lerp(Color.WHITE, BEAM_CORE_BRIGHTEN)
			core.joint_mode = Line2D.LINE_JOINT_ROUND
			core.begin_cap_mode = Line2D.LINE_CAP_ROUND
			core.end_cap_mode = Line2D.LINE_CAP_ROUND
			core.antialiased = true

			for grid_point in segment:
				var pixel: Vector2 = grid_origin + (Vector2(grid_point.x, grid_point.y) + Vector2(0.5, 0.5)) * cell_size
				glow.add_point(pixel)
				core.add_point(pixel)

			_beams_root.add_child(glow)
			_beams_root.add_child(core)
			_beam_line_pool.append({"glow": glow, "core": core})


## Spawns one short LaserMirrorImpactFX per actual mirror reflection in the
## ALREADY-computed _last_result - no extra simulation. Every mirror a beam
## reflects off appears as a segment corner (LaserSystem records it), so the
## corner's neighbors give the outgoing direction and the beam's color is
## the same one _redraw_beams() draws. Only MirrorTile (rotatable or fixed)
## qualifies; splitters pass the beam straight through and are excluded.
## Presentation only: reads _last_result, never writes gameplay state.
func _spawn_mirror_impacts() -> void:
	_clear_impact_fx()
	if _last_result.is_empty() or cell_size < IMPACT_FX_MIN_CELL_SIZE:
		return

	var spawned: Dictionary = {} # de-dupes an identical reflection reached twice in one evaluation
	for beam in _last_result["beams"]:
		var color: int = beam["color"]
		for segment in beam["segments"]:
			for i in range(segment.size()):
				var pos: Vector2i = segment[i]
				if not (_orientable_nodes.get(pos) is MirrorTile):
					continue

				var incoming := Vector2i.ZERO
				if i > 0:
					incoming = Vector2i((pos - segment[i - 1]).sign())
				var outgoing := Vector2i.ZERO
				if i < segment.size() - 1:
					outgoing = Vector2i((segment[i + 1] - pos).sign())

				var key := "%d,%d|%d,%d|%d,%d|%d" % [pos.x, pos.y, incoming.x, incoming.y, outgoing.x, outgoing.y, color]
				if spawned.has(key):
					continue
				spawned[key] = true
				if _impact_root.get_child_count() >= IMPACT_FX_MAX_COUNT:
					return

				var fx: LaserMirrorImpactFX = MIRROR_IMPACT_FX_SCENE.instantiate()
				fx.cell_size = cell_size
				fx.beam_color = color as GridTypes.BeamColor
				fx.burst_direction = Vector2(outgoing)
				# Same cell-center conversion _redraw_beams() uses for beam points.
				fx.position = grid_origin + (Vector2(pos.x, pos.y) + Vector2(0.5, 0.5)) * cell_size
				_impact_root.add_child(fx)


## Era 2: spawns Era2ActivationFX for every Prism/reflective One-Way
## Reflector cell a beam actually touched this evaluation, every Beam
## Receiver hit, and every currently-active Remote Emitter - same
## presentation-only contract as _spawn_mirror_impacts() (player taps
## only, reads the ALREADY-computed _last_result, no extra simulation),
## sharing the same _impact_root container and IMPACT_FX_MAX_COUNT cap.
## A One-Way Reflector's pass-through hits never appear here for free:
## LaserSystem only ever appends a segment point for its REFLECTIVE hits
## (see laser_system.gd), so this position-in-a-segment check already
## excludes pass-through cells without any extra logic.
func _spawn_era2_activation_fx(activated_receiver_positions: Array) -> void:
	if _last_result.is_empty() or cell_size < IMPACT_FX_MIN_CELL_SIZE:
		return

	var spawned: Dictionary = {}

	for beam in _last_result["beams"]:
		for segment in beam["segments"]:
			for pos in segment:
				if _prism_positions.has(pos):
					_try_spawn_era2_fx(spawned, pos, Era2ActivationFX.Kind.PRISM, GridTypes.BeamColor.WHITE)
				elif _orientable_nodes.get(pos) is OneWayReflectorTile:
					_try_spawn_era2_fx(spawned, pos, Era2ActivationFX.Kind.ONE_WAY_REFLECTOR, GridTypes.BeamColor.WHITE)

	for pos in activated_receiver_positions:
		_try_spawn_era2_fx(spawned, pos, Era2ActivationFX.Kind.RECEIVER, GridTypes.BeamColor.WHITE)

	for pos in _remote_emitter_nodes:
		var node: RemoteEmitterTile = _remote_emitter_nodes[pos]
		if node.active:
			_try_spawn_era2_fx(spawned, pos, Era2ActivationFX.Kind.REMOTE_EMITTER, node.beam_color)


func _try_spawn_era2_fx(spawned: Dictionary, pos: Vector2i, kind: Era2ActivationFX.Kind, color: GridTypes.BeamColor) -> void:
	var key := "%d,%d|%d" % [pos.x, pos.y, kind]
	if spawned.has(key):
		return
	spawned[key] = true
	if _impact_root.get_child_count() >= IMPACT_FX_MAX_COUNT:
		return

	var fx: Era2ActivationFX = ERA2_ACTIVATION_FX_SCENE.instantiate()
	fx.cell_size = cell_size
	fx.kind = kind
	fx.beam_color = color
	fx.position = grid_origin + (Vector2(pos.x, pos.y) + Vector2(0.5, 0.5)) * cell_size
	_impact_root.add_child(fx)


## Immediate free (not queue_free) so a fast tap sequence can never leave
## last evaluation's bursts stacked underneath this one's.
func _clear_impact_fx() -> void:
	if _impact_root == null:
		return
	for child in _impact_root.get_children():
		_impact_root.remove_child(child)
		child.free()


## Global Hint System (D97): pulsing ring on ONE cell, no board dim, input-transparent.
func show_hint_cell(pos: Vector2i) -> void:
	_hint_position = pos
	_hint_node.visible = true
	_position_hint()


func clear_hint_cell() -> void:
	_hint_position = Vector2i(-1, -1)
	if _hint_node != null:
		_hint_node.visible = false


func get_hint_cell() -> Vector2i:
	return _hint_position


func _position_hint() -> void:
	if _hint_node == null or not _hint_node.visible:
		return
	_hint_node.cell_size = cell_size
	_hint_node.position = grid_origin + Vector2(_hint_position.x, _hint_position.y) * cell_size - Vector2(TutorialHighlight.FOCUS_PADDING, TutorialHighlight.FOCUS_PADDING)


## Read-only view of the last simulation (HintManager ranks candidates by the beams).
func get_last_simulation() -> Dictionary:
	return _last_result
