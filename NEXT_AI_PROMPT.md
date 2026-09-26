# NEXT_AI_PROMPT.md

Tool-independent continuation prompt (Codex, Claude, or any coding agent). It replaces the need for any chat history.
Written 2026-09-25 at the Claude -> Codex handoff. Source authority is the REPOSITORY: if this file and the code disagree, the code wins; fix the doc.

---

## 0. Ready-to-run prompt

You are continuing development of **BeamShift** (Godot 4.7.1, GDScript, Android/portrait-first deterministic laser-reflection puzzle) on branch **`dev_abhilas`**.

**Current repo overlay (2026-09-26): S4 external-test cleanup pass 1 has started.** `BuildConfig.BUILD_MODE` is `MODE_EXTERNAL_TEST`, which makes `QA_TOOLS` false and hides internal QA UI while preserving all QA systems for `MODE_INTERNAL_QA`. Android metadata is `versionCode=70`, `versionName="4.8.4"`. No APK/AAB/TestFlight artifact has been built or uploaded.

**Current task: PHASE S3.1 - V5 J/K DIFFICULTY REFINEMENT (Levels 2601-3000), manual approval gate.** Not S4. Do not build an APK unless the user explicitly approves S4 after manual V5 play.

Read first, in order: `CLAUDE.md` (esp. "V5 generator rules"), `CURRENT_STATUS.md`, `PROJECT_HANDOFF.md`, this file, `DECISIONS.md` (D108, D109, D110), `ARCHITECTURE.md`, `PROCEDURAL_GENERATION.md` (section 20), `TEST_PLAN.md` (last section), `CHANGELOG.md`, `TUTORIAL_SYSTEM.md`, `ROADMAP.md`. Then run `git status`, `git log -1`, and read the code listed in section 6.

Hard rules (do not violate):
- Stay on `dev_abhilas`. **Do not commit, push, merge, reset, clean or switch branches** unless the user explicitly asks.
- **Do not build an APK; do not change `versionCode`/`versionName`.**
- **Do not modify V1-V4 output** (re-run the fingerprint, section 9). Do not loosen the J/K targets before trying the architectural improvements below.
- Preserve `GridManager.MAX_COLUMNS = 8`, square tiles, mobile readability. No padding, no clutter, no giant boards.
- Preserve Hint, Hint attention pulse, AdMob (rewarded Hint, interstitial cadence), stars (`StarScoring`), Fusion, New Game, save/Continue, T01-T34, audio, unified blue theme, HUD calibration, Level Complete popup fix. Do not redesign them.
- Delete any temporary driver/scratch files before finishing; update the docs when done (section 11).

## 1. Project state (verified from the repository at handoff)

- Branch `dev_abhilas`, HEAD `20c2947` ("BeamShift full project checkpoint"). **Nothing from S1/S2/S3 is committed** (git proves it: 32 modified tracked files, 37 untracked entries at handoff).
- **S1 COMPLETE**: mechanic `TileType.SPLITTER_SELECTOR` + 6 puzzles behind Main Menu "SELECTOR TEST" (`SelectorQaSet`, `levels/selector_qa/`), `scripts/tools/selector_verify.tscn`.
- **S2 COMPLETE**: tutorials T29-T34 (`levels/tutorial/t29.gd`-`t34.gd`), hand-authored hint entries `t29`-`t34` in `levels/hint_solutions.json`, `scripts/tools/selector_tutorial_verify.tscn`.
- **S3 IMPLEMENTED / DESKTOP S3.1 VERIFIED / AWAITING MANUAL APPROVAL**: generator V5 (Levels 2001-3000) exists and generates; `MAX_LEVEL`/`INITIAL_CERTIFIED_LEVEL_TARGET` = 3000 (the CURRENT boundary, not a permanent ceiling); 2000 -> 2001 works; V1-V4 fingerprints unchanged; Selector frequency targets met; Save/Continue, Hint, stars, QA +50 (through 3000) work. **S3.1 final verification completed split deterministic J/K windows: J 50/50 generated with `band_demoted=4` (8.0%); K 50/50 generated with `band_demoted=0`. Do not start S4 until the user manually approves the V5 TEST difficulty/readability.**
- **S4 (Android APK) NOT STARTED and must wait for S3.1 + the user's manual approval.**
- `export_presets.cfg` is modified but that modification is PRE-EXISTING and NOT from S1/S2/S3 (`version/code=69`, `version/name="4.8.3-OFFICE-BRANCH-QA"` vs committed 68 / `4.8.2-HINT-ATTENTION-PULSE-QA`). Leave it alone.

## 2. Version ownership

V1, V2, V3, V4: **frozen** (a saved puzzle always regenerates under its saved version). V5 = post-2000 Selector-capable progression. Levels <= 2000: existing compatible versions (default new play V4 under the QA flags, else V3/V2). Levels 2001-3000: V5 (`LevelManager.procedural_generator_version_for_new_play(level)`, unconditional for level >= 2001). `ProceduralLevelGenerator.GENERATOR_VERSION` (default) is still 2. 3000 is the current boundary; future versions may continue past it.

## 3. S3 measured results (bounded samples, NOT guarantees)

50-level windows, stride 4 (5 parallel processes, timings slightly inflated):

| Band | Levels | Selector share (target) | moves avg (band) | demoted | Selector dropped | avg gen ms (max) |
|---|---|---|---|---|---|---|
| G | 2001-2200 | 42% (35-45) | 21.2 (20-24) | 0/50 | 0 | 1501 (4916) |
| H | 2201-2400 | 50% (45-55) | 22.8 (22-26) | 5/50 | 0 | 1682 (2902) |
| I | 2401-2600 | 58% (55-65) | 24.0 (24-28) | 9/50 | 1 | 1848 (3408) |
| J | 2601-2800 | 62% (60-70) | 24.8 (26-30) | 26/50 | 3 | 1979 (3581) |
| K | 2801-3000 | 71% (65-75) | 25.6 (28-34) | 31/48 | 4 | 2306 (5209) |

Depth avg G-K 11.0/11.9/12.9/13.7/14.6; 0 fallbacks; greedy beam-following solved **0/250** accepted levels (a heuristic only). "Demoted" = accepted only under the reasoning floors of the band BELOW (`band_demoted`); `moves_below_band` marks levels under the move floor.

**S3.1 pass 1 update (Codex, 2026-09-25):** implemented S-M ("Selector -> target continuation") using the existing `TM`/`target` site, added it to J/K selector pools, raised `MAX_ATTEMPTS_V5` to 64, kept J demotion at 32 attempts, and gave K a stricter 48-attempt runway before band demotion. V1-V4 fingerprint stayed identical (`271eb766be20a12446676a947b49a3f1`). Post-change bounded windows with `hist=1`, `budget=90000`: J generated 36/50 before budget, `band_demoted=3` (8.3%); K generated 37/50 before budget, `band_demoted=0` (0%). 0 fallbacks and greedy accepted 0 in both. **Remaining issue:** full 50-level J/K windows still exceed the QA budget, and phone generation time/readability remain unmeasured.

**S3.1 final verification update (Codex, 2026-09-25):** no generator redesign or target loosening after pass 1. Full-equivalent deterministic split windows with `hist=1`: J = 50/50 generated, `band_demoted=4` (8.0%), shortcut rejections 5, minimality rejections 3, greedy accepted 0/50, fallbacks 0, avg gen 1950.1 ms, max 3522 ms; K = 50/50 generated, `band_demoted=0`, shortcut rejections 6, minimality rejections 17, greedy accepted 0/50, fallbacks 0, avg gen 2551.6 ms, max 5383 ms. QA budget root cause is dev-only verification overhead: final shortcut probe dominates, then repeated build/probe/minimality/check work from rejected candidates. Late-game manual QA set: 2500, 2647 (nearest Selector-bearing replacement for non-Selector 2651), 2800, 2900, 3000. Selector QA passed; Fusion QA set passed via bounded temp verifier; 2000/2001/3000 boundary and `MAX_COLUMNS=8` reconfirmed. `selector_tutorial_verify`/bounded T29-T34 smoke were attempted but did not complete in the practical headless QA window; prior S2 evidence remains the exhaustive source.

Other findings (sample measurements, not guarantees):
- `verified_optimal_moves` = -1 for every V5 level (exact optimum UNKNOWN at 20+ moves; `v5_verify` touched-tile BFS proves small levels only); `StarScoring` therefore uses `intended_moves`.
- Replay through a real GridManager found (a) superfluous tile GROUPS in ~14% of unscreened Mastery boards and (b) 9-14-flip alternative solutions in ~2% of Entry/Branching boards. Fixed with `ProceduralMinimality` + one final wide probe, but they remain screens: an independent 6000-simulation/80-width probe still found a shortcut in ~3/72 Interlock-Consequence-Mastery levels (~4%, 12 flips vs 24+); random-order ddmin found a superfluous group in ~1/157 sampled levels. V4 has the same class (1/40 sampled) and is frozen.
- Mastery boards are dense (38-57 tiles of 88); **phone readability is NOT verified**.
- **Android generation time is NOT measured** (desktop ~1.5-2.3 s average, worst ~5.2 s; the final probe is ~1 s/level, minimality ~0.25 s/level; a phone is likely several times slower). Caching/prefetching the generated level is the obvious mitigation and is not built.
- Physical limit: 28+ moves with depth 15+ needs ~65+ tiles on an 8x11 board (>75% occupancy); the composer fails 60-90% of such layouts. 8x12 is NOT comfortable (94 px < 96 px).

## 4. Difficulty philosophy (prominent - keep it)

Difficulty must come from: dependencies, interaction, backward reasoning, shared resources, colour requirements, convergence, delayed consequences, fair misleading routes, multi-stage cause/effect.
NOT from: tiny cells, giant boards, random clutter, padding rotations, meaningless mirrors, excessive blockers, trial-and-error guessing.
`MAX_COLUMNS` stays 8; tiles stay square and mobile-readable. **A genuinely difficult 25-move puzzle beats a padded 30-move puzzle** - but do not lower the J/K targets before the architectural improvements below have been tried and measured. The question a manual tester should be able to answer "yes" to: does the puzzle require thinking about WHY a route must be chosen, not merely WHERE the beam points.

## 5. S3.1 objectives/status

1. Reduce J/K demotion (preferred <= 10% each) by improving the generator, not the labels. **Done in desktop split-window verification: J 8.0%, K 0%.**
2. Strengthen reasoning complexity and coupled dependencies; improve Selector downstream dependencies.
3. Implement the missing Selector families where useful (section 7), and a **fair decoy/bait-route architecture** (a wrong Selector state that looks productive - lights something or reaches a mechanic - but breaks a later requirement; the current consequence metric only approximates this).
4. Strengthen minimality and shortcut screening (residual leaks above) without blowing generation time; consider a cheaper/better probe strategy, seeded multi-order ddmin, exact checks on small sub-boards.
5. Keep boards readable and within `v5_tile_budget`; consider generation-time reduction/caching as a S4 prerequisite (measure, do not guess).
6. Preserve V1-V4 fingerprints, all existing systems, MAX_COLUMNS 8.

Ideas already identified (not tried): tile-cost-aware plan search that picks the family that FITS instead of rejecting late; composing Selector chains as the main depth source (a Selector is a node at zero extra tiles); improving atoms with 75-90% layout failure (SO/SH/PG/FU3/FUF) instead of down-weighting them; a bait builder that adds a fair decoy without clutter; lowering per-attempt cost so more attempts fit the same time; making the strict-band rules (`V5_STRICT_SELECTOR_FROM` 2601) hold under demotion.

## 6. Files/systems to inspect first

`scripts/procedural/`: `procedural_difficulty_contract.gd` (bands G-K, `SELECTOR_POLICY`, `selector_policy`), `procedural_progression_v3.gd` (V5 branch: rolls, density fit, ladder `V5_DEMOTE_AFTER(_SELECTOR)`, `V5_RELAX_GRACE`, `V5_STRICT_SELECTOR_FROM`, final probe, minimality), `procedural_fragments_v3.gd` (`SELECTOR_FRAGMENTS`, `roll_selector`, `_apply_selectors`, `_collect_sites`, `V5_LAYOUT_WEIGHT`, `v5_tile_budget`, `V5_MOVE_RELAX_FRACTION`), `procedural_composer_v3.gd` (`kind "selector"`, `_bias_selector`, `harden` + `_selector_state_solves`), `procedural_board_v3.gd` (`Cursor.to_selector_turn`), `procedural_selector_check.gd`, `procedural_minimality.gd`, `procedural_complexity.gd` (4-state tap distance, Selector kind), `procedural_shortcut_probe.gd`, `procedural_generator_v3.gd` (`_check`), `procedural_v5_qa_set.gd`. Runtime: `scripts/gameplay/laser_system.gd` (Selector rule, only place), `game.gd` (V5 TEST, QA tag), `game_manager.gd`, `level_manager.gd`. Dev tools (never exported): `scripts/tools/v5_sample.tscn`, `v5_verify.tscn`, `selector_verify.tscn`, `selector_tutorial_verify.tscn`. Docs: `PROCEDURAL_GENERATION.md` section 20 and `DECISIONS.md` D110 hold the architecture and evidence.

## 7. Selector families

Implemented (13): SA Selector->Filter, SB ->Portal, SC ->Switch->Gate, SD ->Receiver->Remote, SE ->Fusion input, SF two Selectors->two Fusion inputs, SG Prism->Selector->colour route, SH ->One-Way, SJ ->Portal->Receiver->Remote, SL Selector in front of a Gate, **SM Selector->target continuation**, SN Selector on a Splitter branch, SP Fusion output + input Selectors. SC/SL/SN/SM can still drop when no suitable site survives layout.

Not implemented (S3.1 candidates): **S-I** Selector + shared-resource dependency; **S-K** Selector chooses apparent target progress versus a prerequisite (bait); **S-O** two Selectors with indirect/coupled dependency.

## 8. Splitter Selector (final mechanic behaviour)

`TileType.SPLITTER_SELECTOR` (enum appended, never renumber). Four states; the orientation IS the selected output `Direction` (`tile_orientations`, `TilePlacement.direction` initial). One incoming beam, exactly one outgoing beam through the selected side, colour preserved, same pass, stateless (recomputed in the real `LaserSystem`; nothing latches). Each tap rotates the output one step clockwise; one tap = one move. A beam entering THROUGH the selected output side is absorbed. Save/Continue restores it via the orientation; Hint supports it generically; the mirror rotation SFX is reused. `SplitterSelectorTile` only draws; `LevelSolver` cannot model it (use brute force). A Selector on a straight line is bypassed by removal - it must TURN the beam to matter. Assets: `res://assets/gameplay/splitter_selector/bs_splitter_selector.png`, `.../bs_splitter_selector_active.png`, `res://assets/ui/icons/bs_splitter_selector_icon.png` (the icon is unused: the tutorial panel has no icon support). **Do not delete these untracked assets.**

Tutorials: T29 "Select Path", T30 "Choose Output", T31 "Sel + Filter", T32 "Sel + Portal", T33 "Sel + Fusion", T34 "Sel Trial". T29 becomes selectable at procedural Level 1900 (`SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL`); T30-T34 sequential; tutorials are ad-free; QA builds unlock all; hint entries are hand-authored.

## 9. Regression requirements (after ANY change under scripts/procedural/**)

- **V1-V4 fingerprint**: a temporary driver hashing every tile + the solution for ~33 levels x versions 1-4 (levels 1,5,10,20,21,50,51,100,101,150,200,201,300,400,401,500,700,701,900,1000,1001,1200,1300,1301,1450,1600,1601,1700,1800,1801,1900,1950,2000) - hash before and after, must be IDENTICAL (nothing but `hash()` of a string of tile fields; run twice for determinism first). A scene is required (autoloads), not `--script`.
- `v5_sample.tscn`: anchors (2001,2050,...,3000 every 50), per-band windows (`from= count=50 stride=4`), `hist=1`, `wide=1|big`, `family=XX`, `nosel=1`. `v5_verify.tscn` for determinism + Selector brute force + exact search where feasible.
- **Replay the intended solution through a real GridManager** (`GridManager._on_orientable_tile_clicked` until solved: taps must equal `intended_moves`) - this, not the audits, is what exposed the group-redundancy bug (CLAUDE.md rule 12c technique).
- Real-game checks: Save/Continue (level, version 5, seed, every orientation, move count, hint-used), Hint on a wrong Selector, stars (3 at OPTIMAL, hint caps at 2), QA +50 (1951->2001, 2951->3000, 3000 no-op), 2000->2001, levels 1-15 solver, T01-T34 load, SELECTOR TEST / FUSION TEST, `selector_tutorial_verify`.
- Keep every command under ~60 s (`timeout`; a parse error hangs headless Godot); check for orphaned Godot processes; no full 2001-3000 audit; report `QA_BUDGET_EXCEEDED` instead of running on. Godot binary on the user's machine: `D:\Godot_v4.7.1-stable_win64.exe` (`--headless --path . res://scripts/tools/<tool>.tscn -- key=value`). Temporary drivers go in an export-excluded folder (`_qa_tmp/`) and are deleted afterwards. Never name a PowerShell helper `Rd`/`Ri`/`Rm`/`Cp`/`Mv`.

## 10. Manual QA (V5 TEST: Main Menu "V5 TEST", in-game "NEXT V5"; no saves/stars/ads)

Levels: 2001, 2050, 2201, 2351, 2500, 2647, 2800, 2900, 3000. Level 2651 was checked in the final pass but generated without a Selector; 2647 is the nearest Selector-bearing replacement (tie with 2655, chosen for stronger downstream evidence). The label may show `~DEMOTED`. Inspect especially 2500+, 2800, 2900, 3000: the player should have to reason WHY a route must be selected, not merely where the beam is pointing. The user does the manual play; do not claim approval.

## 11. Documentation and git requirements

When S3.1 is done update: CLAUDE.md, README.md, CURRENT_STATUS.md, PROJECT_HANDOFF.md, ROADMAP.md, DECISIONS.md (new decision), ARCHITECTURE.md (must stay present and non-empty), TEST_PLAN.md, CHANGELOG.md, PROCEDURAL_GENERATION.md, TUTORIAL_SYSTEM.md, NEXT_CLAUDE_PROMPT.md, this file. State measured numbers as sample measurements. Report `git status` at the end. Do not commit or push.

## 12. Stop condition

Stop when the user has manually approved or rejected the V5 TEST difficulty/readability. **Do not start S4, do not build an APK, do not commit.**

## 13. First instruction

Run `git status`, `git log -1`, read the files in the order above, then prepare/run the user's manual V5 TEST approval checklist. Do not redo generator tuning or S4 unless the user explicitly asks.
