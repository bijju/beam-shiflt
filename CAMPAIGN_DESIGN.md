# CAMPAIGN_DESIGN.md

The main reference for producing BeamShift's 100-level handcrafted
campaign. Read this before authoring Stage 2 onward. If anything here
disagrees with the actual level files under `levels/campaign/`, the
files are authoritative — fix this document, don't trust it blindly.

See `DECISIONS.md` D54 for the architecture decisions behind all of
this (why campaign levels are a separate population from the dev/
regression levels, why save data is namespaced separately, etc.) and
`CLAUDE.md`'s scope-discipline rules (no procedural generation, don't
build ahead of what's been asked).

**Note (Era 2 Foundation, see `ERA_2_DESIGN.md`):** this document
describes Levels 1-100 (Era 1) only, which remain completely untouched
by Era 2 Foundation work — same content, same geometry, same difficulty,
same theme. Four new mechanics (Prism, One-Way Reflector, Beam Receiver,
Remote Emitter) now exist in the engine for a future Era 2 campaign
(Levels 101-200), but **no Era 2 campaign levels exist yet** — Campaign
Levels 101+ are still explicitly out of scope until a separate, explicit
request. When that work starts, this file's own template/technique
sections remain the right reference for authoring against `LaserSystem`;
`ERA_2_DESIGN.md` is the reference for the four new mechanics'
exact rules.

**CAMPAIGN REBOOT (current, see D64 for the full writeup):** with the
Guided Tutorial (T01-T10) now teaching every mechanic in isolation and
manually accepted, Campaign Levels 1-50 were rebuilt around a single
permanent rule: **the Campaign is mechanic-agnostic from Level 1
onward.** It no longer exists to teach a mechanic for 10 levels at a
time (the old Stage 1 mirrors / Stage 3 splitters / Stage 4 color /
Stage 5 filters progression) — the player already knows WHAT every
mechanic does from Tutorial; Campaign's only job is teaching HOW TO
THINK with them combined: misdirection, dependencies, backward
reasoning, delayed consequences, planning. **Old Level 50 ("Paradox,"
255 states explored, kept unchanged) is the permanent difficulty-quality
benchmark** for what a "make the player stop and analyze before moving"
campaign level looks like — every level from 21 onward is measured
against it, not against how many mechanics it introduces. See section
11f/11g/11h below for the audit and the new Levels 21-45's own design
tables, and `DECISIONS.md` D64 for the full reasoning, including exactly
which levels were kept vs. replaced and why.

**DIFFICULTY REWORK PASS 2 (current, see `DECISIONS.md` D65):** the
Reboot above (Pass 1) was solver-valid but still too easy in the 21-45
range — optimal-move curves like 3,2,2,2,2 (21-25), 2,2,2,2,5 (31-35),
and 2,4,2,2,3 (41-45) fell far short of the "Hard+/Very Hard/Expert"
labels those levels were supposed to carry, and several were reachable
by a handful of random taps. Pass 2 replaces all 25 Levels 21-45 again
(21-30/31-40/41-45 folders) with new content built for real dependency
depth (cross-branch shared mirrors, filter order, portal misdirection,
switch/gate dependency, multi-emitter dependency, backward reasoning,
blocker/hazard-guarded false forks) rather than inflated move counts —
see section 11f/11g/11h below for the new tables. **Levels 1-20 and
46-50 are untouched by Pass 2**, same as they were untouched by Pass 1.
Tutorial (T01-T10) remains completely separate and unchanged.

## 1. The 100-level structure

10 stages, 10 levels each, campaign level IDs 1-100 running
consecutively across stages (Stage 2's Level 1 is campaign level 11,
etc. — matching `ROADMAP.md`'s table):

| Stage (internal folder only) | Levels | Reboot identity |
|---|---|---|
| 1 | 1-10 | KEPT — manually approved, easy->medium warm-up |
| 2 | 11-20 | KEPT — manually approved, medium->hard escalation |
| 3 | 21-30 | REPLACED — hard+ -> very hard, any mechanic combo |
| 4 | 31-40 | REPLACED — very hard -> expert, any mechanic combo |
| 5 | 41-50 | Levels 41-45 REPLACED, 46-50 KEPT — expert, any mechanic combo |
| 6 | 51-60 | CREATED — expert-entry -> major milestone, no mechanic-teaching reset, continues directly from 46-50 (see section 11i, `DECISIONS.md` D66) |
| 7 | 61-70 | CREATED — expert -> major milestone, no mechanic-teaching reset, continues directly from 51-60 (see section 11j, `DECISIONS.md` D67) |
| 8 | 71-80 | CREATED — MASTER/MASTER+ -> EXTREME, no mechanic-teaching reset, continues directly from 61-70 (see section 11k, `DECISIONS.md` D68) |
| 9 | 81-90 | CREATED — EXTREME/EXTREME+, no mechanic-teaching reset, continues directly from 71-80 (see section 11l, `DECISIONS.md` D69) |
| 10 | 91-100 | CREATED — MASTER+ -> EXTREME -> FINAL CHALLENGE, no mechanic-teaching reset, continues directly from 81-90 (see section 11m, `DECISIONS.md` D70) — **the final stage; the 100-level structure is now complete** |

**As of the Campaign Reboot (see D64), the "Stage = one new mechanic"
identity above is historical only.** The folder names
(`levels/campaign/stage_01/` … `stage_05/`) and the `stage` field's
string values (still "First Light"/"Reflection"/"Split"/"Spectrum"/
"Filters" for save-data continuity, see D54) are **purely internal
organization** — nothing about them is shown to the player, who only
ever sees "Level 1" … "Level 50" in a flat, continuous list (see section
1a below). Levels 21 onward freely combine any mechanic the Tutorial
already teaches, regardless of which folder they live in.

**All 10 stages (campaign levels 1-100) have been created — the
100-level campaign structure originally planned in `ROADMAP.md` is now
complete.** See section 13 for what this means for any future work.

## 1a. Player-facing structure (post-reboot)

The player never sees "Stage 1" through "Stage 10" or their names —
Level Select shows Levels 1-100 as one continuous, flat difficulty
curve (see section 3). The stage folders exist only so campaign level
file paths stay short and organized on disk; `LevelManager.
CAMPAIGN_LEVEL_PATHS` is the single ordered list that actually defines
campaign level 1-100's sequence. Levels 1-50 were **not reordered or
restructured** by either the reboot or Difficulty Rework Pass 2 — only
specific files' *contents* changed (see section 11f/11g/11h for exactly
which); Levels 51-60 (`stage_06`), 61-70 (`stage_07`), 71-80
(`stage_08`), 81-90 (`stage_09`), and 91-100 (`stage_10`) are each a
straight, additive extension appended after the previous block's paths
(see sections 11i/11j/11k/11l/11m and `DECISIONS.md`
D66/D67/D68/D69/D70).

## 2. Difficulty philosophy (post-reboot)

**The Campaign is mechanic-agnostic from Level 1 onward.** It does not
exist to teach a mechanic for 10 levels at a time — the Tutorial (T01-
T10) already teaches every mechanic in isolation before the player ever
reaches Campaign. Campaign's only job is testing combinations and
reasoning: misdirection, dependencies, backward reasoning, delayed
consequences, planning several moves before touching the board. Level 1
does not need to be "the mirror level" any more than Level 45 needs to
be "the filter level" — any level may use any mechanic the Tutorial has
already taught, as long as the level has its own clear reasoning
identity (see section 24-equivalent: every level records a one-sentence
DESIGN INTENT in its own `developer_notes`).

Difficulty must still come from **thinking**, not from busywork. Never
make a level harder merely by growing the grid, filling every cell,
stacking unrelated mechanics, or adding visual clutter — those raise
tedium, not reasoning difficulty, and produce worse puzzles. A locally
correct decision (a branch that reaches its own target) can still be
globally wrong (it triggers a hazard, or leaves a shared dependency
unsatisfied) — see Level 25/38's hazard-guarded splitter branches for a
concrete example.

Real difficulty comes from:
- Misleading routes / competing valid-looking paths (geometry, color,
  portal, filter-order, branch, switch, or global false routes — see
  each new level's `developer_notes` for which type it uses)
- Decoy mirrors (rotatable pieces that look load-bearing but aren't) and
  decoy targets (reachable, but wrong color or non-required)
- Fixed mirrors (pieces the player must route around, not through) —
  backward reasoning from the target through a fixed mirror's one
  possible arrival direction
- Dependencies between multiple beam branches (a splitter's two
  branches converging on one shared mirror from different directions;
  two emitters whose beams depend on the same switch/gate)
- Color requirements and filter-order reasoning (only the LAST filter
  touched before a target survives)
- Portal routing (entry/exit/direction/post-jump route, never just a
  shortcut) and switch/gate sequencing (now used freely from Level 21
  onward, not reserved for a later stage)
- Hazards restricting the obvious route (also used freely from Level 21
  onward)
- Multiple emitters whose paths meaningfully interact, not two
  independent puzzles sharing one board
- Non-obvious interactions between mechanics

Avoid any puzzle whose solution is immediately obvious from a glance at
the board. A player should have to trace the beam mentally, not just
follow their eye to the target.

## 3. Difficulty curve (post-reboot target, human-validated — not the auto-estimate)

| Levels | Target feel |
|---|---|
| 1-5 | Easy → Medium (warm-up after Tutorial, still real puzzles) |
| 6-10 | Medium (first mini-finale at 10) |
| 11-15 | Medium-Hard |
| 16-20 | Hard (first genuinely hard milestone at 20) |
| 21-25 | Hard+ |
| 26-30 | Very Hard (approaching Level 50 quality) |
| 31-35 | Very Hard |
| 36-40 | Very Hard → Expert (comparable to or harder than old Level 50) |
| 41-45 | Expert (whole-board reasoning, any mechanic) |
| 46-49 | Expert+ (each a distinct reasoning identity) |
| 50 | The hardest campaign puzzle so far — permanent milestone |
| 51-54 | Hard+ / Expert entry — continues directly from 46-50, no reset |
| 55 | Expert+ mid-block checkpoint — visibly harder than 52 |
| 56-58 | Expert / Expert+ |
| 59 | Near-finale — whole-board, two-emitter reasoning |
| 60 | MAJOR MILESTONE — the hardest campaign puzzle so far, exceeding Level 50's own benchmark |
| 61-64 | Expert / Expert+ — continues directly from 60, no reset |
| 65 | Master-entry checkpoint — visibly harder than 62 |
| 66-69 | Expert+ / Master / Master+ |
| 70 | MAJOR MILESTONE — a genuine two-stage multi-emitter relay dependency |
| 71-73 | Master — continues directly from 70, no reset |
| 74 | Master+ |
| 75 | Major mid-block checkpoint — visibly more sophisticated than the 61-70 block's average, not merely a larger grid |
| 76-77 | Master+ |
| 78 | Extreme entry |
| 79 | Extreme |
| 80 | MAJOR MILESTONE — four independently-opened gates converge on one target, exceeding Level 70's own two-gate relay in reasoning depth |
| 81-84 | Extreme — continues directly from 80, no reset |
| 85 | Major checkpoint — visibly stronger than the 81-84 average |
| 86-87 | Extreme+ — Level 87 introduces the first three-stage relay |
| 88 | Near-master-final |
| 89 | Extreme milestone |
| 90 | MAJOR CAMPAIGN MILESTONE — five emitters, a three-stage relay, two portals, and two independent converging gates, symmetric on both ends of the relay |
| 91-92 | Master+ — continues directly from 90, no reset |
| 93-94 | Extreme |
| 95 | FINAL-EXAM CHECKPOINT — "I am in the final exam now"; a fixed mirror, a gated third emitter, and a third filter layered onto Level 85's own checkpoint core |
| 96 | Extreme+ — the first shared-state chain (a target's own activation is just a waypoint toward a later emitter's conditions) |
| 97 | Final-exam — a global dependency: three independent-looking sources all depend on the same one late gate |
| 98 | Final-exam+ — backward reasoning plus color/order logic, a 5-link backward chain |
| 99 | Penultimate challenge — two of three targets share dependency on one late gate, with a fourth emitter easy to overlook |
| 100 | THE DEFINITIVE FINAL PUZZLE — every mechanic the campaign teaches, present at once in one coherent system, deliberately no larger and no more padded in move count than Level 90 |

Difficulty is **not perfectly linear** — occasional slight relief
between blocks is fine (e.g. Level 21 opening a new block slightly
below Level 20's peak, matching the exact precedent Stage 3 originally
set), but never resets to Tutorial-level simplicity, and every level
past Level 11 still requires real thought. See `DECISIONS.md` D64 for
the full per-level curve and the honest cases where a later level's
raw move count is lower than an earlier one's (always noted, always for
a stated reason - see section 14's rule, unchanged).

**`LevelMetrics.compute()`'s `difficulty_label` is not authoritative for
this curve** — see section 9 below for why, and always prefer the
target feel in this table plus actual human playtesting over the raw
auto-estimate.

## 4. Optimal-move guidelines (post-reboot, not a hard limit)

| Levels | Optimal moves (guideline) |
|---|---|
| 1-5 | 2-4 |
| 6-10 | 3-5 |
| 11-15 | 4-6 |
| 16-20 | 5-7 |
| 21-25 | 5-8 |
| 26-30 | 6-9 |
| 31-35 | 6-10 |
| 36-40 | 7-11 |
| 41-45 | 7-12 |
| 46-49 | 8-13+ |
| 50 | 10+ if naturally justified |
| 51-60 | 8-14+ (actual: 10,8,7,11,11,8,9,11,11,14 — see section 11i) |
| 61-70 | 9-17+ (actual: 10,10,10,10,12,7,11,9,12,11 — see section 11j) |
| 71-80 | 8-18+ (actual: 11,9,11,8,13,11,12,12,13,14 — see section 11k) |
| 81-90 | 10-18+ (actual: 12,11,11,12,14,12,10,12,13,13 — see section 11l) |
| 91-100 | 11-18+ (actual: 13,13,11,11,15,12,14,14,14,13 — see section 11m) |

These are guidelines, not hard requirements — **a brilliant short
puzzle beats a padded long one.** Several of the reboot's own Levels
21-45 land at 2-4 moves with genuinely dense reasoning (color decoys,
hazard-guarded branches, portal misdirection, backward reasoning
through fixed mirrors) rather than the higher guideline figure, and
that is a deliberate choice, not an oversight — see `DECISIONS.md` D64
for the honest per-level accounting of where the guideline wasn't hit
and why that was still the right call.

## 5. Grid-size guidelines (post-reboot, not a hard limit)

| Levels | Grid size |
|---|---|
| 1-10 | 5x5 / 6x6 |
| 11-30 | 5x5 / 6x6 / occasional 7x7 |
| 31-50 | 6x6 / 7x7 |

Use 8x8+ only if genuinely justified. Never grow the grid merely to
manufacture difficulty — see section 2. Levels 1-20 (kept unchanged)
use 5x5/6x6; the reboot's Levels 21-45 mostly use 7x7 for routing room
without the grid itself being the source of difficulty.

**SUPERSEDED for Levels 1-25 by the Phase 2A portrait re-layout
(2026-09-22, see `DECISIONS.md` D73)** — this table describes each
level's *original* (pre-Phase-2A) shape, which is no longer accurate
for Levels 1-25. Their current shapes: Levels 1-6/11-14/20 are 5x6/6x7
(zero cell-size cost); Levels 7-10/15-19 are 5x7 (modest cell-size
trade for fuller height); Levels 21-24 are 6x7 and Level 25 is 7x8
(columns compacted from their original 7-9, since those were the only
levels already rendering below `UIConstants.MIN_TOUCH_TARGET`). This
was a **geometry-only** re-layout via an order-preserving coordinate
remap — the difficulty/mechanics/solution identity documented in
sections 11/11b/11f below is completely unchanged and still accurate;
only `grid_width`/`grid_height`/tile *positions* differ from what those
tables' original design notes described.

**SUPERSEDED for Levels 26-50 by the Phase 2B portrait re-layout
(2026-09-22, see `DECISIONS.md` D74)** — same caveat, same guarantee.
Their current shapes: 6x7 (12 levels), 7x8 (9 levels, including Level 50
"Paradox" at an unchanged cell size), 8x9 (Levels 37/40), 6x8 (Level
41), 9x10 (Level 45). Sections 11f/11g/11h's difficulty/mechanics/
solution identity is completely unchanged and still accurate — only
geometry differs from what those sections' original design notes
described.

**SUPERSEDED for Levels 51-75 by the Phase 2C portrait re-layout
(2026-09-22, see `DECISIONS.md` D75)** — same caveat, same guarantee.
Their current shapes: 6x7 (2 levels), 7x8 (6 levels), 8x9 (5 levels),
8x10 (Level 59), 9x10 (9 levels), 10x11 (Level 57). **Level 75
("Convergence Reaction") is the one exception — left unchanged**,
already fully packed on both axes. Sections 11i/11j/11k's difficulty/
mechanics/solution identity is completely unchanged and still accurate
— only geometry differs from what those sections' original design notes
described.

**SUPERSEDED for Levels 76-100 by the Phase 2D portrait re-layout —
THE FINAL BATCH (2026-09-22, see `DECISIONS.md` D76)** — same caveat,
same guarantee. Their current shapes: 9x10 (6 levels, compacted from
10-wide), 10x12 (15 levels, zero-cost row growth from 10x10). **Levels
85, 91, 95, and 98 are the exceptions — left unchanged**, already fully
packed on both axes, same situation as Level 75. Sections 11l/11m's
difficulty/mechanics/solution identity is completely unchanged and
still accurate — only geometry differs from what those sections'
original design notes described. **This completes the portrait
re-layout of all 100 campaign levels** — every level in this document
now reflects its POST-re-layout board shape via the two SUPERSEDED
notes above (1-25/26-50/51-75/76-100); the original tables above
remain historically accurate for design INTENT (mechanics, dependency
structure, solutions) but not for board dimensions.

## 6. Production-level acceptance criteria

A campaign level is **rejected and must be redesigned** if any of the
following is true:

- `LevelSolver.analyze()` returns `status == "UNSOLVABLE"`
- `status == "UNKNOWN"` because of poor state-space design (too many
  rotatable pieces for the level's own complexity, not because it
  genuinely needs more than `LevelSolver.DEFAULT_MAX_STATES`)
- `result["trivial"] == true` (a zero-move / already-solved authored
  state)
- The solver's `optimal_moves` differs from the level's own declared
  `optimal_moves` — **always trust the solver and set the declared
  value from its result, never guess** (see section 7)
- An "obvious" straight-line solution bypasses the intended reasoning
  (i.e. the puzzle doesn't actually require thinking about the
  mechanic it's meant to teach)
- Only one trivial mirror rotation solves a puzzle positioned later in
  a stage than that trivial difficulty warrants
- A stage's own later levels are measurably easier than its earlier
  ones (the curve must not invert within a stage)
- The level contains irrelevant complexity with no reasoning value —
  see section 8 for the difference between that and a real decoy

`LevelValidator.validate()` must also return zero `errors` (warnings
are advisory — read them, but they don't block acceptance on their
own).

## 7. Solver-validation workflow

For every new campaign level:

1. Design the layout, tracing the intended solution by hand against
   `GridTypes.reflect()`'s actual table (SLASH: RIGHT→UP, LEFT→DOWN,
   UP→RIGHT, DOWN→LEFT; BACKSLASH: RIGHT→DOWN, LEFT→UP, UP→LEFT,
   DOWN→RIGHT) — don't guess from memory, the table is a `static func`
   in `scripts/gameplay/grid_types.gd`, read it directly.
2. Write the level as a `.gd` file (`extends LevelData`, `_init()`,
   `TilePlacement.make_*()` factories) exactly like every existing
   level under `levels/` or `levels/campaign/stage_01/`.
3. Run `LevelValidator.validate()` and `LevelSolver.analyze()` against
   it via a temporary headless script (`godot --headless --path .
   --script <path>.gd`, `extends SceneTree`, per this project's
   standard throwaway-test-harness convention — see `TEST_PLAN.md`).
   Do this for every new level in one batch script rather than one at
   a time.
4. Compare the solver's `optimal_moves` against your hand-traced
   intent. If they disagree, your hand-trace had an error somewhere —
   re-read `solution_path` (it names the exact tile positions and
   orientations) to find it, fix the level, and re-run. **Never just
   paper over a mismatch by setting `optimal_moves` to whatever the
   solver says without understanding why your trace was wrong** — the
   mismatch usually means the level doesn't teach what you intended.
5. Once `status == "SOLVABLE"` and the solver's `optimal_moves` matches
   your design intent, set the level's `optimal_moves` field to that
   confirmed value.
6. Check `possible_decoys` against every rotatable piece you *intended*
   as a decoy (see section 8) and every one you didn't (which should
   come back empty for those pieces — if a "real" mirror shows up as a
   possible decoy, it means that piece doesn't actually matter for
   solving, which is a design bug to fix, not a note to shrug off).
7. Run the solver-vs-runtime-replay technique (`TEST_PLAN.md`'s
   standard regression script, extended with the new campaign paths) to
   confirm the solved state is reachable through the real
   `GridManager._on_orientable_tile_clicked()` path, not just
   `LaserSystem` in isolation.
8. Only after all of the above passes, wire the level into
   `LevelManager.CAMPAIGN_LEVEL_PATHS` and re-run the full boot/runtime
   validation (Level Select shows it, Game loads it, solving it writes
   to `SaveManager`'s `campaign_*` fields correctly).

## 8. Decoy design rules

A decoy is a rotatable piece whose orientation the solver confirms
doesn't affect solvability (`LevelSolver.analyze()`'s
`possible_decoys` list) — but a decoy that's merely *unused* isn't
automatically a *good* decoy.

- **Do** place it somewhere a player scanning the board would plausibly
  think it's part of the route — near the real path, in a row/column
  that looks relevant, or near a trap (a blocker/dead-end) so it seems
  connected to avoiding it.
- **Don't** dump it in a random remote corner with no visual reason a
  player would ever consider it.
- **Watch for beams continuing past an activated target.**
  `LaserSystem` deliberately lets a beam continue through a target
  after activating it (so one beam can activate several targets in a
  chain — relevant from Stage 3 onward). This means a decoy placed on
  the far side of a target, in the beam's original direction, is
  **not actually untouched** — the beam will hit it after solving. Trace
  the full post-target path, not just the path up to the target, before
  placing a decoy near one. (This bit Campaign Level 9's first draft —
  see `DECISIONS.md` D54.)
- Record every intentional decoy's cell and reasoning in the level's
  own `developer_notes` field — this is required, not optional (see
  section 10).
- If the solver flags a decoy you didn't intend, that's a real design
  bug (a piece you meant to matter, doesn't) — fix the level, don't
  just relabel it as intentional after the fact.

## 9. On the automatic difficulty estimate

`LevelMetrics.compute()`'s `difficulty_label` (`TUTORIAL`/`EASY`/
`MEDIUM`/`HARD`/`EXPERT`) is explicitly documented as non-authoritative
(`DECISIONS.md`, "Difficulty heuristic") — this section adds a concrete,
now-confirmed reason not to trust it blindly for early-stage levels
specifically: **the "mechanics_used" count includes "Colored beams" for
*any* level with an emitter, even one using the default `WHITE` color**
(`LevelMetrics._mechanics_list()` checks `colors_used.size() > 0`, and
`colors_used` is populated from every emitter's `color` field
regardless of value — `WHITE` still counts). Since every level has at
least one emitter, this silently adds +3 to every level's difficulty
score, which is enough on its own to push several genuinely easy Stage
1 levels into `HARD`/`EXPERT` territory despite being, by design,
1-4-move tutorial puzzles on a 5x5 grid with one real decision point.

All 10 Stage 1 levels' raw `difficulty_label` results (for the record,
not as a target): Levels 1,2,4,5 → `MEDIUM`; Levels 3,6,7,8,9 → `HARD`;
Level 10 → `EXPERT`. **Do not use these labels to judge whether Stage 1
hit its "Tutorial/Easy" target** — use section 3's curve, the actual
solver-confirmed move counts (1,2,2,2,2,3,3,4,3,4 — see section 11's
table), and real human playtesting instead. This is a known,
pre-existing quirk of `LevelMetrics`, not something introduced or fixed
this pass — flagged here so a future session doesn't waste time
re-discovering it, and doesn't mistake an inflated label for a signal
that a level needs to be made easier.

## 10. Level metadata requirements

Every campaign level file must set, in its `_init()`:

- `level_id` — position within its own stage's 1-10 numbering (not a
  global 1-100 id — see `DECISIONS.md` D54 for why)
- `display_name` — short, thematic, mobile-friendly (see section 12)
- `stage` — the stage name exactly as it appears in section 1's table
  (e.g. `"First Light"`) — this is what self-identifies a level's stage
  regardless of which directory it physically lives in
- `grid_width` / `grid_height`
- `optimal_moves` — solver-confirmed, never hand-guessed (section 7)
- `is_campaign_level = true` — the flag that distinguishes this from a
  dev/regression level (`DECISIONS.md` D29)
- `developer_notes` — the level's teaching goal in one sentence, plus
  an explicit `INTENTIONAL DECOY:` note (with cell + reasoning) for
  every decoy piece, if any
- `tiles` — via `TilePlacement.make_*()` factories, same as every
  existing level file

## 11. Stage 1 — First Light — design table

All 10 levels: 5x5 grid, one emitter, one required target, `WHITE`
beam. Every `optimal_moves` value below is solver-confirmed (not
hand-guessed) via `LevelSolver.analyze()`, and every level's solved
state was re-confirmed reachable through the real
`GridManager._on_orientable_tile_clicked()` path via the solver-vs-
runtime-replay technique.

| # | Name | Rotatable | Fixed | Blockers | Decoys | Solver Optimal | Shortest Solutions | States Explored | Teaching goal |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Ignition | 1 | 0 | 0 | 0 | 1 | 1 | 2 | Basic mirror rotation |
| 2 | First Turn | 2 | 0 | 0 | 0 | 2 | 1 | 4 | Chaining two reflections |
| 3 | Signal Path | 2 | 0 | 0 | 0 | 2 | 1 | 7 | Multiple mirrors (a 3-mirror staircase; only 2 need rotating) |
| 4 | Blocked | 2 | 0 | 1 | 0 | 2 | 1 | 4 | Blocker punishes a wrong fork |
| 5 | Alignment | 2 | 1 | 0 | 0 | 2 | 1 | 4 | Routing around a fixed (non-rotatable) mirror |
| 6 | False Signal | 3 | 0 | 0 | 0 | 3 | 1 | 8 | A junction with two plausible continuations, only one real |
| 7 | Deception | 3 | 0 | 0 | 1 | 3 | 1 | 15 | First genuine decoy piece |
| 8 | Long Relay | 4 | 0 | 0 | 0 | 4 | 1 | 16 | Planning a full 4-bounce route before moving |
| 9 | Junction | 3 | 1 | 1 | 1 | 3 | 1 | 15 | Combines fixed mirror + blocker + decoy |
| 10 | Breakthrough | 4 | 1 | 1 | 2 | 4 | 1 | 57 | Stage finale: every mechanic, longest/most winding route |

Every level: `status = SOLVABLE`, `trivial = false`, zero validator
errors, zero validator warnings. `shortest_solution_count = 1`
throughout — each level has exactly one shortest solution (deliberately
constrained per section 8's "avoid many trivial shortest solutions"
guidance), not because a tighter constraint is required in general.

No level was rejected or needed redesigning after the first solver
pass — every hand-traced solution matched the solver's confirmed
result exactly on the first attempt (the design process in section 7
was followed throughout, including re-tracing the reflection table by
hand before writing each file, which is why no rejections were needed).
The one real design correction made during authoring was Campaign Level
9's decoy placement, moved from `(0,4)` to `(0,3)` after realizing the
original position sat on the beam's continuation path *after* the
target (see section 8's bullet on this exact trap).

## 11b. Stage 2 — Reflection — design table

All 10 levels use a 5x5 grid except Level 20 (6x6, the finale). One
emitter, one required target, `WHITE` beam throughout — per Stage 2's
own scope, no splitters/colors/filters/portals/switches/gates/hazards
are used yet. Every `optimal_moves` value is solver-confirmed via
`LevelSolver.analyze()`, and every level's solved state was re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path via the solver-vs-runtime-replay technique. **Manual Difficulty
Feedback is PENDING for all 10 — the user has not yet played Stage 2.**

| # | Name | Grid | Rotatable | Fixed | Blockers | Decoys | False Routes | Optimal | Shortest Sols | States | Backward Reasoning? | Multi-Step Dependency? | Design goal | Manual Feedback |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 11 | Redirect | 5x5 | 3 | 0 | 0 | 0 | No | 3 | 1 | 8 | No | No | Bridge from Stage 1 - longer 3-mirror chain, baseline for Stage 2's "trace the whole route" mindset | PENDING |
| 12 | Dead End | 5x5 | 3 | 0 | 1 | 0 | Yes (blocker-guarded fork) | 3 | 1 | 8 | No | No | Blocker makes the fork's wrong orientation a real dead end, not a silent exit | PENDING |
| 13 | Fork Point | 5x5 | 4 | 0 | 0 | 1* | Yes (two plausible multi-cell branches) | 3 | 1 | 15 | No | No | Two genuinely plausible continuations from one mirror; only one reaches the target | PENDING |
| 14 | Reverse Trace | 5x5 | 3 | 1 | 0 | 0 | No | 3 | 1 | 8 | **Yes** | No | Fixed mirror beside the target demands one specific approach direction | PENDING |
| 15 | Mirage | 5x5 | 5 | 0 | 0 | 1 | No | 4 | 1 | 31 | No | No | First dedicated decoy: a mirror beside the real path's final turn, never touched | PENDING |
| 16 | Cascade | 5x5 | 4 | 0 | 0 | 0 | Yes (early fork, no clue which way) | 4 | 1 | 16 | No | **Yes** | Mirror A's correct choice only makes sense once the full downstream route is traced | PENDING |
| 17 | Backtrack | 5x5 | 4 | 1 | 1 | 0 | Yes (blocker-guarded fork) | 4 | 1 | 16 | **Yes** | No | Fixed mirror + blocker combined with a second backward-reasoning payoff | PENDING |
| 18 | Echo Path | 5x5 | 5 | 1 | 0 | 0 | No | 5 | 1 | 32 | No | Yes (long chain) | Five-turn route touring all four board edges before converging | PENDING |
| 19 | Interference | 5x5 | 7 | 0 | 0 | 2 | No | 5 | 1 | 120 | No | Yes (long chain) | Pre-finale: longest Stage 2 route with two decoys planted near the action | PENDING |
| 20 | Culmination | 6x6 | 6 | 2 | 2 | 1 | Yes (2 blocker-guarded forks) | 5 | 1 | 63 | **Yes** | **Yes** | Stage 2 finale: 7-segment route, 2 fixed mirrors, 2 blockers, 1 decoy, backward reasoning and full-chain dependency together | PENDING |

*Level 13's false-branch mirror at `(2,0)` is functionally a decoy under
`LevelSolver`'s own definition (toggling it never breaks the solution)
even though it was designed as a "plausible wrong continuation" rather
than a dedicated decoy piece like Level 15's — both are recorded
honestly as `possible_decoys` hits, see section 8's distinction.

Every level: `status = SOLVABLE`, `trivial = false`, zero validator
errors, zero validator warnings, `shortest_solution_count = 1`
throughout. **Three levels use backward reasoning** (14, 17, 20 — the
exact set requested) and **three levels are explicitly built around
multi-step dependency** (16, 20 by direct design; 18 and 19 also exhibit
it as a natural consequence of their long chains, though not their
primary teaching goal).

**Comparison against Stage 1** (see section 17's complexity-check
methodology): Stage 1's `states_explored` ranged 2-57 (median ~8); Stage
2's ranges 8-120 (median ~16), with three levels (15, 18, 19) already
exceeding Stage 1's finale (57), and Level 19 specifically hitting 120 -
more than double Stage 1's highest. Stage 1's optimal-move curve was
1,2,2,2,2,3,3,4,3,4; Stage 2's is 3,3,3,3,4,4,4,5,5,5 - starting at
Stage 1's own peak and climbing to 5, a genuine escalation rather than a
reset. This increase emerged from the designs (route length, fork count,
fixed-mirror clusters), not from padding move counts - no level's
`optimal_moves` was inflated beyond what its actual mechanic required.

No level was rejected or needed redesigning after the first solver pass
— identical outcome to Stage 1, for the same reason: every path was
re-traced by hand against `GridTypes.reflect()`'s actual table before
writing the file, and two geometry errors were caught and fixed *before*
ever running the solver (see `DECISIONS.md` D55 for both - an early
Level 11 draft had a target position unreachable by its own mirror
chain, and an early Level 12 draft placed a blocker on a cell no beam
configuration could ever reach, making it functionally decorative).

## 11c. Stage 3 — Split — design table

All 10 levels use a 5x5 or 6x6 grid (Levels 21-25 use 5x5; Levels 26-30
use 6x6 for the added relay/backward-reasoning chains). One emitter,
one splitter per level, `WHITE` beam throughout - no colors/filters/
portals/switches/gates/hazards/second emitters, per Stage 3's own
scope. Every `optimal_moves` value is solver-confirmed via
`LevelSolver.analyze()`, and every level's solved state was re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path via the solver-vs-runtime-replay technique. **Manual Difficulty
Feedback is PENDING for all 10 - the user has not yet played Stage 3.**

Splitter behavior (verified directly against `LaserSystem.simulate()`
before any level was designed, per this document's own workflow - see
`DECISIONS.md` D56 for the full write-up): a splitter always sends one
beam straight through unconditionally (direction unchanged, independent
of orientation) AND one branch beam reflected via the identical
`GridTypes.reflect()` table mirrors use. Splitter orientation is
rotatable exactly like a mirror (shares `TilePlacement.mirror_orientation`/
`rotatable`), rotating one counts as a move exactly like a mirror
(`GridManager._on_orientable_tile_clicked()` handles both identically),
and the shared `visited_states` loop guard covers splitter branches the
same as every other beam - a splitter can never hang the simulation.

| # | Name | Grid | Splitters | Required Targets | Rotatable | Fixed | Blockers | Decoys | False Routes | Optimal | Shortest Sols | States | Backward Reasoning? | Cross-Branch Dependency? | Splitter Essential? | Design goal | Manual Feedback |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 21 | Divide | 5x5 | 1 | 2 | 2 | 0 | 0 | 0 | No | 2 | 1 | 4 | No | No | Yes | Splitter tutorial - straight branch is unconditional (deliberately free, the one sanctioned exception to "every target needs a move"), reflected branch needs one mirror | PENDING |
| 22 | Dual Signal | 5x5 | 1 | 2 | 3 | 0 | 0 | 0 | No | 3 | 1 | 8 | No | No | Yes | Both targets require a move (no free target this time) - one branch easy (1 move), one needs adjustment (2 moves) | PENDING |
| 23 | Fork Path | 5x5 | 1 | 2 | 4 | 0 | 0 | 0 | No | 4 | 1 | 16 | No | No | Yes | Branch asymmetry - short route (1 mirror) vs. long route (splitter + 2 mirrors) | PENDING |
| 24 | Branch Cut | 5x5 | 1 | 2 | 4 | 0 | 1 | 0 | Yes (blocker on authored branch) | 4 | 1 | 16 | No | No | Yes | Blocker punishes the splitter's default branch orientation; straight side has its own independent mirror | PENDING |
| 25 | False Fork | 5x5 | 1 | 2 | 5 | 0 | 0 | 1 | Yes (dead-end corridor) | 4 | 1 | 31 | No | No | Yes | First genuine splitter decoy; authored branch orientation runs down a plausible-looking dead end | PENDING |
| 26 | Cross Branch | 5x5 | 1 | 2 | 4 | 0 | 0 | 0 | No | 4 | 1 | 16 | No | **Yes** | Yes | Core Stage 3 lesson - one shared mirror is hit by both the straight and reflected beams from different directions; only one orientation satisfies both | PENDING |
| 27 | Relay Split | 6x6 | 1 | 2 | 5 | 1 | 1 | 1 | Yes (blocker-guarded branch) | 4 | 1 | 31 | **Yes** | No | Yes | Fixed mirror beside Target A only redirects correctly from one approach direction, forcing the straight-through side to be the one that reaches it | PENDING |
| 28 | Split Trap | 6x6 | 1 | 2 | 6 | 0 | 1 | 1 | Yes (blocker-guarded branch) | 5 | 1 | 63 | No | **Yes** | Yes | Reuses Level 26's shared-mirror mechanic deeper in each chain - a player solving one branch in isolation can convince themselves it's correct and still find the other target unreachable; the fix is always the shared mirror | PENDING |
| 29 | Parallel | 6x6 | 1 | 2 | 6 | 1 | 1 | 1 | Yes (blocker-guarded branch) | 5 | 1 | 63 | **Yes** | No | Yes | Pre-finale - relay chain into the splitter, backward reasoning off a fixed mirror, blocker-guarded false route, and a decoy together | PENDING |
| 30 | Fracture | 6x6 | 1 | 2 | 7 | 1 | 1 | 1 | Yes (blocker-guarded branch) | 6 | 1 | 127 | **Yes** | **Yes** | Yes | Stage 3 finale - one FIXED mirror shared by both beams from two different directions (backward reasoning + cross-branch dependency combined); leaving the entrance relay mirror unrotated is a "looks fine, changes nothing downstream" trap that fails the whole level | PENDING |

Every level: `status = SOLVABLE`, `trivial = false`, zero validator
errors, zero validator warnings, `shortest_solution_count = 1`
throughout. **Splitter essentiality confirmed for all 10** - the
splitter itself never appears in any level's `possible_decoys` list,
meaning its orientation is load-bearing everywhere it's used. Every
`possible_decoys` hit exactly matches an intentionally-placed decoy
piece named in that level's own `developer_notes` (Levels 25, 27, 28,
29, 30) - no unintended decoys were found on any level, and no level
needed rejection or redesign for a design/logic reason (one level, 30,
needed a one-line fix - see below).

**One real authoring mistake was caught by the solver, not by hand-
tracing** (see `DECISIONS.md` D56 for the full account): Level 30's
first draft accidentally authored the mirror at `(3,3)` already in its
*solved* orientation instead of the deliberately-wrong starting state
every other rotatable piece uses, so the solver found a 5-move solution
that skipped it entirely - one move short of the intended 6-move
finale. Fixed by flipping its authored orientation to the wrong state,
re-run, solver confirmed 6. Every other level matched its hand-traced
intent exactly on the first solver pass.

**Comparison against Stage 2** (see section 17's complexity-check
methodology): Stage 2's `states_explored` ranged 8-120 (median ~16);
Stage 3's ranges 4-127 (median ~24), with Level 30 specifically
exceeding Stage 2's highest (120). Stage 2's optimal-move curve was
3,3,3,3,4,4,4,5,5,5; Stage 3's is 2,3,4,4,4,4,4,5,5,6 - intentionally
starting lower (Level 21 is a splitter tutorial, explicitly allowed to
be easier than Stage 2's finale per the brief) and climbing past Stage
2's peak by the finale. The curve is monotonically non-decreasing
throughout (no later level solves in fewer moves than an earlier one),
per section 14's rule.

## 11d. Stage 4 — Spectrum — design table

All 10 levels use a 5x5 (Levels 31-32) or 6x6 (Levels 33-40) grid. One
emitter, `WHITE` never used - every level's beam is RED, GREEN, or BLUE.
No filters, portals, switches, gates, hazards, or second emitters, per
Stage 4's own scope (filters are reserved for Stage 5 - see
`DECISIONS.md` D57). Every `optimal_moves` value is solver-confirmed via
`LevelSolver.analyze()`, and every level's solved state was re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path via the solver-vs-runtime-replay technique. **Manual Difficulty
Feedback is PENDING for all 10 - the user has not yet played Stage 4.**

**Color model used (verified directly against `LaserSystem`/`GridTypes`
before any level was designed - see `DECISIONS.md` D57):** a single
emitter's `color` is fixed for its entire beam graph - mirrors, fixed
mirrors, and splitters (both branches) all preserve color unchanged;
only a `FILTER` tile can recolor a beam, and Stage 4 uses none. This
means every level's REQUIRED targets all share the emitter's one color
(or `WHITE`, which accepts any color) - a required target of a
different color would make the level unsolvable by construction, so
"color reasoning" throughout Stage 4 comes from **non-required,
differently-colored target decoys** the beam can genuinely reach
(`target_accepts_color()` correctly refuses them) sitting on plausible-
looking false routes, not from mixing multiple required colors into one
beam graph.

| # | Name | Grid | Splitters | Required Targets | Target Colors | Rotatable | Fixed | Blockers | Decoys | False Routes | Optimal | Shortest Sols | States | Backward Reasoning? | Cross-Branch Dependency? | Color Essential? | Design goal | Manual Feedback |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 31 | Prism | 5x5 | 0 | 1 | RED | 2 | 0 | 0 | 0 (1 non-required color decoy on the direct path) | No (deliberately simple, per brief) | 2 | 1 | 4 | No | No | Yes | STAGE 4 INTRODUCTION - a GREEN target sits directly on the beam's straight path; the RED beam crosses it without activating, then two mirrors reach the real RED target | PENDING |
| 32 | Wavelength | 5x5 | 0 | 1 | BLUE | 3 | 0 | 0 | 0 (1 color decoy on the false branch) | Yes (mirror (2,2) unrotated reaches a GREEN decoy) | 3 | 1 | 8 | No | No | Yes | First genuine color-driven false route - the "obvious" branch is geometrically clean but wrong color | PENDING |
| 33 | Refraction | 6x6 | 0 | 1 | GREEN | 4 | 1 | 0 | 0 (1 color decoy crossed twice by the true path) | No | 4 | 1 | 16 | **Yes** | No | Yes | Longer chain through a FIXED mirror - entry direction plus required color, both reasoned backward from the target | PENDING |
| 34 | Photon | 6x6 | 0 | 1 | RED | 4 | 0 | 1 | 0 (1 color decoy on the true path) | Yes (blocker-guarded fork) | 4 | 1 | 16 | No | No | Yes | Combines a blocker-guarded geometric failure with a color-decoy reminder on the one route that satisfies both | PENDING |
| 35 | Chromatic | 6x6 | 1 | 2 | BLUE, BLUE | 4 | 0 | 0 | 0 (1 color decoy on the branch's wrong orientation) | Yes (splitter unrotated reaches a GREEN decoy) | 4 | 1 | 16 | No | No | Yes | Stage 3's splitter knowledge returns - straight branch free (Stage 3 L21 pattern), reflected branch needs 3 more mirrors past a color decoy | PENDING |
| 36 | Diffraction | 6x6 | 1 | 2 | RED, RED | 5 | 0 | 1 | 0 (1 color decoy on the splitter's wrong branch) | Yes (splitter unrotated reaches a GREEN decoy) | 5 | 1 | 32 | No | **Yes** | Yes | FIRST MAJOR CHALLENGE - a mirror shared by both the splitter's straight and reflected beams (arriving from different directions); only one orientation satisfies both required targets at once | PENDING |
| 37 | Phase | 6x6 | 0 | 1 | GREEN | 5 | 2 | 0 | 0 (1 color decoy on the false route) | Yes (mirror (2,2) unrotated runs through 2 fixed mirrors to a color decoy) | 5 | 1 | 32 | **Yes** | No | Yes | Designed backward from the target through 5 mirrors; the false route reuses two fixed mirrors from different arrival directions, testing entry-direction reasoning | PENDING |
| 38 | Radiance | 6x6 | 1 | 2 | RED, RED | 6 | 0 | 1 | 0 (1 color decoy on the false route, crossed twice) | Yes (mirror (2,2) unrotated gates the entire rest of the board) | 6 | 1 | 64 | No | **Yes** | Yes | GLOBAL DEPENDENCY - the very first mirror gates BOTH required targets at once, even though the splitter and its branches sit much later and look unrelated | PENDING |
| 39 | Pulse | 6x6 | 1 | 2 | BLUE, BLUE | 6 | 1 | 1 | 0 (1 reachable-but-wrong-color decoy, 1 right-color-but-blocked decoy) | Yes (2: color-rejected route + geometry-rejected route) | 6 | 1 | 64 | No | **Yes** | Yes | PRE-FINALE - one route is geometrically correct but wrong color, another is color-compatible but blocked; only the true 6-mirror route satisfies both | PENDING |
| 40 | Spectral | 6x6 | 1 | 2 | GREEN, GREEN | 6 | 1 | 1 | 0 (1 reachable-but-wrong-color decoy, 1 right-color-but-blocked decoy) | Yes (2: color-rejected route + geometry-rejected route) | 6 | 1 | 64 | **Yes** | **Yes** | Yes | STAGE 4 FINALE - an early mirror gates everything; a splitter's two branches converge on one shared mirror from different directions; a fixed mirror right before the first target only works for one entry direction | PENDING |

Every level: `status = SOLVABLE`, `trivial = false`, zero validator
errors, zero validator warnings, `shortest_solution_count = 1`
throughout, **zero unintended `possible_decoys`** - every rotatable
mirror/splitter in all 10 levels is load-bearing, confirmed by the
solver on the first pass for every level (no redesigns were needed).
Every level's hand-traced solution (against `GridTypes.reflect()`'s
actual table, worked out by hand before running anything - see section
7) matched the solver's confirmed `optimal_moves` exactly on the first
attempt for all 10 levels - no mismatches, no re-tracing required. The
"decoys" column above counts intentional **color-target** decoys (non-
required `TARGET` tiles of the wrong color for that level's beam), not
`possible_decoys` from the solver (which reports rotatable-piece decoys,
of which Stage 4 has none, same as Stage 3).

**Comparison against Stage 3** (see section 17's complexity-check
methodology): Stage 3's `states_explored` ranged 4-127 (median ~24);
Stage 4's ranges 4-64 (median 24) - a comparable median but a narrower
top end, because Stage 4's rotatable-piece counts (2-6) stayed lower
than Stage 3's finale (7) even as the *reasoning* load rose (every
Stage 4 level from 33 onward adds a color-decoy layer Stage 3 never had,
and Levels 36/38/39/40 combine that with cross-branch or global
dependency). Stage 3's optimal-move curve was 2,3,4,4,4,4,4,5,5,6;
Stage 4's is 2,3,4,4,4,5,5,6,6,6 - matching Stage 3's finale (6) by
Level 38 and holding there through the Stage 4 finale, consistent with
CAMPAIGN_DESIGN.md's explicit anti-padding guidance (section 4: "never
pad a level's move count artificially"). The curve is monotonically
non-decreasing throughout, per section 14's rule.

**Color correctness and solver/runtime parity** were verified directly
against `LaserSystem`/`GridTypes` in a temporary headless fixture before
any level was designed (deleted afterward, per this section's own
workflow): RED/GREEN/BLUE beams each activate only their own color (and
`WHITE`) targets, all 6 mismatched color pairs correctly fail to
activate, mirrors/fixed mirrors/splitters (both branches) all preserve
color unchanged, and a `WHITE`-required target accepts any beam color
while a colored-required target rejects the default `WHITE` beam. Solver/
runtime parity holds **by construction**, not just by testing - both
`LevelSolver.analyze()` and `GridManager._simulate_and_draw()` call the identical
`LaserSystem.simulate_until_stable()`, so there is no separate "solver
color logic" to drift out of sync with runtime. See `DECISIONS.md` D57.

## 11e. Stage 5 — Filters — design table (historical; Levels 41-45 superseded)

**SUPERSEDED for Levels 41-45 by the Campaign Reboot (see section 11h
and `DECISIONS.md` D64) — the table below describes the original
`versionCode=17`-era Stage 5 authoring pass and is kept for historical
record only. Levels 46-50's rows remain fully accurate (those five
files were not touched by the reboot).** The table's own header text
below (grid sizes, filter scope) describes the pre-reboot Stage 5 as
originally designed, before the reboot removed the "filters are Stage
5's own new mechanic, introduced here for the first time" framing
entirely — every mechanic has been available since Level 21 post-reboot.

**Stage 4 feedback recorded:** the user played/reviewed Stage 4 and
reported campaign levels 31-40 **feel easy**. Stage 4's status stayed
`IMPLEMENTED / VALIDATED` at the time (not redesigned — no bug was
found, only a difficulty note); Stage 4 (Levels 31-40) has since been
fully replaced by the Campaign Reboot — see section 11g.

All 10 levels use a 6x6 (Levels 41-45) or 7x7 (Levels 46-50) grid. One
emitter, `FILTER` tiles introduced as the stage's core new mechanic. A
`FILTER` has no `mirror_orientation`/`rotatable` fields at all (see
`DECISIONS.md` D16) — it is never a move, never part of the solver's
rotatable bitmask, and unconditionally overwrites any beam's color the
instant it passes through, regardless of incoming color or direction.
Chaining filters is supported and verified: **only the LAST filter
touched before a target determines that beam's final color** — an
earlier filter's output is completely overwritten by a later one on the
same path, never blended. No portals/switches/gates/hazards/second
emitters, per Stage 5's own scope. Every `optimal_moves` value is
solver-confirmed via `LevelSolver.analyze()`, and every level's solved
state was re-confirmed reachable through the real
`GridManager._on_orientable_tile_clicked()` path via the solver-vs-
runtime-replay technique. **Manual Difficulty Feedback is PENDING for
all 10 - the user has not yet played Stage 5.**

| # | Name | Grid | Emitter Color | Filters (color, position) | Splitters | Required Targets | Target Colors | Rotatable | Fixed Mirrors | Blockers | Decoys | False Routes | Optimal | Shortest Sols | States | Backward Reasoning? | Cross-Branch Dependency? | Filter Essential? | Filter-Order Reasoning? | Design goal | Manual Feedback |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 41 | Filter | 6x6 | WHITE | 1 RED (4,0) | 0 | 1 | RED | 3 | 0 | 0 | 0 | No | 3 | 1 | 8 | No | No | Yes | No | STAGE 5 INTRODUCTION - clean, non-deceptive: incoming color -> filter -> changed color -> matching target | PENDING |
| 42 | Shift | 6x6 | WHITE | 1 RED (4,0) | 0 | 1 | RED | 4 | 0 | 0 | 0 | Yes (direct bypass, same target cell, wrong/no color) | 4 | 1 | 16 | No | No | Yes | No | First geometrically-valid-but-color-invalid route - a short bypass reaches the SAME target cell still WHITE | PENDING |
| 43 | Cipher | 6x6 | WHITE | 2: RED (4,0) then BLUE (5,2), sequential | 0 | 1 | BLUE | 4 | 1 | 0 | 0 | Yes (bypass skips both filters, still WHITE) | 4 | 1 | 16 | No | No | Yes | **Yes** | Sequential filtering - only the LAST filter (BLUE) survives to the target; RED is completely overwritten | PENDING |
| 44 | Channel | 6x6 | RED | 1 BLUE (4,0), downstream of the split, one branch only | 1 | 2 | RED, BLUE | 5 | 0 | 0 | 0 | Yes (splitter unrotated -> color decoy) | 5 | 1 | 32 | No | No | Yes | No | First splitter+filter combination - straight branch preserves RED, reflected branch must detour through the filter for BLUE | PENDING |
| 45 | Conversion | 6x6 | RED | 2: GREEN (1,0), BLUE (5,2), one per branch | 1 | 2 | GREEN, BLUE | 5 | 0 | 0 | 0 | No | 5 | 1 | 32 | No | No | Yes | No | Target-assignment reasoning - spatially crossed: the straight branch's target sits at the far LEFT, the reflected branch's at the far RIGHT | PENDING |
| 46 | Frequency | 7x7 | RED | 1 BLUE (4,4), straight branch only | 1 | 2 | RED, BLUE | 6 | 0 | 1 | 0 | Yes (splitter unrotated -> color decoy) | 6 | 1 | 64 | No | **Yes** | Yes | No | FIRST MAJOR CHALLENGE - a mirror shared by both the splitter's straight and reflected beams; only one orientation satisfies both, and only the straight branch's route ever needs the filter | PENDING |
| 47 | Transmute | 7x7 | RED | 2: GREEN (4,4) straight branch, BLUE (5,3) reflected branch | 1 | 2 | GREEN, BLUE | 5 | 1 | 2 | 0 | Yes (splitter unrotated -> color decoy) | 5 | 1 | 32 | **Yes** | **Yes** | Yes | No | Backward reasoning through a FIXED shared mirror - its single orientation produces two completely different outcomes depending only on arrival direction | PENDING |
| 48 | Waveform | 7x7 | WHITE | 2: RED (6,2) straight branch, BLUE (5,4) reflected branch | 1 | 2 | RED, BLUE | 6 | 0 | 1 | 1 | Yes (early gate -> color decoy) | 6 | 1 | 64 | No | No | Yes | No | Global color network - the first mirror gates the splitter, both filters, and both targets at once; each branch needs its own dedicated filter | PENDING |
| 49 | Vortex | 7x7 | RED | 3: GREEN decoy (1,0), GREEN (6,4) straight branch, BLUE (5,4) reflected branch | 1 | 2 | GREEN, BLUE | 6 | 0 | 2 | 0 | Yes (2: color-invalid route touching both targets still RED; color-valid route blocked right after) | 6 | 1 | 64 | No | No | Yes | No | EXPERT PRE-FINALE - one route is geometrically perfect but wrong color, another produces the objectively correct color but is blocked; only the true route satisfies both | PENDING |
| 50 | Paradox | 7x7 | RED | 4: GREEN decoy (1,0), GREEN (6,1) then BLUE (3,1) chained on the straight branch, GREEN (5,5) on the reflected branch | 1 | 2 | BLUE, GREEN | 7 | 1 | 1 | 1 | Yes (2: hybrid color/geometry route through an unplanned filter crossing; color-valid-then-blocked route) | 7 | 1 | 255 | **Yes** (light, via fixed mirror) | **Yes** (global gate affects both branches) | Yes | **Yes** | STAGE 5 / FILTERS FINALE - chained two-filter recolor (RED->GREEN->BLUE, only the last survives) on one branch, filter-avoidance on the other, an early global gate, two distinct false-route types, and one solver-confirmed inert decoy | PENDING |

Every level: `status = SOLVABLE`, `trivial = false`, zero validator
errors, zero validator warnings, `shortest_solution_count = 1`
throughout. **Zero unintended `possible_decoys`** across all 10 - the
only `possible_decoys` hit anywhere in the stage is Level 50's single
intentional decoy mirror at `(3,3)`, confirmed inert by the solver
exactly as designed (see its `developer_notes`). Every level's
hand-traced solution (against `GridTypes.reflect()`'s actual table,
worked out by hand before running anything) matched the solver's
confirmed `optimal_moves` exactly on the first attempt for all 10
levels - no mismatches, no redesigns needed.

**Filter essentiality confirmed for all 10** (Part 27 of the brief) -
in every level, the solved state is unreachable without the beam
passing through its required filter(s): a WHITE or wrong-color beam
never satisfies a colored-required target (`GridTypes.
target_accepts_color()`), and every required target in Stage 5 has a
non-`WHITE` required color, so every solution genuinely depends on its
filter(s).

**Color-state tracking (Part 23), Levels 44-50** - the authored
color state at each key point, as recorded in each level's own
`developer_notes`:
- **44 Channel:** Emitter RED -> splitter -> straight branch stays RED
  (target RED) / reflected branch -> BLUE filter -> BLUE (target BLUE).
- **45 Conversion:** Emitter RED -> splitter -> straight branch -> GREEN
  filter -> GREEN (target GREEN) / reflected branch -> BLUE filter ->
  BLUE (target BLUE).
- **46 Frequency:** Emitter RED -> splitter -> straight branch -> BLUE
  filter -> BLUE (target BLUE) / reflected branch stays RED through the
  shared mirror (target RED) - the filter belongs to one branch only.
- **47 Transmute:** Emitter RED -> splitter -> straight branch -> GREEN
  filter -> GREEN (target GREEN) / reflected branch -> BLUE filter ->
  BLUE (target BLUE) - both routed through the same fixed shared mirror
  from opposite directions.
- **48 Waveform:** Emitter WHITE -> splitter -> straight branch -> RED
  filter -> RED (target RED) / reflected branch -> BLUE filter -> BLUE
  (target BLUE) - two completely independent filter/target pairs.
- **49 Vortex:** Emitter RED -> splitter -> straight branch -> GREEN
  filter -> GREEN (target GREEN) / reflected branch -> BLUE filter ->
  BLUE (target BLUE); false route touches a GREEN filter incidentally
  but reaches no target.
- **50 Paradox:** Emitter RED -> splitter -> **straight branch -> GREEN
  filter -> GREEN -> BLUE filter -> BLUE** (target BLUE, only the LAST
  filter's color survives) / **reflected branch avoids both of the
  straight branch's filters**, instead -> its own GREEN filter -> GREEN
  (target GREEN).

**Comparison against Stage 4** (see section 17's complexity-check
methodology): Stage 4's `states_explored` ranged 4-64 (median 24);
Stage 5's ranges 8-255 (median 48) - a genuine escalation at both ends,
and Level 50 specifically (255 states) exceeds every prior stage's
finale, including Stage 3's Level 30 (127) and Stage 4's Level 40 (64),
by a wide margin. Stage 4's optimal-move curve was
2,3,4,4,4,5,5,6,6,6; Stage 5's is 3,4,4,5,5,6,5,6,6,7 - starting higher
(no 1-2-move levels at all, unlike every prior stage) and reaching a new
campaign-wide high of 7 at the finale. **Level 47 (5 moves) is lower
than Level 46 (6 moves)** - an intentional exception, not an inverted
curve violation: Level 46 and Level 48-50 all use full cross-branch/
global shared-mirror or shared-gate constructions requiring 6-7 pieces,
while Level 47 deliberately uses a *fixed* (non-rotatable) shared mirror
instead of a rotatable one specifically to isolate and teach backward
reasoning without also demanding a 6th/7th rotation - it is still
harder to reason about than Level 44/45 despite the lower raw count
(this exception is recorded here per section 14's rule).

## 11f. Difficulty Rework Pass 2 — Levels 21-30 (internal folder: stage_03) design table

**Replaced a second time** (see `DECISIONS.md` D65). Pass 1's Levels
21-30 (optimal-move curve 3,2,2,2,2,5,2,2,3,6) were solver-valid but far
too easy for their "Hard+"/"Very Hard" curve position — most were
reachable with 2 taps and no real reasoning. This pass rebuilds all 10
around genuine dependency: cross-branch shared mirrors, filter order
(the same two filters touched in opposite order by two branches),
switch/gate dependency, and hazard-punished (not merely harmless) wrong
forks. All 10 re-verified `status = SOLVABLE`, zero validator errors/
warnings, `shortest_solution_count = 1` throughout, every
`possible_decoys` hit matches an intentional decoy named in that
level's own `developer_notes`, and every solved state re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path (solver-vs-runtime parity, 50/50 PASS). **Manual Difficulty
Feedback is PENDING for all 10.**

| # | Name | Grid | Mechanics | Optimal | Shortest Sols | States | Decoys | Design intent |
|---|---|---|---|---|---|---|---|---|
| 21 | Crossfire | 7x7 | Splitter, hazard | 5 | 1 | 63 | (5,6) | Splitter's reflected branch is a punished decision (hazard, not a miss) while the straight branch needs its own downstream mirror |
| 22 | Detour | 7x7 | Portal, filter, 6-mirror chain | 6 | 1 | 127 | (2,5) | Portal is one link in a long chain - color (fixed by an early filter) and exit direction both have to be tracked to the target |
| 23 | Misdirect | 7x7 | 2 chained fixed mirrors, filter, false-confirmation decoy target | 5 | 1 | 32 | none | Backward reasoning through 2 fixed mirrors; a wrong junction lights a non-required decoy of a different color |
| 24 | Standoff | 8x8 | Splitter, switch/gate, hazard | 6 | 1 | 127 | (0,5) | Splitter's reflected branch's ONLY job is tripping a switch that opens a gate blocking the straight branch |
| 25 | Bottleneck | 8x8 | Splitter, hazard, 2 independent 3-mirror chains | 6 | 1 | 127 | (6,4) | Two required targets, each its own winding chain off a shared splitter - plan both before moving |
| 26 | Labyrinth | 9x9 | Splitter, fixed cross-branch shared mirror, hazard | 7 | 1 | 255 | (3,4) | One fixed mirror hit by both branches from perpendicular directions after two separate 4-mirror approach chains |
| 27 | Impasse | 7x7 | 3-filter order (single beam), false-confirmation decoy target | 8 | 1 | 256 | none | One beam threads RED->GREEN->BLUE - only the LAST filter decides the required color |
| 28 | Gambit | 9x9 | Splitter, 2 independent filters, hazard | 6 | 1 | 127 | (6,3) | Two color-independent target assignments off one splitter; a wrong mirror cascades into the same hazard (emergent) |
| 29 | Stalemate | 7x7 | Splitter, switch/gate, fixed backward-reasoning mirror, hazard | 7 | 1 | 255 | (6,1) | Reflected branch's only job is tripping a switch (via a fixed mirror) that gates the straight branch's relay |
| 30 | Deadlock | 9x9 | Splitter, fixed cross-branch shared mirror, 2 filters, blocker, hazard | 7 | 1 | 255 | (4,6) | Block finale: cross-branch dependency plus independent filter-color assignment together |

**Two real authoring bugs were caught by the solver, not by hand-
tracing** (see `DECISIONS.md` D65): a first draft of Level 25 placed a
required target directly in the same column as an unrelated mirror,
and the solver found a 2-move shortcut through that accidental
collinearity — fixed by moving the two branches onto fully disjoint
rows/columns; a first draft of Level 27 tried to share two filters
between a splitter's two branches for the order lesson, and the
loop-back geometry ran the beam into its own hazard (`UNSOLVABLE`) —
rebuilt as a single non-branching linear path, which cannot self-
collide. Every other level in this block matched its hand-traced intent
exactly on the first solver pass.

## 11g. Difficulty Rework Pass 2 — Levels 31-40 (internal folder: stage_04) design table

**Replaced a second time.** Pass 1's Levels 31-40 (optimal-move curve
2,2,2,2,5,3,4,2,4,4) repeated the same "too easy" problem this pass
exists to fix. Rebuilt with real dependency depth throughout, including
this block's first two multi-emitter puzzles (32, 36, 44's sibling
theme carried into Level 44). All 10 re-verified `status = SOLVABLE`,
zero validator errors/warnings, `shortest_solution_count = 1`
throughout, every `possible_decoys` hit intentional. **Manual
Difficulty Feedback is PENDING for all 10.**

| # | Name | Grid | Mechanics | Optimal | Shortest Sols | States | Decoys | Design intent |
|---|---|---|---|---|---|---|---|---|
| 31 | Ambush | 7x7 | Portal, hazard, 6-mirror single-beam chain | 6 | 1 | 127 | (6,6) | A single beam threads a portal partway through a long chain; a wrong very first turn hits a hazard, not a miss |
| 32 | Gauntlet | 9x9 | 2 emitters, switch/gate, hazard | 7 | 1 | 128 | none | Emitter 1's beam has no target of its own - its only job is tripping the switch that gates emitter 2's longer chain |
| 33 | Feint | 9x9 | Splitter, 2 filters, blocker, hazard | 6 | 1 | 127 | (6,3) | Two disjoint color-independent chains off one splitter; the straight branch's wrong fork hits a blocker, not a miss |
| 34 | Snare | 9x9 | Portal, switch/gate, filter, false-confirmation decoy target | 5 | 1 | 32 | none | The beam crosses its own switch before its own gate (multi-pass resolution); reuses a dedicated return-leg mirror |
| 35 | Ricochet | 9x9 | Splitter, fixed cross-branch shared mirror, filter, blocker, hazard | 7 | 1 | 255 | (4,6) | Block finale: cross-branch dependency plus an independent filter-color test, blocker-guarded false fork |
| 36 | Vertex | 9x9 | 2 emitters, fixed cross-branch shared mirror, hazard | 9 | 1 | 1023 | (7,0) | Two fully independent emitters converge on one fixed shared mirror from perpendicular directions |
| 37 | Nexus | 9x9 | Splitter, portal, fixed cross-branch shared mirror, hazard | 9 | 1 | 1023 | (2,7) | Structurally different routes (portal-shortcut vs. plain relay) reach one shared fixed mirror |
| 38 | Quandary | 9x9 | Splitter, 2-filter chain (order), blocker, hazard | 6 | 1 | 127 | (6,3) | Straight branch's target needs the SECOND filter's color, not the first - last filter wins |
| 39 | Riddle | 9x9 | Splitter, 2 independent fixed-mirror backward-reasoning chains, blocker, hazard | 9 | 1 | 1023 | (7,5) | Two fully disjoint backward-reasoning puzzles off one splitter, solved independently |
| 40 | Crucible | 9x9 | Splitter, portal, 2-filter chain (order), fixed cross-branch shared mirror, blocker, hazard | 11 | 1 | 4095 | (8,0) | Block finale: filter order + portal routing + a shared fixed mirror, all in one puzzle |

**Three real authoring bugs were caught by the solver** (see
`DECISIONS.md` D65): a first draft of Level 31 tried a beam-revisits-
its-own-mirror trick with a decoy placed one cell from the target - the
solver found a 3-move shortcut straight through the decoy into the
target, bypassing the whole chain; a second draft of the same idea
found an entirely different unintended path through the same mirror
cluster that skipped the portal altogether - both fixed by rebuilding
as a single non-revisiting chain. A first draft of Level 34 placed its
return-leg target directly above the same mirror used for the outbound
turn - since that mirror's "wrong" orientation ALSO sends a rightward
beam straight up into it, the solver caught a 0-move trivial solve;
fixed with a dedicated return-leg mirror. A first draft of Level 36
placed a hazard at (2,0), not realizing emitter 2's own unavoidable
first straight shot along row 0 passed directly through it, making the
level permanently `UNSOLVABLE`; a follow-up draft then placed target B
directly on that same unavoidable row-0 shot, letting the solver find
a 4-move shortcut that skipped every mirror - fixed by moving the
hazard off row 0 and routing the shared mirror's output through a
dedicated relay mirror before reaching a target. Level 40's original
draft was missing one mirror in the reflected branch's relay, leaving
it `UNSOLVABLE` until the missing tile was added. Every other level in
this block matched its hand-traced intent exactly on the first solver
pass.

## 11h. Difficulty Rework Pass 2 — Levels 41-45 (internal folder: stage_05) design table

**Replaced a second time.** Pass 1's Levels 41-45 (optimal-move curve
2,4,2,2,3) were the easiest block of the whole reboot despite carrying
the "Expert" label. Rebuilt as the campaign's hardest block before the
unchanged 46-50, bridging naturally into Level 46. **Levels 46-50 are
unchanged - see section 11e, still fully accurate for those five.** All
5 re-verified `status = SOLVABLE`, zero validator errors/warnings,
`shortest_solution_count = 1` throughout. **Manual Difficulty Feedback
is PENDING for all 5.**

| # | Name | Grid | Mechanics | Optimal | Shortest Sols | States | Decoys | Design intent |
|---|---|---|---|---|---|---|---|---|
| 41 | Foresight | 9x9 | Splitter, 2 filters, 2 fixed mirrors, blocker, hazard | 8 | 1 | 256 | none | Two independent color-coded backward-reasoning chains off one splitter, each ending at its own fixed mirror |
| 42 | Hindsight | 8x8 | Portal, filter, fixed mirror, 9-mirror single-beam chain, hazard | 9 | 1 | 1023 | (0,0) | One deep linear chain, no splitter - deliberately a different shape from its neighbors |
| 43 | Tangent | 9x9 | Splitter, portal (mandatory, not a shortcut), filter, blocker, hazard | 10 | 1 | 2047 | (0,8) | The straight branch's target sits on the far side of a gap only the portal bridges |
| 44 | Overwatch | 9x9 | 2 emitters, switch/gate, hazard | 7 | 1 | 128 | none | Emitter 2's beam earns a 3-mirror rotation payoff beyond the gate - opening it isn't the finish line |
| 45 | Threshold | 10x10 | Splitter, portal, 2-filter chain (order), fixed cross-branch shared mirror, blocker, hazard | 11 | 1 | 4095 | (0,0) | Pre-46-50 bridge finale: portal routing + filter order converge on one shared fixed mirror |

Every level in this block matched its hand-traced intent exactly on the
first solver pass — no redesigns needed for this block specifically
(all authoring mistakes this pass were caught and fixed in blocks 1 and
2 above, whose lessons — check every target/hazard against every
beam's unmodified straight path, never reuse a row/column between two
branches beyond an intended shared tile — were applied from the start
here).

**Comparison across Pass 2's three blocks** (Levels 21-30, 31-40,
41-45): optimal-move curve 5,6,5,6,6,7,8,6,7,7 / 6,7,6,5,7,9,9,6,9,11 /
8,9,10,7,11 — a real escalation from Pass 1's 3,2,2,2,2,5,2,2,3,6 /
2,2,2,2,5,3,4,2,4,4 / 2,4,2,2,3. `states_explored` ranges 32-256 (block
1), 32-4095 (block 2, peaking at Level 40's 11-move finale), 128-4095
(block 3). **Old Level 50 (255 states, kept unchanged) is no longer the
single highest state count in the 1-50 curve** — Levels 36, 37, 39
(1023 each), 40 (4095), and 45 (4095) now exceed it, which is
consistent with Pass 2's explicit brief to push 36-45 close to or past
Level 50's benchmark feel; Level 50 remains the reference for the
*style* of puzzle (whole-board reasoning, no clutter), not a hard
numeric ceiling. See `DECISIONS.md` D65 for the full accounting,
including every rejected first draft and why it was rejected.

## 11i. Campaign Levels 51-60 (internal folder: stage_06) design table

The first post-reboot EXPANSION of the campaign past 50 levels (see
`DECISIONS.md` D66). Levels 1-50 are entirely untouched by this pass.
**No mechanic-teaching reset** — Level 51 continues directly from the
Levels 46-50 difficulty region; every mechanic Tutorial teaches is
available immediately. All 10 re-verified `status = SOLVABLE`, zero
validator errors/warnings, `shortest_solution_count = 1` throughout,
every `possible_decoys` hit matches an intentional decoy named in that
level's own `developer_notes`, and every solved state re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path (solver-vs-runtime parity, 60/60 PASS). **Manual Difficulty
Feedback is PENDING for all 10.**

| # | Name | Grid | Mechanics | Optimal | Shortest Sols | States | Decoys | Backward? | Cross-Branch? | Delayed? | Multi-Emitter? | Design intent |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 51 | Interlock | 8x8 | Splitter, 2 switch/gate pairs (mutual) | 10 | 1 | 1024 | none | No | Yes (mutual) | No | No | Each branch's own switch is what opens the OTHER branch's gate - neither solvable in isolation |
| 52 | Currents | 8x7 | Portal, 2 filters, 1 fixed mirror | 8 | 1 | 511 | (7,6) | Light | No | Yes | No | Beam is recolored twice across a portal jump - only the color set AFTER the portal survives |
| 53 | Shared Line | 7x7 | 2 emitters, shared filter, switch/gate | 7 | 1 | 128 | none | No | No | No | Yes | Two emitters both pass through ONE shared filter from perpendicular directions to two separate targets |
| 54 | Dual Transit | 9x9 | Splitter, 2 portal pairs, 2 filters, fixed cross-branch shared mirror, blocker | 11 | 1 | 4095 | (7,6) | No | Yes | No | No | Two structurally unrelated portal routes converge on one shared fixed mirror |
| 55 | Sequence Lock | 9x9 | Splitter, 2-filter order, switch/gate, fixed cross-branch shared mirror, blocker | 11 | 1 | 4095 | (7,1) | No | Yes | No | No | The straight branch's filter-order chain ALSO trips the switch gating the entire reflected branch |
| 56 | Shared Transit | 9x9 | 2 emitters, 2 portal pairs, switch/gate, hazard | 8 | 1 | 511 | (8,8) | No | No | No | Yes | Emitter 2 gated behind a switch tripped by emitter 1's beam AFTER its own portal exit |
| 57 | Long Division | 10x9 | 2 filters, 2 fixed mirrors, 9-mirror single chain | 9 | 1 | 1023 | (1,7) | Yes (strong) | No | No | No | One linear beam, no splitter - target color can only be reasoned out backward through both fixed mirrors |
| 58 | Delayed Fault | 9x9 | Splitter, 1 filter, fixed cross-branch shared mirror, 2 hazards | 11 | 1 | 4095 | (8,2) | No | Yes | Yes | No | Wrong straight-branch mirror looks harmless for two full cells before the hazard reveals it |
| 59 | Near Convergence | 10x10 | 2 emitters, 2 portal pairs, switch/gate, filter, hazard | 11 | 1 | 4095 | (9,9) | No | No | No | Yes | Emitter 2 gated behind emitter 1's portal+switch; emitter 2's own portal+filter chain reasoned independently |
| 60 | Threshold of Reason | 10x10 | Splitter, portal, switch/gate, 3 filters (2-filter order on one branch), blocker, hazard | 14 | 1 | 32767 | (9,0) | Light | Yes (global) | No | No | MAJOR MILESTONE: reflected branch's entire filter-order puzzle is moot until the straight branch's portal+switch opens its gate |

**Rejected drafts (2 full redesigns, see `DECISIONS.md` D66 for the
full accounting — this is not a "zero redesigns" report):**
- **Level 56 draft 1** shared ONE portal pair between both emitters
  (each entering the opposite end). This created a combinatorially
  pathological search space — solver validation took minutes instead
  of milliseconds on a 7-piece level, a strong signal the interaction
  was also too confusing for a player to reason about. Rejected and
  rebuilt with two separate portal pairs tied together by a switch/
  gate instead.
- **Level 58 draft 1** left a wrong branch to run several cells with no
  immediate consequence at all (no hazard, no blocker) — two adjacent
  cells assigned to different branches turned out to connect into one
  continuous accidental path when both were left in their "wrong"
  state, and the solver found a 4-move shortcut reaching BOTH targets
  through it. Rejected and rebuilt with a real (if delayed, two-cell)
  hazard ending the wrong path and fully disjoint branch zones.

**One minor correction, not a redesign:** Level 51's mirror at (6,5)
was authored as an intentional decoy, but the solver found it
load-bearing — the beam continues past target B and, if that mirror is
left unflipped, runs into the SAME hazard that punishes the wrong
splitter orientation. The tiles were correct; only the `developer_notes`
label was wrong, corrected to describe it honestly as post-target
hazard avoidance (see `CAMPAIGN_DESIGN.md` section 8's standing warning
about tracing a beam's full path past an activated target — this is
the second time in this project a level design has hit exactly this
trap, not a new discovery).

**Design method:** every level was built from one of two solver-
verified-safe templates carried over from Difficulty Rework Pass 2 — a
single non-branching linear chain, or a splitter/multi-emitter pair
whose branches occupy fully disjoint rows/columns except at one
deliberately shared tile (a fixed mirror, a filter, or a switch/gate
pair). The standing lesson from Pass 2 (check every target/hazard
against every beam's fully unmodified straight-line path) was applied
from the start and caught zero NEW instances in this block beyond the
two rejections above — both of which came from experimenting with a
riskier pattern (shared portal, and consequence-free wrong branches)
outside those two templates.

## 11j. Campaign Levels 61-70 (internal folder: stage_07) design table

The second post-reboot expansion past 60 levels (see `DECISIONS.md`
D67). Levels 1-60 are entirely untouched by this pass. **No mechanic-
teaching reset** — Level 61 continues directly from Level 60's
difficulty. All 10 re-verified `status = SOLVABLE`, zero validator
errors/warnings, `shortest_solution_count = 1` throughout, every
`possible_decoys` hit matches an intentional decoy named in that
level's own `developer_notes`, and every solved state re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path (solver-vs-runtime parity, 70/70 PASS). **Manual Difficulty
Feedback is PENDING for all 10.**

| # | Name | Grid | Mechanics | Optimal | Shortest Sols | States | Decoys | Backward? | Cross-Branch? | Delayed? | Multi-Emitter? | Shared Resource? | Design intent |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 61 | Peripheral | 8x8 | Splitter, 2 filters, blocker | 10 | 1 | 2047 | (7,7) | No | No | No | No | No | The visually closer straight branch is a 2-move afterthought; the real puzzle is the longer reflected branch |
| 62 | Longcut | 8x8 | Splitter, hazard | 10 | 1 | 2047 | (7,0) | No | No | No | No | No | The reflected branch's correct route is deliberately the LONGER of two plausible continuations at one mirror |
| 63 | Invalidation | 9x9 | Splitter, portal, switch/gate, color decoy | 10 | 1 | 2047 | (8,0) | No | Yes | No | No | Yes (gate) | Wrong turn reaches a plausible wrong-color decoy target; the real route needs a genuinely closed gate |
| 64 | Twin Anchor | 9x9 | 2 emitters, fixed cross-branch shared mirror | 10 | 1 | 2047 | (7,8) | Yes (dual) | Yes | No | Yes | Yes (mirror) | Two emitters converge on one fixed mirror from perpendicular directions - backward reasoning for both at once |
| 65 | Convergence Point | 9x9 | Splitter, switch/gate, target continuation | 12 | 1 | 8191 | (8,0) | No | Yes | No | No | Yes (gate) | MASTER-ENTRY CHECKPOINT: the beam continues past target A and trips the switch gating the entire reflected branch |
| 66 | Portal Trap | 9x9 | Portal, 2 hazards, 7-mirror single chain | 7 | 1 | 128 | none | No | No | No | No | No | One deep linear chain - the post-portal mirror's "shorter-looking" continuation runs into a hazard |
| 67 | Chain Reaction | 9x9 | Splitter, 4 filters (2-per-branch order), fixed cross-branch shared mirror, blocker | 11 | 1 | 4095 | (8,0) | No | Yes | No | No | Yes (mirror) | Both branches run independent 2-filter-order chains, converging on one shared mirror that never recolors either |
| 68 | Twin Corridor | 9x9 | 2 emitters, 1 shared gate (2 switches) | 9 | 1 | 2036 | (8,8) | No | No | No | Yes | Yes (gate) | Two emitters cross the SAME physical gate cell from perpendicular directions; EITHER switch opens it for both |
| 69 | Color Conflict | 9x9 | 2 emitters, switch/gate, 4 filters (2-per-emitter order) | 12 | 1 | 8191 | (8,0) | No | No | No | Yes | Yes (gate) | Emitter 2 gated behind emitter 1's switch; each emitter then runs its own independent filter-order puzzle |
| 70 | Grand Convergence | 10x10 | 2 emitters, portal, 2 switch/gate pairs (two-stage relay), 4 filters, blocker, hazard | 11 | 1 | 4095 | (9,0) | No | No | No | Yes | Yes (2 gates) | MAJOR MILESTONE: a genuine two-stage relay - emitter 1's switch opens emitter 2's early gate, and only THEN can emitter 2's own switch open emitter 1's later gate |

**One full draft rejection, not zero** (see `DECISIONS.md` D67): Level
63's first draft used an always-open "decoy" gate positioned where the
reflected branch's OWN correct path also passed through it, plus a
"decoy" mirror that turned out to connect the reflected branch's chain
straight into the straight branch's own target — the solver found a
5-move shortcut bypassing the portal, the real gate, and the switch
entirely. Rebuilt with fully disjoint branch zones and no always-open
gate (the "invalidation" identity survives via a plain ungated wrong
turn instead).

**One notes correction, not a design flaw:** Level 68's original hand-
trace mis-applied the reflect table to one mirror, believing it needed
a flip that the solver correctly showed was unnecessary — the mirror
was already authored in its correct orientation (a genuine zero-move
load-bearing piece, not a decoy: toggling it still breaks the
solution). `optimal_moves` corrected from a mis-counted 10 to the
solver-confirmed 9, and the notes updated to explain the distinction
between "unflipped" and "decoy" honestly rather than papering over it.

**Design method:** every level reused the two solver-verified-safe
templates from Difficulty Rework Pass 2 (a single non-branching linear
chain, or a splitter/multi-emitter pair on fully disjoint rows/columns
except one shared tile), plus one new structural pattern proven safe
here for the first time: a single physical GATE cell crossed by two
emitters from perpendicular directions (Level 68), and a two-stage
switch/gate RELAY between two emitters where each unlocks the other in
sequence (Level 70) — both resolved correctly by
`simulate_until_stable()`'s existing multi-pass semantics with zero
new engine code.

## 11k. Campaign Levels 71-80 (internal folder: stage_08) design table

The third post-reboot expansion past 70 levels — MASTER/MASTER+/EXTREME
tier (see `DECISIONS.md` D68). Levels 1-70 are entirely untouched by
this pass. **No mechanic-teaching reset** — Level 71 continues directly
from Level 70's difficulty, and no level in this block is an easier
"stage-opener." All 10 re-verified `status = SOLVABLE`, zero validator
errors/warnings, `shortest_solution_count = 1` throughout, every
`possible_decoys` hit matches an intentional decoy named in that
level's own `developer_notes`, and every solved state re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path (solver-vs-runtime parity, 80/80 PASS across the whole campaign).
**Levels 1-50 are user-tested and reported good (treat as a manually-
positive baseline). Levels 51-70 remain automated-validated only —
manual QA is still pending for 51-70, NOT approved. Manual Difficulty
Feedback is PENDING for all of 71-80.**

| # | Name | Grid | Emitters | Mirrors | Splitters | Filters | Portals | Switches | Gates | Hazards | Blockers | Targets | Colors | Decoys | Optimal | Shortest Sols | States | Backward? | Cross-Branch? | Delayed? | Multi-Emitter? | Shared Resource? | Relay? | Design intent | Rejected drafts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 71 | Deliberate Detour | 10x10 | 1 | 10 (1 fixed) | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | White, Green | 1 | 11 | 1 | 4095 | No | Yes | No | No | Yes (switch) | No | MASTER ENTRY: splitter + mandatory portal on straight branch feeding a switch that gates the reflected branch, both branches converging on one fixed shared mirror | 0 |
| 72 | Locked Corridor | 9x9 | 2 | 8 | 0 | 3 | 0 | 2 | 1 | 1 | 0 | 2 | Blue, Green | 1 | 9 | 1 | 2036 | No | No | No | Yes | Yes (gate) | No | Two emitters cross ONE shared physical gate cell from perpendicular directions with independent 2-filter-order chains on each side | 1 (see below) |
| 73 | Locked Splitter | 10x10 | 1 | 9 | 1 | 4 | 0 | 2 | 2 | 1 | 1 | 2 | Blue, Red | 1 | 11 | 1 | 4095 | No | Yes | No | No | Yes (mutual gates) | No | A single splitter's two branches gate EACH OTHER, deepened with a 2-filter-order chain on each branch | 0 |
| 74 | Twin Portals | 10x10 | 2 | 6 | 0 | 2 | 2 | 1 | 1 | 0 | 0 | 2 | Green, Red | 1 | 8 | 1 | 511 | No | No | Yes | Yes | Yes (switch) | No | Emitter 1's beam continues PAST its own target (target-continuation delayed consequence) to trip a switch gating emitter 2's entire route | 0 |
| 75 | Convergence Reaction | 9x10 | 1 | 12 (1 fixed) | 1 | 4 | 0 | 1 | 1 | 1 | 1 | 2 | Red, Blue, Green | 1 | 13 | 1 | 16383 | No | Yes | Yes | No | Yes (mirror + gate) | No | MAJOR MID-BLOCK CHECKPOINT: both splitter branches run independent 2-filter chains to one shared mirror, AND the straight branch's post-target continuation gates the reflected branch's final approach | 0 |
| 76 | Reverse Relay | 10x10 | 2 | 12 | 0 | 4 | 2 | 2 | 2 | 1 | 1 | 2 | Blue, Blue | 1 | 11 | 1 | 4095 | Yes | No | No | Yes | Yes (2 gates) | Yes | Second deliberate use of Level 70's two-stage relay skeleton, recolored so both targets need BLUE via different filter-order paths — forces backward color reasoning independent of the gate order | 0 |
| 77 | Distant Splitter | 10x10 | 1 | 9 | 1 | 4 | 2 | 2 | 2 | 1 | 1 | 2 | Blue, Red | 1 | 12 | 1 | 8191 | No | Yes | No | No | Yes (mutual gates) | No | Level 73's mutual-gate core extended so the straight branch's delivery jumps through a portal into a totally separate board region before reaching its target | 0 |
| 78 | Distant Corridor | 10x10 | 2 | 11 | 0 | 3 | 2 | 2 | 1 | 1 | 0 | 2 | Blue, Green | 1 | 12 | 1 | 16369 | No | No | No | Yes | Yes (gate) | No | Level 72's shared-gate core extended so emitter 1's delivery jumps through a portal into an expanded board's opposite corner and bounces through 3 more mirrors | 0 |
| 79 | Silent Third | 10x10 | 3 | 11 | 1 | 4 | 2 | 3 | 3 | 1 | 1 | 2 | Blue, Red | 2 | 13 | 1 | 32752 | No | Yes | No | Yes | Yes (mutual gates + gate) | No | EXTREME ENTRY: Level 77's mutual-gate-plus-portal core, plus a completely separate THIRD emitter whose own short chain opens one more gate on target A's final approach | 0 |
| 80 | Full Convergence | 10x10 | 3 | 13 | 1 | 4 | 2 | 4 | 6 | 1 | 1 | 2 | Blue, Red | 2 | 14 | 1 | 65519 | No | Yes | Yes | Yes | Yes (mutual gates + 2 more gates) | No | MAJOR MILESTONE: target A now requires FOUR independently-opened gates to align at once (mutual splitter dependency, portal jump, third emitter, and the reflected branch's own post-target delayed consequence), and the "independent" third emitter is itself re-coupled to the straight branch's own switch, proving the whole board is one system | 0 |

**One draft rejection, not zero** (see `DECISIONS.md` D68): Level 72's
first draft was hand-derived from scratch (two emitters through a
shared gate cell with filters) and came back **UNSOLVABLE** — a
transcription error mixed up two different mirror positions
(`(5,2)`/`(4,2)`/`(4,3)`/`(5,3)`/`(5,4)`/`(4,4)`/`(4,7)`), confirmed via
a temporary debug script (`debug_level72.gd`) showing the beam exiting
the grid without reaching target B. Rebuilt by copying Level 68's
already-solver-confirmed tile geometry verbatim (same mirror positions
and orientations, same switch/gate) and adding 3 filters only at cells
independently confirmed to be pure single-beam transit points for
exactly one beam each — the rebuild matched Level 68's own numbers
exactly (9 moves, 2036 states, decoy `(8,8)`), proving zero
interference. This "extend a validated design via filters-on-safe-
transit-cells" technique was then used proactively (not reactively) to
build Level 75 (on Level 67's geometry), Level 76 (a recolor of Level
70's exact relay skeleton), Level 77 (Level 73's core plus a portal
tail), Level 78 (Level 72's core plus a portal tail), Level 79 (Level
77's core plus a third emitter), and Level 80 (Level 79's core plus a
fourth gate and a cross-coupling of the third emitter into the straight
branch's own switch) — each verified to match its predecessor's
untouched-region numbers exactly before any new mechanic was layered
on top.

**Solver ceiling note:** Level 80 has 16 independently-rotatable pieces
(1 splitter + 14 mirrors + 1 decoy mirror), giving a full state space of
2^16 = 65536 — `LevelSolver.analyze()` explored 65519 of them and
returned a definitive `SOLVABLE` (not `UNKNOWN`), but this is
deliberately at the practical ceiling before `DEFAULT_MAX_STATES`
would need raising. **Do not add further rotatable pieces to Level 80** —
see `DECISIONS.md` D68 and Part 23 of the brief this block was built
under ("redesign rather than raise limits").

**Design method:** every level reused the solver-verified-safe templates
from Difficulty Rework Pass 2 and the 61-70 pass (a single non-branching
linear chain; a splitter/multi-emitter pair on fully disjoint rows/
columns except one shared tile; a single physical gate cell crossed by
two emitters from perpendicular directions; a two-stage switch/gate
relay between two emitters), plus the "extend a validated design without
touching its proven geometry" technique developed in this pass (adding
filters at confirmed transit cells, or extending a branch's tail through
a portal jump into an unused board region, always re-validating against
the base level's own numbers first).

## 11l. Campaign Levels 81-90 (internal folder: stage_09) design table

The fourth post-reboot expansion past 80 levels — EXTREME/EXTREME+ tier
(see `DECISIONS.md` D69). Levels 1-80 are entirely untouched by this
pass. **No mechanic-teaching reset** — Level 81 continues directly from
Level 80's difficulty. All 10 re-verified `status = SOLVABLE`, zero
validator errors/warnings, `shortest_solution_count = 1` throughout,
every `possible_decoys` hit matches an intentional decoy named in that
level's own `developer_notes`, and every solved state re-confirmed
reachable through the real `GridManager._on_orientable_tile_clicked()`
path (solver-vs-runtime parity, 90/90 PASS across the whole campaign).
**Levels 1-50 remain the user-tested, manually-positive baseline.
Levels 51-90 remain automated-validated only — manual QA is still
pending for 51-90, NOT approved. Manual Difficulty Feedback is PENDING
for all of 81-90.**

**New mechanic introduced this pass: the three-stage relay.** Levels
70/76/84 each used a two-stage switch/gate relay between two emitters.
Level 87 is the first to extend this to THREE emitters in a genuine
forward chain (emitter 1's unconditional switch opens emitter 2's early
gate; emitter 2's switch opens emitter 3's early gate; emitter 3's
switch opens the final gate on emitter 1's own tail), resolved over 4
`simulate_until_stable()` passes with zero new engine code. Levels
88-90 build on this same three-stage core.

| # | Name | Grid | Emitters | Mirrors | Filters | Portals | Switches | Gates | Hazards | Blockers | Targets | Colors | Decoys | Optimal | Shortest Sols | States | Backward? | Cross-Branch? | Delayed? | Multi-Emitter? | Shared Resource? | Relay? | Three-Way? | Target Continuation? | Design intent | Rejected drafts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 81 | Third Signal | 10x10 | 3 | 9 | 0 | 0 | 2 | 1 | 1 | 0 | 2 | White, White | 1 | 12 | 1 | 8191 | No | No | Yes | Yes | Yes (2 gates converge) | No | No | Yes | Emitter 2's route needs BOTH emitter 1's delayed post-target continuation AND a completely separate third emitter's gate | 0 |
| 82 | Crossed Corridors | 10x10 | 3 | 7 | 5 | 0 | 2 | 3 | 1 | 0 | 2 | Blue, Green | 1 | 11 | 1 | 4095 | No | No | No | Yes | Yes (transitive 3-way) | No | Yes | No | Two independent 3-filter-order chains converge on a mutual-looking gate PLUS a third, separate emitter gating emitter 1's own mid-chain, making emitter 2's dependency on emitter 1 transitively also a dependency on emitter 3 | 0 |
| 83 | Silent Detour | 10x10 | 2 | 11 | 1 | 2 | 2 | 3 | 1 | 1 | 2 | White, Green | 2 | 11 | 1 | 8178 | No | Yes | No | Yes | Yes (mutual gates + gate) | No | No | No | Level 71's splitter/portal/shared-mirror core extended with a third emitter gating the straight branch's portal corridor before it can even reach the switch that opens the reflected branch's gate | 0 |
| 84 | Distant Relay | 10x10 | 2 | 13 | 4 | 2 | 2 | 2 | 1 | 1 | 2 | Blue, Blue | 1 | 12 | 1 | 8191 | Yes | No | No | Yes | Yes (2 gates) | Yes | No | No | Level 76's two-stage relay extended with a second portal jump on emitter 1's final approach into a distant corner of the board | 0 |
| 85 | Convergence Threshold | 9x10 | 4 | 12 (1 fixed) | 4 | 0 | 2 | 3 | 1 | 2 | 2 | Red, Blue, Green | 1 | 14 | 1 | 32767 | No | Yes | Yes | Yes | Yes (mirror + 2 gates) | No | Yes | Yes | MAJOR CHECKPOINT: Level 75's splitter/shared-mirror/target-continuation core, PLUS the reflected branch's own early path gated by a completely separate third emitter - the reflected branch's single target now depends on three independent sources at once | 0 |
| 86 | Reciprocal Corridor | 10x10 | 2 | 11 | 3 | 2 | 3 | 2 | 1 | 1 | 2 | Blue, Green | 1 | 12 | 1 | 16369 | No | No | Yes | Yes | Yes (gate) | No | No | Yes | Level 78's shared-gate/portal core extended with a SECOND portal on emitter 1's delivery, ending at a gate only emitter 2's own post-target delayed consequence can open - a bidirectional dependency between the two emitters | 0 |
| 87 | Triple Relay | 10x10 | 3 | 14 | 1 | 0 | 3 | 3 | 1 | 0 | 2 | Blue, Green | 1 | 10 | 1 | 2047 | No | No | No | Yes | Yes (3-stage chain) | Yes (3-stage, first ever) | Yes | No | THE FIRST three-stage relay in the campaign: emitter 1 -> gates emitter 2 -> gates emitter 3 -> gates emitter 1's own tail, a true forward chain resolved over 4 simulation passes | 1 (see below) |
| 88 | Distant Triple Relay | 10x10 | 3 | 14 | 2 | 4 | 3 | 3 | 1 | 0 | 2 | Blue, Green | 1 | 12 | 1 | 8191 | No | No | No | Yes | Yes (3-stage chain) | Yes (3-stage) | Yes | No | Level 87's three-stage relay extended so BOTH emitter 1's and emitter 2's deliveries jump through their own separate portals into distant corners before reaching their targets | 0 |
| 89 | Fourfold Relay | 10x10 | 4 | 16 | 2 | 4 | 4 | 5 | 1 | 2 | 2 | Blue, Green | 1 | 13 | 1 | 16383 | No | No | No | Yes | Yes (3-stage + convergence) | Yes (3-stage) | Yes | No | Level 88's three-stage relay PLUS a fourth, independent emitter gating emitter 2's very first step - a convergence layered onto the relay without risking a circular deadlock | 1 (see below) |
| 90 | Full Circuit | 10x10 | 5 | 16 | 2 | 4 | 5 | 7 | 1 | 2 | 2 | Blue, Green | 1 | 13 | 1 | 16383 | No | No | No | Yes | Yes (3-stage + 2 convergences) | Yes (3-stage) | Yes | No | MAJOR CAMPAIGN MILESTONE: Level 89's structure PLUS a fifth independent emitter gating emitter 1's own first step, giving BOTH ends of the three-stage relay a symmetric independent-source convergence - five emitters, two portals, a three-stage relay, and two converging gates, all resolved with zero new engine code | 0 |

**One full draft rejection** (see `DECISIONS.md` D69 for the design
table this applies to): **Level 87 draft 1** placed emitter 1's and
emitter 2's mirror chains in the SAME column (column 2), and when both
were left at their unflipped default orientation, emitter 2's beam bent
directly into emitter 1's own downstream chain and reached both targets
in 5 moves without the three-stage relay ever needing to resolve — this
is the same root-cause class as every prior collinearity lesson
(D65-D68), but specifically triggered by an UNFLIPPED (not flipped)
combination, which is easy to miss when only hand-tracing the intended
solution path. Rebuilt with every emitter's ENTIRE path (not just its
target) confirmed to occupy disjoint rows/columns from both others.

**One mid-design correction caught immediately by the solver, not a
design flaw:** Level 89's first version placed target A one row off
from where the beam actually arrives after two new forced bends (row 3
instead of row 2) — the solver correctly reported `UNSOLVABLE`,
diagnosed with a temporary debug script tracing the exact beam
segments, and fixed by moving the target to the row the beam actually
occupies.

**Circular-dependency safety check (new for this pass):** every
convergence added in Levels 81-90 was checked by hand to confirm it
never creates a true simulation cycle — a gate may only depend on a
switch that is reachable *before* anything the gate itself blocks
becomes necessary. Level 89's fourth emitter and Level 90's fifth
emitter were deliberately kept fully independent (gating only the START
of a branch, never anything downstream of their own switch) specifically
to avoid the deadlock that would result from, for example, gating a
third emitter's approach behind the very relay chain that third emitter
itself helps complete.

**Design method:** every level reused the solver-verified-safe templates
from prior passes (a single non-branching linear chain; a splitter/
multi-emitter pair on fully disjoint rows/columns except one shared
tile; a single physical gate cell crossed by two emitters from
perpendicular directions; a two-stage switch/gate relay), the "extend a
validated design without touching its proven geometry" technique
(portal jumps into confirmed-unused board regions, filters at confirmed
transit cells), and one genuinely new template: the three-stage relay
(Levels 87-90), always verified to resolve as a forward chain, never a
cycle.

## 11m. Campaign Levels 91-100 (internal folder: stage_10) design table — FINAL CAMPAIGN BLOCK

The fifth and final post-reboot expansion, completing the originally-
planned 100-level campaign structure (see `DECISIONS.md` D70). Levels
1-90 are entirely untouched by this pass. **No mechanic-teaching
reset, no soft difficulty reset** — Level 91 continues directly from
Level 90's difficulty. All 10 re-verified `status = SOLVABLE`, zero
validator errors (Level 100 carries one non-blocking "44→42 tiles, a
lot" warning, discussed below), `shortest_solution_count = 1`
throughout, every `possible_decoys` hit matches an intentional decoy
named in that level's own `developer_notes`, and every solved state
re-confirmed reachable through the real
`GridManager._on_orientable_tile_clicked()` path (solver-vs-runtime
parity, 100/100 PASS across the whole campaign). **Levels 1-50 remain
the user-tested, manually-positive baseline. Levels 51-100 remain
automated-validated only — manual QA is still pending for 51-100, NOT
approved. Manual Difficulty Feedback is PENDING for all of 91-100.**

| # | Name | Grid | Emitters | Mirrors | Fixed Mirrors | Filters | Portals | Switches | Gates | Hazards | Blockers | Targets | Colors | Decoys | Optimal | Shortest Sols | States | Backward? | Delayed? | Multi-Emitter? | Shared Resource? | Relay? | Three-Way? | Target Continuation? | Near-Solution? | Design intent | Rejected drafts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 91 | Inferred Convergence | 9x10 | 1 (+splitter) | 8 | 1 | 4 | 0 | 1 | 1 | 1 | 1 | 2 | Green, Red | 1 | 13 | 1 | 16383 | Yes | No | No | Yes (fixed mirror + gate) | No | No | No | No | Backward reasoning through a non-rotatable fixed mirror at the convergence point of two independent 2-filter-order branches | 0 |
| 92 | Delayed Verdict | 10x10 | 1 (+splitter) | 12 | 0 | 4 | 1 | 3 | 3 | 1 | 1 | 2 | Blue, Red | 1 | 13 | 1 | 16383 | No | Yes | No | Yes (mutual gates + gate) | No | No | Yes | Yes | A mutual-gate splitter core plus a target-continuation switch that gates the OTHER branch - neither target lights up from the mutual gate alone | 0 |
| 93 | Pre-Split Signal | 10x10 | 1 (+splitter) | 9 | 0 | 3 | 0 | 2 | 2 | 1 | 1 | 2 | Green, Red | 1 | 11 | 1 | 4095 | No | No | No | Yes (mutual gates) | No | No | No | No | A filter placed BEFORE the splitter recolors both branches, but only matters for whichever branch has no downstream filter of its own to override it | 0 |
| 94 | Traced Colors | 10x10 | 2 (+splitter) | 11 | 0 | 5 | 1 | 2 | 3 | 1 | 1 | 2 | Red, Blue | 2 | 11 | 1 | 8178 | No | No | Yes | Yes (transitive relay + gate) | No | No | No | No | Filters added to each branch at confirmed pure-transit cells of Level 83's proven geometry, deepening color-order reasoning without touching the existing gate/relay structure | 0 |
| 95 | Final Threshold | 9x10 | 2 (+splitter) | 10 | 1 | 5 | 1 | 2 | 2 | 1 | 1 | 2 | Green, Green | 1 | 15 | 1 | 65535 | No | Yes | Yes | Yes (fixed mirror + gate x2) | No | No | Yes | No | MAJOR CHECKPOINT ("I am in the final exam now"): straight branch's delivery gains a THIRD filter via a portal jump into a distant corner, on top of Level 85's fixed-mirror/gate/third-emitter core | 0 |
| 96 | Chain of Custody | 10x10 | 3 | 12 | 0 | 2 | 0 | 3 | 3 | 1 | 1 | 2 | Blue, Green | 1 | 12 | 1 | 8191 | No | No | Yes | Yes (3-stage chain) | Yes (3-stage) | Yes | Yes | No | A genuine shared-state chain: emitter B's own target is itself just a waypoint - its beam continues past it to change emitter C's conditions | 0 |
| 97 | Triple Verdict | 10x10 | 2 (+splitter) | 12 | 0 | 4 | 1 | 3 | 4 | 1 | 1 | 3 | Blue, Red, White | 1 | 14 | 1 | 32767 | No | Yes | Yes | Yes (global late gate) | No | Yes | Yes | No | GLOBAL DEPENDENCY: three independent-looking beam sources all ultimately depend on the exact same one late gate, opened only by the straight branch's full delivery | 0 |
| 98 | Triple Inference | 9x10 | 2 (+splitter) | 9 | 1 | 5 | 0 | 2 | 2 | 1 | 1 | 2 | Green, Red | 1 | 14 | 1 | 32767 | Yes | No | No | Yes (fixed mirror + 2 gates) | No | No | No | No | Backward reasoning + color/order logic: a 5-link backward chain (target color <- fixed mirror <- filter order <- gate <- third emitter) | 0 |
| 99 | Penultimate Verdict | 10x10 | 3 (+splitter) | 12 | 0 | 4 | 1 | 4 | 6 | 1 | 1 | 3 | Blue, Red, White | 1 | 14 | 1 | 32767 | No | Yes | Yes | Yes (global late gate x2) | No | Yes | Yes | Yes | PENULTIMATE CHALLENGE: two of three targets share dependency on one late gate, making it easy to believe the board is understood while a fourth, unrelated-looking emitter gates the third branch's very first step | 0 |
| 100 | Culmination | 10x10 | 5 | 13 | 1 | 2 | 4 | 5 | 7 | 1 | 2 | 2 | Blue, Green | 1 | 13 | 1 | 16383 | Yes | No | Yes | Yes (3-stage + symmetric convergence) | Yes (3-stage) | Yes | No | No | THE DEFINITIVE FINAL PUZZLE: Level 90's three-stage relay + double-portal + symmetric convergence, plus one non-rotatable fixed mirror for genuine backward reasoning - every mechanic in the campaign present at once, nothing decorative | 1 (see below) |

**One full draft rejection** (see `DECISIONS.md` D70 for the full
writeup): **Level 100 draft 1** additionally gated emitter 4's approach
behind emitter 1's own post-target continuation, intending one more
"everything is connected" thread. The solver immediately reported
`UNSOLVABLE`. Diagnosed with a debug script that traced the exact beam
segments and confirmed a genuine circular deadlock: emitter 1 needs
emitter 3's gate to finish; emitter 3 needs emitter 2's gate to start;
emitter 2 needs emitter 4's gate to start; emitter 4 would have needed
emitter 1's own completion to start — a true cycle, not just an
apparent one, exactly the failure mode `DECISIONS.md` D69 warned future
sessions to check for. Removed rather than reworked, restoring emitter
4 to its Level 89/90 role as a fully independent convergence source.
**This is the standing proof that the D69 circular-dependency check is
not academic** — even the author of that lesson, one milestone later,
almost repeated it, and only the solver's immediate, unambiguous
`UNSOLVABLE` report caught it before the mistake could ship.

**Level 100's validator warning is non-blocking and expected, not
overlooked:** at 42 tiles, `LevelValidator` flags "a lot - consider
whether it could be simplified." This is a real tradeoff, weighed
deliberately: Level 100 combines five emitters, a three-stage relay,
double portals, symmetric converging gates, one fixed mirror, and every
other mechanic the campaign teaches, in one coherent system with zero
decorative pieces (every tile is load-bearing or an explicitly-named,
solver-confirmed decoy). The brief's own "elegant, not overloaded"
instruction is honored by keeping `optimal_moves` (13) and grid size
(10x10) IDENTICAL to Level 90's own footprint rather than growing
either — the tile count is a direct consequence of five independent,
individually-necessary beam sources, not padding. See `TEST_PLAN.md`'s
manual review checklist for this specific point to verify by hand.

**Design method:** every level reused the solver-verified-safe templates
from all four prior passes (a single non-branching linear chain; a
splitter/multi-emitter pair on fully disjoint rows/columns except one
shared tile; a single physical gate cell crossed by two emitters from
perpendicular directions; a two-stage or three-stage switch/gate relay;
extending an already-validated level's proven geometry via portal jumps
or filters at confirmed transit cells; an independent converging
emitter gating only the start of an existing branch). Two new elements
proven this pass: a genuinely non-rotatable FIXED mirror used
specifically for backward-reasoning teaching (Levels 91/95/98/100,
distinct from the shared-branch fixed mirrors of Levels 67/71/75/85/91,
which were load-bearing convergence points rather than backward-
reasoning puzzles in their own right), and a shared-state chain where a
target's own activation is explicitly just a waypoint toward changing
a THIRD emitter's conditions (Level 96, matching the brief's Part 9
example directly). Every multi-emitter level in this pass was checked
for BOTH flipped and unflipped mirror states crossing another emitter's
territory, per the D69 lesson — zero new collinearity shortcuts found
in this pass (Level 96 in particular was authored with this check
applied proactively, from the first draft).

## 12. Level naming

Short, thematic, mobile-friendly — 1-2 words, or a short compact
phrase. The top HUD's level-name slot truncates past
`game.gd`'s `MAX_LEVEL_NAME_CHARS` (13), so favor names that read
cleanly within that budget. Stage 1's names: Ignition, First Turn,
Signal Path, Blocked, Alignment, False Signal, Deception, Long Relay,
Junction, Breakthrough. Stage 2's names: Redirect, Dead End, Fork Point,
Reverse Trace, Mirage, Cascade, Backtrack, Echo Path, Interference,
Culmination — chosen to evoke reflection/misdirection/routing per Stage
2's own brief, all within the 13-character HUD budget. Stage 3's names:
Divide, Dual Signal, Fork Path, Branch Cut, False Fork, Cross Branch,
Relay Split, Split Trap, Parallel, Fracture — chosen to evoke splitting/
branching/dividing per Stage 3's own brief. Stage 4's names: Prism,
Wavelength, Refraction, Photon, Chromatic, Diffraction, Phase, Radiance,
Pulse, Spectral — chosen to evoke light/color/optics per Stage 4's own
brief, deliberately avoiding "Spectrum" (the stage's own name) and
"Convergence" (already used by dev level 14). Stage 5's names: Filter,
Shift, Cipher, Channel, Conversion, Frequency, Transmute, Waveform,
Vortex, Paradox — chosen to evoke color transformation/signal processing
per Stage 5's own brief, deliberately avoiding "Filters" (the stage's
own name), "Phase" (already used by Stage 4 Level 37), and "Spectrum"/
"Prism" (already used or avoided per Stage 4's own naming pass). None of
these 50 collide with each other or with any of the 15 dev/regression
levels' own names (First Light, Reflection, Obstruction, Fixed Point,
Three Turns, Twin Targets, Split Path, True Color, Recolor, Through the
Portal, Switch and Gate, Danger Zone, Two Sources, Convergence, All
Systems), which is deliberate — see `DECISIONS.md` D54/D55/D56/D57/D59
on not copying dev levels. Levels 61-70's names: Peripheral, Longcut,
Invalidation, Twin Anchor, Convergence Point, Portal Trap, Chain
Reaction, Twin Corridor, Color Conflict, Grand Convergence. Levels
71-80's names: Deliberate Detour, Locked Corridor, Locked Splitter,
Twin Portals, Convergence Reaction, Reverse Relay, Distant Splitter,
Distant Corridor, Silent Third, Full Convergence — none collide with
any dev, tutorial, or earlier campaign level name; the recurring
"Convergence" motif (Convergence Point/65, Grand Convergence/70,
Convergence Reaction/75, Full Convergence/80) is deliberate thematic
continuity for this project's signature whole-board-dependency levels,
not an accidental duplicate (each full name is distinct). Levels
81-90's names: Third Signal, Crossed Corridors, Silent Detour, Distant
Relay, Convergence Threshold, Reciprocal Corridor, Triple Relay,
Distant Triple Relay, Fourfold Relay, Full Circuit — none collide with
any dev, tutorial, or earlier campaign level name; the "Relay" motif
(Triple Relay/87, Distant Triple Relay/88, Fourfold Relay/89) is
deliberate, naming the new three-stage-relay mechanic honestly rather
than disguising the reuse, and "Full Circuit" (90) deliberately echoes
"Full Convergence" (80) as this pass's own closing-milestone name.
Levels 91-100's names: Inferred Convergence, Delayed Verdict, Pre-Split
Signal, Traced Colors, Final Threshold, Chain of Custody, Triple
Verdict, Triple Inference, Penultimate Verdict, Culmination — none
collide with any dev, tutorial, or earlier campaign level name; the
"Verdict" motif (Delayed Verdict/92, Triple Verdict/97, Penultimate
Verdict/99) marks this block's recurring "the board only reveals the
truth once every dependency resolves" theme, and "Culmination" (100) is
the deliberate, literal closing name for the 100-level campaign.

## 13. The 100-level campaign is now complete — what future work means here

**HISTORICAL NOTE:** this section originally described how to build
Stage 6 onward, back when "Stage = one new mechanic" was still the
plan and only Levels 1-50 existed. That plan no longer applies (see
the Campaign Reboot, `DECISIONS.md` D64), and as of Levels 91-100
(`stage_10`, section 11m, `DECISIONS.md` D70), **all 10 stages / all
100 originally-planned campaign levels now exist.**
`LevelManager.get_campaign_level_count() == 100`, `get_campaign_level(101)`
returns `null` gracefully, and `is_campaign_level_selectable(101) ==
false` — all confirmed via a real-autoload driver. There is no Stage
11 in the original plan.

**What this means for any future session:**

- **Update: Campaign Levels 101-110 now exist** (see section 15) -
  explicitly requested by the user, exactly the "genuinely new
  initiative" scenario this section anticipated. The rule below now
  reads "111+" in spirit; kept as originally written here for historical
  accuracy of what was true when the 100-level campaign completed.
- **Do not create Campaign Levels 101+ or a Stage 11 without being
  explicitly asked.** The 100-level structure was a defined scope, not
  an open-ended one — reaching it is a milestone to report and wait on,
  not a cue to keep going. If a future user explicitly asks for more
  campaign content beyond Level 100, treat it as a genuinely new
  initiative (new naming, new section here, its own `DECISIONS.md`
  entry) rather than "Stage 11" continuing the original plan's numbering.
- **Levels 1-50 are the user-tested, manually-positive baseline.
  Levels 51-100 remain automated-validated only** — full manual
  difficulty QA across 51-100 is the standing, high-priority open item
  for this project. Do not describe any of Levels 51-100 as "approved"
  without checking `CURRENT_STATUS.md` for whether that review actually
  happened.
- **The safe design templates and lessons accumulated across all five
  expansion passes remain load-bearing reference material** for any
  future campaign or non-campaign level work in this project: a single
  non-branching linear chain; a splitter/multi-emitter pair on fully
  disjoint rows/columns except one deliberately shared tile; a single
  physical gate cell crossed by two emitters from perpendicular
  directions; a two-stage or three-stage switch/gate relay; extending
  an already-validated level's proven geometry via portal jumps or
  filters at confirmed transit cells; an independent converging emitter
  gating only the start of a branch; and a genuinely non-rotatable
  fixed mirror used for backward-reasoning teaching. See
  `DECISIONS.md` D54-D70 for the full history and every rejected draft
  along the way.
- **Never share one portal pair between two independently-solved
  beams** (D66, pathologically slow solver search). **Confirm every
  emitter's entire path — including its UNFLIPPED default mirror
  states — is disjoint from every other emitter's entire path** (D69,
  the Level 87 collinearity bug). **Watch the rotatable-piece count
  against `LevelSolver.DEFAULT_MAX_STATES` (65536)** — Levels 80 and 95
  both already sit at the practical 16-rotatable-piece ceiling (D68,
  D70). **Before adding a gate that depends on something downstream in
  an existing relay chain, trace whether it closes an actual circular
  deadlock** (D69, and D70's own near-miss on Level 100's first draft —
  a gate may only depend on a switch reachable *before* anything that
  gate itself blocks becomes necessary).
- **`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true`** (a
  development/QA-only flag, `DECISIONS.md` D58) remains enabled, making
  all 100 campaign levels directly selectable regardless of real unlock
  progress. **This MUST be set to `false` before any final production
  release build** — see the release checklist in `TEST_PLAN.md`. Don't
  mistake "all levels selectable" for "all levels completed" when
  reading save state — check `SaveManager.campaign_completed_levels`
  for genuine progress, and never disable the flag without being
  explicitly asked.
- **Portrait re-layout is now COMPLETE for all 100 campaign levels**
  (Phase 1 engine, `DECISIONS.md` D72; Phase 2A Levels 1-25,
  `DECISIONS.md` D73; Phase 2B Levels 26-50, `DECISIONS.md` D74; Phase
  2C Levels 51-75, `DECISIONS.md` D75; Phase 2D Levels 76-100 — the
  final batch — `DECISIONS.md` D76; see section 5's addendum above). It
  changed board geometry only, via a solver-checked order-preserving
  coordinate remap — never difficulty, mechanics, or solutions. Five
  levels across all four phases (75, 85, 91, 95, 98) were deliberately
  left unchanged, already fully packed on both axes with zero slack to
  remap. **Do not start any further re-layout work, and do not create
  Campaign Levels 101+, without being explicitly asked** — same
  standing rule as every other piece of unrequested future work in this
  file. The complete 100-level campaign plus the T01-T10 tutorial
  together constitute **Era 1** (documented in `ROADMAP.md`); a future
  Era 2 is not implemented and not to be started without a separate
  explicit request.
- **A future, separate "Era" product direction has been recorded (not
  implemented)** in `ROADMAP.md`: eventually Campaign/Endless framing is
  intended to be replaced by one continuous Tutorial+PLAY progression,
  with the current 100-level Campaign + T01-T10 Tutorial together
  forming "Era 1" and future Eras adding their own 100 levels + 10
  tutorials + new mechanics/theme. This is documentation only — no Era
  2 content, no Level 101+, no T11+, exists or should be started without
  a separate explicit future request.
- **Campaign completion behavior was verified, not assumed**: `game.gd`'s
  existing `has_next = current_level_id < LevelManager.
  get_campaign_level_count()` check already correctly evaluates to
  `false` for Level 100 with no code changes needed, and
  `LevelCompletePopup.show_result()`'s existing `_next_button.visible =
  has_next_level` already hides the Next Level button cleanly — this is
  the same generic mechanism that already handled Level 90 being
  "the last level" before this pass, Level 70 before that, and so on
  back to Level 10. No special "Campaign Complete" screen exists, and
  none was built in this pass — see `DECISIONS.md` D70 for the explicit
  decision to defer any dedicated end-of-campaign celebration UI to a
  future milestone, since the existing behavior is already correct,
  crash-free, and does not attempt to load a Level 101.

## 14. Rules preventing trivial levels

- `LevelValidator`'s "TRIVIAL SOLUTION" warning (a level already solved
  in its authored state, zero moves) is a hard stop — never ship a
  level that triggers it.
- A level where every rotatable piece's "wrong" orientation is a boring
  immediate off-grid exit (no real tempting alternative) is *allowed*
  but should be used sparingly — mix in at least one genuine fork or
  blocker-guarded wrong branch per level once past the very first
  levels of a stage (Stage 1's Level 1 is deliberately the one
  exception — it's the player's very first move, and should be as
  unambiguous as possible).
- Never solve a "later, harder" puzzle in fewer real moves than an
  earlier, "easier" one in the same stage without an intentional
  design reason (and if there is one, note it in `developer_notes`).

## 15. Campaign Levels 101-110 — the first Era 2 campaign content

Full writeup: `DECISIONS.md` D80, `ERA_2_DESIGN.md` section 12. This is
the genuinely-new-scope work section 13 above described in advance —
explicitly requested by the user, not a continuation of the original
100-level plan's numbering.

**File layout**: `levels/campaign/era2_stage_01/level_01.gd` -
`level_10.gd` (local `level_id` 1-10, matching every `stage_NN`
folder's own convention), registered as 10 entries appended to
`LevelManager.CAMPAIGN_LEVEL_PATHS` after Level 100's. Named
`era2_stage_01`, not `stage_11` - per section 13's own explicit
guidance not to treat a future 101+ request as "Stage 11 continuing the
original plan's numbering." `get_campaign_level_count()` is now 110;
`get_campaign_level(111)` still returns `null` gracefully, same as
`get_campaign_level(101)` did before this pass.

**Design approach**: unlike Levels 1-100 (which teach one mechanic per
early stage, per section 1a/2's mechanic-agnostic-from-Level-1 rule),
Levels 101-110 are the introductory arc for three entirely new
mechanic families the player has only ever seen in isolation (T11-T20).
Difficulty rises through dependency depth and false-route reasoning,
not tile count or rotatable-piece count - Level 110 (the block's own
finale, combining all three Era 2 families) uses only 3 rotatable
pieces and 8 solver states, far below the project's established
16-piece/65536-state practical ceiling (section 11l/11m). Every level
was hand-traced cell-by-cell for every beam branch under every
rotatable-tile combination before being written, including what each
WRONG orientation does - the same discipline that caught D69's
collinearity bug and D70's near-circular-dependency mistake in Levels
87-100. See `ERA_2_DESIGN.md` section 12 for the full per-level table
(mechanics, grid size, optimal moves, states explored, shortest-
solution count) and Level 110's own color-bypass near-miss (an
originally-`WHITE`-required final target that would have let the RED
Prism channel solve it without ever using the Receiver/Remote Emitter
mechanic - caught by tracing every beam's color at every reachable
cell, fixed by giving the remote emitter an explicit `GREEN` color).

**Validation**: every level `SOLVABLE` with `shortest_solution_count ==
1` and zero `LevelValidator` errors on the first authoring attempt - no
draft rejections needed, unlike several Era 1 expansion batches (D65,
D66, D68, D69, D70). Full regression after adding: 15/15 dev, 110/110
campaign (100 unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures
- all solver + real-`GridManager`-runtime-replay PASS.

**What this means for any future session**: **update - Campaign Levels
111-120 now exist (see section 16)**, requested before section 15's own
Levels 101-110 had even finished manual QA. Do not create Campaign
Levels 121+ without being explicitly asked - same standing rule as
every prior milestone in this file, now shifted by twenty. If a future
user asks for more Era 2 campaign content, that's Levels 121-200, not
a new "era2_stage_02" numbering scheme without checking this section
first for consistency.

## 16. Campaign Levels 111-120 — deepening Era 2, no new mechanics

Full writeup: `DECISIONS.md` D81, `ERA_2_DESIGN.md` section 13.
Requested by the user as an explicit follow-up to section 15's Levels
101-110, before those ten had even been through manual Android QA -
same folder (`levels/campaign/era2_stage_01/`), continuing local
`level_id` 11-20, registered as 10 more `LevelManager.CAMPAIGN_LEVEL_
PATHS` entries. `get_campaign_level_count()` is now 120.

**Design approach**: unlike section 15's introductory arc (which
introduced each Era 2 mechanic family roughly one at a time), this
block explicitly deepens the SAME four mechanics via dependency depth,
shared physical resources (one tile genuinely reused by two different
beams), and misleading-but-fair local reasoning - per brief instruction
not to chase difficulty through tile count, grid size, or rotatable-
piece count. Rotatable-piece counts (2-7) stay well below the
project's established 16-piece practical ceiling; states explored
(4-128) stay nowhere near `LevelSolver.DEFAULT_MAX_STATES` (65536).

**Three real shortcut bugs, all one failure shape**: a beam that has
already activated its own required target keeps traveling in its
current direction (targets never stop a beam) into a second mechanic
it was never designed to touch - the exact class of authoring mistake
this file's own section 11's safe-design-template notes warn about in
the abstract, now with three concrete instances. Levels 112 and 118
each needed one fix (a shared column let one beam or one emitter
accidentally satisfy/power two things at once - moved the second tile
off that column). Level 120 needed two attempts: a first fix that only
changed a rotatable tile's *default* orientation left an alternate,
equal-length shortcut behind (the solver's `shortest_solution_count`
came back 2, not 1) - the real fix relocated the tile so no orientation
of it was ever physically reachable by the stray beam. See `ERA_2_
DESIGN.md` section 13 for the full per-level trace and the per-level
design table (mechanics, grid size, rotatable count).

**Validation**: every level `SOLVABLE` with `shortest_solution_count ==
1` and zero `LevelValidator` errors, after the fixes above. Full
regression: 15/15 dev, 120/120 campaign (110 unchanged + 10 new), 20/20
tutorial, 13/13 Era 2 fixtures - all solver + real-`GridManager`-
runtime-replay PASS. Progression verified against the real
`SaveManager` API across the full 110->111->...->120 walk (every step,
not just the endpoints).

**What this means for any future session**: **update - Campaign Levels
121-130 now exist too (see section 17)**, requested before either
section 15 or section 16's own content had received any manual QA. Do
not create Campaign Levels 131+ without being explicitly asked - same
standing rule, now shifted by thirty.

## 17. Campaign Levels 121-130 — whole-board reasoning, no new mechanics

Full writeup: `DECISIONS.md` D82, `ERA_2_DESIGN.md` section 14. "Deep
dependency pass" - explicitly requested by the user before ANY prior
Era 2 level batch (section 15's 101-110, section 16's 111-120) had
received manual Android QA. Same folder (`levels/campaign/
era2_stage_01/`), continuing local `level_id` 21-30, registered as 10
more `LevelManager.CAMPAIGN_LEVEL_PATHS` entries. `get_campaign_level_
count()` is now 130.

**Design approach**: section 16 deepened individual mechanic
interactions one at a time; this block requires reasoning about
MULTIPLE interacting dependency structures at once - a resource shared
by two beams from entirely different Prism channels or emitters, a
relay chain that is reciprocal rather than one-directional, a near-
solution trap that only resolves by reasoning backward from a target's
required color rather than forward from a channel's own color, and
(Level 130) a target gated by two independent subsystems converging
through two gates in sequence. Rotatable-piece counts (2-7) and states
explored (4-128) stay in the same range section 16 established - depth
came from dependency structure, not search space, per explicit brief
instruction.

**Two issues found and fixed during authoring**: Level 123 had a plain
grid-bounds error (a tile placed one row outside the board - caught
immediately by `LevelValidator`'s own explicit bounds check, not a
shortcut). Level 127 surfaced a genuinely new failure shape beyond
section 16's "beam continues past its own target" family: a wrong-
orientation mirror's stray path crossed a second, unrelated mirror
whose own default orientation happened to complete an accidental
shortcut around the level's Portal - fixed with a blocker placed to
intercept only the stray path. See `ERA_2_DESIGN.md` section 14 for
the full per-level trace, the design table (dependency structure per
level), and the general lesson this second bug adds to the project's
design discipline: a wrong rotation's path must be traced past every
tile it crosses, not just to its first "harmless-looking" exit.

**Validation**: every level `SOLVABLE` with `shortest_solution_count ==
1` and zero `LevelValidator` errors, after the fixes above. Full
regression: 15/15 dev, 130/130 campaign (120 unchanged + 10 new), 20/20
tutorial, 13/13 Era 2 fixtures - all solver + real-`GridManager`-
runtime-replay PASS. Progression verified against the real
`SaveManager` API across the full 120->121->...->130 walk.

**What this means for any future session**: **update - Campaign Levels
131-140 now exist too (see section 18)**, requested before ANY of
sections 15, 16, or 17's own content had received manual QA. Do not
create Campaign Levels 141+ without being explicitly asked - same
standing rule, now shifted by forty.

## 18. Campaign Levels 131-140 — advanced convergence, no new mechanics

Full writeup: `DECISIONS.md` D83, `ERA_2_DESIGN.md` section 15.
"Advanced convergence pass" - explicitly requested before ANY of the
three prior Era 2 level batches (sections 15/16/17) had received
manual Android QA. Same folder (`levels/campaign/era2_stage_01/`),
continuing local `level_id` 31-40, registered as 10 more `LevelManager.
CAMPAIGN_LEVEL_PATHS` entries. `get_campaign_level_count()` is now 140.

**Design approach**: combines the strongest dependency patterns from
101-130 into more advanced puzzles - a reflector genuinely shared by
two Prism colors from different directions (not just two separate
emitters), reciprocal relays where one Remote Emitter deliberately
stalls until a second, independent chain resolves, and (Level 140) four
interacting subsystems including a two-stage Remote Emitter chain and
a Portal. Rotatable counts (2-8) and states explored (4-256) stay in
the same general range as sections 16-17 - depth still comes from
dependency structure, not search space.

**This was the most shortcut-prone batch of the four Era 2 level
passes: 5 of 10 levels needed a fix during authoring** (vs. 3/10 and
2/10 for the two prior passes), directly reflecting the higher
structural complexity this pass required. One was a genuine authoring
error (a mirror inserted into an already-complete straight path made
its own target unreachable - `UNSOLVABLE`, not a shortcut). Two were
variants of the established `WHITE`-accepts-any-color target bypass,
including a new "swapped routing" variant where a shared reflector's
wrong orientation swapped which of two beams reached which of two
targets, invisible only because both used the default `WHITE`. One
(Level 138) was a genuinely new failure shape - a shared reflector's
two beams approaching from the SAME side rather than opposite sides,
needing a full geometric rebuild (opposite-side approach) to fix for
good. See `ERA_2_DESIGN.md` section 15 for the full per-level table
and per-bug trace, and the general lesson this adds to the project's
design discipline: for any shared-resource level, check that both
beams' entire corridors - approach AND exit, every orientation - never
overlap, not just that their entry directions differ.

**Validation**: every level `SOLVABLE` with `shortest_solution_count ==
1` and zero `LevelValidator` errors, after fixes. Full regression:
15/15 dev, 140/140 campaign (130 unchanged + 10 new), 20/20 tutorial,
13/13 Era 2 fixtures - all solver + real-`GridManager`-runtime-replay
PASS. Progression verified against the real `SaveManager` API across
the full 130->131->...->140 walk.

**What this means for any future session**: per the user's own
instruction, **a manual Android review checkpoint is now recommended
before Levels 141+** - four consecutive unreviewed Era 2 campaign
batches (40 levels) currently await real-device feedback together, the
largest backlog this project has carried at once. Do not create
Campaign Levels 141+ without being explicitly asked - same standing
rule, now shifted by forty.
