extends Node
## Autoload: LevelManager
## Owns the ordered list of levels and the star-rating formula.
## Adding a new level for Milestone 3+ only requires adding a new
## file to LEVEL_PATHS - no other system needs to change.

## DEVELOPMENT/QA ONLY - when true, every currently-implemented campaign
## level is selectable from Level Select regardless of real unlock
## progress (see is_campaign_level_selectable() below, the only place
## this flag is read). Does NOT touch SaveManager's actual completion/
## unlock/star/best-move data in any way - completing a level still only
## records that one level's real result, and normal sequential locking
## resumes immediately the moment this is set back to false. Scales
## automatically to however many campaign levels CAMPAIGN_LEVEL_PATHS
## currently has (via get_campaign_level_count()) - no per-stage edits
## needed as Stage 5+ are added.
## IMPORTANT: SET TO FALSE BEFORE FINAL PRODUCTION RELEASE.
const UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING := BuildConfig.QA_TOOLS

const LEVEL_PATHS: Array[String] = [
	"res://levels/level_01.gd",
	"res://levels/level_02.gd",
	"res://levels/level_03.gd",
	"res://levels/level_04.gd",
	"res://levels/level_05.gd",
	"res://levels/level_06.gd",
	"res://levels/level_07.gd",
	"res://levels/level_08.gd",
	"res://levels/level_09.gd",
	"res://levels/level_10.gd",
	"res://levels/level_11.gd",
	"res://levels/level_12.gd",
	"res://levels/level_13.gd",
	"res://levels/level_14.gd",
	"res://levels/level_15.gd",
]

## The real, player-facing production campaign (Milestone 4 - see
## CAMPAIGN_DESIGN.md). Only Stage 1 exists so far; add each future
## stage's 10 paths here, in order, exactly like LEVEL_PATHS above - no
## other system needs to change. Kept completely separate from
## LEVEL_PATHS/get_level() (the 15 dev/regression levels above), which
## remain regression-only and are no longer shown to players - see
## DECISIONS.md D54.
const CAMPAIGN_LEVEL_PATHS: Array[String] = [
	"res://levels/campaign/stage_01/level_01.gd",
	"res://levels/campaign/stage_01/level_02.gd",
	"res://levels/campaign/stage_01/level_03.gd",
	"res://levels/campaign/stage_01/level_04.gd",
	"res://levels/campaign/stage_01/level_05.gd",
	"res://levels/campaign/stage_01/level_06.gd",
	"res://levels/campaign/stage_01/level_07.gd",
	"res://levels/campaign/stage_01/level_08.gd",
	"res://levels/campaign/stage_01/level_09.gd",
	"res://levels/campaign/stage_01/level_10.gd",
	"res://levels/campaign/stage_02/level_01.gd",
	"res://levels/campaign/stage_02/level_02.gd",
	"res://levels/campaign/stage_02/level_03.gd",
	"res://levels/campaign/stage_02/level_04.gd",
	"res://levels/campaign/stage_02/level_05.gd",
	"res://levels/campaign/stage_02/level_06.gd",
	"res://levels/campaign/stage_02/level_07.gd",
	"res://levels/campaign/stage_02/level_08.gd",
	"res://levels/campaign/stage_02/level_09.gd",
	"res://levels/campaign/stage_02/level_10.gd",
	"res://levels/campaign/stage_03/level_01.gd",
	"res://levels/campaign/stage_03/level_02.gd",
	"res://levels/campaign/stage_03/level_03.gd",
	"res://levels/campaign/stage_03/level_04.gd",
	"res://levels/campaign/stage_03/level_05.gd",
	"res://levels/campaign/stage_03/level_06.gd",
	"res://levels/campaign/stage_03/level_07.gd",
	"res://levels/campaign/stage_03/level_08.gd",
	"res://levels/campaign/stage_03/level_09.gd",
	"res://levels/campaign/stage_03/level_10.gd",
	"res://levels/campaign/stage_04/level_01.gd",
	"res://levels/campaign/stage_04/level_02.gd",
	"res://levels/campaign/stage_04/level_03.gd",
	"res://levels/campaign/stage_04/level_04.gd",
	"res://levels/campaign/stage_04/level_05.gd",
	"res://levels/campaign/stage_04/level_06.gd",
	"res://levels/campaign/stage_04/level_07.gd",
	"res://levels/campaign/stage_04/level_08.gd",
	"res://levels/campaign/stage_04/level_09.gd",
	"res://levels/campaign/stage_04/level_10.gd",
	"res://levels/campaign/stage_05/level_01.gd",
	"res://levels/campaign/stage_05/level_02.gd",
	"res://levels/campaign/stage_05/level_03.gd",
	"res://levels/campaign/stage_05/level_04.gd",
	"res://levels/campaign/stage_05/level_05.gd",
	"res://levels/campaign/stage_05/level_06.gd",
	"res://levels/campaign/stage_05/level_07.gd",
	"res://levels/campaign/stage_05/level_08.gd",
	"res://levels/campaign/stage_05/level_09.gd",
	"res://levels/campaign/stage_05/level_10.gd",
	"res://levels/campaign/stage_06/level_01.gd",
	"res://levels/campaign/stage_06/level_02.gd",
	"res://levels/campaign/stage_06/level_03.gd",
	"res://levels/campaign/stage_06/level_04.gd",
	"res://levels/campaign/stage_06/level_05.gd",
	"res://levels/campaign/stage_06/level_06.gd",
	"res://levels/campaign/stage_06/level_07.gd",
	"res://levels/campaign/stage_06/level_08.gd",
	"res://levels/campaign/stage_06/level_09.gd",
	"res://levels/campaign/stage_06/level_10.gd",
	"res://levels/campaign/stage_07/level_01.gd",
	"res://levels/campaign/stage_07/level_02.gd",
	"res://levels/campaign/stage_07/level_03.gd",
	"res://levels/campaign/stage_07/level_04.gd",
	"res://levels/campaign/stage_07/level_05.gd",
	"res://levels/campaign/stage_07/level_06.gd",
	"res://levels/campaign/stage_07/level_07.gd",
	"res://levels/campaign/stage_07/level_08.gd",
	"res://levels/campaign/stage_07/level_09.gd",
	"res://levels/campaign/stage_07/level_10.gd",
	"res://levels/campaign/stage_08/level_01.gd",
	"res://levels/campaign/stage_08/level_02.gd",
	"res://levels/campaign/stage_08/level_03.gd",
	"res://levels/campaign/stage_08/level_04.gd",
	"res://levels/campaign/stage_08/level_05.gd",
	"res://levels/campaign/stage_08/level_06.gd",
	"res://levels/campaign/stage_08/level_07.gd",
	"res://levels/campaign/stage_08/level_08.gd",
	"res://levels/campaign/stage_08/level_09.gd",
	"res://levels/campaign/stage_08/level_10.gd",
	"res://levels/campaign/stage_09/level_01.gd",
	"res://levels/campaign/stage_09/level_02.gd",
	"res://levels/campaign/stage_09/level_03.gd",
	"res://levels/campaign/stage_09/level_04.gd",
	"res://levels/campaign/stage_09/level_05.gd",
	"res://levels/campaign/stage_09/level_06.gd",
	"res://levels/campaign/stage_09/level_07.gd",
	"res://levels/campaign/stage_09/level_08.gd",
	"res://levels/campaign/stage_09/level_09.gd",
	"res://levels/campaign/stage_09/level_10.gd",
	"res://levels/campaign/stage_10/level_01.gd",
	"res://levels/campaign/stage_10/level_02.gd",
	"res://levels/campaign/stage_10/level_03.gd",
	"res://levels/campaign/stage_10/level_04.gd",
	"res://levels/campaign/stage_10/level_05.gd",
	"res://levels/campaign/stage_10/level_06.gd",
	"res://levels/campaign/stage_10/level_07.gd",
	"res://levels/campaign/stage_10/level_08.gd",
	"res://levels/campaign/stage_10/level_09.gd",
	"res://levels/campaign/stage_10/level_10.gd",
	## Levels 101-110 - the first Era 2 ("Refractions") campaign levels,
	## the first campaign content to use Prism/One-Way Reflector/Beam
	## Receiver/Remote Emitter. Folder is named era2_stage_01 rather than
	## continuing "stage_11" - this is genuinely new scope (a separate,
	## explicit request), not a continuation of the original 100-level
	## plan's numbering, per CAMPAIGN_DESIGN.md's own guidance on this.
	## See ERA_2_DESIGN.md and DECISIONS.md for the full writeup.
	"res://levels/campaign/era2_stage_01/level_01.gd",
	"res://levels/campaign/era2_stage_01/level_02.gd",
	"res://levels/campaign/era2_stage_01/level_03.gd",
	"res://levels/campaign/era2_stage_01/level_04.gd",
	"res://levels/campaign/era2_stage_01/level_05.gd",
	"res://levels/campaign/era2_stage_01/level_06.gd",
	"res://levels/campaign/era2_stage_01/level_07.gd",
	"res://levels/campaign/era2_stage_01/level_08.gd",
	"res://levels/campaign/era2_stage_01/level_09.gd",
	"res://levels/campaign/era2_stage_01/level_10.gd",
	## Levels 111-120 - deepens the same three Era 2 mechanic families
	## with no new mechanics, per the user's explicit follow-up request.
	## Same folder (era2_stage_01), continuing local level_id 11-20 -
	## see DECISIONS.md for the full writeup.
	"res://levels/campaign/era2_stage_01/level_11.gd",
	"res://levels/campaign/era2_stage_01/level_12.gd",
	"res://levels/campaign/era2_stage_01/level_13.gd",
	"res://levels/campaign/era2_stage_01/level_14.gd",
	"res://levels/campaign/era2_stage_01/level_15.gd",
	"res://levels/campaign/era2_stage_01/level_16.gd",
	"res://levels/campaign/era2_stage_01/level_17.gd",
	"res://levels/campaign/era2_stage_01/level_18.gd",
	"res://levels/campaign/era2_stage_01/level_19.gd",
	"res://levels/campaign/era2_stage_01/level_20.gd",
	## Levels 121-130 - "deep dependency" pass, whole-board reasoning,
	## multiple interacting dependency structures. Still no new
	## mechanics. Same folder, continuing local level_id 21-30 - see
	## DECISIONS.md for the full writeup.
	"res://levels/campaign/era2_stage_01/level_21.gd",
	"res://levels/campaign/era2_stage_01/level_22.gd",
	"res://levels/campaign/era2_stage_01/level_23.gd",
	"res://levels/campaign/era2_stage_01/level_24.gd",
	"res://levels/campaign/era2_stage_01/level_25.gd",
	"res://levels/campaign/era2_stage_01/level_26.gd",
	"res://levels/campaign/era2_stage_01/level_27.gd",
	"res://levels/campaign/era2_stage_01/level_28.gd",
	"res://levels/campaign/era2_stage_01/level_29.gd",
	"res://levels/campaign/era2_stage_01/level_30.gd",
	## Levels 131-140 - "advanced convergence" pass, combining the
	## strongest dependency patterns from 101-130 into more advanced
	## whole-board puzzles. Still no new mechanics. Same folder,
	## continuing local level_id 31-40 - see DECISIONS.md for the full
	## writeup.
	"res://levels/campaign/era2_stage_01/level_31.gd",
	"res://levels/campaign/era2_stage_01/level_32.gd",
	"res://levels/campaign/era2_stage_01/level_33.gd",
	"res://levels/campaign/era2_stage_01/level_34.gd",
	"res://levels/campaign/era2_stage_01/level_35.gd",
	"res://levels/campaign/era2_stage_01/level_36.gd",
	"res://levels/campaign/era2_stage_01/level_37.gd",
	"res://levels/campaign/era2_stage_01/level_38.gd",
	"res://levels/campaign/era2_stage_01/level_39.gd",
	"res://levels/campaign/era2_stage_01/level_40.gd",
]

## The guided tutorial (T01-T10) - a completely separate population from
## both LEVEL_PATHS and CAMPAIGN_LEVEL_PATHS, never counted toward either
## (the tutorial does NOT occupy campaign level ids). See DECISIONS.md
## ("Guided tutorial system") for why tutorial progression is its own
## SaveManager fields rather than reusing campaign fields.
const TUTORIAL_LEVEL_PATHS: Array[String] = [
	"res://levels/tutorial/t01.gd",
	"res://levels/tutorial/t02.gd",
	"res://levels/tutorial/t03.gd",
	"res://levels/tutorial/t04.gd",
	"res://levels/tutorial/t05.gd",
	"res://levels/tutorial/t06.gd",
	"res://levels/tutorial/t07.gd",
	"res://levels/tutorial/t08.gd",
	"res://levels/tutorial/t09.gd",
	"res://levels/tutorial/t10.gd",
	# Era 2 ("Refractions") tutorial pack - see ERA_2_DESIGN.md. Locked
	# until Level 100 is completed; see
	# LevelManager.is_tutorial_level_selectable().
	"res://levels/tutorial/t11.gd",
	"res://levels/tutorial/t12.gd",
	"res://levels/tutorial/t13.gd",
	"res://levels/tutorial/t14.gd",
	"res://levels/tutorial/t15.gd",
	"res://levels/tutorial/t16.gd",
	"res://levels/tutorial/t17.gd",
	"res://levels/tutorial/t18.gd",
	"res://levels/tutorial/t19.gd",
	"res://levels/tutorial/t20.gd",
	# Fusion pack (Fusion Phase 3, D101) - see FUSION_TUTORIAL_FIRST below for its
	# own unlock rule (it is NOT era-gated: T21-T30 would otherwise read as "Era 3").
	"res://levels/tutorial/t21.gd",
	"res://levels/tutorial/t22.gd",
	"res://levels/tutorial/t23.gd",
	"res://levels/tutorial/t24.gd",
	"res://levels/tutorial/t25.gd",
	"res://levels/tutorial/t26.gd",
	"res://levels/tutorial/t27.gd",
	"res://levels/tutorial/t28.gd",
	# Splitter Selector pack (Selector Phase S2, D109) - own unlock rule, see SELECTOR_TUTORIAL_FIRST.
	"res://levels/tutorial/t29.gd",
	"res://levels/tutorial/t30.gd",
	"res://levels/tutorial/t31.gd",
	"res://levels/tutorial/t32.gd",
	"res://levels/tutorial/t33.gd",
	"res://levels/tutorial/t34.gd",
]

## Fusion tutorial pack (T21-T28, Fusion Phase 3, D101). Normal procedural progression
## first rolls Fusion at Level 201 (ProceduralDifficultyContract._FUSION_PROGRESSION), so
## the pack becomes selectable well before that - at FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL
## - and is never a hard gate: no procedural level is ever locked behind it.
const FUSION_TUTORIAL_FIRST := 21
const FUSION_TUTORIAL_LAST := 28
const FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL := 150

## Splitter Selector tutorial pack (T29-T34, Selector Phase S2, D109). Selector puzzles first appear in main progression at
## Level 2001 (generator V5, Selector Phase S3, D110), so T29 opens - well BEFORE that - once real procedural progression reaches
## SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL (well before the certified boundary); T30-T34 unlock sequentially.
## Never a hard gate: no procedural level is ever locked behind it.
const SELECTOR_TUTORIAL_FIRST := 29
const SELECTOR_TUTORIAL_LAST := 34
const SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL := 1900

## Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md):
## TEMPORARY QA-only flag for the small "NEXT" skip button on the shared
## gameplay HUD (see game.tscn's %QANextButton / game.gd's
## _on_qa_next_pressed()). Testing up to Level 3000 by actually solving
## every prior puzzle is impractical - this lets a tester jump straight to
## the next procedural level. Reuses the same single-obvious-flag
## convention as UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING/
## UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING above. It ONLY ever advances
## SaveManager's procedural RESUME pointer (via SaveManager.
## start_procedural_resume()) so a tester can keep moving forward and
## still get CONTINUE back to where they left off - it never calls
## SaveManager.record_procedural_level_result(), so it can never mark a
## level legitimately completed, write stars, or advance
## procedural_current_level. See PROCEDURAL_GENERATION.md "QA Next button".
## IMPORTANT: SET TO FALSE BEFORE FINAL PRODUCTION RELEASE - shipping with
## this button enabled is a release blocker, same severity as the two
## flags above.
const SHOW_PROCEDURAL_QA_NEXT_BUTTON := BuildConfig.QA_TOOLS

## How many procedural levels the QA button jumps per press (Difficulty
## System Phase 1, D93 - the ONE place this number lives; the button's
## "+N" label is derived from it too). Clamped to
## ProceduralLevelGenerator.MAX_LEVEL; a press at MAX_LEVEL is a no-op.
## Same release rule as SHOW_PROCEDURAL_QA_NEXT_BUTTON - it is only ever
## reachable through that button.
const PROCEDURAL_QA_JUMP_AMOUNT := 50

## Difficulty System Phase 2A (D94): DEV-ONLY entry for the six Generator V3
## prototypes - Main Menu's small "V3 TEST" button starts prototype 1 and the
## in-game QA button becomes "NEXT V3" (cycling 1..6) while in that session
## (see GameManager.start_v3_prototype()). Never touches SaveManager. The
## existing +50 procedural QA button is unchanged outside a V3 session.
## IMPORTANT: SET TO FALSE BEFORE FINAL PRODUCTION RELEASE, same severity as
## SHOW_PROCEDURAL_QA_NEXT_BUTTON.
const SHOW_V3_PROTOTYPE_QA := BuildConfig.QA_TOOLS

## Fusion Node Phase 1 (D99): DEV-ONLY entry for the six Fusion QA puzzles (Main Menu "FUSION TEST",
## in-game "NEXT FUSION"). Same containment as V3 TEST: never touches saves, progression, stars,
## ads or the interstitial counter; hints stay free. IMPORTANT: SET TO FALSE BEFORE PRODUCTION.
const SHOW_FUSION_TEST_QA := BuildConfig.QA_TOOLS

## Splitter Selector Phase S1: DEV-ONLY entry for the six Selector QA puzzles (Main Menu "SELECTOR TEST",
## in-game "NEXT SELECTOR"). Same containment as FUSION TEST. IMPORTANT: SET TO FALSE BEFORE PRODUCTION.
const SHOW_SELECTOR_TEST_QA := BuildConfig.QA_TOOLS

## Selector Phase S3 (D110): DEV-ONLY entry for a curated sample of generator-V5 levels (Main Menu "V5 TEST", in-game
## "NEXT V5"), for manual difficulty review. Same containment as SELECTOR TEST / FUSION TEST: never touches saves, stars,
## ads or the interstitial counter. IMPORTANT: SET TO FALSE BEFORE PRODUCTION (it follows BuildConfig.QA_TOOLS).
const SHOW_V5_TEST_QA := BuildConfig.QA_TOOLS

## Difficulty System Phase 2B (D96): DEV/QA switch that makes normal procedural
## progression (PLAY / CONTINUE / the +50 button) generate NEW puzzles with
## Generator V3 (ProceduralProgressionV3) instead of the frozen V2 default. The ONE
## place that decision lives (see procedural_generator_version_for_new_play()).
## A puzzle that is RESUMED always regenerates under the version saved with it
## (V1/V2/V3 never cross-regenerate). ProceduralLevelGenerator.GENERATOR_VERSION
## stays 2 until the user approves a rollout; V3 is development/QA, not
## release-certified. IMPORTANT: review before any production release, same
## severity as the other QA flags.
const USE_V3_FOR_PROCEDURAL_QA := true
## Fusion Node Phase 2 (D100): DEV/QA switch making new normal procedural puzzles use generator V4 (V3
## progression + Fusion fragments) instead of V3. Only meaningful while USE_V3_FOR_PROCEDURAL_QA is on.
## A RESUMED puzzle still regenerates under its saved version (V3 saves stay V3). IMPORTANT: review
## before any production release; production unlock must be coordinated with the Fusion tutorial.
const USE_FUSION_PROGRESSION_FOR_QA := true



## Phase 4 (D102): star thresholds live ONLY in StarScoring (V1: OPTIMAL+2 = 3 stars, +6 = 2 stars, else 1;
## a granted Hint caps at 2). Kept as an alias so old references keep compiling.
const TWO_STAR_MOVE_MARGIN := StarScoring.THREE_STAR_MARGIN

var _level_cache: Dictionary = {} # level_id (int) -> LevelData
var _campaign_level_cache: Dictionary = {} # campaign level_id (int) -> LevelData
var _tutorial_level_cache: Dictionary = {} # tutorial level_id (int) -> TutorialLevelData

## Phase 3 (Procedural Generator V1): tiny in-memory cache, NOT persisted
## to save data (see PROCEDURAL_GENERATION.md "Generation cache") - at
## most a couple of entries at once (the current level, and whatever the
## most recent get_procedural_level() call happened to generate), rebuilt
## fresh every app launch. Keyed on (level_number, generator_version) so a
## future generator version bump can never return a stale, wrong-version
## cached LevelData for the same level_number.
var _procedural_level_cache: Dictionary = {} # "level_number|generator_version" (String) -> LevelData


func get_level_count() -> int:
	return LEVEL_PATHS.size()


func get_level(level_id: int) -> LevelData:
	if _level_cache.has(level_id):
		return _level_cache[level_id]

	var index := level_id - 1
	if index < 0 or index >= LEVEL_PATHS.size():
		push_warning("LevelManager: invalid level_id %d" % level_id)
		return null

	var level_data := load_level_from_path(LEVEL_PATHS[index])
	_level_cache[level_id] = level_data
	return level_data


## Loads a LevelData from either a .gd script (extends LevelData, needs
## .new()) or a .tres resource (already a live instance on load). See
## DECISIONS.md ("Level editor persistent format") for why both formats
## are supported side by side rather than migrating everything to one.
## Not cached - callers that want caching should go through get_level().
static func load_level_from_path(path: String) -> LevelData:
	var resource = load(path)
	if resource is LevelData:
		return resource
	if resource is GDScript:
		return resource.new()
	push_warning("LevelManager: %s did not resolve to a LevelData or a LevelData script" % path)
	return null


func calculate_stars(level_id: int, moves_used: int, hint_used: bool = false) -> int:
	var level_data := get_level(level_id)
	if level_data == null:
		return 1
	return StarScoring.stars_for(StarScoring.authoritative_optimal(level_data), moves_used, hint_used)


## First level that is unlocked but not yet completed, falling back to the
## highest unlocked level (used by the "Continue" button).
func get_continue_level_id() -> int:
	var highest: int = SaveManager.highest_unlocked_level
	for id in range(1, highest + 1):
		if not SaveManager.is_level_completed(id):
			return id
	return clampi(highest, 1, get_level_count())


## --- Campaign (player-facing) equivalents of the functions above.
## Mirrors get_level_count()/get_level()/calculate_stars()/
## get_continue_level_id() exactly, against CAMPAIGN_LEVEL_PATHS instead
## of LEVEL_PATHS. See DECISIONS.md D54.

func get_campaign_level_count() -> int:
	return CAMPAIGN_LEVEL_PATHS.size()


func get_campaign_level(campaign_level_id: int) -> LevelData:
	if _campaign_level_cache.has(campaign_level_id):
		return _campaign_level_cache[campaign_level_id]

	var index := campaign_level_id - 1
	if index < 0 or index >= CAMPAIGN_LEVEL_PATHS.size():
		push_warning("LevelManager: invalid campaign_level_id %d" % campaign_level_id)
		return null

	var level_data := load_level_from_path(CAMPAIGN_LEVEL_PATHS[index])
	_campaign_level_cache[campaign_level_id] = level_data
	return level_data


func calculate_campaign_stars(campaign_level_id: int, moves_used: int, hint_used: bool = false) -> int:
	var level_data := get_campaign_level(campaign_level_id)
	if level_data == null:
		return 1
	return StarScoring.stars_for(StarScoring.authoritative_optimal(level_data), moves_used, hint_used)


## Level Select calls this (instead of SaveManager.is_campaign_level_
## unlocked() directly) to decide whether a campaign level card is
## selectable. The single place UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING is
## applied - real unlock progress in SaveManager is never read from or
## written to differently because of it.
func is_campaign_level_selectable(campaign_level_id: int) -> bool:
	if UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING:
		return campaign_level_id >= 1 and campaign_level_id <= get_campaign_level_count()
	return SaveManager.is_campaign_level_unlocked(campaign_level_id)


func get_campaign_continue_level_id() -> int:
	var highest: int = SaveManager.campaign_highest_unlocked_level
	for id in range(1, highest + 1):
		if not SaveManager.is_campaign_level_completed(id):
			return id
	return clampi(highest, 1, get_campaign_level_count())


## --- Tutorial (T01-T10) equivalents. Mirrors get_campaign_level_count()/
## get_campaign_level() against TUTORIAL_LEVEL_PATHS. T01-T10 (Era 1) have
## no QA-unlock-style override (tutorial unlock there is always the real
## sequential progression - nothing has asked for a testing bypass for
## it); T11-T20 (Era 2) do, see UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING.

## DEVELOPMENT/QA ONLY - mirrors UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING's
## exact bypass semantics: when true, every implemented Era 2 tutorial
## (T11-T20) is selectable UNCONDITIONALLY - regardless of real Campaign
## completion progress AND regardless of whether T01-T10 were actually
## finished first (the campaign flag bypasses SaveManager.
## is_campaign_level_unlocked() completely the same way - see
## is_campaign_level_selectable() above; a version of this flag that only
## bypassed the Level-100 gate but still required real T01-T10 completion
## would be far less useful for fresh-save development testing). Does NOT
## touch SaveManager's actual tutorial_*/campaign_* data in any way - the
## real gates resume immediately once this is set back to false.
## IMPORTANT: SET TO FALSE BEFORE FINAL PRODUCTION RELEASE.
const UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING := BuildConfig.QA_TOOLS


func get_tutorial_level_count() -> int:
	return TUTORIAL_LEVEL_PATHS.size()


## Tutorial Select calls this (instead of SaveManager.is_tutorial_level_
## unlocked() directly) to decide whether a tutorial card is selectable -
## the one place both UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING and the
## Era-2-requires-Level-100 rule are applied. T01-T10 (Era 1) are
## entirely unaffected - they still use only the plain sequential
## tutorial_highest_unlocked_level progress they always have. See
## CLAUDE.md "Guided tutorial rules" and ERA_2_DESIGN.md "T11-T20 unlock
## rule". Generalizes to future eras: an era N tutorial additionally
## requires campaign level (N-1)*100 completed.
func is_tutorial_level_selectable(tutorial_level_id: int) -> bool:
	if tutorial_level_id >= SELECTOR_TUTORIAL_FIRST and tutorial_level_id <= SELECTOR_TUTORIAL_LAST:
		return is_selector_tutorial_selectable(tutorial_level_id)
	if tutorial_level_id >= FUSION_TUTORIAL_FIRST and tutorial_level_id <= FUSION_TUTORIAL_LAST:
		return is_fusion_tutorial_selectable(tutorial_level_id)
	var era := EraTheme.get_era_for_tutorial(tutorial_level_id)
	if era <= 1:
		return SaveManager.is_tutorial_level_unlocked(tutorial_level_id)
	if UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING:
		return tutorial_level_id >= 1 and tutorial_level_id <= get_tutorial_level_count()
	if not SaveManager.is_tutorial_level_unlocked(tutorial_level_id):
		return false
	var required_campaign_level := (era - 1) * EraTheme.LEVELS_PER_ERA
	return SaveManager.is_campaign_level_completed(required_campaign_level)


## T21 opens once the player's real procedural progression reaches
## FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL; T22-T28 then unlock one by one (the ordinary
## sequential tutorial_highest_unlocked_level rule). The QA flag opens all of them.
func is_fusion_tutorial_selectable(tutorial_level_id: int) -> bool:
	if UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING:
		return true
	if tutorial_level_id == FUSION_TUTORIAL_FIRST:
		return SaveManager.procedural_current_level >= FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL \
			or SaveManager.is_tutorial_level_unlocked(tutorial_level_id)
	return SaveManager.is_tutorial_level_unlocked(tutorial_level_id)


## T29 opens once real procedural progression reaches SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL (or an earlier
## tutorial_highest_unlocked_level says so); T30-T34 are sequential. The QA flag opens all of them.
func is_selector_tutorial_selectable(tutorial_level_id: int) -> bool:
	if UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING:
		return true
	if tutorial_level_id == SELECTOR_TUTORIAL_FIRST:
		return SaveManager.procedural_current_level >= SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL \
			or SaveManager.is_tutorial_level_unlocked(tutorial_level_id)
	return SaveManager.is_tutorial_level_unlocked(tutorial_level_id)


## Phase 4 (D102): true exactly once - when the Fusion tutorial pack is available for the first time and the
## player has not started it yet (QA builds count as available so testers see the nudge on a fresh save).
func should_show_fusion_tutorial_nudge() -> bool:
	if SaveManager.fusion_tutorial_nudge_seen or SaveManager.is_tutorial_level_completed(FUSION_TUTORIAL_FIRST):
		return false
	return BuildConfig.QA_TOOLS or SaveManager.procedural_current_level >= FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL \
		or SaveManager.is_tutorial_level_unlocked(FUSION_TUTORIAL_FIRST)


func get_tutorial_level(tutorial_level_id: int) -> TutorialLevelData:
	if _tutorial_level_cache.has(tutorial_level_id):
		return _tutorial_level_cache[tutorial_level_id]

	var index := tutorial_level_id - 1
	if index < 0 or index >= TUTORIAL_LEVEL_PATHS.size():
		push_warning("LevelManager: invalid tutorial_level_id %d" % tutorial_level_id)
		return null

	var level_data := load_level_from_path(TUTORIAL_LEVEL_PATHS[index])
	if level_data != null and not (level_data is TutorialLevelData):
		push_warning("LevelManager: %s did not resolve to a TutorialLevelData" % TUTORIAL_LEVEL_PATHS[index])
		return null
	_tutorial_level_cache[tutorial_level_id] = level_data
	return level_data


## --- Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md):
## the main-menu PLAY/CONTINUE progression, Levels 1-3000 (1-2000 under generators V1-V4, 2001-3000 under V5). A completely
## separate population from LEVEL_PATHS/CAMPAIGN_LEVEL_PATHS/
## TUTORIAL_LEVEL_PATHS above - generated on demand via
## ProceduralLevelGenerator rather than loaded from a fixed path array, so
## there is no PROCEDURAL_LEVEL_PATHS constant to maintain.

func get_procedural_level_count() -> int:
	return ProceduralLevelGenerator.MAX_LEVEL


## Generates (or returns the cached result for) procedural Level
## `level_number` - the full ProceduralLevelGenerator.generate() result
## (level_data, seed, generator_version, template_id, etc.), so callers
## that need the seed for exact resume (see game.gd) don't have to call
## the generator a second time. Never reads/writes SaveManager - callers
## decide resume/completion bookkeeping.
func get_procedural_generation_result(level_number: int, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> Dictionary:
	var key := "%d|%d" % [level_number, generator_version]
	if _procedural_level_cache.has(key):
		return _procedural_level_cache[key]

	var result := ProceduralLevelGenerator.generate(level_number, generator_version)
	_procedural_level_cache.clear() # keep at most one generated level resident at a time
	_procedural_level_cache[key] = result
	return result


func get_procedural_level(level_number: int, generator_version: int = ProceduralLevelGenerator.GENERATOR_VERSION) -> LevelData:
	return get_procedural_generation_result(level_number, generator_version)["level_data"]


## Generator version for a BRAND-NEW procedural puzzle (never for a resumed one -
## game.gd uses the version saved with the resume state for that).
func procedural_generator_version_for_new_play(level_number: int = 0) -> int:
	# Levels 2001+ exist only under generator V5 (Selector Phase S3, D110) - the ONE place that maps a level to V5.
	if level_number >= ProceduralLevelGenerator.SELECTOR_FIRST_LEVEL:
		return ProceduralLevelGenerator.GENERATOR_VERSION_V5
	if USE_V3_FOR_PROCEDURAL_QA and USE_FUSION_PROGRESSION_FOR_QA:
		return ProceduralLevelGenerator.GENERATOR_VERSION_V4
	if USE_V3_FOR_PROCEDURAL_QA:
		return ProceduralLevelGenerator.GENERATOR_VERSION_V3
	return ProceduralLevelGenerator.GENERATOR_VERSION
