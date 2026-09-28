class_name MenuGameplayPreview
extends PanelContainer
## Main Menu live gameplay preview (Main Menu Redesign pass, 2026-09-28).
## A fully isolated, looping demonstration of BeamShift's laser-routing
## puzzle: loads Campaign Level 3 ("Signal Path") directly into its own
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

const PREVIEW_LEVEL_PATH := "res://levels/campaign/stage_01/level_03.gd"

## Main Menu Mobile Layout Correction (2026-09-28): PreviewViewport's `size` (menu_gameplay_preview.tscn)
## is 700x840 (140px/cell) specifically to match Level 3's grid_width=5/grid_height=6 (5:6) aspect exactly -
## GridManager._recalculate_layout() then fills nearly the whole viewport instead of letterboxing a
## non-square board inside a square viewport. If PREVIEW_LEVEL_PATH is ever changed, re-match
## PreviewViewport's size AND main_menu.gd's PREVIEW_BOARD_ASPECT to the new level's grid_width/grid_height.

## Solver-authored fix for the two mirrors that start wrong - see
## levels/hint_solutions.json key "c3": [[2,0,1],[2,3,1]] (x, y,
## MirrorOrientation). The level's third mirror, at (4,3), already starts
## correctly oriented per its own developer_notes and is deliberately
## never touched here - not every piece needs touching.
const _MOVE_1_POS := Vector2i(2, 0)
const _MOVE_2_POS := Vector2i(2, 3)

const _STEP_DELAY := 1.1
const _SOLVED_HOLD := 2.0
const _RESET_DELAY := 0.6

@onready var _grid: GridManager = %PreviewGrid


func _ready() -> void:
	var level_data := LevelManager.load_level_from_path(PREVIEW_LEVEL_PATH)
	if level_data == null:
		push_warning("MenuGameplayPreview: failed to load preview level, preview stays empty")
		return
	_grid.load_level(level_data)
	_run_sequence()


func _run_sequence() -> void:
	while true:
		if not await _wait(_STEP_DELAY):
			return
		_grid.restore_orientations({_MOVE_1_POS: GridTypes.MirrorOrientation.BACKSLASH})

		if not await _wait(_STEP_DELAY):
			return
		_grid.restore_orientations({_MOVE_2_POS: GridTypes.MirrorOrientation.BACKSLASH})

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
