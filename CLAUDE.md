# CLAUDE.md — Permanent Instructions for Future Claude Sessions

> **Store-release pass (2026-09-26):** owner asked to prepare Google Play + App Store: bundle `com.foursagez.beamshift`, child-directed ads, "No Forced Ads" IAP, cloud save, AAB/iOS presets, CI - code done, console work pending (`STORE_RELEASE.md` section 5). The IAP/SDK additions were explicitly requested; the "no IAP/external SDKs" scope line below predates them.
> **Current phase (2026-09-25): S3.1 NEXT - V5 J/K difficulty refinement.** S1/S2 complete, S3 implemented but NOT certified, S4 (APK) not started. Tool-independent continuation prompt: `NEXT_AI_PROMPT.md`. Nothing from S1-S3 is committed; do not commit/push/build unless asked.

This file is permanent guidance for any Claude session (or account) that
works on BeamShift after this one. It does not expire and is not replaced
by newer milestones — update it, don't discard it.

## Before touching anything

Read, in this order:

1. `CLAUDE.md` (this file)
2. `PROJECT_HANDOFF.md`
3. `CURRENT_STATUS.md`
4. `ARCHITECTURE.md`
5. `DECISIONS.md`
6. `ROADMAP.md`
7. `TEST_PLAN.md`
8. `LEVEL_EDITOR.md` (Milestone 3+ — the level editor's own usage guide; read it before touching `tools/level_editor/` or `scripts/tools/`)
9. `CAMPAIGN_DESIGN.md` (Milestone 4+ — the 100-level campaign's own architecture/design reference; read it before touching anything under `levels/campaign/`)
10. `TUTORIAL_SYSTEM.md` (Guided Tutorial Mode — the T01–T10 tutorial's own architecture/design reference; read it before touching anything under `levels/tutorial/`, `scripts/managers/tutorial_manager.gd`, `scripts/resources/tutorial_*.gd`, `scripts/ui/tutorial_*.gd`, or `scenes/ui/tutorial_*.tscn`)
11. `ERA_2_DESIGN.md` (Era 2 "Refractions" — the Era architecture (`scripts/resources/era_theme.gd`), the four new mechanics (Prism/One-Way Reflector/Beam Receiver/Remote Emitter) and their exact rules, and the T11–T20 tutorial pack's own reference; read it before touching any of those, `assets/**/era2/`, or `levels/tutorial/t11.gd` through `t20.gd`)
12. `PROCEDURAL_GENERATION.md` (Phase 3+ — the procedural level generator's own architecture/design reference: seed derivation, generator versioning, difficulty bands, template catalog, the runtime-vs-dev-time verification split, save contract, and QA Next button behavior; (section 19: the V3 progression generator - fragments, composer, contract bands, shortcut probe, measured evidence) read it before touching `scripts/procedural/**`, `scripts/tools/procedural_audit.gd`, or the procedural branches in `GameManager`/`SaveManager`/`LevelManager`/`game.gd`/`game.tscn`)
14. `ADS_MONETIZATION.md` (AdMob Foundation V1+: AdManager, rewarded hint, interstitial rules, consent, test IDs, release checklist; read before touching `scripts/ads/**`, `scripts/managers/ad_manager.gd`, `addons/admob/**` or the Android Gradle build)
15. `STORE_RELEASE.md` (Store-release pass+: bundle id, child-directed ads, the No Forced Ads IAP, cloud save, export presets, CI, and the owner's console batches; read before touching `scripts/store/**`, `scripts/cloud/**`, `store_manager.gd`, `cloud_save.gd`, `export_presets.cfg`, `.github/workflows/` or `tools/ci/`)
13. `AUDIO_SYSTEM.md` (Audio/SFX Integration Pass+ — the centralized SFX architecture's own reference: semantic event mapping, bus layout, player pooling, per-SFX gain, anti-spam/suppression, Era 2 reuse, and the manual Android audio QA checklist; read it before touching `scripts/managers/audio_manager.gd`, `assets/sfx/**`, `assets/audio/default_bus_layout.tres`, or any `AudioManager.play_*()` call site)

**Never assume a previous chat/session's context exists.** You have no
memory of prior conversations. Inspect the actual project files —
`project.godot`, the scene tree, the scripts — before believing anything
a document claims. If a document and the code disagree, **the code is
authoritative**. Fix the document, note the discrepancy, and move on.

Do not rewrite a working system "for style" without a concrete technical
reason. Do not implement a future milestone unless the user explicitly
asks for it in the current conversation. Update the documentation set
after any meaningful change — a stale doc is worse than no doc.

## Project facts

- **Name:** BeamShift
- **Engine:** Godot 4.7 (developed/validated against 4.7.1)
- **Language:** GDScript, typed where practical
- **Platform:** Android/mobile-first
- **Orientation:** Portrait, but the UI and gameplay layout must be
  resolution/aspect-ratio independent — see "Responsive rules" below.
- **Genre:** Deterministic grid-based laser-reflection logic puzzle.

## Core concept

The player rotates mirrors (and, since Milestone 2, splitters) on a
square grid to redirect one or more colored laser beams from one or more
emitters to one or more targets, through/past filters, portals,
switches, gates, and hazards. Rules stay simple; solutions get hard by
combining mechanics, not by inflating grid size.

## Non-negotiable architecture rules

1. **No physics for puzzle logic.** The laser path is computed by
   deterministic grid simulation (`scripts/gameplay/laser_system.gd`).
   Never use `RayCast2D`, collision layers, or physics bodies to decide
   where the beam goes. Physics may be used later for cosmetic effects
   only, never for solution correctness.
2. **Levels are data, not code paths.** A level is a `LevelData` resource
   (see `scripts/resources/level_data.gd`) with an array of
   `TilePlacement` entries, built via its static `make_*()` factories.
   No level-specific `if level_id == 3` branches anywhere in gameplay
   code.
3. **Reflection rules live in exactly one place:**
   `GridTypes.reflect()` in `scripts/gameplay/grid_types.gd`. Do not
   duplicate the `/` / `\` truth table anywhere else — mirrors AND
   splitters both call into this same function.
4. **Simulation and visuals are separate.** `grid_manager.gd` owns all
   authoritative puzzle state (tile orientations, target/switch/gate/
   hazard state, solved flag). Tile scene scripts (`mirror.gd`,
   `splitter.gd`, `emitter.gd`, `target.gd`, `blocker.gd`, `filter.gd`,
   `portal.gd`, `switch.gd`, `gate.gd`, `hazard.gd`) are dumb views —
   they render and forward input, they never decide gameplay outcomes
   themselves. Gates/switches specifically are **stateless across player
   moves** — every call to `LaserSystem.simulate_until_stable()`
   re-derives gate state from scratch from the current mirror/splitter
   configuration; nothing persists it between rotations. See
   DECISIONS.md D18 before changing this.
5. **Loop protection is mandatory.** `LaserSystem`'s shared
   `visited_states` guard (keyed on `position, direction, color` — see
   ARCHITECTURE.md) must be preserved across every beam branch and every
   emitter. If this is ever removed or narrowed and a level configuration
   creates a beam cycle (including through a splitter or a portal), it
   will hang the engine.
6. **Autoloads are earned, not default.** Only `SaveManager`,
   `LevelManager`, `GameManager`, plus `AudioManager`, `AdManager`,
   `StoreManager` and `CloudSave` (which each earned it - see the
   Audio/Advertising/Store rules), plus the GodotPlayGameServices plugin's
   own `GodotPlayGameServices` autoload, are autoloads (`project.godot` is
   authoritative, eight in total). Don't add a new
   autoload unless something genuinely needs global/persistent access
   from more than one unrelated scene. `TutorialManager` (Guided
   Tutorial Mode, see `TUTORIAL_SYSTEM.md`) is a deliberate example of
   *not* qualifying — its step-machine state is scoped to one tutorial
   play session, so it's a plain `class_name extends RefCounted` that
   `game.gd` instantiates locally, not a 4th autoload.
7. **Mobile touch and desktop mouse share one input path.** Godot's
   default mouse-emulation-from-touch handles this — do not build a
   separate touch-only or mouse-only interaction system.
8. **Beam color is real simulation data, not a rendering tint.**
   `GridTypes.BeamColor` is carried on every beam state through
   `LaserSystem` and consulted by `GridTypes.target_accepts_color()`.
   Never implement a "colored" mechanic by only changing what a `Line2D`
   looks like.
9. **The level editor never ships, and never gets its own simulator.**
   `tools/level_editor/` and `scripts/tools/` (`LevelSolver`,
   `LevelValidator`, `LevelMetrics`) are development-only — excluded from
   the Android export filter (`export_presets.cfg`) and never referenced
   by `game.gd`, `grid_manager.gd`, or any autoload's normal-play code
   path. `LevelSolver` evaluates every candidate board state by calling
   the real `LaserSystem.simulate_until_stable()` — it must never grow
   its own approximate beam logic, no matter how tempting a shortcut
   looks for performance. If a change makes the editor need something
   from gameplay code, import it; never copy/reimplement it.

## Visual assets (Milestone 4A+)

10. **Never use a tile's generated art if it bakes in a fixed-direction
    or fixed-color illustrative beam.** `assets/gameplay/` currently
    contains two overlapping generated-art sets (per-type folders and a
    flat `pieces/` folder - see `DECISIONS.md` D31 before touching
    either). Mirror/target/blocker/gate/hazard have confirmed clean
    (beam-free) source art and use it. Emitter/splitter/portal/switch/
    filter do **not** - every generated asset available for them paints a
    fixed-direction beam (and, for the filter, a fixed blue-in/red-out
    color pair) directly into the tile body, which would misrepresent
    real per-level `direction`/`beam_color`/`output_color` data and
    conflict with `grid_manager.gd`'s dynamically-simulated beam. These 5
    stay on their pre-Milestone-4A procedural `_draw()` rendering until
    clean beam-free art exists for them (regenerated, or cropped/masked
    with actual image-editing tooling - none was available when this
    decision was made). Do not "finish the job" by wiring in the tainted
    art just because it exists.
11. **One shared UI theme.** `themes/beamshift_theme.tres` is the
    project's default `Theme` (`project.godot`'s `[gui] theme/custom`).
    Every `Button` gets its style from it automatically. Don't hand-add
    per-node `StyleBoxTexture` overrides to a `Button` for routine
    styling - use the theme's `DangerButton` type variation (or add a new
    variation) instead. Per-screen `PanelContainer` background art
    (Settings/Level Complete/Pause) is the one deliberate exception -
    each panel's art is visually distinct, so those stay as one-off
    `StyleBoxTexture` overrides directly in that screen's `.tscn`, not in
    the shared theme.
12a. **`--headless` mode cannot test real GUI input dispatch.** Layout/
    anchor math (`Control.get_global_rect()`, `get_viewport().get_visible_rect()`)
    works correctly headlessly and is safe to assert against - but a
    synthetic `InputEventMouseButton` pushed via `push_input()` does NOT
    reliably reach `Control._gui_input()` in `--headless` mode (there's no
    real `DisplayServer`/window backing the GUI input pipeline). Don't
    treat a failed synthetic-click test as proof of an input bug, and
    don't waste time re-discovering this - it was confirmed directly with
    a temporary print inside `_gui_input()` during Milestone 4A.2's Level
    3 investigation (see `DECISIONS.md` D40). Any test claiming to verify
    real tap/click behavior needs a human or a real device.
12b. **When comparing a `Control` rect against a target resolution,
    compare against `get_viewport().get_visible_rect().size` (the logical
    canvas), never the raw physical pixel size.** This project's
    `canvas_items`/`expand` stretch mode guarantees the 1080×1920
    reference is the logical coordinate space's *minimum* size - a
    narrower or same-aspect physical resolution never shrinks it, a
    taller/wider one only ever reveals more of it. Comparing against raw
    physical pixels produces false "overflow" failures (see `DECISIONS.md`
    D43) - this also means any fixed-width popup panel ≤1080px is safe on
    every real phone aspect ratio by construction.
12c. **A puzzle level that "looks unsolvable" during manual testing is
    not automatically a simulation bug.** `LaserSystem`/`GridTypes.reflect()`
    only ever read `tile_orientations` values - they have no concept of
    what a tile *looks like*. A presentation-only bug (a tile's visual
    rotation/state not matching its logical orientation) can make a
    correctly-solvable level look broken without `LevelSolver` or
    `LaserSystem` ever disagreeing, because both operate purely on
    logical state. Before touching level data or simulation code in
    response to a "can't complete this level" report, verify: (1) does a
    direct replay of the solver's own solution path through a real
    `GridManager` reach `is_solved == true` (see `TEST_PLAN.md`'s
    runtime-vs-solver technique)? If yes, the bug is presentational -
    check whether every texture-based tile's visual state genuinely
    matches its logical state (this is exactly how Milestone 4A.2's Level
    3 bug was found - see D40).
12d. **"Cannot visually verify" is a claim to test, not assume.** Every
    visual-integration milestone through 4A.2 asserted headless
    validation was the ceiling and manual/user review was the only way
    to see real pixels. That assumption was **wrong** and cost three
    consecutive failed-QA rounds - this machine has a real GPU, and
    running Godot **without** `--headless` (`godot --path .`, not
    `--headless --path .`) produces genuine rendered frames that
    `get_viewport().get_texture().get_image().save_png()` can capture to
    a PNG Claude can then actually look at with its own image-reading
    tool. Before claiming "cannot visually verify" in any report, try a
    non-headless run first. See `DECISIONS.md` D45-D47 for the technique,
    what it found, and the three-tier AUTOMATED/RENDERED/MANUAL
    validation vocabulary this project now uses - never call an
    AUTOMATED or RENDERED result a MANUAL one; only the user's own review
    is MANUAL and only MANUAL review can approve a milestone. (Also worth
    knowing: with real rendering active, `Input.parse_input_event()`
    correctly dispatches to `_gui_input()` - unlike `Viewport.push_input()`
    under `--headless`, D40 - so real click-driven regression tests are
    possible here too, not just layout math.)
12e. **A "the fix doesn't show up in my build" report is a build-identity
    question first, a code question second.** If automated checks,
    rendered screenshots, and file timestamps all agree the code is
    correct, but the user reports the old behavior on a real device,
    check `export_presets.cfg`'s `version/code`/`version/name` before
    re-diagnosing the code - a same-versionCode reinstall can silently
    leave a device on a stale build depending on how the APK was
    installed. See `DECISIONS.md` D44. Bump the version and add a
    visible, temporary build-identifier label if this is ever in doubt
    again - don't just re-assert the same fix a fourth time.
13. **Android back button is handled, not free.** `project.godot` sets
    `config/quit_on_go_back=false` specifically so `game.gd` can open the
    Pause menu instead of the OS silently exiting the app. This means
    `main_menu.gd`, `level_select.gd`, and `settings_menu.gd` each carry
    their own `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` handler
    replicating their own Back/Quit button, to avoid a silent regression
    on those screens. If you add a new top-level screen, give it the same
    handler (or explicitly decide it needs none and say why) - don't
    assume the OS default still applies anywhere in this project.

14. **Impact VFX read the simulation result; they never feed it.**
    `LaserMirrorImpactFX` (`scripts/gameplay/laser_mirror_impact_fx.gd`,
    D71) is spawned by `GridManager._spawn_mirror_impacts()` purely from
    the already-computed `_last_result` (mirror cells = segment corners,
    outgoing direction from the next corner) — do not add fields to
    `LaserSystem` for it, do not run a second simulation, and do not
    move the spawn into `_redraw_beams()` (that also runs on every
    resize and would respawn effects; the trigger is
    `_simulate_and_draw(true)`, i.e. a player tap, only). VFX nodes must
    stay input-transparent (`Node2D`s under the `mouse_filter=IGNORE`
    `ImpactFX` container), self-freeing, and bounded. Only `MirrorTile`
    (rotatable or fixed) bursts; splitters, targets, filters, portals,
    switches, gates and hazards have no impact VFX yet — adding one is a
    new pass following the same pattern, not a tweak to this one.
15. **Menu backgrounds are per-screen, cover-cropped, and readable via a
    scene-local scrim.** Main Menu / Campaign Select / Tutorial Select use
    `assets/ui/backgrounds/bs_bg_{main_menu,campaign_select,
    tutorial_select}_v2.png` through each scene's existing
    `KEEP_ASPECT_COVERED` `Background` `TextureRect`, with a
    `ReadabilityScrim` gradient (alpha ≤ 0.30) between it and the UI.
    Don't bake UI into these images, don't change global stretch
    settings for them, and don't stack a heavier flat dim on top —
    darken only as much as a rendered screenshot shows is needed
    (D71). The pre-V2 backgrounds are unreferenced/export-excluded.

16. **Gameplay backgrounds must remain visually subordinate to puzzle
    content.** "BeamShift gameplay backgrounds must remain visually
    subordinate to puzzle content. Gameplay readability takes priority
    over environmental decoration." (Minimal Gameplay Background pass,
    `versionCode=47`, see `DECISIONS.md` D90.) The gameplay background
    (`game.tscn`'s root `Background` `TextureRect`) carries
    `modulate = Color(0.22, 0.26, 0.38, 1)` - a non-destructive,
    node-level tint, not an edited PNG. Because `game.gd._apply_era_theme()`
    only ever swaps this node's `.texture` (never its `.modulate`), the
    darkening applies uniformly under every Era, current and future,
    Campaign/procedural/tutorial alike, with zero per-level or per-era
    code. HUD (`TopBar`/`BottomBar`'s own `Background` nodes), grid cell
    art (`TileVisual.active_cell_background`), tiles, and beams are
    separate nodes/draw calls and are deliberately never modulated by
    this. **Do not make this darker or lighter without a fresh,
    explicit request** - the value was chosen and RENDERED-verified
    (D45-D47 tier) at 720x1280/1080x1920/1080x2400 across Campaign
    Levels 1/100/102 (Era 2) and procedural Level 1000. If a future pass
    ever replaces the background PNGs themselves instead of relying on
    this modulate, the new art must itself already be dark, minimal, and
    low-contrast (the modulate is a safety net, not a substitute for
    sourcing genuinely quiet art).

## Level editor rules (Milestone 3+)

- The editor is a plain runtime scene (`tools/level_editor/level_editor.tscn`,
  no `@tool`, no `EditorPlugin`), opened by running it directly (F6) in
  the Godot editor — not the project's `run/main_scene`, not reachable
  from any player-facing menu. See DECISIONS.md D23 before proposing an
  EditorPlugin/dock rewrite.
- A solver result of `"UNKNOWN"` is not the same claim as `"UNSOLVABLE"`
  — `UNKNOWN` means the search budget (`LevelSolver.DEFAULT_MAX_STATES`)
  ran out before the state space could be exhausted. Never collapse
  these two outcomes into one, in code or in anything printed to a user.
- `LevelValidator` errors block Save and Playtest; warnings never block
  anything. Keep that distinction if you add new checks — see
  `LEVEL_EDITOR.md`'s "Interpreting warnings" table for the existing
  error/warning split and why each item landed where it did.
- Playtest must never write to `SaveManager` — see
  `GameManager.is_editor_playtest` and `game.gd`'s branches on it. If you
  add a new place `game.gd` writes save data, check that branch first.
- Levels 1–15 are development/regression test levels, not the final
  campaign. **Milestone 4 (100-level campaign) is underway, and Levels
  1-50 went through a full reboot** (see `DECISIONS.md` D64 and
  `CAMPAIGN_DESIGN.md` sections 1a/2) — **the Campaign is now
  mechanic-agnostic from Level 1 onward**, since the Guided Tutorial
  (T01-T10) teaches every mechanic in isolation; Campaign no longer
  spends a stage teaching one new mechanic at a time, and any level from
  21 onward may freely combine any mechanic the Tutorial already
  covers. The `levels/campaign/stage_01/` … `stage_05/` folder names
  and each file's `stage` field string are **purely internal
  organization now** — the player only ever sees "Level 1" through
  "Level 50," never stage names. Current status per folder: `stage_01/`
  (Levels 1–10, **manually approved**, kept unchanged by the reboot),
  `stage_02/` (Levels 11–20, **manually approved for campaign
  continuation** — user feedback: "these are looking good," kept
  unchanged), `stage_03/` (Levels 21–30, **REPLACED twice** — the
  reboot's own first pass was still too easy and was itself replaced by
  Difficulty Rework Pass 2, manual approval pending), `stage_04/`
  (Levels 31–40, **REPLACED twice** for the same reason, manual
  approval pending), `stage_05/` (Levels 41–45 **REPLACED twice**,
  Levels 46–50 **kept unchanged** including Level 50 "Paradox" — the
  user's own named quality benchmark, 255 states explored — manual
  approval pending for the whole folder). **Difficulty Rework Pass 2**
  (see `DECISIONS.md` D65) rebuilt all 25 of Levels 21–45 a second time
  after the first reboot pass's solver-confirmed move counts (3,2,2,2,2
  / 2,2,2,2,5 / 2,4,2,2,3) came in far below their "Hard+/Very Hard/
  Expert" curve position — the new versions use cross-branch shared
  mirrors, filter order, portal misdirection, switch/gate dependency,
  multi-emitter dependency, and hazard/blocker-guarded false forks for
  real dependency depth, not padded move counts. See
  `CAMPAIGN_DESIGN.md` sections 11f/11g/11h for the full architecture/
  design tables and `DECISIONS.md` D54/D55/D56/D57/D59/D64/D65
  for why campaign levels are a completely separate population from
  1–15, in both level storage (`levels/campaign/` vs `levels/`) and
  save data (`SaveManager`'s `campaign_*` fields vs its original fields
  — namespaced separately specifically because both populations' level
  ids start at 1 and would otherwise collide in the same save keys).
  Don't delete, rename, or "clean up" 1–15 — they remain the
  regression-test population, referenced directly by regression
  scripts and `LevelManager.LEVEL_PATHS`, unrelated to campaign
  progression. **Campaign Levels 51–60 (`levels/campaign/stage_06/`),
  61–70 (`levels/campaign/stage_07/`), 71-80 (`levels/campaign/
  stage_08/`), 81-90 (`levels/campaign/stage_09/`), and 91-100
  (`levels/campaign/stage_10/`) now exist — THE FULL 100-LEVEL CAMPAIGN
  IS COMPLETE.** Five successive post-reboot expansions past 50, each
  built under the identical mechanic-agnostic, no-difficulty-reset rule
  (Level 51 continues directly from the Levels 46-50 region, Level 61
  continues directly from Level 60, Level 71 continues directly from
  Level 70, Level 81 continues directly from Level 80, Level 91
  continues directly from Level 90; see `CAMPAIGN_DESIGN.md` sections
  11i/11j/11k/11l/11m and `DECISIONS.md` D66/D67/D68/D69/D70). Levels
  87-90 introduce the first THREE-stage switch/gate relay (extending
  the two-stage relay pattern to three emitters), resolved by the same
  `simulate_until_stable()` multi-pass semantics with zero new engine
  code — see D69 before building another multi-emitter relay level,
  especially its "unflipped-default collinearity" lesson (two emitters
  sharing a column can create an unintended shortcut even when only ONE
  of the two mirrors involved is left at its unflipped default). Level
  100 ("Culmination") almost repeated D69's circular-dependency mistake
  in its own first draft one milestone later — see D70 before adding
  any gate that depends on something downstream in an existing relay
  chain. **The user has manually tested Levels 1-50 on a real device
  and reported they are good** — treat that as a manually-positive
  baseline, but Levels 51-100 remain automated-validated only; full
  manual QA is still pending for 51-100, do not describe them as
  approved. **Do not create Campaign Levels 101+ or a Stage 11** without
  being explicitly asked — the 100-level structure originally planned
  in `ROADMAP.md` is now complete, and anything beyond it is new scope,
  not a continuation. Don't redesign the just-built Levels 51-100 (or
  the just-rebuilt Levels 1-50) again without being explicitly asked
  either — each unit of work (including this expansion) is validated
  and reviewed on its own, same standing rule as every prior stage.
- **Levels 1-25 were geometrically re-laid out for portrait in Phase 2A**
  (`versionCode=31`, see `DECISIONS.md` D73 and this file's Responsive
  rules section) — board shape and tile positions changed, but every
  level's mechanics/difficulty/solution/decoys are unchanged by
  construction (order-preserving coordinate remap, solver-confirmed
  identical `optimal_moves`/`states_explored` for all 25). This is a
  **geometry-only** pass, layered on top of whatever approval status
  each level already had (1-20's manual approval, 21-25's pending
  approval) — it does not itself constitute new manual approval, and
  does not reopen difficulty review for 1-20.
- **Levels 26-50 were geometrically re-laid out for portrait in Phase 2B**
  (`versionCode=32`, see `DECISIONS.md` D74) using the identical
  order-preserving coordinate-remap technique as Phase 2A, extended to
  the harder splitter/filter/portal/switch-gate/multi-emitter content in
  this block — solver-confirmed identical `status`/`optimal_moves`/
  `shortest_solution_count`/`states_explored` for all 25, zero manual
  geometry corrections needed, zero shortcuts or unintended solves
  introduced. Also **geometry-only**, layered on top of Levels 26-50's
  existing pending-approval status from the Difficulty Rework Pass 2 —
  does not itself constitute new manual approval.
- **Levels 51-75 were geometrically re-laid out for portrait in Phase 2C**
  (`versionCode=33`, see `DECISIONS.md` D75) using the identical
  order-preserving coordinate-remap technique, applied in three
  validated sub-batches (51-60, 61-70, 71-75) with a git checkpoint
  after each. This is the campaign's most mechanically interconnected
  block yet — mutual switch/gate pairs (51, 73), a genuine two-stage
  relay (70), shared-gate perpendicular multi-emitter crossings (68,
  72), post-target beam continuation gating a second branch (65, 74,
  75) — solver-confirmed identical `status`/`optimal_moves`/
  `shortest_solution_count`/`states_explored` for all 25 (24 changed +
  Level 75 unchanged), zero manual geometry corrections needed. **Level
  75 ("Convergence Reaction") was deliberately left unchanged** — its
  distinct-column/row footprint already equals its `grid_width`/
  `grid_height` exactly (zero slack on either axis), so no remap could
  improve it without shrinking its cell size or violating its own
  content. Also **geometry-only**, layered on top of Levels 51-75's
  existing pending-approval status — does not itself constitute new
  manual approval.
- **Levels 76-100 were geometrically re-laid out for portrait in
  Phase 2D — THE FINAL BATCH** (`versionCode=34`, see `DECISIONS.md`
  D76). Same technique, applied to the campaign's hardest and most
  tile-dense block (up to 42 tiles, up to 16 rotatable pieces at the
  solver ceiling, up to 5 emitters, three-stage relays, a four-source
  convergence on Level 80) in three validated sub-batches (76-80, 81-90,
  91-100) with a git checkpoint after each — solver-confirmed identical
  `status`/`optimal_moves`/`shortest_solution_count`/`states_explored`
  for all 25 (21 changed + 4 unchanged), zero manual corrections needed.
  **Levels 85, 91, 95, and 98 were deliberately left unchanged** — same
  zero-slack situation as Level 75, confirmed to recur naturally as
  levels grew more content-dense. **Level 100 ("Culmination") — the
  definitive Era 1 finale — was fully verified**: all five emitter
  routes, all three relay stages, both portal transitions, the symmetric
  convergence, the fixed-mirror backward-reasoning step, target
  continuation, filter/color behavior, and the unique shortest solution
  all confirmed identical before/after. **THIS COMPLETES THE PORTRAIT
  RE-LAYOUT OF ALL 100 CAMPAIGN LEVELS** — final audit: 100/100
  SOLVABLE, zero levels below the 90% height / 85% width utilization
  targets, cell sizes 87-174px (average 122.4px). Also **geometry-only**
  — does not itself constitute new manual approval for any level.
  **Do not create Campaign Levels 101+ or re-layout work beyond this
  point without being explicitly asked** — the entire 100-level
  portrait conversion effort (Phases 2A-2D) is complete; any further
  work here is new scope.
- **`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`** (currently
  `true`) makes every implemented campaign level selectable from Level
  Select regardless of real unlock progress — development/QA only. It
  changes nothing about `SaveManager`'s actual completion/unlock/star/
  best-move data; it only overrides what `LevelManager.
  is_campaign_level_selectable()` reports, which is the one function
  `level_select.gd` calls to decide a card's `disabled` state. Scales
  automatically to whatever `CAMPAIGN_LEVEL_PATHS` currently contains —
  no edits needed when Stage 5+ are added. **MUST be set to `false`
  before any final production release build** — see `DECISIONS.md` D58
  and the release checklist in `TEST_PLAN.md`.

## Guided tutorial rules (Guided Tutorial Mode+)

- T01–T10 (`levels/tutorial/`) are a **completely separate population**
  from both the 15 dev/regression levels and the 100-level campaign —
  never counted toward campaign level ids, never sharing
  `SaveManager` fields with either. See `TUTORIAL_SYSTEM.md` for the
  full architecture and `DECISIONS.md` D60 for the implementation
  writeup.
- **Tutorial and Campaign must always use the identical gameplay
  engine.** A `TutorialLevelData`'s `tiles` are simulated by the same
  `LaserSystem`/`GridManager` as every campaign level — never introduce
  a tutorial-only variant of a mechanic's behavior. The only tutorial-
  specific code is the scaffolding around real gameplay (forced
  interaction, highlighting, instructional text), never the simulation
  itself.
- Forced interaction is gated at exactly one place —
  `GridManager._on_orientable_tile_clicked()`, via
  `interaction_locked`/`interaction_restricted_to` (both default to
  their inert, Campaign-unaffecting values). `TutorialManager` is the
  only code that ever sets them. Don't add a second, competing
  interaction-filtering mechanism elsewhere.
- `GridManager.move_made` fires **before** simulation runs;
  `GridManager.simulation_updated` fires **after** (target/switch/gate/
  hazard state already updated). A tutorial step that needs post-move
  state (e.g. "is this target now activated") must use
  `simulation_updated`, never `move_made` — see `DECISIONS.md` D60 for
  the real bug this distinction fixed. Don't rediscover it.
- Do not fake an unimplemented mechanic in a tutorial. If a future
  tutorial needs a mechanic that doesn't exist yet in `LaserSystem`/
  `GridTypes`, implement the real, reusable mechanic (consistent with
  rules 1–5 above) or leave that tutorial slot explicitly pending and
  say why — never invent tutorial-only gameplay behavior.
- Don't create Tutorial levels beyond T34 (T21-T28 = Fusion pack, T29-T34 = Splitter Selector pack), and don't add mechanics to
  an existing tutorial that aren't the one it's meant to teach, without
  being explicitly asked — same standing scope discipline as Campaign
  stages.
- **A `REQUIRE_TILE_TAP` step must never lock input to a tile that
  doesn't exist.** `GridManager.has_orientable_tile(pos)` is checked
  before `TutorialManager` sets `interaction_restricted_to` — if the
  target tile isn't found, input is left unrestricted and a loud
  `push_error` fires instead of silently softlocking the game forever.
  Keep this fail-safe if you touch `_apply_step_to_grid()`.
- **When hand-writing or hand-editing any `.tscn` file, verify the root
  node's `script = ExtResource(...)` line actually exists** if that
  node is meant to carry a custom script — declaring the script as an
  `ext_resource` at the top of the file is not enough on its own. A
  node with a declared-but-unattached script silently resolves to its
  plain base engine type (no import/parse error at all), and the bug
  only surfaces as a generic runtime "Invalid access to property or
  key" error the first time code touches a member only the custom
  script would provide — which can then abort the rest of that
  caller's `_ready()`, producing misleading symptoms (e.g. "pressing
  Reset fixes it" because an earlier-wired signal connection survived
  the crash while a later call, like `_load_current_level()`, never
  ran). This exact mistake shipped in `versionCode=18` in two files
  (`tutorial_panel.tscn`, `tutorial_complete_popup.tscn`, independently)
  and caused a real failed Android manual QA round — see
  `TUTORIAL_SYSTEM.md` section 11 and `DECISIONS.md` D61. Don't
  re-discover this; check it directly whenever a fresh scene
  instantiation of anything with a hand-written `.tscn` behaves as if a
  whole branch of `_ready()` never ran.
- **The tutorial board dim (`TutorialDimOverlay`) is coupled 1:1 to
  `GridManager.set_highlight()`/`clear_highlight()` — it is not a
  separate state machine and must never become one.** Don't add a
  standalone "show dim"/"hide dim" call anywhere; every dim
  show/hide must go through `set_highlight()`/`clear_highlight()` (or
  `suspend_tutorial_focus()`/`resume_tutorial_focus()` for the Pause-menu
  case) so the dim can never outlive or precede the highlight it exists
  to support. `TutorialHighlight.FOCUS_PADDING` is the single source of
  truth both the ring and the dim's cutout read for their shared
  geometry — don't hardcode a second padding value anywhere. See
  `TUTORIAL_SYSTEM.md` section 12 and `DECISIONS.md` D62 (this was added
  after a manual video QA found the board dim too strong/unreliable and
  the highlight too weak against it — the actual root cause was that no
  dim overlay had ever existed before, not a stale-state bug).
- **When a `.tscn` file instances another scene (`[node ... instance=
  ExtResource(...)]`), any `anchors_preset`/`anchor_*`/`offset_*` value
  re-declared on that instance node completely replaces the instanced
  scene's own layout for that node — it does not merge with it.**
  Before adding a layout override to an instance node, check whether
  the base scene already anchors itself correctly; if so, don't
  override it at all (only override genuinely-instance-specific state
  like `visible`/`unique_name_in_owner`). `game.tscn`'s `TutorialPanel`
  instance redundantly re-declared full-screen anchors on top of
  `tutorial_panel.tscn`'s own correct bottom-anchored layout, silently
  making its `Panel` child (default `mouse_filter = STOP`) cover the
  entire screen and intercept every gameplay tap — invisible on screen
  because the panel's background blended into BeamShift's dark art, but
  it blocked 100% of tutorial forced-tap interaction. **This will not
  show up by reading either `.tscn` file in isolation** — the base
  scene's anchors were never wrong; only the instance's override was.
  The only way to catch this class of bug is to dump the *runtime*
  `mouse_filter`/`get_global_rect()` of the instantiated node and
  compare it against what the base scene's own file declares. See
  `TUTORIAL_SYSTEM.md` section 13 and `DECISIONS.md` D63. Don't
  re-discover this; check it directly whenever a UI element is visible
  but doesn't respond to input, especially one added via a `PackedScene`
  instance in a parent `.tscn`.

## Era 2 rules (Era 2 Foundation+)

- **BeamShift currently uses the existing BLUE/CYAN sci-fi visual
    theme as its single active gameplay theme across all gameplay
    content.** Difficulty, procedural band, tutorial stage, and
    mechanic availability do not change the global visual skin. Purple
    Era 2 assets are retained but inactive. (Unified Blue Theme Fix,
    `versionCode=48`, see `DECISIONS.md` D91.)
    `EraTheme.UNIFIED_BLUE_THEME_ONLY := true`
    (`scripts/resources/era_theme.gd`) is the ONE authoritative switch -
    checked first inside `EraTheme.for_era()`, forcing every caller
    (gameplay background/grid/HUD via `game.gd._apply_era_theme()`,
    `level_button.gd`/`tutorial_button.gd`'s accent tint,
    `level_select.gd`/`tutorial_select.gd`'s background) to always get
    Era 1's asset set, regardless of `era_number`. **Don't add a second,
    competing "is this Era 2" check anywhere else** (an `if level >=
    100` in a different script, a per-scene override, etc.) - every
    visual-theme caller already routes through `for_era()`, so flipping
    this one constant is the complete fix or the complete revert; a
    second check would immediately violate the "single authoritative
    rule" this flag exists to be. `EraTheme.get_era_for_level()`/
    `get_era_for_tutorial()` (the pure numeric band functions) and
    everything that reads them directly for non-visual purposes -
    `LevelManager.is_tutorial_level_selectable()`'s T11-T20 unlock gate,
    `game.gd`'s Level 100->101 `era_transition` popup banner - are
    completely unaffected by this flag and must stay that way; neither
    of them reads anything from `for_era()`'s *returned object*, only
    the numeric era itself, which is exactly what keeps unlock
    progression and mechanic-teaching order independent of the theme
    decision. `_build_era_2()` itself is untouched, not deleted -
    flipping the flag back to `false` fully restores Era 2's violet
    skin with no other code change needed.
    **Prism/One-Way Reflector/Beam Receiver/Remote Emitter's own tile
    textures are genuinely purple-specific art** (`*_era2.png`,
    unconditionally `preload()`-ed in each tile's own script, never
    routed through `EraTheme` at all) and were deliberately left
    unchanged by this fix - per the standing "never generate images,
    never destructively recolor a source PNG" rule, they remain the one
    visible purple element in normal gameplay (small tile icons, not a
    global skin) until a genuine blue-specific replacement asset is
    created. Don't "fix" this by reintroducing an Era 2 texture swap for
    them, and don't treat their continued purple color as a bug this
    flag should have caught - it structurally couldn't.
- **Era content is looked up through `EraTheme`
  (`scripts/resources/era_theme.gd`), never by branching on a raw
  level/tutorial id.** It's a plain `Resource` with static helpers, not
  a 5th autoload (rule 6 - it owns no per-session state). Era 1's theme
  fields are all `null` on purpose, read as "use the existing hardcoded
  Era 1 asset" by every caller - this is what keeps Levels 1-100 and
  T01-T10 visually byte-for-byte unchanged no matter how many future
  eras get added. See `ERA_2_DESIGN.md` section 1.
- **A new PNG needs a real import pass before `preload()` will load
  it, and a new `class_name` script needs one before other scripts can
  reference its type.** `godot --headless --path .` (game mode) does
  not scan for new assets or rebuild the global class cache - run
  `godot --headless --editor --import` once after adding/moving any
  asset or script. Don't waste time re-diagnosing a "Parse Error:
  Identifier ... not declared" or "has no resource loaders" error as a
  code bug before trying this - confirmed directly during Era 2
  Foundation. See `ERA_2_DESIGN.md` section 2.
- **`assets/gameplay/pieces/**` is excluded from the Android build.**
  It exists for genuinely-unused reference art - the same folder whose
  blocker/hazard files caused a real shipped-build bug once before (D51).
  Any new tile's actually-`preload()`-ed art belongs in its own
  per-tile-type folder (`assets/gameplay/<type>/`), matching the
  existing one-folder-per-type convention, never under `pieces/**` -
  confirmed against a real exported `.pck` (`ResourceLoader.exists()`),
  not just source, per rule 12a. See `ERA_2_DESIGN.md` section 2.
- **Prism/One-Way Reflector/Beam Receiver/Remote Emitter's exact rules
  live in `GridTypes` and `LaserSystem`, documented in full in
  `ERA_2_DESIGN.md` sections 3-5 - don't re-derive them from first
  principles or invent a variant behavior.** In short: a Prism's three
  channel directions are derived from `reflect()`, never a new table; a
  One-Way Reflector's reflective side is derived from its existing
  `MirrorOrientation` field (no second stored bit); a Beam Receiver ->
  Remote Emitter dependency is resolved by `simulate_until_stable()`
  exactly like switch -> gate already is (a new `receiver_states`
  dictionary threaded alongside `gate_states`, same monotonic-merge
  convergence guarantee).
- **`LevelManager.UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING`** (currently
  `true`) bypasses T11-T20's real unlock gate (Level 100 completed)
  *unconditionally*, the same way `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`
  bypasses campaign unlock - not merely the era gate on top of an
  otherwise-real T01-T10 progression check. Getting this wrong (checking
  real sequential unlock first, applying the override only after) is a
  real bug this project shipped once already - caught by an actual
  rendered Tutorial Select screenshot, not by source review. **MUST be
  set to `false` before any final production release**, same as the
  campaign flag.
- **Do not create Campaign Levels 101+, T29+, or a new Era without being
  explicitly asked** - same standing scope discipline as every other
  milestone in this project. Era 2 Foundation (this pass) intentionally
  stops at the new mechanics, T11-T20, and visual theming architecture;
  the actual 100-level Era 2 campaign is separate, future work.
- **Levels 101-110 now exist** (Era 2 Levels 101-110 QA pass, see
  `DECISIONS.md` D80 and `CAMPAIGN_DESIGN.md` section 12) - the first
  real Era 2 campaign content, following directly from Level 100/T20,
  the introductory arc for the three new mechanic families (Prism,
  One-Way Reflector, Beam Receiver/Remote Emitter) combined with
  selected Era 1 mechanics. Stored under `levels/campaign/
  era2_stage_01/` (not `stage_11/` - this is genuinely new scope, not a
  continuation of the original 100-level plan's numbering, per
  `CAMPAIGN_DESIGN.md`'s own guidance on this), registered in
  `LevelManager.CAMPAIGN_LEVEL_PATHS` after Level 100's entries.
  `get_campaign_level_count()` is now 110, and everything that reads it
  dynamically (Level Select, `game.gd`'s next-level/unlock logic,
  `SaveManager`'s campaign dictionaries) needed zero further code
  changes - confirmed, not assumed, by a real headless run exercising
  `SaveManager.record_campaign_level_result(100, ...)` and checking
  Level 101 actually unlocks. `game.gd`'s `era_transition` banner
  (Level 100 -> Era 2) was the one real thing that DID need a code fix
  here - it was keyed off "current level == last implemented level",
  which would have silently shifted from firing at 100 to firing at 110
  the moment these were added; it now compares `EraTheme.get_era_for_
  level()` across the level boundary instead, which is both correct
  today and automatically correct for a future Level 200 -> Era 3
  boundary. All ten are solver-confirmed `SOLVABLE` with a unique
  shortest solution (`shortest_solution_count == 1`) and zero
  `LevelValidator` errors, on the first authoring attempt, for every
  level. **Update: Levels 111-120 now exist too, see below - do not
  create Campaign Levels 121+ without being explicitly asked.**
- **Levels 111-120 now exist** (Era 2 Levels 111-120 QA pass, see
  `DECISIONS.md` D81 and `CAMPAIGN_DESIGN.md` section 16) - a
  user-requested follow-up authorized before Levels 101-110 had even
  finished manual Android QA, deepening the same three Era 2 mechanic
  families with **no new mechanics**. Same `levels/campaign/
  era2_stage_01/` folder, continuing local `level_id` 11-20.
  `get_campaign_level_count()` is now 120. **Three real shortcut bugs
  were found and fixed by the solver during authoring, all one failure
  shape**: a beam that has already activated its own required target
  keeps traveling in its current direction (targets never stop a beam,
  by design) into a second mechanic it was never meant to touch. Level
  112 and 118 each needed one fix (a shared column let one beam/emitter
  accidentally satisfy or power two things at once). **Level 120 needed
  two fix attempts** - the first only changed a rotatable tile's
  *default* orientation to a value that happened to avoid the
  collision, but the solver then found an *alternate*, equal-length
  solution that deliberately mis-set that same tile back to re-open the
  identical shortcut (`shortest_solution_count` came back 2, not 1).
  The real fix relocated the tile so no orientation of it was ever
  physically reachable by the stray beam. **Lesson worth remembering
  for any future level in this project: a rotatable tile's default
  orientation being "safe" today says nothing about whether flipping it
  stays safe — only physical unreachability of the interaction does.**
  Verify this by brute-force replaying every rotation combination at
  the target move count if a `shortest_solution_count > 1` ever shows
  up again, not just by eyeballing the solver's first solution path.
  **Update: Levels 121-130 now exist too, see below - do not create
  Campaign Levels 131+ without being explicitly asked.**
- **Levels 121-130 now exist** (Era 2 Levels 121-130 "deep dependency
  pass", see `DECISIONS.md` D82 and `CAMPAIGN_DESIGN.md` section 17) -
  user-requested before ANY prior Era 2 level batch had manual QA,
  still **no new mechanics**, moving into whole-board reasoning (shared
  resources across distant regions, reciprocal relays, backward-
  reasoning near-solution traps, a four-way convergence in Level 130).
  `get_campaign_level_count()` is now 130. **Two more issues found
  during authoring**: Level 123 had a plain grid-bounds error (a tile
  placed one row outside the board — caught immediately by
  `LevelValidator`'s own explicit bounds check, not the solver). Level
  127 surfaced a genuinely NEW failure shape beyond the "beam continues
  past its own target" family above: a wrong-orientation mirror's stray
  path crossed a second, unrelated mirror elsewhere on the board, and
  THAT mirror's own default orientation happened to complete an
  accidental shortcut around the level's Portal. Fixed with a
  `BLOCKER` placed to intercept only the stray path. **General lesson,
  now standing alongside the one above: tracing a wrong rotation's
  path only as far as "it exits harmlessly" is incomplete if that path
  crosses ANY other tile at all — that tile's own current orientation
  must also be checked, since `LaserSystem` has no concept of "which
  mechanic a cell belongs to" and treats a stray beam exactly like an
  intentional one.** **Update: Levels 131-140 now exist too, see below
  - do not create Campaign Levels 141+ without being explicitly
  asked.**
- **Levels 131-140 now exist** (Era 2 Levels 131-140 "advanced
  convergence pass", see `DECISIONS.md` D83 and `CAMPAIGN_DESIGN.md`
  section 18) - user-requested before ANY of the three prior Era 2
  level batches had manual QA, still **no new mechanics**.
  `get_campaign_level_count()` is now 140. **The most shortcut-prone
  batch yet - 5 of 10 levels needed fixes during authoring**: one
  genuine authoring error (a mirror inserted into an already-complete
  straight path made its own target permanently unreachable -
  `UNSOLVABLE`, not a shortcut); two instances of the established
  `WHITE`-accepts-any-color target bypass, including a new "swapped
  routing" variant (a shared reflector's wrong orientation swapped
  which of two beams reached which of two targets, invisible only
  because both used the default `WHITE`); and one genuinely NEW failure
  shape (Level 138) - a shared One-Way Reflector's two beams approached
  from the SAME side rather than genuinely opposite sides, so one
  beam's approach corridor doubled as the other's exit corridor,
  needing a full geometric rebuild (opposite-side approach) to fix.
  **General lesson, now standing alongside the two above: for any
  shared-resource level, check BOTH beams' entire corridors - approach
  AND exit, in every orientation - for overlap, not just whether their
  entry directions differ.** Per the user's own explicit instruction, a
  **manual Android review checkpoint is now recommended before Levels
  141+** - four consecutive unreviewed Era 2 campaign batches (40
  levels) currently await real-device feedback together, the largest
  backlog this project has carried at once. **Do not create Campaign
  Levels 141+ without being explicitly asked.**
- **T11-T20's Tutorial Select cards were briefly regressed to a tall
  poster/card shape** (`bs_level_card_era2.png`, 1024x1536px) before
  this pass - the fix (see `DECISIONS.md` D79) is to never swap a
  button's texture for a differently-shaped Era art asset; instead tint
  the SAME square frame Era 1 buttons use via `TextureRect.modulate =
  EraTheme.for_era(n).accent_color` (`Color.WHITE` for Era 1 = a no-op
  tint). Both `tutorial_button.gd` and `level_button.gd` (the latter
  pre-emptively, since Level 101+ didn't exist until this same pass)
  now follow this pattern - don't reintroduce a texture-swap for a
  future Era's button art without first confirming that art is
  pixel-proportioned for the existing 240x253 button box.
- **Temporary QA/test driver scripts and screenshots belong in the
  environment's scratchpad directory, never the project root.** The
  QA/Hardening pass (`DECISIONS.md` D78) left ~40 `_tmp_*`/`_qa_*` files
  (~120 MB) in the project root between test runs; a first APK export
  (`export_filter="all_resources"`) swept every one of them into the
  package, making the APK *larger* than before any optimization work
  started. Caught by inspecting the exported APK's own zip listing
  (`unzip -l`), not by trusting the byte-count delta alone - **a changed
  APK size is not proof of what changed; list the archive contents.**
  Always delete (or scratchpad-isolate) every temporary driver script/
  screenshot before the final export of any pass that touches
  `export_presets.cfg` or claims an APK size number.
- **`godot --headless --path . --export-pack "Android Debug" out.pck`
  did not appear to honor `export_presets.cfg`'s `exclude_filter` in
  this environment/Godot version** (confirmed D78: even the long-
  established `assets/gameplay/pieces/**` pattern showed as still
  "present" when checked via `--main-pack` against that `.pck`) - **the
  reliable technique is a real `--export-debug`/`--export-release`
  export followed by `unzip -l` (or `aapt2 dump badging` for version
  metadata) against the actual `.apk`**, not `--export-pack` +
  `--main-pack`. D51/D77 both used `--export-pack` successfully before;
  don't assume that still holds without re-confirming - prefer the real
  APK check going forward.
- **A `StyleBoxTexture`'s `content_margin_*` defaults to `-1` ("same as
  the matching `texture_margin_*`") for a reason - don't override it to
  a smaller value inherited from a different (e.g. flat) style without
  re-checking the new texture's own margins.** Doing so during the
  QA/Hardening pass (D78) placed `TutorialCompletePopup`'s buttons
  inside the new Era 2 frame's crystal ornaments; fixed by removing the
  override. Relatedly, a `PanelContainer` sizes to its own content, so a
  themed frame with large top/bottom margins needs the panel's
  `custom_minimum_size` forced to at least that margin sum or the
  frame's fixed corner art gets squeezed smaller than it was designed
  for - both are RENDERED-verification-only bugs, invisible from source.
- **A card/panel `TextureRect` using `STRETCH_KEEP_ASPECT_CENTERED`
  silently misaligns once its texture's aspect ratio changes** (D78:
  `level_button.gd`/`tutorial_button.gd`'s Era 2 card art is a much
  taller aspect than the original near-square button art) - prefer
  `STRETCH_KEEP_ASPECT_COVERED` with `clip_contents = true` for any
  button/card background that different-era art might swap in, and
  verify with a real render, not just by checking the code compiles.

## Responsive rules (do not regress these)

- **BeamShift supports arbitrary rectangular grids and sizes the board
  against the real gameplay rectangle between Top HUD and Bottom HUD**
  (Phase 1 rectangular-grid architecture pass, see `DECISIONS.md` D72 and
  `ARCHITECTURE.md` "Rectangular grid layout"). `grid_manager.gd`'s
  `_recalculate_layout()` (triggered by the `resized` signal) fits
  `grid_width` columns and `grid_height` rows against that Control's own
  rect (already exactly the space `game.tscn`'s `CenterArea` leaves
  between the two aspect-locked HUD bars) using **independent per-axis
  candidates** — `cell_size = floor(min(available_width / columns,
  available_height / rows))`, minus a single small centralized
  `GRID_SAFETY_MARGIN` (8px @ 1080-wide reference) inset on every side —
  not `min(size.x, size.y) / max(grid_width, grid_height)`. A board no
  longer has to be square to use the available space well: a wide board
  fills width, a tall board fills height, a square board still behaves
  exactly as before. Cells are still always square (`cell_size` is one
  scalar applied to both axes via `TileVisual.cell_size`'s setter — never
  stretch a tile's X and Y independently) and the grid is still centered
  in whatever space remains. Do not hardcode pixel positions for
  gameplay or menu elements, and do not reintroduce a
  `min(size.x, size.y)`-style square-only formula.
  `GridManager.get_layout_metrics()`/`format_layout_diagnostics()` are
  development-only diagnostics (never shown to players) for checking a
  candidate shape's resulting cell size and width/height utilization
  before committing to it.
  **Campaign Levels 1–25 were re-laid out for portrait in Phase 2A** (see
  `DECISIONS.md` D73) — each now uses a taller (or taller+narrower)
  board than its original square-ish shape, chosen individually per
  level's own content, reaching 94-99.8% height / 86-99.8% width
  utilization at the 1080×1920 reference. **This was done via an
  order-preserving coordinate remap, not a hand redesign** — every tile
  sharing an old row/column still shares the corresponding new row/
  column, and relative ordering along each axis is preserved, which
  makes it mathematically impossible for the remap to change which
  cells a beam hits or in what order (only the empty-cell distance
  between them changes). Solver-confirmed: all 25 levels' `optimal_moves`,
  `shortest_solution_count`, AND `states_explored` came out identical
  before/after. **If you ever need to change a level's `grid_width`/
  `grid_height`/tile positions again (for Levels 26-100, or to touch
  1-25 further), prefer this same remap technique over hand-editing
  coordinates** — it's the only way to change board geometry with a
  provable, checked guarantee of unchanged difficulty, not just a hope.
  **Campaign Levels 26–50 were re-laid out for portrait in Phase 2B**
  (`versionCode=32`, see `DECISIONS.md` D74), reusing this exact
  technique unchanged, now proven across the block's harder mechanics
  (splitters, filters, portals, switch/gate dependency, multi-emitter
  levels) — 90-100% height / 90-100% width utilization at the 1080×1920
  reference across all 25 (individually chosen per-level shapes, 6x7
  through 9x10, not one blanket size), solver-confirmed identical
  `status`/`optimal_moves`/`shortest_solution_count`/`states_explored`
  for every level, zero manual geometry corrections needed. Level 50
  ("Paradox," the campaign's own named quality benchmark) went 7x7→7x8
  at an unchanged 124px cell size (the same zero-cost row-growth pattern
  Phase 2A used for Level 20), preserving its exact reasoning structure.
  **Campaign Levels 51–75 were re-laid out for portrait in Phase 2C**
  (`versionCode=33`, see `DECISIONS.md` D75), reusing this exact
  technique unchanged across three validated sub-batches (51-60, 61-70,
  71-75), on the campaign's most mechanically interconnected block yet
  (mutual switch/gate pairs, a two-stage relay, shared-gate
  perpendicular multi-emitter crossings, post-target continuation
  gating a second branch) — solver-confirmed identical `status`/
  `optimal_moves`/`shortest_solution_count`/`states_explored` for all 25
  (24 changed + Level 75 deliberately left unchanged, already fully
  packed on both axes with zero slack to remap). Average cell size grew
  96.7px→109.2px (+13.0%, smaller than Phase 2B's +25.6% since this
  block starts with markedly less compaction slack — several boards
  were already using every column or row of their old grid).
  **Campaign Levels 76–100 were re-laid out for portrait in Phase 2D —
  THE FINAL BATCH** (`versionCode=34`, see `DECISIONS.md` D76), on the
  campaign's hardest and most tile-dense block (up to 42 tiles, up to
  16 rotatable pieces at the solver ceiling 2^16=65536, up to 5
  emitters). 6 levels compacted 10-wide→9-wide (+10% cell size); 15
  levels held their exact 87px cell while gaining zero-cost row growth
  to the full safe ceiling (height utilization 82.6%→99.1%); 4 levels
  (85, 91, 95, 98) were deliberately left unchanged, the same zero-
  slack situation Level 75 first established, now confirmed to recur
  naturally. Level 100 ("Culmination") — the definitive Era 1 finale —
  went 10x10→10x12 at zero cost, all five emitter routes/three relay
  stages/both portals/symmetric convergence/fixed-mirror backward
  reasoning fully verified identical. **THIS COMPLETES THE PORTRAIT
  RE-LAYOUT OF ALL 100 CAMPAIGN LEVELS.** Final read-only audit across
  1-100: 100/100 SOLVABLE, zero levels below 90% height / 85% width
  utilization, cell sizes 87-174px (avg 122.4px), avg width util 98.2%,
  avg height util 95.6%. **Do not create Campaign Levels 101+ or start
  any further re-layout work without being explicitly asked** — the
  100-level portrait conversion effort (Phases 2A-2D) is complete; any
  further work here is new scope. See `ROADMAP.md` for the long-term
  "Era" product direction this was asked to document (Tutorial + one
  continuous PLAY mode replacing the separate Campaign/Endless framing,
  100 levels per Era; the current, complete 100-level campaign plus
  T01-T10 together constitute Era 1) — **documented only, not
  implemented**; don't start building Era 2 without an explicit,
  separate request. **Superseded by the Phase 1 direction below** — see
  `ROADMAP.md` for the current 2,000-level procedural target.
- **Phase 1: Shared Adaptive Gameplay Layout Foundation** (`versionCode=41`,
  `3.5.0-ADAPTIVE-LAYOUT-QA`, see `DECISIONS.md` D84) confirmed the
  rectangular-grid/portrait-relayout architecture above is already the
  ONE shared, centralized layout every level uses — no level has ever
  owned HUD positioning — and added the contract a future procedural
  generator targets: `GridManager.MAX_COLUMNS := 8` (a ceiling for NEW
  procedural board profiles only — 58 existing dev/campaign/tutorial/
  fixture levels already exceed it and are grandfathered, never
  modified), `GridManager.MIN_COMFORTABLE_CELL_SIZE := 96.0` (px at the
  1080-wide reference canvas, derived from Android's 48dp minimum touch
  target), and `GridManager.is_board_profile_comfortable(columns, rows,
  playable_size) -> Dictionary` — a pure function reusing the exact
  `_recalculate_layout()` cell-size formula, so a generator (or a
  diagnostic script) can validate a candidate shape BEFORE committing to
  it, without ever deriving a pixel value itself. Verified across the
  full 5-resolution test matrix (720x1280 through 1080x2560) against 12
  representative procedural-shaped profiles: 136/140 comfortable (see
  correction below — now 140/140).
  **CORRECTION (Full-Screen Board Correction, `versionCode=43`, see
  `DECISIONS.md` D86): this pass's own conclusion was wrong.** It
  validated the layout formula headlessly at the 1080x1920 reference
  only and never rendered a real campaign level at any other required
  resolution — the user then found real, reportable wasted board space
  on a real phone (Level 27, `versionCode=42`). Root cause: `canvas_
  items`/`expand` stretch mode reveals more logical canvas height on any
  device taller than the 1080x1920 floor (most real phones today), and
  a width-bound board's `cell_size` doesn't grow to match, so height
  utilization silently degrades on taller devices with zero code or
  level change — Level 27 (7x8) went from 94.2% height utilization at
  the reference down to 64.7% at 1080x2400. **Do not trust a headless-
  only or single-resolution rendered check for a gameplay layout claim
  again — render an actual campaign level, not just a diagnostic, across
  the full resolution range, per the lesson in D86.**
- **Full-Screen Board Correction** (`versionCode=43`,
  `3.6.1-FULLSCREEN-BOARD-QA`, see `DECISIONS.md` D86) fixed the above:
  `game.tscn`'s `SafeAreaMargin` now uses `UIConstants.
  GAMEPLAY_BASELINE_MARGIN := 32.0` (via `SafeAreaMargin.
  margin_override`) instead of the menu-tuned `BASELINE_MARGIN := 96.0`
  — every menu screen's `SafeAreaMargin` instance is untouched (default
  `margin_override = -1.0` still reads `BASELINE_MARGIN`). Real Android
  safe-area insets still widen whichever baseline is active via the
  existing `maxf()` logic, so HUD safety near a real notch/cutout is
  unaffected. Result: Level 27's cell_size 124px→142px (+14.5%), height
  utilization 64.7%→72.3%; full resolution/profile matrix now **140/140
  comfortable** (up from 136/140) — **prefer ≤9 rows at 5–8 columns**
  still holds as the future generator's default range. **Honestly
  disclosed, not fully solved**: a width-bound board's `cell_size` is
  provably already maximized for its available width (99.4-100% width
  utilization confirmed across the whole matrix) — no margin/gap/
  centering change can grow it further without shrinking columns (a
  level redesign) or stretching cells non-square, both forbidden. Some
  residual vertical gap on very tall devices for boards authored against
  the 1080x1920 floor is the mathematically unavoidable remainder; fully
  closing it would need a future portrait re-layout pass choosing shapes
  against the realistic aspect-ratio range, not the 1920 floor alone —
  out of scope unless explicitly requested.
- **Final Gameplay Spacing Refinement** (`versionCode=44`,
  `3.6.2-FINAL-SPACING-QA`, see `DECISIONS.md` D87) — the user manually
  approved D86's larger tiles as "close to the desired result" and asked
  for one more tightening: HUD closer to the screen edge, without
  touching tile size or the D86 left/right margin. `SafeAreaMargin.
  margin_override` split into `horizontal_margin_override` (kept at
  `UIConstants.GAMEPLAY_HORIZONTAL_MARGIN := 32.0`, unchanged) and
  `vertical_margin_override` (new `UIConstants.
  GAMEPLAY_VERTICAL_MARGIN := 8.0`, matching `GRID_SAFETY_MARGIN`'s own
  8px precedent). **Proven mathematically, not just tested**: for a
  width-bound board (confirmed the common case at ≤10 columns on
  portrait), `CenterArea`'s `EXPAND_FILL` sizing + the board's own
  centering within it means the vertical margin (and `VBoxContainer`
  separation) has **zero effect on the visible HUD-to-board gap** —
  `total_top_space = TopBar.height/2 - BottomBar.height/2 +
  screen_height/2 - board_height/2`, independent of both. Confirmed
  directly: sweeping `vertical_margin_override` 32→0 against Level 28
  moved the HUD bar's own screen position but left `total_top_space` at
  exactly 619px throughout. **Don't re-attempt shrinking margin or
  `VBoxContainer` separation to close a width-bound board's HUD-to-board
  gap further — it is mathematically a no-op, proven in D87, not a
  matter of trying harder.** The only real levers left are
  `TopBar`/`BottomBar` height (aspect-locked to unchanged HUD art) or
  `board_height` (already width-maximized) — both off the table without
  a HUD art change or a level redesign. **Future procedural board
  profiles should prefer taller shapes** (e.g. 5x9, 6x10, 7x11, 8x11 —
  examples, not mandatory) specifically to avoid landing strongly
  width-bound in the first place, gated on `GridManager.
  is_board_profile_comfortable()` actually passing — this is the durable
  fix for future content; existing Levels 1-140 are not being redesigned
  to chase it.
- One gameplay scene (`scenes/gameplay/game.tscn`) serves every grid size
  and every screen size. Do not create per-resolution or per-grid-size
  scene variants.
- Menus use Control anchors/containers, not fixed coordinates.

## Direct Play + Continue navigation rules (Phase 2+)

- **A normal player never reaches Level Select.** Main Menu's flow is
  `CONTINUE` / `PLAY` / `TUTORIAL` / `SETTINGS` / `QUIT` — `PLAY`
  (`GameManager.play_game()`) and `CONTINUE` (`GameManager.
  continue_game()`) both resolve to `LevelManager.
  get_campaign_continue_level_id()` (first not-yet-completed campaign
  level, capped at the highest unlocked — safe at Level 140, never
  attempts a nonexistent Level 141) and enter gameplay directly. `PLAY`
  is never disabled and never resets progress; `CONTINUE` is disabled
  until `SaveManager.has_resumable_campaign_game()` is true. See
  `DECISIONS.md` D85.
- **`GameManager.entered_via_level_select: bool`** is the one flag that
  distinguishes a normal PLAY/CONTINUE session from the QA/dev Level
  Select path — set exclusively by `start_level()`'s `from_level_select`
  param. It decides where Back/Pause/Level-Complete's "Level Select"
  navigation actually goes (Level Select for a QA session, Main Menu for
  a normal one) and gates whether the session touches
  `campaign_resume_*` state at all. **Never derive this from anything
  else** (current level id, unlock state, etc.) — it must stay a single,
  explicit, caller-set flag or the QA/normal distinction silently drifts.
- **Level Select (`level_select.tscn`/`level_select.gd`) is retained,
  fully functional, QA/dev-only.** Reached only via Main Menu's small
  "Level Select (QA)" button, itself gated on `LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` — reusing that existing QA
  flag rather than inventing a second one. **MUST be hidden (the flag
  set `false`) before any production release**, same requirement as the
  flag's own existing rule. Do not delete `level_select.tscn`/`.gd`,
  level buttons, or campaign level path data — they remain the QA
  navigation surface and a fallback if Direct Play/Continue ever needs
  debugging in isolation.
- **QA Level Select sessions never read or write `campaign_resume_*`
  state.** A QA tester jumping into an arbitrary level for testing must
  never overwrite the real player's "current progression" resume
  pointer — every `campaign_resume_*` read/write in `game.gd` is guarded
  by `not GameManager.entered_via_level_select`. This is a deliberate,
  documented trade-off (no resume-on-return within a QA session) chosen
  specifically to protect real player state from QA testing.
- **Exact mid-level resume (tile orientations + move count) is real, not
  a fallback.** `SaveManager.campaign_resume_level_id`/
  `campaign_resume_orientations`/`campaign_resume_move_count` persist on
  every accepted move (`GridManager.move_made` → `game.gd.
  _on_move_made()`, event-driven, never per-frame) and are restored via
  `GridManager.restore_orientations()`, which updates
  `tile_orientations` and each node's `.orientation` together — the same
  paired-update pattern `load_level()` itself uses, so restore can never
  produce the visual/logical-mismatch bug class documented in rule 12c
  (D40). `game.gd._load_current_level(force_fresh: bool)` — `true` for
  Reset/Retry (always start over, never resume the pre-reset board),
  `false` for normal entry/Next Level (try to resume if the saved resume
  level matches).
- **One accepted, documented migration limitation**: an existing save
  with real prior progress shows `CONTINUE` disabled until the player
  presses `PLAY` once after upgrading (which immediately sets
  `campaign_resume_level_id` and self-heals permanently). This is
  intentional — see D85 for why synthesizing it during load was
  considered and rejected (it would require duplicating `LevelManager.
  get_campaign_continue_level_id()`'s search logic inside `SaveManager`,
  which has zero autoload dependencies by deliberate design, D6).

## Procedural generator rules (Phase 3+)

Full architecture, seed derivation, difficulty bands, template catalog,
audit numbers, save contract, and QA Next button behavior all live in
`PROCEDURAL_GENERATION.md` — read it before touching any of this. This
section is only the permanent, standing rules.

- **`scripts/procedural/**` is a runtime dependency; `scripts/tools/
  procedural_audit.gd` is dev-only, exactly like `LevelSolver`/
  `LevelValidator`/`LevelMetrics` (rule 9).** `ProceduralLevelGenerator`
  (the live, on-device generator PLAY/CONTINUE/QA-Next actually call)
  must **never** call `LevelSolver`/`LevelValidator` — they live in
  `scripts/tools/`, excluded from the Android export, and calling them
  from a runtime path would either require breaking that export boundary
  or crash on a real device. It self-verifies instead by directly
  simulating its own already-known solution via
  `LaserSystem.simulate_until_stable()` (no search) — see
  `PROCEDURAL_GENERATION.md` section 5 for the full reasoning. The real
  solver/validator instead exhaustively prove the *generator itself*
  during a dev-time-only audit (`scripts/tools/procedural_audit.gd`),
  exactly the same relationship the 140 handcrafted campaign levels
  already have with the solver — it proved them once during authoring;
  nothing in the shipped path calls it at runtime for them either.
- **Every procedural level must be deterministic and versioned.** The
  same `(level_number, generator_version)` must always produce the same
  `LevelData` — every random draw in `ProceduralTemplates` must come from
  the one `RandomNumberGenerator` `ProceduralSeed.rng_for_attempt()`
  returns, never `randi()`/global randomness. Bump
  `ProceduralLevelGenerator.GENERATOR_VERSION` whenever a change to the
  bands/templates/algorithm would change what an *already-existing* level
  number generates — `SaveManager.procedural_resume_generator_version` is
  what keeps a version bump from silently regenerating a different board
  under an active player's in-progress puzzle.
- **A clean generator audit (0 failures) does not by itself prove
  template/mechanic diversity — always check the distribution, not just
  the pass/fail count.** This pass's own first full 1-2000 audit passed
  100% while 6 of 10 templates never appeared anywhere, because template
  selection was accidentally keyed only on retry-attempt index (which
  almost never advances past 0) instead of the level number. See
  `PROCEDURAL_GENERATION.md` section 7 and `DECISIONS.md` D88. Don't
  re-discover this — if you change template/board *selection* logic,
  re-run `mechanic_distribution_report()`/`audit_range()`'s template
  counts, not just its failure count.
- **QA Next (`LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON`) must never
  call `SaveManager.record_procedural_level_result()`.** It only ever
  advances the RESUME pointer (`start_procedural_resume()`), never the
  real progression pointer (`procedural_current_level`) — see
  `PROCEDURAL_GENERATION.md` section 11 for the exact contract and how
  this was verified end-to-end. **MUST be set to `false` before any final
  production release**, same severity as
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`/
  `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING`.
- **`GameManager.play_game()` and `continue_game()` are allowed to target
  different levels for procedural progression** — unlike Campaign's Phase
  2 implementation (D85), where they were byte-identical. PLAY always
  targets real progression (`procedural_current_level`); CONTINUE targets
  the exact last-opened level (`procedural_resume_level_number`), which
  QA Next can legitimately leave ahead of real progression. Don't
  "simplify" these back into one implementation — see D88 for the
  end-to-end test that caught this exact regression risk.
- **Do not create Campaign Levels 141+, T35+, a new Era, or procedural
  Levels 3001+ without being explicitly asked** — same standing scope
  discipline as every other milestone in this project. (Procedural Levels
  2001-3000 now exist as generator V5, Selector Phase S3 / D110 - see
  "V5 generator rules" below.)
- **Known board-size gap, deliberately not fixed yet**: on some
  resolutions/board shapes, a small procedural or legacy board occupies
  noticeably less than the full available portrait height (found and
  documented, not fixed, during the Minimal Gameplay Background pass —
  see `DECISIONS.md` D90's board-size note). This is a separate
  generator/layout-quality task from whatever pass happens to notice
  it — don't fix it as a side effect of an unrelated pass. When this IS
  explicitly tackled, prefer tuning `ProceduralTemplates`/board-profile
  selection toward taller, portrait-friendlier shapes (e.g. 5x9, 6x10,
  7x11, 8x11-style ranges) that better use available height, while
  preserving `GridManager.MAX_COLUMNS := 8`, square cells,
  `MIN_COMFORTABLE_CELL_SIZE`, and no non-square stretching — verify any
  candidate shape against `GridManager.is_board_profile_comfortable()`
  first, per the Responsive rules section above.

## Difficulty contract rules (Difficulty System Phase 1+)

Full contract table, metric definitions, evidence and Phase 2 plan live in
`PROCEDURAL_GENERATION.md` section 17 and `DECISIONS.md` D93. Standing rules:

- **A procedural puzzle is not accepted solely because it is solvable.
  Difficulty is determined by both optimal-move requirements and meaningful
  reasoning complexity.** After the early game, increasing move count
  through independent or obvious rotations is NOT valid difficulty — never
  pad a puzzle with extra plain-route rotations to reach a move band.
- **`ProceduralDifficultyContract.get_difficulty_requirements(level_number)`
  (`scripts/procedural/procedural_difficulty_contract.gd`) is the ONE
  authoritative difficulty table.** Templates, the generator and the
  evaluator read it; never add a level-number difficulty branch anywhere
  else. It is a *product contract* (what an accepted puzzle must be),
  separate from `ProceduralDifficultyProfile` (how the current templates
  are configured). Its numbers are initial, tunable after Android testing.
- **Complexity is measured by ablation through the real `LaserSystem`**
  (`ProceduralComplexity`), never a second beam model (rules 1/3/9): a
  special tile counts only if removing it from the solved board loses a
  target. Presence of a mechanic on the board scores nothing.
  `ProceduralTriviality` reports `TRIVIAL_*` reasons; Phase 1 only
  REPORTS — the generator does not yet reject on them. Phase 2 must
  CONSTRUCT compliant puzzles, never "regenerate until the solver
  approves".
- **Difficulty comes from logic, never size**: `GridManager.MAX_COLUMNS=8`,
  square cells, `MIN_COMFORTABLE_CELL_SIZE` all stay.
- **`ProceduralDifficultyProfile._BANDS_V1`/`_BANDS_V2` and V1/V2
  generation stay frozen** — the contract does not alter what an existing
  `(level_number, generator_version)` generates. Any change that does
  requires a new generator version. A saved V1 puzzle must keep
  regenerating under V1 (verified again in D93).
- **QA jump size is `LevelManager.PROCEDURAL_QA_JUMP_AMOUNT` (=50), the
  single source** (button label derives from it). QA +50 never completes,
  stars, or scores a skipped level; it only moves the resume pointer; at
  Level 2000 it is a true no-op. Same release rule as
  `SHOW_PROCEDURAL_QA_NEXT_BUTTON` (must be `false` for production).
- **Long audits are banned by default**: no 1–2000 solver audit, no
  100+-level solver sample in a routine pass. Use
  `scripts/tools/difficulty_inspect.tscn` (a scene, because `GridManager`
  needs the `AudioManager` autoload — `--script` mode cannot run it) and
  stop any test past ~60 s with `QA_BUDGET_EXCEEDED`.


## V3 generator rules (Difficulty System Phase 2A+)

Full pipeline, prototype table and limits: `PROCEDURAL_GENERATION.md`
section 18; rationale: `DECISIONS.md` D94.

- **V3 is dependency-first.** Logical puzzle structure (`ProceduralPlanV3`)
  is constructed BEFORE beam routing; a physical layout is then chosen; the
  start state is derived from the solved state. Never start from "a zigzag
  route decorated with mechanics", never obtain difficulty by regenerating
  until the solver/metrics happen to approve.
- **High move count without dependency complexity is not difficulty.**
  Phase 2A intentionally targets ~8-12 meaningful moves (a temporary
  exception) before scaling to the contract's production bands. Limited plain
  moves are permitted but must not dominate (profile: >= 70% meaningful).
  Never add moves to reach a number.
- **Every mechanic a plan promises must be load-bearing on the built board**
  (ablation check in the generator) - do not place a mechanic to bump a
  counter.
- **V1/V2 stay frozen and reproducible; `GENERATOR_VERSION` (default) stays 2
  until the user approves a rollout.** V3 is reachable only via explicit
  version 3 or the QA selector. A saved version 1/2/3 must regenerate that
  version.
- **The runtime generator never calls `LevelSolver`/`LevelValidator`.**
  Shortcut proof (optimal vs intended) is dev-time on pinned seeds
  (`scripts/tools/v3_prototype_audit.tscn`); any new archetype/seed/layout
  change requires re-running it (it found a real shortcut in F).
- **`LevelManager.SHOW_V3_PROTOTYPE_QA`** ("V3 TEST" + "NEXT V3") is a QA
  flag: a V3 session never touches `SaveManager`; the `+50` button is
  unchanged outside it. **Must be `false` for production**, same severity as
  the other QA flags.
- Difficulty comes from logic, never size: `MAX_COLUMNS = 8`, square cells,
  comfortable touch size, no shrinking.
- **Phase 2A.1 focuses on reasoning depth rather than raw move count**
  (`DECISIONS.md` D95, `PROCEDURAL_GENERATION.md` 18.7). Not every
  load-bearing tile should visibly advertise its required final orientation
  from the starting state: some route tiles start already correct
  (explicit `keep_correct` in the layout), the downstream chain stays hidden
  behind an unpowered Receiver/closed Gate, and wrong-but-purposeful states
  exist at start. Hard puzzles should contain globally constrained decisions
  where a locally reasonable choice can conflict with another dependency
  (shared tile serving two beams, a wrong-colour route that still reaches the
  target, a pass state that looks like progress). Never add moves to look
  harder.
- **A One-Way "pass" state on a shared cell forces its two beams to overlap**
  (pass = opposite arms, reflect = adjacent arms) - keep the shared One-Way a
  reflect-reflect X and put PASS on its own tile (`Cursor.to_one_way_hold`).
  Ablation cannot see a pass tile or an X tile whose removal lets one beam
  slide along the other's exit row; such plan stages are marked
  non-load-bearing and are covered by the padding check + the dev-time solver.
- **After ANY V3 layout change: re-run `v3_prototype_audit.tscn` (wrapped in
  `timeout`; a parse error hangs headless Godot) on the pinned seeds AND a few
  extra seeds per archetype, and diff A/B/C against a saved baseline** - a
  regex edit once silently corrupted A/B/C's plans and only the diff caught it.
  The runtime generator still never calls `LevelSolver`/`LevelValidator`;
  `ProceduralComplexity.start_state_visibility()`/`greedy_follow_solve()` are
  structural QA proxies, not proofs.

## V3 progression rules (Difficulty System Phase 2B+)

Full pipeline, band table, atom catalog, evidence and limits: `PROCEDURAL_GENERATION.md`
section 19; rationale: `DECISIONS.md` D96. Standing rules:

- **V3 progression is a composer of reusable fragments, not a set of templates.**
  `ProceduralFragmentsV3` (atoms -> line tree) + `ProceduralComposerV3` (router/
  layout) + `ProceduralProgressionV3` (gates). Never hand-place coordinates for a
  progression level, never add a per-level-number branch, never obtain difficulty
  by regenerating until a metric passes. New difficulty = a new atom or a better
  recipe, verified on the built board.
- **`ProceduralDifficultyContract` stays the ONE numbers table** (bands + `_V3_POLICY`
  + boards + mechanic availability). Interactions have no ceiling (kind pairs are
  triangular numbers); dependency/depth ceilings bind only Levels <= 200.
- **V3 selection is centralized**: `LevelManager.USE_V3_FOR_PROCEDURAL_QA` via
  `procedural_generator_version_for_new_play()`. A resumed puzzle ALWAYS uses the
  saved version (V1->V1, V2->V2, V3->V3). `GENERATOR_VERSION` stays 2 until the user
  approves a rollout. A change that alters what an existing `(level, 3)` generates
  after this pass requires deciding whether saved V3 puzzles may change (there are
  none in the wild yet: V3 progression is QA-only) - bump/branch deliberately.
- **The six V3 prototypes (`ProceduralGeneratorV3`) are permanent regression
  fixtures.** Any change to `ProceduralBoardV3`/`Cursor` must keep A-F byte-identical
  (`v3_prototype_audit.tscn solver=0`, diff against a saved baseline ignoring `gen_ms`).
- **Composer safety rules that each fixed a real bug - do not relax them:**
  a line's end must leave the board or meet a blocker (`_end_ok`; tiles do not
  absorb beams); beams cross only perpendicular; a filter's colour must be
  unobtainable by any other beam (`used_colors`); sources go on the edge facing
  inward or get a blocker behind; `harden()` blocks hazardous wrong rays;
  the shortcut probe runs on every candidate. Use the level's own RNG (never
  `Array.shuffle()`).
- **A V2 fallback is never a V3 success.** `V3_GENERATION_FAILED` must stay visible
  (warning, `fallback_count`, HUD `V3 FAILED>V2`); production target is 0.
- **The shortcut probe is a screen, not a proof.** Exact optimality needs
  `LevelSolver` (dev-only, exponential above ~17 rotatables) - say "UNKNOWN", never
  "verified", for levels the solver cannot finish. Do not claim exactness for
  Levels ~1100+.
- **After ANY composer/fragment/contract change**: re-run `v3_progression_sample.tscn`
  (25 levels, independent checks), `v3_progression_stats.tscn` on a few ~50-level
  windows across bands (fallbacks, rejection histogram, timings) and the solver on
  Levels <= ~480 (`max_rotatables=15..17`), plus the prototype diff. Keep every run
  under ~60 s (`timeout`; a parse error hangs headless Godot). No full 1-2000 audit.
- **Difficulty must never come from tile size, columns or clutter**: `MAX_COLUMNS = 8`,
  square cells, comfortable size stay; move targets that do not physically fit are
  lowered, not forced.
- `LevelManager.USE_V3_FOR_PROCEDURAL_QA`, `SHOW_PROCEDURAL_QA_NEXT_BUTTON`,
  `SHOW_V3_PROTOTYPE_QA` and the HUD tag `V3 <band>` are QA-only and must be reviewed
  before any production release. Star thresholds are NOT final - they must use the
  verified/accepted optimum (`verified_optimal_moves`), never a static number.

## Global Hint System rules (Hint Phase 1+)

Details: `DECISIONS.md` D97, `ARCHITECTURE.md` "Global Hint System".
- **Hint is global and shared.** Button = the shared HUD `HintButton` (game.tscn); logic = `HintManager`
  (owned by `game.gd`, not an autoload); ring = `GridManager.show_hint_cell()`. Level files never own hint
  state, hint UI or HUD positioning.
- **Hints come from KNOWN solutions only - never a runtime solver.** Procedural: `solution_orientations`
  from the generator result. Campaign/tutorial: solver-authored `levels/hint_solutions.json`, built offline by
  `scripts/tools/hint_solution_builder.tscn`; regenerate when a level changes. No entry = Hint hidden + dev warning.
- **One press = one tile, ring only.** Never auto-rotate, never count a move, never touch orientations,
  saves, seed, generator version or stars. Tutorials: forced steps are never bypassed.
- **Monetization seam:** `request_hint()` (permission) vs `grant_hint()` (reveal). Do not fold them together.
- Stars/penalties for hints are NOT decided; do not add any without being asked.

## Advertising rules (AdMob Foundation V1+)

Details: `ADS_MONETIZATION.md`, `DECISIONS.md` D98.
- **Gameplay code never calls an ad SDK.** Everything goes through the `AdManager` autoload (5th autoload, earned by cross-scene ad state) over
  `AdBackend` (AdMob on Android/iOS, fake for tests). All ad IDs, switches and rule constants live ONLY in `scripts/ads/ad_config.gd`.
- **This QA build uses Google TEST ids. Never commit production ids** (`PRODUCTION_IDS` stays empty in source control; release checklist in
  `ADS_MONETIZATION.md`). `AdConfig.config_problem()` must be empty for a release.
- **Rewarded hint is granted ONLY from the reward callback.** No free fallback on failure. Tutorials, V3 TEST, campaign QA and desktop stay free.
- **Interstitial: every 4 legitimate normal-procedural completions, >= 120 s, at Level Complete -> Next Level; the counter resets only when one shows.**
  QA `+50`, V3 TEST, tutorials, Reset/Retry/Continue/load never count. Never two full-screen ads back to back (rewarded-on-level suppresses).
- **Ads are optional services**: any failure must never block hints, saves, generation, completion, Next Level or audio.
- The Android build now needs Gradle + **JDK 17** + the plugin binaries (`addons/admob/`, downloaded by the plugin in a headless editor run);
  `android/` is git-ignored. iOS is prepared but unbuilt/unvalidated. No banners, no app-open ads.

## Store release rules (store-release pass, 2026-09-26)

Details: `STORE_RELEASE.md`, `ADS_MONETIZATION.md` 6a-6c.
- **Bundle id is `com.foursagez.beamshift` on every preset, forever.** Build codes are `major*10000+minor*100+patch` (1.0.0 = 10000),
  stamped by `tools/ci/stamp_version.sh`; never hand-edit a lower code in.
- **Every ad request is child-directed** (`AdConfig.CHILD_DIRECTED`: the audience includes under-13). Never add ATT/IDFA,
  `NSUserTrackingUsageDescription` or personalised ads without an explicit owner decision - it is a Families/COPPA policy change.
- **Store/cloud SDKs only behind `StoreManager`/`CloudSave` + per-platform backends loaded by path.** iOS plugins via `ClassDB`, every
  plugin signal `CONNECT_DEFERRED`. Product ids live only in `StoreConfig`. Entitlements live in `SaveManager.entitlements`; only a
  completed full query revokes; entitlements never travel with a cloud profile.
- **"No Forced Ads" removes interstitials only** - the rewarded hint stays (owner decision). Never label it "Remove Ads".
- **`play_time_seconds` counts real play only** (`game.gd _process`); the cloud fresh-install guard depends on menu time never counting.
- **Android builds FAIL while `godot_play_game_services/game_id` is empty** (AAPT resource error) - that is expected until the owner
  creates the PGS project; test exports may use a placeholder but must restore the empty value.
- iOS StoreKit/Game Center GDExtensions are never vendored (CI downloads pinned releases). Signing material stays outside the repo
  (`.gitignore` covers `*.keystore *.jks *.p12 *.p8 *.mobileprovision`).
- AdMob callbacks are named methods only (no lambdas handed to the plugin) + `AdBackendAdMob.release()`: iOS swipe-away crash otherwise.

## Fusion Node rules (Fusion Phase 1+2)

Details: `DECISIONS.md` D99 (mechanic) and D100 (procedural integration). The user APPROVED the Fusion direction after Android QA; Fusion is now part of generator V4 (QA build).
- The runtime rules are FROZEN: colour table only in `GridTypes.combine_beam_colors`; Fusion logic only in `LaserSystem` (state replaced every pass, never latched); `FusionTile` only draws the result. `BeamColor` YELLOW/MAGENTA/CYAN and `TileType.FUSION` were APPENDED - never renumber. Only RED/GREEN/BLUE are valid inputs; composite colours are not (no chained fusion) unless explicitly requested.
- Orientation is 4-state (output `Direction`) in `tile_orientations`; `LevelSolver` is binary-flip only and cannot solve Fusion puzzles - QA puzzles carry their own solutions; generated levels carry `solution_orientations`; dev verification of generated Fusion levels uses `scripts/tools/fusion_verify.tscn` (exhaustive over every orientation where it fits, else "STRUCTURALLY VALID / PROBE PASSED" - never claim "proven" for an UNKNOWN).
- **Fusion is generated ONLY by generator V4** (`GENERATOR_VERSION_V4`, `ProceduralProgressionV3.generate(level, 4)`). V1/V2/V3 stay frozen - after ANY change to the composer/fragments/complexity/probe re-run a before/after fingerprint of V1/V2/V3 output (a temporary driver hashing tiles + solution over ~33 levels x 3 versions, see D100 / TEST_PLAN) and expect IDENTICAL. A change that alters what an existing `(level, 4)` generates needs a decision (there are no released V4 puzzles yet; after a release it needs a new version).
- **The Fusion unlock table is `ProceduralDifficultyContract._FUSION_PROGRESSION` (`fusion_policy()`)** - never add a level-number Fusion branch elsewhere. Levels 1-200 have none. The roll is ONCE per level (dedicated rng stream), never re-rolled per attempt. Do not mechanically force Fusion into every eligible level (the realised share is 14-28% per band; report it after any change).
- **Every generated Fusion node must be load-bearing on the BUILT board** (`ProceduralFusionCheck`): node removal loses a target; EACH input path required (cut ablation); the fused colour consumed (matching composite target, Switch/Receiver, or Prism for WHITE); no required WHITE target or WHITE remote depending on it; NO feedback into its own inputs (an unstable cycle is rejected at generation, LaserSystem's pass cap is only a backstop); start/solved/one-tap-away boards must SETTLE before the cap (`converged`); wrong-direction output rays hardened (an unrepairable adjacent hit rejects). A Filter after a node would erase the fused colour - never place one there.
- A generated node always starts exactly ONE clockwise tap from solved (one honest move). Do not pad Fusion levels with extra rotations; difficulty is dependency structure, `MAX_COLUMNS = 8`, square cells, comfortable size.
- **The certification target is not a permanent ceiling** (`INITIAL_CERTIFIED_LEVEL_TARGET` = 3000 since Selector Phase S3, D110; `MAX_LEVEL` = what is exposed). The contract/fragments are level-number-open (a level past the last row reads the last row). Do NOT expose Level 3001+ or hard-code bands past 3000 without being explicitly asked; the documented direction (D100) is combinations of existing mechanics inside a curated envelope, never smaller tiles/more columns/padding.
- **The player-facing Fusion tutorial now exists (Fusion Phase 3, D101): T21-T28 (`levels/tutorial/t21.gd`-`t28.gd`), unlocked by `LevelManager.is_fusion_tutorial_selectable()` (T21 at procedural Level 150 or after T20, then sequential; QA flag opens all; NOT era-gated - `get_era_for_tutorial(21)` reads "Era 3" but Fusion is not an era; never a hard gate). Fusion is a PRODUCTION-SUPPORTED mechanic. Tutorial rules: same `TutorialManager`, one idea per tutorial, every board brute-force verified to have exactly ONE solution (LevelSolver cannot: 4-state node), hint entries `t21`-`t28` are hand-authored in `hint_solutions.json` (the builder skips ids >= `FUSION_TUTORIAL_FIRST`), display names <= 13 chars, tutorials ad-free.**
- QA flags: `LevelManager.USE_FUSION_PROGRESSION_FOR_QA` (V4 for new play), `SHOW_FUSION_TEST_QA` (FUSION TEST / NEXT FUSION, contained like V3 TEST via `game.gd _is_v3_session()`), `USE_V3_FOR_PROCEDURAL_QA`, `SHOW_PROCEDURAL_QA_NEXT_BUTTON` must all be reviewed before production.
- Never name a PowerShell helper function `Rd`, `Ri`, `Rm`, `Cp` or `Mv` (they are aliases and DELETE/OVERWRITE files - this deleted ARCHITECTURE.md once, D100).

## Audio rules (Audio/SFX Integration Pass+)

Full architecture, semantic event mapping, bus layout, per-SFX gain,
anti-spam/suppression, and Era 2 reuse all live in `AUDIO_SYSTEM.md` —
read it before touching any of this. This section is only the permanent,
standing rules.

- **One centralized `AudioManager` autoload; never a duplicated
  `AudioStreamPlayer` per scene/level.** `scripts/managers/audio_manager.gd`
  is BeamShift's 4th autoload (earns rule 6's bar the same way the other
  three do — genuinely needs global, persistent access from every scene).
  Every gameplay/UI script calls one of its semantic `play_*()` methods
  (`play_mirror_rotate()`, `play_target_activate()`, etc.) — never
  instantiates its own `AudioStreamPlayer`, never references an
  `assets/sfx/*.ogg` path directly. `AudioManager._load_streams()` is the
  ONE place any SFX file path appears in the whole codebase.
- **`LevelData`/`TilePlacement` must never carry an audio path, volume, or
  node reference.** Audio is driven entirely by real gameplay
  transitions/events (a tap, a solve, a state change), never by level
  content — this is what lets all 2,000 procedural levels (and every
  legacy/campaign/tutorial level) get audio automatically, with zero
  per-level authoring. Adding a sound field to level data to "make a
  level feel special" is exactly what this rule forbids.
- **Gameplay audio only ever plays for an actual accepted player move.**
  `GridManager._simulate_and_draw(play_impacts: bool)`'s existing
  `play_impacts` parameter (Milestone 4A's mirror-impact VFX gate) is
  also the audio gate — `_play_state_transition_audio()` and
  `_play_beam_interaction_audio()` are only ever called from inside
  `if play_impacts:`, and `play_impacts` is only ever `true` from
  `_on_orientable_tile_clicked()`'s own accepted-tap path. Do not add a
  second, parallel "is this a real move" check elsewhere — level load,
  Continue/resume restoration (`restore_orientations()`), Reset/Retry,
  and the procedural generator/solver/audit (which never touch
  `GridManager` at all) must all stay silent through this one existing
  gate, not a new suppression flag that could drift out of sync with it.
- **`AudioManager.set_sound_enabled(false)` (or a missing/corrupt SFX
  file) must never affect gameplay, save data, or progression** — see
  `AUDIO_SYSTEM.md` section 12 for the exact missing-resource-safety
  contract (`ResourceLoader.exists()` check, per-event silent no-op,
  never a crash).

## Coding conventions

- Tabs for indentation (GDScript default), typed variables/params/returns
  where it doesn't hurt readability.
- `class_name` + a short doc comment at the top of any script meant to be
  referenced globally (resources, GridTypes, LaserSystem, tile visuals).
- No comments that restate what the code does. Comments explain *why*
  when the why isn't obvious (a constraint, an invariant, a deliberate
  trade-off).
- Signals for cross-node communication; avoid reaching into another
  node's internals via long `get_node()` chains outside of `%UniqueName`
  references within the same scene.

## Testing expectations

- Any change to `laser_system.gd` or the reflection rules must be
  re-verified against **all 15** test levels in `levels/` — their
  documented `optimal_moves` and solvability are load-bearing (see
  `TEST_PLAN.md`). Levels 1-5 (Milestone 1 basics) and 6-15 (Milestone 2
  advanced mechanics) are equally load-bearing; don't assume only the
  newer ones need re-checking after a change.
- Godot headless (`--headless --script <file>.gd` extending `SceneTree`)
  can run pure-logic checks (LaserSystem, LevelData) without a display,
  but **autoload singletons are not available in that mode** — this was
  confirmed during Milestone 1. Don't waste time re-discovering this;
  test autoload-dependent code by running the actual project headless
  (`godot --headless --path .`) instead, or note it as a manual test.
- To exercise a *non-main* scene that needs autoloads (like the level
  editor), temporarily point `project.godot`'s `run/main_scene` at it (or
  at a small driver scene that instantiates it and calls its methods),
  run `godot --headless --path .` with a timeout, capture output, then
  **revert `run/main_scene` immediately** — see `TEST_PLAN.md` for the
  exact technique used to validate the level editor's `_ready()` and its
  `_on_*` handlers this way. Always double-check the revert actually
  landed before ending a session.
- Never claim a manual-only test ("does this feel right on a real phone?",
  "does the popup fit on a 20:9 screen?") was automated. Mark it
  `MANUAL TEST REQUIRED` in `TEST_PLAN.md` if it wasn't actually run.

## Scope discipline

This is a milestone-based project. Do not:
- Build the full 100-level campaign speculatively.
- Add mechanics from `ROADMAP.md`'s future milestones unless asked.
- Add ads, analytics, IAP, or external SDKs.
- "Improve" working systems outside the scope of the current request.
- Build a procedural/random level generator — the solver/validator/
  metrics tooling exists to assist a human designer, not to replace one
  (see DECISIONS.md D30). This is an explicit, standing exclusion, not
  just a Milestone 3 scoping note.

If you're unsure whether something is in scope, say so and ask, rather
than guessing big.

## Fusion Phase 3 standing rules (D101)

- **A Fusion Node is ablated as a DEAD NODE (a blocker), never by deleting its tile** (`ProceduralComplexity.analyze`, `fusion_verify`): deleting it lets its raw input beams run on through the empty cell into a collinear Switch/Receiver - a state no rotation can reach - and produced false "not load-bearing" rejections (share of placed Fusion rolls 16/20 -> 20/20 at 701-1000). Real bypasses are caught by the exact one-tap-away screens in `ProceduralFusionCheck`, the runtime probe and the dev-time exact search, not by that counterfactual.
- **Fragment variants are generator-driven (`plan.params["fusion_variant"]`), never handwritten levels.** Recipe-level variants (`FUSION_RECIPE_VARIANTS`) draw AFTER the fragment draw so the roll stream stays stable. Any change to fragments/complexity/check: re-run the V1/V2/V3 fingerprint (must be IDENTICAL), `fusion_progression_sample` `freq=1` + `stress=90` windows (0 problems, 0 fallbacks, realised share per band), `fusion_verify` on small-state levels. Realised shares (14/23/27/20/31/34/22% per band 201-2000) are inside the targets; don't chase exact percentages - variety matters more.
- **Fusion is available past 2000 by data, not by code**: no fragment/contract code caps at 2000. `INITIAL_CERTIFIED_LEVEL_TARGET = 2000` stays; nothing beyond 2000 is exposed. Chained Fusion (output -> a second Fusion) is a future mechanic and needs an explicit request; composite colours remain OUTPUT ONLY.
- **T21-T28 tutorial numbering is a Fusion pack, not Era 3.** A future Era 3 tutorial pack starts at T35+ and must revisit `LevelManager.FUSION_TUTORIAL_FIRST/LAST` and `EraTheme.TUTORIALS_PER_ERA` together.
- QA flags are still ON in `versionCode=56` (`UNLOCK_ALL_*`, `SHOW_*_QA`, `USE_*_FOR_QA`); production clean-up is a separate, explicitly requested pass.

## Phase 4 standing rules: stars, Hint, QA/production (D102)

- **Stars live in exactly one place: `StarScoring`** (`scripts/managers/star_scoring.gd`). Never put thresholds in a level, never add a per-band formula without being asked. OPTIMAL priority: `verified_optimal_moves` (>= 0) > `intended_moves` > legacy `optimal_moves`. Rule V1: `<= OPTIMAL+2` 3 stars, `<= OPTIMAL+6` 2, else 1; fewer moves than OPTIMAL = 3 stars + warning, never a crash or a punishment. A GRANTED gameplay Hint caps at 2 stars.
- **Hint-used is per attempt and persisted** (`SaveManager.procedural_resume_hint_used` / `campaign_resume_hint_used`). Set only from `HintManager.hint_shown` in normal gameplay (never tutorials, V3/FUSION TEST, editor playtest, an ad closed without reward, or a request with no candidate); cleared only by a fresh load (`start_*_resume`). Do not move it into a place Continue cannot restore.
- **Best stars never decrease.** Procedural identity = `"<level>|<generator_version>"` in `SaveManager.procedural_best_stars` (sparse dictionary, no per-level fields). The popup shows the current run.
- **`BuildConfig.IS_PRODUCTION_BUILD` is THE QA/production switch.** New QA-only UI/unlock must derive from `BuildConfig.QA_TOOLS`, never a new scattered flag. Release checklist: set it true, then separately handle real AdMob ids (`AdConfig.PRODUCTION_IDS`) and the generator rollout flags (`USE_V3_FOR_PROCEDURAL_QA`, `USE_FUSION_PROGRESSION_FOR_QA` - a gameplay decision, not UI). Verify with a production-simulation run (flip, drive Main Menu/game/tutorial, flip back).
- **The Fusion tutorial nudge** is one-time, non-blocking, never a lock (`fusion_tutorial_nudge_seen`). Fusion still first rolls at 201; the pack opens at 150. `bs_fusion_icon.png` is unused because the tutorial panel has no icon support - do not redesign the panel just to use it.
- The old 2-star band (OPTIMAL+1..+2) is gone; do not reintroduce `TWO_STAR_MOVE_MARGIN` logic (it is an alias of `StarScoring.THREE_STAR_MARGIN`).

## HUD edge rule (D103)

Gameplay HUD plates are positioned by ONE mechanism: `SafeAreaMargin.set_hud_overhang()` (fed by `game.gd` from the bars' height x `UIConstants.HUD_*_ART_PAD_FRACTION`) so the visible art sits `GAMEPLAY_VERTICAL_MARGIN` inside the real safe area. No per-level HUD offsets, no disabling safe insets, no HUD/button/font resizing for this. Re-measure the transparent-padding fractions when HUD art changes.

## NEW GAME rule (D107)

NEW GAME immediately starts on a fresh/no-progress save. If meaningful main progress exists (`SaveManager.has_meaningful_main_progress()`), it requires explicit confirmation before resetting the main run. All main-run reset goes through `SaveManager.reset_main_progress_for_new_game()` (one save; never scatter resets in UI). It preserves settings, ALL tutorial progress, ad cadence/consent and QA/legacy populations. Do not base "fresh" on the save file existing.

## Splitter Selector rules (Selector Phases S1+S2, D108/D109)

- **Rule lives only in `LaserSystem`**: `TileType.SPLITTER_SELECTOR` (appended, never renumber). One beam in -> exactly ONE beam out through the selected output side, same pass, colour unchanged, stateless; a beam entering through the output side is absorbed. 4-state orientation = output `Direction` in `tile_orientations` (one tap = one clockwise step, same path as Fusion). `SplitterSelectorTile` only draws; `LevelSolver` cannot model it (brute-force via `selector_verify`/`selector_tutorial_verify`).
- **Selector QA**: `SelectorQaSet` + "SELECTOR TEST" (`LevelManager.SHOW_SELECTOR_TEST_QA` = `BuildConfig.QA_TOOLS`), contained like FUSION TEST. **Tutorials T29-T34** (unlock `SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL` = 1900, hand-authored hint entries, ad-free). **Done in S3 (D110)**: generator V5 / Levels 2001-3000 / contract bands G-K / selector complexity, ablation, equivalent-state and triviality rules (see the V5 section below). Do not expose Level 3001+ or change `MAX_LEVEL` without being asked. A selector on a straight line is bypassed by removal - it must TURN the beam to be load-bearing.


## V5 generator rules (Selector Phase S3, D110)

Full architecture, band table, family catalog, measured evidence and known weaknesses: `PROCEDURAL_GENERATION.md` section 20 and `DECISIONS.md` D110. Standing rules:

- **V5 = generator version 5 = Levels 2001-3000** (`ProceduralLevelGenerator.GENERATOR_VERSION_V5`, `SELECTOR_FIRST_LEVEL`; `LevelManager.procedural_generator_version_for_new_play(level)` is the ONE place that maps a level to V5). V1-V4 stay FROZEN: after ANY change to the composer/fragments/complexity/probe/contract, re-run the V1-V4 fingerprint (a temporary driver hashing tiles + solution over ~33 levels x 4 versions) - it must be IDENTICAL. A saved puzzle always regenerates under its saved version. `GENERATOR_VERSION` (default) is still 2; V5 is reached only by level number (>= 2001) or an explicit version.
- **Difficulty stays logic, never size**: `MAX_COLUMNS = 8`, square cells, comfortable size (8x12 is NOT comfortable: 94 px < `MIN_COMFORTABLE_CELL_SIZE`), a V5 tile budget (`ProceduralFragmentsV3.v5_tile_budget`) instead of clutter, no padding. Move targets that do not physically fit are LOWERED (density fit, then relax after layout failures), never forced; the reasoning floors (depth, dependencies, interactions, kinds, every Selector rule) are the last thing to give.
- **Every relaxation is visible and counted, never silent**: `moves_below_band`, `band_demoted` (attempt >= `V5_DEMOTE_AFTER`(_SELECTOR) uses the REASONING floors of the band below), `selector_dropped` (the rolled family could not be placed), `fallback_used`/`v3_generation_failed` (`V5_GENERATION_FAILED`, HUD `V5 FAILED>V2`; target 0). Never certify a fallback level; never describe a demoted level as full-band.
- **The Selector is a first-class complexity kind** (`ProceduralSelectorCheck`, `TileType.SPLITTER_SELECTOR` in `ProceduralComplexity._SPECIAL_KINDS`): a Selector counts as a mechanic kind / dependency / depth ONLY when it is load-bearing (blocker ablation loses a target), NOT mirror-like (a wrong output changes a state or meets a mechanic, or >= 2 wrong rays are live), and none of its three other orientations solves the board. Hardening does NOT blanket-block its wrong rays (they are what makes it a decision); only a wrong state that would SOLVE gets a blocker. Strict bands (>= 2601, not demoted) additionally need one consequential Selector and one genuine multi-way decision; Selector counts >= 2 must be coupled/converging.
- **A 4-state tile costs its real tap distance**: `ProceduralComplexity.analyze` counts `posmod(solution - start, 4)` for Fusion/Selector (Fusion is always 1, so V4 is unchanged); a generated Selector starts 1-3 taps from solved (55/35/10%), never keep-correct. Never pad four-state tiles for move count.
- **Selector frequency is a deterministic low-discrepancy sequence** (`ProceduralDifficultyContract.selector_policy`, golden-ratio Weyl over the level number), not an RNG draw; Level 2001 always carries one simple Selector (`SELECTOR_INTRO_LEVEL`). The contract's `frequency` is the ROLL, the realised share is lower by the dropped levels - calibrate the roll, not the target.
- **The intended solution must be MINIMAL**: found by replaying it through a real GridManager (the intended move count overstated difficulty on ~14% of unscreened Mastery boards, and 9-14-flip alternative solutions existed on ~2% of Entry/Branching boards). V5 therefore runs `ProceduralMinimality` (lazy activation + ddmin over several tile orders + whole-line unions) and ONE wide final shortcut probe (`V5_FINAL_PROBE_SIMS/WIDTH`) on the candidate that survives every other gate. These are SCREENS: a residual of ~1-4% of Interlock-Mastery levels is documented (independent random-order ddmin / 6000-simulation probe); say "UNKNOWN", never "verified", for optimality (`verified_optimal_moves` stays -1 for every V5 level).
- **After ANY V5 change**: run `scripts/tools/v5_sample.tscn` (anchors, `from= count= stride=` windows, `wide=1|big`, `hist=1`, `family=XX`, `nosel=1`), `v5_verify.tscn` (selector brute force, determinism, exact search where feasible), the V1-V4 fingerprint, and a real-game replay of the intended solution (`GridManager._on_orientable_tile_clicked` until solved: taps == `intended_moves`, stars 3) on anchors. Keep every run under ~60 s (`timeout`; a parse error hangs headless Godot); parallel processes are fine. No 1-1000 (or 2001-3000) full audit.
- **QA**: "V5 TEST" (`LevelManager.SHOW_V5_TEST_QA` = `BuildConfig.QA_TOOLS`, `ProceduralV5QaSet.LEVELS`, in-game "NEXT V5") is contained like SELECTOR TEST / FUSION TEST (`game.gd _is_v3_session()`): no saves, stars, ads or counters. The HUD tag reads `V5 <band code> [F#] [S?]` and `~DEMOTED`. QA +50 clamps at `MAX_LEVEL` (1951 -> 2001, 2951 -> 3000, 3000 no-op) and never completes/stars a level.
- **Not built**: Selector families S-I (shared mirror), S-K (target vs prerequisite bait), S-M (target continuation), S-O (indirect two-Selector dependency) - the composer has no bait/decoy builder; chained Fusion; Levels 3001+; Android build / version bump / commit (S4).
