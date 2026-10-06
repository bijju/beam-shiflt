# BEAMSHIFT — COMPLETE PROJECT FORENSIC AUDIT & HANDOFF

> Generated 2026-10-03 by a read-only inspection of the repository (Claude Code, Sonnet 5.5). The repository, scripts, scenes, resources, configuration and Git state are the source of truth; documentation was used only to recover history and then cross-checked. Where documentation and code disagree it is flagged **DOC≠CODE**.
>
> **How to use this file:** paste the section titled `# BEAMSHIFT MASTER HANDOFF FOR CHATGPT` (Part 44) if you want the short self-contained version. Everything else is the evidence behind it.
>
> **Two corrections to the brief that matter immediately**
> 1. The real project folder is `D:\4Sagez\GodotGames\GitClones\beam-shiflt` (note **shiflt**, not `beam-shift`). `beam-shift` does not exist on disk.
> 2. The brief assumes Firebase / Google Sign-In / cloud save exist. **They were deleted on 2026-10-01** (commit `3df9252`, DECISIONS D118). Android identity is now **Google Play Games (optional, display name only)**; iOS is **Sign in with Apple (optional)**; progress is **local-only**. Many older docs still describe Firebase as live (DOC≠CODE, see Part 25).

---

## Evidence labels used throughout

`CODE` = read in source · `TEST` = covered by the automated suite (I ran it: 152 production tests, 0 failed, 3,681 assertions; QA-mode subset 34 tests, 0 failed) · `DOC-DEVICE` = documentation says the owner verified it on a physical Android device (I cannot independently confirm) · `UNVERIFIED` = no evidence either way.

---

## PART 1 — PROJECT IDENTITY

| Item | Value | Evidence |
|---|---|---|
| Game name | **BeamShift** (`config/name="BeamShift"`) | `project.godot` |
| Publisher / developer | MACLEPRO INC / 4 Sagez Studios Pvt. Ltd. | `scripts/ui/privacy_policy_text.gd`, `scripts/ui/about_screen.gd` |
| Contact | sage@maclepro.in | privacy policy text |
| Repo root | `D:\4Sagez\GodotGames\GitClones\beam-shiflt` | filesystem |
| Git remote | `origin` = `https://github.com/bijju/beam-shiflt.git` (branches `origin/main`, `origin/dev_abhilas`); the separate public privacy-policy repo is `AbhilashDeva/beamshift-privacy` | `git remote -v` |
| Engine | Godot **4.7** feature tag (`config/features=("4.7","Mobile")`), developed/validated with **4.7.1.stable** (`D:\Godot_v4.7.1-stable_win64.exe`; CI `GODOT_VERSION: 4.7.1-stable`) | project.godot, `.github/workflows/release.yml` |
| Language | GDScript (typed where practical) | CODE |
| `config/version` (project.godot) | `1.0.0` | project.godot |
| Android versionCode / versionName | **10004 / "1.0.1"** in both Android presets | `export_presets.cfg` preset.0/1 |
| iOS | short_version `1.0.0`, version `10000` | `export_presets.cfg` preset.2 |
| **DOC≠CODE / drift** | `project.godot config/version=1.0.0` vs presets `1.0.1`; the newest local AAB is named `…-10005-internal.aab` but no preset or doc mentions 10005 (CI `tools/ci/stamp_version.sh` stamps versions, so presets lag) | see Part 22 |
| Package / application ID | `com.foursagez.beamshift` (Android and iOS bundle id) | presets |
| Main scene | `res://scenes/ui/studio_splash.tscn` | project.godot |
| Platforms | Android (primary; APK + AAB), iOS (pipeline prepared, never device-verified in repo docs), desktop/editor (dev only, no export preset) | presets |
| Orientation | Portrait (`window/handheld/orientation=1`) | project.godot |
| Reference resolution | 1080 × 1920 (`window/size/viewport_*`) | project.godot |
| Stretch | `window/stretch/mode="canvas_items"`, `aspect="expand"` (logical canvas is 1080 wide and grows taller on tall phones) | project.godot |
| Renderer | `renderer/rendering_method="mobile"`; Windows driver d3d12; ETC2/ASTC import on; physics engine Jolt (unused by gameplay) | project.godot |
| Theme | `gui/theme/custom="res://themes/beamshift_theme.tres"` (generated from `scripts/ui/beam_ui.gd`) | project.godot |
| quit on back | `config/quit_on_go_back=false` (screens handle Android Back themselves) | project.godot |
| Input map | **No custom input actions** (`[input]` section absent). Touch and mouse both go through Godot's default GUI input (`Control._gui_input`). | project.godot |
| Current branch | `dev_abhilas` | git |
| HEAD | `c2c7752e64136a174f76add4dc899fb9c3781ac7` "Add GitHub Pages nojekyll marker" (2026-10-03) | git |
| Dev stage | **Pre-store-submission release-candidate phase**: gameplay content complete; Android RC validated on a device (per docs) before Firebase removal; since then UI redesign, Firebase removal, mandatory-internet gate, privacy policy, Families hardening (age screen + rewarded-Hint confirmation) — most post-Oct-1 changes are **uncommitted** and **not device-verified** | git status, docs |

### The game concept (what the player does)

BeamShift is a deterministic, grid-based **laser-reflection logic puzzle**. A board holds one or more **emitters** that fire coloured beams in a fixed direction. The player **taps tiles to rotate them** — mirrors and splitters toggle between the two diagonals `/` and `\`; the later "Fusion Node" and "Splitter Selector" tiles step through 4 output directions clockwise. The goal is to route every **required target** so each is hit by a beam of an accepted colour, **without hitting any hazard**. Beams can be recoloured by **filters**, teleported by **portals**, gated by **switch → gate** dependencies, split by **splitters/prisms**, merged by **Fusion Nodes**, and rerouted by **Splitter Selectors**. Rules stay simple; difficulty comes from combining mechanics (dependency chains, shared mirrors, misdirection) rather than board size (`GridManager.MAX_COLUMNS = 8`, square cells only).

There is **no placing, dragging or removing of pieces**; rotation is the only player action. There is **no undo** (grep finds none), but **Reset** (restart level, same puzzle), **Pause → Restart**, **Hint** (one tile ring, rewarded-ad-gated in main progression), and a **move counter + star rating** exist.

### Core gameplay loop (as actually wired today)

```
Android launch
→ studio splash (MaclePro logo, then 4Sagez logo)          scripts/ui/studio_splash.gd
→ [Android only, first launch while age unknown] AGE SELECTION screen   scenes/ui/age_selection.tscn
→ Main Menu: NEW GAME / CONTINUE / TUTORIALS / ABOUT / SETTINGS  (no Quit button)
→ NEW GAME or CONTINUE  → GameManager.start_procedural_level(n)      (PLAY/CONTINUE target PROCEDURAL levels 1–3000)
→ Game scene (HUD + PuzzleGrid) loads LevelData from ProceduralLevelGenerator
→ player taps a mirror/splitter/selector → GridManager rotates it → LaserSystem.simulate_until_stable()
→ beams redraw; targets/switches/gates/hazards update
→ all required targets active and no hazard → level_solved → stars computed (StarScoring) → SaveManager records
→ Level Complete popup (stars, moves) → NEXT LEVEL (maybe interstitial) → next procedural level
```
**Level Select is NOT part of the normal player loop.** It is a QA/dev screen reachable only through a "Level Select (QA)" button that appears only when `BuildConfig.QA_TOOLS` is true (internal-QA builds). The committed build mode is `MODE_PRODUCTION`, so normal players never see it. The 140 handcrafted campaign levels are therefore reachable **only** in QA builds.

### Intended overall progression

1. **Tutorial pack T01–T34** (guided, from the main menu): T01–T10 Era-1 mechanics, T11–T20 "Era 2" mechanics (prism, one-way reflector, beam receiver/remote emitter), T21–T28 Fusion (unlocks when procedural Level 150 is reached or after T20), T29–T34 Splitter Selector (unlocks at procedural Level 1900).
2. **Procedural main progression, Levels 1–3000**: generated on demand and deterministic per `(level, generator_version)`. Levels 1–2000 use generators V3/V4 (V4 default; V1/V2 frozen for old saves); Levels 2001–3000 use generator V5 (adds the Splitter Selector). Difficulty bands from "Foundation" to "Selector Mastery".
3. The handcrafted 140-level campaign (100 Era-1 + 40 Era-2) is retained as a QA population and as the source of test fixtures; it is no longer the player's path.

---

## PART 2 — DIRECTORY STRUCTURE

Tracked files: **1,747** (`git ls-files`). Biggest groups: `addons/admob` 469, `levels/campaign` 281, `assets/ui` 208, `assets/gameplay` 130, `levels/tutorial` 68, `addons/GodotPlayGameServices` 60, `scripts/ui` 56, `tools/tests` 51, `scripts/gameplay` 48, `levels/editor_fixtures` 48, `assets/sfx` 44, `scripts/tools` 43, `scripts/procedural` 40.

```
beam-shiflt/
├─ project.godot                      engine config + 10 autoloads
├─ export_presets.cfg                 Android Debug / Android (AAB) / iOS presets
├─ CLAUDE.md                          permanent AI-session rules (1,553 lines) – the project's de-facto constitution
├─ PROJECT_HANDOFF.md, CURRENT_STATUS.md, ARCHITECTURE.md, DECISIONS.md (D1…D118+), ROADMAP.md, TEST_PLAN.md,
│  CHANGELOG.md, README.md, NEXT_AI_PROMPT.md, NEXT_CLAUDE_PROMPT.md,
│  CAMPAIGN_DESIGN.md, ERA_2_DESIGN.md, TUTORIAL_SYSTEM.md, LEVEL_EDITOR.md, PROCEDURAL_GENERATION.md,
│  AUDIO_SYSTEM.md, ADS_MONETIZATION.md, STORE_RELEASE.md, PRIVACY_AUDIT.md        documentation set (Part 25)
├─ docs/
│  ├─ privacy-policy/index.html       GENERATED web copy of the privacy policy (GitHub Pages source)
│  ├─ .nojekyll
│  └─ BEAMSHIFT_MASTER_HANDOFF.md     (this file)
├─ scenes/
│  ├─ ui/        16 screens/popups (splash, main menu, settings, account, about, privacy policy, age selection,
│  │             level select, tutorial select, level/tutorial buttons, pause, level complete, tutorial complete/panel,
│  │             menu_gameplay_preview)
│  ├─ gameplay/  game.tscn (HUD + grid host), grid.tscn (PuzzleGrid), two VFX scenes
│  └─ tiles/     16 tile scenes (one per TileType)
├─ scripts/
│  ├─ managers/  autoload logic + RefCounted helpers (save/level/game/audio/ad/store/internet/platform_account, star_scoring,
│  │             tutorial_manager, build_config, age_group)
│  ├─ gameplay/  laser_system.gd, grid_types.gd, grid_manager.gd, game.gd, hint_manager.gd, tile scripts, impact VFX
│  ├─ resources/ LevelData, TilePlacement, TutorialLevelData, TutorialStepData, EraTheme
│  ├─ ui/        screens, BeamUI design system, SafeAreaMargin, UIConstants, privacy policy text, hint dialog
│  ├─ ads/       AdConfig + AdBackend (AdMob, fake)
│  ├─ store/     StoreConfig + Play Billing / StoreKit backends
│  ├─ procedural/ the V1–V5 procedural level generator (20 files, runtime dependency)
│  └─ tools/     DEV-ONLY solver/validator/metrics/audit scenes (excluded from exports)
├─ levels/
│  ├─ level_01..15.gd                 15 dev/regression levels
│  ├─ campaign/stage_01..10/          100 Era-1 levels;  campaign/era2_stage_01/ 40 Era-2 levels
│  ├─ tutorial/t01..t34.gd            34 guided tutorials
│  ├─ editor_fixtures/                12 level-editor/validator fixtures (dev only)
│  ├─ fusion_qa/, selector_qa/        QA puzzle sets
│  └─ hint_solutions.json             174 solver-authored hint solutions (c1..c140, t1..t34)
├─ assets/
│  ├─ gameplay/   tile art (runtime 512px set + source 1254px set + era2/fusion/selector)
│  ├─ ui/         UI art (buttons, icons, panels, backgrounds, HUD, era2)
│  ├─ backgrounds/, branding/, fonts/ (Rajdhani), sfx/ (22 .ogg), audio/default_bus_layout.tres
├─ themes/beamshift_theme.tres        GENERATED UI theme (never hand-edit)
├─ addons/
│  ├─ admob/                 Poing Studios AdMob plugin 5.1.0 (Google GMA Next-Gen SDK 1.4.0, UMP 4.0.0)
│  ├─ GodotGooglePlayBilling/ plugin 3.3.0
│  └─ GodotPlayGameServices/  plugin 3.4.0 (play-services-games-v2 21.0.0)
├─ config/        ad_ids.local.json, ad_test_devices.local.json   (GITIGNORED, local secrets-ish; never committed)
├─ android/       Gradle build template (GITIGNORED, regenerated by export; 1.5 GB)
├─ builds/        APK/AAB outputs (GITIGNORED; 7.3 GB, 51 files)
├─ tools/
│  ├─ tests/      automated suite (run_coverage.ps1, 20 case files, 152 tests, fakes)
│  ├─ level_editor/   runtime level editor scene (dev only)
│  ├─ ci/         stamp_version.sh, stamp_store_config.sh, set_build_mode.sh, Apple secret helpers
│  ├─ privacy/    build_policy_html.gd (policy text → HTML)
│  ├─ ui_shots/   screenshot driver + theme builder
│  └─ ios_plugin_src/ README for the iOS plugins CI downloads
├─ references/ci-cd.md     iOS CI/CD architecture doc
├─ .github/workflows/release.yml   "Release CD" pipeline
├─ project.godot.before_admob_test   STALE untracked backup of project.godot (still lists removed CloudSave/FirebaseAuth autoloads) – legacy, safe to ignore
└─ .godot/ (cache)  – ignored
```

---

## PART 4 — PROJECT.GODOT AUDIT

(Full text inspected.)

* `[application]`: name BeamShift, version 1.0.0, main scene studio_splash, `quit_on_go_back=false`, features 4.7/Mobile, icon `assets/branding/bs_app_icon.png`.
* `[audio]`: bus layout `res://assets/audio/default_bus_layout.tres` — buses **Master, SFX, UI** (SFX and UI send to Master).
* `[display]`: 1080×1920, stretch canvas_items/expand, portrait.
* `[editor_plugins] enabled`: admob, GodotGooglePlayBilling, GodotPlayGameServices.
* `[gui] theme/custom`: `themes/beamshift_theme.tres`.
* `[rendering]`: mobile renderer, d3d12 on Windows, ETC2/ASTC.
* `[physics]`: Jolt (unused; CLAUDE rule 1 forbids physics for puzzle logic).
* **No `[admob]` section in the committed file.** The Android AdMob app id is injected only at export time by `tools/ci/stamp_store_config.sh` (appends `[admob] general/android/app_id`); an unstamped build gets the plugin's inert Google sample APPLICATION_ID and ads stay off (`AdConfig.ads_active()` false when production ids are missing).
* No input actions, no custom feature flags in project.godot — all feature flags are GDScript constants (`BuildConfig`, `LevelManager`, `AdConfig`).

### Autoloads (10, in load order)

| # | Name | Script | Responsibility | Important state | Important methods | Signals | Dependencies |
|---|---|---|---|---|---|---|---|
| 1 | `SaveManager` | `scripts/managers/save_manager.gd` (619 lines) | The ONE persistence layer: JSON save at `user://savegame.json` | `highest_unlocked_level`, `completed_levels`, `best_*_per_level`, `sound_enabled`, `music_enabled`, `campaign_*`, `tutorial_*`, `campaign_resume_*`, `procedural_current_level`, `procedural_resume_*`, `procedural_best_stars`, `fusion_tutorial_nudge_seen`, `ad_*` counters, `entitlements`, `age_group`, `play_time_seconds`, `saved_at` | `load_game`, `save_game`, `to_dict`, `record_*_result`, `start_*_resume`, `update_*_resume_state`, `reset_main_progress_for_new_game`, `has_meaningful_main_progress`, `set_entitlement/has_entitlement`, `set_age_group`, `mark_hint_used`, `record_procedural_stars` | `saved` | none (pure; by design D6) |
| 2 | `LevelManager` | `scripts/managers/level_manager.gd` (598) | Level catalogs + unlock rules + generator-version routing + all QA flags | `LEVEL_PATHS` (15), `CAMPAIGN_LEVEL_PATHS` (140), `TUTORIAL_LEVEL_PATHS` (34); caches | `get_level`, `get_campaign_level`, `get_tutorial_level`, `is_campaign_level_selectable`, `is_tutorial_level_selectable`, `get_procedural_generation_result`, `procedural_generator_version_for_new_play`, `calculate_*_stars` | – | SaveManager, ProceduralLevelGenerator, BuildConfig, EraTheme, StarScoring |
| 3 | `GameManager` | `scripts/managers/game_manager.gd` (299) | Scene navigation and session mode flags | `current_level_id`, `current_procedural_level`, `current_tutorial_id`, `is_tutorial_mode`, `is_procedural_mode`, `entered_via_level_select`, `is_editor_playtest`, `is_v3_prototype_mode`, `is_fusion_test_mode`, `is_selector_test_mode`, `is_v5_test_mode` | `play_game`, `continue_game`, `start_new_game`, `start_procedural_level`, `start_level`, `start_tutorial`, `go_to_*`, `quit_game`, `start_v3_prototype/fusion_test/selector_test/v5_test` | – | SaveManager, LevelManager |
| 4 | `AudioManager` | `scripts/managers/audio_manager.gd` (265) | Centralised SFX: 22 events, 10-voice pool, SFX/UI buses | `_streams`, `_pool` | `play_*()` (22 semantic methods), `set_sound_enabled`, `set_sfx_volume_linear` | – | SaveManager (sound flag) |
| 5 | `AdManager` | `scripts/managers/ad_manager.gd` (362) | The only game-facing ad API: rewarded Hint, interstitial pacing, consent | `state` (IDLE/SHOWING_REWARDED/SHOWING_INTERSTITIAL), `_sdk_ready`, `_rewarded_ready`, `_interstitial_ready` | `show_rewarded_hint(cb)`, `register_completion`, `maybe_show_interstitial_after_completion`, `is_interstitial_due`, `forced_ads_removed`, `on_forced_ads_removed`, `hint_requires_ad`, `show_privacy_options` | `rewarded_*`, `reward_earned`, `interstitial_*` | AdConfig, AdBackendAdMob/Fake, SaveManager, InternetManager, StoreConfig |
| 6 | `StoreManager` | `scripts/managers/store_manager.gd` (168) | Purchases/entitlements policy over a per-platform backend (loaded by path) | `_backend`, `_busy`, `_restoring` | `purchase`, `restore_purchases`, `can_purchase`, `price_text`, `has_store`, `owns_no_forced_ads` | `changed`, `purchase_finished(success,msg)` | StoreConfig, SaveManager, AdManager, play_billing_backend / store_kit_backend |
| 7 | `GodotPlayGameServices` | `uid://bsds5unhjravp` → `addons/GodotPlayGameServices/scripts/autoloads/godot_play_game_services.gd` | Plugin entry; wraps the Android singleton | `android_plugin` | `initialize()` (called only by PlatformAccount) | `image_stored` | native plugin |
| 8 | `InternetManager` | `scripts/managers/internet_manager.gd` (160) | Real connectivity state via HTTPS probe | `is_online`, `gate_passed` | `is_blocking`, `request_check`, `retry` | `check_started`, `check_completed`, `internet_lost`, `internet_restored` | HTTPRequest to `https://www.gstatic.com/generate_204` (5 s timeout, 8 s period, 2 s fast retry, 2 failures to declare lost) |
| 9 | `InternetBlocker` | `scripts/managers/internet_blocker.gd` (150) | The ONE global "internet required" gate: CanvasLayer 128, pauses the SceneTree while blocking, shows INTERNET CONNECTION REQUIRED/LOST + RETRY | `_blocking`, `_prior_paused` | `is_blocking`, `is_panel_visible` | – | InternetManager |
| 10 | `PlatformAccount` | `scripts/managers/platform_account.gd` (211) | Optional platform identity (display only): Play Games (Android, 13+ only), Sign in with Apple (iOS), none on desktop | `platform`, `connected`, `display_name`, `busy`, `last_message`, `play_games_setup_attempts` | `sign_in`, `sign_out` (iOS only), `apply_age_group`, `is_supported`, `service_name` | `changed` | SaveManager.age_group, AgeGroup, GodotPlayGameServices |

Non-autoload helpers that behave like systems: `BuildConfig` (consts), `StarScoring`, `HintManager` (owned by game.gd), `TutorialManager` (RefCounted owned by game.gd), `AgeGroup`, `EraTheme`, `AdConfig`, `StoreConfig`, `BeamUI`, `UIConstants`.

---

## PART 5 — ARCHITECTURE (actual)

**Non-negotiable rules (CLAUDE.md, verified in code):** no physics/raycast for puzzle logic (grep: none); levels are data (`LevelData` + `TilePlacement`); the reflection truth table exists only in `GridTypes.reflect()`; `GridManager` owns authoritative state while tile scenes are dumb views; `LaserSystem` loop protection (`visited_states`) is mandatory; dev tools (`scripts/tools/**`, `tools/**`) are export-excluded and runtime code never calls them (I grepped: the only mentions in `scripts/procedural/**` and `level_data.gd` are comments).

| System | Script / scene | Responsibility & key facts | Status |
|---|---|---|---|
| Grid types | `scripts/gameplay/grid_types.gd` | enums `TileType` (17 values), `Direction` (UP,RIGHT,DOWN,LEFT), `MirrorOrientation` (SLASH,BACKSLASH), `BeamColor` (WHITE,RED,GREEN,BLUE,YELLOW,MAGENTA,CYAN); `reflect()`, `target_accepts_color()`, prism channel rule, one-way rule, `combine_beam_colors()` | IMPLEMENTED |
| Laser simulation | `scripts/gameplay/laser_system.gd` (452 lines) | pure static simulation, see Part 8 | IMPLEMENTED |
| Board | `scripts/gameplay/grid_manager.gd` (1019) + `scenes/gameplay/grid.tscn` | builds tile nodes from `LevelData`, per-axis cell-size layout (`MAX_COLUMNS=8`, `MIN_COMFORTABLE_CELL_SIZE=96`, `GRID_SAFETY_MARGIN=8`), tap handling, runs simulation, draws beams (glow 18 px + core 5 px), spawns mirror impact VFX, drives audio transitions, hint ring, tutorial highlight/dim; signals `move_made`, `simulation_updated`, `level_solved`, `tile_tap_attempted` | IMPLEMENTED |
| Game scene | `scripts/gameplay/game.gd` (940) + `scenes/gameplay/game.tscn` | HUD (top bar: back/level/moves; bottom: Hint/Reset/Pause), loads the right level for the session mode, moves, completion, stars, popups, hint/ad glue, tutorial integration, QA labels | IMPLEMENTED |
| Level data | `scripts/resources/level_data.gd`, `tile_placement.gd` | LevelData: id, name, grid w/h, `optimal_moves`, `tiles`; TilePlacement: type, position, direction, mirror_orientation, rotatable, color, required, pair_id, gate_id, initial_open_state, link_id + `make_*` factories | IMPLEMENTED |
| Level loading / catalogs | `LevelManager` | see Part 9 | IMPLEMENTED |
| Win detection | `LaserSystem.simulate()` → `solved` (all required targets active, ≥1 required target, no hazard hit); `GridManager` sets `is_solved` once and emits `level_solved`; `game.gd._on_level_solved` finishes | IMPLEMENTED |
| Stars | `scripts/managers/star_scoring.gd` | ≤optimal+2 → 3★, ≤optimal+6 → 2★, else 1★; a granted Hint caps at 2★; optimal source priority: `verified_optimal_moves` > `intended_moves` > legacy `optimal_moves` | IMPLEMENTED/TEST |
| Hint | `scripts/gameplay/hint_manager.gd`, game.gd, `levels/hint_solutions.json` | one request = one tile ring (6 s auto-clear), from KNOWN solutions only (procedural `solution_orientations`; JSON for campaign/tutorial); `request_hint()` (permission) vs `grant_hint()` (reveal) seam; gold attention pulse | IMPLEMENTED |
| Tutorial | `scripts/managers/tutorial_manager.gd` (+ `scripts/resources/tutorial_*.gd`, `scripts/ui/tutorial_*.gd`, `levels/tutorial/t01..t34.gd`) | step machine, 4 step types; see Part 13 | IMPLEMENTED |
| Settings / Account / About / Privacy | `scenes/ui/settings_menu.tscn` etc. | Sound/Music toggles, account entry, ads & purchases (NO FORCED ADS, RESTORE PURCHASES), Privacy Options (UMP, hidden unless required), Privacy Policy (native screen), About | IMPLEMENTED |
| Audio | `AudioManager` | SFX only (22 `.ogg`); **no music tracks exist** — the Music toggle only stores a flag | IMPLEMENTED (SFX) / PLACEHOLDER (music toggle) |
| Ads | `AdManager` + `scripts/ads/*` | Part 16 | IMPLEMENTED (device-verified per docs for RC3) |
| Billing/IAP | `StoreManager` + `scripts/store/*` | Part 19 | IMPLEMENTED; purchase flow NOT device-verified |
| Auth / identity | `PlatformAccount`, `account_screen.gd`, `age_selection.gd` | Parts 17/18 | IMPLEMENTED (Play Games sign-in unverified on device) |
| Connectivity gate | `InternetManager` + `InternetBlocker` | mandatory internet; Back handlers guard with `InternetManager.is_blocking()` | IMPLEMENTED/TEST |
| Procedural generator | `scripts/procedural/*` | Part 9/10 | IMPLEMENTED |
| Era theming | `scripts/resources/era_theme.gd` | `UNIFIED_BLUE_THEME_ONLY := true` forces Era-1 blue visuals everywhere; Era-2 purple art retained but inactive | IMPLEMENTED (Era 2 skin INACTIVE) |
| Level editor + solver tools | `tools/level_editor/`, `scripts/tools/*` | DEV-ONLY | DEVELOPER-ONLY |
| QA/debug | `BuildConfig`, QA buttons | DEV-ONLY, hidden in production | DEVELOPER-ONLY |
| Automated tests | `tools/tests/` | Part 26 | IMPLEMENTED |



---

## PART 3 — CRITICAL FILE INVENTORY (runtime scripts, scenes, theme)

Generated from the repository: `class_name`, the file's own first doc-comment line, and the runtime files that reference it (by `res://` path, class name or autoload name). Status `ACTIVE` = referenced by runtime code; `DEV-ONLY` = under `scripts/tools/`; `[git: M]` = modified uncommitted, `[git: ?]` = untracked. Only **one** script has no runtime referencer (`scripts/ads/ad_backend_fake.gd`, test double used by the suite). Level files, assets, tests and docs are covered in Parts 9, 11, 26 and 25. Other important non-code files: `project.godot`, `export_presets.cfg`, `levels/hint_solutions.json` (174 solver-authored hints), `config/ad_ids.local.json` + `config/ad_test_devices.local.json` (local/gitignored), `.github/workflows/release.yml`, `tools/ci/*.sh`, `themes/beamshift_theme.tres`, `assets/audio/default_bus_layout.tres`, `docs/privacy-policy/index.html`.

| Path | class_name | Purpose (from the file's own doc comment) | Used by (runtime files) | Status |
|---|---|---|---|---|
| `scenes/gameplay/era2_activation_fx.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/gameplay/game.tscn` | - | - | game_manager.gd | ACTIVE [git: M] |
| `scenes/gameplay/grid.tscn` | - | - | game.tscn, menu_gameplay_preview.tscn | ACTIVE |
| `scenes/gameplay/laser_mirror_impact_fx.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/beam_receiver.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/blocker.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/emitter.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/filter.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/fusion.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/gate.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/hazard.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/mirror.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/one_way_reflector.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/portal.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/prism.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/remote_emitter.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/splitter.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/splitter_selector.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/switch.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/tiles/target.tscn` | - | - | grid_manager.gd | ACTIVE |
| `scenes/ui/about_screen.tscn` | - | - | game_manager.gd | ACTIVE |
| `scenes/ui/account_screen.tscn` | - | - | game_manager.gd | ACTIVE |
| `scenes/ui/age_selection.tscn` | - | - | studio_splash.gd | ACTIVE [git: ??] |
| `scenes/ui/level_button.tscn` | - | - | level_select.gd | ACTIVE |
| `scenes/ui/level_complete_popup.tscn` | - | - | game.tscn | ACTIVE |
| `scenes/ui/level_select.tscn` | - | - | game_manager.gd | ACTIVE |
| `scenes/ui/main_menu.tscn` | - | - | age_selection.gd, game_manager.gd, studio_splash.gd | ACTIVE [git: M] |
| `scenes/ui/menu_gameplay_preview.tscn` | - | - | main_menu.tscn | ACTIVE |
| `scenes/ui/pause_menu.tscn` | - | - | game.tscn | ACTIVE |
| `scenes/ui/privacy_policy_screen.tscn` | - | - | game_manager.gd | ACTIVE |
| `scenes/ui/settings_menu.tscn` | - | - | game_manager.gd | ACTIVE |
| `scenes/ui/studio_splash.tscn` | - | - | project.godot | ACTIVE |
| `scenes/ui/tutorial_button.tscn` | - | - | tutorial_select.gd | ACTIVE |
| `scenes/ui/tutorial_complete_popup.tscn` | - | - | game.tscn | ACTIVE |
| `scenes/ui/tutorial_panel.tscn` | - | - | game.tscn | ACTIVE |
| `scenes/ui/tutorial_select.tscn` | - | - | game_manager.gd | ACTIVE |
| `scripts/ads/ad_backend.gd` | AdBackend | Platform seam under AdManager (ADS_MONETIZATION.md). Game code never touches an SDK: AdManager talks to one AdBackend - the real Google Mobile Ads one on Android/iOS | ad_backend_admob.gd, ad_backend_fake.gd, ad_manager.gd | ACTIVE |
| `scripts/ads/ad_backend_admob.gd` | AdBackendAdMob | Google Mobile Ads through the Poing Studios Godot AdMob plugin (v5.1.0, addons/admob). Only instantiated on Android/iOS. Consent (UMP) runs first every launch; the SDK st... | ad_manager.gd | ACTIVE |
| `scripts/ads/ad_backend_fake.gd` | AdBackendFake | Scriptable stand-in used ONLY by tests/dev drivers (never selected on a device). Events are emitted deferred, like the real plugin. `load_ok`/`show_mode` script | - | no runtime referencer found (tests only) |
| `scripts/ads/ad_config.gd` | AdConfig | The ONE place every advertising switch, rule constant and ad-unit ID lives (ADS_MONETIZATION.md). Nothing else in the project may contain an AdMob ID.  | ad_backend_admob.gd, ad_manager.gd, age_group.gd, build_config.gd | ACTIVE |
| `scripts/gameplay/beam_receiver_tile.gd` | BeamReceiverTile | Beam Receiver visual (Era 2). Not player-interactive - only a laser triggers it, same interaction shape as SwitchTile. `active` is set by GridManager from LaserSystem's p... | beam_receiver.tscn, grid_manager.gd | ACTIVE |
| `scripts/gameplay/blocker.gd` | BlockerTile | Blocker visual. Purely a beam-stopping obstacle - no interactive behavior, no simulation-driven state. Milestone 4A: uses the final beam-free blocker panel art directly, ... | blocker.tscn, grid_manager.gd | ACTIVE |
| `scripts/gameplay/emitter.gd` | EmitterTile | Placeholder emitter visual. Direction and beam color come from level data and are not player-rotatable. | emitter.tscn, grid_manager.gd, remote_emitter_tile.gd | ACTIVE |
| `scripts/gameplay/era2_activation_fx.gd` | Era2ActivationFX | One-shot cosmetic burst for Era 2 mechanic activation (Prism split, One-Way Reflector reflective hit, Beam Receiver powered, Remote Emitter firing) - same architecture as... | era2_activation_fx.tscn, grid_manager.gd | ACTIVE |
| `scripts/gameplay/filter.gd` | FilterTile | Placeholder filter visual. Recolors any beam passing through to output_color, unconditionally - see LaserSystem/DECISIONS.md ("Filter rule"). Not interactive; orientation... | filter.tscn, grid_manager.gd | ACTIVE |
| `scripts/gameplay/fusion_tile.gd` | FusionTile | Beam Fusion Node visual (Fusion Phase 1, D99). PURELY presentational: LaserSystem decides whether the node is active, which colours reached it and what it emits; GridMana... | fusion.tscn, grid_manager.gd | ACTIVE |
| `scripts/gameplay/game.gd` | - | Root of scenes/gameplay/game.tscn. Orchestrates one play session: loads the level requested by GameManager, tracks the move counter, reacts to grid_manager's signals, and... | game.tscn | ACTIVE [git: M] |
| `scripts/gameplay/gate.gd` | GateTile | Gate visual. is_open is set by GridManager after each simulate call, derived from the stabilized switch/gate state - a gate has no independent persistent state of its own... | gate.tscn, grid_manager.gd | ACTIVE |
| `scripts/gameplay/grid_manager.gd` | GridManager | Owns all authoritative puzzle state for the currently loaded level: mirror/splitter orientations, target/switch/gate/hazard state, and the simulated beam paths. Tile node... | audio_manager.gd, beam_receiver_tile.gd, era2_activation_fx.gd, fusion_tile.gd, game.gd (+30) | ACTIVE |
| `scripts/gameplay/grid_types.gd` | GridTypes | Centralized enums and pure helper functions for the puzzle grid. No gameplay state lives here - only deterministic lookups shared by the laser simulation, tile scripts, a... | emitter.gd, era2_activation_fx.gd, filter.gd, fixture_invalid_gate_ref.gd, fixture_invalid_portal.gd (+239) | ACTIVE |
| `scripts/gameplay/hazard.gd` | HazardTile | Hazard visual. If a beam touches this cell, the level cannot be solved (see LaserSystem's hazard_hit rule) but play is NOT interrupted - the player can keep rotating tile... | grid_manager.gd, hazard.tscn | ACTIVE |
| `scripts/gameplay/hint_manager.gd` | HintManager | Global Hint System (Phase 1, DECISIONS.md D97). One shared component, owned by game.gd (a plain RefCounted like TutorialManager - not an autoload, rule 6). | ad_manager.gd, game.gd, grid_manager.gd | ACTIVE |
| `scripts/gameplay/laser_mirror_impact_fx.gd` | LaserMirrorImpactFX | One-shot cosmetic burst played where a beam reflects off a mirror: a soft contact flash, an expanding ring and a few sparks. Purely visual - it never reads or writes puzz... | era2_activation_fx.gd, grid_manager.gd, laser_mirror_impact_fx.tscn | ACTIVE |
| `scripts/gameplay/laser_system.gd` | LaserSystem | Deterministic grid-based multi-beam simulation. This is the single source of truth for beam behavior - no physics, no raycasting. See ARCHITECTURE.md ("Laser propagation ... | audio_manager.gd, beam_receiver_tile.gd, filter.gd, fixture_invalid_portal.gd, fixture_prism_portal_switch.gd (+29) | ACTIVE |
| `scripts/gameplay/mirror.gd` | MirrorTile | Rotatable/fixed mirror tile. This node only renders and reports taps - grid_manager.gd is the authoritative owner of mirror orientation state.  Milestone 4A: the source m... | grid_manager.gd, mirror.tscn, one_way_reflector_tile.gd, splitter.gd, t03.gd | ACTIVE |
| `scripts/gameplay/one_way_reflector_tile.gd` | OneWayReflectorTile | One-Way Reflector visual (Era 2). Rotatable via the identical tap-to- rotate interaction as MirrorTile/SplitterTile (same tile_clicked signal, same GridManager._on_orient... | grid_manager.gd, one_way_reflector.tscn | ACTIVE |
| `scripts/gameplay/portal.gd` | PortalTile | Placeholder portal visual. Two portals sharing pair_id teleport a beam between them, preserving direction and color - see LaserSystem/ DECISIONS.md ("Portal direction beh... | grid_manager.gd, portal.tscn | ACTIVE |
| `scripts/gameplay/prism_tile.gd` | PrismTile | Prism visual (Era 2). Never rotatable, never player-interactive - see GridTypes.prism_output_direction() for the deterministic WHITE -> RED+GREEN+BLUE / colored -> same-c... | grid_manager.gd, prism.tscn | ACTIVE |
| `scripts/gameplay/remote_emitter_tile.gd` | RemoteEmitterTile | Remote Emitter visual (Era 2). Not player-interactive. `active` is set by GridManager from LaserSystem's stabilized "receiver_states" dict, looked up by this tile's own l... | grid_manager.gd, remote_emitter.tscn | ACTIVE |
| `scripts/gameplay/splitter.gd` | SplitterTile | Rotatable/fixed splitter tile. Same tap-to-rotate interaction shape as MirrorTile, but a distinct class - splitter behavior (straight-through + a reflected branch) lives ... | grid_manager.gd, one_way_reflector_tile.gd, splitter.tscn | ACTIVE |
| `scripts/gameplay/splitter_selector_tile.gd` | SplitterSelectorTile | Splitter Selector visual (Selector Phase S1). PURELY presentational: LaserSystem decides which beams reach the node and where they leave; GridManager copies `active`/`rou... | grid_manager.gd, splitter_selector.tscn | ACTIVE |
| `scripts/gameplay/switch.gd` | SwitchTile | Placeholder switch visual. Activates (visually only - GridManager sets this after each simulate call) when a beam passes over it this evaluation. Not interactive by the p... | beam_receiver_tile.gd, grid_manager.gd, switch.tscn | ACTIVE |
| `scripts/gameplay/target.gd` | TargetTile | Target visual. activated toggles when the laser reaches it with an accepted color (see GridTypes.target_accepts_color()). Milestone 4A: uses the final beam-free target re... | grid_manager.gd, target.tscn | ACTIVE |
| `scripts/gameplay/tile_visual.gd` | TileVisual | Shared base for all tile visuals. Draws the common cell background art (Milestone 4A final asset) first, so every subclass's own content - whether final-art sprite childr... | beam_receiver_tile.gd, blocker.gd, emitter.gd, era_theme.gd, filter.gd (+14) | ACTIVE |
| `scripts/managers/ad_manager.gd` | - | AdManager - the single game-facing advertising service (5th autoload; earns rule 6 because ad state - preloaded ads, cooldown, the completion counter, consent - must | ad_backend.gd, ad_backend_admob.gd, game.gd, project.godot, settings_menu.gd (+1) | ACTIVE |
| `scripts/managers/age_group.gd` | AgeGroup | The player's self-selected age RANGE (never an exact age), asked once on Android by the neutral age screen and stored only in the local save. It is NOT sent anywhere and ... | age_selection.gd, platform_account.gd, save_manager.gd, studio_splash.gd | ACTIVE [git: ??] |
| `scripts/managers/audio_manager.gd` | - | Autoload: AudioManager Centralized BeamShift SFX system (Audio/SFX Integration Pass, see AUDIO_SYSTEM.md). Owns the ONE shared pool of AudioStreamPlayer nodes and | about_screen.gd, account_screen.gd, age_selection.gd, fusion_tile.gd, game.gd (+18) | ACTIVE |
| `scripts/managers/build_config.gd` | BuildConfig | THE one place that decides "internal QA" vs "external test" vs "production". Not an autoload (rule 6): it owns no state, only compile-time constants that other scripts de... | ad_config.gd, game.gd, level_manager.gd, main_menu.gd, safe_area_margin.gd (+1) | ACTIVE |
| `scripts/managers/game_manager.gd` | - | Autoload: GameManager Handles scene navigation and carries the currently-selected level id across the Level Select -> Game scene transition. | about_screen.gd, account_screen.gd, game.gd, level_complete_popup.gd, level_manager.gd (+10) | ACTIVE |
| `scripts/managers/internet_blocker.gd` | - | Autoload: InternetBlocker - the ONE global "internet required" gate. Sits above every scene (layer 128), pauses the SceneTree while InternetManager.is_blocking() and | about_screen.gd, account_screen.gd, age_selection.gd, hint_ad_dialog.gd, internet_manager.gd (+5) | ACTIVE [git: M] |
| `scripts/managers/internet_manager.gd` | - | Autoload: InternetManager - BeamShift REQUIRES a working internet connection at all times (local saves are unchanged; this is a product rule, not a sync feature). | about_screen.gd, account_screen.gd, ad_manager.gd, age_selection.gd, game.gd (+9) | ACTIVE |
| `scripts/managers/level_manager.gd` | - | Autoload: LevelManager Owns the ordered list of levels and the star-rating formula. Adding a new level for Milestone 3+ only requires adding a new file to LEVEL_PATHS - n... | build_config.gd, era_theme.gd, fixture_invalid_portal.gd, fixture_rect_5x8.gd, fusion_qa_set.gd (+15) | ACTIVE |
| `scripts/managers/platform_account.gd` | - | PlatformAccount - the optional, platform-native player identity (autoload).  Android: Google Play Games Services. iOS: Sign in with Apple. Desktop/editor: none. | account_screen.gd, age_selection.gd, game_manager.gd, project.godot, settings_menu.gd | ACTIVE [git: M] |
| `scripts/managers/save_manager.gd` | - | Autoload: SaveManager Lightweight local JSON save at user://savegame.json. Handles first launch, missing save, and malformed save gracefully. See ARCHITECTURE.md ("Save f... | ad_manager.gd, age_selection.gd, audio_manager.gd, game.gd, game_manager.gd (+16) | ACTIVE [git: M] |
| `scripts/managers/star_scoring.gd` | StarScoring | The ONE star rule for every level population (Phase 4, D102). Pure static functions, no state, no autoload. Level data never carries star thresholds.  Rule V1, with OPTIM... | game.gd, level_manager.gd, save_manager.gd | ACTIVE |
| `scripts/managers/store_manager.gd` | - | StoreManager - real-money purchases and the entitlements they grant (6th autoload; earns rule 6 because store connection state, prices and the in-flight purchase must out... | ad_manager.gd, play_billing_backend.gd, project.godot, save_manager.gd, settings_menu.gd (+1) | ACTIVE |
| `scripts/managers/tutorial_manager.gd` | TutorialManager | Drives the guided-tutorial step machine and is the single, central place that applies forced-interaction/highlight rules to the active GridManager - see CLAUDE.md ("Guide... | game.gd, game_manager.gd, grid_manager.gd, hint_manager.gd, tutorial_level_data.gd (+2) | ACTIVE |
| `scripts/procedural/procedural_board_v3.gd` | ProceduralBoardV3 | Physical layout primitives for Generator V3 (D94). A board collects tiles while a Cursor "walks" a beam: it advances along its direction, drops a mirror at each turn (the... | procedural_composer_v3.gd, procedural_generator_v3.gd, procedural_layout_v3.gd, procedural_minimality.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_complexity.gd` | ProceduralComplexity | Practical reasoning-complexity metrics for one procedural puzzle (Difficulty System Phase 1, DECISIONS.md D93). Answers "how much thinking does this puzzle need?" separat... | procedural_fragments_v3.gd, procedural_fusion_check.gd, procedural_generator_v3.gd, procedural_level_generator.gd, procedural_minimality.gd (+4) | ACTIVE |
| `scripts/procedural/procedural_composer_v3.gd` | ProceduralComposerV3 | Layout composer for Generator V3 progression (Phase 2B, D96): realises the line tree ProceduralFragmentsV3 planned on a portrait board, WITHOUT any hand-placed coordinate... | procedural_fragments_v3.gd, procedural_fusion_check.gd, procedural_plan_v3.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_difficulty_contract.gd` | ProceduralDifficultyContract | The ONE authoritative procedural difficulty contract (Difficulty System Phase 1, see DECISIONS.md D93 / PROCEDURAL_GENERATION.md "Difficulty contract"). Pure data lookup ... | game.gd, level_manager.gd, procedural_fragments_v3.gd, procedural_generator_v3.gd, procedural_progression_v3.gd (+1) | ACTIVE |
| `scripts/procedural/procedural_difficulty_profile.gd` | ProceduralDifficultyProfile | Difficulty-band configuration for the procedural generator (Levels 1-2000). See PROCEDURAL_GENERATION.md "Difficulty bands" for the full table and reasoning. Pure data lo... | procedural_difficulty_contract.gd, procedural_generator_v3.gd, procedural_level_generator.gd, procedural_templates.gd | ACTIVE |
| `scripts/procedural/procedural_fragments_v3.gd` | ProceduralFragmentsV3 | Fragment planner for Generator V3 progression (Difficulty System Phase 2B, D96). Composes a LOGICAL puzzle out of reusable fragments ("atoms") chosen from a per-band pool... | procedural_composer_v3.gd, procedural_difficulty_contract.gd, procedural_plan_v3.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_fusion_check.gd` | ProceduralFusionCheck | Load-bearing / stability checks for GENERATED Fusion boards (Fusion Node Phase 2, D100). Runtime-safe like ProceduralComplexity: only LaserSystem (ablation by rebuilding ... | procedural_composer_v3.gd, procedural_progression_v3.gd, procedural_selector_check.gd | ACTIVE |
| `scripts/procedural/procedural_generator_v3.gd` | ProceduralGeneratorV3 | Generator V3 - DEPENDENCY FIRST (Difficulty System Phase 2A prototype, D94). Pipeline (each stage only consumes the previous one's output):  difficulty requirements -> Pr... | game.gd, game_manager.gd, procedural_level_generator.gd, procedural_plan_v3.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_layout_v3.gd` | ProceduralLayoutV3 | Physical layout planner for Generator V3 (D94): turns a ProceduralPlanV3 into tiles on a portrait board (<= GridManager.MAX_COLUMNS columns, square cells, no pixel maths ... | procedural_generator_v3.gd, procedural_plan_v3.gd, procedural_planner_v3.gd | ACTIVE |
| `scripts/procedural/procedural_level_generator.gd` | ProceduralLevelGenerator | Procedural level generator V1 (Levels 1-2000). See PROCEDURAL_GENERATION.md for the full architecture writeup. Builds a LevelData for the given level_number using Procedu... | game.gd, game_manager.gd, level_manager.gd, procedural_difficulty_profile.gd, procedural_generator_v3.gd (+7) | ACTIVE |
| `scripts/procedural/procedural_minimality.gd` | ProceduralMinimality | "Is the intended solution really minimal?" - a runtime-safe GROUP redundancy screen (Selector Phase S3 / generator V5, D110). Found by replaying the intended solution thr... | procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_plan_v3.gd` | ProceduralPlanV3 | Logical puzzle plan for Generator V3 (Difficulty System Phase 2A, D94). A plan says WHAT the puzzle is - which mechanics are load-bearing, what depends on what, which col... | procedural_composer_v3.gd, procedural_fragments_v3.gd, procedural_generator_v3.gd, procedural_layout_v3.gd, procedural_planner_v3.gd (+1) | ACTIVE |
| `scripts/procedural/procedural_planner_v3.gd` | ProceduralPlannerV3 | Logical planner for Generator V3 (D94): decides WHICH mechanics carry the puzzle and how they depend on each other BEFORE any cell is chosen. Every archetype is a reusabl... | procedural_generator_v3.gd | ACTIVE |
| `scripts/procedural/procedural_progression_v3.gd` | ProceduralProgressionV3 | Generator V3 as a real progression generator (Difficulty System Phase 2B, D96): (level number, seed, difficulty band) -> a dependency-first puzzle.  ProceduralDifficultyC... | level_manager.gd, procedural_difficulty_contract.gd, procedural_level_generator.gd | ACTIVE |
| `scripts/procedural/procedural_seed.gd` | ProceduralSeed | Deterministic seed derivation for the procedural level generator (Levels 1-2000). See PROCEDURAL_GENERATION.md "Determinism / seed derivation". Every random draw during g... | procedural_generator_v3.gd, procedural_level_generator.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_selector_check.gd` | ProceduralSelectorCheck | First-class Splitter Selector analysis for GENERATED boards (Selector Phase S3 / generator V5, D110). Runtime-safe like ProceduralComplexity/ProceduralFusionCheck: only t... | procedural_complexity.gd, procedural_composer_v3.gd, procedural_difficulty_contract.gd, procedural_fragments_v3.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_shortcut_probe.gd` | ProceduralShortcutProbe | Runtime-safe, BOUNDED shortcut probe for Generator V3 (Phase 2B, D96).  Question: "is there a way to solve this puzzle in FEWER flips than the intended solution?" The exa... | procedural_complexity.gd, procedural_progression_v3.gd | ACTIVE |
| `scripts/procedural/procedural_templates.gd` | ProceduralTemplates | Solution-first puzzle templates for the procedural generator. Every template builds its INTENDED solved path first (using GridTypes.reflect() semantics via a shared zigza... | procedural_difficulty_profile.gd, procedural_level_generator.gd, procedural_seed.gd | ACTIVE |
| `scripts/procedural/procedural_triviality.gd` | ProceduralTriviality | Centralized triviality evaluator (Difficulty System Phase 1, DECISIONS.md D93): checks ProceduralComplexity metrics against ProceduralDifficultyContract requirements and ... | procedural_difficulty_contract.gd, procedural_generator_v3.gd | ACTIVE |
| `scripts/procedural/procedural_v5_qa_set.gd` | ProceduralV5QaSet | DEV-ONLY curated sample of generator-V5 levels for manual difficulty review (Selector Phase S3, D110). Behind Main Menu's "V5 TEST" (LevelManager.SHOW_V5_TEST_QA); never ... | game.gd, game_manager.gd | ACTIVE |
| `scripts/resources/era_theme.gd` | EraTheme | Centralized visual identity for one "Era" (a 100-level campaign block + its 10-tutorial pack, see ROADMAP.md). Not an autoload (CLAUDE.md rule 6 - a lookup table has no p... | aspect_bar.gd, game.gd, level_manager.gd, level_select.gd, tile_visual.gd (+1) | ACTIVE |
| `scripts/resources/level_data.gd` | LevelData | Data-only description of one puzzle level. Individual level files under res://levels/ extend this class and populate its fields in _init(). See ARCHITECTURE.md for why le... | audio_manager.gd, fixture_invalid_gate_ref.gd, fixture_invalid_portal.gd, fixture_multi_solution.gd, fixture_one_way_reflector_backslash.gd (+198) | ACTIVE |
| `scripts/resources/tile_placement.gd` | TilePlacement | Data-only description of a single tile within a LevelData grid. Carries no gameplay logic - only what is needed to place and initialize a tile in the grid. | fixture_invalid_gate_ref.gd, fixture_invalid_portal.gd, fixture_multi_solution.gd, fixture_one_way_reflector_backslash.gd, fixture_one_way_reflector_chain.gd (+219) | ACTIVE |
| `scripts/resources/tutorial_level_data.gd` | TutorialLevelData | A guided tutorial level. Extends LevelData exactly like a campaign level - `tiles`/`grid_width`/`grid_height` are simulated by the SAME LaserSystem/GridManager, so a tuto... | game.gd, level_manager.gd, t01.gd, t02.gd, t03.gd (+33) | ACTIVE |
| `scripts/resources/tutorial_step_data.gd` | TutorialStepData | Data-only description of one step in a guided tutorial level. A TutorialLevelData's `steps` array is driven entirely by these - TutorialManager is the only code that inte... | game.gd, t01.gd, t02.gd, t03.gd, t04.gd (+32) | ACTIVE |
| `scripts/store/play_billing_backend.gd` | - | Google Play half of the store (GodotGooglePlayBilling 3.3.0, addons/GodotGooglePlayBilling). The ONLY file naming a class from that plugin; loaded by path from StoreManag... | store_manager.gd | ACTIVE |
| `scripts/store/store_config.gd` | StoreConfig | The ONE place every in-app product ID and fallback price lives (STORE_RELEASE.md). Product IDs must match Play Console and App Store Connect exactly and can never be | ad_manager.gd, play_billing_backend.gd, store_kit_backend.gd, store_manager.gd | ACTIVE [git: M] |
| `scripts/store/store_kit_backend.gd` | - | App Store half of the store: godot-store-kit 1.5 (StoreKit 2, SwiftGodot, needs iOS 17), driven by class name through ClassDB so this compiles on every platform; the exte... | store_manager.gd | ACTIVE |
| `scripts/tools/difficulty_inspect.gd` | - | Dev-only fast inspection (Difficulty System Phase 1, D93): generates a short list of procedural levels and prints, per level, the difficulty contract, ProceduralComplexit... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/difficulty_inspect.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/fusion_progression_sample.gd` | - | Dev-only Fusion Phase 2 sample tool (D100): generates a focused set of generator-V4 levels and prints the QA report (never exported: scripts/tools/**). NOT a range audit ... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/fusion_progression_sample.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/fusion_verify.gd` | - | Dev-only Fusion Phase 2 verification tool (D100). Never exported (scripts/tools/**).  For generated V4 levels that contain Fusion it runs the shortcut/bypass experiments ... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/fusion_verify.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/hint_solution_builder.gd` | - | Dev-only (never exported): builds levels/hint_solutions.json - the SOLVER-AUTHORED solved orientations the runtime Hint uses for handcrafted campaign levels ("c<id>") | - | DEV-ONLY (export-excluded) |
| `scripts/tools/hint_solution_builder.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/level_metrics.gd` | LevelMetrics | Development-only design metrics + a rough, transparent difficulty ESTIMATE. This is explicitly not a scientific difficulty score - see DECISIONS.md ("Difficulty heuristic... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/level_solver.gd` | LevelSolver | Development-only puzzle solver. Determines whether a level is solvable by rotating its player-controllable pieces (rotatable mirrors and splitters only - never fixed mirr... | fixture_multi_solution.gd, fixture_one_way_reflector_rotation.gd, fixture_search_limit.gd, fixture_unsolvable.gd, fixture_zero_move.gd (+11) | DEV-ONLY (export-excluded) |
| `scripts/tools/level_validator.gd` | LevelValidator | Development-only structural validator. Deliberately separate from LevelSolver: this checks the level DATA is well-formed (no dangling references, no out-of-bounds tiles, ... | fixture_invalid_gate_ref.gd, fixture_invalid_portal.gd, fixture_zero_move.gd, level_data.gd, procedural_fusion_check.gd (+5) | DEV-ONLY (export-excluded) |
| `scripts/tools/make_ios_icon.gd` | - | Dev-only (scripts/tools/ is export-excluded): writes the 1024 px App Store icon the iOS preset points at. Apple rejects an App Store icon with an alpha channel, so the so... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/procedural_audit.gd` | ProceduralAudit | Development-only audit/QA tooling for the procedural generator (ProceduralLevelGenerator, Levels 1-2000). Dev-only, excluded from the Android export like every other scri... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/selector_tutorial_verify.gd` | - | Dev-only Splitter Selector tutorial verifier (Selector Phase S2). Never exported (scripts/tools/**). LevelSolver is binary-flip only, so for each of T29-T34 this brute-fo... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/selector_tutorial_verify.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/selector_verify.gd` | - | Dev-only Splitter Selector QA verifier (Selector Phase S1). Never exported (scripts/tools/**). For each SelectorQaSet puzzle it brute-forces EVERY orientation combination... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/selector_verify.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v3_progression_sample.gd` | - | Dev-only Phase 2B sample tool (D96): generates a focused set of V3 PROGRESSION levels and prints the human-readable QA report. Never exported (scripts/tools/**). NOT a ra... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v3_progression_sample.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v3_progression_stats.gd` | - | Dev-only Phase 2B statistics tool (D96): shortcut / solver agreement over a RANGE of V3 progression levels - the levels are the seeds. Never exported.  | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v3_progression_stats.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v3_prototype_audit.gd` | - | Dev-only Phase 2A audit (D94): generates the six V3 prototypes and prints board, plan reasoning, metrics, gates and (capped) solver comparison. Never exported (scripts/to... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v3_prototype_audit.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v5_sample.gd` | - | Dev-only generator-V5 sample/statistics tool (Selector Phase S3, D110). Never exported (scripts/tools/**). Every run has a hard budget (default 55 s) and prints QA_BUDGET... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v5_sample.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v5_verify.gd` | - | Dev-only generator-V5 verifier (Selector Phase S3, D110). Never exported (scripts/tools/**). LevelSolver models neither 4-state Selectors nor Fusion, so this tool brings ... | - | DEV-ONLY (export-excluded) |
| `scripts/tools/v5_verify.tscn` | - | - | - | DEV-ONLY (export-excluded) |
| `scripts/ui/about_screen.gd` | - | ABOUT US / credits. Panels are built from CREDITS below as plain Labels (no text is baked into any image) so names/roles stay editable in one place. Style mirrors account... | about_screen.tscn | ACTIVE |
| `scripts/ui/account_screen.gd` | - | Account screen: shows the optional platform identity (Play Games on Android, Sign in with Apple on iOS) over the local profile. Progress is stored on this device only; | account_screen.tscn | ACTIVE |
| `scripts/ui/age_selection.gd` | - | First-launch neutral age screen (Android only, Google Play Families). Three equal choices, no default, no exact age, nothing transmitted: the range goes to SaveManager (l... | age_selection.tscn | ACTIVE [git: ??] |
| `scripts/ui/aspect_art_button.gd` | AspectArtButton | Full-width primary button used by the tutorial UI. Kept as a class (scenes/tests reference it) but the redesign dropped the aspect-locked art: it now simply fills its row... | tutorial_panel.tscn | ACTIVE |
| `scripts/ui/aspect_bar.gd` | AspectBar | Keeps a full-width decorative HUD bar's height locked to its source art's aspect ratio on every resize, so bs_hud_top/bottom_portrait.png (Milestone 4A.4) never gets stre... | game.gd, game.tscn | ACTIVE |
| `scripts/ui/beam_button_glow.gd` | BeamButtonGlow | Moving beam around a button's outline. Added as a child of an art button (MenuArtButton / SettingsArtButton); it sizes itself to the button's VISIBLE art rect, draws addi... | about_screen.gd, game.gd, level_complete_popup.gd, main_menu.gd, menu_art_button.gd (+4) | ACTIVE |
| `scripts/ui/beam_button_glow.gdshader` | - | - | beam_button_glow.gd | ACTIVE |
| `scripts/ui/beam_ui.gd` | BeamUI | The BeamShift UI design system: ONE place for colours, sizes and the StyleBox recipes every screen uses. `build_theme()` assembles the shared Theme (themes/beamshift_them... | about_screen.gd, age_selection.gd, aspect_art_button.gd, hint_ad_dialog.gd, internet_blocker.gd (+5) | ACTIVE |
| `scripts/ui/hint_ad_dialog.gd` | HintAdDialog | Disclosure shown BEFORE a rewarded Hint ad starts ("Watch a short ad to reveal a hint."). Purely presentational: it only emits `confirmed` / `cancelled`; game.gd owns the... | game.gd | ACTIVE [git: ??] |
| `scripts/ui/level_button.gd` | - | Single level-select button. Purely presentational; level_select.gd decides lock/complete/star state from SaveManager and LevelManager. Milestone 4A: swaps a background te... | level_button.tscn | ACTIVE |
| `scripts/ui/level_complete_popup.gd` | - | scenes/ui/level_complete_popup.tscn root script. Purely presentational + input relay - game.gd owns the actual level-advance/retry/navigation logic. Milestone 4A: stars r... | level_complete_popup.tscn | ACTIVE |
| `scripts/ui/level_select.gd` | - | Displays one button per level, built dynamically from LevelManager/ SaveManager state. Scales to ~100 levels via ScrollContainer + GridContainer without any per-button ha... | level_select.tscn | ACTIVE |
| `scripts/ui/main_menu.gd` | - | Main Menu Mobile Layout Correction (2026-09-28, real-device follow-up to the Main Menu Redesign pass): the logo/preview/button stack is sized here, in code, instead of fi... | main_menu.tscn | ACTIVE [git: M] |
| `scripts/ui/menu_art_button.gd` | MenuArtButton | Main Menu primary button whose whole look is a supplied PNG (the label is baked into the art). The Button itself stays the touch target and covers the full displayed art ... | beam_button_glow.gd, main_menu.gd, main_menu.tscn | ACTIVE |
| `scripts/ui/menu_gameplay_preview.gd` | MenuGameplayPreview | Main Menu live gameplay preview (Main Menu Redesign pass, 2026-09-28). A fully isolated, looping demonstration of BeamShift's laser-routing puzzle: builds a dedicated pre... | menu_gameplay_preview.tscn | ACTIVE |
| `scripts/ui/menu_particles.gd` | - | Main Menu ambience: keeps the emission box matched to the parent Control's rect (event-driven via `resized`, no per-frame work) so it covers any portrait aspect. | main_menu.tscn | ACTIVE |
| `scripts/ui/pause_menu.gd` | - | scenes/ui/pause_menu.tscn root script (Milestone 4A - new this milestone, see ARCHITECTURE.md "Pause menu"). Purely presentational + input relay, exactly like LevelComple... | pause_menu.tscn | ACTIVE |
| `scripts/ui/privacy_policy_screen.gd` | - | In-game Privacy Policy, rendered natively from PrivacyPolicyText (never opens a browser). The Back button lives in the fixed header, outside the ScrollContainer, so it st... | privacy_policy_screen.tscn | ACTIVE |
| `scripts/ui/privacy_policy_text.gd` | PrivacyPolicyText | THE canonical BeamShift Privacy Policy wording. The in-game screen (privacy_policy_screen.gd) renders SECTIONS directly; the public web copy (docs/privacy-policy/index.ht... | privacy_policy_screen.gd, store_config.gd | ACTIVE [git: M] |
| `scripts/ui/safe_area_margin.gd` | SafeAreaMargin | Outer safe-margin for a top-level screen: a baseline minimum padding on every platform, widened on Android by the real display safe-area inset (notches, camera cutouts, r... | about_screen.tscn, account_screen.tscn, age_selection.tscn, game.gd, game.tscn (+9) | ACTIVE |
| `scripts/ui/settings_art_button.gd` | SettingsArtButton | Settings control whose whole look is a supplied PNG (label/icon baked in). The PNGs carry large, differing transparent padding, so the button is sized to the art's VISIBL... | about_screen.tscn, beam_button_glow.gd, level_complete_popup.tscn, main_menu.gd, pause_menu.tscn (+4) | ACTIVE |
| `scripts/ui/settings_menu.gd` | - | Milestone 4A.1: Sound/Music toggles are custom toggle-mode Buttons showing the wide bs_ui_toggle_on/off.png switch art (which bakes in its own "ON"/"OFF" text) rather tha... | settings_menu.tscn | ACTIVE |
| `scripts/ui/studio_splash.gd` | - | Startup studio splash (Studio Splash pass). Set as project.godot's run/main_scene. Plays the MaclePro logo then the 4Sagez logo, each fading in/hold/fading out, then hand... | studio_splash.tscn | ACTIVE [git: M] |
| `scripts/ui/tutorial_button.gd` | - | Single tutorial-select button. A simplified sibling of level_button.gd (same locked/unlocked/completed textures, reused directly) with no stars row - tutorials aren't sco... | tutorial_button.tscn | ACTIVE |
| `scripts/ui/tutorial_complete_popup.gd` | - | scenes/ui/tutorial_complete_popup.tscn root script. Distinct from LevelCompletePopup on purpose - tutorials have no stars/best-moves to show (see SaveManager's tutorial_*... | tutorial_complete_popup.tscn | ACTIVE |
| `scripts/ui/tutorial_dim_overlay.gd` | TutorialDimOverlay | Guided-tutorial-only board dim. Owned and shown/hidden by GridManager in lockstep with TutorialHighlight (set_highlight()/clear_highlight() are the only callers - see DEC... | grid_manager.gd, tutorial_highlight.gd | ACTIVE |
| `scripts/ui/tutorial_highlight.gd` | TutorialHighlight | Reusable pulsing highlight overlay for the guided tutorial's forced- interaction/focus steps. Purely visual, owned and positioned by GridManager (set_highlight()/clear_hi... | grid_manager.gd, tutorial_dim_overlay.gd | ACTIVE |
| `scripts/ui/tutorial_panel.gd` | - | scenes/ui/tutorial_panel.tscn root script. Purely presentational - game.gd/TutorialManager own all tutorial state; this just renders the current step's text and emits con... | tutorial_panel.tscn | ACTIVE |
| `scripts/ui/tutorial_select.gd` | - | Displays one button per guided tutorial (T01-T10), built from LevelManager/SaveManager's tutorial_* state - a structural sibling of level_select.gd, kept as its own scrip... | tutorial_select.tscn | ACTIVE |
| `scripts/ui/ui_constants.gd` | UIConstants | Shared mobile UI sizing constants. Centralized so every screen uses the same touch-target and safe-margin values instead of scattering magic numbers across scenes. See DE... | game.gd, main_menu.gd, procedural_difficulty_profile.gd, safe_area_margin.gd | ACTIVE |
| `themes/beamshift_theme.tres` | - | - | project.godot | ACTIVE |

---

## PART 6 — SCENE INVENTORY

50 scenes outside addons. Table generated from the `.tscn` files (root node, script, instanced scenes, node count, who references the scene). Production flow: `studio_splash` → (`age_selection` on Android first launch) → `main_menu` → `game` (via `GameManager`). Debug/QA: `level_select`, `level_editor` (tools/), `menu_gameplay_preview` is a **production** decoration inside the main menu.

| Scene | Root (type) | Script | Direct instanced scenes | Nodes | Referenced by |
|---|---|---|---|---|---|
| `scenes/gameplay/era2_activation_fx.tscn` | Era2ActivationFX (Node2D) | `scripts/gameplay/era2_activation_fx.gd` | - | 1 | grid_manager.gd |
| `scenes/gameplay/game.tscn` | Game (Control) | `scripts/gameplay/game.gd` | grid.tscn, level_complete_popup.tscn, pause_menu.tscn, tutorial_complete_popup.tscn, tutorial_panel.tscn | 33 | game_manager.gd, ui_shots.gd |
| `scenes/gameplay/grid.tscn` | PuzzleGrid (Control) | `scripts/gameplay/grid_manager.gd` | - | 1 | game.tscn, menu_gameplay_preview.tscn, test_managers.gd |
| `scenes/gameplay/laser_mirror_impact_fx.tscn` | LaserMirrorImpactFX (Node2D) | `scripts/gameplay/laser_mirror_impact_fx.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/beam_receiver.tscn` | BeamReceiver (Control) | `scripts/gameplay/beam_receiver_tile.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/blocker.tscn` | Blocker (Control) | `scripts/gameplay/blocker.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/emitter.tscn` | Emitter (Control) | `scripts/gameplay/emitter.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/filter.tscn` | Filter (Control) | `scripts/gameplay/filter.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/fusion.tscn` | Fusion (Control) | `scripts/gameplay/fusion_tile.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/gate.tscn` | Gate (Control) | `scripts/gameplay/gate.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/hazard.tscn` | Hazard (Control) | `scripts/gameplay/hazard.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/mirror.tscn` | Mirror (Control) | `scripts/gameplay/mirror.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/one_way_reflector.tscn` | OneWayReflector (Control) | `scripts/gameplay/one_way_reflector_tile.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/portal.tscn` | Portal (Control) | `scripts/gameplay/portal.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/prism.tscn` | Prism (Control) | `scripts/gameplay/prism_tile.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/remote_emitter.tscn` | RemoteEmitter (Control) | `scripts/gameplay/remote_emitter_tile.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/splitter.tscn` | Splitter (Control) | `scripts/gameplay/splitter.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/splitter_selector.tscn` | SplitterSelector (Control) | `scripts/gameplay/splitter_selector_tile.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/switch.tscn` | Switch (Control) | `scripts/gameplay/switch.gd` | - | 1 | grid_manager.gd |
| `scenes/tiles/target.tscn` | Target (Control) | `scripts/gameplay/target.gd` | - | 1 | grid_manager.gd |
| `scenes/ui/about_screen.tscn` | AboutScreen (Control) | `scripts/ui/about_screen.gd` | - | 15 | game_manager.gd, test_ui_screens.gd, ui_shots.gd |
| `scenes/ui/account_screen.tscn` | AccountScreen (Control) | `scripts/ui/account_screen.gd` | - | 17 | game_manager.gd, test_ui_account.gd, ui_shots.gd |
| `scenes/ui/age_selection.tscn` | AgeSelection (Control) | `scripts/ui/age_selection.gd` | - | 14 | studio_splash.gd, test_families.gd, ui_shots.gd |
| `scenes/ui/level_button.tscn` | LevelButton (Button) | `scripts/ui/level_button.gd` | - | 7 | level_select.gd, test_ui_screens.gd |
| `scenes/ui/level_complete_popup.tscn` | LevelCompletePopup (Control) | `scripts/ui/level_complete_popup.gd` | - | 25 | game.tscn, test_ui_screens.gd |
| `scenes/ui/level_select.tscn` | LevelSelect (Control) | `scripts/ui/level_select.gd` | - | 15 | game_manager.gd, test_ui_screens.gd, ui_shots.gd |
| `scenes/ui/main_menu.tscn` | MainMenu (Control) | `scripts/ui/main_menu.gd` | menu_gameplay_preview.tscn | 18 | age_selection.gd, game_manager.gd, studio_splash.gd, test_ui_screens.gd, ui_shots.gd |
| `scenes/ui/menu_gameplay_preview.tscn` | MenuGameplayPreview (PanelContainer) | `scripts/ui/menu_gameplay_preview.gd` | grid.tscn | 5 | main_menu.tscn, test_ui_screens.gd |
| `scenes/ui/pause_menu.tscn` | PauseMenu (Control) | `scripts/ui/pause_menu.gd` | - | 12 | game.tscn, test_ui_screens.gd |
| `scenes/ui/privacy_policy_screen.tscn` | PrivacyPolicyScreen (Control) | `scripts/ui/privacy_policy_screen.gd` | - | 13 | game_manager.gd, test_privacy_policy.gd, ui_shots.gd |
| `scenes/ui/settings_menu.tscn` | SettingsMenu (Control) | `scripts/ui/settings_menu.gd` | - | 44 | game_manager.gd, test_privacy_policy.gd, test_ui_screens.gd, ui_shots.gd |
| `scenes/ui/studio_splash.tscn` | StudioSplash (Control) | `scripts/ui/studio_splash.gd` | - | 6 | project.godot, test_ui_screens.gd |
| `scenes/ui/tutorial_button.tscn` | TutorialButton (Button) | `scripts/ui/tutorial_button.gd` | - | 3 | test_ui_screens.gd, tutorial_select.gd |
| `scenes/ui/tutorial_complete_popup.tscn` | TutorialCompletePopup (Control) | `scripts/ui/tutorial_complete_popup.gd` | - | 12 | game.tscn, test_ui_screens.gd |
| `scenes/ui/tutorial_panel.tscn` | TutorialPanel (Control) | `scripts/ui/tutorial_panel.gd` | - | 5 | game.tscn |
| `scenes/ui/tutorial_select.tscn` | TutorialSelect (Control) | `scripts/ui/tutorial_select.gd` | - | 15 | game_manager.gd, test_ui_screens.gd, ui_shots.gd |
| `scripts/tools/difficulty_inspect.tscn` | DifficultyInspect (Node) | `scripts/tools/difficulty_inspect.gd` | - | 1 | difficulty_inspect.gd, test_dev_tools.gd |
| `scripts/tools/fusion_progression_sample.tscn` | FusionProgressionSample (Node) | `scripts/tools/fusion_progression_sample.gd` | - | 1 | fusion_progression_sample.gd, test_dev_tools.gd |
| `scripts/tools/fusion_verify.tscn` | FusionVerify (Node) | `scripts/tools/fusion_verify.gd` | - | 1 | fusion_verify.gd, test_dev_tools.gd |
| `scripts/tools/hint_solution_builder.tscn` | HintSolutionBuilder (Node) | `scripts/tools/hint_solution_builder.gd` | - | 1 | hint_solution_builder.gd |
| `scripts/tools/selector_tutorial_verify.tscn` | SelectorTutorialVerify (Node) | `scripts/tools/selector_tutorial_verify.gd` | - | 1 | selector_tutorial_verify.gd, test_dev_tools.gd |
| `scripts/tools/selector_verify.tscn` | SelectorVerify (Node) | `scripts/tools/selector_verify.gd` | - | 1 | selector_verify.gd, test_dev_tools.gd |
| `scripts/tools/v3_progression_sample.tscn` | V3ProgressionSample (Node) | `scripts/tools/v3_progression_sample.gd` | - | 1 | test_dev_tools.gd, v3_progression_sample.gd |
| `scripts/tools/v3_progression_stats.tscn` | V3ProgressionStats (Node) | `scripts/tools/v3_progression_stats.gd` | - | 1 | test_dev_tools.gd, v3_progression_stats.gd |
| `scripts/tools/v3_prototype_audit.tscn` | V3PrototypeAudit (Node) | `scripts/tools/v3_prototype_audit.gd` | - | 1 | test_dev_tools.gd, v3_prototype_audit.gd |
| `scripts/tools/v5_sample.tscn` | V5Sample (Node) | `scripts/tools/v5_sample.gd` | - | 1 | test_dev_tools.gd, v5_sample.gd |
| `scripts/tools/v5_verify.tscn` | V5Verify (Node) | `scripts/tools/v5_verify.gd` | - | 1 | test_dev_tools.gd, v5_verify.gd |
| `tools/level_editor/level_editor.tscn` | LevelEditor (Control) | `tools/level_editor/level_editor.gd` | - | 39 | game_manager.gd |
| `tools/tests/test_runner.tscn` | TestRunner (Node) | `tools/tests/test_runner.gd` | - | 1 | test_runner.gd |
| `tools/ui_shots/ui_shots.tscn` | UiShots (Node) | `tools/ui_shots/ui_shots.gd` | - | 1 | ui_shots.gd |

Notes on specific scenes
* **`scenes/ui/studio_splash.tscn`** — run/main_scene. Plays MaclePro then 4Sagez logos (fade 0.35 s, hold 1.4 s) then `change_scene_to_file(AgeSelection or MainMenu)`. Android Back = quit.
* **`scenes/ui/age_selection.tscn`** (NEW, uncommitted) — Android-only neutral age screen; three identical buttons (12 OR YOUNGER / 13–17 / 18 OR OLDER); handlers refuse under the InternetBlocker.
* **`scenes/ui/main_menu.tscn`** — art buttons (`MenuArtButton`), live gameplay preview of campaign level 3 (`menu_gameplay_preview`), particles, footer About/Settings. QA buttons (Level Select QA, V3/FUSION/SELECTOR/V5 TEST) exist in code but only render when `BuildConfig.QA_TOOLS`. The NEW GAME confirmation dialog is built in code (`main_menu.gd`).
* **`scenes/gameplay/game.tscn`** — root `Game` Control: Background, SafeMargin → Layout(TopBar, CenterArea[PuzzleGrid instance], BottomBar[HintButton, ResetButton, PauseButton, QANextButton]), LevelCompletePopup, TutorialCompletePopup, TutorialPanel, QADebugLabel, PauseMenu. The Hint-ad dialog (`HintAdDialog`) is added at runtime as the LAST child so it sits above everything.
* **`scenes/ui/level_select.tscn`** — QA/dev only; 4-column grid in a ScrollContainer; its card root Button uses `mouse_filter = PASS` so drags scroll (fixed 2026-09-30).
* **`scenes/ui/tutorial_select.tscn`** — header (Back + title + balance) above a ScrollContainer (`horizontal_scroll_mode=0`, `scroll_deadzone=24`), 4-column GridContainer of `tutorial_button.tscn` (mouse_filter PASS) — the header/drag-scroll bugs from 2026-09-30 are fixed in the current code.
* **Dialog scenes**: `pause_menu.tscn`, `level_complete_popup.tscn`, `tutorial_complete_popup.tscn`; New Game confirmation and Hint-ad confirmation are code-built.
* **Monetization UI** lives in `settings_menu.tscn` (sections AUDIO, ACCOUNT, ADS & PURCHASES with NO FORCED ADS and RESTORE PURCHASES buttons, PRIVACY OPTIONS, PRIVACY POLICY). **Authentication UI** is `account_screen.tscn` (Play Games connect/retry; "LOCAL PROFILE" when Play Games is not offered).

---

## PART 7 — GAMEPLAY MECHANICS (everything implemented)

Tile scenes are in `scenes/tiles/*.tscn`, scripts `scripts/gameplay/*.gd` (dumb views: `TileVisual` base draws the cell background then each tile draws itself). **Rotation model:** MIRROR / SPLITTER / ONE_WAY_REFLECTOR toggle `SLASH ↔ BACKSLASH` per tap; FUSION and SPLITTER_SELECTOR step their output `Direction` one clockwise step (4 states) per tap (`GridManager._on_orientable_tile_clicked`). A tile is player-rotatable only if `rotatable = true`; fixed tiles ring `mirror_locked` SFX.

| Mechanic | Script / Scene | Behaviour (from `LaserSystem`) | Player interaction | States / enums | Interactions & edge cases | Status |
|---|---|---|---|---|---|---|
| **Emitter** | `emitter.gd` / `emitter.tscn` (procedural `_draw`, no texture) | fires a beam from its cell in its `direction` with its `color` (default WHITE) | none (not rotatable) | `direction`, `color` | multiple emitters share one `visited_states` guard | IMPLEMENTED |
| **Beam (laser)** | `laser_system.gd`, drawn by `grid_manager.gd` | grid-stepped polyline segments per branch; a portal transit starts a new segment | – | `BeamColor` | stops at blocker, hazard, closed gate, board edge, Fusion node, absorbing selector side; passes through targets, switches, receivers, open gates, filters (recolour) | IMPLEMENTED |
| **Mirror** | `mirror.gd` / `mirror.tscn` (texture `bs_tile_mirror_runtime.png`) | reflects via `GridTypes.reflect` | tap toggles `/` `\` | `MirrorOrientation` | `rotatable=false` = fixed mirror (locked SFX); selection FX `bs_fx_mirror_selection_runtime.png`; impact VFX burst only for mirrors | IMPLEMENTED |
| **Splitter** | `splitter.gd` / `splitter.tscn` (procedural) | beam continues straight AND spawns a second branch reflected by `reflect(dir, orientation)` | tap toggles orientation | `MirrorOrientation` | both branches keep colour; shared loop guard | IMPLEMENTED |
| **Filter** | `filter.gd` (procedural) | recolours the beam to the filter's colour and continues | none | `color` | evaluated AFTER portal and BEFORE splitter/mirror in the step order; a Filter after a Fusion node would erase the fused colour (generator forbids it) | IMPLEMENTED |
| **Target** | `target.gd` (texture `bs_tile_target_runtime.png`, activated glow) | activates when a beam of an accepted colour passes (`WHITE` target accepts any colour); beam continues past it | none | `color`, `required` | non-required targets do not count toward `solved`; hitting a target never stops the beam (this created several "shortcut" authoring bugs, see docs D81–D83) | IMPLEMENTED |
| **Blocker** | `blocker.gd` (texture) | stops the beam | none | – | placed to prevent shortcuts in generated/handmade levels | IMPLEMENTED |
| **Hazard** | `hazard.gd` (texture) | stops the beam; sets `hazard_hit`, which makes `solved` false | none | – | triggers `hazard_hit` SFX on a player move | IMPLEMENTED |
| **Portal pair** | `portal.gd` (procedural) | beam entering a portal is relocated to the partner with direction and colour preserved; only pairs with exactly 2 members work (otherwise inert) | none | `pair_id` | portal check runs before filters | IMPLEMENTED |
| **Switch** | `switch.gd` (procedural) | beam passing records `gate_id` as opened (monotonic across passes); beam continues | none | `gate_id` | resolved by `simulate_until_stable` multi-pass; stateless across player moves (re-derived every simulation) | IMPLEMENTED |
| **Gate** | `gate.gd` (textures open/closed) | closed gate stops the beam; open passes | none | `gate_id`, `initial_open_state` | opens only after a pass where its switch was hit | IMPLEMENTED |
| **Prism** (Era 2) | `prism_tile.gd` (`bs_tile_prism_base_era2.png`, opaque RGB) | WHITE beam splits into three channel branches (RED straight, GREEN reflect-SLASH, BLUE reflect-BACKSLASH); a coloured beam uses only its own channel | none (fixed) | `prism_output_direction` | derived from `reflect()` – no new table | IMPLEMENTED (art is purple, Era 2) |
| **One-way reflector** (Era 2) | `one_way_reflector_tile.gd` | reflective only for the incoming-direction pair that includes RIGHT for its orientation; other pair passes straight | tap toggles orientation | `MirrorOrientation` | shared by two beams: both rules apply | IMPLEMENTED |
| **Beam receiver** (Era 2) | `beam_receiver_tile.gd` | like a switch but powers a `link_id` | none | `link_id` | beam continues through it | IMPLEMENTED |
| **Remote emitter** (Era 2) | `remote_emitter_tile.gd` | fires only once its `link_id` is powered from a PRIOR pass | none | `direction`, `color`, `link_id` | resolved with the same monotonic multi-pass rule as gates | IMPLEMENTED |
| **Fusion node** | `fusion_tile.gd` (`bs_fusion_node(_active).png`) | **terminates** every beam reaching it; inputs only RED/GREEN/BLUE through non-output sides; next pass emits ONE beam from its output side in the fused colour (RG→YELLOW, RB→MAGENTA, GB→CYAN, RGB→WHITE); output state REPLACED each pass (never latched) | tap steps output direction clockwise (4-state) | `combine_beam_colors` | `LevelSolver` cannot model it (4-state); levels carry their own solutions; tutorials T21–T28 | IMPLEMENTED |
| **Splitter selector** | `splitter_selector_tile.gd` (`bs_splitter_selector(_active).png`) | one beam in → exactly ONE beam out through the selected output side, same pass, colour unchanged; entering through the output side is absorbed | tap steps output direction clockwise | `tile_orientations` = output `Direction` | must TURN the beam to matter (a straight-line selector is bypassed by removal) | IMPLEMENTED |

Other gameplay facts
* **Move tracking:** `GridManager.move_made` → `game.gd._on_move_made` increments `moves_used`, persists resume state (orientations + count) on every accepted move.
* **Reset / restart:** Reset button and Pause → Restart call `_load_current_level(force_fresh=true)` (fresh puzzle, never resumes the pre-reset board). **No undo.**
* **Stars:** `StarScoring` (Part 5). **Hints:** Part 5/36.
* **Impact VFX** (`laser_mirror_impact_fx.gd`, max 40, min cell 8px) read the simulation result only; they never feed it.
* **Input gating (tutorials):** `GridManager.interaction_locked` / `interaction_restricted_to` — set only by `TutorialManager`; `_on_orientable_tile_clicked` is the single gate.

---

## PART 8 — LASER SIMULATION (reverse-engineered from `scripts/gameplay/laser_system.gd`)

1. **Trigger.** `GridManager._simulate_and_draw(play_impacts)` is called on level load, restore, reset and after every accepted tap. It calls `LaserSystem.simulate_until_stable(level_data, tile_orientations)`.
2. **Emitter start.** Every `EMITTER` tile enqueues `{position, direction, color, segments:[[pos]]}`; also each `REMOTE_EMITTER` whose `link_id` is already powered, and each `FUSION` node whose previous-pass fused colour is valid (`fusion_states[pos] >= 0`).
3. **Grid coordinates.** `Vector2i(x, y)`, origin top-left, x → right, y → down. `grid_width/grid_height` are columns/rows.
4. **Direction.** `GridTypes.Direction {UP, RIGHT, DOWN, LEFT}`; `direction_vector()`: UP (0,-1), RIGHT (1,0), DOWN (0,1), LEFT (-1,0).
5. **Traversal.** An explicit work-list (no recursion). Each beam loops: record `state_key = "x,y|dir|color"`; if already visited → `looped = true`, stop; else step one cell. Leaving the grid appends the out-of-bounds point and ends the branch.
6. **Per-cell rules, in exact priority order** (first match wins): blocker (append, stop) → hazard (append, record hit, stop) → gate (closed: append, stop; open: pass) → switch (record gate id, continue) → beam receiver (record link id, continue) → fusion (append, record input colour per entry side, **stop**) → splitter selector (append, route to selected output; absorbed if entering via output side) → portal (append entry, jump to partner, new segment, continue) → filter (recolour, continue) → splitter (append, enqueue reflected branch, continue straight) → prism (WHITE: enqueue R/G/B branches and stop; coloured: turn into own channel and continue) → mirror (append, reflect, continue) → one-way reflector (reflect only if reflective for that orientation) → target (append, activate if colour accepted, **continue**) → empty (continue).
7. **Mirror reflection:** only `GridTypes.reflect(dir, orientation)`: SLASH: RIGHT→UP, LEFT→DOWN, UP→RIGHT, DOWN→LEFT; BACKSLASH: RIGHT→DOWN, LEFT→UP, UP→LEFT, DOWN→RIGHT.
8. **Splitter:** continues straight and adds a branch `reflect(dir, orientation)` at the same cell.
9. **Colour/filters:** filters overwrite the beam colour; targets use `target_accepts_color` (WHITE required colour accepts anything; otherwise exact match).
10. **Switch/gate:** `simulate()` is ONE pass with fixed `gate_states`; hits are collected in `activated_gate_ids`. `simulate_until_stable()` repeats passes, opening gates monotonically (never re-closing) until nothing changes. Same mechanism for `receiver_states` and (replaced each pass) `fusion_states`.
11. **Convergence/limits.** `max_passes = max(1, gates + receivers + 1) + MAX_EXTRA_PASSES(8) + 3 × fusion_nodes`; per-pass hard cap `MAX_STEPS = 20000`; the shared `visited_states` dictionary guards cycles across all branches/emitters (CLAUDE rule 5 — must never be narrowed). `result["converged"]`/`["passes"]` expose whether it settled before the cap (generator QA asserts this).
12. **Multiple beams.** All branches finish into `beams` (`[{segments, color}]`); the result also carries `activated_targets`, `activated_switch_positions`, `activated_gate_ids`, `hit_hazard_positions`, `activated_receiver_positions`, `activated_link_ids`, `fusion_colors`, `fusion_input_*`, `selector_hits`, `gate_states`, `receiver_states`, `looped`, `solved`.
13. **Completion.** `solved = required_count > 0 and required_activated >= required_count and not hazard_hit`.
14. **Rendering.** `GridManager._redraw_beams()` draws each segment as a wide low-alpha glow line (18 px, alpha 0.3) plus a bright core (5 px, brightened 0.35) using `GridTypes.beam_color_to_render_color` (RED(1,.3,.3) GREEN(.35,1,.45) BLUE(.4,.6,1) YELLOW amber MAGENTA CYAN, WHITE warm yellow-white).
15. **Recalculation.** Recomputed from scratch each time (stateless); resize only redraws (`_redraw_beams`), never respawns impacts.
16. **Performance.** O(cells × beams) with the visited-state prune; Era-2/Fusion boards with many gates need extra passes but converge in ≤ cap. Procedural generation self-verifies by calling this same function (never the solver) at runtime.

---

## PART 9 — LEVEL AUDIT

**Actual counts** (verified by loading every file headlessly): **15** dev/regression levels · **140** handcrafted campaign levels (100 Era-1 + 40 Era-2) · **34** guided tutorials · **3,000** procedural levels (generated on demand, no files) · 12 editor fixtures · 6+ Fusion QA and Selector QA puzzles · `levels/hint_solutions.json` has 174 entries.

How levels are represented/loaded
* Handcrafted level = a `.gd` file `extends LevelData` that fills fields in `_init()` with `TilePlacement.make_*` factories (not `.tres`). Tutorials are `TutorialLevelData` (a LevelData plus `steps`).
* Catalogs are three `const` path arrays in `LevelManager` (`LEVEL_PATHS`, `CAMPAIGN_LEVEL_PATHS`, `TUTORIAL_LEVEL_PATHS`); a level's **order = array order**; **campaign number = array index + 1** (the `level_id` field inside the Era-2 files is a local 1–40 and ids repeat across stage folders — the array index is authoritative; save keys use the campaign number).
* Three separate populations with separate save fields (dev levels: `highest_unlocked_level`, `completed_levels`, …; campaign: `campaign_*`; tutorial: `tutorial_*`; procedural: `procedural_*`). Never mix them.
* **Unlock/completion/replay:** campaign: next level unlocks on completion (`record_campaign_level_result`), replays allowed, best moves/stars kept. Tutorial: sequential, T11–T20 additionally need campaign level 100 done, T21 needs procedural level 150 (or T20), T29 needs procedural level 1900. Procedural: `procedural_current_level` advances only on a legitimate completion; replays/Continue use `procedural_resume_*`.
* **Debug unlock:** `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` and `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` equal `BuildConfig.QA_TOOLS` (false in production). `SHOW_PROCEDURAL_QA_NEXT_BUTTON` ("+50") likewise.
* **Skipping:** only QA builds (Level Select, +50). In production a level cannot be skipped.
* **Missing assets/references:** none found (Part 27). Levels reference no art directly.

### Procedural generator (the player-facing level source)
`scripts/procedural/*` (20 files, runtime). `ProceduralLevelGenerator.generate(level, version)` returns `{level_data, seed, attempt, generator_version, template_id, board_size, fallback_used, rejections, solution_orientations, intended_moves, …}`. **MIN 1, `MAX_LEVEL = 3000`**, `GENERATOR_VERSION` default constant = 2 but `LevelManager.procedural_generator_version_for_new_play()` returns **V5 for level ≥ 2001, V4 for ≤ 2000** (flags `USE_V3_FOR_PROCEDURAL_QA` and `USE_FUSION_PROGRESSION_FOR_QA` are `const true` even in production despite their names). V1/V2 stay frozen for old saves; a saved puzzle regenerates under its saved version. Difficulty contract (`procedural_difficulty_contract.gd`): bands Foundation (1–20, 3–5 moves) → Early Thinking (21–50) → Developing (51–100) → Medium (101–200) → Medium-Hard (201–400) → Hard (401–700) → Hard+ (701–1000) → Expert (1001–1300) → Expert+ (1301–1600) → Master (1601–1800) → Advanced Master (1801–2000, 20–26 moves) → V5 bands Selector Entry (2001–2200) … Selector Mastery (2801–3000, 28–34 moves). Mechanics unlock by level (switch/gate 21, prism 51, receiver/one-way 101, multi-emitter + Fusion 201). Board shapes prefer tall portrait (5×7 early … 8×10/8×11 late; `MAX_COLUMNS=8`). Fusion share 10–28% per band; Selector share 40–76% in 2001–3000 (deterministic golden-ratio sequence). **`verified_optimal_moves` is −1 for every V5 level** (exact optimum unknown); stars use `intended_moves`.

### 9.1 Development / regression levels (`LevelManager.LEVEL_PATHS`, 15)

| # | Name | File | Grid | Opt. moves | Tiles | Rotatable (2-state) | Mechanics | Role |
|---|---|---|---|---|---|---|---|---|
| 1 | First Light | `levels/level_01.gd` | 5x5 | 1 | 3 | 1 | EMITTER:1 MIRROR:1 TARGET:1 | first mirror |
| 2 | Reflection | `levels/level_02.gd` | 5x5 | 2 | 4 | 2 | EMITTER:1 MIRROR:2 TARGET:1 | two mirrors |
| 3 | Obstruction | `levels/level_03.gd` | 5x5 | 2 | 5 | 2 | EMITTER:1 MIRROR:2 BLOCKER:1 TARGET:1 | blocker |
| 4 | Fixed Point | `levels/level_04.gd` | 5x5 | 2 | 5 | 2 | EMITTER:1 MIRROR:3 TARGET:1 | fixed mirror |
| 5 | Three Turns | `levels/level_05.gd` | 5x5 | 3 | 7 | 4 | EMITTER:1 MIRROR:4 BLOCKER:1 TARGET:1 | multi-turn + blocker |
| 6 | Twin Targets | `levels/level_06.gd` | 5x5 | 1 | 4 | 1 | EMITTER:1 TARGET:2 MIRROR:1 | two targets |
| 7 | Split Path | `levels/level_07.gd` | 5x5 | 1 | 4 | 1 | EMITTER:1 SPLITTER:1 TARGET:2 | splitter |
| 8 | True Color | `levels/level_08.gd` | 5x5 | 1 | 3 | 1 | EMITTER:1 MIRROR:1 TARGET:1 | coloured emitter/target |
| 9 | Recolor | `levels/level_09.gd` | 5x5 | 1 | 4 | 1 | EMITTER:1 MIRROR:1 FILTER:1 TARGET:1 | filter recolour |
| 10 | Through the Portal | `levels/level_10.gd` | 5x5 | 1 | 5 | 1 | EMITTER:1 MIRROR:1 PORTAL:2 TARGET:1 | portal pair |
| 11 | Switch and Gate | `levels/level_11.gd` | 5x6 | 1 | 5 | 1 | EMITTER:1 MIRROR:1 SWITCH:1 GATE:1 TARGET:1 | switch + gate |
| 12 | Danger Zone | `levels/level_12.gd` | 5x5 | 2 | 5 | 2 | EMITTER:1 MIRROR:2 HAZARD:1 TARGET:1 | hazard |
| 13 | Two Sources | `levels/level_13.gd` | 5x5 | 2 | 6 | 2 | EMITTER:2 MIRROR:2 TARGET:2 | two emitters |
| 14 | Convergence | `levels/level_14.gd` | 5x5 | 1 | 5 | 1 | EMITTER:1 SPLITTER:1 TARGET:2 FILTER:1 | splitter + filter convergence |
| 15 | All Systems | `levels/level_15.gd` | 6x6 | 2 | 11 | 2 | EMITTER:2 MIRROR:2 SWITCH:1 GATE:1 TARGET:2 HAZARD:1 PORTAL:2 | everything combined (6x6) |

### 9.2 Handcrafted campaign (`LevelManager.CAMPAIGN_LEVEL_PATHS`, 140 levels; campaign number = array index + 1; the `level_id` inside era2_stage_01 files is local 1-40)

| Camp # | Name | File | Grid | Opt. moves | Tiles | Rot2 | Mechanics (tile counts) | Stage tag |
|---|---|---|---|---|---|---|---|---|
| 1 | Ignition | `stage_01/level_01.gd` | 5x6 | 1 | 3 | 1 | EMITTER:1 MIRROR:1 TARGET:1 | First Light |
| 2 | First Turn | `stage_01/level_02.gd` | 5x6 | 2 | 4 | 2 | EMITTER:1 MIRROR:2 TARGET:1 | First Light |
| 3 | Signal Path | `stage_01/level_03.gd` | 5x6 | 2 | 5 | 3 | EMITTER:1 MIRROR:3 TARGET:1 | First Light |
| 4 | Blocked | `stage_01/level_04.gd` | 5x6 | 2 | 5 | 2 | EMITTER:1 MIRROR:2 BLOCKER:1 TARGET:1 | First Light |
| 5 | Alignment | `stage_01/level_05.gd` | 5x6 | 2 | 5 | 2 | EMITTER:1 MIRROR:3 TARGET:1 | First Light |
| 6 | False Signal | `stage_01/level_06.gd` | 5x6 | 3 | 5 | 3 | EMITTER:1 MIRROR:3 TARGET:1 | First Light |
| 7 | Deception | `stage_01/level_07.gd` | 5x7 | 3 | 6 | 4 | EMITTER:1 MIRROR:4 TARGET:1 | First Light |
| 8 | Long Relay | `stage_01/level_08.gd` | 5x7 | 4 | 6 | 4 | EMITTER:1 MIRROR:4 TARGET:1 | First Light |
| 9 | Junction | `stage_01/level_09.gd` | 5x7 | 3 | 8 | 4 | EMITTER:1 MIRROR:5 BLOCKER:1 TARGET:1 | First Light |
| 10 | Breakthrough | `stage_01/level_10.gd` | 5x7 | 4 | 10 | 6 | EMITTER:1 MIRROR:7 BLOCKER:1 TARGET:1 | First Light |
| 11 | Redirect | `stage_02/level_01.gd` | 5x6 | 3 | 5 | 3 | EMITTER:1 MIRROR:3 TARGET:1 | Reflection |
| 12 | Dead End | `stage_02/level_02.gd` | 5x6 | 3 | 6 | 3 | EMITTER:1 MIRROR:3 BLOCKER:1 TARGET:1 | Reflection |
| 13 | Fork Point | `stage_02/level_03.gd` | 5x6 | 3 | 6 | 4 | EMITTER:1 MIRROR:4 TARGET:1 | Reflection |
| 14 | Reverse Trace | `stage_02/level_04.gd` | 5x6 | 3 | 6 | 3 | EMITTER:1 MIRROR:4 TARGET:1 | Reflection |
| 15 | Mirage | `stage_02/level_05.gd` | 5x7 | 4 | 7 | 5 | EMITTER:1 MIRROR:5 TARGET:1 | Reflection |
| 16 | Cascade | `stage_02/level_06.gd` | 5x7 | 4 | 6 | 4 | EMITTER:1 MIRROR:4 TARGET:1 | Reflection |
| 17 | Backtrack | `stage_02/level_07.gd` | 5x7 | 4 | 8 | 4 | EMITTER:1 MIRROR:5 BLOCKER:1 TARGET:1 | Reflection |
| 18 | Echo Path | `stage_02/level_08.gd` | 5x7 | 5 | 8 | 5 | EMITTER:1 MIRROR:6 TARGET:1 | Reflection |
| 19 | Interference | `stage_02/level_09.gd` | 5x7 | 5 | 9 | 7 | EMITTER:1 MIRROR:7 TARGET:1 | Reflection |
| 20 | Culmination | `stage_02/level_10.gd` | 6x7 | 5 | 12 | 6 | EMITTER:1 MIRROR:8 BLOCKER:2 TARGET:1 | Reflection |
| 21 | Crossfire | `stage_03/level_01.gd` | 6x7 | 5 | 10 | 6 | EMITTER:1 MIRROR:5 SPLITTER:1 HAZARD:1 TARGET:2 | Split |
| 22 | Detour | `stage_03/level_02.gd` | 6x7 | 6 | 12 | 7 | EMITTER:1 MIRROR:7 FILTER:1 PORTAL:2 TARGET:1 | Split |
| 23 | Misdirect | `stage_03/level_03.gd` | 6x7 | 5 | 11 | 5 | EMITTER:1 MIRROR:7 FILTER:1 TARGET:2 | Split |
| 24 | Standoff | `stage_03/level_04.gd` | 6x7 | 6 | 12 | 7 | EMITTER:1 MIRROR:6 SPLITTER:1 HAZARD:1 SWITCH:1 GATE:1 TARGET:1 | Split |
| 25 | Bottleneck | `stage_03/level_05.gd` | 7x8 | 6 | 13 | 7 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:8 TARGET:2 | Split |
| 26 | Labyrinth | `stage_03/level_06.gd` | 7x8 | 7 | 13 | 8 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:8 TARGET:2 | Split |
| 27 | Impasse | `stage_03/level_07.gd` | 7x8 | 8 | 14 | 8 | EMITTER:1 MIRROR:8 FILTER:3 TARGET:2 | Split |
| 28 | Gambit | `stage_03/level_08.gd` | 6x7 | 6 | 13 | 7 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:6 FILTER:2 TARGET:2 | Split |
| 29 | Stalemate | `stage_03/level_09.gd` | 6x7 | 7 | 14 | 8 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:8 GATE:1 TARGET:1 SWITCH:1 | Split |
| 30 | Deadlock | `stage_03/level_10.gd` | 7x8 | 7 | 16 | 8 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:8 FILTER:2 TARGET:2 | Split |
| 31 | Ambush | `stage_04/level_01.gd` | 6x7 | 6 | 12 | 7 | EMITTER:1 MIRROR:7 HAZARD:1 PORTAL:2 TARGET:1 | Spectrum |
| 32 | Gauntlet | `stage_04/level_02.gd` | 6x7 | 7 | 13 | 7 | EMITTER:2 MIRROR:7 HAZARD:1 SWITCH:1 GATE:1 TARGET:1 | Spectrum |
| 33 | Feint | `stage_04/level_03.gd` | 6x7 | 6 | 14 | 7 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:6 FILTER:2 TARGET:2 | Spectrum |
| 34 | Snare | `stage_04/level_04.gd` | 7x8 | 5 | 13 | 5 | EMITTER:1 MIRROR:5 TARGET:2 PORTAL:2 SWITCH:1 FILTER:1 GATE:1 | Spectrum |
| 35 | Ricochet | `stage_04/level_05.gd` | 7x8 | 7 | 16 | 8 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:8 FILTER:2 TARGET:2 | Spectrum |
| 36 | Vertex | `stage_04/level_06.gd` | 7x8 | 9 | 16 | 10 | EMITTER:2 MIRROR:11 HAZARD:1 TARGET:2 | Spectrum |
| 37 | Nexus | `stage_04/level_07.gd` | 8x9 | 9 | 17 | 10 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:10 PORTAL:2 TARGET:2 | Spectrum |
| 38 | Quandary | `stage_04/level_08.gd` | 6x7 | 6 | 14 | 7 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:6 FILTER:2 TARGET:2 | Spectrum |
| 39 | Riddle | `stage_04/level_09.gd` | 6x7 | 9 | 17 | 10 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:11 TARGET:2 | Spectrum |
| 40 | Crucible | `stage_04/level_10.gd` | 8x9 | 11 | 22 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 PORTAL:2 TARGET:2 FILTER:2 | Spectrum |
| 41 | Foresight | `stage_05/level_01.gd` | 6x8 | 8 | 17 | 8 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:9 FILTER:2 TARGET:2 | Filters |
| 42 | Hindsight | `stage_05/level_02.gd` | 7x8 | 9 | 17 | 10 | EMITTER:1 MIRROR:11 HAZARD:1 PORTAL:2 FILTER:1 TARGET:1 | Filters |
| 43 | Tangent | `stage_05/level_03.gd` | 7x8 | 10 | 19 | 11 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:10 FILTER:1 PORTAL:2 TARGET:2 | Filters |
| 44 | Overwatch | `stage_05/level_04.gd` | 6x7 | 7 | 13 | 7 | EMITTER:2 MIRROR:7 HAZARD:1 SWITCH:1 GATE:1 TARGET:1 | Filters |
| 45 | Threshold | `stage_05/level_05.gd` | 9x10 | 11 | 23 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 FILTER:3 PORTAL:2 TARGET:2 | Filters |
| 46 | Frequency | `stage_05/level_06.gd` | 6x7 | 6 | 12 | 6 | EMITTER:1 SPLITTER:1 TARGET:3 MIRROR:5 BLOCKER:1 FILTER:1 | Filters |
| 47 | Transmute | `stage_05/level_07.gd` | 6x7 | 5 | 14 | 5 | EMITTER:1 SPLITTER:1 TARGET:3 MIRROR:5 BLOCKER:2 FILTER:2 | Filters |
| 48 | Waveform | `stage_05/level_08.gd` | 6x7 | 6 | 14 | 6 | EMITTER:1 MIRROR:6 TARGET:3 BLOCKER:1 SPLITTER:1 FILTER:2 | Filters |
| 49 | Vortex | `stage_05/level_09.gd` | 6x7 | 6 | 14 | 6 | EMITTER:1 MIRROR:6 FILTER:3 BLOCKER:1 SPLITTER:1 TARGET:2 | Filters |
| 50 | Paradox | `stage_05/level_10.gd` | 7x8 | 7 | 18 | 8 | EMITTER:1 MIRROR:9 FILTER:4 BLOCKER:1 SPLITTER:1 TARGET:2 | Filters |
| 51 | Interlock | `stage_06/level_01.gd` | 7x8 | 10 | 18 | 10 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:9 SWITCH:2 GATE:2 TARGET:2 | Continuum |
| 52 | Currents | `stage_06/level_02.gd` | 6x7 | 8 | 17 | 9 | EMITTER:1 MIRROR:10 HAZARD:1 FILTER:2 PORTAL:2 TARGET:1 | Continuum |
| 53 | Shared Line | `stage_06/level_03.gd` | 6x7 | 7 | 14 | 7 | EMITTER:2 MIRROR:7 SWITCH:1 FILTER:1 TARGET:2 GATE:1 | Continuum |
| 54 | Dual Transit | `stage_06/level_04.gd` | 9x10 | 11 | 24 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 PORTAL:4 FILTER:2 TARGET:2 | Continuum |
| 55 | Sequence Lock | `stage_06/level_05.gd` | 7x8 | 11 | 21 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:11 FILTER:2 SWITCH:1 TARGET:2 GATE:1 | Continuum |
| 56 | Shared Transit | `stage_06/level_06.gd` | 9x10 | 8 | 20 | 9 | EMITTER:2 MIRROR:9 HAZARD:1 PORTAL:4 SWITCH:1 TARGET:2 GATE:1 | Continuum |
| 57 | Long Division | `stage_06/level_07.gd` | 10x11 | 9 | 17 | 10 | EMITTER:1 MIRROR:12 HAZARD:1 FILTER:2 TARGET:1 | Continuum |
| 58 | Delayed Fault | `stage_06/level_08.gd` | 7x8 | 11 | 19 | 12 | EMITTER:1 SPLITTER:1 HAZARD:2 MIRROR:12 FILTER:1 TARGET:2 | Continuum |
| 59 | Near Convergence | `stage_06/level_09.gd` | 8x10 | 11 | 24 | 12 | EMITTER:2 MIRROR:12 HAZARD:1 PORTAL:4 SWITCH:1 TARGET:2 GATE:1 FILTER:1 | Continuum |
| 60 | Threshold of Reason | `stage_06/level_10.gd` | 9x10 | 14 | 27 | 15 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:14 PORTAL:2 SWITCH:1 FILTER:3 TARGET:2 GATE:1 | Continuum |
| 61 | Peripheral | `stage_07/level_01.gd` | 7x8 | 10 | 18 | 11 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:10 TARGET:2 FILTER:2 | Continuum |
| 62 | Longcut | `stage_07/level_02.gd` | 8x9 | 10 | 15 | 11 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:10 TARGET:2 | Continuum |
| 63 | Invalidation | `stage_07/level_03.gd` | 8x9 | 10 | 20 | 11 | EMITTER:1 SPLITTER:1 HAZARD:1 MIRROR:10 TARGET:3 GATE:1 PORTAL:2 SWITCH:1 | Continuum |
| 64 | Twin Anchor | `stage_07/level_04.gd` | 7x8 | 10 | 17 | 11 | EMITTER:2 MIRROR:12 HAZARD:1 TARGET:2 | Continuum |
| 65 | Convergence Point | `stage_07/level_05.gd` | 9x10 | 12 | 20 | 13 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 TARGET:2 SWITCH:1 GATE:1 | Continuum |
| 66 | Portal Trap | `stage_07/level_06.gd` | 7x8 | 7 | 13 | 7 | EMITTER:1 MIRROR:7 HAZARD:2 PORTAL:2 TARGET:1 | Continuum |
| 67 | Chain Reaction | `stage_07/level_07.gd` | 9x10 | 11 | 22 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 FILTER:4 TARGET:2 | Continuum |
| 68 | Twin Corridor | `stage_07/level_08.gd` | 8x9 | 9 | 19 | 11 | EMITTER:2 MIRROR:11 HAZARD:1 SWITCH:2 GATE:1 TARGET:2 | Continuum |
| 69 | Color Conflict | `stage_07/level_09.gd` | 8x9 | 12 | 24 | 13 | EMITTER:2 MIRROR:13 HAZARD:1 SWITCH:1 FILTER:4 TARGET:2 GATE:1 | Continuum |
| 70 | Grand Convergence | `stage_07/level_10.gd` | 9x10 | 11 | 27 | 12 | EMITTER:2 MIRROR:12 HAZARD:1 PORTAL:2 BLOCKER:1 SWITCH:2 FILTER:3 GATE:2 TARGET:2 | Continuum |
| 71 | Deliberate Detour | `stage_08/level_01.gd` | 9x10 | 11 | 23 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 PORTAL:2 SWITCH:1 TARGET:2 FILTER:1 GATE:1 | Continuum |
| 72 | Locked Corridor | `stage_08/level_02.gd` | 8x9 | 9 | 22 | 11 | EMITTER:2 MIRROR:11 HAZARD:1 FILTER:3 SWITCH:2 GATE:1 TARGET:2 | Continuum |
| 73 | Locked Splitter | `stage_08/level_03.gd` | 9x10 | 11 | 25 | 12 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:11 FILTER:4 SWITCH:2 GATE:2 TARGET:2 | Continuum |
| 74 | Twin Portals | `stage_08/level_04.gd` | 9x10 | 8 | 20 | 9 | EMITTER:2 MIRROR:9 HAZARD:1 PORTAL:2 FILTER:2 TARGET:2 SWITCH:1 GATE:1 | Continuum |
| 75 | Convergence Reaction | `stage_08/level_05.gd` | 9x10 | 13 | 26 | 14 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:14 FILTER:4 SWITCH:1 TARGET:2 GATE:1 | Continuum |
| 76 | Reverse Relay | `stage_08/level_06.gd` | 9x10 | 11 | 27 | 12 | EMITTER:2 MIRROR:12 HAZARD:1 PORTAL:2 BLOCKER:1 SWITCH:2 FILTER:3 GATE:2 TARGET:2 | Continuum |
| 77 | Distant Splitter | `stage_08/level_07.gd` | 10x12 | 12 | 28 | 13 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:12 FILTER:4 SWITCH:2 GATE:2 PORTAL:2 TARGET:2 | Continuum |
| 78 | Distant Corridor | `stage_08/level_08.gd` | 9x10 | 12 | 27 | 14 | EMITTER:2 MIRROR:14 HAZARD:1 FILTER:3 SWITCH:2 GATE:1 PORTAL:2 TARGET:2 | Continuum |
| 79 | Silent Third | `stage_08/level_09.gd` | 10x12 | 13 | 33 | 15 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:14 FILTER:4 SWITCH:3 GATE:3 PORTAL:2 TARGET:2 | Continuum |
| 80 | Full Convergence | `stage_08/level_10.gd` | 10x12 | 14 | 37 | 16 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:15 FILTER:4 SWITCH:4 GATE:5 PORTAL:2 TARGET:2 | Continuum |
| 81 | Third Signal | `stage_09/level_01.gd` | 9x10 | 12 | 28 | 13 | EMITTER:3 MIRROR:13 HAZARD:1 PORTAL:2 FILTER:2 TARGET:2 SWITCH:2 GATE:2 BLOCKER:1 | Continuum |
| 82 | Crossed Corridors | `stage_09/level_02.gd` | 10x12 | 11 | 28 | 12 | EMITTER:3 MIRROR:12 HAZARD:1 FILTER:5 GATE:2 TARGET:2 SWITCH:2 BLOCKER:1 | Continuum |
| 83 | Silent Detour | `stage_09/level_03.gd` | 10x12 | 11 | 28 | 13 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:2 MIRROR:13 PORTAL:2 GATE:2 SWITCH:2 TARGET:2 FILTER:1 | Continuum |
| 84 | Distant Relay | `stage_09/level_04.gd` | 9x10 | 12 | 30 | 13 | EMITTER:2 MIRROR:13 HAZARD:1 PORTAL:4 BLOCKER:1 SWITCH:2 FILTER:3 GATE:2 TARGET:2 | Continuum |
| 85 | Convergence Threshold | `stage_09/level_05.gd` | 9x10 | 14 | 31 | 15 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:2 MIRROR:15 FILTER:4 SWITCH:2 TARGET:2 GATE:2 | Continuum |
| 86 | Reciprocal Corridor | `stage_09/level_06.gd` | 10x12 | 12 | 32 | 14 | EMITTER:2 MIRROR:14 HAZARD:1 FILTER:3 SWITCH:3 GATE:2 PORTAL:4 TARGET:2 BLOCKER:1 | Continuum |
| 87 | Triple Relay | `stage_09/level_07.gd` | 9x10 | 10 | 26 | 11 | EMITTER:3 MIRROR:11 HAZARD:1 SWITCH:3 GATE:3 FILTER:2 TARGET:2 BLOCKER:1 | Continuum |
| 88 | Distant Triple Relay | `stage_09/level_08.gd` | 10x12 | 12 | 32 | 13 | EMITTER:3 MIRROR:13 HAZARD:1 SWITCH:3 GATE:3 FILTER:2 PORTAL:4 TARGET:2 BLOCKER:1 | Continuum |
| 89 | Fourfold Relay | `stage_09/level_09.gd` | 10x12 | 13 | 37 | 14 | EMITTER:4 MIRROR:14 HAZARD:1 SWITCH:4 GATE:4 FILTER:2 PORTAL:4 TARGET:2 BLOCKER:2 | Continuum |
| 90 | Full Circuit | `stage_09/level_10.gd` | 10x12 | 13 | 40 | 14 | EMITTER:5 GATE:5 MIRROR:14 HAZARD:1 SWITCH:5 FILTER:2 PORTAL:4 TARGET:2 BLOCKER:2 | Continuum |
| 91 | Inferred Convergence | `stage_10/level_01.gd` | 9x10 | 13 | 26 | 14 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:14 FILTER:4 SWITCH:1 TARGET:2 GATE:1 | Continuum |
| 92 | Delayed Verdict | `stage_10/level_02.gd` | 10x12 | 13 | 31 | 14 | EMITTER:1 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:13 FILTER:4 SWITCH:3 GATE:3 PORTAL:2 TARGET:2 | Continuum |
| 93 | Pre-Split Signal | `stage_10/level_03.gd` | 10x12 | 11 | 24 | 12 | EMITTER:1 FILTER:3 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:11 SWITCH:2 GATE:2 TARGET:2 | Continuum |
| 94 | Traced Colors | `stage_10/level_04.gd` | 10x12 | 11 | 30 | 13 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:2 MIRROR:13 PORTAL:2 GATE:2 FILTER:3 SWITCH:2 TARGET:2 | Continuum |
| 95 | Final Threshold | `stage_10/level_05.gd` | 9x10 | 15 | 35 | 16 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:2 MIRROR:16 FILTER:5 SWITCH:2 PORTAL:2 TARGET:2 GATE:2 | Continuum |
| 96 | Chain of Custody | `stage_10/level_06.gd` | 9x10 | 12 | 28 | 13 | EMITTER:3 MIRROR:13 HAZARD:1 SWITCH:3 GATE:3 FILTER:2 TARGET:2 BLOCKER:1 | Continuum |
| 97 | Triple Verdict | `stage_10/level_07.gd` | 10x12 | 14 | 35 | 15 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:1 MIRROR:14 FILTER:4 SWITCH:3 GATE:4 PORTAL:2 TARGET:3 | Continuum |
| 98 | Triple Inference | `stage_10/level_08.gd` | 9x10 | 14 | 31 | 15 | EMITTER:2 SPLITTER:1 HAZARD:1 BLOCKER:2 MIRROR:15 FILTER:4 SWITCH:2 TARGET:2 GATE:2 | Continuum |
| 99 | Penultimate Verdict | `stage_10/level_09.gd` | 10x12 | 14 | 39 | 15 | EMITTER:3 SPLITTER:1 HAZARD:1 BLOCKER:2 MIRROR:14 FILTER:4 SWITCH:4 GATE:5 PORTAL:2 TARGET:3 | Continuum |
| 100 | Culmination | `stage_10/level_10.gd` | 10x12 | 13 | 42 | 14 | EMITTER:5 GATE:5 MIRROR:15 HAZARD:1 SWITCH:5 FILTER:2 PORTAL:4 TARGET:2 BLOCKER:3 | Continuum |
| 101 | First Refraction | `era2_stage_01/level_01.gd` | 7x7 | 2 | 7 | 2 | EMITTER:1 PRISM:1 TARGET:3 MIRROR:2 | Spectrum |
| 102 | Spectrum Route | `era2_stage_01/level_02.gd` | 7x8 | 2 | 10 | 2 | EMITTER:1 PRISM:1 TARGET:4 MIRROR:3 FILTER:1 | Spectrum |
| 103 | Fractured Path | `era2_stage_01/level_03.gd` | 8x8 | 2 | 10 | 2 | EMITTER:1 PRISM:1 TARGET:3 MIRROR:2 PORTAL:2 SPLITTER:1 | Spectrum |
| 104 | One Way | `era2_stage_01/level_04.gd` | 6x9 | 2 | 7 | 2 | EMITTER:2 ONE_WAY:1 BLOCKER:1 MIRROR:1 TARGET:2 | Spectrum |
| 105 | False Reflection | `era2_stage_01/level_05.gd` | 7x7 | 2 | 7 | 2 | EMITTER:1 PRISM:1 TARGET:3 ONE_WAY:2 | Spectrum |
| 106 | Remote Signal | `era2_stage_01/level_06.gd` | 5x8 | 2 | 6 | 2 | EMITTER:1 MIRROR:2 RECEIVER:1 REMOTE_EM:1 TARGET:1 | Signal |
| 107 | Signal Through | `era2_stage_01/level_07.gd` | 5x10 | 1 | 8 | 1 | EMITTER:1 FILTER:1 PORTAL:2 RECEIVER:1 REMOTE_EM:1 MIRROR:1 TARGET:1 | Signal |
| 108 | Refracted Signal | `era2_stage_01/level_08.gd` | 7x9 | 2 | 9 | 2 | EMITTER:1 PRISM:1 TARGET:3 RECEIVER:1 MIRROR:2 REMOTE_EM:1 | Signal |
| 109 | Directional Chain | `era2_stage_01/level_09.gd` | 7x6 | 1 | 7 | 1 | EMITTER:1 ONE_WAY:1 RECEIVER:1 REMOTE_EM:1 SWITCH:1 GATE:1 TARGET:1 | Signal |
| 110 | Refraction Nexus | `era2_stage_01/level_10.gd` | 8x10 | 3 | 14 | 3 | EMITTER:1 PRISM:1 ONE_WAY:1 SWITCH:1 PORTAL:2 FILTER:1 MIRROR:2 TARGET:2 RECEIVER:1 REMOTE_EM:1 GATE:1 | Nexus |
| 111 | Split Decision | `era2_stage_01/level_11.gd` | 7x8 | 3 | 11 | 3 | EMITTER:1 PRISM:1 TARGET:5 MIRROR:3 SPLITTER:1 | Circuit |
| 112 | Cross Signal | `era2_stage_01/level_12.gd` | 6x8 | 3 | 8 | 3 | EMITTER:1 ONE_WAY:1 RECEIVER:1 MIRROR:2 TARGET:2 REMOTE_EM:1 | Circuit |
| 113 | Spectral Gate | `era2_stage_01/level_13.gd` | 8x8 | 3 | 11 | 3 | EMITTER:1 PRISM:1 MIRROR:3 SWITCH:1 TARGET:3 FILTER:1 GATE:1 | Circuit |
| 114 | Remote Loop | `era2_stage_01/level_14.gd` | 7x10 | 3 | 11 | 3 | EMITTER:1 MIRROR:3 RECEIVER:2 REMOTE_EM:2 PORTAL:2 TARGET:1 | Circuit |
| 115 | Directional Prism | `era2_stage_01/level_15.gd` | 7x8 | 5 | 10 | 5 | EMITTER:1 PRISM:1 ONE_WAY:3 TARGET:3 MIRROR:2 | Checkpoint |
| 116 | False Activation | `era2_stage_01/level_16.gd` | 7x8 | 2 | 9 | 2 | EMITTER:1 MIRROR:3 RECEIVER:1 REMOTE_EM:1 SWITCH:1 GATE:1 TARGET:1 | Checkpoint |
| 117 | Split Spectrum | `era2_stage_01/level_17.gd` | 8x9 | 3 | 13 | 3 | EMITTER:1 PRISM:1 TARGET:4 MIRROR:3 PORTAL:2 FILTER:1 SPLITTER:1 | Checkpoint |
| 118 | Remote Crossing | `era2_stage_01/level_18.gd` | 9x10 | 4 | 14 | 4 | EMITTER:2 MIRROR:4 RECEIVER:2 REMOTE_EM:2 SWITCH:1 GATE:1 TARGET:2 | Checkpoint |
| 119 | Refraction Relay | `era2_stage_01/level_19.gd` | 9x9 | 4 | 15 | 4 | EMITTER:1 PRISM:1 MIRROR:4 TARGET:3 RECEIVER:1 SWITCH:1 REMOTE_EM:1 PORTAL:2 GATE:1 | Checkpoint |
| 120 | Era 2 Circuit | `era2_stage_01/level_20.gd` | 9x11 | 7 | 16 | 7 | EMITTER:1 PRISM:1 ONE_WAY:2 SWITCH:1 MIRROR:5 TARGET:3 GATE:1 RECEIVER:1 REMOTE_EM:1 | Checkpoint |
| 121 | Shared Spectrum | `era2_stage_01/level_21.gd` | 8x8 | 5 | 10 | 5 | EMITTER:1 PRISM:1 ONE_WAY:1 MIRROR:4 TARGET:3 | Convergence |
| 122 | Remote Pair | `era2_stage_01/level_22.gd` | 8x9 | 4 | 13 | 4 | EMITTER:1 MIRROR:4 RECEIVER:2 REMOTE_EM:2 GATE:1 TARGET:2 SWITCH:1 | Convergence |
| 123 | Prism Relay | `era2_stage_01/level_23.gd` | 9x10 | 3 | 13 | 3 | EMITTER:1 PRISM:1 MIRROR:3 TARGET:3 RECEIVER:1 FILTER:1 REMOTE_EM:1 PORTAL:2 | Convergence |
| 124 | Directional Cross | `era2_stage_01/level_24.gd` | 10x8 | 4 | 10 | 4 | EMITTER:2 ONE_WAY:2 GATE:1 MIRROR:2 TARGET:2 SWITCH:1 | Convergence |
| 125 | False Spectrum | `era2_stage_01/level_25.gd` | 9x9 | 4 | 16 | 4 | EMITTER:1 PRISM:1 FILTER:3 TARGET:5 MIRROR:4 PORTAL:2 | Checkpoint |
| 126 | Signal Cascade | `era2_stage_01/level_26.gd` | 9x11 | 2 | 13 | 2 | EMITTER:1 PRISM:1 TARGET:3 RECEIVER:2 REMOTE_EM:2 MIRROR:2 GATE:1 SWITCH:1 | Checkpoint |
| 127 | Fractured Circuit | `era2_stage_01/level_27.gd` | 10x10 | 4 | 14 | 4 | EMITTER:1 PRISM:1 ONE_WAY:1 TARGET:3 MIRROR:3 PORTAL:2 BLOCKER:1 FILTER:1 SPLITTER:1 | Checkpoint |
| 128 | Reciprocal Signal | `era2_stage_01/level_28.gd` | 9x10 | 4 | 14 | 4 | EMITTER:2 MIRROR:3 RECEIVER:2 REMOTE_EM:2 SWITCH:1 GATE:1 ONE_WAY:1 TARGET:2 | Checkpoint |
| 129 | Spectral Network | `era2_stage_01/level_29.gd` | 9x11 | 5 | 18 | 5 | EMITTER:1 PRISM:1 ONE_WAY:2 SWITCH:1 MIRROR:3 TARGET:4 PORTAL:2 FILTER:1 GATE:1 RECEIVER:1 REMOTE_EM:1 | Checkpoint |
| 130 | Convergence Matrix | `era2_stage_01/level_30.gd` | 9x11 | 7 | 19 | 7 | EMITTER:1 PRISM:1 ONE_WAY:2 SWITCH:2 MIRROR:5 TARGET:4 GATE:2 RECEIVER:1 REMOTE_EM:1 | Convergence |
| 131 | Double Bind | `era2_stage_01/level_31.gd` | 9x9 | 6 | 13 | 6 | EMITTER:1 PRISM:1 ONE_WAY:2 MIRROR:6 TARGET:3 | Advanced |
| 132 | Relay Exchange | `era2_stage_01/level_32.gd` | 8x9 | 4 | 13 | 4 | EMITTER:1 MIRROR:4 RECEIVER:2 REMOTE_EM:2 GATE:1 TARGET:2 SWITCH:1 | Advanced |
| 133 | Spectral Lock | `era2_stage_01/level_33.gd` | 8x9 | 3 | 12 | 3 | EMITTER:1 PRISM:1 MIRROR:3 SWITCH:1 PORTAL:2 FILTER:1 GATE:1 TARGET:2 | Advanced |
| 134 | Cross Current | `era2_stage_01/level_34.gd` | 10x8 | 5 | 12 | 5 | EMITTER:2 ONE_WAY:1 RECEIVER:1 MIRROR:4 TARGET:3 REMOTE_EM:1 | Advanced |
| 135 | Delayed Spectrum | `era2_stage_01/level_35.gd` | 9x9 | 3 | 11 | 3 | EMITTER:1 PRISM:1 TARGET:4 RECEIVER:1 MIRROR:3 REMOTE_EM:1 | Checkpoint |
| 136 | Portal Relay | `era2_stage_01/level_36.gd` | 7x10 | 5 | 13 | 5 | EMITTER:1 MIRROR:4 RECEIVER:2 REMOTE_EM:2 PORTAL:2 ONE_WAY:1 TARGET:1 | Checkpoint |
| 137 | Three-Way Refraction | `era2_stage_01/level_37.gd` | 8x10 | 4 | 15 | 4 | EMITTER:1 PRISM:1 MIRROR:4 TARGET:4 RECEIVER:1 SPLITTER:1 GATE:1 REMOTE_EM:1 SWITCH:1 | Advanced |
| 138 | Reciprocal Gates | `era2_stage_01/level_38.gd` | 9x10 | 2 | 12 | 2 | EMITTER:2 MIRROR:1 RECEIVER:1 REMOTE_EM:1 SWITCH:2 ONE_WAY:1 GATE:2 TARGET:2 | Advanced |
| 139 | Fractured Network | `era2_stage_01/level_39.gd` | 9x11 | 6 | 20 | 6 | EMITTER:1 PRISM:1 ONE_WAY:2 SWITCH:1 MIRROR:4 TARGET:5 PORTAL:2 FILTER:1 GATE:1 RECEIVER:1 REMOTE_EM:1 | Advanced |
| 140 | Refraction Engine | `era2_stage_01/level_40.gd` | 9x11 | 8 | 24 | 8 | EMITTER:1 PRISM:1 ONE_WAY:2 SWITCH:2 MIRROR:6 TARGET:4 RECEIVER:2 REMOTE_EM:2 PORTAL:2 GATE:2 | Advanced |

### 9.2b Campaign folder aggregates (derived from the level data)

| Folder | Campaign # | Levels | Opt. moves min/avg/max | Tiles min/avg/max | Grid shapes | Tile-type totals |
|---|---|---|---|---|---|---|
| `levels/campaign/stage_01/` | 1-10 | 10 | 1 / 2.6 / 4 | 3 / 5.7 / 10 | 5x6, 5x7 | BLOCKER:3 EMITTER:10 MIRROR:34 TARGET:10 |
| `levels/campaign/stage_02/` | 11-20 | 10 | 3 / 3.9 / 5 | 5 / 7.3 / 12 | 5x6, 5x7, 6x7 | BLOCKER:4 EMITTER:10 MIRROR:49 TARGET:10 |
| `levels/campaign/stage_03/` | 21-30 | 10 | 5 / 6.3 / 8 | 10 / 12.8 / 16 | 6x7, 7x8 | BLOCKER:1 EMITTER:10 FILTER:9 GATE:2 HAZARD:7 MIRROR:71 PORTAL:2 SPLITTER:7 SWITCH:2 TARGET:17 |
| `levels/campaign/stage_04/` | 31-40 | 10 | 5 / 7.5 / 11 | 12 / 15.4 / 22 | 6x7, 7x8, 8x9 | BLOCKER:5 EMITTER:12 FILTER:9 GATE:2 HAZARD:9 MIRROR:83 PORTAL:8 SPLITTER:6 SWITCH:2 TARGET:18 |
| `levels/campaign/stage_05/` | 41-50 | 10 | 5 / 7.5 / 11 | 12 / 16.1 / 23 | 6x7, 6x8, 7x8, 9x10 | BLOCKER:9 EMITTER:11 FILTER:19 GATE:1 HAZARD:5 MIRROR:80 PORTAL:6 SPLITTER:8 SWITCH:1 TARGET:21 |
| `levels/campaign/stage_06/` | 51-60 | 10 | 7 / 10.0 / 14 | 14 / 20.1 / 27 | 10x11, 6x7, 7x8, 8x10, 9x10 | BLOCKER:3 EMITTER:13 FILTER:14 GATE:7 HAZARD:10 MIRROR:108 PORTAL:16 SPLITTER:5 SWITCH:7 TARGET:18 |
| `levels/campaign/stage_07/` | 61-70 | 10 | 7 / 10.2 / 12 | 13 / 19.5 / 27 | 7x8, 8x9, 9x10 | BLOCKER:4 EMITTER:14 FILTER:13 GATE:6 HAZARD:11 MIRROR:109 PORTAL:6 SPLITTER:5 SWITCH:7 TARGET:20 |
| `levels/campaign/stage_08/` | 71-80 | 10 | 8 / 11.4 / 14 | 20 / 26.8 / 37 | 10x12, 8x9, 9x10 | BLOCKER:7 EMITTER:16 FILTER:32 GATE:19 HAZARD:10 MIRROR:124 PORTAL:14 SPLITTER:6 SWITCH:20 TARGET:20 |
| `levels/campaign/stage_09/` | 81-90 | 10 | 10 / 12.0 / 14 | 26 / 31.2 / 40 | 10x12, 9x10 | BLOCKER:14 EMITTER:29 FILTER:26 GATE:27 HAZARD:10 MIRROR:132 PORTAL:24 SPLITTER:2 SWITCH:28 TARGET:20 |
| `levels/campaign/stage_10/` | 91-100 | 10 | 11 / 13.0 / 15 | 24 / 32.1 / 42 | 10x12, 9x10 | BLOCKER:16 EMITTER:22 FILTER:35 GATE:29 HAZARD:10 MIRROR:138 PORTAL:14 SPLITTER:8 SWITCH:27 TARGET:22 |
| `levels/campaign/era2_stage_01/` | 101-140 | 40 | 1 / 3.6 / 8 | 6 / 12.2 / 24 | 10x10, 10x8, 5x10, 5x8, 6x8, 6x9, 7x10, 7x6, 7x7, 7x8, 7x9, 8x10, 8x8, 8x9, 9x10, 9x11, 9x9 | BLOCKER:2 EMITTER:46 FILTER:13 GATE:22 MIRROR:119 ONE_WAY:29 PORTAL:28 PRISM:25 RECEIVER:33 REMOTE_EM:33 SPLITTER:5 SWITCH:22 TARGET:111 |

### 9.3 Guided tutorials (`LevelManager.TUTORIAL_LEVEL_PATHS`, 34, `TutorialLevelData`)

| T# | Name | File | Grid | Tiles | Mechanics | Steps | Hint entry in hint_solutions.json |
|---|---|---|---|---|---|---|---|
| T01 | First Light | `t01.gd` | 5x5 | 3 | EMITTER:1 MIRROR:1 TARGET:1 | 7 | yes |
| T02 | Two Turns | `t02.gd` | 5x5 | 4 | EMITTER:1 MIRROR:2 TARGET:1 | 5 | yes |
| T03 | Locked In | `t03.gd` | 5x5 | 5 | EMITTER:1 MIRROR:2 BLOCKER:1 TARGET:1 | 6 | yes |
| T04 | Both Lights | `t04.gd` | 5x5 | 5 | EMITTER:1 MIRROR:2 TARGET:2 | 5 | yes |
| T05 | Split Path | `t05.gd` | 5x5 | 4 | EMITTER:1 SPLITTER:1 TARGET:2 | 5 | yes |
| T06 | True Color | `t06.gd` | 5x5 | 4 | EMITTER:1 TARGET:2 MIRROR:1 | 5 | yes |
| T07 | Recolor | `t07.gd` | 5x5 | 5 | EMITTER:1 MIRROR:2 FILTER:1 TARGET:1 | 5 | yes |
| T08 | Through the Portal | `t08.gd` | 5x5 | 5 | EMITTER:1 MIRROR:1 PORTAL:2 TARGET:1 | 5 | yes |
| T09 | Switch and Gate | `t09.gd` | 5x5 | 6 | EMITTER:1 SWITCH:1 MIRROR:1 HAZARD:1 GATE:1 TARGET:1 | 7 | yes |
| T10 | Graduation | `t10.gd` | 5x5 | 6 | EMITTER:2 MIRROR:2 TARGET:2 | 3 | yes |
| T11 | Welcome to Refractions | `t11.gd` | 5x5 | 3 | EMITTER:1 MIRROR:1 TARGET:1 | 5 | yes |
| T12 | Prism Basics | `t12.gd` | 5x5 | 5 | EMITTER:1 PRISM:1 TARGET:2 MIRROR:1 | 6 | yes |
| T13 | Prism Colors | `t13.gd` | 7x6 | 7 | EMITTER:2 PRISM:2 TARGET:2 MIRROR:1 | 6 | yes |
| T14 | Prism Routing | `t14.gd` | 7x5 | 6 | EMITTER:1 PRISM:1 MIRROR:2 TARGET:2 | 5 | yes |
| T15 | Direction Matters | `t15.gd` | 4x4 | 3 | EMITTER:1 ONE_WAY:1 TARGET:1 | 5 | yes |
| T16 | Two Sides | `t16.gd` | 8x7 | 5 | EMITTER:2 ONE_WAY:1 TARGET:2 | 5 | yes |
| T17 | Signal Receiver | `t17.gd` | 5x5 | 6 | EMITTER:1 RECEIVER:1 MIRROR:1 TARGET:2 REMOTE_EM:1 | 5 | yes |
| T18 | Remote Power | `t18.gd` | 4x7 | 5 | EMITTER:1 RECEIVER:1 REMOTE_EM:1 MIRROR:1 TARGET:1 | 5 | yes |
| T19 | Signal Chain | `t19.gd` | 8x7 | 8 | EMITTER:1 RECEIVER:1 GATE:1 TARGET:2 REMOTE_EM:1 SWITCH:1 MIRROR:1 | 5 | yes |
| T20 | Era 2 Graduation | `t20.gd` | 9x9 | 10 | EMITTER:1 PRISM:1 ONE_WAY:1 TARGET:3 RECEIVER:1 REMOTE_EM:1 FILTER:1 MIRROR:1 | 3 | yes |
| T21 | Fusion Node | `t21.gd` | 5x5 | 4 | EMITTER:2 FUSION:1 TARGET:1 | 5 | yes |
| T22 | Output Side | `t22.gd` | 6x5 | 4 | EMITTER:2 FUSION:1 TARGET:1 | 7 | yes |
| T23 | Color Recipes | `t23.gd` | 5x5 | 8 | EMITTER:4 FUSION:2 TARGET:2 | 7 | yes |
| T24 | Three Colors | `t24.gd` | 6x5 | 8 | EMITTER:3 FUSION:1 PRISM:1 TARGET:3 | 5 | yes |
| T25 | Fusion Filter | `t25.gd` | 5x5 | 6 | EMITTER:2 FILTER:2 FUSION:1 TARGET:1 | 5 | yes |
| T26 | Fusion Portal | `t26.gd` | 6x7 | 7 | EMITTER:2 MIRROR:1 PORTAL:2 FUSION:1 TARGET:1 | 7 | yes |
| T27 | Fusion Relay | `t27.gd` | 5x6 | 7 | EMITTER:2 FUSION:1 RECEIVER:1 REMOTE_EM:1 MIRROR:1 TARGET:1 | 7 | yes |
| T28 | Fusion Trial | `t28.gd` | 7x9 | 14 | EMITTER:3 FILTER:1 PORTAL:2 MIRROR:2 FUSION:1 RECEIVER:1 REMOTE_EM:1 GATE:1 TARGET:1 SWITCH:1 | 3 | yes |
| T29 | Select Path | `t29.gd` | 5x5 | 5 | EMITTER:1 SELECTOR:1 BLOCKER:2 TARGET:1 | 6 | yes |
| T30 | Choose Output | `t30.gd` | 5x5 | 5 | EMITTER:1 SELECTOR:1 TARGET:2 BLOCKER:1 | 7 | yes |
| T31 | Sel + Filter | `t31.gd` | 5x6 | 7 | EMITTER:1 SELECTOR:1 FILTER:3 TARGET:2 | 6 | yes |
| T32 | Sel + Portal | `t32.gd` | 6x6 | 6 | EMITTER:1 SELECTOR:1 TARGET:2 PORTAL:2 | 6 | yes |
| T33 | Sel + Fusion | `t33.gd` | 6x6 | 6 | EMITTER:2 SELECTOR:1 BLOCKER:1 FUSION:1 TARGET:1 | 7 | yes |
| T34 | Sel Trial | `t34.gd` | 7x8 | 15 | EMITTER:3 SELECTOR:1 BLOCKER:1 FILTER:2 MIRROR:2 PORTAL:2 FUSION:1 GATE:1 TARGET:1 SWITCH:1 | 3 | yes |

### 9.4 Per-level notes (first doc-comment / developer notes of each level file)

- **DEV 1 — First Light** (`levels/level_01.gd`, 5x5, opt 1): Test Level 1 - "First Light". Teaches basic reflection: one mirror, one rotation needed. See TEST_PLAN.md for the verified solution trace.
- **DEV 2 — Reflection** (`levels/level_02.gd`, 5x5, opt 2): Test Level 2 - "Reflection". Requires two meaningful mirror rotations in sequence. See TEST_PLAN.md for the verified solution trace.
- **DEV 3 — Obstruction** (`levels/level_03.gd`, 5x5, opt 2): Test Level 3 - "Obstruction". Introduces the blocker: leaving the first mirror unrotated sends the beam straight into a blocker, demonstrating the mechanic before the player routes around it. See TEST_PLAN.md.
- **DEV 4 — Fixed Point** (`levels/level_04.gd`, 5x5, opt 2): Test Level 4 - "Fixed Point". Introduces the fixed vs. rotatable mirror distinction: the first mirror cannot be rotated and must be planned around, while two rotatable mirrors need one rotation each. See TEST_PLAN.md for the verified solution trace.
- **DEV 5 — Three Turns** (`levels/level_05.gd`, 5x5, opt 3): Test Level 5 - "Three Turns". Milestone 1 challenge level: three meaningful rotations plus a decoy mirror and a blocker on the "obvious wrong guess" branch, requiring the player to plan the full path before rotating. See TEST_PLAN.md for the verified solution ...
- **DEV 6 — Twin Targets** (`levels/level_06.gd`, 5x5, opt 1): Test Level 6 - "Twin Targets". Introduces multiple required targets: a single beam continues past the first target (Milestone 2 behavior - see ARCHITECTURE.md) and must also reach a second target via one mirror rotation. See TEST_PLAN.md for the verified solut...
- **DEV 7 — Split Path** (`levels/level_07.gd`, 5x5, opt 1): Test Level 7 - "Split Path". Introduces the splitter: the straight branch always reaches one target regardless of orientation, while the reflected branch needs one rotation to reach the second target - see TEST_PLAN.md for the verified solution trace.
- **DEV 8 — True Color** (`levels/level_08.gd`, 5x5, opt 1): Test Level 8 - "True Color". Introduces colored emitters/targets: a GREEN beam only activates a GREEN-required target. See TEST_PLAN.md for the verified solution trace.
- **DEV 9 — Recolor** (`levels/level_09.gd`, 5x5, opt 1): Test Level 9 - "Recolor". Introduces the color filter: the default (WHITE) beam becomes RED after passing through the filter, which is what lets it activate a RED-required target. See TEST_PLAN.md for the verified solution trace.
- **DEV 10 — Through the Portal** (`levels/level_10.gd`, 5x5, opt 1): Test Level 10 - "Through the Portal". Introduces paired portals: after one mirror rotation the beam travels down into portal A and emerges from portal B still heading the same direction, reaching a target that has no direct line of sight from the emitter. See ...
- **DEV 11 — Switch and Gate** (`levels/level_11.gd`, 5x6, opt 1): Test Level 11 - "Switch and Gate". Introduces switches/gates: one mirror rotation routes the beam over a switch and into a closed gate; the gate opens automatically on the next simulation pass (see ARCHITECTURE.md "Switch/gate simulation strategy") and the sam...
- **DEV 12 — Danger Zone** (`levels/level_12.gd`, 5x5, opt 2): Test Level 12 - "Danger Zone". Introduces the hazard: leaving the first mirror unrotated sends the beam straight into a hazard (level fails to solve while hazard_hit is true, but play is not interrupted - see ARCHITECTURE.md). The player must route around it w...
- **DEV 13 — Two Sources** (`levels/level_13.gd`, 5x5, opt 2): Test Level 13 - "Two Sources". Introduces multiple emitters: two completely independent single-mirror puzzles must both be solved (one rotation each) for the level to complete. See TEST_PLAN.md for the verified solution trace.
- **DEV 14 — Convergence** (`levels/level_14.gd`, 5x5, opt 1): Test Level 14 - "Convergence". Combines splitter + colored beam + filter + multiple targets: the straight branch always reaches a neutral target, while the reflected branch needs one rotation to reach a filter that recolors it to match the second, color-requir...
- **DEV 15 — All Systems** (`levels/level_15.gd`, 6x6, opt 2): Test Level 15 - "All Systems". Milestone 2 challenge level, combining switch/gate, hazard, portal, and multiple emitters: two independent chains, each needing one mirror rotation. Chain A routes a beam over a switch that opens a gate guarding its target. Chain...
- **Camp 1 — Ignition** (`levels/campaign/stage_01/level_01.gd`, 5x6, opt 1): Campaign Level 1 — "Ignition". Teaches basic mirror rotation: one emitter, one mirror, one target. The mirror starts in the wrong orientation; a single rotation solves it. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 ...
- **Camp 2 — First Turn** (`levels/campaign/stage_01/level_02.gd`, 5x6, opt 2): Campaign Level 2 — "First Turn". Teaches chaining two reflections: both mirrors start wrong, so the player must reason about the full two-bounce path before rotating either one. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -...
- **Camp 3 — Signal Path** (`levels/campaign/stage_01/level_03.gd`, 5x6, opt 2): Campaign Level 3 — "Signal Path". Teaches multiple mirrors on one route: three mirrors in a staircase, two of them start wrong. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an order-preserving coordinate remap (se...
- **Camp 4 — Blocked** (`levels/campaign/stage_01/level_04.gd`, 5x6, opt 2): Campaign Level 4 — "Blocked". Introduces the Blocker tile: the wrong rotation at the fork mirror sends the beam straight into a blocker, teaching that a plausible-looking guess can be a dead end. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22)...
- **Camp 5 — Alignment** (`levels/campaign/stage_01/level_05.gd`, 5x6, opt 2): Campaign Level 5 — "Alignment". Introduces a fixed (non-rotatable) mirror alongside two rotatable ones: the player must route around a piece they cannot touch. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an order...
- **Camp 6 — False Signal** (`levels/campaign/stage_01/level_06.gd`, 5x6, opt 3): Campaign Level 6 — "False Signal". Teaches that a mirror junction can offer two plausible-looking continuations where only one actually leads anywhere - the wrong choice at Mirror B just runs off the grid with nothing to show for it. See CAMPAIGN_DESIGN.md. PH...
- **Camp 7 — Deception** (`levels/campaign/stage_01/level_07.gd`, 5x7, opt 3): Campaign Level 7 — "Deception". Introduces the stage's first genuine decoy piece: a rotatable mirror that the beam never actually reaches in any solution, placed near the middle of the board where a player scanning for "unused" pieces might assume it matters. ...
- **Camp 8 — Long Relay** (`levels/campaign/stage_01/level_08.gd`, 5x7, opt 4): Campaign Level 8 — "Long Relay". Requires planning a full four-bounce route before making any move - all four mirrors start wrong, so a player rotating on sight (rather than tracing the whole path first) will waste moves. See CAMPAIGN_DESIGN.md. PHASE 2A PORTR...
- **Camp 9 — Junction** (`levels/campaign/stage_01/level_09.gd`, 5x7, opt 3): Campaign Level 9 — "Junction". Combines every Stage 1 mechanic at once: a fixed mirror, three rotatable mirrors, a blocker guarding a wrong fork, and a decoy near the trap. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7...
- **Camp 10 — Breakthrough** (`levels/campaign/stage_01/level_10.gd`, 5x7, opt 4): Campaign Level 10 — "Breakthrough". Stage 1 finale: a five-mirror route (one fixed, four rotatable) winding right/down/right/down/left/ up across the whole board, with a blocker guarding one wrong fork and two decoys planted near the real turns. See CAMPAIGN_D...
- **Camp 11 — Redirect** (`levels/campaign/stage_02/level_01.gd`, 5x6, opt 3): Campaign Level 11 (Stage 2 #1) — "Redirect". Bridge from Stage 1: a three-mirror chain, longer than any single Stage 1 fork, easing the player into Stage 2's "trace the whole route" mindset without resetting to tutorial difficulty. See CAMPAIGN_DESIGN.md. PHAS...
- **Camp 12 — Dead End** (`levels/campaign/stage_02/level_02.gd`, 5x6, opt 3): Campaign Level 12 (Stage 2 #2) — "Dead End". Blocker-focused: the fork mirror's wrong orientation sends the beam straight into a blocker, teaching that the shorter-looking branch can be a trap. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): ...
- **Camp 13 — Fork Point** (`levels/campaign/stage_02/level_03.gd`, 5x6, opt 3): Campaign Level 13 (Stage 2 #3) — "Fork Point". Two genuinely plausible multi-cell continuations from one mirror - only one actually reaches the target. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x6 via an order-preserv...
- **Camp 14 — Reverse Trace** (`levels/campaign/stage_02/level_04.gd`, 5x6, opt 3): Campaign Level 14 (Stage 2 #4) — "Reverse Trace". First dedicated backward-reasoning level: a fixed mirror sits directly beside the target and only redirects correctly when approached from one specific direction, rewarding a player who reasons backward from th...
- **Camp 15 — Mirage** (`levels/campaign/stage_02/level_05.gd`, 5x7, opt 4): Campaign Level 15 (Stage 2 #5) — "Mirage". Decoy-focused: one convincing decoy mirror sits right beside the real path's final two turns, never actually touched by the solved beam. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5...
- **Camp 16 — Cascade** (`levels/campaign/stage_02/level_06.gd`, 5x7, opt 4): Campaign Level 16 (Stage 2 #6) — "Cascade". Multi-step dependency: Mirror A's correct orientation only makes sense once the full 4-bounce downstream route (through B, E, F) is understood - its wrong choice simply exits the board with no visible clue why it's w...
- **Camp 17 — Backtrack** (`levels/campaign/stage_02/level_07.gd`, 5x7, opt 4): Campaign Level 17 (Stage 2 #7) — "Backtrack". Second backward- reasoning level: a fixed mirror beside the target demands a specific approach direction, a blocker punishes the wrong fork earlier in the chain, and the route is the longest real chain yet (4 rotat...
- **Camp 18 — Echo Path** (`levels/campaign/stage_02/level_08.gd`, 5x7, opt 5): Campaign Level 18 (Stage 2 #8) — "Echo Path". A five-mirror route that visits all four edges of the board before converging near the center - dense-looking, but every piece is load-bearing (no decoys). See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-...
- **Camp 19 — Interference** (`levels/campaign/stage_02/level_09.gd`, 5x7, opt 5): Campaign Level 19 (Stage 2 #9) — "Interference". Pre-finale challenge: a five-mirror route with two decoys planted near the action. See CAMPAIGN_DESIGN.md. PHASE 2A PORTRAIT RE-LAYOUT (2026-09-22): board grew 5x5 -> 5x7 via an order-preserving coordinate remap...
- **Camp 20 — Culmination** (`levels/campaign/stage_02/level_10.gd`, 6x7, opt 5): Campaign Level 20 (Stage 2 #10) — "Culmination". Stage 2 finale: a seven-segment route (5 rotatable mirrors + 2 fixed) touring most of the board, two blockers guarding real wrong forks, one decoy near the fixed-mirror cluster, and a backward-reasoning payoff a...
- **Camp 21 — Crossfire** (`levels/campaign/stage_03/level_01.gd`, 6x7, opt 5): Campaign Level 21 — "Crossfire". DIFFICULTY REWORK PASS 2. Splitter dual-branch where the reflected branch's orientation is a real, punished decision (wrong orientation runs the beam into a hazard, not a harmless miss) while the straight branch needs its own d...
- **Camp 22 — Detour** (`levels/campaign/stage_03/level_02.gd`, 6x7, opt 6): Campaign Level 22 — "Detour". DIFFICULTY REWORK PASS 2. A mid-chain filter permanently recolors the beam before a mandatory portal hop; the portal's exit direction still has to be threaded through three more mirrors to reach a color-matched target. A rotatable...
- **Camp 23 — Misdirect** (`levels/campaign/stage_03/level_03.gd`, 6x7, opt 5): Campaign Level 23 — "Misdirect". DIFFICULTY REWORK PASS 2. Backward reasoning through two chained fixed mirrors, plus a false route that genuinely lights up a non-required decoy target of the wrong color - a false confirmation that looks like a solve but isn't...
- **Camp 24 — Standoff** (`levels/campaign/stage_03/level_04.gd`, 6x7, opt 6): Campaign Level 24 — "Standoff". DIFFICULTY REWORK PASS 2. Splitter/switch/gate dependency: the reflected branch's ONLY job is to trip a switch that opens a gate blocking the straight branch's own route to the target. Wrong splitter orientation both misses the ...
- **Camp 25 — Bottleneck** (`levels/campaign/stage_03/level_05.gd`, 7x8, opt 6): Campaign Level 25 — "Bottleneck". DIFFICULTY REWORK PASS 2, block finale. A splitter feeds two symmetric, winding chains (one to each of two required targets); the reflected branch's orientation is punished by a hazard if wrong, not just a miss. First level in...
- **Camp 26 — Labyrinth** (`levels/campaign/stage_03/level_06.gd`, 7x8, opt 7): Campaign Level 26 — "Labyrinth". DIFFICULTY REWORK PASS 2. Genuine cross-branch dependency: a single FIXED shared mirror is hit by both the splitter's straight branch (arriving RIGHT) and its reflected branch (arriving DOWN, after a long separate loop) - each ...
- **Camp 27 — Impasse** (`levels/campaign/stage_03/level_07.gd`, 7x8, opt 8): Campaign Level 27 — "Impasse". DIFFICULTY REWORK PASS 2. A single beam threads three filters in sequence (RED -> GREEN -> BLUE) - "last filter touched wins" means only the final one determines the required target color, and an early wrong turn genuinely lights...
- **Camp 28 — Gambit** (`levels/campaign/stage_03/level_08.gd`, 6x7, opt 6): Campaign Level 28 — "Gambit". DIFFICULTY REWORK PASS 2. Splitter with two independently-colored branches (RED / BLUE), each needing its own filter and its own multi-mirror chain, plus an emergent cascade: a wrong second-branch mirror doesn't just miss its targ...
- **Camp 29 — Stalemate** (`levels/campaign/stage_03/level_09.gd`, 6x7, opt 7): Campaign Level 29 — "Stalemate". DIFFICULTY REWORK PASS 2. Splitter/switch/gate dependency: the reflected branch's ONLY job is to reach a switch through a backward-reasoning fixed mirror; the straight branch is physically gated until that happens, then relays ...
- **Camp 30 — Deadlock** (`levels/campaign/stage_03/level_10.gd`, 7x8, opt 7): Campaign Level 30 — "Deadlock". DIFFICULTY REWORK PASS 2, block finale. Combines cross-branch dependency (one fixed shared mirror hit by both splitter branches from perpendicular directions), a filter on each branch, and a blocker-guarded false route - the blo...
- **Camp 31 — Ambush** (`levels/campaign/stage_04/level_01.gd`, 6x7, opt 6): Campaign Level 31 — "Ambush". DIFFICULTY REWORK PASS 2. A single beam threads a portal partway through a long six-mirror chain; a wrong very first turn runs straight into a hazard instead of a harmless miss. See CAMPAIGN_DESIGN.md section 11g (Pass 2).
- **Camp 32 — Gauntlet** (`levels/campaign/stage_04/level_02.gd`, 6x7, opt 7): Campaign Level 32 — "Gauntlet". DIFFICULTY REWORK PASS 2. Two independent emitters share one gate: emitter 1's entire job is to reach a switch through its own 2-mirror chain; emitter 2's beam is physically blocked until that happens, then has to be routed thro...
- **Camp 33 — Feint** (`levels/campaign/stage_04/level_03.gd`, 6x7, opt 6): Campaign Level 33 — "Feint". DIFFICULTY REWORK PASS 2. Splitter with two color-independent branches, each behind its own filter; the straight branch's wrong fork runs into a blocker instead of a harmless miss. See CAMPAIGN_DESIGN.md section 11g (Pass 2).
- **Camp 34 — Snare** (`levels/campaign/stage_04/level_04.gd`, 7x8, opt 5): Campaign Level 34 — "Snare". DIFFICULTY REWORK PASS 2. Portal into a switch that opens its own downstream gate, resolved by simulate_until_stable's multi-pass loop; the returning beam is turned into the target by a DEDICATED mirror never touched on the outboun...
- **Camp 35 — Ricochet** (`levels/campaign/stage_04/level_05.gd`, 7x8, opt 7): Campaign Level 35 — "Ricochet". DIFFICULTY REWORK PASS 2, block finale. Cross-branch dependency (one fixed shared mirror hit from perpendicular directions) combined with a filter on the reflected branch and a blocker-guarded false fork on the straight branch -...
- **Camp 36 — Vertex** (`levels/campaign/stage_04/level_06.gd`, 7x8, opt 9): Campaign Level 36 — "Vertex". DIFFICULTY REWORK PASS 2. Two independent emitters (no splitter) converge on ONE fixed shared mirror from perpendicular directions - the player has to plan both chains before touching anything, since the shared mirror's single ori...
- **Camp 37 — Nexus** (`levels/campaign/stage_04/level_07.gd`, 8x9, opt 9): Campaign Level 37 — "Nexus". DIFFICULTY REWORK PASS 2. Splitter with two structurally different routes to the same shared fixed mirror - the straight branch's route is a portal shortcut, the reflected branch's is a plain relay - reaching one shared decision po...
- **Camp 38 — Quandary** (`levels/campaign/stage_04/level_08.gd`, 6x7, opt 6): Campaign Level 38 — "Quandary". DIFFICULTY REWORK PASS 2. Splitter where the straight branch chains two filters (RED then BLUE, last one wins) and the reflected branch's wrong orientation runs into a hazard instead of a harmless miss. See CAMPAIGN_DESIGN.md se...
- **Camp 39 — Riddle** (`levels/campaign/stage_04/level_09.gd`, 6x7, opt 9): Campaign Level 39 — "Riddle". DIFFICULTY REWORK PASS 2. Splitter feeding two fully independent backward-reasoning puzzles - each branch ends at its own fixed mirror whose orientation determines the required upstream approach direction. See CAMPAIGN_DESIGN.md s...
- **Camp 40 — Crucible** (`levels/campaign/stage_04/level_10.gd`, 8x9, opt 11): Campaign Level 40 — "Crucible". DIFFICULTY REWORK PASS 2, block finale. The hardest puzzle in the block: a portal-routed straight branch and a 2-filter-order reflected branch converge on one fixed shared mirror, with a blocker guarding the straight branch's fa...
- **Camp 41 — Foresight** (`levels/campaign/stage_05/level_01.gd`, 6x8, opt 8): Campaign Level 41 — "Foresight". DIFFICULTY REWORK PASS 2. Splitter feeding two independent color-coded backward-reasoning chains, each ending at its own fixed mirror. See CAMPAIGN_DESIGN.md section 11h (Pass 2).
- **Camp 42 — Hindsight** (`levels/campaign/stage_05/level_02.gd`, 7x8, opt 9): Campaign Level 42 — "Hindsight". DIFFICULTY REWORK PASS 2. One deep single-beam chain, no splitter - portal, filter, and a fixed mirror in the middle of the chain, deliberately a different shape from its splitter-heavy neighbors. See CAMPAIGN_DESIGN.md section...
- **Camp 43 — Tangent** (`levels/campaign/stage_05/level_03.gd`, 7x8, opt 10): Campaign Level 43 — "Tangent". DIFFICULTY REWORK PASS 2. Splitter where the straight branch's ONLY route to its target crosses a mandatory portal (not a shortcut - there is no other way across), while the reflected branch is a long independent relay. See CAMPA...
- **Camp 44 — Overwatch** (`levels/campaign/stage_05/level_04.gd`, 6x7, opt 7): Campaign Level 44 — "Overwatch". DIFFICULTY REWORK PASS 2. Two independent emitters share one gate; emitter 2's beam only earns its final rotation payoff (three more mirrors) after emitter 1 opens the way through. See CAMPAIGN_DESIGN.md section 11h (Pass 2).
- **Camp 45 — Threshold** (`levels/campaign/stage_05/level_05.gd`, 9x10, opt 11): Campaign Level 45 — "Threshold". DIFFICULTY REWORK PASS 2, pre-46-50 bridge finale. Combines portal routing on the straight branch with a 2-filter order chain on the reflected branch, both converging on one fixed shared mirror - the block's hardest puzzle, tra...
- **Camp 46 — Frequency** (`levels/campaign/stage_05/level_06.gd`, 6x7, opt 6): Campaign Level 46 (Stage 5 #6) — CROSS-BRANCH COLOR DEPENDENCY. First major Stage 5 challenge. The mirror at (3,2) is shared by BOTH the splitter's straight branch (arriving from the west, about to enter the BLUE filter) and its reflected branch (arriving from...
- **Camp 47 — Transmute** (`levels/campaign/stage_05/level_07.gd`, 6x7, opt 5): Campaign Level 47 (Stage 5 #7) — BACKWARD FILTER REASONING. Designed from both targets backward: each target's required color determines which filter must be the LAST one touched, which determines what direction the beam must arrive at the shared FIXED mirror ...
- **Camp 48 — Waveform** (`levels/campaign/stage_05/level_08.gd`, 6x7, opt 6): Campaign Level 48 (Stage 5 #8) — GLOBAL COLOR NETWORK. The very first mirror (2,3) gates access to the entire rest of the board - the splitter, both filters, and both required targets - even though the failure (a wrong-color decoy touch) is only apparent sever...
- **Camp 49 — Vortex** (`levels/campaign/stage_05/level_09.gd`, 6x7, opt 6): Campaign Level 49 (Stage 5 #9) — EXPERT PRE-FINALE. Two distinct false routes, each demonstrating a different failure mode: one is geometrically perfect but produces the wrong final color (passes directly over BOTH required targets, still RED, activating neith...
- **Camp 50 — Paradox** (`levels/campaign/stage_05/level_10.gd`, 7x8, opt 7): Campaign Level 50 (Stage 5 #10) — "Paradox". STAGE 5 / FILTERS FINALE. The hardest level in BeamShift so far. An early mirror gates the entire board; two distinct false routes (one becomes the "right" color via an unplanned filter crossing but never reaches a ...
- **Camp 51 — Interlock** (`levels/campaign/stage_06/level_01.gd`, 7x8, opt 10): Campaign Level 51 — "Interlock". Post-reboot Levels 51-60 (internal folder stage_06), continuing directly from the Levels 46-50 difficulty region - no mechanic-teaching reset. See CAMPAIGN_DESIGN.md section 11i. A splitter feeds two switch/gate pairs that gate...
- **Camp 52 — Currents** (`levels/campaign/stage_06/level_02.gd`, 6x7, opt 8): Campaign Level 52 — "Currents". Post-reboot Levels 51-60. A single beam is recolored TWICE across a portal jump - the first filter's color is a red herring; only the color set AFTER the portal (by the second filter) determines the target requirement. See CAMPA...
- **Camp 53 — Shared Line** (`levels/campaign/stage_06/level_03.gd`, 6x7, opt 7): Campaign Level 53 — "Shared Line". Post-reboot Levels 51-60. Two independent emitters share one filter corridor: emitter 1 must trip a switch before emitter 2's gate opens, and BOTH beams pass through the same filter (from different directions) to reach their ...
- **Camp 54 — Dual Transit** (`levels/campaign/stage_06/level_04.gd`, 9x10, opt 11): Campaign Level 54 — "Dual Transit". Post-reboot Levels 51-60. Two structurally unrelated portal routes (different pairs, different filters) converge on one fixed shared mirror from perpendicular directions - the player must independently solve each portal chai...
- **Camp 55 — Sequence Lock** (`levels/campaign/stage_06/level_05.gd`, 7x8, opt 11): Campaign Level 55 — "Sequence Lock". Post-reboot Levels 51-60, mid-block checkpoint. A splitter's straight branch chains two filters (only the last determines the target color) AND trips a switch mid-chain that gates the reflected branch entirely - color reaso...
- **Camp 56 — Shared Transit** (`levels/campaign/stage_06/level_06.gd`, 9x10, opt 8): Campaign Level 56 — "Shared Transit". Post-reboot Levels 51-60. Two independent emitters each thread their own separate portal, but emitter 2's gate only opens once emitter 1's beam trips a switch AFTER its own portal exit - a genuine multi-emitter dependency ...
- **Camp 57 — Long Division** (`levels/campaign/stage_06/level_07.gd`, 10x11, opt 9): Campaign Level 57 — "Long Division". Post-reboot Levels 51-60. A single beam threads a 9-mirror chain through two filters and two fixed mirrors - the target's color can only be reasoned out by working backward through the second fixed mirror's orientation to s...
- **Camp 58 — Delayed Fault** (`levels/campaign/stage_06/level_08.gd`, 7x8, opt 11): Campaign Level 58 — "Delayed Fault". Post-reboot Levels 51-60. Cross-branch dependency (one fixed shared mirror hit from perpendicular directions) where the straight branch's mistake isn't punished at the very next tile - the beam travels two full cells past t...
- **Camp 59 — Near Convergence** (`levels/campaign/stage_06/level_09.gd`, 8x10, opt 11): Campaign Level 59 — "Near Convergence". Post-reboot Levels 51-60, near-finale. Two independent emitters, each threading its own portal, one gated behind a switch tripped by the other's downstream path - whole-board planning across two separate mechanic chains....
- **Camp 60 — Threshold of Reason** (`levels/campaign/stage_06/level_10.gd`, 9x10, opt 14): Campaign Level 60 — "Threshold of Reason". MAJOR MILESTONE. Post- reboot Levels 51-60 finale. Combines a portal-routed straight branch (switch, filter, 7-mirror relay) with a 2-filter-order reflected branch gated behind that same switch (7-mirror relay) - a ge...
- **Camp 61 — Peripheral** (`levels/campaign/stage_07/level_01.gd`, 7x8, opt 10): Campaign Level 61 — "Peripheral". Post-60 Levels 61-70 (internal folder stage_07), continuing directly from Level 60's difficulty - no mechanic-teaching reset. See CAMPAIGN_DESIGN.md section 11j. The straight branch (visually closest to the emitter) is short a...
- **Camp 62 — Longcut** (`levels/campaign/stage_07/level_02.gd`, 8x9, opt 10): Campaign Level 62 — "Longcut". Post-60 Levels 61-70. The reflected branch's real solution deliberately loops far out of the way (up and around through a 2-mirror detour) before reaching the mirror that actually decides the route - one orientation there is a de...
- **Camp 63 — Invalidation** (`levels/campaign/stage_07/level_03.gd`, 8x9, opt 10): Campaign Level 63 — "Invalidation". Post-60 Levels 61-70. The straight branch's wrong turn reaches a plausible-looking decoy target of the wrong color; the real route needs a genuinely closed gate that only the reflected branch's switch opens. See CAMPAIGN_DES...
- **Camp 64 — Twin Anchor** (`levels/campaign/stage_07/level_04.gd`, 7x8, opt 10): Campaign Level 64 — "Twin Anchor". Post-60 Levels 61-70. Two independent emitters converge on ONE fixed shared mirror from perpendicular directions - the player must reason backward for BOTH emitters at once, since neither approach direction can be adjusted af...
- **Camp 65 — Convergence Point** (`levels/campaign/stage_07/level_05.gd`, 9x10, opt 12): Campaign Level 65 — "Convergence Point". Post-60 Levels 61-70, MASTER-ENTRY CHECKPOINT. The straight branch's beam continues past its own required target and trips a switch that gates the entire reflected branch - solving target A is not the end of that branch...
- **Camp 66 — Portal Trap** (`levels/campaign/stage_07/level_06.gd`, 7x8, opt 7): Campaign Level 66 — "Portal Trap". Post-60 Levels 61-70. One deep linear chain (no splitter) - the mirror right after the portal exit offers two plausible continuations, and the geometrically "closer-looking" one runs straight into a hazard. See CAMPAIGN_DESIG...
- **Camp 67 — Chain Reaction** (`levels/campaign/stage_07/level_07.gd`, 9x10, opt 11): Campaign Level 67 — "Chain Reaction". Post-60 Levels 61-70, MASTER TIER. Both splitter branches run their own 2-filter-order chain, converging on one fixed cross-branch shared mirror - four filters total, each branch's final color depending on which one it tou...
- **Camp 68 — Twin Corridor** (`levels/campaign/stage_07/level_08.gd`, 8x9, opt 9): Campaign Level 68 — "Twin Corridor". Post-60 Levels 61-70, MASTER TIER. Two emitters cross the SAME physical gate cell from perpendicular directions (one horizontal, one vertical) - EITHER emitter's own switch opens it for BOTH. See CAMPAIGN_DESIGN.md section ...
- **Camp 69 — Color Conflict** (`levels/campaign/stage_07/level_09.gd`, 8x9, opt 12): Campaign Level 69 — "Color Conflict". Post-60 Levels 61-70, MASTER+ TIER. Two emitters, each running its own independent 2-filter-order chain to its own colored target - emitter 2 physically gated behind emitter 1's switch, so neither chain's color puzzle even...
- **Camp 70 — Grand Convergence** (`levels/campaign/stage_07/level_10.gd`, 9x10, opt 11): Campaign Level 70 — "Grand Convergence". MAJOR CAMPAIGN MILESTONE. Post-60 Levels 61-70 finale. Two emitters in a genuine TWO-STAGE relay dependency: emitter 1's switch opens the gate on emitter 2's EARLY path, and emitter 2's switch (reached only after that) ...
- **Camp 71 — Deliberate Detour** (`levels/campaign/stage_08/level_01.gd`, 9x10, opt 11): Campaign Level 71 — "Deliberate Detour". Post-70 Levels 71-80 (internal folder stage_08), MASTER ENTRY, continuing directly from Level 70's difficulty - no mechanic-teaching reset. See CAMPAIGN_DESIGN.md section 11k. The straight branch's mandatory portal deto...
- **Camp 72 — Locked Corridor** (`levels/campaign/stage_08/level_02.gd`, 8x9, opt 9): Campaign Level 72 — "Locked Corridor". Post-70 Levels 71-80, MASTER TIER. Two emitters cross the SAME physical gate cell from perpendicular directions (one horizontal, one vertical) - EITHER emitter's own switch opens it for both - while each independently car...
- **Camp 73 — Locked Splitter** (`levels/campaign/stage_08/level_03.gd`, 9x10, opt 11): Campaign Level 73 — "Locked Splitter". Post-70 Levels 71-80, MASTER TIER. A single splitter's two branches gate EACH OTHER (mutual switch/gate dependency, like Level 51 but deepened with a 2-filter- order chain on each branch). See CAMPAIGN_DESIGN.md section 1...
- **Camp 74 — Twin Portals** (`levels/campaign/stage_08/level_04.gd`, 9x10, opt 8): Campaign Level 74 — "Twin Portals". Post-70 Levels 71-80, MASTER+ TIER. Emitter 1's beam continues past its own target (delayed consequence) to trip a switch that gates emitter 2's entire route. See CAMPAIGN_DESIGN.md section 11k.
- **Camp 75 — Convergence Reaction** (`levels/campaign/stage_08/level_05.gd`, 9x10, opt 13): Campaign Level 75 — "Convergence Reaction". Post-70 Levels 71-80, MAJOR MID-BLOCK CHECKPOINT. Both splitter branches run independent 2-filter-order chains converging on one shared fixed mirror (like Level 67) - but this time the straight branch's post-target c...
- **Camp 76 — Reverse Relay** (`levels/campaign/stage_08/level_06.gd`, 9x10, opt 11): Campaign Level 76 — "Reverse Relay". Post-70 Levels 71-80, MASTER+ TIER. The same two-stage relay dependency proven in Level 70 (emitter 1's switch opens emitter 2's early gate; only then can emitter 2's switch open emitter 1's later gate), but this time the p...
- **Camp 77 — Distant Splitter** (`levels/campaign/stage_08/level_07.gd`, 10x12, opt 12): Campaign Level 77 — "Distant Splitter". Post-70 Levels 71-80, MASTER+ TIER. A single splitter's two branches gate EACH OTHER (same mutual switch/gate dependency proven in Level 73), but the straight branch's final leg now jumps through a portal to a completely...
- **Camp 78 — Distant Corridor** (`levels/campaign/stage_08/level_08.gd`, 9x10, opt 12): Campaign Level 78 — "Distant Corridor". Post-70 Levels 71-80, EXTREME ENTRY TIER. The same shared-physical-gate crossing proven in Level 72 (two emitters cross gate (4,5) from perpendicular directions, either switch opens it for both), but emitter 1's delivery...
- **Camp 79 — Silent Third** (`levels/campaign/stage_08/level_09.gd`, 10x12, opt 13): Campaign Level 79 — "Silent Third". Post-70 Levels 71-80, EXTREME TIER. The same mutual splitter-gate dependency and portal jump proven in Level 77, but the straight branch's final delivery now also depends on a completely separate THIRD emitter whose own shor...
- **Camp 80 — Full Convergence** (`levels/campaign/stage_08/level_10.gd`, 10x12, opt 14): Campaign Level 80 — "Full Convergence". MAJOR CAMPAIGN MILESTONE. Post-70 Levels 71-80, the hardest puzzle built so far - not by grid size or move count, but by convergence depth: ONE target (A) is gated by THREE independent sources (the splitter's own mutual ...
- **Camp 81 — Third Signal** (`levels/campaign/stage_09/level_01.gd`, 9x10, opt 12): Campaign Level 81 — "Third Signal". EXTREME ENTRY TIER (Levels 81-90). Built by extending Level 74's already-validated two-emitter/target- continuation/portal geometry: emitter 1's tail is rerouted through two more forced bends before its target, and emitter 2...
- **Camp 82 — Crossed Corridors** (`levels/campaign/stage_09/level_02.gd`, 10x12, opt 11): Campaign Level 82 — "Crossed Corridors". EXTREME TIER (Levels 81-90). Two emitters run independent 3-filter-order color chains through fully disjoint lanes, converging at a mutual-looking gate dependency PLUS a third, completely separate emitter whose own shor...
- **Camp 83 — Silent Detour** (`levels/campaign/stage_09/level_03.gd`, 10x12, opt 11): Campaign Level 83 — "Silent Detour". EXTREME TIER (Levels 81-90). Built by extending Level 71's already-validated splitter/portal/ shared-mirror geometry: the portal now exits into a longer corridor gated by a completely separate third emitter before it can ev...
- **Camp 84 — Distant Relay** (`levels/campaign/stage_09/level_04.gd`, 9x10, opt 12): Campaign Level 84 — "Distant Relay". EXTREME+ TIER (Levels 81-90). Built by extending Level 76's already-validated two-stage relay geometry: emitter 1's final approach now jumps through a second portal into a totally separate corner of the board before reachin...
- **Camp 85 — Convergence Threshold** (`levels/campaign/stage_09/level_05.gd`, 9x10, opt 14): Campaign Level 85 — "Convergence Threshold". MAJOR CHECKPOINT (Levels 81-90). Built by extending Level 75's already-validated splitter/shared-mirror/target-continuation geometry: the reflected branch's own early path now also passes through a NEW gate opened o...
- **Camp 86 — Reciprocal Corridor** (`levels/campaign/stage_09/level_06.gd`, 10x12, opt 12): Campaign Level 86 — "Reciprocal Corridor". EXTREME+ TIER (Levels 81-90). Built by extending Level 78's already-validated shared-gate/portal geometry: emitter 1's final delivery now jumps through a SECOND portal that ends at a gate opened only by emitter 2's ow...
- **Camp 87 — Triple Relay** (`levels/campaign/stage_09/level_07.gd`, 9x10, opt 10): Campaign Level 87 — "Triple Relay". EXTREME+ TIER (Levels 81-90). The FIRST genuine three-stage relay in the campaign: emitter 1's switch (unconditionally reachable, before any gate on its own path) opens emitter 2's early gate; only then can emitter 2's own s...
- **Camp 88 — Distant Triple Relay** (`levels/campaign/stage_09/level_08.gd`, 10x12, opt 12): Campaign Level 88 — "Distant Triple Relay". NEAR-MASTER-FINAL TIER (Levels 81-90). Built by extending Level 87's already-validated three-stage relay geometry: both emitter 1's and emitter 2's final deliveries now jump through their own separate portals into di...
- **Camp 89 — Fourfold Relay** (`levels/campaign/stage_09/level_09.gd`, 10x12, opt 13): Campaign Level 89 — "Fourfold Relay". EXTREME MILESTONE (Levels 81-90). Built by extending Level 88's already-validated double-portal three-stage relay: emitter 2's early path now ALSO passes through a gate opened only by a completely separate FOURTH emitter, ...
- **Camp 90 — Full Circuit** (`levels/campaign/stage_09/level_10.gd`, 10x12, opt 13): Campaign Level 90 — "Full Circuit". MAJOR CAMPAIGN MILESTONE (hardest puzzle built so far). Built by extending Level 89's already- validated three-stage relay + double-portal + fourfold convergence: emitter 1's own very first step now ALSO passes through a gat...
- **Camp 91 — Inferred Convergence** (`levels/campaign/stage_10/level_01.gd`, 9x10, opt 13): Campaign Level 91 — "Inferred Convergence". FINAL CAMPAIGN BLOCK (Levels 91-100), MASTER+ TIER. Built by recoloring Level 75's already- validated splitter/shared-fixed-mirror/target-continuation geometry: the fixed mirror at the convergence point cannot be rot...
- **Camp 92 — Delayed Verdict** (`levels/campaign/stage_10/level_02.gd`, 10x12, opt 13): Campaign Level 92 — "Delayed Verdict". FINAL CAMPAIGN BLOCK (Levels 91-100), MASTER+ TIER. Built by extending Level 77's already- validated mutual-gate/portal geometry: the straight branch's target continuation (targets do not stop beams) now trips a switch th...
- **Camp 93 — Pre-Split Signal** (`levels/campaign/stage_10/level_03.gd`, 10x12, opt 11): Campaign Level 93 — "Pre-Split Signal". FINAL CAMPAIGN BLOCK (Levels 91-100), EXTREME TIER. Built by extending Level 73's already- validated mutual-gate splitter geometry: a filter placed BEFORE the splitter recolors the beam for BOTH branches at once, but onl...
- **Camp 94 — Traced Colors** (`levels/campaign/stage_10/level_04.gd`, 10x12, opt 11): Campaign Level 94 — "Traced Colors". FINAL CAMPAIGN BLOCK (Levels 91-100), EXTREME TIER. Built by extending Level 83's already- validated splitter/portal/third-emitter geometry: a filter is added to EACH branch at a cell already confirmed to be pure single-bea...
- **Camp 95 — Final Threshold** (`levels/campaign/stage_10/level_05.gd`, 9x10, opt 15): Campaign Level 95 — "Final Threshold". FINAL-EXAM CHECKPOINT (Levels 91-100). Built by extending Level 85's already-validated splitter/shared-mirror/target-continuation/third-emitter geometry: the straight branch's delivery now jumps through a portal into a di...
- **Camp 96 — Chain of Custody** (`levels/campaign/stage_10/level_06.gd`, 9x10, opt 12): Campaign Level 96 — "Chain of Custody". FINAL CAMPAIGN BLOCK (Levels 91-100), EXTREME+ TIER. Built by extending Level 87's already- validated three-stage relay geometry: emitter 2's switch is replaced by a target-continuation trigger (its beam reaches ITS OWN ...
- **Camp 97 — Triple Verdict** (`levels/campaign/stage_10/level_07.gd`, 10x12, opt 14): Campaign Level 97 — "Triple Verdict". FINAL CAMPAIGN BLOCK (Levels 91-100), FINAL-EXAM TIER (global dependency). Built by extending Level 92's already-validated mutual-gate/portal/delayed- consequence geometry: a completely separate THIRD emitter's own target ...
- **Camp 98 — Triple Inference** (`levels/campaign/stage_10/level_08.gd`, 9x10, opt 14): Campaign Level 98 — "Triple Inference". FINAL CAMPAIGN BLOCK (Levels 91-100), FINAL-EXAM+ TIER (backward reasoning + color/order logic). Built by extending Level 91's already-validated splitter/ fixed-mirror/backward-reasoning geometry: the reflected branch's ...
- **Camp 99 — Penultimate Verdict** (`levels/campaign/stage_10/level_09.gd`, 10x12, opt 14): Campaign Level 99 — "Penultimate Verdict". FINAL CAMPAIGN BLOCK (Levels 91-100), PENULTIMATE CHALLENGE TIER. Built by extending Level 97's already-validated mutual-gate/portal/global-late-gate geometry: the reflected branch's very first step now ALSO passes th...
- **Camp 100 — Culmination** (`levels/campaign/stage_10/level_10.gd`, 10x12, opt 13): Campaign Level 100 — "Culmination". THE DEFINITIVE FINAL CAMPAIGN PUZZLE. Built by extending Level 90's already-validated three-stage relay + double-portal + symmetric-convergence geometry - the campaign's own prior milestone - with one genuine backward-reason...
- **Camp 101 — First Refraction** (`levels/campaign/era2_stage_01/level_01.gd`, 7x7, opt 2): Campaign Level 101 — "First Refraction". THE FIRST ERA 2 CAMPAIGN LEVEL. Player's first non-tutorial Prism puzzle: one WHITE beam splits into all three RGB channels, spread top/middle/bottom of the board. RED arrives for free (straight channel); GREEN and BLUE...
- **Camp 102 — Spectrum Route** (`levels/campaign/era2_stage_01/level_02.gd`, 7x8, opt 2): Campaign Level 102 — "Spectrum Route". Prism + Filter + Mirror reasoning: a route that visually looks correct (GREEN channel ending at a GREEN-labeled target) is actually a trap because a FILTER silently recolors the beam to RED before it arrives - the target ...
- **Camp 103 — Fractured Path** (`levels/campaign/era2_stage_01/level_03.gd`, 8x8, opt 2): Campaign Level 103 — "Fractured Path". Prism + Splitter + Portal: three spatially separated branches. The GREEN channel must cross a portal to reach its target on the far side of the board; the BLUE channel passes through a splitter whose reflected branch is a...
- **Camp 104 — One Way** (`levels/campaign/era2_stage_01/level_04.gd`, 6x9, opt 2): Campaign Level 104 — "One Way". First campaign use of the One-Way Reflector as the primary mechanic: a single tile that must reflect one approaching beam while letting a second, perpendicular beam pass straight through it - the same orientation must satisfy bo...
- **Camp 105 — False Reflection** (`levels/campaign/era2_stage_01/level_05.gd`, 7x7, opt 2): Campaign Level 105 — "False Reflection". Prism + One-Way Reflector: each of the three RGB channels meets its own One-Way Reflector at the top/bottom edge of the board. Treating either reflector as an ordinary mirror (assuming it always bends) is the false rout...
- **Camp 106 — Remote Signal** (`levels/campaign/era2_stage_01/level_06.gd`, 5x8, opt 2): Campaign Level 106 — "Remote Signal". First campaign use of Beam Receiver / Remote Emitter as the primary mechanic: the main beam must be routed down to a receiver well away from the emitter, which wakes a second, independent beam elsewhere on the board that s...
- **Camp 107 — Signal Through** (`levels/campaign/era2_stage_01/level_07.gd`, 5x10, opt 1): Campaign Level 107 — "Signal Through". The main beam passes through a Filter, then a Portal, before ever reaching the Beam Receiver - by the time it does, it has crossed to a completely different part of the board. The Remote Emitter's own beam then needs one ...
- **Camp 108 — Refracted Signal** (`levels/campaign/era2_stage_01/level_08.gd`, 7x9, opt 2): Campaign Level 108 — "Refracted Signal". First strong multi-system Era 2 puzzle: one Prism branch activates a Receiver directly (no routing needed), a second Prism branch has its own independent target, and the Receiver's Remote Emitter opens a third, complete...
- **Camp 109 — Directional Chain** (`levels/campaign/era2_stage_01/level_09.gd`, 7x6, opt 1): Campaign Level 109 — "Directional Chain". A full dependency chain not obvious from the initial board state: Emitter -> One-Way Reflector -> Receiver -> Remote Emitter -> Switch -> Gate -> final target. Only one tile is rotatable, but nothing downstream even ex...
- **Camp 110 — Refraction Nexus** (`levels/campaign/era2_stage_01/level_10.gd`, 8x10, opt 3): Campaign Level 110 — "Refraction Nexus". THE FIRST ERA 2 CAMPAIGN MILESTONE. All three Era 2 mechanic families (Prism, One-Way Reflector, Beam Receiver / Remote Emitter) plus selected Era 1 mechanics (Mirror, Portal, Filter, Switch/Gate) in one coherent system...
- **Camp 111 — Split Decision** (`levels/campaign/era2_stage_01/level_11.gd`, 7x8, opt 3): Campaign Level 111 — "Split Decision". Prism + Splitter: the GREEN channel hits a splitter, creating a second layer of branching. One rotatable mirror's plausible-but-wrong orientation sends its beam through a real target cell with the WRONG required color (a ...
- **Camp 112 — Cross Signal** (`levels/campaign/era2_stage_01/level_12.gd`, 6x8, opt 3): Campaign Level 112 — "Cross Signal". A single One-Way Reflector is genuinely reused by two different beams approaching from two different directions - Emitter A's beam (entering RIGHT, always reflective) and Remote Emitter B's beam (entering DOWN, whose reflec...
- **Camp 113 — Spectral Gate** (`levels/campaign/era2_stage_01/level_13.gd`, 8x8, opt 3): Campaign Level 113 — "Spectral Gate". Prism + Filter + Switch/Gate: the RED channel must itself be routed (via a mirror) into a switch before the GREEN channel's gate will ever open, and the GREEN channel passes a true-positive decoy target (still GREEN at tha...
- **Camp 114 — Remote Loop** (`levels/campaign/era2_stage_01/level_14.gd`, 7x10, opt 3): Campaign Level 114 — "Remote Loop". The first proper two-stage Receiver/Remote Emitter relay in the main campaign (Receiver A -> Remote Emitter A -> Portal -> Receiver B -> Remote Emitter B -> target), a pure linear chain with no circular dependency.
- **Camp 115 — Directional Prism** (`levels/campaign/era2_stage_01/level_15.gd`, 7x8, opt 5): Campaign Level 115 — "Directional Prism". THE MID-BLOCK CHECKPOINT. All three Prism channels each meet their own One-Way Reflector. Treating any of them as an ordinary mirror fails on at least one channel - each requires real reflect-vs-pass-through reasoning ...
- **Camp 116 — False Activation** (`levels/campaign/era2_stage_01/level_16.gd`, 7x8, opt 2): Campaign Level 116 — "False Activation". The Receiver itself always activates correctly once its own mirror is set - the trap is realizing the Remote Emitter's own beam still has an independent switch-then-gate sequence to solve on its own path; powering the R...
- **Camp 117 — Split Spectrum** (`levels/campaign/era2_stage_01/level_17.gd`, 8x9, opt 3): Campaign Level 117 — "Split Spectrum". GREEN routes through a Portal before a Filter; BLUE routes through a Splitter, and BOTH resulting branches are meaningful (not a decorative decoy) - whole-board reasoning across a deliberately asymmetric layout.
- **Camp 118 — Remote Crossing** (`levels/campaign/era2_stage_01/level_18.gd`, 9x10, opt 4): Campaign Level 118 — "Remote Crossing". Two independent sources each power their own Receiver, but their two Remote Emitters' beams physically cross through ONE shared gate cell from perpendicular directions - genuinely interdependent, not two separate mini-pu...
- **Camp 119 — Refraction Relay** (`levels/campaign/era2_stage_01/level_19.gd`, 9x9, opt 4): Campaign Level 119 — "Refraction Relay". One Prism branch (GREEN) activates a Receiver directly; a second branch (BLUE) is routed to its own independent target AND trips a switch along the way; the Remote Emitter's own beam, arriving through a Portal, depends ...
- **Camp 120 — Era 2 Circuit** (`levels/campaign/era2_stage_01/level_20.gd`, 9x11, opt 7): Campaign Level 120 — "Era 2 Circuit". THE SECOND MAJOR ERA 2 MILESTONE. All four Era 2 mechanics (Prism, One-Way Reflector, Beam Receiver, Remote Emitter) plus Mirror/Portal/Switch/Gate in one system: a shared gate crossing two Prism branches, a genuine Receiv...
- **Camp 121 — Shared Spectrum** (`levels/campaign/era2_stage_01/level_21.gd`, 8x8, opt 5): Campaign Level 121 — "Shared Spectrum". THE FIRST WHOLE-BOARD-REASONING LEVEL IN ERA 2. A single One-Way Reflector is reused by the RED and GREEN Prism channels from two different directions - the SAME orientation must satisfy both. RED's own wrong-orientation...
- **Camp 122 — Remote Pair** (`levels/campaign/era2_stage_01/level_22.gd`, 8x9, opt 4): Campaign Level 122 — "Remote Pair". Two Receiver/Remote-Emitter chains that are NOT independent: Chain A's own beam directly powers Receiver B; Chain B's beam then trips a switch that opens the gate blocking Chain A's own final tail. Resolves monotonically acr...
- **Camp 123 — Prism Relay** (`levels/campaign/era2_stage_01/level_23.gd`, 9x10, opt 3): Campaign Level 123 — "Prism Relay". One Prism branch activates a Receiver directly; a second is recolored through a Filter; a third is independent; the Remote Emitter's own beam crosses a Portal before reaching its target. No single branch can be ignored - all...
- **Camp 124 — Directional Cross** (`levels/campaign/era2_stage_01/level_24.gd`, 10x8, opt 4): Campaign Level 124 — "Directional Cross". Two emitters, two One-Way Reflectors: the first reflector is genuinely shared (Emitter A enters it RIGHT - always reflective; Emitter B enters it DOWN - orientation- dependent), and Emitter B's own success is what open...
- **Camp 125 — False Spectrum** (`levels/campaign/era2_stage_01/level_25.gd`, 9x9, opt 4): Campaign Level 125 — "False Spectrum". THE MID-BLOCK CHECKPOINT. A deliberate near-solution trap: one mirror orientation reaches a real-looking (but optional) target directly; the other sends the beam through a Portal to the actual required target, whose color...
- **Camp 126 — Signal Cascade** (`levels/campaign/era2_stage_01/level_26.gd`, 9x11, opt 2): Campaign Level 126 — "Signal Cascade". A genuine activation cascade: Receiver A's power wakes Remote A, whose own beam directly powers Receiver B, waking Remote B, whose beam trips a switch that opens the gate on Remote A's own tail - six mechanic hops from th...
- **Camp 127 — Fractured Circuit** (`levels/campaign/era2_stage_01/level_27.gd`, 10x10, opt 4): Campaign Level 127 — "Fractured Circuit". Three spatially separated board regions linked only by a Portal jump and a shared One-Way Reflector that behaves differently for two different incoming routes - a Splitter's reflected branch is a genuine inert decoy.
- **Camp 128 — Reciprocal Signal** (`levels/campaign/era2_stage_01/level_28.gd`, 9x10, opt 4): Campaign Level 128 — "Reciprocal Signal". Two Receiver/Remote-Emitter chains that initially look like two separate systems - each has its own emitter, mirror, and receiver - but their two Remote Emitters cross through ONE shared gate cell, and Chain A's tail i...
- **Camp 129 — Spectral Network** (`levels/campaign/era2_stage_01/level_29.gd`, 9x11, opt 5): Campaign Level 129 — "Spectral Network". NEAR-FINALE DIFFICULTY. Every Era 2 mechanic is load-bearing: a Prism color-order dependency (GREEN needs RED's switch), a Receiver/Remote-Emitter chain isolated in its own column (the D81 lesson applied from the start)...
- **Camp 130 — Convergence Matrix** (`levels/campaign/era2_stage_01/level_30.gd`, 9x11, opt 7): Campaign Level 130 — "Convergence Matrix". THE SECOND MAJOR ERA 2 MILESTONE (Levels 121-130's own capstone). GREEN's own path is gated TWICE - once by RED's switch, once by the Remote Emitter's switch - so GREEN's single target requires FOUR independently-solv...
- **Camp 131 — Double Bind** (`levels/campaign/era2_stage_01/level_31.gd`, 9x9, opt 6): Campaign Level 131 — "Double Bind". THE FIRST ADVANCED-CONVERGENCE LEVEL. RED and GREEN share ONE One-Way Reflector from genuinely different directions (RIGHT vs DOWN, both reflective under BACKSLASH - the exact Level 121 pattern, re-verified safe). A second, ...
- **Camp 132 — Relay Exchange** (`levels/campaign/era2_stage_01/level_32.gd`, 8x9, opt 4): Campaign Level 132 — "Relay Exchange". A reciprocal relay: Chain A's own beam directly powers Receiver B; Chain B's beam then trips a switch that opens the gate blocking Chain A's own final tail. Chain A's Remote Emitter does NOT immediately reach its own obje...
- **Camp 133 — Spectral Lock** (`levels/campaign/era2_stage_01/level_33.gd`, 8x9, opt 3): Campaign Level 133 — "Spectral Lock". The GREEN channel crosses a Portal into a distant board region where a Filter recolors it to RED BEFORE a gate that only RED's own switch (a completely different Prism branch) can open - the player must reason backward fro...
- **Camp 134 — Cross Current** (`levels/campaign/era2_stage_01/level_34.gd`, 10x8, opt 5): Campaign Level 134 — "Cross Current". Two emitters share ONE One-Way Reflector from perpendicular directions (RIGHT/DOWN, both reflective under BACKSLASH); Emitter A's tail powers a Receiver, and the Remote Emitter it wakes REUSES a second mirror Emitter B's o...
- **Camp 135 — Delayed Spectrum** (`levels/campaign/era2_stage_01/level_35.gd`, 9x9, opt 3): Campaign Level 135 — "Delayed Spectrum". MAJOR MID-BLOCK CHECKPOINT. The RED channel's beam activates its own required target, then keeps traveling (targets never stop a beam) into a Beam Receiver that wakes a Remote Emitter elsewhere - fair and visually trace...
- **Camp 136 — Portal Relay** (`levels/campaign/era2_stage_01/level_36.gd`, 7x10, opt 5): Campaign Level 136 — "Portal Relay". Emitter -> Receiver A -> Remote A -> Portal -> One-Way Reflector -> Receiver B -> Remote B -> final objective. The reflector's WRONG orientation looks like progress (the beam keeps moving, bending toward open board) but act...
- **Camp 137 — Three-Way Refraction** (`levels/campaign/era2_stage_01/level_37.gd`, 8x10, opt 4): Campaign Level 137 — "Three-Way Refraction". All three Prism channels are meaningfully different: RED reaches its own colored objective via one mirror, GREEN directly activates a Receiver, and BLUE hits a Splitter creating two genuinely required routes - one o...
- **Camp 138 — Reciprocal Gates** (`levels/campaign/era2_stage_01/level_38.gd`, 9x10, opt 2): Campaign Level 138 — "Reciprocal Gates". Two Receiver/Remote-Emitter systems that read as independent at first glance (own emitter, own mirror, own receiver each) - the reciprocal coupling (Remote A's switch opens a gate on Emitter B's own path; Emitter B's sw...
- **Camp 139 — Fractured Network** (`levels/campaign/era2_stage_01/level_39.gd`, 9x11, opt 6): Campaign Level 139 — "Fractured Network". NEAR-FINALE. Every mechanic is load-bearing: a cross-color gate dependency (GREEN needs RED's switch), a Receiver/Remote-Emitter chain isolated in its own column (no accidental cross-talk), a One-Way Reflector whose pa...
- **Camp 140 — Refraction Engine** (`levels/campaign/era2_stage_01/level_40.gd`, 9x11, opt 8): Campaign Level 140 — "Refraction Engine". THE ERA 2 LEVELS 131-140 MILESTONE. Four interacting subsystems: RED's own switch opens one of GREEN's two gates; BLUE powers a Receiver that starts a genuine TWO-STAGE Remote Emitter chain (Remote 1 -> Receiver 2 -> R...
- **T01 — First Light** (`levels/tutorial/t01.gd`, 5x5, opt 1): Tutorial T01 — "First Light". Teaches: the emitter produces a laser, the target is the goal, a mirror redirects the beam, and tapping a mirror rotates it. Follows the brief's exact suggested 7-step sequence. See CLAUDE.md/DECISIONS.md "Guided tutorial system".
- **T02 — Two Turns** (`levels/tutorial/t02.gd`, 5x5, opt 1): Tutorial T02 — "Two Turns". Teaches both mirror orientations and how they change the beam's direction. The first mirror is forced (exactly like T01); the second is left to the player's own judgment once the lesson has been introduced, so they practice recogniz...
- **T03 — Locked In** (`levels/tutorial/t03.gd`, 5x5, opt 1): Tutorial T03 — "Locked In". Teaches: BLOCKER tiles stop the beam completely, and FIXED mirrors (rotatable=false) redirect the beam exactly like normal ones but can never be rotated by the player - MirrorTile._gui_input() already rejects taps on them and shows ...
- **T04 — Both Lights** (`levels/tutorial/t04.gd`, 5x5, opt 1): Tutorial T04 — "Both Lights". Teaches: some puzzles require MULTIPLE targets active simultaneously - activating one is not enough. The beam passes through target A on its way to target B (LaserSystem lets a beam activate several targets in sequence - see DECIS...
- **T05 — Split Path** (`levels/tutorial/t05.gd`, 5x5, opt 1): Tutorial T05 — "Split Path". Teaches: a SPLITTER sends the beam two ways at once - one branch continues straight, unconditionally, regardless of the splitter's orientation; the other branch reflects exactly like a mirror, and IS controlled by rotating it. Uses...
- **T06 — True Color** (`levels/tutorial/t06.gd`, 5x5, opt 1): Tutorial T06 — "True Color". Teaches: beams can be colored, and a colored target only accepts an exact color match - GridTypes. target_accepts_color() is the real, unmodified rule (WHITE is neutral on both ends, a colored target rejects anything else). The RED...
- **T07 — Recolor** (`levels/tutorial/t07.gd`, 5x5, opt 1): Tutorial T07 — "Recolor". Teaches: a FILTER repaints any beam that passes through it, unconditionally - it never bends the beam (direction is unchanged), it's fixed (never rotatable, no orientation at all), and mirrors/splitters downstream preserve whatever co...
- **T08 — Through the Portal** (`levels/tutorial/t08.gd`, 5x5, opt 1): Tutorial T08 — "Through the Portal". Teaches: a beam entering one PORTAL of a paired pair instantly exits the other, preserving direction and color exactly (no portal orientation exists - see DECISIONS.md D17). Portals are not player-interactive (no tile_click...
- **T09 — Switch and Gate** (`levels/tutorial/t09.gd`, 5x5, opt 1): Tutorial T09 — "Switch and Gate". Teaches three linked mechanics in one clean route: a SWITCH doesn't block/bend the beam, just crossing it opens a linked GATE elsewhere (gates are stateless/derived fresh every simulation pass - see DECISIONS.md "Switch/gate s...
- **T10 — Graduation** (`levels/tutorial/t10.gd`, 5x5, opt 1): Tutorial T10 — "Graduation". Teaches: multiple emitters fire completely independent beams (LaserSystem already loops over every EMITTER tile with zero special-casing - proven by dev regression level 13 "Two Sources"), and serves as the tutorial's final, lightl...
- **T11 — Welcome to Refractions** (`levels/tutorial/t11.gd`, 5x5, opt 1): Tutorial T11 — "Welcome to Refractions". Era 2's first tutorial. Teaches nothing new mechanically - purely a recap of the tap-to-rotate interaction under the new Era 2 visual theme, exactly like T01 did for Era 1, before T12+ introduce the four new mechanics. ...
- **T12 — Prism Basics** (`levels/tutorial/t12.gd`, 5x5, opt 1): Tutorial T12 — "Prism Basics". Teaches: a PRISM splits one WHITE beam into three colored beams (RED/GREEN/BLUE) at once - see GridTypes.prism_output_direction() and ERA_2_DESIGN.md "Prism". The RED (straight) channel already reaches its target with zero moves,...
- **T13 — Prism Colors** (`levels/tutorial/t13.gd`, 7x6, opt 1): Tutorial T13 — "Prism Colors". Teaches: unlike a WHITE beam, a COLORED beam entering a Prism only ever produces its own matching channel - never the other two. Two independent colored chains (red, green), each through its own Prism, contrast this directly agai...
- **T14 — Prism Routing** (`levels/tutorial/t14.gd`, 7x5, opt 1): Tutorial T14 — "Prism Routing". Teaches: a Prism's channels combine naturally with mirrors - each colored branch can be routed completely independently to its own target. Two required rotations this time (one per routed channel); the third (blue) channel is le...
- **T15 — Direction Matters** (`levels/tutorial/t15.gd`, 4x4, opt 1): Tutorial T15 — "Direction Matters". Introduces the ONE_WAY_REFLECTOR. A beam travelling RIGHT is always reflective for this tile (see GridTypes.one_way_reflector_is_reflective()) - rotating it (the exact same tap-to-rotate interaction as a mirror) changes WHIC...
- **T16 — Two Sides** (`levels/tutorial/t16.gd`, 8x7, opt 1): Tutorial T16 — "Two Sides". One rotatable One-Way Reflector, shared by TWO beams from different directions - rotating it affects both beams differently at once. The rightward beam always reflects (only the bend direction changes); the downward beam only reflec...
- **T17 — Signal Receiver** (`levels/tutorial/t17.gd`, 5x5, opt 1): Tutorial T17 — "Signal Receiver". Introduces the BEAM_RECEIVER alone, previewing what it does without yet requiring the player to route its effect - that's T18. The main beam (needing one familiar mirror rotation) already passes through the receiver on its way...
- **T18 — Remote Power** (`levels/tutorial/t18.gd`, 4x7, opt 1): Tutorial T18 — "Remote Power". The Receiver from T17 is now the whole puzzle: the main beam powers it automatically (zero moves), waking up a Remote Emitter whose own beam is what actually needs routing. Proves simulate_until_stable() already resolves the Rece...
- **T19 — Signal Chain** (`levels/tutorial/t19.gd`, 8x7, opt 1): Tutorial T19 — "Signal Chain". A Receiver -> Remote Emitter chain feeding a SWITCH that opens a GATE on the MAIN beam's own path - proving a Receiver-triggered chain can gate something else entirely, resolved by the same simulate_until_stable() multi-pass mach...
- **T20 — Era 2 Graduation** (`levels/tutorial/t20.gd`, 9x9, opt 1): Tutorial T20 — "Era 2 Graduation". Combines every Era 2 mechanic with an Era 1 one in a single puzzle, minimal hand-holding (one overview message, one free-play wait_for_solved step) - matching T10's own "reduce hand-holding by the final lesson" pattern. One W...
- **T21 — Fusion Node** (`levels/tutorial/t21.gd`, 5x5, opt 1): Tutorial T21 — "Fusion Node". Introduces the Fusion Node alone: two different primary beams arrive, one new color leaves. RED from the left + GREEN from above = YELLOW. The node starts facing UP (the side GREEN arrives on), so it is dark until the player's sin...
- **T22 — Output Side** (`levels/tutorial/t22.gd`, 6x5, opt 1): Tutorial T22 — "Output Direction". The node is already fusing RED + GREEN, but its output faces DOWN, away from the target. Turning it clockwise (DOWN -> LEFT -> UP -> RIGHT) walks the output through the two sides the inputs arrive on - each of which switches ...
- **T23 — Color Recipes** (`levels/tutorial/t23.gd`, 5x5, opt 1): Tutorial T23 — "Color Recipes". Two Fusion Nodes, one lesson each: RED + BLUE = MAGENTA (top node) and GREEN + BLUE = CYAN (bottom node). Both start facing UP, the side their BLUE beam arrives on, so each needs exactly one tap; the steps deal with them one at ...
- **T24 — Three Colors** (`levels/tutorial/t24.gd`, 6x5, opt 1): Tutorial T24 — "Three Colors". RED + GREEN + BLUE = WHITE. A WHITE target would accept ANY beam, so the proof of a real WHITE output is a Prism: only WHITE splits into three channels, lighting a RED, a GREEN and a BLUE target (RED straight, GREEN turns up, BLU...
- **T25 — Fusion Filter** (`levels/tutorial/t25.gd`, 5x5, opt 1): Tutorial T25 — "Fusion + Filter". Both emitters shoot plain WHITE beams (which a Fusion Node cannot accept - only RED/GREEN/BLUE are valid inputs); a GREEN Filter and a BLUE Filter on the input paths recolor them into a valid pair. GREEN + BLUE = CYAN. The clo...
- **T26 — Fusion Portal** (`levels/tutorial/t26.gd`, 6x7, opt 1): Tutorial T26 — "Fusion + Portal". The RED input has to travel through a portal pair (and needs one mirror turned to reach it) before it can arrive at the Fusion Node; the GREEN input arrives directly from below. Two forced taps: the mirror, then the node. The ...
- **T27 — Fusion Relay** (`levels/tutorial/t27.gd`, 5x6, opt 1): Tutorial T27 — "Fusion + Receiver". A Fusion Node's new beam passes through a Beam Receiver (which never blocks a beam), powering a Remote Emitter elsewhere on the board; that beam still needs one mirror turned to reach the target. Uses T17/T18's receiver rule...
- **T28 — Fusion Trial** (`levels/tutorial/t28.gd`, 7x9, opt 1): Tutorial T28 — "Fusion Challenge". Free-play comprehension check for the whole Fusion pack, matching T10/T20's "reduce hand-holding by the final lesson" pattern (one overview message, one wait_for_solved). GREEN (WHITE emitter + Filter) and BLUE (through a Por...
- **T29 — Select Path** (`levels/tutorial/t29.gd`, 5x5, opt 1): Tutorial T29 — "Select Path". Introduces the Splitter Selector alone: one beam in, exactly ONE chosen output. The selector starts pointing RIGHT into a wall; UP is also walled, so the only useful output is DOWN, one tap away. Nothing else is asked of the playe...
- **T30 — Choose Output** (`levels/tutorial/t30.gd`, 5x5, opt 1): Tutorial T30 — "Choose Output". Every output of the selector leads somewhere visible: LEFT is the side the beam arrives on (nothing leaves), UP lights a harmless decoy target, RIGHT hits a wall, DOWN reaches the real target. The selector starts on LEFT, so thr...
- **T31 — Sel + Filter** (`levels/tutorial/t31.gd`, 5x6, opt 1): Tutorial T31 — "Sel + Filter". Each selector output crosses a different Filter. The target needs BLUE; the RIGHT output (its start state) carries RED into a decoy BLUE target that stays dark, UP carries GREEN off the board, and only DOWN carries BLUE to the go...
- **T32 — Sel + Portal** (`levels/tutorial/t32.gd`, 6x6, opt 1): Tutorial T32 — "Sel + Portal". The selector's DOWN output enters a Portal and leaves the partner (row 0) still travelling DOWN, to the real target. The selector starts UP; the middle state, RIGHT, is a plausible-but-wrong route that lights a decoy target on th...
- **T33 — Sel + Fusion** (`levels/tutorial/t33.gd`, 6x6, opt 1): Tutorial T33 — "Sel + Fusion". GREEN reaches the Fusion Node directly; RED can only reach it through the Selector (any other output misses the node - the Selector is genuinely load-bearing). The node already faces the target, so both taps go to the Selector (U...
- **T34 — Sel Trial** (`levels/tutorial/t34.gd`, 7x8, opt 1): Tutorial T34 — "Sel Trial". Free-play check for the whole Selector pack (one overview message, one wait_for_solved, like T10/T20/T28). RED (WHITE emitter -> Selector -> RED Filter -> mirror M1) and GREEN (WHITE emitter -> GREEN Filter -> Portal pair) meet at a...

### 9.5 Other level populations
* **`levels/editor_fixtures/` (12 files)** — validator/solver/editor test fixtures (invalid gate ref, invalid portal, multi-solution, rectangular 5×8, …). DEV-ONLY, export-excluded.
* **`levels/fusion_qa/fusion_qa_set.gd`, `levels/selector_qa/selector_qa_set.gd`** — QA puzzle sets behind FUSION TEST / SELECTOR TEST (QA builds only; no saves/stars/ads).
* **`scripts/procedural/procedural_v5_qa_set.gd`** — curated V5 sample behind "V5 TEST".
* **Intended solution structure:** campaign levels were built by a solver-in-the-loop process (docs report the Era-1 audit as 100/100 `SOLVABLE`, and Era-2 levels 101–140 each `SOLVABLE` with `shortest_solution_count == 1`; I did NOT re-run the solver over all 140 in this audit). Manual approval status per docs: Era-1 stages 1–2 (levels 1–20) manually approved; owner later reported 1–50 good on a real device; 51–140 automated-validated only.
* **Known level risks:** manual approval pending for campaign 21–140 (docs); Mastery-band procedural boards are dense (38–57 tiles of 88) — phone readability unverified; `LevelMetrics` mislabels difficulty on early campaign levels (documented quirk).

---

## PART 10 — SOLVER / VALIDATOR / METRICS / EDITOR

| Tool | Path | Purpose | Referenced by | Production? | Safe to remove? |
|---|---|---|---|---|---|
| `LevelSolver` | `scripts/tools/level_solver.gd` | exhaustive/bounded search over 2-state rotations using the REAL `LaserSystem`; returns SOLVABLE / UNSOLVABLE / UNKNOWN (budget `DEFAULT_MAX_STATES`) — cannot model 4-state Fusion/Selector | test suite, editor, audit scenes, `hint_solution_builder` | DEV only (export-excluded) | No — it is the proof tool for handcrafted levels and hint table |
| `LevelValidator` | `scripts/tools/level_validator.gd` | errors (block save/playtest) vs warnings | editor, tests | DEV only | No |
| `LevelMetrics` | `scripts/tools/level_metrics.gd` | difficulty estimates | editor, tests | DEV only | Low risk, but tests cover it |
| Level editor | `tools/level_editor/level_editor.tscn/.gd` | runtime scene (not EditorPlugin), opened with F6; playtest hand-off via `GameManager.is_editor_playtest` (never writes saves) | – | DEV only | No (documented in LEVEL_EDITOR.md) |
| Audit/sample scenes | `scripts/tools/*.tscn` (v3/v5 samples, fusion/selector verify, procedural_audit, difficulty_inspect, hint_solution_builder) | dev-time proofs of the generator; long audits are banned by default (≤ ~60 s per run) | CLAUDE.md procedures | DEV only | No |
| UI shots | `tools/ui_shots/*` | renders every screen from an isolated project COPY | – | DEV only | Optional |
| CI scripts | `tools/ci/*.sh` | version/ad-id/Game-ID stamping, build mode | `release.yml` | CI only | No |

All of `tools/**` and `scripts/tools/**` and `levels/editor_fixtures/**` are in the export `exclude_filter`.



---

## PART 11 — ASSET FORENSIC AUDIT

**Counts.** 179 image files tracked under `assets/` plus `icon.svg` (184 PNG, 27 SVG overall incl. plugin art). Reference scan = exact `res://` path match across all scripts, scenes, resources, `project.godot`, `export_presets.cfg` and tools (addon `admob` internals excluded).

| Bucket | Files | Notes |
|---|---|---|
| Referenced by production code/scenes/config, **packaged** in Android | 69 | the canonical live set |
| Referenced, but excluded from Android | 1 | `assets/branding/bs_app_icon_ios_1024.png` — referenced only by the **iOS preset** (`icons/icon_1024x1024`), correctly stripped from Android |
| Referenced only by tests/tools | 1 | `icon.svg` (a test) |
| **Unreferenced and excluded** from Android (≈184 MB raw) | 95 | source/legacy/inactive art, correctly stripped |
| **Unreferenced but still packaged** | 13 (≈18 MB raw) | dead weight, see list below |
Packaged image bytes (raw PNG) ≈ 109 MB; Godot's import compression is why APKs are ~170 MB (debug) / ~123–145 MB (AAB).

### Which gameplay art is canonical (the "competing sets" question)

1. **Canonical (live):** `assets/gameplay/<type>/bs_<…>_runtime.png` — **512×512 RGBA**, preloaded by the tile scripts: `bs_tile_mirror_runtime.png` (mirror.gd), `bs_tile_target_runtime.png` (target.gd), `bs_tile_blocker_runtime.png` (blocker.gd), `bs_tile_hazard_runtime.png` (hazard.gd), `bs_tile_gate_open/closed_runtime.png` (gate.gd), `grid/bs_tile_grid_base_runtime.png` (tile_visual.gd, the cell background), `effects/bs_fx_mirror_selection_runtime.png`, `effects/bs_fx_target_activated_runtime.png`. Plus the newer standalone art: `fusion/bs_fusion_node(_active).png`, `splitter_selector/bs_splitter_selector(_active).png` (1303×1207), and the four Era-2 tile faces (`prism/…_era2.png`, `one_way_reflector/…_era2.png`, `beam_receiver/…base/inactive_era2.png`, `remote_emitter/…base/inactive_era2.png` — **opaque RGB, purple**, still used in normal gameplay because the unified-blue switch only affects the board/HUD skin, not these tile faces).
2. **Source masters (unreferenced, 1254×1254):** the un-suffixed `bs_tile_*.png` next to each runtime file (mirror, target, blocker, hazard, gate open/closed, grid base, emitter, filter, portal, splitter, switch) and `effects/bs_fx_laser_beams.png`, `bs_fx_laser_impact.png`. Excluded from Android via explicit `exclude_filter` entries.
3. **Tainted art deliberately NOT used (CLAUDE rule 10):** emitter, splitter, portal, switch, filter have PNGs (`assets/gameplay/{emitter,filter,portal,splitter,switch}/bs_tile_*.png`) that bake a fixed-direction beam/colour into the tile, which would contradict level data, so those five tiles are rendered **procedurally with `_draw()`** (no texture preload; confirmed by grep: 0 `preload` of art, 1 `_draw` in each).
4. **Legacy flat set:** `assets/gameplay/pieces/**` (17 files, 31 MB) and `assets/gameplay/tiles/bs_tile_grid_empty.png` — an earlier generated set (DECISIONS D31/D51). Unreferenced, excluded by `assets/gameplay/pieces/**` / `assets/gameplay/tiles/**`. Per CLAUDE.md / DECISIONS D51 this same folder's blocker/hazard files once caused a real shipped-build bug (assets referenced from an export-excluded location); the current code references only per-type files, and the reference scan above confirms nothing in production points into `pieces/` or `tiles/`.
5. **Era-2 art, inactive:** `assets/gameplay/grid/era2/`, `backgrounds/era2/`, `fx/era2/` (8 VFX), `assets/ui/era2/` (16 files). Reachable only through `EraTheme._build_era_2()`, which `EraTheme.for_era()` never returns while `UNIFIED_BLUE_THEME_ONLY := true`. Flipping that constant to `false` restores the violet skin with no other change.
6. **Backgrounds:** live gameplay background is `assets/backgrounds/gameplay/bs_bg_gameplay.png` (game.gd `DEFAULT_GAMEPLAY_BACKGROUND`, node `modulate` darkened to (0.22,0.26,0.38) — "Minimal Gameplay Background" rule, do not change without request). Menu backgrounds are `assets/ui/backgrounds/bs_bg_{main_menu,campaign_select,tutorial_select}_v2.png` (+ two era2 variants). `assets/backgrounds/{main_menu,level_select}/*.png` are pre-V2 leftovers, excluded.
7. **UI art superseded by the UI redesign (2026-10-01):** the old `bs_panel_*_portrait.png` frames, per-screen panel art, legacy HUD bar images (still `preload`ed as constants in `game.gd` but the visible HUD is flat `HudPlate` panels), `assets/ui/panels/**`, `assets/ui/gameplay/**`, `assets/ui/stage_*`. Text is now always a Label/Button (Rajdhani); art buttons remain for Main Menu / Settings / Pause / Level Complete / New Game dialog.

### Unreferenced but still packaged in Android (13 files, ≈18 MB raw) — safe candidates to exclude, NOT deleted
`assets/branding/bs_logo_main.png`, `assets/ui/buttons/bs_ui_button_{danger,primary,secondary}.png`, `assets/ui/era2/bs_milestone_complete_era2.png`, `assets/ui/icons/bs_fusion_icon.png`, `assets/ui/icons/bs_splitter_selector_icon.png`, `assets/ui/icons/bs_ui_icon_settings.png`, `assets/ui/panels/bs_panel_{level_complete,pause,settings}_portrait.png`, `assets/ui/settings/bs_ui_toggle_{on,off}_runtime.png`. (Dynamic path construction was searched for — none in production code — so these are genuinely unreferenced; `bs_fusion_icon.png` is deliberately unused per CLAUDE.md because the tutorial panel has no icon support.)

### Complete image table
Legend: status = `REF` referenced by the files listed (exact `res://` path match in scripts/scenes/resources/project/export config); `UNREF` = no exact-path reference anywhere; `TOOLS` = referenced only by dev tools. `Android` = whether the Android RELEASE preset exclude_filter strips it from the package. Alpha column is the PNG colour type (RGBA = has an alpha channel; RGB = opaque/full-background image).


#### `assets/backgrounds/gameplay` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `backgrounds/gameplay/bs_bg_gameplay.png` | 941x1672 | RGB | 2306 | legacy menu/gameplay backgrounds | REF | game.gd, game.tscn | packaged |

#### `assets/backgrounds/level_select` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `backgrounds/level_select/bs_bg_level_select.png` | 941x1672 | RGB | 2664 | legacy menu/gameplay backgrounds | UNREF | - | EXCLUDED |

#### `assets/backgrounds/main_menu` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `backgrounds/main_menu/bs_bg_main_menu.png` | 941x1672 | RGB | 2411 | legacy menu/gameplay backgrounds | UNREF | - | EXCLUDED |

#### `assets/branding/4sagez_logo 1.PNG` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `branding/4sagez_logo 1.PNG` | 1024x1024 | RGBA | 1518 | branding / app icon / logos | REF | studio_splash.tscn | packaged |

#### `assets/branding/MaclePro_logo 1.PNG` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `branding/MaclePro_logo 1.PNG` | 1920x1080 | RGBA | 2111 | branding / app icon / logos | REF | studio_splash.tscn | packaged |

#### `assets/branding/app_icon` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `branding/app_icon/bs_app_icon.png` | 1254x1254 | RGB | 2468 | branding / app icon / logos | UNREF | - | EXCLUDED |

#### `assets/branding/bs_app_icon.png` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `branding/bs_app_icon.png` | 1254x1254 | RGB | 2267 | branding / app icon / logos | REF | export_presets.cfg, project.godot | packaged |

#### `assets/branding/bs_app_icon_ios_1024.png` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `branding/bs_app_icon_ios_1024.png` | 1024x1024 | RGB | 1496 | branding / app icon / logos | REF | export_presets.cfg | EXCLUDED |

#### `assets/branding/bs_logo_main.png` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `branding/bs_logo_main.png` | 1774x887 | RGBA | 1533 | branding / app icon / logos | UNREF | - | packaged |

#### `assets/gameplay/backgrounds` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/backgrounds/era2/bs_bg_gameplay_era2.png` | 941x1672 | RGB | 2085 | gameplay background (Era 2 art, inactive) | REF | era_theme.gd | packaged |

#### `assets/gameplay/beam_receiver` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/beam_receiver/bs_tile_beam_receiver_base_era2.png` | 1254x1254 | RGB | 1787 | gameplay tile art | REF | beam_receiver_tile.gd | packaged |
| `gameplay/beam_receiver/bs_tile_beam_receiver_inactive_era2.png` | 1254x1254 | RGB | 1803 | gameplay tile art | REF | beam_receiver_tile.gd | packaged |

#### `assets/gameplay/blocker` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/blocker/bs_tile_blocker.png` | 1254x1254 | RGBA | 1894 | gameplay tile art | UNREF | - | EXCLUDED |
| `gameplay/blocker/bs_tile_blocker_runtime.png` | 512x512 | RGBA | 441 | gameplay tile art | REF | blocker.gd | packaged |

#### `assets/gameplay/effects` (6 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/effects/bs_fx_laser_beams.png` | 1774x887 | RGBA | 1490 | gameplay VFX / selection / target glow | UNREF | - | EXCLUDED |
| `gameplay/effects/bs_fx_laser_impact.png` | 1254x1254 | RGBA | 1044 | gameplay VFX / selection / target glow | UNREF | - | EXCLUDED |
| `gameplay/effects/bs_fx_mirror_selection.png` | 1254x1254 | RGBA | 1609 | gameplay VFX / selection / target glow | UNREF | - | EXCLUDED |
| `gameplay/effects/bs_fx_mirror_selection_runtime.png` | 512x512 | RGBA | 408 | gameplay VFX / selection / target glow | REF | mirror.gd | packaged |
| `gameplay/effects/bs_fx_target_activated.png` | 1254x1254 | RGBA | 1840 | gameplay VFX / selection / target glow | UNREF | - | EXCLUDED |
| `gameplay/effects/bs_fx_target_activated_runtime.png` | 512x512 | RGBA | 448 | gameplay VFX / selection / target glow | REF | target.gd | packaged |

#### `assets/gameplay/emitter` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/emitter/bs_tile_emitter.png` | 1254x1254 | RGBA | 1597 | gameplay tile art | UNREF | - | EXCLUDED |

#### `assets/gameplay/filter` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/filter/bs_tile_filter.png` | 1254x1254 | RGBA | 1893 | gameplay tile art | UNREF | - | EXCLUDED |

#### `assets/gameplay/fusion` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/fusion/bs_fusion_node.png` | 1254x1254 | RGBA | 1374 | gameplay tile art | REF | fusion_tile.gd | packaged |
| `gameplay/fusion/bs_fusion_node_active.png` | 1254x1254 | RGBA | 1389 | gameplay tile art | REF | fusion_tile.gd | packaged |

#### `assets/gameplay/fx` (8 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/fx/era2/bs_fx_ambient_energy_era2.png` | 1254x1254 | RGBA | 1574 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_beam_receiver_activation_era2.png` | 1254x1254 | RGBA | 1628 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_grid_cell_select_era2.png` | 1247x1261 | RGBA | 1335 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_level_complete_era2.png` | 1024x1536 | RGBA | 2980 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_one_way_reflector_activation_era2.png` | 1254x1254 | RGBA | 991 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_prism_activation_era2.png` | 1254x1254 | RGBA | 1213 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_puzzle_solved_era2.png` | 1152x1366 | RGBA | 2782 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |
| `gameplay/fx/era2/bs_fx_remote_emitter_activation_era2.png` | 1254x1254 | RGBA | 1684 | gameplay VFX (Era 2 art, inactive) | UNREF | - | EXCLUDED |

#### `assets/gameplay/gate` (4 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/gate/bs_tile_gate_closed.png` | 1254x1254 | RGBA | 1964 | gameplay tile art | UNREF | - | EXCLUDED |
| `gameplay/gate/bs_tile_gate_closed_runtime.png` | 512x512 | RGBA | 533 | gameplay tile art | REF | gate.gd | packaged |
| `gameplay/gate/bs_tile_gate_open.png` | 1254x1254 | RGBA | 1493 | gameplay tile art | UNREF | - | EXCLUDED |
| `gameplay/gate/bs_tile_gate_open_runtime.png` | 512x512 | RGBA | 372 | gameplay tile art | REF | gate.gd | packaged |

#### `assets/gameplay/grid` (5 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/grid/bs_tile_grid_base.png` | 1254x1254 | RGBA | 1732 | board cell art | UNREF | - | EXCLUDED |
| `gameplay/grid/bs_tile_grid_base_runtime.png` | 512x512 | RGBA | 363 | board cell art | REF | tile_visual.gd | packaged |
| `gameplay/grid/era2/bs_grid_surface_era2.png` | 941x1672 | RGBA | 2373 | board cell art | UNREF | - | EXCLUDED |
| `gameplay/grid/era2/bs_tile_grid_empty_era2.png` | 1254x1254 | RGBA | 1957 | board cell art | REF | era_theme.gd | packaged |
| `gameplay/grid/era2/bs_tile_grid_selected_era2.png` | 1254x1254 | RGBA | 2255 | board cell art | REF | era_theme.gd | packaged |

#### `assets/gameplay/hazard` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/hazard/bs_tile_hazard.png` | 1254x1254 | RGBA | 2306 | gameplay tile art | UNREF | - | EXCLUDED |
| `gameplay/hazard/bs_tile_hazard_runtime.png` | 512x512 | RGBA | 555 | gameplay tile art | REF | hazard.gd | packaged |

#### `assets/gameplay/mirror` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/mirror/bs_tile_mirror.png` | 1254x1254 | RGBA | 2060 | gameplay tile art | UNREF | - | EXCLUDED |
| `gameplay/mirror/bs_tile_mirror_runtime.png` | 512x512 | RGBA | 463 | gameplay tile art | REF | mirror.gd | packaged |

#### `assets/gameplay/one_way_reflector` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/one_way_reflector/bs_tile_one_way_reflector_base_era2.png` | 1254x1254 | RGB | 1706 | gameplay tile art | REF | one_way_reflector_tile.gd | packaged |

#### `assets/gameplay/pieces` (17 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/pieces/bs_tile_blocker.png` | 1254x1254 | RGBA | 1894 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_color_filter.png` | 1254x1254 | RGBA | 1681 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_emitter.png` | 1254x1254 | RGBA | 1309 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_gate_closed.png` | 1254x1254 | RGBA | 1689 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_gate_open.png` | 1254x1254 | RGBA | 1417 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_hazard.png` | 1254x1254 | RGBA | 2306 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_mirror.png` | 1254x1254 | RGBA | 1577 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_mirror_locked.png` | 1254x1254 | RGBA | 1938 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_mirror_movable.png` | 1254x1254 | RGBA | 1823 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_portal.png` | 1254x1254 | RGBA | 1893 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_splitter.png` | 1254x1254 | RGBA | 1610 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_switch.png` | 1254x1254 | RGBA | 1806 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/bs_tile_target.png` | 1254x1254 | RGBA | 1747 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/era2/bs_tile_beam_receiver_era2.png` | 1254x1254 | RGB | 1810 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/era2/bs_tile_one_way_reflector_era2.png` | 1254x1254 | RGB | 1741 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/era2/bs_tile_prism_era2.png` | 1254x1254 | RGBA | 2372 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |
| `gameplay/pieces/era2/bs_tile_remote_emitter_era2.png` | 1254x1254 | RGB | 1759 | gameplay: legacy flat generated set | UNREF | - | EXCLUDED |

#### `assets/gameplay/portal` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/portal/bs_tile_portal.png` | 1254x1254 | RGBA | 2122 | gameplay tile art | UNREF | - | EXCLUDED |

#### `assets/gameplay/prism` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/prism/bs_tile_prism_base_era2.png` | 1254x1254 | RGB | 1682 | gameplay tile art | REF | prism_tile.gd | packaged |

#### `assets/gameplay/remote_emitter` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/remote_emitter/bs_tile_remote_emitter_base_era2.png` | 1254x1254 | RGB | 1786 | gameplay tile art | REF | remote_emitter_tile.gd | packaged |
| `gameplay/remote_emitter/bs_tile_remote_emitter_inactive_era2.png` | 1254x1254 | RGB | 1780 | gameplay tile art | REF | remote_emitter_tile.gd | packaged |

#### `assets/gameplay/splitter` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/splitter/bs_tile_splitter.png` | 1254x1254 | RGBA | 2162 | gameplay tile art | UNREF | - | EXCLUDED |

#### `assets/gameplay/splitter_selector` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/splitter_selector/bs_splitter_selector.png` | 1303x1207 | RGBA | 2037 | gameplay tile art | REF | splitter_selector_tile.gd | packaged |
| `gameplay/splitter_selector/bs_splitter_selector_active.png` | 1303x1207 | RGBA | 2060 | gameplay tile art | REF | splitter_selector_tile.gd | packaged |

#### `assets/gameplay/switch` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/switch/bs_tile_switch.png` | 1254x1254 | RGBA | 2017 | gameplay tile art | UNREF | - | EXCLUDED |

#### `assets/gameplay/target` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/target/bs_tile_target.png` | 1254x1254 | RGBA | 2089 | gameplay tile art | UNREF | - | EXCLUDED |
| `gameplay/target/bs_tile_target_runtime.png` | 512x512 | RGBA | 489 | gameplay tile art | REF | target.gd | packaged |

#### `assets/gameplay/tiles` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `gameplay/tiles/bs_tile_grid_empty.png` | 1254x1254 | RGB | 2090 | gameplay: legacy empty-cell tile | UNREF | - | EXCLUDED |

#### `assets/ui/backgrounds` (5 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/backgrounds/bs_bg_campaign_select_v2.png` | 941x1672 | RGB | 1912 | menu screen backgrounds (V2) | REF | level_select.gd, level_select.tscn | packaged |
| `ui/backgrounds/bs_bg_level_select_era2_portrait.png` | 941x1672 | RGB | 2562 | menu screen backgrounds (V2) | REF | era_theme.gd | packaged |
| `ui/backgrounds/bs_bg_main_menu_v2.png` | 941x1672 | RGB | 1976 | menu screen backgrounds (V2) | REF | main_menu.tscn | packaged |
| `ui/backgrounds/bs_bg_tutorial_select_era2_portrait.png` | 941x1672 | RGB | 2646 | menu screen backgrounds (V2) | REF | era_theme.gd | packaged |
| `ui/backgrounds/bs_bg_tutorial_select_v2.png` | 941x1672 | RGB | 2031 | menu screen backgrounds (V2) | REF | about_screen.tscn, account_screen.tscn, age_selection.tscn, privacy_policy_screen.tscn, settings_menu.tscn, tu | packaged |

#### `assets/ui/branding` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/branding/bs_logo_main_menu_portrait.png` | 1215x1295 | RGBA | 1193 | UI branding | REF | about_screen.tscn, main_menu.tscn, settings_menu.tscn | packaged |

#### `assets/ui/buttons` (8 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/buttons/bs_btn_continue.png` | 2188x718 | RGBA | 1429 | UI buttons (art) | REF | main_menu.tscn | packaged |
| `ui/buttons/bs_btn_main_about_footer.png` | 2172x724 | RGBA | 1257 | UI buttons (art) | REF | main_menu.tscn | packaged |
| `ui/buttons/bs_btn_main_settings_footer.png` | 2172x724 | RGBA | 1338 | UI buttons (art) | REF | main_menu.tscn | packaged |
| `ui/buttons/bs_btn_new_game.png` | 2161x728 | RGBA | 1354 | UI buttons (art) | REF | main_menu.tscn | packaged |
| `ui/buttons/bs_btn_tutorials.png` | 2160x728 | RGBA | 1311 | UI buttons (art) | REF | main_menu.tscn | packaged |
| `ui/buttons/bs_ui_button_danger.png` | 1774x887 | RGBA | 1146 | UI buttons (art) | UNREF | - | packaged |
| `ui/buttons/bs_ui_button_primary.png` | 1774x887 | RGBA | 1168 | UI buttons (art) | UNREF | - | packaged |
| `ui/buttons/bs_ui_button_secondary.png` | 1774x887 | RGBA | 1139 | UI buttons (art) | UNREF | - | packaged |

#### `assets/ui/dialogs` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/dialogs/new_game/bs_btn_new_game_cancel.png` | 2172x724 | RGBA | 1407 | dialog art buttons (New Game) | REF | main_menu.gd | packaged |
| `ui/dialogs/new_game/bs_btn_new_game_confirm.png` | 2172x724 | RGBA | 1460 | dialog art buttons (New Game) | REF | main_menu.gd | packaged |

#### `assets/ui/era2` (16 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/era2/bs_header_era2_refractions_portrait.png` | 941x1672 | RGB | 2521 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_hud_bottom_era2.png` | 2172x724 | RGBA | 1307 | Era 2 UI art (inactive theme) | REF | era_theme.gd | packaged |
| `ui/era2/bs_hud_top_era2.png` | 2172x724 | RGBA | 1562 | Era 2 UI art (inactive theme) | REF | era_theme.gd | packaged |
| `ui/era2/bs_icon_loading_era2.png` | 1254x1254 | RGBA | 2468 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_icon_mechanic_unlock_era2.png` | 1254x1254 | RGBA | 2329 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_icon_star_era2.png` | 1254x1254 | RGBA | 2103 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_level_card_era2.png` | 1024x1536 | RGBA | 2867 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_level_card_locked_era2.png` | 1024x1536 | RGB | 2489 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_milestone_complete_era2.png` | 1536x1024 | RGBA | 2505 | Era 2 UI art (inactive theme) | UNREF | - | packaged |
| `ui/era2/bs_panel_level_complete_clean_era2.png` | 1024x1536 | RGBA | 2348 | Era 2 UI art (inactive theme) | REF | era_theme.gd | packaged |
| `ui/era2/bs_panel_level_complete_era2.png` | 1536x1024 | RGBA | 2593 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_panel_mechanic_notification_era2.png` | 1774x887 | RGBA | 1713 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_panel_tutorial_complete_era2.png` | 1024x1536 | RGBA | 2310 | Era 2 UI art (inactive theme) | REF | era_theme.gd | packaged |
| `ui/era2/bs_transition_era1_to_era2.png` | 1024x1536 | RGB | 2856 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_tutorial_complete_era2.png` | 1024x1536 | RGBA | 2937 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |
| `ui/era2/bs_tutorial_highlight_frame_era2.png` | 1024x1536 | RGBA | 2141 | Era 2 UI art (inactive theme) | UNREF | - | EXCLUDED |

#### `assets/ui/gameplay` (4 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/gameplay/bs_ui_gameplay_bottom_frame.png` | 2079x756 | RGBA | 958 | legacy gameplay HUD art | UNREF | - | EXCLUDED |
| `ui/gameplay/bs_ui_gameplay_top_frame.png` | 2079x756 | RGBA | 733 | legacy gameplay HUD art | UNREF | - | EXCLUDED |
| `ui/gameplay/bs_ui_icon_best_moves.png` | 1254x1254 | RGBA | 1976 | legacy gameplay HUD art | UNREF | - | EXCLUDED |
| `ui/gameplay/bs_ui_icon_moves.png` | 1254x1254 | RGBA | 1946 | legacy gameplay HUD art | UNREF | - | EXCLUDED |

#### `assets/ui/hud` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/hud/bs_hud_bottom_portrait.png` | 2112x744 | RGBA | 1140 | gameplay HUD art | REF | game.gd, game.tscn | packaged |
| `ui/hud/bs_hud_top_portrait.png` | 2112x745 | RGBA | 1111 | gameplay HUD art | REF | game.gd, game.tscn | packaged |

#### `assets/ui/icons` (25 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/icons/bs_fusion_icon.png` | 1254x1254 | RGBA | 1307 | UI icons | UNREF | - | packaged |
| `ui/icons/bs_icon_hint.png` | 1254x1254 | RGBA | 1823 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_icon_pause.png` | 1254x1254 | RGBA | 1960 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_icon_reset.png` | 1254x1254 | RGBA | 1976 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_splitter_selector_icon.png` | 1254x1254 | RGBA | 1285 | UI icons | UNREF | - | packaged |
| `ui/icons/bs_ui_icon_back.png` | 1254x1254 | RGBA | 1934 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_back_runtime.png` | 256x256 | RGBA | 117 | UI icons | REF | game.tscn | packaged |
| `ui/icons/bs_ui_icon_hint.png` | 1254x1254 | RGBA | 1891 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_hint_runtime.png` | 256x256 | RGBA | 133 | UI icons | REF | game.tscn | packaged |
| `ui/icons/bs_ui_icon_home.png` | 1254x1254 | RGBA | 1826 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_level_select.png` | 1254x1254 | RGBA | 1855 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_lock.png` | 1254x1254 | RGBA | 1803 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_lock_runtime.png` | 256x256 | RGBA | 128 | UI icons | REF | fusion_tile.gd, mirror.gd, one_way_reflector_tile.gd, splitter_selector_tile.gd | packaged |
| `ui/icons/bs_ui_icon_music_off.png` | 1254x1254 | RGBA | 1889 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_music_on.png` | 1254x1254 | RGBA | 1917 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_next.png` | 1254x1254 | RGBA | 1837 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_pause.png` | 1254x1254 | RGBA | 1743 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_pause_runtime.png` | 256x256 | RGBA | 117 | UI icons | REF | game.tscn | packaged |
| `ui/icons/bs_ui_icon_play.png` | 1254x1254 | RGBA | 1852 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_reset.png` | 1254x1254 | RGBA | 1944 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_reset_runtime.png` | 256x256 | RGBA | 119 | UI icons | REF | game.tscn | packaged |
| `ui/icons/bs_ui_icon_retry.png` | 1254x1254 | RGBA | 1924 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_settings.png` | 1254x1254 | RGBA | 1906 | UI icons | UNREF | - | packaged |
| `ui/icons/bs_ui_icon_sound_off.png` | 1254x1254 | RGBA | 1843 | UI icons | UNREF | - | EXCLUDED |
| `ui/icons/bs_ui_icon_sound_on.png` | 1254x1254 | RGBA | 1807 | UI icons | UNREF | - | EXCLUDED |

#### `assets/ui/level_complete` (5 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/level_complete/bs_btn_complete_main_menu.png` | 2172x724 | RGBA | 1485 | level-complete popup art | REF | level_complete_popup.tscn | packaged |
| `ui/level_complete/bs_btn_complete_next_level.png` | 2172x724 | RGBA | 1456 | level-complete popup art | REF | level_complete_popup.tscn | packaged |
| `ui/level_complete/bs_btn_complete_retry.png` | 2172x724 | RGBA | 1457 | level-complete popup art | REF | level_complete_popup.tscn | packaged |
| `ui/level_complete/bs_ui_level_complete.png` | 1254x1254 | RGBA | 1552 | level-complete popup art | UNREF | - | EXCLUDED |
| `ui/level_complete/bs_ui_level_complete_panel.png` | 1536x1024 | RGBA | 1885 | level-complete popup art | UNREF | - | EXCLUDED |

#### `assets/ui/level_select` (10 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/level_select/bs_ui_level_button_completed.png` | 1222x1287 | RGBA | 1599 | level select / stars art | UNREF | - | EXCLUDED |
| `ui/level_select/bs_ui_level_button_completed_runtime.png` | 512x540 | RGBA | 466 | level select / stars art | REF | level_button.gd, tutorial_button.gd | packaged |
| `ui/level_select/bs_ui_level_button_locked.png` | 1222x1287 | RGBA | 1614 | level select / stars art | UNREF | - | EXCLUDED |
| `ui/level_select/bs_ui_level_button_locked_runtime.png` | 512x540 | RGBA | 443 | level select / stars art | REF | level_button.gd, tutorial_button.gd | packaged |
| `ui/level_select/bs_ui_level_button_unlocked.png` | 1222x1287 | RGBA | 1501 | level select / stars art | UNREF | - | EXCLUDED |
| `ui/level_select/bs_ui_level_button_unlocked_runtime.png` | 512x540 | RGBA | 432 | level select / stars art | REF | level_button.gd, level_button.tscn, tutorial_button.gd, tutorial_button.tscn | packaged |
| `ui/level_select/bs_ui_star_earned.png` | 1254x1254 | RGBA | 1728 | level select / stars art | UNREF | - | EXCLUDED |
| `ui/level_select/bs_ui_star_earned_runtime.png` | 128x128 | RGBA | 27 | level select / stars art | REF | level_button.gd, level_complete_popup.gd | packaged |
| `ui/level_select/bs_ui_star_unearned.png` | 1254x1254 | RGBA | 1697 | level select / stars art | UNREF | - | EXCLUDED |
| `ui/level_select/bs_ui_star_unearned_runtime.png` | 128x128 | RGBA | 25 | level select / stars art | REF | level_button.gd, level_button.tscn, level_complete_popup.gd, level_complete_popup.tscn | packaged |

#### `assets/ui/panels` (3 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/panels/bs_panel_level_complete_portrait.png` | 941x1672 | RGBA | 1661 | legacy panel frames | UNREF | - | packaged |
| `ui/panels/bs_panel_pause_portrait.png` | 941x1672 | RGBA | 1609 | legacy panel frames | UNREF | - | packaged |
| `ui/panels/bs_panel_settings_portrait.png` | 941x1672 | RGBA | 1777 | legacy panel frames | UNREF | - | packaged |

#### `assets/ui/pause` (5 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/pause/bs_btn_pause_main_menu.png` | 2172x724 | RGBA | 1211 | pause menu art | REF | pause_menu.tscn | packaged |
| `ui/pause/bs_btn_pause_restart.png` | 2172x724 | RGBA | 1256 | pause menu art | REF | pause_menu.tscn | packaged |
| `ui/pause/bs_btn_pause_resume.png` | 2172x724 | RGBA | 1283 | pause menu art | REF | pause_menu.tscn | packaged |
| `ui/pause/bs_btn_pause_settings.png` | 2172x724 | RGBA | 1246 | pause menu art | REF | pause_menu.tscn | packaged |
| `ui/pause/bs_ui_pause_panel.png` | 941x1672 | RGBA | 1609 | pause menu art | UNREF | - | EXCLUDED |

#### `assets/ui/settings` (12 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/settings/bs_btn_about_us.png` | 2172x724 | RGBA | 1182 | settings screen art | REF | settings_menu.tscn | packaged |
| `ui/settings/bs_btn_account.png` | 2172x724 | RGBA | 1172 | settings screen art | REF | settings_menu.tscn | packaged |
| `ui/settings/bs_btn_no_forced_ads.png` | 2172x724 | RGBA | 1151 | settings screen art | REF | settings_menu.tscn | packaged |
| `ui/settings/bs_btn_restore_purchases.png` | 2172x724 | RGBA | 1199 | settings screen art | REF | settings_menu.tscn | packaged |
| `ui/settings/bs_btn_settings_back.png` | 2171x724 | RGBA | 1721 | settings screen art | REF | about_screen.tscn, privacy_policy_screen.tscn, settings_menu.tscn, tutorial_select.tscn | packaged |
| `ui/settings/bs_toggle_off.png` | 1983x793 | RGBA | 1792 | settings screen art | REF | settings_menu.gd | packaged |
| `ui/settings/bs_toggle_on.png` | 2172x724 | RGBA | 1542 | settings screen art | REF | settings_menu.gd, settings_menu.tscn | packaged |
| `ui/settings/bs_ui_settings_panel.png` | 941x1672 | RGBA | 1671 | settings screen art | UNREF | - | EXCLUDED |
| `ui/settings/bs_ui_toggle_off.png` | 1774x887 | RGBA | 1342 | settings screen art | UNREF | - | EXCLUDED |
| `ui/settings/bs_ui_toggle_off_runtime.png` | 640x320 | RGBA | 295 | settings screen art | UNREF | - | packaged |
| `ui/settings/bs_ui_toggle_on.png` | 1774x887 | RGBA | 1315 | settings screen art | UNREF | - | EXCLUDED |
| `ui/settings/bs_ui_toggle_on_runtime.png` | 640x320 | RGBA | 298 | settings screen art | UNREF | - | packaged |

#### `assets/ui/stage_complete` (2 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/stage_complete/bs_ui_stage_card.png` | 1536x1024 | RGBA | 1834 | legacy stage-complete art | UNREF | - | EXCLUDED |
| `ui/stage_complete/bs_ui_stage_complete.png` | 1254x1254 | RGBA | 2094 | legacy stage-complete art | UNREF | - | EXCLUDED |

#### `assets/ui/stage_select` (4 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `ui/stage_select/bs_ui_stage_card_selected.png` | 1536x1024 | RGBA | 1666 | legacy stage-select art | UNREF | - | EXCLUDED |
| `ui/stage_select/bs_ui_stage_locked.png` | 1254x1254 | RGBA | 1662 | legacy stage-select art | UNREF | - | EXCLUDED |
| `ui/stage_select/bs_ui_stage_selected.png` | 1254x1254 | RGBA | 1663 | legacy stage-select art | UNREF | - | EXCLUDED |
| `ui/stage_select/bs_ui_stage_unlocked.png` | 1254x1254 | RGBA | 1656 | legacy stage-select art | UNREF | - | EXCLUDED |

#### `root` (1 files)

| File | Dim | Mode | KB | Category | Status | Referenced by | Android |
|---|---|---|---|---|---|---|---|
| `icon.svg` |  | svg | 0 | misc | TOOLS | (tools) test_managers.gd | packaged |

### Other media
* **Fonts:** `assets/fonts/Rajdhani-SemiBold.ttf`, `Rajdhani-Bold.ttf` (SIL OFL, `OFL.txt`) — used by `BeamUI.FONT_REGULAR/FONT_BOLD` and the generated theme.
* **SFX:** `assets/sfx/*.ogg` (22) — Part 15. `addons/admob/assets/music.ogg` is plugin sample content (not game audio).
* **Shaders:** `scripts/ui/beam_button_glow.gdshader` (the sweeping glow on art buttons; `BeamButtonGlow` ColorRect).

---

## PART 12 — UI / MOBILE RESPONSIVENESS

**Design system.** `scripts/ui/beam_ui.gd` (`BeamUI`) is the ONE source of UI tokens: palette (CYAN `#4DDBFF`-ish, BLUE_DEEP, GLASS, TEXT, DANGER, GOLD, SUCCESS), radii (button 20, panel 26), `TOUCH_MIN 96`, `SCREEN_MARGIN 40`, fonts (title 64, button 34, section 30, body 28, small 24; dialog buttons scale 44–80 with viewport width via `bind_dialog_button_fonts`). `themes/beamshift_theme.tres` is **generated** from it (`godot --headless --path . --script res://tools/ui_shots/build_theme.gd`); never hand-edit. Variations: `SecondaryButton`, `DangerButton`, `GhostButton`, `IconButton`, `CardPanel`, `DialogPanel`, `HeaderPanel`, `HudPlate`, `TitleLabel`, `SectionLabel`, `DimLabel`. Font Rajdhani.

**Layout system.** Stretch `canvas_items`/`expand`, 1080×1920 logical minimum; every full screen is `Control` + anchors/containers (no fixed pixel positions for gameplay/menus). `SafeAreaMargin` (`MarginContainer`) = baseline margin (`UIConstants.BASELINE_MARGIN 96` for menus; gameplay horizontal 32, vertical 8) widened on **Android only** by the real display safe-area inset (`DisplayServer.get_display_safe_area()` converted into UI space — handles notches/cutouts/gesture bars) with `maxf()` so a baseline never reduces protection. Gameplay HUD uses `set_hud_overhang`, `GAMEPLAY_TOP/BOTTOM_VISIBLE_GAP = 20`, `GAMEPLAY_STACK_VERTICAL_OFFSET = -30` (whole HUD/board stack lifted up as one unit). Touch targets: `UIConstants.MIN_TOUCH_TARGET 144` (logical px), `BeamUI.TOUCH_MIN 96`, board cells never below `MIN_COMFORTABLE_CELL_SIZE 96`.

**Board layout.** `GridManager._recalculate_layout()` fits `grid_width` columns and `grid_height` rows independently: `cell_size = floor(min(avail_w/cols, avail_h/rows))` minus an 8 px margin, centred, always square. `MAX_COLUMNS = 8` is a ceiling for NEW procedural shapes only (58 legacy levels exceed it and are grandfathered); `is_board_profile_comfortable()` validates a candidate shape. D86/D87 proved a width-bound board cannot grow further on taller phones — residual vertical slack on very tall devices is known and accepted.

**Screens (current implementation):**
* *Main menu* — logo (cropped region of `bs_logo_main_menu_portrait.png`), live board preview of campaign level 3, art buttons (NEW GAME, CONTINUE, TUTORIALS), footer ABOUT/SETTINGS; sizes computed in code (`_layout_hero_elements`) from the viewport; `top_margin_extra/bottom_margin_extra` lift the stack. Quit button was removed (uncommitted).
* *Level select (QA only)* — header + ScrollContainer + 4-col grid; PASS-mouse-filter cards for drag-scroll.
* *Gameplay HUD* — flat `HudPlate` top (`AspectBar` aspect_ratio **6.0** in `game.tscn`: back button, level name ≤13 chars, MOVES) and bottom (**5.2**: HINT, RESET, PAUSE; QA +50 button hidden) bars (**DOC≠CODE:** CLAUDE.md says 6.4 / 5.6; the scene says 6.0 / 5.2 and the code is authoritative); gold hint attention pulse every 5 s.
* *Tutorial* — in-game `TutorialPanel` (instruction label + "TAP TO CONTINUE") + `TutorialHighlight`/`TutorialDimOverlay`; separate Tutorial Select screen.
* *Settings* — AUDIO (Sound/Music toggles), ACCOUNT, ADS & PURCHASES (NO FORCED ADS price button, RESTORE PURCHASES), PRIVACY OPTIONS (UMP; hidden unless required), PRIVACY POLICY, About, version label.
* *About* — plain Labels built from the `CREDITS` const (Publisher Maclepro Inc; studio 4Sagez; Game Direction/Gameplay Systems Praneeth B and Abhilash D; engine line).
* *Completion UI* — `LevelCompletePopup` (stars, moves, best moves, NEXT/RETRY/main-menu buttons); `TutorialCompletePopup`.
* *Purchase UI* — Settings buttons only (no separate screen). *Auth UI* — `account_screen`.

**Layout risks (code-based).** (1) Safe-area widening is unconfirmed on a real notch/cutout device (docs). (2) Level/Tutorial Select grids with 140 / 34 cards rely on a ScrollContainer; drag-scroll was fixed 2026-09-30 and is device-pending. (3) Mastery-band procedural boards are dense; phone readability unverified. (4) Hand-written `.tscn` pitfalls documented in CLAUDE.md (missing `script =` line; instance anchor overrides) — re-check after any scene edit. (5) Settings price label overflow was fixed with a dynamic font — re-verify with other locales/prices. (6) Android Back on many screens is custom (`quit_on_go_back=false`): every new screen needs its own `NOTIFICATION_WM_GO_BACK_REQUEST` handler that starts with `if InternetManager.is_blocking(): return`.

---

## PART 13 — TUTORIAL

* **Entry:** Main Menu → TUTORIALS → `tutorial_select.tscn` → tap a card → `GameManager.start_tutorial(id)` → `game.tscn` in tutorial mode.
* **Data:** `levels/tutorial/t01.gd … t34.gd` (`TutorialLevelData` = LevelData + `steps: Array[TutorialStepData]`). Step types: `MESSAGE` (shows `text`, waits for TAP TO CONTINUE), `REQUIRE_TILE_TAP` (locks input to `target_position`; advances on `move_made`), `WAIT_FOR_TARGET_ACTIVATION` (advances on `simulation_updated` showing the target active), `WAIT_FOR_PUZZLE_SOLVED` (ends the tutorial). Optional `highlight_position`, `lock_all_input`.
* **Engine:** `scripts/managers/tutorial_manager.gd` (RefCounted, owned by `game.gd`, NOT an autoload) is the only code interpreting steps; forced interaction is gated in exactly one place (`GridManager._on_orientable_tile_clicked` via `interaction_locked/interaction_restricted_to`); `REQUIRE_TILE_TAP` fail-safe never locks input to a non-existent tile.
* **UI:** `tutorial_panel.tscn` (bottom-anchored), `tutorial_highlight.gd` ring + `tutorial_dim_overlay.gd` board dim (both coupled 1:1 to `GridManager.set_highlight/clear_highlight`), `tutorial_complete_popup`.
* **Pack:** T01–T10 Era-1 basics; T11–T20 Era-2 mechanics (T11–T20 need campaign level 100 done unless QA); T21–T28 Fusion (unlock at procedural level 150 or after T20); T29–T34 Splitter Selector (unlock at procedural level 1900). Text is in the level files (no image pages; no tutorial images). Hint entries t1–t34 exist in `hint_solutions.json` (hand-authored for T21+).
* **Persistence:** `SaveManager.tutorial_highest_unlocked_level`, `tutorial_completed_levels` (+ `fusion_tutorial_nudge_seen`). NEW GAME preserves all tutorial progress. Replay: any unlocked tutorial can be replayed from Tutorial Select; completion popup offers retry/next/tutorial select. Tutorials are ad-free and never write procedural/campaign progress.
* **Header / Back / scroll history (current state verified in scenes):** `tutorial_select.tscn` has `Header` HBox = `BackButton` (custom_minimum_size 230) + `TitleLabel` (expand) + 230-px `Balance` spacer (keeps the title centred and the Back button un-squeezed), a 3-px `Rule`, then ScrollContainer (`scroll_deadzone 24`, horizontal scroll off) → 4-column grid; cards use `mouse_filter = PASS` so touch drags reach the scroll container. Docs say these fixes (2026-09-30) were RENDERED/desktop-verified and then covered by the RC3 owner device pass ("Tutorial scrolling" listed as confirmed).
* **UI risk:** the T11–T20 unlock gate and QA overrides are `BuildConfig.QA_TOOLS`-driven; the fusion nudge toast (`main_menu.gd`) is one-time.

---

## PART 14 — SAVE SYSTEM

* **Location:** `user://savegame.json` (Android: app-private storage; `user_data_backup/allow=false` so Android auto-backup is OFF). **Format:** one JSON dictionary written non-atomically with `FileAccess.WRITE` on every meaningful change (`save_game()`); `saved` signal.
* **Version:** `SAVE_VERSION := 5`, informational only — every field read with `Dictionary.get(key, default)`, so older saves load with defaults for new fields. **Corruption handling:** missing/unreadable/malformed file → warning + defaults (`_default_data()`); there is **no backup copy and no atomic rename** (a crash mid-write can lose the file — TECHNICAL DEBT).
* **Schema (`to_dict()`):**

| Key | Type | Meaning |
|---|---|---|
| `version` | int | 5 |
| `highest_unlocked_level`, `completed_levels`, `best_moves_per_level`, `best_stars_per_level` | int / dict(str→true/int) | the 15 dev levels |
| `sound_enabled`, `music_enabled` | bool | settings (music has no audio behind it) |
| `campaign_highest_unlocked_level`, `campaign_completed_levels`, `campaign_best_moves_per_level`, `campaign_best_stars_per_level` | | the 140 QA campaign levels |
| `tutorial_highest_unlocked_level`, `tutorial_completed_levels` | | T01–T34 |
| `campaign_resume_level_id`, `campaign_resume_orientations`, `campaign_resume_move_count`, `campaign_resume_hint_used` | | QA/campaign mid-level resume |
| `procedural_current_level` | int | REAL progression pointer (first not-completed procedural level) |
| `procedural_resume_level_number`, `procedural_resume_seed`, `procedural_resume_generator_version`, `procedural_resume_orientations`, `procedural_resume_move_count`, `procedural_resume_hint_used` | | exact mid-level resume for CONTINUE (regenerates the same puzzle under the saved version) |
| `procedural_best_stars` | dict | key `"<level>|<generator_version>"` → best stars (never decreases) |
| `fusion_tutorial_nudge_seen` | bool | one-time nudge |
| `ad_completions_since_interstitial`, `ad_last_interstitial_unix`, `ad_last_counted_level` | int | interstitial pacing |
| `entitlements` | dict | `{"beamshift_no_forced_ads": true}` — local record of the store's answer |
| `age_group` | int | NEW: 0 UNKNOWN, 1 CHILD_12_OR_YOUNGER, 2 TEEN_13_TO_17, 3 ADULT_18_PLUS |
| `play_time_seconds`, `saved_at` | | leftover/informational (kept for compatibility) |

* **Other persisted file:** `user://platform_account.json` (iOS only: `{apple:true, name}`); nothing for Android Play Games (display name is memory-only).
* **Not stored:** achievements, leaderboards, cloud saves, exact age/DOB, authentication tokens, payment data.
* **Reset:** `reset_main_progress_for_new_game()` (NEW GAME) resets main procedural progression/resume/stars and `ad_last_counted_level`; it PRESERVES settings, all tutorial progress (materialising an earned Fusion/Selector tutorial unlock first), `fusion_tutorial_nudge_seen`, QA/legacy populations, interstitial cadence (so NEW GAME cannot dodge ads), entitlements and `age_group`. Restores state if the write fails.
* **Persistence matrix:**

| Event | Progress/settings | Entitlement | age_group |
|---|---|---|---|
| App restart / device restart | kept | kept (and re-checked against Play at launch) | kept |
| App update | kept | kept | kept |
| Uninstall → reinstall | **LOST** (no cloud save, auto-backup off, no Play Games snapshots) | **restored only because Play Billing re-queries owned purchases** (`StoreManager`/`play_billing_backend` on connect, and Restore Purchases) — NOT because of the save | **LOST** (asked again) |
| Clear app data | lost | restored via Play query | lost |



---

## PART 15 — AUDIO

* **Manager:** `AudioManager` autoload (`scripts/managers/audio_manager.gd`) — the only place an SFX path appears (`SFX_TABLE`: event key → `{file, bus, gain_db}`); callers use semantic `play_*()` methods. Pool of **10** `AudioStreamPlayer` voices (round-robin, steals the oldest). Missing/corrupt file → logged once, event silently no-ops. `LevelData` never carries audio.
* **Buses** (`assets/audio/default_bus_layout.tres`): `Master`, `SFX`, `UI` (both send to Master). `set_sound_enabled()` mutes SFX+UI; `set_sfx_volume_linear()` exists for a future slider (no slider UI).
* **SFX (22 `.ogg` in `assets/sfx/`):** ui_button_press (−3 dB), ui_back, ui_level_select, ui_locked, ui_popup, mirror_rotate (−4), mirror_locked, laser_activate, laser_reflect (−3), laser_split, target_activate, target_wrong, filter_pass, portal_enter, portal_exit, switch_activate, gate_open, hazard_hit, puzzle_solved (+1), level_complete (+2), star_appear, tutorial_step.
* **Gameplay gating:** gameplay SFX are called only from `GridManager._simulate_and_draw(play_impacts=true)`, which is `true` only for an accepted player tap — level load/resume/reset/generator/solver are silent by construction.
* **Music:** **no music files exist.** `SaveManager.music_enabled` and the Settings Music toggle exist, but nothing plays music (PLACEHOLDER). `addons/admob/assets/music.ogg` is plugin sample content.
* **Ads:** `AdManager._duck_audio` mutes Master while a full-screen ad is up and restores the previous mute state.
* **Tuning status:** per-SFX gains are "placeholder judgment calls"; **no manual Android audio QA is recorded** (UNVERIFIED on device beyond the owner's general RC3 pass).

---

## PART 16 — ADMOB

| Item | Finding (CODE unless noted) |
|---|---|
| Plugin | Poing Studios **AdMob plugin 5.1.0** (`addons/admob`), wraps Google's **GMA Next-Gen SDK `com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0`** (the legacy `play-services-ads` is excluded in `android/build/build.gradle`). Transitive: `user-messaging-platform:4.0.0` (UMP), `play-services-ads-identifier:18.0.0`, `play-services-appset:16.0.1`, `play-services-cronet:18.0.1`. Bridge AARs `poing-godot-admob-ads-{debug,release}.aar` + `-core`. Poing is only a Godot↔native bridge; ads are requested/served by Google's SDK. No mediation adapters are packaged (only GDScript stubs exist). |
| Wrapper | `AdManager` (autoload) → `AdBackend` interface → `AdBackendAdMob` (Android/iOS) or `AdBackendFake` (tests). Gameplay code never calls an SDK. All ids/switches/constants live only in `scripts/ads/ad_config.gd`. |
| Initialization | `AdManager._ready()` → if `AdConfig.ads_active()` and a mobile platform → `AdBackendAdMob.initialize()`: UMP `update()` with `tag_for_under_age_of_consent = CHILD_DIRECTED` → consent form only if REQUIRED (with child-directed tagging it is normally NOT_REQUIRED) → `_init_sdk()`: builds `RequestConfiguration` (**TFCD TRUE, TFUA TRUE, max rating G**, test device ids) → `MobileAds.set_request_configuration()` → `MobileAds.initialize()`. 8 s UMP timeout falls back to init. SDK init is refused only when consent is still REQUIRED. |
| IDs | `AdConfig.USE_TEST_IDS := not BuildConfig.IS_PRODUCTION_BUILD` — non-production builds use Google's **sample** ids; production builds read ids from `res://config/ad_ids.local.json` (gitignored, written by CI/stamp script). Missing ids ⇒ `ads_active()` false ⇒ no SDK, hints free. Local file currently contains **Android production ids only** (no iOS entry ⇒ iOS ads would be OFF). |
| Application ID | injected at export time into `project.godot` `[admob] general/android/app_id` by `tools/ci/stamp_store_config.sh`; the committed project.godot has no `[admob]` section. |
| Test devices | `config/ad_test_devices.local.json` (gitignored; **1 device id** present). Read by `AdConfig.test_device_ids()`. **Release presets exclude it, "Android Debug" keeps it** (D114). |
| Banner | **none** (no banners, no app-open ads). |
| Interstitial | `AdManager.maybe_show_interstitial_after_completion`: shown only on **Level Complete → NEXT LEVEL** in normal procedural play when `ad_completions_since_interstitial >= 4` AND `>= 120 s` since the last (`AdConfig.INTERSTITIAL_EVERY_COMPLETIONS=4`, `INTERSTITIAL_MIN_SECONDS=120`); counter resets ONLY when one actually shows; not shown after a level where a rewarded ad was opened; never in tutorials/QA sessions/Reset/Retry/Continue; not-ready never blocks progression; second tap while an ad is up is swallowed; audio ducked. |
| Rewarded Hint | `game.gd._hint_permission` → (NEW, uncommitted) **`HintAdDialog` confirmation "GET A HINT? / Watch a short ad to reveal a hint. [CANCEL][WATCH AD]"** when an ad is READY → `_start_rewarded_hint` → `AdManager.show_rewarded_hint(cb)`; hint is granted ONLY from the reward callback (`reward_earned`), at most once per ad; closed-without-reward or show-failure ⇒ no hint; not-ready ⇒ reload + dim feedback, **no free fallback**; double taps return "busy". Tutorials, QA sessions and desktop (no backend) have free hints. |
| Retry/backoff | failed loads retry after 30 s doubling to 240 s; only when `InternetManager.is_online`. |
| Lifecycle | `AdBackendAdMob.release()` from `_exit_tree` empties static callback slots (iOS swipe-away crash fix); every callback is a named method, never a lambda. |
| Child-directed | `AdConfig.CHILD_DIRECTED := true` for every user/age range (Families). The age screen never affects ads (tested). Deprecated TFCD/TFUA APIs are still documented by Google as functional; the Poing 5.1.0 bridge does not expose `setAgeRestrictedTreatment`. |
| **beamshift_no_forced_ads owned** | `AdManager.forced_ads_removed()` reads `SaveManager.has_entitlement("beamshift_no_forced_ads")`. Effects: `maybe_show_interstitial_after_completion` returns false, `load_interstitial` returns early, and on purchase `on_forced_ads_removed()` discards any preloaded interstitial. **Rewarded Hint ads remain available** (owner decision; never label the product "Remove Ads"). No banners exist to remove. |
| Device status | per docs: rewarded Hint and interstitial worked on a physical phone in the RC3 pass (test-device config). Production ads serving is limited until AdMob app review completes ("Requires review"). UNVERIFIED: any build after RC3. |
| Risks | AdMob app review pending; AD_ID permission present (Part 20); a full-screen ad whose SDK never calls dismissed/failed would leave `AdManager.state` stuck (no watchdog); one latent double-advance branch in `maybe_show_interstitial_after_completion` if `show_interstitial()` ever returned false after `has_interstitial()` was true (unreachable today). |

---

## PART 17 — GOOGLE SIGN-IN (current state: REMOVED)

* **Firebase Auth, Firestore/cloud save, the `GodotGoogleSignIn` Credential-Manager plugin, the cloud chooser and Game Center/iCloud code were deleted on 2026-10-01** (commit `3df9252` "Remove Firebase and use platform-native authentication", D118). Grep of `scripts/`, `scenes/`, presets, plugins, CI: **zero** Firebase/GoogleSignIn code. Only tests that assert absence, docs, `references/ci-cd.md`, `tools/ios_plugin_src/README.md` and the stale `project.godot.before_admob_test` mention it.
* **History worth keeping:** Google Sign-In + Firebase worked on sideloaded debug APKs (debug key SHA-1 `F6:B7:C8:8B:89:16:E7:E8:26:78:86:42:70:DD:B3:BE:74:83:D7:A7`), then FAILED on the Play-Internal-Testing install because **Play App Signing re-signs the app with Google's own certificate** (SHA-1 `3C:D2:C8:1D:1A:68:1C:D0:71:A1:83:85:8C:61:43:61:A4:0D:64:28`) which was not registered; the upload-key SHA-1 (`A4:82:77:62:47:1D:00:AE:09:CA:AA:FB:34:20:5B:24:1B:1E:60:5A`) later also had to be registered for locally-signed release APKs. (These are public certificate fingerprints, not secrets.)
* **What this means for THIS project (relevant if any Google OAuth/Play Games config is touched again):**
  * *debug APK* — signed with the Android debug keystore; fingerprint must be registered for Play Games/OAuth to work on it.
  * *locally signed / sideloaded release APK or AAB uploaded* — signed with the **upload key** (keystore stored outside the repo; CI uses `ANDROID_KEYSTORE_*` secrets).
  * *Play-installed build* — re-signed by **Play App Signing**; OAuth/Play Games must trust that certificate.
  * Play Games Services (Part 18) needs the same fingerprints registered in the Play Console / Google Cloud OAuth client linked to the Game ID.
* **Current status:** nothing Google-Sign-In/Firebase-related is pending in code. The brief's "Google Sign-In verification" step is obsolete; the equivalent is Play Games sign-in verification (Part 18).
* **Flow today (Android):** none required. Optional Play Games identity only (Part 37).

---

## PART 18 — GOOGLE PLAY GAMES

| Part | Status | Detail |
|---|---|---|
| Plugin | IMPLEMENTED | `addons/GodotPlayGameServices` **3.4.0** (Jacob Ibanez), `play-services-games-v2:21.0.0`; autoload `GodotPlayGameServices`; export plugin writes `game_services_project_id` into Android strings and adds `com.google.android.gms.games.APP_ID` meta-data |
| Game ID | **CONFIGURED OUTSIDE SOURCE** | `godot_play_game_services/game_id=""` in both Android presets (committed empty on purpose). CI stamps `PLAY_GAMES_GAME_ID`; the owner's Game ID is `516411257761` (used in the test APKs I built; stored in resources as `game_services_project_id`). **A real Android export FAILS while it is empty** (AAPT resource error). NEEDS PLAY CONSOLE CONFIGURATION for fingerprints/OAuth/testers. |
| Authentication | IMPLEMENTED, NEEDS DEVICE TEST | `PlatformAccount` (Android): `apply_age_group()` starts Play Games ONLY for TEEN/ADULT age ranges; then a silent `is_authenticated()` at launch; `sign_in()` only when the player presses CONNECT/RETRY on the Account screen; display name via `PlayersClient.load_current_player` kept in memory only. For UNKNOWN and CHILD_12_OR_YOUNGER BeamShift's own code never initializes/authenticates (tested). **Caveat:** the library registers its own `PlayGamesInitProvider` at process start, outside GDScript control; what it does alone is unverified. |
| Achievements / leaderboards / snapshots / events | **NOT IMPLEMENTED** | plugin wrappers exist in addons but no game script calls them |
| Callbacks | `user_authenticated`, `current_player_loaded` | failures only set `last_message`; sign-in failure never blocks play and is NOT an internet failure |
| Status of verification | Older Play Games checks happened in the Firebase era; no explicit device verification record for the post-Firebase `beamshift-playgames-test.apk` | UNVERIFIED |

---

## PART 19 — GOOGLE PLAY BILLING / IAP

* **Plugin:** `addons/GodotGooglePlayBilling` 3.3.0 (`BillingClient.gd`); backend `scripts/store/play_billing_backend.gd` (loaded by path only on Android by `StoreManager`); iOS `store_kit_backend.gd` (StoreKit 2 via a GDExtension that CI downloads — never vendored).
* **Product:** `beamshift_no_forced_ads` (`StoreConfig.NO_FORCED_ADS`) — **non-consumable, one-time**; store purchase option `no-forced-ads-lifetime` (per docs); fallback display price `$3.99` (live price comes from Play; docs record ₹450.00 retrieved on a real device in India). IDs can never be reused/renamed.
* **Flow (CODE):** `StoreManager._ready` loads the backend → `BillingClient.start_connection()` → on connect: `query_product_details` + `query_purchases(INAPP)` → `can_purchase()` true only when connected AND price known → `purchase(product_id)` → Play sheet → `on_purchase_updated` → `_scan_purchases` → `PURCHASED` ⇒ `ownership_known(owned, authoritative=false)` and **acknowledge** (`acknowledge_purchase` for unacknowledged tokens; Play auto-refunds after 3 days otherwise) → `SaveManager.set_entitlement(id, true)` → `AdManager.on_forced_ads_removed()`.
* **Restore / reinstall:** `restore_purchases()` and every connect run `query_purchases`; a full query result is **authoritative**: owned ⇒ granted, **absent ⇒ entitlement revoked** (refund/revocation) — a failed/offline query never revokes. `ITEM_ALREADY_OWNED` triggers restore. Reinstall restoration therefore comes from Play, not from the save.
* **Pending purchases:** `PurchaseState.PENDING` ⇒ `purchase_pending` ⇒ message "Your purchase is pending approval. It will unlock automatically." **Cancelled** ⇒ silent. **Failed/unavailable** ⇒ player-facing messages (`MSG_*` in `store_manager.gd`). Auto-reconnect every 20 s after disconnect.
* **UI:** Settings → ADS & PURCHASES: NO FORCED ADS button (price/OWNED, disabled while busy) and RESTORE PURCHASES; status messages.
* **Evidence ladder:**
  * CODE IMPLEMENTED: yes (full flow above).
  * LOCAL/AUTOMATED TESTED: `test_store.gd` (5), `test_store_backends.gd` (2) using `tools/tests/fakes/fake_store_backend.gd` — covers grant, revoke, pending, failure, restore logic against fakes.
  * ANDROID TESTED (documented): the live localized price was retrieved on a real device from a Play Internal-Testing install (build 10001) — proves product + console wiring. **No documented completion of:** actual purchase, acknowledgement, restart persistence, Restore Purchases, reinstall restoration, refund/revocation, interstitials-stop-after-purchase on a device. The manual checklist A–F exists in STORE_RELEASE.md and is marked not run.
  * PLAY INTERNAL TESTING VERIFIED: price retrieval only.
  * NOT VERIFIED / MISSING: everything else above; iOS StoreKit entirely (no device, CI path unexecuted per docs).

---

## PART 20 — ANDROID CONFIGURATION

| Item | Value |
|---|---|
| Package | `com.foursagez.beamshift` |
| versionCode / versionName | 10004 / 1.0.1 (both presets); CI stamps `major*10000+minor*100+patch` (1.0.6 → 10006) |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 (Gradle template `android/build/config.gradle`; presets leave min/target empty = Godot defaults); AGP 8.6.1, Kotlin 2.1.21, JDK 17, NDK 29, build-tools 36.1.0 |
| Architectures | armeabi-v7a + arm64-v8a (x86/x86_64 off) |
| Build type | Gradle build (`use_gradle_build=true`), APK for "Android Debug" (`export_format=0`), AAB for "Android" (`export_format=1`), `compress_native_libraries=true` |
| Orientation | portrait (project setting) |
| Screen | immersive_mode true, edge_to_edge false, supports small→xlarge |
| Auto backup | `user_data_backup/allow=false` |
| Permissions declared by preset | `INTERNET` only |
| **Merged permissions in the RELEASE AAB** (`beamshift-1.0.1-10005-internal.aab`, parsed from its proto manifest) | `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_BASIC_PHONE_STATE` (Next-Gen SDK), `com.android.vending.BILLING`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `<pkg>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, `com.google.android.gms.permission.AD_ID` (ads-mobile-sdk / ads-identifier) **and** the non-standard `android.permission.AD_ID` (Poing bridge AAR). No location, camera, mic, contacts, storage. No `debuggable`. Contains `PlayGamesInitProvider`. |
| Billing requirement | `BILLING` permission via plugin; products must exist & be ACTIVE in Play Console (confirmed by owner for `beamshift_no_forced_ads`) |
| AdMob requirement | `com.google.android.gms.ads.APPLICATION_ID` meta-data (stamped; confirmed `ca-app-pub-2730…~7269770832` style production id in the test APKs I built — not repeated in full here) |
| Play Games requirement | `com.google.android.gms.games.APP_ID` meta-data + non-empty Game ID at export |
| Signing | presets carry **empty** keystore fields; signing comes from environment/CI secrets (`ANDROID_KEYSTORE_B64/PASSWORD/USER`) or the local Godot editor settings; `*.keystore/*.jks` are gitignored. Upload key SHA-1 `A4:82:77:…:60:5A` (documented). Debug-signed APKs are what the test APKs use. |
| CI | `.github/workflows/release.yml` ("Release CD"): `guard` job + `android-play` job (builds signed AAB + APK as private Actions artifacts; **never uploads to Play**) + `ios-appstore` job (macOS, signed IPA, TestFlight upload via ASC key on tags/manual). GitHub Releases are deliberately NOT used (repo is public). Secrets referenced: ADMOB_{ANDROID,IOS}_{APP,REWARDED,INTERSTITIAL}_ID, ANDROID_KEYSTORE_*, PLAY_GAMES_GAME_ID, APPLE_TEAM_ID, ASC_*, IOS_DIST_CERT_*, IOS_PROVISIONING_PROFILE_B64 (names only). |
| Export filters | see Part 21 |

---

## PART 21 — EXPORT_PRESETS.CFG

* **Presets:** `[preset.0]` "Android Debug" → `builds/android/beamshift-debug.apk` (the *runnable* preset); `[preset.1]` "Android" → `builds/android/beamshift.aab` (release AAB); `[preset.2]` "iOS" → `builds/ios/BeamShift.ipa` (bundle `com.foursagez.beamshift`, min iOS 17, arm64, `ITSAppUsesNonExemptEncryption=false`, Sign in with Apple entitlement only, Game Center/iCloud/push off, **all privacy collected-data declarations false, tracking off**, version 1.0.0 / 10000).
* **export_filter** = `all_resources` for all three, with `exclude_filter` of 71 (Debug), 72 (Android release), 71 (iOS) patterns. Excluded: `tools/**`, `docs/**`, `scripts/tools/**`, `levels/editor_fixtures/**`, `_qa_tmp/**`, `assets/gameplay/pieces/**`, `assets/gameplay/tiles/**`, every unreferenced 1254² source tile (mirror/target/blocker/hazard/gate/grid/emitter/filter/portal/splitter/switch), unused Era-2 UI/FX/grid art, legacy UI icon/panel sets, pre-V2 backgrounds, `assets/branding/bs_app_icon_ios_1024.png` (Android only). The release Android preset additionally excludes `config/ad_test_devices.local.json`; "Android Debug" keeps it; **`config/ad_ids.local.json` is never excluded** (production ids are read at runtime).
* **Historical asset-export problem (D51 / "Missing Tile Fix"):** blocker/hazard art lived under the export-excluded `pieces/` folder and so was missing on real Android builds. **Current verification (this audit):** a cross-check of every production-referenced image against all three exclude lists found **zero** referenced assets excluded from Android (the single hit is the iOS icon referenced by the iOS preset itself). The 13 unreferenced-but-packaged files are listed in Part 11. A reliable technique recorded in CLAUDE.md: judge exports by `unzip -l`/`aapt2 dump` of the real APK, not `--export-pack`.
* Other keys: `package/retain_data_on_uninstall=false`, adaptive icon uses `bs_app_icon.png` as foreground only (background/monochrome empty), `gesture/swipe_to_dismiss=false`, `script_export_mode=2` (compressed GDScript).

---

## PART 22 — BUILD HISTORY (artifacts present in `builds/android/`, all gitignored; sizes/dates from disk, version info read with `aapt2`)

Legend — **DEVICE-VERIFIED (docs)** = documented owner physical-device validation; **BUILT/UNKNOWN** = built, no verification record; **HISTORICAL** = superseded; **AAB** has no `debuggable`.

| Date (2026) | File | vc / vn | Type | Status / purpose |
|---|---|---|---|---|
| 09-26 | `beamshift-external-test.apk` | 70 / 4.8.4 | debug | HISTORICAL external-test cleanup build |
| 09-28 | `beamshift-internet-test.apk`, `-runtime-internet-test`, `-main-menu-test`, `-main-menu-v2-test`, `-splash-test` | 10000 / 1.0.0 | debug | HISTORICAL UI/internet-gate experiments |
| 09-28 | `beamshift-firebase-account-test.apk`, `-account-ui-fix-test`, `-google-signin-test`, `-google-signin-plugin-fix-test` | 10000 / 1.0.0 | debug | HISTORICAL (Firebase/Google Sign-In era; removed 10-01) |
| 09-28 | `beamshift.aab` | 10001 | AAB | **uploaded to Play Internal Testing by the owner and installed on a real device via Play** (docs, STORE_RELEASE §16–17); Google Sign-In failed there due to the Play App Signing cert gap (since removed from the product) |
| 09-30 | `beamshift-tutorial-ui-fix.apk`, `-tutorial-header-fix` (10002), `-about-scroll-qa` (10003), `-internal-qa-testads` (10003) | 10000–10003 | debug | HISTORICAL QA builds for About/Tutorial/Level-Select scroll fixes |
| 09-30 | `beamshift-internal-10002.aab` | 10002 | AAB | built, NOT uploaded (docs) — HISTORICAL |
| 09-30 | `beamshift-1.0.0-rc.apk` / `beamshift-1.0.0-10004.aab` | 10004 / 1.0.0 | release-signed APK / AAB | HISTORICAL RC |
| 09-30 | `beamshift-android-admob-rc.apk`, `-testdevice-rc`, `-testdevice-rc2` | 10004 / 1.0.1 | release-signed APK | iterations toward RC3 |
| 09-30 | **`beamshift-android-admob-googleauth-rc3.apk`** | 10004 / 1.0.1 | release-signed APK (not debuggable) | **DEVICE-VERIFIED (docs): owner confirmed on a physical phone** — Google Sign-In + Firebase (since removed), AdMob test-device config, rewarded Hint, interstitial, normal production progression, About Us, Tutorial scrolling, latest UI fixes; no QA controls visible. = the "approved source state" at that time |
| 09-30 | `beamshift-1.0.1-10004-internal.aab` | 10004 / 1.0.1 | release AAB | final Internal Testing AAB of that era, LOCAL ONLY, NOT uploaded (docs) |
| 10-01 | `beamshift-ui-redesign.apk` ×4, `-no-firebase`, `-playgames-test`, `-internet-required`, `-internet-playgames`, `-main-buttons-test`, `-wide-buttons-test`, `-preview-polish-test`, `-settings-ui-test` ×2, `-pause-ui-test`, `-input-fix-test`, `-resume-glow-test`, `-glow-newgame-test`, `beamshift-debug.apk`, `-main-glow-match-test`, `-back-buttons-test` | 10004 / 1.0.1 | debug | **BUILT/UNKNOWN** — rapid UI-redesign / Firebase-removal / internet-gate iterations (commit messages such as "Device UI fix" show owner device feedback, but no explicit verification record) |
| 10-02 | `beamshift-dialog-buttons-test.apk`, `-release-blocker-fix`, `-production-config-test` (production AdMob ids + test device, debug-signed) | 10004 / 1.0.1 | debug | BUILT/UNKNOWN |
| 10-02 02:01 | **`beamshift-1.0.1-10005-internal.aab`** | 10005 (from filename; manifest parsed OK, not debuggable) / 1.0.1 | release AAB | **UNKNOWN purpose/upload state — no doc mentions 10005**; presets still say 10004 (CI stamps). Contains the same permission set; 145 MB (vs 123 MB for earlier AABs) |
| 10-02/03 | `beamshift-hud-test.apk`, `-privacy-policy-test`, `-families-ui-test`, **`-families-policy-test`** (newest, 10-03 14:39) | 10004 / 1.0.1 | debug, production config + test device | BUILT, **device verification PENDING**; `families-policy-test` = latest source incl. age screen, Hint confirmation and updated privacy policy |

Also: `beamshift-debug-test.apk.idsig`, `beamshift-debug.apk.idsig` (v4 signature sidecars). `builds/` totals 7.3 GB — nothing there is committed.

**Never built/never run per available evidence:** an iOS IPA from the repo (the macOS CI lane is prepared; docs call it never-executed as of 2026-09-29, no later record of a run), any build after the Families changes as an AAB, any Play Production release.

---

## PART 23 — QA / DEBUG / PRODUCTION FLAGS

| Flag | File | Current value | Effect |
|---|---|---|---|
| `BuildConfig.BUILD_MODE` | `scripts/managers/build_config.gd` | **`MODE_PRODUCTION`** (committed; never commit another) | derives `IS_PRODUCTION_BUILD` true, `QA_TOOLS` false |
| `BuildConfig.QA_TOOLS` | same | false | root of every QA UI/unlock flag |
| `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`, `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING`, `SHOW_PROCEDURAL_QA_NEXT_BUTTON` (+50), `SHOW_V3_PROTOTYPE_QA`, `SHOW_FUSION_TEST_QA`, `SHOW_SELECTOR_TEST_QA`, `SHOW_V5_TEST_QA` | `level_manager.gd` | all `= BuildConfig.QA_TOOLS` → false | hide Level Select (QA), +50, V3/FUSION/SELECTOR/V5 TEST, unlock-all |
| `UIConstants.ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET` | `ui_constants.gd` | = QA_TOOLS | QA-only HUD offset experiment |
| `game.gd` | QA debug label, generator tag ("V4/V5 band") | visible only if `QA_TOOLS` | |
| `AdConfig.USE_TEST_IDS` | `ad_config.gd` | `not IS_PRODUCTION_BUILD` → false | production never uses Google sample ids |
| `AdConfig.QA_BYPASS_REWARDED` | `ad_config.gd` | false | hints skip ad only if true |
| `LevelManager.USE_V3_FOR_PROCEDURAL_QA`, `USE_FUSION_PROGRESSION_FOR_QA` | `level_manager.gd` | **`true` (not tied to QA_TOOLS)** | choose generator V4 for new play ≤2000 — a gameplay rollout decision despite the "QA" name |
| `EraTheme.UNIFIED_BLUE_THEME_ONLY` | `era_theme.gd` | true | forces blue skin |
| `AdConfig.ADS_ENABLED` | `ad_config.gd` | true | master ad switch |
| `tools/ci/set_build_mode.sh internal_qa` | CI/dev | – | flips to QA mode; restore before commit |

**Can dev-only content leak into production?** By code: no — every QA control derives from the single `QA_TOOLS` constant, the committed mode is production, `scripts/tools/**`, `tools/**`, `levels/editor_fixtures/**` are export-excluded, and the owner confirmed no QA controls on the RC3 device. Residual items: one `print("[Ads] AdMob test devices configured: N")` in `ad_backend_admob.gd` (logcat only); `Android Debug` APKs deliberately ship the test-device JSON (owner devices only); the "QA"-named generator flags are always true.



---

## PART 24 — GIT FORENSIC AUDIT (read-only commands only)

* **Current branch:** `dev_abhilas` (== `origin/dev_abhilas`). **HEAD:** `c2c7752e64136a174f76add4dc899fb9c3781ac7` — "Add GitHub Pages nojekyll marker" (AbhilashDeva, 2026-10-03 09:42 +0530). 30 commits total.
* **Branches:** `main` = `f8a2e6f` (also `origin/main`; **11 commits behind** `dev_abhilas`, 0 ahead); `master` `d9244db` (old, 24 commits not in HEAD — legacy); `Dev_Abhilash` `afc95f0` (old, 1 commit not in HEAD); `beamshift-production-prep` `8bfb1a2` (old, 25 commits not in HEAD). Everything of current relevance is on `dev_abhilas`. `git stash list` empty, no tags.
* **Working tree was ALREADY DIRTY before this handoff file was created.** No staged changes. **19 modified tracked files:** `ADS_MONETIZATION.md`, `CLAUDE.md`, `PRIVACY_AUDIT.md`, `STORE_RELEASE.md`, `docs/privacy-policy/index.html`, `scenes/gameplay/game.tscn`, `scenes/ui/main_menu.tscn`, `scripts/gameplay/game.gd`, `scripts/managers/internet_blocker.gd`, `scripts/managers/platform_account.gd`, `scripts/managers/save_manager.gd`, `scripts/store/store_config.gd`, `scripts/ui/main_menu.gd`, `scripts/ui/privacy_policy_text.gd`, `scripts/ui/studio_splash.gd`, `tools/tests/cases/test_game_session.gd`, `tools/tests/cases/test_privacy_policy.gd`, `tools/tests/cases/test_ui_account.gd`, `tools/ui_shots/ui_shots.gd`. **11 untracked:** `project.godot.before_admob_test` (stale backup), `scenes/ui/age_selection.tscn`, `scripts/managers/age_group.gd(.uid)`, `scripts/ui/age_selection.gd(.uid)`, `scripts/ui/hint_ad_dialog.gd(.uid)`, `tools/tests/cases/test_families.gd(.uid)`, `tools/tests/coverage_report.html`. This audit then adds one more untracked file: `docs/BEAMSHIFT_MASTER_HANDOFF.md`.
* **What the uncommitted work is:** (a) gameplay HUD enhancement + Quit-button removal on the main menu (`game.tscn`, `main_menu.tscn/.gd`, `game.gd`), (b) privacy-URL / native privacy policy work (`store_config.gd`, policy text/HTML/tests/docs), (c) Families hardening: Android neutral age screen + `AgeGroup` + Play Games gating + rewarded-Hint confirmation dialog (+ 20 tests), (d) `internet_blocker.gd` Back-guard tweak. **All of this is NOT committed and NOT in `origin/dev_abhilas`.**

### Commit history (oldest → newest) with what each did
| Date | Hash | Subject | Meaning |
|---|---|---|---|
| 09-25 | f0f38d5, 3369b01 | .gitignore, "Initial Project" | repo start (Sreeharry created .gitignore) |
| 09-25 | 20c2947 | BeamShift full project checkpoint | **the whole pre-Git development history lands here** (core, 15 dev levels, editor/solver, 140 campaign levels, tutorials T01–T28, Era 2, procedural V1–V4, audio, hints, ads foundation, Fusion…). Only docs preserve the earlier chronology. |
| 09-25 | 36fc104, acbdd2e | Splitter Selector mechanics, S3 | Selector mechanic + generator V5 (Levels 2001–3000) |
| 09-26 | b50be41, c3d673f, 9d8c7b2 | S4 external-test cleanup, S3, "S_3 playetest" | `BuildConfig` modes, V5 playtests |
| 09-26 | 9b0a1c4, 92c01ea | production prep; production AdMob IDs + internal-testing build | CI stamping, store config |
| 09-28 | 5a66539, 0d5b42d | Firebase cloud save + Google Sign-In + internet gate; v10001 internal testing release | (since reverted in spirit by D118) |
| 09-29 | a33e02b | Verify Google Sign-In and Firebase Cloud Save on Play Store build | root-cause fix in console, no code |
| 09-30 | 0fc37a5, 3b85776, 44fdcee, e8f3e77, af63fa0 | iOS release pipeline, TestFlight path, Game Center/iCloud dropped | CI for iOS |
| 10-01 | f8a2e6f | main menu polish + automated coverage suite | `tools/tests` introduced (this is also `origin/main`) |
| 10-01 | 7762edf, d7d6ef8, 866c467, e359127 | complete UI redesign (BeamUI), main-menu refinements, device UI fixes | design system + flat HUD |
| 10-01 | 3df9252 | **Remove Firebase; platform-native authentication** | D118; `PlatformAccount` |
| 10-01 | f9cf633 | **Require an active internet connection: global InternetBlocker** | mandatory-internet gate |
| 10-02 | f7e88fb | finalize production UI and release readiness | art buttons + Back guards + export filter fixes |
| 10-02 | 7b160da, 71062bd | manual Android + automatic TestFlight release config; disable public GitHub binary releases | CI policy |
| 10-03 | 02c8069, c2c7752 | Add BeamShift privacy policy; GitHub Pages nojekyll marker | `docs/privacy-policy` |

---

## PART 25 — DOCUMENTATION AUDIT

37k lines of Markdown. **Rule from CLAUDE.md: if a document and the code disagree, the code wins.**

| Path | Lines | Purpose | Currency | Conflicts / notes |
|---|---|---|---|---|
| `CLAUDE.md` | 1,553 | permanent AI-session rules, per-feature standing rules (Era 2, procedural, difficulty, hints, ads, store, Fusion, Selector, V5, identity, privacy, production build, Families hardening) | **MOSTLY CURRENT** (edited through 2026-10-03) | header "Current phase S3.1 NEXT / nothing from S1–S3 committed / do not build" is **stale**; HUD plate aspects 6.4/5.6 vs scene 6.0/5.2 |
| `PROJECT_HANDOFF.md` | 2,486 | older handoff briefing + milestone narrative | OUTDATED (last big update 09-30; still shows Firebase) | superseded by this file |
| `CURRENT_STATUS.md` | 2,395 | status snapshot + milestone history | OUTDATED top (RC3 / Firebase-live narrative) | says Google Sign-In/Firebase live; code removed them |
| `ARCHITECTURE.md` | 2,230 | deep architecture (laser algorithm, layout, save, tutorials, eras, procedural, hints, ads…) | MOSTLY CURRENT for gameplay; ~96 Firebase/CloudSave mentions are **historical** | no section for PlatformAccount/InternetBlocker/age screen |
| `DECISIONS.md` | 7,417 | decision log D1…D118 | CURRENT through D118 | **no entry** for InternetBlocker, UI redesign, privacy policy, Families/age screen/Hint confirmation (those live only in CLAUDE.md, STORE_RELEASE.md, PRIVACY_AUDIT.md, ADS_MONETIZATION.md) |
| `CHANGELOG.md` | 3,545 | dated change log | current to 10-01 | missing Oct 2–3 items except one Families mention |
| `ROADMAP.md` | 678 | milestones | OUTDATED | |
| `TEST_PLAN.md` | 7,045 | manual + automated test plans, checklists | PARTLY OUTDATED (68 Firebase mentions) | manual IAP/device checklists remain useful |
| `README.md` | 381 | overview | **OUTDATED** (says versionCode 70 / 4.8.4, S4 pass 1) | |
| `NEXT_AI_PROMPT.md`, `NEXT_CLAUDE_PROMPT.md` | 141 / 2,266 | tool-independent continuation prompts | **OUTDATED** (S3.1 phase, HEAD `20c2947`) | contradict git history |
| `CAMPAIGN_DESIGN.md` | 1,684 | 140-level campaign design/architecture | CURRENT (design reference) | |
| `ERA_2_DESIGN.md` | 645 | Era 2 mechanics rules, T11–T20 | CURRENT | |
| `PROCEDURAL_GENERATION.md` | 1,265 | generator architecture, V3/V5, audits | CURRENT through D112 | |
| `TUTORIAL_SYSTEM.md` | 445 | tutorial architecture | CURRENT (one-line "T01–T10" comments stale) | |
| `LEVEL_EDITOR.md` | 270 | editor usage | CURRENT | |
| `AUDIO_SYSTEM.md` | 317 | audio architecture/QA list | CURRENT | |
| `ADS_MONETIZATION.md` | 199 | AdMob foundation, ids, rules, Hint confirmation | CURRENT (edited 10-03, uncommitted) | |
| `STORE_RELEASE.md` | 1,776 | store release playbook, checklists, history | CURRENT in tail; middle is Firebase-era history | records "Families declaration NOT submitted; Play Console setup NOT complete" |
| `PRIVACY_AUDIT.md` | 56 | privacy audit table + Families update | CURRENT (10-03, uncommitted) | |
| `references/ci-cd.md` | 273 | iOS CI/CD architecture | PARTLY OUTDATED (mentions Firebase) | |
| `tools/tests/README.md`, `levels/campaign/README.md`, `tools/ios_plugin_src/README.md` | 44/45/107 | local READMEs | CURRENT | |
| `project.godot.before_admob_test` (not a doc) | – | stale backup | LEGACY | still lists CloudSave/FirebaseAuth autoloads |

**Documented-vs-code disagreements found (code wins):** (1) Firebase/Google Sign-In/cloud save described as live in README/CURRENT_STATUS/PROJECT_HANDOFF/NEXT_* vs deleted in code; (2) version 70/4.8.4 (README) vs 10004/1.0.1 (presets); (3) `project.godot` `config/version=1.0.0` vs presets `1.0.1`; (4) HUD aspect 6.4/5.6 (CLAUDE) vs 6.0/5.2 (scene); (5) "nothing committed / HEAD 20c2947" vs 30 commits; (6) `tutorial_select.gd` header says T01–T10 but shows 34; (7) CLAUDE.md "Do not build an APK" in NEXT_AI_PROMPT vs APKs built daily afterwards (the standing rule today is user-directed: APK first, no AAB until approved).

---

## PART 26 — TEST SUITE

* **Framework:** custom GDScript runner `tools/tests/test_runner.tscn` + `test_case.gd` (assert helpers `ok/eq/near/ne`, `frames()`, `watch()`, `solve_by_taps`, `reset_scene`). **Dev-only, export-excluded.** Run: `powershell -ExecutionPolicy Bypass -File tools/tests/run_coverage.ps1 [-Filter name] [-SkipQa]` (needs `godot --headless --editor --import` once after new class_name scripts). It copies the project to `%TEMP%`, instruments `scripts/**` + `levels/**` for statement coverage, isolates `user://`, and runs a **production pass** (all tests) plus an **internal-QA pass** (flips `BuildConfig` to `MODE_INTERNAL_QA` in a second copy; subset `ui_screens,game_session,game_flow,managers`). Any `SCRIPT ERROR` fails the run; 150 s watchdog.
* **Results (I ran them this session, after the latest changes):** **PASS** — production **152 tests, 0 failed, 3,681 assertions**; QA pass **34 tests, 0 failed, 221 assertions**; statement coverage ~91.3% (production) / 92.0% (merged), `scripts/ads` 93%, `gameplay` 97%, `managers` 92%, `procedural` 94%, `store` 86%, `tools` 81%, `ui` 83%; `levels/**` 100%.
* **Per file (test funcs):** test_ad_backend_admob 3, test_ads 8, test_core_logic 15, test_dev_tools 8, test_families 20, test_game_flow 5, test_game_session 11, test_grid_types 1, test_internet_required 16, test_levels_bulk 3, test_managers 8, test_privacy_policy 10, test_procedural 8, test_procedural_units 4, test_save_manager 8, test_store 5, test_store_backends 2, test_tiles 2, test_ui_account 5, test_ui_screens 10 = **152**.
* **Covers:** every level file through the real simulator/validator/solver (bulk), laser/tiles, save/migration/NEW GAME, level & tutorial flows (all 34 tutorials played step-by-step), game sessions, ads (fake backend + AdMob wrapper), store (fake backend), InternetBlocker/Back guards, privacy policy (text ↔ HTML sync), Account screen, UI screens, procedural generation units, age screen + Hint confirmation (new).
* **Not covered / cannot run headless:** real touch input (CLAUDE rule 12a), real Android Play Billing/AdMob/Play Games, notch/safe-area, audio loudness, iOS, pixel layout (`tools/ui_shots` renders by hand), the long generator audits (banned by default), full re-solve of all 140 campaign levels with the exhaustive solver, GDExtension/StoreKit.
* Status labels: PASS = above; REQUIRES ANDROID = real billing/ads/Play Games/IME/back button; REQUIRES PLAY SERVICES = Play Games sign-in, billing; NOT RUN = full solver audits, iOS CI.

---

## PART 27 — BROKEN REFERENCES / ERRORS / WARNINGS

* **Scan:** 543 `res://` literals in scripts/scenes/resources/config/CI were resolved against disk. **Missing: none in production code.** Non-issues flagged by the scan: `tools/level_editor/level_editor.gd/.tscn` default save names (`res://levels/level_16.tres`) are *future output paths*, `tools/tests/cov.gd` (`res://cov_map.json` runtime artifact), `test_ui_account.gd` (negative assertions that firebase files do NOT exist).
* **Parse/runtime:** headless import (`--editor --import`) and the full suite ran with **no SCRIPT ERROR / parse error**.
* **TODO/FIXME/HACK:** none in scripts/scenes/tools (only an "XXXXXXXXXX" placeholder in a shell comment).
* **Placeholders:** 5 tiles use procedural `_draw()` (by rule 10, intentional); "Placeholder" comments in `emitter/filter/portal/switch.gd`; per-SFX gains are placeholder judgment calls; Music toggle has no music; `StoreConfig.FALLBACK_PRICES` `$3.99` is a fallback.
* **Obsolete/inert:** `physics/3d/physics_engine="Jolt Physics"` unused; `AdBackendFake` test-only; `project.godot.before_admob_test`; `tools/tests/coverage_report.html` (untracked artefact).
* **Config risks:** empty `game_id` in presets (intended; CI/test stamping); `config/ad_ids.local.json` has no iOS ids; deprecated Google TFCD/TFUA API still used (works).
* **Export sanity:** 13 unreferenced-but-packaged images (Part 11); `android.permission.AD_ID` (non-standard, from Poing AAR) present beside the real `com.google.android.gms.permission.AD_ID`.

---

## PART 28 — CURRENTLY WORKING FEATURES (conservative evidence labels)

Legend: **C** confirmed by current code · **T** confirmed by automated test · **D** documented as previously Android-verified (owner, RC3 pass; Firebase era) · **N** implemented, needs device verification · **U** uncertain.

| Feature | Evidence |
|---|---|
| Deterministic laser simulation, all 17 tile types | C, T |
| Tap-to-rotate (2-state and 4-state), move counting, reset | C, T, D (basic) |
| Win detection, stars (StarScoring), best-stars-never-decrease | C, T |
| Procedural levels 1–3000 deterministic & versioned; resume exactly | C, T; D for normal progression |
| All 140 campaign levels + 15 dev levels load and simulate | C, T (bulk) |
| Tutorials T01–T34 playable end-to-end with forced-tap steps | C, T (all 34 played in `test_game_session`); D for T01–T10 scrolling |
| Hint ring (one tile) incl. attention pulse | C, T; D (rewarded Hint) |
| Rewarded Hint via AdMob | C, T (fake); D (RC3 device) ; confirmation dialog: C, T, **N** |
| Interstitial every 4 completions / 120 s at Next Level | C, T; D (RC3) |
| No Forced Ads gating of interstitials; rewarded Hint kept | C, T (fake store) ; purchase on device **N** |
| Purchase, acknowledge, restore, reinstall restore, refund revocation | C (code), T (fakes); device **N** (only price retrieval documented) |
| Local save, NEW GAME confirmation + reset, Continue | C, T; D |
| Mandatory internet gate + Back guards | C, T; D? (built 10-01; no explicit verification) → **N** |
| Age screen (Android), Play Games gating, local age persistence | C, T; **N** |
| Play Games optional sign-in (13+) + display name | C, T (callbacks); **N** |
| Privacy policy native screen + web copy + Settings entry | C, T; web deploy was pending at last check |
| Settings (sound toggle, privacy options, policy, about) | C, T; D (earlier) |
| About Us | C; D (RC3) |
| Level Select drag-scroll, Tutorial Select header/scroll | C; D (RC3) |
| Audio SFX (22 events), ducking during ads | C, T; no dedicated device audio QA |
| Unified blue theme; Era-2 skin inactive | C, T |
| Safe-area handling on notch devices | C; **U** (docs: unconfirmed on a real cutout device) |
| iOS (Sign in with Apple, StoreKit, TestFlight CI) | C (code); **U/N** (no macOS/device evidence) |

---

## PART 29 — CURRENTLY INCOMPLETE / PENDING (verified, not assumed)

### MUST FIX (repo/code/config)
1. **Commit hygiene:** ≈30 uncommitted entries incl. the whole Families/age-screen/Hint-confirmation/privacy-policy work and HUD/Quit changes (`origin/dev_abhilas` lacks them). Nothing was committed in this audit.
2. **Version alignment:** presets 10004/1.0.1 vs project 1.0.0 vs an undocumented `…10005` AAB; decide the next release version (CI stamps from a tag/typed version).
3. **Decide `PlayGamesInitProvider`** handling (library starts at process launch; unverified behaviour for under-13) — possible manifest `tools:node="remove"`.
4. **Decide AD_ID permission** (both `com.google.android.gms.permission.AD_ID` and non-standard `android.permission.AD_ID` are merged) for Families/Data-safety consistency.
5. **Full-screen-ad watchdog** (no timeout if the SDK never calls dismissed/failed) and the latent double-advance branch in `AdManager`.
6. **Save robustness:** non-atomic write, no backup.
7. Docs refresh (README/CURRENT_STATUS/PROJECT_HANDOFF/NEXT_* are stale; DECISIONS lacks Internet gate/UI redesign/Families entries).

### MUST TEST (physical Android device)
* Age screen first-launch flow, all three choices, Back behaviour, restart persistence; Play Games NOT starting for under-13; Play Games optional sign-in for 13+.
* Rewarded Hint: CANCEL, WATCH AD, close-without-reward, offline, repeated taps, No-Forced-Ads-owned case.
* Interstitial cadence and Next-Level continuity after a real ad.
* IAP checklist A–F (purchase, ads stop, restart, Restore, reinstall, refund) on a Play-installed licensed-tester build.
* Mandatory-internet blocker on a real device (airplane-mode toggle mid-level; Back button under the gate).
* Privacy policy screen scroll/Back; Settings; About; Level/Tutorial Select scroll; notch/cutout safe-area; HUD on tall (20:9+) phones; Mastery-band board readability; audio levels.
* A clean install of the exact AAB that will be uploaded (Play-installed, not sideloaded).

### PLAY CONSOLE CONFIGURATION (owner)
* **Target audience & content (Families) declaration — NOT submitted** (audience being prepared: 9–12, 13–15, 16–17, 18+); content rating (IARC), Data safety form, Ads declaration, Advertising-ID declaration, privacy-policy URL entry (`https://abhilashdeva.github.io/beamshift-privacy/`; the updated policy was pushed to the privacy repo — GitHub Pages deploy was still "building" at last check).
* Play Games Services project/credentials/fingerprints/testers for Game ID `516411257761` (needs the Play App Signing + upload-key fingerprints registered).
* AdMob app review ("Requires review" ⇒ limited serving) and test-device registration; iOS ad ids missing.
* Play Internal Testing upload of the next AAB (nothing after 10001 is documented as uploaded) and verify the `beamshift_no_forced_ads` product stays ACTIVE.
* Signing: upload key custody (stored outside repo), Play App Signing enrolment (already enabled per docs).

### OPTIONAL POLISH
Excluding the 13 dead packaged images; music (Music toggle is a placeholder); a Settings age-range editor (deliberately absent); removal of stale docs/backups; Mastery-band readability tuning; per-SFX gain tuning after device listening.

### FUTURE FEATURE (not requested)
Achievements/leaderboards, cloud save (explicitly deleted), Era 3 content / new mechanics, chained Fusion, procedural Levels 3001+, campaign Levels 141+, iOS release (needs macOS signing, ids, device QA), banner ads (none planned), `setAgeRestrictedTreatment` migration (needs a Poing plugin update).

---

## PART 30 — KNOWN BUGS AND RISKS

**CONFIRMED BUGS:** none open in code/tests (suite green). Fixed-this-session: Hint-ad dialog originally collapsed to the top-left (`set_anchors_preset` → `set_anchors_and_offsets_preset`), now covered by a regression test.

**SUSPECTED BUGS**
* `scripts/managers/ad_manager.gd` `maybe_show_interstitial_after_completion`: if `show_interstitial()` ever returned false after `has_interstitial()` was true, `_finish_interstitial(false)` would call `on_done` and the caller would also advance → skipped level (branch effectively unreachable).
* No timeout if a full-screen ad never reports dismissed/failed → `AdManager.state` stuck (Next Level and Hint swallowed until restart).
* A reward earned when no hint candidate exists is consumed without showing a hint (`game.gd`/`HintManager.grant_hint`).

**ANDROID RISKS:** safe-area/cutout unverified; `PlayGamesInitProvider`; Back handlers are per-screen and must start with the InternetBlocker guard; debug APK size (~173 MB) vs AAB ~123–145 MB; targetSdk 36 behaviours (edge-to-edge off by preset).
**UI RISKS:** dense Mastery boards; 4-column cards for 140/34 entries (device-pending); hand-written `.tscn` pitfalls (Part 12).
**LEVEL RISKS:** campaign 51–140 not manually QA'd; V5 `verified_optimal_moves` unknown (-1) so star thresholds rest on `intended_moves`; residual ~1–4% of Interlock-Mastery levels may have a shorter alternative solution (documented screens, not proofs).
**SAVE/PROGRESSION RISKS:** non-atomic save, no backup; uninstall loses progress (by design: no cloud); procedural version/seed resume depends on generator determinism (frozen versions + fingerprint checks).
**ADMOB RISKS:** app review pending; child-directed everywhere limits demand; AD_ID permissions; deprecated TFCD/TFUA; interstitial/rewarded close timing is SDK-controlled (Families "5-second close" cannot be proven by the app); no iOS ids.
**IAP RISKS:** only price retrieval device-verified; acknowledgement/restore/refund unproven on device; fallback price `$3.99` vs live ₹450.
**GOOGLE SIGN-IN RISKS:** feature removed — only a risk if reintroduced (cert fingerprints).
**PLAY GAMES RISKS:** Game ID/fingerprints/testers not verified; library startup behaviour for under-13; unverified UX when unauthenticated; plugin 3.4.0 is third-party.
**RELEASE RISKS:** uncommitted tree; unexplained 10005 AAB; main lags dev branch; public GitHub repo (CI must never publish binaries — configured); Families declaration not submitted.
**TECHNICAL DEBT:** very large doc set with stale sections; dual UI systems (art buttons + BeamUI); 13 dead packaged assets; 95 unreferenced source assets kept on disk; `QA`-named generator flags that are production switches.

---

## PART 31 — LEGACY / DEAD / DUPLICATE CONTENT (nothing deleted)

| Item | Evidence it is legacy |
|---|---|
| `assets/gameplay/pieces/**`, `assets/gameplay/tiles/**` | zero references; explicit export excludes; DECISIONS D31/D51 |
| 1254² source tiles next to each `*_runtime.png` | unreferenced; excluded; runtime variants are what code loads |
| tainted emitter/filter/portal/splitter/switch PNGs | unreferenced by rule 10 (procedural `_draw` instead) |
| `assets/backgrounds/{main_menu,level_select}/`, `assets/ui/{panels,gameplay,stage_complete,stage_select}`, old icon/panel sets | superseded by V2 backgrounds / BeamUI redesign; unreferenced; excluded |
| Era-2 skin assets (`*/era2/`) | inactive behind `UNIFIED_BLUE_THEME_ONLY` |
| `levels/level_01..15.gd` | still used as regression fixtures + `LEVEL_PATHS`; not player-facing |
| Level Select, 140-level campaign | QA-only since D85; retained deliberately |
| `tools/level_editor`, `scripts/tools/*` | dev tooling, export-excluded |
| Firebase-era docs/CI text/`project.godot.before_admob_test` | code deleted in `3df9252` |
| `NEXT_AI_PROMPT.md`, `NEXT_CLAUDE_PROMPT.md`, `PROJECT_HANDOFF.md` narrative | describe a phase long passed |
| `master`, `Dev_Abhilash`, `beamshift-production-prep` branches | diverged old histories |
| `builds/android/*` (≈50 APK/AAB) | disposable outputs, gitignored |
| `AdBackendFake` | test double (runtime-unreferenced by design) |

---

## PART 32 — IMPORTANT CONSTANTS / ENUMS / DATA STRUCTURES

* **`GridTypes.TileType`** (numeric order, never renumber): `0 EMPTY, 1 EMITTER, 2 MIRROR, 3 TARGET, 4 BLOCKER, 5 SPLITTER, 6 FILTER, 7 PORTAL, 8 SWITCH, 9 GATE, 10 HAZARD, 11 PRISM, 12 ONE_WAY_REFLECTOR, 13 BEAM_RECEIVER, 14 REMOTE_EMITTER, 15 FUSION, 16 SPLITTER_SELECTOR`.
* **`Direction`**: `UP=0, RIGHT=1, DOWN=2, LEFT=3` (vectors (0,-1),(1,0),(0,1),(-1,0)). **`MirrorOrientation`**: `SLASH=0, BACKSLASH=1`. **`BeamColor`**: `WHITE=0, RED=1, GREEN=2, BLUE=3, YELLOW=4, MAGENTA=5, CYAN=6` (appended values keep older numeric identity). Fusion table: R+G→YELLOW, R+B→MAGENTA, G+B→CYAN, R+G+B→WHITE; one primary or non-primary inputs → invalid.
* **`TilePlacement` fields:** `tile_type, position, direction, mirror_orientation, rotatable, color, required, pair_id, gate_id, initial_open_state, link_id`; factories `make_emitter/mirror/splitter/target/blocker/filter/portal/switch/gate/hazard/prism/one_way_reflector/beam_receiver/remote_emitter/splitter_selector/fusion`.
* **`AgeGroup`:** `UNKNOWN=0, CHILD_12_OR_YOUNGER=1, TEEN_13_TO_17=2, ADULT_18_PLUS=3`; `play_games_allowed` = TEEN or ADULT; `screen_required(group, os)` = Android and UNKNOWN.
* **`BuildConfig`:** `MODE_INTERNAL_QA=0, MODE_EXTERNAL_TEST=1, MODE_PRODUCTION=2`.
* **`AdManager.State`:** `IDLE, SHOWING_REWARDED, SHOWING_INTERSTITIAL`. **`TutorialStepData.StepType`:** `MESSAGE, REQUIRE_TILE_TAP, WAIT_FOR_TARGET_ACTIVATION, WAIT_FOR_PUZZLE_SOLVED`. **`PlatformAccount.Platform`:** `NONE, ANDROID, IOS`.
* **Save file:** `user://savegame.json`, version 5 (Part 14). **Product id:** `beamshift_no_forced_ads`. **Hint table:** `res://levels/hint_solutions.json` keys `c1..c140` (campaign number), `t1..t34`. **Procedural star key:** `"<level>|<generator_version>"`.
* **Scene paths (GameManager):** MAIN_MENU `res://scenes/ui/main_menu.tscn`, LEVEL_SELECT, TUTORIAL_SELECT, SETTINGS, ACCOUNT, ABOUT, PRIVACY_POLICY, AGE (`res://scenes/ui/age_selection.tscn`, loaded by the splash), GAME `res://scenes/gameplay/game.tscn`, LEVEL_EDITOR `res://tools/level_editor/level_editor.tscn`.
* **Numbers that matter:** `MAX_COLUMNS 8`, `MIN_COMFORTABLE_CELL_SIZE 96`, `GRID_SAFETY_MARGIN 8`, `INTERSTITIAL_EVERY_COMPLETIONS 4`, `INTERSTITIAL_MIN_SECONDS 120`, `PROCEDURAL_QA_JUMP_AMOUNT 50`, `ProceduralLevelGenerator.MAX_LEVEL 3000`, `SELECTOR_FIRST_LEVEL 2001`, `FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL 150`, `SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL 1900`, `LaserSystem.MAX_EXTRA_PASSES 8`, `MAX_STEPS 20000`, `AudioManager.POOL_SIZE 10`, `HintManager.AUTO_CLEAR_SEC 6`, `LEVEL_COMPLETE_DELAY 0.8`, `StarScoring` margins 2 / 6, hint cap 2, `InternetManager` URL `https://www.gstatic.com/generate_204`, timeout 5 s, period 8 s, fast retry 2 s, 2 failures.
* **Signals worth knowing:** `GridManager.move_made` (BEFORE simulation), `simulation_updated` (AFTER state refresh), `level_solved`, `tile_tap_attempted`; `HintManager.hint_shown/cleared/unavailable`; `TutorialManager.step_changed/tutorial_finished`; `AdManager.rewarded_*/reward_earned/interstitial_*`; `StoreManager.changed/purchase_finished`; `InternetManager.internet_lost/restored/check_*`; `PlatformAccount.changed`; `SaveManager.saved`; `HintAdDialog.confirmed/cancelled`. Groups: none used. Metadata: only `grid_position` on cell backgrounds.

---

## PART 33 — SIGNAL / EVENT FLOWS (actual)

**Piece rotated → completion**
`tile gui_input` → `GridManager._on_orientable_tile_clicked(pos)` (gates: solved? locked? restricted?) → flip/step `tile_orientations[pos]`, update node `.orientation`, `AudioManager.play_mirror_rotate()` → `move_made` (game.gd `_on_move_made`: `moves_used++`, update label, persist resume state, tutorial notify) → `_simulate_and_draw(true)` → `LaserSystem.simulate_until_stable` → update target/switch/hazard/gate/receiver/remote/fusion/selector node views → `_redraw_beams` → impact VFX + transition audio → `simulation_updated` (tutorial/hint hooks) → if `solved and not is_solved`: `is_solved = true`, `level_solved` → `AudioManager.play_puzzle_solved()`.

**Level completed → next**
`GridManager.level_solved` → `game.gd._on_level_solved`: (procedural normal session) `StarScoring.stars_for(authoritative_optimal, moves, hint_used)` → `SaveManager.record_procedural_stars` → `record_procedural_level_result(level)` (advances `procedural_current_level` only if it equals this level) → `AdManager.register_completion(level)` (counter++ once per level) → wait `LEVEL_COMPLETE_DELAY` 0.8 s → `play_level_complete()` → `LevelCompletePopup.show_result(...)`. NEXT LEVEL → `_on_next_level_pressed` → `maybe_show_interstitial_after_completion(rewarded_this_level, _advance_to_next_level)` → (ad or immediately) `_advance_to_next_level()` → `current_procedural_level += 1` → `_load_current_level()` (new `start_procedural_resume`).
Campaign (QA) path: `record_campaign_level_result` instead; tutorial path: `TutorialManager.notify_puzzle_solved` → `tutorial_finished` → `SaveManager.record_tutorial_level_result` → TutorialCompletePopup.

**Hint**
HINT button → `_on_hint_pressed` → `HintManager.request_hint()` → (permission provider set in normal procedural play) `_hint_permission` → (ad ready) `HintAdDialog` → WATCH AD → `AdManager.show_rewarded_hint(cb)` → backend show → `reward_earned` → `cb(true)` → `HintManager.grant_hint()` → `hint_shown(pos)` → `game._on_hint_granted` (`_hint_used_this_attempt = true`, `SaveManager.mark_hint_used`) → ring on `GridManager.show_hint_cell`; auto-clears after 6 s or on a move.

**IAP**
Settings buy → `StoreManager.purchase(id)` → `play_billing_backend.purchase` → Play sheet → `on_purchase_updated` → `ownership_known(owned, false)` + `acknowledge_purchase` → `StoreManager._on_ownership_known` → `SaveManager.set_entitlement(id, true)` (saves) → `AdManager.on_forced_ads_removed()` (drops preloaded interstitial) → `purchase_finished(true, MSG_THANKS)`; later `AdManager.forced_ads_removed()` is true ⇒ no interstitials; rewarded Hint unaffected. Launch/Restore → `query_purchases` → authoritative `ownership_known` (can revoke).

**Identity (Android)**
splash → `AgeGroup.screen_required` → `age_selection` → `SaveManager.set_age_group` → `PlatformAccount.apply_age_group()` → (TEEN/ADULT) `_setup_play_games()` → `GodotPlayGameServices.initialize()` → `PlayGamesSignInClient.is_authenticated()` → `user_authenticated` → `_players.load_current_player` → `current_player_loaded` → `display_name` → `changed` → Settings/Account refresh.

---

## PART 34 — STARTUP FLOW (exact)

1. **Godot boot**; project settings applied; `res://themes/beamshift_theme.tres` loaded; audio bus layout loaded.
2. **Autoloads in order:** `SaveManager._ready` → `load_game()`; `LevelManager` (consts/caches); `GameManager`; `AudioManager._ready` (resolve buses, `_load_streams`, build pool, `set_sound_enabled(SaveManager.sound_enabled)`); `AdManager._ready` (config warning; if `AdConfig.ads_active()` and Android/iOS → `use_backend(AdBackendAdMob)` → `initialize_ads()` = UMP update + SDK init + preload rewarded/interstitial after init); `StoreManager._ready` (Android → load `play_billing_backend.gd` → `BillingClient.start_connection()` → product + purchase queries); `GodotPlayGameServices` (plugin autoload; nothing initialized yet); `InternetManager._ready` (HTTPRequest + timers; startup probe, process mode ALWAYS); `InternetBlocker._ready` (CanvasLayer 128; holds the tree paused with NO panel until the first probe resolves, then shows the panel only if offline); `PlatformAccount._ready` (Android → `apply_age_group()` → starts Play Games only if `SaveManager.age_group` is TEEN/ADULT; iOS → loads the stored Apple flag).
3. **Main scene** `studio_splash.tscn` plays both logos (~4 s), then `change_scene_to_file(age_selection.tscn)` if Android and age UNKNOWN, else `main_menu.tscn`.
4. **Main menu `_ready`:** wire buttons + SFX + glow; `CONTINUE` disabled unless `SaveManager.has_resumable_procedural_game()`; QA buttons only if `QA_TOOLS`; one-time Fusion tutorial nudge when due; hero layout computed from the viewport.
5. **PLAY/NEW GAME** (`GameManager.start_new_game` → resets main progress if confirmed → `start_procedural_level(1)`) or **CONTINUE** (`continue_game` → saved resume level) → `change_scene_to_file(game.tscn)`; **TUTORIALS** → `tutorial_select`; **Level Select** only in QA.
6. **Game `_ready`:** build HUD, connect signals, create `HintManager`/`TutorialManager`, `_load_current_level()` (generate/resume level, build grid, apply theme, configure hint permission, tutorial start).



---

## PART 35 — COMPLETE GAMEPLAY FLOW (one normal session, actual code paths)

1. **Start** — splash → (Android first launch) age screen → Main Menu. `NEW GAME` (`main_menu.gd._on_new_game_pressed`): fresh/no-progress save ⇒ immediate `GameManager.start_new_game()`; meaningful progress ⇒ code-built confirmation dialog first. `CONTINUE` ⇒ `GameManager.continue_game()`.
2. **Level select** — *not part of the player flow.* QA builds only: Main Menu "Level Select (QA)" → `level_select.gd` → `GameManager.start_level(id, true)`.
3. **Choose level** — `GameManager.start_procedural_level(n)` sets `is_procedural_mode=true` and changes to `game.tscn`.
4. **Level data loads** — `game.gd._load_current_level()`: resume vs fresh decision (`SaveManager.has_resumable_procedural_game()` & matching level & saved generator version) → `LevelManager.get_procedural_generation_result(level, version)` → `ProceduralLevelGenerator.generate` (deterministic seed, self-verifies with `LaserSystem`) → `GridManager.load_level(level_data)`.
5. **Pieces spawn** — `load_level` instantiates one tile scene per `TilePlacement` (`scenes/tiles/*`), computes layout (`_recalculate_layout`), seeds `tile_orientations`.
6. **Interaction** — tap → `_on_orientable_tile_clicked` (Part 33).
7. **Beam recalculation** — `LaserSystem.simulate_until_stable`.
8. **Targets activate** — views updated from the result dictionary; SFX on inactive→active transitions.
9. **Solved** — `solved` in the result ⇒ `level_solved`.
10. **Completion** — `game.gd._on_level_solved` (stars, save, ad counter, popup after 0.8 s).
11. **Save** — `record_procedural_stars` + `record_procedural_level_result` (+ `register_completion`); every accepted move also saved the resume state.
12. **Next level unlocked** — `procedural_current_level` incremented when the solved level was the current progression level (a replay or QA jump never advances it).
13. **Completion UI** — `LevelCompletePopup` (stars, moves, HINT USED note if applicable; NEXT/RETRY/main-menu).
14. **Next/Return** — NEXT LEVEL (interstitial if due) → next generated level; main-menu button → `GameManager.go_to_main_menu()`; CONTINUE later resumes exactly.

---

## PART 36 — MONETIZATION FLOW

* **Normal player → ads:** interstitial at Level Complete → Next Level every 4 completions and ≥120 s apart (Part 16). Rewarded Hint optional.
* **Hint:** HINT → (ad ready) "GET A HINT?" dialog → WATCH AD → rewarded video → reward callback → exactly one hint ring; hint use caps stars at 2; no free fallback when the ad is unavailable.
* **Purchase `beamshift_no_forced_ads`:** Settings → Play Billing → entitlement saved in `SaveManager.entitlements` → interstitials disabled and any preloaded one discarded; rewarded Hint stays.
* **App restart:** entitlement is read from the save instantly (offline-correct) and re-checked against Play at connect; only an authoritative full query can revoke.
* **Reinstall:** the save is gone; Play Billing returns the owned purchase on connect / Restore Purchases ⇒ entitlement re-granted.
* **Not implemented/tested:** purchase, restore, reinstall and refund on a device; iOS StoreKit; production ad serving before AdMob review.

---

## PART 37 — AUTHENTICATION FLOW

* *"Continue with Google" does not exist any more.* Current Android identity (optional): age screen choice 13+ → `PlatformAccount.apply_age_group()` → `GodotPlayGameServices.initialize()` → silent `is_authenticated()` → (if signed in) `load_current_player` → display name shown in Settings/Account. Not signed in → Account screen shows CONNECT → `sign_in()` → Google Play Games UI → `user_authenticated` → name. Cancel/failure → `last_message` only; gameplay unaffected.
* Under-13 or unknown age: nothing is initialized by BeamShift; Account shows "LOCAL PROFILE".
* **Known failure points:** missing/incorrect Game ID (export fails or sign-in silently fails); certificate fingerprints not registered for the signing key actually used (debug vs upload vs Play App Signing — the cause of the historic failure); Play Games app/Play services absent; the plugin surfaces some configuration errors as a quiet "cancelled".
* iOS: Sign in with Apple via a vendored AuthenticationServices extension; only a flag + name are stored.

---

## PART 38 — RELEASE PIPELINE (intended, from the repository)

`development (dev_abhilas)` → `local validation` (run_coverage.ps1: production + QA passes; ui_shots renders) → **`APK` (debug-signed test APK with production ids + registered test device; recipe in Part 44)** → `physical Android device test` → `fixes` → `APK retest` → *(only on explicit owner approval)* **`final AAB`** (CI `Release CD` android-play lane or manual `--export-release "Android"`; versions stamped by `tools/ci/stamp_version.sh`) → `owner uploads AAB to Play Internal Testing by hand (CI never uploads)` → `IAP verification (checklist A–F)` → `ads verification` → `Play Games verification` → `Play Console: Target audience/Families, Data safety, content rating, ads/AD_ID declarations, privacy URL` → `release readiness` → `closed/production`. iOS lane: tag/manual run → signed IPA → TestFlight (prepared, no recorded run).

**Workflow rules in force:** APK first; no AAB until the owner explicitly approves APK testing; never push to `main` unless asked; commit/push only on request; preserve working systems; verify repository state before trusting any historical note.

---

## PART 39 — CRITICAL FILE MAP (condensed)

```
project.godot → 10 autoloads, portrait 1080x1920, main scene studio_splash, theme
export_presets.cfg → Android Debug/Android/iOS, 71–72 exclude patterns, versions, empty game_id
scripts/gameplay/laser_system.gd → THE simulation (static, pure) → grid_types.gd, level_data.gd, tile_placement.gd
scripts/gameplay/grid_types.gd → enums + reflect()/colour rules → everything
scripts/gameplay/grid_manager.gd → board: layout, tap, simulate, draw, VFX, audio → laser_system, tiles, AudioManager, tutorial hooks
scripts/gameplay/game.gd (+ scenes/gameplay/game.tscn) → session controller (HUD, completion, hint/ad glue, tutorial) → GridManager, HintManager, TutorialManager, SaveManager, LevelManager, AdManager, StarScoring
scripts/gameplay/hint_manager.gd (+ levels/hint_solutions.json) → one-tile hints, permission seam → game.gd
scripts/managers/save_manager.gd → user://savegame.json (schema v5) → no deps; read by everyone
scripts/managers/level_manager.gd → catalogs, unlocks, generator routing, QA flags → SaveManager, ProceduralLevelGenerator, BuildConfig, EraTheme
scripts/managers/game_manager.gd → scene navigation + session flags → LevelManager, SaveManager
scripts/managers/build_config.gd → MODE_PRODUCTION; QA_TOOLS root flag → LevelManager, AdConfig, UIConstants
scripts/managers/star_scoring.gd → the one star rule
scripts/managers/ad_manager.gd → ads policy (rewarded/interstitial/consent) → scripts/ads/*, SaveManager, InternetManager, StoreConfig
scripts/ads/ad_config.gd → ids, switches, CHILD_DIRECTED, cadence constants; ad_backend_admob.gd → Poing plugin (TFCD/TFUA/G, UMP)
scripts/managers/store_manager.gd → purchases/entitlements → scripts/store/play_billing_backend.gd, store_config.gd, SaveManager, AdManager
scripts/store/store_config.gd → product id, fallback price, privacy URL
scripts/managers/platform_account.gd → optional Play Games / Apple identity → AgeGroup, SaveManager, GodotPlayGameServices
scripts/managers/age_group.gd + scripts/ui/age_selection.gd + scenes/ui/age_selection.tscn → Android neutral age screen → SaveManager, PlatformAccount
scripts/ui/hint_ad_dialog.gd → "GET A HINT?" disclosure → game.gd
scripts/managers/internet_manager.gd + internet_blocker.gd → mandatory-internet gate (layer 128) → every screen's Back handler
scripts/managers/audio_manager.gd → SFX table/pool → grid_manager, UI scripts; assets/sfx/*.ogg
scripts/managers/tutorial_manager.gd + scripts/resources/tutorial_*.gd + levels/tutorial/t01..t34.gd → guided tutorials → GridManager gating
scripts/procedural/procedural_level_generator.gd (+ progression_v3, composer_v3, fragments_v3, difficulty_contract, selector/fusion checks) → procedural levels 1–3000 → LaserSystem (never solver)
scripts/resources/era_theme.gd → UNIFIED_BLUE_THEME_ONLY → game.gd, level/tutorial buttons
scripts/ui/beam_ui.gd → UI tokens → themes/beamshift_theme.tres (generated)
scripts/ui/safe_area_margin.gd + ui_constants.gd → safe areas, HUD spacing → every screen
scripts/ui/main_menu.gd, studio_splash.gd, settings_menu.gd, account_screen.gd, about_screen.gd, privacy_policy_screen.gd, privacy_policy_text.gd, level_select.gd, tutorial_select.gd, pause_menu.gd, level_complete_popup.gd → screens
levels/campaign/**, levels/level_XX.gd, levels/tutorial/** → handcrafted data (QA + tutorial)
docs/privacy-policy/index.html → generated from privacy_policy_text.gd by tools/privacy/build_policy_html.gd
tools/tests/** → 152-test suite; tools/ci/*.sh + .github/workflows/release.yml → release/stamping pipeline
scripts/tools/** + tools/level_editor/** → dev solver/validator/editor (never ships)
config/ad_ids.local.json + ad_test_devices.local.json (gitignored) → production ad ids/test device
addons/admob (5.1.0), addons/GodotGooglePlayBilling (3.3.0), addons/GodotPlayGameServices (3.4.0) → native plugins
CLAUDE.md → the permanent rules (read before touching anything)
```

---

## PART 40 — DEPENDENCY MAP

```
studio_splash ──► [Android & age UNKNOWN] age_selection ──► SaveManager.age_group ─► PlatformAccount.apply_age_group ─► (13+) Play Games silent check ─► display name
      │
      ▼
 Main Menu ──► NEW GAME/CONTINUE ──► GameManager.start_procedural_level ──► game.tscn
      │                                             │
      │                                             ├─► LevelManager ─► ProceduralLevelGenerator (V4 ≤2000, V5 ≥2001) ─► LevelData
      │                                             ├─► GridManager.load_level ─► tile scenes (dumb views)
      │            tap ─────────────────────────────┤        │  _on_orientable_tile_clicked
      │                                             │        ▼
      │                                             │   LaserSystem.simulate_until_stable ─► GridTypes.reflect/colours
      │                                             │        ▼
      │                                             │   targets/gates/hazards views, beams, VFX, AudioManager
      │                                             │        ▼ level_solved
      │                                             ├─► StarScoring ─► SaveManager (stars, progress, resume)
      │                                             ├─► AdManager.register_completion ─► [Next] interstitial ─► AdBackendAdMob ─► Google GMA SDK
      │                                             └─► HINT ─► HintManager ─► HintAdDialog ─► AdManager.show_rewarded_hint ─► reward ─► hint ring
      ├─► TUTORIALS ─► tutorial_select ─► game.tscn (tutorial mode) ─► TutorialManager ─► GridManager gating ─► SaveManager.tutorial_*
      ├─► SETTINGS ─► Sound toggle ─► AudioManager;  NO FORCED ADS/RESTORE ─► StoreManager ─► play_billing_backend ─► Google Play Billing ─► SaveManager.entitlements ─► AdManager.forced_ads_removed
      │             ├─► ACCOUNT ─► PlatformAccount;  PRIVACY OPTIONS ─► UMP;  PRIVACY POLICY ─► PrivacyPolicyText screen
      └─► ABOUT
InternetManager ─► InternetBlocker (layer 128, pauses tree) wraps EVERYTHING above
QA only: Level Select ─► 140 campaign levels (+50, V3/FUSION/SELECTOR/V5 TEST) – hidden unless BuildConfig.QA_TOOLS
```

---

## PART 41 — DEVELOPMENT HISTORY RECOVERY

(Git only holds history from 2026-09-25; earlier history comes from DECISIONS/CHANGELOG/ROADMAP — marked **doc-sourced**.)

| Milestone | What changed | Important files | Current relevance | Evidence |
|---|---|---|---|---|
| **Foundation / Milestone 1** (doc) | grid + deterministic laser sim, mirrors, emitter, target, blocker, Level Select, save, levels 1–5; "no physics", loop guard, single reflect table rules | `grid_types.gd`, `laser_system.gd`, `grid_manager.gd`, `levels/level_01..05.gd` | core of everything | TEST_PLAN M1, 15 dev levels still tested |
| **Milestone 2 – advanced mechanics** (doc) | splitters, colours/filters, portals, switch/gate, hazards, multi-emitter; levels 6–15 | same + tile scenes | all live | `test_levels_bulk`, regression fixtures |
| **Milestone 3 – tooling** (doc) | runtime level editor, `LevelSolver`, `LevelValidator`, `LevelMetrics`, fixtures | `scripts/tools/*`, `tools/level_editor/*` | dev-only, proof tooling | LEVEL_EDITOR.md, test_dev_tools |
| **Milestone 4 – 100-level campaign** (doc) | 10 stages, solver-in-the-loop authoring, Levels 1–50 rebuilt mechanic-agnostic twice (D64/D65), 51–100 (D66–D70) | `levels/campaign/stage_01..10` | QA population only now | CAMPAIGN_DESIGN.md; owner: 1–50 good on device |
| **Milestone 4A – final asset integration** (doc) | final art for tiles/UI, duplicate generated sets resolved (D31), the Level-3 "unsolvable" bug = presentation mismatch (D40), rendered-screenshot verification technique (D45–47), build-identity lesson (D44) | `assets/gameplay/*_runtime.png`, tile scripts | canonical asset set | Part 11 scan |
| **APK size optimisation** (doc D53) | 113 MB → 51 MB by shrinking oversized textures, export excludes | presets | export filter discipline | DECISIONS D53 |
| **Mobile UI passes** (doc 4A.1–4A.6, D72–D76, D84–D87) | portrait relayout of all 100 campaign levels (order-preserving remap), per-axis board fit, full-screen board correction, safe-area margins | `grid_manager.gd`, `safe_area_margin.gd`, `ui_constants.gd` | live layout system | docs + tests |
| **Guided tutorial T01–T10** (doc D60–D63) | step machine, highlight/dim, forced-tap gate, panel bugs found by dumping runtime rects | `tutorial_manager.gd`, panel/highlight/dim scripts | live | `test_game_session` plays all 34 |
| **Era 2 foundation** (doc D77–D83) | prism, one-way reflector, beam receiver/remote emitter, T11–T20, levels 101–140, shortcut-bug families | `era_theme.gd`, tile scripts, `levels/campaign/era2_stage_01` | mechanics live; skin inactive | ERA_2_DESIGN.md |
| **Direct Play + Procedural V1/V2** (D85, D88–D92) | PLAY/CONTINUE replace Level Select; 2000 procedural levels; deterministic seed + versions; QA +50 | `procedural_*`, `game_manager.gd` | live | PROCEDURAL_GENERATION.md |
| **Audio / background / blue theme** (D89–D91) | centralised SFX, minimal gameplay background, unified blue theme | `audio_manager.gd`, `era_theme.gd` | live | AUDIO_SYSTEM.md |
| **Difficulty system + V3/V4** (D93–D96, D99–D102) | difficulty contract, dependency-first generation, Hint system (D97), AdMob foundation (D98), Fusion node (D99–D101), centralised stars (D102) | contract/fragments/composer, `hint_manager.gd`, `ad_manager.gd`, `star_scoring.gd` | live | CLAUDE.md sections |
| **HUD calibration & NEW GAME** (D103–D107) | HUD edge/gap/stack-shift tuning, NEW GAME confirm + single reset function | `safe_area_margin.gd`, `save_manager.gd` | live | tests |
| **Splitter Selector + generator V5** (D108–D112, git `36fc104`/`acbdd2e`/`c3d673f`) | selector mechanic, tutorials T29–T34, Levels 2001–3000, minimality screens | `splitter_selector_tile.gd`, V5 files | live | `v5_*` tools, D110–D112 |
| **External-test/production prep** (D113–D114, git `b50be41`, `9b0a1c4`, `92c01ea`) | `BuildConfig` modes, CI stamping of ids/Game ID, production AdMob ids | `build_config.gd`, `tools/ci/*` | live | STORE_RELEASE |
| **Google Sign-In / Firebase / cloud save** (git `5a66539`, `0d5b42d`, `a33e02b`; D115) | built, failed on Play install due to the Play App Signing cert, fixed in console, later removed | – | **removed 10-01** | STORE_RELEASE §14–17 |
| **iOS pipeline** (D116–D117, git `0fc37a5`…`af63fa0`) | AuthenticationServices Apple sign-in, GitHub Actions macOS lane, TestFlight | `release.yml`, `references/ci-cd.md` | prepared, unrun | docs |
| **About Us, Tutorial/Level-Select scroll fixes** (doc 09-30) | credits screen; `mouse_filter = PASS` on cards; header spacer | `about_screen.gd`, `*_select.tscn` | live | RC3 owner pass |
| **IAP integration** (doc 09-29, STORE_RELEASE) | Play Billing backend + checklist; price-label overflow fix | `store_manager.gd`, `play_billing_backend.gd` | live | price retrieved on device |
| **RC3 + AABs 10002/10004** (doc 09-30) | RC validation passed; internal AABs built | `builds/android/*` | – | owner-confirmed RC3 |
| **UI redesign, Firebase removal, Internet gate** (git `7762edf`…`f9cf633`, 10-01) | BeamUI design system, flat HUD, PlatformAccount, mandatory internet | `beam_ui.gd`, `platform_account.gd`, `internet_*` | live | commits + tests |
| **Production UI + CI policy** (git `f7e88fb`, `7b160da`, `71062bd`, 10-02) | art buttons, Back guards, no public GitHub releases, TestFlight automation | UI scripts, `release.yml` | live | commits |
| **Privacy policy** (git `02c8069`, `c2c7752`, 10-03) | native policy screen + GitHub Pages copy | `privacy_policy_text.gd`, `docs/privacy-policy` | live (updated copy pushed to the privacy repo) | tests |
| **Families hardening** (uncommitted, 10-03) | age screen, Play Games gating, Hint ad confirmation, policy rewrite | `age_*`, `hint_ad_dialog.gd`, `platform_account.gd`, `save_manager.gd` | latest work | 20 tests; APK built; device pending |

---

## PART 42 — CURRENT EXACT STATE: "Where is BeamShift development right now?"

**Finished & working (code + automated tests):** the whole puzzle engine with 17 tile types; 3,000 deterministic procedural levels; 15 dev + 140 campaign + 34 tutorial levels; stars/hints/NEW GAME/Continue; SFX; AdMob rewarded Hint + interstitial wired to production ids (child-directed everywhere); Play Billing "No Forced Ads" implemented; optional Play Games (13+) and Sign in with Apple; mandatory-internet gate; native privacy policy; Android age screen; Hint-ad confirmation dialog. **152 tests pass (3,681 assertions)**, QA-mode subset 34 pass.

**Tested on a device (per docs, owner):** the RC3 build (before Firebase removal): rewarded Hint, interstitial, normal production progression, About Us, tutorial scrolling, UI; Play Internal Testing install of an earlier AAB (10001); live IAP price retrieval.

**NOT tested on a device (as far as any record shows):** everything done since 2026-10-01 — UI redesign, Firebase removal, internet gate, Play Games after the Firebase removal, age screen, Hint-ad dialog, new privacy-policy screen; the IAP purchase/restore/reinstall/refund flows; iOS anything.

**Broken/at risk:** nothing known broken; risks are the uncommitted tree, undocumented 10005 AAB, `PlayGamesInitProvider` behaviour, AD_ID permission posture, ad-state watchdog, non-atomic save, stale docs.

**Uncertain:** safe-area on notch devices, Mastery-band board readability, whether the live GitHub Pages policy is deployed (push done; deploy was "building"), Play Games Console configuration, AdMob app review status.

**Before release:** commit/organise the work; device-test the latest APK; settle PlayGamesInitProvider/AD_ID; fix version numbers; complete Play Console declarations (Families target audience NOT submitted); build the AAB only after APK approval; Internal Testing + IAP A–F + Play Games verification; AdMob review.

---

## PART 43 — NEXT STEPS (ordered by dependency)

1. **Device-test the existing APK** `builds/android/beamshift-families-policy-test.apk` (latest source). *Why first:* every later step (commit, policy text, Play Console answers) depends on the age screen / Hint dialog / Play Games gating behaving as the policy now says.
2. **Fix whatever step 1 finds**, then run `tools/tests/run_coverage.ps1` (production + QA) — *because* the policy and Families declaration must describe verified behaviour.
3. **Owner decisions needed before the forms:** `PlayGamesInitProvider` removal or acceptance; AD_ID permission handling; whether an age-range editor is wanted. *Because* Data safety / Families answers depend on them.
4. **Confirm the public privacy page is live** (`https://abhilashdeva.github.io/beamshift-privacy/` shows "select an age range"/"CANCEL or WATCH AD") — *the Play Console privacy-URL field must point at final text.*
5. **Commit the work on `dev_abhilas`** (owner approval needed; never to `main` without being asked). *Because* nothing downstream is reproducible while ~30 entries are uncommitted.
6. **Play Console (owner):** Target audience/Families, content rating, Data safety, Ads + Advertising-ID declaration, privacy URL; Play Games credentials/fingerprints/testers; AdMob review.
7. **Align versions** (presets vs project.godot; choose > last uploaded code; explain `10005`), then — **only after the owner explicitly approves APK testing** — build the signed AAB (CI `Release CD` or manual) and upload to Internal Testing by hand.
8. **On the Play-installed build:** IAP A–F, Play Games sign-in, ads, internet gate, back-button, safe-area; fix → repeat (APK first for iterations).
9. **Release readiness:** closed/production track decisions; iOS only if wanted (ids, signing, TestFlight run, device QA).
Do **not** rebuild existing systems (store, ads, identity, procedural generator, UI system) — they exist and are tested.



---

# BEAMSHIFT MASTER HANDOFF FOR CHATGPT

*(Self-contained. Written 2026-10-03 from a read-only forensic audit of the real repository. Where this text and any older document disagree, the code wins. I could not run the game on a phone; "device-verified" below always means "documented by the owner", never something I observed.)*

## 1. Identity
* **BeamShift** — a portrait mobile **laser-reflection logic puzzle** (Godot **4.7.1 stable**, GDScript, "Mobile" renderer). Publisher MACLEPRO INC, developer 4 Sagez Studios Pvt. Ltd., contact sage@maclepro.in.
* **Project root:** `D:\4Sagez\GodotGames\GitClones\beam-shiflt` (the folder name is *shiflt*). Git origin `https://github.com/bijju/beam-shiflt.git`. **Current branch `dev_abhilas`, HEAD `c2c7752` ("Add GitHub Pages nojekyll marker", 2026-10-03).** `main` is at `f8a2e6f` (11 commits behind). **The working tree is dirty (~30 uncommitted entries) — see §16.**
* Android package/bundle id **`com.foursagez.beamshift`**; versionCode **10004**, versionName **1.0.1** in the presets (project.godot `config/version` still says 1.0.0; the newest local AAB is named 10005 with no documentation). Main scene `res://scenes/ui/studio_splash.tscn`. Portrait, 1080×1920 canvas, `canvas_items` + `expand` stretch. minSdk 24 / targetSdk 36, arm64-v8a + armeabi-v7a.
* The player-facing game has **no accounts, no cloud save, no Firebase** (all deleted 2026-10-01). Internet is **mandatory** (global blocker). Progress is local only.

## 2. What the game is
The player taps tiles to rotate them so coloured beams from emitters reach all required targets without touching hazards. Mirrors/splitters/one-way reflectors toggle `/` ↔ `\`; Fusion nodes and Splitter Selectors step through 4 output directions. Other mechanics: blockers, filters (recolour), portals, switches→gates, prism (WHITE→RGB), beam receiver→remote emitter, Fusion node (R+G→Y, R+B→M, G+B→C, RGB→W), Splitter Selector (one in → one out). There is no placing/dragging, no undo; Reset, Hint, moves and 1–3 stars exist. Difficulty comes from combining mechanics, never from board size (`MAX_COLUMNS = 8`, square cells).

## 3. Normal player loop (production)
Splash → *(Android first launch only)* **age selection** → Main Menu (NEW GAME / CONTINUE / TUTORIALS / ABOUT / SETTINGS; no Quit) → **procedural levels 1–3000** via `GameManager.start_procedural_level` → solve → stars saved → Level Complete popup → NEXT LEVEL (interstitial every 4th completion, ≥120 s apart). **Level Select and the 140 handcrafted campaign levels are QA-only** (visible only when `BuildConfig.QA_TOOLS`, i.e. an internal-QA build). Tutorials T01–T34 are reachable from the main menu.

## 4. Architecture (the rules that must be preserved — see `CLAUDE.md`, 1,553 lines)
1. Puzzle logic is a deterministic grid simulation, **never physics/raycast**: `scripts/gameplay/laser_system.gd` (`simulate()` one pass; `simulate_until_stable()` multi-pass for switch→gate, receiver→remote, Fusion). The reflection table lives only in `GridTypes.reflect()`.
2. Levels are data: `LevelData` + `TilePlacement` (`make_*` factories). No per-level-id branches.
3. `GridManager` owns authoritative state; tile scenes are dumb views. The shared `visited_states` loop guard must never be narrowed.
4. Dev tools (`scripts/tools/**`, `tools/**`, `levels/editor_fixtures/**`) never ship and runtime code never calls them; the procedural generator self-verifies with `LaserSystem` only.
5. Autoloads (10): `SaveManager`, `LevelManager`, `GameManager`, `AudioManager`, `AdManager`, `StoreManager`, `GodotPlayGameServices` (plugin), `InternetManager`, `InternetBlocker`, `PlatformAccount`. Don't add more; `TutorialManager`, `HintManager`, `AgeGroup`, `EraTheme`, `BuildConfig`, `StarScoring`, `AdConfig`, `StoreConfig` are helpers.
6. One shared UI theme generated from `scripts/ui/beam_ui.gd` (never hand-edit `themes/beamshift_theme.tres`); text is Labels/Buttons (Rajdhani); art buttons only on Main Menu/Settings/Pause/Level Complete/New-Game dialog.
7. Every screen's Android Back handler must start with `if InternetManager.is_blocking(): return`.
8. Hand-written `.tscn` pitfalls: verify the root `script =` line; don't re-declare anchors on an instanced scene.
9. Headless Godot cannot test real touch; render with `tools/ui_shots/shoot.sh` for visuals.

## 5. Important directories
`scenes/{ui,gameplay,tiles}`, `scripts/{managers,gameplay,resources,ui,ads,store,procedural,tools}`, `levels/{level_01..15.gd, campaign/stage_01..10 + era2_stage_01, tutorial/t01..t34, editor_fixtures, fusion_qa, selector_qa, hint_solutions.json}`, `assets/{gameplay,ui,backgrounds,branding,fonts,sfx,audio}`, `addons/{admob 5.1.0, GodotGooglePlayBilling 3.3.0, GodotPlayGameServices 3.4.0}`, `tools/{tests,ci,level_editor,privacy,ui_shots}`, `docs/privacy-policy`, `config/` (gitignored local ad files), `android/` + `builds/` (gitignored outputs).

## 6. Critical files (see Part 39 for the full map)
`project.godot`, `export_presets.cfg`, `laser_system.gd`, `grid_types.gd`, `grid_manager.gd`, `game.gd`, `hint_manager.gd`, `save_manager.gd`, `level_manager.gd`, `game_manager.gd`, `build_config.gd`, `star_scoring.gd`, `ad_manager.gd`, `ad_config.gd`, `ad_backend_admob.gd`, `store_manager.gd`, `play_billing_backend.gd`, `store_config.gd`, `platform_account.gd`, `age_group.gd`, `age_selection.gd`, `hint_ad_dialog.gd`, `internet_manager.gd`, `internet_blocker.gd`, `audio_manager.gd`, `tutorial_manager.gd`, `procedural_level_generator.gd`, `procedural_difficulty_contract.gd`, `era_theme.gd`, `beam_ui.gd`, `safe_area_margin.gd`, `privacy_policy_text.gd`, `tools/tests/run_coverage.ps1`, `.github/workflows/release.yml`.

## 7. Laser system (short form)
Queue of beams; each step moves one cell; per-cell priority: **blocker(stop) → hazard(stop, sets hazard_hit) → gate(closed stops) → switch(record) → receiver(record) → fusion(terminates; records input colour/side) → selector(route to selected side; absorbed from output side) → portal(jump to partner, new segment) → filter(recolour) → splitter(+reflected branch) → prism(WHITE→3 branches / colour→own channel) → mirror(reflect) → one-way(reflect if reflective) → target(activate if colour accepted; beam continues) → empty**. Loop guard `visited_states["x,y|dir|color"]`; `MAX_STEPS 20000`; multi-pass gate/receiver/fusion resolution with monotonic gate/receiver states and replaced fusion state; `solved = ≥1 required target and all required targets active and no hazard`. Colours: WHITE 0, RED 1, GREEN 2, BLUE 3, YELLOW 4, MAGENTA 5, CYAN 6; a WHITE target accepts anything.

## 8. Levels
15 dev/regression levels (5×5…6×6), **140** handcrafted campaign levels (100 Era-1 in `stage_01..10`, 40 Era-2 in `era2_stage_01`; campaign number = index in `LevelManager.CAMPAIGN_LEVEL_PATHS` + 1; grids 5×6 up to 10×12; optimal moves 1–14 and up to 40 tiles), **34** tutorials (T01–T10 basics, T11–T20 Era-2 mechanics, T21–T28 Fusion, T29–T34 Selector), and **3,000 procedural levels** (generator V4 for ≤2000, **V5 for 2001–3000**, V1–V3 frozen for old saves; deterministic per `(level, generator_version)`; bands Foundation → Advanced Master → Selector Mastery; `verified_optimal_moves = -1` for V5, stars use `intended_moves`). Hints come from `levels/hint_solutions.json` (c1..c140, t1..t34) or the generator's solution — never a runtime solver. Dev tools `LevelSolver/LevelValidator/LevelMetrics` + level editor exist but are dev-only.

## 9. Assets
Canonical gameplay art = **512×512 `*_runtime.png`** files (mirror, target, blocker, hazard, gate open/closed, grid cell, selection and target-glow FX) + Fusion/Selector PNGs + four Era-2 tile faces (purple, opaque). **Emitter, splitter, filter, portal, switch are drawn procedurally** on purpose (their art bakes in a fixed beam). The 1254² source PNGs, `assets/gameplay/pieces/**`, `tiles/**`, old backgrounds/panels and Era-2 skin art are unreferenced and **excluded from Android** (cross-checked: no production-referenced image is excluded). 13 unreferenced images (≈18 MB raw) are still packaged. UI is Rajdhani text on the generated `BeamUI` theme; unified **blue** skin (`EraTheme.UNIFIED_BLUE_THEME_ONLY = true`); gameplay background is `assets/backgrounds/gameplay/bs_bg_gameplay.png` with a node modulate that must not be changed without request.

## 10. UI / mobile
Anchors + containers everywhere; `SafeAreaMargin` (baseline margin + Android display-safe-area insets); `GridManager` fits `grid_width × grid_height` to the available rectangle with square cells (comfortable ≥96 px); HUD = flat `HudPlate` top (back, level name ≤13 chars, MOVES) and bottom (HINT, RESET, PAUSE) with a gold hint attention pulse. Tutorial Select/Level Select use ScrollContainers with PASS-filter cards (drag-scroll fixed). Dialogs for NEW GAME and the Hint-ad confirmation are built in code. Risks: notch/cutout safe area unverified on a device; dense Mastery boards.

## 11. Tutorial
`TutorialManager` (RefCounted owned by `game.gd`) drives `TutorialLevelData.steps` (MESSAGE, REQUIRE_TILE_TAP, WAIT_FOR_TARGET_ACTIVATION, WAIT_FOR_PUZZLE_SOLVED); input is gated only in `GridManager._on_orientable_tile_clicked`; highlight ring + board dim are tied to `set_highlight()`. Progress in `SaveManager.tutorial_*`; tutorials are ad-free; unlocks: T11–T20 need campaign level 100 (or QA), T21 at procedural level 150, T29 at procedural level 1900.

## 12. Save / progression
`user://savegame.json` (schema v5, `.get()`-defaulted, non-atomic writes, no backup). Fields: dev/campaign/tutorial progress dicts, `procedural_current_level`, `procedural_resume_*` (level, seed, generator version, orientations, moves, hint-used), `procedural_best_stars` (`"level|version"`), ad pacing counters, `entitlements`, `age_group`, settings. NEW GAME resets only main procedural progress (keeps settings, tutorials, entitlements, age_group, ad cadence). Survives restart/update; **uninstall loses everything** (no cloud, auto-backup off) except the IAP, which Play Billing restores.

## 13. Ads (AdMob via Poing plugin 5.1.0 → Google GMA Next-Gen SDK 1.4.0, UMP 4.0.0)
All requests are **child-directed for every user** (TFCD TRUE, TFUA TRUE, max rating G; set before `MobileAds.initialize`). Production ids come from gitignored `config/ad_ids.local.json` (Android only today); non-production builds use Google sample ids; missing ids ⇒ ads off, hints free. Interstitial: only at Level Complete → Next Level in normal procedural play, every 4th completion and ≥120 s apart, never in tutorials/QA. Rewarded Hint: HINT → (if an ad is ready) **"GET A HINT? Watch a short ad to reveal a hint. [CANCEL][WATCH AD]"** → rewarded video → hint only from the reward callback; no free fallback; stars capped at 2 when a hint is granted. `beamshift_no_forced_ads` removes interstitials only; rewarded Hint stays. Test device JSON is excluded from release presets. AdMob app review is pending; device-verified (per docs) for the RC3 build only.

## 14. Billing (Google Play Billing plugin 3.3.0)
Product `beamshift_no_forced_ads` (non-consumable, fallback price $3.99; live price e.g. ₹450 retrieved on a device). `StoreManager` → `play_billing_backend.gd`: connect → query details + purchases → purchase → acknowledge → `SaveManager.set_entitlement` → `AdManager.on_forced_ads_removed()`; restore/refund via authoritative purchase queries (only a completed full query can revoke). **Only price retrieval is documented as device-verified**; purchase/ack/restart/restore/reinstall/refund are NOT verified on a device. iOS StoreKit path is unverified.

## 15. Identity (Google Sign-In/Firebase are GONE)
Optional **Play Games** (plugin 3.4.0, Game ID supplied only at export — presets keep it empty; owner's ID `516411257761`): shown/started only for age ranges 13–17 and 18+; for "12 or younger" and unknown, BeamShift's own code never initializes it. Display name only (memory-only); no leaderboards/achievements/cloud. The library's own `PlayGamesInitProvider` starts with the process (unverified effect). iOS: optional Sign in with Apple (flag + name in `user://platform_account.json`). **Neutral age screen** (Android only, first launch): 12 OR YOUNGER / 13–17 / 18 OR OLDER, three identical buttons, stored locally as `SaveManager.age_group`, never transmitted, never affects ads, no in-game editor. Historical lesson: Google Sign-In failed on Play-installed builds until the **Play App Signing certificate** SHA-1 was registered (debug, upload-key and Play-signing fingerprints are three different certificates).

## 16. Android / build state
Presets: "Android Debug" (APK, `builds/android/beamshift-debug.apk`), "Android" (AAB), "iOS". Gradle build, JDK 17, merged release permissions: INTERNET, ACCESS_NETWORK_STATE, READ_BASIC_PHONE_STATE, BILLING, WAKE_LOCK, FOREGROUND_SERVICE, DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, `com.google.android.gms.permission.AD_ID` and the non-standard `android.permission.AD_ID`. Signing keys are not in the repo (CI secrets; upload key SHA-1 `A4:82:77:…:60:5A`). Artifacts in `builds/android` (gitignored): RC3 `beamshift-android-admob-googleauth-rc3.apk` (**owner-verified on a phone**, pre-Firebase-removal), AABs 10001/10002/10004/**10005 (undocumented)**, ~35 debug test APKs; newest **`beamshift-families-policy-test.apk`** (10-03; production AdMob ids + registered test device + Game ID; debug-signed; contains age screen, Hint confirmation, updated policy; **not yet device-tested**).
**How a test APK is built here (recipe):** back up `project.godot`, `export_presets.cfg`, `config/*.json`, `build_config.gd` (keep SHA-1s) → export env vars from `config/ad_ids.local.json`, `PLAY_GAMES_GAME_ID=<id>` → `bash tools/ci/set_build_mode.sh` (must print MODE_PRODUCTION) → `bash tools/ci/stamp_store_config.sh android` (appends `[admob]` to project.godot and sets both `game_id` lines) → `godot --headless --path . --export-debug "Android Debug" builds/android/<name>.apk` (**quote the preset name**) → restore the backed-up files and verify SHA-1s → check with `aapt2 dump badging`/`xmltree` and `unzip -p … assets/config/ad_ids.local.json`. Never change versionCode permanently; never build an AAB unless asked.

## 17. Tests / validation
`powershell -ExecutionPolicy Bypass -File tools/tests/run_coverage.ps1` (copy-based, instrumented): **152 tests, 0 failed, 3,681 assertions** (production) + QA pass 34 tests, 0 failed; ~92% statement coverage. After adding a `class_name` script run `godot --headless --editor --import`. Long solver audits are banned by default (≤ ~60 s per run). Not covered: real touch, real Play services/billing/ads, notch layout, audio loudness, iOS.

## 18. Git state (important)
Branch `dev_abhilas`. **Uncommitted:** 19 modified (`ADS_MONETIZATION.md`, `CLAUDE.md`, `PRIVACY_AUDIT.md`, `STORE_RELEASE.md`, `docs/privacy-policy/index.html`, `game.tscn`, `main_menu.tscn`, `game.gd`, `internet_blocker.gd`, `platform_account.gd`, `save_manager.gd`, `store_config.gd`, `main_menu.gd`, `privacy_policy_text.gd`, `studio_splash.gd`, three test files, `ui_shots.gd`) + untracked age/hint/test files and a stale `project.godot.before_admob_test`. This work = HUD enhancement + Quit removal, native privacy policy + URL, Families hardening (age screen, Hint confirmation, Play Games gating). The separate public repo `AbhilashDeva/beamshift-privacy` (GitHub Pages) received the updated policy (commit `e30d585`); its Pages deploy was still "building" at last check. **Rules: do not commit/push/merge/reset/checkout unless the owner asks; never push to `main` unless explicitly told.**

## 19. Known bugs & risks (details in Parts 29–30)
No open confirmed bugs. Suspected: no watchdog if a full-screen ad never reports closed; a latent double-advance branch in `AdManager.maybe_show_interstitial_after_completion`; a reward earned with no hint candidate is consumed; non-atomic save. Release risks: uncommitted tree, undocumented AAB 10005, version drift (1.0.0 vs 1.0.1), PlayGamesInitProvider/AD_ID posture, stale docs, notch safe-area unverified, Mastery-board readability, V5 optimum unknown.

## 20. Pending work
MUST TEST on device: age screen (3 choices, restart, Back), Play Games gating (under-13 never starts; 13+ optional sign-in), Hint dialog (CANCEL/WATCH AD/no reward/offline/double tap, No-Forced-Ads owned), interstitial cadence, internet blocker + Back, privacy-policy screen, notch/tall-phone layout, **IAP checklist A–F on a Play-installed build**. MUST DECIDE/FIX: PlayGamesInitProvider, AD_ID, ad watchdog, version alignment, commit hygiene, docs refresh. PLAY CONSOLE (owner): **Target audience/Families declaration (9–12, 13–15, 16–17, 18+) NOT submitted**, content rating, Data safety, ads + Advertising-ID declarations, privacy URL, Play Games credentials/fingerprints/testers, AdMob app review, Internal Testing upload. FUTURE: iOS release, music, achievements/leaderboards, Era 3/new mechanics, levels 3001+.

## 21. Workflow rules for ChatGPT / any assistant
* **APK first.** Build and device-test APKs; **do not build or upload an AAB until the owner explicitly says APK testing is approved.**
* **Do not push to `main` unless explicitly asked.** Do not commit/push at all unless asked. Stay on `dev_abhilas`.
* Preserve existing working systems; extend, don't rebuild. Never change `GridManager.MAX_COLUMNS`, square cells, the unified blue theme, the gameplay background modulate, generator V1–V4 outputs, `AdConfig.CHILD_DIRECTED`, or the entitlement semantics without an explicit request.
* Verify repository state (git status, code) before trusting any documentation; if code and docs disagree, the code wins — then fix the doc.
* Never put production ad ids, the Play Games Game ID, keystores or passwords in committed files; stamping is done temporarily and restored.
* Any change to what the game stores/sends/integrates requires updating `scripts/ui/privacy_policy_text.gd`, regenerating `docs/privacy-policy/index.html` (`godot --headless --path . --script res://tools/privacy/build_policy_html.gd`), `PRIVACY_AUDIT.md`, and the privacy repo copy.
* Put scratch/driver scripts and screenshots outside the repo (scratchpad), never in the project root.

## 22. Next recommended task
Install **`builds/android/beamshift-families-policy-test.apk`** on the owner's registered device and run the Families checklist (age screen, Play Games gating, Hint dialog, internet blocker, policy screen); fix findings and re-run the test suite; then (with owner decisions on PlayGamesInitProvider and AD_ID) commit the work on `dev_abhilas`, confirm the public privacy page is live, finish the Play Console declarations, align version numbers, and only after the owner approves APK testing build the signed AAB for Internal Testing and run IAP A–F, Play Games and ads verification on the Play-installed build.

---

## PART 45 — MACHINE-READABLE PROJECT SNAPSHOT

```
PROJECT: BeamShift
PROJECT_ROOT: D:\4Sagez\GodotGames\GitClones\beam-shiflt   # NOTE: "shiflt"
ENGINE: Godot 4.7.1.stable (GDScript, Mobile renderer)
PACKAGE_ID: com.foursagez.beamshift
VERSION_CODE: 10004   # presets; latest local AAB file named 10005 (undocumented); iOS 10000
VERSION_NAME: 1.0.1   # presets; project.godot config/version = 1.0.0; iOS 1.0.0
CURRENT_BRANCH: dev_abhilas
HEAD_COMMIT: c2c7752e64136a174f76add4dc899fb9c3781ac7
WORKING_TREE: DIRTY (19 modified tracked + 11 untracked, none staged)  # plus docs/BEAMSHIFT_MASTER_HANDOFF.md once written
MAIN_SCENE: res://scenes/ui/studio_splash.tscn
ORIENTATION: portrait (1080x1920, canvas_items/expand)
TOTAL_LEVELS: 15 dev + 140 campaign (100 Era-1 + 40 Era-2) + 34 tutorials + 3000 procedural (generated)

AUTOLOADS:
- SaveManager      res://scripts/managers/save_manager.gd
- LevelManager     res://scripts/managers/level_manager.gd
- GameManager      res://scripts/managers/game_manager.gd
- AudioManager     res://scripts/managers/audio_manager.gd
- AdManager        res://scripts/managers/ad_manager.gd
- StoreManager     res://scripts/managers/store_manager.gd
- GodotPlayGameServices  addons/GodotPlayGameServices (uid://bsds5unhjravp)
- InternetManager  res://scripts/managers/internet_manager.gd
- InternetBlocker  res://scripts/managers/internet_blocker.gd
- PlatformAccount  res://scripts/managers/platform_account.gd

CORE_SYSTEMS:
- LaserSystem (pure deterministic simulation)   - GridManager (board/layout/input)   - game.gd (session)
- Procedural generator V1-V5 (levels 1-3000)    - Hint system   - Guided tutorials   - StarScoring
- AdMob (rewarded Hint + interstitial, child-directed)   - Play Billing (no_forced_ads)   - PlatformAccount (Play Games / Apple, optional)
- InternetBlocker (mandatory internet)   - AgeGroup + age screen (Android)   - Native privacy policy
- DEV-ONLY: LevelSolver/Validator/Metrics, level editor, audit scenes, test suite

CORE_SCENES:
- scenes/ui/studio_splash.tscn, age_selection.tscn, main_menu.tscn, settings_menu.tscn, account_screen.tscn, about_screen.tscn,
  privacy_policy_screen.tscn, tutorial_select.tscn, level_select.tscn (QA), pause_menu.tscn, level_complete_popup.tscn, tutorial_*.tscn
- scenes/gameplay/game.tscn, grid.tscn; scenes/tiles/*.tscn (16)

CORE_SCRIPTS:
- scripts/gameplay/{laser_system,grid_types,grid_manager,game,hint_manager}.gd
- scripts/managers/{save_manager,level_manager,game_manager,audio_manager,ad_manager,store_manager,internet_manager,internet_blocker,platform_account,age_group,build_config,star_scoring,tutorial_manager}.gd
- scripts/ads/{ad_config,ad_backend,ad_backend_admob}.gd ; scripts/store/{store_config,play_billing_backend}.gd
- scripts/ui/{beam_ui,safe_area_margin,ui_constants,main_menu,age_selection,hint_ad_dialog,privacy_policy_text}.gd
- scripts/procedural/procedural_level_generator.gd (+ progression/composer/fragments/contract)

LEVEL_FILES:
- levels/level_01..15.gd ; levels/campaign/stage_01..stage_10/level_*.gd ; levels/campaign/era2_stage_01/level_01..40.gd
- levels/tutorial/t01..t34.gd ; levels/hint_solutions.json (174 entries) ; levels/editor_fixtures/ (12) ; levels/fusion_qa, selector_qa

CANONICAL_ASSET_DIRECTORIES:
- assets/gameplay/<type>/*_runtime.png (512px) ; assets/gameplay/{fusion,splitter_selector,prism,one_way_reflector,beam_receiver,remote_emitter}/
- assets/gameplay/grid/ ; assets/gameplay/effects/*_runtime.png ; assets/backgrounds/gameplay/ ; assets/ui/{backgrounds,buttons,dialogs,hud,icons,level_complete,level_select,pause,settings,branding}/
- assets/fonts/ ; assets/sfx/ (22 ogg) ; assets/branding/
- LEGACY/EXCLUDED: assets/gameplay/pieces/, assets/gameplay/tiles/, 1254px source tiles, assets/ui/{panels,gameplay,stage_*}, */era2/ (inactive skin)

ADS:
  STATUS: IMPLEMENTED; production Android ids local-only; child-directed for all; device-verified (docs) for RC3 only; AdMob app review pending
  IMPORTANT_FILES: scripts/managers/ad_manager.gd, scripts/ads/*, scripts/ui/hint_ad_dialog.gd, config/ad_ids.local.json (gitignored), ADS_MONETIZATION.md
  PENDING: device test of Hint confirmation, AD_ID decision, ad-state watchdog, iOS ids, AdMob review

IAP:
  STATUS: CODE COMPLETE; only live price retrieval device-verified
  PRODUCT_IDS: beamshift_no_forced_ads (non-consumable)
  IMPORTANT_FILES: scripts/managers/store_manager.gd, scripts/store/{store_config,play_billing_backend,store_kit_backend}.gd, addons/GodotGooglePlayBilling
  PENDING: purchase/ack/restart/restore/reinstall/refund device checklist A-F; iOS StoreKit

GOOGLE_SIGN_IN:
  STATUS: REMOVED 2026-10-01 (Firebase + Credential Manager plugin deleted, D118); no code pending
  IMPORTANT_FILES: (history only) STORE_RELEASE.md sections 14-17, DECISIONS D115/D118
  PENDING: none (if reintroduced: register debug/upload/Play-App-Signing SHA-1s)

PLAY_GAMES:
  STATUS: IMPLEMENTED (optional identity, display name only, 13+ only); Game ID injected at export; no achievements/leaderboards/snapshots
  IMPORTANT_FILES: scripts/managers/platform_account.gd, scripts/managers/age_group.gd, scripts/ui/{account_screen,age_selection}.gd, addons/GodotPlayGameServices
  PENDING: device test; Play Console credentials/fingerprints/testers; PlayGamesInitProvider decision

SAVE_SYSTEM:
  STATUS: IMPLEMENTED (local JSON v5, non-atomic)
  IMPORTANT_FILES: scripts/managers/save_manager.gd, scripts/managers/age_group.gd
  SAVED_DATA: progress dicts (dev/campaign/tutorial), procedural_current_level, procedural_resume_*, procedural_best_stars, ad counters, entitlements, age_group, sound/music, play_time; (iOS) platform_account.json

ANDROID:
  STATUS: builds from presets work (Gradle, JDK17, minSdk24/targetSdk36, arm64+armv7); test APKs built daily; AAB 10005 undocumented
  IMPORTANT_FILES: export_presets.cfg, project.godot, android/build (gitignored), tools/ci/*.sh, .github/workflows/release.yml
  PENDING: version alignment, device test of latest APK, Play Console, final AAB (only after APK approval)

DEVICE_VERIFIED:   # per documentation (owner), not by me
- RC3 APK (beamshift-android-admob-googleauth-rc3.apk): rewarded Hint, interstitial, progression, About Us, tutorial scrolling, UI (Firebase-era)
- Play Internal Testing install of AAB 10001; live IAP price retrieval

IMPLEMENTED_NOT_VERIFIED:
- Age screen; Hint ad confirmation; Play Games gating/sign-in; mandatory-internet blocker; UI redesign/Firebase-removal builds;
  IAP purchase/ack/restore/reinstall/refund; notch safe-area; native privacy policy screen; iOS (Apple sign-in, StoreKit, TestFlight)

KNOWN_BUGS:
- none confirmed open; suspected: no full-screen-ad watchdog; latent interstitial double-advance branch; reward-without-hint-candidate; non-atomic save

PENDING_RELEASE_BLOCKERS:
- Uncommitted work on dev_abhilas; device verification of latest APK; Families/Target-audience + Data-safety + ads/AD_ID declarations NOT submitted;
  Play Games console setup; PlayGamesInitProvider/AD_ID decisions; version alignment + unexplained AAB 10005; IAP device verification; AdMob review

IMPORTANT_RULES:
- APK first
- Do not build AAB until explicitly requested
- Do not push to main unless explicitly requested
- Preserve existing working systems
- Verify repository state before assuming historical information is still correct

NEXT_RECOMMENDED_TASK:
Device-test builds/android/beamshift-families-policy-test.apk (age screen, Play Games gating, Hint dialog, internet blocker, policy screen); fix findings; owner decisions on PlayGamesInitProvider/AD_ID; commit on dev_abhilas when asked; finish Play Console; align versions; AAB only after APK approval.
```

---

## FINAL QUALITY CHECK (coverage of the brief)

| Item | Where | Item | Where |
|---|---|---|---|
| project.godot | Part 4 | export_presets.cfg | Part 21 |
| every autoload | Part 4 | major scenes | Part 6 |
| major scripts | Part 3 | every current level | Part 9 tables |
| laser architecture | Part 8 | every piece type | Part 7 |
| asset directories / duplicates / legacy | Parts 11, 31 | mobile UI | Part 12 |
| tutorial | Part 13 | save system | Part 14 |
| audio | Part 15 | AdMob (Hint, interstitial) | Part 16 |
| no-forced-ads IAP / Restore | Part 19 | Google Sign-In | Part 17 (REMOVED) |
| Firebase/Google config | Parts 17, 25 | Play Games | Part 18 |
| Android config / export filters | Parts 20, 21 | QA/debug flags | Part 23 |
| Git | Part 24 | docs | Part 25 |
| tests | Part 26 | broken refs | Part 27 |
| working / pending / bugs | Parts 28–30 | legacy | Part 31 |
| constants / flows / startup | Parts 32–34 | history / next steps | Parts 41, 43 |
| master handoff / snapshot | Part 44 / 45 | | |

**UNKNOWN / NOT ENOUGH EVIDENCE (explicit):** whether AAB `…10005…` was ever uploaded or what it contains beyond the permission set; whether any post-2026-10-01 build was device-verified by the owner; real behaviour of `PlayGamesInitProvider` alone; whether the live GitHub Pages policy has finished deploying; AdMob app review status; whether the iOS CI lane has ever run; whether Play Games Console credentials/fingerprints are configured; the exact unique-solution status of all 140 campaign levels (not re-solved here); safe-area behaviour on a notch device; real device audio loudness.
