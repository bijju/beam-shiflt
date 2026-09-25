extends Node
## Autoload: GameManager
## Handles scene navigation and carries the currently-selected level id
## across the Level Select -> Game scene transition.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"
const TUTORIAL_SELECT_SCENE := "res://scenes/ui/tutorial_select.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_menu.tscn"
const GAME_SCENE := "res://scenes/gameplay/game.tscn"
const LEVEL_EDITOR_SCENE := "res://tools/level_editor/level_editor.tscn"

var current_level_id: int = 1

## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): true only
## when the current gameplay session was entered through the QA/dev
## Level Select screen, false for a normal PLAY/CONTINUE session. Set
## exclusively by start_level()'s from_level_select param. Two things
## branch on this: (1) Back/Pause's "Level Select" button and the Level
## Complete popup's own "Level Select" button go to Level Select for a
## true session, Main Menu for a false one - a normal player should never
## land on Level Select even by backing out; (2) game.gd's campaign_
## resume_* persistence is skipped entirely for a true session, so a QA
## tester jumping around arbitrary levels can never overwrite the real
## player's "current progression" resume pointer.
var entered_via_level_select: bool = false

## Guided-tutorial hand-off, mirroring is_editor_playtest below exactly.
## When true, game.gd loads TUTORIAL_LEVEL_PATHS[current_tutorial_id]
## through TutorialManager instead of a campaign level, and routes
## completion/back navigation to the tutorial UI instead of Campaign's.
## Never true outside a Tutorial Select -> start_tutorial() call.
var is_tutorial_mode: bool = false
var current_tutorial_id: int = 1

## Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md): true
## for a normal PLAY/CONTINUE session, mirroring is_tutorial_mode's own
## pattern. game.gd branches its campaign-vs-procedural loading logic on
## this exactly like it already branches on is_tutorial_mode. Never true
## for a QA Level Select session (entered_via_level_select) - that legacy
## path always loads a campaign level, unchanged by this phase.
var is_procedural_mode: bool = false


func start_tutorial(tutorial_id: int) -> void:
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = false
	current_tutorial_id = tutorial_id
	is_tutorial_mode = true
	get_tree().change_scene_to_file(GAME_SCENE)


func go_to_tutorial_select() -> void:
	is_tutorial_mode = false
	get_tree().change_scene_to_file(TUTORIAL_SELECT_SCENE)

## Development-only playtest hand-off (Milestone 3 level editor). When
## `is_editor_playtest` is true, game.gd loads `editor_level_data`
## directly instead of asking LevelManager for a saved level, and its
## Back button returns to the editor scene instead of Level Select. Never
## set by any normal player-facing code path - see
## tools/level_editor/level_editor.gd and ARCHITECTURE.md ("Editor
## playtest hand-off").
var is_editor_playtest: bool = false
var editor_level_data: LevelData = null
var _editor_return_pending: bool = false


func start_editor_playtest(level_data: LevelData) -> void:
	editor_level_data = level_data
	is_editor_playtest = true
	get_tree().change_scene_to_file(GAME_SCENE)


func return_to_editor_from_playtest() -> void:
	is_editor_playtest = false
	_editor_return_pending = true
	get_tree().change_scene_to_file(LEVEL_EDITOR_SCENE)


## True exactly once after a playtest round-trip, so level_editor.gd can
## tell "just opened fresh" apart from "returning from Playtest with
## in-progress edits to restore." Consumed (cleared) by
## take_editor_level_data().
func is_editor_playtest_return_pending() -> bool:
	return _editor_return_pending


## Consumes and returns the level data that was being playtested. Clears
## the pending-return flag so a later fresh editor open doesn't
## mistakenly think it's resuming a playtest session.
func take_editor_level_data() -> LevelData:
	_editor_return_pending = false
	var data := editor_level_data
	editor_level_data = null
	return data


func go_to_main_menu() -> void:
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = false
	is_tutorial_mode = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func go_to_level_select() -> void:
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = false
	is_tutorial_mode = false
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func go_to_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func start_level(level_id: int, from_level_select: bool = false) -> void:
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = false
	current_level_id = level_id
	is_tutorial_mode = false
	is_procedural_mode = false
	entered_via_level_select = from_level_select
	get_tree().change_scene_to_file(GAME_SCENE)


## Phase 3 (Procedural Generator V1): enters procedural Level `level_number`
## directly - never through QA Level Select (there is no procedural Level
## Select at all, see PROCEDURAL_GENERATION.md "QA Level Select status").
## current_level_id is left at whatever it was; game.gd's procedural
## branch reads current_procedural_level, not current_level_id, so there
## is no possible collision between the two id spaces.
var current_procedural_level: int = 1


func start_procedural_level(level_number: int) -> void:
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = false
	current_procedural_level = level_number
	is_tutorial_mode = false
	is_procedural_mode = true
	entered_via_level_select = false
	get_tree().change_scene_to_file(GAME_SCENE)


## PLAY: enters the player's current PROCEDURAL progression -
## SaveManager.procedural_current_level (Level 1 on a fresh save,
## otherwise the first not-yet-LEGITIMATELY-completed procedural level -
## see SaveManager.record_procedural_level_result()). NEVER resets
## progress - this is not "New Game." Deliberately always targets real
## progression, even if QA Next (see LevelManager.
## SHOW_PROCEDURAL_QA_NEXT_BUTTON) has left the player's resume pointer
## somewhere further ahead - PLAY is "take me to my real progress,"
## CONTINUE below is "take me back to exactly where I was." Procedural
## progression is now the main-menu PLAY/CONTINUE target (see
## PROCEDURAL_GENERATION.md "PLAY behavior" / "Player save migration") -
## the legacy handcrafted Campaign (1-140) remains reachable only through
## the QA/dev Level Select screen.
## NEW GAME (D107): resets the main procedural run (SaveManager.reset_main_progress_for_new_game()) then starts Level 1
## with the current new-play generator rule. Returns false, without navigating, if the reset could not be saved.
func start_new_game() -> bool:
	if not SaveManager.reset_main_progress_for_new_game():
		return false
	start_procedural_level(1)
	return true


func play_game() -> void:
	start_procedural_level(clampi(SaveManager.procedural_current_level, 1, ProceduralLevelGenerator.MAX_LEVEL))


## CONTINUE: resumes the EXACT level the player was last in - normally
## identical to PLAY's target, but can genuinely differ after QA Next
## (spec example: tester on Level 487, presses QA Next to reach Level 488,
## exits app - CONTINUE must reopen Level 488, not jump back to the real
## progression pointer at 487). SaveManager.procedural_resume_level_number
## (set by every _load_current_level() call and by QA Next alike - see
## game.gd) is exactly "whatever procedural level was last opened,"
## independent of whether it was reached via real progression or a QA
## skip - falls back to procedural_current_level only when there is no
## resume state at all (a fresh save; also when has_resumable_procedural_
## game() is false, this function's caller - main_menu.gd - never even
## enables the Continue button, so that fallback is purely defensive).
## Only ever enabled by main_menu.gd when
## SaveManager.has_resumable_procedural_game() is true - see that
## function's doc comment for why this is NOT the same check as "some
## procedural level got unlocked."
func continue_game() -> void:
	var target := SaveManager.procedural_resume_level_number if SaveManager.has_resumable_procedural_game() else SaveManager.procedural_current_level
	start_procedural_level(clampi(target, 1, ProceduralLevelGenerator.MAX_LEVEL))


func quit_game() -> void:
	get_tree().quit()


## Difficulty System Phase 2A (D94) - DEV-ONLY V3 prototype session, gated by
## LevelManager.SHOW_V3_PROTOTYPE_QA. A sub-mode of procedural mode
## (is_procedural_mode stays true so game.gd's procedural UI applies) that
## generates ProceduralGeneratorV3 prototypes 1..PROTOTYPE_COUNT and NEVER
## reads or writes any save/progress/resume state. Reset by every other
## start_*/go_to_* entry point above.
var is_v3_prototype_mode: bool = false


func start_v3_prototype(index: int) -> void:
	current_procedural_level = clampi(index, 1, ProceduralGeneratorV3.PROTOTYPE_COUNT)
	is_tutorial_mode = false
	is_procedural_mode = true
	is_v3_prototype_mode = true
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = false
	entered_via_level_select = false
	get_tree().change_scene_to_file(GAME_SCENE)


## Fusion Node Phase 1 (D99) - DEV-ONLY Fusion QA session (LevelManager.SHOW_FUSION_TEST_QA).
## Identical containment to the V3 prototype session (see game.gd's _is_v3_session()): a sub-mode
## of procedural mode that plays levels/fusion_qa puzzles 1..FusionQaSet.COUNT and never reads or
## writes save/progress/resume state, ads or the completion counter.
var is_fusion_test_mode: bool = false


func start_fusion_test(index: int) -> void:
	current_procedural_level = clampi(index, 1, FusionQaSet.COUNT)
	is_tutorial_mode = false
	is_procedural_mode = true
	is_v3_prototype_mode = false
	is_fusion_test_mode = true
	is_selector_test_mode = false
	is_v5_test_mode = false
	entered_via_level_select = false
	get_tree().change_scene_to_file(GAME_SCENE)


## Splitter Selector Phase S1 - DEV-ONLY Selector QA session (LevelManager.SHOW_SELECTOR_TEST_QA).
## Same containment as the Fusion QA session: a save-free, ad-free sub-mode of procedural mode that
## plays levels/selector_qa puzzles 1..SelectorQaSet.COUNT (see game.gd's _is_v3_session()).
var is_selector_test_mode: bool = false


func start_selector_test(index: int) -> void:
	current_procedural_level = clampi(index, 1, SelectorQaSet.COUNT)
	is_tutorial_mode = false
	is_procedural_mode = true
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = true
	is_v5_test_mode = false
	entered_via_level_select = false
	get_tree().change_scene_to_file(GAME_SCENE)


## Selector Phase S3 (D110) - DEV-ONLY V5 QA session (LevelManager.SHOW_V5_TEST_QA): plays a curated list of generator-V5
## levels (ProceduralV5QaSet.LEVELS) for manual difficulty review. Same containment as the Fusion/Selector QA sessions: a
## save-free, ad-free, counter-free sub-mode of procedural mode (game.gd's _is_v3_session()). `current_procedural_level` holds
## the 1-based INDEX into that list, never a real level number.
var is_v5_test_mode: bool = false


func start_v5_test(index: int) -> void:
	current_procedural_level = clampi(index, 1, ProceduralV5QaSet.COUNT)
	is_tutorial_mode = false
	is_procedural_mode = true
	is_v3_prototype_mode = false
	is_fusion_test_mode = false
	is_selector_test_mode = false
	is_v5_test_mode = true
	entered_via_level_select = false
	get_tree().change_scene_to_file(GAME_SCENE)
