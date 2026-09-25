class_name TutorialStepData
extends Resource
## Data-only description of one step in a guided tutorial level. A
## TutorialLevelData's `steps` array is driven entirely by these -
## TutorialManager is the only code that interprets them, so authoring a
## new tutorial never requires writing new step-machine logic (see
## ARCHITECTURE.md "Guided tutorial system").
##
## `step_type` decides what makes the step ADVANCE (the player action
## TutorialManager is waiting for). `text`/`highlight_position` are
## independent of type - any step can show a message and/or highlight a
## cell. This intentionally collapses the brief's full step-type
## vocabulary (MESSAGE, SHOW_TARGET, TAP_TO_CONTINUE, REQUIRE_TILE_TAP,
## REQUIRE_TILE_ROTATION, WAIT_FOR_BEAM_RESULT, WAIT_FOR_TARGET_
## ACTIVATION, WAIT_FOR_PUZZLE_SOLVED) into 4 orthogonal advancement
## conditions plus optional highlight/text, rather than one enum value
## per combination - see DECISIONS.md for why.

enum StepType {
	## Shows `text` (optionally with a highlight) and waits for the
	## player to press the tutorial panel's "TAP TO CONTINUE" button.
	## Covers the brief's MESSAGE/SHOW_TARGET/TAP_TO_CONTINUE step types -
	## all three are "informational, player taps to proceed."
	MESSAGE,
	## Locks puzzle input to exactly `target_position`'s tile (a
	## MIRROR/SPLITTER) - every other tile tap is ignored. Advances the
	## instant that one tile is successfully rotated (GridManager's
	## `move_made` signal). Covers REQUIRE_TILE_TAP/REQUIRE_TILE_ROTATION.
	REQUIRE_TILE_TAP,
	## Leaves normal (or fully locked, see `lock_all_input`) puzzle input
	## active and advances the moment `target_position`'s TARGET tile
	## becomes activated. Covers WAIT_FOR_TARGET_ACTIVATION/
	## WAIT_FOR_BEAM_RESULT.
	WAIT_FOR_TARGET_ACTIVATION,
	## Leaves puzzle input active (or locked, see `lock_all_input`) and
	## advances the moment the whole level is solved - always the step
	## that ends a tutorial. Covers WAIT_FOR_PUZZLE_SOLVED.
	WAIT_FOR_PUZZLE_SOLVED,
}

@export var step_type: StepType = StepType.MESSAGE
@export var text: String = ""

## Cell to pulse-highlight during this step. Vector2i(-1, -1) = no
## highlight. Independent of step_type - a REQUIRE_TILE_TAP step almost
## always highlights `target_position`, but a MESSAGE step can highlight
## any cell purely to draw the eye (e.g. "this is the emitter").
@export var highlight_position: Vector2i = Vector2i(-1, -1)

## REQUIRE_TILE_TAP: the exact MIRROR/SPLITTER cell the player must tap -
## every other orientable tile is rejected while this step is active.
## WAIT_FOR_TARGET_ACTIVATION: the TARGET cell being watched.
## Unused by MESSAGE/WAIT_FOR_PUZZLE_SOLVED.
@export var target_position: Vector2i = Vector2i(-1, -1)

## WAIT_FOR_TARGET_ACTIVATION/WAIT_FOR_PUZZLE_SOLVED only: true locks all
## puzzle-tile taps while waiting (a pure "watch" step); false (default)
## leaves the player free to keep experimenting until the watched
## condition is met - used for T02+'s "less hand-holding" steps.
@export var lock_all_input: bool = false


static func message(text_: String, highlight_pos: Vector2i = Vector2i(-1, -1)) -> TutorialStepData:
	var s := TutorialStepData.new()
	s.step_type = StepType.MESSAGE
	s.text = text_
	s.highlight_position = highlight_pos
	return s


static func require_tap(pos: Vector2i, text_: String) -> TutorialStepData:
	var s := TutorialStepData.new()
	s.step_type = StepType.REQUIRE_TILE_TAP
	s.text = text_
	s.target_position = pos
	s.highlight_position = pos
	return s


static func wait_for_target(pos: Vector2i, text_: String, locked: bool = false) -> TutorialStepData:
	var s := TutorialStepData.new()
	s.step_type = StepType.WAIT_FOR_TARGET_ACTIVATION
	s.text = text_
	s.target_position = pos
	s.lock_all_input = locked
	return s


static func wait_for_solved(text_: String = "", locked: bool = false) -> TutorialStepData:
	var s := TutorialStepData.new()
	s.step_type = StepType.WAIT_FOR_PUZZLE_SOLVED
	s.text = text_
	s.lock_all_input = locked
	return s
