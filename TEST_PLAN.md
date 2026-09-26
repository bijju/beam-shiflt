# TEST_PLAN.md

## S4 External-Test Cleanup

- **AUTOMATED - DONE (2026-09-26).** `godot --headless --path . --import` completed with no `SCRIPT ERROR` / `Parse Error` lines after the build-mode change. Environment warnings remained: Windows root certificate store and editor settings save warnings.
- **STATIC CHECK - DONE (2026-09-26).** Confirmed `BuildConfig.BUILD_MODE == MODE_EXTERNAL_TEST`, `QA_TOOLS` derives from `IS_INTERNAL_QA_BUILD`, LevelManager QA flags derive from `BuildConfig.QA_TOOLS`, Main Menu reads `TUTORIALS`, QA spacer visibility is gated by `BuildConfig.QA_TOOLS`, generator/tutorial debug labels are gated, gameplay QA stack cap override follows `BuildConfig.QA_TOOLS`, export metadata is `versionCode=70`, `versionName="4.8.4"`, and `OFFICE`/`BRANCH-QA`/`ANDROID TILE FIX` are absent from `export_presets.cfg`.
- **AUTOMATED - BLOCKED IN THIS ENVIRONMENT (2026-09-26).** Both `godot --headless --path . --script _qa_tmp/s4_external_test_smoke.gd` and `godot --headless --path . --quit-after 3` hit a Godot 4.7.1 crash handler (`signal 11`) before useful scene assertions. No live Godot process remained afterward. Treat real runtime boot/menu/gameplay visibility as MANUAL/RENDERED still required for S4.
- **MANUAL TEST REQUIRED (Android/iOS device).** External tester flow: Launch -> Main Menu -> New Game/Continue -> Tutorials -> Gameplay -> Hint -> Reset -> Pause -> Complete -> Next Level -> close/reopen -> Continue. Confirm no QA/dev/test labels are visible and dense V5 boards are readable on phone hardware.

Repeatable tests for BeamShift. Each item is marked with how it was last
validated: **AUTOMATED** (a command you can re-run), **MANUAL** (needs a
human in the editor or on a device — not yet performed unless stated
otherwise), or **MANUAL — DONE** (a human validated it and the result is
recorded here; update the date/result if you re-check it).

## How to re-run the automated checks

All automated checks so far use headless Godot. Two modes matter:

- `godot --headless --path . --import` — parses/imports the whole
  project and registers global classes. Any GDScript parse error, broken
  `class_name`, or missing resource surfaces here.
- `godot --headless --path . --script <file>.gd` (where `<file>.gd`
  `extends SceneTree`) — runs a custom script with **no autoloads
  available** (confirmed in Milestone 1, see `DECISIONS.md` D7). Use this
  only for autoload-free logic (`LaserSystem`, `GridTypes`, `LevelData`,
  `TilePlacement`, `GridManager`).
- `godot --headless --path .` (no `--script`) — runs the real project,
  main scene and all, with autoloads initialized normally. Use this to
  confirm the actual boot sequence has no runtime errors. It will run
  until killed (there's no display to close); redirect output and check
  it for errors, not for a clean exit code.
- **(Milestone 3 addition)** To exercise a scene that itself needs
  autoloads in its `_ready()` (like the level editor) without a full
  interactive session, temporarily edit `project.godot`'s
  `run/main_scene` to point at that scene (or, for scripted assertions
  against it, a small driver scene that instantiates it as a child and
  calls its methods directly), run `godot --headless --path .` with a
  `timeout`, capture output, then **revert `run/main_scene`
  immediately**. This is how the editor's `_ready()` and its actual
  `_on_*` handler methods were exercised - see DECISIONS.md/
  `PROJECT_HANDOFF.md` for why `--script` mode couldn't reach it. Always
  double-check `project.godot` is back to
  `res://scenes/ui/main_menu.tscn` afterward.

The exact test scripts used for these automated checks were written to a
scratch/temp directory (not part of the repo, since they're throwaway
harnesses, not shipped test infrastructure). Recreate them from the
descriptions below if you need to re-verify — they're short.

## Project boot

- **AUTOMATED — DONE.** `godot --headless --path . --import` completes
  with `[ DONE ] first_scan_filesystem` and `[ DONE ]
  update_scripts_classes`, listing every expected global class
  (`GridTypes`, `LaserSystem`, `LevelData`, `TilePlacement`, `TileVisual`,
  `EmitterTile`, `MirrorTile`, `TargetTile`, `BlockerTile`) with zero
  `SCRIPT ERROR` / `Parse Error` lines.
- **AUTOMATED — DONE.** `godot --headless --path .` (no script override)
  runs the real main scene (`main_menu.tscn`) with real autoloads and
  produces zero runtime errors before being terminated. This confirms
  `main_menu.gd`'s `_ready()` (which touches `SaveManager` and
  `GameManager`) executes cleanly on a fresh project (no save file yet).

## Main Menu

- **MANUAL — DONE.** Desktop click-through confirmed Main Menu working
  overall (user report, desktop test pass). Individual button behaviors
  below were not separately itemized in that report — re-confirm
  specifically if a regression is suspected:
  - Play button opens Level Select.
  - Continue button: disabled on a fresh install (no save file yet);
    after completing a level, becomes enabled and jumps directly into
    gameplay at the correct level.
  - Settings button opens the Settings screen; Back returns to Main Menu.
  - Quit button: visible and functional on desktop
    (`OS.has_feature("mobile") == false`); hidden on a mobile export.

## Level Selection

- **AUTOMATED (partial) — DONE.** `level_select.gd`'s population logic
  (`_populate_levels()`) itself can't run under `--script` mode (needs
  `SaveManager`/`GameManager`), but `LevelManager.LEVEL_PATHS` was read
  directly from the script's constant map (no autoload needed) and
  confirmed to have **15** entries, all 15 loading without error.
- **MANUAL — DONE (Milestone 1, 5 levels only).** Desktop click-through
  confirmed Level Selection working overall for the original 5 levels
  (user report). Specific sub-cases not separately itemized in that
  report:
  - Exactly 5 buttons appeared, Level 1 unlocked/no stars, Levels 2–5
    showed `LOCKED` before any progress existed.
  - Locked level buttons are non-interactive.
  - After completing Level 1, Level 2 becomes tappable and Level 1 shows
    its earned star count.
  - Back button returns to Main Menu.
- **MANUAL — pending (Milestone 2, levels 6–15).** Never visually
  confirmed: that all 15 buttons now appear (not just 5), that the
  `GridContainer`'s 3-column layout still looks reasonable with 15
  entries instead of 5 (5 rows now instead of ~2), and that Level 6
  unlocks correctly after completing Level 5 (sequential unlocking
  across the Milestone 1 → Milestone 2 boundary specifically).

## Level loading / grid generation

- **AUTOMATED — DONE.** Loading `level_01.gd` into a live `GridManager`
  instance (`grid.tscn`, added to a real `SceneTree`, given a 600x600
  size) produces a non-zero `cell_size` and `is_solved == false`
  immediately after `load_level()`.

## Emitter direction / mirror reflection / fixed vs. rotatable

- **AUTOMATED — DONE (all 5 levels).** For each of `level_01.gd`
  through `level_05.gd`: loaded the level, verified the *initial* mirror
  state is **not** already solved, then replayed exactly the documented
  solution sequence (each move = one call to the same toggle logic
  `GridManager._on_mirror_clicked()` uses) through the real
  `LaserSystem.simulate()`, and confirmed:
  - the level becomes solved after exactly `optimal_moves` moves,
  - the resulting star count is 3 (using the same formula as
    `LevelManager.calculate_stars()`).

  Results (all PASS):

  | Level | optimal_moves | Result |
  |---|---|---|
  | 1 First Light | 1 | PASS |
  | 2 Reflection | 2 | PASS |
  | 3 Obstruction | 2 | PASS |
  | 4 Fixed Point | 2 | PASS |
  | 5 Three Turns | 3 | PASS |

- **AUTOMATED — DONE.** Both `/` (SLASH) and `\` (BACKSLASH)
  reflection cases are exercised across the 5 levels above (every
  `GridTypes.reflect()` branch is hit by at least one level's solution
  path).
- **MANUAL.** Fixed mirror (Level 4, `Vector2i(2,4)`) does not rotate
  when tapped in a running game window, and does not increment the move
  counter. General mirror-tap interaction was confirmed working in the
  desktop pass, but this specific fixed-mirror edge case was not called
  out separately — worth a targeted re-check.
- **AUTOMATED — DONE.** `GridManager`: after solving Level 1, a second
  click on the same mirror position was issued directly — the mirror's
  stored orientation did not change (post-completion interaction is
  correctly blocked at the state level, not just visually).

## Touch input / mouse input

- **MOUSE: MANUAL — DONE.** Mouse-driven mirror rotation confirmed
  working in the desktop click-through pass.
- **TOUCH: MANUAL — pending.** Not exercised (desktop has no touch
  input). Needs a manual tap test on the Android device once the debug
  APK (`builds/android/beamshift-debug.apk`) is installed — see
  "Android device test" below.

## Move counting / Reset

- **AUTOMATED — DONE.** `GridManager.reset_level()` after solving Level 1
  restored `is_solved = false` and restored the mirror at `(2,2)` to its
  *original* `BACKSLASH` orientation from `level_01.gd` (not just "some"
  unsolved state — the exact authored initial state).
- **MANUAL — DONE.** `game.gd`'s move counter label (`MOVES: N`) and
  Reset were exercised as part of the desktop gameplay pass ("Gameplay
  working" / "Level progression working" in the user's report). The
  specific invalid-tap-does-not-increment-counter edge case below was not
  separately itemized — worth a targeted re-check:
  - Confirm an invalid tap (e.g. tapping an empty cell or a fixed mirror)
    does not increment the counter.

## Blocker

- **AUTOMATED — DONE.** Level 3's default (unsolved) mirror state routes
  the beam directly into the blocker at `(2,0)`, and `LaserSystem`
  correctly terminates the beam there without activating the target —
  confirmed as part of the per-level solvability test above (the
  intermediate un-solved states were printed and checked).

## Target detection

- **AUTOMATED — DONE.** Covered by the same per-level test: each level's
  target only reports `activated_targets` containing its position once
  the beam actually reaches it, and `solved` only becomes `true` at that
  point.

## Loop protection

- **AUTOMATED — DONE.** A synthetic level (4 mirrors arranged in a closed
  square cycle, fed by an emitter positioned so its beam enters the cycle
  and never reaches an edge/blocker/target) was run through
  `LaserSystem.simulate()` directly. Result: `looped == true`,
  `solved == false`, completed in 0ms (measured with
  `Time.get_ticks_msec()`), confirming the `visited_states` guard
  prevents a hang. See `ARCHITECTURE.md`'s "Loop protection" section for
  the exact mirror layout, and `DECISIONS.md`/`CLAUDE.md` for why this
  guard must never be removed.

## Milestone 2: multi-beam simulation and all 15 levels

- **AUTOMATED — DONE (all 15 levels).** Extended the same per-level
  solvability test above to cover `level_06.gd` through `level_15.gd`.
  For each: loaded the level, verified the initial state is **not**
  already solved, replayed the documented move sequence (mirror/splitter
  toggles) through `LaserSystem.simulate_until_stable()`, and confirmed
  it solves in exactly `optimal_moves`, scoring 3 stars.

  Results (all PASS):

  | Level | optimal_moves | Result |
  |---|---|---|
  | 6 Twin Targets | 1 | PASS |
  | 7 Split Path | 1 | PASS |
  | 8 True Color | 1 | PASS |
  | 9 Recolor | 1 | PASS |
  | 10 Through the Portal | 1 | PASS |
  | 11 Switch and Gate | 1 | PASS |
  | 12 Danger Zone | 2 | PASS |
  | 13 Two Sources | 2 | PASS |
  | 14 Convergence | 1 | PASS |
  | 15 All Systems | 2 | PASS |

  Levels 1–5 were re-run through the same (rewritten) `LaserSystem` in
  the same pass and still all PASS — see "Backward compatibility" below.

  Level 15 initially **failed** this test on first authoring — a portal
  exit tile had accidentally been placed on a different chain's own
  beam path, hijacking it. This is recorded, not hidden: it's a genuine
  example of why the automated per-level check matters even for
  hand-authored levels; the level was fixed (portal moved to a
  non-conflicting cell) and re-verified.

- **AUTOMATED — DONE.** Multiple required targets: a synthetic level
  (one emitter, two targets on its straight path) confirms both activate
  and `solved` requires both; a variant with a blocker between them
  confirms only the reachable one activates and `solved` stays false.
  Also confirmed live on Level 6 (`activated_targets.size() == 2` after
  the documented solution).
- **AUTOMATED — DONE.** Splitter: a synthetic level confirms both the
  straight and reflected branches are recorded as separate entries in
  `result["beams"]`, and each can independently activate a different
  target. Also confirmed live on Level 7 and Level 14.
- **AUTOMATED — DONE.** Color matching
  (`GridTypes.target_accepts_color()`): a RED beam activates a
  RED-required target; a BLUE beam does **not** activate a RED-required
  target; a WHITE (neutral) target accepts a non-WHITE beam. Also
  confirmed live on Level 8.
- **AUTOMATED — DONE.** Filter recoloring: a BLUE beam passing through a
  RED filter activates a RED-required target immediately after. Also
  confirmed live on Level 9 and Level 14.
- **AUTOMATED — DONE.** Portal travel: a beam entering one portal of a
  valid pair exits the other, preserving direction, and reaches a target
  with no direct line of sight from the emitter; the resulting beam has
  2+ `segments` (confirming the "no line across the teleport distance"
  rendering requirement is satisfiable from the data shape alone). Also
  confirmed live on Level 10 (`segments.size() >= 2` after the solution)
  and Level 15.
- **AUTOMATED — DONE.** Portal fail-safe: a single **unpaired** portal
  (pair size 1, not 2) does not crash and the beam passes through as if
  the cell were empty.
- **AUTOMATED — DONE.** Switch/gate: a synthetic two-emitter level (one
  beam hits a switch, a separate beam is blocked by that switch's linked
  gate) confirms the gate is closed before the switch fires and open
  (via `simulate_until_stable()`'s multi-pass resolution) after, and that
  a level with a closed gate and **no** switch anywhere stays unsolved.
  Also confirmed live on Level 11 (gate closed → open, `solved` true
  after) and Level 15 (gate resolves independently of the level's other
  hazard/portal chain).
- **AUTOMATED — DONE.** Hazard: a beam directed straight into a hazard
  sets `hazard_hit = true` and `solved = false` even with zero other
  obstacles; a level where the target is reachable without crossing a
  (present but avoided) hazard has `hazard_hit = false` and solves
  normally. Also confirmed live on Level 12 (hit before routing, clear
  after) and Level 15 (hazard and gate resolve independently within the
  same level).
- **AUTOMATED — DONE.** Multiple emitters: a synthetic two-emitter,
  two-target level confirms both targets activate and `result["beams"]`
  contains one entry per emitter. Also confirmed live on Level 13 and
  Level 15.
- **AUTOMATED — DONE.** Loop protection re-verified after the rewrite:
  the exact Milestone 1 4-mirror closed-loop geometry still produces
  `looped == true` through the new `simulate_until_stable()`, in well
  under a second. A separate portal-heavy configuration (not a
  mathematically proven cycle, just a stress case combining portals +
  mirrors) also terminates promptly — see `ARCHITECTURE.md`'s "Loop
  protection" section for why the shared `visited_states` guard is
  correct by construction, not just empirically fast.
- **AUTOMATED — DONE.** `GridManager` scene-level test (not just
  `LaserSystem` in isolation): a synthetic level combining a splitter,
  filter, colored target, switch, and gate was loaded into a **real**
  `GridManager` under a live `SceneTree`, with real `SplitterTile`,
  `FilterTile`, `TargetTile`, `SwitchTile`, `GateTile` nodes. Confirmed:
  the gate/target driven by switch resolves automatically with zero
  rotations; the color-matched target requires exactly the documented
  splitter rotation; `reset_level()` correctly restores both the
  splitter's original orientation and the gate's default (closed) state.

### Backward compatibility (Milestone 1 levels through the rewritten simulator)

- **AUTOMATED — DONE.** All 5 Milestone 1 levels (`level_01`–`level_05`)
  re-verified solvable in their documented `optimal_moves` through the
  Milestone 2 `LaserSystem` rewrite (see the results table above — this
  is the same test run, not a separate pass).
- **AUTOMATED — DONE.** The 5 Milestone 1 level files were migrated from
  the old positional `TilePlacement.new(...)` constructor (removed) to
  the new static `make_*()` factories — re-running the solvability test
  after this migration is what confirms the rewrite preserved identical
  tile data, not just similar-looking data.
- Beams now continue past an activated target instead of stopping there
  (see `ARCHITECTURE.md`/`DECISIONS.md` D22) — hand-re-traced for all 5
  Milestone 1 levels to confirm this never changes their `solved` outcome
  (Level 4's beam draws one harmless extra segment to the grid edge after
  its target; no other level is affected even visually).

## Level completion / Stars

- **AUTOMATED — DONE.** Solving a level via the documented move sequence
  correctly sets `is_solved = true` (see the per-level test above).
- **MANUAL — DONE (general).** The user's desktop pass reported "Level
  progression working," which necessarily exercised the
  `LevelCompletePopup` (moves/stars text, Next Level button) since
  progressing through levels requires it to appear and function. Not
  separately itemized: Next Level button's hidden state specifically on
  the last level (Level 5) — worth a targeted re-check.

## Retry / Next Level / Level Select return (from the popup)

- **MANUAL — DONE (general).** Covered by the same "Level progression
  working" desktop confirmation — Next Level was necessarily used to
  progress through multiple levels. Retry and Level Select specifically
  were not separately itemized — worth a targeted re-check if not
  already tried.

## Save creation / loading / best-score preservation / sequential
unlocking / malformed save handling

- **MANUAL — DONE (partial).** "Level progression working" in the
  desktop report confirms, at minimum, that completing a level writes a
  save and unlocks the next one correctly within a single session
  (`SaveManager.record_level_result()`'s core write path and
  `is_level_unlocked()` both exercised for real, not just read/reasoned
  about).
- **MANUAL — still open.** Not confirmed by the report above, and still
  the biggest gap in this milestone's validation:
  1. Save **persistence across a full app relaunch** — quit and restart
     the game, confirm progress/stars survived (currently only tested
     within one continuous session).
  2. **Best-result preservation** — solve a level again with more moves
     than a previous 3-star run, confirm the star count and best-move
     count do **not** regress.
  3. **Malformed save handling** — manually corrupt
     `user://savegame.json` (e.g. truncate it or write `not json`),
     relaunch, confirm the game falls back to defaults instead of
     crashing.

## Portrait UI behavior / Responsive layout

- **MANUAL — DONE (general).** The desktop pass confirmed "Portrait
  layout working" at the window size actually used for testing. The
  specific multi-resolution resize matrix below was not part of that
  report and remains open:
- **MANUAL — still open.** Test at minimum these representative window sizes by
  resizing the desktop editor's game window (these are **test sizes
  only**, never hardcode gameplay against them):
  - 720×1280
  - 1080×1920 (project's reference resolution)
  - 1080×2160
  - 1080×2400
  - one wider/tablet-like portrait ratio (e.g. 1600×2000)

  At each size, confirm:
  - No UI clipping or overlap on Main Menu, Level Select, Gameplay HUD,
    Level Complete popup, Settings.
  - The puzzle grid stays square and its cells stay square (this is
    computed in `GridManager._recalculate_layout()` from the smaller of
    the container's width/height — verify it visually, since the
    automated tests only checked that `cell_size > 0`, not that it's
    visually centered/correct).
  - Buttons remain comfortably tappable (not shrunk below a reasonable
    touch target) — every interactive button now targets a 144px minimum
    (`UIConstants.MIN_TOUCH_TARGET`, see `ARCHITECTURE.md`), verify this
    visually holds up at each tested size.
  - Text doesn't clip or overlap.
  - The Level Complete popup stays fully on-screen at every size tested.
  - Top/bottom HUD elements and Level Select's top bar keep visible
    breathing room from the screen edges (`SafeAreaMargin`'s baseline
    96px margin) rather than sitting flush against them.
- **MANUAL.** Resize the desktop window live while the gameplay scene is
  open and confirm the grid recomputes its layout smoothly (this is what
  the `resized` signal connection in `grid_manager.gd` is for), **and**
  that `SafeAreaMargin`'s margins stay stable (they recompute on
  `get_viewport().size_changed`, same signal family) rather than
  flickering or lagging behind the resize.

## Manual test checklist: Milestone 2 mechanics (desktop)

None of these have been manually exercised yet — everything below is
open. Run the project in the Godot editor (F5) and, for each, open the
relevant level from Level Select:

- **Multiple targets** (Level 6): confirm the beam visibly passes
  through the first target without stopping, and that the level only
  shows complete once both are lit.
- **Splitter interaction** (Level 7, 14): tap the splitter and confirm
  both the straight and branch beams redraw correctly, with the branch
  visibly changing angle.
- **Colored beams** (Level 8, 9, 14): confirm the beam `Line2D` actually
  renders in the emitter's/filter's color, not just white.
- **Colored targets** (Level 8): confirm the target's color ring matches
  its required color, and that it only lights up for a matching beam.
- **Filters** (Level 9, 14): confirm the beam's visible color changes
  immediately after crossing the filter tile.
- **Portals** (Level 10, 15): confirm the beam visibly disappears at one
  portal and reappears at its pair, with **no** connecting line drawn
  across the gap between them (this is the specific rendering
  requirement `ARCHITECTURE.md`'s "Laser visualization" section
  describes — worth a close look).
- **Switch/gate interaction** (Level 11, 15): confirm the gate's visual
  changes from closed (solid bar) to open (gapped bars) after the linked
  switch is hit, and that this happens automatically (no extra move) once
  the routing move is made.
- **Hazards** (Level 12, 15): confirm the hazard icon visually flashes/
  changes when hit, and that the game does **not** show a game-over or
  block further mirror rotation while a hazard is hit — the player should
  be able to keep adjusting mirrors freely.
- **Multiple emitters** (Level 13, 15): confirm both emitters' beams
  render simultaneously and independently.
- **Reset** (any Milestone 2 level): confirm Reset restores every
  splitter's orientation, every gate's visual to closed, every hazard's
  visual to untriggered, and every colored target to inactive — not just
  mirrors.
- **Retry / Next Level / Level Select** (from the Level 15 completion
  popup specifically): confirm the flow still works at the new highest
  level number.
- **Save/progression across the new levels**: complete Level 5, confirm
  Level 6 unlocks; complete through Level 15, confirm `Continue` from the
  Main Menu still resolves correctly with no more unlocked-but-incomplete
  levels.

## Milestone 3: level editor, solver, validator, metrics

- **AUTOMATED — DONE.** All 15 levels re-verified via `LevelSolver`
  (independent of the Milestone 1/2 direct-replay tests): for each,
  `LevelValidator.validate()` reports zero errors, and
  `LevelSolver.analyze()` returns `status == "SOLVABLE"` with
  `optimal_moves` exactly matching the level's declared value. This is a
  genuinely different check than replaying one documented move sequence
  - the solver explores the *entire* rotatable-piece state space, so it
  would catch an accidentally-shorter or accidentally-absent solution
  that a hand-traced sequence test could miss. `LevelMetrics.compute()`
  was also run against all 15 and confirmed to execute without error and
  produce a difficulty label for each.

  | Level | Declared optimal | Solver optimal | Match |
  |---|---|---|---|
  | 1–15 | (see earlier tables) | identical | PASS (all 15) |

  Level 5 specifically was confirmed to have exactly one "possible
  decoy" flagged at the position of its intentionally-unused mirror
  (`Vector2i(4, 0)`) — the solver independently rediscovering a design
  choice that was deliberately built in, which is a meaningful positive
  signal for the decoy-detection feature's correctness, not just its
  absence of crashing.

- **AUTOMATED — DONE.** `LevelValidator` negative-case testing: a level
  missing an emitter, missing a required target, containing a
  duplicate/out-of-bounds tile, an unpaired portal, and a switch
  referencing a nonexistent gate_id, each independently confirmed to
  produce at least one error. A gate with no switch confirmed to produce
  a *warning*, not an error (level stays saveable). A trivially-solved
  (zero-move) level confirmed to produce the "TRIVIAL SOLUTION" warning.
- **AUTOMATED — DONE.** `LevelSolver` three-way status testing: a
  constructed unsolvable level (blocker directly in the beam's only
  path, with a rotatable mirror positioned where the beam can never
  reach it) confirmed `status == "UNSOLVABLE"` with the full state space
  exhausted (`states_explored` small and finite, not the search limit).
  The same level analyzed with `max_states = 0` confirmed
  `status == "UNKNOWN"` — proving the implementation does not conflate
  "search budget exhausted" with "proven no solution exists."
- **AUTOMATED — DONE.** Multiple-solutions detection: a constructed
  level with two entirely independent single-mirror chains both feeding
  the same required target confirmed `shortest_solution_count == 2` at
  `optimal_moves == 1` — both 1-move states found and neither treated as
  more optimal than the other.
- **AUTOMATED — DONE.** Search-limit demonstration fixture
  (`fixture_search_limit.gd`, 9 rotatable pieces = 2^9 = 512 states):
  confirmed `status == "SOLVABLE"` and correct `optimal_moves` at the
  *default* search limit (65536) in under a few milliseconds, and
  confirmed `status == "UNKNOWN"` (not a false `"UNSOLVABLE"`) when
  called with an artificially tiny `max_states = 5`.
- **AUTOMATED — DONE.** All 6 editor fixture levels
  (`levels/editor_fixtures/*.gd`) individually confirmed to produce
  exactly their documented validator/solver behavior - see
  `ARCHITECTURE.md`'s "Milestone 3 editor fixtures" section for the
  one-line summary of each and what it proves.
- **AUTOMATED — DONE.** `.tres` save/load roundtrip: a `LevelData`
  (including a typed `Array[TilePlacement]` with an emitter, a
  non-rotatable mirror, and a colored target) was written via
  `ResourceSaver.save()` and read back via `load()`; every field
  (`level_id`, `display_name`, grid dimensions, tile count, emitter
  color, mirror `rotatable` flag, target required color) confirmed
  identical after the roundtrip, and the roundtripped level confirmed
  still structurally valid and still solvable in its original move
  count.
- **AUTOMATED — DONE.** The real editor scene, instantiated under a live
  `SceneTree` with real autoloads (via the temporary `run/main_scene`
  swap technique described above), driven through its actual
  UI-triggering methods (`_on_tool_selected`, `_on_cell_clicked`,
  `_on_solve_pressed`, `_on_save_pressed`, `_on_load_pressed`,
  `_on_new_pressed`, direct `TilePlacement` field mutation matching what
  a property-panel control's callback would do):
  - Placing an emitter tile via a simulated palette click produces a
    real `TilePlacement` with the correct default direction, and
    mutating its `direction` field is immediately reflected when the
    same cell is queried again (confirms the "live object reference,
    no separate apply step" design actually works, not just that it's
    intended to).
  - Placing a mirror + target and running the real Solve button's
    handler correctly reports the level solvable in 1 move.
  - Saving via the real Save button's handler writes a loadable `.tres`
    file; clearing the editor's tiles and loading that file back through
    the real Load button's handler restores the level ID, display name,
    the target tile, and the mirror's non-default orientation correctly.
  - The saved file correctly appears in the Load dropdown after a save
    (confirming `_populate_load_dropdown()` is actually called and
    re-scans, not just that the file exists on disk).
  - Attempting to Save a level with no emitter/target through the real
    Save button's handler is correctly blocked - no file is written.
  - Resizing the grid smaller via the real "Apply Grid Size" handler
    correctly drops a tile that's now outside the new bounds while
    keeping tiles that still fit.
  - (Two early false failures during this testing were traced to flawed
    *test* assumptions, not editor bugs - see `PROJECT_HANDOFF.md`'s
    "Known issues" for the resize-preserves-tiles behavior, and a stale
    file left on disk from an earlier test run before that was
    understood. Both were root-caused and fixed in the test, not papered
    over.)
- **AUTOMATED — DONE.** Android export re-verified after the export
  filter change (see "Android build export" below) - this is the
  Milestone 3-relevant regression check for "did the editor tooling
  break the build," per the milestone brief's explicit Part 33
  requirement.

## Manual test checklist: level editor (desktop only — this is a development tool)

None of these have been performed yet. Open
`tools/level_editor/level_editor.tscn` in the Godot editor and press F6:

- Create a new 5x5 level, place an emitter/mirror/target, confirm the
  grid cells visually update immediately on placement.
- Click Select/Inspect, click the mirror, confirm the properties panel
  shows exactly Orientation + Rotatable (not fields from other tile
  types).
- Change the mirror's orientation via the properties panel dropdown,
  confirm the grid cell's `/`/`\` label updates immediately.
- Click Validate on an intentionally broken level (e.g. delete the
  emitter) and confirm the error appears in the output panel and Save
  is refused.
- Click Run Solver / Analyze on a solvable level and confirm the
  reported optimal move count, solution path, and difficulty estimate
  all appear and look reasonable.
- Click Playtest, solve the level in the real game window by hand,
  confirm the moves used match what the solver reported, then click
  Back or Level Select on the completion popup and confirm you land back
  in the editor with your level exactly as you left it (not reset).
- Save the level to a `.tres` path, close and reopen the editor scene
  (stop and re-run with F6), Load that file, confirm every field
  restored correctly.
- Load one of the 6 fixture levels from the `[fixture]`-prefixed dropdown
  entries and confirm the editor correctly displays its intentionally
  broken/edge-case state (e.g. the unpaired portal fixture shows a lone
  portal tile with no partner).
- Resize an existing level's grid smaller and confirm tiles now outside
  the bounds are dropped with a visible message, while in-bounds tiles
  are kept.

## Android build export

- **AUTOMATED — DONE.** `export_presets.cfg` defines an "Android Debug"
  preset (package `com.beamshift.game`, `arm64-v8a`, min SDK 24 / target
  SDK 36, debug-signed with the local Godot debug keystore). Exported
  successfully via `godot --headless --export-debug "Android Debug"
  "builds/android/beamshift-debug.apk"` — a ~28.4 MB APK, aligned and
  signed, zero export errors.
- **AUTOMATED — DONE.** Inspected the exported `AndroidManifest.xml`
  directly with `aapt2 dump xmltree`/`dump badging` (not just trusted the
  export to "succeed silently correct"):
  - `screenOrientation=1` (portrait) — confirmed correct only after
    fixing a real bug where this was stored as the string `"portrait"`
    instead of the required integer enum, which had silently produced
    `screenOrientation=0` (landscape). See `DECISIONS.md`/
    `PROJECT_HANDOFF.md` for the fix.
  - `package name='com.beamshift.game'`, `minSdkVersion='24'`,
    `targetSdkVersion='36'`, `versionName='1.0'` all correct.
  - `native-code: 'arm64-v8a'` — matches the preset's architecture
    selection.
- Two Android-specific project settings had to be added to make export
  possible at all — `rendering/textures/vram_compression/import_etc2_astc
  = true` (Android export refuses without it) and the orientation fix
  above. Both are recorded in `DECISIONS.md`.
- **AUTOMATED — DONE (re-export after the mobile UI polish pass).**
  Re-ran the same export command after the `UIConstants`/`SafeAreaMargin`
  UI fix (no `export_presets.cfg` or `project.godot` Android-specific
  settings changed this time — only `.tscn` scene edits). Zero export
  errors; re-confirmed `screenOrientation=1` via `aapt2 dump xmltree`.
- **AUTOMATED — DONE (re-export after Milestone 2).** Re-ran the same
  export command after the multi-beam simulator rewrite, 6 new tile
  types, and 10 new levels. No `export_presets.cfg`/Android-specific
  `project.godot` settings changed. Zero export errors; re-confirmed
  `screenOrientation=1` via `aapt2 dump xmltree`. **This confirms the
  build is well-formed, nothing more** — it does not confirm the new
  mechanics work correctly on a device (touch input on new tile types,
  color rendering, on-device performance with more procedural `_draw()`
  tiles per cell) — see "Android device test" Round 3 below.
- **AUTOMATED — DONE (re-export after Milestone 3).** `export_presets.cfg`'s
  `exclude_filter` was extended to
  `tools/**,scripts/tools/**,levels/editor_fixtures/**` (the level
  editor and its supporting tooling should never ship to players - see
  `DECISIONS.md` D24). Re-exported successfully with zero errors;
  `screenOrientation=1` and package id/SDK versions reconfirmed
  unchanged. This is the Milestone 3-relevant Android regression check
  the brief's Part 33 explicitly asks for ("ensure Android export is not
  broken by editor tooling") - the risk being tested here is narrowly
  "does the exclude filter syntax work / does excluding these paths
  break anything the shipped game still needs," which the successful
  export answers; it does not re-test Milestone 1/2 gameplay on-device
  (unaffected by this change, and not re-tested for that reason).

## Milestone 4A: final asset integration

- **AUTOMATED — DONE.** `godot --headless --path . --import` after every
  visual rewrite (tile scripts, all UI scenes, theme, project.godot,
  export_presets.cfg): zero errors.
- **AUTOMATED — DONE.** Re-ran the Milestone 3 `LevelSolver`-vs-declared-
  `optimal_moves` check across all 15 levels *after* the tile visual
  rewrite (script: load each `levels/level_XX.gd`, call
  `LevelSolver.analyze()`, compare against `level_data.optimal_moves`).
  All 15 still PASS, identical to Milestone 3's own results — confirms
  the visual-only rewrite didn't touch simulation behavior (it shouldn't
  have, since `LaserSystem`/`GridTypes`/`grid_manager.gd`'s state-owning
  logic were never edited, but this re-confirms it rather than assuming).
- **AUTOMATED — DONE.** Scene-level smoke test: instantiated the real
  `scenes/gameplay/grid.tscn` under a live `SceneTree` (no autoload
  needed, see D6), loaded Level 15 (emitter, mirror, target, portal,
  switch, gate, hazard — the most tile-diverse level), called
  `_on_orientable_tile_clicked()` on a mirror/splitter, and forced a
  resize + `_recalculate_layout()`. Zero script errors from any of the 5
  rewritten texture-based tile visuals (`MirrorTile`/`TargetTile`/
  `BlockerTile`/`GateTile`/`HazardTile`), the new
  `GridManager._background_root` cell-background layer, or the new
  interaction-feedback Tweens (mirror selection pulse, target activation
  pulse) and `PortalTile._process()` idle-pulse animation.
- **AUTOMATED — DONE.** `game.tscn`, `level_select.tscn`, and
  `settings_menu.tscn` each booted headlessly with real autoloads via the
  documented temporary `run/main_scene` swap (each reverted immediately
  after, confirmed back to `res://scenes/ui/main_menu.tscn` before moving
  on). Zero script errors from: the new Pause menu instance and its
  signal wiring in `game.gd`, the new HUD frame/icon nodes, the reworked
  `level_button.tscn`'s `%Background`/`%NumberLabel`/`%Star1-3` unique-
  name lookups populating for all 15 levels, the new `CheckButton` icon
  overrides and `PanelContainer` `StyleBoxTexture` in Settings.
- **AUTOMATED — DONE.** Android debug export re-ran successfully with the
  new final art included (`godot --headless --export-debug "Android
  Debug" "builds/android/beamshift-debug.apk"`), zero errors. Inspected
  the exported APK directly (not just trusted a successful export):
  `aapt2 dump badging` confirms `package='com.beamshift.game'`, and
  `res/mipmap-anydpi-v26/icon.xml` + populated `mipmap-*dpi/icon*.webp`
  entries confirm the new `bs_app_icon.png` was actually used to generate
  adaptive launcher icons (previously the stock Godot icon, unconfigured
  launcher icon slots). `aapt2 dump xmltree --file AndroidManifest.xml`
  re-confirms `screenOrientation=1`, `minSdkVersion=24`,
  `targetSdkVersion=36` — all unchanged by this visual-only milestone.
  **APK size grew from ~28.4 MB to ~107 MB** (recorded, not silently
  ignored — most of the ~80 new PNGs are still `Lossless`-compressed for
  UI/icon sharpness; only the 3 full-screen backgrounds were switched to
  `VRAM Compressed`. Worth revisiting before a release build if size
  becomes a concern.)

None of the following have been performed — **MANUAL, not yet done**:

- Open the project in the Godot editor (F5) and visually confirm every
  screen: Main Menu (logo/background/button art), Level Select (locked/
  unlocked/completed card art + star icons at various scroll positions),
  Settings (panel + toggle icons), gameplay HUD (top/bottom frame art,
  icon buttons), Level Complete (panel + star icons + new Best Moves
  row), and the new Pause menu (panel art, all 5 buttons).
- Specifically check the best-effort button/panel `StyleBoxTexture`
  9-slice margins (`DECISIONS.md` D36) for stretching artifacts at the
  actual in-game button sizes (144-360px) — these were chosen as a
  fraction of each source image's dimensions, not measured against the
  art's real rounded-corner radius, since no image-viewing/measurement
  tool was available this session.
- Confirm the mirror's orientation-to-rotation mapping (BACKSLASH = 0°,
  SLASH = 90°, see `mirror.gd`) actually matches which diagonal the
  source art shows by default — this was a guess (purely cosmetic; wrong
  either way never affects gameplay, only which diagonal looks "right"
  for which state).
- Play through all 15 levels checking that the 5 still-procedural tile
  types (emitter, splitter, portal, switch, filter) don't look jarringly
  inconsistent next to the 5 final-art tiles (mirror, target, blocker,
  gate, hazard) — this is a known, deliberate, documented gap (D31), but
  worth seeing how it actually reads in motion.
- Confirm the laser beam visual upgrade (brighter core, rounder joins)
  actually looks like an improvement at real screen size/resolution, and
  that beam colors (WHITE/RED/GREEN/BLUE) all still read clearly against
  the new backgrounds.
- Pause menu: open via the new HUD Pause button AND via the Android back
  gesture (desktop: Esc, which raises the same
  `NOTIFICATION_WM_GO_BACK_REQUEST`) during active gameplay; confirm the
  puzzle is genuinely frozen (mirror/splitter taps don't register, the
  move counter doesn't advance) while paused; confirm Resume/Restart/
  Settings/Level Select/Main Menu each behave as expected; confirm
  pressing back/Esc again while Pause is already open closes it
  (Resume), and that it does nothing while the Level Complete popup is
  showing (shouldn't be dismissible via back mid-completion).
- Confirm Android back on Main Menu/Level Select/Settings still behaves
  exactly as before this milestone (quit / go to Main Menu / go to Main
  Menu respectively) now that `quit_on_go_back` was disabled project-wide
  and each screen replicates it manually (`DECISIONS.md` D34) — this is a
  behavior-preservation claim that needs a real back-gesture press to
  confirm, not just code review.
- Responsive layout re-check at the same 5 sizes as before (720×1280,
  1080×1920, 1080×2160, 1080×2400, ~1600×2000 tablet-like), now with real
  background/frame/panel art instead of flat colors — confirm nothing
  clips, art doesn't look badly stretched at any of them, and the puzzle
  grid still reads clearly against the new gameplay background.
- Android device install of the new APK (`adb install -r
  builds/android/beamshift-debug.apk`) — touch targets with the new
  icon-based buttons, Pause menu usability, on-device look of the new
  art, and whether the ~107 MB size is acceptable for this project.

## Milestone 4A.1: UI integration correction pass

Milestone 4A's visual integration **failed manual QA** (14 reported
problems - see `CHANGELOG.md`/`DECISIONS.md` for the full list). This
section covers the correction pass, not a repeat of Milestone 4A's own
(still valid) checks above.

- **AUTOMATED — DONE.** `godot --headless --path . --import` after every
  corrected scene/script (theme, `game.tscn`, `main_menu.tscn`,
  `level_select.tscn`/`level_button.tscn`, `settings_menu.tscn`/`.gd`,
  `pause_menu.tscn`, `level_complete_popup.tscn`): zero errors.
- **AUTOMATED — DONE.** Re-ran the `LevelSolver`-vs-declared-`optimal_moves`
  check across all 15 levels again after this correction pass. All 15
  still PASS, identical to Milestone 4A/3's results - this pass touched
  zero simulation code, only confirms nothing was accidentally affected.
- **AUTOMATED — DONE.** `game.tscn`, `settings_menu.tscn`, and
  `level_select.tscn` each booted headlessly with real autoloads via the
  documented temporary `run/main_scene` swap (each reverted immediately
  after, confirmed back to `res://scenes/ui/main_menu.tscn`). Zero script
  errors from: the rebuilt HUD icon buttons (Back/Reset/Pause/Hint, each
  now a fixed-size `TextureRect` inside a fixed-size `Button` instead of
  a raw `Button.icon`), the reworked Settings toggle widgets
  (`toggle_mode` `Button` + `TextureRect`, replacing `CheckButton`), and
  the level-select card/grid restructure (`CenterContainer`-wrapped
  `GridContainer`, fixed-size non-expanding cards).
- **AUTOMATED — DONE.** Android debug export re-ran successfully with the
  corrected layout, zero errors.
- **AUTOMATED — NOT POSSIBLE IN THIS ENVIRONMENT (explicitly noted, not
  silently skipped):** actually rendering a frame and measuring resulting
  control sizes/positions. This is precisely the gap that let Milestone
  4A ship with a catastrophically oversized Reset icon while every
  headless script-error check passed - see `DECISIONS.md` D37. There is
  no substitute for a human (or a screenshot-capable tool this session
  didn't have) actually looking at the rendered UI.

**MANUAL — NOT YET DONE, and this is the check that actually matters for
this milestone.** Per the correction brief: only the user can approve
Milestone 4A.1, after reviewing it visually (in-editor and/or on a
device). Checklist, keyed to the 14 originally-reported problems:

1. Reset icon in the gameplay HUD renders small (a ~64px glyph inside a
   144px button), not large enough to obstruct the puzzle board.
2. Gameplay HUD top/bottom frame art no longer overlaps the puzzle grid -
   the grid should visibly occupy the clear majority of vertical space.
3. Pause menu panel is a reasonable size (not near-full-screen) with
   RESUME/RESTART/SETTINGS/LEVEL SELECT/MAIN MENU clearly readable and
   evenly spaced, with no text sitting on top of the panel's own "PAUSE"
   header art.
4. Settings panel: SETTINGS header (baked into the art) is not
   duplicated by a second text label; Sound/Music rows with their
   toggle-switch graphics sit inside the panel's plain inner area, not
   over its decorative border/gear emblem.
5. Main Menu buttons (PLAY/CONTINUE/SETTINGS/QUIT) read as comfortably
   large relative to the background, not small/lost in it.
6. Main Menu has a clear "tap here first" hierarchy - PLAY should read
   as visually primary (larger) compared to CONTINUE/SETTINGS, and QUIT
   smallest/distinct.
7. Level Select cards are a consistent, moderate size - not oversized,
   not stretched into a non-square shape.
8. Level Select spacing between cards looks even, and the grid doesn't
   look lopsided/packed to one side.
9. Scrolling Level Select all the way down fully reveals the last row of
   cards with visible breathing room below it, not clipped/flush against
   the screen edge.
10. No text (labels, titles) visibly sits on top of a busy/bright part of
    any panel's decorative artwork.
11. Every button (Main Menu, Pause, Settings, Level Complete) renders at
    a sensible, non-distorted size - no visibly stretched or squished
    button art.
12. Buttons and icons across every screen read as using one consistent
    sizing system (touch targets ~144px, HUD icons ~64px), not an
    arbitrary mix.
13. No decorative art appears to be "filling its own rectangle" in a way
    that crowds or covers a control - e.g., toggle switches are legible
    at their new size, not thumbnail-scale.
14. Overall visual impression: does this now look like a deliberately
    laid-out mobile UI, or still like raw assets dropped into place?

Also re-run the full responsive-layout matrix (unchanged sizes from
Milestone 4A's own checklist: 720×1280, 1080×1920, 1080×2160, 1080×2400,
~1600×2000 tablet-like) now that button/panel/card dimensions have
changed - confirm nothing clips or overlaps at any of them, and that the
gameplay HUD's now-fixed 160px bar height still leaves the puzzle grid
clearly dominant on the smallest (720×1280) size tested.

## Milestone 4A.2: Level 3 fix + runtime-vs-solver validation + responsive rectangle validation

Milestone 4A.1 failed a second manual QA round: Level 3 was
uncompletable in real gameplay, and popup content was still too small.
See `DECISIONS.md`'s "Milestone 4A.2" section (D40-D43) for full
reasoning.

- **AUTOMATED — DONE.** Root-cause diagnosis for Level 3 (see
  `CHANGELOG.md`/D40 for the full sequence): confirmed via direct
  `_on_orientable_tile_clicked()` replay that `LaserSystem`/target
  detection/reset were never broken; confirmed via a temporary debug
  print that `--headless` mode cannot dispatch real `_gui_input` events
  (a Godot limitation, not a bug - see `CLAUDE.md` rule 12a, don't
  re-attempt this test expecting a different headless result); confirmed
  via direct visual inspection of `bs_tile_mirror.png` that the rotation
  mapping was backwards. Fixed with a one-line change to `mirror.gd`.
- **AUTOMATED — DONE.** Re-ran the standard `LevelSolver`-vs-declared
  check across all 15 levels after the fix - unaffected (rendering-only
  change), all still PASS.

### New technique: runtime-vs-solver replay (added this milestone, now part of the standard regression routine)

**Why:** `LevelSolver`/`LaserSystem` only ever read logical tile
orientation - they have no way to detect a bug where a tile's *visual*
state contradicts its logical state (exactly what caused the Level 3
bug). Comparing solver-computed vs. declared `optimal_moves` (the
regression check used through Milestone 4A/4A.1) can never catch this
class of bug, because both sides of that comparison come from the same
pure-logic source. This technique instead **replays the solver's own
solution through a real, instantiated `GridManager`**, exercising the
same method (`_on_orientable_tile_clicked()`) a real tap calls.

**Script** (recreate from this description in a scratch directory - not
committed to the repo, per this project's existing convention for
throwaway test harnesses):
```gdscript
extends SceneTree
const GRID_SCENE := preload("res://scenes/gameplay/grid.tscn")
const LEVEL_PATHS := [ /* res://levels/level_01.gd ... level_15.gd */ ]
var _grid: GridManager
var _frame := 0

func _init() -> void:
    _grid = GRID_SCENE.instantiate()
    get_root().add_child(_grid)
    _grid.size = Vector2(600, 600)

func _process(_delta: float) -> bool:
    _frame += 1
    if _frame == 2:
        for path in LEVEL_PATHS:
            var level_data: LevelData = load(path).new()
            var solver_result: Dictionary = LevelSolver.analyze(level_data)
            var runtime_level: LevelData = load(path).new()
            _grid.load_level(runtime_level)
            for move in solver_result["solution_path"]:
                _grid._on_orientable_tile_clicked(move["position"])
            print("%s -> is_solved=%s" % [path, _grid.is_solved]) # must be true
        quit()
    return false
```
Run with `godot --headless --path . --script <path>.gd` (no autoloads
needed - `GridManager` has none, see D6).

- **AUTOMATED — DONE.** All 15 levels PASS (`is_solved == true` after
  replaying the solver's own solution) both before this milestone's fix
  (confirming Level 3 specifically failed nothing at the simulation
  level - the bug really was presentation-only) and after (confirming
  the mirror fix didn't regress anything).

### New technique: responsive rectangle validation (added this milestone)

**Why:** "headless cannot visually verify" was previously used to justify
not automating Part B8-style resolution checks. That's true for actual
*rendering*, but `Control` layout/anchor math (`get_global_rect()`,
`get_viewport().get_visible_rect()`) runs independently of rendering and
works correctly headlessly - so real Control rects at real target
resolutions CAN be measured and asserted against automatically.

**Critical gotcha (see `DECISIONS.md` D43 and `CLAUDE.md` rule 12b):**
compare rects against `get_viewport().get_visible_rect().size` (the
logical canvas), never the raw physical pixels passed to
`get_viewport().size`. This project's `canvas_items`+`expand` stretch
mode guarantees the 1080×1920 reference is the logical space's *minimum*
size - comparing against raw physical pixels for a narrower/same-aspect
resolution produces false "overflow" failures.

**Script** (recreate as a Node-based scene set temporarily as
`run/main_scene`, since it needs real autoloads - GameManager/SaveManager
- unlike the runtime-vs-solver script above; revert `run/main_scene`
immediately after, per this project's standard temporary-main-scene-swap
technique):
```gdscript
extends Node
const RESOLUTIONS := [Vector2i(720,1280), Vector2i(1080,1920), Vector2i(1080,2160), Vector2i(1080,2400), Vector2i(1600,2000)]
func _ready() -> void:
    for res in RESOLUTIONS:
        get_viewport().size = res
        await get_tree().process_frame
        await get_tree().process_frame
        var logical_size: Vector2 = get_viewport().get_visible_rect().size
        # instantiate each screen (game.tscn, settings_menu.tscn, main_menu.tscn, ...),
        # await 1-2 process_frame calls after each add_child()/state-changing
        # call (opening Pause, calling show_result()) before reading rects,
        # then assert against logical_size: within bounds, >= min touch size,
        # no overlap between known-conflicting pairs (e.g. grid vs HUD bars).
    get_tree().quit()
```
- **AUTOMATED — DONE.** All 5 resolutions PASS for Main Menu (Play
  button), Settings (panel/toggle/Back button), Game (Back/Reset/Pause
  buttons, puzzle grid vs. both HUD bars), Pause menu (panel/Resume
  button), and Level Complete (panel/Next Level button): every checked
  rect within logical canvas bounds, every touch target ≥96px, no
  grid/HUD-bar overlap at any resolution. The puzzle grid's screen-area
  fraction correctly grows on taller aspect ratios (0.667 at 1080×1920,
  0.702 at 1080×2160, 0.730 at 1080×2400), confirming "expand" stretch
  mode is behaving as designed.
- **AUTOMATED — DONE.** `game.tscn`/`settings_menu.tscn` re-booted with
  real autoloads (temporary `run/main_scene` swap, reverted immediately
  after each) after the Part B sizing changes - zero script errors.
- **AUTOMATED — DONE.** Android debug APK re-exported, zero errors.

**MANUAL — NOT YET DONE, and this is what actually matters for approval:**
- Play Level 3 by hand (in-editor or on-device) and confirm it can now be
  completed via normal tapping - specifically confirm the mirror's own
  drawn diagonal now visually agrees with which way it bends the beam.
- Visually confirm Settings/Pause/Level Complete now feel appropriately
  sized on a real phone screen, not squeezed - specifically the
  toggle-switch legibility, button label size, and star size.
- Confirm the gameplay HUD's slightly larger text/icons still don't
  crowd the puzzle board, and that Reset/Pause/Back/Hint icons are
  comfortably legible without looking oversized again.
- Play through a few other levels (not just 3) tapping mirrors/splitters
  normally and confirm the fixed rotation mapping doesn't look wrong for
  any of them.

## Milestone 4A.3: runtime truth audit, build identity, screenshot validation

Milestone 4A.2 failed a third manual QA round reporting symptoms
(Level 3 uncompletable, UI squeezed) that no longer matched the actual
project code. See `DECISIONS.md`'s "Milestone 4A.3" section (D44-D47)
for the full audit and its conclusion (a stale APK install on the tested
device, not a code regression). **This section documents two techniques
that are now part of the standard toolkit going forward.**

### New technique: RENDERED screenshot capture (see `DECISIONS.md` D45/D47 for the AUTOMATED/RENDERED/MANUAL vocabulary this introduces)

**Why:** every prior visual-integration milestone asserted "cannot
visually verify, headless only" without ever testing whether that was
true. It wasn't - this machine has a real GPU and can render without
`--headless`.

**Script** (temporary driver scene set as `run/main_scene`, reverted
after use):
```gdscript
extends Node
func _ready() -> void:
    get_viewport().size = Vector2i(1080, 1920)
    await get_tree().process_frame
    # instantiate each real scene (main_menu.tscn, game.tscn, ...) as a
    # child, await 2 process_frame calls + RenderingServer.frame_post_draw
    # after each state change (add_child, opening a popup, a simulated
    # click), then:
    var img := get_viewport().get_texture().get_image()
    img.save_png("<scratch_dir>/<name>.png")
    # ... repeat for each screen, then get_tree().quit()
```
Run with `godot --path .` (no `--headless` flag) under a `timeout`
wrapper. **Claude must actually open the resulting PNG with its own
image-reading tool and describe what it shows before making any claim**
- saving a PNG without looking at it is not RENDERED validation, it's
just AUTOMATED validation with extra steps.

**Bonus finding:** with real rendering active, `Input.parse_input_event()`
(not `Viewport.push_input()`, which fails under `--headless` - see D40)
correctly dispatches to `Control._gui_input()`. This means a REAL
click-driven test is possible on this machine:
```gdscript
var mirror_node: Control = grid._orientable_nodes[Vector2i(2, 2)]
var center: Vector2 = mirror_node.get_global_rect().get_center()
var motion := InputEventMouseMotion.new()
motion.position = center; motion.global_position = center
Input.parse_input_event(motion)
await get_tree().process_frame
var press := InputEventMouseButton.new()
press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true
press.position = center; press.global_position = center
Input.parse_input_event(press)
await get_tree().process_frame
# ... and the matching release event
```

- **RENDERED — DONE.** Captured and inspected: Main Menu (BUILD 4A.3
  label visible), Level Select (15 cards), Level 3 initial state
  (emitter/mirrors/blocker/target all visible, beam correctly blocked
  pre-solve), Level 3 solved via a REAL simulated click sequence on both
  mirrors (Level Complete popup appeared automatically - "Moves Used: 2
  / Best Moves: 2", 3 gold stars, 3 legible buttons), Pause menu on an
  unsolved level (5 evenly-spaced labeled buttons), Settings (large
  header, legible Sound/Music toggle rows, large Back button). None
  matched the "squeezed"/"uncompletable" symptoms in the correction
  brief - see `DECISIONS.md` D46 for detail on each.
- **AUTOMATED — DONE.** One test-harness bug found and fixed during this
  process (not a game bug): the first Pause screenshot attempt actually
  captured the Level Complete popup, because `game.gd._on_pause_pressed()`
  correctly refuses to open Pause while Level Complete is showing (a
  Milestone 4A guard) - the test had tried to open Pause on an
  already-solved level. Fixed by testing Pause on the unsolved state.

### New technique: build identity audit (Phase 0, run before touching any code)

Before assuming a "the fix isn't in my build" report means the code is
wrong, check in this order:
1. `find` for other `project.godot`/`beamshift-debug.apk` files on the
   machine - confirm there's exactly one project and one APK.
2. Compare file modification timestamps (source files touched by the
   claimed fix) against the existing APK's build timestamp - the APK
   must be newer than every source edit it's supposed to contain.
3. Check `export_presets.cfg`'s `version/code`/`version/name` - if
   they've never changed across multiple "fixed" milestones, a
   same-versionCode reinstall on the test device is a real, common
   failure mode, not a theoretical one.
- **DONE.** All three checks performed for Milestone 4A.3: exactly one
  project/APK found on this machine; the pre-existing APK's timestamp
  (18:13) was after every relevant source file's Milestone 4A.2 edit
  timestamp (18:03-18:08), confirming it genuinely contained the fixes;
  `version/code`/`version/name` had never been bumped (`1`/`"1.0"` since
  the project's original template) - bumped to `5`/`"1.0.0-4A.3"` this
  pass.

### Regression (unaffected by this milestone - no simulation/UI-layout code was changed, only the build identifier and version)

- **AUTOMATED — DONE.** All 15 levels re-verified via both the standard
  `LevelSolver`-vs-declared check and the runtime-vs-solver replay
  technique (see Milestone 4A.2's section above) - all PASS, identical
  results to before this milestone.
- **AUTOMATED — DONE.** Responsive rectangle validation re-run at the 4
  resolutions explicitly required this pass (720×1280, 1080×1920,
  1080×2160, 1080×2400) for Game HUD, Pause (panel + all 5 buttons),
  Level Complete (panel + all 3 buttons + all 3 stars), and Settings
  (panel + both toggles + Back button) - all PASS at every resolution,
  zero bounds/overlap/touch-target findings.
- **AUTOMATED — DONE.** Fresh Android debug APK exported after deleting
  the previous one (per the correction brief's explicit instruction) -
  zero errors; manifest re-confirmed `versionCode='5'`,
  `versionName='1.0.0-4A.3'`, package id, SDK versions, and
  `screenOrientation=1` all correct.

**MANUAL — NOT YET DONE, and this is the only thing that can approve
this milestone:**
- Install the fresh APK (`builds/android/beamshift-debug.apk`, rebuild
  from scratch - don't reuse a cached copy) and **confirm "BUILD 4A.3" is
  visible** on the Main Menu and/or Settings screen before testing
  anything else. If it is NOT visible, the install did not actually
  update and any further testing is testing the wrong build - stop and
  fix the install first.
- Only once BUILD 4A.3 is confirmed visible: play Level 3 by hand and
  confirm it completes; review Pause/Settings/Level Complete for real
  and confirm they read comfortably on the actual device screen.

## Android device test

**Round 1 — MANUAL — DONE.** The user installed and tested the first
debug APK on a physical device. Result: **core gameplay confirmed
working** — mirror rotation, laser simulation, level progression all
correct on-device. This same test also surfaced a real UI usability
problem (not a gameplay bug): screen-edge margins too thin and buttons
too small to comfortably tap. Root cause and fix documented in
`DECISIONS.md` D10/D11 and `CHANGELOG.md`.

**Round 2 — MANUAL — DONE.** The user re-tested the rebuilt APK (with the
`UIConstants`/`SafeAreaMargin` fix) on the physical device and confirmed
gameplay working correctly, giving the explicit go-ahead to continue into
Milestone 2. The device-specific sub-items below (safe-area-widening on
an actual notch/cutout, back-button behavior, on-device performance) were
not itemized in that confirmation — treat them as still individually
open if a future session needs precise evidence for one of them
specifically, but the round as a whole is closed.

**Round 3 (Milestone 2) — MANUAL — pending.** A new debug APK was
exported after Milestone 2's changes (multi-beam simulation, 6 new tile
types, colors, 10 new levels). Nothing in Milestone 2 touched the safe-
area/touch-target UI work Round 2 validated, but the **new gameplay
mechanics themselves have never run on a device**:

1. Install the rebuilt `builds/android/beamshift-debug.apk` (`adb install
   -r builds/android/beamshift-debug.apk` to reinstall over the previous
   build).
2. Confirm Levels 6–15 are visible and playable from Level Select.
3. Tap-to-rotate a splitter on-device (touch input on this specific new
   interactive tile type has never been tested — mirrors were, in Round
   1/2, but splitters are new this milestone).
4. Visually confirm colored beams/emitters/targets render distinguishably
   on the actual device screen/panel (color rendering can look different
   than a desktop monitor).
5. Confirm the Level Complete flow, Reset, and save/progression still
   work correctly across the now-15-level list on-device.
6. Performance check with the new `_draw()`-heavy tile visuals (portal
   ring, gate bars, hazard icon) on this specific device — Milestone 2
   added several more procedurally-drawn tile types per cell.

Do not mark this round passed based on the APK re-exporting successfully
— see the note under "Android build export" below.

## Milestone 4A.5: portrait UI replacement + responsive HUD

Five new portrait UI assets integrated (Pause, Level Complete, top/bottom
gameplay HUD - Settings deliberately excluded, see `DECISIONS.md` D48).
Reused the exact RENDERED-screenshot and real-click-driven techniques
from Milestone 4A.3 (D45/D47) - see that section above for the driver
script shape.

- **AUTOMATED — DONE.** `--headless --import` clean after every scene/
  script change. All 15 levels' solver solutions replayed through a real
  `GridManager` - all PASS (`is_solved == true`, solver-vs-declared
  `optimal_moves` match, zero `LevelValidator` errors) - confirms zero
  gameplay regression from this UI-only pass. Level 3 Reset and
  replay-after-Reset both PASS.
- **DESKTOP RENDERED — DONE.** Captured and personally inspected: Main
  Menu (unaffected, "UI 4A.4" label visible bottom-right), Level Select
  (unaffected), Settings (confirmed still correctly reads "SETTINGS" -
  proves the old-art-retention decision didn't silently break anything),
  Gameplay/Level 3 initial state (new HUD bars render correctly, no
  distortion, Back/Level/Moves all legible, decorative background
  confirmed `mouse_filter=IGNORE` in the live scene), Pause (opened via a
  real `PauseButton.pressed` signal mid-level - "PAUSE" header, 5 buttons,
  no clipping, no duplicate title), Level Complete (reached via a REAL
  two-click simulated solve of Level 3 through `_gui_input()` - stars/
  moves/buttons all render correctly inside the new portrait frame, no
  clipping). Grid available area measured at ≈45.8% of the 1080x1920
  screen vs. ≈16.3% per HUD bar (≈32.6% combined) - grid remains the
  single largest region. The real click-through still reached
  `moves_used=2`, `is_solved=true`, `complete_popup_visible=true`,
  confirming the new decorative HUD layers don't block real input.
- **ANDROID EXPORTED — DONE.** Fresh APK (old one deleted first),
  `versionCode=7`/`versionName="1.0.0-UI4A4"` confirmed via
  `aapt2 dump badging` on the built APK itself. Size ≈113.1 MB.
- **ANDROID MANUAL QA PENDING.** Nobody has reviewed this build on a real
  device. Needed:
  1. Confirm "UI 4A.4" is visible on Main Menu/Settings (proves the
     install is this build).
  2. Settings screen - confirm it still reads correctly (it's
     intentionally unchanged this pass, but worth a real-device glance
     since everything else changed around it).
  3. Pause menu - open via the HUD Pause button and via Android back
     during gameplay; confirm all 5 actions, readability, and no
     overlap/clipping against the new frame's border on a real screen.
  4. Level Complete - solve any level and confirm stars/moves/buttons
     read comfortably inside the new portrait frame.
  5. Gameplay HUD - confirm the top/bottom bars don't feel oversized or
     crowd the puzzle board on the actual device, and that Back/Reset/
     Pause remain easy, accurate touch targets (not just visually
     present).
  6. Confirm the puzzle grid still feels like the dominant part of the
     screen, not squeezed by the two new HUD bars.
  7. Play a few different levels (not just Level 3) to confirm the new
     HUD reads fine with varying level-name lengths (long names may wrap
     to 2-3 lines in the narrow left slot - check this doesn't look
     broken).

## Milestone 4A.6: corrected Settings panel + final UI QA

Small follow-up: the user supplied a corrected `bs_panel_settings_
portrait.png` (the Milestone 4A.5 original was a mislabeled byte-
duplicate of the Level Complete art - D48). Verified via MD5 (now
differs) and visual inspection (gear icon, "SETTINGS" title) before
integrating, then wired in exactly like Pause/Level Complete. Reused the
same RENDERED/click-driven techniques as every prior UI pass.

- **AUTOMATED — DONE.** `--headless --import` clean. All 15 levels'
  solver-vs-runtime-replay regression PASS (unchanged - confirms zero
  gameplay impact from a Settings-only asset swap). Level 3 Reset/
  replay-after-Reset PASS.
- **DESKTOP RENDERED — DONE.** All 6 screens captured and personally
  inspected. Settings now shows the corrected gear icon + "SETTINGS"
  title, properly sized (no longer tiny-panel-in-empty-screen), Sound/
  Music/Back all legible and well-spaced, no clipping, no duplicate
  title. Pause and Level Complete reconfirmed unaffected. A real
  two-click simulated solve of Level 3 through the actual `_gui_input()`
  path still reached `is_solved=true`/`complete_popup_visible=true`.
- **ANDROID EXPORTED — DONE.** Fresh APK, `versionCode=8`/
  `versionName="1.0.0-UIFINAL"` confirmed via `aapt2 dump badging` on the
  built APK. Size ≈113.2 MB.
- **ANDROID MANUAL QA PENDING.** This is now the single remaining gate.
  Checklist for the user:
  1. Confirm "UI FINAL QA" is visible on Main Menu/Settings.
  2. Open Settings - confirm the gear icon, "SETTINGS" title, and
     Sound/Music/Back all read comfortably on the real screen, panel
     doesn't feel tiny or oversized.
  3. Open Pause and Level Complete (solve any level) - confirm both
     still read correctly (unaffected by this pass, but worth a
     real-device glance).
  4. Confirm the gameplay HUD (top/bottom bars) still feels reasonably
     sized and the puzzle grid feels like the dominant part of the
     screen.
  5. General click-through: mirrors/splitters rotate correctly, Reset/
     Pause/Back all work, Level Select and popup buttons all work.

## Android HUD Alignment + Missing Tile Fix

Root cause of "Level 3 tiles invisible on Android, laser still visible"
was found and fixed **without physical Android hardware**, using a new
technique this milestone introduces: actually running the real exported
package, not source. Every prior RENDERED validation in this project ran
via `godot --path .`, which reads source files directly and completely
bypasses `export_presets.cfg`'s `exclude_filter` - structurally unable to
catch an export-filter-exclusion bug no matter how thorough. See
`DECISIONS.md` D51 for the full trace.

### New technique: exported-package verification (no device needed)

```bash
# 1. Export a real .pck using the actual export preset/filter:
godot --headless --path . --export-pack "Android Debug" out.pck

# 2. Run headless against ONLY that package (no source project):
godot --headless --main-pack out.pck --script check.gd
```
Inside `check.gd` (`extends SceneTree`), use `ResourceLoader.exists(path)`
to directly test whether a specific resource survived the export filter,
and/or actually `load()`/instantiate the scene in question (e.g. a real
`GridManager.load_level()` call, using the same frame-delay pattern as
the runtime-vs-solver technique above - `_process()` with a frame
counter, not a same-frame call in `_init()`) to observe real runtime
behavior against the exact file set Android would see. This is fully
automatable and should be run any time a change touches which files are
excluded, or which scripts/scenes reference files under a partially-
excluded folder (see `export_presets.cfg`'s `exclude_filter` -
`tools/**`, `scripts/tools/**`, `levels/editor_fixtures/**`,
`assets/gameplay/pieces/**`, `assets/gameplay/tiles/**`,
`assets/branding/app_icon/**`).

- **AUTOMATED — DONE (root cause).** `ResourceLoader.exists(
  "res://assets/gameplay/pieces/bs_tile_blocker.png")` returned `false`
  against the real exported package; loading `blocker.gd` against that
  package printed a script parse error; instantiating a real
  `GridManager` and calling `load_level()` with Level 3's data against
  that package showed only 2 of 5 tiles were actually created (the loop
  silently stopped at the broken blocker tile).
- **AUTOMATED — DONE (fix verification).** Re-exported the package after
  moving the art to its canonical folder and repointing the scripts; the
  same `ResourceLoader.exists()` check now returns `true`, `blocker.gd`
  loads without error, and `GridManager.load_level()` against the
  rebuilt package now creates all 5 of Level 3's tiles correctly (proper
  scripts, sizes, positions).
- **AUTOMATED — DONE (shipped-APK confirmation).** Unzipped the actual
  built `beamshift-debug.apk` directly (`unzip -d . beamshift-debug.apk`)
  and confirmed `assets/gameplay/blocker/`/`hazard/` are present in it
  and `assets/gameplay/pieces/` is completely absent, with both
  `blocker.gd`/`hazard.gd` present as compiled `.gdc` files - this is
  the actual shipped artifact, not a proxy for it.
- **AUTOMATED — DONE (regression).** All 15 levels' solver-vs-runtime-
  replay regression PASS (unchanged - confirms zero gameplay-logic
  impact). Level 3 Reset/replay-after-Reset PASS.
- **DESKTOP RENDERED — DONE.** Screenshots captured for Levels 1, 2, 3,
  4, 5, and 12 (the last two specifically re-confirming the fix across
  every level with a blocker/hazard, not just Level 3) - all tiles render
  correctly, HUD text reads as clean two-line "LEVEL N / Name" blocks,
  Moves/Back/Reset/Pause all correctly positioned and balanced. **Note:**
  since this runs from source, it could never have caught the original
  bug in the first place - it validates layout/appearance only, not
  export-filter correctness. Use the exported-package technique above for
  that.
- **ANDROID EXPORTED — DONE.** Fresh APK, `versionCode=9`/
  `versionName="1.0.0-TILEFIX"` confirmed via `aapt2 dump badging`.
- **ANDROID MANUAL QA PENDING.** Checklist for the user:
  1. Confirm "ANDROID TILE FIX" is visible on Main Menu/Settings.
  2. Open Level 3 and confirm all 5 tiles (emitter, 2 mirrors, blocker,
     target) are visible, not just the laser beam.
  3. Also check Levels 5, 12, and 15 (blocker/hazard tiles) for the same.
  4. Confirm the top HUD reads "LEVEL N" / level name on two clean
     lines, centered, not 3-line wrapped or overlapping the frame.
  5. Confirm Moves (top-right) looks balanced against the level name
     (top-left), and Reset/Pause icons (bottom) sit centered in their
     slots, not crowded against the center reactor or each other.
  6. General click-through: mirrors/splitters, Reset, Pause, Back all
     work as expected.

## Final HUD Alignment + Level Complete Delay

Small polish pass: bottom HUD button vertical alignment, and a short
delay between solve detection and the Level Complete popup appearing.
No puzzle logic, level data, scoring, or assets touched.

### Bottom HUD re-measurement

Reused the pixel-sampling approach from `DECISIONS.md` D49/D52, but as a
**flood-fill connected-component scan** (seeded from a known point inside
each slot, expanding through matching "flat slot interior" pixels) rather
than a single horizontal-line scan - this measures each slot's true 2D
bounding box (both X and Y), not just its horizontal extent at one row.

- **AUTOMATED — DONE.** Flood-fill on `bs_hud_bottom_portrait.png`
  found: Reset slot bbox center at fraction `(0.2940, 0.5175)`, Pause
  slot bbox center at `(0.7045, 0.5161)` (image-space fractions). The
  previous horizontal anchors (`0.294`/`0.7045`) matched to within
  0.0002 - already correct. The vertical anchors (previously `0.5`, the
  bar's exact center) were off by the difference shown above - corrected
  in `game.tscn`.
- **AUTOMATED — DONE.** A real (non-headless) driver read
  `%ResetButton`/`%PauseButton`'s actual `Rect2` relative to `BottomBar`
  at runtime after the fix: Reset center `(261.07, 161.88)` in a
  `888x312.82` bar (bar center `(444, 156.41)`) - offset ≈6px down, ≈183px
  left of center; Pause center `(625.60, 161.45)` - offset ≈5px down,
  ≈182px right of center. Left/right offsets from bar-center are
  symmetric within 2px.
- **DESKTOP RENDERED — DONE.** Screenshot captured and inspected - both
  icons visually centered in their slots, no overlap with the center
  reactor or adjacent slots.

### Level Complete delay

- **AUTOMATED — DONE.** 15/15 `LevelSolver` PASS, 15/15 runtime-replay
  PASS, unchanged (the regression script asserts on `GridManager
  .is_solved` directly, never on the popup, so this UI-only change has
  no effect on it).
- **DESKTOP RENDERED / real-timing — DONE.** A real (non-headless) driver
  using `Input.parse_input_event()` (the actual `_gui_input` path):
  - Solved Levels 1, 3, 5, 12, and 15 via each level's actual solver
    solution. In every case, `is_solved` became `true` immediately but
    the popup stayed hidden; polling at 0.15s granularity, the popup
    became visible at ≈0.75-0.90s in every case (0.8s target).
  - Attempted a mirror click during the delay window (Levels 1 and 3):
    `tile_orientations` was confirmed byte-for-byte unchanged afterward -
    the pre-existing `GridManager._on_orientable_tile_clicked()` guard
    (`if is_solved: return`) rejected it, no new code needed.
  - Retry after the popup: `moves_used=0`, `is_solved=false`,
    `_completion_pending=false`, popup hidden - clean restart.
  - Next Level (Level 1 → 2): `current_level_id` advanced correctly, new
    board loaded unsolved, popup hidden.
  - Reset before solving (mid-puzzle): worked exactly as before, no
    delay-related regression.
- **ANDROID EXPORTED — DONE.** Fresh APK, `versionCode=10`/
  `versionName="1.0.0-HUDDELAY"` confirmed via `aapt2 dump badging`.
- **ANDROID MANUAL QA PENDING.** Checklist for the user (superseded by
  `versionCode=11`/`"1.0.0-OPTIMIZED"` below - the QA label this
  checklist references was removed in that build):
  1. Confirm Reset/Pause icons look precisely centered in their bottom
     HUD slots (this was previously "slightly off").
  2. Solve any level and confirm the Level Complete popup does **not**
     appear instantly - there should be a short, clearly perceptible
     pause (~0.8s) showing the final beam/solved board first.
  3. During that pause, try tapping another mirror - confirm nothing
     happens (no move counted, no orientation change).
  4. Confirm Retry, Next Level, and Reset all still work normally.

## APK Optimization + Asset Cleanup (versionCode 11, "1.0.0-OPTIMIZED")

See `DECISIONS.md` D53 for the full root-cause/technique writeup. Summary
of what was validated and how:

### New technique gotcha: run exported-package checks from a directory with NO `project.godot` anywhere in its parent chain

D51 first introduced `godot --headless --main-pack out.pck --script
check.gd`. This pass found a real trap in it: running that command
**from inside the project directory** (any subdirectory of it counts -
Godot walks up looking for `project.godot`) makes `ResourceLoader.exists()`
silently blend the pck's contents with the live local filesystem - a
path that's genuinely excluded from the pck can still report `true`.
**Fix:** copy the `.pck` and the check script into a scratch directory
with no `project.godot` anywhere above it, and run from there
(`Start-Process ... -WorkingDirectory <scratch dir>` on Windows). Only
then does `ResourceLoader.exists()` reflect the real, isolated exported
file set. Re-confirmed three times this pass (Pass A's exclusions, Pass
C's derived-texture swap, and the final `versionCode=11` build) - every
one correctly showed the intended masters/derived files present and
excluded files genuinely absent only once run from a clean directory.

### Baseline audit

- `versionCode=10` APK: **113,129,693 bytes (113.1 MB)** on disk,
  confirmed via `stat`, matching `CURRENT_STATUS.md`'s prior estimate.
- `assets/` on disk: 83 PNGs, 149.5 MB total (masters + duplicates +
  already-excluded art all included in that figure).
- Reference map (`grep` every `.tscn`/`.gd`/`.tres`/`project.godot` for
  `res://assets/...`, diffed against every PNG on disk): **exactly 34
  referenced, 49 unreferenced** - and all 49 already matched
  `export_presets.cfg`'s `exclude_filter` patterns from prior sessions.
- MD5 duplicate scan across all 83 PNGs found only the 3 already-known
  pairs (blocker/hazard master-vs-`pieces/` copies from D51, and a
  newly-noticed byte-identical `bs_panel_pause_portrait.png` ==
  `bs_ui_pause_panel.png` - the *new* Milestone 4A.5 pause art is
  pixel-identical to the *old*, superseded pause art. Unlike D48's
  settings mislabel, this one is plausibly intentional coincidence (the
  Pause screen may simply not have changed design) rather than a
  mislabeled duplicate - flagged here for a future session to ask the
  user about if it ever matters, not acted on).

### PASS A — re-export with the existing (already-correct) exclude filter

- **AUTOMATED — DONE.** `--headless --path . --import`: zero errors.
  Fresh `--export-debug`: 73,563,313 bytes (down from 113,129,693 -
  39,566,380 bytes / 35% saved from zero content changes). Verified via
  a real exported `.pck` (run from a clean directory, see above): all 34
  referenced assets `ResourceLoader.exists() == true`; all 49 excluded
  assets `== false`; a real `GridManager.load_level()` call for Levels
  3/5/12/15 against that package correctly instantiated `Blocker`
  (L3/L5), `Hazard` (L12), and `Switch`/`Gate`/`Portal` (L15) tile nodes.
  15/15 `LevelSolver` PASS, 15/15 runtime-replay PASS (unaffected - no
  source/logic touched).

### PASS C — derived (resized) runtime textures for the 21 most oversized assets

- **AUTOMATED — DONE.** 21 new `<name>_runtime.png` files created
  (`System.Drawing`, `HighQualityBicubic`, straight alpha preserved) at
  2-4x real on-screen display size; every `preload()`/`ext_resource`
  reference in `scripts/gameplay/{blocker,gate,grid_manager,hazard,
  mirror,tile_visual,target}.gd`, `scripts/ui/{settings_menu,
  level_complete_popup,level_button}.gd`, and `scenes/{gameplay/game,
  ui/level_button,ui/level_complete_popup,ui/settings_menu}.tscn`
  repointed to the derived file; the 21 original masters added to
  `export_presets.cfg`'s `exclude_filter` (kept on disk, per the D31
  pattern). `--import`: zero errors. Fresh `--export-debug`: 50,974,209
  bytes (down a further 22,589,104 bytes / 30.7% from Pass A - 55.0%
  below the original `versionCode=10` baseline). Same exported-package
  verification as Pass A, repeated for all 21 derived files (present)
  and all 21 masters (correctly absent). 15/15 `LevelSolver` PASS, 15/15
  runtime-replay PASS.

### RENDERED visual comparison (see `DECISIONS.md` D45/D47 vocabulary)

Non-headless (`godot --path .`, real D3D12/RTX 4080-class GPU) capture
of all 6 key screens after Pass C, via the documented temporary-
main-scene-swap + `get_viewport().get_texture().get_image().save_png()`
technique, **each PNG actually opened and inspected**:

- **Main Menu:** logo, background, all 4 buttons (Play/Continue/
  Settings/Quit) crisp, no blur, no color shift.
- **Level Select:** all 15 level cards (now using the 512x540 derived
  card art) sharp at their actual ~240x253 display size, lock icons
  crisp, no banding/pixelation.
- **Gameplay, Level 3** (the D51-critical level - has a `Blocker` tile):
  mirror, blocker, target all render crisp at cell size; beam correctly
  bends through the mirror and is stopped/routed around the blocker;
  HUD bars, Reset/Pause icons (now 256px derived, was 1254px) all sharp.
- **Settings:** gear icon, title, both toggle switches (now 640x320
  derived, was 1774x887) render with clean "ON" text and intact neon
  glow, no artifacts.
- **Pause** (first capture attempt was actually a duplicate of the
  Settings screen due to a driver-script bug - stale scene not cleared
  before adding Pause; fixed and recaptured): Resume/Restart/Settings/
  Level Select/Main Menu all render correctly with the pause panel art.
- **Level Complete:** 3 earned stars (now 128x128 derived, was
  1254x1254 - the single most extreme oversample found, ~2300x more
  source pixels than ever displayed) render as clean, sharp gold stars
  with no visible quality loss at their actual 26x26 display size.

No blur, no ugly alpha edges, no blocky gradients, no destroyed neon
glow, no color shift, no texture stretching, and no missing artwork on
any of the 6 screens.

### Final build

- **ANDROID EXPORTED — DONE.** `versionCode=11`, `versionName=
  "1.0.0-OPTIMIZED"`, `package=com.beamshift.game`, confirmed via
  `aapt2 dump badging` (also reconfirmed `minSdkVersion=24`,
  `targetSdkVersion=36` unchanged). Final size: **50,974,209 bytes
  (48.6 MB)** - 62,155,484 bytes (59.3 MB, 55.0%) below the
  `versionCode=10` baseline. Temporary `BuildLabel` QA marker ("HUD +
  DELAY FIX") removed from `main_menu.tscn`/`settings_menu.tscn`.
- **ANDROID MANUAL QA PENDING** - this is the next required step. See
  `CURRENT_STATUS.md` for the exact checklist. Nothing about this pass
  may be marked "Android verified" until the user installs this exact
  build and confirms it, same standing rule as every prior build.

## Production Campaign Phase 1 (versionCode 12, "1.1.0-STAGE1")

See `DECISIONS.md` D54 and `CAMPAIGN_DESIGN.md` for the full
architecture/design writeup. This section covers validation only.

### Solver + validator, all 10 Stage 1 levels

**AUTOMATED - DONE.** `LevelValidator.validate()` and
`LevelSolver.analyze()` run against every level under
`levels/campaign/stage_01/` via a temporary headless script
(`extends SceneTree`, `--headless --path . --script <path>.gd`, this
project's standard throwaway-harness convention). Result for all 10:
zero validator errors, zero validator warnings, `status == "SOLVABLE"`,
`trivial == false`, and the solver's `optimal_moves` matching the
level's declared value exactly (declared values were themselves set
FROM this same solver run, per `CAMPAIGN_DESIGN.md` section 7's
workflow - never hand-guessed). Full per-level results (moves, shortest-
solution count, states explored, decoys found) are in
`CAMPAIGN_DESIGN.md` section 11's design table - not duplicated here.

### Solver-vs-runtime-replay regression, dev + campaign combined

**AUTOMATED - DONE.** The standard runtime-vs-solver technique (see
"Milestone 4A.2" section above for the original writeup) extended to
cover both level populations in one script: for each of the 15 dev
levels AND all 10 campaign levels, the solver's own solution was
replayed through a real, instantiated `GridManager` via
`_on_orientable_tile_clicked()`. Result: **15/15 dev PASS, 10/10
campaign PASS** (`is_solved == true` for every one). Confirms the
campaign levels' solved states are reachable through the actual player
input path, not just `LaserSystem` in isolation.

### Real-runtime integration test (real autoloads, not just the solver)

**AUTOMATED - DONE.** A temporary `Node` driver script, run via this
project's standard temporary `run/main_scene` swap (real autoloads
needed - `GameManager`/`SaveManager`/`LevelManager`, unlike the
solver-only script above), performed, in order:

1. Instantiated `main_menu.tscn` on a completely fresh (no prior)
   save file - confirmed the Continue button's `disabled` property was
   `true` (no campaign progress yet).
2. Instantiated `level_select.tscn` - confirmed exactly 10 buttons in
   `%LevelGrid`, `level_id` 1 through `disabled == false` and levels
   2-10 all `disabled == true`.
3. Set `GameManager.current_level_id = 1` and
   `GameManager.is_editor_playtest = false`, instantiated `game.tscn`,
   confirmed it loaded Campaign Level 1 ("Ignition") via
   `LevelManager.get_campaign_level(1)`.
4. Replayed the solver's own solution through the real `%PuzzleGrid`
   node's `_on_orientable_tile_clicked()` - confirmed `is_solved ==
   true`.
5. Waited past the real `LEVEL_COMPLETE_DELAY` (0.8s;  the driver
   waited 1.2s to be comfortably clear of it) rather than skipping the
   delay, so `_on_level_solved()`'s actual `await` path executed for
   real - confirmed the Level Complete popup's `visible == true`.
6. Inspected `SaveManager` directly afterward: `campaign_completed_levels
   == {"1": true}`, `campaign_highest_unlocked_level == 2`,
   `campaign_best_stars_per_level == {"1": 3}` (3 stars - Level 1's
   1-move optimal, solved in 1 move), `campaign_best_moves_per_level ==
   {"1": 1}`. **Also confirmed the dev-level fields were completely
   untouched**: `highest_unlocked_level` still `1`, `completed_levels`
   still `{}` - proving the two save populations never cross-
   contaminate.
7. Emitted the Level Complete popup's `next_level_pressed` signal
   directly (the same signal its own button emits) - confirmed
   `GameManager.current_level_id` advanced to `2`.

Every one of the 7 checks above matched its expected value exactly on
the first run. Project.godot's `run/main_scene` was reverted immediately
after (confirmed via a follow-up `grep`, per this project's standard
practice) and the temporary driver script/scene deleted. The runtime
test's own `SaveManager.save_game()` call wrote a real
`user://savegame.json` file to this dev machine - **deleted afterward**
so the user's own first manual test starts from a genuinely fresh save,
not one that already shows Level 1 complete.

### Exported-package validation

**AUTOMATED - DONE.** Using the established D51/D53 technique (export a
real `.pck`, run a check script against it from a directory with **no
`project.godot` anywhere in its parent chain** - see this file's "APK
Optimization + Asset Cleanup" section above for why that specific
detail matters): confirmed all 10
`res://levels/campaign/stage_01/level_0N.gd` files and both spot-checked
dev levels (`level_01.gd`, `level_15.gd`) resolve via
`ResourceLoader.exists()`, confirmed `editor_fixtures`/
`tools/level_editor` remain correctly excluded, and actually `load()`ed
Campaign Level 10 against the real package to confirm its full data
(10 tiles, `optimal_moves == 4`, `is_campaign_level == true`, `stage ==
"First Light"`) survived the export intact.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=12`, `versionName=
"1.1.0-STAGE1"`, `package=com.beamshift.game` (unchanged), confirmed via
`aapt2 dump badging` (`minSdkVersion=24`, `targetSdkVersion=36`
unchanged). Final size: **50,992,443 bytes (50.99 MB)** - up only
18,234 bytes (~17.8 KB) from the prior `versionCode=11` build, exactly
as expected for adding 10 small `.gd` data files with zero new assets.

### Manual test checklist (Stage 1 approval - nobody but the user can close this out)

**ANDROID MANUAL QA PENDING.** Install `versionCode=12`
(`"1.1.0-STAGE1"`) and:

1. Confirm Level Select shows exactly 10 levels, only Level 1 unlocked.
2. Play Campaign Levels 1-10 **in order, for real** (not via any dev
   tool). For each, check against `CAMPAIGN_DESIGN.md` section 11's
   design table:
   - Does the level actually teach what it's meant to teach?
   - Does the stated decoy (Levels 7, 9, 10) look plausible rather than
     randomly placed?
   - Does solving it award 3 stars at the solver-confirmed optimal move
     count, and correctly unlock the next level?
3. Confirm the overall feel across Levels 1-10 is Tutorial → Easy, per
   `CAMPAIGN_DESIGN.md` section 3 - **not** the raw `HARD`/`EXPERT`
   `LevelMetrics` labels (see that document's section 9 for why those
   are misleading for this stage specifically).
4. Confirm Main Menu's Continue button correctly resumes at the first
   incomplete campaign level after playing at least one level.
5. Confirm the old 15 dev/regression levels are not reachable from any
   player-facing menu.
6. General sanity: Reset/Pause/Back/Settings/Retry/Next Level/Level
   Select all still work exactly as before (unaffected by this pass).

Nothing about this pass may be marked "Android verified" until the user
installs this exact build and confirms it, same standing rule as every
prior build.

**UPDATE: Stage 1 was subsequently played and MANUALLY APPROVED** by the
user ("the starting levels are good") — see the "Production Campaign
Phase 2" section below for what came next.

## Production Campaign Phase 2 (versionCode 13, "1.2.0-STAGE2")

See `DECISIONS.md` D55 and `CAMPAIGN_DESIGN.md` section 11b for the full
architecture/design writeup. This section covers validation only.

### Solver + validator, all 10 Stage 2 levels

**AUTOMATED - DONE.** `LevelValidator.validate()` and
`LevelSolver.analyze()` run against every level under
`levels/campaign/stage_02/` via the same temporary headless-script
convention as Stage 1. Result for all 10: zero validator errors, zero
validator warnings, `status == "SOLVABLE"`, `trivial == false`, and the
solver's `optimal_moves` matching the level's declared value exactly.
Full per-level results (moves, shortest-solution count, states explored,
decoys) are in `CAMPAIGN_DESIGN.md` section 11b - not duplicated here.

**Two real level-design mistakes were caught and fixed before this
solver run, not by it** - see `DECISIONS.md` D55 for the full trace: an
early Level 11 draft's target was unreachable by its own designed mirror
chain (caught by re-deriving the path cell-by-cell against
`GridTypes.reflect()`'s table before finalizing the file), and an early
Level 12 draft placed a blocker on a cell no beam configuration could
ever reach (caught the same way). Both fixed before the solver was ever
run against them - the solver would not have flagged either as
structurally invalid, only as "not the intended puzzle."

### Solver-vs-runtime-replay regression, dev + Stage 1 + Stage 2 combined

**AUTOMATED - DONE.** The standard technique, extended to cover all
three populations in one script: 15/15 dev levels, 10/10 Stage 1 levels,
and 10/10 Stage 2 levels each had the solver's own solution replayed
through a real, instantiated `GridManager` via
`_on_orientable_tile_clicked()`. Result: **15/15 dev PASS, 10/10 Stage 1
PASS, 10/10 Stage 2 PASS - 20/20 total campaign.** Re-confirms Stage 1
didn't regress while adding Stage 2 (the whole point of always
re-running the earlier populations' regression alongside a new stage's
own, per `CAMPAIGN_DESIGN.md` section 13, step 6).

### Real-runtime integration test (real autoloads, all 20 campaign levels)

**AUTOMATED - DONE.** A temporary `Node` driver, run via the standard
temporary `run/main_scene` swap (real autoloads needed), performed:

1. Instantiated `level_select.tscn` on a fresh save - confirmed exactly
   20 buttons in `%LevelGrid`, only Level 1 unlocked.
2. Played Campaign Levels 1 through 10 in order via the real
   `%PuzzleGrid._on_orientable_tile_clicked()` path (the solver's own
   solution replayed through each), each solve's real
   `LEVEL_COMPLETE_DELAY` (0.8s) allowed to elapse for real so
   `SaveManager` actually wrote the result, exactly as a real player's
   solve would.
3. Specifically confirmed completing Level 10 unlocked Level 11 -
   `SaveManager.campaign_highest_unlocked_level == 11` and
   `is_campaign_level_unlocked(11) == true` - the Stage1→Stage2 boundary.
4. Played Campaign Level 11 (the first Stage 2 level) through the same
   real path, confirming the stage transition itself works, not just the
   unlock flag.
5. Played Campaign Levels 12 through 19 the same way, reaching Level 20.
6. Played Campaign Level 20 (the finale) and specifically checked the
   Level Complete popup's `%NextLevelButton.visible` - confirmed
   `false`, since no Level 21 exists. Also confirmed
   `campaign_highest_unlocked_level` stayed at `20` (didn't try to
   "unlock" a nonexistent 21) and
   `LevelManager.get_campaign_continue_level_id()` correctly returned
   `20` (everything unlocked is completed). This specifically answers
   the brief's "Next Level must not crash or incorrectly attempt to load
   nonexistent Level 21" requirement - confirmed via the actual generic
   `has_next = current_level_id < LevelManager.get_campaign_level_count()`
   check already in `game.gd`, with zero new special-case code written.

Every check matched its expected value exactly on the first run.
`project.godot`'s `run/main_scene` was reverted immediately after
(confirmed via a follow-up `grep`) and the temporary driver deleted. The
runtime test's own `SaveManager.save_game()` calls wrote a real
`user://savegame.json` to this dev machine - **deleted afterward** so
the user's own manual test starts from a genuinely fresh save.

### Exported-package validation

**AUTOMATED - DONE.** Using the established D51/D53/D54 technique
(export a real `.pck`, run a check script against it from a directory
with no `project.godot` anywhere in its parent chain): confirmed all 20
`res://levels/campaign/stage_0{1,2}/level_*.gd` files and two
spot-checked dev levels (`level_01.gd`, `level_15.gd`) resolve via
`ResourceLoader.exists()`, and actually `load()`ed Campaign Level 20
against the real package to confirm its full data (12 tiles,
`optimal_moves == 5`, `is_campaign_level == true`, `stage ==
"Reflection"`) survived the export intact.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=13`, `versionName=
"1.2.0-STAGE2"`, `package=com.beamshift.game` (unchanged), confirmed via
`aapt2 dump badging` (`minSdkVersion=24`, `targetSdkVersion=36`
unchanged). Final size: **51,010,677 bytes (51.01 MB)** - up only 18,234
bytes (~18.2 KB) from the Stage 1 build, exactly as expected for adding
10 small `.gd` data files with zero new assets.

### Manual test checklist (Stage 2 approval - nobody but the user can close this out)

**ANDROID MANUAL QA PENDING.** Install `versionCode=13`
(`"1.2.0-STAGE2"`) and:

1. Confirm Level Select now shows exactly 20 levels, with Stage 1's
   completion/star state preserved from the earlier approved playthrough
   and only Level 11 newly unlocked (assuming Level 10 was completed).
2. Play Campaign Levels 11-20 **in order, for real**. For each, check
   against `CAMPAIGN_DESIGN.md` section 11b's design table:
   - Does the level teach what it's meant to?
   - **Levels 14, 17, 20 (backward reasoning):** does tracing backward
     from the target's fixed mirror actually feel like the intended
     approach, not just something the solver happens to confirm?
   - **Levels 13, 15, 19, 20 (decoys):** do they read as plausible?
   - **Levels 12, 17, 20 (blocker-guarded forks):** does the wrong
     choice's punishment feel like a fair consequence?
   - Does solving award 3 stars at the solver-confirmed optimal move
     count and correctly unlock the next level?
3. Confirm the stage overall feels **noticeably trickier than Stage 1**
   without feeling padded or unfair - this is the specific outcome the
   user's Stage 2 brief asked for.
4. Confirm Level 20 feels like a genuine finale/checkpoint - harder than
   Stage 1's own Level 10 - and that completing it doesn't crash, hang,
   or attempt to load a nonexistent Level 21 (the mechanism is already
   AUTOMATED/REAL-RUNTIME confirmed; this step confirms it also *reads*
   correctly to a real player - no dangling "Next Level" button, no
   confusing dead end).
5. Confirm Main Menu's Continue button correctly resumes at the first
   incomplete campaign level after playing at least one Stage 2 level.
6. General sanity: Reset/Pause/Back/Settings/Retry/Next Level/Level
   Select all still work exactly as before (unaffected by this pass).

Nothing about this pass may be marked "Android verified" until the user
installs this exact build and confirms it, same standing rule as every
prior build. Stage 1's own manual approval stands on its own and does
not need re-confirming.

## Production Campaign Phase 3 (versionCode 14, "1.3.0-STAGE3")

See `DECISIONS.md` D56 and `CAMPAIGN_DESIGN.md` section 11c for the full
architecture/design writeup. This section covers validation only.

### Splitter and multi-target behavior verification (before any level was designed)

**AUTOMATED - DONE.** Per the brief's explicit "do not assume splitter
behavior" instruction, `scripts/gameplay/laser_system.gd` and
`scripts/gameplay/grid_manager.gd` were read directly before any Stage 3
level was authored. Confirmed: a splitter always sends the beam straight
through unconditionally (direction unchanged regardless of orientation)
and pushes one additional branch beam reflected via the identical
`GridTypes.reflect()` table mirrors use; splitter orientation is stored
in the same `tile_orientations` dictionary as mirrors; rotating a
splitter goes through the exact same `GridManager._on_orientable_tile_
clicked()` handler as a mirror and counts as a move identically; the
shared `visited_states` loop guard covers every splitter branch, so a
splitter can never hang the simulation; `LevelSolver` treats a rotatable
splitter as one bit in its search bitmask exactly like a mirror, with no
splitter-specific solver code; `LevelValidator` has no splitter-specific
check. Multi-target completion was verified from `LaserSystem.simulate()`'s
own `solved` formula (`required_count > 0 and required_activated >=
required_count and not hazard_hit`, recomputed fresh every pass): all
required targets must be simultaneously active in one simulated state,
a partial activation never triggers `is_solved`, orientation changes
correctly reset activation state every pass, and one beam (including a
splitter's branch) can legitimately activate multiple targets in a
single pass. All of this matched `DECISIONS.md` D15's existing prose
exactly - confirmed from source, not assumed from the doc.

### Solver + validator, all 10 Stage 3 levels

**AUTOMATED - DONE.** `LevelValidator.validate()` and
`LevelSolver.analyze()` run against every level under
`levels/campaign/stage_03/` via the same temporary headless-script
convention as Stages 1-2. Result for all 10: zero validator errors, zero
validator warnings, `status == "SOLVABLE"`, `trivial == false`, and the
solver's `optimal_moves` matching the level's declared value exactly.
Full per-level results (moves, shortest-solution count, states explored,
decoys) are in `CAMPAIGN_DESIGN.md` section 11c - not duplicated here.

**One real level-authoring mistake was caught by this solver run, not
by hand-tracing** - see `DECISIONS.md` D56 for the full account: Level
30's first draft authored one mirror already in its solved orientation
instead of the deliberately-wrong starting state every other rotatable
piece uses, so the solver found a 5-move solution skipping it entirely -
one short of the intended 6-move finale. The mismatch was found by
comparing the solver's `optimal_moves` (5) against the level's declared
value (6), then reading `solution_path` to see which piece it never
named. Fixed by correcting the authored orientation; re-run confirmed
`optimal_moves == 6`.

### Solver-vs-runtime-replay regression, dev + all 3 campaign stages

**AUTOMATED - DONE.** The standard technique, extended to cover all four
populations in one script (grid instantiated once per level via
`GRID_SCENE.instantiate()` + a manual `_ready()` call, since a plain
`--script` `SceneTree` has no automatic node-tree entry to trigger it):
15/15 dev levels, 10/10 Stage 1, 10/10 Stage 2, and 10/10 Stage 3 levels
each had the solver's own solution replayed through a real, instantiated
`GridManager` via `_on_orientable_tile_clicked()`. Result: **DEV 15/15
PASS, STAGE1 10/10 PASS, STAGE2 10/10 PASS, STAGE3 10/10 PASS - 30/30
total campaign, 45/45 grand total.** Re-confirms Stages 1-2 didn't
regress while adding Stage 3.

### Real-runtime integration check (real autoloads, read-only)

**AUTOMATED - DONE.** A temporary `Node` driver, run via the standard
temporary `run/main_scene` swap (real autoloads needed), confirmed:
`LevelManager.get_campaign_level_count() == 30`; `get_campaign_level(20)`
and `get_campaign_level(21)` both load correctly with their expected
`stage` metadata (`"Reflection"` and `"Split"` respectively - confirming
Stage 2 untouched); `get_campaign_level(30)` loads correctly
(`"Fracture"`, `stage == "Split"`); `has_next` (the same generic
`current_level_id < LevelManager.get_campaign_level_count()` expression
`game.gd` uses) is correctly `true` after Level 20 and `false` after
Level 30, with zero new special-case code. **Deliberately read-only this
pass** - unlike Phase 2's driver, this one never called
`SaveManager.record_campaign_level_result()`, to avoid writing to this
dev machine's real `user://savegame.json`; separately confirmed that
save is fresh/untouched (`campaign_highest_unlocked_level == 1`,
`campaign_completed_levels.size() == 0`), so no real progress was ever
at risk either way. `project.godot`'s `run/main_scene` was reverted
immediately after (confirmed via a follow-up `grep`) and the temporary
driver files deleted.

### Exported-package validation

**AUTOMATED - DONE.** Using the established D51/D53/D54/D55 technique
(export a real `.pck`, run a check script against it from a directory
with no `project.godot` anywhere in its parent chain): confirmed all 30
paths in `LevelManager.CAMPAIGN_LEVEL_PATHS` resolve via
`ResourceLoader.exists()` AND actually `load()` successfully from the
package (30/30); confirmed `scripts/gameplay/splitter.gd`,
`scenes/tiles/splitter.tscn`, and the target/mirror/blocker scripts and
scenes all resolve and load; confirmed dev tooling
(`tools/level_editor/level_editor.tscn`, `scripts/tools/level_solver.gd`,
`levels/editor_fixtures/`) remains absent from the package. Also
confirmed `assets/gameplay/splitter/**` is (correctly, expectedly)
absent - re-reading `splitter.gd`'s `_draw()` directly shows it uses
only `draw_line`/`draw_circle` with plain `Color` constants and zero
`preload()` calls, so this exclusion (in place since Milestone 4A/D31)
never touches anything the splitter actually needs.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=14`, `versionName=
"1.3.0-STAGE3"`, `package=com.beamshift.game` (unchanged), confirmed via
`aapt2 dump badging` (`minSdkVersion=24`, `targetSdkVersion=36`
unchanged). Final size: **51,033,007 bytes (51.03 MB)** - up only 22,330
bytes (~22.3 KB) from the Stage 2 build, exactly as expected for adding
10 small `.gd` data files with zero new assets and zero export-filter
changes.

### Manual test checklist (Stage 3 approval - nobody but the user can close this out)

**ANDROID MANUAL QA PENDING.** Install `versionCode=14`
(`"1.3.0-STAGE3"`) and:

1. Confirm Level Select now shows exactly 30 levels, with Stages 1-2's
   completion/star state preserved from the earlier approved playthrough
   and only Level 21 newly unlocked (assuming Level 20 was completed).
2. Play Campaign Levels 21-30 **in order, for real**. For each, check
   against `CAMPAIGN_DESIGN.md` section 11c's design table:
   - Does the level teach what it's meant to?
   - **Level 21:** does the splitter tutorial read clearly - straight
     branch free, reflected branch needs one move?
   - **Levels 22-30:** does every required target visibly need a move
     (nothing lights up "for free" past the Level 21 tutorial)?
   - **Levels 26, 28, 30 (cross-branch dependency):** does the shared
     mirror genuinely read as "one decision serves both branches"?
   - **Levels 27, 29, 30 (backward reasoning):** does tracing backward
     from the target's fixed mirror feel like the intended approach?
   - **Levels 24, 25, 27, 28, 29, 30 (decoys/false routes):** do they
     read as plausible, not random?
   - Does solving award 3 stars at the solver-confirmed optimal move
     count and correctly unlock the next level?
3. Confirm the stage overall feels **noticeably trickier than Stage 2**
   without feeling padded or unfair, and that difficulty comes from
   branch reasoning rather than piece count - the specific outcome the
   user's Stage 3 brief asked for.
4. Confirm Level 30 feels like a genuine finale - harder than Stage 2's
   own Level 20 - and that completing it doesn't crash, hang, or attempt
   to load a nonexistent Level 31 (the mechanism is already AUTOMATED/
   REAL-RUNTIME confirmed; this step confirms it also *reads* correctly
   to a real player).
5. Confirm Main Menu's Continue button correctly resumes at the first
   incomplete campaign level after playing at least one Stage 3 level.
6. General sanity: Reset/Pause/Back/Settings/Retry/Next Level/Level
   Select all still work exactly as before (unaffected by this pass).

Nothing about this pass may be marked "Android verified" until the user
installs this exact build and confirms it, same standing rule as every
prior build. Stages 1-2's own manual approval stands on its own and
does not need re-confirming.

## Production Campaign Phase 4 (versionCode 15, "1.4.0-STAGE4")

See `DECISIONS.md` D57 and `CAMPAIGN_DESIGN.md` section 11d for the full
architecture/design writeup. This section covers validation only.

### Color-mechanics audit + correctness fixture (before any level was designed)

**AUTOMATED - DONE.** Per this project's own "verify against source, not
memory" workflow, `scripts/gameplay/grid_types.gd` (`BeamColor` enum,
`target_accepts_color()`) and `scripts/gameplay/laser_system.gd`'s tile-
handling switch were read directly before any Stage 4 level was
authored. Confirmed: an emitter's `color` is fixed for its entire beam
graph; mirrors and fixed mirrors never touch color; both a splitter's
straight branch AND its reflected branch inherit the incoming beam's
color unchanged; only a `FILTER` tile recolors a beam
(`color = filters[pos]`); `target_accepts_color()` is exactly
`required_color == WHITE or required_color == beam_color`. Since Stage 4
uses zero filters (per the brief), every level has exactly one beam
color for its whole tile graph, meaning every REQUIRED target must share
that color - color reasoning comes entirely from non-required
color-decoy targets the beam can genuinely reach along a plausible false
route.

A temporary headless fixture (`RefCounted`-based `LevelData`/
`TilePlacement` objects built directly in a throwaway `SceneTree`
script, no `.gd` level files needed, deleted after use) then verified:
RED->RED, GREEN->GREEN, BLUE->BLUE beams all activate their matching
target; all 6 mismatched pairs (RED->GREEN, RED->BLUE, GREEN->RED,
GREEN->BLUE, BLUE->RED, BLUE->GREEN) correctly fail to activate with
zero activated targets; a colored beam through a rotatable mirror, a
fixed mirror, and BOTH splitter branches all preserve color exactly; a
`WHITE`-required target accepts a colored beam; the default `WHITE`
beam correctly fails a colored-required target. All 15 assertions
passed on the first run.

**Solver/runtime color parity confirmed by construction, not just by
testing:** `LevelSolver.analyze()` (`scripts/tools/level_solver.gd`)
and `GridManager._simulate_and_draw()` (`scripts/gameplay/grid_manager.gd`)
both call the identical `LaserSystem.simulate_until_stable()` - there is
no second, separate "solver-side" color implementation that could ever
drift out of sync with runtime behavior.

### Solver + validator, all 10 Stage 4 levels

**AUTOMATED - DONE.** `LevelValidator.validate()` and
`LevelSolver.analyze()` run against every level under
`levels/campaign/stage_04/` via the same temporary headless-script
convention as Stages 1-3. Result for all 10: zero validator errors, zero
validator warnings, `status == "SOLVABLE"`, `trivial == false`,
`shortest_solution_count == 1`, zero `possible_decoys`, and the solver's
`optimal_moves` matching the level's declared value exactly -
**2, 3, 4, 4, 4, 5, 5, 6, 6, 6** for Levels 31-40 respectively. Full
per-level results (moves, shortest-solution count, states explored,
decoys) are in `CAMPAIGN_DESIGN.md` section 11d - not duplicated here.

**No level-authoring mistakes this pass** - unlike Stage 3's Level 30
(D56), every one of Stage 4's 10 hand-traces (worked out against
`GridTypes.reflect()`'s actual table before writing each file) matched
the solver's confirmed `optimal_moves` exactly on the first attempt.

### Solver-vs-runtime-replay regression, dev + all 4 campaign stages

**AUTOMATED - DONE.** The standard technique, extended to cover all five
populations in one script (grid instantiated once via
`GRID_SCENE.instantiate()` + a manual `_ready()`-equivalent frame-delay
pattern): 15/15 dev levels, 10/10 Stage 1, 10/10 Stage 2, 10/10 Stage 3,
and 10/10 Stage 4 levels each had the solver's own solution replayed
through a real, instantiated `GridManager` via
`_on_orientable_tile_clicked()`. Result: **DEV 15/15 PASS, STAGE1 10/10
PASS, STAGE2 10/10 PASS, STAGE3 10/10 PASS, STAGE4 10/10 PASS - 40/40
total campaign, 55/55 grand total.** Re-confirms Stages 1-3 didn't
regress while adding Stage 4.

### Real-runtime integration check (real autoloads)

**AUTOMATED - DONE.** A temporary `Node` driver, run via the standard
temporary `run/main_scene` swap (real autoloads needed), confirmed:
`LevelManager.get_campaign_level_count() == 40`; `get_campaign_level(31)`
loads correctly (`"Prism"`, `stage == "Spectrum"`); `get_campaign_level(40)`
loads correctly (`"Spectral"`); `get_campaign_level(41)` returns `null`
with a graceful `push_warning` (pre-existing `LevelManager` behavior,
confirmed sufficient - no new code needed). Unlike Phase 3's
deliberately read-only driver, this pass's driver DID exercise
`SaveManager.record_campaign_level_result()` to verify progression end-
to-end: completing campaign Level 30 correctly unlocks Level 31;
completing Levels 31-40 in sequence correctly unlocks each next level;
`campaign_highest_unlocked_level` correctly stays at 40 after completing
Level 40 (never attempts to unlock a nonexistent 41); Stage 1-3 progress
(campaign levels 1-30) stayed marked complete throughout; the dev-level
save fields (`highest_unlocked_level`, `completed_levels`) were
completely untouched, confirming the two save populations never cross-
contaminate. `project.godot`'s `run/main_scene` was reverted immediately
after (confirmed via a follow-up `grep`) and the temporary driver files
deleted. The driver's own `SaveManager.save_game()` calls wrote a real
`user://savegame.json` to this dev machine - overwritten back to fresh
defaults afterward (same JSON `SaveManager._default_data()` would
produce) so the user's own first manual Stage 4 playtest starts from a
genuinely clean save.

### Exported-package validation

**AUTOMATED - DONE.** Using the established D51/D53/D54/D55/D56
technique (export a real `.pck`, run a check script against it from a
directory with no `project.godot` anywhere in its parent chain):
confirmed all 40 paths in `LevelManager.CAMPAIGN_LEVEL_PATHS` resolve
via `ResourceLoader.exists()`; spot-`load()`ed Level 31 and Level 40 in
full from the package (confirmed `display_name`, `stage`, `tiles.size()`,
`optimal_moves`, `is_campaign_level` all survived intact); confirmed
`grid_types.gd`, `laser_system.gd`, `target.gd`, `splitter.gd`,
`mirror.gd`, `blocker.gd`, and their scenes all resolve and load;
confirmed dev tooling (`tools/level_editor/level_editor.gd`,
`scripts/tools/level_solver.gd`, `levels/editor_fixtures/`) remains
absent from the package.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=15`, `versionName=
"1.4.0-STAGE4"`, `package=com.beamshift.game` (unchanged). Final size:
**51,055,337 bytes (51.06 MB)** - up only 22,330 bytes (~22.3 KB) from
the Stage 3 build, the identical delta to Stage 3's own growth over
Stage 2, exactly as expected for adding 10 small `.gd` data files with
zero new assets and zero export-filter changes.

### Mobile color readability (no device - visual/contrast reasoning only)

**PARTIAL - AUTOMATED reasoning, MANUAL confirmation still required.**
`GridTypes.beam_color_to_render_color()` was read directly:
`RED = (1.0, 0.3, 0.3)`, `GREEN = (0.35, 1.0, 0.45)`,
`BLUE = (0.4, 0.6, 1.0)`, `WHITE = (1.0, 0.95, 0.3)` (warm yellow-white,
unchanged from Milestone 1) - four colors with clearly separated hues
and no near-duplicates, against `target.gd`'s dark gameplay background
(confirmed no near-black-on-near-black or near-white-on-near-white
pairing exists in this palette). `target.gd`'s existing colored-ring +
dimmed-alpha rendering (built for Milestone 2's dev color levels,
unchanged by this pass) already renders each target's `required_color`
distinctly. **No code changes were made or needed** - this is the same
palette Milestone 2's dev Levels 8/9 ("True Color"/"Recolor") already
shipped and exercised. Actual on-device contrast/brightness under real
sunlight or a specific panel's calibration is a MANUAL TEST REQUIRED
item - see the checklist below.

### Manual test checklist (Stage 4 approval - nobody but the user can close this out)

**ANDROID MANUAL QA PENDING.** Install `versionCode=15`
(`"1.4.0-STAGE4"`) and:

1. Confirm Level Select now shows exactly 40 levels, with Stages 1-3's
   completion/star state preserved and only Level 31 newly unlocked
   (assuming Level 30 was completed).
2. Play Campaign Levels 31-40 **in order, for real**. For each, check
   against `CAMPAIGN_DESIGN.md` section 11d's design table:
   - Does the level teach what it's meant to?
   - **Level 31:** does the color lesson read clearly - the beam visibly
     crosses the wrong-color target without activating it, then reaches
     the real target?
   - **Levels 32-40:** are RED/GREEN/BLUE beams and targets clearly
     distinguishable on your actual screen (MANUAL TEST REQUIRED - see
     "Mobile color readability" above)?
   - **Levels 36, 38, 39, 40 (cross-branch/global dependency):** does
     the shared mirror / early decision genuinely read as "this one
     piece controls more than it looks like"?
   - **Levels 33, 37, 39, 40 (backward reasoning):** does tracing
     backward from the target's required color and the fixed mirror's
     entry direction feel like the intended approach?
   - **Levels 31-40 (color decoys/false routes):** do the wrong-color
     targets read as plausible traps, not random clutter?
   - Does solving award 3 stars at the solver-confirmed optimal move
     count and correctly unlock the next level?
3. Confirm the stage overall feels **noticeably trickier than Stage 3**
   without feeling padded or unfair, and that difficulty comes from
   color+geometry reasoning together, not piece count.
4. Confirm Level 40 feels like a genuine finale - harder than Stage 3's
   own Level 30 - and that completing it doesn't crash, hang, or attempt
   to load a nonexistent Level 41 (the mechanism is already AUTOMATED/
   REAL-RUNTIME confirmed; this step confirms it also *reads* correctly
   to a real player).
5. Confirm Main Menu's Continue button correctly resumes at the first
   incomplete campaign level after playing at least one Stage 4 level.
6. General sanity: Reset/Pause/Back/Settings/Retry/Next Level/Level
   Select all still work exactly as before (unaffected by this pass).

Nothing about this pass may be marked "Android verified" until the user
installs this exact build and confirms it, same standing rule as every
prior build. Stages 1-2's own manual approval stands on its own and
does not need re-confirming; Stage 3's manual QA is still separately
pending and should ideally be confirmed alongside Stage 4's.

## Development Test Mode — Unlock All Campaign Levels (versionCode 16, "1.4.1-QA-UNLOCK")

See `DECISIONS.md` D58 for the full implementation writeup. This section
covers validation only.

### QA-unlock-all validation

**AUTOMATED - DONE.** A temporary `Node` driver, run via the standard
temporary `run/main_scene` swap (real autoloads needed), tested both
flag states:

**Flag `true` (current default):**
1. `get_campaign_level_count() == 40` confirmed.
2. From a fresh save (`campaign_highest_unlocked_level == 1`),
   `LevelManager.is_campaign_level_selectable(id)` returned `true` for
   every spot-checked id (1, 15, 30, 31, 40) and for **all 40** ids in
   a full loop, even though `SaveManager.is_campaign_level_unlocked()`
   itself correctly still reported `false` for everything past Level 1
   — confirming the override is additive at the Level Select layer only
   and never mutates the underlying unlock check.
3. Directly recorded Level 31's completion (never touching 1-30) via
   `SaveManager.record_campaign_level_result(31, ...)`:
   `campaign_completed_levels == {"31": true}` only,
   `campaign_best_moves_per_level == {"31": 2}`,
   `campaign_best_stars_per_level == {"31": 3}` (solver-derived, not
   faked), and levels 1-30 confirmed still NOT completed.
4. Reset, then directly recorded Level 40's completion (never touching
   1-39): `campaign_completed_levels == {"40": true}` only, correct
   solver-derived stars/moves, levels 1-39 confirmed still NOT
   completed, and `campaign_highest_unlocked_level` stayed at `1` -
   completing Level 40 directly does **not** cascade-unlock anything,
   confirming real progression tracking is completely unaffected by the
   QA override.
5. Dev-level save fields (`highest_unlocked_level`, `completed_levels`)
   confirmed untouched throughout.

**Flag `false` (temporarily set for this test only, then reverted to
`true`):**
6. Same fresh-save state: only Level 1 reported `is_campaign_level_
   selectable() == true`; Levels 2-40 all correctly reported `false`,
   matching `SaveManager.is_campaign_level_unlocked()` exactly (normal
   sequential locking, fully restored with zero code path differences
   from before this feature existed).
7. No save-file schema change, no migration, no reset needed to switch
   between the two states - confirmed by re-running against the same
   save fields already in memory from step 6's setup.

Flag set back to `true` afterward, confirmed via `grep`.
`project.godot`'s `run/main_scene` was reverted immediately after
(confirmed via a follow-up `grep`) and the temporary driver files
deleted. The driver's own `SaveManager.save_game()` calls wrote a real
`user://savegame.json` to this dev machine during both test runs -
overwritten back to fresh defaults afterward, same established
convention as every prior stage's runtime validation.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=16`, `versionName=
"1.4.1-QA-UNLOCK"`, `package=com.beamshift.game` (unchanged). Final
size: **51,055,337 bytes (51.06 MB)** - byte-identical to the Stage 4
build, exactly as expected for a one `const bool` + one small function
change with zero new assets.

### Release checklist (do not ship with QA unlock enabled)

- [ ] Disable `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` (set to `false`
      in `scripts/managers/level_manager.gd`) before final production
      APK.
- [ ] Re-run the QA-unlock validation above with the flag `false` to
      reconfirm normal sequential locking before shipping.
- [ ] Re-export the Android release build only after the flag is
      confirmed `false`.

This build (`versionCode=16`) is a **development/QA build** and must
never be distributed as the production release while the flag is `true`.

## Campaign Reboot — Levels 1-50 rebuilt mechanic-agnostic (versionCode 22, "2.0.0-CAMPAIGN-REBOOT-QA")

See `DECISIONS.md` D64 and `CAMPAIGN_DESIGN.md` sections 1a/2/11f/11g/
11h for the full architecture/design writeup. This section covers
validation only; the "Production Campaign Phase 3/4/5" sections below
describe the ORIGINAL authoring of Levels 21-50 and remain historically
accurate for Levels 46-50 (unchanged) but not for Levels 21-45
(replaced).

### Audit of existing Levels 1-50

**AUTOMATED - DONE (source inspection, per `CAMPAIGN_DESIGN.md`'s own
existing design tables' recorded `states_explored`/`optimal_moves`,
cross-referenced against manual-approval status in `CURRENT_STATUS.md`).**
Result: Levels 1-10 and 11-20 KEEP (manually approved); Levels 21-30,
31-40, 41-45 REPLACE (never approved; 31-40 had explicit "feels easy"
feedback; the others were front-loaded mechanic-introduction levels);
Levels 46-50 KEEP (already combination-focused, Level 50 is the named
benchmark). See `DECISIONS.md` D64 for the full per-block reasoning.

### 25 replaced levels (21-45) — design + solver validation

**AUTOMATED - DONE.** Each of the 25 new levels was hand-designed and
hand-traced against `GridTypes.reflect()`'s actual table before being
written, then validated in 5 batches of 5 via a temporary headless
script running `LevelValidator.validate()` and `LevelSolver.analyze()`.
Result: **zero validator errors or warnings across all 25**; every
`possible_decoys` hit matches an intentionally-placed decoy named in
that level's own `developer_notes`, nothing unintended.
`shortest_solution_count = 1` for all 25.

**One real authoring bug caught by the solver, not by hand-tracing**
(exactly what this workflow exists to catch): Level 30 ("Deadlock")'s
first draft required target A as RED, but its own straight branch
passes through an unavoidable GREEN filter first - the solver correctly
returned `status == "UNSOLVABLE"` across the full 128-state search.
Fixed by matching the target's required color (GREEN) to what the beam
actually carries; re-run confirmed `SOLVABLE`, 6 moves, matching
original intent. One further bookkeeping-only fix: Level 40
("Crucible")'s declared `optimal_moves` was initially 5 (miscounting an
inert decoy piece); the solver correctly reported 4, and the declared
value was corrected per section 7's "always trust the solver" rule. All
other 23 levels matched hand-traced intent exactly on the first solver
pass.

### Full campaign regression (all 50)

**AUTOMATED - DONE.** Solver-vs-runtime-replay technique re-run against
all 50 campaign levels together (not just the 25 new ones): **50/50
solver PASS, 50/50 runtime-replay PASS** (`GridManager.
_on_orientable_tile_clicked()`, the real gameplay path, confirms every
solver-found solution is actually reachable through real player input,
not just `LaserSystem` in isolation).

### Dev and Tutorial regression

**AUTOMATED - DONE.** 15/15 dev-level solver-vs-runtime-replay PASS
(unaffected, not touched). 10/10 tutorial-board solvability PASS
(Tutorial untouched this pass, per the brief's explicit freeze on
redesigning T01-T10 content).

### Save compatibility

**DONE (design decision, not a code change).** Campaign level IDs 1-50
are unchanged, so an existing QA save's `campaign_completed_levels`/
star data for those IDs still applies to the *redesigned* puzzle at the
same ID (e.g. a save showing "Level 35 complete, 3 stars" will keep
showing that even though Level 35 is now a different puzzle). Explicitly
acceptable for QA since `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` already
makes every level directly selectable regardless of save state. No save
was wiped, no migration was needed, `SAVE_VERSION` was not bumped (no
field shape changed). A real release build would need a save reset or a
"levels changed, stars reset" migration before launch - noted as a
pre-launch checklist item, not an immediate action.

### Manual test checklist (Campaign Reboot approval — nobody but the user can close this out)

**ANDROID MANUAL DIFFICULTY QA PENDING.** Install `versionCode=22`
(`"2.0.0-CAMPAIGN-REBOOT-QA"`) and play through the Campaign. A full
50-level playthrough isn't required for a first pass - use this
recommended focused set to sample the whole curve:

1. **Levels 1, 5, 10** (kept, unchanged) — confirm they still feel as
   good as before; this is a sanity check that nothing regressed, not a
   re-review of already-approved content.
2. **Level 11, 15, 20** (kept, unchanged) — same sanity check for Stage
   2's content.
3. **Level 21, 25, 30** (REPLACED) — confirm these feel like real hard+
   -> very hard puzzles, not "the easy splitter tutorial" the old
   content was. Level 30 specifically should feel like it's approaching
   Level 50's quality (per the design intent).
4. **Level 31, 35, 40** (REPLACED, explicit "feels easy" feedback on
   the old content) — this is the most important check in the whole
   pass: confirm these are now genuinely harder, not just renamed.
   Level 40 specifically should feel comparable to or harder than Level
   50.
5. **Level 41, 45** (REPLACED) — confirm these feel like expert-tier,
   whole-board-reasoning puzzles rather than "here's what a filter
   does."
6. **Level 46-50** (KEPT, unchanged) — confirm Level 50 "Paradox" still
   feels like the clear hardest puzzle in the campaign, and that
   Levels 46-49 leading into it each feel distinct from each other
   (not four variations of the same trick).
7. For each level played, note: did you find the correct first move
   quickly or did you have to think? Did any "obvious" route turn out
   to be a trap? Did you ever solve a target while accidentally
   breaking another (hazard/dependency levels)? Report specific level
   numbers for anything that felt too easy, unfairly obscure, or
   broken.
8. Confirm Campaign progress/stars from a pre-reboot save (if any) still
   loads without errors — expected: an old save's completion/star data
   for Levels 21-50 will still show, even though the puzzles changed
   underneath it (see "Save compatibility" above) - this is expected
   QA-phase behavior, not a bug to report.

Nothing about this pass may be marked "Android verified" until the user
installs this exact build and confirms it, same standing rule as every
prior build. **This is the Campaign's first manual QA pass in its
rebuilt form** — even Levels 1-20's prior approval was for the *old*
campaign context, before Levels 21-50 around them changed completely.

## Production Campaign Phase 5 (versionCode 17, "1.5.0-STAGE5-QA")

See `DECISIONS.md` D59 and `CAMPAIGN_DESIGN.md` section 11e for the full
architecture/design writeup. This section covers validation only.

### Stage 4 feedback recorded

**DONE.** User feedback ("Levels 31-40 feel easy") recorded in
`CURRENT_STATUS.md`, `PROJECT_HANDOFF.md`, `ROADMAP.md`, and
`CLAUDE.md`. Stage 4's status stays `IMPLEMENTED / VALIDATED` - no bug
was found in Stage 4, so no Stage 4 level was modified; the feedback
instead shaped Stage 5's escalation curve (Levels 43 onward increase
sharply, per the brief's explicit instruction).

### Filter-mechanics audit + multi-filter-chain fixture (before any level was designed)

**AUTOMATED - DONE.** Per this project's "verify against source, not
memory" workflow, `scripts/gameplay/filter.gd`,
`TilePlacement.make_filter()`, and `LaserSystem.simulate()`'s filter
branch were read directly before any Stage 5 level was authored.
Confirmed: a `FILTER` has no `mirror_orientation`/`rotatable` fields at
all and is therefore structurally excluded from
`LevelData.get_rotatable_tiles()` (which only matches `MIRROR`/
`SPLITTER`) - a filter can never be a move, never part of the solver's
bitmask; the filter branch in `LaserSystem.simulate()` is
`color = filters[pos]; continue` - unconditional, direction-preserving,
no dependency on incoming color.

A temporary headless fixture (deleted after use) then verified 15
assertions, all passing on the first run: RED/GREEN/BLUE single-filter
recolors from both `WHITE` and from another starting color; a 2-filter
chain (`WHITE -> RED filter -> BLUE filter`) correctly solves a BLUE
target and correctly fails a RED target - confirming **filters chain as
"last one touched wins," never blending**; color preservation through a
rotatable mirror, a fixed mirror, and both a splitter's straight and
reflected branches; a direct check that `get_rotatable_tiles()` excludes
a filter from its result; and a solver-vs-hand-trace parity check
(`optimal_moves == 0`) on a small filter level.

**Solver/runtime filter parity confirmed by construction, not just by
testing:** `LevelSolver.analyze()` and `GridManager._simulate_and_draw()`
both call the identical `LaserSystem.simulate_until_stable()`, and since
a filter can never vary across candidate states (it's never in the
rotatable bitmask), the solver evaluates every filter identically to
fixed board geometry in every state it explores.

### Solver + validator, all 10 Stage 5 levels

**AUTOMATED - DONE.** `LevelValidator.validate()` and
`LevelSolver.analyze()` run against every level under
`levels/campaign/stage_05/` via the same temporary headless-script
convention as Stages 1-4. Result for all 10: zero validator errors, zero
validator warnings, `status == "SOLVABLE"`, `trivial == false`,
`shortest_solution_count == 1`, and the solver's `optimal_moves`
matching the level's declared value exactly - **3, 4, 4, 5, 5, 6, 5, 6,
6, 7** for Levels 41-50 respectively. `possible_decoys` returned empty
for 9 of 10 levels and returned exactly `[(3,3)]` for Level 50 - its one
fully intentional decoy mirror, confirmed inert by the solver precisely
as designed. Full per-level results (moves, shortest-solution count,
states explored, filter sequences) are in `CAMPAIGN_DESIGN.md` section
11e - not duplicated here.

**No level-authoring mistakes this pass** - every one of Stage 5's 10
hand-traces (worked out against `GridTypes.reflect()`'s actual table
before writing each file) matched the solver's confirmed `optimal_moves`
exactly on the first attempt.

### Solver-vs-runtime-replay regression, dev + all 5 campaign stages

**AUTOMATED - DONE.** The standard technique, extended to cover all six
populations in one script: 15/15 dev levels, 10/10 Stage 1, 10/10 Stage
2, 10/10 Stage 3, 10/10 Stage 4, and 10/10 Stage 5 levels each had the
solver's own solution replayed through a real, instantiated
`GridManager` via `_on_orientable_tile_clicked()`. Result: **DEV 15/15
PASS, STAGE1 10/10 PASS, STAGE2 10/10 PASS, STAGE3 10/10 PASS, STAGE4
10/10 PASS, STAGE5 10/10 PASS - 50/50 total campaign, 65/65 grand
total.** Re-confirms Stages 1-4 didn't regress while adding Stage 5.

### Real-runtime integration check (real autoloads, QA unlock + progression)

**AUTOMATED - DONE.** A temporary `Node` driver, run via the standard
temporary `run/main_scene` swap, confirmed: `LevelManager.
get_campaign_level_count() == 50`; `get_campaign_level(41)` loads
correctly (`"Filter"`, `stage == "Filters"`); `get_campaign_level(50)`
loads correctly (`"Paradox"`); `get_campaign_level(51)` returns `null`
with a graceful `push_warning`. With `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_
TESTING` still `true` (D58), `is_campaign_level_selectable()` returned
`true` for all 50 ids from a fresh save, confirming the QA-unlock flag
needed zero changes to cover the new stage. Separately, real progression
(the `SaveManager` layer underneath the QA override) was also verified:
completing campaign Level 40 correctly unlocks Level 41; completing
Levels 41-50 in sequence correctly unlocks each next level;
`campaign_highest_unlocked_level` correctly stays at 50 after completing
Level 50 (never attempts to unlock a nonexistent 51); Stage 1-4 progress
(campaign levels 1-40) stayed marked complete throughout; the dev-level
save fields stayed completely untouched. `project.godot`'s
`run/main_scene` was reverted immediately after (confirmed via a
follow-up `grep`) and the temporary driver files deleted. The driver's
own `SaveManager.save_game()` calls wrote a real `user://savegame.json`
to this dev machine - overwritten back to fresh defaults afterward.

### Exported-package validation

**AUTOMATED - DONE.** Using the established D51/D53/D54/D55/D56/D57
technique (export a real `.pck`, run a check script against it from a
directory with no `project.godot` anywhere in its parent chain):
confirmed all 50 paths in `LevelManager.CAMPAIGN_LEVEL_PATHS` resolve
via `ResourceLoader.exists()`; spot-`load()`ed Level 41 and Level 50 in
full from the package (confirmed `display_name`, `stage`,
`tiles.size()`, `optimal_moves`, `is_campaign_level` all survived
intact); confirmed `filter.gd`, `filter.tscn`, `grid_types.gd`,
`laser_system.gd`, `target.gd`, `splitter.gd`, `mirror.gd`, `blocker.gd`
and their scenes all resolve and load; confirmed dev tooling
(`tools/level_editor/level_editor.gd`, `scripts/tools/level_solver.gd`)
remains absent from the package.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=17`, `versionName=
"1.5.0-STAGE5-QA"`, `package=com.beamshift.game` (unchanged). Final
size: **51,077,667 bytes (51.08 MB)** - up only 22,330 bytes (~22.3 KB)
from the QA-unlock build, the same delta every prior stage transition
produced, exactly as expected for adding 10 small `.gd` data files with
zero new assets and zero export-filter changes. QA unlock-all
(`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`) confirmed still `true` in
this build, per explicit instruction to keep it enabled.

### Android color/filter readability (no device - visual/contrast reasoning only)

**PARTIAL - AUTOMATED reasoning, MANUAL confirmation still required.**
`FilterTile._draw()` (`scripts/gameplay/filter.gd`) was read directly:
a filter renders as an outlined, semi-transparent colored square (22%
margin inset, 5px stroke, 18% fill alpha) using the same
`GridTypes.beam_color_to_render_color()` palette as beams and targets -
visually distinct in shape from a target's ring and from a beam's solid
line, so a filter should not be confused with either at a glance. No
code changes were made or needed - this is the same filter visual
Milestone 2's dev Level 9 ("Recolor") already shipped and exercised.
Actual on-device contrast/brightness, and whether a player can
distinguish a filter's color from a target's ring color at a glance
under real sunlight or a specific panel's calibration, is a MANUAL TEST
REQUIRED item - see the checklist below.

### Manual test checklist (Stage 5 approval - nobody but the user can close this out)

**ANDROID MANUAL QA PENDING.** Install `versionCode=17`
(`"1.5.0-STAGE5-QA"`) and:

1. Confirm Level Select shows exactly 50 levels, all directly
   selectable (QA unlock is enabled) - confirm this does NOT show any
   level as falsely completed/starred if it hasn't actually been played.
2. Play Campaign Levels 41-50 **in order, for real**. For each, check
   against `CAMPAIGN_DESIGN.md` section 11e's design table:
   - Does the level teach what it's meant to?
   - **Level 41:** does the filter lesson read clearly - incoming color
     -> filter -> changed color -> matching target, with no ambiguity?
   - **Levels 42-50:** is a filter tile visually distinguishable from a
     target and from a beam segment on your actual screen (MANUAL TEST
     REQUIRED - see "Android color/filter readability" above)?
   - **Levels 46, 47, 48, 50 (cross-branch/global dependency):** does
     the shared mirror / early gate genuinely read as "this one piece
     controls more than it looks like"?
   - **Levels 47, 50 (backward reasoning):** does tracing backward from
     the target's required color, through the fixed mirror, feel like
     the intended approach?
   - **Level 50 (chained filters):** is it clear that only the LAST
     filter touched determines the beam's final color on the straight
     branch?
   - **Levels 41-50 (false routes/decoys):** do they read as plausible
     traps, not random clutter?
   - Does solving award 3 stars at the solver-confirmed optimal move
     count and correctly unlock the next level (real progression,
     independent of QA unlock)?
3. Confirm the stage overall feels **noticeably trickier than Stage 4**
   - directly addressing the "feels easy" feedback - without feeling
   padded or unfair.
4. Confirm Level 50 feels like the hardest level in the game so far -
   harder than Stage 4's own Level 40, Stage 3's Level 30, and Stage
   2's Level 20 - and that completing it doesn't crash, hang, or
   attempt to load a nonexistent Level 51.
5. Confirm Main Menu's Continue button correctly resumes at the first
   incomplete campaign level after playing at least one Stage 5 level
   (Continue uses real progression, not the QA-unlock override).
6. General sanity: Reset/Pause/Back/Settings/Retry/Next Level/Level
   Select all still work exactly as before (unaffected by this pass).

Nothing about this pass may be marked "Android verified" until the user
installs this exact build and confirms it, same standing rule as every
prior build. Stages 1-2's own manual approval stands on its own and
does not need re-confirming; Stages 3, 4, and 5's manual QA are all
still separately pending and should ideally be confirmed together.

## Guided Tutorial Mode (versionCode 18 -> 19 -> 20 -> 21, "1.6.0-TUTORIAL-QA" -> "1.6.1-TUTORIAL-FIX" -> "1.6.2-TUTORIAL-VISUAL-FIX" -> "1.6.3-TUTORIAL-INPUT-FIX")

See `DECISIONS.md` D60/D61/D62/D63 and `TUTORIAL_SYSTEM.md` for the full
architecture/design writeup. This section covers validation only.

**`versionCode=18` MANUAL ANDROID QA FAILED** (real device test by the
user): T01 opened with no tiles visible, Reset made tiles appear but no
tutorial instruction/highlight ever showed and the mirror could not be
rotated - effectively softlocked. Root cause: `scenes/ui/tutorial_panel.tscn`
and `scenes/ui/tutorial_complete_popup.tscn` never attached their
scripts to their root nodes, crashing `game.gd._ready()` before
`_load_current_level()` ran on first open. Full root-cause writeup:
`DECISIONS.md` D61. Fixed in `versionCode=19`
(`"1.6.1-TUTORIAL-FIX"`). **Do not treat any `versionCode=18` "PASS"
below as proof of correctness on its own** - none of those checks
exercised a real, freshly-instantiated `game.gd` scene, which is exactly
what missed the bug the first time.

**Manual VIDEO QA of `versionCode=19` found two visual bugs** (not a
repeat of the v1 failure - tiles/instruction/interaction all worked):
the board stayed heavily dimmed during `REQUIRE_TILE_TAP` with the
required mirror hard to see under it, and the dim wasn't reliably
clearing. Investigation found no dim overlay had ever existed in the
Tutorial system before this - the real bug was a plain outline highlight
with too little contrast against full gameplay art. Fixed in
`versionCode=20` (`"1.6.2-TUTORIAL-VISUAL-FIX"`) - full root-cause
writeup and architecture: `DECISIONS.md` D62. See the "Visual focus fix
validation" section below, added after the original (all still-accurate)
sections from the `versionCode=18`/`19` passes.

**Manual VIDEO QA of `versionCode=20` found the highlighted mirror could
be SEEN but not TAPPED** - repeated taps at `REQUIRE_TILE_TAP` did
nothing, the tutorial never advanced. Root cause: `game.tscn`'s
`TutorialPanel` instance node redundantly re-declared full-screen
anchors on top of `tutorial_panel.tscn`'s own correct bottom-anchored
layout, making its `Panel` child (default `mouse_filter = STOP`)
silently cover the entire screen and intercept every tap - invisible
because the panel's 88%-opaque background blended into the already-dark
gameplay art. Fixed in `versionCode=21` (`"1.6.3-TUTORIAL-INPUT-FIX"`) -
full root-cause writeup: `DECISIONS.md` D63. See the "Click input fix
validation" section below, added after the D62-pass sections.

### Mechanic availability audit

**AUTOMATED - DONE (source inspection).** Before designing any tutorial,
every mechanic the brief's T01-T10 plan named was checked directly
against source, not assumed: `scripts/gameplay/mirror.gd` (fixed
mirrors already reject taps via `_gui_input()`'s `if not rotatable:
return`, and already draw a lock icon - no tutorial-only rule needed),
`scripts/gameplay/portal.gd`/`switch.gd`/`gate.gd`/`hazard.gd` (all
fully implemented, all purely passive/non-interactive, all proven by
existing dev/regression levels 10-13), and `LaserSystem.simulate()`
(loops over every `EMITTER` tile with zero special-casing, proven by
dev/regression level 13 "Two Sources"). Result: **every mechanic was
already implemented - none needed to be faked, none needed to be left
pending.**

### Forced-interaction / step-machine architecture test

**AUTOMATED - DONE.** A temporary headless driver instantiated a real
`GridManager` and a `TutorialManager` directly (no scene-tree signal
wiring - the driver manually forwards `move_made`/`simulation_updated`
in the same order the real signals fire, exactly as `game.gd` does) and
drove T01 through its full step sequence:
- Step 0 (`MESSAGE`): confirmed `interaction_locked == true`.
- Steps 1-3 (`MESSAGE`, with highlights): confirmed still locked.
- Step 4 (`REQUIRE_TILE_TAP` on the one correct mirror): confirmed
  `interaction_restricted_to == (2,2)`.
- A tap on a **different** cell while restricted: confirmed silently
  ignored - `TutorialManager.current_step_index` unchanged, no state
  mutated.
- A tap on the **correct** cell: confirmed it cascades through
  `REQUIRE_TILE_TAP -> WAIT_FOR_PUZZLE_SOLVED -> MESSAGE` correctly in
  one synchronous chain (the real puzzle actually solves - `grid.
  is_solved == true` - during this same step), then `advance()` past
  the final step correctly returns `null` (`current_step_index` points
  past the end) and would emit `tutorial_finished`.

**A real bug was found and fixed during this test, not by inspection:**
`GridManager.move_made` fires *before* `_simulate_and_draw()` runs
(pre-existing, unchanged Campaign behavior - confirmed by reading
`_on_orientable_tile_clicked()` directly). A `WAIT_FOR_TARGET_ACTIVATION`
step naively wired to `move_made` would therefore always read one-move-
stale target state. Fixed by adding a new `GridManager.simulation_
updated` signal, emitted at the end of `_simulate_and_draw()` *after*
target/switch/gate/hazard state updates - purely additive, zero effect
on `move_made`'s existing timing or its only other listener (`game.gd`'s
move counter, which doesn't read simulation state at all).
`TutorialManager.notify_move_made()` (via `move_made`) now only ever
handles `REQUIRE_TILE_TAP`; `notify_simulation_updated()` (via the new
signal) handles `WAIT_FOR_TARGET_ACTIVATION`.

### All 10 tutorial boards confirmed solvable

**AUTOMATED - DONE.** Each `levels/tutorial/t0N.gd` was loaded into a
real `GridManager` and its own intended move sequence (the exact taps
each tutorial's `REQUIRE_TILE_TAP`/free-play steps expect) was replayed
via `_on_orientable_tile_clicked()` directly - the same runtime-replay
technique `TEST_PLAN.md` uses for Campaign levels. Result: **T01-T10,
10/10 PASS** (`is_solved == true` for every one). There is no
`LevelSolver` involvement for tutorials (they don't have solver-
confirmed `optimal_moves` - each tutorial's `steps` array itself defines
the one intended path, not an open search space).

### Save isolation test

**AUTOMATED - DONE.** Confirmed in both directions: calling
`SaveManager.record_tutorial_level_result(1, ...)` left
`campaign_completed_levels`/`campaign_highest_unlocked_level` and the
dev-level fields (`completed_levels`/`highest_unlocked_level`)
completely untouched; calling `SaveManager.record_campaign_level_
result(1, ...)` afterward left `tutorial_completed_levels` unchanged
(still exactly `{"1": true}`). `SAVE_VERSION` bumped 2 -> 3 is purely
informational - `.get()` defaults mean a pre-Tutorial save loads
correctly with fresh tutorial progress and every existing field intact,
no migration code needed, same pattern as D54's 1 -> 2 bump.

### Real scene-instantiation / integration check

**AUTOMATED - DONE.** A temporary driver instantiated the real scenes
directly (not through a full navigation flow, but genuine
`PackedScene.instantiate()` + `add_child()`, exercising real `_ready()`
logic) and confirmed:
- Main Menu's button order: `CONTINUE, CAMPAIGN, TUTORIAL, SETTINGS,
  QUIT` (previously `PLAY, CONTINUE, SETTINGS, QUIT`) - `TutorialButton`
  present and visible, correctly wired to `GameManager.
  go_to_tutorial_select()`.
- Tutorial Select populates exactly 10 cards; T01's card `disabled ==
  false` (always unlocked) and T02's `disabled == true` (locked, fresh
  save) - matching `SaveManager.is_tutorial_level_unlocked()` exactly.
- Campaign Level Select **still populates exactly 50 cards**, completely
  unaffected; `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`
  confirmed still `true`; `is_campaign_level_selectable(50) == true`
  even from a fresh save - QA unlock-all fully intact.
- `game.tscn` instantiates cleanly (normal, non-tutorial load) with the
  new `TutorialPanel`/`TutorialCompletePopup` nodes present but inert
  (both `visible = false` by default, never shown outside tutorial
  mode).

### `get_tutorial_level(11)` safety

**AUTOMATED - DONE.** Confirmed `LevelManager.get_tutorial_level(11)`
returns `null` with a graceful `push_warning` - the identical pre-
existing pattern `get_campaign_level()`/`get_level()` already use for an
out-of-range id. No new "end of tutorial content" code was needed.

### Full existing regression re-confirmed

**AUTOMATED - DONE.** Re-run after every architecture change (not just
once at the end): headless `--import` clean; 15/15 dev-level + 10/10
each of Stage 1/2/3/4/5 (50/50 total campaign) solver-vs-runtime-replay
all PASS - **65/65 grand total, zero Campaign regression at any point**
during this pass.

### Exported-package validation

**AUTOMATED - DONE.** Using the established D51/D53/D54/D55/D56/D57
technique: confirmed all 10 `levels/tutorial/t0N.gd` files resolve and
load with correct data (spot-checked T01 and T10 in full - `tiles`/
`steps` counts both survived intact); confirmed every new tutorial
script/scene (`tutorial_manager.gd`, `tutorial_step_data.gd`,
`tutorial_level_data.gd`, `tutorial_panel.gd`/`.tscn`,
`tutorial_complete_popup.gd`/`.tscn`, `tutorial_button.gd`/`.tscn`,
`tutorial_select.gd`/`.tscn`, `tutorial_highlight.gd`) and
`portal.gd`/`switch.gd`/`gate.gd`/`hazard.gd` all resolve and load;
confirmed all 50 campaign level files and `main_menu.tscn`/`game.tscn`
still resolve; confirmed dev tooling remains excluded.

### Android export

**ANDROID EXPORTED - DONE.** `versionCode=18`, `versionName=
"1.6.0-TUTORIAL-QA"`, `package=com.beamshift.game` (unchanged). Final
size: **51,126,659 bytes (51.13 MB)** - up 48,992 bytes from the Stage
5/QA-unlock build, larger than a typical stage's pure-level-data delta
since this pass added real new architecture (~15 new scripts/scenes)
plus 10 tutorial levels, not just level data. QA unlock-all
(`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`) confirmed still `true` in
this build.

### Android UI/readability assessment (no device - code/layout reasoning only)

**PARTIAL - AUTOMATED reasoning, MANUAL confirmation still required.**
`TutorialHighlight._draw()` was read directly: a pulsing cyan
(`Color(0.3, 0.95, 1.0)`) outline-only border (never fills the cell, so
the tile stays fully visible), `mouse_filter = IGNORE` (confirmed it can
never intercept a tap meant for the tile underneath). `tutorial_panel.
tscn` is bottom-anchored with a flat, semi-transparent dark panel
(`StyleBoxFlat`, no texture dependency, so no export-filter risk) sized
to avoid the center puzzle-grid area on a portrait phone aspect ratio by
construction (anchored to the bottom ~220px band, same general region as
the existing gameplay `BottomBar`). No code changes were made or needed
beyond this pass's own additions. Actual on-device readability -
instruction text size, whether the highlight is visible in bright
sunlight, whether the panel ever visually overlaps a highlighted tile on
a specific real aspect ratio, touch-target size for the "TAP TO
CONTINUE" button - is a MANUAL TEST REQUIRED item, see the checklist
below.

### Runtime fix validation (`versionCode=19`, "1.6.1-TUTORIAL-FIX")

**RENDERED - DONE.** A real (non-headless, per `CLAUDE.md` 12d) run
reproduced the exact reported crash (`SCRIPT ERROR: Invalid access to
property or key 'continue_pressed'`) before the fix, confirmed it was
gone after adding `script = ExtResource("1")` to both `.tscn` roots,
and captured a real screenshot of T01's very first frame after
switching into tutorial mode - showing the grid, a visible beam, the
emitter tile, the "Welcome to BeamShift." message, and a "TAP TO
CONTINUE" button, with **no Reset needed**. `grid.size = (888.0,
1069.0)` and `cell_size = 177.0` were both already correct and nonzero
on this first frame, confirming there was never a separate `Control`-
layout timing race - see `DECISIONS.md` D61 for why no
`level_visuals_ready` signal was added.

**AUTOMATED - DONE.** All 10 tutorials (T01-T10) re-validated for
startup through the real `game.tscn` instantiation path (the exact path
that caught the original bug, not a direct-method-call fixture) -
grid non-null with `level_data` set, tiles instantiated, `cell_size >
0`, `TutorialPanel` visible with non-empty instruction text, the new
`QADebugLabel` visible. Result: **T01 through T10, 10/10 PASS, zero
script/runtime errors.**

**AUTOMATED - DONE.** T01 lifecycle validated via a driver that calls
the same handlers a real button press does (`_on_reset_pressed()`,
`_on_pause_pressed()`, `_on_pause_resume_pressed()`,
`_on_pause_restart_pressed()`):
- Reset **three times in a row** from mid-tutorial (step 2): each time
  correctly returns to step 0, with exactly 3 tiles re-instantiated,
  the panel visible, and the highlight not left stuck visible from a
  prior state - no duplicated UI/highlights/signals across repeated
  Resets.
- Pause -> Resume: `get_tree().paused` correctly toggles true then
  false; `TutorialManager.current_step_index` is exactly the same
  before and after - no step is skipped or repeated by pausing.
- Pause -> Restart: correctly resets to step 0 with `paused` returned
  to `false`.

**AUTOMATED - DONE.** Fail-safe added: `GridManager.has_orientable_tile()`
+ `TutorialManager`'s `REQUIRE_TILE_TAP` handling now check the target
tile actually exists before locking input to it; if it doesn't, a loud
`push_error` fires and input is left unrestricted rather than
softlocked. Verified by direct code read; no tutorial's authored data
currently triggers this path (all `target_position` values are correct
for their tutorial), so this is a defense against a *future* authoring
mistake, not a fix for a currently-triggered condition.

**AUTOMATED - DONE.** Full existing regression re-run one final time
after the fix: **15/15 dev-level + 50/50 campaign (65/65 total)**
solver-vs-runtime-replay all PASS, plus **10/10 tutorial-board
solvability** re-confirmed - zero Campaign regression from this pass.

**Android-specific review (code-level, done as part of this fix, per
the task's explicit request not to assume desktop/Android timing are
identical):**
- No `CanvasLayer` is used anywhere in `game.tscn` or
  `tutorial_panel.tscn` - the entire tutorial UI lives in the same
  `Control` tree as gameplay, so there is no cross-layer z-order/
  ordering risk to reason about.
- `TutorialPanel`'s root, `TutorialHighlight`, and the new
  `QADebugLabel` all set `mouse_filter = MOUSE_FILTER_IGNORE` (confirmed
  by direct read of `tutorial_panel.tscn`, `tutorial_highlight.gd`, and
  `game.tscn`), so none of them can ever intercept a tap meant for a
  tile or button underneath - the Continue button itself keeps its
  default `mouse_filter` (STOP) so it still receives taps normally.
- Touch-to-mouse emulation and viewport scaling are unaffected by this
  fix - both were already covered by `CLAUDE.md` 12a (mobile touch and
  desktop mouse share one input path by Godot default) and 12b (the
  `canvas_items`/`expand` stretch mode guarantee), and nothing in this
  fix changed input routing or layout math, only script attachment.
- Scene-ready timing: the crash happened inside `_ready()` itself,
  before any frame was drawn, so it was 100% deterministic and platform-
  independent (this explains why it reproduced identically in this
  project's Windows-hosted Godot editor/headless runs, not just on the
  user's Android device) - it was never a race condition that could
  differ by platform speed.

**Real-input dispatch (`_gui_input()`-driven mirror rotation) - scope
note, honestly disclosed:** a full T01 playthrough using synthetic
`InputEventMouseButton` dispatch (`Input.parse_input_event()` and
`get_viewport().push_input()`) was attempted in a real, non-headless
render, but did not successfully trigger `MirrorTile._gui_input()` in
that specific test harness (where `game.tscn` was instantiated as a
child of a helper/root node rather than becoming the tree's true
`current_scene` the way a real scene transition does). This is
**disclosed as a testing-methodology limitation, not treated as a
verified-working claim** - per `CLAUDE.md` 12a, a synthetic input event
is not proof of real tap behavior either way. What IS verified: the
accept/reject decision logic in `_on_orientable_tile_clicked()` was
already proven correct by direct method calls (D60's original test),
and `MirrorTile._gui_input()` is the exact same code path Campaign's
mirror tiles already use successfully on real, manually-approved
Android hardware (Stages 1-2). **Real on-device tapping remains a
MANUAL TEST REQUIRED item** - see the checklist below.

### Visual focus fix validation (`versionCode=20`, "1.6.2-TUTORIAL-VISUAL-FIX")

**Source check first, per `CLAUDE.md`'s "code is authoritative" rule -
AUTOMATED, DONE.** The commissioning brief for this fix was written as a
bug report against an assumed pre-existing dim/spotlight overlay.
`grep`-ing the whole project for `Dim`/`Fade`/`ColorRect`/`Overlay`
before writing any code found **no such overlay had ever existed** in
the Tutorial system - only two unrelated, pre-existing dims
(`pause_menu.tscn`, `tutorial_complete_popup.tscn`), neither touched by
`TutorialManager`/`GridManager`. The real, verifiable problem was
`TutorialHighlight`'s thin outline-only ring having too little contrast
against full-color gameplay art. See `DECISIONS.md` D62 for the full
discrepancy note and why the fix proceeds per the brief's own detailed
Goal/Part 2-9 specification anyway (a genuine, working board-dim-with-
cutout system is what actually resolves the underlying complaint).

**AUTOMATED - DONE.** A headless driver walked every step of all 10
tutorials (covering every tile type any tutorial highlights - mirror,
emitter, target, blocker, fixed mirror, splitter, filter, portal,
switch/gate, hazard) via direct `advance()` calls, asserting after each
step that `TutorialHighlight.visible`/`TutorialDimOverlay.visible`
exactly match whether that step has a `highlight_position`, that the
dim's cutout rect exactly equals the highlight's own rect (single
source of truth: both read `TutorialHighlight.FOCUS_PADDING`), and that
both are fully cleared after the tutorial's last step. Result:
**10/10 PASS, zero mismatches**, across every tutorial and every
highlighted tile type.

**RENDERED - DONE, with a technique note worth keeping.** The first
rendered-screenshot attempt opened in an unexpectedly wide/short desktop
window in this environment - neither `project.godot`'s declared
1080x1920 nor an explicit `--windowed --resolution 1080x1920` CLI flag
changed it (environment-specific windowing, not a project bug).
Eyeballing screen coordinates against the wrong assumed resolution
initially made the fix look like it wasn't doing anything. Fixed by
reading the *actual* logged geometry from the same run
(`grid.global_position`, `TutorialHighlight.global_position`/`size`,
`get_viewport().get_visible_rect().size`), scaling it against the saved
PNG's real pixel dimensions, and sampling/cropping exactly that region.
Once measured correctly: the highlighted tile's cutout center sampled
~2.5-3x brighter (pixel luminance) than a point immediately outside the
cutout on the same tile row, and a cropped/3x-zoomed screenshot visually
confirms a clearly brighter tile with a visible cyan-tinted ring against
darkened neighbors. A second screenshot during a Pause opened mid-
`REQUIRE_TILE_TAP` shows Pause's own panel rendered crisp with no
visible extra darkening (confirms the double-dim fix) and confirms
Pause now renders on top of the tutorial instruction panel (confirms the
z-order fix).

**AUTOMATED - DONE.** Direct-call assertions (matching the driver used
for D61's lifecycle test) confirmed: Pause opened during a dimmed
`REQUIRE_TILE_TAP` step correctly hides both the highlight and the dim
(`suspend_tutorial_focus()`) while `pause_menu.visible`/
`get_tree().paused` both become true; Resume correctly restores both
(`resume_tutorial_focus()`) and both flags return to false; the tutorial
step index is unchanged by the whole Pause/Resume cycle.

**AUTOMATED - DONE.** Full existing regression re-run after every
change: **15/15 dev-level + 50/50 campaign (65/65 total)** all PASS -
zero Campaign regression from this visual-only change.

**Real on-device tap-driven input dispatch** was not independently
re-verified this pass either, for the same disclosed testing-harness
reason as D61 (see the "Real-input dispatch" note above this section) -
this fix touches only highlight/dim/z-order presentation code, not
`_on_orientable_tile_clicked()`'s own accept/reject logic, so this
remains an inherited, not new, gap.

### Click input fix validation (`versionCode=21`, "1.6.3-TUTORIAL-INPUT-FIX")

**Correction to the note directly above**: D62 assumed its changes
"touch only highlight/dim/z-order presentation code, not
`_on_orientable_tile_clicked()`'s own accept/reject logic." That
assumption was too narrow - a presentation-layer bug (an oversized,
invisible-but-input-blocking panel) turned out to be exactly what
prevented `_on_orientable_tile_clicked()` from ever being reached at
all. Presentation-layer Controls that sit above the gameplay board are
not risk-free for input just because they don't touch gameplay logic.

**RENDERED - DONE, root cause found by runtime inspection, not
`.tscn` source (per the brief's explicit instruction).** A real,
non-headless session dumped live `mouse_filter`/`get_global_rect()`
values for every Control between the Viewport and the highlighted tile
at T01's `REQUIRE_TILE_TAP` step. `TutorialPanel` and its `Panel` child
both reported `rect=[P: (0,0), S: (1954,1920)]` - the full screen -
instead of the `.tscn`'s own declared ~220px bottom band, immediately
revealing `game.tscn`'s `TutorialPanel` instance node had redundantly
overridden the base scene's layout with `anchors_preset = 15`. A
point-in-rect hit-test search at the exact click position confirmed
`Panel` (default `mouse_filter = STOP`) was the topmost blocking
candidate before the fix. After removing the override: the same dump
showed the correct `rect=[P: (24,1660), S: (1906,220)]`, and the
hit-test candidate list at the same click position no longer included
either node.

**RENDERED, incidental but genuine - DONE.** During this same
investigation, real OS-level mouse input on the development machine
(not synthetically constructed by any test script - genuine
`InputEventMouseMotion`/`InputEventMouseButton` events with organic,
non-uniform positions/velocities) was observed reaching
`MirrorTile._gui_input()` and `GridManager._on_orientable_tile_clicked()`
at the correctly-restricted cell and being accepted. This is real,
if unplanned, end-to-end confirmation that a genuine click on the
correct tile now works through the fully fixed pipeline - distinct
from and stronger than a synthetic dispatch, though still not a
substitute for actual Android manual QA.

**Scripted synthetic dispatch - reconfirmed as a known harness
limitation, not a product bug.** `Input.parse_input_event()` and
`get_viewport().push_input()` were both retried (as they were in D61)
and neither reached `_gui_input()` in this test harness - reconfirmed
with a baseline test against a plain `Button` (`TutorialPanel`'s own
`ContinueButton`), which also never registered a scripted click. Since
even a stock `Button` doesn't respond to this harness's synthetic
dispatch, this is conclusively a harness limitation (`CLAUDE.md` 12a),
not evidence against the fix.

**AUTOMATED (bounded, real signal-chain) - DONE.** For every
`REQUIRE_TILE_TAP` step reached along each tutorial's natural forward
path (T01-T10, via `GridManager._on_orientable_tile_clicked()` called
directly on a live, fully-`_ready()`'d scene - not a bypass, since the
real `move_made`/`level_solved`/`step_changed` signal chain is what
actually drives every step transition): a tap on a cell adjacent to the
target is rejected without mutating any state, and a tap on the exact
target cell is accepted and the tutorial advances - **10/10 PASS**.
`highlight_position == target_position` also confirmed for every
`REQUIRE_TILE_TAP` step in every tutorial file, directly.

**A process note on test-driver stability, not a product issue:** an
earlier, more ambitious version of this validation driver (looping all
10 tutorials with extra manual `TutorialManager.advance()` calls on
non-`REQUIRE_TILE_TAP` steps) hung completely with zero output. A
minimal, single-tutorial, heavily-logged script isolated the safe
pattern: never manually call `advance()` past a
`WAIT_FOR_TARGET_ACTIVATION`/`WAIT_FOR_PUZZLE_SOLVED` step (let the
real signal chain do it, exactly as a real play session would), and
cap iterations as a safety net. See `DECISIONS.md` D63 for the full
note.

**Full existing regression re-run after every change - DONE:** 15/15
dev-level + 50/50 campaign (65/65 total), plus 10/10 tutorial-board
solvability - zero Campaign regression.

### Manual test checklist (Guided Tutorial Mode approval - nobody but the user can close this out)

**ANDROID MANUAL QA PENDING** for the D61 runtime fix, D62 visual fix,
and this D63 input fix together - none has been confirmed on a real
device yet. Install `versionCode=21` (`"1.6.3-TUTORIAL-INPUT-FIX"`)
and, critically, **open T01 from a completely fresh app launch first
(do NOT press Reset before checking)** - this is exactly the scenario
that failed on `versionCode=18`:

1. From Main Menu, confirm the new button order (CONTINUE, CAMPAIGN,
   TUTORIAL, SETTINGS) reads clearly and CAMPAIGN still opens the
   existing Level Select showing all 50 campaign levels unchanged.
2. Tap TUTORIAL - confirm Tutorial Select shows T01-T10, only T01
   unlocked on a fresh save, clearly distinguishable from Campaign
   Level Select (different header, `T0N` labels instead of plain
   numbers, no star rows).
3. Play T01-T10 **in order, for real**. For each:
   - Confirm the instruction panel's text is readable and doesn't cover
     the highlighted tile or the beam.
   - Confirm the board visibly dims around the highlighted tile while it
     stays bright, and this reads as an intentional spotlight, not a
     glitch - the dim should be moderate (board context still readable),
     not near-black.
   - Confirm the highlighted tile's cyan pulse ring is clearly visible
     against the dimmed background, without hiding the tile underneath.
   - Confirm the dim clears the instant the required action is taken
     (tap accepted / target activates) and never lingers into the next
     step or the completion popup.
   - During a dimmed step, open Pause: confirm the board does NOT go
     noticeably darker than Pause normally looks (no double-dim), and
     the Pause panel is fully visible on top of everything, including
     the tutorial instruction panel. Resume: confirm the highlight/dim
     come back exactly as they were.
   - Confirm tapping any tile OTHER than the one currently required
     does nothing (no rotation, no move counted, no visual glitch).
   - **Confirm tapping the correct/highlighted tile actually rotates
     it** and the beam updates immediately - this exact interaction
     failed silently on `versionCode=20` (the tile was visible but
     unresponsive), so this is the single most important check in this
     entire pass. If you tap the highlighted tile and nothing happens,
     stop and report it immediately with the QA debug overlay's
     `LAST TAP:`/`HIGHLIGHT:`/`ALLOWED:` line visible in your report.
   - **T03:** confirm tapping the fixed (locked-icon) mirror does
     nothing, and this reads as intentional, not broken.
   - **T04:** confirm the "not solved yet" message after the first
     target activates reads clearly, not confusingly.
   - **T05:** confirm it's clear the straight splitter branch activated
     on its own, before any input.
   - **T06/T07:** confirm colors and the filter tile are visually
     distinguishable from each other and from a plain target on a real
     screen.
   - **T08:** confirm the portal teleport reads as instant and clear,
     not like a bug.
   - **T09:** confirm the switch/gate/hazard relationship (crossing the
     switch opens the gate; touching the hazard would have failed the
     puzzle) reads clearly from the message text alone.
   - **T10:** confirm the reduced hand-holding still feels achievable
     using what was taught in T01-T09, not suddenly harder.
   - Confirm the completion popup ("LESSON COMPLETE" for T01-T09,
     "TUTORIAL COMPLETE" for T10) shows the right buttons (NEXT
     TUTORIAL / RETRY / TUTORIAL SELECT for T01-T09; CAMPAIGN / RETRY /
     TUTORIAL SELECT for T10) and each button navigates correctly.
4. Confirm Pause during a forced (`REQUIRE_TILE_TAP`/`MESSAGE`) step
   works safely - Resume returns to the exact same forced state, Restart
   Tutorial correctly resets to step 0 with a freshly-reloaded board,
   and neither ever softlocks.
5. Confirm the Android system Back button/gesture during a tutorial
   opens Pause (or resumes from Pause) exactly like Campaign, and never
   silently exits the app or skips a forced step.
6. Replay a completed tutorial from Tutorial Select - confirm replaying
   is allowed and works correctly (the brief explicitly requires this).
7. After completing several tutorials, confirm Campaign progress/stars/
   best-moves are completely unaffected, and vice versa - complete a
   Campaign level and confirm Tutorial progress is unaffected.
8. General sanity: Settings/Quit and all existing Campaign flows
   (Level Complete popup, Pause, Reset, Continue) still work exactly as
   before (unaffected by this pass).

Nothing about this pass may be marked "Android verified" until the user
installs this exact build (`versionCode=21`) and confirms it, same
standing rule as every prior build. **The Tutorial's manual QA history
so far**: `versionCode=18` FAILED on initial load/interaction
(`DECISIONS.md` D61, fixed at `versionCode=19`); a manual video QA at
`versionCode=19` found the visual/dim bugs fixed at `versionCode=20`
(`DECISIONS.md` D62); a further manual video QA at `versionCode=20`
found the highlighted tile couldn't actually be tapped, fixed at
`versionCode=21` (`DECISIONS.md` D63). This checklist is now the
Tutorial's *fourth* manual QA attempt - and the first time the specific
tap-interaction bug is expected to actually be gone. Stages 3, 4, and 5's
manual QA remain separately pending from before and should ideally be
confirmed together with the Tutorial in one device session.

## Campaign Difficulty Rework Pass 2 — Levels 21-45 replaced again (versionCode 23, "2.0.1-CAMPAIGN-DIFFICULTY-QA")

The `versionCode=22` reboot above was solver-valid but still too easy
in Levels 21-45 (see `DECISIONS.md` D65 for the full brief and
authoring-bug accounting). This pass replaces all 25 of Levels 21-45 a
second time. Levels 1-20, 46-50, and Tutorial T01-T10 are untouched by
this pass — their own checklists above still apply unchanged.

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean.
- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.analyze()`
  against all 25 redesigned levels (a temporary headless batch script,
  `godot --headless --path . --script <path>.gd`, per this project's
  standard throwaway-test-harness convention): 25/25 `status = SOLVABLE`,
  zero validator errors/warnings, every level's declared `optimal_moves`
  matches the solver's confirmed value exactly, every `possible_decoys`
  hit matches an intentional decoy named in that level's own
  `developer_notes`.
- **AUTOMATED — DONE.** Full campaign regression (the runtime-vs-solver
  replay technique — see the Milestone 4A.2 section above for the
  original script): **50/50 campaign solver PASS, 50/50 campaign
  runtime-replay PASS** (all 50 levels, not just the 25 redesigned
  ones — confirms zero regression to Levels 1-20/46-50).
- **AUTOMATED — DONE.** **15/15 dev-level solver+runtime-replay PASS**
  (unaffected — no simulation/engine code touched this pass, only level
  data).
- **AUTOMATED — DONE.** **10/10 tutorial-board solvability PASS**
  (`LevelSolver.analyze()` against all 10 T01-T10 boards — Tutorial
  untouched, confirmed via this same check both before and after this
  pass).
- **QA unlock-all confirmed still enabled** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`) — all 50 levels
  remain directly selectable regardless of save state.

### New optimal-move / states-explored curve (Levels 21-45)

| Levels | Optimal moves | States explored |
|---|---|---|
| 21-25 | 5, 6, 5, 6, 6 | 63, 127, 32, 127, 127 |
| 26-30 | 7, 8, 6, 7, 7 | 255, 256, 127, 255, 255 |
| 31-35 | 6, 7, 6, 5, 7 | 127, 128, 127, 32, 255 |
| 36-40 | 9, 9, 6, 9, 11 | 1023, 1023, 127, 1023, 4095 |
| 41-45 | 8, 9, 10, 7, 11 | 256, 1023, 2047, 128, 4095 |

For comparison, old Level 50 ("Paradox," unchanged) explores 255
states — Levels 36, 37, 39, 40, and 45 now exceed it, consistent with
the brief's explicit instruction that 36-45 should approach or exceed
Level 50's benchmark feel.

### Manual review checklist (device, not yet performed)

Install `versionCode=23` and play, in this order, paying attention to
whether the level requires real planning or falls to a few random taps:

- Levels 21, 23, 25 (first block — should already require pausing to
  study the board)
- Level 27 (single-beam 3-filter-order puzzle — confirm the "last
  filter wins" reasoning reads clearly, not just as an arbitrary color
  requirement)
- Level 30 (block finale — cross-branch dependency + 2 independent
  filter-color assignments)
- Levels 31, 33, 35 (very-hard block; 35 is the block finale)
- Level 36 (two independent emitters converging on one shared mirror —
  confirm this reads as "plan both before touching anything," not as
  two unrelated mini-puzzles)
- Level 38 (filter-order — confirm players don't assume the FIRST
  filter they see is the one that counts)
- Level 40 (expert-transition finale — should feel close to old Level
  50's quality)
- Levels 41, 42, 43, 44, 45 (expert block; 42 is deliberately a single
  long linear chain rather than a splitter puzzle, for shape variety;
  45 is the pre-46-50 bridge finale)
- Levels 46, 48, 50 (unchanged — confirm the transition from the new
  45 into these still feels like a coherent, escalating curve, not a
  sudden mechanical shift)

Record explicit feedback (too easy / about right / too hard, and
specifically whether any level fell to random tapping) before this
pass can be marked manually approved.

### Release checklist reminder (unchanged from prior passes)

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` **MUST be set to
`false`** before any final production release build — see
`DECISIONS.md` D58. Still `true` as of this pass, correctly, since
Android manual QA is still pending.

## Campaign Levels 51-60 — first post-reboot expansion past 50 (versionCode 24, "2.1.0-CAMPAIGN-60-QA")

The campaign now has 60 levels. Levels 51-60 (internal folder
`stage_06`) are new content, built under the same mechanic-agnostic,
no-difficulty-reset rule as Levels 21+ (see `DECISIONS.md` D66 for the
full brief and the two rejected drafts). Levels 1-50 and Tutorial
T01-T10 are untouched by this pass — their own checklists above still
apply unchanged.

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean.
- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.analyze()`
  against all 10 new levels: 10/10 `status = SOLVABLE`, zero validator
  errors/warnings, every level's declared `optimal_moves` matches the
  solver's confirmed value exactly, every `possible_decoys` hit matches
  an intentional decoy named in that level's own `developer_notes`
  (Level 51's one exception — a piece originally authored as a decoy
  turned out load-bearing, and the `developer_notes` were corrected to
  match, not the tiles).
- **AUTOMATED — DONE.** Full campaign regression (runtime-vs-solver
  replay): **60/60 campaign solver PASS, 60/60 campaign runtime-replay
  PASS** (all 60 levels, confirming zero regression to Levels 1-50).
- **AUTOMATED — DONE.** **15/15 dev-level solver+runtime-replay PASS**
  (unaffected — no simulation/engine code touched, only level data plus
  one array append in `LevelManager`).
- **AUTOMATED — DONE.** **10/10 tutorial-board solvability PASS**
  (Tutorial untouched, reconfirmed via the same check as every prior
  pass).
- **AUTOMATED — DONE.** Real-autoload verification (temporary
  `run/main_scene` swap to a throwaway driver scene, reverted
  immediately after): `LevelManager.get_campaign_level_count() == 60`;
  `get_campaign_level(60)` loads correctly (`display_name ==
  "Threshold of Reason"`); `get_campaign_level(61)` returns `null` with
  a graceful `push_warning`, no crash; `is_campaign_level_selectable(60)
  == true` and `(61) == false` under the QA-unlock flag;
  `SaveManager.campaign_highest_unlocked_level` confirmed untouched
  (real save progression unaffected by the new levels' mere existence).
- **QA unlock-all confirmed still enabled** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`) — all 60 levels
  directly selectable regardless of save state.

### New optimal-move / states-explored curve (Levels 51-60)

| # | Name | Optimal moves | States explored |
|---|---|---|---|
| 51 | Interlock | 10 | 1024 |
| 52 | Currents | 8 | 511 |
| 53 | Shared Line | 7 | 128 |
| 54 | Dual Transit | 11 | 4095 |
| 55 | Sequence Lock | 11 | 4095 |
| 56 | Shared Transit | 8 | 511 |
| 57 | Long Division | 9 | 1023 |
| 58 | Delayed Fault | 11 | 4095 |
| 59 | Near Convergence | 11 | 4095 |
| 60 | Threshold of Reason | 14 | 32767 |

Level 60 exceeds every prior level in the campaign by states explored
(old Level 50: 255; Difficulty Rework Pass 2's peak, Levels 40/45:
4095 each) — consistent with its role as the block's major milestone.

### Manual review checklist (device, not yet performed)

Install `versionCode=24` and play, comparing directly against Levels
45/48/50 to confirm Level 51 does NOT feel like a difficulty reset:

- Level 51 (mutual switch/gate — confirm both branches genuinely feel
  interdependent, not solvable one at a time)
- Level 53 (shared filter between two emitters — confirm the "why does
  this filter matter to BOTH emitters" reasoning reads clearly)
- Level 55 (mid-block checkpoint — should feel clearly harder than 52)
- Level 57 (single long linear chain, no splitter — confirm the shape
  variety reads as intentional, not simpler)
- Level 58 (delayed-consequence hazard — confirm the two-cell delay
  before the hazard reads as "I made a mistake a few steps back," not
  as an arbitrary/unfair placement)
- Level 59 (near-finale, two emitters through two portals)
- Level 60 (major milestone — should feel like the strongest puzzle in
  the campaign so far; compare directly against old Level 50)

Record explicit feedback (too easy / about right / too hard, whether
Level 51 feels like a continuation vs. a reset, and whether Level 60
lives up to "major milestone") before this pass can be marked manually
approved. **This is in addition to, not a replacement for, the still-
outstanding full manual review of Levels 21-50 from Difficulty Rework
Pass 2** — see that section above for its own checklist, still pending
beyond the informal "its good" sample.

### Release checklist reminder (unchanged from prior passes)

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` **MUST be set to
`false`** before any final production release build — see
`DECISIONS.md` D58. Still `true` as of this pass, correctly, since
Android manual QA is still pending.

## Campaign Levels 61-70 — advanced expert block, second expansion past 60 (versionCode 25, "2.2.0-CAMPAIGN-70-QA")

The campaign now has 70 levels. Levels 61-70 (internal folder
`stage_07`) are new "advanced expert" content, built under the same
mechanic-agnostic, no-difficulty-reset rule as every prior block (see
`DECISIONS.md` D67 for the full brief and the rejected draft). Levels
1-60 and Tutorial T01-T10 are untouched by this pass — their own
checklists above still apply unchanged.

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean.
- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.analyze()`
  against all 10 new levels: 10/10 `status = SOLVABLE`, zero validator
  errors/warnings, every level's declared `optimal_moves` matches the
  solver's confirmed value exactly (Level 68's corrected from a
  mis-counted 10 to the solver-confirmed 9 after a reflect-table
  hand-trace error was found), every `possible_decoys` hit matches an
  intentional decoy named in that level's own `developer_notes`.
- **AUTOMATED — DONE.** Full campaign regression (runtime-vs-solver
  replay): **70/70 campaign solver PASS, 70/70 campaign runtime-replay
  PASS** (all 70 levels, confirming zero regression to Levels 1-60).
- **AUTOMATED — DONE.** **15/15 dev-level solver+runtime-replay PASS**
  (unaffected — no simulation/engine code touched, only level data plus
  one array append in `LevelManager`).
- **AUTOMATED — DONE.** **10/10 tutorial-board solvability PASS**
  (Tutorial untouched, reconfirmed via the same check as every prior
  pass).
- **AUTOMATED — DONE.** Real-autoload verification (temporary
  `run/main_scene` swap to a throwaway driver scene, reverted
  immediately after): `LevelManager.get_campaign_level_count() == 70`;
  `get_campaign_level(70)` loads correctly (`display_name ==
  "Grand Convergence"`); `get_campaign_level(71)` returns `null` with a
  graceful `push_warning`, no crash; `is_campaign_level_selectable(70)
  == true` and `(71) == false` under the QA-unlock flag;
  `SaveManager.campaign_highest_unlocked_level` confirmed untouched.
- **QA unlock-all confirmed still enabled** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`) — all 70 levels
  directly selectable regardless of save state.

### New optimal-move / states-explored curve (Levels 61-70)

| # | Name | Optimal moves | States explored |
|---|---|---|---|
| 61 | Peripheral | 10 | 2047 |
| 62 | Longcut | 10 | 2047 |
| 63 | Invalidation | 10 | 2047 |
| 64 | Twin Anchor | 10 | 2047 |
| 65 | Convergence Point | 12 | 8191 |
| 66 | Portal Trap | 7 | 128 |
| 67 | Chain Reaction | 11 | 4095 |
| 68 | Twin Corridor | 9 | 2036 |
| 69 | Color Conflict | 12 | 8191 |
| 70 | Grand Convergence | 11 | 4095 |

Level 65 and 69 both explore 8191 states — the highest in this block,
appropriately positioned at the "Master-entry checkpoint" and
"Master+" tiers. Level 70's sophistication comes from its two-stage
relay dependency, not from state count (4095, below Level 65/69's
peak, and well below Level 60's own 32767) — deliberately, per the
brief's explicit instruction not to chase state counts for their own
sake.

### Manual review checklist (device, not yet performed)

Install `versionCode=25` and play, comparing directly against Levels
55/58/60 to confirm Level 61 does NOT feel like a difficulty reset:

- Level 61 (the visually-closer branch is a red herring — confirm
  players don't waste time solving it first thinking it's "step one")
- Level 63 (always-open gate removed after a rejected draft — confirm
  the wrong-color decoy target reads as a fair trap, not a bug)
- Level 65 (master-entry checkpoint — target continuation trips a
  switch; confirm players eventually notice the beam's job isn't over)
- Level 67 (two independent 2-filter-order chains sharing one fixed
  mirror — confirm both color puzzles read as genuinely independent)
- Level 68 (single gate cell crossed by two emitters — confirm this
  reads as one shared resource, not two coincidentally-adjacent gates)
- Level 69 (master+ tier — two independent filter-order puzzles gated
  behind one switch)
- Level 70 (major milestone — the two-stage relay should feel like a
  genuinely different kind of dependency than Level 60's single-
  direction gating; compare directly against Level 60)

Record explicit feedback (too easy / about right / too hard, whether
Level 61 feels like a continuation vs. a reset, and whether Level 70
feels more sophisticated than Level 60 rather than merely larger)
before this pass can be marked manually approved. **This is in
addition to, not a replacement for, the still-outstanding full manual
review of Levels 21-60** — see the "Campaign Difficulty Rework Pass 2"
and "Campaign Levels 51-60" sections above for their own checklists,
still pending beyond the informal "its good" sample.

### Release checklist reminder (unchanged from prior passes)

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` **MUST be set to
`false`** before any final production release build — see
`DECISIONS.md` D58. Still `true` as of this pass, correctly, since
Android manual QA is still pending.

## Campaign Levels 71-80 — MASTER/MASTER+/EXTREME block, third expansion past 70 (versionCode 26, "2.3.0-CAMPAIGN-80-QA")

The campaign now has 80 levels. Levels 71-80 (internal folder
`stage_08`) are new MASTER/MASTER+/EXTREME tier content, built under the
same mechanic-agnostic, no-difficulty-reset rule as every prior block
(see `DECISIONS.md` D68 for the full brief, the rejected draft, and the
mid-design correction). Levels 1-70 and Tutorial T01-T10 are untouched
by this pass — their own checklists above still apply unchanged.
**Levels 1-50 are now user-tested on a real device and reported good —
that manual review is DONE for 1-50; Levels 51-70's manual review is
still the separately-outstanding item from the prior two sections.**

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean
  (implicit in the solver/validator runs below completing without
  import errors).
- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.analyze()`
  against all 10 new levels: 10/10 `status = SOLVABLE`, zero validator
  errors/warnings, `shortest_solution_count = 1` throughout, every
  level's declared `optimal_moves` matches the solver's confirmed value
  exactly (Level 79's corrected from an intended-but-wrong 12 to the
  solver-confirmed 13 after an entry mirror's authored orientation
  turned out to already be correct), every `possible_decoys` hit
  matches an intentional decoy named in that level's own
  `developer_notes`.
- **AUTOMATED — DONE.** Full campaign regression (runtime-vs-solver
  replay): **80/80 campaign solver PASS, 80/80 campaign runtime-replay
  PASS** (all 80 levels, confirming zero regression to Levels 1-70).
- **AUTOMATED — DONE.** **15/15 dev-level solver+runtime-replay PASS**
  (unaffected — no simulation/engine code touched, only level data plus
  one array append in `LevelManager`).
- **AUTOMATED — DONE.** **10/10 tutorial-board solvability PASS**
  (Tutorial untouched, reconfirmed via the same check as every prior
  pass).
- **AUTOMATED — DONE.** Real-autoload verification (temporary
  `run/main_scene` swap to a throwaway driver scene, reverted
  immediately after): `LevelManager.get_campaign_level_count() == 80`;
  `get_campaign_level(80)` loads correctly (`display_name == "Full
  Convergence"`); `get_campaign_level(81)` returns `null` with a
  graceful `push_warning`, no crash; `is_campaign_level_selectable(80)
  == true` and `(81) == false` under the QA-unlock flag;
  `SaveManager.campaign_highest_unlocked_level` confirmed untouched.
- **QA unlock-all confirmed still enabled** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`) — all 80 levels
  directly selectable regardless of save state.

### New optimal-move / states-explored curve (Levels 71-80)

| # | Name | Optimal moves | States explored |
|---|---|---|---|
| 71 | Deliberate Detour | 11 | 4095 |
| 72 | Locked Corridor | 9 | 2036 |
| 73 | Locked Splitter | 11 | 4095 |
| 74 | Twin Portals | 8 | 511 |
| 75 | Convergence Reaction | 13 | 16383 |
| 76 | Reverse Relay | 11 | 4095 |
| 77 | Distant Splitter | 12 | 8191 |
| 78 | Distant Corridor | 12 | 16369 |
| 79 | Silent Third | 13 | 32752 |
| 80 | Full Convergence | 14 | 65519 |

Level 80's 65519 states is the highest ever explored in this project —
deliberately at the practical ceiling of `LevelSolver.DEFAULT_MAX_STATES`
(65536), since Level 80 has 16 independently-rotatable pieces (2^16 =
65536 possible states). The solver still returned a definitive
`SOLVABLE`, not `UNKNOWN`. Do not add further rotatable pieces to Level
80 without first re-confirming the search still terminates definitively
— see `DECISIONS.md` D68.

### Manual review checklist (device, not yet performed)

Install `versionCode=26` and play, comparing directly against Levels
65/69/70 to confirm Level 71 does NOT feel like a difficulty reset:

- Level 71 (splitter + mandatory portal feeding a switch that gates the
  reflected branch — confirm the portal reads as a real routing
  decision, not a throwaway detour)
- Level 73 (a splitter's two branches gate EACH OTHER, deepened with a
  2-filter-order chain per branch — confirm both color puzzles read as
  genuinely independent until the mutual-gate dependency clicks)
- Level 75 (major mid-block checkpoint — confirm this reads as
  genuinely more sophisticated than the 61-70 block's average, not
  merely a larger grid)
- Level 77 (Level 73's mutual-gate core plus a portal jump into a
  totally separate board region — confirm players can trace the jump
  without feeling like the portal exit is arbitrary)
- Level 78 (Level 72's shared-gate core plus a 3-mirror portal tail in
  an expanded corner — confirm the extra bounces read as a real
  decision sequence, not padding)
- Level 79 (EXTREME entry — a completely separate third emitter opens
  one more gate; confirm players notice it exists and don't dismiss it
  as decorative)
- Level 80 (MAJOR MILESTONE — four independently-opened gates converge
  on one target, and the "independent" third emitter turns out to be
  coupled to the straight branch's own switch; confirm this reads as a
  genuinely deeper convergence than Level 70's two-stage relay, not
  merely a bigger version of it)

Record explicit feedback (too easy / about right / too hard, whether
Level 71 feels like a continuation vs. a reset, and whether Level 80
feels more sophisticated than Level 70 rather than merely larger)
before this pass can be marked manually approved. **This is in
addition to, not a replacement for, the still-outstanding full manual
review of Levels 51-70** — see the "Campaign Levels 51-60" and
"Campaign Levels 61-70" sections above for their own checklists.
**Levels 1-50 are the one population with a completed manual review —
the user played them on a real device and reported they are good.**

### Release checklist reminder (unchanged from prior passes)

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` **MUST be set to
`false`** before any final production release build — see
`DECISIONS.md` D58. Still `true` as of this pass, correctly, since
Android manual QA is still pending.

## Campaign Levels 81-90 — EXTREME/EXTREME+ block, fourth expansion past 80 (versionCode 27, "2.4.0-CAMPAIGN-90-QA")

The campaign now has 90 levels. Levels 81-90 (internal folder
`stage_09`) are new EXTREME/EXTREME+ tier content, built under the same
mechanic-agnostic, no-difficulty-reset rule as every prior block (see
`DECISIONS.md` D69 for the full brief, the rejected draft, and the
mid-design correction). Levels 1-80 and Tutorial T01-T10 are untouched
by this pass — their own checklists above still apply unchanged.
**Levels 1-50's manual review is DONE (user-tested, reported good);
Levels 51-80's manual review is still the separately-outstanding item
from the prior three sections.**

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean
  (implicit in the solver/validator runs below completing without
  import errors).
- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.analyze()`
  against all 10 new levels: 10/10 `status = SOLVABLE`, zero validator
  errors/warnings, `shortest_solution_count = 1` throughout, every
  level's declared `optimal_moves` matches the solver's confirmed value
  exactly (Level 89's corrected after a target-placement error produced
  an UNSOLVABLE first draft), every `possible_decoys` hit matches an
  intentional decoy named in that level's own `developer_notes`.
- **AUTOMATED — DONE.** Full campaign regression (runtime-vs-solver
  replay): **90/90 campaign solver PASS, 90/90 campaign runtime-replay
  PASS** (all 90 levels, confirming zero regression to Levels 1-80).
- **AUTOMATED — DONE.** **15/15 dev-level solver+runtime-replay PASS**
  (unaffected — no simulation/engine code touched, only level data plus
  one array append in `LevelManager`).
- **AUTOMATED — DONE.** **10/10 tutorial-board solvability PASS**
  (Tutorial untouched, reconfirmed via the same check as every prior
  pass).
- **AUTOMATED — DONE.** Real-autoload verification (temporary
  `run/main_scene` swap to a throwaway driver scene, reverted
  immediately after): `LevelManager.get_campaign_level_count() == 90`;
  `get_campaign_level(90)` loads correctly (`display_name == "Full
  Circuit"`); `get_campaign_level(91)` returns `null` with a graceful
  `push_warning`, no crash; `is_campaign_level_selectable(90) == true`
  and `(91) == false` under the QA-unlock flag; `SaveManager.
  campaign_highest_unlocked_level` confirmed untouched.
- **QA unlock-all confirmed still enabled** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`) — all 90 levels
  directly selectable regardless of save state.

### New mechanic: the three-stage relay (Levels 87-90)

Levels 70/76/84 each proved a two-stage switch/gate relay between two
emitters (emitter 1's switch opens emitter 2's gate; emitter 2's switch
opens emitter 1's gate). Level 87 extends this to a genuine three-stage
forward chain across three emitters: emitter 1's unconditionally-
reachable switch opens emitter 2's early gate; only then can emitter 2
reach its own switch, opening emitter 3's early gate; only then can
emitter 3 reach its own switch, opening the final gate on emitter 1's
own tail. This resolves automatically over 4 `simulate_until_stable()`
passes — the exact same multi-pass gate/switch resolution the engine
already used for two-stage relays, generalizing to N stages with zero
new code. Levels 88-90 build on this core (double portals, a fourth
independent converging emitter, and a fifth symmetric one).

### New optimal-move / states-explored curve (Levels 81-90)

| # | Name | Optimal moves | States explored |
|---|---|---|---|
| 81 | Third Signal | 12 | 8191 |
| 82 | Crossed Corridors | 11 | 4095 |
| 83 | Silent Detour | 11 | 8178 |
| 84 | Distant Relay | 12 | 8191 |
| 85 | Convergence Threshold | 14 | 32767 |
| 86 | Reciprocal Corridor | 12 | 16369 |
| 87 | Triple Relay | 10 | 2047 |
| 88 | Distant Triple Relay | 12 | 8191 |
| 89 | Fourfold Relay | 13 | 16383 |
| 90 | Full Circuit | 13 | 16383 |

Level 87's 10 moves and relatively low 2047 states reflect that the
three-stage relay's difficulty comes from a genuinely new *kind* of
dependency (a three-way forward chain), not from raw move count or
state count — the same principle Level 70 established for the original
two-stage relay, deliberately not chased here either.

### Manual review checklist (device, not yet performed)

Install `versionCode=27` and play, comparing directly against Levels
75/79/80 to confirm Level 81 does NOT feel like a difficulty reset:

- Level 81 (emitter 2's route needs both emitter 1's delayed
  post-target continuation AND a separate third emitter's gate —
  confirm both dependencies read as real, not redundant)
- Level 83 (Level 71's splitter/portal/shared-mirror core extended with
  a third emitter gating the portal corridor — confirm the added
  dependency doesn't feel bolted-on)
- Level 85 (major checkpoint — confirm this reads as genuinely more
  sophisticated than the 71-80 block's average)
- Level 87 (THE FIRST three-stage relay — confirm players can trace a
  three-emitter chain reaction, not just a two-emitter one; this is a
  new mechanic shape, worth extra attention)
- Level 88 (the three-stage relay extended with two separate portal
  jumps — confirm both jumps read as real routing decisions)
- Level 89 (a fourth, independent emitter converges onto the relay —
  confirm players notice it and don't dismiss it as decorative)
- Level 90 (MAJOR MILESTONE — five emitters, the three-stage relay, two
  portals, and two symmetric converging gates; confirm this reads as a
  genuinely deeper puzzle than Level 80, not merely a bigger one)

Record explicit feedback (too easy / about right / too hard, whether
Level 81 feels like a continuation vs. a reset, whether the three-stage
relay in Levels 87-90 reads as meaningfully different from the
two-stage relay in Levels 70/76/84, and whether Level 90 feels more
sophisticated than Level 80 rather than merely larger) before this pass
can be marked manually approved. **This is in addition to, not a
replacement for, the still-outstanding full manual review of Levels
51-80** — see the "Campaign Levels 51-60", "Campaign Levels 61-70", and
"Campaign Levels 71-80" sections above for their own checklists.
**Levels 1-50 are the one population with a completed manual review —
the user played them on a real device and reported they are good.**

### Release checklist reminder (unchanged from prior passes)

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` **MUST be set to
`false`** before any final production release build — see
`DECISIONS.md` D58. Still `true` as of this pass, correctly, since
Android manual QA is still pending.

## Campaign Levels 91-100 — final campaign block, completing the 100-level campaign (versionCode 28, "2.5.0-CAMPAIGN-100-QA")

The campaign now has 100 levels — **the full, originally-planned
structure is complete.** Levels 91-100 (internal folder `stage_10`) are
new MASTER+/EXTREME/FINAL CHALLENGE tier content, built under the same
mechanic-agnostic, no-difficulty-reset rule as every prior block (see
`DECISIONS.md` D70 for the full brief and the significant rejected
draft). Levels 1-90 and Tutorial T01-T10 are untouched by this pass —
their own checklists above still apply unchanged. **Levels 1-50's
manual review is DONE (user-tested, reported good); Levels 51-90's
manual review is still the separately-outstanding item from the prior
four sections.**

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean
  (implicit in the solver/validator runs below completing without
  import errors).
- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.analyze()`
  against all 10 new levels: 10/10 `status = SOLVABLE`, zero validator
  errors, `shortest_solution_count = 1` throughout, every level's
  declared `optimal_moves` matches the solver's confirmed value exactly
  (Level 100's corrected after a first draft's circular gate dependency
  produced an UNSOLVABLE result), every `possible_decoys` hit matches an
  intentional decoy named in that level's own `developer_notes`. Level
  100 carries one non-blocking validator WARNING ("44→42 tiles, a lot -
  consider whether it could be simplified") — warnings never block Save
  or Playtest per `CLAUDE.md`'s level-editor rules, and this one is a
  deliberate, examined tradeoff (see `DECISIONS.md` D70) rather than an
  oversight.
- **AUTOMATED — DONE.** Full campaign regression (runtime-vs-solver
  replay): **100/100 campaign solver PASS, 100/100 campaign
  runtime-replay PASS** (all 100 levels, confirming zero regression to
  Levels 1-90).
- **AUTOMATED — DONE.** **15/15 dev-level solver+runtime-replay PASS**
  (unaffected — no simulation/engine code touched, only level data plus
  one array append in `LevelManager`).
- **AUTOMATED — DONE.** **10/10 tutorial-board solvability PASS**
  (Tutorial untouched, reconfirmed via the same check as every prior
  pass).
- **AUTOMATED — DONE.** Real-autoload verification (temporary
  `run/main_scene` swap to a throwaway driver scene, reverted
  immediately after): `LevelManager.get_campaign_level_count() == 100`;
  `get_campaign_level(100)` loads correctly (`display_name ==
  "Culmination"`); `get_campaign_level(101)` returns `null` with a
  graceful `push_warning`, no crash; `is_campaign_level_selectable(100)
  == true` and `(101) == false` under the QA-unlock flag;
  `SaveManager.campaign_highest_unlocked_level` confirmed untouched.
- **AUTOMATED — DONE. Campaign completion behavior (Parts 29/33 of the
  brief this block was built under):** confirmed `100 <
  LevelManager.get_campaign_level_count()` (the exact expression
  `game.gd` uses to compute `has_next`) evaluates to `false` for Level
  100. `LevelCompletePopup.show_result()`'s pre-existing `_next_button.
  visible = has_next_level` line therefore already hides the Next Level
  button correctly for Level 100, with the Retry and Level Select
  buttons still available — the exact same generic mechanism that
  already handled Level 90 (and Level 10, 20, ... before it) as "the
  last level." No code changes were needed and none were made. No
  dedicated "Campaign Complete" celebration screen exists or was built
  in this pass — deferred to a future milestone only if requested.
- **QA unlock-all confirmed still enabled** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`) — all 100 levels
  directly selectable regardless of save state. **This MUST be set to
  `false` before any final production release build** — see
  `DECISIONS.md` D58's release checklist, now more urgent since campaign
  content is complete.

### New mechanics: backward-reasoning fixed mirrors, and a shared-state chain

Levels 91/95/98/100 use a genuinely non-rotatable fixed mirror
specifically to teach backward reasoning (distinct from the campaign's
earlier shared-branch convergence fixed mirrors, which were load-bearing
convergence points rather than backward-reasoning puzzles in their own
right) — the player must reason backward from a target's position
through the fixed mirror's one possible output to deduce the correct
orientation of a rotatable mirror upstream of it. Level 96 introduces a
genuine shared-state chain where a target's own activation is explicitly
just a waypoint: emitter B's beam reaches its own target, continues past
it (targets do not stop beams), and only then trips the switch that
unlocks emitter C — directly matching the brief's own Part 9 example.

### New optimal-move / states-explored curve (Levels 91-100)

| # | Name | Optimal moves | States explored |
|---|---|---|---|
| 91 | Inferred Convergence | 13 | 16383 |
| 92 | Delayed Verdict | 13 | 16383 |
| 93 | Pre-Split Signal | 11 | 4095 |
| 94 | Traced Colors | 11 | 8178 |
| 95 | Final Threshold | 15 | 65535 |
| 96 | Chain of Custody | 12 | 8191 |
| 97 | Triple Verdict | 14 | 32767 |
| 98 | Triple Inference | 14 | 32767 |
| 99 | Penultimate Verdict | 14 | 32767 |
| 100 | Culmination | 13 | 16383 |

Level 95's 65535 states is the second time this project has reached the
practical ceiling of `LevelSolver.DEFAULT_MAX_STATES` (65536) — Level
95 independently has 16 rotatable pieces (1 splitter + 15 mirrors),
exactly like Level 80 before it. The solver still returned a definitive
`SOLVABLE`, not `UNKNOWN`. Do not add further rotatable pieces to Level
95 without first re-confirming the search still terminates definitively.

### Manual review checklist (device, not yet performed)

Install `versionCode=28` and play, comparing directly against Levels
85/89/90 to confirm Level 91 does NOT feel like a difficulty reset:

- Level 91 (backward reasoning through a non-rotatable fixed mirror —
  confirm players can actually work backward from the target rather
  than treating every mirror as a free guess)
- Level 93 (a filter placed BEFORE the splitter — confirm the "does the
  upstream color survive or get overwritten" reasoning reads clearly
  per branch, not as an arbitrary trick)
- Level 95 (FINAL-EXAM CHECKPOINT — confirm this genuinely feels like
  "I am in the final exam now" compared to the 81-90 block's average)
- Level 97 (GLOBAL DEPENDENCY — confirm players can trace that three
  seemingly-unrelated beam sources all depend on the exact same one
  late gate)
- Level 98 (backward reasoning + color/order logic — confirm the 5-link
  backward chain is traceable, not overwhelming)
- Level 99 (PENULTIMATE CHALLENGE — confirm the near-solution quality
  reads fairly: two of three targets sharing a late gate should feel
  like a genuine "almost there" moment, not a trick)
- Level 100 (THE DEFINITIVE FINAL PUZZLE — confirm this feels like a
  true culmination of everything learned across the whole campaign,
  and specifically confirm the 42-tile board reads as "everything
  matters," not "overloaded" — this is the single most important
  subjective judgment call in this entire review)

Record explicit feedback (too easy / about right / too hard, whether
Level 91 feels like a continuation vs. a reset, whether the backward-
reasoning fixed mirrors and the shared-state chain read as genuinely
new techniques, and above all whether Level 100 successfully feels like
the definitive final campaign puzzle rather than merely a bigger Level
90) before this pass can be marked manually approved. **This is in
addition to, not a replacement for, the still-outstanding full manual
review of Levels 51-90** — see the "Campaign Levels 51-60", "Campaign
Levels 61-70", "Campaign Levels 71-80", and "Campaign Levels 81-90"
sections above for their own checklists. **Levels 1-50 are the one
population with a completed manual review — the user played them on a
real device and reported they are good.**

### Release checklist reminder (now more urgent — campaign content is complete)

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` **MUST be set to
`false`** before any final production release build — see
`DECISIONS.md` D58. Still `true` as of this pass, correctly, since
Android manual QA is still pending. With all 100 campaign levels now
implemented, this flag is the single most important thing to remember
to flip before any real release build - there is no more campaign
content coming to distract from it.


## UI Background Refresh V2 + Laser → Mirror Impact VFX (versionCode 29, "2.6.0-UI-VFX-QA")

Visual-only pass (D71); the point of this section is proving gameplay did
not change and recording exactly which tier each visual claim was checked
at (D47 vocabulary: AUTOMATED / RENDERED / MANUAL). Tooling: Godot 4.7.1
at `D:\Godot_v4.7.1-stable_win64.exe`; throwaway drivers lived in a
temporary `_qa_tmp/` folder under the project root (deleted afterwards —
they must not exist at export time, `export_filter="all_resources"`) run
as `godot --path . --resolution WxH res://_qa_tmp/<driver>.tscn` (no
`--headless`), saving `get_viewport().get_texture().get_image()` PNGs.
Back up `user://savegame.json` before any driver that could solve a
level/tutorial (a rendered T01 run reaches the solved state); the
gameplay-VFX driver used `GameManager.is_editor_playtest = true`, which
never writes `SaveManager`.

### Background integration
- **AUTOMATED — DONE.** All three V2 PNGs exist in
  `assets/ui/backgrounds/` and imported (`.import` files generated by
  `godot --headless --path . --import`, zero errors).
- **RENDERED — DONE.** Main Menu, Campaign Select and Tutorial Select
  screenshots at 540×960 (9:16) — art fills the screen, no borders, no
  distortion — and at a taller ~1080×2387 logical aspect (~20:9: covered,
  side edges trimmed, no stretch). Before/after comparison against the old
  backgrounds (temporary runtime texture swap) confirmed the Main Menu
  `Logo` not drawing and the small Back button are pre-existing, not
  regressions. Titles, Back, level tiles/numbers, T01–T10 tiles and stars,
  and Main Menu buttons all readable with the scrim; no UI hidden behind
  the background; scrim doesn't sit above UI.
- **MANUAL TEST REQUIRED.** Real-phone look at all three screens (esp. the
  Campaign Select tile grid over the top-right planet glow, and how much
  side-panel art a 20:9 phone crops).

### Mirror impact VFX
- **RENDERED — DONE.** Frame timeline of a 3-reflection board (two
  rotatable mirrors + one fixed mirror) after a tap: bursts appear exactly
  on the three mirror cells, flash → ring → sparks (sprayed along the
  reflected direction) → gone by ~0.3 s; mirror orientation, beam and
  neighbours remain legible. Four-color sheet (WHITE/BLUE/RED/GREEN)
  shows per-color tinting with a white core. Tutorial T01 after the
  forced tap (dim overlay + burst at the mirror) looks correct.
- **AUTOMATED — DONE (duplicate/leak).** During the timeline: max 3 FX
  nodes for 3 reflections (no duplicates); 60 taps at 30 ms intervals:
  peak 3 FX nodes, **0** after 0.7 s, total `get_tree().get_node_count()`
  120 before and after (no growth).
- **RENDERED/real-input — DONE (input).** With `Input.parse_input_event`
  (window `get_final_transform()` applied to logical coordinates — the
  first attempt passed logical coords and did nothing, a driver bug not a
  game bug), a click rotated a mirror and a second click ~50 ms later —
  while 3 bursts were alive on that very mirror — rotated it back. FX
  hold no `Control` children; `ImpactFX.mouse_filter == IGNORE`.
- **AUTOMATED — DONE (placement).** During the full regression below,
  after every replayed solver tap across all 125 levels, each spawned
  burst's cell was checked against the level's `MIRROR` tiles:
  **5,291 bursts, 0 off-mirror** (so none ever landed on a splitter or any
  other tile, splitter-containing levels included).
- **Tutorial T01 interaction/startup — DONE (RENDERED/real input).**
  Real `game.tscn` in tutorial mode: step 0 input locked; after
  Continue-ing to the `REQUIRE_TILE_TAP` step, `interaction_restricted_to
  == (2,2)`; a real click on the mirror was accepted and solved T01
  (1 burst, as expected).
- **MANUAL TEST REQUIRED.** Feel/subtlety on a real phone: is the burst
  clear but not distracting at real cell sizes on many-mirror levels
  (e.g. Level 90/100) and during rapid tapping? Frame-rate on a
  mid/low-end Android device.

### Regression (identical to the previous build — gameplay untouched)
Same `full_regression.gd` technique as previous passes (per set:
`LevelValidator` + `LevelSolver.analyze` SOLVABLE, then solver solution
replayed through a real `GridManager` via `_on_orientable_tile_clicked()`
must reach `is_solved`), plus the FX-placement assertion above:
- **AUTOMATED — DONE.** DEV **15/15** solver PASS, **15/15** runtime PASS.
- **AUTOMATED — DONE.** CAMPAIGN **100/100** solver PASS, **100/100**
  runtime PASS.
- **AUTOMATED — DONE.** TUTORIAL **10/10** board solver + runtime PASS.
- **AUTOMATED — DONE.** `godot --headless --path . --import` clean after
  every change (no `SCRIPT ERROR`/parse errors).
- `project.godot` byte-identical to its pre-task backup afterwards
  (`run/main_scene` untouched; the drivers were launched by scene path,
  no temporary main-scene swap was needed this time).

### Android export
- **AUTOMATED — DONE.** `godot --headless --export-debug "Android Debug"
  builds/android/beamshift-debug.apk` succeeded and signed (debug
  keystore). `aapt2 dump badging`: package `com.beamshift.game`,
  `versionCode='29'`, `versionName='2.6.0-UI-VFX-QA'`. Size 54,384,898
  bytes (≈51.9 MiB; previous 51,299,930). APK contains the three V2
  background `.ctex`s, `laser_mirror_impact_fx` script + scene; does
  **not** contain the two superseded backgrounds. (`aapt2` also prints a
  harmless `themed_icon` resource warning, not from this change.)

### MANUAL ANDROID VISUAL QA CHECKLIST (install `versionCode=29`)
1. Main Menu: background fills the screen, buttons (esp. dim CONTINUE) and
   QUIT clearly separated from the floor; no stray logo/plaque overlap.
2. Campaign Select: scroll through Levels 1–100 — numbers, locks, stars and
   tile frames never merge with the background; Back and title readable.
3. Tutorial Select: T01–T10 tiles, locks and stars readable; Back readable.
4. Try a tall phone (≥ 20:9) and a shorter one (e.g. 16:9): no borders,
   nothing distorted.
5. Gameplay: tap a mirror on a 1-mirror level — one small burst at the
   mirror, beam color-matched; not blocking the next tap.
6. Multi-mirror level (e.g. 60+): every reflection bursts together, calm not
   noisy; fixed (locked) mirrors also burst when hit.
7. Colored-beam and filter levels: burst color matches the beam drawn.
8. Mash a mirror: no lag, no leftover sparks, no stuck rings.
9. Reset and re-enter levels: no bursts on load/Reset (intended);
   Tutorial T01–T10 forced-tap steps still work with the dim overlay.
10. Confirm `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` is still on (all 100
    levels selectable) — expected for this QA build.

## Rectangular Grid Architecture — Phase 1 (2026-09-22)

Engine/layout pass — see `DECISIONS.md` D72 and `ARCHITECTURE.md`
"Rectangular grid layout" for the full writeup. Zero level content
changed; only `GridManager._recalculate_layout()` plus two new dev-only
diagnostic methods.

### Audit for square-grid assumptions
- **AUTOMATED — DONE.** Grepped `grid_width`/`grid_height` usage across
  `scripts/` and `tools/`: `LaserSystem` (bounds check, per-axis),
  `LevelData` (field declarations), `LevelMetrics` (area-based "large
  grid" warning, not square-only), `LevelValidator`
  (`MAX_SANE_GRID_DIMENSION`, per-axis), `level_editor.gd` (GridContainer
  columns/rows, already row/column-correct). Read `TileVisual.cell_size`'s
  setter and every tile script's `_draw()`/`_on_cell_size_changed()`,
  `TutorialHighlight`, `TutorialDimOverlay`, `LaserMirrorImpactFX`: all
  already consume a single `cell_size` scalar + a `Rect2`/position,
  generic to any grid shape. Found exactly one square-grid assumption:
  `GridManager._recalculate_layout()`'s
  `cell_size = floor(min(size.x,size.y) / max(grid_width,grid_height))`.

### Layout formula fix
- **AUTOMATED — DONE.** Replaced with
  `cell_size = floor(min(available.x/columns, available.y/rows))`,
  `available = size - GRID_SAFETY_MARGIN*2` (new constant, 8px @
  1080-wide reference, symmetric on all 4 sides). Grid still centered in
  the full rect afterward. New `GridManager.get_layout_metrics()` /
  `format_layout_diagnostics()` (dev-only).

### Solver-vs-runtime-replay regression (dev + campaign + tutorial + new rectangular fixtures)
Technique: solver-vs-declared + the runtime-vs-solver replay technique
(see above in this file) via a temporary headless script
(`godot --headless --path . --script <script>.gd`, no autoloads needed —
`GridManager` has none), across all 125 existing levels (15 dev + 100
campaign + 10 tutorial) plus the 5 new fixtures below:
- **AUTOMATED — DONE.** DEV **15/15** PASS. CAMPAIGN **100/100** PASS.
  RECT-FIXTURE **5/5** PASS (`is_solved == true` for every one).
- TUTORIAL: all **10/10** boards reach `is_solved == true` (genuinely
  solvable, unchanged) — 4 of them (T02/T04/T07/T10) have a declared
  `optimal_moves` that doesn't match the solver's own count. This is a
  **pre-existing, unrelated condition** (tutorials aren't move-scored —
  no `tutorial_best_moves_per_level` field exists — and this pass never
  touched `levels/tutorial/`), not a regression from this pass; recorded
  in `DECISIONS.md` D72 so a future session doesn't misattribute it.

### Temporary rectangular layout fixtures
- **AUTOMATED — DONE.** 5 fixtures added under `levels/editor_fixtures/`
  (`fixture_rect_5x8.gd`, `_6x10.gd`, `_7x11.gd`, `_8x12.gd`,
  `_9x10.gd`), following the existing 6-fixture convention (`level_id =
  -1`, never in `LevelManager.LEVEL_PATHS`/`CAMPAIGN_LEVEL_PATHS`/
  `TUTORIAL_LEVEL_PATHS`, export-excluded). Each: emitter at one corner,
  one rotatable mirror at the far end of the top row (authored in the
  wrong orientation — a real 1-move puzzle), target at the opposite
  corner — the beam crosses the board's full width then full height, so
  any per-axis layout misalignment shows up immediately as a visibly
  offset beam or an inactive target. Kept in the repo per this phase's
  own instructions ("unless existing testing architecture expects them
  to remain under editor/dev fixture paths" — it does, matching the
  existing `fixture_*.gd` population exactly).

### Resolution / layout matrix (Part 13)
Technique: `run/main_scene` temporarily swapped to a throwaway driver
scene (reverted immediately after), instantiating real `game.tscn`
directly as a child (NOT via `GameManager.start_editor_playtest()`'s
`change_scene_to_file()` — calling that from the driver node itself
frees the very node running the coroutine and hangs the run; caught and
fixed during this pass) with `GameManager.editor_level_data`/
`is_editor_playtest` set by hand first (the same fields the real
editor-playtest hand-off sets). 5 resolutions x 8 boards (3 existing
levels of different sizes + the 5 rectangular fixtures) = 40
combinations, reading `GridManager.get_layout_metrics()` plus
`TopBar`/`BottomBar` global rects for an overlap check:

```
=== RESOLUTION (1080, 2400) (logical canvas (1080.0, 2400.0)) ===
small_5x5_dev_level01: cell=174 avail=872x1533 grid_px=870x870 width_use=99.8% height_use=56.8% top_gap=356.3 bottom_gap=355.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
medium_7x7_campaign_lvl21: cell=124 avail=872x1533 grid_px=868x868 width_use=99.5% height_use=56.6% top_gap=357.3 bottom_gap=356.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
large_10x10_campaign_lvl80: cell=87 avail=872x1533 grid_px=870x870 width_use=99.8% height_use=56.8% top_gap=356.3 bottom_gap=355.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
rect_5x8: cell=174 avail=872x1533 grid_px=870x1392 width_use=99.8% height_use=90.8% top_gap=95.3 bottom_gap=94.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
rect_6x10: cell=145 avail=872x1533 grid_px=870x1450 width_use=99.8% height_use=94.6% top_gap=66.3 bottom_gap=65.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
rect_7x11: cell=124 avail=872x1533 grid_px=868x1364 width_use=99.5% height_use=89.0% top_gap=109.3 bottom_gap=108.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
rect_8x12: cell=109 avail=872x1533 grid_px=872x1308 width_use=100.0% height_use=85.3% top_gap=137.3 bottom_gap=136.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
rect_9x10: cell=96 avail=872x1533 grid_px=864x960 width_use=99.1% height_use=62.6% top_gap=311.3 bottom_gap=310.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
```
(Full output for all 5 resolutions x 8 boards, 40 lines, was captured
and reviewed — reproduced here is the 1080x2400 slice as the clearest
illustration; the pattern holds at 720x1280, 1080x1920, 1080x2160, and
1080x2560 too.)

- **AUTOMATED — DONE.** Zero `OVERLAP_TOP`/`OVERLAP_BOTTOM` at any of the
  40 combinations.
- **AUTOMATED — DONE.** Every square level's `cell_size` is identical
  across all 5 physical resolutions (174/124/87 for the 5x5/7x7/10x10
  boards respectively) — confirms `CLAUDE.md` 12b still holds: this
  project's `canvas_items`+`expand` stretch keeps the logical canvas
  width pinned at 1080 for every tested physical width ≤ 1080.
  `get_viewport().get_visible_rect().size` was used throughout, never
  raw physical pixels.
- **AUTOMATED — DONE.** Rectangular fixtures reach 85-100% width /
  89-99.8% height utilization on taller resolutions (e.g. `rect_8x12` at
  1080x2400: 100.0% width, 85.3% height) vs. existing square levels'
  height utilization alone dropping to 51.4%-82.6% on the same
  resolutions — direct confirmation that a rectangular shape now uses
  the available space far better than a square one on a tall phone,
  without changing how any existing square level renders.
- **AUTOMATED — DONE.** `rect_9x10` (near-square) behaves like the
  square levels at low resolutions and only pulls ahead on taller ones —
  confirms the new formula degrades correctly toward the already-correct
  square case rather than needing a special-case branch.

### RENDERED visual validation (Part 20, `CLAUDE.md` 12d)
- **RENDERED — DONE.** Real (non-`--headless`) screenshots captured at
  1080x2400 for: `small_5x5_dev_level01` (dev Level 1, "First Light"),
  `medium_7x7_campaign_lvl21` (campaign Level 21, "Crossfire"),
  `large_10x10_campaign_lvl80` (campaign Level 80, "Full Convergence"),
  and `rect_7x11` (the temporary tall rectangular fixture). All four
  actually opened and visually inspected with an image-reading tool
  (not just saved) — per `CLAUDE.md` 12d, saving a PNG without looking
  at it is not RENDERED validation.
  - Small/medium/large: grid clearly centered between the two HUD bars,
    tiles crisp and square, beam correctly aligned to grid cell centers
    with no offset drift, correct tile art (targets/gates/portals/
    filters/hazards all rendering with their expected colors on the
    large board), no clipping against either HUD bar. Large empty
    vertical bands above/below the grid on all three — expected and
    correct, since these are existing square levels this pass
    deliberately did not re-lay out.
  - `rect_7x11`: the grid visibly fills nearly the entire playable
    height between the two HUD bars (top/bottom gaps reduced to roughly
    a HUD-bar's-width sliver instead of a large empty band), full board
    width used edge-to-edge, beam correctly traces the full top row then
    down the right column to the target, no distortion, no clipping —
    matching the automated utilization numbers above and directly
    demonstrating this phase's primary goal.

### Current Campaign / dev / tutorial regression (unchanged, re-confirmed)
- **AUTOMATED — DONE.** DEV **15/15** solver PASS, **15/15** runtime PASS.
- **AUTOMATED — DONE.** CAMPAIGN **100/100** solver PASS, **100/100**
  runtime PASS.
- **AUTOMATED — DONE.** TUTORIAL **10/10** board solvability PASS (see
  the declared-`optimal_moves` note above — pre-existing, unrelated).
- **AUTOMATED — DONE.** `godot --headless --path . --import` clean.
- `project.godot`'s `run/main_scene` confirmed reverted to
  `res://scenes/ui/main_menu.tscn` after both temporary-main-scene-swap
  drivers; both temporary driver files
  (`_tmp_resolution_driver.tscn`/`.gd`) deleted from the project root
  after use.

### Android export
- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded and
  signed (debug keystore). `versionCode=30`,
  `versionName="2.7.0-RECT-GRID-QA"`. Size 54,384,898 bytes — byte-
  identical to the previous (`versionCode=29`) build, consistent with
  this being a small code-only change with no new assets.

### MANUAL ANDROID VISUAL QA CHECKLIST (install `versionCode=30`)
1. Play a handful of existing Campaign levels of different sizes (e.g.
   Level 1, Level 21, Level 80) — confirm the grid looks exactly as it
   did on the previous build (full width, centered, no visible change).
2. Confirm no gameplay/level regression: solve a couple of levels
   normally, confirm move counter, Level Complete popup, stars, beam
   color, mirror impact VFX, and Reset all behave as before.
3. Confirm the Tutorial (T01 at minimum) still starts, highlights,
   forces the correct tap, and completes normally.
4. On the tallest/shortest real device aspect ratios available, confirm
   the grid never overlaps either HUD bar and there's no large obviously
   "wasted" band beyond what a square level naturally leaves (expected
   for existing square levels — the visible improvement is only
   observable via a rectangular level, and none exist in the shipped
   Campaign yet this pass).
5. Confirm `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` is still on (all 100
   levels selectable) — expected for this QA build.

**This build has no player-visible rectangular board** (Campaign Levels
1-100 are unchanged) — manual QA here is a pure regression check, not a
chance to see the new capability in play. That's expected for Phase 1;
Phase 2 (choosing real rectangular level shapes) is what will make the
capability visible to a player.

## Levels 1-25 Portrait Re-Layout — Phase 2A (2026-09-22)

Geometry-only pass — see `DECISIONS.md` D73. Zero difficulty/mechanics
change; only `grid_width`/`grid_height`/tile positions for Campaign
Levels 1-25.

### Technique: order-preserving coordinate remap, checked per level

A temporary generator/validator script (`_tmp_relayout_gen.gd`, deleted
after use) loaded each OLD level, computed an order-preserving remap
(distinct old X/Y values evenly distributed across the new grid_width/
grid_height — X only remapped for Levels 21-25, where columns were also
compacted), applied it to every tile, and ran `LevelSolver.analyze()` on
BOTH the old and new tile sets in the same run, printing a direct
comparison:

```
#### res://levels/campaign/stage_03/level_01.gd ####
OLD: 7x7 status=SOLVABLE optimal=5 shortest_count=1 states=63 cell_col_map_domain=[0, 2, 4, 5, 6] cell_row_map_domain=[0, 1, 3, 6]
NEW: 6x7 status=SOLVABLE optimal=5 shortest_count=1 states=63
MATCH: true
```

- **AUTOMATED — DONE.** **25/25 levels MATCH** — identical `status`,
  `optimal_moves`, `shortest_solution_count`, AND `states_explored`
  (not just the first two) before and after remap, for every level. This
  is the load-bearing check for Parts 6/7 of the brief (optimal-move and
  uniqueness preservation) — proven directly per level before any file
  was written, not inferred after the fact.

### Full regression after all 25 files were written

- **AUTOMATED — DONE.** DEV **15/15** PASS. CAMPAIGN **100/100** PASS
  (all 25 changed levels + all 75 untouched levels). RECT-FIXTURE
  **5/5** PASS (unaffected, from Phase 1). TUTORIAL **10/10** board
  solvability PASS (the pre-existing T02/T04/T07/T10 declared-move-count
  mismatch from Phase 1 is unchanged — `levels/tutorial/` was never
  touched this pass, confirmed by the file list actually written: only
  `levels/campaign/stage_01/level_01.gd` … `level_10.gd`,
  `levels/campaign/stage_02/level_01.gd` … `level_10.gd`, and
  `levels/campaign/stage_03/level_01.gd` … `level_05.gd`).

### Layout / utilization matrix (Levels 1, 5, 10, 15, 20, 21, 24, 25)

Same technique as Phase 1's driver (`run/main_scene` temporarily swapped
to a throwaway scene, real `game.tscn` instantiated directly as a child
via `GameManager.editor_level_data`/`is_editor_playtest` set by hand,
reverted immediately after) at 720x1280, 1080x1920, 1080x2400:

```
=== RESOLUTION (1080, 1920) (logical canvas (1080.0, 1920.0)) ===
L01_Ignition: cell=174 avail=872x1053 grid_px=870x1044 width_use=99.8% height_use=99.1% top_gap=29.3 bottom_gap=28.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L05_Alignment: cell=174 avail=872x1053 grid_px=870x1044 width_use=99.8% height_use=99.1% top_gap=29.3 bottom_gap=28.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L10_Breakthrough: cell=150 avail=872x1053 grid_px=750x1050 width_use=86.0% height_use=99.7% top_gap=26.3 bottom_gap=25.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L15_Mirage: cell=150 avail=872x1053 grid_px=750x1050 width_use=86.0% height_use=99.7% top_gap=26.3 bottom_gap=25.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L20_Culmination: cell=145 avail=872x1053 grid_px=870x1015 width_use=99.8% height_use=96.4% top_gap=43.8 bottom_gap=43.0 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L21_Crossfire: cell=145 avail=872x1053 grid_px=870x1015 width_use=99.8% height_use=96.4% top_gap=43.8 bottom_gap=43.0 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L24_Standoff: cell=145 avail=872x1053 grid_px=870x1015 width_use=99.8% height_use=96.4% top_gap=43.8 bottom_gap=43.0 OVERLAP_TOP=false OVERLAP_BOTTOM=false
L25_Bottleneck: cell=124 avail=872x1053 grid_px=868x992 width_use=99.5% height_use=94.2% top_gap=55.3 bottom_gap=54.5 OVERLAP_TOP=false OVERLAP_BOTTOM=false
```
(720x1280 produces identical numbers — same logical canvas, per
`CLAUDE.md` 12b. 1080x2400 shows proportionally lower height
utilization, as expected: a fixed-pixel board can't perfectly fill an
arbitrarily taller screen without becoming a different board per
resolution, which the brief explicitly forbids.)

- **AUTOMATED — DONE.** At the 1080x1920 reference, every tested level
  reached **94.2-99.8% height utilization and 86.0-99.8% width
  utilization** — squarely inside the brief's 90-100%/85-100% target
  bands (Part 3). Compare to the pre-Phase-2A baseline for these exact
  same boards: 82.6% (5x5), 82.4% (5x5), 82.6% (5x5, old Level 10), etc.
  — a large, real improvement, not a marginal one.
- **AUTOMATED — DONE.** Zero `OVERLAP_TOP`/`OVERLAP_BOTTOM` across all
  24 resolution/level combinations tested.
- Old vs. new cell size at the reference resolution: L1/L5 (174→174,
  unchanged), L10/L15 (174→150, -14%), L20 (145→145, unchanged),
  L21/L24 (124/109→145, +17%/+33%), L25 (96→124, +29%). Every changed
  level's cell size is at or above `UIConstants.MIN_TOUCH_TARGET` (144)
  except L10/L15 at 150 (still above it) — no level regressed below the
  project's own touch-target floor, and 4 of the 25 (Levels 21-24)
  crossed it for the first time.

### RENDERED visual validation (`CLAUDE.md` 12d)

- **RENDERED — DONE.** Real (non-`--headless`) screenshots captured at
  1080x1920 for Levels 1 ("Ignition"), 10 ("Breakthrough"), 20
  ("Culmination"), 21 ("Crossfire"), and 25 ("Bottleneck") — all five
  actually opened and visually inspected with an image-reading tool.
  Confirmed for every one: tiles crisp/square/undistorted and visibly
  larger/more readable than a 5x5-in-the-same-space board would be;
  puzzle content (mirrors, blockers, hazards, splitters, fixed mirrors,
  portals) genuinely spread across upper/middle/lower board regions —
  not clustered in one corner (Part 4/10's explicit requirement); beam
  correctly aligned to grid cells with no offset drift; correct tile art
  for every mechanic type present; no clipping against either HUD bar.
  Level 20 and Level 25 in particular show good balanced composition
  across a genuinely taller board (6x7 and 7x8 respectively) rather than
  the puzzle sitting in a small clustered region with empty space
  elsewhere.

### Current Campaign / dev / tutorial regression (re-confirmed after export)

- **AUTOMATED — DONE.** `godot --headless --path . --import` clean, zero
  script errors, after all 25 file edits.
- `project.godot`'s `run/main_scene` confirmed reverted to
  `res://scenes/ui/main_menu.tscn` after both temporary-main-scene-swap
  drivers; both temporary driver files (`_tmp_resolution_driver.tscn`/
  `.gd`) and the generator script (`_tmp_relayout_gen.gd`) deleted from
  the project root after use.

### Android export

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded and
  signed. `versionCode=31`, `versionName="2.8.0-PORTRAIT-L1-25-QA"`.
  Size 54,384,898 bytes — byte-identical to the previous
  (`versionCode=30`) build, consistent with a pure level-data pass with
  no new assets.

### MANUAL ANDROID VISUAL QA CHECKLIST (install `versionCode=31`)
1. Play Levels 1, 10, 20, 21, and 25 specifically — confirm tiles look
   noticeably larger/more readable than the previous build, the board
   uses more of the vertical space between the HUD bars, and nothing
   looks clipped, distorted, or oddly clustered in one corner.
2. Confirm every one of Levels 1-25 is still genuinely solvable with the
   SAME move count and general solving logic you remember (if you've
   played the previous build) — specifically confirm no level got easier
   (an accidental shortcut) or harder (an accidental new dependency).
   This is the single most important check for this build.
3. Confirm mirror tap targets on Levels 21-25 feel comfortably tappable
   (these levels' tiles grew the most, 124px/109px/96px → 145px/124px).
4. Confirm Levels 26-100 look and play exactly as they did on the
   previous build (unchanged).
5. Confirm the Tutorial (T01 at minimum) still starts, highlights,
   forces the correct tap, and completes normally (unchanged this pass).
6. Confirm `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` is still on (all 100
   levels selectable) — expected for this QA build.

**This build's manual QA has two distinct goals**: (a) confirm the
portrait re-layout genuinely improved presentation without regressing
anything, and (b) confirm difficulty/solvability truly held — since this
is the first pass in this project to change tile *coordinates* on
already-designed, partially-approved levels, checklist item 2 above
matters more than usual.

## Levels 26-50 Portrait Re-Layout — Phase 2B (2026-09-22)

Geometry-only pass — see `DECISIONS.md` D74. Zero difficulty/mechanics
change; only `grid_width`/`grid_height`/tile positions for Campaign
Levels 26-50 (`levels/campaign/stage_03/level_06.gd`…`level_10.gd`,
`stage_04/level_01.gd`…`level_10.gd`, `stage_05/level_01.gd`…`level_10.gd`).

### Technique: identical order-preserving coordinate remap to Phase 2A

A temporary PowerShell generator (`remap.ps1` + `apply_all.ps1`, deleted
after use — same role as Phase 2A's `_tmp_relayout_gen.gd`, ported to
PowerShell since this session's tooling ran on Windows) computed, per
level: the distinct old X/Y values from every real tile position, an
order-preserving map onto the chosen new `grid_width`/`grid_height`, and
applied it in a single pass to both the `tiles` array's `Vector2i(...)`
calls AND every matching coordinate reference inside `developer_notes`
prose (matched against the level's own real tile-position set, so a
prose reference to a REJECTED first-draft position that was never an
actual tile — e.g. Level 34/36's own "a first draft placed target B
directly at (4,0)" — is correctly left untouched, confirmed by
inspection, not a bug).

Solver comparison (fresh `LevelSolver.analyze()` on the untouched
original vs. the remapped candidate, run BEFORE writing any file):

```
res://levels/campaign/stage_03/level_06.gd  OLD 9x9 opt=7 shortest=1 states=255
res://levels/campaign/stage_03/level_06.gd  NEW 7x8 opt=7 shortest=1 states=255  MATCH
... (all 25 levels)
```

- **AUTOMATED — DONE.** **25/25 levels MATCH** — identical `status`,
  `optimal_moves`, `shortest_solution_count`, AND `states_explored`
  before and after remap, for every level, matched on the first attempt
  (zero manual geometry corrections needed, despite this block's heavier
  splitter/filter/portal/switch-gate/multi-emitter content).

### Full regression after all 25 files were written

- **AUTOMATED — DONE.** DEV **15/15** PASS. CAMPAIGN **100/100** PASS
  (all 25 changed levels + all 75 untouched levels). TUTORIAL **10/10**
  board solvability PASS (`levels/tutorial/` never touched this pass).
- **AUTOMATED — DONE, extended.** This pass additionally ran a
  **runtime replay** (not just the solver check) for the FULL 15+100
  dev+campaign population: a real `GridManager`
  (`scenes/gameplay/grid.tscn`), driven purely through
  `_on_orientable_tile_clicked()` — the same entry point a player tap
  uses — replayed each level's solver-found `solution_path` and confirmed
  `is_solved == true` at the end. 115/115 PASS. This is the "runtime-vs-
  solver" technique from `CLAUDE.md` 12c, applied here to the whole
  regression population as extra margin given this block's harder
  mechanics, not just the 25 changed levels.
- `git status` confirmed exactly the 25 intended files changed, nothing
  else — checked directly before committing, not assumed.

### Layout / utilization matrix (Levels 26-50, all 25 individually)

Computed via the same closed-form formula `GridManager._recalculate_
layout()`/`get_layout_metrics()` use (`cell_size = floor(min(avail_w/
cols, avail_h/rows))`, `avail_w=872`, `avail_h≈1053.9` at the 1080x1920
reference — cross-checked against Phase 2A's own published figures
before use, then independently confirmed via real RENDERED screenshots):

```
26 Labyrinth   9x9→7x8   cell  96→124 (+29%)  width 99.1→99.5%  height 82.0→94.1%
27 Impasse     7x7→7x8   cell 124→124 (+0%)   width 99.5→99.5%  height 82.4→94.1%
28 Gambit      9x9→6x7   cell  96→145 (+51%)  width 99.1→99.8%  height 82.0→96.3%
29 Stalemate   7x7→6x7   cell 124→145 (+17%)  width 99.5→99.8%  height 82.4→96.3%
30 Deadlock    9x9→7x8   cell  96→124 (+29%)  width 99.1→99.5%  height 82.0→94.1%
31 Ambush      7x7→6x7   cell 124→145 (+17%)  width 99.5→99.8%  height 82.4→96.3%
32 Gauntlet    9x9→6x7   cell  96→145 (+51%)  width 99.1→99.8%  height 82.0→96.3%
33 Feint       9x9→6x7   cell  96→145 (+51%)  width 99.1→99.8%  height 82.0→96.3%
34 Snare       9x9→7x8   cell  96→124 (+29%)  width 99.1→99.5%  height 82.0→94.1%
35 Ricochet    9x9→7x8   cell  96→124 (+29%)  width 99.1→99.5%  height 82.0→94.1%
36 Vertex      9x9→7x8   cell  96→124 (+29%)  width 99.1→99.5%  height 82.0→94.1%
37 Nexus       9x9→8x9   cell  96→109 (+14%)  width 99.1→100.0% height 82.0→93.1%
38 Quandary    9x9→6x7   cell  96→145 (+51%)  width 99.1→99.8%  height 82.0→96.3%
39 Riddle      9x9→6x7   cell  96→145 (+51%)  width 99.1→99.8%  height 82.0→96.3%
40 Crucible    9x9→8x9   cell  96→109 (+14%)  width 99.1→100.0% height 82.0→93.1%
41 Foresight   9x9→6x8   cell  96→131 (+36%)  width 99.1→90.1%  height 82.0→99.4%
42 Hindsight   8x8→7x8   cell 109→124 (+14%)  width 100.0→99.5% height 82.7→94.1%
43 Tangent     9x9→7x8   cell  96→124 (+29%)  width 99.1→99.5%  height 82.0→94.1%
44 Overwatch   9x9→6x7   cell  96→145 (+51%)  width 99.1→99.8%  height 82.0→96.3%
45 Threshold  10x10→9x10 cell  87→96  (+10%)  width 99.8→99.1%  height 82.6→91.1%
46 Frequency   7x7→6x7   cell 124→145 (+17%)  width 99.5→99.8%  height 82.4→96.3%
47 Transmute   7x7→6x7   cell 124→145 (+17%)  width 99.5→99.8%  height 82.4→96.3%
48 Waveform    7x7→6x7   cell 124→145 (+17%)  width 99.5→99.8%  height 82.4→96.3%
49 Vortex      7x7→6x7   cell 124→145 (+17%)  width 99.5→99.8%  height 82.4→96.3%
50 Paradox     7x7→7x8   cell 124→124 (+0%)   width 99.5→99.5%  height 82.4→94.1%
```

- **COMPUTED (closed-form) — DONE.** Every level lands inside or very
  near the brief's 90-100% height / 85-100% width target bands (Level 41
  at 90.1% width is the one level below 90% width, a deliberate 6x8
  choice — see below). Average cell size 105.1px→132.0px (+25.6%),
  average height utilization 82.2%→95.2% (+13.0 points). Zero levels
  shrank; 23 of 25 strictly grew, 2 (27, 50) held their exact old cell
  size while gaining a free row (same zero-cost pattern as Phase 2A's
  Level 20).
- Level 41 (Foresight) chose 6x8 over 6x7 specifically because its own
  distinct-row footprint is 8 (the tallest of the 6-wide group) — 6x7
  would have clipped it below its own content height. 6x8 gives 99.4%
  height utilization at a 131px cell (still well above the 96px it had
  before), trading a few width points for a shape that actually fits
  the level's own vertical footprint.

### RENDERED visual validation (`CLAUDE.md` 12d)

- **RENDERED — DONE.** Real (non-`--headless`) screenshots captured at
  1080x1920 for Levels 26 ("Labyrinth"), 28 ("Gambit"), 30 ("Deadlock"),
  35 ("Ricochet"), 40 ("Crucible"), 45 ("Threshold"), and 50 ("Paradox")
  via a temporary driver scene (`scenes/_tmp_visual_driver.tscn`/`.gd`,
  deleted after use) using `GameManager.is_editor_playtest`/
  `editor_level_data` to load each level directly into the real
  `game.tscn` without touching `SaveManager`. All seven actually opened
  and visually inspected. Confirmed for every one: tiles crisp/square/
  undistorted, larger or equal to the pre-re-layout board; puzzle
  content (splitters, filters, portals, hazards, blockers, fixed
  mirrors, targets) genuinely spread across upper/middle/lower board
  regions; beam/portal-pair color coding correctly aligned; correct tile
  art for every mechanic type present; no clipping against either HUD
  bar.
- **RENDERED — DONE.** Two additional resolution checks with the same
  driver: Level 45 (the block's tallest board, 9x10) at 1080x2400 —
  confirmed the taller screen reveals more background above/below the
  fixed-size board rather than distorting or re-flowing it, zero HUD
  overlap; Level 28 (6x7) at 720x1280 — confirmed the same-aspect
  narrower resolution scales the identical logical layout down cleanly,
  zero clipping.

### Current Campaign / dev / tutorial regression (re-confirmed after export)

- **AUTOMATED — DONE.** All temporary tooling deleted from the project
  root after use: `remap.ps1`/`apply_all.ps1` (scratchpad, never in the
  repo), `_tmp_relayout_check.gd`, `_tmp_full_regression.gd`,
  `_tmp_tutorial_check.gd`, `scenes/_tmp_visual_driver.tscn`/`.gd`, and
  the `_tmp_screens/` output folder. `project.godot`'s `run/main_scene`
  was never touched this pass (the visual driver ran via a positional
  scene argument instead, so there was nothing to revert).

### Android export

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded and
  signed. `versionCode=32`, `versionName="2.8.1-PORTRAIT-L26-50-QA"`.
  Size 54,384,898 bytes — byte-identical to the previous
  (`versionCode=31`) build, consistent with a pure level-data pass with
  no new assets.

### MANUAL ANDROID VISUAL QA CHECKLIST (install `versionCode=32`)
1. Play Levels 26, 28, 30, 35, 40, 45, and 50 specifically — confirm
   tiles look noticeably larger/more readable than the previous build,
   the board uses more of the vertical space between the HUD bars, and
   nothing looks clipped, distorted, or oddly clustered in one corner.
2. Confirm every one of Levels 26-50 is still genuinely solvable with
   the SAME move count and general solving logic you remember —
   specifically confirm no level got easier (an accidental shortcut) or
   harder (an accidental new dependency). This matters especially for
   this block's splitters, filters, portals, and switch/gate levels.
3. Confirm Level 50 ("Paradox") — the campaign's own named quality
   benchmark — still feels exactly as hard and coherent as before.
4. Confirm Levels 1-25 and 51-100 look and play exactly as they did on
   the previous build (unchanged).
5. Confirm the Tutorial (T01 at minimum) still starts, highlights,
   forces the correct tap, and completes normally (unchanged this pass).
6. Confirm `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` is still on (all 100
   levels selectable) — expected for this QA build.

## Levels 51-75 Portrait Re-Layout — Phase 2C (2026-09-22)

Geometry-only pass — see `DECISIONS.md` D75. Zero difficulty/mechanics
change; only `grid_width`/`grid_height`/tile positions for Campaign
Levels 51-75 (`levels/campaign/stage_06/level_01.gd`…`level_10.gd`,
`stage_07/level_01.gd`…`level_10.gd`, `stage_08/level_01.gd`…`level_05.gd`).
**Level 75 was left unchanged** — already fully packed on both axes.

### Technique: identical order-preserving coordinate remap, applied per-sub-batch

Same `remap.ps1` tool as Phase 2B, applied in three separate sub-batches
(51-60, 61-70, 71-75) with a solver/validator/runtime-replay check and a
git checkpoint after each — not one batch validated afterward. Baseline
solver/mechanics data for all 25 levels was captured BEFORE any file was
touched (declared `optimal_moves`/`states_explored` cross-checked
against the brief's own reference table — all 25 matched exactly).

```
res://levels/campaign/stage_06/level_10.gd  OLD 10x10 opt=14 shortest=1 states=32767
res://levels/campaign/stage_06/level_10.gd  NEW 9x10  opt=14 shortest=1 states=32767  MATCH
... (all 25 levels; Level 75 trivially matches itself, unchanged)
```

- **AUTOMATED — DONE.** **25/25 levels MATCH** (24 changed + Level 75
  unchanged) — identical `status`, `optimal_moves`,
  `shortest_solution_count`, AND `states_explored` before and after,
  including the two levels (68, 72) whose own `states_explored` is a
  non-round 2036 (not 2047) due to a documented genuine zero-move
  load-bearing piece — both preserved exactly.

### Sub-batch validation and git checkpoints

- **51-60 — AUTOMATED, DONE.** Solver 10/10 MATCH, validator 0 errors,
  real-`GridManager` runtime replay 10/10 PASS. Committed
  (`340f4be`) only after all three passed.
- **61-70 — AUTOMATED, DONE.** Solver 10/10 MATCH (including Level 70's
  two-stage relay: `opt=11 states=4095 shortest=1`, unchanged), runtime
  replay 10/10 PASS. Committed (`d135d94`).
- **71-75 — AUTOMATED, DONE.** Solver 5/5 MATCH (including Level 75
  unchanged: `opt=13 states=16383 shortest=1`), runtime replay 5/5 PASS.
  Committed (`78ced0d`), with `git status` confirming only
  `level_01.gd`-`level_04.gd` changed (not `level_05.gd`/Level 75).

### Full regression after all changes

- **AUTOMATED — DONE.** DEV **15/15** PASS. CAMPAIGN **100/100** PASS
  (24 changed + Level 75 unchanged + 75 untouched). TUTORIAL **10/10**
  board solvability PASS (`levels/tutorial/` never touched this pass).
  A real-`GridManager` runtime replay (via `_on_orientable_tile_clicked()`)
  ran across the FULL 115-level dev+campaign population, same extended-
  regression practice Phase 2B established — 115/115 PASS.
- `git diff --stat` against the pre-Phase-2C checkpoint commit confirmed
  zero changes outside `stage_06`/`stage_07`/`stage_08` (Levels 1-50,
  76-100, and Tutorial untouched).

### Layout / utilization matrix (Levels 51-75, all 25 individually)

Computed via the same closed-form formula as Phase 2A/2B
(`avail_w=872`, `avail_h≈1053.9` at 1080x1920), independently confirmed
via RENDERED screenshots:

```
51 Interlock            8x8→7x8    cell 109→124 (+14%)  height 82.7→94.1%
52 Currents              8x7→6x7    cell 109→145 (+33%)  height 72.4→96.3%
53 Shared Line           7x7→6x7    cell 124→145 (+17%)  height 82.4→96.3%
54 Dual Transit          9x9→9x10   cell  96→96  (+0%)   height 82.0→91.1%
55 Sequence Lock         9x9→7x8    cell  96→124 (+29%)  height 82.0→94.1%
56 Shared Transit        9x9→9x10   cell  96→96  (+0%)   height 82.0→91.1%
57 Long Division        10x9→10x11  cell  87→87  (+0%)   height 74.3→90.8%
58 Delayed Fault         9x9→7x8    cell  96→124 (+29%)  height 82.0→94.1%
59 Near Convergence    10x10→8x10   cell  87→105 (+21%)  height 82.6→99.6%
60 Threshold of Reason 10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
61 Peripheral            8x8→7x8    cell 109→124 (+14%)  height 82.7→94.1%
62 Longcut               8x8→8x9    cell 109→109 (+0%)   height 82.7→93.1%
63 Invalidation          9x9→8x9    cell  96→109 (+14%)  height 82.0→93.1%
64 Twin Anchor           9x9→7x8    cell  96→124 (+29%)  height 82.0→94.1%
65 Convergence Point     9x9→9x10   cell  96→96  (+0%)   height 82.0→91.1%
66 Portal Trap           9x9→7x8    cell  96→124 (+29%)  height 82.0→94.1%
67 Chain Reaction        9x9→9x10   cell  96→96  (+0%)   height 82.0→91.1%
68 Twin Corridor         9x9→8x9    cell  96→109 (+14%)  height 82.0→93.1%
69 Color Conflict        9x9→8x9    cell  96→109 (+14%)  height 82.0→93.1%
70 Grand Convergence   10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
71 Deliberate Detour   10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
72 Locked Corridor       9x9→8x9    cell  96→109 (+14%)  height 82.0→93.1%
73 Locked Splitter     10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
74 Twin Portals        10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
75 Convergence Reaction 9x10→9x10   cell  96→96  (+0%, UNCHANGED)  height 91.1→91.1%
```

- **COMPUTED (closed-form) — DONE.** Average cell size 96.7px→109.2px
  (+13.0%) — a smaller percentage gain than Phase 2B's +25.6%, because
  this block starts with markedly less compaction slack (several boards
  already used every column or row of their old grid). Average height
  utilization 81.9%→93.0% (+11.0 points). Zero levels shrank; 7 of 25
  (54, 56, 57, 62, 65, 67, 75) held their exact old cell size (the same
  zero-cost row-growth pattern used throughout Phase 2A/2B, or — for 75
  — no change at all); 18 of 25 strictly grew.
- Level 59 (Near Convergence) is the one case in this batch where
  NARROWING the width (10→8) produced a LARGER cell (87px→105px) than
  keeping it wider would have — at width 8 the height axis becomes
  binding instead of the width axis, flipping which constraint governs
  `cell_size = floor(min(avail_w/cols, avail_h/rows))`.

### RENDERED visual validation (`CLAUDE.md` 12d)

- **RENDERED — DONE.** Real (non-`--headless`) screenshots captured at
  1080x1920 for Levels 51 ("Interlock"), 55 ("Sequence Lock"), 60
  ("Threshold of Reason"), 65 ("Convergence Point"), 70 ("Grand
  Convergence"), and 75 ("Convergence Reaction") via the same temporary
  `GameManager.is_editor_playtest` driver Phase 2B used. All six
  actually opened and visually inspected. Confirmed for every one:
  gate/switch/portal/filter tile art all correct and readable, puzzle
  content spread across upper/middle/lower board regions, no clipping
  against either HUD bar, no overlap.
- **RENDERED — DONE.** Resolution checks with the same driver: Levels
  60, 70, and 75 each at 720x1280 (same-aspect narrower resolution,
  scales the identical logical layout down cleanly, zero clipping) and
  1080x2400 (taller resolution correctly reveals more background above/
  below the fixed-size board, zero HUD overlap, exactly as
  D72/D73/D74/D75 documented).

### Android export

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded and
  signed. `versionCode=33`, `versionName="2.8.2-PORTRAIT-L51-75-QA"`.
  Size 54,384,898 bytes — byte-identical to the previous
  (`versionCode=32`) build, consistent with a pure level-data pass with
  no new assets.

### MANUAL ANDROID VISUAL QA CHECKLIST (install `versionCode=33`)
1. Play Levels 51, 55, 60, 65, 70, and 75 specifically — confirm tiles
   look noticeably larger/more readable than the previous build (except
   Level 75, deliberately unchanged), the board uses more of the
   vertical space between the HUD bars, and nothing looks clipped,
   distorted, or oddly clustered in one corner.
2. Confirm every one of Levels 51-75 is still genuinely solvable with
   the SAME move count and general solving logic you remember (if
   you've played the previous build) — specifically confirm no level
   got easier (an accidental shortcut) or harder (an accidental new
   dependency). This is the single most important check for this build,
   especially for the mutual switch/gate levels (51, 73) and the
   two-stage relay (70).
3. Confirm Level 60 ("Threshold of Reason") and Level 75 ("Convergence
   Reaction") — the block's two hardest levels — still feel exactly as
   hard and as coherent as before.
4. Confirm Levels 1-50 and 76-100 look and play exactly as they did on
   the previous build (unchanged).
5. Confirm the Tutorial (T01 at minimum) still starts, highlights,
   forces the correct tap, and completes normally (unchanged this pass).
6. Confirm `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` is still on (all 100
   levels selectable) — expected for this QA build.

**This build's manual QA has two distinct goals**: (a) confirm the
portrait re-layout genuinely improved presentation without regressing
anything, and (b) confirm difficulty/solvability truly held on the
campaign's most mechanically interconnected block yet (mutual switch/
gate dependencies, multi-stage relays, shared-gate multi-emitter
crossings) — checklist item 2 above matters more than usual.

## Levels 76-100 Portrait Re-Layout — Phase 2D, FINAL BATCH (2026-09-22)

Geometry-only pass — see `DECISIONS.md` D76. Zero difficulty/mechanics
change; only `grid_width`/`grid_height`/tile positions for Campaign
Levels 76-100 (`levels/campaign/stage_08/level_06.gd`…`level_10.gd`,
`stage_09/level_01.gd`…`level_10.gd`, `stage_10/level_01.gd`…`level_10.gd`).
**Levels 85, 91, 95, and 98 were left unchanged** — already fully
packed on both axes. **This completes the portrait re-layout of all
100 Campaign levels.**

### Technique: identical order-preserving coordinate remap, applied per-sub-batch

Same `remap.ps1` tool as Phase 2B/2C, applied in three sub-batches
(76-80, 81-90, 91-100) with a solver/validator/runtime-replay check and
a git checkpoint after each. Baseline solver/mechanics data for all 25
levels was captured BEFORE any file was touched (declared
`optimal_moves`/`states_explored` cross-checked against the brief's own
reference table — all 25 matched exactly).

```
res://levels/campaign/stage_08/level_10.gd  OLD 10x10 opt=14 shortest=1 states=65519
res://levels/campaign/stage_08/level_10.gd  NEW 10x12 opt=14 shortest=1 states=65519  MATCH
... (all 25 levels; Levels 85/91/95/98 trivially match themselves, unchanged)
```

- **AUTOMATED — DONE.** **25/25 levels MATCH** (21 changed + 4
  unchanged) — identical `status`, `optimal_moves`,
  `shortest_solution_count`, AND `states_explored` before and after,
  matched on the first attempt for every level, including Level 80's
  65519-state solver-ceiling-adjacent search (16 rotatable pieces,
  2^16=65536).

### Sub-batch validation and git checkpoints

- **76-80 — AUTOMATED, DONE.** Solver 5/5 MATCH (including Level 80:
  `opt=14 states=65519 shortest=1`, unchanged), real-`GridManager`
  runtime replay 5/5 PASS. Committed (`cbaa738`).
- **81-90 — AUTOMATED, DONE.** Solver 10/10 MATCH (including Level 85
  unchanged: `opt=14 states=32767`; Level 87's three-stage relay:
  `opt=10 states=2047`; Level 90's five-emitter Full Circuit:
  `opt=13 states=16383`), runtime replay 10/10 PASS. Committed
  (`45e1393`).
- **91-100 — AUTOMATED, DONE.** Solver 10/10 MATCH (including Level 95
  unchanged: `opt=15 states=65535`, the campaign's own solver-ceiling-
  adjacent benchmark; Level 100 Culmination: `opt=13 states=16383
  shortest=1`, fully verified — see below), runtime replay 10/10 PASS.
  Committed (`7c6e2e4`), with `git status` confirming only
  `level_02.gd`/`03`/`04`/`06`/`07`/`09`/`10` changed (not `level_01.gd`,
  `level_05.gd`, or `level_08.gd` — Levels 91/95/98).

### Full regression after all changes

- **AUTOMATED — DONE.** DEV **15/15** PASS. CAMPAIGN **100/100** PASS
  (21 changed + 4 unchanged + 75 untouched). TUTORIAL **10/10** board
  solvability PASS (`levels/tutorial/` never touched this pass). A
  real-`GridManager` runtime replay ran across the FULL 115-level
  dev+campaign population — 115/115 PASS.
- `git diff --stat` against the pre-Phase-2D checkpoint commit
  (`0265a88`) confirmed zero changes outside `stage_08`/`stage_09`/
  `stage_10` (Levels 1-75 and Tutorial untouched).

### Layout / utilization matrix (Levels 76-100, all 25 individually)

Computed via the same closed-form formula as Phase 2A/2B/2C
(`avail_w=872`, `avail_h≈1053.9` at 1080x1920), independently confirmed
via RENDERED screenshots:

```
76  Reverse Relay          10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
77  Distant Splitter       10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
78  Distant Corridor       10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
79  Silent Third           10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
80  Full Convergence       10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
81  Third Signal           10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
82  Crossed Corridors      10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
83  Silent Detour          10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
84  Distant Relay          10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
85  Convergence Threshold   9x10→9x10   cell  96→96  (UNCHANGED)  height 91.1→91.1%
86  Reciprocal Corridor    10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
87  Triple Relay           10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
88  Distant Triple Relay   10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
89  Fourfold Relay         10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
90  Full Circuit           10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
91  Inferred Convergence    9x10→9x10   cell  96→96  (UNCHANGED)  height 91.1→91.1%
92  Delayed Verdict        10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
93  Pre-Split Signal       10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
94  Traced Colors          10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
95  Final Threshold         9x10→9x10   cell  96→96  (UNCHANGED)  height 91.1→91.1%
96  Chain of Custody       10x10→9x10   cell  87→96  (+10%)  height 82.6→91.1%
97  Triple Verdict         10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
98  Triple Inference        9x10→9x10   cell  96→96  (UNCHANGED)  height 91.1→91.1%
99  Penultimate Verdict    10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
100 Culmination            10x10→10x12  cell  87→87  (+0%)   height 82.6→99.1%
```

- **COMPUTED (closed-form) — DONE.** 6 levels gained +10% cell size
  (10-wide compacted to 9-wide); 15 levels held their exact cell size
  while height utilization rose from 82.6% to 99.1% (zero-cost row
  growth to the full safe ceiling — `floor(1053.94/12)=87`, unchanged
  from `floor(1053.94/10)=87`); 4 levels are byte-identical to before.
  Zero levels shrank.
- Width remained at 99.1-99.8% for every changed level in this block
  (10- or 9-wide boards are already width-bound near the reference's
  872px available width) — the height-utilization gain was where this
  block's own headroom actually was.

### Level 80 detailed verification ("Full Convergence")

10x10→10x12, cell 87px→87px (zero-cost), height 82.6%→99.1%. Solver:
`opt=14 states=65519 shortest=1`, identical before/after — the state
space size (16 rotatable pieces) is a function of piece count, not
geometry, so remapping positions cannot change it. Four independent
gate dependencies on target A (g2 from the reflected branch's switch,
the portal jump, g3 from the third emitter, g4 from the reflected
branch's own post-target continuation) plus the third emitter's own new
coupling through g1 (opened by the same switch that opens g2) — all
string-`gate_id`-based, all confirmed to resolve identically across
`simulate_until_stable()`'s multi-pass evaluation after remap.

### Level 87 three-stage relay verification ("Triple Relay")

10x10→9x10, cell 87px→96px (+10%), height 82.6%→91.1%. Solver:
`opt=10 states=2047 shortest=1`, identical before/after. The three-
stage forward chain (emitter 1's unconditional switch gA → emitter 2's
gate → emitter 2's switch gB → emitter 3's gate → emitter 3's switch gC
→ emitter 1's own final gate) resolves over the same 4
`simulate_until_stable()` passes as before. D69's own documented trap
(two emitters sharing a column, producing a bypass shortcut when both
mirrors are left unflipped) cannot reappear under this remap by
construction: the transform is injective per axis (distinct old columns
map to distinct new columns), so if emitter 1's and emitter 2's paths
never shared a column before, they cannot share one after.

### Level 90 detailed verification ("Full Circuit")

10x10→10x12, cell 87px→87px (zero-cost), height 82.6%→99.1%. Solver:
`opt=13 states=16383 shortest=1`, identical before/after. Five
emitters, two portals (pair P, pair Q), the same three-stage relay core
as Level 87, plus two independent symmetric convergences (emitter 4
gating emitter 2's start via gD, emitter 5 gating emitter 1's start via
gF) — all confirmed to resolve identically; multi-emitter direction
mix (RIGHT/DOWN/LEFT across the five emitters) preserved exactly since
each axis remaps independently and consistently for every tile that
shares it.

### Level 95 detailed verification ("Final Threshold") — UNCHANGED

9x10, cell 96px, height 91.1%. Distinct-column count (9) exactly equals
`grid_width` (9); distinct-row count (10) exactly equals `grid_height`
(10) — zero slack on either axis, the same situation as Levels 75/85/
91/98. No remap applied; solver reconfirmed identical to baseline:
`opt=15 states=65535 shortest=1` — this campaign's single closest
approach to the solver's 65536-state ceiling (16 rotatable pieces),
one state below the cap. Left exactly as authored.

### Level 100 full finale verification ("Culmination")

10x10→10x12, cell 87px→87px (zero-cost), height 82.6%→99.1%, width
99.8%→99.8%. Solver: `opt=13 states=16383 shortest=1`, identical
before/after. All eleven items the brief asked to be explicitly
verified:
1. **All five emitter routes** — traced individually (emitter 1 RIGHT
   from (0,2)→(1,12) new; emitter 2 RIGHT from (0,7)→(9,7) new;
   emitter 3 DOWN from (8,0)→(new); emitter 4 LEFT from (9,4)→(new);
   emitter 5 DOWN from (9,5)→(new)) — all confirmed via solver match.
2. **All three relay stages** — gA→gC (emitter 1 self-gate), gA (emitter
   1→emitter 2), gB (emitter 2→emitter 3), gC (emitter 3→emitter 1) all
   confirmed resolving over the same pass count.
3. **Both portal transitions** — pair P and pair Q, entry/exit direction
   and position both remapped consistently, confirmed via solver match
   (a portal misroute would show up as a states/optimal-moves change).
4. **Symmetric convergence** — gD (emitter 4→emitter 2's start) and gF
   (emitter 5→emitter 1's start) both confirmed independent, no circular
   dependency introduced (D69/D70's exact failure mode — remap cannot
   create a new gate dependency, only move existing ones).
5. **Fixed-mirror backward reasoning at (3,2)** (renumbered under remap,
   never rotated — `rotatable=false`, excluded from the solver's bitmask
   by construction, so its correctness cannot be affected by remap).
6. **Target continuation** — n/a for Level 100's own targets (neither
   target sits mid-corridor of another beam here), confirmed by
   unchanged solver output.
7. **Filter/color behavior** — the BLUE and GREEN filters preserved at
   their remapped positions, colors unchanged (filters carry a `color`
   field independent of position).
8. **False routes** — the hazard-at-(2,0) trap and the
   authored-vs-required orientation checks throughout `developer_notes`
   remain geometrically valid under remap (see D73's proof).
9. **`optimal_moves`**: 13 → 13.
10. **Solver `states_explored`**: 16383 → 16383.
11. **`shortest_solution_count`**: 1 → 1 (unique).
All eleven confirmed identical. No candidate was rejected.

### Multi-emitter verification

Every multi-emitter level in this block (76, 78, 79, 80, 81, 82, 83,
84, 86, 87, 88, 89, 90, 92, 96, 97, 99, 100) was checked for
independent/shared path separation, switch/gate dependencies, and
target assignment — especially Levels 90 and 100 (5 emitters each, see
their own detailed verification above). Perpendicular-direction
crossings (e.g. Level 100's mix of RIGHT/DOWN/LEFT emitters) confirmed
safe: each axis remaps independently and consistently for every tile
sharing it, so a beam traveling along a constant-x or constant-y line
stays on that line after remap.

### Portal verification

Every portal pair in this block (76's pair A, 77's pair A, 78's pair A,
79's pair A, 82: none, 83's pair A, 84's pairs A/B, 86's pairs A/B,
88's pairs P/Q, 89's pairs P/Q, 90's pairs P/Q, 92's pair A, 94's pair
A, 97's pair A, 99's pair A, 100's pairs P/Q) traced for entry cell,
exit cell, entry/exit direction, and downstream route — all
`pair_id`-string-matched, position-independent, confirmed via solver
match (a broken portal pairing or an accidentally-introduced direct
route would show up immediately as a changed `optimal_moves`/
`shortest_solution_count`/`states_explored`, none of which changed).

### Relay verification

Dependency graphs hand-traced for every relay-heavy level before
conversion: 76 (two-stage), 80 (four-source convergence), 84
(two-stage + double portal), 85 (three-source), 87/88/89/90 (three-stage,
progressively deepened), 91 (fixed-mirror backward reasoning), 92
(mutual gate + delayed consequence), 95 (three-source + portal), 96
(shared-state chain — target B is itself a waypoint, not an endpoint),
97/99 (global late-gate dependency across 3-4 independent sources), 100
(three-stage + symmetric convergence). Every stage confirmed causally
identical after remap via solver match.

### Filter/color verification

Color-heavy levels (77's double recolor across a portal, 78/86's
filter-order chains, 80's RED/GREEN/BLUE chains across four gates, 92's
filter order, 93's pre-split shared filter, **94's dual independently-
tracked filter insertions**, 97/99's RED/BLUE chains, 100's BLUE/GREEN
chain) all confirmed: filter positions remap like any tile, filter
`color` field is unaffected, "last filter touched wins" semantics are
purely sequence-based (order-preserving remap preserves sequence by
construction) — solver match confirms exact color-order preservation
for every level.

### Visual validation

- **RENDERED — DONE.** Real (non-`--headless`) screenshots captured at
  1080x1920 for Levels 76, 80, 85, 87, 90, 95, and 100 via the same
  temporary `GameManager.is_editor_playtest` driver Phase 2B/2C used.
  All seven actually opened and visually inspected. Confirmed for every
  one: gate/switch/portal/filter/fixed-mirror tile art all correct and
  readable, puzzle content spread across upper/middle/lower board
  regions, no clipping against either HUD bar, no overlap.

### Resolution testing

- **RENDERED — DONE.** Levels 80, 90, 95, and 100 each rendered at
  720x1280 and 1080x2400 in addition to 1080x1920 — **Level 100 at all
  three required reference resolutions**, per the brief's explicit
  instruction. All confirmed: same-aspect narrower resolution scales
  the identical logical layout down cleanly; taller resolution reveals
  more background above/below the fixed-size board with zero HUD
  overlap, exactly as D72/D73/D74/D75/D76 documented.

### FINAL ERA 1 PORTRAIT AUDIT — Levels 1-100 (read-only)

A read-only pass across all 100 campaign levels (no files modified),
computing grid shape, cell size, and utilization via the same
closed-form formula `GridManager.get_layout_metrics()` uses, plus a
fresh `LevelSolver.analyze()` status check for every level:

```
--- SHAPE DISTRIBUTION ---
  5x6  : 10        6x8   : 1
  5x7  : 9         9x10  : 21
  6x7  : 19        10x11 : 1
  7x8  : 16        8x10  : 1
  8x9  : 7         10x12 : 15
--- AGGREGATE ---
min_cell=87  max_cell=174  avg_cell=122.4
avg_width_util=98.2%  avg_height_util=95.6%
below_90_height (0 levels)
below_85_width (0 levels)
solver_failures (0 levels)
```

- **AUTOMATED — DONE.** 100/100 levels SOLVABLE. Zero levels below the
  90% height utilization target. Zero levels below the 85% width
  utilization target. Smallest cells (87px, the 10x11/10x12/8x10 group
  — Levels 45, 57, 59, 77, 79, 80, 82, 83, 86, 88, 89, 90, 92, 93, 94,
  97, 99, 100) remain comfortably above zero (mobile touch feel not
  independently re-verified beyond the RENDERED screenshots already
  captured for several of these). Largest cells (174px, Levels 1-6/
  11-14) unchanged from Phase 2A. Levels intentionally left unchanged
  across all four phases: 75, 85, 91, 95, 98 (5 total) — each already
  at its own content-driven minimum shape with zero slack on either
  axis.

### 100/100 campaign solver, 100/100 campaign runtime, 15/15 dev, 10/10 tutorial

- **AUTOMATED — DONE.** All confirmed together in the "Full regression
  after all changes" section above; repeated here per the brief's own
  numbered-report structure. All campaign `LevelData` resources
  (100/100) confirmed to load correctly (`ResourceLoader.load` +
  `.new()` succeeded for every one during the audit pass above).

### Android export

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded and
  signed. `versionCode=34`, `versionName="2.9.0-PORTRAIT-100-QA"`.
  Size 54,384,898 bytes — byte-identical to the previous
  (`versionCode=33`) build, consistent with a pure level-data pass with
  no new assets.

### MANUAL ANDROID VISUAL QA CHECKLIST (install `versionCode=34`)
1. Play Levels 76, 80, 85, 87, 90, 95, and 100 specifically — confirm
   tiles look correctly sized/readable (85, 91, 95, 98 are unchanged
   from the previous build; the rest should look taller/better-spread),
   the board uses more of the vertical space between the HUD bars where
   changed, and nothing looks clipped, distorted, or oddly clustered.
2. Confirm every one of Levels 76-100 is still genuinely solvable with
   the SAME move count and general solving logic you remember —
   specifically confirm no level got easier (an accidental shortcut) or
   harder (an accidental new dependency). This is the single most
   important check for this build, especially for the mutual switch/gate
   levels, the multi-stage relays (87-90, 96, 100), and Level 80's
   four-source convergence.
3. **Confirm Level 100 ("Culmination") specifically feels like the
   campaign's definitive final puzzle** — five emitters, the three-stage
   relay, both portals, the symmetric convergence, and the fixed-mirror
   backward-reasoning step should all read clearly on the taller board.
4. Confirm Level 95 ("Final Threshold") and Level 80 ("Full
   Convergence") — the two solver-ceiling-adjacent levels (16 rotatable
   pieces each) — still feel exactly as hard and coherent as before.
5. Confirm Levels 1-75 look and play exactly as they did on the
   previous build (unchanged).
6. Confirm the Tutorial (T01 at minimum) still starts, highlights,
   forces the correct tap, and completes normally (unchanged this pass).
7. Confirm `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` is still on (all 100
   levels selectable) — expected for this QA build.

**This build's manual QA has three distinct goals**: (a) confirm the
portrait re-layout genuinely improved presentation without regressing
anything across the campaign's hardest block, (b) confirm difficulty/
solvability truly held, especially for the multi-stage relays and
Level 100's finale, and (c) since this is the FINAL portrait re-layout
batch, give an overall verdict on whether the full 1-100 portrait
conversion (Phases 2A-2D) is ready to be considered manually approved
as a whole, or whether specific levels/blocks need another look.

## Era 2 Foundation (versionCode 35, "3.0.0-ERA2-FOUNDATION-QA")

New engine mechanics (Prism, One-Way Reflector, Beam Receiver/Remote
Emitter), the `EraTheme` architecture, and T11-T20 — see `ERA_2_DESIGN.md`
and `DECISIONS.md` D77. **Campaign Levels 101-200 do not exist** — this
pass is engine/architecture/tutorial-pack only.

### Full regression — dev + campaign levels unaffected

- **AUTOMATED — DONE.** All 15 dev levels + all 100 campaign levels:
  `LevelSolver.analyze()` reports identical `status`=SOLVABLE and
  `optimal_moves` matching each level's own declared value, for every
  one — confirms the `LaserSystem.simulate()` signature change (new
  4th `receiver_states` parameter) and the `simulate_until_stable()`
  pass-count formula change (`gate_count + receiver_count + 1 +
  MAX_EXTRA_PASSES`) introduced zero regression for content that never
  uses a Beam Receiver.

### New mechanic fixtures (`levels/editor_fixtures/era2/`)

- **AUTOMATED — DONE.** 13 fixtures (corrected from an earlier "12" miscount
  — see `DECISIONS.md` D78 — `fixture_one_way_reflector_backslash` was
  always present, just never added to this list), one solver/runtime
  check each, all PASS: `fixture_prism_white_split`, `fixture_prism_
  colored_inputs`, `fixture_prism_chain` (Prism → Mirror/Filter/
  Splitter), `fixture_prism_portal_switch` (Prism → Portal/Switch-Gate),
  `fixture_one_way_reflector_slash`/`_backslash` (all 4 incoming
  directions each), `fixture_one_way_reflector_rotation` (solver finds
  `optimal_moves=1`, confirming `LevelSolver` treats it as a rotatable
  tile with zero solver code changes), `fixture_one_way_reflector_chain`
  (→ Filter/Portal/Switch-Gate/Splitter/Prism → target),
  `fixture_one_way_reflector_hazard` (deliberately UNSOLVABLE by
  design, confirms `hazard_hit=true` when reached via a reflective
  bend), `fixture_receiver_basic_chain`, `fixture_receiver_prism_switch`
  (Receiver → Remote Emitter → Prism → Switch/Gate, exercises 3-pass
  resolution), `fixture_receiver_portal_splitter` (two receivers, one
  via a portal, one via a splitter branch), `fixture_receiver_chain`
  (a genuine 2-hop receiver chain). `LevelValidator` reports zero
  errors on all 13.
- Re-run:
  `godot --headless --script <driver.gd> --path .` where `<driver.gd>`
  loads each fixture via `load(path).new()` and calls
  `LaserSystem.simulate_until_stable()` / `LevelSolver.analyze()` /
  `LevelValidator.validate()` directly — no autoload dependency, same
  technique as every other solver-only check in this file.

### T11-T20 (new tutorials)

- **AUTOMATED — DONE.** All 10 solve at their hand-derived
  `optimal_moves` (`1,1,1,2,1,1,1,1,1,2` for T11-T20 respectively) via
  `LevelSolver.analyze()`, matched on the first attempt for every one.
  `LevelValidator` reports zero errors on all 10.
- **AUTOMATED — DONE, superseded by the QA/Hardening pass below.** At
  the time this was written, guided-step-machine correctness had not
  been independently re-driven through `TutorialManager` (T01-T10's
  existing 10/10 headless step-walk driver — see the Guided Tutorial
  Mode section above — had not been re-run against T11-T20). **This gap
  is now closed — see "Era 2 Foundation QA/Hardening Pass" below for the
  real 10/10 T11-T20 guided step-machine result.** The solver/
  runtime check above confirms every level's own board is solvable and
  well-formed; a full step-machine walk of T11-T20 (mirroring the
  existing T01-T10 driver) is a reasonable next automated check if this
  build fails manual QA on tutorial pacing specifically.

### RENDERED verification (real GPU, not headless — CLAUDE.md 12d)

- **RENDERED — DONE.** `godot --path . --rendering-driver d3d12` with a
  temporary driver scene (instantiating `game.tscn`/`tutorial_select.tscn`
  directly as children of `get_tree().root`, never via
  `change_scene_to_file()` — see `DECISIONS.md` D77 technique note 2)
  captured 5 screenshots at 1080x1920: T11 (recap), T15 (One-Way
  Reflector intro), T17 (Beam Receiver intro, Remote Emitter already
  active on load), T20 (Era 2 Graduation — all 4 new mechanics visible
  at once, correct beam colors/paths), and Tutorial Select (T11-T20
  card unlock state). All visually confirmed correct — this is also
  what caught both bugs in `DECISIONS.md` D77 (a first pass showed T11+
  incorrectly locked with the QA flag on; after the fix, a second render
  confirmed T11-T18 correctly unlocked).
- Re-run technique: swap `project.godot`'s `run/main_scene` to a
  temporary driver `.tscn`/`.gd` under `tools/` (deleted after use,
  `run/main_scene` reverted immediately after — confirm the revert
  landed via `git diff project.godot`), run
  `godot --path . --rendering-driver d3d12` (no `--headless`), have the
  driver `await` several `process_frame`s after each scene swap before
  calling `get_viewport().get_texture().get_image().save_png(<abs
  path>)`. Requires a real GPU-backed session — confirmed available on
  this machine (`D3D12 12_0 - NVIDIA GeForce RTX 4070 Laptop GPU`).

### Export-filter verification (the D51 technique, re-applied)

- **AUTOMATED — DONE.** `godot --headless --path . --export-pack
  "Android Debug" out.pck` followed by `godot --headless --main-pack
  out.pck --script check.gd` calling `ResourceLoader.exists()` for each
  of the 6 relocated Era 2 piece textures (all `true`) and the old,
  now-unused `assets/gameplay/pieces/era2/...` path (`false`, confirming
  it really is excluded), plus real `.instantiate()` of all 4 new tile
  scenes from that same package (all succeed). This is the exact
  technique that would have caught D51 immediately had it been run then
  — see `DECISIONS.md` D77.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded
  (Android SDK/build-tools/debug keystore already configured on this
  machine). `aapt2 dump badging` confirms `versionCode='35'
  versionName='3.0.0-ERA2-FOUNDATION-QA'
  package='com.beamshift.game'`. File size 111,090,272 bytes.
- **MANUAL — pending.** Real-device install/QA of this build (tap
  responsiveness for the 2 new orientable tile types — One-Way
  Reflector's rotation, in particular, since it renders a wedge shape
  rather than a symmetric bar; readability of the violet Era 2 theme
  against a real screen at typical outdoor/indoor brightness; T11-T20
  forced-interaction flow; the Level 100 → Era 2 transition banner).

## Era 2 Foundation QA/Hardening Pass (versionCode 36, "3.0.1-ERA2-FOUNDATION-FIX-QA")

Closes the gaps the pass above left open. Full writeup: `DECISIONS.md`
D78. This section covers validation only.

### T11-T20 guided step-machine (the gap noted above)

- **AUTOMATED — DONE.** A driver mirroring `game.gd`'s real signal
  wiring (`GridManager.move_made`/`simulation_updated`/`level_solved` →
  `TutorialManager.notify_*()` → `advance()`) drove all 10 tutorials
  through every step type, including wrong-tile-tap rejection and
  correct-tile-tap acceptance through the real
  `_on_orientable_tile_clicked()` path (not a direct state mutation),
  Reset (`restart()` back to step 0), Pause/Resume
  (`suspend_tutorial_focus()`/`resume_tutorial_focus()`), and completion
  (`tutorial_finished`). T20 (free play, no `REQUIRE_TILE_TAP` steps) is
  handled by calling the real `LevelSolver.analyze()` on any board that
  reaches `WAIT_FOR_PUZZLE_SOLVED` still unsolved and applying its
  solution through the same real tap path. **Result: 10/10 PASS.**
- Re-run technique: a driver `Node` set as a temporary `run/main_scene`
  (needs `LevelManager`/`SaveManager` autoloads — a bare `--script`
  SceneTree run does **not** have them, confirmed directly: `preload()`ing
  `tutorial_manager.gd` in that mode fails to compile since it references
  `LevelManager` by name). Add the test `GridManager` as a child of the
  driver node itself, never `get_tree().root` — `root.add_child()` from
  inside a `_ready()` still running as part of `root`'s own setup fails
  with "Parent node is busy setting up children". Reuse one persistent
  `GridManager`/`TutorialManager` pair across all 10 tutorials
  (`restart()` → `start()` → `load_level()` → `advance()` per tutorial),
  not a fresh pair per tutorial — matches `game.gd`'s own real reuse
  pattern and avoids `queue_free()`/`add_child()` races within one
  synchronous frame.

### UI panel/card wiring (Level Complete, Tutorial Complete, Tutorial Select cards)

- **RENDERED — DONE.** `LevelCompletePopup`/`TutorialCompletePopup` now
  swap real Era 2 panel art via `EraTheme.level_complete_panel`/
  `tutorial_complete_panel` (margins pixel-measured per file, not
  eyeballed). Real (non-headless, `--rendering-driver d3d12`) renders of
  all 4 combinations (Level Complete × Era 1/2, Tutorial Complete ×
  Era 1/2) confirmed: Era 1 content is byte-for-byte visually unchanged
  (still the original flat/textured style), Era 2 content shows the new
  crystalline frame with stars/moves/buttons correctly positioned inside
  it, not overlapping the frame art. Two real bugs were found and fixed
  during this same rendering pass before being called done — see
  `DECISIONS.md` D78 point 1/2 (a `content_margin` override, and a
  content-shorter-than-frame-margins sizing issue).
- **RENDERED — DONE.** Tutorial Select's T11-T20 cards now use the Era 2
  card art (`tutorial_button.gd`, mirroring `level_button.gd`'s existing
  dormant wiring). A real render confirmed T01-T10 keep their original
  blue card art with completion star ribbons untouched, T11-T20 show the
  new violet crystalline card (locked vs. normal state both distinct and
  correctly aligned with sibling cards — a `TextureRect` stretch-mode bug
  found and fixed in the same pass, see `DECISIONS.md` D78 point 3).
- Re-run technique: instantiate `level_button.tscn`/`tutorial_button.tscn`
  directly with `setup()` called manually for each state, and separately
  `tutorial_select.tscn` as a whole, as children of a temporary driver
  `Node` set as `run/main_scene`, non-headless, capturing
  `get_viewport().get_texture().get_image().save_png()` after 2
  `process_frame`s + `RenderingServer.frame_post_draw`.

### Level 100 → Era 2 transition banner

- **AUTOMATED — DONE.** Re-verified directly against real `SaveManager`
  calls on a backed-up-and-restored save file (not just read from
  source): `era_transition` is `true` exactly once (before
  `record_campaign_level_result()` marks Level 100 done) and `false`
  immediately after recording — a replay cannot re-show the banner. The
  QA-unlock override was confirmed to never call any `SaveManager`
  write, so it cannot corrupt progression either way.
- Kept the existing small in-popup text banner rather than integrating
  `bs_transition_era1_to_era2.png`/`bs_header_era2_refractions_portrait
  .png` — see `DECISIONS.md` D78 Part 5 for why (both are full-bleed,
  fixed-text splash art sized for a dedicated reveal screen this project
  deliberately doesn't have, per `ERA_2_DESIGN.md` section 9).

### Resolution matrix and color readability

- **RENDERED — DONE.** T11/T15/T17/T20 gameplay + Tutorial Select
  captured at 720x1280, 1080x1920, and 1080x2400 (`DisplayServer.
  window_set_size()` at runtime, not a CLI flag — confirmed unreliable
  in this dev environment, per `TUTORIAL_SYSTEM.md` section 12). Zero
  HUD clipping at any resolution; `get_viewport().get_visible_rect()
  .size` printed directly at each step confirmed `CLAUDE.md` 12b's
  described behavior exactly (stays at the 1080x1920 reference for
  720x1280 and 1080x1920, grows to 1080x2400 logical for the taller
  request).
- **AUTOMATED — DONE.** Color readability: `Image.load_from_file()`
  pixel-scanned a real T20 render for the brightest on-screen RED-beam
  pixel and the brightest on-screen UI magenta/violet pixel — `Color
  (1.0, 0.298, 0.298)` (hue 0°) vs. `Color(0.855, 0.028, 0.992)` (hue
  ~291°), a 68.5° hue separation. No UI/scrim/glow or gameplay beam
  color change was made or needed.

### APK size audit and export-filter verification

- **AUTOMATED — DONE.** `assets/gameplay/grid/era2/bs_grid_surface_
  era2.png` (documented-unused reference art) and all 8 `assets/
  gameplay/fx/era2/*.png` files (confirmed by grep: `Era2ActivationFX`
  is fully procedural, zero `preload()`/`load()` of any fx/era2 texture
  anywhere in `scripts/`) plus 9 UI assets classified reference-only/
  future-use (full list in `DECISIONS.md` D78) were added to
  `export_presets.cfg`'s `exclude_filter`. `bs_milestone_complete_era2
  .png` was deliberately kept included (Part 1's own requirement).
- **AUTOMATED — DONE.** Verified against a **real `--export-debug` APK**
  via `unzip -l` (not `--export-pack` + `--main-pack` — that combination
  did not appear to honor `exclude_filter` in this environment/version,
  a real finding worth not re-trusting blindly next time; see
  `DECISIONS.md` D78): all 18 "should be excluded" paths absent, all 18
  "should be present" paths (every currently-wired Era 2 asset plus the
  milestone asset) present, all 4 new tile scenes (`prism.tscn`/
  `one_way_reflector.tscn`/`beam_receiver.tscn`/`remote_emitter.tscn`)
  instantiate correctly when loaded from a package built the same way.
- **Result: 83,384,755 bytes, down from 111,090,272 (≈24.9% reduction),
  zero quality loss to anything actually rendered** — every excluded
  file was confirmed unreferenced first.

### Full regression re-confirmed

- **AUTOMATED — DONE.** Re-run after every code change in this pass, not
  just once at the end: 15/15 dev, 100/100 campaign, 13/13 Era 2
  fixtures, 20/20 T01-T20 tutorial boards solvable (same 6 pre-existing
  cosmetic `optimal_moves`-metadata mismatches as always — T02/T04/T07/
  T10/T14/T20, all genuinely solvable, never load-bearing for tutorials
  per `TUTORIAL_SYSTEM.md` section 10), 10/10 T11-T20 guided step-machine.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded.
  `aapt2 dump badging` confirms `versionCode='36' versionName=
  '3.0.1-ERA2-FOUNDATION-FIX-QA' package='com.beamshift.game'`. File
  size 83,384,755 bytes.
- **MANUAL — pending.** Same real-device checklist as the pass above,
  plus: the new Era 2 Level Complete/Tutorial Complete panel art (does
  the frame read clearly against a real screen; do stars/moves/buttons
  feel cramped), and the new Era 2 Tutorial Select cards (does the
  locked-padlock card read clearly at actual card size on a phone).

## Era 2 Levels 101-110 pass

Full writeup: `DECISIONS.md` D79/D80. Two parts, both user-requested.

### Part A — Tutorial Select button-shape regression

- **MANUAL (user, real device) — FAILED, root cause found and fixed.**
  T11-T20 rendered as tall rectangular "poster" cards instead of the
  established compact square button. Root cause confirmed two
  independent ways: a research subagent's source-level trace, and this
  session's own `Add-Type -AssemblyName System.Drawing` pixel-dimension
  check (`bs_level_card_era2.png` = 1024x1536px vs. the button's
  240x253 box and T01-T10's own 512x540px art).
- **AUTOMATED — DONE.** Both edited scripts (`tutorial_button.gd`,
  `level_button.gd`) load cleanly (`load()` succeeds, no parse errors)
  via a headless `SceneTree` script.
- **RENDERED — DONE** (real GPU render, `godot --path .`, 1080x1920,
  main-scene-swap technique): Tutorial Select screenshot visually
  confirms T11-T18 (as far as the unscrolled view shows) render as the
  identical compact square frame T01-T10 use, tinted violet, labels
  legible, no cropping/poster artifacts.

### Part B — Campaign Levels 101-110

- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.
  analyze()` run against all 10 new level files via a headless script:
  zero validator errors/warnings and `status == "SOLVABLE"` with
  `shortest_solution_count == 1` for all ten, matching every hand-
  derived `optimal_moves` on the first attempt (2,2,2,2,2,2,1,2,1,3).
- **AUTOMATED — DONE (runtime-vs-solver replay, the standard
  regression technique).** A real `GridManager` (via `grid.tscn`)
  replayed each solver's own solution path through
  `_on_orientable_tile_clicked()` (the same entry point a player tap
  uses) for the full dev+campaign+tutorial+fixture population: **15/15
  dev, 110/110 campaign (100 unchanged + 10 new), 20/20 tutorial, 13/13
  Era 2 fixtures** (12 solvable-by-design PASS + `fixture_one_way_
  reflector_hazard` correctly still reports `UNSOLVABLE`, exactly as
  its own header documents it should — a deliberate fixture, not a
  regression) — all PASS.
- **AUTOMATED — DONE (progression/save, real API, not a hand-inspection
  or a faked flag).** A headless main-scene-swap driver: fresh save
  with Levels 1-99 completed shows Level 101 locked; calling the real
  `SaveManager.record_campaign_level_result(100, ...)` (the exact call
  `game.gd` makes) unlocks Level 101 and advances `campaign_highest_
  unlocked_level` to 101; `get_campaign_level(111)` returns `null` with
  a graceful `push_warning`; `EraTheme.get_era_for_level()` reports
  100→Era 1, 101-110→Era 2; both QA unlock-all flags confirmed still
  `true`.
- **RENDERED — DONE** (real GPU render, D45-D47 technique): Levels
  101/103/105/108/110 at 1080x1920, Level 110 additionally at 720x1280
  and 1080x2400 — all inspected directly (not just saved). Confirmed:
  correct Era 2 background/HUD/grid theming, full board utilization
  with content spread across upper/middle/lower thirds, all Era 2
  mechanic types (Prism, One-Way Reflector, Beam Receiver, Remote
  Emitter) and Era 1 selections (Mirror, Portal, Filter, Switch, Gate,
  Splitter, Blocker) visually distinct, beams correctly colored, zero
  HUD overlap or clipping at any tested resolution.
- **AUTOMATED — DONE.** `T11-T20` guided step-machine behavior is
  unchanged from the prior confirmed 10/10 PASS (see the QA/Hardening
  pass section above) — not re-run this pass, since nothing touching
  `TutorialManager`, tutorial level data, or tutorial step logic was
  modified; only `tutorial_button.gd` (Tutorial Select UI, not
  gameplay) changed.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded.
  `aapt2 dump badging` confirms `versionCode='37' versionName=
  '3.1.0-ERA2-L101-110-QA' package='com.beamshift.game'`. File size
  79,298,431 bytes. `unzip -l` confirms all 10 new level `.gdc`/
  `.remap` files present, the two now-orphaned Era 2 card assets
  correctly excluded, `assets/gameplay/pieces/**` still excluded, and
  zero `_qa_tmp_*`/`_tmp_*` files packaged.
- **MANUAL — pending.** This is the user's first chance to play real
  Era 2 gameplay (Levels 101-110) — the actual purpose of this pass.
  Checklist: T11-T20 cards read as a compact square button family on a
  real screen (not the previous poster regression); Levels 101-110 feel
  like a coherent introductory Era 2 arc, not a difficulty cliff after
  Level 100/T20; Prism/One-Way Reflector/Receiver/Remote Emitter all
  feel understandable from in-level reasoning alone; Level 110 feels
  like a real milestone ("now I understand what Era 2 is about").

## Era 2 Levels 111-120 pass

Full writeup: `DECISIONS.md` D81. User-requested follow-up, authorized
before manual Android QA of Levels 101-110 finished. No new mechanics.

- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.
  analyze()` against all 10 new level files: zero validator errors/
  warnings and `status == "SOLVABLE"` for all ten. **Three real
  shortcuts caught this way during authoring, not after**: Level 112
  and 118 each initially solved in fewer moves than declared (a shared
  column let one beam satisfy two targets, or one emitter power two
  receivers); Level 120 initially solved in fewer moves, and after a
  first fix attempt, an exhaustive brute-force replay of every 6-move
  rotation combination (`LaserSystem.simulate_until_stable()` called
  directly for every combination, bypassing the solver's own pruning,
  to enumerate every solution rather than just the first one found)
  confirmed a SECOND, equal-length solution still existed
  (`shortest_solution_count == 2`) before the real structural fix
  brought it back to a unique solution. All ten now match declared
  `optimal_moves` exactly and reach `shortest_solution_count == 1`
  (3,3,3,3,5,2,3,4,4,7).
- **AUTOMATED — DONE (runtime-vs-solver replay).** A real `GridManager`
  replayed each solver's own solution path through `_on_orientable_
  tile_clicked()` for the full dev+campaign+tutorial+fixture
  population: **15/15 dev, 120/120 campaign (110 unchanged + 10 new),
  20/20 tutorial, 13/13 Era 2 fixtures** (12 solvable-by-design PASS +
  `fixture_one_way_reflector_hazard` correctly still `UNSOLVABLE`,
  unchanged) — all PASS.
- **AUTOMATED — DONE (progression, real API).** A headless main-scene-
  swap driver walked the FULL 110->111->112->...->120 chain (not just
  the endpoints): each level's completion via the real `SaveManager.
  record_campaign_level_result()` call correctly unlocks the next;
  `campaign_highest_unlocked_level` reaches 120; `get_campaign_level
  (121)` returns `null` with a graceful `push_warning`; `EraTheme.
  get_era_for_level()` reports Era 2 for all of 111-120; both QA
  unlock-all flags confirmed still `true`.
- **RENDERED — DONE** (real GPU render, D45-D47 technique): Levels
  111/114/115/118/120 at 1080x1920, Levels 111 and 120 additionally at
  720x1280 and 1080x2400 — all inspected directly. Confirmed: correct
  Era 2 theming, full board utilization, all mechanic states correct
  (including Level 120's Remote Emitter correctly rendering INACTIVE at
  first frame, unlike Level 110's — its Receiver genuinely isn't
  powered yet in the authored state), zero HUD overlap or clipping.
- **AUTOMATED — DONE.** T11-T20 guided step-machine not re-run — nothing
  touching `TutorialManager`/tutorial level data/step logic was
  modified this pass.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded.
  `aapt2 dump badging` confirms `versionCode='38' versionName=
  '3.2.0-ERA2-L111-120-QA' package='com.beamshift.game'`. File size
  79,324,957 bytes. `unzip -l` confirms all 20 Levels-101-120 `.gdc`/
  `.remap` files present (40 files), zero `_qa_tmp_*`/`_tmp_*` files
  packaged.
- **MANUAL — pending.** Levels 101-110 are still awaiting their own
  first manual playthrough; Levels 111-120 add to that same backlog.
  Checklist: Levels 111-120 feel clearly harder than 101-110 through
  reasoning (dependency depth, shared resources, misleading local
  solutions) rather than tile count or grid size; Level 112's shared
  One-Way Reflector and Level 118's shared gate both feel like genuine
  "aha" moments once understood, not confusing; Level 120 feels
  meaningfully harder than Level 110.

## Era 2 Levels 121-130 pass

Full writeup: `DECISIONS.md` D82. "Deep dependency pass" - user-
requested, authorized before ANY prior Era 2 level batch had received
manual Android QA. No new mechanics.

- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.
  analyze()` against all 10 new level files. **Level 123 initially
  failed validation outright** (a Portal and Remote Emitter placed one
  row outside a `grid_height=9` board) - `LevelValidator`'s own
  explicit position-bounds check caught this immediately, before the
  solver ever ran; fixed by growing the board to `grid_height=10`.
  **Level 127 initially solved in 2 moves instead of the intended 4** -
  a shortcut, not a bounds error; see the `DECISIONS.md` D82 writeup
  for the full trace (a stray beam crossing a second, unrelated mirror
  whose own default orientation completed an accidental Portal-
  bypassing shortcut). Fixed with a precisely placed `BLOCKER`,
  re-verified via the solver to intercept only the stray path. All ten
  now match declared `optimal_moves` exactly and reach
  `shortest_solution_count == 1` (5,4,3,4,4,2,4,4,5,7).
- **AUTOMATED — DONE (runtime-vs-solver replay).** A real `GridManager`
  replayed each solver's own solution path for the full dev+campaign+
  tutorial+fixture population: **15/15 dev, 130/130 campaign (120
  unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures** (12
  solvable-by-design PASS + `fixture_one_way_reflector_hazard`
  correctly still `UNSOLVABLE`, unchanged) — all PASS.
- **AUTOMATED — DONE (progression, real API).** A headless main-scene-
  swap driver walked the FULL 120->121->122->...->130 chain: each
  level's completion via the real `SaveManager.record_campaign_level_
  result()` call correctly unlocks the next; `campaign_highest_
  unlocked_level` reaches 130; `get_campaign_level(131)` returns `null`
  with a graceful `push_warning`; `EraTheme.get_era_for_level()`
  reports Era 2 for all of 121-130; both QA unlock-all flags confirmed
  still `true`.
- **RENDERED — DONE** (real GPU render, D45-D47 technique): Levels
  121/124/125/128/129/130 at 1080x1920, Level 130 additionally at
  720x1280 and 1080x2400 — all inspected directly. Confirmed: correct
  Era 2 theming, full board utilization, gates/switches/receiver/
  inactive-remote-emitter/OWR-chevron-indicators all legible, zero HUD
  overlap or clipping.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded.
  `aapt2 dump badging` confirms `versionCode='39' versionName=
  '3.3.0-ERA2-L121-130-QA' package='com.beamshift.game'`. File size
  79,355,579 bytes. `unzip -l` confirms all 30 Levels-101-130 `.gdc`/
  `.remap` files present (60 files), zero `_qa_tmp_*`/`_tmp_*` files
  packaged.
- **MANUAL — pending.** All three Era 2 level batches (101-110,
  111-120, 121-130) are now awaiting their first manual playthrough
  together. Checklist: Levels 121-130 feel like genuine whole-board
  puzzles, not single-chain puzzles with more tiles; Level 121's shared
  reflector and Level 130's four-way convergence both feel like real
  "aha" moments; Level 125's near-solution trap feels fair (discoverable
  through in-level reasoning) rather than arbitrary; Level 130 feels
  like a genuine step up from Level 120, not just a bigger board.

## Era 2 Levels 131-140 pass

Full writeup: `DECISIONS.md` D83. "Advanced convergence pass" -
user-requested, explicitly authorized before ANY of the three prior
Era 2 level batches had received manual Android QA. No new mechanics.

- **AUTOMATED — DONE.** `LevelValidator.validate()` + `LevelSolver.
  analyze()` against all 10 new level files. **Level 133 initially
  reported `UNSOLVABLE`** - not a bounds error this time but a genuine
  authoring mistake (a second mirror inserted into an already-complete
  straight path made its own target permanently unreachable, since a
  mirror always bends and can never let a beam continue straight);
  fixed by removing the superfluous mirror. **Levels 134, 137, and 138
  each initially solved in fewer moves than declared** - three separate
  shortcuts, all traced in full in `DECISIONS.md` D83 (two variants of
  the established `WHITE`-target-bypass bug, and one genuinely new
  failure shape in Level 138 requiring a full geometric rebuild of the
  shared reflector's approach directions). All ten now match declared
  `optimal_moves` exactly and reach `shortest_solution_count == 1`
  (6,4,3,5,3,5,4,2,6,8).
- **AUTOMATED — DONE (runtime-vs-solver replay).** A real `GridManager`
  replayed each solver's own solution path for the full dev+campaign+
  tutorial+fixture population: **15/15 dev, 140/140 campaign (130
  unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures** (12
  solvable-by-design PASS + `fixture_one_way_reflector_hazard`
  correctly still `UNSOLVABLE`, unchanged) — all PASS.
- **AUTOMATED — DONE (progression, real API).** A headless main-scene-
  swap driver walked the FULL 130->131->132->...->140 chain: each
  level's completion via the real `SaveManager.record_campaign_level_
  result()` call correctly unlocks the next; `campaign_highest_
  unlocked_level` reaches 140; `get_campaign_level(141)` returns `null`
  with a graceful `push_warning`; `EraTheme.get_era_for_level()`
  reports Era 2 for all of 131-140; both QA unlock-all flags confirmed
  still `true`.
- **RENDERED — DONE** (real GPU render, D45-D47 technique): Levels
  131/133/135/138/139/140 at 1080x1920, Level 140 additionally at
  720x1280 and 1080x2400 — all inspected directly. Confirmed: correct
  Era 2 theming, full board utilization, both instances of a shared
  Portal pair labeled consistently, gates/switches/receivers/inactive-
  remote-emitters/reflector-chevron-indicators all legible, zero HUD
  overlap or clipping.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` succeeded.
  `aapt2 dump badging` confirms `versionCode='40' versionName=
  '3.4.0-ERA2-L131-140-QA' package='com.beamshift.game'`. File size
  79,386,201 bytes. `unzip -l` confirms all 40 Levels-101-140 `.gdc`/
  `.remap` files present (80 files), zero `_qa_tmp_*`/`_tmp_*` files
  packaged.
- **MANUAL — pending, and now explicitly flagged as a checkpoint.**
  Four consecutive Era 2 campaign batches (101-110, 111-120, 121-130,
  131-140 — 40 levels total) are now awaiting their first manual
  playthrough together, per the user's own explicit STOP-CONDITION
  instruction to recommend a review checkpoint here. Checklist: Levels
  131-140 feel like genuine advanced convergence (multiple subsystems
  understood simultaneously), not just harder single-chain puzzles;
  Level 131's shared reflector (two Prism colors, two directions) and
  Level 140's four-subsystem milestone both feel like real "aha"
  moments; Level 138's opposite-side reflector approach reads clearly
  once solved; Level 140 feels like a genuine, understandable step up
  from Level 130.

## Phase 1: Shared Adaptive Gameplay Layout Foundation (2026-09-23, `versionCode=41`)

See `DECISIONS.md` D84 for the full writeup. This pass added
`GridManager.MAX_COLUMNS`, `GridManager.MIN_COMFORTABLE_CELL_SIZE`, and
`GridManager.is_board_profile_comfortable()` (purely additive — no
existing function's body changed) and touched no level data, `game.tscn`,
or `LaserSystem`/solver code.

### Column audit (report only)

Grep-audited `grid_width` across every level file:

| Population | Total | Exceed `MAX_COLUMNS`=8 |
|---|---|---|
| Dev/regression (`level_01`-`15`) | 15 | 0 |
| Campaign (`stage_01`-`10` + `era2_stage_01`) | 140 | 54 |
| Tutorial (`t01`-`t20`) | 20 | 1 (T20, width 9) |
| Editor fixtures (main + `era2/`) | 24 | 3 (`fixture_rect_9x10`, `fixture_one_way_reflector_chain`, `fixture_receiver_portal_splitter`) |

All grandfathered as legacy/regression content — zero files modified.

### Resolution / board-profile diagnostic (AUTOMATED — DONE)

Throwaway headless script (`--headless --path . --script <path>.gd`)
built the same node structure as `game.tscn` in a bare `SceneTree`
(`SafeAreaMargin`→`Layout` `VBoxContainer`→`TopBar`/`BottomBar`
`AspectBar` at `game.tscn`'s real aspect ratios→`CenterArea`→a real
`grid.tscn` instance), drove it at all 5 required logical resolutions,
and read `get_layout_metrics()`/`is_board_profile_comfortable()` for 12
representative procedural-shaped profiles (5-8 columns × 7/9/11 rows).
Full output:

```
=== 720x1280 (physical) -> logical 1080x1920 ===
CenterArea rect: (888.0, 1069.0)
  5x7 cell=150px wUse=86.0% hUse=99.7% -> COMFORTABLE
  5x9 cell=117px wUse=67.1% hUse=100.0% -> COMFORTABLE
  5x11 cell=95px wUse=54.5% hUse=99.2% -> FAIL (below MIN_COMFORTABLE_CELL_SIZE)
  6x7 cell=145px wUse=99.8% hUse=96.4% -> COMFORTABLE
  6x9 cell=117px wUse=80.5% hUse=100.0% -> COMFORTABLE
  6x11 cell=95px wUse=65.4% hUse=99.2% -> FAIL
  7x7 cell=124px wUse=99.5% hUse=82.4% -> COMFORTABLE
  7x9 cell=117px wUse=93.9% hUse=100.0% -> COMFORTABLE
  7x11 cell=95px wUse=76.3% hUse=99.2% -> FAIL
  8x7 cell=109px wUse=100.0% hUse=72.5% -> COMFORTABLE
  8x9 cell=109px wUse=100.0% hUse=93.2% -> COMFORTABLE
  8x11 cell=95px wUse=87.2% hUse=99.2% -> FAIL

=== 1080x1920 (physical) -> logical 1080x1920 ===
(identical to 720x1280 above — same logical canvas, D43)

=== 1080x2160 (physical) -> logical 1080x2160 ===
CenterArea rect: (888.0, 1309.0)
  5x7..8x11: ALL COMFORTABLE (cell 109-174px, wUse 99.5-100%, hUse 59.0-99.5%)

=== 1080x2400 (physical) -> logical 1080x2400 ===
CenterArea rect: (888.0, 1549.0)
  5x7..8x11: ALL COMFORTABLE (cell 109-174px, wUse 99.5-100%, hUse 49.8-99.8%)

=== 1080x2560 (physical) -> logical 1080x2560 ===
CenterArea rect: (888.0, 1709.0)
  5x7..8x11: ALL COMFORTABLE (cell 109-174px, wUse 99.5-100%, hUse 45.1-99.4%)
```

**Result: 136/140 combinations COMFORTABLE.** The only FAILs are 11-row
profiles at every column count (5-8) on the two shortest logical heights
(1920px, i.e. 720x1280 and 1080x1920 physical) — `cell_size` lands at
95px, one pixel under `MIN_COMFORTABLE_CELL_SIZE=96`. Every 7-row and
9-row profile is comfortable across the entire matrix. Guideline for a
future generator: **prefer ≤9 rows at 5-8 columns** for guaranteed
comfort on the shortest supported device height.

### Full regression (AUTOMATED — DONE)

Runtime-vs-solver replay, run after the `grid_manager.gd` change, across
every population (throwaway `--headless --path . --script` driver, same
technique as every prior pass in this file):

```
DEV: 15/15 PASS
CAMPAIGN: 140/140 PASS
TUTORIAL: 20/20 PASS
ERA2-FIXTURE: 12/12 PASS
ERA2-FIXTURE-UNSOLVABLE: 1/1 PASS (confirmed UNSOLVABLE as designed)

=== TOTAL: 188 PASS / 0 FAIL ===
```

Zero regression from the purely-additive `grid_manager.gd` change.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` — see this pass's
  final report for the exact `aapt2 dump badging`/`unzip -l` output.
- **MANUAL — pending.** Per the spec's own 18-point Android manual QA
  checklist (this pass's final report) — the user will test the layout
  on a real device before any Phase 2 (Direct Play/Continue, procedural
  generator) work begins.

## Phase 2: Direct Play + Continue Flow (2026-09-23, `versionCode=42`)

See `DECISIONS.md` D85 for the full writeup.

### Resume-flow test (AUTOMATED — DONE, 19/19 PASS)

Needs real autoload initialization (`SaveManager`/`GameManager`/
`LevelManager`), so a `--script`-mode `SceneTree` driver won't work (D7)
- used the documented `run/main_scene` temporary-swap technique instead.
This dev machine's own real save file (140/140 campaign + 10/10 tutorial
already completed) was backed up before running and restored byte-for-
byte after. Full output:

```
=== TOTAL: 19 PASS / 0 FAIL ===
```

Covered: fresh-save `has_resumable_campaign_game()` false; `start_
campaign_resume()` sets the resume pointer and enables it; `update_
campaign_resume_state()`/`get_campaign_resume_orientations()` round-trip
orientations and move count correctly; a second `start_campaign_resume()`
call (simulating Reset) clears orientations/move count back to fresh
without losing the level pointer; `record_campaign_level_result()` +
`start_campaign_resume()` correctly advances the tracked resume level;
a fully-completed 140-level campaign clamps `LevelManager.
get_campaign_continue_level_id()` to 140 (never attempts 141); a real
`GridManager.restore_orientations()` call against a real campaign level
(`campaign/stage_01/level_01.gd`) correctly updates both `tile_
orientations` and the target node's own `.orientation` together, and a
second call correctly restores the original orientation back.

Test driver files (`_phase2_test_driver.gd`/`.tscn`) and the temporary
`run/main_scene` swap were deleted/reverted immediately after use, never
committed - confirmed via `git status` showing zero stray files.

### Full regression (AUTOMATED — DONE)

Re-ran the same runtime-vs-solver replay driver from Phase 1 (no level/
solver code touched this pass, so no change was expected):

```
DEV: 15/15 PASS
CAMPAIGN: 140/140 PASS
TUTORIAL: 20/20 PASS
ERA2-FIXTURE: 12/12 PASS
ERA2-FIXTURE-UNSOLVABLE: 1/1 PASS (confirmed UNSOLVABLE as designed)

=== TOTAL: 188 PASS / 0 FAIL ===
```

### Main Menu RENDERED verification (AUTOMATED/RENDERED — DONE)

This dev machine's physical screen height couldn't fit an actual
1920px/2400px-tall window, so rendering used aspect-ratio-matched
smaller physical sizes instead (500x889 for the 720x1280/1080x1920 9:16
ratio, 450x1000 for the 1080x2400 ratio) - `canvas_items`/`expand`
stretch mode means the logical canvas proportions are what determine
layout, confirmed identical to the true target resolutions by Phase 1's
own diagnostic. Both renders confirmed: `CONTINUE`/`PLAY`/`TUTORIAL`/
`SETTINGS`/`QUIT` in the correct order, `PLAY` text (not "CAMPAIGN"),
`CONTINUE` visibly greyed/disabled and legible (the real dev save has no
`campaign_resume_level_id` yet, pre-Phase-2 - correctly shows disabled,
exercising the documented one-time migration limitation for real), no
stray CAMPAIGN button, the new small "Level Select (QA)" button
correctly low-prominence at the very bottom, no overlap or clipping.
Screenshot driver files were deleted immediately after use, never
committed.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` — see this pass's
  final report for the exact `aapt2 dump badging`/`unzip -l` output.
- **MANUAL — pending.** Per this pass's own Android manual QA checklist
  (final report) — on top of Phase 1's own still-outstanding review.

## Full-Screen Board Correction (2026-09-23, `versionCode=43`)

See `DECISIONS.md` D86 for the full writeup. Corrects a real bug the
user found on a real Android phone testing `versionCode=42` (Level 27
rendering with large wasted vertical space). This time, non-headless
rendered validation of REAL campaign levels (not just a synthetic
diagnostic) was performed first and is the primary evidence, per the
spec's explicit "rendered visual validation is required" instruction.

### Root-cause investigation (RENDERED)

Rendered the real `game.tscn` with Level 27 (7x8, "Impasse") loaded via
a temporary `run/main_scene`-swap driver, at both the 1080x1920
reference and the 1080x2400 aspect ratio (scaled to fit this dev
machine's screen), dumping the actual `Control` rect chain:

```
1080x1920: TopBar=313 BottomBar=313 CenterArea=888x1069
           cell=124  wUse=99.5%  hUse=94.2%   (matches Phase 2B's D74 claim)
1080x2400: TopBar=313 BottomBar=313 CenterArea=888x1549
           cell=124  wUse=99.5%  hUse=64.7%   (same cell_size, height utilization collapses)
```

Confirmed: `cell_size` is identical at both resolutions (width-bound,
already maximized for the 872px available width) - the degradation is
purely `CenterArea` growing taller on the taller device without the
board growing to match. This is the root cause: Phase 1's own
5-resolution diagnostic (`DECISIONS.md` D84) measured this exact
pattern for synthetic profiles but nobody rendered a REAL level at more
than the one reference resolution to see it visually.

### Margin candidate sweep (AUTOMATED)

Swept `SafeAreaMargin.margin_override` against Level 27 at 1080x2400:

```
margin=96  cell=124  hUse=64.7%
margin=64  cell=133  hUse=68.6%
margin=48  cell=138  hUse=70.7%
margin=32  cell=142  hUse=72.3%
margin=24  cell=145  hUse=73.7%
margin=16  cell=147  hUse=74.4%
```

Strongly diminishing returns below 32px (96→32: +14.5% cell size;
32→16: only +3.5% more) - 32 chosen as the point past which further
reduction buys little while risking the board/HUD hugging the screen
edge with too little breathing room.

### Full resolution × profile matrix (AUTOMATED, real `game.tscn`)

Re-ran Phase 1's 5-resolution × 12-profile diagnostic, this time
instantiating the real `game.tscn` (so it automatically picks up the
`margin_override=32` fix) instead of a hand-built node tree:

```
720x1280/1080x1920 (identical logical canvas): worst case 5x11/6x11/
  7x11/8x11 all now cell=99px (was 95px in Phase 1) - all COMFORTABLE
1080x2160: all COMFORTABLE, cell 121-190px
1080x2400: all COMFORTABLE, cell 125-200px
1080x2560: all COMFORTABLE, cell 125-200px
```

**Result: 140/140 COMFORTABLE** (up from Phase 1's 136/140 - the margin
reduction pushed every previously-borderline 95px cell above
`MIN_COMFORTABLE_CELL_SIZE=96`).

### RENDERED visual validation (RENDERED — DONE, as explicitly required)

Rendered 5 real levels/tutorial at the 1080x2400 aspect ratio (scaled
to 450x1000 to fit this dev machine's screen) and visually inspected
each:

- **Level 1** "Ignition" (5x6, small board) — fills the screen well,
  large comfortable tiles.
- **Level 27** "Impasse" (7x8, the reported case) — board and tiles
  visibly larger than the before-fix render (direct before/after
  comparison performed); remains the "loosest" of the five, consistent
  with its width-bound 7:8 shape, but meaningfully improved.
- **Level 100** "Culmination" (10x12, tall/dense board) — fills nearly
  the entire CenterArea, minimal gap.
- **Era 2 Level 110** "Refraction Nexus" (8x10, `MAX_COLUMNS` board) —
  fills the screen well, themed Era 2 art renders correctly.
- **Tutorial T01** "First Light" (5x5) — fills the screen well,
  tutorial panel/QA overlay render correctly, no regression.

All screenshots were captured, visually inspected, and deleted after
use (temporary driver, never committed).

### Regression (AUTOMATED)

Full runtime-vs-solver replay, unchanged (no puzzle/solver code
touched):

```
DEV: 15/15 PASS
CAMPAIGN: 140/140 PASS
TUTORIAL: 20/20 PASS
ERA2-FIXTURE: 12/12 PASS
ERA2-FIXTURE-UNSOLVABLE: 1/1 PASS (confirmed UNSOLVABLE as designed)

=== TOTAL: 188 PASS / 0 FAIL ===
```

Dedicated Phase 2 (Direct Play + Continue) re-check, since this pass
touches `game.tscn` (which Phase 2's resume logic also reads):

```
=== PHASE 2 RE-CHECK: 12 PASS / 0 FAIL ===
```

Covered: fresh-save resolve to Level 1, a real level entry sets the
resume pointer, a real player move (via `_on_orientable_tile_clicked()`)
persists orientation + move count, re-entering the same level restores
both via `restore_orientations()`, Reset clears them back to fresh,
completing a level advances the resume pointer, and a QA Level Select
entry still never touches resume state.

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` — see this pass's
  final report for the exact `aapt2 dump badging`/`unzip -l` output.
- **MANUAL — pending.** The user must install this APK and visually
  approve the board sizing on a real phone before any procedural
  generator work begins, per this pass's own STOP CONDITION.

## Final Gameplay Spacing Refinement (2026-09-23, `versionCode=44`)

See `DECISIONS.md` D87 for the full writeup. The user manually tested
`versionCode=43` and confirmed it "close to the desired result" — this
pass tightens Top/Bottom HUD toward the screen edge without touching
tile size or the D86 left/right margin.

### Margin candidate sweep (AUTOMATED)

Swept `SafeAreaMargin.vertical_margin_override` against Level 28 (6x7,
the reference level) at 1080x2400:

```
vMargin=32  TopBarY=32  cell=166  total_top_space=619
vMargin=24  TopBarY=24  cell=166  total_top_space=619
vMargin=16  TopBarY=16  cell=166  total_top_space=619
vMargin=8   TopBarY=8   cell=166  total_top_space=619
vMargin=0   TopBarY=0   cell=166  total_top_space=619
```

Confirms the mathematical derivation in `DECISIONS.md` D87:
`total_top_space` (margin + separation + board-centering offset) is
**exactly invariant** to the vertical margin for a width-bound board —
only `TopBarY` (the HUD bar's own screen position) moves. `cell_size`
is also unaffected (still width-bound, still 166px). Chose
`vertical_margin_override = 8` (matching `GRID_SAFETY_MARGIN`'s own 8px
precedent) since it's mathematically free (no cost to the gap either
way) and maximizes the one real, deliverable improvement (HUD closer to
the edge).

### Full resolution × profile matrix (AUTOMATED)

Re-ran the 5-resolution × 12-profile diagnostic — unchanged at
**140/140 COMFORTABLE** (expected: vertical margin doesn't affect
`cell_size`, only horizontal margin does, and that wasn't touched this
pass).

### RENDERED visual validation (RENDERED — DONE)

Rendered 6 real levels/tutorial at the 1080x2400 aspect ratio (scaled
to fit this dev machine's screen) and at the 1080x1920 reference for
Level 28 specifically:

- **Level 28** "Gambit" (6x7, the reference level) — direct before
  (`vertical_margin=32`, via `git stash`) / after (`vertical_margin=8`)
  comparison performed. At 1080x2400: HUD bars visibly closer to the
  screen edge; board composition otherwise unchanged (as the math
  predicts). At the 1080x1920 reference: nearly fully filled (97.2%
  width / 99.6% height utilization) — HUD close to edge, minimal gap,
  matches the target diagram closely.
- **Level 27** "Impasse" (7x8, D86's original reported case) — HUD
  visibly tighter to the edge, board fill unchanged from D86.
- **Level 1** "Ignition" (5x6), **Level 100** "Culmination" (10x12),
  **Era 2 Level 110** "Refraction Nexus" (8x10), **Tutorial T01** "First
  Light" (5x5) — all render correctly, HUD fully visible and legible at
  the tighter margin, no clipping, no overlap, QA debug overlay and
  tutorial panel unaffected.

All screenshots captured, visually inspected, then deleted (temporary
driver, never committed).

### Regression (AUTOMATED)

Full runtime-vs-solver replay, unchanged:

```
DEV: 15/15 PASS
CAMPAIGN: 140/140 PASS
TUTORIAL: 20/20 PASS
ERA2-FIXTURE: 12/12 PASS
ERA2-FIXTURE-UNSOLVABLE: 1/1 PASS (confirmed UNSOLVABLE as designed)

=== TOTAL: 188 PASS / 0 FAIL ===
```

Phase 2 (Direct Play + Continue) re-check, since this pass again
touches `game.tscn`:

```
=== PHASE 2 RE-CHECK (D87): 12 PASS / 0 FAIL ===
```

### Android build

- **AUTOMATED — DONE.** `godot --headless --path . --export-debug
  "Android Debug" builds/android/beamshift-debug.apk` — see this pass's
  final report for the exact `aapt2 dump badging`/`unzip -l` output.
- **MANUAL — pending.** The user must install this APK and visually
  approve the final gameplay layout on a real phone before any
  procedural generator work begins, per this pass's own STOP CONDITION.

## Phase 3: Procedural Level Generator V1 + QA Next button

See `PROCEDURAL_GENERATION.md` for the full architecture and
`DECISIONS.md` D88 for the implementation writeup. This section is the
test record only.

### Full 1-2000 generator audit (AUTOMATED — DONE)

Dev-only driver (`scripts/tools/procedural_audit.gd`'s `audit_range(1,
2000, true)`, temporary `--headless --path . --script <driver>.gd`
invocation, never committed — per this project's own scratchpad rule)
exercising the REAL `LevelSolver`/`LevelValidator` against every
generated level, not an approximation:

```
=== FULL 1-2000 AUDIT (WITH real solver) ===
elapsed_ms=278061  total=2000  fail_count=0  fallback_count=0
optimal_moves min=1 median=6 p95=10 max=14
states_explored min=2 median=502 p95=7814 max=65519
gen_us median=241 p95=681 max=1779  (sum_ms=616)
solve_us median=24770 p95=553881 max=7738718  (sum_ms=277189)
non_unique_shortest_solution_count (informational, not a failure): 20

=== DETERMINISM (11-level sample) ===
Level 1/10/100/250/500/750/1000/1250/1500/1750/2000: all MATCH

=== DIFFICULTY DISTRIBUTION (bands) ===
Introductory 50, Easy/Developing 100, Medium 250, Medium-Hard 350,
Hard 450, Expert 400, Advanced Expert 400
```

Template distribution (all 10 templates used, none starved — see
DECISIONS.md D88 for the selection-logic bug this caught): `simple_
mirror_route` 75, `color_filter_route` 275, `multi_mirror_route` 176,
`splitter_branch` 275, `portal_route` 247, `switch_gate_dependency` 252,
`multiple_emitter` 200, `one_way_directional_route` 201, `prism_
color_branch` 150, `receiver_remote_emitter` 149.

This full-range run supersedes the spec's own narrower "representative
batch" (1-20, 45-55, 95-105, 245-255, 495-505, 745-755, 995-1005,
1245-1255, 1495-1505, 1745-1755, 1990-2000) — that range is a strict
subset of 1-2000, so no separate pass was needed once the full range
proved inexpensive enough (278s) to run exhaustively in one sitting.

### Rendered visual tests (RENDERED — DONE for a representative subset)

Non-headless real-rendering technique (D45-47), temporary render driver
(deleted after use): procedural Level 1 at ~1080x1920 (`--resolution
1080x1920`), Level 1000 at ~720x1280, Level 2000 at ~1080x2400. All
three: board fills the available space correctly, HUD legible, `%QANext
Button` (`NEXT >>`) visible and readable in its hex-frame slot, no
clipping. One real bug found and fixed this way (not by headless
checks) — see DECISIONS.md D88: the QA Next button's first placement
used the wrong vertical anchor and was invisible in the actual render
despite `.visible == true` in code.

Caveat: `--resolution` did not reliably force the exact requested
PHYSICAL window size on this dev machine (Windows DPI/window-manager
behavior) — the reported logical viewport sizes didn't precisely match
720x1280/1080x1920/1080x2400. This is a supplementary qualitative check
only; the authoritative, resolution-independent proof is the headless
`GridManager.is_board_profile_comfortable()` check against
`ProceduralDifficultyProfile.REFERENCE_PLAYABLE_SIZE` (the documented
1080x1920-floor technique, per CLAUDE.md rule 12b/D43), which the full
1-2000 audit above already confirms passes for every generated level.
**Full 8-level x 3-resolution rendered matrix (Levels 1/50/100/250/500/
1000/1500/2000) was NOT completed** — only the 3 samples above — a
reasonable time/value tradeoff for V1 given the headless comfort check
already covers every level exhaustively; expand this if a future pass
wants broader RENDERED-tier coverage.

### Legacy regression (AUTOMATED — DONE)

Separate temporary driver (real autoloads, per this file's own
autoload-dependent-scene technique; real `savegame.json` backed up
before and restored after):

```
Campaign 1/50/100/140 (QA Level Select, solved via real solver path): is_solved=true, entered_via_level_select=true, is_procedural_mode=false — 4/4 PASS
Dev levels 1/15: solver=SOLVABLE, optimal_moves unchanged (1, 2) — 2/2 PASS
Tutorial T01/T20: loads into Game, is_tutorial_mode=true, no crash — 2/2 PASS
Editor-playtest hand-off: is_editor_playtest=true, unaffected — 1/1 PASS
```

Zero `LaserSystem`/`GridTypes`/campaign/tutorial/dev-level code was
touched by this phase — every `game.gd` change is a new `elif` branch
alongside the pre-existing ones (confirmed by direct diff of the
surrounding `if`/`elif`/`else` structure), so the full 188-level replay
suite from prior passes was not re-run in full; this targeted sample
covers every population it draws from.

### End-to-end procedural runtime test (AUTOMATED — DONE)

Temporary autoload driver (real autoloads; real `savegame.json` backed
up before and restored after both driver runs used in this phase):

```
PHASE 1 (fresh save, PLAY, one move): resume persists (level/moves/orientations) — PASS
PHASE 2 (simulated relaunch, CONTINUE): exact board state restored (moves + orientations) — PASS
PHASE 3 (legitimate solve of the real next-in-line level): procedural_current_level advances — PASS
QA Next (from the just-completed level): advances the VIEWED level only, procedural_current_level unchanged — PASS
Solving the QA-Next-skipped-to level (not next-in-line): procedural_current_level does NOT advance — PASS
Level 2000 completion: is_solved=true, procedural_current_level -> 2001, no crash, Next hidden — PASS
```

A real design gap was found only by this end-to-end test, not code
review — `continue_game()` originally targeted `procedural_current_level`
(same as `play_game()`), which does not correctly resume a QA-Next-ahead
session. Fixed; see DECISIONS.md D88.

### Android build

- **AUTOMATED — DONE.** See this pass's final report for the exact
  `godot --headless --path . --export-debug "Android Debug" builds/
  android/beamshift-debug.apk` / `aapt2 dump badging` / `unzip -l`
  output.
- **MANUAL — pending.** Same as every prior pass's own outstanding
  review — this build has not been installed/reviewed on a real device.

### Release checklist (procedural-specific, additive)

- [ ] `LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON` set to `false`.
- [ ] (Pre-existing, still pending, unrelated to this phase)
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` / `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` set to `false`.
- [ ] Manual Android review of representative procedural levels across
  the 1-2000 range — this pass is AUTOMATED/RENDERED-verified only, per
  CLAUDE.md rule 12d's vocabulary.

## Audio/SFX Integration Pass (versionCode 46, "4.0.1-AUDIO-SFX-QA")

See `AUDIO_SYSTEM.md` for the full architecture and `DECISIONS.md` D89
for the implementation writeup. This section is the test record only.

### Asset validation (AUTOMATED — DONE)

Confirmed directly (`ls -la assets/sfx/*.ogg`, `git status`): all 22
files present at `res://assets/sfx/`, each with a `.import` sibling
already generated, all non-zero length (4.5 KB - 29 KB), none excluded
by `export_presets.cfg`'s `exclude_filter`. No file was missing or
substituted.

### AudioManager + GridManager integration (AUTOMATED — DONE)

Temporary driver (`scripts/tools/_qa_audio_driver.gd`/`.tscn`, deleted
before this pass ended — per D78's "temporary QA files never survive a
pass" rule), `run/main_scene` temporarily pointed at it, run via
`godot --headless --path .` with a timeout, `run/main_scene` reverted
immediately after (confirmed via `grep`):

```
=== QA AUDIO DRIVER START ===
Loaded campaign level 1: Ignition grid=5x6
Initial simulate OK. is_solved=false orientable tiles=1
AudioManager loaded streams: 22/22
ALL 22 SFX STREAMS LOADED OK
Simulating player tap at (3, 5)
Tap 1 OK. is_solved=true
Tap 2 OK. is_solved=true
Any pooled voice has a stream assigned: true
restore_orientations OK, is_solved=true
=== QA AUDIO DRIVER END ===
```

Confirms: all 22 `AudioStream` resources load without error
(`ResourceLoader.exists()` + `load()` both succeed for every path); a
real player-tap rotation through `GridManager._on_orientable_tile_clicked()`
runs end-to-end with no crash (this is the exact call path that fires
`mirror_rotate`, `laser_reflect`/`target_activate`/`puzzle_solved` for
Level 1's single-mirror solve); a second tap on an already-solved board
is a correct no-op (`is_solved` stays `true`, no double-fire); and
`restore_orientations()` (the Continue/resume code path) completes with
no crash. No script/parse errors anywhere in the headless log (`grep -i
"parse error\|script error"` against the full run: zero matches), before
and after this pass's full script edit set.

### No level/puzzle regression risk (AUTOMATED — verified by inspection)

`laser_system.gd`/`grid_types.gd`/`scripts/procedural/**`/
`scripts/tools/procedural_audit.gd`/`level_solver.gd`/`level_validator.gd`/
`level_metrics.gd`/every campaign/tutorial/dev level file/`LevelData`/
`TilePlacement` — all untouched (grep-confirmed zero references to
`AudioManager`/`assets/sfx` anywhere outside the files listed in
`DECISIONS.md` D89's "Modified" list). No re-run of the 15-level dev
regression suite or the 1-2000 procedural audit was needed, since no
simulation-affecting file changed.

### Android build

- **AUTOMATED — DONE.** See this pass's final report for the exact
  `godot --headless --path . --export-debug "Android Debug" builds/
  android/beamshift-debug.apk` / `aapt2 dump badging` / `unzip -l`
  output, including confirmation that `assets/sfx/*.ogg` are present in
  the real exported `.apk` (not just editor import status).
- **MANUAL — pending.** Same as every prior pass's own outstanding
  review — this build has not been installed/reviewed on a real device.

### What could NOT be tested headlessly (MANUAL TEST REQUIRED)

Per CLAUDE.md's standing rule against claiming a manual-only test was
automated — see `AUDIO_SYSTEM.md` section 15 for the full checklist:
perceived loudness/gain balance on a real phone speaker, whether the
Puzzle Solved → (0.8s) → Level Complete sound pairing feels cluttered,
whether Settings' Sound toggle audibly mutes/restores correctly and
persists across an app restart, and whether Continue genuinely produces
no audible burst on a real device (the headless test above proves the
CODE PATH taken is the silent one — `_simulate_and_draw(false)` — not
that a real device's audio output is actually silent during that call).

### Release checklist (audio-specific, additive)

- [ ] (Pre-existing, still pending, unrelated to this phase)
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` /
  `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` /
  `SHOW_PROCEDURAL_QA_NEXT_BUTTON` set to `false`.
- [ ] Manual Android audio QA — see `AUDIO_SYSTEM.md` section 15's full
  checklist. This pass is AUTOMATED-verified only, per CLAUDE.md rule
  12d's vocabulary — no MANUAL (real-device) audio review has occurred.

## Minimal Gameplay Background Pass (versionCode 47, "4.0.3-MINIMAL-BG-QA")

See `DECISIONS.md` D90 for the full investigation/decision writeup and
`ARCHITECTURE.md`'s "Gameplay background — minimal treatment" section
for the mechanism. This section is the test record.

### Environment finding: on-screen window capture was silently wrong on this machine (RENDERED — DONE)

Before any before/after comparison could be trusted, a real bug in the
test technique itself was found and fixed. This machine's physical
monitor is a 2560x1080 ultrawide (`[System.Windows.Forms.Screen]::
AllScreens`, `WorkingArea` height 1032). A plain
`godot --path . --resolution 1080x1920 <driver>.tscn` (no `--headless`)
came back with an actual captured `get_viewport().get_texture()` image
of **1080x1061**, not 1080x1920 — Windows silently clamped the window to
the monitor's work-area height, and `canvas_items`/`expand` stretch mode
then reflowed the ENTIRE logical layout to that clamped near-square
aspect ratio instead of the intended portrait one (confirmed by directly
measuring the saved PNG's pixel dimensions with
`System.Drawing.Image`, not by trusting the `--resolution` flag's
request). This means every resolution check on this machine before this
pass that used a real on-screen window and assumed the requested size
was actually applied should be treated with suspicion unless its saved
image dimensions were independently verified.

**Fix, now the standing technique for any future resolution-matrix
RENDERED check on this machine**: reparent the live scene
(`get_tree().current_scene`) out of `root` and into a temporary
`SubViewport` with an explicit `.size` set to the exact target
resolution, wait 2-3 `process_frame`s + one `RenderingServer.
frame_post_draw`, capture `SubViewport.get_texture().get_image()`, then
reparent the scene back to `root` before advancing to the next level (so
the next `GameManager.start_level()`/`start_procedural_level()`'s
`change_scene_to_file()` call frees the correct node normally). A
SubViewport's `size` is independent of the physical display, and a
Control inside it resolves `get_viewport().get_visible_rect()` to the
SubViewport itself, so `grid_manager.gd`'s existing layout math needs no
special-casing at all — this technique is a drop-in replacement for a
plain on-screen window capture, not a new, separate code path to
maintain.

One other driver-only pitfall found and fixed along the way: a driver
`.tscn` passed positionally on the command line starts out AS
`tree.current_scene`, so the very first
`GameManager.start_level()`/`start_procedural_level()` call frees the
driver itself (its own script instance), not the old game scene —
`get_tree()` then returns null inside the driver's own still-running
`await` chain. Fix: `get_tree().current_scene = null` once in the
driver's `_ready()`, before triggering any scene change, so `change_
scene_to_file()` has nothing stale to free on that first call.

### Before/after RENDERED comparison (DONE)

Captured via the SubViewport technique above, at all three required
resolutions (720x1280, 1080x1920, 1080x2400), for Campaign Level 1
(5x6, Era 1), Campaign Level 100 ("Culmination", 10x12, Era 1's last
level, densest Era-1 board available), Campaign Level 102 ("Spectrum
Router", 7x7, Era 2 — confirms the modulate isn't Era-1-specific), and
procedural Level 1000 (8x10, Era 3+, exercises the Era-fallback-to-
Era-1-texture path). Both a `before` pass (`game.tscn`'s `Background`
node with no `modulate` override — the pre-existing shipped state) and
an `after` pass (with `modulate = Color(0.22, 0.26, 0.38, 1)`) were
captured from the same driver/level list for a true like-for-like
comparison, not just a single after-the-fact screenshot.

Visually confirmed in every one of the 24 captured images: laser beams
(yellow/orange/red/cyan observed across the sample) stay fully
saturated and immediately readable; mirrors, targets, prisms, and other
tile art stay bright against the now-quieter backdrop; grid cells remain
clearly distinguishable from the background without being excessively
bright; the busy floor-tile pattern, orange glow strips, and crate
set-dressing all recede noticeably, most dramatically on Level 1/100's
Era 1 background (its dominant complaint) and to a real but smaller
degree on Level 102's Era 2 background (already quieter centrally,
corner crystal glow measurably dimmed too).

**Quantitative pixel confirmation, not just visual impression**: at
1080x1920, Level 102's background-art sample point went from
`(229,138,243)` before to `(50,36,92)` after — matches the
`Color(0.22,0.26,0.38)` multiplier almost exactly. A second sample point
landing on the Era 2 HUD's own baked crystal-frame art came back
`(67,12,197)` in BOTH before and after captures — bit-for-bit identical,
confirming the HUD is structurally untouched by this change, not merely
unchanged by coincidence.

### Scope-boundary regression check (AUTOMATED — verified by inspection)

`git diff scenes/gameplay/game.tscn` shows exactly one added line
(`modulate = Color(0.22, 0.26, 0.38, 1)` on the `Background` node) plus
pre-existing, unrelated in-progress changes from the Procedural
Generator V1 / Audio pass (a `QANextButton` node) already present before
this pass started. `grid_manager.gd`, `laser_system.gd`, `grid_types.gd`,
every tile script, `tile_visual.gd`, `scripts/procedural/**`,
`scripts/tools/procedural_audit.gd`, `save_manager.gd`, `audio_manager.gd`,
and every level data file are untouched (grep/diff-confirmed). No PNG
was edited (confirmed via `git status` — zero modified/added files under
`assets/`). `user://savegame.json` was backed up before, and restored
byte-for-byte after, every rendering run in this pass (procedural level
loads write real resume state on load regardless of QA context — see
`game.gd`'s `_load_current_level()` — so this was treated as mandatory,
not optional).

### Board-size note (found, deliberately NOT fixed this pass)

Several of the rendered levels (most visibly Level 1's 5x6 board at
720x1280 and 1080x1920) occupy a small fraction of the available
portrait screen — a board-sizing/generator-profile matter, unrelated to
background readability, and explicitly out of scope for this pass per
the brief. Recorded in `CLAUDE.md`'s Procedural generator rules and
`DECISIONS.md` D90 as a separate future task: favor taller, portrait-
friendlier board-profile shapes going forward, gated on `GridManager.
is_board_profile_comfortable()`, while preserving `MAX_COLUMNS := 8`,
square cells, `MIN_COMFORTABLE_CELL_SIZE`, and no stretching.

### Android build

- **AUTOMATED — DONE.** See this pass's final report for the exact
  `godot --headless --path . --export-debug "Android Debug" builds/
  android/beamshift-debug.apk` / `aapt2 dump badging` / `unzip -l`
  output.
- **MANUAL — pending.** This build has not been installed/reviewed on a
  real device. **This is the required next step** — the brief's own
  STOP CONDITION is to wait for Android visual feedback before any
  further tuning of the modulate value.

### What could NOT be tested on this machine (MANUAL TEST REQUIRED)

Real-device color rendering (phone displays vary in gamma/saturation
more than a desktop monitor), real ambient lighting conditions
(sunlight/dark room) affecting how "dark" the treatment reads, and
whether the darkened background still feels like the "unified blue/
cyan sci-fi theme" the brief asked to preserve on an actual phone
screen, not just this desktop GPU's rendering.

## Unified Blue Theme Fix (versionCode 48, "4.0.4-UNIFIED-BLUE-QA")

See `DECISIONS.md` D91 for the full investigation/decision writeup and
`ARCHITECTURE.md`'s `EraTheme` section for the mechanism. This section
is the test record.

### Theme-selection path audit (AUTOMATED — DONE, by inspection)

Grep-confirmed every visual-theme call site in the codebase routes
through `EraTheme.for_era()`: `game.gd._apply_era_theme()` (gameplay
background/grid/HUD/popup panels), `level_button.gd`/`tutorial_button.gd`
(card accent tint), `level_select.gd`/`tutorial_select.gd` (select-screen
background). No scattered `if level >= 100`/`if era == 2` check exists
anywhere else — the fix is a single early-return inside `for_era()`
itself (`EraTheme.UNIFIED_BLUE_THEME_ONLY := true`).

### Visual regression set (RENDERED — DONE)

Captured via the SubViewport-independent driver technique (D90), 14
screens in one pass: Campaign Levels 21, 99, 100, 101, 102, 140;
procedural Levels 200, 500, 1000, 1500, 2000; Tutorials T01, T11, T20.
All 14 confirmed visually consistent — same dark-blue gameplay
background family, same grid cell art, same HUD bars (including the
same HUD aspect ratio; Era 2's own `hud_aspect_ratio = 3.0` no longer
applies anywhere), same white/unmodulated card accent tint.

**Level 21 vs. Level 102 (the brief's own key comparison)**: rendered
side by side — indistinguishable in background/grid/HUD family. The
only differences are puzzle content (Level 102's Prism/switch/portal
layout vs. Level 21's simpler board) and the small Prism/switch tile
icons' own purple-specific art (expected, see below) — never the
surrounding skin.

Advanced mechanic tiles (Prism, One-Way Reflector, Beam Receiver, Remote
Emitter) visible in the Level 101/102/T11/T20 captures render exactly as
before — fully functional, still their own purple-toned icon art (these
were never routed through `EraTheme`, so this fix structurally could not
and did not touch them). This is the one remaining visible purple
element in normal gameplay; not a regression, a known/documented
leftover (see D91's explicit asset list).

### Text/color consistency fixes (RENDERED + AUTOMATED — DONE)

Two residual-purple issues found during the RENDERED pass above and
fixed (both content/style-only, zero logic touched): T11's first message
no longer claims "only the scenery" changes (it doesn't, anymore);
`level_complete_popup.tscn`'s `EraTransitionLabel` (shown once, at the
real Level 100→101 boundary) recolored from violet to cyan-blue. Its
text content was left unchanged (still accurate). Not independently
re-rendered in a solved state this pass (would require simulating a full
Level 100 solve) — a plain `.tscn` `font_color` property change, verified
by direct source inspection instead; flagged here so a future solved-
state render can double-check it if ever in doubt.

### Runtime QA (AUTOMATED — DONE)

Real driver, real autoloads, run via the project's standard
`--path .` (non-headless) technique, `user://savegame.json` backed up
before and restored after:

```
AudioManager streams loaded: 22
Determinism check (Level 777): seed_a=3413417488 seed_b=3413417488 match=true gen_version_match=true
PLAY -> current_scene: Game is_procedural_mode=true current_procedural_level=1
QA Next button visible: true
QA Next: resume level before=1 after=2
CONTINUE -> current_scene: Game resumed_level=2 matches_resume_pointer=true
```

Confirms: `AudioManager` unaffected (22/22 streams, matching D89's own
count exactly); procedural determinism unaffected (same level number +
generator version → identical seed, called twice in-process); `PLAY`
correctly enters real procedural progression; the QA Next button is
present and correctly advances the resume pointer; `CONTINUE` correctly
resumes the exact QA-Next-advanced level, matching D88's documented
PLAY-vs-CONTINUE contract exactly (unchanged by this pass).

### Scope-boundary regression check (AUTOMATED — verified by inspection)

`git status` after this pass shows exactly 3 modified files:
`scripts/resources/era_theme.gd`, `levels/tutorial/t11.gd`,
`scenes/ui/level_complete_popup.tscn` — no other file touched. In
particular: zero changes to any tile script, `grid_manager.gd`,
`laser_system.gd`, `grid_types.gd`, `scripts/procedural/**`,
`scripts/tools/procedural_audit.gd`, `SaveManager`, `AudioManager`, any
level's `tiles` array, `export_presets.cfg`'s `exclude_filter`, or any
PNG. No asset was deleted, moved, or excluded — all Era 2 art remains on
disk, unreferenced by any active code path.

### Android build

- **AUTOMATED — DONE.** See this pass's final report for the exact
  `godot --headless --path . --export-debug "Android Debug" builds/
  android/beamshift-debug.apk` / `aapt2 dump badging` / `unzip -l`
  output.
- **MANUAL — pending.** This build has not been installed/reviewed on a
  real device. **This is the required next step**, per the brief's own
  STOP CONDITION.

### What could NOT be tested on this machine (MANUAL TEST REQUIRED)

Whether the now-unified blue skin genuinely reads as "the same game" to
a player moving from Level 99 to Level 101 on a real phone (color
perception, not just pixel-identity, which this pass's tooling already
confirmed); whether the still-purple advanced-mechanic tile icons feel
like an acceptable temporary inconsistency or need prioritizing sooner
than "future work."
## Difficulty System Phase 1 (AUTOMATED, headless; no RENDERED/MANUAL)

- **9-level fast inspection** (`godot --headless --path . res://scripts/tools/difficulty_inspect.tscn`,
  levels 1,25,50,100,500,1000,1500,1900,2000, solver capped at 4096 states):
  whole run ~1 s, no `QA_BUDGET_EXCEEDED`. Only Level 1 passes its contract;
  the other 8 fail (too few moves/deps/depth, single route, ...). Level 1900
  solver = UNKNOWN at the 4096 cap (13 rotatables).
- **Scans (no solver):** V2 Levels 1801-2000 in ~12 s: min 6 intended moves,
  0 fallbacks; solver on the 31 lowest: optimal == intended for all. V1
  1801-2000: 2x3-move, 4x4-move, 10x5-move levels. Strided V2 sample (100
  levels, ~6 s): 99/100 fail the contract.
- **QA +50 end-to-end** (temporary driver instantiating a real `game.tscn`;
  driver deleted, real `savegame.json` backed up and restored byte-identical):
  1->51, 51->101, 101->151, 451->501, 951->1001, 1451->1501, 1851->1901,
  1901->1951, 1951->2000, 2000->2000 (no-op) all PASS; resume pointer
  follows; `SaveManager.procedural_current_level` untouched; CONTINUE target
  1051 after a 1001 jump, PLAY still 1; button label "+50".
- **V1 compatibility:** `generate(1897, 1)` deterministic (3 moves) and !=
  V2's (12 moves); a saved V1 resume for Level 1897 reloads the V1 puzzle and
  keeps `procedural_resume_generator_version == 1`.
- **MANUAL TEST REQUIRED:** none new (no player-visible change except the
  unchanged "+50" label). Phase 2 needs an Android difficulty review.
- Not run by design: full 1-2000 audit, V1/V2 exhaustive audits, 100+ solver sample.
## Difficulty System Phase 2A (AUTOMATED, headless; no RENDERED/MANUAL)

- **V3 prototype audit** (`godot --headless --path . res://scripts/tools/v3_prototype_audit.tscn`,
  solver cap 16384 states): all six prototypes generate at attempt 0, are
  deterministic (generate twice -> identical seed and board), start unsolved,
  intended solution solves, `LevelValidator` errors none, columns <= 8,
  board comfortable; every solver run SOLVABLE with optimal == intended and a
  unique shortest solution. Whole run ~1.3 s (solver <= 90 ms each). No
  `QA_BUDGET_EXCEEDED`.
- **Real-game driver** (temporary, deleted; real save backed up/restored):
  V3 session shows "NEXT V3", cycles 2..6,1; the intended solution of
  prototype 2 solves via real `GridManager._on_orientable_tile_clicked`
  (8 taps); the save file is byte-identical after a V3 session; normal mode
  label "+50"; +50 jumps 1->51, 951->1001, 1901->1951, 1951->2000, 2000->2000;
  progression pointer untouched. V1 (1897 = 3 moves) and V2 (500) samples
  deterministic; default version 2; `generate(n, 3)` routes to V3; a saved V1
  resume regenerates V1. (One driver check with a wrong threshold - prototype 1
  has 17 tiles, not > 20 - was the driver's own error, not a defect.)
- **APK:** `aapt2 dump badging` -> versionCode 49 / 4.1.0-PROCEDURAL-V3-PROTOTYPE-QA;
  archive lists the V3 scripts and no `_qa_tmp`/`scripts/tools` entries.
- **MANUAL TEST REQUIRED (Android):** difficulty feel of all six (did it need
  thought, obvious?, shortcuts?, comfort of controls, "NEXT V3" button fit).

## Difficulty System Phase 2A.1 (AUTOMATED, headless; no RENDERED/MANUAL)

- **Audit** (`godot --headless --path . res://scripts/tools/v3_prototype_audit.tscn`,
  optional `-- levels=4,5,6 solver=1`; always wrap in `timeout 50`): whole run
  ~1.3 s for six prototypes, 3-5 s for 12 extra seeds; no `QA_BUDGET_EXCEEDED`.
  D/E/F generate at attempt 0, deterministic, start unsolved, intended solution
  solves, no loop, `LevelValidator` errors none, 8 columns, comfortable, no
  triviality flags. Solver (cap 16384): D 8 / E 11 / F 11, all SOLVABLE,
  optimal == intended, `shortest_solution_count == 1` (1981 / 8178 / 4095
  states). Repeated on levels 10-12, 16-18, 22-24, 28-30 (+ F on 36, 42):
  identical. **A/B/C**: audit output (ASCII, metrics, solver) diffed against a
  baseline saved before the change -> identical. V1/V2 source files untouched.
  **Not re-run this pass (no code path changed):** `+50` behaviour, V3 TEST /
  NEXT V3 session logic, saves - `LevelManager`/`GameManager`/`game.gd`/
  `SaveManager` were not modified; `PROCEDURAL_QA_JUMP_AMOUNT` still 50 and
  `SHOW_V3_PROTOTYPE_QA` still true (grep-checked).
- **Technique warning:** a GDScript parse error in a `--headless` scene run
  hangs instead of exiting - always use `timeout`.
- **APK:** `aapt2 dump badging` -> versionCode 50 /
  4.1.1-PROCEDURAL-V3-THINKING-QA (export 12 s). The `.pck` is opaque to
  `unzip -l`, so absence of `_qa_tmp`/`scripts/tools` is by the preset's
  `exclude_filter`, not by listing the pack.
- **MANUAL TEST REQUIRED (Android), D/E/F:** D - did the shared One-Way make me
  think about more than one beam? E - did I need to understand why the two
  branches depend on each other? F - did I need the whole chain before the
  moves became clear? All: did I trace before rotating; were initially
  plausible states misleading but fair; could I solve by rotating every visibly
  wrong tile; any shorter accidental solution.


## Difficulty System Phase 2B - V3 progression generator (2026-09-24)

All runs use `timeout` (a parse error hangs headless Godot) and stay < ~60 s each. Godot:
`"/d/Godot_v4.7.1-stable_win64.exe" --headless --path . <scene>`; user args after `--`.

**AUTOMATED - re-run these after any composer/fragment/contract change**
- `res://scripts/tools/v3_progression_sample.tscn` (25 focused levels: generation, determinism,
  start unsolved, intended solves, columns <= 8, comfortable, contract verdict, validator, moves in
  band, greedy proxy, start visibility; `ascii=1` prints boards; `solver=1 solver_levels=1,50,...
  solver_states=200000` runs the dev solver on a subset). Result this pass: **25/25 ALL PASS, 0
  fallbacks**, greedy solves only Levels 25/50/75.
- `res://scripts/tools/v3_progression_stats.tscn -- range=a-b [step=N] [probe=0|1]
  [solver_states=..] [max_rotatables=..]` (fallbacks, rejection histogram, composer failure
  reasons, density buckets, band averages, solver-vs-probe agreement, timings). Results this pass:
  solver-checked 1-120 (120), 121-260 (140), 401-440 (40), 441-480 (40), 701-719 (17): **0
  shortcuts with the probe on**, optimal == intended everywhere, unique shortest solution in all
  but two; probe-off raw shortcuts 4/40 (401-440) and 1/16 (701-719), probe caught 5/5; validator
  over 286 levels sampled across 3-2000: **0 errors, 0 fallbacks**; windows of 50-60 levels per
  band 501-2000: 0 fallbacks (one `1976` fallback seen before the 16-attempt cap for 1301+).
- Prototype fixtures: `v3_prototype_audit.tscn -- solver=0` diffed against a saved baseline (ignore
  `gen_ms`/`elapsed`): **IDENTICAL**; with `solver=1`: A-F optimal == intended, unique.
- Dev solver subset (`solver_states=200000`): Levels 1/50/100/500/1000 SOLVABLE, optimal ==
  intended (3/5/7/13/15), unique; **1500/1900/2000 UNKNOWN** (state cap, 15-29 s each; total
  72 s -> `QA_BUDGET_EXCEEDED` reported). UNKNOWN is not UNSOLVABLE.
- End-to-end through the real `game.tscn` (temporary driver, since deleted): new-play version V3;
  PLAY L1 saves resume v3; `+50` chain 1 -> 51 -> 101 ... -> 951 -> 1001 ... -> 1951 -> 2000, no-op
  at 2000, `procedural_current_level` untouched, resume pointer = 2000/v3; CONTINUE reloads 2000 as V3;
  saved V2 resume stays V2; saved V1 resume stays V1; V3 TEST prototype session touches no save;
  NEXT V3 cycles 4 -> 5. 20/20 checks passed (twice, before and after the final code freeze
  for the QA label).
- RENDERED: non-headless captures at 720x1280 of Levels 1, 60, 500, 1950 (HUD tag `V3 HRD` fits;
  8x11 board at 1950 readable). This is RENDERED evidence, not MANUAL approval.
- Export: `--export-debug` -> `aapt2 dump badging`: versionCode 51 / 4.2.0-PROCEDURAL-V3-PROGRESSION-QA /
  com.beamshift.game; 786 entries, 79,804,416 bytes; `unzip -l` shows no `_qa_tmp`/`scripts/tools`,
  runtime `procedural_*` scripts present.

**MANUAL TEST REQUIRED (Android)** - the next decision depends on these
- Early game (Levels 1-20): not too hard? Level 1 should be a 3-move mirror route.
- Does difficulty become noticeable after ~20-30 levels? (Early Thinking 21-50 uses only F+P/F+SB and G recipes.)
- Mid game (100-400): more reasoning, not just beam-following? Any accidental shorter solution?
- Late game (1000+/1800+): cannot be solved by following the beam? Are tiles still large and comfortable
  (8x11 boards)? Any visible level-load hitch at high levels (`+50` into 1301+)? Does the HUD ever show
  `V3 FAILED>V2`? (PLAY on a level whose saved resume is an old V2 puzzle resumes that V2 puzzle by design;
  Reset generates V3.)
- Do not treat any of the above as approved until the user reports it.


## Global Hint System Phase 1 (2026-09-24)

AUTOMATED (temporary driver through the real `game.tscn`, deleted after use; backs up/restores the save):
per case - button visible, candidate valid + currently wrong, hint changes nothing (orientations, moves),
second hint = another tile, rotating clears ring and counts exactly 1 move, Reset clears ring/history,
following hints alone solves the level, solved -> no hint. Cases: V3 Levels 1/100/500/1000/1900/2000, V1 and V2
(saved-resume versions, L60), V3 TEST prototype 4, campaign 3 and 90, tutorials 1 and 12 (message steps: no
hint; REQUIRE_TILE_TAP: hint = step target). Also: `+50` (1->51) clears the ring; hint leaves resume state
untouched; 22/22 SFX streams loaded. Result: all PASS (one early FAIL was a test artifact: legitimate solves
advance progression). Candidate cost 26-134 microseconds. RENDERED: ring + visible HUD bulb button at 720x1280
(Level 100). Solution table: `hint_solution_builder.tscn` solved 160/160. Export: aapt2 versionCode 52 /
4.2.1-GLOBAL-HINT-QA; `hint_solutions.json` + `hint_manager` present, no `_qa_tmp`/`scripts/tools`.
MANUAL TEST REQUIRED (Android): hint button reachable/visible, ring readable, helpfulness of the chosen tile,
tutorials (not conflicting with steps), Continue after hinting, `+50` then hint.


## AdMob Foundation V1 (2026-09-24)

AUTOMATED (temporary driver, fake `AdBackend`, real `game.tscn`; save backed up/restored; injected clock): 35 checks pass - rewarded preload; double tap -> one show; reward -> one hint, moves unchanged,
preload again; close without reward / show failure / no ad available -> no hint, no crash; V3 TEST, tutorial, campaign QA free; completions 1-3 no ad, 4th shows, counter resets only after the show,
120 s cooldown blocks then allows, not-ready never blocks and keeps the counter, rewarded-on-level suppresses; QA +50, Reset, V3 TEST, Continue/load and duplicate solved callbacks do not count;
old save loads; 22/22 SFX; Master bus restored. Prototype fixtures diff identical after the `_plan_c` fix. Export: aapt2 versionCode 53 / 4.3.0-ADMOB-FOUNDATION-QA; manifest sample App ID, AD_ID/INTERNET,
all PoingGodotAdMob plugins registered; no `_qa_tmp`/`scripts/tools`.
NOT VERIFIED: real Google Mobile Ads/UMP init, real test ads, Java->GDScript callbacks, pause/resume around a real ad (no device here); iOS. MANUAL TEST REQUIRED (Android): rewarded hint end-to-end, close-early = no hint,
airplane mode, interstitial on the 4th completion (and not within 120 s), consent form behaviour, audio returns after ads, V3 TEST/tutorial/+50 ad-free.

## Fusion Node Phase 1 (2026-09-24)

AUTOMATED (temporary headless driver, deleted): colour table + both orders + 6 RGB permutations + singles/same-colour/empty/non-primary; 36 two-input side/order cases; three-input -> ONE WHITE; inputs terminate;
output-side entry absorbed; dynamic mirror/gate/switch scenarios, no stale YELLOW; determinism. Six QA puzzles: unsolved at start, solvable, validator clean, every move needed; QA4 misrouted input is not WHITE;
QA5 chain powered; ~159 us per stable simulation. Regression: 160/160 campaign+tutorial solutions, dev levels 1-15, prototypes A-F unchanged. Game scene: Fusion TEST hints (ring only, no move, no ad), follow-hints
solves each, Reset, 4-tap rotation = 4 moves, NEXT FUSION cycles, progression/resume/ad counter untouched, no ads; normal procedural hint still via AdManager; 22 SFX. RENDERED: puzzles 4 and 5 at 720x1280.
Export: aapt2 versionCode 54 / 4.4.0-FUSION-NODE-QA, fusion assets present.
MANUAL TEST REQUIRED (Android): node readability (inactive/active, arrow, input dots), YELLOW vs WHITE beam readability, tap-to-rotate feel, puzzles 1-6, hints on Fusion, performance.

## Fusion Node Phase 2 (2026-09-24)

AUTOMATED (temporary headless drivers in `_qa_tmp/`, deleted; dev tools kept in `scripts/tools/`):
- **Frozen versions**: a fingerprint driver (hash of every tile + the solution for 33 levels x V1/V2/V3 = 99 pairs) before vs after the pass and after every later code change - IDENTICAL. Prototypes A-F (`v3_prototype_audit.tscn solver=0`): boards/metrics unchanged (only the `reasoning:` text of prototype C differs from the older baseline, from an earlier planner fix).
- **Fusion levels** (`fusion_progression_sample.tscn`): independent checks on every sampled level (intended solution solves, start unsolved, columns <= 8, comfortable, every node active with >= 2 distinct primary inputs and exactly one tap from solved, deterministic regeneration). Stress windows (Levels 201-2000, ~900 levels): 0 failures; fallback_count 0 after the 16-attempt fix for V4 Levels >= 1001 (one non-Fusion Level 1015 had exhausted 12 attempts). Realised Fusion share per band (stride 4): 14% / 23% / 17% / 16% / 27% / 28% / 20% for 201-400 ... 1801-2000.
- **Exact / shortcut** (`fusion_verify.tscn`): bypass, omitted input, Prism removed, WHITE target/remote checks; exhaustive search over every orientation (Fusion 4-state) -> PROVEN OPTIMAL, unique shortest solution for all 19 levels of the final run (F1-F5, 8k-131k states) and 22+ over the pass (one real shortcut found and fixed). Late levels (1001+): wide probe (4000 sims) on 42 F2-F7 levels: 1 cheaper alternate solution (2.4%); reported as STRUCTURALLY VALID / PROBE PASSED, never proven.
- **Stability**: hand-built feedback loop (Fusion -> Switch -> Gate -> own input) settles but is REJECTED by `ProceduralFusionCheck`; 60,000 random Fusion/Prism/Filter/Gate/Switch/Receiver/Remote boards: 0 unsettled, max 4 passes; 3,000 random states of 25 generated Fusion levels: 0 unsettled.
- **Game scene end-to-end (28 checks, fake ad backend)**: PLAY uses V4; a tap on the node = 1 clockwise move; Continue recreates the identical board, generator version, every orientation and the move count; only-the-Fusion-wrong -> Hint points at it; rewarded flow (reward -> exactly one hint, no reward -> none, hint never rotates/counts); a solved generated Fusion level counts as ONE interstitial completion and advances progression; a saved V3 puzzle regenerates byte-identical as V3; FUSION TEST is interstitial-ineligible with free hints. QA +50: 1951 -> 2000, 2000 -> no-op, counters untouched.
- **Regression**: dev levels 1-15 solver-verified (15/15), campaign 1-140 (140/140) and tutorial T01-T20 (20/20) solver-authored solutions solve, Fusion QA puzzles 6/6; levels 2001-99999 generate under V4 (post-2000 readiness) without fallback.
- RENDERED: generated Levels 250 and 1663 (V4, F1 solved / F7 start) at 720x1280 - HUD tag, node, beams readable.
- Export: aapt2 versionCode 55 / 4.5.0-FUSION-PROGRESSION-QA; fusion + procedural_fusion_check scripts present, no `_qa_tmp`/`scripts/tools` entries, manifest App ID is Google's sample ID.
MANUAL TEST REQUIRED (Android): PLAY + QA +50 -> Level 201+ (first Fusion levels understandable, not too early, variety of fragments, late levels combine mechanics, readable on phone), Hint (rewarded ad) on Fusion levels, interstitial counter, no unexpected `V4 FAILED>V2`, level-load time on a real phone (worst desktop ~0.65 s), no simulation instability.

## Fusion Node Phase 3 (2026-09-24, `versionCode=56`, `4.6.0-FUSION-FULL-QA`)

`"/d/Godot_v4.7.1-stable_win64.exe" --headless --path . <scene>`; user args after `--`; wrap every run in `timeout` (a parse error hangs headless Godot). Temporary drivers live in `_qa_tmp/` (export-excluded) and were deleted afterwards; they back up/restore `user://savegame.json` when they record tutorial completion.
- **AUTOMATED - DONE.** T21-T28 brute force through the real `LaserSystem`: each board has exactly ONE solving orientation combination (min taps 1/3/2/1/1/2/2/3), none starts solved, `hint_solutions.json` `t21`-`t28` equal that solution.
- **AUTOMATED - DONE.** Real-game-scene replay of ALL 28 tutorials (real autoloads): MESSAGE locks input, wrong-tile tap rejected, Hint candidate == forced tile, completion recorded, popup visible, Reset -> step 0 + authored orientations, `_interstitial_eligible_session()` false. T01-T20 unchanged.
- **RENDERED - DONE.** T24 step 1, T28 step 1 (540x960) and Tutorial Select (T01-T28 cards, unified blue theme) inspected. Panel text fits; HUD title truncates > ~13 chars (names shortened).
- **AUTOMATED - DONE.** `fusion_progression_sample.tscn freq=1 stride=4`: realised Fusion share 201-400 14%, 401-700 23%, 701-1000 27%, 1001-1300 20%, 1301-1600 31%, 1601-1800 34%, 1801-2000 22%; `stress=90` windows from 401/701/1001/1301/1601/1801: 141 Fusion levels, 0 problems, 0 fallbacks, 0 greedy-solvable, settling passes <= 4. Levels 2001-2060: 15 Fusion, 0 problems (dev only).
- **AUTOMATED - DONE.** `fusion_verify.tscn window=... max=10 states=70000 probe=0` over 201-400 / 401-700 / 701-1000: 30 levels PROVEN OPTIMAL, one shortest solution, optimal == intended (9 have a solving empty-cell counterfactual = false alarm). `levels=` spot checks at 1310/1355/1601/1629: dead-node ablation unsolved, STRUCTURALLY VALID / PROBE PASSED (UNKNOWN exact, never claimed proven).
- **AUTOMATED - DONE.** V1/V2/V3 fingerprint (temporary driver hashing tiles + solution over 38 levels x 3 versions) IDENTICAL before/after; V4 differs only at Fusion-rolled levels.
- **AUTOMATED - DONE.** Save/Continue on generated Level 401 (V4, F3 portal_a): Fusion x2 + mirror x1, exit, CONTINUE -> identical board, orientations, move count 3, generator version 4. Hint: one solution tile, ring only, orientations/moves unchanged. Ads: eligible in normal Fusion play, not in tutorials / FUSION TEST.
- **AUTOMATED - DONE.** Regression: 140 campaign hint-table solutions solve, 15 dev levels `LevelSolver` optimal == declared, `hint_solution_builder` skips T21+.
- **AUTOMATED - DONE.** Export: `aapt2 dump badging` versionCode 56 / 4.6.0-FUSION-FULL-QA / com.beamshift.game; `unzip -l` shows T21-T28 + hint table, no `scripts/tools`, no `_qa_tmp`. 108,948,560 bytes.
- **MANUAL TEST REQUIRED (Android):** T21-T28 feel and text length on a phone, tapping the Fusion node in forced steps, Hint on a forced Fusion step, T28 difficulty, Tutorial Select scroll to T28; normal levels: PLAY + QA +50 to 201+ and check Fusion variants (portal on output, gated input, remote+gate, prism_one) read fairly, load time of dense late Fusion levels, rewarded Hint on a Fusion level, CONTINUE after killing the app mid-Fusion level, no ad in tutorials / FUSION TEST.

## Phase 4 (D102, `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`) - stars, Hint cap, central QA switch, Fusion tutorial nudge

- **Stars:** one rule in `StarScoring` (OPTIMAL from `verified_optimal_moves` >= 0, else `intended_moves`, else legacy `optimal_moves`; +2 = 3 stars, +6 = 2, else 1; below optimal = 3 + QA warning). A GRANTED gameplay Hint caps the attempt at 2 stars (`game.gd._hint_used_this_attempt`, persisted in `procedural_resume_hint_used`/`campaign_resume_hint_used` so Continue cannot reset it; cleared by Reset/Next/QA +50). Best stars: `SaveManager.procedural_best_stars["<level>|<generator_version>"]` (raise-only) and the existing campaign dictionary. Tutorials, V3 TEST, FUSION TEST: no stars, no records. The popup shows the current run's stars + a small "HINT USED".
- **QA vs production:** ONE constant, `BuildConfig.IS_PRODUCTION_BUILD` (false in this build). It derives every QA-only UI/unlock flag in `LevelManager` and hides the tutorial debug overlay and the generator tag. Tools are hidden, never deleted. Not covered: Google TEST ad ids, and the generator rollout flags `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA`.
- **Fusion tutorial nudge:** one-time non-blocking "NEW TUTORIAL: FUSION" banner on Main Menu (`LevelManager.should_show_fusion_tutorial_nudge()`, persisted `fusion_tutorial_nudge_seen`); never forces the tutorial, never locks progression. `bs_fusion_icon.png` remains unused (no icon support in the tutorial panel).
- Level 2000 remains the certification target; nothing beyond it is exposed; no new mechanic.
- **AUTOMATED - DONE (Phase 4).** Temporary drivers (deleted; save backed up/restored): star matrix (OPT 5/10/20, hint, below-optimal), V4 Levels 1/50/100/201/401/500/1000/1601/1900/2000 (optimal 3 / hint 2 / +7 = 1 / best kept / V2 identity separate), 140 campaign levels, generated Fusion Level 401 Hint -> exit -> CONTINUE -> solve (2 stars + HINT USED) -> Reset (flag false) -> solve (3 stars), FUSION TEST / tutorial hint not counted, QA +50 records nothing, T21-T28 replay, nudge once. Production simulation: `BuildConfig.IS_PRODUCTION_BUILD` flipped true -> Main Menu only CONTINUE/PLAY/TUTORIAL/SETTINGS/QUIT, no +50, no generator tag, no tutorial overlay; flipped back. Export: versionCode 57 / 4.7.0-STARS-PRODUCTION-QA, 108,952,946 bytes.
- **MANUAL TEST REQUIRED (Android):** star counts/feel on real levels, the popup "HINT USED" layout, rewarded Hint -> cap, Continue after a Hint, nudge banner size/position on a phone, Tutorial text readability, load time of dense Fusion levels.

## NEW GAME flow (2026-09-24, `versionCode=66`)

- **AUTOMATED - DONE.** Temporary driver (deleted; save backed up/restored): cases 1-10 of the brief plus double tap, Back = cancel, T21-unlock materialisation, all PASS. Production simulation Main Menu = CONTINUE / NEW GAME / TUTORIAL / SETTINGS / QUIT. Popup rendered at 540x960.
- **MANUAL TEST REQUIRED (Android):** popup readability/tap targets on a phone, Back gesture on the popup, real fresh install and upgraded save.


## Splitter Selector S1 + S2 (2026-09-25) - AUTOMATED/RENDERED, MANUAL pending

- **AUTOMATED - DONE**: selector_verify.tscn (6 QA puzzles, exhaustive), selector_tutorial_verify.tscn (T29-T34 unique solution, min moves T34 = 5), 35-level solver regression (levels 1-15 + campaign sample), V1/V2/V3/V4 fingerprint identical (25 levels each, HEAD copy vs current).
- **RENDERED - DONE (540x960)**: T29-T34 through the real game: message steps lock input, forced steps accept only the required tile, wrong taps rejected, Hint = required tile only (no move, no rotation), reset -> step 0, completion popup + save record, ad/star/progress state untouched, real GUI click on the selector; T01-T28 replay; SELECTOR TEST 1-6; FUSION TEST 1-6.
- **MANUAL TEST REQUIRED**: feel/readability of T29-T34 and the selector art on a real phone; Android build of this pass (not built - Phase S4).


## Selector Phase S3 - generator V5, Levels 2001-3000 (2026-09-25) - AUTOMATED/RENDERED, MANUAL pending

- **AUTOMATED - DONE**: V1-V4 fingerprint (33 levels x 4 versions = 132 hashes of tiles + solution) identical before/after and after the last change; V5 fingerprint (22 anchors) identical across two separate processes; `v5_sample.tscn` per-band windows (50 levels each, stride 4: 0 fallbacks, Selector share 42/50/58/62/71%, greedy-solvable 0/250, demoted 0/5/9/26/31), 21 anchors clean under an independent 2500/40 probe, `v5_verify.tscn` (Selector brute force + determinism on ~40 levels: 0 problems; exact BFS proves 8/8 V3 levels, UNKNOWN on V5), levels 1-15 solver 15/15, campaign samples load, T01-T34 load, T29-T34 hint entries, SELECTOR TEST 1-6 / FUSION TEST 1-6 (start unsolved, solution solves), `selector_verify`/`selector_tutorial_verify` 0 problems.
- **Real-game drivers (temporary, deleted)**: Save/Continue at 2001/2200/2500/2800/3000 exact (level, generator version 5, seed, every orientation incl. Selector states, move count, hint-used); Hint on a wrong Selector, no rotation/no move, hint-used caps stars at 2; intended solution replayed through a real GridManager (7 anchors: solved, taps == intended_moves, 3 stars); QA +50 (1951->2001, 2001->2051, 2951->3000, 3000 no-op, no stars/no real progression); 2000 -> 2001 Next Level V4 -> V5; version mapping 1999/2000 -> V4, 2001/2002/3000 -> V5; MAX_LEVEL 3000, MAX_COLUMNS 8.
- **RENDERED - DONE (540x960)**: V5 TEST levels 5 and 9 through the real game scene.
- **Known findings**: replay found group-redundant intended solutions (~14% unscreened Mastery) and shallow shortcuts (~2% Entry/Branching); fixed by `ProceduralMinimality` + final wide probe; residual documented in `PROCEDURAL_GENERATION.md` 20.6.
- **MANUAL TEST REQUIRED**: play the V5 TEST levels (2001, 2050, 2201, 2351, 2500, 2651, 2800, 2900, 3000) for difficulty feel (does the puzzle require thinking about WHY a route must be chosen?), readability of 38-57-tile boards on a real phone, and on-device generation time. Android build not made (S4).

- **Status note (2026-09-25 handoff)**: S3 is implemented but NOT certified; S3.1 (J/K refinement) is next and must re-run this whole S3 section plus the V1-V4 fingerprint. `NEXT_AI_PROMPT.md` section 9 lists the regression requirements.
