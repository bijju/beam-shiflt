# CHANGELOG.md

## Hint attention pulse (2026-09-25, QA)

`versionCode=68`, `4.8.2-HINT-ATTENTION-PULSE-QA`. Subtle repeating cyan glow/scale pulse (5 s interval, scale 1.04) on the Hint icon; visual-only, one reusable halo node and one looping Tween in `game.gd`; constants in `UIConstants.HINT_*`. Stops on press/ad/solve/reload.

## Level Complete button stretching fix (2026-09-25, QA)

`versionCode=67`, `4.8.1-LEVEL-COMPLETE-BUTTON-FIX-QA`. Fixed stretched NEXT LEVEL/RETRY/LEVEL SELECT buttons on the Level Complete popup: `ButtonRow`'s buttons were missing `size_flags_horizontal` and had a zero-width `custom_minimum_size`, so default `FILL` behavior stretched the button art to the full panel width. Set `size_flags_horizontal = 4` + `custom_minimum_size = Vector2(600, 140)` on all three, matching Main Menu's proven button pattern. Rendered-verified at 540x960 and 1080x2400. `pause_menu.tscn`/`tutorial_complete_popup.tscn` share the same missing-pattern bug but were left untouched (out of scope).

## NEW GAME flow (2026-09-24)

`DECISIONS.md` D107. `versionCode=66`, `4.8.0-NEW-GAME-FLOW-QA`. PLAY -> NEW GAME with confirmation only when meaningful progress exists; `SaveManager.reset_main_progress_for_new_game()`; `save_game()` returns bool.

## Gameplay stack 40 px-down calibration (2026-09-24, QA)

`versionCode=65`, `4.7.8-GAMEPLAY-STACK-40DOWN-QA`. `GAMEPLAY_STACK_VERTICAL_OFFSET` -70 -> -30; whole stack +40 px. Pending Android approval.

## Gameplay stack 50 px-down calibration (2026-09-24, QA only)

`versionCode=64`, `4.7.7-GAMEPLAY-STACK-50DOWN-QA`. `GAMEPLAY_STACK_VERTICAL_OFFSET` -120 -> -70; top plate, board and bottom plate each moved +50 px from build 63.

## Gameplay stack -100 px QA test (2026-09-24)

`versionCode=63`, `4.7.6-GAMEPLAY-STACK-100PX-QA`. QA TEST ONLY: whole stack moved 100 px above build 62 (offset -120, cap lifted by `ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET`). Measured: top plate, board and bottom plate each -100/-100/-99 px.

## Gameplay stack -20 px test (2026-09-24)

`versionCode=62`, `4.7.5-GAMEPLAY-STACK-20PX-QA`. `GAMEPLAY_STACK_VERTICAL_OFFSET` -8 -> -20; stack moved up another 12 canvas px (clamped at the safe edge).

## Gameplay stack shift (2026-09-24)

`DECISIONS.md` D106. `versionCode=61`, `4.7.4-GAMEPLAY-STACK-CENTER-QA`. Whole HUD/board/HUD stack translated up (-8 px + inset balance, clamped to the safe edge).

## HUD symmetric gap (2026-09-24)

`DECISIONS.md` D105. `versionCode=60`, `4.7.3-HUD-SYMMETRIC-GAP-QA`. Top HUD gap 3.6 -> 20.6 canvas px to match the bottom (20.8, unchanged).

## HUD final position (2026-09-24)

`DECISIONS.md` D104. `versionCode=59`, `4.7.2-HUD-FINAL-POSITION-QA`. Top HUD gap 8.6 -> 3.6, bottom 8.8 -> 20.8 canvas px via new `GAMEPLAY_TOP_VISIBLE_GAP`/`GAMEPLAY_BOTTOM_VISIBLE_GAP`.

## HUD edge spacing (2026-09-24)

`DECISIONS.md` D103. Build `versionCode=58`, `4.7.1-HUD-EDGE-QA` (108,953,750 bytes, QA ON, Google TEST ads). Top/Bottom HUD plates moved from ~80 to ~8.7 canvas px inside the safe area by compensating for the art's transparent padding (`SafeAreaMargin.set_hud_overhang`); board gained height; QA tutorial debug label moved below the HUD.

## Phase 4 - production cleanup: stars, Hint cap, central QA switch, Fusion tutorial polish + nudge (2026-09-24)

`DECISIONS.md` D102. Build `versionCode=57`, `versionName="4.7.0-STARS-PRODUCTION-QA"` (`builds/android/beamshift-debug.apk`, 108,952,946 bytes, Google TEST ads unchanged, QA mode ON).
- New `StarScoring` (one rule: OPTIMAL+2 = 3 stars, +6 = 2, else 1; a granted Hint caps at 2; below-optimal = 3 + warning); procedural best stars per `level|generator_version`; Hint-used persisted with resume state; popup shows real stars + "HINT USED"; V3/FUSION TEST show none.
- New `BuildConfig.IS_PRODUCTION_BUILD` drives every QA-only UI/unlock flag and the tutorial overlay/generator tag (production simulation verified). QA tools hidden, not deleted.
- T21-T28 text shortened; one-time "NEW TUTORIAL: FUSION" Main Menu nudge (persisted, non-blocking). Fusion icon left unused (no panel icon support).
- Not changed: AdMob, audio, HUD, mechanics, Level 2000 boundary.

## Fusion Node Phase 3 - production integration: tutorial T21-T28, variants, shortcut hardening (2026-09-24)

`DECISIONS.md` D101. Build `versionCode=56`, `versionName="4.6.0-FUSION-FULL-QA"` (`builds/android/beamshift-debug.apk`, 108,948,560 bytes, Google TEST ads unchanged, all QA flags still ON). Fusion is now a PRODUCTION-SUPPORTED mechanic (user-approved after Android QA of 55).
- New: Fusion tutorial pack **T21-T28** (Fusion Node / Output Side / Color Recipes / Three Colors / Fusion Filter / Fusion Portal / Fusion Relay / Fusion Trial), same `TutorialManager`, hint entries `t21`-`t28`, unlock `LevelManager.is_fusion_tutorial_selectable()` (T21 at procedural Level 150 or after T20, then sequential; QA flag opens all; never a hard gate; NOT era-gated).
- Generator (V4 only; V1-V3 fingerprint-identical): fragment variants F3 portal_a/portal_out, F4 gate-on-input (`FUK`), F5 remote_gate, F6 prism_one, F7 portal; Fusion load-bearing ablation now uses a dead-node BLOCKER (deleting the tile produced false rejections) - realised Fusion share now inside every band target (14/23/27/20/31/34/22%); new exact shortcut screens in `ProceduralFusionCheck`.
- Verified: 8 tutorial boards each have exactly one solution; all 28 tutorials replay in the real game scene; 540-level stress 0 problems / 0 fallbacks; 30 levels PROVEN OPTIMAL & unique; Save/Continue restores a Fusion level exactly; 140 campaign + 15 dev levels + T01-T20 regression clean.
- Not built (by request or scope): chained Fusion, Level 2001+, star economy, production flag clean-up, tutorial mechanic icon (panel has no icon support).

## Fusion Node Phase 2 - Fusion in the main V3 procedural progression (2026-09-24)

Build `versionCode=55`, `versionName="4.5.0-FUSION-PROGRESSION-QA"` (`builds/android/beamshift-debug.apk`, 108,932,092 bytes, Google TEST ads unchanged). `DECISIONS.md` D100.
- Generator V4 (`GENERATOR_VERSION_V4`): the V3 progression generator with seven Fusion fragments (F1 basic, F2 filter inputs, F3 portal, F4 -> switch/gate, F5 -> receiver/remote, F6 prism + fusion, F7 RGB -> WHITE -> prism), unlocked by `ProceduralDifficultyContract._FUSION_PROGRESSION` from Level 201 (none in 1-200), one deterministic roll per level (realised share 14-28% per band). V1/V2/V3 frozen (99/99 fingerprints identical). New play uses V4 (`LevelManager.USE_FUSION_PROGRESSION_FOR_QA`); saved V3/V4 puzzles regenerate under their own version.
- New: `ProceduralFusionCheck` (per-input ablation, colour-consumption, feedback/cycle rejection, settling of start/solved/one-tap-away boards, WHITE guards). `LaserSystem.simulate_until_stable` returns `passes`/`converged`. Composer `fusion`/`fjoin` tokens; wrong-direction output hardening; widened runtime shortcut probe for Fusion boards; 4-state Fusion in greedy/probe/complexity (`fusion_dependency_count`).
- Verification: exhaustive search PROVEN OPTIMAL for every checked level up to ~140k states (one real shortcut found and fixed), 60,000 random boards settle, end-to-end save/Continue/Hint/ad checks 28/28, dev levels 15/15, campaign 140/140, tutorial 20/20, Fusion QA 6/6, prototypes A-F unchanged.
- Level 2000 is now the INITIAL_CERTIFIED_LEVEL_TARGET, not an architectural ceiling (contract reads its last row past 2000; nothing beyond 2000 is exposed). `MAX_COLUMNS` stays 8.
- Docs: ARCHITECTURE.md verified/corrected after the Phase 1 deletion incident (autoload list, hint button). RELEASE BLOCKER recorded: Fusion tutorial before production.

## Fusion Node Phase 1 - QA only (2026-09-24)

`DECISIONS.md` D99. Build `versionCode=54`, `versionName="4.4.0-FUSION-NODE-QA"` (`builds/android/beamshift-debug.apk`, 108,914,289 bytes; Google TEST ads unchanged).
- Beam Fusion Node (R+G=YELLOW, R+B=MAGENTA, G+B=CYAN, RGB=WHITE): `TileType.FUSION`, appended `BeamColor` YELLOW/MAGENTA/CYAN, `GridTypes.combine_beam_colors`, LaserSystem fusion state, `FusionTile`, 4-state rotation, Hint support, `laser_split` reuse.
- Six QA puzzles, Main Menu "FUSION TEST" / "NEXT FUSION" (`LevelManager.SHOW_FUSION_TEST_QA`), contained like V3 TEST. Not in procedural V3 / campaign; no final tutorial.

## AdMob Foundation V1 - rewarded Hint + interstitial every 4 completions (2026-09-24)

Details: `ADS_MONETIZATION.md`, `DECISIONS.md` D98. Build **`versionCode=53`, `versionName="4.3.0-ADMOB-FOUNDATION-QA"`**
(`builds/android/beamshift-debug.apk`, 105,914,950 bytes). **Google test ads only.**
- New: `AdManager` autoload, `scripts/ads/` (`AdConfig`, `AdBackend`, `AdBackendAdMob`, `AdBackendFake`), `addons/admob` (Poing AdMob v5.1.0), three additive
  SaveManager ad fields, Hint permission wiring, interstitial at Level Complete -> Next Level, `ADS_MONETIZATION.md`.
- Android build now uses Gradle (`android/build`, JDK 17); manifest carries the sample App ID. iOS prepared, not built.
- Fixed a missing-key script error in V3 prototype 3 (`_plan_c`).
- Tests (fake backend, real game scene): 35 checks pass. Not verified: real SDK/ads on a device.


## Global Hint System Phase 1 (2026-09-24)

Details: `DECISIONS.md` D97. Build **`versionCode=52`, `versionName="4.2.1-GLOBAL-HINT-QA"`**
(`builds/android/beamshift-debug.apk`, 79,812,864 bytes, 789 entries).
- New: `scripts/gameplay/hint_manager.gd`, `levels/hint_solutions.json` (160 solver-authored solutions),
  dev tool `scripts/tools/hint_solution_builder.tscn`. `GridManager` gained a dim-free hint ring;
  `game.gd` wires the shared HUD Hint button (visible where a hint source exists).
- One press = one required tile (ring only); no solver at runtime; no move/save/star effect; history per
  puzzle, reset by Reset/QA jump/new level; tutorials never bypassed. No star penalty (pending decision).
- Tested via the real game scene: V3 L1/100/500/1000/1900/2000, V1, V2, V3 TEST, campaign 3/90, tutorials 1/12,
  `+50`, audio 22/22 - all pass.


## Difficulty System Phase 2B - V3 progression generator (2026-09-24)

Full detail in `DECISIONS.md` D96 and `PROCEDURAL_GENERATION.md` section 19.
Build: **`versionCode=51`, `versionName="4.2.0-PROCEDURAL-V3-PROGRESSION-QA"`**
(`builds/android/beamshift-debug.apk`, 786 entries, 79,804,416 bytes; no `_qa_tmp`/`scripts/tools`).

- New runtime generator files: `procedural_fragments_v3.gd` (atoms, band pools, escalation,
  turn budget), `procedural_composer_v3.gd` (router, backtracking, restarts, colour/leak/
  hardening rules), `procedural_progression_v3.gd` (attempt loop, gates, fallback policy),
  `procedural_shortcut_probe.gd` (bounded runtime shortcut search). Extended:
  `procedural_board_v3.gd` (`path_axis`, snapshot/restore, `tile_line`, `center_content`),
  `procedural_plan_v3.gd` (`lines`), `procedural_complexity.gd` (public `touched_cells`/
  `progress_score`), `procedural_difficulty_contract.gd` (Phase 2B bands, `_V3_POLICY`, boards,
  unlocks, `band_code`).
- `LevelManager.USE_V3_FOR_PROCEDURAL_QA` + `procedural_generator_version_for_new_play()`;
  `game.gd` tracks the loaded puzzle's generator version (stars use the right version) and
  shows a QA-only `V3 <band>` line; `ProceduralLevelGenerator.generate(n, 3)` now routes to the
  progression generator. Prototype fixtures unchanged (diffed identical).
- Dev-only tools: `scripts/tools/v3_progression_sample.tscn` (25-level report + independent
  checks + optional solver subset), `v3_progression_stats.tscn` (range statistics: fallbacks,
  rejection histogram, solver/probe agreement, timings).
- Bugs found by dumping rejected boards: leaky line ends (mirrors do not absorb beams),
  colour bypass via raw prism channels, beams through emitter cells, wrong-ray alignments,
  straight-run pockets. Details in D96.
- Evidence: 25/25 sample levels pass; 286 sampled levels 0 validator errors/0 fallbacks;
  ~357 solver-checked levels 0 shortcuts with the probe on; greedy solves 0% from Level 201.
- Not done on purpose: full 1-2000 audit, stars, new mechanics, visual/audio changes, default
  rollout, commit.


## Difficulty System Phase 2A.1 - reasoning depth for V3 prototypes D/E/F (2026-09-24)

Full detail in `DECISIONS.md` D95 and `PROCEDURAL_GENERATION.md` section 18.7.
Build: **`versionCode=50`, `versionName="4.1.1-PROCEDURAL-V3-THINKING-QA"`**
(`builds/android/beamshift-debug.apk`, 778 entries).

- D/E/F layouts, plans and acceptance profiles rebuilt around globally
  constrained decisions and less self-explanatory start states (some route
  tiles start correct; wrong-but-purposeful states at start). Phase 2A.1
  focuses on reasoning depth rather than raw move count (8/11/11 moves).
- D: shared One-Way + second One-Way that must be PASSED + Portal; E: colour
  fork with a wrong-colour decoy route + Portal; F: shared One-Way whose pass
  state lights a second target with the wrong beam, two Portal hops.
- New: `Cursor.to_one_way_hold`, `Cursor.to_join`, `third_color`,
  `requirements_for(archetype)`, `ProceduralComplexity.start_state_visibility`
  and `greedy_follow_solve`; audit prints them. A/B/C unchanged (diffed).
- Solver (dev-only): D/E/F optimal == intended, unique, on 12+ seeds each.
- Known: greedy beam-follower proxy still solves F; F needs attempt 1/3 on
  levels 24/36 (padding on attempt 0).


## Difficulty System Phase 2A - Generator V3 prototype (2026-09-23)

Full detail in `DECISIONS.md` D94 and `PROCEDURAL_GENERATION.md` section 18.
Build: **`versionCode=49`, `versionName="4.1.0-PROCEDURAL-V3-PROTOTYPE-QA"`**
(`builds/android/beamshift-debug.apk`, 778 entries, no `_qa_tmp`/`scripts/tools`).

- New dependency-first generator V3: `procedural_plan_v3.gd`,
  `procedural_planner_v3.gd`, `procedural_board_v3.gd`,
  `procedural_layout_v3.gd`, `procedural_generator_v3.gd` (six reusable
  archetypes A-F; ~8-12 meaningful moves; Phase 1 complexity/triviality are
  now real acceptance gates).
- Named versions `GENERATOR_VERSION_V1/V2/V3`; default stays 2; V1/V2
  untouched and re-verified; `generate(n, 3)` routes to V3.
- Dev-only QA access: Main Menu "V3 TEST" -> six prototypes, in-game "NEXT V3"
  cycle; V3 sessions never touch saves. `LevelManager.SHOW_V3_PROTOTYPE_QA`.
- Dev-only `scripts/tools/v3_prototype_audit.tscn`: all six pass; solver
  optimal == intended, unique solution, on every prototype (it caught and
  drove a fix for a real shortcut in F).
- `ProceduralComplexity` now also returns `load_bearing_units`;
  `export_presets.cfg` excludes `_qa_tmp/**`.
- QA `+50` and PLAY/CONTINUE unchanged (re-verified).

## Difficulty System Phase 1 (2026-09-23)

Real-device feedback: a Level 1900+ puzzle solved in about 3 moves. Full
detail in `DECISIONS.md` D93 and `PROCEDURAL_GENERATION.md` section 17.
**No APK; `versionCode` stays 48.** Generation output is unchanged.

- New permanent principle: a procedural puzzle is not accepted solely
  because it is solvable; difficulty = optimal moves AND meaningful
  reasoning complexity; independent/obvious-rotation padding is not
  difficulty after the early game.
- Added `scripts/procedural/procedural_difficulty_contract.gd` (one
  authoritative 11-band table), `procedural_complexity.gd` (ablation-based
  metrics through the real `LaserSystem`), `procedural_triviality.gd`
  (`TRIVIAL_*` verdicts), and dev-only `scripts/tools/difficulty_inspect.gd`/
  `.tscn`.
- `ProceduralLevelGenerator.generate()` now also returns
  `solution_orientations` and `intended_moves` (read-only).
- QA +50 centralized: `LevelManager.PROCEDURAL_QA_JUMP_AMOUNT := 50`; label
  "+50" derived from it; a press at Level 2000 is a no-op.
- Root cause traced: frozen V1 yields 3-5 move puzzles in 1801-2000 (1842,
  1897 = 3 moves); V2 never enforces its move minimum and templates are one
  zigzag plus at most one special tile; 99/100 of a V2 sample fail the new
  contract. Phase 2 (construction by design) awaits approval.


## Unified Blue Theme Fix (2026-09-23)

The user approved the Minimal Gameplay Background pass but rejected a
separate, pre-existing behavior it surfaced: Era 2 content (Campaign
Levels 101+, T11-T20) automatically switched the whole gameplay screen
to a violet/magenta skin. Full detail in `DECISIONS.md` D91. Build:
**`versionCode=48`, `versionName="4.0.4-UNIFIED-BLUE-QA"`**, package
`com.beamshift.game`.

- **BeamShift now uses exactly ONE active gameplay theme (blue/cyan)
  across all 2,000 procedural levels, the legacy campaign, and every
  tutorial.** Single authoritative switch: `EraTheme.
  UNIFIED_BLUE_THEME_ONLY := true` (`scripts/resources/era_theme.gd`),
  checked first inside `for_era()` — every visual-theme call site
  already routed through this one function, so this is the complete fix
  (and, flipped back, the complete revert).
- **Progression/unlock/mechanic-teaching logic is completely
  unaffected** — `EraTheme.get_era_for_level()`/`get_era_for_tutorial()`
  and their two non-visual callers (T11-T20 unlock gating, the Level
  100→101 transition banner) read the numeric era directly, never
  anything from `for_era()`'s returned object.
- **Purple Era 2 assets retained, not deleted** — `_build_era_2()` and
  every Era 2 PNG are fully intact on disk and in source, simply
  unreachable while the flag is on.
- **Prism/One-Way Reflector/Beam Receiver/Remote Emitter keep their
  existing purple-toned tile art** — these were never routed through
  `EraTheme` to begin with, so this fix has no effect on them either
  way; per the standing "never generate or destructively recolor art"
  rule, they're left as the one remaining visible purple element in
  normal gameplay (small tile icons, not a skin) until a genuine
  blue-specific replacement exists.
- **Two small residual-purple issues found and fixed along the way**:
  T11's own tutorial text no longer claims "only the scenery" changes
  (it doesn't, anymore); `level_complete_popup.tscn`'s one-time Era 2
  unlock announcement recolored from violet to cyan-blue text.
- **RENDERED-verified (D45-D47 tier)** across Campaign Levels
  21/99/100/101/102/140, procedural Levels 200/500/1000/1500/2000, and
  Tutorials T01/T11/T20 — Level 21 vs. Level 102 (the key comparison)
  confirmed visually indistinguishable in background/grid/HUD family.
  Procedural determinism, PLAY/CONTINUE/QA Next, and AudioManager
  (22/22 streams) all re-confirmed unaffected. No save schema change.
- **NOT MANUALLY APPROVED — Android device visual QA pending.**

## Minimal Gameplay Background Pass (2026-09-23)

The user reported the gameplay background's environmental detail
competes visually with the puzzle and asked for an investigation before
any new art was generated. Full detail in `DECISIONS.md` D90. Build:
**`versionCode=47`, `versionName="4.0.3-MINIMAL-BG-QA"`**, package
`com.beamshift.game`.

- **Non-destructive fix: `game.tscn`'s root `Background` `TextureRect`
  gained `modulate = Color(0.22, 0.26, 0.38, 1)`** — no PNG edited. Since
  `game.gd._apply_era_theme()` only ever swaps this node's `.texture`
  (never its `.modulate`), the darkening applies uniformly under every
  Era, current and future, with zero per-level or per-era code.
- **Confirmed via RENDERED evidence (D45-D47 tier) that HUD, grid cells,
  tiles, and beams are structurally unaffected** — a HUD-art pixel
  sampled bit-for-bit identical before/after, not just visually
  unchanged; a background-art pixel matched the modulate multiplier
  almost exactly.
- **Neither existing gameplay background PNG qualified as "minimal" on
  its own** (checked before writing any fix): the Era 1 background has
  a floor-tile pattern that visually echoes the grid plus prominent
  orange/blue glow strips; the Era 2 background is quieter centrally but
  is a different hue family (violet) and is Era 2's own deliberate
  identity, not a general-purpose asset. No new image was generated,
  per the brief's explicit instruction.
- **Environment discovery, reusable going forward**: this dev machine's
  physical 2560x1080 monitor silently clamps any on-screen portrait
  test window taller than ~1032px, which was quietly reflowing every
  prior "1080x1920" on-screen RENDERED capture on this machine to a
  near-square aspect instead of the intended portrait one. Fixed by
  capturing through an off-screen `SubViewport` with an explicit size
  instead of relying on the physical window — see `TEST_PLAN.md`'s
  section of the same name for the full technique.
- **Board-size gap found, deliberately NOT fixed this pass**: some small
  boards occupy less of the available portrait height at some
  resolutions — recorded as a separate future generator/layout-quality
  task in `CLAUDE.md` and `DECISIONS.md` D90.
- **NOT MANUALLY APPROVED — Android device visual QA pending.**

## Audio/SFX Integration Pass (2026-09-23)

The user staged 22 renamed Kenney-sourced SFX files under `assets/sfx/`
and requested a centralized audio architecture. Full detail in
`AUDIO_SYSTEM.md` (new file) and `DECISIONS.md` D89. Build:
**`versionCode=46`, `versionName="4.0.1-AUDIO-SFX-QA"`**, package
`com.beamshift.game`.

- **One centralized `AudioManager` autoload** (4th autoload) exposing 22
  semantic `play_*()` methods — no level or scene ever instantiates its
  own `AudioStreamPlayer`, and `LevelData`/`TilePlacement` gained zero
  new fields, so all 2,000 procedural levels get audio automatically.
- **New `Master`/`SFX`/`UI` audio buses** (`assets/audio/default_bus_layout.tres`);
  Settings' existing Sound toggle now mutes both `SFX` and `UI` together.
- **Gameplay audio only plays for an actual accepted player move** —
  reuses `GridManager._simulate_and_draw()`'s existing `play_impacts`
  parameter as the gate, so Continue/resume restoration, level load,
  Reset/Retry, and the procedural generator/solver/audit are silent by
  construction, not by a separate suppression flag.
- **Transition-only + de-duplicated playback**: target/switch/gate/
  hazard/receiver/remote-emitter audio fires only on a false→true
  transition; beam-interaction audio (reflect/split/filter/portal)
  de-dupes by position per evaluation.
- **10-voice pooled `AudioStreamPlayer`** — short SFX overlap correctly,
  never an unbounded number of player nodes.
- **Era 2 mechanics reuse existing SFX** (no new assets): Prism →
  `laser_split`, One-Way Reflector → `laser_reflect`, Beam Receiver →
  `switch_activate`, Remote Emitter → `laser_activate`.
- **3 of the 22 SFX are registered but deliberately unused** (no matching
  gameplay event exists — see `AUDIO_SYSTEM.md` section 11): wrong-target,
  star-appear, and locked-UI-tap sounds.
- **One real gap found and fixed during this pass's own verification**:
  One-Way Reflector reflections initially played no SFX (only `MirrorTile`
  was checked) — fixed before the pass ended.
- **NOT MANUALLY APPROVED — Android device audio QA pending**; per-SFX
  gains are unlistened placeholder values.

## Phase 3: Procedural Level Generator V1 + QA Next button (2026-09-23)

The user requested the procedural generator itself, superseding D87's own
"wait for Android QA" deferral for this pass. Full detail in
`PROCEDURAL_GENERATION.md` (new file) and `DECISIONS.md` D88. Build:
**`versionCode=45`, `versionName="4.0.0-PROCEDURAL-V1-QA"`**, package
`com.beamshift.game`.

- **2,000 deterministic procedural levels**, generated on-device from a
  level number + generator version, never hand-authored source files.
  New `scripts/procedural/` module (`ProceduralSeed`,
  `ProceduralDifficultyProfile`, `ProceduralTemplates`,
  `ProceduralLevelGenerator`) — runtime code, not dev-only.
- **Main Menu `PLAY`/`CONTINUE` now target procedural progression**
  instead of the legacy Campaign. The legacy Campaign (1-140) is
  unchanged, reachable only via the existing QA Level Select screen.
- **The live generator never calls `LevelSolver`/`LevelValidator`**
  (dev-only, excluded from the Android export) — it self-verifies each
  candidate via a direct `LaserSystem` simulation of its own already-known
  solution. Those dev-only tools instead exhaustively proved the
  generator's own output during a dev-time-only audit
  (`scripts/tools/procedural_audit.gd`): full 1-2000 range, 0 failures,
  0 fallbacks, 11/11 determinism matches, all 10 templates used.
- **Temporary QA "NEXT" button** (`LevelManager.
  SHOW_PROCEDURAL_QA_NEXT_BUTTON`) lets a tester skip ahead without
  solving every level — proven end-to-end to never mark a level
  legitimately completed or advance real progression.
- **Four real generator bugs found and fixed during this pass's own
  audit** (a `portal_route` geometry bug, a leg-count clamping bug, a
  lost direction-parity constraint, and a template-selection bug that
  silently starved 6 of 10 templates despite 0 audit failures) — see
  `DECISIONS.md` D88 for the full writeup and general lessons.
- **`SaveManager.SAVE_VERSION` 4→5** (additive `procedural_*` fields,
  no migration code needed, same pattern as every prior schema bump).

## Final Gameplay Spacing Refinement (2026-09-23)

The user manually tested `versionCode=43` and confirmed the larger-tile
layout "MUCH BETTER... close to the desired result" — this pass is a
final polish only. Full detail in `DECISIONS.md` D87. Build:
**`versionCode=44`, `versionName="3.6.2-FINAL-SPACING-QA"`**, package
`com.beamshift.game`.

- **Top/Bottom HUD moved closer to the screen edge.**
  `SafeAreaMargin.margin_override` split into `horizontal_margin_
  override` (kept at 32px, unchanged from D86) and `vertical_margin_
  override` (new, 8px). Tile size and left/right margin untouched, as
  requested.
- **Proved mathematically, not just tried**: for a width-bound board
  (the common case), the vertical margin has zero effect on the
  HUD-to-board gap itself — `CenterArea`'s `EXPAND_FILL` sizing plus the
  board's own centering makes the total gap algebraically independent
  of both the vertical margin and `VBoxContainer` separation. Confirmed
  by a direct render sweep of Level 28 (the reference level): the HUD
  bar's own position moved as expected, but total HUD-to-board space
  stayed exactly 619px at every margin value tested.
- **This is the honest mathematical limit, not an incomplete fix** —
  closing the gap further would need different HUD art or a board shape
  that isn't width-bound, both out of scope.
- **Future procedural generator guidance recorded**: prefer taller
  board profiles (e.g. 5x9, 6x10, 7x11, 8x11) to avoid landing
  width-bound in the first place, gated on `is_board_profile_
  comfortable()` — the durable fix for new content.
- **Regression**: 188/188 PASS (unchanged). Phase 2 re-check: 12/12
  PASS. Full resolution/profile matrix unchanged at 140/140 comfortable.
- **NOT MANUALLY APPROVED — Android device QA pending.**

## Full-Screen Board Correction (2026-09-23)

**Corrects a real bug shipped in the previous pass.** The user tested
`versionCode=42` on a real Android phone and found Level 27 (7x8)
rendering with large wasted vertical space and a small, centered board
— a real, correctly-reported regression. Full detail in `DECISIONS.md`
D86. Build: **`versionCode=43`, `versionName="3.6.1-FULLSCREEN-BOARD-QA"`**,
package `com.beamshift.game`.

- **Root cause**: the prior pass validated its layout math only at the
  1080x1920 reference resolution and never rendered a real campaign
  level at the 4 other required (taller) resolutions. `canvas_items`/
  `expand` stretch mode reveals more logical canvas height on taller
  devices without a width-bound board's `cell_size` growing to match —
  Level 27's height utilization silently degraded from 94.2% (at the
  reference) to 64.7% (at 1080x2400) with zero level or code change.
- **`SafeAreaMargin` gained `margin_override`** — `game.tscn` now uses
  a smaller, gameplay-specific baseline (`UIConstants.
  GAMEPLAY_BASELINE_MARGIN := 32.0`) instead of the menu-tuned
  `BASELINE_MARGIN := 96.0`. Every menu screen's `SafeAreaMargin`
  instance is untouched. Real Android safe-area insets still widen it.
- **Result**: Level 27's cell_size 124px→142px (+14.5%), height
  utilization 64.7%→72.3%; full 5-resolution × 12-profile matrix now
  **140/140 comfortable** (up from 136/140). Visually confirmed via 5
  real rendered levels/tutorial (Level 1, 27, 100, Era 2 Level 110,
  Tutorial T01), not just metrics.
- **Honestly disclosed, not fully solved**: a width-bound board's
  `cell_size` was already maximized for its available width — some
  residual gap on very tall devices for boards authored against the
  1080x1920 floor remains mathematically unavoidable without a level
  redesign or non-square cells, both out of scope this pass.
- **Regression**: 188/188 PASS (unchanged). New 12-point Phase 2
  (Direct Play + Continue) re-check: 12/12 PASS.
- **NOT MANUALLY APPROVED — Android device QA pending.**

## Phase 2: Direct Play + Continue Flow (2026-09-23)

Main Menu's `PLAY` button (previously labeled "CAMPAIGN," routing to
Level Select) now enters the player's current campaign progression
directly; `CONTINUE` resumes it, including exact mid-level tile
orientations and move count. Level Select retained, QA/dev-only. Full
detail in `DECISIONS.md` D85. Build: **`versionCode=42`,
`versionName="3.6.0-DIRECT-PLAY-CONTINUE-QA"`**, package
`com.beamshift.game`.

- **`GameManager.play_game()`/`continue_game()`** both resolve
  `LevelManager.get_campaign_continue_level_id()` directly — no more
  Level Select roundtrip for a normal player.
- **`GameManager.entered_via_level_select`** distinguishes a QA Level
  Select session from a normal PLAY/CONTINUE one: routes Back/Pause/
  Level-Complete's "Level Select" navigation correctly for each, and
  gates whether the session touches resume state at all.
- **Exact mid-level resume**: new `SaveManager.campaign_resume_*` fields
  (`SAVE_VERSION` 3→4), `GridManager.restore_orientations()`, event-
  driven persistence on every accepted move. Reset/Retry always start
  fresh, never resume their own pre-reset state.
- **Level Select is QA/dev-only now** — reached via a small Main Menu
  button gated on `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`.
  `level_select.tscn`/`.gd` themselves are completely unchanged.
- **`TutorialCompletePopup`'s own "CAMPAIGN" button** (shown on the
  final tutorial of a pack) had the identical problem — relabeled
  "PLAY", rewired to `GameManager.play_game()`.
- **Full regression: 188/188 PASS** (unchanged — no level/solver code
  touched). New dedicated resume-flow test: **19/19 PASS**.
- **NOT MANUALLY APPROVED — Android device QA pending**, on top of
  Phase 1's own still-outstanding review.

## Phase 1: Shared Adaptive Gameplay Layout Foundation (2026-09-23)

New product direction recorded: BeamShift's long-term target is now
**2,000 procedurally-generated levels** (direct PLAY/CONTINUE, no
player-facing Level Select) — the generator itself is NOT built this
pass. Full detail in `DECISIONS.md` D84. Build: **`versionCode=41`,
`versionName="3.5.0-ADAPTIVE-LAYOUT-QA"`**, package `com.beamshift.game`.

- **Confirmed the shared, centralized gameplay layout already existed.**
  `game.tscn`'s `SafeAreaMargin`→`Layout`→`TopBar`/`CenterArea`/
  `BottomBar` structure, `grid_manager.gd`'s independent-per-axis
  cell-size formula, and whole-cell tap (`TileVisual` sized to the full
  cell) were all already in place from the Rectangular Grid Architecture
  (D72) and Portrait Re-Layout (D73-D76) passes — no level has ever
  owned HUD positioning.
- **Added the future-procedural contract** (all additive, in
  `scripts/gameplay/grid_manager.gd`): `MAX_COLUMNS := 8`,
  `MIN_COMFORTABLE_CELL_SIZE := 96.0`, and
  `is_board_profile_comfortable(columns, rows, playable_size)`.
- **Column audit** (report only): 54 campaign levels, 1 tutorial level
  (T20), and 3 editor fixtures already exceed 8 columns — grandfathered
  as legacy/regression content, none modified.
- **Resolution/board-profile matrix**: 720x1280 through 1080x2560 × 12
  representative procedural profiles (5-8 columns × 7/9/11 rows) —
  136/140 comfortable; only 11-row boards on the two shortest device
  heights dip 1px under the comfort floor.
- **Full regression: 188/188 PASS** (15 dev + 140 campaign + 20 tutorial
  + 13 Era 2 fixtures) — zero regression from the purely-additive
  `grid_manager.gd` change.
- **NOT MANUALLY APPROVED — Android device QA pending.** Per the pass's
  own STOP CONDITION: Direct Play/Continue and the procedural generator
  are explicitly NOT started.

## Era 2 Levels 131-140 (2026-09-22)

"Advanced convergence pass" - user-requested, explicitly authorized
before ANY of the three prior Era 2 level batches had received manual
Android QA. No new mechanics. Full detail in `DECISIONS.md` D83.
Build: **`versionCode=40`, `versionName="3.4.0-ERA2-L131-140-QA"`**,
package `com.beamshift.game`, 79,386,201 bytes, both QA unlock flags
kept `true`.

- **Campaign Levels 131-140 added.** `get_campaign_level_count()` is
  now 140. Highlights: 131 shares one reflector between two Prism
  colors from genuinely different directions; 132/138 build reciprocal
  relay chains; 135 demonstrates fair target continuation; 140
  ("Refraction Engine") combines four subsystems including a two-stage
  Remote Emitter chain and a Portal.
- **The most shortcut-prone batch yet: 5 of 10 levels needed a fix
  during authoring.** One was a genuine authoring error (a mirror
  inserted into an already-complete straight path, making its target
  unreachable). The other four were solver-caught shortcuts, including
  a new variant of the established `WHITE`-target-bypass bug and one
  genuinely new failure shape (a shared reflector's two beams
  approaching from the same rather than opposite sides, requiring a
  full geometric rebuild to fix).
- **Regression**: 15/15 dev, 140/140 campaign, 20/20 tutorial, 13/13
  Era 2 fixtures, all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 130->140 walk.
  RENDERED verification at three resolutions.
- **NOT MANUALLY APPROVED — Android device QA pending.** Per the
  user's own instruction, a MANUAL ANDROID REVIEW CHECKPOINT is
  recommended before continuing to Levels 141+ - four consecutive
  unreviewed Era 2 batches (40 levels) now await real-device feedback.

## Era 2 Levels 121-130 (2026-09-22)

"Deep dependency pass" - user-requested, authorized before any prior
Era 2 level batch had received manual Android QA. No new mechanics -
moves beyond single-chain dependency into whole-board reasoning. Full
detail in `DECISIONS.md` D82. Build: **`versionCode=39`,
`versionName="3.3.0-ERA2-L121-130-QA"`**, package `com.beamshift.game`,
79,355,579 bytes, both QA unlock flags kept `true`.

- **Campaign Levels 121-130 added.** `get_campaign_level_count()` is
  now 130. Highlights: 121 shares one One-Way Reflector between two
  Prism color channels; 122 and 128 build reciprocal (not merely
  parallel) Receiver/Remote-Emitter relays; 125 is a deliberate near-
  solution trap requiring backward reasoning from a target's color;
  130 ("Convergence Matrix") requires four independently-resolved
  prerequisites to converge on one target.
- **Two issues found and fixed during authoring**: Level 123 had a
  simple grid-bounds error (caught explicitly by `LevelValidator`).
  Level 127 hit a new shortcut shape beyond the previous pass's "beam
  continues past its own target" family - a wrong-orientation mirror's
  stray path crossed a second, unrelated mirror whose own default
  orientation completed an accidental Portal-bypassing shortcut; fixed
  with a precisely placed blocker.
- **Regression**: 15/15 dev, 130/130 campaign, 20/20 tutorial, 13/13
  Era 2 fixtures, all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 120->130 walk.
  RENDERED verification at three resolutions.
- **NOT MANUALLY APPROVED — Android device QA pending** (same as every
  prior Era 2 batch).

## Era 2 Levels 111-120 (2026-09-22)

User-requested follow-up, authorized before manual Android QA of Levels
101-110 was finished. No new mechanics - deepens Prism/One-Way
Reflector/Beam Receiver/Remote Emitter through dependency depth, shared
resources, and misleading local reasoning. Full detail in
`DECISIONS.md` D81. Build: **`versionCode=38`,
`versionName="3.2.0-ERA2-L111-120-QA"`**, package `com.beamshift.game`,
79,324,957 bytes, both QA unlock flags kept `true`.

- **Campaign Levels 111-120 added.** `get_campaign_level_count()` is
  now 120. Highlights: 112 reuses one One-Way Reflector for two beams
  from two directions; 115 puts all three Prism channels through their
  own One-Way Reflector; 118 makes two Receiver/Remote Emitter pairs
  genuinely interdependent via one shared gate cell; 120 ("Era 2
  Circuit") combines all four Era 2 mechanics with a cross-color shared
  gate and a pass-through-not-reflect finale.
- **Three real shortcut bugs found and fixed by the solver** - all the
  same failure shape: a beam continuing past its own activated target
  (targets never stop a beam) into a second mechanic it was never meant
  to reach. Level 112 and 118 needed one fix each (moving a tile off a
  shared column); Level 120 needed two attempts, since the first fix
  only changed a default orientation and left an alternate same-length
  shortcut - the real fix relocated the tile so no orientation of it
  could ever be reached by the stray beam.
- **Regression**: 15/15 dev, 120/120 campaign, 20/20 tutorial, 13/13
  Era 2 fixtures, all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 110->120 walk.
  RENDERED verification at three resolutions.
- **NOT MANUALLY APPROVED — Android device QA pending.**

## Era 2 Levels 101-110 (2026-09-22)

Two-part, user-requested pass: fixed a real Tutorial Select button-shape
regression the user found on a real device, then built the first real
Era 2 campaign content. Full detail in `DECISIONS.md` D79/D80.
Build: **`versionCode=37`, `versionName="3.1.0-ERA2-L101-110-QA"`**,
package `com.beamshift.game`, 79,298,431 bytes, both QA unlock flags
kept `true`.

- **Fixed T11-T20 Tutorial Select cards**: they had regressed to tall
  rectangular "poster" cards (a 1024x1536px asset covered/cropped into
  the button's 240x253 box). Fix: stop swapping texture for Era 2 —
  tint the same square Era 1 frame via `TextureRect.modulate`. Applied
  to `tutorial_button.gd` (the live bug) and `level_button.gd`
  (the identical dormant bug, fixed pre-emptively).
- **Campaign Levels 101-110 added** — the first Era 2 campaign content,
  combining Prism/One-Way Reflector/Beam Receiver/Remote Emitter with
  selected Era 1 mechanics. Stored at `levels/campaign/era2_stage_01/`.
  `get_campaign_level_count()` is now 110. Every level solver-confirmed
  `SOLVABLE` with a unique shortest solution and zero validator errors
  on the first authoring attempt.
- **Fixed `game.gd`'s `era_transition` banner logic**, which was keyed
  off "current level == last implemented level" and would have silently
  shifted from firing at Level 100 to Level 110 the moment these levels
  were added — now compares `EraTheme.get_era_for_level()` across the
  level boundary, correct today and for any future era boundary.
- **Regression**: 15/15 dev, 110/110 campaign, 20/20 tutorial, 13/13 Era
  2 fixtures, all solver+runtime-replay PASS. Progression/save verified
  against the real `SaveManager` API (Level 100 completion correctly
  unlocks Level 101). RENDERED verification at three resolutions.
- **NOT MANUALLY APPROVED — Android device QA pending.**

## Era 2 Foundation QA/Hardening Pass (2026-09-22)

Closed the gaps the "Era 2 Foundation" pass below left open, under its
own STOP CONDITION (no Campaign Levels 101+, no T21+, no Era 3, no
production release). Full detail in `DECISIONS.md` D78.
Build: **`versionCode=36`, `versionName="3.0.1-ERA2-FOUNDATION-FIX-QA"`**,
package `com.beamshift.game`, 83,384,755 bytes (down 24.9% from the
previous build's 111,090,272 bytes), both QA unlock flags kept `true`.

- The user-supplied `bs_milestone_complete_era2.png` verified (real
  alpha, no baked text/checkerboard, present in a real exported APK)
  and deliberately left unwired — Level 200 doesn't exist yet.
- **T11-T20 now have a real guided-step-machine test** (previously only
  solver/validator-tested) — a driver mirroring `game.gd`'s own
  `GridManager` signal wiring drove all 10 through every step type,
  including wrong-tile-tap rejection, Reset, Pause/Resume, and
  completion. **10/10 PASS.**
- **Two new UI integrations**: `LevelCompletePopup`/`TutorialCompletePopup`
  now swap in real Era 2 panel art via `EraTheme`, and Tutorial Select's
  T11-T20 cards now use the Era 2 card art (mirroring `level_button.gd`'s
  previously-dormant wiring). Two real rendering bugs (a `content_margin`
  override, a `TextureRect` stretch-mode misalignment) were found and
  fixed via RENDERED verification before either shipped.
- Six other Era 2 UI assets reviewed and deliberately left unwired — see
  `DECISIONS.md` D78's A/B/C classification.
- **APK size cut 24.9%** by excluding `bs_grid_surface_era2.png` and all
  8 `assets/gameplay/fx/era2/*.png` files (confirmed completely
  unreferenced — `Era2ActivationFX` is procedural) plus 9 unwired UI
  assets from the Android export filter, verified against a real
  exported APK's own zip listing.
- Resolution matrix (720x1280/1080x1920/1080x2400) and color readability
  (RED beam vs. UI magenta — 68.5° hue separation, pixel-measured)
  re-confirmed clean; no gameplay color or UI scrim/glow changes made.
- Fixed a documentation undercount: the Era 2 fixture population is 13
  files, not 12.
- Validated: 15/15 dev, 100/100 campaign, 13/13 Era 2 fixtures, 20/20
  tutorial boards solvable, 10/10 T11-T20 guided step-machine — all
  PASS. **NOT MANUALLY APPROVED — Android device QA pending.**

## Era 2 Foundation (2026-09-22)

Built Era 2 ("Refractions")'s engine/architecture foundation — **not**
its 100-level campaign, explicitly out of scope for this pass. Full
detail in `ERA_2_DESIGN.md` and `DECISIONS.md` D77.
Build: **`versionCode=35`, `versionName="3.0.0-ERA2-FOUNDATION-QA"`**,
package `com.beamshift.game`, 111,090,272 bytes, both
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`/
`UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` `true`.

- **Era architecture**: `EraTheme` (`scripts/resources/era_theme.gd`,
  not an autoload) maps a campaign level/tutorial number to its Era and
  fetches that Era's themed assets. Era 1's theme is all-null by
  construction — Levels 1-100/T01-T10 verified visually unchanged.
- **Four new deterministic mechanics**: Prism (WHITE splits into
  RED/GREEN/BLUE via `reflect()`; a colored beam only uses its own
  channel), One-Way Reflector (reuses Mirror's rotation model —
  reflective side derived from orientation, no new state), Beam
  Receiver → Remote Emitter (new `receiver_states` layer resolved by
  `simulate_until_stable()` exactly like switch → gate). Zero
  `LevelSolver` changes needed. 12 new dev fixtures.
- **T11-T20**: the Era 2 tutorial pack, locked until Level 100 is
  legitimately completed, with a QA override mirroring the campaign
  one. No `SAVE_VERSION` bump needed.
- **Visual theming**: per-era gameplay background/HUD/grid art,
  Level/Tutorial Select background theming, a Level 100 → Era 2
  transition banner, and a new `Era2ActivationFX` violet/magenta burst.
- **Two real bugs found and fixed via actual rendered/exported
  verification** (see `DECISIONS.md` D77): new piece art initially sat
  under the Android-export-excluded `assets/gameplay/pieces/**` (a
  repeat of D51 — fixed by moving into per-tile-type folders, verified
  against a real exported `.pck`); the QA tutorial-unlock override
  didn't actually bypass real T01-T10 progress requirements (fixed to
  match the campaign flag's unconditional-bypass semantics).
- Validated: full 115-level dev+campaign solver regression unchanged;
  12/12 new fixtures pass; 10/10 new tutorials solve at their
  hand-derived `optimal_moves` and pass the validator with zero errors;
  5 RENDERED screenshots (1080x1920, real GPU) confirmed correct
  rendering. **NOT MANUALLY APPROVED — Android device QA pending.**

## Levels 76-100 Portrait Re-Layout — Phase 2D, FINAL BATCH (2026-09-22)

Geometry-only pass on Campaign Levels 76-100 — **not a difficulty
redesign**. Same technique as Phase 2A/2B/2C, applied to the campaign's
hardest and most tile-dense block (up to 42 tiles, up to 16 rotatable
pieces at the solver ceiling, up to 5 emitters, three-stage relays, a
four-source convergence). **THIS COMPLETES THE PORTRAIT RE-LAYOUT OF
ALL 100 CAMPAIGN LEVELS.** Full rationale in `DECISIONS.md` D76.
Build: **`versionCode=34`, `versionName="2.9.0-PORTRAIT-100-QA"`**,
package `com.beamshift.game`, 54,384,898 bytes (byte-identical to the
previous build — pure level-data edits, no new assets),
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still `true`.

- **Technique: identical order-preserving coordinate remap**, applied
  in three validated sub-batches (76-80, 81-90, 91-100) with a git
  checkpoint after each — solver-confirmed identical `status`/
  `optimal_moves`/`shortest_solution_count`/`states_explored` for all 25
  levels, matched on the first attempt.
- **Levels 85, 91, 95, and 98 deliberately left unchanged** — already
  fully packed on both axes, the same zero-slack situation Level 75
  first established (Phase 2C), now confirmed to recur naturally.
- **New technique this pass: zero-cost row growth computed to its full
  safe ceiling** rather than one row at a time — 15 levels held their
  exact 87px cell while height utilization rose from 82.6% to 99.1%.
  6 levels compacted 10-wide→9-wide for a genuine +10% cell-size gain.
- **Level 100 ("Culmination") — the definitive Era 1 finale — fully
  verified**: all five emitter routes, three relay stages, both
  portals, symmetric convergence, and the fixed-mirror backward-
  reasoning step confirmed identical; went 10x10→10x12 at zero cost.
- **Final read-only portrait audit across all 100 campaign levels**:
  100/100 SOLVABLE, zero levels below 90% height / 85% width
  utilization, cell sizes 87-174px (avg 122.4px), avg width util 98.2%,
  avg height util 95.6%.
- **Extended regression**: real-`GridManager` runtime replay across the
  FULL 115-level dev+campaign population (115/115 PASS).
- **Era terminology recorded** (documentation only): the complete
  100-level campaign plus T01-T10 together constitute Era 1; Era 2
  (Levels 101-200, T11-T20, new mechanics, new visual theme) remains
  documented-only in `ROADMAP.md`, not implemented.
- Levels 1-75 and the Tutorial were not touched.

## Levels 51-75 Portrait Re-Layout — Phase 2C (2026-09-22)

Geometry-only pass on Campaign Levels 51-75 — **not a difficulty
redesign**. Same technique as Phase 2A/2B, applied to the campaign's
most mechanically interconnected block yet (mutual switch/gate pairs,
a two-stage relay, shared-gate perpendicular multi-emitter crossings,
post-target beam continuation). Full rationale in `DECISIONS.md` D75.
Build: **`versionCode=33`, `versionName="2.8.2-PORTRAIT-L51-75-QA"`**,
package `com.beamshift.game`, 54,384,898 bytes (byte-identical to the
previous build — pure level-data edits, no new assets),
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still `true`.

- **Technique: identical order-preserving coordinate remap**, applied
  in three validated sub-batches (51-60, 61-70, 71-75) with a git
  checkpoint after each — solver-confirmed identical `status`/
  `optimal_moves`/`shortest_solution_count`/`states_explored` for all 25
  levels, matched on the first attempt.
- **Level 75 ("Convergence Reaction") deliberately left unchanged** —
  already fully packed on both axes (distinct-column/row counts exactly
  equal its `grid_width`/`grid_height`), zero slack to remap without
  shrinking its cell size.
- **Individually-chosen new shapes**: 6x7 (2 levels), 7x8 (6 levels),
  8x9 (5 levels), 8x10 (1, Level 59 - narrowing width flipped which axis
  is cell-size-binding, producing a LARGER cell than a wider shape
  would), 9x10 (9 levels), 10x11 (1). Average cell size grew 96.7px →
  109.2px (+13.0%); average height utilization grew 81.9% → 93.0%.
- **Zero manual geometry corrections needed** across all 25 levels,
  despite mutual switch/gate dependencies, a two-stage relay, and
  shared-gate multi-emitter crossings.
- **Extended regression**: real-`GridManager` runtime replay across the
  FULL 115-level dev+campaign population (115/115 PASS), same practice
  Phase 2B established.
- **Git checkpoints used as designed**: a checkpoint before touching any
  file, then one commit per validated sub-batch — the practice Phase 2B
  introduced, now exercised across three sequential checkpoints.
- Levels 1-50 and 76-100 and the Tutorial were not touched.

## Levels 26-50 Portrait Re-Layout — Phase 2B (2026-09-22)

Geometry-only pass on Campaign Levels 26-50 — **not a difficulty
redesign**. Same technique as Phase 2A, extended to this block's harder
mechanics (splitters, filters, portals, switch/gate dependency,
hazards/blockers, two-emitter levels). Full rationale in `DECISIONS.md`
D74. Build: **`versionCode=32`, `versionName="2.8.1-PORTRAIT-L26-50-QA"`**,
package `com.beamshift.game`, 54,384,898 bytes (byte-identical to the
previous build — pure level-data edits, no new assets),
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still `true`.

- **Technique: identical order-preserving coordinate remap to Phase 2A.**
  Applied per level via a temporary PowerShell generator (`remap.ps1`),
  which also rewrote every coordinate reference inside each level's
  prose `developer_notes` to match — solver-confirmed identical
  `status`/`optimal_moves`/`shortest_solution_count`/`states_explored`
  for all 25 levels, before and after, matched on the first attempt.
- **Individually-chosen new shapes**: 6x7 (12 levels), 7x8 (9 levels,
  including Level 50 "Paradox" at an unchanged 124px cell — the same
  zero-cost row-growth pattern Phase 2A used for Level 20), 8x9 (Levels
  37/40, the block's most tile-dense), 6x8 (Level 41), 9x10 (Level 45,
  the block's biggest board). Average cell size grew 105.1px → 132.0px
  (+25.6%); average height utilization grew 82.2% → 95.2%.
- **Zero manual geometry corrections needed** across all 25 levels,
  despite this block's heavier mechanic mix — the order-preserving
  proof held unconditionally.
- **Extended regression**: this pass additionally ran a real-
  `GridManager` runtime replay (not just the solver check) across the
  FULL 115-level dev+campaign population (115/115 PASS), as extra
  margin given the harder mechanics in this block.
- **Version control added this pass** — the project had no git
  repository before this; `git init` plus incremental commits after
  each validated batch are now the standing practice going forward.
- Levels 1-25 and 51-100 and the Tutorial were not touched.

## Levels 1-25 Portrait Re-Layout — Phase 2A (2026-09-22)

Geometry-only pass on Campaign Levels 1-25 — **not a difficulty
redesign**. Full rationale in `DECISIONS.md` D73. Build:
**`versionCode=31`, `versionName="2.8.0-PORTRAIT-L1-25-QA"`**, package
`com.beamshift.game`, 54,384,898 bytes (byte-identical to the previous
build — pure level-data edits, no new assets),
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still `true`.

- **Technique: order-preserving coordinate remap.** `LaserSystem` only
  depends on the *sequence* of cell-type hits a beam makes, never the
  distance between them, so a transform mapping every tile sharing an
  old row/column to the same new row/column (and preserving relative
  order per axis) cannot change which cells a beam hits or in what
  order — only the empty space between them changes. A temporary
  generator/validator script confirmed this directly for all 25 levels:
  `LevelSolver.analyze()` on the OLD and NEW tile sets returned
  identical `status`/`optimal_moves`/`shortest_solution_count`/
  `states_explored` for every single one.
- **Individually-chosen new shapes** (not one blanket size): Levels
  1-19 grew from 5x5 to 5x6 (zero cell-size cost) or 5x7 (14% cost, on
  the more elaborate levels); Level 20 grew from 6x6 to 6x7 (zero
  cost); Levels 21-25 (the only ones already rendering below
  `UIConstants.MIN_TOUCH_TARGET`'s 144px) had columns compacted
  alongside row growth, landing at 6x7 or 7x8 with cell sizes 29-33%
  LARGER than before.
- 5 temporary rectangular layout fixtures from Phase 1 (`levels/
  editor_fixtures/fixture_rect_*.gd`) are unaffected/unchanged.
- Validated: 15/15 dev + 100/100 campaign (25 changed + 75 untouched) +
  5/5 rectangular fixtures + 10/10 tutorial-board solvability all PASS;
  layout matrix confirmed 94.2-99.8% height / 86.0-99.8% width
  utilization at the 1080x1920 reference (vs. the old square boards'
  56.8-99.8% height) with zero HUD overlap across 24 combinations
  tested; RENDERED screenshots of Levels 1/10/20/21/25 confirmed larger
  readable tiles, content genuinely spread across the taller board (not
  clustered in one corner), no distortion or clipping. **NOT MANUALLY
  APPROVED — Android visual QA pending.**
- **Campaign Levels 26-100 have NOT been re-laid out.** Re-laying out
  further batches is future work — not started, not authorized by this
  pass's completion.
- **Future product direction documented, not implemented**: an eventual
  "Era" structure (Tutorial + one continuous PLAY mode replacing
  separate Campaign/Endless framing, 100 levels + 10 tutorials per Era,
  current content = Era 1) was recorded in `ROADMAP.md` per explicit
  instruction. No Era 2 content, no Level 101+, no T11+ exists or should
  be started without a separate explicit request.

## Rectangular Grid Architecture — Phase 1 (2026-09-22)

Engine/layout architecture pass. **Zero level content change:** no
Campaign/dev/tutorial level's `grid_width`/`grid_height`/tile
coordinates were touched — `LaserSystem`, `GridTypes`, `LevelData`,
`LevelSolver`, `LevelValidator` are all untouched too. 15/15 dev, 100/100
campaign, 10/10 tutorial solver+runtime-replay regressions identical to
the previous build. Full rationale in `DECISIONS.md` D72. Build:
**`versionCode=30`, `versionName="2.7.0-RECT-GRID-QA"`**, package
`com.beamshift.game`, 54,384,898 bytes (byte-identical to the previous
build — no new assets), `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still
`true`.

- **`GridManager._recalculate_layout()`** now fits an arbitrary
  `grid_width` (columns) x `grid_height` (rows) board against its own
  `Control` rect — already exactly the playable space `game.tscn`'s
  `CenterArea` leaves between the Top HUD and Bottom HUD bars — using
  independent per-axis cell-size candidates
  (`cell_size = floor(min(available_width/columns,
  available_height/rows))`) instead of the old square-only formula
  (`min(size.x,size.y)/max(grid_width,grid_height)`, the one square-grid
  assumption a full codebase audit found). A new single centralized
  `GRID_SAFETY_MARGIN` constant (8px @ 1080-wide reference) insets the
  available rect on all four sides before the fit. A square board's
  result is unchanged by construction — every existing campaign/dev/
  tutorial level renders exactly as before this pass.
- Two new development-only diagnostics on `GridManager`:
  `get_layout_metrics()` (columns/rows/cell_size/grid_px/available/
  width_utilization/height_utilization) and `format_layout_diagnostics()`
  (a formatted print of the same). Never shown to players; for a future
  Phase 2 pass choosing rectangular campaign-level shapes.
- 5 temporary rectangular layout fixtures added under
  `levels/editor_fixtures/` (`fixture_rect_5x8.gd`, `_6x10.gd`, `_7x11.gd`,
  `_8x12.gd`, `_9x10.gd`) — same convention as the 6 existing validator
  fixtures (`level_id=-1`, never in any `LevelManager` path list, never
  Campaign-reachable, export-excluded).
- Validated: 15/15 dev + 100/100 campaign + 10/10 tutorial solver-vs-
  runtime-replay regression unchanged; 5/5 rectangular fixtures PASS; a
  resolution/layout matrix (720x1280, 1080x1920, 1080x2160, 1080x2400,
  1080x2560 x 8 boards, 40 combinations) confirmed zero HUD overlap and
  rectangular fixtures reaching 85-100% width / 89-99.8% height
  utilization vs. existing square levels' width-bound-only behavior;
  RENDERED screenshots (small 5x5, medium 7x7, large 10x10, tall
  rectangular 7x11) visually confirmed correct alignment, no distortion,
  no clipping. **NOT MANUALLY APPROVED — Android visual QA pending.**
- **Campaign Levels 1-100 have NOT been re-laid out.** Choosing real
  rectangular `grid_width`/`grid_height` shapes for campaign content is
  Phase 2 — not started, not authorized by this pass's completion.

## UI Background Refresh V2 + Laser → Mirror Impact VFX (2026-09-21)

Visual-only pass on top of the completed 100-level campaign build.
**Zero gameplay change:** `LaserSystem`, `GridTypes`, level data, solver,
validator and every campaign/tutorial level are untouched — 100/100
campaign solver + runtime, 15/15 dev, and 10/10 tutorial regressions are
identical to the previous build. Full rationale in `DECISIONS.md` D71.
Build: **`versionCode=29`, `versionName="2.6.0-UI-VFX-QA"`**, package
`com.beamshift.game`, `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still
`true`.

- **Part A — three V2 menu backgrounds** (941×1672 portrait art, ~9:16)
  replace the previous busy artwork, one per screen (each used by that
  screen only):
  `res://assets/ui/backgrounds/bs_bg_main_menu_v2.png` → Main Menu,
  `res://assets/ui/backgrounds/bs_bg_campaign_select_v2.png` → Campaign
  Level Select, `res://assets/ui/backgrounds/bs_bg_tutorial_select_v2.png`
  → Tutorial Level Select. The three scenes' existing full-rect
  `Background` `TextureRect` (`expand_mode=IGNORE_SIZE`,
  `stretch_mode=KEEP_ASPECT_COVERED`) already did fill-and-center-crop
  with no distortion, so only the texture reference changed — no global
  stretch/aspect setting touched. Level Select and Tutorial Select
  previously *shared* one image; they now each have their own.
- **Readability scrim:** a new `ReadabilityScrim` `TextureRect`
  (`mouse_filter=IGNORE`, `GradientTexture2D` sub-resource, dark
  blue-black `Color(0.015, 0.03, 0.08)`) sits between `Background` and
  the UI in each scene. Main Menu: vertical gradient, alpha 0 above 42%
  of screen height rising to 0.26 at 62% and 0.30 at the bottom (behind
  the button stack only). Campaign/Tutorial Select: horizontal gradient,
  alpha 0 at both edges rising to 0.24 by 12% and 88% (calms the planet
  glow behind the tile grid/title while leaving the framing hull art
  untouched). All ≤ 0.30, below the brief's 0.40 ceiling.
- The two superseded backgrounds (`assets/backgrounds/main_menu/
  bs_bg_main_menu.png`, `assets/backgrounds/level_select/
  bs_bg_level_select.png`) remain on disk but nothing references them;
  they were added to `export_presets.cfg`'s `exclude_filter` so they
  don't ship in the APK (`export_filter="all_resources"`).
- **Part B — `LaserMirrorImpactFX`** (`scripts/gameplay/
  laser_mirror_impact_fx.gd` + `scenes/gameplay/laser_mirror_impact_fx.tscn`):
  a ~0.32 s procedural burst — contact flash, expanding ring, 5 sparks
  spraying along the reflected direction — drawn in one additive-blend
  `_draw()` with one Tween, self-freeing. No particle nodes, no
  textures, no lights. `GridManager._spawn_mirror_impacts()` reads the
  ALREADY-computed `_last_result` (no second simulation) and spawns one
  per reflection off a `MirrorTile` (rotatable or fixed; splitters
  excluded), colored from the real `GridTypes.beam_color_to_render_color`
  mapping. Fires on player-initiated re-evaluations (a tap) only — not on
  load/Reset/resize.
- `GridManager` additions: `ImpactFX` container (`mouse_filter=IGNORE`),
  `_simulate_and_draw(play_impacts := false)`, `_spawn_mirror_impacts()`,
  `_clear_impact_fx()`, constants `IMPACT_FX_MIN_CELL_SIZE`/
  `IMPACT_FX_MAX_COUNT`. No existing gameplay line changed.
- **Validation:** AUTOMATED 15/15 dev, 100/100 campaign solver + runtime
  replay, 10/10 tutorial; 5,291 bursts across every replayed solver tap
  checked, 0 not on a MIRROR tile. RENDERED (real GPU) screenshots of all
  three menus at 9:16 and a taller ~20:9 aspect, gameplay burst timeline,
  four beam colors, and Tutorial T01. Real synthetic clicks (D45) toggled
  a mirror twice while three bursts were alive on top of it. 60 rapid
  taps: peak 3 FX nodes, 0 after settle, scene node count 120 → 120.
  **MANUAL Android visual QA of this build is pending.**
- APK: 54,384,898 bytes (≈51.9 MiB; previous build 51,299,930), signed
  with the local debug keystore, confirmed via `aapt2 dump badging`.

## Campaign Levels 91-100 — final campaign block, 100-level campaign complete (2026-09-21)

**The campaign now has 100 levels — the full, originally-planned
structure is complete.** Levels 91-100 (`levels/campaign/stage_10/`)
continue directly from Level 90's difficulty — **no mechanic-teaching
reset**, MASTER+/EXTREME/FINAL CHALLENGE tier, framed as a "final exam"
for BeamShift's complete gameplay language. Full technical detail in
`DECISIONS.md` D70; design table in `CAMPAIGN_DESIGN.md` section 11m.
**Levels 1-50 remain the user-tested, manually-positive baseline;
Levels 51-100 remain automated-validated only.**

- Created Levels 91-100: Inferred Convergence, Delayed Verdict,
  Pre-Split Signal, Traced Colors, Final Threshold, Chain of Custody,
  Triple Verdict, Triple Inference, Penultimate Verdict, Culmination.
- **Two new techniques:** a genuinely non-rotatable fixed mirror used
  specifically for backward-reasoning teaching (Levels 91/95/98/100),
  and a shared-state chain where a target's own activation is
  explicitly just a waypoint toward a later emitter's conditions
  (Level 96), directly matching the brief's own example.
- **New optimal-move curve:** 13, 13, 11, 11, 15, 12, 14, 14, 14, 13.
  Level 95 ("Final Threshold") is the "final exam" checkpoint. Level
  100 ("Culmination") is the definitive final puzzle — Level 90's own
  three-stage relay + double-portal + symmetric convergence, plus one
  fixed mirror for genuine backward reasoning, deliberately held to
  Level 90's exact move count (13) and grid size (10x10) rather than
  padded, since the brief explicitly asked for elegance over size.
- **One full draft rejection, and a significant one:** Level 100's
  first draft additionally gated emitter 4 behind emitter 1's own
  post-target continuation, creating a genuine circular deadlock
  (emitter 1 needs emitter 3, which needs emitter 2, which needs
  emitter 4, which would have needed emitter 1's own completion) —
  exactly the failure mode `DECISIONS.md` D69 documented one milestone
  earlier as a lesson for future sessions, and the very next level
  almost repeated it anyway. Caught immediately by the solver reporting
  `UNSOLVABLE`, removed rather than reworked, re-validated to a clean
  13-move unique solution.
- **Campaign completion behavior verified, not built from scratch:**
  `game.gd`'s existing `has_next = current_level_id <
  LevelManager.get_campaign_level_count()` check and
  `LevelCompletePopup.show_result()`'s existing `_next_button.visible =
  has_next_level` line both already correctly handle Level 100 as the
  last level, with zero code changes needed. No dedicated "Campaign
  Complete" celebration screen exists or was built — deferred to a
  future milestone only if the user asks for one.
- **Zero architecture changes needed** — `LevelManager.
  CAMPAIGN_LEVEL_PATHS` gained 10 more entries;
  `get_campaign_level_count()` picked up 100 automatically. Verified
  with a real-autoload driver (temporary `run/main_scene` swap,
  reverted immediately): count is 100, Level 100 loads correctly,
  Level 101 returns `null` gracefully, QA-unlock correctly allows 100
  and blocks 101, real save data confirmed untouched.
- **Validated:** 10/10 new-level solver PASS, 10/10 new-level
  runtime-replay PASS, 100/100 full campaign solver PASS, 100/100
  campaign runtime-replay PASS, 15/15 dev-level PASS, 10/10
  tutorial-board solvability PASS. Levels 1-90 and Tutorial untouched.
- New build: `versionCode=28`, `versionName="2.5.0-CAMPAIGN-100-QA"`. QA
  unlock-all (D58) kept enabled — **and MUST be set to `false` before
  any final production release build**, now more urgent than ever
  since campaign content itself is complete. **NOT MANUALLY APPROVED —
  ANDROID MANUAL DIFFICULTY QA PENDING** for Levels 91-100; full manual
  QA of Levels 51-90 also remains separately pending. **The 100-level
  campaign structure originally planned in `ROADMAP.md` is now complete
  — Campaign Levels 101+ or a Stage 11 would be new scope, not a
  continuation, and need an explicit request.**

## Campaign Levels 81-90 — EXTREME/EXTREME+ block, fourth expansion past 80 (2026-09-21)

**The campaign now has 90 levels.** Levels 81-90 (`levels/campaign/
stage_09/`) continue directly from Level 80's difficulty — **no
mechanic-teaching reset**, EXTREME/EXTREME+ tier. Full technical detail
in `DECISIONS.md` D69; design table in `CAMPAIGN_DESIGN.md` section
11l. **Levels 1-50 remain the user-tested, manually-positive baseline;
Levels 51-90 remain automated-validated only.**

- Created Levels 81-90: Third Signal, Crossed Corridors, Silent Detour,
  Distant Relay, Convergence Threshold, Reciprocal Corridor, Triple
  Relay, Distant Triple Relay, Fourfold Relay, Full Circuit.
- **New mechanic: the three-stage relay** (Level 87 onward) — extends
  the two-stage switch/gate relay (Levels 70/76/84) to THREE emitters in
  a genuine forward chain (emitter 1 opens emitter 2's gate; emitter 2
  opens emitter 3's gate; emitter 3 opens emitter 1's final gate),
  resolved over 4 `simulate_until_stable()` passes with zero new engine
  code.
- **New optimal-move curve:** 12, 11, 11, 12, 14, 12, 10, 12, 13, 13.
  Level 85 ("Convergence Threshold") is a major checkpoint. Level 90
  ("Full Circuit") is a major milestone — five emitters, the three-stage
  relay, two portal jumps, and two independent converging gates placed
  symmetrically on both ends of the relay, exceeding Level 80's
  convergence depth through breadth of independent sources rather than
  by stacking more gates onto one target.
- **One full draft rejection:** Level 87's first draft placed two
  emitters' mirror chains in the same column at different rows,
  reasoning that different rows would keep them separate — when both
  mirrors were left at their unflipped default orientation, one beam
  bent directly into the other's downstream chain, reaching both
  targets in 5 moves without the three-stage relay ever resolving.
  Rebuilt with every emitter's ENTIRE path (not just its target)
  confirmed disjoint from every other emitter's entire path, including
  a check of each mirror's unflipped default behavior — a new standing
  lesson for future multi-emitter levels.
- **One mid-design correction caught by the solver itself:** Level 89's
  first version placed target A one row off from where the beam
  actually arrives after two new forced bends — the solver correctly
  reported `UNSOLVABLE`, diagnosed with a temporary debug script, and
  fixed by moving the target to the row the beam actually occupies.
- **Circular-dependency safety analysis:** every new converging gate
  added in this pass was checked to confirm it depends only on a switch
  reachable *before* anything that gate itself blocks becomes
  necessary. A tempting but rejected alternative (gating a third emitter
  behind a first emitter's own completion, when that emitter's own
  switch was needed earlier in the same chain) would have created a
  genuine unsolvable deadlock — caught during design, before writing
  any level file.
- **Zero architecture changes needed** — `LevelManager.
  CAMPAIGN_LEVEL_PATHS` gained 10 more entries;
  `get_campaign_level_count()` picked up 90 automatically. Verified
  with a real-autoload driver (temporary `run/main_scene` swap,
  reverted immediately): count is 90, Level 90 loads correctly, Level
  91 returns `null` gracefully, QA-unlock correctly allows 90 and
  blocks 91, real save data confirmed untouched.
- **Validated:** 10/10 new-level solver PASS, 10/10 new-level
  runtime-replay PASS, 90/90 full campaign solver PASS, 90/90 campaign
  runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
  solvability PASS. Levels 1-80 and Tutorial untouched.
- New build: `versionCode=27`, `versionName="2.4.0-CAMPAIGN-90-QA"`. QA
  unlock-all (D58) kept enabled. **NOT MANUALLY APPROVED — ANDROID
  MANUAL DIFFICULTY QA PENDING** for Levels 81-90; full manual QA of
  Levels 51-80 also remains separately pending.

## Campaign Levels 71-80 — MASTER/MASTER+/EXTREME block, third expansion past 70 (2026-09-21)

**The campaign now has 80 levels.** Levels 71-80 (`levels/campaign/
stage_08/`) continue directly from Level 70's difficulty — **no
mechanic-teaching reset**, MASTER/MASTER+/EXTREME tier. Full technical
detail in `DECISIONS.md` D68; design table in `CAMPAIGN_DESIGN.md`
section 11k. **Levels 1-50 are now user-tested on a real device and
reported good** — a manually-positive baseline; Levels 51-80 remain
automated-validated only.

- Created Levels 71-80: Deliberate Detour, Locked Corridor, Locked
  Splitter, Twin Portals, Convergence Reaction, Reverse Relay, Distant
  Splitter, Distant Corridor, Silent Third, Full Convergence.
- **New technique proven this pass:** extend an already-validated
  level's exact tile geometry (portal jump into a confirmed-unused
  board region, or filters at confirmed single-beam transit cells)
  rather than hand-deriving fresh geometry from scratch — used for
  Levels 76-80, each re-validated against its base level's own numbers
  before any new mechanic was layered on top.
- **New optimal-move curve:** 11, 9, 11, 8, 13, 11, 12, 12, 13, 14.
  Level 75 ("Convergence Reaction") is a major mid-block checkpoint.
  Level 80 ("Full Convergence") is a major milestone — one target gated
  by FOUR independently-opened dependencies (mutual splitter gate pair,
  portal jump, third emitter's own gate, reflected branch's own
  post-target delayed consequence), with the "independent" third
  emitter itself re-coupled into the straight branch's own switch —
  exceeding Level 70's two-stage relay in convergence depth, not merely
  in size (10x10, only 3 moves more than Level 70).
- **One full draft rejection:** Level 72's first draft was hand-derived
  from scratch (two emitters through a shared gate cell with filters)
  and came back UNSOLVABLE — a transcription error mixed up several
  intended mirror positions. Rebuilt by copying Level 68's already-
  validated geometry verbatim and adding 3 filters only at confirmed
  single-beam transit cells, matching Level 68's own numbers exactly
  (9 moves, 2036 states, decoy (8,8)).
- **One mid-design correction caught by the solver itself:** Level 79's
  entry mirror was authored assuming the wrong orientation was a "trap,"
  but `GridTypes.reflect()`'s table showed it was already correct — the
  solver immediately flagged the mismatch (returning Level 77's own
  baseline move count instead of the intended higher one). Corrected to
  the genuinely-wrong orientation and re-validated to 13 moves.
- **Solver ceiling watched, not exceeded:** Level 80 has 16 rotatable
  pieces (2^16 = 65536 states, exactly `LevelSolver.DEFAULT_MAX_STATES`)
  — explored 65519 states and returned a definitive SOLVABLE, not
  UNKNOWN. No further rotatable pieces should be added to Level 80.
- **Zero architecture changes needed** — `LevelManager.
  CAMPAIGN_LEVEL_PATHS` gained 10 more entries;
  `get_campaign_level_count()` picked up 80 automatically. Verified
  with a real-autoload driver (temporary `run/main_scene` swap,
  reverted immediately): count is 80, Level 80 loads correctly, Level
  81 returns `null` gracefully, QA-unlock correctly allows 80 and
  blocks 81, real save data confirmed untouched.
- **Validated:** 10/10 new-level solver PASS, 10/10 new-level
  runtime-replay PASS, 80/80 full campaign solver PASS, 80/80 campaign
  runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
  solvability PASS. Levels 1-70 and Tutorial untouched.
- New build: `versionCode=26`, `versionName="2.3.0-CAMPAIGN-80-QA"`. QA
  unlock-all (D58) kept enabled. **NOT MANUALLY APPROVED — ANDROID
  MANUAL DIFFICULTY QA PENDING** for Levels 71-80; full manual QA of
  Levels 51-70 also remains separately pending.

## Campaign Levels 61-70 — advanced expert block, second expansion past 60 (2026-09-21)

**The campaign now has 70 levels.** Levels 61-70 (`levels/campaign/
stage_07/`) continue directly from Level 60's difficulty — **no
mechanic-teaching reset**, "advanced expert" tier. Full technical
detail in `DECISIONS.md` D67; design table in `CAMPAIGN_DESIGN.md`
section 11j.

- Created Levels 61-70: Peripheral, Longcut, Invalidation, Twin
  Anchor, Convergence Point, Portal Trap, Chain Reaction, Twin
  Corridor, Color Conflict, Grand Convergence.
- **Two new structural patterns proven safe for the first time:** a
  single physical gate cell crossed by two emitters from perpendicular
  directions, with EITHER emitter's switch opening it for both (Level
  68); and a genuine two-stage switch/gate relay between two emitters,
  where emitter 1 unlocks emitter 2's early path and only THEN can
  emitter 2 unlock emitter 1's later path (Level 70) — hand-verified
  against `simulate_until_stable()`'s real pass-by-pass resolution (3
  passes) before trusting the solver.
- **New optimal-move curve:** 10, 10, 10, 10, 12, 7, 11, 9, 12, 11.
  Level 70 ("Grand Convergence") is a second major milestone — more
  sophisticated than Level 60 through its relay dependency, not merely
  larger (4095 states, below Level 60's own 32767, deliberately not
  chasing state count).
- **One full draft rejection:** Level 63's first draft used an always-
  open decoy gate positioned where the reflected branch's own correct
  path also passed through it, and a "decoy" mirror that connected the
  reflected branch's chain straight into the straight branch's target
  — the solver found a 5-move shortcut bypassing the portal, gate, and
  switch entirely. Rebuilt with fully disjoint branch zones.
- **One notes correction, not a design flaw:** Level 68's hand-trace
  mis-applied the reflect table to one mirror, assuming a flip was
  needed that the solver correctly showed was unnecessary (already
  correctly authored) — `optimal_moves` corrected from 10 to the
  solver-confirmed 9.
- **Zero architecture changes needed** — `LevelManager.
  CAMPAIGN_LEVEL_PATHS` gained 10 more entries;
  `get_campaign_level_count()` picked up 70 automatically. Verified
  with a real-autoload driver: count is 70, Level 70 loads correctly,
  Level 71 returns `null` gracefully, QA-unlock correctly allows 70 and
  blocks 71, real save data confirmed untouched.
- Validated: 10/10 new-level solver PASS, 10/10 new-level runtime-
  replay PASS, 70/70 full campaign solver PASS, 70/70 runtime-replay
  PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
- **Levels 1-60 and Tutorial untouched.**
- New build: `versionCode=25`, `versionName="2.2.0-CAMPAIGN-70-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 61-70. Full manual QA of Levels
  21-60 also remains separately pending — only informal partial
  feedback ("its good") exists so far.

## Campaign Levels 51-60 — first post-reboot expansion past 50 (2026-09-21)

**The campaign now has 60 levels.** Levels 51-60 (`levels/campaign/
stage_06/`) continue directly from the Levels 46-50 difficulty region —
**no mechanic-teaching reset**, freely combining everything Tutorial
already teaches. Full technical detail in `DECISIONS.md` D66; design
table in `CAMPAIGN_DESIGN.md` section 11i.

- Created Levels 51-60: Interlock, Currents, Shared Line, Dual Transit,
  Sequence Lock, Shared Transit, Long Division, Delayed Fault, Near
  Convergence, Threshold of Reason.
- **New dependency patterns not used in Difficulty Rework Pass 2:** a
  genuinely mutual switch/gate dependency (Level 51 — each branch's own
  switch opens the OTHER branch's gate), a filter shared by two
  independent emitters from perpendicular directions (Level 53), and a
  global switch/gate gating an entire independent filter-order
  sub-puzzle (Levels 55, 60).
- **New optimal-move curve:** 10, 8, 7, 11, 11, 8, 9, 11, 11, 14. Level
  60 ("Threshold of Reason") explores 32767 states — the highest in the
  campaign, exceeding old Level 50 (255) and Pass 2's own Levels 40/45
  peak (4095 each).
- **Two full draft rejections, not zero** (see `DECISIONS.md` D66 for
  the full accounting): Level 56's first draft shared ONE portal pair
  between two independent emitters, creating a combinatorially
  pathological search space (solver validation took minutes instead of
  milliseconds on a 7-piece level) — killed and rebuilt with two
  separate portals tied together by a switch/gate. Level 58's first
  draft left a wrong branch with no immediate consequence at all, and
  two adjacent cells assigned to different branches accidentally
  connected into a 4-move shortcut — rebuilt with disjoint zones and a
  real (if delayed) hazard.
- **Zero architecture changes needed** — `LevelManager.
  CAMPAIGN_LEVEL_PATHS` gained 10 more entries;
  `get_campaign_level_count()` picked up 60 automatically. Verified
  with a real-autoload driver: count is 60, Level 60 loads correctly,
  Level 61 returns `null` gracefully, QA-unlock correctly allows 60 and
  blocks 61, real save data confirmed untouched.
- Validated: 10/10 new-level solver PASS, 10/10 new-level runtime-
  replay PASS, 60/60 full campaign solver PASS, 60/60 runtime-replay
  PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
- **Levels 1-50 and Tutorial untouched.**
- New build: `versionCode=24`, `versionName="2.1.0-CAMPAIGN-60-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 51-60. Full manual QA of Levels
  21-50 (Difficulty Rework Pass 2) also remains separately pending —
  only informal partial feedback ("its good") exists so far.

## Campaign Difficulty Rework Pass 2 — Levels 21-45 replaced again (2026-09-21)

**The Main Campaign Reboot below (`versionCode=22`) was solver-valid
but still too easy in Levels 21-45** — optimal-move curves of 3,2,2,2,2
(21-25), 2,2,2,2,5 (31-35), and 2,4,2,2,3 (41-45) fell far short of
their "Hard+/Very Hard/Expert" labels. Full technical detail in
`DECISIONS.md` D65; new design tables in `CAMPAIGN_DESIGN.md` sections
11f/11g/11h.

- **Replaced all 25 of Levels 21-45 a second time**, built around real
  dependency depth instead of padded move counts: cross-branch shared
  mirrors (one fixed mirror hit by two beams from perpendicular
  directions), filter order (the same filters touched in opposite
  order by two branches), portal misdirection (never a shortcut),
  switch/gate dependency, multi-emitter dependency (Levels 32, 36, 44),
  backward reasoning through fixed mirrors, and hazard/blocker-guarded
  false forks that genuinely punish a wrong choice.
- **New optimal-move curve:** 5,6,5,6,6 (21-25) / 7,8,6,7,7 (26-30) /
  6,7,6,5,7 (31-35) / 9,9,6,9,11 (36-40) / 8,9,10,7,11 (41-45).
  `states_explored` now peaks at 4095 (Levels 40 and 45), exceeding old
  Level 50's 255-state benchmark — Level 50 remains the reference for
  puzzle *style*, not a numeric ceiling.
- **Every level built from one of two solver-verified-safe templates**
  (a single non-branching linear chain, or a splitter with two branches
  on fully disjoint rows/columns except at one shared fixed mirror)
  after six early drafts (Levels 25, 27, 31 x2, 34, 36 x2, 40) hit the
  same class of bug: a target/hazard/emitter accidentally collinear
  with an unrelated beam's straight path, producing an unintended
  shortcut or `UNSOLVABLE` result — each caught by the solver, not by
  hand-tracing, and fixed. See `DECISIONS.md` D65 for the full
  accounting and the general lesson for future level design.
- **Levels 1-20 and 46-50 untouched.** Tutorial (T01-T10) completely
  separate and unchanged.
- Validated: **50/50 campaign solver PASS, 50/50 runtime-replay PASS,
  15/15 dev PASS, 10/10 tutorial-board PASS.**
- New build: `versionCode=23`, `versionName="2.0.1-CAMPAIGN-DIFFICULTY-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for all 25 redesigned levels.

## Main Campaign Reboot — Levels 1-50 rebuilt mechanic-agnostic (2026-09-20)

**With the Guided Tutorial (T01-T10) now teaching every mechanic in
isolation, Campaign Levels 1-50 no longer needed to teach a mechanic
per stage — rebuilt around a permanent new rule: the Campaign is
mechanic-agnostic from Level 1 onward, testing combinations and
reasoning instead.** Full technical detail in `DECISIONS.md` D64;
architecture/design tables in `CAMPAIGN_DESIGN.md` sections 1a, 2,
11f/11g/11h.

**Audit of the existing 50** (states/moves from `CAMPAIGN_DESIGN.md`'s
own tables, cross-referenced against manual-approval status):
- **Levels 1-10 and 11-20: KEPT, unchanged.** Both carry real prior
  manual approval ("the starting levels are good"/"these are looking
  good").
- **Levels 21-30, 31-40, 41-45: REPLACED entirely.** Never manually
  approved; Levels 31-40 had explicit **"feels easy"** feedback; all
  three ranges were front-loaded "teach the mechanic" introductions no
  longer appropriate now that Tutorial covers that.
- **Levels 46-50: KEPT, unchanged — including Level 50 "Paradox,"** the
  user's own explicitly-named quality benchmark (255 states explored).
  Already combination-focused and escalating; no strengthening needed.

**25 levels (21-45) hand-designed and solver-validated in 5 batches of
5**, freely combining any mechanic (portals/filters/switches-gates/
hazards/multiple emitters no longer reserved for later stages). New
design patterns: splitter puzzles where *neither* branch is free
(breaking the earlier-taught assumption); portal misdirection requiring
real entry/exit/direction tracking; backward reasoning through fixed-
mirror chains, including two independent chains in one level;
switch/gate dependency where an unconditional branch is what lets a
separate branch's gate open; hazard-guarded branches where a locally-
correct target hit is globally worthless; cross-branch dependency via a
shared mirror approached from disjoint paths, including via two
independent emitters; filter-order "false-confirmation" traps.

**24 of 25 levels matched hand-traced intent exactly on the first
solver pass.** One real bug caught by the solver, not hand-tracing:
Level 30 ("Deadlock") required a target as RED, but its own straight
branch passes through an unavoidable GREEN filter first - the solver
correctly returned `UNSOLVABLE`; fixed by matching the target's color
to what the beam actually carries.

**Internal structure preserved** — `levels/campaign/stage_01/` …
`stage_05/` folder layout and `LevelManager.CAMPAIGN_LEVEL_PATHS`
ordering untouched; only specific files' contents were rewritten. The
player only ever sees "Level 1"–"Level 50," never stage names.

**Validated:** 50/50 campaign solver PASS, 50/50 runtime-replay PASS,
15/15 dev PASS, 10/10 tutorial-board PASS (Tutorial untouched, per the
brief's explicit freeze).

New build: `versionCode=22`, `versionName="2.0.0-CAMPAIGN-REBOOT-QA"`,
51,130,936 bytes. QA unlock-all kept enabled. **NOT MANUALLY
APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING** for all 50 levels.

## Guided Tutorial Click Input Fix — highlighted tile visible but not tappable (2026-09-20)

**Manual video QA of `versionCode=20` found the highlighted mirror at
T01's "Tap the highlighted mirror to rotate it." step was clearly
visible but repeated taps did nothing** - the tutorial never advanced.
Full technical detail in `DECISIONS.md` D63.

**Root cause, found by dumping runtime `mouse_filter`/`get_global_rect()`
values (not `.tscn` source) for every Control between the Viewport and
the highlighted tile**: `game.tscn`'s `TutorialPanel` instance node
redundantly re-declared full-screen anchors (`anchors_preset = 15`) on
top of `tutorial_panel.tscn`'s own correct bottom-anchored layout,
making its `Panel` child (default `mouse_filter = STOP`) silently cover
the **entire screen** instead of the intended ~220px bottom band. Since
the panel's background is only 88% opaque and the game's art is already
dark, this blended in visually - the mirror stayed visible - but
`Panel`'s `STOP` filter intercepted every tap anywhere on the board
before it could reach any tile.

**Fixes:**
- Removed the conflicting anchor override from `game.tscn`'s
  `TutorialPanel` instance node, restoring its correct bottom-band
  layout.
- Hardened `tutorial_panel.tscn`'s `Panel` to `mouse_filter = IGNORE` -
  only its `ContinueButton` can consume a tap now.
- Added a fail-safe: `TutorialManager` now `push_error`s if a
  `REQUIRE_TILE_TAP` step's highlighted cell and allowed cell ever
  diverge.
- Expanded the QA debug overlay with live `HIGHLIGHT:`/`ALLOWED:`/
  `LAST TAP:` tracking, via a new `GridManager.tile_tap_attempted`
  signal that fires for every tap attempt, accepted or rejected.

**Validated:** a runtime ancestor-chain dump confirmed the intercepting
node before the fix and its absence after; genuine OS-level mouse input
observed during the investigation (not synthetically generated) reached
the correct tile and was accepted; a headless driver confirmed every
`REQUIRE_TILE_TAP` step across all 10 tutorials correctly rejects a
wrong-cell tap and accepts/advances on the correct one via the real
signal chain - 10/10 PASS; full existing regression re-confirmed (15/15
dev + 50/50 campaign) - zero Campaign regression.

New build: `versionCode=21`, `versionName="1.6.3-TUTORIAL-INPUT-FIX"`,
51,135,032 bytes. QA unlock-all kept enabled. Campaign untouched.
**STILL NOT MANUALLY APPROVED — ANDROID MANUAL QA PENDING** for all
three tutorial fixes (runtime, visual, input) together.

## Guided Tutorial Visual Focus Fix — dim overlay + highlight visibility + completion cleanup (2026-09-20)

**Manual video QA of `versionCode=19` found two visual bugs**: the
board stayed heavily dimmed during `REQUIRE_TILE_TAP` with the required
mirror hard to see under it, and the dimming wasn't reliably clearing.
Full technical detail in `DECISIONS.md` D62; architecture reference in
`TUTORIAL_SYSTEM.md` section 12.

**Investigation found no dim overlay had ever existed in the Tutorial
system** (checked directly against source, per this project's standing
rule) — the real, verifiable problem was `TutorialHighlight`'s thin
outline having too little contrast against full-color gameplay art. The
fix implements the commissioning brief's own detailed dim/spotlight
specification anyway, since it's what genuinely resolves the complaint.

**Fixes:**
- New `TutorialDimOverlay`: a board dim (`DIM_ALPHA = 0.52`) with a
  fully transparent cutout around the highlighted tile, so that tile
  stays at full brightness rather than "less dark." Coupled 1:1 to
  `GridManager.set_highlight()`/`clear_highlight()` — no new state
  machine, no step-type branching needed.
- `TutorialHighlight` strengthened (brighter cyan-white, thicker
  border, higher min alpha) and enlarged by a shared `FOCUS_PADDING`
  constant so the ring and the dim's cutout can never drift apart.
- Pause double-dimming fixed: `suspend_tutorial_focus()`/
  `resume_tutorial_focus()` hide/restore the tutorial dim around
  Pause's own independent dim.
- An adjacent z-order bug found and fixed: `PauseMenu` was an earlier
  sibling than `TutorialPanel` in `game.tscn`, so the tutorial
  instruction panel rendered on top of Pause when opened mid-tutorial —
  reordered so `PauseMenu` is always last (topmost).
- `game.gd._clear_tutorial_focus_visuals()` added as the one
  authoritative highlight/dim cleanup path, called at every tutorial
  exit point.

**Validated:** a headless driver walked every step of all 10 tutorials
(every tile type any tutorial highlights) confirming highlight/dim stay
exactly in sync and both clear after the last step — 10/10 PASS; real
rendered screenshots with pixel-luminance sampling objectively confirmed
the highlighted tile reads ~2.5-3x brighter than its dimmed neighbors;
full existing regression re-confirmed (15/15 dev + 50/50 campaign) —
zero Campaign regression.

New build: `versionCode=20`, `versionName="1.6.2-TUTORIAL-VISUAL-FIX"`,
51,130,936 bytes. QA unlock-all kept enabled. Campaign untouched.
**STILL NOT MANUALLY APPROVED — ANDROID MANUAL QA PENDING** for the D61
runtime fix and this visual fix together.

## Guided Tutorial Runtime Fix — T01 initial-load/instruction/forced-interaction bug (2026-09-20)

**Guided Tutorial Mode v1 (`versionCode=18`) FAILED real Android manual
QA**: T01 opened with an empty board (no tiles), Reset made tiles
appear but the tutorial stayed softlocked — no instruction/message, no
highlight, no mirror interaction. Full technical detail in
`DECISIONS.md` D61; pitfall writeup in `TUTORIAL_SYSTEM.md` section 11.

**Root cause** (found via a real, non-headless render, `CLAUDE.md`
12d, not the initially-suspected `Control`-layout timing race):
`scenes/ui/tutorial_panel.tscn` and
`scenes/ui/tutorial_complete_popup.tscn` each declared their script as
an `ext_resource` but never attached it to their root node
(`script = ExtResource(...)` was missing). `%TutorialPanel` therefore
resolved to a plain `Control` lacking the `continue_pressed` signal
`game.gd._ready()` unconditionally tries to connect in tutorial mode —
crashing `_ready()` before its final line, `_load_current_level()`,
ever ran. Reset "fixed" tile visibility only because the Reset button's
`pressed` connection is wired earlier in `_ready()`, before the crash.

**Fixes:**
- Both `.tscn` files now correctly attach their scripts.
- Fail-safe added: `GridManager.has_orientable_tile()` +
  `TutorialManager`'s `REQUIRE_TILE_TAP` handling now refuse to lock
  input to a nonexistent tile, logging a `push_error` and leaving input
  unrestricted instead of softlocking silently.
- Temporary, tutorial-mode-only QA debug overlay added (`QADebugLabel`)
  showing the live step number/input mode/target cell.
- No `level_visuals_ready` signal was needed — `grid.size`/`cell_size`
  were already correct from the first frame once the real bug was
  fixed, so there was no separate timing race.

**Validated:** real rendered reproduction of the crash and its fix
(screenshot of T01's first frame showing tiles/beam/instruction/
continue-button, no Reset needed); all 10 tutorials (T01-T10)
re-validated for startup through the real `game.tscn` path; T01
Reset x3/Pause-Resume/Pause-Restart lifecycle all correct with no
duplicated UI/highlights; full existing regression re-confirmed
(15/15 dev + 50/50 campaign, 65/65 total, plus 10/10 tutorial-board
solvability) — zero Campaign regression.

New build: `versionCode=19`, `versionName="1.6.1-TUTORIAL-FIX"`,
51,130,755 bytes. QA unlock-all kept enabled. Campaign untouched.
**STILL NOT MANUALLY APPROVED — ANDROID MANUAL RE-QA PENDING.**

## Guided Tutorial Mode — T01-T10 + Full Menu Integration (2026-09-20)

Built from an explicit, detailed user request for a new, permanent
product structure: a 10-level guided TUTORIAL section, completely
separate from the 100-level CAMPAIGN (currently 1-50 implemented). On
top of "Production Campaign Phase 5" (`versionCode=17`, 51.08 MB). Full
technical detail in `DECISIONS.md` D60; architecture reference in the
new `TUTORIAL_SYSTEM.md`.

**Mechanic availability audited from source before designing anything**
— every mechanic the brief's T01-T10 plan named (mirrors, blockers,
fixed mirrors, multiple targets, splitters, colored beams/targets,
filters, portals, switches, gates, hazards, multiple emitters) was
confirmed already fully implemented. Portals/switches-gates/hazards/
multiple-emitters had simply never been *used* in Campaign yet (reserved
for future Stages 6/7/9/8) but were already proven by dev/regression
levels 10-13 ("Through the Portal," "Switch and Gate," "Danger Zone,"
"Two Sources"). **No tutorial was left pending, no mechanic was faked.**

**New architecture** (all summarized in `TUTORIAL_SYSTEM.md`):
- `TutorialStepData`/`TutorialLevelData` — a tutorial's `tiles` are
  simulated by the identical `LaserSystem`/`GridManager` Campaign uses;
  `steps` (an ordered array of 4 step types: `MESSAGE`,
  `REQUIRE_TILE_TAP`, `WAIT_FOR_TARGET_ACTIVATION`,
  `WAIT_FOR_PUZZLE_SOLVED`) is the only addition.
- `TutorialManager` — the step machine, deliberately a
  `class_name extends RefCounted` rather than a 4th autoload
  (`CLAUDE.md` rule 6: nothing here needs to survive a scene change).
  `game.gd` owns one instance per play session.
- Forced interaction is gated at the single existing tap handler,
  `GridManager._on_orientable_tile_clicked()`, via two new fields
  (`interaction_locked`, `interaction_restricted_to`) that default to
  their inert values — Campaign input is completely unaffected.
- `TutorialHighlight` — a pulsing cyan **outline-only** highlight
  (never fills the tile, never intercepts a tap), owned/positioned by
  `GridManager`.
- New instruction panel (`tutorial_panel.tscn`) and completion popup
  (`tutorial_complete_popup.tscn`, distinct from `LevelCompletePopup` —
  no stars/best-moves, and T10's graduation screen offers CAMPAIGN
  instead of NEXT TUTORIAL).
- Main Menu reordered to CONTINUE / CAMPAIGN / TUTORIAL / SETTINGS /
  QUIT; new, separate Tutorial Select scene
  (`tutorial_select.tscn`/`.gd`) — kept apart from `level_select.gd` on
  purpose for zero Campaign regression risk.
- `SaveManager` gained `tutorial_highest_unlocked_level`/
  `tutorial_completed_levels`, namespaced separately from both
  `campaign_*` and the dev-level fields (same collision reasoning as
  D54). No stars/best-moves for tutorials — they're lessons, not scored
  puzzles. `SAVE_VERSION` bumped 2 → 3, purely informational, zero
  migration code needed.

**Created all 10 tutorials** (`levels/tutorial/t01.gd` … `t10.gd`):
First Light (mirrors), Two Turns (reflection, progressively less
forced), Locked In (blockers + fixed mirrors), Both Lights (multiple
targets), Split Path (splitters), True Color (colored beams/targets),
Recolor (filters), Through the Portal (portals), Switch and Gate
(switches/gates/hazards together), Graduation (multiple emitters,
near-free-play finale, reduced hand-holding per the brief).

**Found and fixed a real signal-timing bug during this feature's own
testing:** `GridManager.move_made` fires *before* simulation runs
(pre-existing, unchanged Campaign behavior), so a target-activation
check would read stale state if wired to it directly. Fixed with a new,
purely additive `GridManager.simulation_updated` signal (fires *after*
target/switch/gate/hazard state updates) — zero effect on `move_made`'s
existing Campaign timing.

**Validated five independent ways:** a full T01 step-machine test
(forced-tap accept/reject, cascading advancement, save isolation in both
directions, `get_tutorial_level(11) == null`); all 10 tutorial boards
confirmed solvable through a real `GridManager`; a real scene-
instantiation check (Main Menu button order, Tutorial Select's 10 cards,
Campaign Level Select's 50 cards and QA-unlock-all completely
unaffected); exported-package validation (all 10 tutorial levels + every
new script/scene + all 50 campaign levels present and loadable); full
existing regression re-confirmed after every change — 15/15 dev-level +
50/50 campaign (65/65 total) solver-vs-runtime-replay all PASS
throughout, zero Campaign regression at any point.

New build: `versionCode=18`, `versionName="1.6.0-TUTORIAL-QA"`,
51,126,659 bytes (51.13 MB, +48,992 bytes over the Stage 5 build —
larger than a typical stage's pure-level-data delta since this pass
added real new architecture, not just level data). QA unlock-all kept
enabled per explicit instruction. **NOT MANUALLY APPROVED — ANDROID
MANUAL QA PENDING** for the Tutorial (new) and Stages 3, 4, and 5 (still
outstanding). This pass's own completion is not authorization to start
Stage 6 or any further Tutorial work.

## Development Test Mode + Production Campaign Phase 5 — Stage 5: Filters, Campaign Levels 41-50 (2026-09-20)

Two passes on top of "Production Campaign Phase 4" (`versionCode=15`,
51.06 MB): a QA-unlock-all toggle, then Stage 5 itself, built directly
against explicit Stage 4 feedback. Full technical detail in
`DECISIONS.md` D58/D59; design table in `CAMPAIGN_DESIGN.md` section
11e.

**QA unlock-all added:** `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_
TESTING` (`const bool`, currently `true`) plus one new function,
`LevelManager.is_campaign_level_selectable()`, which `level_select.gd`
now calls instead of `SaveManager.is_campaign_level_unlocked()`
directly. `SaveManager` itself was not modified - real completion/
unlock/star/best-move data behaves identically regardless of the flag.
Scales automatically to however many campaign levels exist. **Must be
disabled before any production release** - tracked as a release-
checklist item in `TEST_PLAN.md`.

**Stage 4 feedback recorded:** the user reported campaign levels 31-40
"feel easy." Stage 4's status stays `IMPLEMENTED / VALIDATED` - no bug
was found, so no Stage 4 level was modified - but the feedback directly
shaped Stage 5's escalation curve, per an explicit instruction that
Stage 5 make a clearly stronger difficulty jump.

**Filter mechanics audited from source before any level was designed**
— per this project's standing rule, `scripts/gameplay/filter.gd`,
`TilePlacement.make_filter()`, and `LaserSystem`'s filter-handling
branch were read directly. Confirmed: a `FILTER` has no orientation
field and is never rotatable - structurally excluded from the solver's
bitmask; it unconditionally overwrites a beam's color regardless of
incoming color/direction; and **chaining is "last filter touched
wins,"** never blending. Verified with a temporary headless fixture
(15 assertions, all passed first run, deleted after use). Solver/
runtime parity holds by construction - `LevelSolver` and `GridManager`
call the identical `LaserSystem.simulate_until_stable()`.

**Stage 5 — "Filters" (campaign levels 41-50):** created under
`levels/campaign/stage_05/level_01.gd` … `level_10.gd` — Filter, Shift,
Cipher, Channel, Conversion, Frequency, Transmute, Waveform, Vortex,
Paradox. The first stage to introduce the `FILTER` tile as a core
mechanic.

- **Filter introduction (Level 41):** clean, non-deceptive - incoming
  color -> filter -> changed color -> matching target.
- **Color-invalid bypass routes (Levels 42, 43, 45-50 variants):** a
  short, geometrically valid path reaches the target cell while still
  un-recolored, demonstrating that geometry alone never satisfies a
  colored-required target.
- **Sequential filtering / filter order (Levels 43, 50):** multiple
  filters on one path - only the LAST one touched before the target
  survives; Level 50 chains two (RED->GREEN->BLUE) on one branch while
  the other branch avoids both entirely, using its own third filter.
- **Splitter + filter placement (Levels 44-50):** filters placed
  downstream of a split, on one branch only, so each branch can reach
  its own differently-colored target.
- **Cross-branch / global dependency (Levels 46, 47, 48, 50):** a
  shared rotatable or fixed mirror gates both splitter branches at
  once, or an early mirror gates the entire board - reusing Stage 3/4's
  proven technique, now layered with filters.
- **Backward reasoning (Levels 47, 50):** a fixed mirror whose single
  orientation produces two different outcomes depending only on
  arrival direction.
- **Expert double-rejection false routes (Levels 49, 50):** one route
  is geometrically perfect but wrong color; another produces the
  objectively correct color but is blocked; only the true route
  satisfies both.
- Optimal-move curve **3, 4, 4, 5, 5, 6, 5, 6, 6, 7** (vs. Stage 4's 2,
  3, 4, 4, 4, 5, 5, 6, 6, 6) - no 1-2-move levels this time, and a new
  campaign-wide high of 7 at the finale. `states_explored` ranged 8-255
  (vs. Stage 4's 4-64) - Level 50's 255 clearly exceeds every prior
  stage's finale, including Stage 3's 127. Every hand-trace against
  `GridTypes.reflect()` matched the solver's confirmed `optimal_moves`
  exactly on the first attempt for all 10 levels; zero unintended
  `possible_decoys` (Level 50's one intentional decoy at `(3,3)`
  confirmed inert exactly as designed).

**Zero architecture changes needed:** `LevelManager.CAMPAIGN_LEVEL_PATHS`
gained 10 new entries immediately after Stage 4's 10; nothing else in
`LevelManager`, `SaveManager`, `game.gd`, or `level_select.gd` changed.
QA unlock-all automatically covered all 50 levels with zero edits.

**Validated four independent ways:** 50/50 total campaign (10/10 each
stage) + 15/15 dev-level solver-vs-runtime-replay regression PASS
(65/65 grand total); a real-autoload runtime driver confirmed
`get_campaign_level_count() == 50`, Level 40 completion unlocks Level
41, sequential unlock through Level 50, `campaign_highest_unlocked_
level` correctly caps at 50 with no Level 51 ever offered, and Stage
1-4 progress plus dev-level save fields stayed untouched; QA unlock
covered all 50 levels automatically; the exported `.pck` was
re-verified to contain all 50 campaign levels and `filter.gd`/
`filter.tscn` correctly, with dev tooling still excluded.

New build: `versionCode=17`, `versionName="1.5.0-STAGE5-QA"`,
51,077,667 bytes (51.08 MB, +22,330 bytes over the QA-unlock build —
pure level data, identical delta to every prior stage's growth). **NOT
MANUALLY APPROVED — ANDROID MANUAL QA PENDING** for Stages 3, 4, and 5.
QA unlock-all kept enabled per explicit instruction. This pass's own
completion is not authorization to start Stage 6 (Quantum Gates).

## Production Campaign Phase 4 — Stage 4: Spectrum, Campaign Levels 31-40 (2026-09-20)

Built from an explicit, detailed user request naming Stage 4 by number
and scope, while Stage 3 was still pending manual approval — see
`DECISIONS.md` D57 for that context. On top of "Production Campaign
Phase 3" (`versionCode=14`, 51.03 MB). Full technical detail in
`DECISIONS.md` D57; design table in `CAMPAIGN_DESIGN.md` section 11d.

**Color mechanics audited from source before any level was designed** —
per this project's standing "verify against source, not memory" rule,
`GridTypes.BeamColor`, `target_accepts_color()`, and `LaserSystem`'s
filter/splitter/mirror color handling were read directly. Confirmed: an
emitter's color is fixed for its entire beam graph; mirrors, fixed
mirrors, and BOTH splitter branches all preserve color unchanged; only a
`FILTER` tile recolors a beam. Since Stage 4 uses zero filters (per the
brief), every level has exactly one beam color throughout, so every
REQUIRED target must share it — color reasoning instead comes from
**non-required color-decoy targets** the beam can genuinely reach along
a plausible false route. Verified with a temporary headless fixture
(deleted after use): 3 matching-color activations pass, all 6
mismatched-color pairs correctly fail, mirror/fixed-mirror/both-
splitter-branch color preservation all confirmed. Solver/runtime parity
holds by construction — `LevelSolver` and `GridManager` call the
identical `LaserSystem.simulate_until_stable()`.

**Stage 4 — "Spectrum" (campaign levels 31-40):** created under
`levels/campaign/stage_04/level_01.gd` … `level_10.gd` — Prism,
Wavelength, Refraction, Photon, Chromatic, Diffraction, Phase, Radiance,
Pulse, Spectral. The first stage to introduce `BeamColor` reasoning as a
core mechanic.

- **Color introduction (Level 31):** a non-required GREEN target sits
  directly on the beam's straight path; the RED beam crosses it without
  activating, then two mirrors reach the real RED target — deliberately
  simple, no deception, per the brief.
- **Color-driven false routes (Levels 32, 35, 36, 37, 40):** the
  "obvious"/unrotated branch of a mirror or splitter is geometrically
  clean but reaches a wrong-color decoy, not the real target.
- **Cross-branch dependency** (Levels 36, 38, 39, 40): a single mirror
  tile is hit by both of a splitter's branches from different
  directions — only one orientation satisfies both required targets at
  once, reusing Stage 3's Level 26/28/30 technique with color layered on
  top.
- **Global dependency** (Level 38): the very first rotatable mirror
  gates access to the entire rest of the board, including the splitter
  and both required targets, even though they sit much later and look
  unrelated.
- **Geometry-vs-color double rejection** (Levels 39, 40): one route is
  geometrically correct but wrong color (a real, reachable decoy);
  another is color-compatible but blocked by a blocker; only the true
  route satisfies both constraints at once.
- **Backward reasoning** (Levels 33, 37, 39, 40): fixed mirrors whose
  single orientation only produces the needed exit for one specific
  entry direction, forcing the player to trace from the target backward.
- Optimal-move curve **2, 3, 4, 4, 4, 5, 5, 6, 6, 6** (vs. Stage 3's 2,
  3, 4, 4, 4, 4, 4, 5, 5, 6), `states_explored` ranging 4-64 (vs. Stage
  3's 4-127) — every hand-trace against `GridTypes.reflect()` matched
  the solver's confirmed `optimal_moves` exactly on the first attempt
  for all 10 levels, zero redesigns, zero unintended `possible_decoys`.

**Zero architecture changes needed:** `LevelManager.CAMPAIGN_LEVEL_PATHS`
gained 10 new entries immediately after Stage 3's 10; nothing else in
`LevelManager`, `SaveManager`, `game.gd`, or `level_select.gd` changed.
`target.gd`'s existing colored-ring + dimmed-alpha rendering (built for
Milestone 2's dev color levels) already handled every Stage 4 need.

**Validated four independent ways:** 40/40 total campaign (10/10 each
stage) + 15/15 dev-level solver-vs-runtime-replay regression PASS (55/55
grand total); a real-autoload runtime driver confirmed
`get_campaign_level_count() == 40`, Level 30 completion unlocks Level
31, sequential unlock through Level 40,
`campaign_highest_unlocked_level` correctly caps at 40 with no Level 41
ever offered, and Stage 1-3 progress plus dev-level save fields stayed
untouched; the exported `.pck` was re-verified to contain all 40
campaign levels and the color/target/splitter/mirror/blocker
scripts/scenes correctly, with dev tooling still excluded.

New build: `versionCode=15`, `versionName="1.4.0-STAGE4"`, 51,055,337
bytes (51.06 MB, +22,330 bytes over Stage 3 — pure level data, identical
delta to Stage 3's own growth over Stage 2). **NOT MANUALLY APPROVED —
ANDROID MANUAL QA PENDING** for both Stage 3 and Stage 4. This pass's
own completion is not authorization to start Stage 5 (Filters).

## Production Campaign Phase 3 — Stage 3: Split, Campaign Levels 21-30 (2026-09-19)

Built after the user manually played Stage 2 and gave explicit approval
("these are looking good"), on top of "Production Campaign Phase 2"
(`versionCode=13`, 51.01 MB). Full technical detail in `DECISIONS.md`
D56; design table in `CAMPAIGN_DESIGN.md` section 11c.

**Stage 2 approval recorded:** the user played Stage 2 for real and
gave explicit continuation feedback. Recorded in `CURRENT_STATUS.md`,
`PROJECT_HANDOFF.md`, `ROADMAP.md`, and `CLAUDE.md`.

**Splitter and multi-target behavior verified from source before any
level was designed** — per the brief's explicit "do not assume splitter
behavior" instruction, `LaserSystem.simulate()` and `GridManager` were
read directly, not inferred from `DECISIONS.md` D15's prose. Confirmed:
a splitter always sends the beam straight through unconditionally plus
one branch reflected via the same `GridTypes.reflect()` table mirrors
use; splitter orientation is rotated by the identical
`_on_orientable_tile_clicked()` handler as a mirror and counts as a move
the same way; the shared loop guard covers every splitter branch; the
solver treats a rotatable splitter as one bitmask bit exactly like a
mirror. Multi-target completion (`solved = required_count > 0 and
required_activated >= required_count and not hazard_hit`, recomputed
fresh every simulation pass) confirmed all required targets must be
simultaneously active, partial activation never solves the level, and
one beam can activate several targets in a single pass. Everything
matched existing documentation exactly.

**Stage 3 — "Split" (campaign levels 21-30):** created under
`levels/campaign/stage_03/level_01.gd` … `level_10.gd` — Divide, Dual
Signal, Fork Path, Branch Cut, False Fork, Cross Branch, Relay Split,
Split Trap, Parallel, Fracture. The first stage to introduce splitters
and multiple required targets as a core mechanic, built directly against
the user's explicit directive: difficulty must come from reasoning about
multiple beam branches, never from adding pieces.

- **Splitter tutorial (Level 21):** the sole, explicitly-sanctioned
  exception to "every target needs a move" — its straight-through target
  is free by design, specifically to demonstrate the splitter's
  unconditional straight branch before asking the player to reason about
  anything else.
- **Cross-branch dependency** (Levels 26, 28, 30): a single mirror tile
  is hit by both the straight-through beam and the reflected branch from
  different directions, so its orientation must satisfy both
  simultaneously — the two branches cannot be solved as independent
  mini-puzzles. Level 30's version uses a *fixed* shared mirror,
  combining this with backward reasoning in one piece.
- **Backward reasoning** (Levels 27, 29, 30): a fixed mirror beside a
  target only redirects correctly from one approach direction.
- **False routes and decoys:** blocker-guarded wrong branches (Levels
  24, 27, 28, 29, 30) punish the splitter's authored/default orientation
  concretely; genuine decoy mirrors (Levels 25, 27, 28, 29, 30) sit near
  the real action, never in unused corners.
- Optimal-move curve: 2,3,4,4,4,4,4,5,5,6 — starting below Stage 2's
  floor (a tutorial level) and climbing past its ceiling (5) by the
  finale. `states_explored` ranges 4-127 (vs. Stage 2's 8-120), still
  well within the solver's safety limit throughout.
- **One real level-authoring mistake caught by the solver, not by hand-
  tracing:** Level 30's first draft authored one mirror already in its
  solved orientation, so the solver found a 5-move solution skipping it
  entirely. Fixed by correcting the authored orientation to the intended
  wrong starting state, restoring the designed 6-move finale. Every
  other level matched its hand-traced intent exactly on the first
  solver pass.
- **Zero architecture changes needed** — `LevelManager.CAMPAIGN_LEVEL_PATHS`
  gained 10 new entries, nothing else in `LevelManager`, `SaveManager`,
  `game.gd`, or `level_select.gd` was touched. Confirmed
  `assets/gameplay/splitter/**`'s pre-existing export exclusion is safe
  — the splitter has zero texture dependency (pure procedural `_draw()`).
- Validated three independent ways: 30/30 total campaign (10/10 each
  stage) + 15/15 dev-level solver+runtime-replay regression PASS (45/45
  grand total); a read-only real-autoload runtime driver confirmed the
  Stage2→Stage3 boundary without writing to real save data; the exported
  package was re-verified to contain all 30 campaign levels, the
  splitter's script/scene, and every other referenced tile resource.
- New build: `versionCode=14`, `versionName="1.3.0-STAGE3"`, 51,033,007
  bytes (51.03 MB, +22,330 bytes over Stage 2 — pure level data, zero new
  assets). **IMPLEMENTED, AUTOMATED VALIDATION COMPLETE, ANDROID
  EXPORTED, MANUAL PLAYTEST PENDING.**

## Production Campaign Phase 2 — Stage 2: Reflection, Campaign Levels 11-20 (2026-09-19)

Built on top of the manually-approved Stage 1 ("the starting levels are
good") and "Production Campaign Phase 1" (`versionCode=12`, 50.99 MB).
Full technical detail in `DECISIONS.md` D55; design table in
`CAMPAIGN_DESIGN.md` section 11b.

**Stage 1 approval recorded:** the user played Stage 1 for real and
confirmed the levels were good. This is the project's first MANUAL-tier
approval of any campaign content — recorded in `CURRENT_STATUS.md`,
`PROJECT_HANDOFF.md`, `ROADMAP.md`, and `CLAUDE.md`.

**Stage 2 — "Reflection" (campaign levels 11-20):** created under
`levels/campaign/stage_02/level_01.gd` … `level_10.gd` — Redirect, Dead
End, Fork Point, Reverse Trace, Mirage, Cascade, Backtrack, Echo Path,
Interference, Culmination. Built directly against the user's explicit
directive: difficulty must come from reasoning, misdirection, route
planning, and dependencies — never from grid size, mirror count, visual
clutter, or artificially inflated move counts.

- **Backward reasoning** (exactly the 3 levels requested — 14, 17, 20):
  each places a fixed mirror directly beside the target that only
  redirects correctly when approached from one specific direction,
  rewarding a player who reasons backward from the target rather than
  forward from the emitter.
- **Multi-step dependency** (Levels 16 and 20 explicitly, by design):
  an early mirror's correct orientation only makes sense once the full
  downstream route is traced — no piece can be solved in isolation.
- **Stronger false routes and decoys:** blocker-guarded wrong forks
  (Levels 12, 17, 20) punish plausible-looking wrong choices concretely
  rather than letting them silently exit the grid; a genuinely plausible
  false-branch mirror (Level 13) and dedicated decoys (Levels 15, 19,
  20) sit near the real action rather than in unused corners.
- Optimal-move curve: 3,3,3,3,4,4,4,5,5,5 — starting at Stage 1's own
  peak (4) and climbing to 5. `states_explored` ranges 8-120 (vs. Stage
  1's 2-57), with Level 19 alone hitting 120 — more than double Stage
  1's highest. This increase came from the actual designs (route length,
  fork count, fixed-mirror clusters), not from padding move counts.

**Zero architecture changes were needed.** Everything D54 built for
Stage 1 — `LevelManager.CAMPAIGN_LEVEL_PATHS`, the campaign-prefixed
`SaveManager` fields, `game.gd`'s campaign-data branch, `level_select.gd`'s
enumeration — scaled to Stage 2 by simply appending 10 more paths.
Specifically verified (not assumed) that Level 20's Level Complete popup
correctly has no Next Level button, since no Level 21 exists yet — the
existing generic `has_next = current_level_id <
LevelManager.get_campaign_level_count()` check in `game.gd` already
handles the "last level of what currently exists" case with zero new
code.

**Two real level-design mistakes caught before ever running the
solver:** re-deriving each path by hand against `GridTypes.reflect()`'s
actual table at write time (not trusting an earlier scratch calculation)
caught an early Level 11 draft whose designed target position was
unreachable by its own mirror chain, and an early Level 12 draft whose
blocker sat on a cell no beam configuration could ever reach (made
decorative by an adjacent mirror that always redirected the beam before
it could arrive). Both fixed before validation, not discovered by it —
the solver would not have flagged either as structurally broken, only as
"not the intended puzzle."

**Validation:** 10/10 Stage 2 + 10/10 Stage 1 + 15/15 dev-level
solver+runtime-replay regression PASS (20/20 total campaign — confirms
Stage 1 didn't regress while Stage 2 was added). A real-autoload runtime
driver played all 20 campaign levels in order through the actual
`_on_orientable_tile_clicked()` path, confirming the Stage1→Stage2
unlock boundary (completing Level 10 unlocks Level 11), Level Select
showing all 20 with correct lock states, and Level 20's Next Level
button correctly absent. The exported package was re-verified (from a
directory with no `project.godot` in its parent chain) to contain all 20
campaign levels correctly.

New build: `versionCode=13`, `versionName="1.2.0-STAGE2"`,
`package=com.beamshift.game` (unchanged), confirmed via `aapt2 dump
badging` (`minSdkVersion=24`, `targetSdkVersion=36` also unchanged).
Final size: **51,010,677 bytes (51.01 MB)** — up only 18,234 bytes
(~18.2 KB) from the prior build, exactly as expected for pure level-data
files with zero new assets. **IMPLEMENTED, AUTOMATED VALIDATION
COMPLETE, ANDROID EXPORTED, MANUAL PLAYTEST PENDING** — not manually
approved. Stages 3-10 are architecture-only until Stage 2 is explicitly
approved — this pass's own completion is not authorization to continue.

## Production Campaign Phase 1 — Campaign Architecture + Real Levels 1-10 (2026-09-19)

The real 100-level campaign begins (`ROADMAP.md` Milestone 4), on top of
"APK Optimization + Asset Cleanup" (`versionCode=11`, 50.97 MB). Full
technical detail in `DECISIONS.md` D54; the campaign's own architecture
reference is the new `CAMPAIGN_DESIGN.md`.

**Architecture:** defined the complete 100-level structure (10 stages ×
10 levels, mechanic progression per stage, difficulty philosophy,
optimal-move/grid-size guidelines per stage, production-level acceptance
criteria, and the solver-validation workflow) in `CAMPAIGN_DESIGN.md` -
the standing reference for creating every future stage.

**Stage 1 — "First Light" (campaign levels 1-10):** created under
`levels/campaign/stage_01/level_01.gd` … `level_10.gd`, newly designed
(not copied from the dev/regression levels) — Ignition, First Turn,
Signal Path, Blocked, Alignment, False Signal, Deception, Long Relay,
Junction, Breakthrough. Each teaches one specific concept building on
the last: basic rotation → chained reflection → multiple mirrors →
blockers → fixed mirrors → plausible forks → a first genuine decoy →
long-route planning → combining fixed mirror + blocker + decoy → a
finale combining everything. Every level's `optimal_moves` was set from
`LevelSolver.analyze()`'s confirmed result, never hand-guessed; every
level passed `LevelValidator` with zero errors/warnings; zero levels
needed rejection or redesign after the first solver pass (every
hand-traced solution, re-derived directly against `GridTypes.reflect()`'s
actual reflection table, matched the solver's result exactly). Full
design table (teaching goal, solver-confirmed optimal moves, decoys,
states explored) in `CAMPAIGN_DESIGN.md` section 11.

**Population separation:** campaign levels are kept fully separate from
the 15 dev/regression levels (`levels/level_01.gd`-`level_15.gd`, left
completely untouched) in both level storage and save data.
`LevelManager` gained `CAMPAIGN_LEVEL_PATHS` and campaign-prefixed
mirrors of every dev-level function (`get_campaign_level()`,
`calculate_campaign_stars()`, `get_campaign_continue_level_id()`) using
a separate cache dictionary. `SaveManager` gained parallel `campaign_*`
progress fields (`campaign_highest_unlocked_level`,
`campaign_completed_levels`, `campaign_best_moves_per_level`,
`campaign_best_stars_per_level`) and campaign-prefixed mirrors of every
dev-level method - necessary because both populations' level ids start
at 1 and would collide in the same save-dictionary keys otherwise. The
original dev-level fields/methods are completely unchanged; a save file
predating this change loads correctly with fresh campaign progress
(`SAVE_VERSION` bumped 1→2 as a record of the schema growing - purely
additive, no migration code needed).

**Player-facing rewiring:** `game.gd`'s normal-play branch,
`level_select.gd`, and `GameManager.continue_game()` now resolve
campaign data instead of dev data. **A real integration bug was found
and fixed, not just guessed at:** `main_menu.gd`'s Continue-button
enabled/disabled check was still reading the old dev-level save fields,
which would never update again under normal play now that nothing calls
the dev-level `record_level_result()` from the player-facing path -
found by grepping every `SaveManager.`/`LevelManager.` call site across
`scripts/ui/` and `scripts/managers/` specifically looking for anything
still touching the old field names after making the rewiring changes.

**A real design trap found while authoring the levels themselves:**
`LaserSystem` deliberately lets a beam continue past an activated target
(so one beam can chain-activate several targets, relevant from Stage 3
onward) - Campaign Level 9's first-draft decoy at `(0,4)` sat directly
in the target's row, on the beam's post-target continuation path, and
wasn't actually untouched the way a trace stopping at the target would
suggest. Caught before validation by re-tracing the full post-target
path; moved to `(0,3)`, a genuinely safe cell. Recorded as a standing
design rule in `CAMPAIGN_DESIGN.md` section 8 for every future stage's
decoys.

**A pre-existing tooling quirk found, not fixed:** `LevelMetrics`'s
`difficulty_label` treats any emitter - even a default-`WHITE` one - as
"uses colored beams," inflating every level's difficulty score by +3
unconditionally. This pushes several genuinely tutorial-tier Stage 1
levels into `HARD`/`EXPERT` labels despite being 1-4-move, single-
decision-point puzzles on 5x5 grids. Not fixed (shared dev tooling,
outside this pass's scope, and the project's own standing guidance
already says not to treat the estimate as authoritative) - documented
in `CAMPAIGN_DESIGN.md` section 9 so it isn't mistaken for a real
signal that Stage 1 needs to be easier.

**Validation:** 10/10 campaign-level solver+runtime-replay regression
PASS, 15/15 dev-level solver+runtime-replay regression PASS (unaffected
- confirms nothing about the dev/regression population regressed). A
real-autoload runtime driver (temporary `run/main_scene` swap)
confirmed the actual Main Menu → Level Select → Game → solve →
`SaveManager` write → Next Level flow end to end: Continue disabled on a
fresh save, Level Select showing exactly 10 buttons with only Level 1
unlocked, Campaign Level 1 solving via the real
`_on_orientable_tile_clicked()` path, the Level Complete popup appearing
after the real 0.8s delay, `campaign_*` save fields recording correctly
(3 stars, 1 move - Level 1's exact optimal), **the dev-level save fields
staying completely untouched**, and Next Level correctly advancing to
campaign level 2. The exported package was re-verified (from a
directory with no `project.godot` in its parent chain, per the
established D51/D53 technique) to contain all 10 campaign levels and
all 15 dev levels correctly, with `editor_fixtures`/`tools/level_editor`
still excluded.

New build: `versionCode=12`, `versionName="1.1.0-STAGE1"`,
`package=com.beamshift.game` (unchanged), confirmed via `aapt2 dump
badging` (`minSdkVersion=24`, `targetSdkVersion=36` also unchanged).
Final size: **50,992,443 bytes (50.99 MB)** - up only 18,234 bytes
(~17.8 KB) from the prior build, exactly as expected for pure level-data
files with zero new assets. **NOT MANUALLY APPROVED - ANDROID MANUAL QA
PENDING**, this is the next required step. Stages 2-10 are architecture-
only until Stage 1 is explicitly approved - this pass's own completion
is not authorization to continue.

## APK Optimization + Asset Cleanup (2026-09-19)

Explicitly-requested, staged, safety-first Android APK size reduction on
top of "Final HUD Alignment + Level Complete Delay" (`versionCode=10`,
113.1 MB). Zero gameplay, level-data, scoring, or UI-layout changes. Full
technical detail in `DECISIONS.md` D53; validation detail in
`TEST_PLAN.md`'s "APK Optimization + Asset Cleanup" section.

**Baseline audit:** a from-scratch asset reference map (`grep` every
`.tscn`/`.gd`/`.tres`/`project.godot` for `res://assets/...` paths,
diffed against all 83 PNGs on disk) found exactly 34 referenced and 49
unreferenced assets. Every one of the 49 was already covered by
`export_presets.cfg`'s `exclude_filter` from prior sessions - but the
shipped `versionCode=10` APK's own `export_presets.cfg` had a newer
mtime than the APK file itself, meaning the build simply predated
several of its own already-authored exclusion rules.

**Pass A - re-export, zero content changes:** a plain re-export against
the current (already-correct) `exclude_filter` dropped the APK from
113.1 MB to 73.56 MB (39.57 MB / 35% saved).

**Pass C - derived runtime textures:** reading real PNG pixel dimensions
and cross-referencing actual on-screen display sizes (`custom_minimum_size`
values, `cell_size`-relative `draw_texture_rect` calls) found 21
gameplay-tile and icon-class assets shipping at 1254×1254 (or
1222×1287) source resolution while displaying at 26-250px on screen -
5x to 48x linear oversampling (the level-select stars were the extreme
case: 1254px source for a 26px display, ~2300x more pixels than ever
rendered). Created downscaled `<name>_runtime.png` derived copies next
to each original (`System.Drawing`, `HighQualityBicubic` interpolation,
straight alpha preserved, sized at 2-4x real display size for retina
headroom - 256px for icons, 512px for tile art, 128px for stars, 512×540
for level cards, 640×320 for toggles), rewired every `preload()`/
`ext_resource` reference across `scripts/gameplay/{blocker,gate,
grid_manager,hazard,mirror,tile_visual,target}.gd`, `scripts/ui/
{settings_menu,level_complete_popup,level_button}.gd`, and
`scenes/{gameplay/game,ui/level_button,ui/level_complete_popup,
ui/settings_menu}.tscn`, and added the 21 now-unreferenced original
masters to `export_presets.cfg`'s `exclude_filter` (kept on disk,
unused - same pattern D31 established for `pieces/`/`tiles/`). Dropped
the APK a further 22.59 MB, to 50.97 MB (30.7% off Pass A, 55.0% off
the original baseline).

**Deliberately left untouched:** the 3 `Button` textures and the
Settings/Pause/Level Complete panels (9-sliced `StyleBoxTexture` with
hand-measured `region_rect`/`texture_margin_*` values - recomputing them
for a resized source carries real regression risk this pass judged not
worth taking); the 2 HUD bars (2112px wide vs. a 1080px-wide logical
canvas - only ~2x oversampled, normal retina headroom, not waste); the 3
full-screen backgrounds (already VRAM/ETC2-compressed since Milestone
4A, correctly sized for the portrait canvas).

**Validation:** every pass re-verified against a **real exported `.pck`**
(not just source) - `ResourceLoader.exists()` confirmed all referenced/
derived assets present and all excluded/superseded masters absent; a
real `GridManager.load_level()` call for Levels 3/5/12/15 against each
package confirmed their Blocker/Hazard/Switch/Gate/Portal tiles still
instantiate correctly (re-confirming the D51 fix survived intact). A new
gotcha was found and documented in this exported-package technique:
running the check script from *inside* the project directory silently
blends the pck's contents with the local filesystem, producing false
"present" results for genuinely-excluded paths - fixed by running from a
directory with no `project.godot` anywhere in its parent chain.
DESKTOP RENDERED screenshots (real non-headless GPU rendering) of all 6
key screens - Main Menu, Level Select, Gameplay/Level 3, Settings,
Pause, Level Complete - were captured and personally inspected; no
blur, ugly alpha edges, blocky gradients, destroyed neon glow, color
shift, texture stretching, or missing artwork found on any screen (the
first Pause capture attempt was actually a duplicate of the Settings
screen due to a driver-script bug - fixed and recaptured correctly). All
15 levels' `LevelSolver` + runtime-replay regression PASS throughout
(unaffected - no simulation/gameplay code touched at any point).

**Also this pass:** the temporary `BuildLabel` QA marker node ("HUD +
DELAY FIX") was removed from `main_menu.tscn`/`settings_menu.tscn`, per
the standing instruction to strip it once a build supersedes the one it
identified.

New build: `versionCode=11`, `versionName="1.0.0-OPTIMIZED"`,
`package=com.beamshift.game` (unchanged), confirmed via `aapt2 dump
badging` (`minSdkVersion=24`, `targetSdkVersion=36` also unchanged).
Final size: **50,974,209 bytes (50.97 MB) - 62,155,484 bytes (59.3 MB,
55.0%) below the `versionCode=10` baseline.** **NOT MANUALLY APPROVED -
ANDROID MANUAL QA PENDING**, this is the next required step. This pass's
own completion is not authorization to start a further optimization
pass, production-pipeline prep, or the 100-level campaign.

## Final HUD Alignment + Level Complete Delay (2026-09-19)

Small polish pass on top of "Android HUD Alignment + Missing Tile Fix."
No puzzle logic, level data, scoring, or assets touched.

**Bottom HUD alignment:** the previous pass's horizontal slot-center
measurements (`0.294`/`0.7045` fractions) turned out to already be
pixel-accurate on re-measurement (a flood-fill connected-component scan
of `bs_hud_bottom_portrait.png`, seeded inside each slot, confirmed the
same values within 0.0002). The actual residual offset was **vertical**:
`ResetButton`/`PauseButton` were anchored to the bar's exact vertical
center (`anchor_top = anchor_bottom = 0.5`), but each slot's own flood-
filled bounding box center sits slightly below that (`fracY ≈ 0.5175` for
Reset, `≈0.5161` for Pause) - a ~6px offset at the 1080-wide reference
that read as "slightly off-center." Both buttons' `anchor_top`/
`anchor_bottom` were corrected to these measured fractions; horizontal
anchors unchanged. Confirmed via a real rendered screenshot and by
reading the buttons' actual `Rect2` relative to `BottomBar` at runtime
(see Final Report below for exact numbers).

**Level Complete delay:** `game.gd` gained `const LEVEL_COMPLETE_DELAY :=
0.8` and a `_completion_pending: bool` guard. `_on_level_solved()` now
snapshots the result (moves/stars/save write - unchanged, still
synchronous and immediate), then `await get_tree().create_timer(
LEVEL_COMPLETE_DELAY).timeout` before calling
`_complete_popup.show_result()`. **The solve calculation itself is
untouched and still immediate** - `grid_manager.gd`'s `is_solved` becomes
`true` the instant the winning move lands, exactly as before; only the
popup's appearance is delayed. **Input during the delay is already
handled by existing code** - `GridManager._on_orientable_tile_clicked()`
has always started with `if is_solved: return`, so once solved, further
mirror/splitter clicks are rejected with zero new code. Verified directly
(not assumed): a real click attempted during the delay window left
`tile_orientations` byte-for-byte unchanged.

**Duplicate-popup / stale-delay protection:** `_completion_pending`
prevents `_on_level_solved()` from starting a second timer if it somehow
fires twice, and `_load_current_level()` (called by Reset, Retry, and
Next Level) clears the flag immediately - so if the player resets during
the delay, the in-flight `await` checks `_completion_pending` (and
`is_inside_tree()`, in case the scene itself is gone) after waking up and
simply returns without showing a stale popup for a board that's no longer
solved.

**Validation:**
- AUTOMATED — 15/15 `LevelSolver` PASS, 15/15 runtime-replay PASS
  (unaffected - the regression script checks `GridManager.is_solved`
  directly, never the popup, so the UI-only delay has zero effect on it).
- DESKTOP RENDERED / real-timing — a live (non-headless) driver clicked
  through real solutions for Levels 1, 3, 5, 12, and 15 using
  `Input.parse_input_event()` (the actual `_gui_input` path, not a
  bypass) and measured wall-clock time to popup appearance: all landed
  at ≈0.75-0.90s (polling granularity 0.15s), confirming the ~0.8s target
  and ruling out both "instant" and "never appears." A same-driver click
  attempted mid-delay confirmed `tile_orientations` was unchanged. Retry
  after the popup produced a clean `moves_used=0`/`is_solved=false`/
  `_completion_pending=false` state. Next Level (tested on Level 1→2)
  correctly advanced `current_level_id` and loaded a fresh, unsolved
  board. Reset-before-solve (mid-puzzle, popup never shown) worked as
  before.
- ANDROID EXPORTED — fresh APK, `versionCode=10`/
  `versionName="1.0.0-HUDDELAY"` confirmed via `aapt2 dump badging`.
- **ANDROID MANUAL QA PENDING** - not yet confirmed on a real device.

## Android HUD Alignment + Missing Tile Fix (2026-09-19)

The user's manual Android QA found: (1) top HUD text alignment wrong,
(2) bottom HUD button/icon alignment wrong, (3) Level 3 puzzle tiles
invisible on Android despite being visible on PC, with the laser beam
still visible and level logic still correct. See `DECISIONS.md`'s
"Android HUD Alignment + Missing Tile Fix" section (D51/D52) for full
technical detail.

**Missing-tile root cause (D51), found and fixed without needing physical
Android hardware:** `blocker.gd`/`hazard.gd` `preload()`d their tile
textures from `assets/gameplay/pieces/`, which is entirely excluded from
the Android export filter as an "unused duplicate art" folder (D31/D24) -
except these two specific files were never actually unused. In any real
exported build, this makes both scripts fail to parse/load entirely,
which makes `grid_manager.gd`'s statically-typed
`var node: BlockerTile = BLOCKER_SCENE.instantiate()` throw an uncaught
runtime type-mismatch error that **silently aborts the rest of that
level's tile-loading loop** - every tile placed after a blocker/hazard in
a level's array never gets created. The laser beam still renders because
`LaserSystem` reads level data directly, independent of the visual tile
nodes - exactly matching the reported "tiles gone, beam fine" symptom.
**4 of the 15 real levels were affected: Level 3 and 5 (blocker), Level
12 and 15 (hazard).**

Verified real, not theoretical, three independent ways: (a) exported an
actual `.pck` and confirmed `ResourceLoader.exists()` returns `false` for
the missing path against it; (b) instantiated a real `GridManager` against
that broken package and confirmed only 2 of Level 3's 5 tiles were
created; (c) unzipped the previously-shipped APK directly and confirmed
`assets/gameplay/pieces/` was absent from it. Fixed by moving the
actually-used art into the already-established, non-excluded canonical
per-type folders (`assets/gameplay/blocker/`, `assets/gameplay/hazard/`)
and repointing both scripts - `export_presets.cfg`'s exclude filter itself
was correct and untouched. Re-verified the same three ways after the fix,
all now pass; the newly-built APK was unzipped again and confirmed to
contain the correct paths and no longer reference `pieces/`.

**HUD alignment (D52):** the top HUD's level-name label previously used
`"LEVEL %d: %s"` with word-wrap enabled in a narrow slot, producing an
awkward 3-line wrap for most level names. Now formatted as two explicit
lines with word-wrap disabled and a new ellipsis-truncation helper
(`_shorten_level_name()`), guaranteeing exactly two clean, centered lines.
Top/bottom bar slot anchors were re-measured by pixel-sampling the actual
HUD art (not eyeballed) for exact, symmetric slot centers; the Back button
was moved out of the level-label's layout container (it had been pushing
the label off-center) into its own small button near the bar's left edge.

**Validation:**
- AUTOMATED — `--headless --import` clean; all 15 levels'
  solver-vs-runtime-replay regression PASS (unchanged - confirms zero
  gameplay-logic impact); Level 3 Reset/replay-after-Reset PASS.
- DESKTOP RENDERED — real screenshots captured for Levels 1, 2, 3, 4, 5,
  and 12 (the last two specifically to re-confirm the blocker/hazard fix
  across every affected level, not just Level 3). All show correct HUD
  text/alignment and all tiles (emitter, mirror, blocker, hazard, target)
  rendering correctly. Note: since desktop RENDERED tests run from
  source, they never reproduced the export-filter bug in the first
  place - the authoritative proof for this fix is the exported-package
  test described above, not this screenshot pass (which only validates
  layout/appearance).
- ANDROID EXPORTED — fresh APK built, zero export errors,
  `versionCode=9`/`versionName="1.0.0-TILEFIX"` confirmed via
  `aapt2 dump badging`. Size ≈113.1 MB, essentially unchanged. The
  shipped APK's contents were directly unzipped and inspected as
  described above - this is the actual authoritative confirmation the fix
  is real, independent of the desktop rendering pass.
- **ANDROID MANUAL QA PENDING** - not yet confirmed on a real device.
  This is the next required step.

## Milestone 4A.6 — Corrected Settings Panel Integration + Final UI QA (2026-09-19)

Small follow-up to Milestone 4A.5. The user manually replaced the
mislabeled `bs_panel_settings_portrait.png` (D48) with the correct
Settings artwork. No gameplay/simulation code touched.

**Verified before integrating (not just trusted):** MD5 confirmed the
corrected file (`842825d8...`) now differs from
`bs_panel_level_complete_portrait.png` (`939e93f0...`); visual inspection
confirmed a gear icon and baked "SETTINGS" title at 941x1672, matching
the Pause/Level Complete frame style. See `DECISIONS.md` D50.

**Integrated:** `settings_menu.tscn` now references
`res://assets/ui/panels/bs_panel_settings_portrait.png`;
`texture_margin_*` pixel-sampled directly against this file (left=160,
top=460, right=175, bottom=255). No duplicate title `Label` existed or
was added. Panel width kept at 900 for visual consistency with the
sibling panels. **All five of the Milestone 4A.5 replacement assets are
now active** - Settings, Pause, Level Complete, top HUD, bottom HUD.
Confirmed zero stray references to any superseded art anywhere in
`scenes/`.

**Build marker:** updated from "UI 4A.4" to "UI FINAL QA" on Main Menu
and Settings (bottom-right, same position as before).

**Validation:**
- AUTOMATED — `--headless --import` clean; all 15 levels'
  solver-vs-runtime-replay regression PASS (unchanged, confirms zero
  gameplay impact); Level 3 Reset/replay-after-Reset PASS.
- DESKTOP RENDERED — real screenshots captured and personally inspected
  for all 6 screens. Settings now shows the correct gear icon and
  "SETTINGS" title, properly sized (no more tiny-panel-in-empty-screen
  problem), Sound/Music/Back all legible and correctly spaced, no
  clipping, no duplicate title. Pause and Level Complete confirmed
  unaffected/still correct. A real two-click simulated solve of Level 3
  (`Input.parse_input_event()` through the actual `_gui_input()` path)
  still reached `moves_used=2`, `is_solved=true`,
  `complete_popup_visible=true` - the Settings swap didn't disturb
  gameplay input.
- ANDROID EXPORTED — fresh APK built, zero export errors,
  `versionCode=8`/`versionName="1.0.0-UIFINAL"` confirmed via
  `aapt2 dump badging` on the actual built APK. Size ≈113.2 MB (~108 MB),
  essentially unchanged from Milestone 4A.5 (~0.1 MB growth from the
  corrected Settings PNG being a similar size to its predecessor).
- **ANDROID MANUAL QA PENDING** - not yet reviewed on a real device. This
  is now the single remaining gate before any further work - see
  `NEXT_CLAUDE_PROMPT.md`.

No asset optimization or deletion performed this pass, per instruction -
old/superseded art remains on disk, unreferenced.

## Milestone 4A.5 — Portrait UI Replacement + Responsive HUD Integration (2026-09-19)

Replaced the Settings/Pause/Level Complete panel art and gameplay top/
bottom HUD art with five newly generated portrait-oriented assets. UI
integration only - no puzzle simulation, `LaserSystem`, `GridTypes`,
level data, `LevelManager`, `SaveManager`, scoring, or mirror/target logic
was touched. See `DECISIONS.md`'s "Milestone 4A.4" section (D48/D49) for
full reasoning.

**Asset finding (D48):** `bs_panel_settings_portrait.png` is a
byte-identical duplicate of `bs_panel_level_complete_portrait.png` (both
say "LEVEL COMPLETE", confirmed via MD5) - not a real Settings asset.
Settings was deliberately left on its old, correct art rather than
shipping a mismatched screen; the other four assets (Pause, Level
Complete, top HUD, bottom HUD) integrated normally.

**Pause & Level Complete panels:** swapped to the new portrait art
(941x1672, both with baked-in titles - no duplicate dynamic title Labels
added, matching D38's existing rule). `texture_margin_*` re-measured
against the new art directly (pixel-sampled, not guessed) since its
border proportions differ from the old art. Level Complete's panel went
from a 1536x1024 landscape source to portrait, requiring re-measurement
but no structural layout change (content order - stars, moves, best
moves, buttons - was already correct).

**Gameplay HUD (top/bottom bars):** replaced `PanelContainer` +
fixed-height `StyleBoxTexture` with a `Control` running a new script
(`scripts/ui/aspect_bar.gd`) that locks the bar's height to the source
art's aspect ratio on every resize (same pattern `grid_manager.gd` uses
for its own square-cell layout) - the new HUD art has a structural
reactor-icon centerpiece that would visibly distort under arbitrary
stretching, unlike the old tileable-border art. Back button + Level
label live in the top bar's left slot, Moves counter in its right slot;
Reset and Pause (the only two implemented bottom-bar actions - Hint stays
hidden/unimplemented, no Undo exists) live in the two bottom-bar slots
flanking the reactor icon, with the two outer slots left visually empty
per the brief's explicit instruction not to invent placeholder
functionality. All decorative `TextureRect` backgrounds use
`mouse_filter = IGNORE`; interactive buttons are unaffected structurally
(same `unique_name_in_owner` nodes `game.gd` already referenced, so no
script changes were needed there beyond removing the debug overlay
below).

**Removed:** the temporary Milestone 4A.3 "L3 DEBUG" on-screen overlay
(`game.gd`/`game.tscn`) - Level 3 is confirmed working (see Milestone
4A.4 above), so the diagnostic is no longer needed. The QA build-identity
label (Main Menu/Settings, bottom-right) was kept per standing practice
and updated to "UI 4A.4".

**Validation:**
- AUTOMATED — `--headless --import` clean; all 15 levels' solver
  solutions replayed through a real `GridManager`, all 15 PASS
  (`is_solved == true`, solver-vs-declared `optimal_moves` match, zero
  `LevelValidator` errors) - confirms zero gameplay regression from this
  UI-only pass; Level 3 Reset and replay-after-Reset both PASS.
- DESKTOP RENDERED — real (non-headless) screenshots captured and
  personally inspected for Main Menu, Level Select, Settings, Gameplay
  (Level 3 initial state), Pause (opened mid-level via the real
  `PauseButton.pressed` signal), and Level Complete (reached via a real
  simulated two-click solve of Level 3, `Input.parse_input_event()`
  through the actual `_gui_input()` path). Grid available area measured
  at ≈45.8% of the 1080x1920 screen vs. ≈16.3% per HUD bar - grid is the
  single largest region. All decorative HUD backgrounds confirmed
  `mouse_filter = IGNORE` in the running scene; the real click-through
  still solved Level 3 (`moves_used=2`, `is_solved=true`,
  `complete_popup_visible=true`), confirming interactive controls were
  not accidentally blocked by the new decorative layers.
- ANDROID EXPORTED — fresh APK built (old APK deleted first), zero export
  errors, `versionCode=7`/`versionName="1.0.0-UI4A4"` confirmed via
  `aapt2 dump badging` on the actual built APK (not just the source
  file). Size ≈113.1 MB (~108 MB), up ≈1 MB from the five new PNGs (all
  still Lossless-compressed, consistent with existing UI/icon texture
  policy - see "Known issues" in `CURRENT_STATUS.md`/`PROJECT_HANDOFF.md`
  for the standing note that texture compression is worth revisiting if
  size becomes a real concern).
- **ANDROID MANUAL QA PENDING** - nobody has looked at this build on a
  real device yet. Only the user's own review can approve it. See
  `TEST_PLAN.md`'s Milestone 4A.4 section for the exact manual checklist.

## Milestone 4A.4 — Level 3 Device/Runtime Re-Investigation (2026-09-19)

The user confirmed BUILD 4A.3 **was** visible on their tested device and
Level 3 **still** did not complete - ruling out the stale-APK theory
Milestone 4A.3 had concluded with. This pass re-audited the full Level 3
path end to end rather than re-asserting the same explanation a second
time. See `TEST_PLAN.md`'s "Milestone 4A.4" section for exact commands.

**Traced and verified, all correct:**
- Runtime level resource: `res://levels/level_03.gd` (via
  `LevelManager.LEVEL_PATHS[2]`) - confirmed by printing the actual
  loaded `level_data` at runtime, not assumed.
- Full tile dump at runtime matched `level_03.gd`'s source exactly:
  emitter (0,2) RIGHT, mirror (2,2) SLASH, blocker (2,0), mirror (2,3)
  SLASH, target (4,3) WHITE/required, 5x5 grid.
- Target visibility: instantiated, correctly positioned, correct
  `z_index` (default draw order, nothing overlaps it), not modulated
  transparent, not clipped - confirmed both in code (`target.gd`) and in
  an actual rendered screenshot (a clear reticle icon at grid cell (4,3),
  reddish/inactive before solve).
- Mirror orientation mapping (`mirror.gd`): SLASH renders at 0 degrees
  and BACKSLASH at 90 degrees, matching `GridTypes.reflect()` - confirmed
  unchanged since the Milestone 4A.2 fix, no regression.
- Input path: no duplicate touch/mouse handling exists anywhere in the
  codebase - `mirror.gd`/`splitter.gd`'s `_gui_input()` is the only
  listener, reacting only to `InputEventMouseButton.pressed`, and no
  script anywhere handles `InputEventScreenTouch` separately. Godot's
  default `emulate_mouse_from_touch` converts a touch to exactly one
  mouse-button-press dispatch to `_gui_input()` - a code-level double-fire
  is not possible with this input-handling structure.
  `LevelCompletePopup`/`PauseMenu` are correctly `hide()`-d at `_ready()`
  and stay invisible (and therefore non-input-blocking) until explicitly
  shown - not a hidden full-screen input blocker.
- A REAL click-driven test (`Input.parse_input_event()`, real rendering,
  not `--headless`) tapped mirror (2,2) then (2,3) through the actual
  `_gui_input()` -> `tile_clicked` -> `GridManager._on_orientable_tile_clicked()`
  path exactly as a player would: moves went 0 -> 1 -> 2, orientations
  went SLASH/SLASH -> BACKSLASH/SLASH -> BACKSLASH/BACKSLASH, beam path
  printed correctly at each step, target activated after move 2,
  `is_solved` became `true`, and the Level Complete popup appeared
  automatically with "Moves Used: 2 / Best Moves: 2" - all captured in
  rendered screenshots and personally inspected.
- Regression: all 15 levels' solver solutions replayed through a real
  `GridManager` - all PASS (`is_solved == true`, solver-vs-declared
  `optimal_moves` match, zero `LevelValidator` errors). Level 3 Reset and
  replay-after-Reset both PASS (`is_solved` correctly returns to `false`
  after reset with orientations restored to SLASH/SLASH, then `true`
  again after replaying the same two clicks).

**No code defect was found this pass** - every traced step behaved
correctly, matching Milestone 4A.3's RENDERED findings exactly, now with
a REAL click-through re-confirming it rather than re-asserting the same
conclusion.

**New, temporary QA tooling added instead of a further guess:** a small
on-screen debug overlay (`game.gd`/`game.tscn`, gated to Level 3 only,
purely presentational) now shows live `Moves` / mirror `A`/`B`
orientation / `Targets` / `Solved` state directly on the device during
play. If the actual failure is something genuinely Android-specific that
neither headless nor desktop-rendered testing can reproduce (a real
touchscreen digitizer quirk, a specific device's input driver, etc.),
this overlay is the only way to see what state the device itself reaches
after the two taps - existing docs had no on-device diagnostic
whatsoever. **Remove this overlay once the real root cause is found and
fixed, or once Level 3 is confirmed working - it must not ship.**

**Version bump:** `versionCode` 5 -> 6, `versionName` "1.0.0-4A.3" ->
"1.0.0-L3FIX" (confirmed via `aapt2 dump badging` on the exported APK,
not just the source file). The "BUILD 4A.3" QA label on Main Menu and
Settings was updated in place to "L3 FIX BUILD" (same bottom-right
position, same purpose - build identification is still present, not
removed).

**Not resolved this pass:** if Level 3 still fails on the user's actual
device with this build, the debug overlay's on-device reading is now the
next piece of evidence needed - specifically whether `Moves` reaches 2
and `A`/`B` reach `BACKSLASH`/`BACKSLASH` (proving input digitizer and
click routing work and the bug is downstream, e.g. `Solved` visually
lagging) or whether `Moves` does something unexpected like incrementing
by 2 per tap (would indicate a genuine Android-only double-fire that
neither this machine's desktop test nor headless testing can reproduce).

## Milestone 4A.3 — Runtime Truth Audit + Build Identity + Screenshot Validation (2026-09-18)

Milestone 4A.2 **failed manual QA a third time**, reporting the exact
same symptoms (Level 3 uncompletable, UI squeezed) that Milestone 4A.2's
own changes were supposed to have fixed. This milestone is an audit, not
a re-fix: determine why the reported build didn't match the claimed
fixes before touching any more code. See `DECISIONS.md`'s "Milestone
4A.3" section (D44-D47) for full reasoning.

### Audit findings

1. **No duplicate project or APK found** on this machine - exactly one
   `beam-shift` project directory, exactly one `beamshift-debug.apk`.
2. **File timestamps confirmed the previous APK genuinely contained the
   Milestone 4A.2 fixes** - every relevant source file's edit timestamp
   (18:03-18:08) predates the APK's build timestamp (18:13).
3. **A real gap found and fixed**: `export_presets.cfg`'s Android
   `version/code`/`version/name` had never changed from the project
   template defaults (`1`/`"1.0"`) across Milestones 4A/4A.1/4A.2 - a
   same-versionCode reinstall can silently leave a device on a stale
   build depending on the install method.
4. **Discovered non-headless screenshot capture works on this machine**
   (real GPU, D3D12) - never attempted in any prior visual-integration
   milestone, which had assumed "cannot visually verify" was a hard
   environment limit. Captured and personally inspected real rendered
   screenshots of Main Menu, Level Select, Level 3 (initial and solved
   via a real simulated click sequence), Pause, Settings, and Level
   Complete - **all matched the intended Milestone 4A.2 design**, none
   reproduced the reported symptoms.
5. **Bonus finding**: with real rendering active, `Input.parse_input_event()`
   correctly dispatches to `Control._gui_input()` (unlike
   `Viewport.push_input()` under `--headless`, which Milestone 4A.2's D40
   found does not) - Level 3 was solved via a genuine simulated click
   sequence on both mirrors, not a bypass, and completed correctly:
   moves counted, target activated, Level Complete popup appeared
   automatically with correct stats.

**Conclusion:** the evidence points to the tested device running a stale
APK build from before Milestone 4A.2's fixes, not a code regression.
This is stated as the most likely explanation given the evidence, not as
certain - there's no way to inspect the user's device from this
environment.

### Fixes / changes made

- `export_presets.cfg` — Android `version/code` bumped `1 → 5`,
  `version/name` set to `"1.0.0-4A.3"`.
- `scenes/ui/main_menu.tscn`, `scenes/ui/settings_menu.tscn` — added a
  small, low-opacity **"BUILD 4A.3"** label (bottom-right corner) so a
  physical device tester can visually confirm which build is installed.
  **Temporary, QA-only - must be removed before any real release.**

### New validation techniques added (see `TEST_PLAN.md` for full detail)

- **RENDERED screenshot capture** — a new validation tier, distinct from
  AUTOMATED (headless script checks) and MANUAL (the user's own review).
  Documented as a runnable technique for future sessions.
- **Real click-driven testing** via `Input.parse_input_event()` under
  non-headless rendering - a genuine alternative to the
  direct-method-call bypass used since Milestone 4A.1, when a real GUI
  input test is needed.
- **Build-identity audit** (duplicate-project search, file-timestamp
  comparison, version-code check) as a first step whenever a "the fix
  isn't in my build" report arrives.
- **Three-tier validation vocabulary** (AUTOMATED / RENDERED / MANUAL) -
  every validation claim in this project's docs must now use one of
  these three labels and must never present a lower tier as a higher one.

### Validation performed

- **AUTOMATED:** full headless re-import (zero errors); all 15 levels
  re-verified via both the solver-vs-declared check and the
  runtime-vs-solver replay - unaffected, all PASS (no simulation code
  touched this pass); responsive rectangle validation re-run at the 4
  required resolutions for Game/Pause/Level Complete/Settings - all
  PASS, zero bounds/overlap/touch-target findings; fresh Android debug
  APK exported after deleting the previous one - zero errors, manifest
  re-confirmed `versionCode='5'`, `versionName='1.0.0-4A.3'`.
- **RENDERED:** see "Audit findings" above - all 7 required screens
  captured and personally inspected, matching the intended design.
- **MANUAL — not performed, and must not be marked done:** nobody has
  installed the fresh, version-bumped APK on a real device yet. Per the
  correction brief, **only the user can approve Milestone 4A.3** -
  specifically, only after confirming "BUILD 4A.3" is visible (proving
  the install actually updated) and then testing Level 3/the UI for
  real. Do not mark this milestone approved in any document.

## Milestone 4A.2 — Level 3 Gameplay Fix + UI Scale Correction (2026-09-18)

Milestone 4A.1 **failed the user's second manual QA** on the actual
Android/desktop build, with two unrelated problems: (A) Level 3 could
not be completed in real gameplay, and (B) Pause/Settings/Level Complete
content remained visually squeezed. See `DECISIONS.md`'s "Milestone
4A.2" section (D40-D43) for the full root-cause reasoning.

### Part A: Level 3 root cause and fix

**Root cause:** `mirror.gd`'s texture-rotation mapping (introduced in
Milestone 4A) was backwards - the unrotated source art shows the "/"
(SLASH) shape, but the code mapped unrotated to BACKSLASH and rotated-90°
to SLASH. `LaserSystem`/`GridTypes.reflect()`/`LevelSolver` were never
affected (they only ever read the logical `orientation` value, never
"what a tile looks like"), so puzzle logic was correct the whole time -
but the mirror's own drawn diagonal contradicted the real (correctly
simulated and rendered) beam, making an already-slightly-non-obvious
2-move solution look broken/impossible to a real player.

**Diagnosis performed, in order:**
1. Replayed the solver's exact 2-move solution for Level 3 through a real
   `GridManager._on_orientable_tile_clicked()` call sequence - confirmed
   `is_solved` becomes `true`, target activates, reset restores correctly.
   This ruled out `LaserSystem`/target-detection/reset as the cause.
2. Attempted to reproduce the bug via a real `InputEventMouseButton`
   dispatched at the mirror's exact `get_global_rect()` center - never
   reached `MirrorTile._gui_input()` (confirmed with a temporary debug
   print, since removed). Traced to a **Godot `--headless`-mode
   limitation** (no real `DisplayServer` backing GUI input dispatch), not
   a real bug - now documented in `CLAUDE.md` rule 12a so it isn't
   re-discovered the hard way again.
3. Opened `bs_tile_mirror.png` directly and compared its unrotated pose
   against the pre-Milestone-4A procedural mirror code's SLASH/BACKSLASH
   line-drawing convention - confirmed the rotation mapping was inverted.

**Fix:** one line in `scripts/gameplay/mirror.gd` - the rotation angle
condition was flipped to match the verified convention (unrotated =
SLASH, 90° = BACKSLASH).

### Part A6: new validation layer

Added a runtime-vs-solver cross-validation technique (see `TEST_PLAN.md`
for the exact runnable script): for every one of the 15 levels, take
`LevelSolver`'s own found solution path and replay it through a real
`GridManager` (not `LaserSystem` in isolation), asserting `is_solved ==
true`. This is the check that would have caught D40's bug, since it
exercises the same code path `_on_orientable_tile_clicked()` a real tap
uses, one level below the actual `_gui_input()` hop (which can't be
tested headlessly - see above). All 15 levels pass after the fix.

### Part B: UI scale correction

Settings/Pause/Level Complete content was resized independently of their
panel art (see `DECISIONS.md` D42 for the "decorative panel vs. content"
architecture principle) - not just re-measuring panel margins like
Milestone 4A.1 did:
- **Settings** (`settings_menu.tscn`): panel width 780→900; Sound/Music
  label font 28→38; toggle switch 240×120→300×150; Back button
  120→148px height, font 26→32; row/section separation increased.
- **Pause** (`pause_menu.tscn`): panel width 640→780; all 5 buttons
  116→148px height, font 26→32; separation 18→26.
- **Level Complete** (`level_complete_popup.tscn`): panel width
  760→880; stars 56→84px; Moves/Best Moves font 22/20→32/28; buttons
  116→140px height, font 24→30.
- **Gameplay HUD** (`game.tscn`): `LevelLabel` font 24→28, `MovesLabel`
  font 22→26, all 4 HUD icons' visual size 64→76px - touch targets
  (144px) and bar height (160px) intentionally unchanged, per the
  explicit instruction not to return to Milestone 4A's oversized-icon
  problem.

### Part B8: responsive rectangle validation

Built a lightweight validation tool (`scripts/debug_driver_temp.gd`,
temporary - see `TEST_PLAN.md` for the technique to recreate it) that
measures real `Control.get_global_rect()` values for key controls across
5 target resolutions (720×1280, 1080×1920, 1080×2160, 1080×2400,
1600×2000) and asserts: within logical canvas bounds, ≥96px touch
targets, no HUD/grid overlap. First attempt compared against raw
physical pixels and produced false failures; corrected to compare
against `get_viewport().get_visible_rect().size` (the actual logical
canvas Controls live in, per this project's `canvas_items`/`expand`
stretch mode) - see `DECISIONS.md` D43. All 5 resolutions pass after the
correction, including confirming the puzzle grid's screen-area fraction
correctly *grows* on taller aspect ratios (0.667 at 1080×1920 up to
0.730 at 1080×2400).

### Files modified

- `scripts/gameplay/mirror.gd` — rotation angle mapping fixed (the Level
  3 root cause)
- `scenes/ui/settings_menu.tscn` — larger panel/toggle/label/button sizing
- `scenes/ui/pause_menu.tscn` — larger panel/button sizing
- `scenes/ui/level_complete_popup.tscn` — larger panel/star/stat/button
  sizing
- `scenes/gameplay/game.tscn` — larger HUD label fonts and icon visual
  size (touch targets/bar height unchanged)

### Validation performed

- **Automated:** full headless re-import (zero errors); all 15 levels
  re-verified via `LevelSolver` (unaffected - this was a rendering-only
  fix); **new** - all 15 levels' solver solutions replayed through a real
  `GridManager`, confirming `is_solved == true` for every one (this is
  the check that would have caught the Level 3 bug, now part of the
  regression routine - see `TEST_PLAN.md`); `game.tscn`/
  `settings_menu.tscn` re-booted with real autoloads, zero errors;
  responsive rectangle validation passed at all 5 target resolutions;
  Android debug APK re-exported successfully.
- **Manual — not performed, and must not be marked done:** nobody has
  played Level 3 (or looked at the resized popups) on a real
  device/desktop yet. Per the correction brief, **only the user can
  approve Milestone 4A.2** - do not mark it approved in any document.

## Milestone 4A.1 — UI Integration Correction Pass (2026-09-18)

**Milestone 4A FAILED the user's manual visual QA.** Reported verdict:
"large raw PNGs were placed into scenes without properly designing the
controls around the artwork" - 14 specific observed problems, most
severely a Reset button icon rendering large enough to cover most of the
puzzle board. This milestone is a targeted correction, not new content:
no gameplay, campaign, or art-asset changes - see `DECISIONS.md`
"Milestone 4A.1" (D37-D39) for full root-cause analysis and reasoning.

**Method change from Milestone 4A:** every asset touched this pass was
opened and visually inspected directly (via the `Read` tool's image
support) before any layout decision was made, rather than reasoning
about likely proportions from filenames/survey descriptions. This is
what surfaced both root causes below.

### Root causes found

1. **`Button.icon` renders at native PNG resolution with no size cap.**
   `bs_ui_icon_reset.png` is 1254×1254; set directly as `Button.icon`
   with no `expand_icon`/`icon_max_width`, it rendered at ~1254px inside
   a 144px-tall button, overflowing massively - this is the "Reset
   graphic is enormous" bug, and its cascading effect on container
   minimum sizes is also most of the "HUD artwork overlaps the playable
   area" bug. See `DECISIONS.md` D37.
2. **Three panels have their screen title baked into the art itself**
   (Pause, Settings, Level Complete each already render "PAUSE"/
   "SETTINGS"/"LEVEL COMPLETE" as part of the PNG). Milestone 4A also
   drew a second, dynamic `Label` with the same text, using a flat 40px
   inner margin that didn't clear the baked header - hence "overlapping
   decorative artwork, title, labels and controls." See `DECISIONS.md`
   D38.
3. Buttons and panels were 9-sliced using margins guessed from filenames/
   proportions (Milestone 4A's D36), not measured against the actual
   art - which has ~20% transparent glow padding on the button textures
   specifically, undersized further by too-small overall button
   dimensions on a 1080-wide reference. See `DECISIONS.md` D38.
4. The Settings Sound/Music toggle art (`bs_ui_toggle_on/off.png`) is a
   wide pill graphic with "ON"/"OFF" baked into it - Milestone 4A used it
   as a `CheckButton` icon override, which renders it at checkbox-glyph
   scale, illegible and mis-proportioned. See `DECISIONS.md` D39.

### UI scenes/scripts modified

- `themes/beamshift_theme.tres` - button textures now use
  `StyleBoxTexture.region_rect` to crop out transparent padding before
  9-slicing; margins re-tuned to the cropped region; added
  `font_outline_color`/`outline_size` on `Label`/`Button` for contrast;
  added a defensive `icon_max_width` on `Button` project-wide.
- `scenes/gameplay/game.tscn` - every HUD button (Back/Reset/Pause/Hint)
  rebuilt as a fixed 144×144 touch target containing one fixed 64×64
  icon `TextureRect` (was: raw `Button.icon` at native resolution);
  `TopBar`/`BottomBar` given an explicit `custom_minimum_size.y = 160` so
  bar height is asserted, not derived from content.
- `scenes/ui/main_menu.tscn` - button group enlarged and given a clear
  primary/secondary/danger size hierarchy (Play 640×156, Continue/
  Settings 560×132, Quit 420×112); logo pinned near the top and the
  button group near the bottom (a flexible spacer between them) instead
  of one dead-centered group, to avoid the background art's bright
  central focal point and baked flavor text.
- `scenes/ui/level_select.tscn`, `scenes/ui/level_button.tscn` - cards
  fixed at 240×253 with shrink (not expand-fill) size flags, wrapped in a
  `CenterContainer` for even side gutters, a 48px bottom spacer added so
  the last row isn't flush against the screen edge;
  `NumberLabel`/`StarsRow` anchors re-positioned to the card art's actual
  two zones (large upper area, lower notch tab).
- `scenes/ui/pause_menu.tscn`, `scenes/ui/level_complete_popup.tscn` -
  removed the duplicate title `Label` (redundant with baked art); panel
  `StyleBoxTexture` margins re-measured against the actual art.
- `scenes/ui/settings_menu.tscn`, `scripts/ui/settings_menu.gd` - removed
  the duplicate title `Label`; replaced both `CheckButton` toggles with a
  `toggle_mode` `Button` + child `TextureRect` showing the real toggle
  art at a legible size (240×120); panel margins re-measured.

### Fixes

- Reset (and every other HUD icon) rendering at native PNG resolution,
  catastrophically overlapping the puzzle board.
- Duplicate/overlapping titles and cramped controls on Pause, Settings,
  and Level Complete.
- Main Menu buttons too small and centered on the background's brightest
  focal point.
- Level Select cards inconsistent size, uneven spacing, bottom row not
  fully reachable by scroll.
- Settings toggle art displayed illegibly small.

### Validation performed

- **Automated:** full headless re-import (zero errors); all 15 levels
  re-verified via `LevelSolver` (identical to Milestone 4A and 4/2/1 -
  simulation code untouched this pass); `game.tscn`, `settings_menu.tscn`,
  and `level_select.tscn` each booted headlessly with real autoloads (via
  the documented temporary `run/main_scene` swap, reverted immediately
  after each) with zero script errors; Android debug APK re-exported
  successfully.
- **Manual — not performed, and explicitly must not be marked done:**
  nobody has looked at this correction pass rendered for real yet. Per
  the user's explicit instruction, **only the user can approve Milestone
  4A.1** after reviewing screenshots or a device build - do not mark it
  approved in any document.

## Milestone 4A — Final Asset Integration (2026-09-18)

The user's kickoff called this "Milestone 4A"; content-wise it's
`ROADMAP.md`'s Milestone 5 (final visual assets/UI polish/VFX), done
before Milestone 4's 100-level campaign at the user's explicit request,
minus audio (no audio assets were provided). Scope was strictly visual —
no puzzle logic, no optimal-move counts, no save format, no progression
rules were touched. See `ARCHITECTURE.md` "Final asset integration" and
`DECISIONS.md` D31-D36 for full reasoning.

### Files created

**Theme**
- `themes/beamshift_theme.tres` — shared project-wide Button/Label theme

**Pause menu (new feature, explicitly requested)**
- `scenes/ui/pause_menu.tscn`
- `scripts/ui/pause_menu.gd`

### Files modified

**Gameplay tile visuals** — 5 of 10 converted from procedural `_draw()`
to final generated art (`draw_texture_rect()` inside `_draw()`, layered
correctly with any overlay — see `DECISIONS.md` D32); the other 5 are
unchanged (kept procedural — every available generated asset for them
bakes in a fixed-direction/color illustrative beam, see D31):
- `scripts/gameplay/tile_visual.gd` — base `_draw()` now paints the
  shared cell-background texture instead of a flat color rect
- `scripts/gameplay/mirror.gd` — final art, 90°-rotated per orientation,
  tinted when fixed, lock-icon overlay, tap pulse Tween
- `scripts/gameplay/target.gd` — final art, tinted active/inactive,
  dimmed when optional, activation pulse Tween, colored ring overlay
  unchanged (still procedural — per-level color, no art equivalent)
- `scripts/gameplay/blocker.gd` — final art, no state
- `scripts/gameplay/gate.gd` — final art, swaps open/closed texture
- `scripts/gameplay/hazard.gd` — final art, tinted when triggered
- `scripts/gameplay/portal.gd` — unchanged body, added a continuous idle
  pulse animation (`_process()`)
- `scripts/gameplay/emitter.gd`, `splitter.gd`, `switch.gd`, `filter.gd`
  — **not modified** (see above)
- `scripts/gameplay/grid_manager.gd` — added a `_background_root` layer
  filling every empty grid cell with the shared background texture
  (previously only occupied cells had any background); laser `Line2D`
  rendering tuned for a brighter core + rounder joins/caps/antialiasing
  (beam **data** — path/color/segments — untouched)

**UI scenes/scripts**
- `scenes/ui/main_menu.tscn` — background + logo art; buttons now themed
  automatically (no per-node changes needed); Quit uses the theme's
  `DangerButton` variation
- `scenes/ui/level_select.tscn` — background art
- `scenes/ui/level_button.tscn`, `scripts/ui/level_button.gd` — rewritten
  from `Button.text` composition (including Unicode star glyphs) to a
  state-swapped background texture + dynamic number `Label` + 3 star
  `TextureRect`s
- `scenes/ui/settings_menu.tscn` — panel art, toggle icons on the
  existing `CheckButton`s (no save-format change)
- `scenes/ui/level_complete_popup.tscn`, `scripts/ui/level_complete_popup.gd`
  — panel art, star icons replacing Unicode glyphs, new Best Moves row
  (star/move **calculation** itself untouched)
- `scripts/gameplay/game.gd` — `_on_level_solved()` now also passes
  `SaveManager.get_best_moves()` to the popup; Pause menu wiring; new
  `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` handler
- `scenes/gameplay/game.tscn` — background art, top/bottom HUD frame art,
  Back/Reset/Pause icons, new (hidden) Hint button, new `PauseMenu`
  instance, root `process_mode` set to `ALWAYS` for pause support
- `scripts/ui/main_menu.gd`, `scripts/ui/level_select.gd`,
  `scripts/ui/settings_menu.gd` — each added a
  `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` handler replicating
  its own Back/Quit button, needed once `quit_on_go_back` was disabled
  project-wide (see below)

**Config**
- `project.godot` — `config/icon` now points at `bs_app_icon.png` (was
  the stock Godot icon); added `[gui] theme/custom`; added
  `config/quit_on_go_back=false` (see `DECISIONS.md` D34)
- `export_presets.cfg` — `launcher_icons/main_192x192`/
  `adaptive_foreground_432x432` now point at `bs_app_icon.png`;
  `exclude_filter` extended to drop the unused duplicate art set and 3
  orphaned icon files from the APK (see `DECISIONS.md` D31)
- 3 background `.png.import` files switched from `Lossless` to `VRAM
  Compressed` (memory optimization for full-screen art specifically —
  UI/icon/gameplay-piece textures were deliberately left `Lossless` for
  sharpness, see `ARCHITECTURE.md`)

### Systems added

- Project-wide `Theme` resource (buttons, `DangerButton` variation)
- Pause menu (new — didn't exist before this milestone)
- Android system back-button handling during gameplay (previously
  unhandled and would silently quit the app)
- Lightweight interaction feedback: mirror tap pulse, target activation
  pulse, portal idle glow

### Fixes

- Android back button silently exiting the app during gameplay (no
  handler existed anywhere before this milestone).

### Deliberately not done this milestone

- Stage Select screen (assets present, unwired — no existing screen/
  script to re-skin; building one is new navigation-flow feature work,
  see `DECISIONS.md` D33)
- A real Hint system (button present, hidden — no hint logic exists
  anywhere in gameplay code; inventing one wasn't requested)
- Audio (no audio assets were provided)
- The 100-level campaign / Milestone 4 (explicitly out of scope, waiting
  on the user's separate approval)

### Validation performed

- **Automated:** full headless re-import (zero errors across every
  rewritten script/scene); all 15 levels re-verified via `LevelSolver`
  after the tile-visual rewrite (declared `optimal_moves` still matches
  the solver's independently-computed value for all 15 — simulation
  logic was never touched, this confirms it wasn't accidentally
  affected); a synthetic scene-level smoke test instantiating the real
  `grid.tscn`, loading the most tile-diverse level (15), clicking an
  orientable tile, and resizing the grid, with zero script errors from
  any of the 5 rewritten tile visuals; `game.tscn`, `level_select.tscn`,
  and `settings_menu.tscn` each booted headlessly with real autoloads
  (via the documented temporary `run/main_scene` swap, reverted
  immediately after each), zero script errors; Android debug APK
  re-exported successfully, manifest re-confirmed (portrait orientation,
  package id, SDK versions, adaptive launcher icon slots populated).
- **Manual — not performed:** nobody has looked at any of the new
  visuals rendered for real, in the Godot editor or on a device. See
  `TEST_PLAN.md`'s Milestone 4A section and `CURRENT_STATUS.md`'s
  "Manual tests still needed" for the full list — nothing here is
  claimed as tested when it wasn't.

## Milestone 3 — Level Editor + Puzzle Validation + Difficulty Tooling (2026-09-18)

The user's Milestone 3 kickoff referenced Milestone 2 as already
established and confirmed on a physical device, giving the go-ahead to
build development tooling on top of it. This entry covers Milestone 3 in
full: a standalone level editor, a real puzzle solver, a structural
validator, design metrics, `.tres` level support, and an editor↔game
playtest hand-off — no puzzle logic, laser simulation, or player-facing
UI was touched.

### Files created

**Tooling core**
- `scripts/tools/level_solver.gd` — BFS puzzle solver
- `scripts/tools/level_validator.gd` — structural validator
- `scripts/tools/level_metrics.gd` — design metrics + difficulty estimate

**Editor**
- `tools/level_editor/level_editor.tscn` — editor scene (static UI shell)
- `tools/level_editor/level_editor.gd` — editor logic (dynamic UI, all interactions)

**Fixtures**
- `levels/editor_fixtures/fixture_invalid_portal.gd`
- `levels/editor_fixtures/fixture_invalid_gate_ref.gd`
- `levels/editor_fixtures/fixture_zero_move.gd`
- `levels/editor_fixtures/fixture_unsolvable.gd`
- `levels/editor_fixtures/fixture_multi_solution.gd`
- `levels/editor_fixtures/fixture_search_limit.gd`

**Reserved for Milestone 4**
- `levels/campaign/README.md` (directory placeholder, no levels yet)

**Documentation**
- `LEVEL_EDITOR.md` — the editor's user/developer guide

### Files modified

- `scripts/resources/level_data.gd` — added `stage`, `developer_notes`,
  `is_campaign_level` metadata fields (all optional, no effect on
  existing levels); added `get_initial_tile_orientations()` and
  `get_rotatable_tiles()` helper methods, used by the solver/validator
  (and available for `GridManager` to adopt later, though it wasn't
  changed this pass to avoid touching a working system without cause).
- `scripts/managers/level_manager.gd` — `get_level()` now delegates to a
  new `load_level_from_path()` static helper that transparently loads
  either `.tres` (already a live `LevelData` instance) or `.gd`
  (a script needing `.new()`).
- `scripts/managers/game_manager.gd` — added the editor-playtest
  hand-off: `is_editor_playtest`, `editor_level_data`,
  `start_editor_playtest()`, `return_to_editor_from_playtest()`,
  `is_editor_playtest_return_pending()`, `take_editor_level_data()`.
  Inert during normal play.
- `scripts/gameplay/game.gd` — `_load_current_level()` and
  `_on_level_solved()`/`_on_back_pressed()`/`_on_level_select_pressed()`
  now branch on `GameManager.is_editor_playtest`: loads
  `editor_level_data` instead of a saved level, skips
  `SaveManager.record_level_result()` entirely (a playtest must never
  touch player save data), shows a preview star count, hides "Next
  Level," and returns to the editor instead of Level Select. All
  branches are no-ops when not in playtest mode - normal play is
  byte-for-byte unchanged.
- `export_presets.cfg` — `exclude_filter` extended to
  `tools/**,scripts/tools/**,levels/editor_fixtures/**` so none of this
  milestone's development tooling ships in the Android build.

### Systems added

- Visual level editor: grid sizing (tested 4x4–9x9), a full tile
  palette with an eraser and select/inspect tool, per-tile-type property
  editing, save/load, validate, solve/analyze, and playtest, all driving
  the same `LevelData`/`TilePlacement`/`LaserSystem` the real game uses
- `LevelSolver`: breadth-first search over the 2^N rotatable-piece
  orientation space, using the real `LaserSystem` to evaluate every
  candidate (no second simulator); reports solvability (with a genuine
  three-way `SOLVABLE`/`UNSOLVABLE`/`UNKNOWN` distinction), optimal move
  count, an example solution path, how many distinct shortest solutions
  exist, and possible decoy pieces
- `LevelValidator`: structural error/warning checks, used to gate Save
  and Playtest
- `LevelMetrics`: tile/mechanic counts plus a transparent, documented,
  explicitly-non-authoritative difficulty estimate
- `.tres` level format support, loaded transparently alongside the
  existing `.gd` levels (not a migration - see `DECISIONS.md` D25)
- Editor↔game playtest round-trip that never touches player save data

### Fixes

None to gameplay - this milestone is additive tooling. (A real level-
authoring bug in Level 15, from Milestone 2, is what the solver's
existence retroactively demonstrates the value of - see
`PROJECT_HANDOFF.md`'s "Known issues" - but that bug was already caught
and fixed during Milestone 2's own validation, before the solver existed
to independently re-confirm it.)

### Validation performed

- **Automated:** full headless re-import (zero errors, 3 new global
  classes registered); all 15 levels re-verified solvable via both the
  existing direct-replay test AND the new independent solver search (two
  methods agreeing); all 6 editor fixtures behave exactly as designed
  (unpaired portal, dangling gate reference, trivial solution,
  unsolvable, multiple solutions, search-limit UNKNOWN-not-UNSOLVABLE); a
  full `.tres` save/load roundtrip confirmed lossless; the real editor
  scene instantiated under a live `SceneTree` with real autoloads (via a
  temporary `run/main_scene` swap - reverted immediately after) and
  driven through its actual UI-triggering methods end-to-end: place
  tiles, edit properties, solve, save, clear, load back, confirm
  validation blocks an invalid save, confirm grid resize preserves
  in-bounds tiles and drops out-of-bounds ones; real project headless
  boot with zero runtime errors; Android debug APK re-exported
  successfully with the new tooling excluded, portrait orientation
  reconfirmed.
- **Manual — not performed:** nobody has opened the editor in the Godot
  editor and used it by hand yet. Explicitly listed as the top priority
  in `TEST_PLAN.md` and `PROJECT_HANDOFF.md` - nothing here is claimed
  as tested when it wasn't.

## Milestone 2 — Advanced Puzzle Mechanics (2026-09-18)

Milestone 1's UI fix passed physical-device re-test and the user gave
explicit approval to continue. This entry covers Milestone 2 in full:
splitters, beam colors, color filters, paired portals, switches/gates,
hazards, multiple targets/emitters, and 10 new test levels — built on a
rewritten multi-beam, multi-pass `LaserSystem`.

### Files created

**Scripts — gameplay (new tile visuals)**
- `scripts/gameplay/splitter.gd`
- `scripts/gameplay/filter.gd`
- `scripts/gameplay/portal.gd`
- `scripts/gameplay/switch.gd`
- `scripts/gameplay/gate.gd`
- `scripts/gameplay/hazard.gd`

**Scenes — tiles**
- `scenes/tiles/splitter.tscn`
- `scenes/tiles/filter.tscn`
- `scenes/tiles/portal.tscn`
- `scenes/tiles/switch.tscn`
- `scenes/tiles/gate.tscn`
- `scenes/tiles/hazard.tscn`

**Level data**
- `levels/level_06.gd` — "Twin Targets" (multiple required targets)
- `levels/level_07.gd` — "Split Path" (splitter)
- `levels/level_08.gd` — "True Color" (colored emitter/target)
- `levels/level_09.gd` — "Recolor" (color filter)
- `levels/level_10.gd` — "Through the Portal" (paired portals)
- `levels/level_11.gd` — "Switch and Gate" (multi-pass switch/gate resolution)
- `levels/level_12.gd` — "Danger Zone" (hazard)
- `levels/level_13.gd` — "Two Sources" (multiple emitters)
- `levels/level_14.gd` — "Convergence" (splitter + color + filter + multiple targets combined)
- `levels/level_15.gd` — "All Systems" (switch/gate + hazard + portal + multiple emitters combined, Milestone 2's challenge level)

### Files modified

**Simulation core**
- `scripts/gameplay/grid_types.gd` — added 6 new `TileType` values
  (`SPLITTER`, `FILTER`, `PORTAL`, `SWITCH`, `GATE`, `HAZARD`), the
  `BeamColor` enum (`WHITE`/`RED`/`GREEN`/`BLUE`),
  `target_accepts_color()`, and `beam_color_to_render_color()`.
- `scripts/gameplay/laser_system.gd` — full rewrite. Single-beam,
  single-pass → multi-beam (explicit work-queue, not recursion),
  multi-pass (`simulate()` for one pass, `simulate_until_stable()` for
  the switch/gate-resolving wrapper). New per-pass result fields:
  `activated_switch_positions`, `activated_gate_ids`,
  `hit_hazard_positions`, `hazard_hit`, `gate_states`. Beam
  representation changed from flat `points` to `segments` (a list of
  polylines, so portal transits don't draw a line across the jump). A
  beam now continues past an activated target instead of stopping there.
  See `DECISIONS.md` D14–D22 for the full reasoning behind each choice.
- `scripts/gameplay/grid_manager.gd` — `mirror_orientations` renamed
  `tile_orientations` (now shared by mirrors AND splitters);
  `_on_mirror_clicked` renamed `_on_orientable_tile_clicked`; added
  instantiation/wiring for all 6 new tile types; beam rendering rewritten
  to draw one `Line2D` pair per beam **segment** (not per beam) and to
  color each by `beam["color"]`; gate/target/switch/hazard visuals now
  update from the simulation result every `_simulate_and_draw()` call.

**Data model**
- `scripts/resources/tile_placement.gd` — added `color`, `required`,
  `pair_id`, `gate_id`, `initial_open_state` fields. The old positional
  `_init(tile_type, position, direction, mirror_orientation, rotatable)`
  constructor was **removed** and replaced with 10 static `make_*()`
  factories (one per tile type) — see `DECISIONS.md` D12.
- `scripts/gameplay/emitter.gd` — added `beam_color` property; body
  color now reflects it (WHITE keeps the original orange for zero visual
  change on Milestone 1 levels).
- `scripts/gameplay/target.gd` — added `required_color` and `required`
  properties; draws an extra color ring for non-WHITE required colors
  and dims optional (non-required) targets slightly. WHITE targets are
  pixel-identical to Milestone 1.

**Level files (migrated to the new factory API — see `DECISIONS.md` D13)**
- `levels/level_01.gd` through `level_05.gd` — every
  `TilePlacement.new(...)` call rewritten as the equivalent
  `TilePlacement.make_*()` call. No tile data changed; re-verified
  solvable identically (see "Validation performed" below).

**Level list**
- `scripts/managers/level_manager.gd` — `LEVEL_PATHS` extended from 5 to
  15 entries. No other change — this is the "adding a level costs one
  array entry" architecture working as designed.

### Systems added

- Multi-beam, multi-pass deterministic laser simulation (see above)
- Splitters (rotatable/fixed, like mirrors, but distinct simulation logic)
- Beam colors as real simulation data (not a visual-only tint) with a
  centralized color-matching rule
- Color filters (unconditional recolor)
- Paired portals with direction/color preservation and fail-safe invalid-
  pairing handling
- Switches + gates with deterministic multi-pass resolution (monotonic
  state change, no oscillation possible) and zero persistent state across
  player moves (derived fresh every simulation call — see `DECISIONS.md`
  D18 for why, and why this makes Reset correct for free)
- Hazards (block solving, never block play)
- Multiple required/optional targets per level
- Multiple emitters per level
- 10 new test levels exercising every mechanic individually plus two
  combined-mechanics challenge levels

### Fixes

- One real level-authoring bug caught by automated testing: Level 15's
  first draft placed a portal exit tile on a different chain's own beam
  path, silently hijacking it. Caught because the automated per-level
  solvability check failed, not because it was manually spotted — fixed
  by relocating the portal tile. See `TEST_PLAN.md`.

### Validation performed

- **Automated:** full headless re-import (zero errors, all 6 new tile
  visual global classes registered); all 15 levels' documented optimal-
  move solutions replay correctly (including the 5 Milestone 1 levels,
  confirming the simulator rewrite preserves backward compatibility);
  every new mechanic unit-tested in isolation with synthetic levels
  *and* spot-checked against the real shipped levels for properties
  beyond solved/unsolved (hazard hit/clear, gate open/closed, switch
  activation, portal segment count); the exact Milestone 1 closed-loop
  geometry re-verified to still trigger loop protection through the
  rewritten simulator; a synthetic Milestone 2 level (splitter + filter
  + color target + switch/gate) driven through the **real** `GridManager`
  scene tree end-to-end, not just `LaserSystem` in isolation; real
  project headless boot with zero runtime errors; Android debug APK
  re-exported with zero errors, portrait orientation reconfirmed.
- **Manual — not performed:** no desktop click-through of any new
  mechanic, and no Android device test of this milestone's build. Both
  are explicitly listed as open in `TEST_PLAN.md` and `PROJECT_HANDOFF.md`
  — nothing here is claimed as tested when it wasn't.

## Milestone 1 — Mobile UI polish (2026-09-18)

Physical Android device testing succeeded for gameplay itself (mirror
rotation, laser simulation, level progression all confirmed working on
device), but surfaced a real usability problem: UI edge-spacing and
button touch-target sizing were both inadequate for comfortable phone
use. This entry is scoped strictly to fixing that — no puzzle logic,
laser simulation, save data, star thresholds, level unlocking, or level
data format was touched.

### Root cause found

This project's UI values were never actually "small numbers that felt a
bit tight" — they were roughly **3x smaller than intended** relative to
real device touch targets, because the project's 1080x1920 reference
canvas approximates a 360dp/3x-density Android screen, making 1 project
UI unit ≈ 1/3 dp. A 64px button was only ~21dp tall (well under the
44-48dp minimum every mobile design guideline recommends); a 24px margin
was ~8dp (imperceptibly thin). This was invisible on desktop because a
mouse pointer has no minimum comfortable size and desktop windows aren't
edge-sensitive. Full reasoning in `DECISIONS.md` D10.

### Files created

- `scripts/ui/ui_constants.gd` (`class_name UIConstants`) — two shared
  constants, `MIN_TOUCH_TARGET` (144) and `BASELINE_MARGIN` (96), both
  derived from the ~3x dp conversion above.
- `scripts/ui/safe_area_margin.gd` (`class_name SafeAreaMargin`, extends
  `MarginContainer`) — applies `BASELINE_MARGIN` on every platform, and
  on Android additionally widens each edge using the real
  `DisplayServer.get_display_safe_area()` OS query when available. See
  `DECISIONS.md` D11.

### Files modified

- `scenes/ui/main_menu.tscn` — wrapped content in `SafeAreaMargin`;
  all 4 buttons raised to 144px minimum height (from 84px).
- `scenes/ui/level_select.tscn` — its `Margin` node now uses
  `SafeAreaMargin` instead of a flat 24px theme override; Back button
  raised to 144x144 (from 96x64), its balancing spacer widened to match
  so "SELECT LEVEL" stays centered.
- `scenes/ui/level_button.tscn` — height raised to 144px (from 140px).
- `scenes/ui/settings_menu.tscn` — wrapped content in `SafeAreaMargin`;
  both `CheckButton`s and the Back button raised to 144px height (from
  64-72px).
- `scenes/gameplay/game.tscn` — its `SafeMargin` node now uses
  `SafeAreaMargin` instead of a flat 24px theme override; Back button
  raised to 144x144 (from 96x64); `MovesLabel` given a matching 144px
  minimum width (right-aligned) so it balances the Back button and keeps
  the Level title genuinely centered instead of drifting toward whichever
  side has less content; Reset button raised to 200x144 (from 160x64);
  `Layout` separation raised from 16 to 20.
- `scenes/ui/level_complete_popup.tscn` — wrapped the popup panel (not
  the full-screen dim overlay, which still needs to cover the whole
  screen) in `SafeAreaMargin`; all 3 buttons (Next Level/Retry/Level
  Select) raised to 144px height (from 64px); inner panel margin raised
  from 32 to 40px.

### Systems added

None beyond the two UI scripts above — this is layout/sizing, not new
gameplay or architecture.

### Fixes

- Insufficient touch-target sizing on every interactive button in the
  game (see "Root cause found").
- Insufficient/flat edge margins on Main Menu, Level Select, Settings,
  gameplay HUD, and the Level Complete popup, replaced with a
  device-aware system that can react to real Android safe-area insets.

### Validation performed

- **Automated:** re-ran the full headless import (zero errors, both new
  global classes `SafeAreaMargin`/`UIConstants` registered correctly);
  re-ran the per-level laser-solvability test (all 5 levels still solve
  in their documented optimal move count — confirms puzzle logic is
  genuinely untouched); re-ran the `GridManager` load/click/solve/
  reset flow test (still passes); re-ran the full project's headless
  boot to Main Menu (zero runtime errors, confirms the new
  `SafeAreaMargin` nodes initialize cleanly even where the Android-only
  code path doesn't execute).
- **Automated:** re-exported the Android debug APK
  (`builds/android/beamshift-debug.apk`) — zero export errors,
  `screenOrientation=1` (portrait) reconfirmed via `aapt2 dump xmltree`.
- **Manual — pending:** installing and re-testing the rebuilt APK on the
  physical Android device to confirm the spacing/touch-target fix
  actually resolves the reported problem, and that the Android-specific
  safe-area-widening code path (untestable on desktop) behaves reasonably
  on real hardware. **Milestone 1 stays open until this passes** — see
  `CURRENT_STATUS.md`.

## Milestone 1 — Android debug build (2026-09-18)

Desktop manual testing passed (user-confirmed: Main Menu, Level
Selection, gameplay, mirror interaction, laser simulation, level
progression, portrait layout — no blocker). This entry covers preparing
and validating an Android debug export, per explicit scope: Android
validation only, no Milestone 2 work.

### Files created

- `export_presets.cfg` — one preset, "Android Debug" (package
  `com.beamshift.game`, `arm64-v8a` only, min SDK 24 / target SDK 36,
  legacy non-Gradle build, debug-signed).
- `builds/android/beamshift-debug.apk` — exported debug build (~28.4 MB,
  git-ignored, not part of the repo — regenerate via the export command
  in `PROJECT_HANDOFF.md`).

### Files modified

- `project.godot`:
  - Added `rendering/textures/vram_compression/import_etc2_astc=true` —
    required by Godot's Android exporter; without it, export fails
    outright with an explicit configuration error (caught immediately,
    not a silent issue).
  - Changed `display/window/handheld/orientation` from the string
    `"portrait"` to the integer `1`. **This was a real, previously
    undetected bug**: the string value doesn't match the property's
    actual type (an int enum), so it silently fell back to the default
    (`0` = landscape) with no warning from the editor or from desktop
    testing (desktop windows aren't orientation-locked, so this never
    surfaced there). Only caught by exporting an Android build and
    inspecting the generated `AndroidManifest.xml` directly with `aapt2
    dump xmltree`, which showed `screenOrientation=0` before the fix and
    `screenOrientation=1` after.
- `.gitignore` — added `/builds/` (exported build artifacts aren't
  source and shouldn't be tracked).
- `CURRENT_STATUS.md`, `PROJECT_HANDOFF.md`, `TEST_PLAN.md` — updated to
  record the desktop pass and the Android export/build status (see their
  own diffs for detail; not repeated here).

### Systems added

None — no gameplay/architecture changes. This was export configuration
only, as scoped.

### Fixes

- Portrait orientation bug described above (`project.godot`'s
  `display/window/handheld/orientation`). This bug existed since
  Milestone 1's initial implementation but was undetectable on desktop —
  worth noting in case any other `[display]` settings in `project.godot`
  were also written with a string where Godot expects an int; none other
  were found on inspection, but this class of mistake (a plausible-
  looking string value for what's actually a raw enum int) is easy to
  reintroduce if `project.godot` is hand-edited again rather than
  through the editor's Project Settings UI.

### Validation performed

- **Automated:** Android Debug export completed with zero errors,
  producing a signed, aligned APK. The exported `AndroidManifest.xml`
  was inspected with `aapt2 dump xmltree`/`dump badging` (not just
  trusted from the export succeeding) and confirmed correct package id,
  min/target SDK, architecture, and — after the fix above — portrait
  orientation. Re-ran the full headless import (`--headless --import`)
  after the `project.godot` changes to confirm no regression.
- **Manual — pending:** Installing and running the APK on a physical
  Android device. Not performed in this session (out of scope — the
  brief explicitly says to export the build and stop, not to test it).
  See `TEST_PLAN.md`'s "Android device test" section for exactly what to
  check once the user installs it.

## Milestone 1 — Core Prototype (2026-09-18)

Initial implementation. The project started as a blank Godot 4.7
"Mobile" template (`project.godot`, `icon.svg`, no scenes/scripts) —
everything below is new.

### Files created

**Config**
- `project.godot` — modified in place: added `run/main_scene`, the
  `[autoload]` section (SaveManager, LevelManager, GameManager), and
  `[display]` portrait/viewport settings (1080×1920 reference,
  `canvas_items`/`expand` stretch, `handheld/orientation="portrait"`).

**Scripts — managers (autoloads)**
- `scripts/managers/save_manager.gd`
- `scripts/managers/level_manager.gd`
- `scripts/managers/game_manager.gd`

**Scripts — gameplay**
- `scripts/gameplay/grid_types.gd`
- `scripts/gameplay/laser_system.gd`
- `scripts/gameplay/grid_manager.gd`
- `scripts/gameplay/tile_visual.gd`
- `scripts/gameplay/emitter.gd`
- `scripts/gameplay/mirror.gd`
- `scripts/gameplay/target.gd`
- `scripts/gameplay/blocker.gd`
- `scripts/gameplay/game.gd`

**Scripts — resources**
- `scripts/resources/level_data.gd`
- `scripts/resources/tile_placement.gd`

**Scripts — UI**
- `scripts/ui/main_menu.gd`
- `scripts/ui/level_select.gd`
- `scripts/ui/level_button.gd`
- `scripts/ui/settings_menu.gd`
- `scripts/ui/level_complete_popup.gd`

**Scenes**
- `scenes/ui/main_menu.tscn`
- `scenes/ui/level_select.tscn`
- `scenes/ui/level_button.tscn`
- `scenes/ui/settings_menu.tscn`
- `scenes/ui/level_complete_popup.tscn`
- `scenes/gameplay/game.tscn`
- `scenes/gameplay/grid.tscn`
- `scenes/tiles/emitter.tscn`
- `scenes/tiles/mirror.tscn`
- `scenes/tiles/target.tscn`
- `scenes/tiles/blocker.tscn`

**Level data**
- `levels/level_01.gd` — "First Light" (optimal 1 move)
- `levels/level_02.gd` — "Reflection" (optimal 2 moves)
- `levels/level_03.gd` — "Obstruction" (optimal 2 moves)
- `levels/level_04.gd` — "Fixed Point" (optimal 2 moves)
- `levels/level_05.gd` — "Three Turns" (optimal 3 moves)

**Documentation**
- `CLAUDE.md`, `README.md`, `PROJECT_HANDOFF.md`, `ROADMAP.md`,
  `DECISIONS.md`, `ARCHITECTURE.md`, `TEST_PLAN.md`, `CHANGELOG.md`
  (this file), `CURRENT_STATUS.md`, `NEXT_CLAUDE_PROMPT.md`

### Systems added

- Deterministic grid-based laser simulation with centralized reflection
  rules and beam-loop protection (`GridTypes`, `LaserSystem`)
- Full puzzle gameplay loop: mirror rotation (tap/click, touch and mouse
  share one input path), target activation, blocker stopping, move
  counting, reset-from-data, level completion
- 3/2/1-star rating (deterministic thresholds, see `DECISIONS.md`)
- Local JSON save with best-result preservation and sequential unlocking
- Main Menu, Level Select (dynamically built, scales toward ~100 levels),
  Settings screen, Level Complete popup — all Control/anchor/container-
  based for responsive layout
- Responsive square-grid layout that recomputes on resize
  (`GridManager._recalculate_layout()`)

### Fixes

N/A — this is the initial implementation; nothing was being fixed.

### Validation performed

See `TEST_PLAN.md` for the full breakdown. Summary: headless import is
clean; all 5 levels' documented solutions were automatically replayed
against the real simulation code and confirmed correct; loop protection
was automatically verified with a synthetic closed-loop level; the actual
project boots headlessly with zero runtime errors. UI interaction, visual
correctness at various screen sizes, save-file persistence across
launches, and anything requiring a real Android device are marked
`MANUAL TEST REQUIRED` and have not yet been performed.
