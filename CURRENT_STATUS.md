# CURRENT_STATUS.md

Fast snapshot. If this disagrees with `CHANGELOG.md`/`ARCHITECTURE.md`,
trust the code, then fix whichever doc is stale.

## CURRENT STATUS (authoritative — read this section for "what's true right now")

Everything below this section (from "## MILESTONE HISTORY" onward) is
**historical** — chronological record of how the project got here, kept
for context, not a source of current facts. If anything further down
ever disagrees with this section, **this section wins**; fix the stale
part below instead of trusting it.

## CURRENT DEVELOPMENT PHASE (2026-09-25, S3.1 final verification)

**S3.1 READY FOR MANUAL APPROVAL - V5 J/K DIFFICULTY REFINEMENT (Levels 2601-3000).** Continuation prompt: `NEXT_AI_PROMPT.md` (tool-independent; preferred). Branch `dev_abhilas`, HEAD `36fc104`; **nothing from S1/S2/S3/S3.1 is committed**.

- **S1: COMPLETE** (Splitter Selector runtime + 6 SELECTOR TEST puzzles).
- **S2: COMPLETE** (tutorials T29-T34; T29 unlocks at procedural Level 1900).
- **S3: IMPLEMENTED / DESKTOP S3.1 VERIFIED / AWAITING MANUAL APPROVAL** (generator V5, Levels 2001-3000, `MAX_LEVEL` 3000 = current boundary). Works: generation, 2000->2001, V1-V4 fingerprint unchanged, Selector frequency targets, Save/Continue, Hint, stars, QA +50 through 3000. S3.1 final verification completed split deterministic J/K windows: J 50/50 generated, `band_demoted=4` (8.0%); K 50/50 generated, `band_demoted=0` (0%). Exact optimum UNKNOWN, phone readability and Android generation time remain unmeasured - see `NEXT_AI_PROMPT.md`.
- **S4: NOT STARTED** (Android APK) - only after S3.1 and the user's manual approval of the difficulty.
- `export_presets.cfg` shows `version/code=69`, `4.8.3-OFFICE-BRANCH-QA`: a PRE-EXISTING modification, not from S1/S2/S3; no version bump was made by them.

**S3.1 pass 1 changes/measurements (Codex, 2026-09-25):** added S-M (`Selector -> target continuation`) using the existing `TM`/`target` site, added S-M to J/K selector pools, raised `MAX_ATTEMPTS_V5` to 64, kept J demotion at 32 attempts, and gave K a 48-attempt strict runway before band demotion. Pre-change baseline reproduced with `hist=1`: J 36/50 generated before 55s budget, `band_demoted=20`; K 30/50 generated before 55s budget, `band_demoted=22`. Post-change (`budget=90000`): J 36/50 generated, `band_demoted=3` (8.3%); K 37/50 generated, `band_demoted=0`; 0 fallbacks, greedy accepted 0 in both. V1-V4 fingerprint before/after: `271eb766be20a12446676a947b49a3f1`.

**S3.1 final verification (Codex, 2026-09-25):** no generator redesign or target loosening. Split deterministic windows covered 50 levels per band under bounded per-process budgets. J: 50/50 generated, 4 demoted (8.0%), shortcut rejections 5, minimality rejections 3, greedy accepted 0/50, fallbacks 0, avg gen 1950.1 ms, max 3522 ms. K: 50/50 generated, 0 demoted, shortcut rejections 6, minimality rejections 17, greedy accepted 0/50, fallbacks 0, avg gen 2551.6 ms, max 5383 ms. QA budget root cause is dev-only verification overhead: final shortcut probe dominates, followed by repeated build/probe/minimality/check work from rejected candidates. Targeted late-game QA: use 2500, 2647 (nearest Selector-bearing replacement for non-Selector 2651), 2800, 2900, 3000. Selector QA passed; Fusion QA set passed via bounded temporary verifier; 2000/2001/3000 boundary and `MAX_COLUMNS=8` reconfirmed. `selector_tutorial_verify`/bounded T29-T34 smoke were attempted but did not complete in the practical headless QA window; prior S2 evidence remains the exhaustive source. S4/APK remains blocked pending manual V5 approval and Android generation/readability checks.

- **SPLITTER SELECTOR PHASE S3 - GENERATOR V5, LEVELS 2001-3000 (IMPLEMENTED / NOT CERTIFIED; uncommitted, no APK; J/K refinement = S3.1 is next)** - `ProceduralLevelGenerator.GENERATOR_VERSION_V5` owns Levels 2001-3000 (`MAX_LEVEL`/`INITIAL_CERTIFIED_LEVEL_TARGET` = 3000, the current boundary, not a ceiling); bands G-K in `ProceduralDifficultyContract`; Selector as a first-class complexity kind (`ProceduralSelectorCheck`), 12 Selector families, `ProceduralMinimality` + final wide shortcut probe, QA entry "V5 TEST" (`ProceduralV5QaSet`). Measured (50-level windows): Selector share G-K 42/50/58/62/71%, 0 fallbacks, but J/K miss their move bands (avg 24.8/25.6) and ~half of J/K levels are `band_demoted`; exact optimum UNKNOWN on every V5 level; generation 1.5-2.3 s desktop (phone unmeasured). V1-V4 fingerprint identical. See `DECISIONS.md` D110 and `PROCEDURAL_GENERATION.md` section 20. Next: S3.1 (J/K difficulty refinement, see NEXT_AI_PROMPT.md); the user plays the V5 TEST levels; only then S4 (Android build).
- **SPLITTER SELECTOR PHASES S1+S2 (uncommitted, no APK yet)** - mechanic SPLITTER_SELECTOR + SELECTOR TEST (D108) and tutorials T29-T34 (D109, unlock at procedural Level 1900, QA opens all). Verified: exhaustive per-board checks, real-flow tutorial run, T01-T28/FUSION TEST regression, V1-V4 fingerprint identical. (Superseded: S3 generator V5 now exists but is NOT certified; S3.1 is next; Android build S4 NOT started.)
- **HINT ATTENTION PULSE (previous) - `versionCode=68`, `4.8.2-HINT-ATTENTION-PULSE-QA` (108,961,246 bytes).** Visual-only repeating cyan pulse on the gameplay Hint button: 5.0 s idle, 0.35 s glow in, 0.20 s hold, 0.45 s glow out, icon scale 1.04, additive halo alpha 0.55 (all in `UIConstants.HINT_*`). Implemented centrally in `game.gd` (`_hint_attention_*`): animates only the `HintIcon` child and one reusable halo `TextureRect` created once (mouse-ignore); a single looping Tween, killed before every replacement. Stops/restarts on Hint press, rewarded ad open/close, level solved, every level load (Reset/Next/Continue/tutorial). A cycle is skipped unless the button is visible/enabled and no popup/pause/ad is showing, and (tutorials) the step allows a hint. Rendered-verified 720x1280: 11 cycles, no layout drift, no node/child growth. Android approval pending. Nothing else touched (HintManager, ads, stars, layout).
- **LEVEL COMPLETE BUTTON FIX (current) - `versionCode=67`, `4.8.1-LEVEL-COMPLETE-BUTTON-FIX-QA` (108,958,142 bytes).** Fixed horizontally-stretched NEXT LEVEL/RETRY/LEVEL SELECT buttons on the Android Level Complete popup: `ButtonRow`'s three `Button` nodes never set `size_flags_horizontal` and had `custom_minimum_size.x = 0`, so Godot's default `FILL` behavior stretched each button's `StyleBoxTexture` art to the full ~812px panel content width instead of its intended proportion. Fix: `size_flags_horizontal = 4` (SHRINK_CENTER) + `custom_minimum_size = Vector2(600, 140)` on all three, matching the same pattern Main Menu/Settings buttons already use. Rendered-verified at 540x960 and 1080x2400 (identical 600x140, ratio 4.2857 on both). Same missing-pattern bug also exists in `pause_menu.tscn` and `tutorial_complete_popup.tscn` (each hand-authored per-scene, not a shared component) - **not fixed here, out of scope for this pass**; a future pass should apply the same fix there if reported. Stars/Moves Used/panel position/HUD/board untouched.
- **NEW GAME FLOW (previous, D107) - `versionCode=66`, `4.8.0-NEW-GAME-FLOW-QA`:** Main Menu PLAY -> NEW GAME (instant on a fresh save, confirmation popup when meaningful progress exists; one atomic reset preserving settings, tutorials and ad cadence). HUD stack calibration unchanged (offset -30, QA cap override on).
- **GAMEPLAY STACK 40 PX DOWN CALIBRATION (previous) (QA, pending Android approval) (current) - `versionCode=65`, `4.7.8-GAMEPLAY-STACK-40DOWN-QA`:** offset -70 -> -30 after a real screenshot showed build 64 too high; QA cap override still on.
- **GAMEPLAY STACK 50 PX DOWN CALIBRATION (previous) (QA ONLY, NOT PRODUCTION APPROVED) (current) - `versionCode=64`, `4.7.7-GAMEPLAY-STACK-50DOWN-QA`:** `GAMEPLAY_STACK_VERTICAL_OFFSET` -120 -> -70 (stack ~50 px above build 62); QA cap override still on. Awaiting Android testing.
- **GAMEPLAY STACK -100 PX (previous, QA TEST ONLY, NOT PRODUCTION APPROVED) (current, D107) - `versionCode=63`, `4.7.6-GAMEPLAY-STACK-100PX-QA`:** `GAMEPLAY_STACK_VERTICAL_OFFSET := -120` (= 100 px above build 62) with `ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET := true` lifting the safe-edge cap (QA builds only). Top HUD plate is ~99 px above the screen edge (partly off-screen) by design of the experiment.
- **GAMEPLAY STACK -20 PX TEST (previous) - `versionCode=62`, `4.7.5-GAMEPLAY-STACK-20PX-QA`:** `GAMEPLAY_STACK_VERTICAL_OFFSET` -8 -> -20 (top gap 0.6 / bottom 40.8 desktop). Awaiting Android screenshot.
- **GAMEPLAY STACK SHIFT (previous, D106) - `versionCode=61`, `4.7.4-GAMEPLAY-STACK-CENTER-QA`:** whole HUD/board/HUD stack moved up (offset -8 canvas px + automatic inset-asymmetry balance, clamped at the safe edge). Awaiting a real Android screenshot for tuning.
- **HUD SYMMETRIC GAP (previous, D105) - `versionCode=60`, `4.7.3-HUD-SYMMETRIC-GAP-QA`:** top HUD gap matched to bottom (20 px each, ~20.6 vs 20.8 measured). Awaiting Android testing.
- **HUD FINAL POSITION (previous, D104) - `versionCode=59`, `4.7.2-HUD-FINAL-POSITION-QA`:** asymmetric HUD gaps, top 3 px / bottom 20 px inside the safe area (`UIConstants.GAMEPLAY_TOP_VISIBLE_GAP`/`GAMEPLAY_BOTTOM_VISIBLE_GAP`). Awaiting Android testing.
- **HUD EDGE SPACING (previous, D103) - `versionCode=58`, `4.7.1-HUD-EDGE-QA`:** HUD plates now sit 8 px inside the safe area (was ~80 canvas px) via a centralized overhang in `SafeAreaMargin`; board gained ~146 canvas px height; QA mode ON, Google TEST ads. Awaiting Android testing.
- **PHASE 4 (previous, D102) - PRODUCTION CLEANUP, QA build `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA` (108,952,946 bytes).** Centralized star scoring (`StarScoring`: OPTIMAL+2 = 3 stars, +6 = 2, else 1; a granted Hint caps at 2 and persists across Continue; best stars per `level|generator_version`), Level Complete popup shows real stars + "HINT USED", `BuildConfig.IS_PRODUCTION_BUILD` is the single QA/production switch (production simulation verified; QA ON in this build), T21-T28 text polished, one-time "NEW TUTORIAL: FUSION" nudge. Level 2000 remains the certification target. **Awaiting Android testing.** Remaining production items: flip the switch, real AdMob ids, generator rollout flags decision.
- **FUSION NODE PHASE 3 (previous, D101) - PRODUCTION INTEGRATION, QA build.** The user approved Fusion after Android testing of 55: it is now a **production-supported mechanic**. New: the Fusion tutorial pack **T21-T28** (same `TutorialManager`; unlock via `LevelManager.is_fusion_tutorial_selectable()`: T21 at procedural Level 150 or after T20, sequential after, QA flag opens all, never a hard gate, not era-gated), generator-V4 fragment variants (F3 portal_a/portal_out, F4 gate-on-input `FUK`, F5 remote_gate, F6 prism_one, F7 portal), Fusion ablation as a dead-node BLOCKER (fixes false "not load-bearing" rejections; realised Fusion share 14/23/27/20/31/34/22% per band 201-2000, inside every target), new exact shortcut screens (`ProceduralFusionCheck`). Verified: all 8 tutorial boards have one solution, all 28 tutorials replay in the real game scene, 540-level stress 0 problems / 0 fallbacks, 30 levels PROVEN OPTIMAL & unique, Fusion Save/Continue exact, V1-V3 fingerprint-identical, campaign/dev/T01-T20 regression clean. Level 2000 stays the certification target; nothing beyond 2000 exposed; no chained Fusion; no star economy; all QA flags ON; Google TEST ads. Build `versionCode=56`, `4.6.0-FUSION-FULL-QA` (108,948,560 bytes). **Awaiting Android testing** (Tutorial -> T21-T28; PLAY + QA +50 to Level 201+, HUD tag `V4 <band> F#`).
- **FUSION NODE PHASE 2 (superseded by Phase 3 above, D100) - MAIN PROCEDURAL INTEGRATION, QA build.** The user approved the Fusion concept on Android. Generator **V4** (= V3 progression + Fusion fragments F1-F7, unlock table `ProceduralDifficultyContract._FUSION_PROGRESSION`: none in 1-200, F1 from 201, more fragments in later bands; one deterministic roll per level, realised 14-28% per band) is the QA default for new play (`LevelManager.USE_FUSION_PROGRESSION_FOR_QA`); V1/V2/V3 frozen and fingerprint-verified. Every generated node is load-bearing (per-input ablation, colour consumption, no feedback cycle, settles before the pass cap). Level 2000 is the certification target, not a ceiling; nothing beyond 2000 exposed; `MAX_COLUMNS` 8. **Fusion tutorial = release blocker.** Build `versionCode=55`, `4.5.0-FUSION-PROGRESSION-QA` (108,932,092 bytes, Google TEST ads). **Awaiting Android testing** (PLAY + QA +50 to reach Level 201+; HUD tag `V4 <band> F#`).
- **FUSION NODE PHASE 1 (previous, D99) - mechanic + QA puzzles.** Beam Fusion Node combines RED/GREEN/BLUE beams into YELLOW/MAGENTA/CYAN/WHITE. Six QA puzzles via Main Menu "FUSION TEST" / "NEXT FUSION"; Hint-supported;
  ad-free and save-free like V3 TEST. **Not in procedural V3 / campaign; final tutorial pending.** Build `versionCode=54`, `4.4.0-FUSION-NODE-QA` (108,914,289 bytes, Google TEST ads; AdMob test ads were device-verified by the user before this pass).
  **Awaiting Android Fusion testing and approval before any procedural integration.**
- **ADMOB FOUNDATION V1 (previous - Android test ads device-verified by the user, D98, `ADS_MONETIZATION.md`).** Rewarded ad -> one Hint (normal procedural play; granted only from the reward callback, no free
  fallback) and an interstitial every 4 legitimate procedural completions (>= 120 s, at Level Complete -> Next Level, counter resets only on a real show, suppressed on
  a level where a rewarded ad was watched). Tutorials, V3 TEST, QA `+50`, campaign QA are ad-free. `AdManager` autoload over `AdBackend`; Poing AdMob plugin v5.1.0; UMP
  consent every launch. **Google TEST ids only.** Build **`versionCode=53`, `4.3.0-ADMOB-FOUNDATION-QA`** (105,914,950 bytes; Gradle build, JDK 17). Verified with a fake
  backend (35 checks); **real ads/SDK on a device NOT yet verified; iOS prepared, not built.** Release blockers: replace test ids, verify UMP/privacy options, iOS on a Mac.
  **Awaiting Android AdMob testing.**

- **GLOBAL HINT SYSTEM PHASE 1 (previous, D97).** The shared HUD Hint button works in procedural V1/V2/V3
  (+V3 TEST), campaign and tutorials: one press rings ONE required tile from a known solution (generator
  `solution_orientations`; campaign/tutorial from offline-solver `levels/hint_solutions.json`, 160/160 built);
  no runtime solver, no auto-rotate, no move/save/star effect. Build **`versionCode=52`,
  `4.2.1-GLOBAL-HINT-QA`** (79,812,864 bytes). Stars: no hint penalty (pending decision). Rewarded-ad seam
  (`request_hint` vs `grant_hint`) exists, no ads. V3 difficulty unchanged. **Awaiting Android testing;
  Phase 2C not started.**

- **DIFFICULTY SYSTEM PHASE 2B (previous, see `DECISIONS.md` D96,
  `PROCEDURAL_GENERATION.md` section 19).** V3 is now a reusable, dependency-first
  **progression generator** for Levels 1-2000: reusable fragments (Filter, Portal,
  Splitter branch, Gate with own/splitter/prism/shared-mirror/shared-one-way/two-stage
  switch routes, Prism, Receiver->Remote hop, One-Way turn/hold, mid-route target) are
  chosen from per-band pools, laid out by a generic router (no hand-placed
  coordinates) and gated on the band contract (`ProceduralDifficultyContract`, Phase 2B
  targets: e.g. Level 1 = 3 moves, Level 1000 = 12-16 moves/depth 6+, Level 2000 = 20-26
  moves/depth 10+). Latest Android build: **`versionCode=51`,
  `4.2.0-PROCEDURAL-V3-PROGRESSION-QA`** (`builds/android/beamshift-debug.apk`, 786
  entries, 79,804,416 bytes). V3 is selected for NEW procedural play by
  `LevelManager.USE_V3_FOR_PROCEDURAL_QA` (a resumed puzzle keeps its saved
  version: V1/V2/V3 never cross-regenerate); default `GENERATOR_VERSION` is still 2;
  the six prototypes ("V3 TEST"/"NEXT V3") are permanent regression fixtures
  (diffed identical); `+50`, saves, CONTINUE verified end-to-end through the real game
  scene. QA HUD shows `V3 <band>` (or `V3 FAILED>V2`) under the level number.
  Evidence: 25-level sample all pass independent checks; 286 levels sampled across 3-2000:
  0 validator errors, 0 fallbacks; exhaustive solver on ~357 generated levels (1-260,
  401-480, 701-719): 0 shortcuts with the runtime shortcut probe on, optimal == intended;
  1500/1900/2000 solver UNKNOWN (state cap - not unsolvable). Greedy beam-following
  solves 0% of sampled puzzles from Level 201 up. **Not release-certified; no full 1-2000
  audit; stars not finalised.** Known: top-band generation 100-330 ms on desktop (device
  unmeasured); decoy forks/reciprocal dependencies not implemented. **Awaiting Android
  playtest; Phase 2C not started.**

- **Older Android build (superseded by Phase 2A.1 and Phase 2B, see above):** `versionCode=48`, `versionName=
  "4.0.4-UNIFIED-BLUE-QA"`, package `com.beamshift.game`
  (`builds/android/beamshift-debug.apk`) — see this pass's own final
  report for the exact size/entry-count numbers. Previous:
  `versionCode=47` / `4.0.3-MINIMAL-BG-QA`.
- **DIFFICULTY SYSTEM PHASE 2A.1 (superseded by Phase 2B above; see `DECISIONS.md` D95,
  `PROCEDURAL_GENERATION.md` section 18.7).** Phase 2A.1 focuses on reasoning
  depth rather than raw move count: prototypes D, E and F were rebuilt after
  the user found them too easy on Android (A/B/C untouched, diffed identical).
  Each has a globally constrained decision (D shared One-Way + a One-Way that
  must be PASSED; E colour fork with a wrong-colour decoy route; F shared
  One-Way whose pass state lights a second target with the wrong beam) and a
  less self-explanatory start state. D/E/F: 8/11/11 moves, deps 6/5/9, depth
  5/8/9, solver optimal == intended, unique. Latest Android build:
  **`versionCode=50`, `4.1.1-PROCEDURAL-V3-THINKING-QA`**. Known: a greedy
  beam-follower proxy still solves F. **(Android feedback on D/E/F was positive; Phase 2B - see above - followed.)**
- **DIFFICULTY SYSTEM PHASE 2A (previous; D/E/F superseded by 2A.1) (see `DECISIONS.md` D94,
  `PROCEDURAL_GENERATION.md` section 18).** Generator V3 (dependency-first)
  prototype exists and is playable only through the dev-only "V3 TEST"
  selector (`LevelManager.SHOW_V3_PROTOTYPE_QA`); default generator is still
  V2, V1/V2 frozen. Six archetypes pass all gates (8-11 moves, depth 4-9,
  100% meaningful, solver optimal == intended, unique solution). Build
  at that time: **`versionCode=49`, `4.1.0-PROCEDURAL-V3-PROTOTYPE-QA`**.
  **Awaiting manual Android feedback before Phase 2B (scaling V3).**

- **DIFFICULTY SYSTEM PHASE 1 (see `DECISIONS.md` D93,
  `PROCEDURAL_GENERATION.md` section 17).** Permanent principle: a
  procedural puzzle is not accepted solely because it is solvable;
  difficulty = optimal-move requirements AND meaningful reasoning
  complexity. Built: `ProceduralDifficultyContract` (one authoritative
  11-band table), `ProceduralComplexity` (ablation metrics through the
  real `LaserSystem`), `ProceduralTriviality` (`TRIVIAL_*` verdicts),
  `scripts/tools/difficulty_inspect.tscn`. **Generation is unchanged**
  (V1 frozen, V2 default) - the new rules are measured, not yet enforced,
  and no APK was built (`versionCode` still 48). Finding: a 100-level V2
  sample fails the contract 99/100; frozen V1 makes 3-5 move puzzles in
  1801-2000 (1897 = 3 moves). QA button is "+50"
  (`LevelManager.PROCEDURAL_QA_JUMP_AMOUNT`), no-op at 2000. **Phase 2
  (templates that construct dependency chains) awaits user approval.**
  Still-open release blockers: `SHOW_PROCEDURAL_QA_NEXT_BUTTON`,
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`,
  `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` must be `false` for production.

- **UNIFIED BLUE THEME FIX (current, see `DECISIONS.md` D91).**
  BeamShift now uses exactly ONE active gameplay visual theme — the
  existing blue/cyan sci-fi look — across all 2,000 procedural levels,
  the legacy campaign, and every tutorial. `EraTheme.
  UNIFIED_BLUE_THEME_ONLY := true` (`scripts/resources/era_theme.gd`) is
  the single authoritative switch, checked first inside `EraTheme.
  for_era()`, forcing every visual-theme call site (gameplay background/
  grid/HUD, level/tutorial card accent tint, Level Select/Tutorial Select
  background) to always use Era 1's asset set regardless of numeric era.
  Era-band logic that ISN'T about visuals — T11-T20 unlock gating, the
  Level 100→101 transition banner — reads the numeric era directly and
  is completely unaffected; progression/mechanic-teaching order is
  unchanged. Prism/One-Way Reflector/Beam Receiver/Remote Emitter's own
  tile art is genuinely purple-specific and was never routed through
  `EraTheme` to begin with — left as-is per the standing "never generate
  or destructively recolor art" rule, and is now the only visible purple
  element in normal gameplay (small tile icons, not a skin). Purple Era 2
  assets and `_build_era_2()` itself are fully retained, just unreachable
  while the flag is `true`. RENDERED-verified (D45-D47 tier) across
  Campaign Levels 21/99/100/101/102/140, procedural Levels
  200/500/1000/1500/2000, and Tutorials T01/T11/T20 — Level 21 vs. Level
  102 (the key comparison) confirmed visually indistinguishable in
  background/grid/HUD family. Procedural determinism, PLAY/CONTINUE/QA
  Next, and AudioManager (22/22 streams) all re-confirmed unaffected. No
  save schema change. **NOT MANUALLY APPROVED — Android device visual QA
  pending.**
- **MINIMAL GAMEPLAY BACKGROUND PASS (previous, see `DECISIONS.md` D90).**
  The gameplay background (`game.tscn`'s root `Background` `TextureRect`)
  now carries `modulate = Color(0.22, 0.26, 0.38, 1)` — a non-destructive,
  node-level darkening, no PNG edited. Since `game.gd._apply_era_theme()`
  only ever swaps this node's `.texture` (never its `.modulate`), the
  treatment applies uniformly under every Era, current and future,
  Campaign/procedural/tutorial alike, with zero per-level code. HUD, grid
  cell art, tiles, and beams are separate nodes/draws and are
  structurally unaffected — confirmed via direct pixel sampling (a
  HUD-art pixel came back bit-for-bit identical before/after), not just
  visual inspection. RENDERED-verified (D45-D47 tier) at
  720x1280/1080x1920/1080x2400 for Campaign Levels 1/100/102 (Era 2) and
  procedural Level 1000, via a new off-screen `SubViewport` capture
  technique (this machine's physical 2560x1080 monitor silently clamps
  any on-screen portrait window taller than ~1032px, which had been
  quietly reflowing every prior "1080x1920" on-screen capture on this
  machine to a near-square aspect — see D90 for the full finding and the
  reusable fix). **Board-size note (found, deliberately not fixed this
  pass)**: some small boards occupy less of the available portrait
  height at some resolutions — a separate generator/layout-quality task,
  see `CLAUDE.md`'s Procedural generator rules and D90. **NOT MANUALLY
  APPROVED — Android device visual QA pending.**
- **AUDIO/SFX INTEGRATION PASS (previous, see `DECISIONS.md` D89 and
  `AUDIO_SYSTEM.md`).** A centralized `AudioManager` autoload (4th
  autoload) now provides 22 semantic gameplay/UI SFX, sourced from 22
  Kenney-pack `.ogg` files the user staged under `assets/sfx/`. No level
  or scene owns its own `AudioStreamPlayer`; `LevelData`/`TilePlacement`
  carry zero audio fields, so all 2,000 procedural levels get audio
  automatically. Gameplay audio reuses `GridManager._simulate_and_draw()`'s
  existing `play_impacts` gate, so it only ever plays for a genuine
  accepted player move — Continue/resume restoration and the procedural
  generator/solver/audit stay silent by construction. New `Master`/`SFX`/
  `UI` audio buses; Settings' existing Sound toggle now mutes SFX+UI.
  Era 2's four new mechanics reuse existing SFX (no new assets). 3 of the
  22 SFX are registered but deliberately unused (no matching gameplay
  event exists yet). **NOT MANUALLY APPROVED — Android device audio QA
  pending**, on top of the Phase 1-3 layout/navigation/generator passes
  that already await real-device review together (now five consecutive
  unreviewed passes).
- **PROCEDURAL LEVEL GENERATOR V1 (current, see `DECISIONS.md` D88 and
  `PROCEDURAL_GENERATION.md`).** BeamShift's main player-facing
  progression is now procedural: 2,000 deterministic, on-device-generated
  levels (`scripts/procedural/**`), replacing the handcrafted Campaign as
  Main Menu `PLAY`/`CONTINUE`'s target. Full 1-2000 dev-time audit (real
  `LevelSolver`/`LevelValidator`): 0/2000 failures, 0/2000 fallbacks,
  11/11 determinism matches, all 10 templates used. The live/runtime
  generator never calls the dev-only solver/validator (rule 9's Android-
  export boundary is completely untouched) — it self-verifies via a
  direct `LaserSystem` simulation of its own already-known solution
  instead. A temporary QA-only "NEXT" skip button
  (`LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON`) is proven (end-to-end
  runtime test) to never fake a legitimate completion. The legacy
  Campaign (1-140) is unchanged, reachable only via QA Level Select.
  **NOT MANUALLY APPROVED — Android device QA pending**, on top of
  Phases 1-2's own still-outstanding review (four consecutive unreviewed
  layout/navigation/generator passes now await real-device feedback
  together).
- **FINAL GAMEPLAY SPACING REFINEMENT (current, see `DECISIONS.md`
  D87).** The user manually tested `versionCode=43` (D86) on a real
  phone and confirmed the larger-tile layout is "MUCH BETTER... close
  to the desired result" - a final polish pass only, not a redesign:
  move Top/Bottom HUD closer to the screen edge, without touching tile
  size or D86's left/right margin. `SafeAreaMargin.margin_override`
  split into `horizontal_margin_override` (kept at 32px, unchanged) and
  `vertical_margin_override` (new, 8px). **Proved mathematically, not
  just tried**: for a width-bound board (confirmed the common case at
  ≤10 columns on portrait), the vertical margin has ZERO effect on the
  visible HUD-to-board gap — `CenterArea`'s `EXPAND_FILL` sizing plus
  the board's own centering within it makes `total_top_space` algebraically
  independent of both the vertical margin and `VBoxContainer` separation
  (`total_top_space = TopBar.height/2 - BottomBar.height/2 +
  screen_height/2 - board_height/2`). Confirmed by a direct render sweep
  of Level 28 (6x7, the reference level): the HUD bar's own screen
  position moved as expected (32→8px from the edge), but total
  HUD-to-board space stayed exactly 619px at every value tested. **This
  is the honest mathematical limit, not an incomplete fix** — closing it
  further needs different HUD art or a board shape that isn't
  width-bound, both out of scope. Full resolution/profile matrix still
  140/140 comfortable (unchanged — vertical margin doesn't affect cell
  size). Visually confirmed via 6 real rendered levels/tutorial. Full
  regression unchanged: 188/188 PASS; Phase 2 re-check: 12/12 PASS.
  Recorded future-generator guidance: prefer taller board profiles
  (e.g. 5x9, 6x10, 7x11, 8x11) to avoid landing width-bound in the first
  place — the durable fix for new content, not existing levels. **NOT
  MANUALLY APPROVED — Android device QA pending.** Per this pass's own
  STOP CONDITION: do not start the procedural generator until the user
  visually approves this final layout on a real phone.
- **FULL-SCREEN BOARD CORRECTION (previous, see `DECISIONS.md` D86).**
  **Corrects a real bug Phase 1 shipped**: the user manually tested
  `versionCode=42` on a real Android phone and found Level 27 (7x8)
  rendering with large wasted vertical space around a small, centered
  board — a real, correctly-reported regression, not a matter of taste.
  Root cause: Phase 1 validated its layout math only at the 1080x1920
  reference resolution and never rendered a real campaign level at the
  4 taller resolutions it was also supposed to check — `canvas_items`/
  `expand` stretch mode reveals more logical canvas height on any
  device taller than that reference (most real phones today), and a
  width-bound board's `cell_size` doesn't grow to compensate, so height
  utilization silently degrades on taller devices with zero level/code
  change (Level 27: 94.2% height utilization at 1080x1920 → 64.7% at
  1080x2400). **Fix**: `SafeAreaMargin` gained a `margin_override`
  field; `game.tscn` uses a new, smaller gameplay-specific baseline
  (`UIConstants.GAMEPLAY_BASELINE_MARGIN := 32.0`, vs. the menu-tuned
  `BASELINE_MARGIN := 96.0`, which every menu screen keeps unchanged).
  Real Android safe-area insets still widen it via the existing
  `maxf()` logic, so HUD safety near a notch/cutout is unaffected.
  **Result**: Level 27's cell_size 124px→142px (+14.5%), height
  utilization 64.7%→72.3%; full 5-resolution × 12-profile matrix now
  **140/140 comfortable** (up from 136/140). Visually confirmed via 5
  real rendered levels/tutorial (not just metrics), per the spec's
  explicit "rendered validation is required" instruction. **Honestly
  disclosed**: a width-bound board's `cell_size` was already
  width-maximized (99.4-100% width utilization) — some residual gap on
  very tall devices for boards authored against the 1920 floor remains
  mathematically unavoidable without a level redesign or non-square
  cells (both out of scope). Full regression unchanged: **188/188
  PASS**; a dedicated 12-point Phase 2 re-check: **12/12 PASS**. **NOT
  MANUALLY APPROVED — Android device QA pending.** Per this pass's own
  STOP CONDITION: do not start the procedural generator until the user
  visually approves the board sizing on a real phone.
- **PHASE 2: DIRECT PLAY + CONTINUE FLOW (previous, see `DECISIONS.md`
  D85).** Main Menu is now genuinely `CONTINUE`/`PLAY`/`TUTORIAL`/
  `SETTINGS`/`QUIT` — `PLAY` (was labeled "CAMPAIGN," routed to Level
  Select) now enters the player's current campaign progression directly
  via `GameManager.play_game()`; `CONTINUE` resumes it, including exact
  tile orientations and move count if the player left mid-level. Level
  Select is retained, fully functional, reachable only through a small
  QA-only Main Menu button gated on the existing `UNLOCK_ALL_CAMPAIGN_
  LEVELS_FOR_TESTING` flag. New `SaveManager.campaign_resume_*` fields
  (`SAVE_VERSION` 3→4) track the one in-progress campaign game; a QA
  Level Select session never reads/writes them, so QA testing can never
  corrupt a real player's progression pointer. **Zero level data,
  `LaserSystem`, or Tutorial content/unlock changes.** Full regression
  unchanged: **188/188 PASS**. A dedicated 19-point resume-flow test
  (temporary driver, real autoloads, against this dev machine's own real
  140/140-campaign save — backed up before, restored byte-for-byte
  after): **19/19 PASS**. RENDERED verification (Main Menu at the
  720x1280/1080x1920 and 1080x2400 aspect ratios): correct button order,
  "PLAY" text, disabled-CONTINUE legible, no stray CAMPAIGN button, QA
  button unobtrusive. **NOT MANUALLY APPROVED — Android device QA
  pending**, on top of Phase 1's own still-outstanding review. Per this
  pass's own STOP CONDITION: **do not implement procedural generation,
  create Level 141+, or delete any Level Select code** without being
  explicitly asked.
- **PHASE 1: SHARED ADAPTIVE GAMEPLAY LAYOUT FOUNDATION (previous, see
  `DECISIONS.md` D84).** New product direction recorded: BeamShift's
  long-term target is now **2,000 procedurally-generated levels**
  (deterministic-seed, direct PLAY/CONTINUE, no player-facing Level
  Select) — see `ROADMAP.md`'s "Future product direction" section; the
  generator itself is NOT built yet. This pass confirmed the shared,
  centralized gameplay layout the new spec asked for **already existed**
  (built across D72–D76 — `game.tscn`'s `SafeAreaMargin`→`Layout`→
  `TopBar`/`CenterArea`/`BottomBar` structure, `grid_manager.gd`'s
  independent-per-axis cell-size formula, whole-cell tap) and added the
  future-procedural contract that was genuinely missing:
  `GridManager.MAX_COLUMNS := 8`, `GridManager.
  MIN_COMFORTABLE_CELL_SIZE := 96.0`, and `GridManager.
  is_board_profile_comfortable(columns, rows, playable_size)`. A
  grep-audit found 54 campaign levels (+1 tutorial, +3 fixtures) already
  exceed 8 columns — grandfathered, unmodified. A 5-resolution ×
  12-profile diagnostic found 136/140 combinations comfortable (only
  11-row boards on the two shortest device heights dip 1px under the
  floor). **Zero level data, `game.tscn`, or `LaserSystem`/solver
  changes.** Full regression: **188/188 PASS** (15 dev + 140 campaign +
  20 tutorial + 13 Era 2 fixtures). **NOT MANUALLY APPROVED — Android
  device QA pending.** Per the pass's own STOP CONDITION: **do not start
  Direct Play/Continue or the procedural generator** without being
  explicitly asked.
- **ERA 2 LEVELS 131-140 (previous, see `DECISIONS.md` D83 and
  `CAMPAIGN_DESIGN.md` section 18).** "Advanced convergence pass" -
  user-requested, explicitly authorized to proceed before ANY of the
  three prior Era 2 level batches (101-110, 111-120, 121-130) had
  received manual Android QA - four consecutive unreviewed Era 2
  campaign batches (40 levels) now await real-device feedback together.
  No new mechanics. `get_campaign_level_count()` is now 140. **The most
  shortcut-prone batch yet: 5 of 10 levels needed a fix during
  authoring** (vs. 3/10 and 2/10 for the two prior passes), reflecting
  the higher structural complexity this pass required (two-reflector
  chains, reciprocal relays spanning genuinely opposite approach
  corridors). One was a genuine authoring error (a mirror inserted into
  an already-complete straight path, making its own target permanently
  unreachable - `LevelSolver` reported `UNSOLVABLE`, not a shortcut).
  The other four were shortcuts, all caught by `LevelSolver`'s
  shortest-solution-count check: two were the established `WHITE`-
  accepts-any-color target bypass (D81/D82's fix pattern, including a
  new variant where a swapped-routing shortcut was invisible specifically
  because both candidate beams and both targets shared the same default
  `WHITE`); one (Level 138) was the deepest structural bug found to
  date - a shared One-Way Reflector's two beams approached from the
  SAME side rather than genuinely opposite sides, so one beam's own
  approach corridor doubled as the other's exit corridor, requiring a
  full geometric rebuild (opposite-side approach: one beam entering
  from below, the other from the left) to close for good. Every level
  solver-confirmed `SOLVABLE` with a unique shortest solution and zero
  validator errors after fixes. **Regression**: 15/15 dev, 140/140
  campaign (130 unchanged + 10 new), 20/20 tutorial, 13/13 Era 2
  fixtures - all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 130->140 walk.
  RENDERED verification at three resolutions. **NOT MANUALLY APPROVED -
  Android device QA pending. Per the user's own instruction, a MANUAL
  ANDROID REVIEW CHECKPOINT is now recommended before continuing to
  Levels 141+** - this is the largest unreviewed content backlog this
  project has carried at once. **Do not create Campaign Levels 141+,
  T21+, Era 3, or new Era 2 mechanics, do not disable QA unlock, do not
  make a production release** without being explicitly asked.
- **ERA 2 LEVELS 121-130 (previous, see `DECISIONS.md` D82 and
  `CAMPAIGN_DESIGN.md` section 17).** "Deep dependency pass" -
  user-requested, authorized before ANY of Levels 101-110, 111-120 had
  received manual Android QA. No new mechanics. Moves beyond single-
  chain dependency into whole-board reasoning: shared resources
  spanning distant regions, reciprocal relay chains, near-solution
  traps requiring backward reasoning from a target's color, and (Level
  130) a genuine four-way convergence where one target needs two gates
  opened by two entirely different subsystems. `get_campaign_level_
  count()` is now 130. **Two more issues found and fixed during
  authoring**: Level 123 had a simple grid-bounds error (a tile placed
  one row outside the board - caught immediately and explicitly by
  `LevelValidator`, not the solver). Level 127 hit a NEW failure shape
  beyond D81's "beam continues past its own target" family: a wrong-
  orientation mirror's stray path physically crossed a second,
  unrelated mirror elsewhere on the board, and that mirror's own
  default orientation happened to complete an accidental shortcut
  bypassing the level's Portal entirely - fixed with a precisely placed
  `BLOCKER` that only intercepts the stray path, never the real one.
  Every level solver-confirmed `SOLVABLE` with a unique shortest
  solution and zero validator errors after fixes. **Regression**: 15/15
  dev, 130/130 campaign (120 unchanged + 10 new), 20/20 tutorial, 13/13
  Era 2 fixtures - all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 120->130 walk.
  RENDERED verification at three resolutions. **NOT MANUALLY APPROVED -
  Android device QA pending** (same as every prior Era 2 batch - none
  of 101-110/111-120/121-130 have real-device feedback yet). **Do not
  create Campaign Levels 131+, T21+, Era 3, or new Era 2 mechanics, do
  not disable QA unlock, do not make a production release** without
  being explicitly asked.
- **ERA 2 LEVELS 111-120 (previous, see `DECISIONS.md` D81 and
  `CAMPAIGN_DESIGN.md` section 16).** User-requested follow-up,
  authorized before manual Android QA of Levels 101-110 was finished -
  deepens the same three Era 2 mechanic families (Prism, One-Way
  Reflector, Beam Receiver/Remote Emitter) with NO new mechanics, per
  explicit brief instruction. `get_campaign_level_count()` is now 120.
  **Three real shortcut bugs found and fixed by the solver during
  authoring** - all the same failure shape (a beam continuing past its
  own activated target, since targets never stop a beam, into a second
  mechanic it was never meant to touch): Level 112 (two targets sharing
  a column let one beam satisfy both), Level 118 (two receivers sharing
  a column let one emitter power both), and Level 120 (GREEN's beam
  continuing into a One-Way Reflector it was never meant to reach,
  bypassing the entire Receiver/Remote Emitter chain - this one needed
  TWO fix attempts, since a first fix that only changed the reflector's
  default orientation left an alternate same-length shortcut behind;
  the real fix relocated the reflector so no orientation of it is ever
  reachable by that beam at all). Every level solver-confirmed
  `SOLVABLE` with a unique shortest solution and zero validator errors
  after fixes. **Regression**: 15/15 dev, 120/120 campaign (110
  unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures - all
  solver+runtime-replay PASS. Progression verified against the real
  `SaveManager` API across the full 110->120 walk. RENDERED
  verification at three resolutions (111, 114, 115, 118, 120). **NOT
  MANUALLY APPROVED - Android device QA pending** (same as Levels
  101-110, still awaiting the user's own playthrough). **Do not create
  Campaign Levels 121+, T21+, Era 3, or new Era 2 mechanics, do not
  disable QA unlock, do not make a production release** without being
  explicitly asked.
- **ERA 2 LEVELS 101-110 (previous, see `DECISIONS.md` D79/D80 and
  `CAMPAIGN_DESIGN.md` section 12).** Two-part pass, user-requested,
  giving the user their first real Era 2 gameplay to evaluate:
  - **Part A — fixed a real Tutorial Select regression the user found on
    a real device**: T11-T20's cards had regressed to tall rectangular
    "poster" cards (`bs_level_card_era2.png`, 1024x1536px, covered/cropped
    into the button's 240x253 box, chopping off the frame's rounded
    corners). Root cause confirmed two independent ways (a research
    subagent's trace + this session's own PNG pixel-dimension check).
    Fix: stop swapping texture for Era 2 entirely; tint the same square
    T01-T10 frame via `TextureRect.modulate = EraTheme.for_era(n).
    accent_color` (violet for Era 2, white/no-op for Era 1). Applied to
    both `tutorial_button.gd` (fixing the live bug) and `level_button.gd`
    (the identical dormant bug, fixed pre-emptively since Level 101+
    didn't exist until this same session's Part B). Verified via a real
    non-headless 1080x1920 render — T11-T18 now render as the identical
    compact square frame T01-T10 use, just violet-tinted.
  - **Part B — Campaign Levels 101-110, the first real Era 2 campaign
    content** (as opposed to T11-T20's isolated single-mechanic
    tutorials or the 13 `editor_fixtures/era2/` regression fixtures).
    Stored at `levels/campaign/era2_stage_01/` (not `stage_11/` — see
    `CAMPAIGN_DESIGN.md`'s own guidance that a 101+ request is new scope,
    not a continuation of the original numbering), registered as 10 new
    `LevelManager.CAMPAIGN_LEVEL_PATHS` entries after Level 100's.
    `get_campaign_level_count()` is now 110. Introductory Era 2 arc:
    101 (Prism), 102 (Prism+Filter trap), 103 (Prism+Splitter+Portal),
    104 (One-Way Reflector directionality), 105 (Prism+One-Way Reflector
    false-route), 106 (Receiver/Remote Emitter), 107 (Receiver+Portal
    +Filter, spatially disconnected), 108 (Prism+Receiver multi-system),
    109 (One-Way Reflector→Receiver→Remote Emitter→Switch→Gate chain),
    110 "Refraction Nexus" (all three Era 2 mechanic families + Mirror/
    Portal/Filter/Switch/Gate, the first Era 2 campaign milestone).
    **Every level solver-confirmed `SOLVABLE` with a unique shortest
    solution (`shortest_solution_count == 1`) and zero `LevelValidator`
    errors on the FIRST authoring attempt** — no draft rejections needed,
    unlike several Era 1 batches. `game.gd`'s `era_transition` banner
    (previously keyed off "current level == last implemented level," which
    would have silently shifted from firing at Level 100 to Level 110) was
    fixed to compare `EraTheme.get_era_for_level()` across the boundary
    instead — correct today and automatically correct for a future
    Level 200 -> Era 3 boundary.
  - **Regression**: 15/15 dev, 110/110 campaign (100 unchanged + 10 new),
    20/20 tutorial, 13/13 Era 2 fixtures (12 solvable-by-design + 1
    deliberately-unsolvable-by-design, confirmed still behaving exactly
    as designed) — all solver+runtime-replay PASS via a real `GridManager`
    (`_on_orientable_tile_clicked()`, the same entry point a player tap
    uses). T11-T20's guided step-machine behavior is unchanged from the
    prior confirmed 10/10 PASS (D78) — nothing in this pass touched
    `TutorialManager`, tutorial level data, or tutorial step logic.
  - **Progression/save verified against the real `SaveManager` API** (not
    a faked flag): completing Level 100 via `SaveManager.record_campaign_
    level_result()` correctly unlocks Level 101 and advances
    `campaign_highest_unlocked_level`; `get_campaign_level(111)` correctly
    returns `null` with a graceful warning; both QA unlock-all flags
    (`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`, `UNLOCK_ALL_ERA_2_
    TUTORIALS_FOR_TESTING`) left `true`.
  - **RENDERED verification** (real GPU render, `godot --path .`, D45-D47
    technique): Levels 101/103/105/108/110 at 1080x1920, Level 110
    additionally at 720x1280 and 1080x2400 — all clean, correct Era 2
    theming, full board utilization, no HUD overlap or clipping.
  - **NOT MANUALLY APPROVED — Android device QA pending**, same standing
    state as every build; this is the user's first chance to actually
    play real Era 2 gameplay. **Do not create Campaign Levels 111+, T21+,
    or Era 3, do not disable QA unlock, do not make a production
    release** without being explicitly asked.
- **ERA 2 FOUNDATION QA/HARDENING PASS (previous, see `DECISIONS.md`
  D78).** Closed the gaps the D77 pass left open, all under the same
  STOP CONDITION (no Campaign Levels 101+, no T21+, no Era 3, no
  production release):
  - The user-supplied `bs_milestone_complete_era2.png` verified (real
    alpha, no baked text/checkerboard, present in a real exported APK)
    and deliberately left unwired (Level 200 doesn't exist).
  - **T11-T20 now have a real guided-step-machine test** (the prior
    pass only solver/validator-tested them) - a driver mirroring
    `game.gd`'s own `GridManager` signal wiring drove all 10 tutorials
    through MESSAGE/REQUIRE_TILE_TAP (incl. wrong-tile rejection)/
    WAIT_FOR_TARGET_ACTIVATION/WAIT_FOR_PUZZLE_SOLVED, Reset, Pause/
    Resume, and completion. **10/10 PASS.**
  - **Two new UI integrations**: `LevelCompletePopup`/
    `TutorialCompletePopup` now swap in real Era 2 panel art
    (`bs_panel_level_complete_clean_era2.png`/`bs_panel_tutorial_
    complete_era2.png`) via `EraTheme`, and Tutorial Select's T11-T20
    cards now use the Era 2 card art (`level_button.gd`'s existing but
    dormant wiring, now mirrored in `tutorial_button.gd` - live
    immediately since T11-T20 already exist). **Two real rendering bugs
    were found and fixed via RENDERED verification** before either
    shipped: a `content_margin` override that placed button text inside
    the new frame's crystal ornaments, and a `TextureRect` stretch mode
    (`KEEP_ASPECT_CENTERED`) that misaligned the taller Era 2 card art -
    switched to `KEEP_ASPECT_COVERED` + `clip_contents`.
  - Six other Era 2 UI assets (mechanic-notification panel/icon,
    loading icon, tutorial highlight frame, the Era transition splash
    pair) reviewed and left deliberately unwired - either no feature
    exists yet to attach them to, or (tutorial highlight frame,
    non-"clean" level/tutorial complete panels) they don't fit the
    actual UI architecture/contain fake baked data. Full per-asset
    reasoning in `DECISIONS.md` D78.
  - **APK size reduced 24.9%** by excluding `bs_grid_surface_era2.png`
    and all 8 `assets/gameplay/fx/era2/*.png` files (confirmed
    completely unreferenced - `Era2ActivationFX` is procedural, no
    texture assets at all) plus the unwired UI assets above from
    `export_presets.cfg`'s `exclude_filter` - verified against a real
    exported APK's own zip listing, not assumed.
  - Resolution matrix (720x1280/1080x1920/1080x2400) and color-
    readability (RED beam vs. UI magenta, pixel-sampled: 68.5° hue
    separation) both re-confirmed clean via real GPU renders; no
    gameplay color or UI scrim/glow changes were needed.
  - Fixed a small pre-existing documentation undercount: the Era 2
    fixture population is **13** files, not 12 (`fixture_one_way_
    reflector_backslash` was always there, just never counted).
  - **Regression**: 15/15 dev, 100/100 campaign, 13/13 Era 2 fixtures,
    20/20 tutorial boards solvable, 10/10 T11-T20 guided step-machine -
    all PASS. **NOT MANUALLY APPROVED - Android device QA pending.**
    **Do not create Campaign Levels 101+, T21+, or Era 3, do not
    disable QA unlock, do not make a production release** without being
    explicitly asked.
- **ERA 2 FOUNDATION (previous, see `ERA_2_DESIGN.md`, `DECISIONS.md`
  D77).** New product direction work: Era 2 ("Refractions") - the second
  100-level campaign block + its own 10-tutorial pack - now has its
  engine foundation, visual theming architecture, and guided tutorial
  pack in place. **Levels 101-200 do NOT exist yet** - this pass was
  explicitly scoped to stop short of them, per the brief's own STOP
  CONDITION.
  - **Era architecture**: `EraTheme` (`scripts/resources/era_theme.gd`,
    not an autoload) maps any campaign level/tutorial number to its Era
    and fetches that Era's themed assets; Era 1's theme is all-null by
    construction, so Levels 1-100 and T01-T10 are visually unchanged.
  - **Four new deterministic LaserSystem mechanics**: Prism (a WHITE
    beam splits into RED/GREEN/BLUE via `reflect()`; a colored beam only
    ever uses its own matching channel), One-Way Reflector (reuses
    Mirror's exact rotation model - the reflective side is *derived*
    from orientation, no new stored state; a rightward beam always
    reflects, rotation only changes which way), and Beam Receiver ->
    Remote Emitter (a new `receiver_states` dependency layer resolved by
    `simulate_until_stable()` exactly like switch -> gate already is).
    Zero `LevelSolver` code changes needed (One-Way Reflector reuses the
    existing rotatable-tile abstraction; Prism/Receiver/Remote Emitter
    are never rotatable). 13 new dev fixtures
    (`levels/editor_fixtures/era2/`) cover every named interaction.
  - **T11-T20**: the Era 2 guided tutorial pack, added to
    `LevelManager.TUTORIAL_LEVEL_PATHS`. Locked until Level 100 is
    legitimately completed (`LevelManager.is_tutorial_level_selectable()`,
    generalizes to future eras), with a
    `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` QA override mirroring the
    existing campaign one. No `SAVE_VERSION` bump needed - the existing
    `tutorial_*` fields were already generic over tutorial count.
  - **Visual theming**: gameplay background, both HUD bars (including a
    different HUD aspect ratio), and grid cell art all swap per-era in
    `game.gd`; Level Select/Tutorial Select background themes against
    the player's furthest-unlocked content; a small Era transition
    banner appears in `LevelCompletePopup` the first time Level 100 is
    completed. `Era2ActivationFX` - a new violet/magenta procedural
    burst, same architecture as the existing `LaserMirrorImpactFX` -
    plays for Prism/reflective One-Way Reflector/Receiver/Remote
    Emitter activation.
  - **Two real bugs found and fixed via actual rendered/exported
    verification** (not just source review) - see `DECISIONS.md` D77 for
    the full trace: (1) the new piece art was initially placed under the
    Android-export-excluded `assets/gameplay/pieces/**` folder (a repeat
    of D51's exact failure mode - would have shipped invisible Era 2
    tiles), fixed by moving it into per-tile-type folders and re-verified
    against a real exported `.pck`; (2) `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_
    TESTING` didn't actually bypass unlock on a save with real T01-T10
    progress, fixed to match the campaign flag's own unconditional-
    bypass semantics.
  - **Validated**: full 115-level dev+campaign solver regression
    unchanged (167/171 headless checks pass; the 4 non-passes are the
    same pre-existing T02/T04/T07/T10 tutorial metadata mismatch this
    project has carried since the Rectangular Grid Architecture pass,
    unrelated); all 13 new Era 2 fixtures pass exactly as designed; all
    10 new T11-T20 tutorials solve at their hand-derived `optimal_moves`
    (`1,1,1,2,1,1,1,1,1,2`) and pass `LevelValidator` with zero errors;
    5 RENDERED screenshots (T11/T15/T17/T20 gameplay + Tutorial Select,
    1080x1920, real GPU) visually confirmed correct rendering, including
    catching bug (2) above.
  - **NOT MANUALLY APPROVED - Android device QA pending**, same standing
    state as every new build. **Do not create Campaign Levels 101+, T21+,
    or Era 3 without being explicitly asked** - this pass's own
    completion is not authorization to continue; the brief's STOP
    CONDITION applies.
- **LEVELS 76-100 PORTRAIT RE-LAYOUT — PHASE 2D, FINAL BATCH (previous,
  see `DECISIONS.md` D76, `ARCHITECTURE.md` "Rectangular grid layout",
  `CLAUDE.md` Level editor rules/Responsive rules).** Campaign Levels
  76-100's board geometry was re-laid out the same way Phase 2A/2B/2C
  did 1-75 — an order-preserving coordinate remap per level, individually
  chosen shapes, geometry-only. **THIS COMPLETES THE PORTRAIT RE-LAYOUT
  OF ALL 100 CAMPAIGN LEVELS.** This is the campaign's hardest and most
  tile-dense block — up to 42 tiles (Level 100), up to 16 rotatable
  pieces at the practical solver ceiling 2^16=65536 (Levels 80, 95), up
  to 5 emitters (Levels 90, 100), three-stage relays (87, 88, 89, 90,
  96, 100), a four-independent-source convergence (Level 80), and
  five-link backward-reasoning chains (Level 98). Every level was read
  in full and its dependency graph understood before choosing a shape.
  **Applied in three validated sub-batches with a git checkpoint after
  each** (76-80, 81-90, 91-100) — solver + validator + real-
  `GridManager` runtime-replay check passed before each commit.
  **Solver-confirmed for all 25 levels**: identical `status`/
  `optimal_moves`/`shortest_solution_count`/`states_explored` old vs.
  new, matched on the first attempt every time — zero manual geometry
  corrections, zero shortcuts, zero unintended UNSOLVABLE states,
  including Level 80's 65519-state solver-ceiling-adjacent search.
  **Levels 85, 91, 95, and 98 were deliberately left unchanged** — the
  same zero-slack situation Level 75 first established (distinct-
  column/row counts already exactly equal `grid_width`/`grid_height`),
  now confirmed to recur naturally as levels grew more content-dense.
  6 levels compacted 10-wide→9-wide (cell 87px→96px, +10%); 15 levels
  held their exact 87px cell while gaining zero-cost row growth to the
  full safe ceiling (`floor(1053.94/12)=87`, height utilization
  82.6%→99.1%) — a new technique this pass: computing the actual
  zero-cost ceiling rather than adding one row at a time. **Level 100
  ("Culmination") — the definitive Era 1 finale — was fully verified**:
  all five emitter routes, all three relay stages, both portal
  transitions, the symmetric convergence (emitter 4/5 gating emitter
  2/1's starts), the fixed-mirror backward-reasoning step at (3,2),
  target continuation, filter/color behavior, and the unique shortest
  solution all confirmed identical before/after (`opt=13 states=16383
  shortest=1`, unchanged), went 10x10→10x12 at zero cell-size cost.
  **15/15 dev, 100/100 campaign (21 changed + 4 unchanged + 75
  untouched) solver PASS, 100/100 campaign runtime-replay PASS
  (extended to the full 115-level dev+campaign population, 115/115
  PASS), 10/10 tutorial-board solvability PASS.** RENDERED screenshots
  (Levels 76, 80, 85, 87, 90, 95, 100) visually confirmed correct
  rendering; resolution checks (720x1280/1080x1920/1080x2400 — Level
  100 at all three) confirmed zero HUD overlap.
  **FINAL READ-ONLY PORTRAIT AUDIT ACROSS ALL 100 CAMPAIGN LEVELS**:
  100/100 SOLVABLE, zero levels below the 90% height utilization
  target, zero levels below the 85% width utilization target, min cell
  87px, max cell 174px, average cell 122.4px, average width utilization
  98.2%, average height utilization 95.6%. Shape distribution: 5x6 (10),
  5x7 (9), 6x7 (19), 6x8 (1), 7x8 (16), 8x9 (7), 8x10 (1), 9x10 (21),
  10x11 (1), 10x12 (15). Five levels intentionally unchanged across all
  four phases: 75, 85, 91, 95, 98. **Levels 1-75 and the Tutorial were
  never touched this pass** (confirmed via `git diff --stat` against
  the pre-Phase-2D checkpoint commit — exactly the 21 intended files
  changed). **NOT MANUALLY APPROVED — Android visual QA of this build
  pending**, same as every prior pass. **Era terminology recorded**:
  the complete 100-level campaign plus T01-T10 together constitute
  **Era 1**; a future Era 2 (Levels 101-200, T11-T20, new mechanics, a
  new visual theme) is documented in `ROADMAP.md` but **not implemented
  and not to be started without a separate explicit request**.
- **LEVELS 51-75 PORTRAIT RE-LAYOUT — PHASE 2C (previous, see
  `DECISIONS.md` D75, `ARCHITECTURE.md` "Rectangular grid layout",
  `CLAUDE.md` Level editor rules/Responsive rules).** Campaign Levels
  51-75's board geometry was re-laid out the same way Phase 2A/2B did
  1-50 — an order-preserving coordinate remap per level, individually
  chosen shapes, geometry-only. This is the campaign's most mechanically
  interconnected block re-laid out so far: mutual switch/gate pairs
  where each branch's switch opens the OTHER branch's gate (Levels 51,
  73), a genuine two-stage relay (Level 70: emitter 1's switch opens
  emitter 2's early gate, emitter 2's switch — reached only after —
  opens emitter 1's own later gate), shared-gate cells crossed by
  perpendicular-direction beams from two different emitters (Levels 68,
  72), and post-target beam continuation gating a second branch (Levels
  65, 74, 75). Every one of these was individually read and reasoned
  through before choosing a shape, not just solver-trusted — though the
  order-preserving proof (position-only, independent of tile type or
  mechanic) held unconditionally for all 25 anyway.
  **Applied in three validated sub-batches with a git checkpoint after
  each** (51-60, 61-70, 71-75) — solver + validator + real-`GridManager`
  runtime-replay check passed before each commit, never all 25 batched
  and validated afterward. **Solver-confirmed for all 25 levels**:
  identical `status`/`optimal_moves`/`shortest_solution_count`/
  `states_explored` old vs. new, matched on the first attempt every
  time — zero manual geometry corrections, zero shortcuts, zero
  unintended UNSOLVABLE states. **Level 75 ("Convergence Reaction") was
  deliberately left unchanged** — its distinct-column count (9) and
  distinct-row count (10) already exactly equal its `grid_width`/
  `grid_height` (itself already non-square/portrait-shaped, 9x10, from
  original design), so no remap could improve it without either
  violating its own content footprint or shrinking its cell size. Two
  other levels' original boards were already non-square too (Level 52
  "Currents" 8x7, Level 57 "Long Division" 10x9) — not every pre-D72
  board was a naive square. Average cell size grew 96.7px → 109.2px
  (+13.0%, a smaller percentage than Phase 2B's +25.6% since this block
  starts with markedly less compaction slack — several boards, e.g.
  Levels 56/60/67/70/71/73, already used every column or row of their
  old grid); average height utilization grew 81.9% → 93.0%. **15/15 dev,
  100/100 campaign (24 changed + Level 75 unchanged + 75 untouched)
  solver PASS, 100/100 campaign runtime-replay PASS (extended, as in
  Phase 2B, to the FULL 115-level dev+campaign population, all 115/115
  PASS), 10/10 tutorial-board solvability PASS.** RENDERED screenshots
  (Levels 51, 55, 60, 65, 70, 75) visually confirmed correct gate/
  switch/portal/filter rendering and larger/equal readable tiles;
  resolution checks (720x1280/1080x1920/1080x2400, Levels 60/70/75)
  confirmed zero HUD overlap. **Levels 1-50 and 76-100 and the Tutorial
  were never touched this pass** (confirmed via `git status`/
  `git diff --stat` against the pre-Phase-2C checkpoint commit — exactly
  the 24 intended files changed, Level 75's file untouched).
  **NOT MANUALLY APPROVED — Android visual QA of this build pending**,
  same as every prior pass. **Campaign Levels 76-100 have NOT yet been
  re-laid out** — re-laying out further batches is future work, not
  started, not authorized by this pass's completion. **The project's git
  repository (added during Phase 2B) was exercised as designed this
  pass** — a checkpoint commit before touching any Level 51-75 file,
  then one commit per validated sub-batch, never a bare working tree as
  the only copy.
- **LEVELS 26-50 PORTRAIT RE-LAYOUT — PHASE 2B (previous, see
  `DECISIONS.md` D74, `ARCHITECTURE.md` "Rectangular grid layout",
  `CLAUDE.md` Level editor rules/Responsive rules).** Campaign Levels
  26-50's board geometry was re-laid out the same way Phase 2A did
  Levels 1-25 — an order-preserving coordinate remap per level (own
  `grid_width`/`grid_height`/every tile position chosen individually,
  not one blanket size) — **not a difficulty redesign**. This batch is
  the harder block: splitters, filters, portals, switch/gate dependency,
  hazards/blockers, and two-emitter levels throughout, so every level
  was hand-read for its mechanic structure before choosing a shape (per
  the brief's explicit caution about geometry changes creating
  unintended beam intersections in these mechanics), not just
  auto-compacted. Shapes chosen: 6x7 (12 levels, e.g. Gambit, Stalemate,
  Ambush, Foresight-adjacent), 7x8 (9 levels, e.g. Labyrinth, Impasse,
  Deadlock, Paradox), 8x9 (Nexus, Crucible), 6x8 (Foresight), 9x10
  (Threshold) — every one held at or above its own distinct occupied-
  column/row count, several exactly matching Phase 2A's "zero-cost row
  growth" pattern (Levels 27/50 kept their exact old cell size, +1 free
  row). **Solver-confirmed for all 25 levels, before writing any file**:
  identical `status`/`optimal_moves`/`shortest_solution_count`/
  `states_explored` old vs. new — the load-bearing check, not a
  formality (same technique/proof as D73: the remap preserves the
  *sequence* of cell-type hits a beam makes, never the distance between
  them, so it cannot change which cells a beam hits or introduce a
  shortcut). Average cell size grew ~105px → ~132px (+25.6%); average
  height utilization grew ~82.2% → ~95.2%; **zero levels needed a manual
  geometry correction, zero solver-detected shortcuts, zero unintended
  UNSOLVABLE intermediate states** — every one of the 25 order-preserving
  remaps matched its baseline on the first attempt. Level 50 ("Paradox,"
  the campaign's own named quality benchmark) went 7x7→7x8 at an
  UNCHANGED 124px cell size (same zero-cost pattern as Phase 2A's Level
  20), 255 states explored preserved exactly, reasoning structure
  (chained recolor, filter avoidance, false routes, fixed-mirror
  backward reasoning, the one inert decoy) untouched by construction.
  **15/15 dev, 100/100 campaign (all 25 changed + 75 untouched) solver
  PASS, 100/100 campaign runtime-replay PASS (a real `GridManager`,
  driven only through the same `_on_orientable_tile_clicked()` entry
  point a player tap uses, reaches `is_solved == true` after replaying
  each solver's own solution path), 10/10 tutorial-board solvability
  PASS.** RENDERED screenshots (Levels 26, 28, 30, 35, 40, 45, 50)
  visually confirmed larger/equal readable tiles, puzzle content spread
  across upper/middle/lower board regions, correct beam/portal/filter
  rendering, no distortion, no clipping; resolution matrix (720x1280,
  1080x1920, 1080x2400) confirmed zero HUD overlap, including one real
  RENDERED check at 1080x2400 (taller screen correctly reveals more
  background above/below the fixed-size board, exactly as D72/D73
  documented, never distorting or re-flowing it). **Levels 1-25 and
  51-100 and the Tutorial were never touched this pass** (confirmed via
  `git status` — exactly the 25 intended files changed, nothing else).
  **NOT MANUALLY APPROVED — Android visual QA of this build pending**,
  same as every prior pass. **Campaign Levels 51-100 have NOT yet been
  re-laid out** — re-laying out further batches is future work, not
  started, not authorized by this pass's completion.
- **LEVELS 1-25 PORTRAIT RE-LAYOUT — PHASE 2A (previous, see
  `DECISIONS.md` D73, `ARCHITECTURE.md` "Rectangular grid layout",
  `CLAUDE.md` Level editor rules/Responsive rules).** Campaign Levels
  1-25's board geometry (`grid_width`/`grid_height`/every tile position)
  was re-laid out to use the Phase 1 rectangular-grid engine's available
  portrait space substantially better - **not a difficulty redesign**.
  Technique: an **order-preserving coordinate remap** (every tile
  sharing an old row/column still shares the new one; relative order per
  axis preserved) - since `LaserSystem` only depends on the *sequence*
  of cell-type hits a beam makes, never the distance between them, this
  transform is mathematically guaranteed not to change which cells a
  beam hits or in what order. Solver-confirmed for all 25 levels:
  identical `status`/`optimal_moves`/`shortest_solution_count`/
  `states_explored` before and after, checked directly (not assumed) via
  a temporary generator/validator script. Levels 1-19 grew from 5x5 to
  5x6 or 5x7 (columns held constant, rows grown - zero or 14% cell-size
  cost); Level 20 grew 6x6 -> 6x7 (zero cost); Levels 21-25 (the only
  ones already rendering below the project's own `UIConstants.
  MIN_TOUCH_TARGET`=144px minimum at 124-96px) had columns compacted
  alongside row growth, landing at 6x7 or 7x8 with cell sizes 29-33%
  LARGER than before (145px/124px). At the 1080x1920 reference
  resolution, every tested level reached 94.2-99.8% height / 86.0-99.8%
  width utilization (vs. the old square boards' 56.8-99.8% height at the
  same widths). **15/15 dev, 100/100 campaign (all 25 changed + 75
  untouched), 5/5 rectangular fixtures, 10/10 tutorial-board solvability
  regressions all PASS; zero HUD overlap across 24 resolution/level
  combinations tested; RENDERED screenshots (Levels 1, 10, 20, 21, 25)
  visually confirmed larger readable tiles, puzzle content genuinely
  spread across the taller board (not clustered), correct beam/tile
  rendering, no distortion or clipping.** **Levels 26-100 and the
  Tutorial were never touched this pass** (confirmed - only the 15
  `stage_01`/`stage_02` files and 5 of `stage_03`'s files were written).
  **NOT MANUALLY APPROVED - Android visual QA of this build pending.**
  **Campaign Levels 26-100 have NOT yet been re-laid out** - re-laying
  out further batches is future work, not started, not authorized by
  this pass's completion. The long-term "Era" product direction (one
  continuous Tutorial+PLAY progression instead of separate Campaign/
  Endless framing, 100 levels + 10 tutorials per Era) was documented per
  explicit instruction in `ROADMAP.md` but **is not implemented and must
  not be started without a separate explicit request.**
- **RECTANGULAR GRID ARCHITECTURE — PHASE 1 (previous, see `DECISIONS.md`
  D72, `ARCHITECTURE.md` "Rectangular grid layout", `CLAUDE.md`
  Responsive rules).** Engine/layout architecture pass only — **zero
  Campaign/dev/tutorial level content changed**, no `grid_width`/
  `grid_height`/tile-coordinate edits anywhere. `GridManager._recalculate_
  layout()` now fits an arbitrary `columns x rows` board against the real
  playable rectangle between Top HUD and Bottom HUD using independent
  per-axis cell-size candidates (`min(available_width/columns,
  available_height/rows)`) instead of the old square-only formula
  (`min(size.x,size.y)/max(grid_width,grid_height)`) — the single
  square-grid assumption found anywhere in the project after a full
  audit of `LaserSystem`, `LevelSolver`/`LevelValidator`/`LevelMetrics`,
  every tile visual script, the tutorial highlight/dim system, and
  mirror impact VFX (all already consumed `cell_size`/`grid_origin`
  generically with no further changes needed). A square board's layout
  is unchanged by construction. New dev-only diagnostics
  (`GridManager.get_layout_metrics()`/`format_layout_diagnostics()`,
  never shown to players) report cell size and width/height utilization
  for a future Phase 2 pass choosing real rectangular campaign-level
  shapes. **15/15 dev, 100/100 campaign, 10/10 tutorial (solvability)
  solver+runtime-replay regressions unchanged; 5/5 new temporary
  rectangular layout fixtures (`levels/editor_fixtures/fixture_rect_
  5x8/6x10/7x11/8x12/9x10.gd` — never in any `LevelManager` path list,
  never Campaign-reachable) PASS; resolution/layout matrix (720x1280,
  1080x1920, 1080x2160, 1080x2400, 1080x2560) confirmed zero HUD overlap
  and rectangular fixtures reaching 85-100% width / 89-99.8% height
  utilization vs. existing square levels' width-bound-only behavior;
  RENDERED screenshots (small/medium/large/tall-rectangular) visually
  confirmed correct alignment, no distortion, no clipping.** Pre-existing,
  unrelated finding (not fixed, not introduced by this pass): 4 tutorials
  (T02/T04/T07/T10) have a declared `optimal_moves` that doesn't match
  the solver's count, though all remain genuinely solvable — cosmetic
  Tutorial metadata, out of scope for an engine pass. **NOT MANUALLY
  APPROVED — Android visual QA of this build pending**, same as every
  prior pass. **Campaign Levels 1-100 have NOT yet been re-laid out —
  choosing rectangular level shapes for real campaign content is Phase
  2, not started, not authorized by this pass's completion.**
- **UI BACKGROUND REFRESH V2 + MIRROR IMPACT VFX (previous, see
  `DECISIONS.md` D71, `ARCHITECTURE.md` "Mirror impact VFX" and "Menu
  backgrounds V2").** Visual-only pass on the finished 100-level build —
  **no gameplay, level, solver or save change.** (1) Main Menu / Campaign
  Level Select / Tutorial Select now each use their own V2 portrait
  background (`res://assets/ui/backgrounds/bs_bg_main_menu_v2.png`,
  `bs_bg_campaign_select_v2.png`, `bs_bg_tutorial_select_v2.png`), shown
  with the scenes' existing cover-crop `TextureRect`, plus a subtle
  scene-local `ReadabilityScrim` gradient (alpha ≤ 0.30) between
  background and UI; the two superseded backgrounds are unreferenced and
  excluded from the APK. (2) `LaserMirrorImpactFX` — a ~0.32 s procedural
  flash + ring + spark burst at each mirror (rotatable or fixed; not
  splitters) the beam reflects off, spawned by `GridManager` from the
  already-computed simulation result, on player taps only (not load/
  Reset/resize), tinted by the real BeamColor mapping, self-freeing,
  input-transparent. **15/15 dev, 100/100 campaign solver + runtime,
  10/10 tutorial regressions unchanged; RENDERED screenshots inspected;
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` still `true`.** **NOT MANUALLY
  APPROVED — Android visual QA of this build pending** (checklist in
  `TEST_PLAN.md`). Known/flagged, not changed: the Main Menu `Logo`
  never draws (zero width in its `CenterContainer`, pre-existing — the V2
  art's baked "BEAMSHIFT" plaque is the only title there), the Back
  button on the select screens renders small (pre-existing), very tall
  phones trim the baked side panels, and a mirror's burst color follows
  its branch's *final* (post-filter) color, same as the drawn beam.
- **CAMPAIGN COMPLETE — LEVELS 91-100 (previous, see `DECISIONS.md` D70
  and `CAMPAIGN_DESIGN.md` section 11m).** The campaign now has all 100
  originally-planned levels. Levels 91-100 (internal folder `stage_10`)
  are the fifth and FINAL post-reboot expansion — MASTER+/EXTREME/FINAL
  CHALLENGE tier, built with **no mechanic-teaching reset**: Level 91
  continues directly from Level 90's difficulty. Optimal-move curve:
  13,13,11,11,15,12,14,14,14,13 — Level 95 ("Final Threshold") is the
  "final exam" checkpoint, Level 96 ("Chain of Custody") introduces a
  genuine shared-state chain where a target's own activation is just a
  waypoint toward a later emitter's conditions, and Level 100
  ("Culmination") is THE definitive final puzzle: Level 90's own
  three-stage relay + double-portal + symmetric-convergence structure
  plus a genuinely non-rotatable fixed mirror for backward reasoning,
  deliberately held to Level 90's exact move count and grid size rather
  than padded. **One full draft rejection, and a significant one:**
  Level 100's first draft additionally gated emitter 4 behind emitter
  1's own post-target continuation, creating a genuine circular
  deadlock (emitter 1 needs emitter 3, which needs emitter 2, which
  needs emitter 4, which would have needed emitter 1's own completion)
  — exactly the failure mode D69 warned the very next session to check
  for, caught immediately by the solver reporting UNSOLVABLE, removed
  rather than reworked. See D70 for the full writeup. **90/90→100/100
  campaign solver PASS, 100/100 runtime-replay PASS, 15/15 dev PASS,
  10/10 tutorial-board PASS.** `get_campaign_level_count() == 100`
  confirmed via a real-autoload driver; Level 101 correctly returns
  `null` with no crash; `game.gd`'s existing `has_next` check and
  `LevelCompletePopup`'s existing Next-Level-button visibility logic
  both confirmed to already handle Level 100 as the last level
  correctly, with zero code changes needed. **Levels 1-90 and Tutorial
  completely untouched.** **NOT YET MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 91-100. **The 100-level campaign
  structure is now complete — do not create Campaign Levels 101+ or a
  Stage 11 without being explicitly asked.**
- **CAMPAIGN EXPANSION — LEVELS 81-90 (previous, see `DECISIONS.md` D69
  and `CAMPAIGN_DESIGN.md` section 11l).** Levels 81-90 (internal folder
  `stage_09`) are the fourth post-reboot expansion past 80 — EXTREME/
  EXTREME+ tier, built with **no mechanic-teaching reset**. Optimal-move
  curve: 12,11,11,12,14,12,10,12,13,13 — Level 87 ("Triple Relay")
  introduced the first THREE-stage switch/gate relay in the campaign
  (emitter 1's switch opens emitter 2's gate; emitter 2's switch opens
  emitter 3's gate; emitter 3's switch opens the final gate on emitter
  1's own tail), resolved automatically over 4 simulation passes with
  zero new engine code, and Level 90 ("Full Circuit") is a major
  milestone: five emitters, the three-stage relay, two portal jumps, and
  two independent converging gates placed symmetrically on both ends of
  the relay. One full draft rejection (Level 87's first draft let two
  emitters share a column; when both mirrors were left unflipped, one
  beam bent directly into the other's chain, producing a 5-move
  shortcut that bypassed the relay entirely) and one mid-design
  correction caught immediately by the solver (Level 89's target A was
  placed one row off from the beam's actual path) — see D69 for both.
  **Levels 1-50 are USER-TESTED on a real device and reported good —
  treat this as a manually-positive baseline.** Separately, **full
  manual QA of Levels 51-100 remains pending** — do not describe Levels
  51-100 as "approved" without checking whether the user has actually
  completed that review in `TEST_PLAN.md`'s corresponding sections.
- **CAMPAIGN EXPANSION — LEVELS 71-80 (previous, see `DECISIONS.md` D68
  and `CAMPAIGN_DESIGN.md` section 11k).** Levels 71-80 (internal folder
  `stage_08`) are the third post-reboot expansion past 70 — MASTER/
  MASTER+/EXTREME tier, built with **no mechanic-teaching reset**.
  Optimal-move curve: 11,9,11,8,13,11,12,12,13,14 — Level 75
  ("Convergence Reaction") is a major mid-block checkpoint, and Level 80
  ("Full Convergence") is a major milestone exceeding Level 70's own
  two-stage relay: one target is gated by FOUR independently-opened
  dependencies. One full draft rejection (Level 72's from-scratch
  geometry mixed up mirror positions and came back UNSOLVABLE; rebuilt
  on Level 68's proven geometry) and one mid-design correction caught
  immediately by the solver (Level 79's entry mirror) — see D68 for
  both. Level 80 sits at the practical solver ceiling (16 rotatable
  pieces = 2^16 = 65536 states against `LevelSolver.DEFAULT_MAX_STATES`)
  — do not add rotatable pieces to it. **Levels 1-50 are USER-TESTED on
  a real device and reported good — treat this as a manually-positive
  baseline.** Separately, **full manual QA of Levels 51-90 remains
  pending** — do not describe Levels 51-90 as "approved" without
  checking whether the user has actually completed that review
  in `TEST_PLAN.md`'s corresponding sections.
- **CAMPAIGN EXPANSION — LEVELS 51-60 (previous, see `DECISIONS.md` D66
  and `CAMPAIGN_DESIGN.md` section 11i).** The campaign reached 60
  levels. Levels 51-60 (internal folder `stage_06`) are the first
  post-reboot expansion past 50 — built with **no mechanic-teaching
  reset**: Level 51 continues directly from the Levels 46-50 difficulty
  region, freely combining every mechanic Tutorial already teaches.
  Optimal-move curve: 10,8,7,11,11,8,9,11,11,14 — Level 60
  ("Threshold of Reason") is a major milestone at 32767 states explored,
  exceeding old Level 50's 255-state benchmark. Two full draft
  rejections during design (a pathologically slow shared-portal design
  in Level 56, and an accidental 4-move shortcut in Level 58's first
  draft) — see D66 for both. **50/50→60/60 campaign solver PASS, 60/60
  runtime-replay PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.**
  `get_campaign_level_count() == 60` confirmed via a real-autoload
  driver at the time. **Levels 1-50 and Tutorial completely untouched.**
- **CAMPAIGN DIFFICULTY REWORK PASS 2 (current, see `DECISIONS.md` D65
  and `CAMPAIGN_DESIGN.md` sections 11f/11g/11h).** The `versionCode=22`
  reboot below was solver-valid but still too easy in Levels 21-45
  (optimal-move curves 3,2,2,2,2 / 2,2,2,2,5 / 2,4,2,2,3 — far short of
  their "Hard+/Very Hard/Expert" labels, several solvable with a
  handful of random taps). This pass replaces all 25 of Levels 21-45 a
  SECOND time with content built for real dependency depth (cross-
  branch shared mirrors, filter order, portal misdirection, switch/gate
  dependency, multi-emitter dependency, backward reasoning, hazard/
  blocker-guarded false forks) rather than padded move counts. New
  optimal-move curve: 5,6,5,6,6 (21-25) / 7,8,6,7,7 (26-30) / 6,7,6,5,7
  (31-35) / 9,9,6,9,11 (36-40) / 8,9,10,7,11 (41-45). **Levels 1-20 and
  46-50 remain untouched** (same as the first reboot pass); Tutorial
  remains completely separate and unchanged. **50/50 campaign solver
  PASS, 50/50 runtime-replay PASS, 15/15 dev PASS, 10/10 tutorial-board
  PASS.** Several authoring bugs (accidental collinearity between a
  target/hazard and an unrelated beam's straight path, causing
  unintended shortcuts or `UNSOLVABLE` results) were caught by the
  solver during design and fixed — see `DECISIONS.md` D65 for the full
  accounting. **NOT YET MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY
  QA PENDING** for all 25 redesigned levels; do not describe Levels
  21-45 as "approved" without checking whether the user has actually
  played this Pass 2 version.
- **MAIN CAMPAIGN REBOOT (Pass 1, superseded by Pass 2 above for Levels
  21-45 — historical context for Levels 1-20/46-50, which Pass 2 left
  untouched; see `DECISIONS.md` D64 and
  `CAMPAIGN_DESIGN.md` sections 1a/2/11f/11g/11h).** With the Guided
  Tutorial (T01-T10) now teaching every mechanic in isolation, Campaign
  Levels 1-50 have been rebuilt around a permanent new rule: **the
  Campaign is mechanic-agnostic from Level 1 onward** - it no longer
  spends a stage teaching one new mechanic at a time. Audit of the
  existing 50: **Levels 1-10 and 11-20 KEPT** (both carry real prior
  manual approval); **Levels 21-30, 31-40, and 41-45 REPLACED** (never
  approved; 31-40 had explicit "feels easy" feedback; 21-30/41-45 were
  front-loaded mechanic-introduction levels no longer appropriate now
  that Tutorial covers that); **Levels 46-50 KEPT** (already
  combination-focused and escalating; **Level 50 "Paradox" — the user's
  explicitly named quality benchmark — is UNCHANGED** and remains the
  clear peak of the curve, 255 states vs. every reboot level's own
  figures topping out at 127). Internal `stage_01/`-`stage_05/` folder
  organization and `LevelManager.CAMPAIGN_LEVEL_PATHS` ordering were
  **not touched** — only specific files' contents were rewritten; the
  player only ever sees "Level 1"-"Level 50," never stage names. 25
  levels (21-45) were hand-designed and solver-validated in 5 batches;
  24/25 matched their hand-traced intent on the first solver pass, one
  (Level 30) needed a color-tracking fix after the solver correctly
  caught an `UNSOLVABLE` authoring mistake. **50/50 solver PASS, 50/50
  runtime-replay PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.**
  **NOT YET MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING**
  for all 50 levels; do not describe any of Levels 1-50 as "approved"
  without checking whether the user has actually played this rebuilt
  version.
- **TUTORIAL v1 (`versionCode=18`) MANUAL ANDROID QA FAILED.** The user
  opened T01 on a real device: no gameplay tiles were visible on first
  open (empty board), pressing RESET made the tiles suddenly appear, and
  even after Reset there was no tutorial instruction/message visible, no
  visible highlight, and the tutorial mirror could not be rotated —
  **effectively softlocked**. Root cause: two hand-written `.tscn` files
  (`scenes/ui/tutorial_panel.tscn`, `scenes/ui/tutorial_complete_popup.tscn`)
  declared their scripts as `ext_resource`s but never attached them to
  their root node via `script = ExtResource(...)` — so `%TutorialPanel`
  resolved to a plain `Control` with none of `tutorial_panel.gd`'s
  members, and `game.gd._ready()` crashed the instant it tried to
  connect `_tutorial_panel.continue_pressed`, aborting the rest of
  `_ready()` (including the call to `_load_current_level()`) before any
  tiles were ever loaded or the tutorial ever started. **FIXED at
  `versionCode=19`** — see `DECISIONS.md` D61.
- **TUTORIAL v2 (`versionCode=19`) MANUAL VIDEO QA found two visual
  bugs** (not a repeat of the v1 failure — tiles/instruction/interaction
  all worked): the board stayed heavily darkened during
  `REQUIRE_TILE_TAP` and the required mirror was hard to see under it,
  and the darkening wasn't reliably clearing. Investigation found **no
  dim overlay had ever existed in the Tutorial system** — the real bug
  was a plain outline highlight with too little contrast against full
  gameplay art. **FIXED at `versionCode=20`**: added
  `TutorialDimOverlay` (a board dim with a fully transparent cutout
  around the highlighted tile, so that tile stays at full brightness
  instead of just "less dark"), strengthened the highlight ring, coupled
  both tightly to the existing `set_highlight()`/`clear_highlight()`
  calls (no new state machine, no stale-dim window possible), fixed
  Pause-menu double-dimming (`suspend_tutorial_focus()`/
  `resume_tutorial_focus()`), and fixed an adjacent z-order bug where
  `TutorialPanel` rendered on top of `PauseMenu`. See `DECISIONS.md` D62
  for the full writeup, including the real-rendering technique used to
  objectively prove the fix (pixel-luminance sampling showed the
  highlighted tile ~2.5-3x brighter than its dimmed neighbors).
  See `DECISIONS.md` D62 for the full writeup.
- **TUTORIAL v3 (`versionCode=20`) MANUAL VIDEO QA found the highlighted
  mirror could be SEEN but not TAPPED** — repeated taps at
  `REQUIRE_TILE_TAP` did nothing, the tutorial never advanced. Root
  cause: `game.tscn`'s `TutorialPanel` instance node redundantly
  re-declared `anchors_preset = 15` (full-screen) on top of
  `tutorial_panel.tscn`'s own correct bottom-anchored layout, making the
  panel's `Panel` child (default `mouse_filter = STOP`) silently cover
  the **entire screen** and intercept every tap before it could reach
  any tile — invisible because the panel's 88%-opaque dark background
  blended into BeamShift's already-dark art. Found by dumping *runtime*
  `mouse_filter`/`get_global_rect()` values for every Control between
  the Viewport and the highlighted tile (not trusting `.tscn` source),
  exactly as instructed. **FIXED at `versionCode=21`**: removed the
  conflicting override so `TutorialPanel` correctly inherits its own
  ~220px bottom band; also set `Panel`'s `mouse_filter = IGNORE`
  (hardening, only `ContinueButton` itself can consume a tap now);
  added a highlight/allowed-cell mismatch fail-safe; expanded the QA
  debug overlay with live LAST TAP/HIGHLIGHT/ALLOWED tracking via a new
  `GridManager.tile_tap_attempted` signal. **GUIDED TUTORIAL MODE —
  T01-T10, IMPLEMENTED, AUTOMATED VALIDATION COMPLETE (INCLUDING A
  RUNTIME ANCESTOR-CHAIN HIT-TEST DUMP PROVING THE INTERCEPTING NODE
  BEFORE/AFTER, AND GENUINE OS-LEVEL MOUSE INPUT OBSERVED REACHING AND
  BEING ACCEPTED BY THE CORRECT TILE), ANDROID EXPORTED AT
  `versionCode=21`, MANUAL QA PENDING FOR ALL THREE FIXES TOGETHER — DO
  NOT MARK APPROVED UNTIL THE USER CONFIRMS ON A REAL DEVICE.** See
  `TUTORIAL_SYSTEM.md` for the full architecture, `DECISIONS.md` D60 for
  the original implementation writeup, D61 for the runtime fix, D62 for
  the visual fix, and D63 for this input fix.
- **DEVELOPMENT/QA UNLOCK-ALL IS CURRENTLY ENABLED** —
  `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`. Every
  currently-implemented campaign level (1-50) is selectable from Level
  Select regardless of real unlock progress — confirmed automatic, no
  code changes were needed when Stage 5 was added (driven by
  `get_campaign_level_count()`). This does **not** touch `SaveManager`'s
  real completion/star/best-move data or its unlock progression in any
  way — only Level Select's card `disabled` state is affected. See
  `DECISIONS.md` D58. **MUST be set back to `false` in
  `scripts/managers/level_manager.gd` before any final production
  release build** — tracked as a release-checklist item in
  `TEST_PLAN.md`.
- **Campaign is now mechanic-agnostic (post-reboot) — the "Stage =
  teaches one mechanic" framing below is HISTORICAL.** Internal folder
  names (`stage_01/`-`stage_05/`) still exist on disk for organization
  only; the player only ever sees "Level 1"-"Level 50." See
  `DECISIONS.md` D64 and `CAMPAIGN_DESIGN.md` sections 1a/2/11f/11g/11h.
- **Levels 1-10 (folder `stage_01`): MANUALLY APPROVED, KEPT UNCHANGED
  by the reboot.** The user played it for real on their own device and
  confirmed "the starting levels are good." Do not modify unless a
  genuine regression is found.
- **Levels 11-20 (folder `stage_02`): MANUALLY APPROVED FOR CAMPAIGN
  CONTINUATION, KEPT UNCHANGED by the reboot.** User feedback: "these
  are looking good." See `DECISIONS.md` D55/D64. Do not modify unless a
  genuine regression is found.
- **Levels 21-30 (folder `stage_03`): REPLACED TWICE — Pass 1 (the
  reboot) then Pass 2 (Difficulty Rework).** Pass 1's splitter-only
  content was never approved; Pass 2 (current, see `DECISIONS.md` D65)
  replaced it again after Pass 1's own solver-confirmed moves
  (3,2,2,2,2,5,2,2,3,6) proved too easy for its curve position. Current
  optimal-move curve: 5,6,5,6,6,7,8,6,7,7. **NOT YET MANUALLY APPROVED.**
- **Levels 31-40 (folder `stage_04`): REPLACED TWICE.** Pass 1 had
  **explicit user feedback: "feels easy"** even after its own rebuild;
  Pass 2 (current) replaced it again, curve now 6,7,6,5,7,9,9,6,9,11.
  **NOT YET MANUALLY APPROVED.**
- **Levels 41-45 (folder `stage_05`, first half): REPLACED TWICE.**
  Pass 1's "expert-tier" claim didn't match its own solver-confirmed
  2,4,2,2,3 curve; Pass 2 (current) replaced it again, curve now
  8,9,10,7,11 — the hardest block in the whole 1-50 curve by
  states_explored. **NOT YET MANUALLY APPROVED.**
- **Levels 46-50 (folder `stage_05`, second half): KEPT UNCHANGED by
  the reboot — including Level 50 "Paradox," the user's own explicitly-
  named quality benchmark (255 states explored).** Already combination-
  focused and escalating; no strengthening was needed since every
  reboot level was deliberately kept below its 255-state peak. See
  `DECISIONS.md` D59/D64 and `CAMPAIGN_DESIGN.md` section 11e for the
  original implementation writeup. **NOT YET MANUALLY APPROVED.**
- **Stages 6-10 do not exist yet** — do not create them without being
  explicitly asked. Stage 6 ("Quantum Gates") introduces portals/
  non-linear routing — do not add portal mechanics, switches/gates,
  hazards, or a second emitter to any Stage 5 level.
- **Validation status:**
  - AUTOMATED PASS (headless `--import` clean; 15/15 dev-level, 10/10
    each of Stage 1/2/3/4/5 solver+runtime-replay regression all PASS —
    50/50 total campaign)
  - FILTER CORRECTNESS + MULTI-FILTER-CHAIN + SOLVER/RUNTIME PARITY
    VERIFIED (temporary headless fixture: single-filter recolors from
    WHITE and from another color, a 2-filter chain correctly solving its
    true target and correctly failing a wrong one, color preservation
    through a rotatable mirror/fixed mirror/both splitter branches, and
    confirmation a `FILTER` is never part of the solver's rotatable
    bitmask — parity holds by construction)
  - REAL-RUNTIME VALIDATED (a temporary driver with live autoloads
    confirmed `get_campaign_level_count() == 50`; Level 41 and Level 50
    both load correctly with `stage == "Filters"`; completing Level 40
    unlocks Level 41; sequential unlock through 41-50 confirmed;
    `campaign_highest_unlocked_level` correctly stays at 50 after
    completing Level 50 — no Level 51 is ever offered; Stage 1-4
    progress and the dev-level save fields stayed untouched throughout;
    QA unlock-all automatically covered all 50 levels with zero code
    changes)
  - EXPORTED-PACKAGE VALIDATED (all 50 campaign level files, `filter.gd`/
    `filter.tscn` and every other referenced tile script/scene, and
    `LevelManager.CAMPAIGN_LEVEL_PATHS` itself all confirmed present and
    loadable against a real `--export-pack` output; dev tooling
    confirmed still excluded)
  - ANDROID EXPORTED (fresh APK built and signed: `versionCode=17`,
    `versionName="1.5.0-STAGE5-QA"` for Stage 5; superseded by
    `versionCode=18`/`"1.6.0-TUTORIAL-QA"` below)
  - **ANDROID MANUAL QA PENDING (Stages 3, 4, AND 5)** — no
    physical-device confirmation of any of the three yet. Nothing may be
    marked "Android verified" or "Android QA passed" for any of them
    until the user performs this and says so explicitly. Stages 1-2's
    manual approval stands on its own and does not need re-confirming.
- **Zero gameplay-engine, UI-layout, or export-filter changes this
  pass** — only 10 new level-data files and 10 new entries appended to
  `LevelManager.CAMPAIGN_LEVEL_PATHS`. No architecture changes were
  needed; everything D54/D55/D56/D57/D58 built for Stages 1-4 (and the
  QA-unlock flag) scaled to Stage 5 by construction. See `DECISIONS.md`
  D59 for the full filter-mechanics audit performed before any level was
  designed.
- **Guided Tutorial Mode validation status (v1, `versionCode=18`,
  historical — kept for context on what the failed QA actually
  exercised):**
  - AUTOMATED PASS (T01 full step-machine test: `MESSAGE` locks input,
    `REQUIRE_TILE_TAP` restricts to one tile and silently rejects every
    other tap, a correct tap cascades through `REQUIRE_TILE_TAP ->
    WAIT_FOR_PUZZLE_SOLVED -> MESSAGE -> finished` correctly;
    `SaveManager`'s `tutorial_*` fields confirmed fully isolated from
    both `campaign_*` and dev-level fields in both directions;
    `get_tutorial_level(11) == null` with a graceful warning)
  - ALL 10 TUTORIAL BOARDS CONFIRMED SOLVABLE (each T01-T10 replayed
    through a real `GridManager` via its own intended move sequence —
    10/10 PASS)
  - REAL-RUNTIME VALIDATED, EXPORTED-PACKAGE VALIDATED, FULL EXISTING
    REGRESSION RE-CONFIRMED, ANDROID EXPORTED — all as previously
    recorded. **None of this caught the real bug** — every automated
    check drove the tutorial step machine and grid state directly by
    method call, never through a real, freshly-instantiated `game.gd`
    scene the way a player's first tap on "TUTORIAL" actually does. See
    `DECISIONS.md` D61 part "why automated PASS missed it."
  - **ANDROID MANUAL QA: FAILED.** See the root-cause summary above and
    `DECISIONS.md` D61 for the full writeup.
- **Guided Tutorial Mode validation status (v2 fix, `versionCode=19` —
  current):**
  - ROOT CAUSE FIXED: `scenes/ui/tutorial_panel.tscn` and
    `scenes/ui/tutorial_complete_popup.tscn` now correctly attach their
    scripts (`script = ExtResource("1")` on the root node).
  - FAIL-SAFE ADDED: `GridManager.has_orientable_tile()` +
    `TutorialManager`'s `REQUIRE_TILE_TAP` handling now refuse to lock
    input to a tile that doesn't exist — logs a loud `push_error` and
    leaves input unrestricted instead of softlocking silently.
  - TEMPORARY QA DEBUG OVERLAY ADDED: a small on-screen label, visible
    only when `GameManager.is_tutorial_mode` is true, showing `TUTORIAL
    QA`, the current step number, input mode, and target cell — never
    shown in Campaign. Meant to be removed once Tutorial is manually
    approved.
  - REAL RENDERED REPRODUCTION (non-headless, per `CLAUDE.md` 12d):
    reproduced the original crash before the fix, confirmed it
    disappeared after the fix, and captured a real screenshot of T01's
    first frame after switching into tutorial mode showing the grid,
    beam, emitter, "Welcome to BeamShift." message, and "TAP TO
    CONTINUE" button all present with no Reset needed.
  - ALL 10 TUTORIALS (T01-T10) STARTUP RE-VALIDATED against the real
    `game.tscn` instantiation path (the exact path that caught the
    original bug) — 10/10 PASS, zero script/runtime errors.
  - T01 LIFECYCLE VALIDATED: Reset x3 in a row from mid-tutorial each
    correctly returns to step 0 with 3 tiles and the panel visible (no
    duplicated UI/highlights); Pause -> Resume preserves the exact
    current step; Pause -> Restart resets to step 0 cleanly.
  - FULL EXISTING REGRESSION RE-CONFIRMED (15/15 dev-level + 50/50
    campaign, 65/65 total, solver-vs-runtime-replay all PASS; 10/10
    tutorial-board solvability re-confirmed) — zero Campaign regression.
  - ANDROID EXPORTED (fresh APK built and signed: `versionCode=19`,
    `versionName="1.6.1-TUTORIAL-FIX"`).
  - **ANDROID MANUAL RE-QA PENDING (superseded by the v3 visual fix
    below — the device test never happened at `versionCode=19`).**
- **Guided Tutorial Mode validation status (v3 visual fix,
  `versionCode=20` — current):**
  - Manual video QA found: the board stayed heavily dimmed during
    `REQUIRE_TILE_TAP` with the required mirror hard to see, and the dim
    wasn't reliably clearing. Investigation confirmed no dim overlay had
    ever existed in the Tutorial system — see `DECISIONS.md` D62.
  - `TutorialDimOverlay` (new) draws a board dim with a fully
    transparent cutout around the highlighted tile — the tile itself
    stays at full brightness, not just "less dark." `TUTORIAL_DIM_ALPHA`
    is one constant (0.52) in one place.
  - `TutorialHighlight` strengthened (brighter cyan-white, thicker
    border, higher min alpha) and now sized `FOCUS_PADDING` (10px)
    larger than the tile — both the ring and the dim's cutout read this
    same constant, so they can never drift apart.
  - Dim is coupled 1:1 to the existing `set_highlight()`/
    `clear_highlight()` calls — no new step-type branching needed, since
    no existing tutorial sets a highlight during a
    `WAIT_FOR_TARGET_ACTIVATION`/`WAIT_FOR_PUZZLE_SOLVED` step (verified
    directly against all 10 tutorial files).
  - Pause double-dimming fixed: `GridManager.suspend_tutorial_focus()`/
    `resume_tutorial_focus()` hide/restore the tutorial dim around
    Pause's own independent dim, so the two never stack.
  - **Found and fixed an adjacent bug**: `PauseMenu` was an earlier
    sibling than `TutorialPanel` in `game.tscn`, so the tutorial
    instruction panel rendered ON TOP of Pause when opened mid-tutorial.
    Reordered so `PauseMenu` is always last (topmost).
  - `_clear_tutorial_focus_visuals()` added as the one authoritative
    highlight/dim cleanup path, called at every tutorial exit point
    (completion, restart, back-to-select, back-to-main-menu, scene
    teardown) — defense-in-depth on top of the fact `clear_highlight()`
    already runs on every real step transition.
  - REAL RENDERED VALIDATION (per `CLAUDE.md` 12d): screenshots captured
    across the full T01 sequence including a Pause-during-dim moment;
    pixel-luminance sampling (done after correctly reading this
    environment's actual window geometry, not the assumed 1080x1920 —
    see D62) objectively confirmed the highlighted tile is ~2.5-3x
    brighter than its dimmed neighbors, and a cropped/zoomed screenshot
    visually confirms a clearly brighter tile with a visible cyan ring.
  - AUTOMATED: a headless driver walked every step of all 10 tutorials
    (covering every tile type any tutorial highlights) asserting
    highlight/dim stay exactly in sync with each step's
    `highlight_position`, and both clear after the tutorial's last step
    — **10/10 PASS**, zero mismatches.
  - FULL EXISTING REGRESSION RE-CONFIRMED (15/15 dev-level + 50/50
    campaign, 65/65 total) — zero Campaign regression.
  - ANDROID EXPORTED (fresh APK built and signed: `versionCode=20`,
    `versionName="1.6.2-TUTORIAL-VISUAL-FIX"`; superseded by
    `versionCode=21`/`"1.6.3-TUTORIAL-INPUT-FIX"` below).
  - **ANDROID MANUAL QA: this build's own tap-input bug (see below)
    means the dim/highlight itself was never actually confirmed
    reachable by a real tap in the field.**
- **Guided Tutorial Mode validation status (v4 input fix,
  `versionCode=21` — current):**
  - Manual video QA found: the highlighted mirror at `REQUIRE_TILE_TAP`
    was clearly visible but repeated taps did nothing - the tutorial
    never advanced.
  - Root cause found by dumping **runtime** `mouse_filter`/
    `get_global_rect()` values (not `.tscn` source) for every Control
    between the Viewport and the highlighted tile: `game.tscn`'s
    `TutorialPanel` instance node redundantly re-declared
    `anchors_preset = 15` (full-screen) on top of
    `tutorial_panel.tscn`'s own correct bottom-anchored layout, making
    its `Panel` child (default `mouse_filter = STOP`) silently cover
    the entire screen and intercept every tap - invisible because the
    panel's 88%-opaque dark background blended into the already-dark
    gameplay art.
  - FIXED: removed the conflicting override so `TutorialPanel`
    correctly inherits its own ~220px bottom band; hardened `Panel`
    itself to `mouse_filter = IGNORE` (only `ContinueButton` can
    consume a tap now); added a highlight/allowed-cell mismatch
    fail-safe in `TutorialManager`; expanded the QA debug overlay with
    live `HIGHLIGHT:`/`ALLOWED:`/`LAST TAP:` tracking via a new
    `GridManager.tile_tap_attempted` signal.
  - RENDERED: a runtime ancestor-chain dump confirmed `TutorialPanel`/
    `Panel` covered the full screen before the fix and only the correct
    ~220px band after; a hit-test candidate search at the highlighted
    tile's exact screen position confirmed those nodes were removed
    from the blocking-candidate list. Separately, genuine OS-level mouse
    input observed during this investigation (not synthetically
    generated by any test script) reached `MirrorTile._gui_input()` and
    was accepted at the correctly-restricted cell - real, if incidental,
    end-to-end confirmation. This project's own synthetic `push_input()`/
    `Input.parse_input_event()` dispatch still doesn't reliably reach
    `_gui_input()` in this test harness (reconfirmed against a plain
    `Button` too) - a known, pre-existing limitation (`CLAUDE.md` 12a).
  - AUTOMATED (bounded, real signal-chain): for every `REQUIRE_TILE_TAP`
    step reached along each tutorial's natural forward path (T01-T10), a
    wrong-cell tap is rejected and the correct-cell tap is accepted and
    advances via the real `move_made` signal chain (never bypassed) -
    **10/10 PASS**.
  - FULL EXISTING REGRESSION RE-CONFIRMED (15/15 dev-level + 50/50
    campaign, 65/65 total, plus 10/10 tutorial-board solvability) - zero
    Campaign regression.
  - ANDROID EXPORTED (fresh APK built and signed: `versionCode=21`,
    `versionName="1.6.3-TUTORIAL-INPUT-FIX"`).
  - **ANDROID MANUAL QA PENDING** for the D61 runtime fix, D62 visual
    fix, and this D63 input fix together - none has been confirmed on a
    real device session yet. **Tutorial must not be marked manually
    approved until that happens.**
- **Prior fix, still relevant context:** `blocker.gd`/`hazard.gd`
  previously referenced tile textures from the export-excluded
  `assets/gameplay/pieces/`, breaking Levels 3/5/12/15's visible tiles on
  Android — fixed several passes ago (`versionCode=9`), unaffected by
  this pass. See `DECISIONS.md` D51/D52.
- **Exact next action:** the user performs **physical Android manual QA
  of the current build** — install `versionCode=34`
  (`2.9.0-PORTRAIT-100-QA`) and play through Levels 76-100 (brand new
  portrait geometry, never played in this layout), confirming the
  bigger/taller boards read well on a real device and that difficulty/
  puzzle feel is unchanged, with special attention to Level 80 ("Full
  Convergence") and Level 95 ("Final Threshold") — the two solver-
  ceiling-adjacent levels — Level 87's three-stage relay, Level 90's
  five-emitter "Full Circuit", and above all **Level 100 ("Culmination")
  — the definitive final puzzle of the entire campaign**, which should
  feel like everything the campaign taught arriving at once, clearly
  readable on its new 10x12 board. **This is now the single most
  important outstanding manual QA task for the whole project**: with
  Phase 2D complete, the ENTIRE 100-level campaign's portrait geometry
  has been changed by an automated tool across four separate passes
  (2A-2D), and NONE of it has yet been confirmed on a real device except
  Levels 1-25's own original (pre-re-layout) content. Levels 1-25's
  (Phase 2A), 26-50's (Phase 2B), and 51-75's (Phase 2C) own portrait
  re-layouts are all still pending their first Android confirmation too
  — ideally this build's manual QA pass should sample across all four
  phases, not just 76-100, precisely because this is the final batch and
  a good moment for an overall verdict on the whole conversion effort.
  Separately, the Guided Tutorial also still needs its own first
  successful manual QA pass (three prior rounds each found a real bug,
  all now fixed but none reconfirmed - see `DECISIONS.md`
  D61/D62/D63) - install the SAME `versionCode=34` build for this too,
  open TUTORIAL -> T01 fresh (no Reset), and confirm
  tiles/instruction/highlight/tap-to-rotate/advancement all work
  correctly end to end. Give explicit feedback on all of the above.
  **The 100-level campaign structure is complete, AND the portrait
  re-layout of all 100 levels is now also complete** - any further
  campaign content (Levels 101+) or further geometry work is new scope,
  not a continuation of the original plan, and needs its own explicit
  request. **Era 2 (Levels 101-200, T11-T20, new mechanics, new visual
  theme) remains documented-only in `ROADMAP.md` and must not be started
  without a separate, explicit request** — the natural next step after
  this pass's manual QA is either fixing anything that QA finds, or
  beginning to discuss Era 2's scope, not silently starting it.
- **Campaign Levels 101+ / a Stage 11, and any further Tutorial
  milestone:** **NOT STARTED, NOT AUTHORIZED.** Do not begin new
  campaign content, add Tutorial levels beyond T10, or start any other
  follow-on work until the user gives explicit feedback and explicitly
  asks for the next step — completing this pass is not itself
  authorization to continue.

## LEVEL POPULATIONS (read this first — it's easy to conflate these)

- **DEVELOPMENT/REGRESSION TEST LEVELS: 1–15** (`levels/level_01.gd` …
  `level_15.gd`). Exist to exercise mechanics and regression-test the
  simulator/editor/solver. **No longer shown to players** — Level Select
  now shows campaign levels exclusively (see `DECISIONS.md` D54). Still
  referenced directly by every regression script and
  `LevelManager.LEVEL_PATHS`; do not delete, rename, or repurpose them.
- **CAMPAIGN LEVELS: 100 created (internal folders stage_01-10, now
  mechanic-agnostic post-reboot) — THE FULL 100-LEVEL CAMPAIGN IS
  COMPLETE.** Player-facing this is simply "Level 1" through "Level
  100," not stage names. `levels/campaign/stage_01/` (Levels 1-10,
  approved, kept), `levels/campaign/stage_02/` (Levels 11-20, approved
  for continuation, kept), `levels/campaign/stage_03/` (Levels 21-30,
  REPLACED TWICE — reboot then Difficulty Rework Pass 2 — pending full
  manual approval), `levels/campaign/stage_04/` (Levels 31-40, REPLACED
  TWICE, pending full manual approval), `levels/campaign/stage_05/`
  (Levels 41-45 REPLACED TWICE, Levels 46-50 kept including the Level
  50 benchmark — **Levels 1-50 as a whole are user-tested and reported
  good**), `levels/campaign/stage_06/` (Levels 51-60, CREATED — no
  mechanic-teaching reset, continues directly from 46-50's difficulty,
  pending manual approval), `levels/campaign/stage_07/` (Levels 61-70,
  CREATED — "advanced expert" tier, no mechanic-teaching reset,
  continues directly from 60's difficulty, pending manual approval),
  `levels/campaign/stage_08/` (Levels 71-80, CREATED — MASTER/MASTER+/
  EXTREME tier, no mechanic-teaching reset, continues directly from
  70's difficulty, pending manual approval), `levels/campaign/stage_09/`
  (Levels 81-90, CREATED — EXTREME/EXTREME+ tier, introduces the first
  three-stage switch/gate relay, no mechanic-teaching reset, continues
  directly from 80's difficulty, pending manual approval),
  `levels/campaign/stage_10/` (Levels 91-100, newly CREATED — MASTER+/
  EXTREME/FINAL CHALLENGE tier, the campaign's final stage, no
  mechanic-teaching reset, continues directly from 90's difficulty,
  pending manual approval) — the real, player-facing production
  campaign (Milestone 4), now feature-complete at its originally-planned
  100 levels. See `CAMPAIGN_DESIGN.md` for the full 100-level structure
  and `DECISIONS.md` D64/D65/D66/D67/D68/D69/D70 for the reboot/rework/
  expansions' full audit/reasoning. **Do not create Campaign Levels
  101+ or a Stage 11 before it's explicitly requested** — that would be
  new scope beyond the original 100-level plan.
- **EDITOR FIXTURES: 6**, under `levels/editor_fixtures/`. Validator/
  solver test cases only — never in `LevelManager.LEVEL_PATHS` or
  `CAMPAIGN_LEVEL_PATHS`, never reachable by a player, excluded from the
  Android export.
- **GUIDED TUTORIAL LEVELS: 10 (T01-T10)**, under `levels/tutorial/`
  (`t01.gd` … `t10.gd`). A completely separate population from both the
  15 dev/regression levels and the 50 campaign levels — never counted
  toward campaign level ids, never sharing `SaveManager` fields with
  either (see `SaveManager`'s `tutorial_*` fields). Reachable only via
  Main Menu's TUTORIAL button → Tutorial Select, never via Campaign
  Level Select. See `TUTORIAL_SYSTEM.md` for the full architecture.

## MILESTONE HISTORY (historical — newest first; see "CURRENT STATUS" above for what's true right now)

**"Guided Tutorial Mode — T01-T10 + Full Menu Integration."** Built from
an explicit, detailed user request for a new, permanent product
structure: a 10-level guided TUTORIAL section, completely separate from
the 100-level CAMPAIGN. Full detail in `DECISIONS.md` D60 and
`TUTORIAL_SYSTEM.md`. Summary:
- Audited every mechanic the brief's T01-T10 plan named against actual
  source before designing anything - **all of them were already fully
  implemented** (portals/switches-gates/hazards/multiple-emitters had
  simply never been used in Campaign yet, proven by dev/regression
  levels 10-13). No tutorial was left pending, no mechanic was faked.
- Built the guided-tutorial architecture: `TutorialStepData`/
  `TutorialLevelData` (new `Resource` subclasses - a tutorial's `tiles`
  are simulated by the identical `LaserSystem`/`GridManager` Campaign
  uses), `TutorialManager` (a `class_name extends RefCounted`,
  deliberately **not** a 4th autoload - `CLAUDE.md` rule 6), forced
  interaction gated at the single existing tap handler
  (`GridManager._on_orientable_tile_clicked()`, via two new inert-by-
  default fields), a pulsing cyan outline-only highlight
  (`TutorialHighlight`), a new instruction panel and completion popup,
  and new `SaveManager` fields (`tutorial_highest_unlocked_level`/
  `tutorial_completed_levels`, `SAVE_VERSION` 2 → 3, additive only).
- Main Menu reordered to CONTINUE / CAMPAIGN / TUTORIAL / SETTINGS /
  QUIT; new Tutorial Select scene (`tutorial_select.tscn`/`.gd`, kept
  separate from `level_select.gd` on purpose - zero Campaign regression
  risk).
- Created all 10 tutorials (`levels/tutorial/t01.gd` … `t10.gd`): First
  Light, Two Turns, Locked In, Both Lights, Split Path, True Color,
  Recolor, Through the Portal, Switch and Gate, Graduation - one per
  named lesson, no gaps.
- **Found and fixed a real signal-timing bug during this feature's own
  testing**: `GridManager.move_made` fires *before* simulation runs, so
  a naive target-activation check would read stale state - fixed with a
  new, purely additive `GridManager.simulation_updated` signal (fires
  *after*), zero effect on `move_made`'s existing Campaign timing.
- Validated: full T01 step-machine test (forced-tile-tap acceptance/
  rejection, cascading step advancement, `SaveManager` isolation both
  directions, `get_tutorial_level(11) == null`); all 10 tutorial boards
  confirmed solvable via their own intended move sequence through a real
  `GridManager`; real scene-instantiation check (Main Menu button order,
  Tutorial Select's 10 cards with correct lock states, Campaign Level
  Select's 50 cards and QA-unlock-all completely unaffected); exported-
  package validation (all 10 tutorial levels + every new script/scene +
  all 50 campaign levels present and loadable); full existing regression
  re-confirmed after every change - 15/15 dev-level + 50/50 campaign
  (65/65 total) solver-vs-runtime-replay all PASS throughout, zero
  Campaign regression at any point.
- New build: `versionCode=18`, `versionName="1.6.0-TUTORIAL-QA"`,
  51,126,659 bytes (+48,992 bytes over the Stage 5 build - larger than a
  typical stage's pure-level-data delta since this added real new
  architecture, not just level data). QA unlock-all kept enabled per
  explicit instruction. **NOT MANUALLY APPROVED - ANDROID MANUAL QA
  PENDING** for the Tutorial (new) and Stages 3/4/5 (still outstanding).

**"Production Campaign Phase 5 — Stage 5: Filters, Campaign Levels
41-50."** Built from an explicit, detailed user request naming Stage 5
by number and scope, carrying the Stage 4 "feels easy" feedback and an
instruction that Stage 5 make a clearly stronger difficulty jump. Full
detail in `DECISIONS.md` D59 and `CAMPAIGN_DESIGN.md` section 11e.
Summary:
- Recorded Stage 4 feedback ("Levels 31-40 feel easy") without
  modifying any Stage 4 level - no bug was found, only a difficulty note
  that shaped Stage 5's curve.
- Audited the `FILTER` tile directly against source before designing
  anything: it has no orientation field and is never rotatable (never
  part of the solver's bitmask), unconditionally overwrites a beam's
  color, and chains as "last filter touched wins" - confirmed with a
  temporary fixture (all 15 assertions passed first run), deleted after
  use.
- Created Stage 5 — "Filters" (campaign levels 41-50) under
  `levels/campaign/stage_05/`: Filter, Shift, Cipher, Channel,
  Conversion, Frequency, Transmute, Waveform, Vortex, Paradox.
- Added the 10 new paths to `LevelManager.CAMPAIGN_LEVEL_PATHS`
  immediately after Stage 4's 10 - zero other architecture changes;
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` automatically covered all 50
  levels with no edits.
- Every level hand-traced against `GridTypes.reflect()` before writing,
  and every hand-trace matched the solver's confirmed `optimal_moves` on
  the first attempt (3,4,4,5,5,6,5,6,6,7) - zero unintended
  `possible_decoys` (Level 50's one intentional decoy at `(3,3)`
  confirmed inert exactly as designed), zero validator errors/warnings.
- States explored ranged 8-255 (vs. Stage 4's 4-64) - Level 50's 255
  states clearly exceeds every prior stage's finale, including Stage
  3's 127.
- Full regression: 15/15 dev-level + 10/10 each of Stage 1/2/3/4/5
  (50/50 campaign) solver-vs-runtime-replay all PASS.
- Real-autoload driver confirmed `get_campaign_level_count() == 50`,
  Level 40 completion unlocks Level 41, sequential unlock through 50,
  `campaign_highest_unlocked_level` correctly caps at 50 (no Level 51),
  Stage 1-4 progress and dev-level save fields untouched.
- Exported-package validation: all 50 campaign levels plus
  `filter.gd`/`filter.tscn` and every other referenced script/scene
  confirmed present and loadable against a real `.pck`; dev tooling
  confirmed still excluded.
- New build: `versionCode=17`, `versionName="1.5.0-STAGE5-QA"`, 51.08 MB
  (+22.3 KB over the QA-unlock build, identical delta to every prior
  stage's growth). QA unlock-all kept enabled throughout, per explicit
  instruction. **NOT MANUALLY APPROVED - ANDROID MANUAL QA PENDING for
  Stages 3, 4, AND 5.**

**"Development Test Mode — Unlock All Campaign Levels."** Requested so
manual QA of Stages 3/4 doesn't require grinding through earlier levels
every session. Full detail in `DECISIONS.md` D58. Summary:
- Added `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` (`const
  bool`, currently `true`) and `LevelManager.is_campaign_level_
  selectable()`, the single function that reads it. `SaveManager` was
  not modified in any way.
- Changed `level_select.gd`'s one call site from
  `SaveManager.is_campaign_level_unlocked(id)` to
  `LevelManager.is_campaign_level_selectable(id)` - the only other file
  touched.
- Scales automatically to however many campaign levels exist (driven by
  `get_campaign_level_count()`, not a hardcoded `40`) - no changes
  needed when Stage 5+ are added.
- Validated both directions with a real-autoload driver: flag `true` →
  all 40 levels selectable from a fresh save, directly completing Level
  31 or Level 40 alone records only that level (no false completions,
  no fake stars/moves, no cascade-unlock); flag `false` → only Level 1
  selectable, normal sequential locking immediately restored, zero save
  changes needed to switch. Flag left `true` afterward, confirmed via
  `grep`.
- New build: `versionCode=16`, `versionName="1.4.1-QA-UNLOCK"`,
  51,055,337 bytes (byte-identical to the Stage 4 build).
  **DEVELOPMENT/QA BUILD - MUST DISABLE THE FLAG BEFORE FINAL RELEASE.**

**"Production Campaign Phase 4 — Stage 4: Spectrum, Campaign Levels
31-40."** Built from an explicit, detailed user request naming Stage 4
by number and scope, while Stage 3 was still pending manual approval —
see `DECISIONS.md` D57 for that context. On top of the "Production
Campaign Phase 3" build (`versionCode=14`, 51.03 MB). Full detail in
`DECISIONS.md` D57 and `CAMPAIGN_DESIGN.md` section 11d. Summary:
- Audited every existing color mechanic directly against source
  (`GridTypes.BeamColor`, `target_accepts_color()`, `LaserSystem`'s
  filter/splitter/mirror handling) before designing anything - confirmed
  color is fixed per-beam-graph with no filters in scope, so Stage 4's
  color reasoning had to come from non-required color-decoy targets.
- Verified color correctness (3 matches, 6 mismatches) and mirror/fixed-
  mirror/splitter color preservation in a temporary headless fixture,
  deleted after use.
- Created Stage 4 — "Spectrum" (campaign levels 31-40) under
  `levels/campaign/stage_04/`: Prism, Wavelength, Refraction, Photon,
  Chromatic, Diffraction, Phase, Radiance, Pulse, Spectral.
- Added the 10 new paths to `LevelManager.CAMPAIGN_LEVEL_PATHS`
  immediately after Stage 3's 10 - zero other architecture changes.
- Every level hand-traced against `GridTypes.reflect()` before writing,
  and every hand-trace matched the solver's confirmed `optimal_moves` on
  the first attempt (2,3,4,4,4,5,5,6,6,6) - zero unintended
  `possible_decoys`, zero validator errors/warnings across all 10.
- Full regression: 15/15 dev-level + 10/10 each of Stage 1/2/3/4 (40/40
  campaign) solver-vs-runtime-replay all PASS.
- Real-autoload driver confirmed `get_campaign_level_count() == 40`,
  Level 30 completion unlocks Level 31, sequential unlock through 40,
  `campaign_highest_unlocked_level` correctly caps at 40 (no Level 41),
  Stage 1-3 progress and dev-level save fields untouched.
- Exported-package validation: all 40 campaign levels plus color/target/
  splitter/mirror/blocker scripts and scenes confirmed present and
  loadable against a real `.pck`; dev tooling confirmed still excluded.
- New build: `versionCode=15`, `versionName="1.4.0-STAGE4"`, 51.06 MB
  (+22.3 KB over Stage 3, identical delta to Stage 3's own growth).
  **NOT MANUALLY APPROVED - ANDROID MANUAL QA PENDING for Stage 4 (and
  still pending for Stage 3).**

**"Production Campaign Phase 3 — Stage 3: Split, Campaign Levels
21-30."** Built after the user manually played Stage 2 and gave
explicit approval ("these are looking good"), on top of the "Production
Campaign Phase 2" build (`versionCode=13`, 51.01 MB). Full detail in
`DECISIONS.md` D56 and `CAMPAIGN_DESIGN.md` section 11c. Summary:
- Created Stage 3 — "Split" (campaign levels 21-30) under
  `levels/campaign/stage_03/`: Divide, Dual Signal, Fork Path, Branch
  Cut, False Fork, Cross Branch, Relay Split, Split Trap, Parallel,
  Fracture. First stage to introduce splitters and multiple required
  targets as a core mechanic, per the user's explicit "difficulty from
  reasoning about beam branches, not from adding pieces" directive.
- Splitter and multi-target completion behavior were verified directly
  against `LaserSystem`/`GridManager` source **before** any level was
  designed (not assumed from the campaign brief) — see `DECISIONS.md`
  D56 for the full verification writeup. Both matched existing
  documentation exactly.
- Level 21 is the sole, explicitly-sanctioned exception to "every
  target needs a move" (its straight-through target is free by design,
  to teach the splitter's unconditional straight branch) — every other
  level (22-30) requires at least one move per target. Levels 26, 28,
  and 30 build genuine cross-branch dependency by routing both the
  straight-through beam and the reflected branch through one shared
  mirror tile from different directions; Level 30 combines this with
  backward reasoning using a *fixed* shared mirror.
- Optimal-move curve 2,3,4,4,4,4,4,5,5,6 — starting below Stage 2's
  floor (Level 21's tutorial) and climbing past its ceiling (5) by the
  finale; `states_explored` ranging 4-127 (vs. Stage 2's 8-120), well
  within the solver's safety limit throughout.
- One real level-authoring mistake (not an architecture bug) was caught
  by the solver, not by hand-tracing: Level 30's first draft authored
  one mirror already in its solved orientation, so the solver found a
  5-move solution skipping it entirely — fixed by correcting its
  authored orientation to the intended wrong starting state, restoring
  the designed 6-move finale. Every other level matched its hand-traced
  intent exactly on the first solver pass.
- Zero architecture, engine, UI, or export-filter changes needed —
  everything D54/D55 built for Stages 1-2 scaled to Stage 3 by simply
  appending 10 more paths to `LevelManager.CAMPAIGN_LEVEL_PATHS`.
  Confirmed `assets/gameplay/splitter/**`'s pre-existing export
  exclusion is safe (the splitter has zero texture dependency — pure
  procedural `_draw()`, see `CLAUDE.md` rule 10).
- Validated three independent ways: 30/30 total campaign (10/10 each
  stage) + 15/15 dev-level solver+runtime-replay regression PASS; a
  real-autoload runtime driver confirmed the Stage2→Stage3 boundary
  (`get_campaign_level_count() == 30`, correct `has_next` before/after
  Level 30) without writing to real save data; the exported package was
  re-verified to contain all 30 campaign levels, the splitter's script/
  scene, and every other referenced tile resource correctly.
- New build: `versionCode=14`, `versionName="1.3.0-STAGE3"`, 51.03 MB
  (+22.3 KB — pure level data, no new assets). **IMPLEMENTED, AUTOMATED
  VALIDATION COMPLETE, ANDROID EXPORTED, MANUAL PLAYTEST PENDING** — not
  manually approved. This pass's own completion is not authorization to
  start Stage 4.

**"Production Campaign Phase 2 — Stage 2: Reflection, Campaign Levels
11-20."** Built on top of the manually-approved Stage 1 ("the starting
levels are good"), on top of the "Production Campaign Phase 1" build
(`versionCode=12`, 50.99 MB). Full detail in `DECISIONS.md` D55 and
`CAMPAIGN_DESIGN.md` section 11b. Summary:
- Created Stage 2 — "Reflection" (campaign levels 11-20) under
  `levels/campaign/stage_02/`: Redirect, Dead End, Fork Point, Reverse
  Trace, Mirage, Cascade, Backtrack, Echo Path, Interference,
  Culmination. Built per the user's explicit directive that difficulty
  come from reasoning/misdirection/route-planning, never from grid size,
  mirror count, clutter, or padded move counts.
- Exactly 3 levels (14, 17, 20 — the precise set requested) use backward
  reasoning: a fixed mirror beside the target only redirects correctly
  from one approach direction, rewarding a player who traces backward
  from the target rather than forward from the emitter. Levels 16 and 20
  are explicitly built around multi-step dependency (an early mirror's
  correct orientation only makes sense once the full downstream chain is
  understood).
- Optimal-move curve 3,3,3,3,4,4,4,5,5,5 — starting at Stage 1's own
  peak (4) and climbing to 5; `states_explored` ranging 8-120 vs. Stage
  1's 2-57, a genuine, unpadded difficulty increase confirmed by the
  solver, not asserted.
- Zero architecture changes needed — everything built for Stage 1 in
  `LevelManager`/`SaveManager`/`game.gd`/`level_select.gd` scaled to
  Stage 2 by simply appending 10 more paths. Specifically verified (not
  assumed) that Level 20's Level Complete popup correctly has no Next
  Level button, since no Level 21 exists — the existing generic
  `has_next` check in `game.gd` already handles this with zero new code.
- Two real level-design mistakes (not architecture bugs) were caught and
  fixed *before* ever running the solver, by re-deriving each path by
  hand against `GridTypes.reflect()`'s table at write time: an early
  Level 11 draft had a target unreachable by its own mirror chain; an
  early Level 12 draft placed a blocker on a cell no beam configuration
  could ever reach, making it decorative rather than a real guard.
- Validated three independent ways: 20/20 total campaign (10/10 Stage 1
  + 10/10 Stage 2) + 15/15 dev-level solver+runtime-replay regression
  PASS; a real-autoload runtime driver played all 20 campaign levels in
  order confirming the Stage1→Stage2 unlock boundary and Level 20's safe
  end-of-content behavior; the exported package was re-verified to
  contain all 20 campaign levels correctly.
- New build: `versionCode=13`, `versionName="1.2.0-STAGE2"`, 51.01 MB
  (+18.2 KB — pure level data, no new assets). **IMPLEMENTED, AUTOMATED
  VALIDATION COMPLETE, ANDROID EXPORTED, MANUAL PLAYTEST PENDING** — not
  manually approved. This pass's own completion is not authorization to
  start Stage 3.

**"Production Campaign Phase 1 — Campaign Architecture + Real Levels
1-10."** The real 100-level campaign begins, on top of the "APK
Optimization + Asset Cleanup" build (`versionCode=11`, 50.97 MB). Full
detail in `DECISIONS.md` D54 and `CAMPAIGN_DESIGN.md`. Summary:
- Defined the complete 100-level architecture (10 stages × 10 levels,
  mechanic progression, difficulty philosophy, optimal-move/grid-size
  guidelines, production-acceptance criteria) in the new
  `CAMPAIGN_DESIGN.md` — the standing reference for every future stage.
- Created Stage 1 — "First Light" (campaign levels 1-10) under
  `levels/campaign/stage_01/`, newly designed (not copied from the dev
  levels), each teaching one specific concept: rotation, chained
  reflection, multiple mirrors, blockers, fixed mirrors, plausible
  forks, a first decoy, long-route planning, and a finale combining
  every mechanic. Every level's `optimal_moves` is solver-confirmed, not
  guessed; zero levels needed rejection/redesign after the first solver
  pass.
- Kept campaign levels a fully separate population from the 15 dev/
  regression levels (`levels/level_01.gd`-`level_15.gd`, untouched) in
  both level storage and save data — added `LevelManager.CAMPAIGN_LEVEL_PATHS`
  and `SaveManager`'s `campaign_*` fields as parallel, additive
  structures alongside (never replacing) the originals, specifically
  because both populations' level ids start at 1 and would otherwise
  collide in the same save keys.
- Repointed `game.gd`/`level_select.gd`/`GameManager`/`main_menu.gd`'s
  normal-play paths to the campaign data; a real integration bug
  (`main_menu.gd`'s Continue button still reading the old dev-level save
  fields) was found and fixed during this rewiring, not just guessed at.
- Validated three independent ways: 10/10 campaign + 15/15 dev-level
  solver+runtime-replay regression PASS; a real-autoload runtime driver
  confirmed the actual Main Menu → Level Select → Game → solve →
  SaveManager-write → Next Level flow end to end; the exported package
  was re-verified to contain all 10 campaign levels and all 15 dev
  levels correctly.
- New build: `versionCode=12`, `versionName="1.1.0-STAGE1"`, 50.99 MB
  (+17.8 KB — pure level data, no new assets). **UPDATE: subsequently
  MANUALLY APPROVED** by the user ("the starting levels are good") —
  see "CURRENT STATUS" at the top of this file and the "Production
  Campaign Phase 2" entry above for what came next.

**"APK Optimization + Asset Cleanup."** Explicitly-requested, staged,
safety-first size optimization on top of the "Final HUD Alignment +
Level Complete Delay" build (`versionCode=10`, 113.1 MB). Two passes,
zero gameplay/level-data/scoring/UI-layout changes: (A) a from-scratch
asset reference-map audit found the shipped APK actually predated
several exclusion rules already sitting in `export_presets.cfg` from
prior sessions — a plain re-export recovered 39.57 MB with zero content
changes; (C) 21 gameplay-tile/icon assets were found shipping at
1254×1254 source resolution while displaying at 26-250px on screen
(5x-48x oversampled) — created downscaled `_runtime.png` derived copies,
rewired every reference, kept originals on disk unused/excluded,
recovering a further 22.59 MB. Final: `versionCode=11`,
`versionName="1.0.0-OPTIMIZED"`, **50.97 MB (55% below the `versionCode=10`
baseline)**. Verified via a real exported `.pck` (not just source) after
every pass — all referenced/derived assets present, all excluded/
superseded masters absent, Levels 3/5/12/15's Blocker/Hazard/Switch/
Gate/Portal tiles all instantiate correctly. DESKTOP RENDERED screenshots
of all 6 key screens confirmed no visible quality loss. 15/15 solver +
15/15 runtime-replay regression PASS throughout. The temporary "HUD +
DELAY FIX" QA build-marker label was also removed this pass (no longer
needed once superseded). See `DECISIONS.md` D53 and `TEST_PLAN.md`'s
"APK Optimization + Asset Cleanup" section for full detail, including a
newly-documented gotcha in the exported-package verification technique
(must run from a directory with no `project.godot` in its parent chain).
**ANDROID MANUAL QA PENDING** — this is the next required step; nothing
about this pass authorizes moving on to the 100-level campaign or any
further optimization on its own.

**"Final HUD Alignment + Level Complete Delay."** Small polish pass on
the "Android HUD Alignment + Missing Tile Fix" build. Re-measured the
bottom HUD's Reset/Pause slots via a pixel flood-fill and found the
horizontal placement was already accurate; the residual "slightly off"
look was a ~6px vertical offset, now corrected. Added a tunable 0.8s
delay (`game.gd`'s `LEVEL_COMPLETE_DELAY`) between solve detection and
the Level Complete popup appearing, so the player sees the final beam/
target-activation state first - the solve calculation itself stays
immediate; only the popup is delayed. Further moves during the delay
were already rejected by a pre-existing `GridManager` guard. Zero
puzzle/level/scoring changes. New build: `versionCode=10`,
`versionName="1.0.0-HUDDELAY"`. See `CHANGELOG.md`'s "Final HUD
Alignment + Level Complete Delay" section. **ANDROID MANUAL QA
PENDING.**

**"Android HUD Alignment + Missing Tile Fix."** The user's first real
Android manual QA pass found HUD alignment issues plus a serious bug:
Level 3's puzzle tiles were invisible on Android (laser beam and
background still visible). **Root cause found and fixed without physical
Android hardware**, by actually exporting and running the real package
headlessly instead of testing from source: `blocker.gd`/`hazard.gd`
preloaded textures from the export-excluded `assets/gameplay/pieces/`
folder, which made both scripts fail to parse in any exported build and
silently truncated the tile-loading loop for any level with a blocker/
hazard - **4 of 15 levels affected (3, 5, 12, 15)**, not just Level 3.
Fixed by moving the actually-used art into the already-established
canonical per-type folders and repointing the two scripts; verified three
independent ways including directly unzipping the shipped APK to confirm
the fix. HUD text/alignment also corrected (two clean lines instead of
awkward word-wrap, pixel-measured symmetric slot anchors). Zero gameplay
logic touched - all 15 levels solver+runtime-replay regression still
PASS. New build: `versionCode=9`, `versionName="1.0.0-TILEFIX"`,
"ANDROID TILE FIX" QA label. See `DECISIONS.md` D51/D52 and
`CHANGELOG.md`'s "Android HUD Alignment + Missing Tile Fix" section.
**ANDROID MANUAL QA PENDING** - this is the next required step.

**"Milestone 4A.6 — Corrected Settings Panel Integration + Final UI QA."**
Small follow-up to 4A.5: the user manually supplied a corrected
`bs_panel_settings_portrait.png` (the original was a mislabeled
byte-duplicate of the Level Complete art - D48). Verified independently
(MD5 now differs, gear icon + "SETTINGS" title visually confirmed) and
integrated into `settings_menu.tscn` the same way as Pause/Level
Complete. **All five Milestone 4A.5 replacement assets are now active.**
Build marker updated to "UI FINAL QA". Zero gameplay code touched - all
15 levels solver+runtime-replay regression still PASS. DESKTOP RENDERED
screenshots confirmed Settings now reads correctly (gear icon, "SETTINGS"
title, properly sized, no clipping) and Pause/Level Complete remain
unaffected. New build: `versionCode=8`, `versionName="1.0.0-UIFINAL"`,
APK ≈113.2 MB. **ANDROID MANUAL QA PENDING — this is now the single
remaining gate before any further UI or level-production work.** See
`DECISIONS.md` D50 and `CHANGELOG.md`'s "Milestone 4A.6" section.

**"Milestone 4A.5 — Portrait UI Replacement + Responsive HUD Integration"**
(the user's own brief for this pass called it "Milestone 4A.4" - numbered
4A.5 here only to avoid colliding with the Level 3 re-investigation pass
immediately below, which landed earlier the same day and had already
claimed "4A.4"). Five new portrait UI assets
(`assets/ui/panels/bs_panel_{settings,pause,level_complete}_portrait.png`,
`assets/ui/hud/bs_hud_{top,bottom}_portrait.png`) were integrated.
**Finding:** the Settings asset is a byte-identical mislabeled duplicate
of the Level Complete asset (both say "LEVEL COMPLETE") - Settings was
deliberately left on its old, correct art rather than ship a mismatched
screen; see `DECISIONS.md` D48. Pause, Level Complete, and the gameplay
top/bottom HUD all now use their correct new art; the HUD bars use a new
`AspectBar` resize script (`scripts/ui/aspect_bar.gd`) to keep the new
art's aspect ratio locked without stretching/distorting (D49). The
temporary "L3 DEBUG" overlay was removed (Level 3 confirmed working); the
QA build label is now "UI 4A.4". Zero gameplay regression: all 15 levels
solver+runtime-replay PASS, Level 3 Reset/replay PASS. DESKTOP RENDERED
validation (real screenshots, personally inspected) confirmed no title
duplication, no clipping, correct `mouse_filter` on decorative layers,
and a real click-through still solves Level 3 end to end. New build:
`versionCode=7`, `versionName="1.0.0-UI4A4"`, APK ≈113.1 MB. **ANDROID
MANUAL QA PENDING** - not yet reviewed on a real device. Full detail in
`CHANGELOG.md`'s "Milestone 4A.5" section. **The 100-level campaign must
NOT begin until the user manually approves this UI pass.**

**"Milestone 4A.4 — Level 3 Device/Runtime Re-Investigation."** The user
confirmed BUILD 4A.3 was genuinely visible on their device and Level 3
still failed to complete - ruling out Milestone 4A.3's stale-APK
conclusion. A full re-trace (runtime level resource, tile dump, target
visibility, input path, orientation mapping, a REAL rendered click-driven
test through the actual `_gui_input` path, and a 15-level + reset/replay
regression) found **no code defect** - everything behaved correctly,
matching Milestone 4A.3's findings again, this time via a genuine
click-through rather than a re-assertion. See `CHANGELOG.md`'s "Milestone
4A.4" section for the full trace. A temporary on-screen debug overlay
(Level 3 only: Moves/mirror A+B orientation/Targets/Solved) was added
so the user's own device can report what state it actually reaches -
this is the concrete next diagnostic step if the real device still fails
on this build. New build: `versionCode=6`, `versionName="1.0.0-L3FIX"`,
"L3 FIX BUILD" label on Main Menu/Settings (updated in place from "BUILD
4A.3"). **NOT MANUALLY APPROVED** - needs the user to test this exact
build and, if it still fails, report what the debug overlay shows.

**"Milestone 4A.3 — Runtime Truth Audit + Build Identity + Screenshot
Validation."** Milestone 4A.2 failed manual QA a **third** time,
reporting symptoms the actual project code no longer had. A full audit
(no duplicate project/APK found; file timestamps confirmed the prior APK
genuinely contained the 4A.2 fixes; **real rendered screenshots**,
personally inspected, showed every screen matching the intended
Milestone 4A.2 design, including Level 3 completing via a genuine
simulated click sequence) points to the tested device running a **stale
APK build**, not a code regression. Fixed the actual gap this points to:
Android `version/code`/`version/name` had never been bumped across
4A/4A.1/4A.2 (a real, previously-unexamined risk) — now bumped, plus a
temporary, highly visible **"BUILD 4A.3"** label added to Main Menu and
Settings so the installed build can be confirmed with certainty. See
`DECISIONS.md` D44-D47. **This milestone also discovered non-headless
screenshot capture works on this machine** (never tried before, wrongly
assumed impossible) — this is now a standing capability, see
`CLAUDE.md` rule 12d. **NOT MANUALLY APPROVED** — only the user,
confirming BUILD 4A.3 is visible and then testing for real, can approve
this.

**"Milestone 4A.2 — Level 3 Gameplay Fix + UI Scale Correction"**
(previous).
Milestone 4A.1 failed the user's **second** manual QA on the real
Android/desktop build: (A) Level 3 could not be completed in actual
gameplay - root cause was a real, confirmed bug (`mirror.gd`'s texture
rotation mapping was backwards, shipped in Milestone 4A - see
`DECISIONS.md` D40), now fixed with a one-line change; (B) Pause/
Settings/Level Complete content was still visually squeezed - fixed by
growing content sizing independently of panel art (D42). A new
runtime-vs-solver validation layer was added specifically because the
Level 3 bug was invisible to every check used through Milestone 4A/4A.1
(see D41/D42 and `TEST_PLAN.md`). **NOT MANUALLY APPROVED** - only the
user can approve this after reviewing it. Milestone 4A.1's own summary is
kept below for history but is superseded wherever this section says
otherwise.

**"Milestone 4A.1 — UI Integration Correction Pass"** (previous). Milestone 4A
("Final Asset Integration" — see `ROADMAP.md`'s naming note) **FAILED the
user's manual visual QA** — 14 specific reported problems, most severely
a Reset button icon rendering large enough to cover most of the puzzle
board. Milestone 4A.1 is a targeted correction of that same visual
integration (no new content, no gameplay changes) — root causes and every
fix are documented in `DECISIONS.md`'s "Milestone 4A.1" section (D37-D39).
Implemented and automatically validated (see below). **NOT MANUALLY
APPROVED — only the user can approve this after reviewing it visually
(in-editor and/or on a device).** Do not mark it approved in any document
without that. Milestone 3 (level editor) remains separately, also not yet
manually tested — unrelated to either 4A or 4A.1 (the editor's own grid
view uses plain `Button` cells, not anything either pass touched — see
`ARCHITECTURE.md` "Editor architecture"). Milestones 1 and 2 remain
implementation-complete underneath all of this (Milestone 1 fully
device-validated; Milestone 2 automatically validated with the user's
general go-ahead but no itemized manual-test report — see
`PROJECT_HANDOFF.md`).

## COMPLETED

**Milestone 1** — Core Prototype, fully done including Android device
validation (gameplay + a UI sizing fix, both device-confirmed).

**Milestone 2** — Advanced Puzzle Mechanics: multi-beam/multi-pass
`LaserSystem`, 6 new tile types, beam colors, multiple targets/emitters,
10 new test levels. Automated validation complete.

**Milestone 3** — Level Editor + Puzzle Validation + Difficulty Tooling:
- A development-only level editor (`tools/level_editor/`), run via F6,
  not part of the shipped game
- Visual grid editing (4x4–9x9 tested, architected for other sizes),
  a full tile palette, per-tile-type property panels
- Level metadata fields (ID, name, grid size, optimal moves, stage,
  developer notes)
- `.tres` save/load alongside the existing `.gd` levels, with save
  blocked on structural validation errors
- `LevelValidator` — structural error/warning checks
- `LevelSolver` — real breadth-first search over rotatable-piece
  orientations using the actual `LaserSystem`, reporting solvability,
  optimal move count, solution path, multiple-solution count, and
  possible decoy pieces, with a proven-safe search-limit mechanism
  (`SOLVABLE`/`UNSOLVABLE`/`UNKNOWN`, never a false unsolvable)
- `LevelMetrics` — design metrics + a transparent, explicitly
  non-authoritative difficulty estimate
- A real Playtest button that launches the actual gameplay scene (no
  second/fake simulator), never writes to the player's save data, and
  round-trips back to the editor with in-progress edits preserved
- 6 editor fixture levels covering every solver/validator edge case
- `levels/campaign/` reserved (empty) for Milestone 4
- All 15 existing levels independently re-verified solvable by the new
  solver (and one real level-authoring bug from Milestone 2 is recorded
  as a concrete example of why this matters — see `PROJECT_HANDOFF.md`)

**Milestone 4A — Final Asset Integration** (visual-only, see
`ROADMAP.md`'s naming note):
- Reconciled two unreconciled generated-art sets under `assets/gameplay/`
  into one canonical set per tile type; excluded the unused set from the
  Android export filter rather than deleting it (see `DECISIONS.md` D31)
- 5 of 10 gameplay tile types (mirror, target, blocker, gate, hazard) now
  render final generated art instead of procedural `_draw()`; the other 5
  (emitter, splitter, portal, switch, filter) deliberately stay
  procedural because every available generated asset for them bakes in a
  fixed-direction/fixed-color illustrative beam that would conflict with
  real per-level data (D31) — no image-editing tool was available to
  clean them up safely
- A shared cell-background texture now renders behind every tile,
  including empty cells (previously just a thin grid line)
- A project-wide `Theme` resource (`themes/beamshift_theme.tres`) styles
  every `Button` automatically; Main Menu, Level Select (including a
  fully reworked `level_button.tscn`), Settings, Level Complete, and the
  gameplay HUD all got final backgrounds/panels/icons
- A brand-new Pause menu (didn't exist before) with Resume/Restart/
  Settings/Level Select/Main Menu, opened by a new HUD button or the
  Android system back gesture during gameplay
- Fixed: the Android back button previously had no handler anywhere and
  would silently exit the app via Godot's `quit_on_go_back` default —
  now every top-level screen intercepts it and replicates its own Back/
  Quit button (D34)
- Laser beam rendering polish (brighter core, rounder joins/caps,
  antialiasing) — the beam **simulation data itself is unchanged**
- Lightweight interaction feedback: a mirror-tap pulse, a target-
  activation pulse, a portal idle glow animation
- App icon wired into `project.godot`/`export_presets.cfg` (previously
  the stock Godot icon); Android launcher icon slots populated
- Stage Select and a real Hint system were both deliberately **not**
  built this pass — see `DECISIONS.md` D33 and "Not implemented" below

**Milestone 4A's *layout* of the above FAILED the user's manual QA** —
the assets/systems listed above are the right set of things, but they
were positioned/sized wrong (see Milestone 4A.1 below). Don't read the
list above as "and it looked correct" — it didn't.

**Milestone 4A.1 — UI Integration Correction Pass** (current milestone,
not yet approved — see `DECISIONS.md`'s "Milestone 4A.1" section, D37-D39,
for full root-cause detail):
- Root cause #1: `Button.icon` renders at native PNG resolution with no
  size cap — a 1254×1254 Reset icon inside a 144px-tall button overflowed
  catastrophically, and cascaded into the HUD bars' own size. Fixed: every
  HUD icon is now a fixed 144×144 touch-target `Button` containing a fixed
  64×64 `TextureRect` — Control decides touch size, TextureRect decides
  visual size, permanently decoupled.
- Root cause #2: Pause/Settings/Level Complete panel art already has its
  screen's title baked in; a second, dynamic title `Label` was drawn on
  top of it with margins too small to clear the baked header. Fixed:
  duplicate titles removed, panel `StyleBoxTexture` margins re-measured
  by actually viewing the art.
- Button/panel `StyleBoxTexture` margins were re-measured against the
  real art (not guessed from proportions) — buttons additionally got a
  `region_rect` crop to remove ~20% of transparent glow padding that was
  never accounted for.
- Settings' Sound/Music toggles were rebuilt as a `toggle_mode` `Button` +
  `TextureRect` showing the actual (wide, "ON"/"OFF"-baked) toggle art at
  a legible size, replacing a `CheckButton` that rendered it at
  illegible checkbox-glyph scale.
- Main Menu buttons enlarged with a clear primary/secondary/danger size
  hierarchy, and the logo/button group repositioned to top/bottom
  respectively (away from the background art's bright central focal
  point and baked flavor text — background image itself unchanged).
- Level Select cards fixed to a uniform, non-stretched size; grid
  centered; a bottom spacer added so the last row is fully reachable by
  scroll (root cause of the "clipped bottom row" report was expand-fill
  size flags preventing `ScrollContainer` from computing correct content
  height).
- A project-wide `font_outline_color`/`outline_size` added to the shared
  theme for text legibility against busy backgrounds.

**Milestone 4A.2** (current, not yet approved):
- **Fixed:** Level 3 (and, structurally, every mirror in the game) had
  its visual rotation backwards from its logical orientation
  (`mirror.gd`, one-line fix) — the beam simulation was always correct,
  but the mirror's own drawn diagonal contradicted it, making a
  genuinely solvable level look broken. See `DECISIONS.md` D40.
- **New validation layer:** every regression check through Milestone
  4A/4A.1 only compared solver-computed vs. declared `optimal_moves` —
  both derived from the same pure-logic `LaserSystem`, so a
  presentation-only bug like the above was invisible to it. Added a
  runtime-vs-solver replay check (solver's solution path replayed
  through a real `GridManager`) that would have caught this — now part
  of the standard regression routine. See `TEST_PLAN.md`.
- **UI scale correction:** Settings/Pause/Level Complete content
  (buttons, labels, toggles, stars) grown independently of their panel
  art, not just re-measuring panel margins like 4A.1 did — see
  `DECISIONS.md` D42.
- **New tooling:** a responsive-rectangle validation technique that
  measures real Control rects at 5 target resolutions headlessly
  (comparing against the *logical* canvas, not raw physical pixels — see
  D43) — all 5 pass.

## IN PROGRESS

Nothing implementation-wise. What remains for Milestone 3 is the user's
manual, hands-on use of the editor; what remains for Milestone 4A.2 is
the user's manual desktop/device review and explicit approval (see
"Manual tests still needed" below) — **do not treat Milestone 4A.2 as
approved until that happens.**

## NOT IMPLEMENTED

Everything explicitly deferred: the 100-level campaign itself (Milestone
4), procedural/random level generation (explicitly excluded by design —
see `DECISIONS.md` D30), prisms, movable tiles, timed switches, advanced
optical beam merging, real audio/music (Settings toggles still control
nothing audible — no audio assets were provided), a Stage Select screen
(assets present, unwired — D33), a real Hint system (button present,
hidden — no hint logic exists), a release/signing export workflow, ads,
purchases, analytics, any external SDK.

## KNOWN ISSUES

- **(Production Campaign Phase 1)** The level editor's Load dropdown
  (`tools/level_editor/level_editor.gd`) still only lists
  `LevelManager.LEVEL_PATHS` (the 15 dev levels) plus `editor_fixtures/`
  — it does not yet list `CAMPAIGN_LEVEL_PATHS`. Not a bug (campaign
  levels were authored as plain `.gd` files directly, same as every dev
  level, not through the editor), but worth adding once the editor is
  used to author a future stage, so campaign levels can be loaded back
  in for editing/inspection. Out of scope for this pass ("minimal safe
  integration" was the brief).
- **(Production Campaign Phase 1)** `LevelMetrics`'s auto difficulty
  estimate mislabels early campaign levels as `HARD`/`EXPERT` due to a
  pre-existing "any emitter counts as colored beams" quirk — see
  `CAMPAIGN_DESIGN.md` section 9. Not fixed (shared dev tooling, outside
  this pass's scope); don't mistake the label for a real difficulty
  signal.
- Level Select's 3-column `GridContainer` works at 15 levels, unverified
  at ~100.
- Safe-area edge-widening (vs. baseline margin) still unconfirmed on an
  actual notch/cutout device.
- The editor's grid resize preserves in-bounds tiles rather than
  clearing everything — a deliberate design choice, but one worth
  double-checking matches user expectations once manually tested (see
  `PROJECT_HANDOFF.md`).
- See `PROJECT_HANDOFF.md`'s "Known issues" for the complete list,
  including the genuine level-authoring bug the solver caught.
- **(Milestone 4A)** Two unreconciled generated art sets for gameplay
  tiles were found and resolved by picking a canonical one per tile type
  — see `DECISIONS.md` D31. The unused set (`assets/gameplay/pieces/**`,
  `assets/gameplay/tiles/**`) is excluded from export but still on disk.
- **(Milestone 4A)** 5 of 10 gameplay tile types (emitter, splitter,
  portal, switch, filter) still use procedural rendering, not final art
  — every generated asset for them bakes in a fixed-direction/color
  illustrative beam that would conflict with real level data, and no
  image-editing tool was available this session to clean them up. See
  `DECISIONS.md` D31.
- ~~(Milestone 4A) Button/panel 9-slice margins were a best-effort
  guess~~ — **corrected in Milestone 4A.1** by actually viewing the art
  and re-measuring; see `DECISIONS.md` D37/D38. Still worth a final visual
  check once a human looks at it, but this is no longer a known blind
  guess.
- **(Milestone 4A.1)** The mirror's orientation-to-rotation mapping
  (`BACKSLASH` = 0°, `SLASH` = 90° in `mirror.gd`) is still an unverified
  guess about which rotation matches the source art's default diagonal —
  purely cosmetic, never affects gameplay.
- ~~(Milestone 4A) APK size grew from ~28.4 MB (Milestone 3) to ~107 MB
  after adding ~80 final-art PNGs...~~ — **addressed in the "APK
  Optimization + Asset Cleanup" pass** (`DECISIONS.md` D53): a stale
  export plus 21 grossly-oversized textures accounted for most of the
  growth; current size is 50.97 MB (`versionCode=11`). Every icon/tile
  still uses `Lossless` compression (unchanged — only pixel *dimensions*
  were reduced, not the compression algorithm) except the 3 backgrounds
  (VRAM-compressed since Milestone 4A, unchanged this pass). The 3
  `Button` textures and the Settings/Pause/Level Complete panels were
  deliberately left at their original size/compression (9-slice
  `region_rect`/`texture_margin_*` recompute risk) — still the next
  lever if size ever needs to shrink further.
- **(Milestone 4A)** Settings opened from the new Pause menu returns to
  Main Menu on Back (Settings' existing, unchanged behavior), not back
  into the paused game — a deliberate minimal-scope choice, not a bug.
  No progress is lost either way since nothing saves until a level is
  solved.

## DESKTOP VALIDATION

**Milestone 1: PASSED** (user-confirmed, itemized).
**Milestone 2: not itemized** — only automated validation + the user's
general Milestone 3 kickoff statement that "gameplay is working
correctly," which wasn't a line-by-line manual QA report.
**Milestone 3: NOT YET TESTED** — nobody has opened the editor in Godot
and used it by hand.
**Milestone 4A: FAILED** manual QA (visual integration).
**Milestone 4A.1: FAILED** manual QA a second time — Level 3 uncompletable
in real gameplay, popups still too small. See the "Milestone 4A.2" note
at the top of this file for the fix.
**Milestone 4A.2: NOT YET TESTED** — this correction pass has not been
reviewed by the user. **Milestones 4A.3 through the current "Android HUD
Alignment + Missing Tile Fix" build: DESKTOP RENDERED PASS on each pass**
(real non-headless screenshots, personally inspected) — see "MILESTONE
HISTORY" above for what each pass specifically validated. **None have
progressed to a physical-device review** — see "CURRENT STATUS" at the
top of this file for the current, single manual-QA gate that supersedes
all of these individually.

Automated (headless Godot), current as of Milestone 3:
- Project imports/compiles cleanly, zero errors, including all 3 new
  `scripts/tools/` classes
- All 15 levels solve in their documented optimal move count via both
  the direct-replay test (Milestone 1/2 style) AND the independent
  solver search (Milestone 3) — two different methods agreeing
- All 6 editor fixtures behave exactly as designed (see
  `PROJECT_HANDOFF.md`'s "Validation status" for the full breakdown)
- `.tres` save/load roundtrip confirmed lossless
- The real editor scene driven end-to-end (tile placement, property
  edits, solve, save, load, validation-blocks-bad-save, grid resize)
  through its actual methods with live autoloads
- Real project boots headlessly with zero runtime errors

Automated (headless Godot), added this milestone (Milestone 4A) — see
`TEST_PLAN.md` for exact commands:
- Full `--import` pass: zero errors across every rewritten script/scene
- All 15 levels re-verified via `LevelSolver` **again**, after the tile
  visual rewrite — declared `optimal_moves` still matches the solver's
  independently-computed value for every level (simulation logic was
  never touched, but this confirms it, not just assumes it)
- A synthetic scene-level smoke test: instantiated the real `grid.tscn`,
  loaded Level 15 (the most tile-diverse level — emitter, mirror, target,
  portal, switch, gate, hazard), clicked an orientable tile, and resized
  the grid — zero script errors from any of the 5 rewritten
  texture-based tile visuals or the new interaction-feedback Tweens
- `game.tscn`, `level_select.tscn`, and `settings_menu.tscn` each booted
  headlessly with real autoloads (via the documented temporary
  `run/main_scene` swap, reverted immediately after each) — zero script
  errors from the new HUD/Pause menu/theme/reworked level-button wiring
- Android debug export succeeded with zero errors; manifest re-confirmed
  (`screenOrientation=1`, correct package id/SDK versions, adaptive
  launcher icon slots populated from the new app icon)

Automated (headless Godot), added this milestone (Milestone 4A.1) — see
`TEST_PLAN.md` for exact commands:
- Full `--import` pass: zero errors across every corrected scene/script
- All 15 levels re-verified via `LevelSolver` **again**, after the layout
  correction pass — identical results to Milestone 4A/3 (no simulation
  code was touched this pass either)
- `game.tscn`, `settings_menu.tscn`, and `level_select.tscn` each booted
  headlessly with real autoloads (temporary `run/main_scene` swap,
  reverted after each) — zero script errors from the rebuilt HUD icon
  buttons, the reworked Settings toggle widgets, or the level-select
  card/grid restructure
- Android debug export re-ran successfully with zero errors

Automated (headless Godot), added this milestone (Milestone 4A.2) — see
`TEST_PLAN.md` for exact commands:
- Level 3 root-cause diagnosis: direct-call replay of the solver's
  2-move solution through a real `GridManager` confirmed simulation/
  target/reset logic was never broken; a real `InputEventMouseButton`
  test confirmed `--headless` mode cannot dispatch to `_gui_input`
  (a documented Godot limitation, not a bug); direct visual inspection
  of the mirror art confirmed the rotation mapping was backwards
- New runtime-vs-solver technique: all 15 levels' solver solutions
  replayed through a real `GridManager`, all reach `is_solved == true`
  after the fix
- New responsive-rectangle validation: real Control rects measured at
  5 target resolutions, compared against the logical canvas size — all
  pass (bounds, touch targets, no grid/HUD overlap)
- `game.tscn`/`settings_menu.tscn` re-booted with real autoloads after
  the Part B sizing changes — zero errors
- Android debug export re-ran successfully with zero errors

## ANDROID VALIDATION

**Milestone 1: PASSED** (device-confirmed, including the UI fix).
**Milestone 2: build re-exported successfully; new mechanics never
device-tested.**
**Milestone 3: build re-exported successfully with the new dev-tooling
excluded from the APK; nothing Milestone-3-specific applies on-device
since the editor never ships** — Android validation for this milestone
is really just "did the export filter change break anything," which the
successful re-export answers.
**Milestone 4A: build re-exported successfully; failed the user's manual
visual review once actually looked at** — a clean export was never proof
the layout was correct, and it wasn't. **Milestone 4A.1: build re-exported
successfully; failed a SECOND manual review** — Level 3 uncompletable in
real gameplay (a genuine bug, not a false alarm — see D40), popups still
too small. **Milestone 4A.2: build re-exported successfully; failed a
THIRD manual review reporting the same symptoms** — but a full audit
(D44) found the code already correct by this point (confirmed via
rendered screenshots, D45/D46) and pointed to a stale APK install as the
likely cause, not a fresh code bug. **Milestone 4A.3 (historical): fresh build
exported (old APK deleted first, per instruction) with a version bump
(`versionCode` 1→5, `versionName` "1.0"→"1.0.0-4A.3") and a visible
"BUILD 4A.3" QA label, specifically so a stale-install ambiguity can
never recur silently; never installed on a physical device.** That build
is superseded — see "CURRENT STATUS" at the top of this file for the
current `versionCode`/`versionName`/QA label. Package id
`com.beamshift.game`, `arm64-v8a`, min SDK 24 / target SDK 36 have been
unchanged since Milestone 4A.3 through the current build.
`export_presets.cfg`'s `exclude_filter` (as of `versionCode=10`, before
this milestone's own additions) started with:
`tools/**,scripts/tools/**,levels/editor_fixtures/**,assets/gameplay/pieces/**,assets/gameplay/tiles/**,assets/branding/app_icon/**,assets/ui/icons/bs_icon_hint.png,assets/ui/icons/bs_icon_pause.png,assets/ui/icons/bs_icon_reset.png`
— see `DECISIONS.md` D31 for why `pieces/`/`tiles/` are excluded, and D51
for why `blocker.gd`/`hazard.gd` no longer reference anything under
`pieces/`. The "APK Optimization + Asset Cleanup" pass (D53) added many
more entries (the 5 procedural-tile-type art folders, superseded UI
panels, the stage-select set, orphan icons, and the 21 original-
resolution masters superseded by derived `_runtime.png` files); see
`export_presets.cfg` itself for the exact current string rather than
trusting a copy of it here, which will drift. Neither the "Production
Campaign Phase 1" (D54) nor "Production Campaign Phase 2" (D55) passes
touched any export-filter entries — every campaign level file is a
plain, small `.gd` script with no asset dependencies, correctly included
by default (not matched by any exclude pattern). APK path:
`builds/android/beamshift-debug.apk` (not tracked by version control —
this project has no git repository at all, see below). **Current size:
51,010,677 bytes (51.01 MB)** (`versionCode=13`, +18.2 KB over the Stage
1 `versionCode=12` build's 50.99 MB — see "CURRENT STATUS" at the top
and `DECISIONS.md` D53/D54/D55).

Subsequent milestones (4A.4 Level 3 re-investigation, 4A.5 portrait UI
replacement, 4A.6 corrected Settings panel, "Android HUD Alignment +
Missing Tile Fix", "Final HUD Alignment + Level Complete Delay", "APK
Optimization + Asset Cleanup", "Production Campaign Phase 1", and
"Production Campaign Phase 2") each re-exported the APK with their own
version bump — see "MILESTONE HISTORY" above for each one's specifics,
and "CURRENT STATUS" at the top of this file for the current,
authoritative build info. **The "Production Campaign Phase 1" build
(`versionCode=12`) was the first to receive physical-device manual QA —
PASSED, per the user's Stage 1 approval.** No build after it
(`versionCode=13`, the current Stage 2 build) has been installed on a
physical device yet; ANDROID MANUAL QA for Stage 2 specifically is
PENDING.

## MANUAL TESTS STILL NEEDED (current)

**Stages 1-2 are done — the user already played and approved both.**
None of the following have been performed yet on Stage 3, current
`versionCode=14` build — see `TEST_PLAN.md`'s "Production Campaign Phase
3" section for the full checklist. **This is the review that determines
whether Stage 3 is approved — nobody but the user can close this out:**
- **Install the current APK** (`versionCode=14`, `"1.3.0-STAGE3"` — no
  visible QA build-identity label exists on this build; check
  `versionCode` via the device's app-info screen if in doubt whether the
  install updated).
- **Play Level Select** — confirm it now shows exactly 30 levels (not
  20), with Levels 1-20 in whatever completed/star state Stages 1-2's
  own playthrough left them in, and only Level 21 additionally unlocked
  at first (assuming Level 20 was completed during Stage 2 testing).
- **Play through Campaign Levels 21-30 in order, for real** (not via the
  solver) — for each, confirm against `CAMPAIGN_DESIGN.md` section 11c's
  design table:
  - The level actually teaches what its `developer_notes` say it should.
  - **Level 21 specifically:** confirm the splitter tutorial reads
    clearly — the straight branch reaching Target A with zero moves
    should feel like a deliberate demonstration, not a bug.
  - **Cross-branch dependency (Levels 26, 28, 30):** confirm the shared
    mirror genuinely reads as "one decision serves both branches," and a
    player can't solve each target as an independent mini-puzzle.
  - **Backward reasoning (Levels 27, 29, 30):** confirm the fixed mirror
    beside a target genuinely rewards "trace backward from the target."
  - **Decoys/false routes (Levels 24, 25, 27, 28, 29, 30):** confirm
    they read as plausible, not obviously irrelevant or randomly placed.
  - Solving awards the expected star count and correctly unlocks the
    next level.
- **Confirm the overall stage feels noticeably trickier than Stage 2**
  without feeling padded, unfair, or artificially inflated, and that
  difficulty comes from reasoning about branches rather than piece
  count — this is the specific outcome the user's Stage 3 brief asked
  for.
- **Level 30 specifically:** confirm it feels like a genuine finale —
  harder than Level 20 (Stage 2's own finale) — and that completing it
  does not crash, hang, or attempt to load a nonexistent Level 31
  (AUTOMATED/REAL-RUNTIME validation already confirmed the Next Level
  button is correctly absent — this step is confirming the same thing
  reads correctly to a real player, not re-testing the mechanism).
- **Confirm Continue** (Main Menu) correctly resumes at the first
  incomplete campaign level after playing at least one from Stage 3.
- General interaction sanity check: Reset, Pause, Back, Settings, Level
  Complete's Retry/Next Level/Level Select buttons all still work exactly
  as before (unaffected by this pass, but worth a real-device glance).

## NEXT MILESTONE

Stage 4 ("Spectrum," campaign levels 31-40 — see `ROADMAP.md`/
`CAMPAIGN_DESIGN.md` — the first stage to introduce colored beams and
targets). **Waiting for the user to manually play Stage 3 on their own
device and give explicit feedback before Stage 4 is even considered** —
completing Stage 3 is not itself authorization to start Stage 4,
introduce color mechanics, or begin any other follow-on work (matching
this project's standing pattern: every phase here has been explicitly
requested, none self-directed). If Stage 3's feedback requests changes,
address only what's reported — don't preemptively touch Stage 1/2/3
levels that weren't flagged, and don't start Stage 4 as part of a
Stage 3 fix.
