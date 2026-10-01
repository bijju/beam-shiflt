class_name MenuGameplayPreview
extends PanelContainer
## Main Menu live gameplay preview (Main Menu Redesign pass, 2026-09-28).
## A fully isolated, looping demonstration of BeamShift's laser-routing
## puzzle: builds a dedicated preview board (see _build_preview_level) directly into its own
## GridManager instance inside a SubViewport, drives it through a
## deterministic scripted sequence, and resets. Presentation-only:
## - never touches SaveManager/GameManager/LevelManager progression state.
##   GridManager itself never writes save data (see CLAUDE.md rules 2/4);
##   the two calls used below - restore_orientations()/reset_level() - are
##   GridManager's own public API, the exact same calls Continue's
##   mid-level resume and the in-game Reset button already use.
## - never plays gameplay SFX. Both calls route through
##   _simulate_and_draw(false); per AUDIO_SYSTEM.md's transition-detection
##   gate, audio only ever plays when play_impacts=true (a real accepted
##   player tap), which this preview never sets.
## - pauses for free when InternetManager pauses the SceneTree: the
##   awaited timers below are ordinary SceneTreeTimers, which stop
##   ticking while get_tree().paused is true and resume exactly where
##   they left off - no extra pause/resume code needed here.
## - cannot duplicate across menu visits: GameManager navigates via
##   change_scene_to_file(), which frees the entire previous scene tree
##   (this node included) before the new Main Menu is built, so a fresh
##   instance (and a fresh SubViewport) is created every time.

## The board is a dedicated, code-built preview (never a real level): the Level 3 "Signal Path" staircase
## (emitter -> A -> B -> C -> target, solved by flipping A and B to BACKSLASH) stretched over however many square
## cells fit the frame, so the board fills the blue frame instead of floating in it. Filler cells are plain floor.
const _MIN_CELL := 90.0
const _MAX_CELL := 130.0
const _FRAME_PAD := 16.0 ## GridManager.GRID_SAFETY_MARGIN on both sides
const _MIN_COLS := 4
const _MIN_ROWS := 3

var _grid_dims := Vector2i.ZERO
var _move_1_pos := Vector2i.ZERO
var _move_2_pos := Vector2i.ZERO

const _STEP_DELAY := 1.1
const _SOLVED_HOLD := 2.0
const _RESET_DELAY := 0.6

@onready var _grid: GridManager = %PreviewGrid


func _ready() -> void:
	# The container only has its real size after the first layout pass.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_rebuild()
	# Main Menu's layout settles over a few frames/resizes; re-pick the grid whenever the frame size changes.
	%PreviewViewportContainer.resized.connect(_rebuild)
	_run_sequence()


func _rebuild() -> void:
	var level_data := _build_preview_level(%PreviewViewportContainer.size)
	if level_data.grid_width == _grid_dims.x and level_data.grid_height == _grid_dims.y:
		return
	_grid_dims = Vector2i(level_data.grid_width, level_data.grid_height)
	_grid.load_level(level_data)


func _build_preview_level(frame: Vector2) -> LevelData:
	var avail := Vector2(maxf(frame.x - _FRAME_PAD, 1.0), maxf(frame.y - _FRAME_PAD, 1.0))
	# Pick the square-cell grid that covers the most of the frame while keeping cells comfortably large.
	var rows := _MIN_ROWS
	var cols := _MIN_COLS
	var best := -1.0
	for r in range(_MIN_ROWS, 9):
		for c in range(_MIN_COLS, 13):
			var cell := minf(avail.x / c, avail.y / r)
			if cell < _MIN_CELL or cell > _MAX_CELL:
				continue
			var coverage := float(c * r) * cell * cell
			if coverage > best:
				best = coverage
				rows = r
				cols = c
	var level := LevelData.new()
	level.display_name = "Menu Preview"
	level.grid_width = cols
	level.grid_height = rows
	level.optimal_moves = 2
	var col_a := maxi(1, cols / 2)
	var row_b := maxi(1, (rows - 1) / 2)
	_move_1_pos = Vector2i(col_a, 0)
	_move_2_pos = Vector2i(col_a, row_b)
	level.tiles = [
		TilePlacement.make_emitter(Vector2i(0, 0), GridTypes.Direction.RIGHT),
		TilePlacement.make_mirror(_move_1_pos, GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(_move_2_pos, GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_mirror(Vector2i(cols - 1, row_b), GridTypes.MirrorOrientation.BACKSLASH),
		TilePlacement.make_target(Vector2i(cols - 1, rows - 1)),
	]
	return level


func _run_sequence() -> void:
	while true:
		if not await _wait(_STEP_DELAY):
			return
		_grid.restore_orientations({_move_1_pos: GridTypes.MirrorOrientation.BACKSLASH})

		if not await _wait(_STEP_DELAY):
			return
		_grid.restore_orientations({_move_2_pos: GridTypes.MirrorOrientation.BACKSLASH})

		if not await _wait(_SOLVED_HOLD):
			return
		_grid.reset_level()

		if not await _wait(_RESET_DELAY):
			return


## Awaits `seconds` and reports whether this node is still alive and in
## the tree afterward, so _run_sequence() can bail out cleanly instead of
## touching a freed GridManager if Main Menu was left mid-wait.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return is_instance_valid(self) and is_inside_tree()
