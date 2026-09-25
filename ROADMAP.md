# ROADMAP.md

Milestones are only marked complete once actually validated (see
`CURRENT_STATUS.md` and `TEST_PLAN.md` for what "validated" means for
each). Do not begin a milestone the user hasn't explicitly asked for.

## Milestone 1 — Core Prototype ✅

- Core deterministic grid/laser simulation with loop protection
- Main Menu (Play/Continue/Settings/Quit)
- Level Select with lock/unlock/star display, scalable architecture
- 5 test levels, hand-verified solvable
- Move counter, Reset, Level Complete popup, star rating
- Local JSON save with best-result preservation and sequential unlocking
- Fully responsive Control-based UI and square/centered puzzle grid,
  including a mobile UI sizing pass (safe margins + touch targets)
  validated against a physical Android device
- Full documentation set (this file and its siblings)

Status: implemented, desktop- and Android-device-validated by the user.
Complete.

## Milestone 2 — Advanced Puzzle Mechanics ✅

- Multi-beam, multi-pass `LaserSystem` rewrite (explicit work-queue, not
  recursion; loop protection shared across every beam/emitter, keyed on
  position+direction+color)
- Splitters (straight + reflected branch), reusing `GridTypes.reflect()`
- Beam colors (WHITE/RED/GREEN/BLUE), colored emitters/targets, color
  filters — color is real simulation data, not a visual tint
- Paired portals (direction/color preserved, fail-safe on invalid
  pairing, loop-safe)
- Switches + gates, resolved deterministically via multi-pass
  stabilization (monotonic closed→open, no oscillation) — fully
  stateless/derived across player moves, which is also what makes Reset
  correct for gates/switches with zero new reset code
- Hazards: block solving without blocking play
- Multiple required targets (a beam continues past an activated target)
  and multiple emitters
- 10 new test levels (`level_06`–`level_15`), one per major mechanic plus
  two combined-mechanics challenge levels, exposed in Level Select
  alongside the original 5
- All 5 Milestone 1 levels re-verified solvable through the rewritten
  simulator; the old `.gd` level files migrated from a positional
  `TilePlacement` constructor to static `make_*()` factories

Status: implemented and automatically validated. Android debug APK
re-exported. The user's Milestone 3 kickoff referenced this milestone as
already established and device-tested, which is being treated as
sufficient approval to proceed — see `PROJECT_HANDOFF.md` for the caveat
that no itemized manual-test report exists for Milestone 2 specifically,
unlike Milestone 1's.

## Milestone 3 — Level Editor + Puzzle Validation + Difficulty Tooling ✅ (implementation)

- A standalone development-only level editor (`tools/level_editor/`),
  run via F6, never part of the shipped game
- Visual grid editing (tested 4x4–9x9), a full tile palette, per-tile-
  type property panels, level metadata (ID/name/grid size/optimal moves/
  stage/developer notes)
- `LevelValidator` — structural error/warning checks, gating Save/Playtest
- `LevelSolver` — real breadth-first search over rotatable-piece
  orientations using the actual `LaserSystem` (never an approximation);
  reports solvability (`SOLVABLE`/`UNSOLVABLE`/`UNKNOWN`, with `UNKNOWN`
  meaning the search limit was hit, never confused with a proven
  negative), optimal move count, solution path, multiple-solution count,
  and possible decoy pieces
- `LevelMetrics` — design metrics + a transparent, explicitly non-
  authoritative difficulty estimate
- A real Playtest button using the actual gameplay scene, never writing
  to player save data, round-tripping back to the editor with
  in-progress edits preserved
- `.tres` level format support alongside the existing `.gd` levels (not
  a migration — Levels 1-15 remain `.gd` files)
- 6 editor-only validator/solver test fixtures, invisible to players
- `levels/campaign/` reserved (empty) for Milestone 4
- All 15 existing levels independently re-verified solvable by the solver

Status: implemented and automatically validated (see `TEST_PLAN.md`).
Android debug APK re-exported with the new tooling excluded from the
build. **Awaiting the user's manual, hands-on use of the editor** and
explicit approval before Milestone 4 begins.

## Milestone 4 — Full 100-Level Campaign ✅ (all 10 stages created — awaiting full manual QA)

**Content-complete.** All 100 originally-planned levels now exist
across Stages 1-10 (see `DECISIONS.md` D70). "Production Campaign
Phase 1" implemented Stage 1 —
First Light (campaign levels 1-10), **manually approved** by the user
("the starting levels are good"). "Production Campaign Phase 2"
implemented Stage 2 — Reflection (campaign levels 11-20), deepening the
same mirror/blocker/fixed-mirror mechanics with stronger misdirection,
backward reasoning, and multi-step route dependency — **manually
approved for campaign continuation** ("these are looking good").
"Production Campaign Phase 3" implemented Stage 3 — Split (campaign
levels 21-30), the first stage to introduce splitters and multiple
required targets, with genuine cross-branch dependency (a mirror shared
by both beams) per the user's explicit "difficulty from reasoning about
branches, not from adding pieces" directive — fully solver-validated and
real-runtime-validated, **manual approval pending**. "Production
Campaign Phase 4" implemented Stage 4 — Spectrum (campaign levels
31-40), the first stage to introduce `BeamColor` reasoning (no filters
used - color stays fixed per beam graph, so the reasoning comes from
non-required color-decoy targets on plausible false routes) — this
stage was explicitly commissioned by the user's own detailed request
while Stage 3 was still pending manual QA (see `DECISIONS.md` D57) —
fully solver-validated and real-runtime-validated, **manual approval
pending**; user feedback on Stage 4 was **"Levels 31-40 feel easy"**,
which was recorded without modifying any Stage 4 level and instead
shaped Stage 5's curve. "Production Campaign Phase 5" implemented Stage
5 — Filters (campaign levels 41-50), the first stage to introduce the
`FILTER` tile (fixed, never rotatable, unconditionally overwrites a
beam's color; chaining is "last filter touched wins") — built directly
against the Stage 4 "too easy" feedback, escalating sharply from Level
43 onward (see `DECISIONS.md` D59) — fully solver-validated and
real-runtime-validated, **manual approval pending**. All five stages
kept as a separate population from the 15 dev/regression levels in both
storage and save data — see `CAMPAIGN_DESIGN.md` (the architecture/
design reference for every stage) and `DECISIONS.md`
D54/D55/D56/D57/D59 (the implementation writeups). Uses Milestone 5's
final visual art from the first level, as planned (the splitter and
filter both stay procedural — see D31). A development/QA-only flag,
`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` (currently
`true`, see `DECISIONS.md` D58), makes every implemented campaign level
directly selectable regardless of real progress - it must be disabled
before any production release. **Stages 6-10 are architecture-only** —
table below is still target structure, not yet built, and **not to be
built ahead of explicit request**, same standing rule as before Stages
1-5 started:

**CAMPAIGN REBOOT (see `DECISIONS.md` D64):** with the Guided Tutorial
(below) now teaching every mechanic in isolation, Campaign Levels 21-50
no longer needed to be organized as "one stage teaches one mechanic" -
Levels 21-30, 31-40, and 41-45 were rebuilt entirely as mechanic-
agnostic, difficulty-focused puzzles (the "Stage 3/4/5" names below are
now internal folder organization only, not a player-facing mechanic
progression); Levels 46-50 are unchanged.

**DIFFICULTY REWORK PASS 2 (see `DECISIONS.md` D65):** the reboot pass
above was solver-valid but still too easy in Levels 21-45 (optimal-move
curves 3,2,2,2,2 / 2,2,2,2,5 / 2,4,2,2,3) - all 25 were replaced again
with content built for real dependency depth (cross-branch shared
mirrors, filter order, portal misdirection, switch/gate dependency,
multi-emitter dependency, backward reasoning) rather than padded move
counts. See `CAMPAIGN_DESIGN.md` sections 11f/11g/11h for the current
design tables.

**CAMPAIGN EXPANSIONS — THE 100-LEVEL CAMPAIGN IS NOW COMPLETE (see
`DECISIONS.md` D66/D67/D68/D69/D70):** five successive post-reboot
expansions past 50, each with no mechanic-teaching reset - Levels 51-60
continue directly from 46-50's difficulty, Levels 61-70 continue
directly from Level 60's, Levels 71-80 continue directly from Level
70's, Levels 81-90 continue directly from Level 80's, Levels 91-100
continue directly from Level 90's. See `CAMPAIGN_DESIGN.md` sections
11i/11j/11k/11l/11m for the design tables. **Levels 1-50 are user-
tested on a real device and reported good** - a manually-positive
baseline; Levels 51-100 remain automated-validated only. **Any further
campaign content (Levels 101+) is new scope beyond the original plan,
not a continuation of it.**

| Levels (internal folder) | Status |
|---|---|
| 1–10 (`stage_01`) | ✅ done, **manually approved**, unchanged by any pass |
| 11–20 (`stage_02`) | ✅ done, **manually approved for continuation**, unchanged by any pass |
| 21–30 (`stage_03`) | ✅ REPLACED TWICE (reboot, then Difficulty Rework Pass 2), part of the **user-tested "Levels 1-50 are good" baseline** |
| 31–40 (`stage_04`) | ✅ REPLACED TWICE (after "feels easy" feedback on the pre-reboot content, then again by Pass 2), part of the **user-tested "Levels 1-50 are good" baseline** |
| 41–45 (`stage_05`, first half) | ✅ REPLACED TWICE, part of the **user-tested "Levels 1-50 are good" baseline** |
| 46–50 (`stage_05`, second half) | ✅ done, unchanged by any pass (includes Level 50 "Paradox," the quality benchmark), part of the **user-tested "Levels 1-50 are good" baseline** |
| 51–60 (`stage_06`) | ✅ CREATED — no mechanic-teaching reset, continues directly from 46-50 (see `CAMPAIGN_DESIGN.md` section 11i, `DECISIONS.md` D66), awaiting manual QA |
| 61–70 (`stage_07`) | ✅ CREATED — "advanced expert" tier, no mechanic-teaching reset, continues directly from 60 (see `CAMPAIGN_DESIGN.md` section 11j, `DECISIONS.md` D67), awaiting manual QA |
| 71–80 (`stage_08`) | ✅ CREATED — MASTER/MASTER+/EXTREME tier, no mechanic-teaching reset, continues directly from 70 (see `CAMPAIGN_DESIGN.md` section 11k, `DECISIONS.md` D68), awaiting manual QA |
| 81–90 (`stage_09`) | ✅ CREATED — EXTREME/EXTREME+ tier, first three-stage relay, no mechanic-teaching reset, continues directly from 80 (see `CAMPAIGN_DESIGN.md` section 11l, `DECISIONS.md` D69), awaiting manual QA |
| 91–100 (`stage_10`) | ✅ CREATED — MASTER+/EXTREME/FINAL CHALLENGE tier, the campaign's final stage, no mechanic-teaching reset, continues directly from 90 (see `CAMPAIGN_DESIGN.md` section 11m, `DECISIONS.md` D70), awaiting manual QA |

## Milestone 4B — Guided Tutorial Mode 🚧 (awaiting manual QA)

A new, permanent product section alongside the 100-level Campaign: T01–
T10, ten guided interactive lessons teaching every implemented mechanic
through forced player action rather than easier puzzles. Built from an
explicit, detailed user request while Campaign Stages 3–5 were still
pending manual approval — an explicit-request exception to the standing
"don't start unrequested work" rule, same as Stage 4/5 before it. Does
**not** count toward the 100 campaign levels — completely separate
numbering, completely separate `SaveManager` fields. See
`TUTORIAL_SYSTEM.md` for the full architecture and `DECISIONS.md` D60
for the implementation writeup.

Every mechanic the brief's T01–T10 plan named was confirmed already
implemented before any tutorial was designed — including portals,
switches/gates, hazards, and multiple emitters, none of which Campaign
has used yet (reserved for Stages 6/7/9/8 respectively) but all of
which were already proven by dev/regression levels 10–13. No tutorial
was left pending, no mechanic was faked.

| Tutorial | Name | Lesson | Status |
|---|---|---|---|
| T01 | First Light | Emitter, target, basic mirror | ✅ done, awaiting manual QA |
| T02 | Two Turns | Both mirror orientations | ✅ done, awaiting manual QA |
| T03 | Locked In | Blockers, fixed mirrors | ✅ done, awaiting manual QA |
| T04 | Both Lights | Multiple required targets | ✅ done, awaiting manual QA |
| T05 | Split Path | Splitters | ✅ done, awaiting manual QA |
| T06 | True Color | Colored beams/targets | ✅ done, awaiting manual QA |
| T07 | Recolor | Filters | ✅ done, awaiting manual QA |
| T08 | Through the Portal | Portals | ✅ done, awaiting manual QA |
| T09 | Switch and Gate | Switches, gates, hazards | ✅ done, awaiting manual QA |
| T10 | Graduation | Multiple emitters, free-play finale | ✅ done, awaiting manual QA |

**Do not add T11 or beyond, and do not start Milestone 4's Stage 6
without explicit approval of this milestone first.**

## Milestone 5 — Final Visual Assets, UI Polish, VFX, Audio ✅

**Naming note:** the user's kickoff for this work called it "Milestone
4A — Final Asset Integration" and scoped it explicitly to visuals only,
run before Milestone 4 (100-level campaign) rather than after it as this
roadmap originally planned. Content-wise it *is* this milestone (final
art, theme, VFX, and — as of the Audio/SFX Integration Pass below —
audio) - kept under its original "Milestone 5" number here so the
roadmap's history stays consistent; don't renumber past entries to match
ad hoc session naming.

Replaced Milestone 1's procedural placeholder visuals with real generated
art for Main Menu, Level Select, Settings, gameplay HUD, Level Complete,
and 5 of 10 gameplay tile types (see `ARCHITECTURE.md` "Final asset
integration" and `DECISIONS.md` D31-D36 for full detail and why the other
5 tile types - emitter, splitter, portal, switch, filter - remain
procedural). Also built a new Pause menu (didn't exist before) and fixed
the Android back button silently exiting the app during gameplay.

**Audio SFX is now wired** (see "Audio/SFX Integration Pass" below,
`AUDIO_SYSTEM.md`, `DECISIONS.md` D89) - `SaveManager.sound_enabled` now
genuinely mutes the SFX/UI buses via a centralized `AudioManager`
autoload; 22 gameplay/UI sounds are live. **Music remains untouched** -
`SaveManager.music_enabled` still exists structurally but controls
nothing audible; no music bus or music assets exist yet. A future pass
would need actual music files before this milestone is fully ✅ on both
audio fronts, not just SFX.

### Visual polish pass after campaign completion — UI backgrounds V2 + mirror impact VFX (2026-09-21)

Not a numbered milestone: a small presentation pass done between Milestone
4's completion and Milestone 6. Three new menu backgrounds (Main Menu,
Campaign Select, Tutorial Select) with a subtle readability scrim, and a
procedural laser → mirror impact burst (`LaserMirrorImpactFX`). Gameplay
untouched; build `versionCode=29` / `2.6.0-UI-VFX-QA`; **manual Android
visual QA pending**. See `DECISIONS.md` D71. Further VFX (targets,
portals, gates, filters, hazards) were explicitly left for separate
passes and are not started. Audio is still untouched.

### Rectangular Grid Architecture — Phase 1 (2026-09-22)

Not a numbered milestone: an engine/layout architecture pass, done
between the visual polish pass above and Milestone 6. **BeamShift
supports arbitrary rectangular grids and sizes the board against the
real gameplay rectangle between Top HUD and Bottom HUD** (see
`CLAUDE.md`'s Responsive rules, `ARCHITECTURE.md` "Rectangular grid
layout," `DECISIONS.md` D72) — `GridManager._recalculate_layout()` now
fits `columns x rows` using independent per-axis cell-size candidates
instead of the old square-only `min(size.x,size.y)/max(grid_width,
grid_height)` formula, the one square-grid assumption a full audit found
anywhere in the project. **Campaign Levels 1-100 have NOT yet been
re-laid out** — every level's `grid_width`/`grid_height`/tile
coordinates are untouched; this pass only makes the engine capable of
using a rectangular shape well, it doesn't choose one for any real
level. 5 temporary rectangular layout fixtures
(`levels/editor_fixtures/fixture_rect_*.gd`, never Campaign-reachable)
were added for validation. 15/15 dev + 100/100 campaign + 10/10 tutorial
solver+runtime-replay regressions unchanged; resolution/layout matrix
and RENDERED screenshots confirmed correct alignment and 85-100%
width / 89-99.8% height utilization on rectangular test boards vs.
existing square levels' width-bound-only behavior. Build
`versionCode=30` / `2.7.0-RECT-GRID-QA`; **manual Android visual QA
pending**. See `DECISIONS.md` D72.

**Phase 2 (choosing real rectangular `grid_width`/`grid_height` shapes
for Campaign Levels 1-100, level by level) is explicitly NOT started and
NOT authorized by this pass's completion** — same standing "don't
continue without being asked" rule as every prior stage/expansion.

### Rectangular Grid Portrait Re-Layout — Phase 2A: Levels 1-25 (2026-09-22)

Not a numbered milestone: the first of what will be several future
batches re-laying out existing Campaign levels' board geometry onto the
portrait-friendly rectangular shapes Phase 1 made possible. **Explicitly
NOT a difficulty redesign** — see `DECISIONS.md` D73 and `CLAUDE.md`'s
Level editor rules/Responsive rules. Re-laid out Levels 1-25's
`grid_width`/`grid_height`/tile positions via an **order-preserving
coordinate remap** (a transform that provably cannot change which cells
a beam hits or in what order, since `LaserSystem` only depends on that
sequence, never on distance — solver-confirmed identical
`optimal_moves`/`shortest_solution_count`/`states_explored` for all 25,
checked directly rather than assumed). Each level's new shape was chosen
individually from its own content, landing between 5x6 and 7x8; Levels
21-25 also had columns compacted since they were the only ones already
below the project's own 144px minimum touch-target size, ending up with
cells 29-33% LARGER than before. Height utilization at the 1080x1920
reference rose to 94.2-99.8% (from 56.8-99.8%) with zero HUD overlap.
Build `versionCode=31` / `2.8.0-PORTRAIT-L1-25-QA`; **manual Android
visual QA pending**. See `DECISIONS.md` D73.

### Rectangular Grid Portrait Re-Layout — Phase 2B: Levels 26-50 (2026-09-22)

The second re-layout batch, identical technique to Phase 2A extended to
Levels 26-50's heavier mechanic mix (splitters, filters, portals,
switch/gate dependency, hazards/blockers, two-emitter levels) — see
`DECISIONS.md` D74. Every level's shape was chosen individually from its
own content, landing between 6x7 and 9x10; solver-confirmed identical
`optimal_moves`/`shortest_solution_count`/`states_explored` for all 25,
zero manual geometry corrections needed. Average cell size rose 105px →
132px (+25.6%); average height utilization rose 82.2% → 95.2%. Level 50
("Paradox," the campaign's own named quality benchmark) preserved
exactly at an unchanged 124px cell size, same zero-cost row-growth
pattern as Phase 2A's Level 20. Build `versionCode=32` /
`2.8.1-PORTRAIT-L26-50-QA`; **manual Android visual QA pending**. See
`DECISIONS.md` D74.

### Rectangular Grid Portrait Re-Layout — Phase 2C: Levels 51-75 (2026-09-22)

The third re-layout batch, identical technique to Phase 2A/2B, applied
to the campaign's most mechanically interconnected block yet — mutual
switch/gate pairs, a genuine two-stage relay (Level 70), shared-gate
perpendicular multi-emitter crossings, post-target beam continuation
gating a second branch — see `DECISIONS.md` D75. Applied in three
validated sub-batches (51-60, 61-70, 71-75) with a git checkpoint after
each, per the brief's explicit instruction not to batch-convert and
validate afterward. Solver-confirmed identical `optimal_moves`/
`shortest_solution_count`/`states_explored` for all 25 (24 changed +
Level 75 deliberately left unchanged — already fully packed on both
axes, zero slack to remap). Average cell size rose 96.7px → 109.2px
(+13.0%, a smaller gain than Phase 2B's since this block had markedly
less compaction slack); average height utilization rose 81.9% → 93.0%.
Build `versionCode=33` / `2.8.2-PORTRAIT-L51-75-QA`; **manual Android
visual QA pending**. See `DECISIONS.md` D75.

### Rectangular Grid Portrait Re-Layout — Phase 2D: Levels 76-100, FINAL BATCH (2026-09-22)

The fourth and final re-layout batch, identical technique to Phase
2A/2B/2C, applied to the campaign's hardest and most tile-dense block —
up to 42 tiles, up to 16 rotatable pieces at the practical solver
ceiling (2^16=65536), up to 5 emitters, three-stage relays, a four-
independent-source convergence (Level 80) — see `DECISIONS.md` D76.
Applied in three validated sub-batches (76-80, 81-90, 91-100) with a
git checkpoint after each. Solver-confirmed identical `optimal_moves`/
`shortest_solution_count`/`states_explored` for all 25 (21 changed + 4
deliberately left unchanged — Levels 85, 91, 95, 98, the same zero-
slack situation Level 75 first established). 6 levels compacted
10-wide→9-wide (+10% cell size); 15 levels held their exact cell size
while gaining zero-cost row growth to the full safe ceiling (height
utilization 82.6%→99.1%). Level 100 ("Culmination," the definitive
Era 1 finale) was fully verified — all five emitter routes, three relay
stages, both portals, symmetric convergence, and the fixed-mirror
backward-reasoning step all confirmed identical, `optimal_moves`/
`states_explored`/`shortest_solution_count` unchanged. **THIS COMPLETES
THE PORTRAIT RE-LAYOUT OF ALL 100 CAMPAIGN LEVELS.** Final read-only
audit across 1-100: 100/100 SOLVABLE, zero levels below the 90% height
/ 85% width utilization targets, cell sizes 87-174px (avg 122.4px), avg
width util 98.2%, avg height util 95.6%. Build `versionCode=34` /
`2.9.0-PORTRAIT-100-QA`; **manual Android visual QA pending**. **Do not
create Campaign Levels 101+ or start any further re-layout work without
being explicitly asked** — the 100-level portrait conversion effort
(Phases 2A-2D) is complete. See `DECISIONS.md` D76.

**Era terminology** (documentation only, per this phase's explicit
instruction): the complete 100-level campaign plus the T01-T10 tutorial
together constitute **Era 1**. See "Future product direction — Eras"
below for the long-term Era 2+ direction — still not implemented, not
to be started without a separate explicit request.

### Future product direction — "Eras" (documented, NOT implemented)

Recorded per an explicit instruction during Phase 2A planning, so a
future session has the long-term shape of the product without mistaking
documentation for authorization to build any of it:

BeamShift's eventual player-facing structure will **replace the current
separate Campaign/Endless framing with one continuous progression**:
Tutorial, then a single continuous PLAY mode. There will not be a
separate "Campaign" and "Endless" mode as distinct products.

The current 100-level Campaign (Levels 1-100) plus the existing Guided
Tutorial (T01-T10) together form **Era 1**. The intended future
structure repeats this pattern indefinitely:

| Era | Tutorial | Levels |
|---|---|---|
| Era 1 (current, complete) | T01-T10 | 1-100 |
| Era 2 (future) | T11-T20 | 101-200 |
| Era 3 (future) | T21-T30 | 201-300 |
| ... | ... | ... |

Each future 100-level Era may introduce new mechanics, a new tutorial
pack teaching them, a new visual theme, and new VFX/audio treatment.
Future procedural generation is intended to eventually support
unlimited progression beyond hand-authored Eras.

## Milestone 4C — Era 2 Foundation ✅ (engine/architecture only — campaign not started)

Built per an explicit request to implement Era 2's foundation - engine
mechanics, visual theming architecture, and guided tutorial pack - while
explicitly stopping short of the 100-level campaign itself. Full detail
in `ERA_2_DESIGN.md` and `DECISIONS.md` D77:

- `EraTheme` (`scripts/resources/era_theme.gd`) - the first real piece
  of the "Eras" direction above: a centralized, non-autoload lookup that
  maps any campaign level/tutorial number to its Era and that Era's
  themed assets. Era 1's theme is all-null by construction, so Levels
  1-100/T01-T10 stay visually byte-for-byte unchanged.
- Four new deterministic mechanics: Prism, One-Way Reflector, Beam
  Receiver/Remote Emitter - see `ERA_2_DESIGN.md` sections 3-5 for the
  exact rules. Zero `LevelSolver` changes needed. 13 new dev fixtures.
- T11-T20 (the Era 2 tutorial pack), locked until Level 100 is
  legitimately completed.
- Per-era gameplay background/HUD/grid theming, Level/Tutorial Select
  background theming, a Level 100 -> Era 2 transition banner, and a new
  `Era2ActivationFX` VFX burst.

A follow-up **"Era 2 Foundation QA/Hardening Pass"** (`versionCode=36`,
see `DECISIONS.md` D78) closed the gaps this pass left open: a real
T11-T20 guided-step-machine test, Era 2 panel/card art wired into
Level Complete/Tutorial Complete/Tutorial Select, and a 24.9% APK size
reduction - still explicitly stopping short of Campaign Levels 101+.

**Still not implemented, still requires a separate explicit request:**
Campaign Levels 101-200 (the actual Era 2 100-level content), T21+,
Era 3, procedural generation, and the eventual Campaign/Endless-framing
unification the "Eras" direction below describes - these two passes
built the foundation those would sit on top of, not the content itself.

### Future product direction — "Eras" (partially implemented as of Milestone 4C)

Recorded per an explicit instruction during Phase 2A planning, so a
future session has the long-term shape of the product without mistaking
documentation for authorization to build any of it:

BeamShift's eventual player-facing structure will **replace the current
separate Campaign/Endless framing with one continuous progression**:
Tutorial, then a single continuous PLAY mode. There will not be a
separate "Campaign" and "Endless" mode as distinct products.

The current 100-level Campaign (Levels 1-100) plus the existing Guided
Tutorial (T01-T10) together form **Era 1**. The intended future
structure repeats this pattern indefinitely:

| Era | Tutorial | Levels |
|---|---|---|
| Era 1 (current, complete) | T01-T10 | 1-100 |
| Era 2 (foundation + T11-T20 built; Levels 101-140 of 101-200 built) | T11-T20 ✅ | 101-140 ✅ of 101-200 |
| Era 3 (future) | T21-T30 | 201-300 |
| ... | ... | ... |

Levels 101-110 (see `DECISIONS.md` D80, `CAMPAIGN_DESIGN.md` section 12)
are the introductory Era 2 arc, following directly from Level 100/T20 —
the first real campaign use of Prism/One-Way Reflector/Beam Receiver/
Remote Emitter. Levels 111-120 (see `DECISIONS.md` D81, `CAMPAIGN_
DESIGN.md` section 16) deepen the same four mechanics with no new
mechanic types. Levels 121-130 (see `DECISIONS.md` D82, `CAMPAIGN_
DESIGN.md` section 17) push into whole-board reasoning. Levels 131-140
(see `DECISIONS.md` D83, `CAMPAIGN_DESIGN.md` section 18) push into
advanced convergence - two-reflector chains, reciprocal relays with
genuinely opposite approach corridors, and Level 140's four-subsystem
milestone - still no new mechanics, user-requested before ANY of the
three prior Era 2 batches had received manual QA. **A manual Android
review checkpoint is now recommended before Levels 141+** - four
consecutive unreviewed Era 2 batches (40 levels) currently await
real-device feedback together. **Levels 141-200 are not started** and
should not be begun without a separate, explicit future request, same
standing rule as every other unbuilt milestone in this document.

Each future 100-level Era may introduce new mechanics and a new tutorial
pack teaching them - Era 2 is the first Era to actually do this (Prism/
One-Way Reflector/Beam Receiver/Remote Emitter, T11-T20). **The "new
visual theme per Era" part of this plan is currently switched off,
deliberately, not abandoned**: the Unified Blue Theme Fix (see
`DECISIONS.md` D91, `CLAUDE.md`'s Era 2 rules) made
`EraTheme.UNIFIED_BLUE_THEME_ONLY := true` the single authoritative
switch forcing every gameplay screen - Campaign, procedural, tutorials,
any level/tutorial number - to render in Era 1's existing blue/cyan
theme, after the user decided a per-Era visual reskin (Era 2's violet
"Refractions" look) was not the desired direction. Era 2's own theme
(`EraTheme._build_era_2()`) and every violet/magenta asset it references
still exist in full, untouched, simply unreachable while the flag is
on - flipping it back to `false` is the complete revert if a future,
separate, explicit request ever wants per-Era visual reskins again. Any
future Era's mechanics/tutorial content plan is unaffected by this -
only "does the skin also change" is currently answered "no." Future
procedural generation is intended to eventually support unlimited
progression beyond hand-authored Eras.

**Campaign Levels 141-200, T21+, Era 3, procedural generation, and the
Campaign/Endless-framing unification are still not implemented**
(Levels 101-140 now exist - see `DECISIONS.md` D80/D81/D82/D83) and
should not be started without a separate, explicit future request - see
`CLAUDE.md`'s standing "don't build ahead of an explicit ask" rule and
the project's standing exclusion on procedural/random level generation
(`DECISIONS.md` D30).

## Future product direction — 2,000-level procedural progression (supersedes "Eras" above; documented, NOT implemented)

Recorded per an explicit new-direction request accompanying the Phase 1
layout pass below. **This supersedes the "Eras" (100-hand-authored-levels-
per-Era, T01-T10/T11-T20/...) framing documented above** — that framing
is kept in this file for history, not deleted, but is no longer the
target structure. The new standing direction:

- **2,000 procedurally-generated levels** — deterministic-seed generation,
  not hand-authored content at that scale.
- **No normal player-facing Level Select** — direct **PLAY** (start next
  unplayed level) / **CONTINUE** (resume in-progress) flow instead.
- **Maximum 8 columns** for any new procedurally-generated board
  (`GridManager.MAX_COLUMNS`, see below) — large, thumb-friendly tiles;
  difficulty comes from puzzle logic (mechanic combinations, dependency
  depth), never from shrinking tiles to fit more columns.
- **One shared, centralized gameplay layout** for every level regardless
  of scale (Level 1 through a future Level 2000) — no per-level HUD
  positioning, ever.

**The procedural generator (V1) is now built — see Phase 3 below and
`PROCEDURAL_GENERATION.md` for the full reference.** The existing 15 dev +
140 campaign + 20 tutorial + 24 fixture levels remain exactly as they
were: generator design references, regression fixtures, and difficulty
benchmarks, per the standing "existing level compatibility" rule — they
were also the actual patterns the generator's own templates draw from.
Do not create Campaign Levels 141+ / T21+ / a new Era / procedural Levels
2001+ without a separate, explicit future request.

## Phase 1 — Shared Adaptive Gameplay Layout Foundation ✅ (awaiting manual QA)

Not a numbered milestone: a layout-architecture hardening pass done ahead
of the procedural generator, so a future generator can target pure
puzzle data (`columns`, `rows`, `pieces`) and never pixel positions. See
`DECISIONS.md` D84 for the full writeup. **Key finding: the shared,
centralized layout this phase asked for already existed**, built across
the Rectangular Grid Architecture (D72) and four-phase Portrait
Re-Layout (D73-D76) passes above — `game.tscn`'s `SafeAreaMargin` →
`Layout` → `TopBar`/`CenterArea`/`BottomBar` structure, `grid_manager.
gd`'s independent-per-axis cell-size formula, and whole-cell tap
(`TileVisual` sized to the full cell) were all already in place, and no
level has ever owned HUD positioning. This phase confirmed that
architecture with a fresh 5-resolution test matrix and added the pieces
that were genuinely missing for the new procedural direction:
`GridManager.MAX_COLUMNS := 8`, `GridManager.
MIN_COMFORTABLE_CELL_SIZE := 96.0`, and `GridManager.
is_board_profile_comfortable(columns, rows, playable_size)` — the
contract a future generator calls before committing to a board shape.
54 existing campaign levels (plus 1 tutorial, 3 fixtures) already exceed
8 columns and are grandfathered, unmodified. Zero level data, HUD
scene, or `LaserSystem`/solver changes. Full regression: 188/188 PASS
(15 dev + 140 campaign + 20 tutorial + 13 Era 2 fixtures). Build
`versionCode=41` / `3.5.0-ADAPTIVE-LAYOUT-QA`; **manual Android visual
QA pending**. **Direct Play/Continue and the procedural generator itself
are explicitly NOT started** — next steps per the future-direction
section above, not to be begun without a separate explicit request.

## Phase 2 — Direct Play + Continue Flow ✅ (awaiting manual QA)

Not a numbered milestone: the menu/navigation layer catching up to the
"no player-facing Level Select" future direction above, done immediately
after Phase 1 (before its own manual QA landed). See `DECISIONS.md` D85
for the full writeup. Main Menu's flow is now genuinely `CONTINUE` /
`PLAY` / `TUTORIAL` / `SETTINGS` / `QUIT` — `PLAY` (previously labeled
"CAMPAIGN" and routing to Level Select) now enters the player's current
campaign progression directly; `CONTINUE` resumes it, including exact
tile orientations and move count if the player left mid-level. Level
Select is retained, fully functional, reachable only via a small QA-only
button gated on the existing `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`
flag. New `SaveManager.campaign_resume_*` fields (`SAVE_VERSION` 3->4)
track the one in-progress campaign game; a QA Level Select session never
touches them, so QA testing can never corrupt a real player's
progression pointer. Zero level data, `LaserSystem`, or Tutorial content/
unlock changes. Full regression unchanged at 188/188; a dedicated
19-point resume-flow test (temporary driver, real autoloads) also ran
19/19 PASS. Build `versionCode=42` /
`3.6.0-DIRECT-PLAY-CONTINUE-QA`; **manual Android QA pending**, on top of
Phase 1's own still-outstanding review.

## Phase 3 — Procedural Level Generator V1 + QA Next button ✅ (awaiting manual QA)

Not a numbered milestone: the procedural generator itself, Levels 1-2000,
built on top of Phases 1-2's layout/navigation foundation per an explicit
user request (superseding D87's own "wait for Android QA before starting
this" deferral for this specific pass). Full architecture, band table,
template catalog, and audit numbers in the new `PROCEDURAL_GENERATION.md`;
implementation writeup in `DECISIONS.md` D88. In short: `scripts/
procedural/**` (runtime) generates a deterministic, solution-first,
self-verified `LevelData` for any level number 1-2000 from a seed derived
from `(level_number, generator_version)`; `scripts/tools/
procedural_audit.gd` (dev-only) exhaustively proved the generator's own
output via the real `LevelSolver`/`LevelValidator` across the full 1-2000
range (0/2000 failures, 0/2000 fallbacks, 11/11 determinism matches,
278.1s dev-time audit run). Main Menu `PLAY`/`CONTINUE` now target
procedural progression instead of Campaign; the legacy Campaign (1-140)
remains reachable only via the existing QA Level Select screen, unchanged.
A temporary QA-only "NEXT" button (`LevelManager.
SHOW_PROCEDURAL_QA_NEXT_BUTTON`) lets a tester skip ahead without solving
every level, proven (end-to-end runtime test) to never fake a legitimate
completion. Zero `LaserSystem`/`GridTypes`/campaign/tutorial code changes;
`scripts/tools/**`'s Android-export exclusion is completely untouched
(the live generator never calls the dev-only solver — see
`PROCEDURAL_GENERATION.md` section 5). Build `versionCode=45` /
`4.0.0-PROCEDURAL-V1-QA`; **manual Android QA pending**, on top of Phases
1-2's own still-outstanding review — four consecutive unreviewed passes
now await real-device feedback together. **Do not create Campaign Levels
141+, T21+, a new Era, or procedural Levels 2001+ without being
explicitly asked.** (Update 2026-09-25: procedural Levels 2001-3000 now exist as generator V5, Selector Phase S3 / D110 - see the section at the end of this file.)


## Difficulty System - Phase 1 done, Phase 2 pending approval

Phase 1 (contract, complexity metrics, triviality model, QA +50) is built and
documented (D93). **Phase 2**: rewrite templates to construct dependency-chain
puzzles that meet the contract (`GENERATOR_VERSION` 3), then Android difficulty
review, then star tuning from the solver-verified optimum. Not started.


## Difficulty System - Phase 2A done (V3 prototype) [Phase 2B is done below]

Phase 2A.1 (`versionCode=50`, D95): D/E/F reworked for reasoning depth after
Android feedback; pass-correct One-Way is in D (second One-Way; a shared pass
cell overlaps beams by geometry). Still awaiting feedback; Phase 2B not started.

Phase 2A: dependency-first generator V3, six prototype archetypes, QA
selector, APK `versionCode=49`. **Phase 2B** (after manual Android feedback):
tune archetypes, add a pass-correct One-Way structure and target-continuation
delays, per-band acceptance profiles, longer/composed chains toward the
20-26 move bands, then make V3 the default (`GENERATOR_VERSION` 3) and tune
stars from the solver-verified optimum. Not started.

## Difficulty System - Phase 2B done (V3 progression, QA), Phase 2C pending Android feedback

Phase 2B (`versionCode=51`, D96): V3 is now a reusable dependency-first progression
generator (atoms + composer + per-band contract) selected for new play by
`LevelManager.USE_V3_FOR_PROCEDURAL_QA`; the six prototypes remain permanent fixtures; V1/V2
frozen; default generator still V2. Still development/QA, **not** release-certified; a full
1-2000 certification and star thresholds are deliberately postponed. **Phase 2C (after Android
feedback on early/mid/late feel):** tune bands from real play, add wrong-colour decoy forks and
reciprocal dependencies, measure/optimise level-load time on device (top bands), extend
exact-optimum verification (partial solver / verified seeds), then decide the default rollout and
derive star thresholds from the verified optimum. Not started.

## Milestone 6 — Android Optimization, Device Testing, Release Prep

Not started. Real-device validation of the responsive layout work done in
Milestone 1 (which has only been tested via desktop window resizing and
manual reasoning about anchors/containers — see `TEST_PLAN.md`'s "Android
device test" section), performance passes, and store release
configuration.

## Global Hint System - Phase 1 done (D97), later phases pending decisions

Phase 1 (`versionCode=52`): one-tile ring hint from known solutions across procedural/campaign/tutorial.
Pending product decisions: star/perfect-score penalty for hints, rewarded-ad or purchased hints (the
`request_hint`/`grant_hint` seam is ready), smarter V3 stage-aware ordering, hint history across Continue.

## AdMob Foundation V1 done (test ads), production integration pending

Done (D98): rewarded hint, interstitial rule, consent architecture, Android Gradle build. Pending: Android device verification of real test ads, production IDs + release
checklist (`ADS_MONETIZATION.md` section 10), Privacy Options UI, child-directed decision, iOS build/validation on a Mac, hint-star policy.

## Fusion Node - Phase 2 done (QA), Android test pending

Phase 2 (D100): Fusion in the main procedural progression via generator V4 (F1-F7, unlock table, once-per-level roll, load-bearing/colour/feedback checks). Next (each only when explicitly asked): the player-facing Fusion TUTORIAL (release blocker; uses `bs_fusion_icon.png`), Android tuning of frequency/probe/attempt knobs from the user's feedback, certification of Levels 1-2000, a 4-state-aware solver/validator, optional chained fusion (composite inputs). POST-2000 (design direction only, nothing built or exposed): the architecture is level-number-open; difficulty continues through combinations of existing mechanics (deeper Fusion + Prism + Filter, Fusion + Portal + Switch/Gate, Fusion + Receiver/Remote + One-Way, multi-branch convergence, shared resources, delayed dependencies) inside a curated high-difficulty envelope - never smaller tiles, more than 8 columns, giant boards or padding.


## Fusion Node - Phase 3 done (QA), production-supported, Android test pending

Phase 3 (D101): the Fusion tutorial pack T21-T28, generator-V4 fragment variants, dead-node ablation, exact shortcut screens; Fusion is a production-supported mechanic. Next (each only when explicitly asked): Android tuning from the user's feedback, a first-launch/Level-200 Fusion tutorial nudge if players reach 201 untaught, the star economy (metadata is exposed: `intended_moves`, `verified_optimal_moves`, `target_move_range`, `difficulty_band`), production flag clean-up (all QA flags), certification of Levels 1-2000, a 4-state-aware solver/validator, chained Fusion (composite inputs) as a future mechanic, a post-2000 progression (combinations of existing mechanics inside a curated envelope - Fusion + Prism + Filter, + Portal + Gate, + Receiver + Remote, + One-Way + Portal, three-colour + Receiver, shared/reciprocal systems, multiple Fusion prerequisites; never smaller tiles, > 8 columns or padding). Nothing beyond Level 2000 is exposed.

## Phase 4 (D102, `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`) - stars, Hint cap, central QA switch, Fusion tutorial nudge

- **Stars:** one rule in `StarScoring` (OPTIMAL from `verified_optimal_moves` >= 0, else `intended_moves`, else legacy `optimal_moves`; +2 = 3 stars, +6 = 2, else 1; below optimal = 3 + QA warning). A GRANTED gameplay Hint caps the attempt at 2 stars (`game.gd._hint_used_this_attempt`, persisted in `procedural_resume_hint_used`/`campaign_resume_hint_used` so Continue cannot reset it; cleared by Reset/Next/QA +50). Best stars: `SaveManager.procedural_best_stars["<level>|<generator_version>"]` (raise-only) and the existing campaign dictionary. Tutorials, V3 TEST, FUSION TEST: no stars, no records. The popup shows the current run's stars + a small "HINT USED".
- **QA vs production:** ONE constant, `BuildConfig.IS_PRODUCTION_BUILD` (false in this build). It derives every QA-only UI/unlock flag in `LevelManager` and hides the tutorial debug overlay and the generator tag. Tools are hidden, never deleted. Not covered: Google TEST ad ids, and the generator rollout flags `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA`.
- **Fusion tutorial nudge:** one-time non-blocking "NEW TUTORIAL: FUSION" banner on Main Menu (`LevelManager.should_show_fusion_tutorial_nudge()`, persisted `fusion_tutorial_nudge_seen`); never forces the tutorial, never locks progression. `bs_fusion_icon.png` remains unused (no icon support in the tutorial panel).
- Level 2000 remains the certification target; nothing beyond it is exposed; no new mechanic.


## Procedural Levels 2001-3000 (generator V5, Selector Phase S3, 2026-09-25)

Built (uncommitted): generator V5 = the V4 pipeline + Splitter Selector fragments, bands G-K continuing the late-V4 curve (Level 2001 must feel like progression after 2000, never a reset), `MAX_LEVEL` = 3000 (the CURRENT certification boundary, not a permanent ceiling), T29 available before the introduction (unlock at procedural Level 1900). Difficulty grows through dependency/interaction complexity, never tile size (`MAX_COLUMNS` 8), padding or clutter; exact optimality is UNKNOWN on large state spaces. Status: S3 implemented / NOT certified; S3.1 pass 1 added S-M and reduced bounded J/K demotion, but full certification remains. Next: finish S3.1 (full J/K windows or lower generation cost, remaining families S-I/S-K/S-O, fair decoy routes, stronger minimality/shortcut screens), then manual play review of the V5 TEST levels, then S4 (Android build; measure on-device generation time). See `NEXT_AI_PROMPT.md`. Not planned without a request: Levels 3001+, chained Fusion, Selector families S-I/S-K/S-O.
