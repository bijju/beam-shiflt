extends Node
## Autoload: SaveManager
## Lightweight local JSON save at user://savegame.json.
## Handles first launch, missing save, and malformed save gracefully.
## See ARCHITECTURE.md ("Save format") for the on-disk schema.

const SAVE_PATH := "user://savegame.json"
## Bumped 1 -> 2 when campaign_* fields were added (Milestone 4,
## "Production Campaign Phase 1" - see DECISIONS.md D54); bumped 2 -> 3
## when tutorial_* fields were added (Guided Tutorial Mode - see
## DECISIONS.md "Guided tutorial system"); bumped 3 -> 4 when
## campaign_resume_* fields were added (Phase 2: Direct Play + Continue
## Flow - see DECISIONS.md D85); bumped 4 -> 5 when procedural_* fields
## were added (Phase 3: Procedural Generator V1 - see
## PROCEDURAL_GENERATION.md). Purely informational in every case -
## load_game()/_apply_data() below use Dictionary.get() with safe
## defaults for every field, so an older save (missing the newer keys
## entirely) loads correctly with fresh progress for just the new fields
## and every existing field fully intact. No migration code was needed
## in any case; this constant just records when the schema grew. See
## PROCEDURAL_GENERATION.md "Player save migration" for the specific
## procedural-progression migration decision (PLAY initializes procedural
## progression at Level 1 for an upgrading save - no equivalence is
## synthesized from prior campaign progress).
const SAVE_VERSION := 5

var highest_unlocked_level: int = 1
var completed_levels: Dictionary = {} # level_id (String) -> true
var best_moves_per_level: Dictionary = {} # level_id (String) -> int
var best_stars_per_level: Dictionary = {} # level_id (String) -> int
var sound_enabled: bool = true
var music_enabled: bool = true

## Player-facing production campaign progress (Milestone 4). Namespaced
## separately from the dev-level fields above on purpose - the two
## populations must never share unlock/completion state (a dev level_id
## and a campaign level_id can both be e.g. "3" and must not collide).
## See DECISIONS.md D54.
var campaign_highest_unlocked_level: int = 1
var campaign_completed_levels: Dictionary = {} # campaign level_id (String) -> true
var campaign_best_moves_per_level: Dictionary = {} # campaign level_id (String) -> int
var campaign_best_stars_per_level: Dictionary = {} # campaign level_id (String) -> int

## Guided tutorial (T01-T10) progress. Namespaced separately from BOTH
## the dev-level and campaign fields above, same reasoning as D54 - a
## tutorial level_id (1-10) would otherwise collide with dev/campaign ids
## in the same save keys. No stars/best-moves fields exist for tutorials
## on purpose - tutorials are lessons, not scored puzzles (see the
## brief's explicit "do not show misleading stars/best-move info").
## Tutorial completion/unlock never touches campaign_* or the dev-level
## fields, and vice versa - see the isolation test in TEST_PLAN.md.
var tutorial_highest_unlocked_level: int = 1
var tutorial_completed_levels: Dictionary = {} # tutorial level_id (String) -> true

## Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): the ONE
## in-progress campaign game a player can resume, independent of
## unlock/completion state. 0 is a sentinel meaning "no resumable game
## yet" - deliberately NOT derived from campaign_highest_unlocked_level,
## since "a level got unlocked" and "the player has an actual resumable
## session" are different facts (a fresh save has campaign_highest_
## unlocked_level == 1 but no resumable game at all). Set exclusively by
## start_campaign_resume() - see game.gd's _load_current_level(), which
## only calls it for a normal PLAY/CONTINUE session, never a QA Level
## Select one (see GameManager.entered_via_level_select).
var campaign_resume_level_id: int = 0
## String "x,y" (grid position) -> int (GridTypes.MirrorOrientation) for
## campaign_resume_level_id only - a single slot, not a history, since
## exactly one campaign level can be "in progress" at a time under linear
## progression. JSON-safe (Vector2i can't be a JSON object key) - see
## update_campaign_resume_state()/get_campaign_resume_orientations() for
## the Vector2i<->String conversion, which is the only place it happens.
var campaign_resume_orientations: Dictionary = {}
var campaign_resume_move_count: int = 0

## Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md): the
## player's current procedural progression pointer - the first not-yet-
## legitimately-completed Level 1-2000. Mirrors campaign_highest_unlocked_
## level's role but for the procedural population, which is namespaced
## completely separately (same reasoning as D54 - see the campaign_* field
## comments above). Only record_procedural_level_result() ever advances
## this, and only for a LEGITIMATE solve - QA Next (see LevelManager.
## SHOW_PROCEDURAL_QA_NEXT_BUTTON) never touches it.
var procedural_current_level: int = 1

## The ONE in-progress procedural puzzle a player can resume - mirrors
## campaign_resume_* exactly (see that field group's own doc comments for
## the full reasoning, including why 0 is a sentinel for "no resumable
## game" independent of progression). procedural_resume_generator_version
## is saved alongside the seed specifically so a future generator version
## bump can never silently regenerate a different board under an active
## player - see ProceduralLevelGenerator.GENERATOR_VERSION's own doc
## comment and PROCEDURAL_GENERATION.md "Versioning contract".
var procedural_resume_level_number: int = 0
var procedural_resume_seed: int = 0
var procedural_resume_generator_version: int = 0
var procedural_resume_orientations: Dictionary = {}
var procedural_resume_move_count: int = 0

## Phase 4 (D102): a gameplay Hint was GRANTED during the in-progress attempt (caps stars at 2). Persisted with the
## resume state so quitting + CONTINUE cannot regain 3-star eligibility. Additive: old saves default to false.
var procedural_resume_hint_used: bool = false
var campaign_resume_hint_used: bool = false

## Phase 4 (D102): best stars per PROCEDURAL puzzle identity, "<level>|<generator_version>" -> 1..3 (a sparse dictionary,
## never a fixed 2000-entry structure). Additive; old saves default to {}.
var procedural_best_stars: Dictionary = {}

## Phase 4 (D102): the one-time "NEW TUTORIAL: FUSION" nudge has been shown. Additive; default false.
var fusion_tutorial_nudge_seen: bool = false

## AdMob Foundation (D98): interstitial pacing. Additive fields (old saves default to 0).
## Only what makes sense to persist - never ad objects, SDK state or callbacks.
var ad_completions_since_interstitial: int = 0
var ad_last_interstitial_unix: int = 0
var ad_last_counted_level: int = 0

## Store release (STORE_RELEASE.md): owned store products, product_id -> true. The store is
## the authority - StoreManager re-checks at every launch - and entitlements NEVER travel
## with a cloud profile (adopt_cloud_data keeps the local ones).
var entitlements: Dictionary = {}
## Seconds of real gameplay (a level on screen, not paused). The cloud-save merge rule and
## its fresh-install guard read this, so menu time must never count.
var play_time_seconds: float = 0.0
## ISO-8601 UTC stamp of the last write - the cloud merge tie-breaker.
var saved_at: String = ""

## Emitted after every successful write (CloudSave queues a throttled push from it).
signal saved


func _ready() -> void:
	load_game()


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"highest_unlocked_level": 1,
		"completed_levels": {},
		"best_moves_per_level": {},
		"best_stars_per_level": {},
		"sound_enabled": true,
		"music_enabled": true,
		"campaign_highest_unlocked_level": 1,
		"campaign_completed_levels": {},
		"campaign_best_moves_per_level": {},
		"campaign_best_stars_per_level": {},
		"tutorial_highest_unlocked_level": 1,
		"tutorial_completed_levels": {},
		"campaign_resume_level_id": 0,
		"campaign_resume_orientations": {},
		"campaign_resume_move_count": 0,
		"procedural_current_level": 1,
		"procedural_resume_level_number": 0,
		"procedural_resume_seed": 0,
		"procedural_resume_generator_version": 0,
		"procedural_resume_orientations": {},
		"procedural_resume_move_count": 0,
		"procedural_resume_hint_used": false,
		"campaign_resume_hint_used": false,
		"procedural_best_stars": {},
		"fusion_tutorial_nudge_seen": false,
		"ad_completions_since_interstitial": 0,
		"ad_last_interstitial_unix": 0,
		"ad_last_counted_level": 0,
		"entitlements": {},
		"play_time_seconds": 0.0,
		"saved_at": "",
	}


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_data(_default_data())
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: could not open save file, using defaults.")
		_apply_data(_default_data())
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file malformed, using defaults.")
		_apply_data(_default_data())
		return

	_apply_data(parsed)


func _apply_data(data: Dictionary) -> void:
	highest_unlocked_level = int(data.get("highest_unlocked_level", 1))
	completed_levels = data.get("completed_levels", {})
	best_moves_per_level = data.get("best_moves_per_level", {})
	best_stars_per_level = data.get("best_stars_per_level", {})
	sound_enabled = bool(data.get("sound_enabled", true))
	music_enabled = bool(data.get("music_enabled", true))
	# .get() defaults mean a version-1 save (predating these fields)
	# loads cleanly with fresh campaign progress - see SAVE_VERSION.
	campaign_highest_unlocked_level = int(data.get("campaign_highest_unlocked_level", 1))
	campaign_completed_levels = data.get("campaign_completed_levels", {})
	campaign_best_moves_per_level = data.get("campaign_best_moves_per_level", {})
	campaign_best_stars_per_level = data.get("campaign_best_stars_per_level", {})
	# Same .get() defaults reasoning for a pre-tutorial save (version 1 or 2).
	tutorial_highest_unlocked_level = int(data.get("tutorial_highest_unlocked_level", 1))
	tutorial_completed_levels = data.get("tutorial_completed_levels", {})
	# Same .get() defaults reasoning for a pre-Phase-2 save (version <= 3) -
	# 0/{}/0 correctly means "no resumable game yet," not an error.
	campaign_resume_level_id = int(data.get("campaign_resume_level_id", 0))
	campaign_resume_orientations = data.get("campaign_resume_orientations", {})
	campaign_resume_move_count = int(data.get("campaign_resume_move_count", 0))
	# Same .get() defaults reasoning for a pre-Phase-3 save (version <= 4) -
	# procedural_current_level defaults to 1 (a fresh player starts at
	# Level 1) and the resume fields default to "no resumable game yet,"
	# matching campaign_resume_level_id's own 0-sentinel exactly.
	procedural_current_level = int(data.get("procedural_current_level", 1))
	procedural_resume_level_number = int(data.get("procedural_resume_level_number", 0))
	procedural_resume_seed = int(data.get("procedural_resume_seed", 0))
	procedural_resume_generator_version = int(data.get("procedural_resume_generator_version", 0))
	procedural_resume_orientations = data.get("procedural_resume_orientations", {})
	procedural_resume_move_count = int(data.get("procedural_resume_move_count", 0))
	procedural_resume_hint_used = bool(data.get("procedural_resume_hint_used", false))
	campaign_resume_hint_used = bool(data.get("campaign_resume_hint_used", false))
	procedural_best_stars = data.get("procedural_best_stars", {})
	fusion_tutorial_nudge_seen = bool(data.get("fusion_tutorial_nudge_seen", false))
	ad_completions_since_interstitial = int(data.get("ad_completions_since_interstitial", 0))
	ad_last_interstitial_unix = int(data.get("ad_last_interstitial_unix", 0))
	ad_last_counted_level = int(data.get("ad_last_counted_level", 0))
	var owned: Variant = data.get("entitlements", {})
	entitlements = owned if typeof(owned) == TYPE_DICTIONARY else {}
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	saved_at = str(data.get("saved_at", ""))


func save_game() -> bool:
	saved_at = Time.get_datetime_string_from_system(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not write save file.")
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.close()
	saved.emit()
	return true


## The whole profile as plain data - what save_game() writes and CloudSave pushes.
func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"highest_unlocked_level": highest_unlocked_level,
		"completed_levels": completed_levels,
		"best_moves_per_level": best_moves_per_level,
		"best_stars_per_level": best_stars_per_level,
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"campaign_highest_unlocked_level": campaign_highest_unlocked_level,
		"campaign_completed_levels": campaign_completed_levels,
		"campaign_best_moves_per_level": campaign_best_moves_per_level,
		"campaign_best_stars_per_level": campaign_best_stars_per_level,
		"tutorial_highest_unlocked_level": tutorial_highest_unlocked_level,
		"tutorial_completed_levels": tutorial_completed_levels,
		"campaign_resume_level_id": campaign_resume_level_id,
		"campaign_resume_orientations": campaign_resume_orientations,
		"campaign_resume_move_count": campaign_resume_move_count,
		"procedural_current_level": procedural_current_level,
		"procedural_resume_level_number": procedural_resume_level_number,
		"procedural_resume_seed": procedural_resume_seed,
		"procedural_resume_generator_version": procedural_resume_generator_version,
		"procedural_resume_orientations": procedural_resume_orientations,
		"procedural_resume_move_count": procedural_resume_move_count,
		"procedural_resume_hint_used": procedural_resume_hint_used,
		"campaign_resume_hint_used": campaign_resume_hint_used,
		"procedural_best_stars": procedural_best_stars,
		"fusion_tutorial_nudge_seen": fusion_tutorial_nudge_seen,
		"ad_completions_since_interstitial": ad_completions_since_interstitial,
		"ad_last_interstitial_unix": ad_last_interstitial_unix,
		"ad_last_counted_level": ad_last_counted_level,
		"entitlements": entitlements,
		"play_time_seconds": play_time_seconds,
		"saved_at": saved_at,
	}


func has_entitlement(product_id: String) -> bool:
	return bool(entitlements.get(product_id, false))


## Returns true when the value changed (and was saved).
func set_entitlement(product_id: String, owned: bool) -> bool:
	if has_entitlement(product_id) == owned:
		return false
	if owned:
		entitlements[product_id] = true
	else:
		entitlements.erase(product_id)
	save_game()
	return true


## Accumulated in memory; persisted by the next save (every accepted move saves).
func add_play_time(seconds: float) -> void:
	play_time_seconds += seconds


## Replaces the profile with a cloud copy and saves. Kept LOCAL, never taken from the
## cloud: entitlements (per store account), sound/music (per device), and the
## interstitial cadence (so switching devices can't dodge or double ads).
func adopt_cloud_data(cloud: Dictionary) -> void:
	var data := cloud.duplicate(true)
	var local := to_dict()
	for key in ["entitlements", "sound_enabled", "music_enabled", "ad_completions_since_interstitial", "ad_last_interstitial_unix", "ad_last_counted_level"]:
		data[key] = local[key]
	_apply_data(data)
	save_game()


func is_level_completed(level_id: int) -> bool:
	return bool(completed_levels.get(str(level_id), false))


func is_level_unlocked(level_id: int) -> bool:
	return level_id <= highest_unlocked_level


func get_best_moves(level_id: int) -> int:
	return int(best_moves_per_level.get(str(level_id), -1))


func get_best_stars(level_id: int) -> int:
	return int(best_stars_per_level.get(str(level_id), 0))


## Records a completion result, keeping only the best stars and best moves.
## Unlocks the next level. Persists immediately.
func record_level_result(level_id: int, moves_used: int, stars: int, total_level_count: int) -> void:
	var key := str(level_id)
	completed_levels[key] = true

	var previous_best_stars := get_best_stars(level_id)
	if stars > previous_best_stars:
		best_stars_per_level[key] = stars

	var previous_best_moves := get_best_moves(level_id)
	if previous_best_moves < 0 or moves_used < previous_best_moves:
		best_moves_per_level[key] = moves_used

	if level_id + 1 <= total_level_count and level_id + 1 > highest_unlocked_level:
		highest_unlocked_level = level_id + 1

	save_game()


## --- Campaign (player-facing) equivalents of the four functions above.
## Mirror is_level_completed()/is_level_unlocked()/get_best_moves()/
## get_best_stars()/record_level_result() exactly, against the
## campaign_* fields instead of the dev-level fields. See DECISIONS.md
## D54 for why the two populations are namespaced separately.

func is_campaign_level_completed(campaign_level_id: int) -> bool:
	return bool(campaign_completed_levels.get(str(campaign_level_id), false))


func is_campaign_level_unlocked(campaign_level_id: int) -> bool:
	return campaign_level_id <= campaign_highest_unlocked_level


func get_campaign_best_moves(campaign_level_id: int) -> int:
	return int(campaign_best_moves_per_level.get(str(campaign_level_id), -1))


func get_campaign_best_stars(campaign_level_id: int) -> int:
	return int(campaign_best_stars_per_level.get(str(campaign_level_id), 0))


func record_campaign_level_result(campaign_level_id: int, moves_used: int, stars: int, total_level_count: int) -> void:
	var key := str(campaign_level_id)
	campaign_completed_levels[key] = true

	var previous_best_stars := get_campaign_best_stars(campaign_level_id)
	if stars > previous_best_stars:
		campaign_best_stars_per_level[key] = stars

	var previous_best_moves := get_campaign_best_moves(campaign_level_id)
	if previous_best_moves < 0 or moves_used < previous_best_moves:
		campaign_best_moves_per_level[key] = moves_used

	if campaign_level_id + 1 <= total_level_count and campaign_level_id + 1 > campaign_highest_unlocked_level:
		campaign_highest_unlocked_level = campaign_level_id + 1

	save_game()


## --- Phase 2 (Direct Play + Continue Flow, see DECISIONS.md D85): exact
## mid-level resume for the campaign_resume_* fields above.

## Is there an actual resumable campaign game right now? Deliberately NOT
## "campaign_highest_unlocked_level > 1 or campaign_completed_levels.size()
## > 0" - see campaign_resume_level_id's own doc comment for why that
## would be the wrong signal.
func has_resumable_campaign_game() -> bool:
	return campaign_resume_level_id > 0


## Starts tracking a fresh (just-entered or just-reset) campaign level as
## the resumable game - clears any previous level's saved orientations/
## move count, since only one level is ever "in progress" at a time.
## Called by game.gd whenever a normal (non-QA-Level-Select) session
## enters a campaign level that isn't already the tracked resume level,
## and whenever Reset/Retry explicitly restart the current one.
func start_campaign_resume(campaign_level_id: int) -> void:
	campaign_resume_level_id = campaign_level_id
	campaign_resume_orientations = {}
	campaign_resume_move_count = 0
	campaign_resume_hint_used = false
	save_game()


## Event-driven persistence (called once per accepted move, never per
## frame - see game.gd._on_move_made()). `orientations` is GridManager.
## tile_orientations (Vector2i -> GridTypes.MirrorOrientation); converted
## to a JSON-safe String-keyed Dictionary here, the only place this
## project converts a grid position to/from a save-file key.
func update_campaign_resume_state(orientations: Dictionary, move_count: int) -> void:
	var serializable := {}
	for pos in orientations:
		serializable["%d,%d" % [pos.x, pos.y]] = int(orientations[pos])
	campaign_resume_orientations = serializable
	campaign_resume_move_count = move_count
	save_game()


## Inverse of update_campaign_resume_state()'s key conversion - returns
## Vector2i -> int (GridTypes.MirrorOrientation), ready for GridManager.
## restore_orientations(). Malformed/foreign keys are skipped rather than
## crashing (defensive against a hand-edited or corrupted save file).
func get_campaign_resume_orientations() -> Dictionary:
	var result := {}
	for key in campaign_resume_orientations:
		var parts := String(key).split(",")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			result[Vector2i(int(parts[0]), int(parts[1]))] = int(campaign_resume_orientations[key])
	return result


## --- Tutorial (T01-T10) equivalents. No stars/best-moves - see the
## `tutorial_*` field comments above for why. Otherwise mirrors
## is_campaign_level_completed()/is_campaign_level_unlocked()/
## record_campaign_level_result() against the tutorial_* fields.

func is_tutorial_level_completed(tutorial_level_id: int) -> bool:
	return bool(tutorial_completed_levels.get(str(tutorial_level_id), false))


func is_tutorial_level_unlocked(tutorial_level_id: int) -> bool:
	return tutorial_level_id <= tutorial_highest_unlocked_level


## Records a tutorial as completed and unlocks the next one. Replaying an
## already-completed tutorial (explicitly allowed - see the brief) calls
## this again harmlessly: `completed_levels[key] = true` is idempotent
## and the unlock-next guard only ever moves progress forward.
func record_tutorial_level_result(tutorial_level_id: int, total_level_count: int) -> void:
	tutorial_completed_levels[str(tutorial_level_id)] = true
	if tutorial_level_id + 1 <= total_level_count and tutorial_level_id + 1 > tutorial_highest_unlocked_level:
		tutorial_highest_unlocked_level = tutorial_level_id + 1
	save_game()


## --- Phase 3 (Procedural Generator V1, see PROCEDURAL_GENERATION.md):
## exact mid-puzzle resume for the procedural_* fields above. Mirrors the
## campaign_resume_* function group exactly (has_resumable_campaign_game()/
## start_campaign_resume()/update_campaign_resume_state()/
## get_campaign_resume_orientations() above) - see those functions' own
## doc comments for the full reasoning, which applies identically here.

func has_resumable_procedural_game() -> bool:
	return procedural_resume_level_number > 0


## NEW GAME flow (D107): does the player have MEANINGFUL main-game progress worth a confirmation? Deliberately not
## "a save file exists" (a fresh install writes one for settings). True when progression moved past Level 1, any
## procedural star exists, or the resumable board is past Level 1 / has at least one move or a Hint used.
func has_meaningful_main_progress() -> bool:
	if procedural_current_level > 1 or not procedural_best_stars.is_empty():
		return true
	return has_resumable_procedural_game() and (procedural_resume_level_number > 1 or procedural_resume_move_count > 0 or procedural_resume_hint_used)


## NEW GAME flow (D107): the ONE authoritative reset of the MAIN procedural run, saved once. Resets: procedural_current_level,
## all procedural_resume_* (level, seed, generator version, orientations, moves, hint-used), procedural_best_stars,
## ad_last_counted_level (per-level dedupe only). PRESERVES: sound/music, ALL tutorial progress (a Fusion tutorial
## unlock EARNED by reaching procedural Level 150 is materialised into tutorial_highest_unlocked_level first),
## fusion_tutorial_nudge_seen, the legacy campaign/dev-level fields (QA population), and the interstitial cadence
## (ad_completions_since_interstitial, ad_last_interstitial_unix - resetting them would let New Game dodge ads).
## Returns false (and restores every touched field) if the save could not be written.
func reset_main_progress_for_new_game() -> bool:
	var snapshot := {
		"tutorial_highest_unlocked_level": tutorial_highest_unlocked_level,
		"procedural_current_level": procedural_current_level,
		"procedural_resume_level_number": procedural_resume_level_number,
		"procedural_resume_seed": procedural_resume_seed,
		"procedural_resume_generator_version": procedural_resume_generator_version,
		"procedural_resume_orientations": procedural_resume_orientations,
		"procedural_resume_move_count": procedural_resume_move_count,
		"procedural_resume_hint_used": procedural_resume_hint_used,
		"procedural_best_stars": procedural_best_stars,
		"ad_last_counted_level": ad_last_counted_level,
	}
	if procedural_current_level >= LevelManager.FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL and tutorial_highest_unlocked_level < LevelManager.FUSION_TUTORIAL_FIRST:
		tutorial_highest_unlocked_level = LevelManager.FUSION_TUTORIAL_FIRST
	if procedural_current_level >= LevelManager.SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL and tutorial_highest_unlocked_level < LevelManager.SELECTOR_TUTORIAL_FIRST:
		tutorial_highest_unlocked_level = LevelManager.SELECTOR_TUTORIAL_FIRST
	procedural_current_level = 1
	procedural_resume_level_number = 0
	procedural_resume_seed = 0
	procedural_resume_generator_version = 0
	procedural_resume_orientations = {}
	procedural_resume_move_count = 0
	procedural_resume_hint_used = false
	procedural_best_stars = {}
	ad_last_counted_level = 0
	if save_game():
		return true
	push_warning("SaveManager: NEW GAME reset could not be saved - restoring the previous state.")
	for key in snapshot:
		set(key, snapshot[key])
	return false


## Starts tracking a fresh (just-entered or just-reset) procedural level as
## the resumable game. `generator_version`/`seed` are saved alongside the
## level number specifically so CONTINUE can regenerate the EXACT same
## base puzzle later (see ProceduralLevelGenerator.generate() - the same
## level_number + generator_version always derives the same seed, but
## persisting the seed directly here is what lets a future generator
## version bump change what NEW levels look like without ever altering an
## already-active player's in-progress one).
func start_procedural_resume(level_number: int, seed_value: int, generator_version: int) -> void:
	procedural_resume_level_number = level_number
	procedural_resume_seed = seed_value
	procedural_resume_generator_version = generator_version
	procedural_resume_orientations = {}
	procedural_resume_move_count = 0
	procedural_resume_hint_used = false
	save_game()


## Event-driven persistence (called once per accepted move, never per
## frame - see game.gd._on_move_made()), identical Vector2i<->String key
## conversion as update_campaign_resume_state().
func update_procedural_resume_state(orientations: Dictionary, move_count: int) -> void:
	var serializable := {}
	for pos in orientations:
		serializable["%d,%d" % [pos.x, pos.y]] = int(orientations[pos])
	procedural_resume_orientations = serializable
	procedural_resume_move_count = move_count
	save_game()


## Inverse of update_procedural_resume_state()'s key conversion, identical
## to get_campaign_resume_orientations().
func get_procedural_resume_orientations() -> Dictionary:
	var result := {}
	for key in procedural_resume_orientations:
		var parts := String(key).split(",")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			result[Vector2i(int(parts[0]), int(parts[1]))] = int(procedural_resume_orientations[key])
	return result


## Records a LEGITIMATE procedural level completion: advances
## procedural_current_level only if `level_number` IS the player's current
## progression pointer - a level reached by jumping ahead (QA Next) or any
## other means never advances real progression, only completing the
## actual next-in-line level does. Mirrors record_campaign_level_result()
## exactly, including NOT touching the resume_* fields here (harmless to
## leave stale - see start_campaign_resume()'s own reasoning: resume state
## is only ever consulted by comparing against the SPECIFIC level number
## being loaded next, and a just-completed level is never reloaded, so the
## next _load_current_level() call naturally starts the new level fresh
## via start_procedural_resume() without needing an explicit clear here).
## Deliberately the ONLY function that touches procedural_current_level -
## see LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON's own doc comment for
## why QA Next must never call this.
## A real gameplay Hint was granted in the current attempt (see StarScoring). Persisted immediately.
func mark_hint_used(procedural: bool) -> void:
	if procedural:
		procedural_resume_hint_used = true
	else:
		campaign_resume_hint_used = true
	save_game()


func _procedural_star_key(level_number: int, generator_version: int) -> String:
	return "%d|%d" % [level_number, generator_version]


func get_procedural_best_stars(level_number: int, generator_version: int) -> int:
	return int(procedural_best_stars.get(_procedural_star_key(level_number, generator_version), 0))


## Keeps the BEST result per (level, generator version) identity - a worse replay never lowers it.
func record_procedural_stars(level_number: int, generator_version: int, stars: int) -> void:
	var key := _procedural_star_key(level_number, generator_version)
	if stars > int(procedural_best_stars.get(key, 0)):
		procedural_best_stars[key] = stars
		save_game()


func record_procedural_level_result(level_number: int) -> void:
	if level_number == procedural_current_level:
		procedural_current_level += 1
	save_game()
