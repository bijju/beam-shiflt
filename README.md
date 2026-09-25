# BeamShift

A mobile-first, portrait-oriented laser-reflection logic puzzle built in
Godot 4. Rotate mirrors and splitters on a grid to route one or more
colored laser beams from their emitters to their targets, through
filters, portals, switch-linked gates, and around hazards. Easy rules,
increasingly hard solutions.

## Status

**This section is a chronological narrative that has not been kept
current every pass — see `CURRENT_STATUS.md` for the authoritative,
up-to-date snapshot (currently Phase 4 - production cleanup: centralized
star scoring with a Hint cap, one QA/production switch (`BuildConfig`),
Fusion tutorials T21-T28 polished, `versionCode=57`,
`4.7.0-STARS-PRODUCTION-QA`; earlier passes below).** Notably: Main Menu's main-progression button is now
`PLAY` (not `CAMPAIGN`), Level Select is QA/dev-only (see `DECISIONS.md`
D85), the campaign now has 140 legacy levels across Era 1 (1-100) and
Era 2 (101-140) reachable only via QA Level Select, `PLAY`/`CONTINUE`
now target 2,000 procedurally-generated levels instead (see
`PROCEDURAL_GENERATION.md`), and a centralized `AudioManager` now
provides 22 gameplay/UI SFX (see `AUDIO_SYSTEM.md`) — none of which the
50/100-level campaign narrative below reflects.

The core puzzle framework (deterministic grid/laser simulation, save/
progression) is implemented, along with the level editor/solver tooling
(Milestone 3), a full portrait UI integration pass (final art for Main
Menu, Level Select, Settings, Pause, Level Complete, and the gameplay
HUD), and a completed APK size optimization pass (113.1 MB → 50.97 MB -
see `DECISIONS.md` D53). **The real 100-level production campaign is
underway** (`ROADMAP.md` Milestone 4): Stage 1 - "First Light" (campaign
levels 1-10) and Stage 2 - "Reflection" (campaign levels 11-20,
deepening the same mechanics with stronger misdirection, backward
reasoning, and route-dependency puzzles) are both **manually approved**
by the user ("the starting levels are good"; "these are looking good").
**Campaign Levels 21-50 have since been through a full reboot** (see
`DECISIONS.md` D64): with the Guided Tutorial now teaching every
mechanic in isolation, Campaign no longer teaches a mechanic per stage
- it's mechanic-agnostic from Level 1 onward, testing combinations and
reasoning instead. Levels 21-30 ("Split" folder), 31-40 ("Spectrum"
folder, after explicit "feels easy" feedback), and 41-45 ("Filters"
folder, first half) were replaced entirely with harder, freely-combined
puzzles; Levels 46-50 are unchanged, including Level 50 "Paradox" - the
user's own named quality benchmark (255 states explored), which every
other level is now measured against. Stage folder names on disk
(`stage_01`-`stage_05`) are internal organization only; players just
see "Level 1" through "Level 50." All 50 are live under
`levels/campaign/` and directly selectable via the development-only
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` flag (`DECISIONS.md` D58),
**manual difficulty approval pending for the whole rebuilt 1-50.** See
`CAMPAIGN_DESIGN.md` for the full campaign architecture and design
tables, and `DECISIONS.md` D54/D55/D56/D57/D59/D64 for how campaign
levels are kept separate from the 15 development/regression test levels
(which remain under `levels/`, unchanged, no longer player-facing but
still exercised by every regression script). Stage 6 / Campaign Levels
51-100 have **not** been created and will not begin until the rebuilt
1-50 is manually approved.

**A separate, permanent Guided Tutorial section (T01-T10) now exists
alongside the Campaign** - ten scripted, interactive lessons teaching
every implemented mechanic (mirrors, blockers/fixed mirrors, multiple
targets, splitters, colored beams/targets, filters, portals, switches/
gates/hazards, and multiple emitters) through forced player action
rather than just easier puzzles. Tutorial and Campaign share the exact
same `LaserSystem`/`GridManager` simulation - nothing about a mechanic
behaves differently in a tutorial. See `TUTORIAL_SYSTEM.md` for the full
architecture and `DECISIONS.md` D60 for the implementation writeup.
Main Menu now offers CONTINUE / PLAY / TUTORIAL / SETTINGS / QUIT — see
"Direct Play + Continue Flow" below.

The latest build (`versionCode=34`,
`versionName="2.9.0-PORTRAIT-100-QA"`) re-lays out Campaign Levels
76-100's board geometry the same way, applied to the campaign's hardest
and most tile-dense block (up to 42 tiles, up to 16 rotatable pieces at
the practical solver ceiling 2^16=65536, up to 5 emitters, three-stage
relays, a four-source convergence) — **THIS COMPLETES THE PORTRAIT
RE-LAYOUT OF ALL 100 CAMPAIGN LEVELS.** 6 levels compacted 10-wide to
9-wide for a genuine +10% cell-size gain; 15 levels held their exact
cell size while gaining zero-cost row growth to the full safe ceiling
(height utilization 82.6%→99.1%); 4 levels (85, 91, 95, 98) were
deliberately left unchanged, already fully packed on both axes — **not
a difficulty redesign**: the identical order-preserving coordinate
remap mathematically guarantees every level's mechanics/solution/
optimal-move-count are unchanged, solver-confirmed for all 25, zero
manual corrections needed (`DECISIONS.md` D76). Level 100
("Culmination," the definitive Era 1 finale) was fully verified: all
five emitter routes, three relay stages, both portals, symmetric
convergence, and the fixed-mirror backward-reasoning step all confirmed
identical. A final read-only audit across all 100 levels found 100/100
SOLVABLE, zero levels below the 90% height / 85% width utilization
targets, cell sizes 87-174px (avg 122.4px). This builds on
`versionCode=33` (`2.8.2-PORTRAIT-L51-75-QA`), the third re-layout batch
(Levels 51-75, +13.0% cell size, +11.0pt height utilization —
`DECISIONS.md` D75), which built on `versionCode=32`
(`2.8.1-PORTRAIT-L26-50-QA`), the second batch (Levels 26-50, +25.6%
cell size, +13.0pt height utilization — `DECISIONS.md` D74), which
built on `versionCode=31` (`2.8.0-PORTRAIT-L1-25-QA`), the first batch
(Levels 1-25, 94-99.8% height / 86-99.8% width utilization, up from
57-99.8% height — `DECISIONS.md` D73), which built on `versionCode=30`
(`2.7.0-RECT-GRID-QA`), the engine/layout pass that made rectangular
(non-square) boards possible in the first place — `GridManager` fits an
arbitrary `columns x rows` board against the real playable rectangle
between the Top and Bottom HUD bars, instead of assuming a good layout
is always square (`DECISIONS.md` D72). **The complete 100-level
campaign plus the T01-T10 tutorial together constitute Era 1** — a
future Era 2 (Levels 101-200, T11-T20, new mechanics, a new visual
theme) is documented in `ROADMAP.md` but not implemented and not to be
started without a separate explicit request. **Campaign Levels 1-50 are
user-tested on a real device and reported good** - treat that as a
manually-positive baseline for puzzle content (the portrait re-layout of
all 100 levels is a geometry-only change layered on top of that
approval, not a difficulty change, and has not itself been manually
confirmed on a device yet). **Physical Android manual QA of the entire
portrait re-layout (all 100 levels, across Phases 2A-2D), the Tutorial,
and the last few builds' changes is still pending** - see
`CURRENT_STATUS.md` for the up-to-date snapshot.

**Era 2 Foundation (`versionCode=35`-36):** the engine/architecture
foundation for Era 2 ("Refractions") — four new deterministic mechanics
(Prism, One-Way Reflector, Beam Receiver, Remote Emitter), a new
`EraTheme` architecture that themes gameplay/UI per-era without
touching Era 1 content, and a T11-T20 guided tutorial pack (locked
until Level 100 is completed).

**Era 2 Levels 101-110 (`versionCode=37`):** the first real Era 2
campaign content — ten levels (`levels/campaign/era2_stage_01/`)
combining Prism/One-Way Reflector/Beam Receiver/Remote Emitter with
selected Era 1 mechanics, culminating in Level 110 "Refraction Nexus."
This pass also fixed a real Tutorial Select regression the user found
on a real device (T11-T20's cards had become tall rectangular "poster"
cards instead of the established compact square button — fixed by
tinting the same frame via `modulate` instead of swapping texture).

**Era 2 Levels 111-120 (`versionCode=38`):** a user-requested follow-up,
authorized before Levels 101-110 had even finished manual QA. No new
mechanics — deepens the same four Era 2 mechanics through dependency
depth, shared resources (one tile genuinely reused by two different
beams), and misleading-but-fair local reasoning, culminating in Level
120 "Era 2 Circuit." Three real shortcut bugs (a beam continuing past
its own target into a mechanic it was never meant to reach) were found
and fixed by the solver during authoring.

**Era 2 Levels 121-130 (`versionCode=39`):** "deep dependency pass" —
still no new mechanics — moves beyond single-chain dependency into
whole-board reasoning: shared resources spanning distant regions,
reciprocal relay chains, a backward-reasoning near-solution trap, and
Level 130's four-way convergence. Two more issues (a grid-bounds error
and a genuinely new shortcut shape) were found and fixed during
authoring.

**Era 2 Levels 131-140 (current, `versionCode=40`,
`versionName="3.4.0-ERA2-L131-140-QA"`):** "advanced convergence pass"
— user-requested, explicitly authorized before ANY of the three prior
Era 2 level batches had received manual QA. Still no new mechanics —
combines the strongest dependency patterns from 101-130 into more
advanced puzzles: a reflector shared by two Prism colors from
different directions, reciprocal relays with genuinely opposite
approach corridors, and Level 140's four-subsystem milestone.
`get_campaign_level_count()` is now 140. **The most shortcut-prone
batch yet — 5 of 10 levels needed fixes**, including one genuinely new
failure shape (a shared reflector's two beams approaching from the
same rather than opposite sides, needing a full geometric rebuild).
**Campaign Levels 141+ do not exist yet — per the user's own
instruction, a manual Android review checkpoint is now recommended
before continuing further**, since four consecutive Era 2 level
batches (40 levels) currently await real-device feedback together.
See `ERA_2_DESIGN.md` sections 12-15, `CAMPAIGN_DESIGN.md` sections
15-18, and `CURRENT_STATUS.md` for the up-to-date snapshot.

### Direct Play + Continue Flow (`versionCode=42`, current)

Main Menu's flow is now `CONTINUE` / `PLAY` / `TUTORIAL` / `SETTINGS` /
`QUIT` — a normal player never reaches Level Select. `PLAY`
(`GameManager.play_game()`, previously labeled "CAMPAIGN" and routing to
Level Select) enters the player's current campaign progression directly;
`CONTINUE` resumes it, including exact mid-level tile orientations and
move count if the player left mid-puzzle (new `SaveManager.campaign_
resume_*` fields, `SAVE_VERSION` 3→4). Level Select is retained, fully
functional, reachable only through a small QA/dev-only Main Menu button.
See `DECISIONS.md` D85 and `ARCHITECTURE.md`'s "Direct Play + Continue
navigation" section for the full architecture; **the procedural
generator itself is still not built** — this is menu/navigation and save
schema only.

## Godot version

Developed and validated against **Godot 4.7.1 (stable)**. The project
declares `config/features=("4.7", "Mobile")` in `project.godot`.

## Opening the project

1. Install Godot 4.7.x.
2. Open Godot, choose "Import", and select this folder's `project.godot`.
3. Let the editor finish its initial scan (it registers the `class_name`
   scripts as global classes — this can take a few seconds on first open).

## Running the project

- **In the editor:** press F5 (or the Play button). The main scene is
  `scenes/ui/main_menu.tscn`.
- **From the command line (desktop):**
  ```
  godot --path . 
  ```
- **Headless (for scripted checks, no window):**
  ```
  godot --headless --path .
  ```

## Level editor (development tool, Milestone 3)

BeamShift levels can be authored visually instead of by hand-writing
GDScript. Open `tools/level_editor/level_editor.tscn` in the Godot
editor and press **F6** ("Run Current Scene") — this is a development
tool, not part of the shipped game, so it's never reachable from the
Main Menu. It supports grid sizing, a full tile palette, per-tile
property editing, structural validation, a real breadth-first solver
(using the actual game simulation, not an approximation) that reports
solvability/optimal moves/solution paths/difficulty estimates, save/load
as `.tres`, and a Playtest button that launches the real gameplay scene
without touching player save data. See `LEVEL_EDITOR.md` for the full
guide.

## Current features (Milestones 1–4A)

- Main Menu (Continue / Play / Tutorial / Settings / Quit) — `Play`
  enters the player's current campaign progression directly, `Continue`
  resumes it exactly where they left off (see "Direct Play + Continue
  Flow" above)
- Level Select (locked/unlocked/completed states, star display, scales
  to 100+ levels without redesign) — retained but QA/dev-only now,
  reachable only through a small Main Menu button gated on the existing
  QA unlock flag; a normal player never sees it
- **Guided Tutorial (T01-T10)**: a separate, scripted-interaction
  section teaching every implemented mechanic - see `TUTORIAL_SYSTEM.md`
- Deterministic grid puzzle gameplay (5x5 up to 6x6 in the current test
  levels; the grid size is fully data-driven, not hardcoded)
- Multi-beam laser simulation (grid-based, no physics): mirrors,
  splitters, blockers, targets (single or multiple, required or
  optional), beam colors (WHITE/RED/GREEN/BLUE), color filters, paired
  portals, switch-linked gates, hazards, multiple emitters, and
  beam-loop protection shared across every beam and every mechanic
- Tap/click rotation for mirrors and splitters (touch + mouse via the
  same input path)
- Move counter (player actions only — automatic beam/switch/gate
  resolution never counts), Reset, Level Complete popup (moves used,
  stars, Next/Retry/Level Select)
- 3/2/1-star rating based on moves vs. each level's optimal move count
- Local JSON save (`user://savegame.json`): campaign progress (unlocked/
  completed campaign levels, best stars, best moves) tracked separately
  from the 15 dev/regression levels' own save fields — see `DECISIONS.md`
  D54
- **Campaign Levels 1-50** (internal folders `levels/campaign/
  stage_01/` – `stage_05/`, purely organizational — players only ever
  see "Level 1"–"Level 50"): 50 handcrafted, solver-validated production
  levels, mechanic-agnostic from Level 1 onward since the Guided
  Tutorial now teaches every mechanic in isolation. **Levels 1-10 and
  11-20 manually approved** ("the starting levels are good"/"these are
  looking good"); **Levels 21-30, 31-40, and 41-45 rebuilt entirely**
  under the reboot (`DECISIONS.md` D64) after never being approved (and
  31-40 specifically after "feels easy" feedback); **Levels 46-50
  unchanged**, including Level 50 "Paradox," the named quality
  benchmark. Automated validation complete (50/50 solver, 50/50
  runtime-replay), **manual difficulty approval pending for the whole
  rebuilt 1-50**. See `CAMPAIGN_DESIGN.md` for the full campaign
  architecture and design tables.
- **Development/QA unlock-all flag** (`LevelManager.
  UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`, currently `true`): makes
  every implemented campaign level directly selectable from Level
  Select regardless of real unlock progress, without touching
  `SaveManager`'s actual completion/star/best-move data — see
  `DECISIONS.md` D58. **Must be disabled before any production
  release.**
- 15 hand-verified **development/regression test** levels (no longer
  player-facing): `levels/level_01.gd` … `level_05.gd` (Milestone 1
  basics) and `level_06.gd` … `level_15.gd` (Milestone 2 advanced
  mechanics, one level per major new mechanic plus two combined-mechanics
  challenge levels) — each independently re-verified by the Milestone 3
  solver, not just hand-traced
- A real puzzle solver, structural validator, and difficulty-metrics tool
  (development-only, see "Level editor" above)
- Fully responsive layout: the puzzle grid fits arbitrary `columns x rows`
  boards (not just square ones) against the real playable rectangle
  between the Top and Bottom HUD bars on every resize, using independent
  per-axis cell-size candidates so a rectangular board uses the available
  space well (Rectangular Grid Architecture Phase 1 — see `DECISIONS.md`
  D72); safe-margin and touch-target sizing tuned for real mobile
  devices; no fixed pixel layout for gameplay or menus. Campaign Levels
  1-100 have not yet been re-laid out to use rectangular shapes — that's
  a separate future pass.
- **Final generated art** (Milestone 4A) for Main Menu, Level Select,
  Settings, the gameplay HUD, and Level Complete, plus 5 of 10 gameplay
  tile types (mirror, target, blocker, gate, hazard); a shared
  project-wide `Theme`; lightweight interaction feedback (mirror tap
  pulse, target activation pulse, portal idle glow); a polished laser
  beam look (brighter core, rounder joins - simulation unchanged). 5 tile
  types (emitter, splitter, portal, switch, filter) intentionally remain
  on their original procedural rendering - see `ARCHITECTURE.md`/
  `DECISIONS.md` D31 for why.
- A gameplay **Pause menu** (new this milestone) reachable from the HUD
  or the Android system back gesture, which no longer silently exits the
  app during gameplay

## Project structure

```
scenes/
    ui/            main menu, level select, settings, level-complete popup
    gameplay/      game.tscn (session/HUD), grid.tscn (puzzle grid)
    tiles/         emitter/mirror/target/blocker/splitter/filter/portal/switch/gate/hazard visual scenes
scripts/
    managers/      SaveManager, LevelManager, GameManager (autoloads)
    gameplay/      grid types/enums, multi-beam laser simulation, grid manager, tile scripts
    resources/     LevelData / TilePlacement resource classes
    ui/             menu/level-select/popup scripts, mobile UI sizing helpers
    tools/         LevelSolver / LevelValidator / LevelMetrics — development-only, not shipped
tools/
    level_editor/  the level editor scene + script — run via F6, not shipped
levels/            one file per level (extends LevelData, or a saved .tres — both
                   load transparently) — see ARCHITECTURE.md for the format.
                   These 15 are development/regression test levels only —
                   no longer shown to players, see CAMPAIGN_DESIGN.md
    editor_fixtures/  validator/solver test fixtures, never shown to players
    campaign/         the real 100-level campaign (Milestone 4) —
                       stage_01/, stage_02/, stage_03/ (30 levels) exist;
                       stage_04+ not yet created. This is what Level
                       Select shows players today.
themes/            beamshift_theme.tres - shared project-wide Theme (Milestone 4A)
assets/            final generated art (Milestone 4A) - see ARCHITECTURE.md
                   "Final asset integration" and DECISIONS.md D31 for
                   which of two overlapping generated-art sets is
                   canonical, and why 5 of 10 gameplay tile types still
                   render procedurally instead of using generated art
```

See `ARCHITECTURE.md` for the full technical write-up (data flow, laser
algorithm, save format, editor/solver architecture, etc.),
`LEVEL_EDITOR.md` for how to use the level editor, `CAMPAIGN_DESIGN.md`
for the 100-level campaign's architecture/design reference, and
`PROJECT_HANDOFF.md` for a continue-from-here briefing aimed at a new
Claude session.

## Development status

See `CURRENT_STATUS.md` for the authoritative, concise snapshot of what's
done, in progress, not implemented, and known issues.

## Procedural difficulty (Difficulty System Phase 2B)

The 2,000 procedural levels can now be generated by **Generator V3**, a dependency-first
progression generator: reusable fragments (filters, portals, splitters, switch/gate chains, prisms,
receiver/remote hops, one-way reflectors, mid-route targets) are composed per difficulty band and laid
out on portrait boards of at most 8 columns; difficulty comes from reasoning depth (dependency chains,
colour, convergence, hidden state), never from smaller tiles or bigger boards. V3 is development/QA
(`LevelManager.USE_V3_FOR_PROCEDURAL_QA`, currently on); the default generator is still V2 and V1/V2 stay
frozen so saved puzzles never change. Reference: `PROCEDURAL_GENERATION.md` section 19, `DECISIONS.md` D96.
Dev tools: `scripts/tools/v3_progression_sample.tscn` and `v3_progression_stats.tscn`.

## Hint

The shared HUD Hint button rings ONE required tile from a known solution (no runtime solver, no move/star
effect); see `DECISIONS.md` D97.

## Ads (test build)

Rewarded ad -> one Hint, and an interstitial every 4 legitimate procedural completions, through `AdManager` (Google TEST ads only in this build). See `ADS_MONETIZATION.md`.

## Fusion Node (QA only)

A Beam Fusion Node combines RED/GREEN/BLUE beams into YELLOW/MAGENTA/CYAN/WHITE. QA-only for now (Main Menu "FUSION TEST"); see `DECISIONS.md` D99.

## Fusion Node in procedural levels (QA build)

Fusion Nodes now appear in main procedural levels from Level 201 (generator V4, `versionCode=55`): a node combines RED/GREEN/BLUE beams into YELLOW/MAGENTA/CYAN/WHITE and every generated node is load-bearing. Levels 1-200 have none; Level 2000 is the initial certification target (not a ceiling). QA entry points: PLAY + QA +50, Main Menu "FUSION TEST". A player-facing Fusion tutorial is a release blocker. See `DECISIONS.md` D99/D100.
