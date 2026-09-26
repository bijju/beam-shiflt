class_name TutorialManager
extends RefCounted
## Drives the guided-tutorial step machine and is the single, central
## place that applies forced-interaction/highlight rules to the active
## GridManager - see CLAUDE.md ("Guided tutorial system") and
## DECISIONS.md for why this lives here instead of scattered per-level
## checks. Campaign/editor-playtest gameplay never touches this class.
##
## Deliberately NOT an autoload - CLAUDE.md rule 6 ("autoloads are earned,
## not default") only sanctions SaveManager/LevelManager/GameManager, and
## nothing here needs to survive a scene change: all step-machine state
## is scoped to one tutorial play session. game.gd owns one instance as
## a plain member (`var _tutorial := TutorialManager.new()`), exactly
## like it already owns other per-session state.
##
## Lifecycle: game.gd calls start(tutorial_id) once when entering
## tutorial mode, sets active_grid to its %PuzzleGrid, connects
## step_changed/tutorial_finished, then calls advance() to begin step 0.
## From then on, game.gd forwards GridManager's move_made/level_solved
## signals to notify_move_made()/notify_puzzle_solved() and this class
## decides whether/how to advance - no tutorial-specific logic lives in
## game.gd itself beyond that forwarding.

signal step_changed(step: TutorialStepData)
signal tutorial_finished

var current_tutorial_id: int = 1
var current_step_index: int = -1
var current_level: TutorialLevelData = null

## Set by game.gd to the live %PuzzleGrid the instant tutorial mode
## begins; cleared when the tutorial scene tears down. All forced-
## interaction/highlight calls below are no-ops if this is null (should
## never happen in practice, but avoids a crash if a step fires before
## the grid is wired up).
var active_grid: GridManager = null


## Loads the tutorial's LevelData (tiles + steps) and resets step state.
## Does NOT advance to step 0 - call advance() once the caller has
## finished wiring signals/active_grid, so the first step_changed signal
## is never missed.
func start(tutorial_id: int) -> TutorialLevelData:
	current_tutorial_id = tutorial_id
	current_level = LevelManager.get_tutorial_level(tutorial_id)
	current_step_index = -1
	return current_level


## Re-enters the current tutorial at step 0 with a freshly-reloaded
## board - used by "Restart Tutorial" (Pause menu / completion popup's
## Retry). Caller must reload the grid (grid.load_level(...)) and call
## advance() again afterward, same as start().
func restart() -> void:
	current_step_index = -1


func get_current_step() -> TutorialStepData:
	if current_level == null or current_step_index < 0 or current_step_index >= current_level.steps.size():
		return null
	return current_level.steps[current_step_index]


func advance() -> void:
	current_step_index += 1
	var step := get_current_step()
	if step == null:
		_clear_grid_restrictions()
		tutorial_finished.emit()
		return
	_apply_step_to_grid(step)
	step_changed.emit(step)


## Called by game.gd whenever GridManager.move_made fires during a
## tutorial. move_made fires BEFORE simulation runs (see GridManager), so
## this is only safe for a REQUIRE_TILE_TAP step - it's satisfied by
## definition the instant it fires at all (interaction_restricted_to
## guarantees only the required tile could have produced this signal).
## WAIT_FOR_TARGET_ACTIVATION needs post-simulation state - see
## notify_simulation_updated() below, not this function.
func notify_move_made() -> void:
	var step := get_current_step()
	if step != null and step.step_type == TutorialStepData.StepType.REQUIRE_TILE_TAP:
		advance()


## Called by game.gd whenever GridManager.simulation_updated fires -
## AFTER target states are recomputed, unlike move_made. A
## WAIT_FOR_TARGET_ACTIVATION step re-checks its watched target every
## time this fires (including the initial simulate_and_draw() a fresh
## load_level() runs, which is harmless - nothing's activated yet).
func notify_simulation_updated() -> void:
	var step := get_current_step()
	if step == null:
		return
	if step.step_type == TutorialStepData.StepType.WAIT_FOR_TARGET_ACTIVATION:
		if active_grid != null and active_grid.is_target_activated(step.target_position):
			advance()


## Called by game.gd whenever GridManager.level_solved fires during a
## tutorial. Only a WAIT_FOR_PUZZLE_SOLVED step reacts - every tutorial's
## final step must be this type, so this is also what ends the tutorial
## (advance() past the last step emits tutorial_finished).
func notify_puzzle_solved() -> void:
	var step := get_current_step()
	if step != null and step.step_type == TutorialStepData.StepType.WAIT_FOR_PUZZLE_SOLVED:
		advance()


func _apply_step_to_grid(step: TutorialStepData) -> void:
	if active_grid == null:
		return

	if step.highlight_position != Vector2i(-1, -1):
		active_grid.set_highlight(step.highlight_position)
	else:
		active_grid.clear_highlight()

	match step.step_type:
		TutorialStepData.StepType.MESSAGE:
			active_grid.interaction_locked = true
			active_grid.interaction_restricted_to = null
		TutorialStepData.StepType.REQUIRE_TILE_TAP:
			# Fail-safe (see DECISIONS.md "Guided tutorial system" runtime
			# fix, Part 7): a REQUIRE_TILE_TAP step must never lock input
			# to a tile that doesn't actually exist - that would softlock
			# the tutorial silently. If the authored target_position has
			# no orientable (MIRROR/SPLITTER) tile, log a loud, impossible-
			# to-miss error and leave input UNRESTRICTED instead of locked,
			# so the tutorial stays playable (if not correct) rather than
			# stuck, and the bug is visibly reported during testing.
			# Second fail-safe (click input fix): the highlighted cell and
			# the accepted cell must always be identical - a step authored
			# with mismatched highlight_position/target_position would show
			# the player one tile while only accepting taps on another,
			# which reads exactly like "the highlighted tile can't be
			# clicked." Every TutorialStepData.require_tap() call sets both
			# to the same value, so this should be structurally impossible
			# today, but this checks it directly rather than trusting that.
			if step.highlight_position != step.target_position:
				push_error("TutorialManager: REQUIRE_TILE_TAP step's highlight_position %s does not match target_position %s in tutorial %d step %d ('%s') - the player would see one tile highlighted but only another accepted." % [step.highlight_position, step.target_position, current_tutorial_id, current_step_index, step.text])
			if active_grid.has_orientable_tile(step.target_position):
				active_grid.interaction_locked = false
				active_grid.interaction_restricted_to = step.target_position
			else:
				push_error("TutorialManager: REQUIRE_TILE_TAP step targets %s, which has no orientable tile in tutorial %d step %d ('%s') - leaving input unrestricted instead of softlocking." % [step.target_position, current_tutorial_id, current_step_index, step.text])
				active_grid.interaction_locked = false
				active_grid.interaction_restricted_to = null
		TutorialStepData.StepType.WAIT_FOR_TARGET_ACTIVATION, TutorialStepData.StepType.WAIT_FOR_PUZZLE_SOLVED:
			active_grid.interaction_locked = step.lock_all_input
			active_grid.interaction_restricted_to = null


func _clear_grid_restrictions() -> void:
	if active_grid == null:
		return
	active_grid.interaction_locked = false
	active_grid.interaction_restricted_to = null
	active_grid.clear_highlight()
