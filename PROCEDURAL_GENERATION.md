# PROCEDURAL_GENERATION.md — Procedural Level Generator (V1 base; V3 progression: section 19)

This is the procedural generator's own architecture/design reference,
covering `scripts/procedural/**`, `scripts/tools/procedural_audit.gd`, and
the PLAY/CONTINUE/QA-Next integration in `GameManager`/`SaveManager`/
`LevelManager`/`game.gd`/`game.tscn`. Read this before touching any of
those. See `CLAUDE.md`'s "Before touching anything" list for where this
sits relative to the rest of the doc set, and `DECISIONS.md` D88 for the
implementation writeup (audit numbers, files touched, bugs found during
authoring).

## 1. What this is, in one paragraph

BeamShift's main player-facing progression is now **procedural**: 2,000
levels (Levels 1-2000), generated on-device at the moment they're needed,
deterministically, from a level number and a generator version. There is
no player-facing Level Select for this population — `PLAY`/`CONTINUE` on
the Main Menu enter it directly, exactly like Campaign did before this
phase. The legacy handcrafted Campaign (Levels 1-140) and the Guided
Tutorial (T01-T20) are unchanged and remain reachable exactly as before —
Campaign only through the QA/dev Level Select screen now, Tutorial through
its own unchanged Tutorial Select flow.

## 2. Architecture

```
scripts/procedural/
  procedural_seed.gd                 -- (A) deterministic seed derivation
  procedural_difficulty_profile.gd   -- (B) band/mechanic/board config lookup
  procedural_templates.gd            -- (C+D) solution-first puzzle construction
  procedural_level_generator.gd      -- (E-G) orchestration, self-verification, retry/fallback
scripts/tools/
  procedural_audit.gd                -- (dev-only) the ONE place LevelSolver/
                                          LevelValidator ever touch generated content
```

All four `scripts/procedural/` files are plain `RefCounted`/static classes
(`class_name`, no autoload — CLAUDE.md rule 6: a generator has no
per-session state of its own). `scripts/procedural/` is a normal **runtime**
dependency (not excluded from the Android export); `scripts/tools/` stays
**dev-only**, excluded exactly as before (see section 5 for why the split
falls exactly there).

Puzzle construction reuses the existing static factories
(`TilePlacement.make_*`), `GridTypes` enums/`reflect()`, and
`LaserSystem.simulate_until_stable()` — no new simulation logic exists
anywhere in this pass, per CLAUDE.md rules 1/3.

## 3. Determinism / seed derivation

`ProceduralSeed.for_attempt(level_number, generator_version, attempt) -> int`
combines the three integers into one deterministic seed via GDScript's
stable `hash()` — never `randi()`/OS entropy. `ProceduralSeed.rng_for_attempt()`
returns a fresh `RandomNumberGenerator` seeded from that value; every
random draw inside `ProceduralTemplates` must come from that one RNG
instance, nothing else.

**Proven, not assumed**: an 11-level determinism sample (1, 10, 100, 250,
500, 750, 1000, 1250, 1500, 1750, 2000) regenerated twice each and compared
tile-by-tile (type/position/orientation/every per-type field) came back
`MATCH` for all 11, across two full audit runs. See section 8.

## 4. Generator versioning contract

`ProceduralLevelGenerator.GENERATOR_VERSION := 1`. Bump this whenever a
change to `ProceduralDifficultyProfile`/`ProceduralTemplates`/the
generation algorithm in `ProceduralLevelGenerator.generate()` would change
what gets generated for an **already-existing** level number. Every saved
procedural resume slot (`SaveManager.procedural_resume_generator_version`)
persists the version it was generated under, so a future version bump
never silently regenerates a different board under a player with an
in-progress puzzle — `CONTINUE` always regenerates via the **saved**
`(level_number, generator_version)` pair, not the current
`ProceduralLevelGenerator.GENERATOR_VERSION` constant. `LevelManager`'s
generation cache is likewise keyed on both numbers together.

## 5. Runtime vs. dev-time verification (read this before changing either)

`ProceduralLevelGenerator` is a genuine runtime dependency (PLAY/CONTINUE/
QA-Next call it live, on-device) but it **never calls `LevelSolver` or
`LevelValidator`** — those stay in `scripts/tools/`, dev-only, excluded
from the Android export exactly as CLAUDE.md rule 9 has always required.
Two different verification strategies are deliberately used at two
different times:

- **Live, on-device (`ProceduralLevelGenerator._verify()`)**: every
  template is *solution-first* — it already knows the correct
  (un-scrambled) orientation of every rotatable tile it places, returned
  alongside the `LevelData` as `solution_orientations`. `_verify()`
  confirms, via a **single direct `LaserSystem.simulate_until_stable()`
  call** (not a search), that (a) the authored/scrambled state is *not*
  already solved, and (b) applying `solution_orientations` on top of the
  authored state *does* simulate to `solved == true` with no loop. This
  is proof by direct simulation, not BFS search — fast (no search
  overhead) and safe (`LaserSystem` is core gameplay code, never
  excluded). A small in-file structural check (`_structural_check`, no
  duplicate/out-of-bounds tiles) is the only other check the live path
  owns — it does **not** reimplement `LevelValidator`'s full rule set
  (portal pairing, switch/gate/receiver dangling references, etc.).
- **Dev-time, exhaustive (`scripts/tools/procedural_audit.gd`)**: the ONE
  place `LevelSolver.analyze()`/`LevelValidator.validate()` ever run
  against generated content. This is what actually proves every
  template/profile combination the generator can produce is solvable,
  well-scoped, and structurally clean — run once (or whenever templates/
  profiles change) across representative batches and the full 1-2000
  range, never at runtime. See section 8 for the numbers.

This is the exact same relationship the 140 handcrafted campaign levels
already have with `LevelSolver` — it proved them once during authoring;
`game.gd`/`grid_manager.gd` never call it at runtime. The generator is
just "authoring," done by code instead of a human, still proven the same
way, still never touching the dev-only solver from the shipped path.

**Do not add a live call to `LevelSolver`/`LevelValidator` from
`ProceduralLevelGenerator` or any other `scripts/procedural/` file** —
doing so would either require removing `scripts/tools/**` from
`export_presets.cfg`'s `exclude_filter` (breaking rule 9's Android-export
boundary) or silently crash on a real device (the classes wouldn't be in
the package). If a future change genuinely needs solver-quality
information at runtime, that's a `PROCEDURAL_GENERATOR_VERSION`-worthy
design decision, not a one-line addition — flag it, don't just add the
call.

## 6. Difficulty bands

`ProceduralDifficultyProfile.for_level(level_number) -> Dictionary` looks
up a band and returns board-profile candidates (pre-filtered through
`GridManager.is_board_profile_comfortable()`), the allowed template pool,
rotatable-tile range, tile budget, decoy budget, target optimal-moves
range, and a solver states-explored ceiling (used only by the dev-time
audit, not the runtime gate).

| Levels | Band | Board candidates | Rotatable range | Template pool starts with |
|---|---|---|---|---|
| 1-50 | Introductory | 5x7, 5x8, 6x8 | 1-3 | simple_mirror_route only |
| 51-150 | Easy/Developing | 6x8, 6x9, 7x8 | 2-5 | + multi_mirror_route, splitter_branch, color_filter_route |
| 151-400 | Medium | 7x9, 7x10, 8x9 | 4-8 | + portal_route, switch_gate_dependency |
| 401-750 | Medium-Hard | 7x10, 8x10, 7x11 | 6-10 | + multiple_emitter, one_way_directional_route |
| 751-1200 | Hard | 8x10, 8x11 | 8-12 | + prism_color_branch, receiver_remote_emitter (full pool) |
| 1201-1600 | Expert | 8x11 | 10-14 | full pool, simple/multi_mirror_route retired |
| 1601-2000 | Advanced Expert | 8x11 | 10-16 | full pool |

Board rows are capped at **11** for every band (see `MAX_ROWS` and
`REFERENCE_PLAYABLE_SIZE` in `procedural_difficulty_profile.gd`) — at
`GridManager.MAX_COLUMNS=8` or fewer columns, 12 rows drops `cell_size`
to ~95px at the 1080x1920 reference floor, one pixel under
`MIN_COMFORTABLE_CELL_SIZE=96`. This means difficulty above the Hard band
comes **entirely** from tile/mechanic density within an 8x11 (88-cell)
ceiling — matching CLAUDE.md's "structure, not size" rule exactly, and
matching D87's own generator note (`prefer ≤9 rows at 5-8 columns` was the
comfort *preference*; 11 rows is the hard *ceiling* this pass measured
directly against the current, post-D87 layout).

**Breather levels**: every 13th level from the Medium band onward pulls
from a reduced rotatable-count range (`is_breather` in the returned
Dictionary), so difficulty rises as an envelope, not a strict staircase —
per the spec's explicit "avoid Level N+1 always strictly harder than N."

**Mechanic-unlock progression**: template pools are additive per band
(never a full reset), matching the spec's "don't expose every mechanic in
Level 1" ask. Era 2 mechanics (Prism/One-Way Reflector/Beam Receiver/
Remote Emitter) first appear in the Medium-Hard/Hard bands; visual Era
theming (`EraTheme.for_era(EraTheme.get_era_for_level(n))`, reused as-is,
100 levels/era) is independent of mechanic availability and simply
follows the level number.

## 7. Generation templates

`ProceduralTemplates.build(template_id, rng, profile, board_size) ->
{"level_data": LevelData, "solution_orientations": Dictionary}`. Every
template is **solution-first**: it builds a monotonic "zigzag" path (see
the file's own class doc comment) — each leg moves strictly RIGHT, then
strictly DOWN (or strictly UP), alternating — which guarantees no
self-intersection and a single uniform `MirrorOrientation` for every turn
by construction (RIGHT→DOWN/DOWN→RIGHT are both `BACKSLASH`; RIGHT→UP/
UP→RIGHT are both `SLASH` — see `GridTypes.reflect()`). Rotatable tiles are
then placed at the *authored* (often scrambled-away-from-solution)
orientation; the *solution* orientation is returned separately so the
caller can self-verify (section 5).

V1 ships 10 templates: `simple_mirror_route`, `multi_mirror_route`,
`splitter_branch`, `color_filter_route`, `portal_route`,
`switch_gate_dependency`, `multiple_emitter`, `one_way_directional_route`,
`prism_color_branch`, `receiver_remote_emitter`. Two-subsystem templates
(`multiple_emitter`, `receiver_remote_emitter`, `portal_route`) band-split
the board into two row ranges and build one independent zigzag path per
band, guaranteeing zero collision between the two subsystems by
construction (not by retry).

**Decoys** are deliberately conservative for V1: non-rotatable, off-path
mirrors placed at cells outside the path's own `occupied` set, so no beam
can ever reach them — inert by construction. This can never create the
"stray beam crosses an unrelated tile" shortcut class documented in
CLAUDE.md's Era 2 lessons (D81-D83). Genuinely-reachable, rotatable decoys
(a false-but-plausible branch) are a real future extension, not built in
V1 — the templates above are exactly the spec's own example list minus
`PRISM -> RECEIVER`/`PORTAL -> RECEIVER`/`PRISM + ONE-WAY`/`MULTI-BRANCH
CONVERGENCE`/`TARGET CONTINUATION`-as-its-own-template/`SHARED RESOURCE`,
which remain documented-but-unbuilt for a future generator pass.

**Bugs found and fixed during this pass's own audit** (see DECISIONS.md
D88 for the full writeup — recorded here because the *lesson*, not just
the fix, matters for whoever extends this file next):

1. `portal_route`'s Portal B was placed in Portal A's own column (the
   board's far-right edge), leaving the second path zero horizontal room;
   it degenerated into a clamped vertical wiggle that collided with Portal
   A's own tiles. Fixed by band-splitting the board (same technique
   `multiple_emitter` already used) so both path segments always get full
   width room from `x=0`.
2. `_zigzag_from()` only floored a leg's *distributed* length at 1, never
   capping the *total* leg count against the board's actually-available
   room — a turn count too large for a small band (e.g. a band-split
   height of 5 rows) forced legs to clamp at the board boundary, producing
   duplicate turn/target positions. Fixed by clamping the turn count
   itself, mathematically, against `h_room`/`v_room` *before* laying out
   any legs (`L <= 2*h_room` and `L <= 2*v_room + 1`), not after.
3. Losing `portal_route`'s "path 1 must end moving RIGHT" parity
   constraint (a casualty of fix #1's rewrite) meant path 1 sometimes
   entered Portal A moving DOWN/UP — since portals preserve direction and
   path 2 is always built assuming a RIGHT entry, the beam exited Portal B
   in the wrong direction for path 2's own geometry. The solver still
   found *some* solvable combination (an unintended one), but the
   template's own intended solution never simulated as solved. Fixed by
   restoring the parity constraint.
4. Template **selection** was keyed on `attempt % pool.size()`, not
   `level_number` — since attempt 0 succeeds on the vast majority of
   candidates, every level in a band landed on `template_pool[0]`, and 6
   of the 10 templates never got used across the entire 1-2000 range on
   the first full audit. Fixed by keying selection on
   `(level_number + attempt) % pool.size()`, confirmed by the
   mechanic-frequency numbers in section 8. **General lesson for this
   file**: a "no failures" audit result does not by itself prove
   *diversity* — always check the distribution counts, not just the pass/
   fail count, exactly like this project's campaign-authoring lessons
   (D81-D83) already warn for hand-authored levels.

## 8. Audit results (this pass, full 1-2000 range, real `LevelSolver`/`LevelValidator`)

Run via `scripts/tools/procedural_audit.gd`'s `audit_range(1, 2000, true)`,
`godot --headless --path . --script <driver>.gd` (dev-only driver, not
committed — see CLAUDE.md's scratchpad rule). Total wall time **278.1
seconds** for the full exhaustive-solver pass across all 2000 levels
(dev-time only; the live per-level runtime gate in section 5 is
sub-millisecond, see below).

- **0 / 2000 failures** (validator errors, non-`SOLVABLE` solver status,
  or `MAX_COLUMNS`/comfort violations).
- **0 / 2000 fallbacks** (the `MAX_ATTEMPTS=40`-exhausted safety net in
  `ProceduralLevelGenerator.generate()` was never actually needed).
- **20 / 2000 (1.0%) non-unique shortest solutions** (`shortest_solution_count > 1`) — informational per the spec's own Part 12 ("track and report it... do not automatically reject"), not a failure.
- **Template distribution** (all 10 used, no template starved):
  `simple_mirror_route` 75, `color_filter_route` 275, `multi_mirror_route`
  176, `splitter_branch` 275, `portal_route` 247, `switch_gate_dependency`
  252, `multiple_emitter` 200, `one_way_directional_route` 201,
  `prism_color_branch` 150, `receiver_remote_emitter` 149.
- **Board distribution**: 5x7 through 8x11, 8x11 used 1025/2000 times
  (dominant in the Hard/Expert/Advanced Expert bands, all of which have
  it as their only candidate — expected).
- **`optimal_moves`**: min 1, median 6, p95 10, max 14.
- **`states_explored`** (BFS, dev-time only): min 2, median 502, p95 7814,
  max 65519 (just under the 65536 ceiling — a handful of the hardest
  levels nearly exhaust the solver's practical range but still resolve
  within it).
- **Generation timing** (live path, `ProceduralLevelGenerator.generate()`
  alone, no solver): median 241µs, p95 681µs, max 1779µs — well within
  the "must not visibly freeze the mobile UI" requirement with large
  headroom; no async/loading-screen strategy was needed for V1.
- **Determinism**: 11/11 `MATCH` (section 3).
- **Difficulty band distribution**: Introductory 50, Easy/Developing 100,
  Medium 250, Medium-Hard 350, Hard 450, Expert 400, Advanced Expert 400
  (exactly matching each band's level-count range by construction).

**Representative-batch verification** (spec's own ranges: 1-20, 45-55,
95-105, 245-255, 495-505, 745-755, 995-1005, 1245-1255, 1495-1505,
1745-1755, 1990-2000) is a subset of the full 1-2000 run above — no
separate pass was needed once the full range was confirmed inexpensive
enough to run exhaustively in one sitting (a staged/sampled approach, the
spec's own documented fallback for an impractically slow full audit, was
not needed here).

## 9. Runtime integration

- **`LevelManager`**: `get_procedural_generation_result(level_number,
  generator_version)` (the full `ProceduralLevelGenerator.generate()`
  result, cached — see below) and `get_procedural_level(...)` (just the
  `LevelData`). `get_procedural_level_count() -> 2000`
  (`ProceduralLevelGenerator.MAX_LEVEL`). `SHOW_PROCEDURAL_QA_NEXT_BUTTON`
  (see section 11).
- **`GameManager`**: `is_procedural_mode: bool` (mirrors `is_tutorial_mode`'s
  pattern), `current_procedural_level: int`, `start_procedural_level(n)`.
  `play_game()` targets `SaveManager.procedural_current_level` (real
  progression); `continue_game()` targets
  `SaveManager.procedural_resume_level_number` when a resumable game
  exists, else falls back to `procedural_current_level` — **these can
  genuinely differ** after QA Next (section 11), which is why they're no
  longer byte-identical implementations (they were through Phase 2).
- **`game.gd`**: a new `elif GameManager.is_procedural_mode:` branch in
  `_load_current_level()`, parallel to the existing editor-playtest/
  campaign branches — loads via `LevelManager.get_procedural_generation_result()`,
  applies era theme via `EraTheme.for_era(EraTheme.get_era_for_level(n))`
  (reused as-is), resumes orientations/move-count via the paired-update
  `restore_orientations()` pattern (rule 12c-safe). `_on_move_made()`/
  `_on_level_solved()` branch the same way they already branch tutorial
  vs. campaign. The Level-100→Era-2 transition banner is explicitly
  excluded for procedural sessions (it's a campaign-specific gate with no
  procedural equivalent — see the `era_transition` computation's own
  comment in `game.gd`).

## 10. Save contract (additive, `SAVE_VERSION` 4 → 5)

New `SaveManager` fields, all with safe defaults via `Dictionary.get()` (no
migration code needed, matching every prior schema bump):

| Field | Default | Purpose |
|---|---|---|
| `procedural_current_level` | `1` | Real progression pointer — the only field `record_procedural_level_result()` advances |
| `procedural_resume_level_number` | `0` | 0 = no resumable game (same sentinel pattern as `campaign_resume_level_id`) |
| `procedural_resume_seed` | `0` | Exact seed of the in-progress puzzle |
| `procedural_resume_generator_version` | `0` | Generator version the in-progress puzzle was built under (section 4) |
| `procedural_resume_orientations` | `{}` | Same `"x,y"` string-keyed format as `campaign_resume_orientations` |
| `procedural_resume_move_count` | `0` | |

No star/best-moves tracking for procedural levels — not part of this
phase's scope (Part 14 of the original spec lists only the fields above).
`record_procedural_level_result(level_number)` mirrors
`record_campaign_level_result()` exactly, including **not** touching the
resume fields — resume state is only ever consulted by comparing against
the *specific* level number being loaded next, and a just-completed level
is never reloaded, so the next `_load_current_level()` call naturally
starts the new level fresh via `start_procedural_resume()` without an
explicit clear (confirmed by this pass's own end-to-end runtime test, see
DECISIONS.md D88).

## 11. QA Next button

`LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON` (currently `true`) — the
**one** flag controlling the small `%QANextButton` on `game.tscn`'s
`BottomBar`, visible only when this flag is true **and**
`GameManager.is_procedural_mode` is true (never for Campaign/Tutorial/
editor-playtest). Purpose: testing up to Level 2000 by solving every prior
puzzle is impractical.

**Exact behavior** (`game.gd._on_qa_next_pressed()`):
```gdscript
func _on_qa_next_pressed() -> void:
    if not (LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON and GameManager.is_procedural_mode):
        return
    GameManager.current_procedural_level += 1
    _load_current_level(true)
```
`_load_current_level(true)` (`force_fresh`) always calls
`SaveManager.start_procedural_resume(n+1, ...)` — moving the resume
pointer forward, exactly like entering any not-yet-resumed level would.
**It never calls `record_procedural_level_result()`** — proven directly by
this pass's own end-to-end runtime test (DECISIONS.md D88): pressing QA
Next repeatedly advances `GameManager.current_procedural_level` and
`SaveManager.procedural_resume_level_number` without moving
`SaveManager.procedural_current_level` at all, and subsequently *solving*
a QA-Next-skipped-to level (one that is not the real next-in-line level)
does not advance `procedural_current_level` either — `record_procedural_level_result()`'s own guard
(`if level_number == procedural_current_level`) is what enforces this,
independent of how the player got to that level. A later `CONTINUE`
correctly reopens the skipped-to level (matching the spec's own example:
tester on 487, QA Next to 488, exits app, CONTINUE reopens 488) without
that level counting as "passed" for real progression.

**Production safety**: `SHOW_PROCEDURAL_QA_NEXT_BUTTON = false` before any
release build — see the release-blocker checklist in `TEST_PLAN.md` and
CLAUDE.md's Level editor rules section, which now lists this alongside the
two existing `UNLOCK_ALL_*_FOR_TESTING` flags.

## 12. Level 2000 / end of range

Completing Level 2000 legitimately reuses the existing Level-Complete
popup with `has_next_level=false` (Next button hidden) — the exact same
mechanism that already handles "no more next level" at the end of any
bounded population (e.g. completing the legacy Campaign's Level 140). No
new UI, no crash, no Level 2001 attempt — confirmed directly (DECISIONS.md
D88: Level 2000 solved via the real solver's own solution path,
`procedural_current_level` advanced to 2001 safely, `has_next_level` false).
`ProceduralLevelGenerator.MAX_LEVEL := 2000` and `MIN_LEVEL := 1` bound
every call into the generator; nothing in this phase generates Level 2001+
or wraps back to Level 1.

## 13. Player save migration

An existing save (pre-Phase-3, `SAVE_VERSION <= 4`) loads with
`procedural_current_level = 1` and no resumable procedural game — `PLAY`
starts fresh procedural progression at Level 1 regardless of any prior
Campaign progress. No equivalence between Campaign progress and
procedural progression is synthesized (the spec explicitly asks for "the
cleanest safe migration," not an invented mapping). This mirrors D85's own
accepted Phase-2 migration limitation exactly (`CONTINUE` stays disabled
until the player presses `PLAY` once, which immediately establishes real
procedural resume state and self-heals permanently).

## 14. Legacy content status (unchanged by this phase)

- **Campaign (Levels 1-140)**: unchanged, remains the QA/dev regression
  population, reachable only via the "Level Select (QA)" button (gated on
  `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`, unchanged).
- **Tutorial (T01-T20)**: fully unchanged — separate population, separate
  save fields, unaffected by any of this phase's code.
- **Dev/regression levels (1-15)** and **editor fixtures**: unaffected —
  confirmed directly by this pass's own regression driver (Campaign 1/50/
  100/140, Dev 1/15, Tutorial T01/T20, editor-playtest hand-off all
  re-verified solvable/functional with zero code-path changes, see
  DECISIONS.md D88).
- **`tools/level_editor/`**: entirely unaffected — the generator is a
  separate, parallel system; the editor's own `LevelSolver`/
  `LevelValidator`/`LevelMetrics` usage is unchanged.

## 15. Release-blocker checklist (procedural-specific, additive to the existing one)

- [ ] `LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON` set to `false`.
- [ ] (Pre-existing, unrelated to this phase, still pending) `LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` / `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` set to `false`.
- [ ] Manual Android QA of representative procedural levels across the full 1-2000 range (this pass is AUTOMATED/RENDERED-verified only — see CLAUDE.md rule 12d's vocabulary; no MANUAL review has occurred yet).
- [ ] `export_presets.cfg` bumped to a real release preset/versioning before any store submission (this pass only produces a QA debug build).

## 16. Extending this generator (future work, not built in V1)

- Remaining spec template names (`PRISM -> RECEIVER`, `PORTAL -> RECEIVER`,
  `PRISM + ONE-WAY`, `MULTI-BRANCH CONVERGENCE`, a dedicated `TARGET
  CONTINUATION`/`SHARED RESOURCE` template beyond what `multiple_emitter`/
  `receiver_remote_emitter` already provide).
- Genuinely-reachable (rotatable) decoys with real, fair false routes —
  V1's decoys are deliberately inert (section 7).
- A true N-template "layering" combinator for higher bands, beyond the
  two built-in two-subsystem templates — V1 relies on
  `multiple_emitter`/`receiver_remote_emitter`/`portal_route`'s band-split
  technique for dependency depth rather than a generic combinator.
- Do not create Campaign Levels 141+, T21+, procedural Levels 2001+, or a
  new Era without an explicit, separate request — same standing scope
  discipline as every other milestone in this project (see CLAUDE.md).


---

## 17. Difficulty contract, complexity metrics and triviality model (Difficulty System Phase 1)

> **Phase 2B update (D96):** the band numbers, board pools and mechanic-unlock schedule quoted in this
> section are the Phase 1 values. `ProceduralDifficultyContract` now holds the Phase 2B production
> targets (section 19.3), the extra V3 policy columns, `max_dependency_depth`, and the V3 mechanic
> availability; when this section disagrees with section 19 or the code, section 19 / the code wins.

**Principle (permanent):** a procedural puzzle is not accepted solely
because it is solvable. Difficulty is determined by both optimal-move
requirements and meaningful reasoning complexity. After the early game,
increasing move count through independent or obvious rotations is not valid
difficulty. QA procedural navigation jumps +50 levels per press during
development and does not affect legitimate completion.

Phase 1 built the *measuring* infrastructure; **generation is unchanged**
(V1 frozen, V2 default, `GENERATOR_VERSION` still 2). Phase 2 changes what
templates build. See `DECISIONS.md` D93.

### 17.1 Files

| File | Role |
|---|---|
| `scripts/procedural/procedural_difficulty_contract.gd` | `get_difficulty_requirements(level_number)` - the one contract table |
| `scripts/procedural/procedural_complexity.gd` | `analyze(level, solution_orientations, solver_result = {})` - metrics by ablation through the real `LaserSystem` |
| `scripts/procedural/procedural_triviality.gd` | `evaluate(metrics, requirements)` / `evaluate_generated(n, generation, solver_result = {})` - `TRIVIAL_*` verdicts |
| `scripts/tools/difficulty_inspect.gd` + `.tscn` | dev-only fast inspection (excluded from export via `scripts/tools/**`) |

`ProceduralLevelGenerator.generate()` now also returns
`solution_orientations` and `intended_moves` (read-only exposure; does not
change any generated level).

### 17.2 Contract bands (initial; tune after Android testing)

| Levels | Name | Optimal moves | Meaningful deps | Min depth | Min interactions | Min distinct mechanics | Max decoys |
|---|---|---|---|---|---|---|---|
| 1-20 | Foundation | 3-5 | 0-1 | 1 | 0 | 0 | 0 |
| 21-50 | Early Thinking | 4-6 | 1-2 | 2 | 0 | 1 | 0 |
| 51-100 | Developing | 5-7 | >=2 (soft*) | 3 | 1 | 1 | 0 |
| 101-200 | Medium | 6-9 | 2-3 | 3 | 1 | 2 | 0 |
| 201-400 | Medium-Hard | 8-11 | >=3 | 4 | 2 | 2 | 1 |
| 401-700 | Hard | 10-14 | 3-4 (soft*) | 4 | 2 | 3 | 1 |
| 701-1000 | Hard+ | 12-16 | >=4 | 5 | 3 | 3 | 2 |
| 1001-1300 | Expert | 14-18 | 4-5 | 5 | 3 | 4 | 2 |
| 1301-1600 | Expert+ | 16-20 | >=5 | 6 | 4 | 4 | 2 |
| 1601-1800 | Master | 18-22 | 5-6 | 6 | 4 | 5 | 2 |
| 1801-2000 | Advanced Master | 20-26 | >=6 | 7 | 5 | 5 | 2 |

\* `dependencies_soft`: the floor is "where supported" by mechanics unlocked
at that level. Move and dependency ranges are the user-specified curve; the
depth / interaction / distinct-mechanic floors are this pass's own initial
numbers (roughly deps+1). Also returned: `unlocked_mechanics` (same unlock
schedule the V2 pools use: splitter/filter 51, portal/switch_gate 151,
multiple_emitter/one_way 401, prism/receiver_remote 751),
`preferred_board_profiles` (taller portrait shapes, <=8 columns, <=11 rows),
`max_independent_move_fraction` (1.0 below 21, 0.75 to 100, 0.6 to 400,
0.5 to 1000, 0.4 above), `reject_single_route` (level >= 30),
`require_non_padding`.

### 17.3 Definitions

- **Meaningful move:** a player rotation required by a shortest valid
  solution. Not counted: QA navigation, Reset, Pause, menus, automatic
  activation, beam simulation, animation, save restore.
- **Padding move:** an intended-solution rotation that can be reverted while
  the board stays solved (so it is not required).
- **Load-bearing tile:** a special tile (Filter, Portal pair, Switch,
  Receiver, Remote Emitter, Prism, Splitter, One-Way Reflector) whose removal
  from the solved board loses a required target. A tile that is merely
  present scores nothing.
- **Meaningful dependency count** = load-bearing Switch->Gate links +
  Receiver->Remote links + load-bearing Portal pairs + Filters/Prisms +
  One-Ways + Splitters + shared-resource rotatables + convergence merges.
  Adjacent mirrors are never counted.
- **Dependency depth:** longest causal chain, `1 + sum` over the load-bearing
  tiles whose removal loses one target (a Switch that has a Gate counts 2).
  Mirror->Target = 1; Prism->Filter->Switch->Gate->Receiver->Remote->Target = 8.
- **Mechanic interaction:** distinct unordered kind pairs (e.g. `prism+filter`,
  `gate+switch`, `receiver+remote`) that are both load-bearing for the SAME
  target. Boards with many mechanics that do not affect one target score 0.
- **Shared resource:** a rotatable mirror/one-way that two or more distinct
  solved-state beams cross (a beam's own origin cell excluded - branching is
  not sharing).
- **Convergence:** required targets minus independent target components;
  two routes that never touch each other converge 0.
- **Independent rotations:** required moves whose every affected target has no
  load-bearing cause ("follow the beam and rotate" moves) - `plain_route_moves`.
- **Single obvious route:** one required target, one emitter, one beam, no
  load-bearing special tile.
- Also tracked: required rotatables, prerequisite chains, color deps, gate/
  portal/receiver/prism/one-way counts, decoys (fixed mirrors/blockers no
  beam touches) and, when a solver result is supplied, verified optimal
  moves, `shortest_solution_count`, solver states.

Known limits (practical, not academic): the intended solution the template
built is the move set, so `intended_move_count` is an upper bound on the
true optimum until a solver result is supplied; shared-resource and
convergence overlap slightly by design; the model has only been exercised on
current-template output, not yet on rich handcrafted levels.

### 17.4 Triviality reasons

`TRIVIAL_TOO_FEW_MOVES`, `TRIVIAL_TOO_FEW_DEPENDENCIES`, `TRIVIAL_TOO_SHALLOW`,
`TRIVIAL_INDEPENDENT_ROTATIONS` (4+ required moves and plain share above the
band's fraction - this is what rejects "20 obvious rotations"),
`TRIVIAL_SINGLE_OBVIOUS_ROUTE`, `TRIVIAL_MECHANICS_NOT_INTERACTING`,
`TRIVIAL_PADDING`, `TRIVIAL_LATE_GAME_SINGLE_MECHANIC` (fewer distinct
load-bearing mechanic kinds than the band requires), `TRIVIAL_SHORTCUT_SOLUTION`
(solver optimum below intended moves; needs a solver result). Exceeding the
move cap is a non-blocking note, `OVER_MAX_OPTIMAL_MOVES`.

### 17.5 Why a ~3-move puzzle appeared at Level 1900+ (traced, not guessed)

Evidence from the fast inspection (V2 default unless stated):

1. **Frozen V1 really produces them.** V1 (flip_chance 0.65, no move lower
   bound) over Levels 1801-2000: 2 levels at 3 moves (1842, 1897), 4 at 4,
   10 at 5 - 8% at 5 or fewer moves. A saved V1 puzzle keeps regenerating
   under V1 (correct, D92), so a tester on a V1 save keeps meeting them.
   Level 1897 under V1 = 3 moves (`color_filter_route`); under V2 = 12.
2. **V2 does not fix the class, only shifts it.** 1801-2000: no level below
   6 moves (median about 10) and no fallbacks, but the band's declared
   `optimal_moves_range` minimum is **never enforced** - `_verify()` only
   rejects `move_count < 1` or `> 2 x max`. Solver check of the 31 lowest V2
   levels: optimal == intended for all (no shortcuts).
3. **Structure never scales.** Every template is one monotonic zigzag with
   at most ONE special tile (or two independent half-board paths); "difficulty"
   is only the turn count from `rotatable_range`, clamped by board geometry
   (`_zigzag_from` max_legs). There is no dependency chain to deepen.
   Templates also degrade silently: `prism_color_branch` places no prism when
   the last leg is short (Level 1900 is a plain 13-turn single route);
   `switch_gate_dependency`/`receiver_remote_emitter` drop the switch/gate/
   receiver when too few straight cells exist.
4. **Mechanics present but not load-bearing; rotations independent.**
   `multiple_emitter` = two independent paths; flipped mirrors are all
   "plain" rotations. 8 of the 100 sampled levels had at least one padding
   move (intended count overstated).
5. **Acceptance = self-verification only** (the intended solution simulates as
   solved); solver metadata, dependency structure and the move lower bound
   are never consulted.
6. Strided V2 sample (every 20th level from 7, 100 levels, ~6 s, no solver):
   **99/100 fail the contract** (only a Foundation level passes); average
   dependencies 0.8-1.7 and depth 1.7-2.5 in every band from Medium up, vs.
   required 2-6 / 3-7. Failure counts: too-few-deps 98, too-shallow 98,
   mechanics-not-interacting 96, too-few-moves 95, late-game-single-mechanic
   91, independent-rotations 22, single-route 9, padding 8.

### 17.6 Phase 2 recommendation (construction-by-design)

Do not regenerate-until-hard. Build each puzzle from a **dependency-chain
plan** sized by the contract:

1. Choose a chain of N unlocked "stages" (prism -> filter -> switch -> gate ->
   receiver -> remote ...) with N from the band's depth / dependency floor.
2. Lay each stage on its own board region along a monotonic path (the existing
   zigzag guarantees no self-crossing), linking stages by construction
   (switch before its gate; the receiver feeds the remote whose beam continues
   the chain).
3. Force **required, non-independent** moves: shared reflectors that two chain
   branches must use in opposite orientations, and authored orientations
   chosen so the first tempting rotation is wrong (a guaranteed-flipped set,
   not a probability).
4. Place one-way/prism so a stray branch cannot bypass a stage (extend the
   "physically unreachable" rule from D81-D83 to every stage).
5. Size stages to reach the band's move floor with real moves - never add
   plain rotations.
6. Run `ProceduralComplexity` + `ProceduralTriviality` on the constructed
   candidate as a cheap gate (a handful of simulations, no solver) and reject
   only on construction bugs; keep the solver as a dev-time audit.

New behavior means `GENERATOR_VERSION = 3` (new `_BANDS_V3`; V1/V2 frozen).
Stars should then use the solver-verified optimum, tuned after difficulty
(not before).

### 17.7 QA +50

`LevelManager.PROCEDURAL_QA_JUMP_AMOUNT := 50` is the single source; the
button label ("+50") and `game.gd._on_qa_next_pressed()` read it. Target =
`min(current + 50, 2000)`; pressing at 2000 is a no-op (no reload). It only
calls `start_procedural_resume()` (via `_load_current_level(true)`), never
`record_procedural_level_result()` - no completion, stars, best-moves, Level
Complete or reward audio; only the existing subtle UI press SFX. CONTINUE
returns to the jumped-to level; PLAY still targets real progression.
Verified end-to-end against a real `game.tscn` instance (see TEST_PLAN.md).


---

## 18. Generator V3 - dependency-first prototype (Difficulty System Phase 2A)

**V3 is dependency-first.** Logical puzzle structure is constructed before
beam routing. High move count without dependency complexity is not accepted
as difficulty. Phase 2A intentionally targets approximately 8-12 meaningful
moves before scaling to the final production difficulty bands (a temporary
prototype exception to the contract's 20-26 late-game band). Limited plain
moves are permitted, but they must not dominate the solution (the profile
requires >= 70% meaningful, <= 30% plain; the six prototypes have 0% plain).
See `DECISIONS.md` D94.

### 18.1 Versions

`ProceduralLevelGenerator.GENERATOR_VERSION_V1/_V2/_V3 = 1/2/3`;
`GENERATOR_VERSION` (the default for new play) stays **2**. `generate(n, 1)`
and `generate(n, 2)` are untouched (frozen tables and templates);
`generate(n, 3)` delegates to `ProceduralGeneratorV3.generate(n)`. A save
holding `generator_version` 1/2/3 regenerates that exact version. V3 is
reachable only through an explicit version 3 or the dev-only QA selector.

### 18.2 Pipeline

```
difficulty requirements (phase2a_requirements)
   -> ProceduralPlannerV3      logical plan: stages, load-bearing mechanics, edges, colors
   -> ProceduralLayoutV3       physical macro-layout per archetype (board size only, no pixels)
   -> ProceduralBoardV3        beam routing: Cursor walks a beam, computes mirror orientations via GridTypes.reflect
   -> start state              opposite of solved for every required move (+ 0-2 "keep correct")
   -> gates                    technical validity, ProceduralComplexity, ProceduralTriviality, plan LB check
   -> accept / retry (geometry conflict or gate failure) / V2 fallback after 12 attempts
```

Files: `procedural_plan_v3.gd` (PuzzlePlan: stages/edges/params/reasoning),
`procedural_planner_v3.gd` (6 archetypes), `procedural_board_v3.gd` (board +
`Cursor` primitives: `to_turn`, `to_splitter`, `to_prism`, `to_portal`,
`to_switch/to_gate`, `to_receiver`, `remote_emitter`, `to_filter`,
`to_one_way_turn/pass`, `to_target`, `cap`, shared mirror/one-way),
`procedural_layout_v3.gd`, `procedural_generator_v3.gd`; dev-only
`scripts/tools/v3_prototype_audit.gd/.tscn`.

- **Load-bearing enforcement:** every plan stage marked load-bearing must
  overlap a load-bearing unit found by `ProceduralComplexity` ablation on the
  real board, else the candidate is rejected ("plan stage 'x' is not
  load-bearing").
- **Required actions / starting state:** each rotatable records its solved
  orientation; start = opposite (a required move) unless `keep_correct`
  (plausible tile that must not be disturbed). No random flip chance. Mirrors
  are binary, so "not solved" is exactly one choice.
- **Shared resources:** shared mirror / shared one-way whose two beams use
  DISJOINT arms (an X): one orientation serves both, the other breaks both.
- **Branching/convergence:** Prism (channels derived from PHYSICAL
  direction, unused ones capped), Splitter, two-emitter; convergence via
  Switch+Receiver both required for one target.
- **Color reasoning:** colored emitters/remote emitters, Filters, colored
  targets (no WHITE target bypass).
- **Portals** separate cause from effect (entry region vs exit region);
  **Switch/Gate** and **Receiver/Remote** chains gate later stages;
  **One-Way** used as a turn on a shared cell (reflect).
- **Not built in 2A (built in 2A.1, see 18.7):** a One-Way "pass-through is correct" puzzle. The
  arithmetic of `one_way_reflective` (RIGHT always reflects; UP reflects only
  in SLASH; DOWN only in BACKSLASH; LEFT never) means a pass-correct shared
  cell needs a crossing whose beams share arms; `to_one_way_pass` exists but
  no prototype uses it yet (Phase 2B candidate).
- **Runtime shortcut protection is structural** (disjoint arms, capped
  channels, colored targets, ablation padding check). The exhaustive
  optimal-vs-intended proof is DEV-TIME (`LevelSolver`, dev-only, CLAUDE.md
  rule 9) on the pinned prototype seeds. F's first layout had a real shortcut
  (solver optimal 9 vs intended 10, two solutions) because RED's mirrors on
  row 4 sat on the BLUE channel's wrong-state deflection path; fixed by
  relocating RED to the top-right - now optimal == intended, 1 solution.

### 18.3 Acceptance profile (Phase 2A)

Moves 8-12; meaningful dependencies >= 3; depth >= 4; interactions >= 2;
distinct load-bearing mechanic kinds >= 3; padding 0; >= 70% of required
moves meaningful; >= 2 beam branches; no single obvious route; move count
must not exceed 12. Rejections are recorded in the result's `rejections`
(`stage` = layout|gate, human-readable `reasons`, e.g. "dependency depth 3 <
required 4", "only 44% of required moves are meaningful"); nothing is logged
in release.

### 18.4 Prototypes (levels 1-6 under version 3; archetype = (n-1) % 6)

| # | Archetype | Board | Seed (attempt 0) | Mechanics | Moves | Deps | Depth | Inter. | Shared | Branches | Solver |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 A | switch_gate_shared | 8x10 | 4029216510 | switch, gate, filter (+ shared mirror) | 9 | 3 | 4 | 3 | 1 | 2 | 9, unique |
| 2 B | prism_color_portal | 8x11 | 4030402431 | prism, portal, filter | 8 | 4 | 4 | 3 | 0 | 4 | 8, unique |
| 3 C | portal_receiver_remote | 8x10 | 4031588352 | portal, receiver, remote, filter | 10 | 3 | 5 | 6 | 0 | 2 | 10, unique |
| 4 D | shared_one_way | 8x10 | 4032774273 | one-way (shared), switch, gate | 8 | 4 | 4 | 3 | 1 | 2 | 8, unique |
| 5 E | splitter_convergence | 8x11 | 4033960194 | splitter, switch, gate, receiver, remote, filter | 11 | 4 | 7 | 15 | 0 | 3 | 11, unique |
| 6 F | mixed_chain | 8x11 | 4035146115 | prism, switch, gate, portal, receiver, remote, one-way, filter | 9 | 6 | 9 | 28 | 0 | 5 | 9, unique |

Seeds shown are the current `ProceduralSeed.for_attempt(n, 3, 0)` values
(layouts vary only by mirror-image flip, colors and 0-2 keep-correct tiles;
`intended` = `optimal` for all six, generation < 5 ms each).

### 18.5 QA access (dev-only)

`LevelManager.SHOW_V3_PROTOTYPE_QA` (true in the QA build; **must be false for
production**). Main Menu gets a small code-built "V3 TEST" button ->
`GameManager.start_v3_prototype(1)` (sub-mode `is_v3_prototype_mode`, procedural
mode stays true). In that session the HUD QA button reads "NEXT V3" and
cycles 1..6; the header reads "V3 PROTO n / 6". A V3 session never reads or
writes `SaveManager` (no resume, no completion, no stars). Outside it the
`+50` button is byte-for-byte unchanged.

### 18.6 Known limits / Phase 2B inputs

Only mirror-image + color variation per archetype (no free-form layout
search); only 0-2 keep-correct tiles, so most required tiles start wrong;
generator hard-codes 8-column boards; a single fixed acceptance profile (not
yet per contract band); One-Way pass-correct puzzle and target-continuation
delay not yet used (pass-correct now exists in D as of 2A.1, see 18.7); scaling to the 20-26 move bands needs longer chains or
two-archetype composition. Decide from manual Android feedback.

### 18.7 Phase 2A.1 - reasoning depth for prototypes D, E and F (`versionCode=50`, `4.1.1-PROCEDURAL-V3-THINKING-QA`)

**Phase 2A.1 focuses on reasoning depth rather than raw move count.** The user
approved the V3 direction after playing all six on Android but found D, E and F
too easy to execute: most required tiles started visibly wrong, so the loop was
"see wrong mirror -> rotate -> follow beam -> next obvious tile". A/B/C were
accepted as the easy baseline and are **byte-identical** to Phase 2A (ASCII
board, metrics and solver result diffed against a saved baseline). Only D/E/F
layouts, plans and their acceptance profiles changed; `PROTOTYPE_COUNT` is still
6, V3 is still QA-only, V1/V2 files were not touched.

**Not every load-bearing tile should visibly advertise its required final
orientation from the starting state.** New start-state rules for D/E/F:
route tiles the player would otherwise follow can start already correct
(explicit `keep_correct` in the layout, not the random 0-2 draw - the planner now
forces that param to 0 for D/E/F), the downstream chain is hidden behind an
unpowered Receiver, and a wrong-but-purposeful state is on the board at start.

**Hard puzzles should contain globally constrained decisions where a locally
reasonable choice can conflict with another dependency.** Each of D/E/F has one:

| | Concept | Local choice | Global constraint |
|---|---|---|---|
| D | shared One-Way OW1 (X: A right->up, B up->right) + a second One-Way OW2 A must PASS | B's pre-route starts correct, so at start B PASSES OW1, lights the Switch and the Gate looks open | the same orientation sends A away; fixing OW1 closes the Gate until A itself arrives; A then has to PASS OW2 (reflecting is wrong there) |
| E | splitter -> {Switch/Gate, Portal->Receiver->Remote}, then a colour fork | the Switch branch (`(5,1)` starts correct) can look finished; the fork's wrong side reaches the target too | wrong side = fixed decoy route through a wrong-colour Filter (target stays dark); right side needs the Gate (Switch) AND the target-colour Filter. Backward: target colour -> Filter -> Gate -> Switch |
| F | Prism -> shared One-Way; RED channel Portal->Portal->Receiver->Remote; DOWN channel (Z) into the One-Way | wrong state: remote beam PASSES the One-Way, hits the Switch, lights the second target T_w | right state reflects the remote beam through Gate+Filter to T, and Z (not the remote) must light T_w and the Switch: allocation of one shared tile between two beams |

**One-Way pass/reflect (D).** A pass-correct *shared* cell is geometrically
unavoidable-overlap: a passing beam uses opposite arms (N+S), a reflecting beam
an adjacent pair (W+S / W+N / ...), so any reflecting partner necessarily
retraces the passer's approach or exit corridor (verified by enumerating every
`one_way_reflector_is_reflective` case). So D keeps OW1 as a reflect-reflect X
and puts PASS on a second One-Way (`Cursor.to_one_way_hold`, solved = the
non-reflecting orientation, start = reflecting), and the start state itself
shows B PASSING OW1. A pass tile is not ablation-load-bearing by nature
(removing a tile the beam passes changes nothing), so the plan does not mark it
load-bearing - its required *move* is what the padding check verifies.
Likewise F's shared One-Way cannot be seen by ablation: with the tile removed
the Prism's Z beam slides along the remote beam's exit row, so F's plan marks it
non-load-bearing and F's depth comes from the two Portal hops, Receiver/Remote,
Filter and Switch/Gate.

**Board primitives added:** `Cursor.to_one_way_hold(cell, node, keep_correct)`,
`Cursor.to_join(cell, role)` (a second route ending on an existing tile),
`ProceduralPlannerV3.third_color(a, b)`. Existing `to_turn(..., rotatable=false)`
builds the fixed decoy routes (E: 2 fixed mirrors; F: 1).

**Per-archetype acceptance (`ProceduralGeneratorV3.requirements_for`).** A/B/C
keep `phase2a_requirements()`. D: 8-11 moves, deps >= 4, depth >= 5, interactions
>= 4, branches >= 2, >= 80% meaningful, shared >= 1. E: 10-13, deps >= 5, depth
>= 7, interactions >= 6, branches >= 3, prerequisite chains >= 2. F: 10-14, deps
>= 6, depth >= 9, interactions >= 8, branches >= 3, >= 85% meaningful, shared >=
1, chains >= 2. New keys `min_shared_resources`, `min_prerequisite_chains`.
Gate rejections now carry `metrics` and `ascii` (used by the audit to print the
rejected candidate).

**New QA metrics (structural, one start-state simulation, no search)** -
`ProceduralComplexity.start_state_visibility()`:
`obvious_wrong_required_tiles` (required tiles a start beam already touches),
`hidden_required_tiles`, `preserved_tiles` (start already solved),
`start_activations` (switches+receivers+targets lit at start),
`initially_plausible_required_states = hidden + preserved + start_activations`.
Also `greedy_follow_solve()` - a *proxy* for "rotate every visibly wrong tile":
a player who only tries beam-touched tiles and keeps a flip that raises visible
progress (targets >> switches/receivers >> special tiles reached >> cells lit).
It is not a solver and proves nothing; it is deliberately generous (it sees the
effect of each hypothetical flip). `load_bearing_units` entries now list `lost`.

**Prototype table after 2A.1** (pinned seeds, attempt 0; solver cap 16384):

| # | Board | Moves | Deps | Depth | Inter. | Shared | Branches | Chains | Solver | obvious/hidden/preserved/start-act/plausible | Greedy |
|---|---|---|---|---|---|---|---|---|---|---|---|
| D | 8x10 | 8 | 6 | 5 | 6 | 1 | 2 | 1 | 8, unique, 1981 states | 3/5/3/1/9 | stuck (3 flips) |
| E | 8x11 | 11 | 5 | 8 | 21 | 0 | 3 | 2 | 11, unique, 8178 states | 1/10/2/0/12 | stuck (6 flips) |
| F | 8x11 | 11 | 9 | 9 | 21 | 1 | 5 | 2 | 11, unique, 4095 states | 1/10/1/0/11 | **solves (11 flips)** |

(A/B/C for comparison: obvious 2/1/1, hidden 7/7/9, preserved 1/1/0; greedy
stuck/solves/stuck. Solved by the greedy: B and F.)
Shortcut check repeated on 12 further seeds of D/E/F (levels 10-12, 16-18,
22-24, 28-30) plus F on 36 and 42: optimal == intended and unique on all.
Levels 24 and 36 (both F) needed attempt 1 / 3 (attempt 0 hit
`TRIVIAL_PADDING`, 1 padding move, for that colour draw) - still deterministic,
pinned prototype 6 is attempt 0.

**Honest limits.** (1) "Plain moves 0%" is reported for all six but is
generous: with one causal target the metric cannot tell a route-following mirror
from a dependent one. (2) `obvious_wrong` is 1-3 for every prototype including
A/B/C (the downstream is hidden by construction), so it does not separate D/E/F
from 2A by itself; the differences are `preserved`, `start_activations` (D) and
the constructed wrong states. It was not measured on the old D/E/F. (3) F is
still solved by the greedy proxy: its wrong-route trap (T_w) only bites if the
player powers the remote before routing the Prism's Z channel, and a forward
player usually does the reverse. F's difficulty is chain length, hidden remote
route, two Portal hops and the shared tile - Android feedback decides if that is
enough. (4) D's shared tile has no pass-correct answer (18.7 geometry note).


## 19. Generator V3 progression (Difficulty System Phase 2B, `versionCode=51`, `4.2.0-PROCEDURAL-V3-PROGRESSION-QA`)

Full rationale: `DECISIONS.md` D96. **V3 is still development/QA - not
release-certified, not the default generator (`GENERATOR_VERSION` stays 2).**
Phase 2A's six hardcoded prototypes are now permanent regression fixtures; the
same dependency-first idea is scaled into a reusable generator that works from
(level number, seed, difficulty band). **Difficulty comes from reasoning
(dependency chains, load-bearing mechanics, colour, convergence, hidden
state), never from board size, tile size or extra plain rotations.**

### 19.1 Versions, selection, saves

| | |
|---|---|
| V1 / V2 | frozen, byte-identical (re-verified: prototypes A-F diffed identical to a saved baseline; V1/V2 regenerate as V1/V2 in the end-to-end test) |
| V3 fixtures (A-F) | `ProceduralGeneratorV3.generate(1..6)`, reachable only through Main Menu "V3 TEST" / in-game "NEXT V3"; never touch saves; unchanged |
| V3 progression | `ProceduralProgressionV3.generate(level)`; reached by `ProceduralLevelGenerator.generate(n, 3)` |
| New-play selection | `LevelManager.procedural_generator_version_for_new_play()` - **V3 while `LevelManager.USE_V3_FOR_PROCEDURAL_QA` is `true`** (single place), else `GENERATOR_VERSION` (2) |
| Resume | the version saved with the puzzle (`SaveManager.procedural_resume_generator_version`) always wins: a saved V1 -> V1, V2 -> V2, V3 -> V3 (never cross-regenerated) |
| Seeds | `ProceduralSeed.for_attempt(level, 3, 100 + attempt)` (offset so progression can never collide with the six fixtures' seeds) |

Consequences worth knowing: PLAY on a level whose *saved resume* is an old V2
puzzle at that same level number resumes that V2 puzzle (by design); Reset /
Retry and the `+50` button use `force_fresh` and therefore generate V3. The
QA HUD shows a second line under the level number, `V3 <band code>`
(`FND ERT DEV MED MHD HRD HD+ EXP EX+ MST ADV`), or `V3 FAILED>V2` when the
generator fell back (only shown while the QA flag is on and the puzzle is V3).

### 19.2 Pipeline

```
ProceduralDifficultyContract band (single source: moves / deps / depth / interactions / kinds
                                    + V3 policy: meaningful, plain cap, greedy policy, keep, plausible)
  -> ProceduralFragmentsV3.compose   atom recipe (core pool + escalation) -> LINE TREE + turn-slot budget
  -> ProceduralComposerV3.build      portrait layout, router, restarts (no hand-placed coordinates)
  -> center_content()                pure translation
  -> ProceduralComposerV3.harden     wrong-ray blockers
  -> apply_keep_correct              some mirrors start correct
  -> ProceduralGeneratorV3._check    technical validity + ablation metrics + load-bearing promises + triviality
  -> extra gates                     early ceilings, plain share, plausible share
  -> ProceduralShortcutProbe         bounded runtime shortcut search (LaserSystem only)
  -> greedy heuristic                policy: allowed / track / prefer_reject / reject
```

Runtime-safe (rule 9): only `LaserSystem` is ever called at runtime; the
solver/validator are dev-time (`scripts/tools/`). Files: `procedural_fragments_v3.gd`,
`procedural_composer_v3.gd`, `procedural_progression_v3.gd`,
`procedural_shortcut_probe.gd` (+ additions to `procedural_board_v3.gd`,
`procedural_plan_v3.gd`, `procedural_complexity.gd`, `procedural_difficulty_contract.gd`).

### 19.3 Difficulty bands (the contract - `ProceduralDifficultyContract._BANDS`)

| Levels | Band | Moves | Deps | Depth | Interactions | Kinds | Board pool | Meaningful >= | Plain <= | Greedy policy | Keep-correct |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1-20 | Foundation | 3-5 | 0-1 | 1-2 | 0 | 0 | 5x7 5x8 6x8 | 50% | 50% | allowed | 0 |
| 21-50 | Early Thinking | 4-6 | 1-2 | 2-3 | 1+ | 2 | 5x7 5x8 6x8 | 50% | 50% | allowed | 0 |
| 51-100 | Developing | 5-7 | 2+ | 3+ | 2+ | 3 | 5x9 6x9 6x10 | 60% | 40% | track | 10% |
| 101-200 | Medium | 6-9 | 2-3 | 3-4 | 2+ | 3 | 6x9 6x10 7x9 | 60% | 40% | track | 10% |
| 201-400 | Medium-Hard | 8-11 | 3+ | 4+ | 3+ | 3 | 6x10 7x9 7x10 | 70% | 30% | prefer_reject | 15% |
| 401-700 | Hard | 10-14 | 3-4 | 5+ | 4+ | 4 | 6x10 7x10 7x11 | 70% | 30% | prefer_reject | 15% |
| 701-1000 | Hard+ | 12-16 | 4+ | 6+ | 4+ | 4 | 7x10 7x11 8x10 | 75% | 25% | reject | 15% |
| 1001-1300 | Expert | 14-18 | 4-5 | 7+ | 5+ | 4 | 7x10 7x11 8x10 | 75% | 25% | reject | 15% |
| 1301-1600 | Expert+ | 16-20 | 5+ | 8+ | 6+ | 4 | 7x10 7x11 8x10 | 80% | 20% | reject | 15% |
| 1601-1800 | Master | 18-22 | 5-6 | 9+ | 7+ | 5 | 7x11 8x10 8x11 | 80% | 20% | reject | 15% |
| 1801-2000 | Advanced Master | 20-26 | 6+ | 10+ | 8+ | 5 | 7x11 8x10 8x11 | 80% | 20% | reject | 15% |

Reading the table honestly:
- These are progression targets, not a padding mandate. Only the moves window
  and the floors are hard gates everywhere; the dependency/depth **ceilings**
  bind only Levels <= 200 (later they are soft because the metric also counts
  convergence/shared resources the plan model cannot pre-count; convergence is
  excluded from the early ceiling comparison).
- **Interactions have no stored maximum**: the metric counts distinct
  mechanic-kind *pairs* per target, i.e. triangular numbers (0, 1, 3, 6, 10,
  15...), so "3-4" / "4-5" style ceilings are not attainable - only the floor is
  meaningful (kinds >= 3 gives 3+, kinds >= 4 gives 6+, kinds >= 5 gives 10+).
- "Meaningful" is the ablation metric (`dependent_moves / required`);
  "plain" is a *construction* share (interior turns of a route slot: turns
  beyond the two that touch a mechanic, scaled by the required share of all
  mirrors) - a rejection threshold, never a target. For a pure mirror route
  (the first Foundation levels) the ratios cannot apply and are skipped.
- Boards are always <= 8 columns, square cells, and re-checked against
  `GridManager.is_board_profile_comfortable()` inside `_check`. From Level 401
  the pool is ordered largest-first; from 1001 only shapes within 10% of the
  biggest area are used (fitting is what fails, never comfort).
- Mechanic availability (`_UNLOCKS` in the contract, per the Phase 2B pools): filter/portal/
  splitter from 1, switch/gate 21, prism + shared mirror 51, receiver/remote +
  one-way 101; shared one-way, two-stage gates, one-way "hold", target
  continuation 401.

### 19.4 Fragments ("atoms") and archetype pools

A recipe is a list of atoms; the planner starts from a **core** recipe for the
band whose *predicted* depth/deps already fit the ceilings, then **escalates**
with extra atoms (preferring ones that add new mechanic kinds; two-node atoms
when the dependency ceiling binds) until the predicted depth / kinds / deps meet
the band. `predict()` models depth = 1 + sum of nodes, kinds, deps; the real
ablation metrics still gate the built board.

| Atom | Meaning | Nodes | Kinds | Min level |
|---|---|---|---|---|
| F / F2 | Filter recolours; the target needs that colour (F2 = second filter after a mid target) | 1 | filter | 1 / 401 |
| P | Portal jump (exit off the entry ray) | 1 | portal | 1 |
| SB | Splitter whose branch feeds a *second required target* | 1 | splitter | 1 |
| G | Gate on the route, its Switch on its own emitter's route | 2 | switch, gate | 21 |
| SG | Gate opened by a Switch on a *splitter branch* of the same trunk | 3 | splitter, switch, gate | 51 |
| PR | Prism: white trunk, main continues on a turning colour channel, other channels capped | 1 | prism | 51 |
| PG | Gate opened by a Switch on a *prism channel* of the same trunk | 3 | prism, switch, gate | 51 |
| SH | Gate whose Switch route **shares one mirror** with the main route (disjoint arms) | 2 | switch, gate | 51 |
| H | Receiver -> Remote Emitter hop (a new route starts elsewhere) | 2 | receiver, remote | 101 |
| OW | One-Way turn (wrong state PASSES or reflects the other way) | 1 | one_way | 101 |
| OH | One-Way that must PASS the beam (start state reflects) | 0 | - | 401 |
| TM | Required target mid-route (target continuation) | 0 | - | 401 |
| SO | Gate whose Switch route shares one **One-Way** (reflect + reflect) | 3 | one_way, switch, gate | 401 |
| GG | Two-stage gate: the Switch's own route passes a second Gate | 4 | switch, gate | 401 |

Band cores (examples): Foundation route / F / P / SB; Early Thinking F+P, G;
Developing G+F, SG, PR+F+P, SB+F+P, SH+F, PG; Medium PR+H, H+F, OW+F+P, OW+G, SG,
PG; Medium-Hard SG+F, SH+F+P, PR+H+F, GG+F; Hard SG+F, SO+F, OW+H+F, GG+F+P,
OH+SG+F; Hard+ and up SG/PG/SO/GG combined with H, plus escalation to depth 10+
in Advanced Master (e.g. `GG+H+P+F+TM+F2+SB`). Composition, not one monster
template: every board is generated from these reusable atoms and nothing
else. Ordering rules: prisms lead (they need a white beam); a first filter sits
directly before a mid-route target and the second after it; the splitter-branch
target comes last so it inherits the colour; at most one prism and one
non-target-bracketed filter (a second filter is only load-bearing around a mid
target).

Not implemented (documented, not faked): **wrong-colour decoy fork routes**
(Phase 2A prototype E's decoy) and **linked/reciprocal dependencies** - see 19.11.

### 19.5 Layout composer rules (`ProceduralComposerV3`)

- **Randomised depth-first router** over turn cells, budgeted (`WALK_BUDGET`),
  biased toward short hops (`plan.params.alpha`: 0.3 up to Level 400, 0.6 to 1000,
  1.0 above - dense boards pack tight). Group-level backtracking: each turn group
  / straight run is retried from a board snapshot and the remainder is placed
  inside the try, so a dead end backtracks into earlier random choices.
  **Restarts** (`RESTARTS` x `OP_BUDGET` router steps): placement time is
  heavy-tailed (median success a few hundred steps, dead ends burn thousands).
- **Beams only cross perpendicular** (`ProceduralBoardV3.path_axis`), never along
  the same axis, never through a tile.
- **A line's end must be safe** (`_end_ok`): out of the board, or a blocker (the
  composer places one) - a mirror/receiver/switch/portal in front of a beam's end
  is rejected because a stray beam would keep going and power things the plan
  never meant. (This single rule removed most padding / non-load-bearing
  rejections; found by dumping rejected boards.)
- **Sources sit on the edge facing inward whenever possible**; an open-field
  emitter/remote gets a blocker behind it (a stray beam passing an emitter cell in
  its own direction would continue as that emitter's beam - seen as a shortcut).
- **Colour is real data: a filter always takes a colour no other beam in the
  puzzle produces** (`used_colors`: coloured emitters/remotes, prism channels,
  earlier filters). Otherwise a raw prism channel colour equal to the target
  colour satisfies the target without the filter/gate chain (Level 300's first
  draft: optimal 4 vs intended 11).
- **Wrong-ray hardening** (`harden`): for every rotatable mirror/one-way in the
  solved state, its wrong-orientation ray must not run into a non-blocker tile or
  along an existing beam corridor; a blocker on the first free cell fixes it (the
  solved beams never touch that cell). Typical board: 5-18 hazards, 1-5 repaired;
  the rest are immediate neighbours and cannot be repaired - which is why the
  runtime probe exists.
- **`center_content()`** translates the finished layout to the middle of the board
  (pure translation: all tile-to-tile relations unchanged).
- Hop remote colours are WHITE whenever a prism/second filter follows.

### 19.6 Acceptance gates (per attempt, deterministic)

1. plan feasible (turn slots vs move target, plain cap); move target drawn per
   band (Foundation ramps 3 -> 5 with the level number; Level >= 1301 skews low
   because the top of the window physically fits far less reliably; every layout
   failure lowers the next target by 2 down to the band floor);
2. layout placed (`RESTARTS`); board <= 8 columns and comfortable;
3. start state unsolved; intended solution solves, no loop;
4. ablation metrics vs the band (moves in window, deps, depth, interactions,
   kinds, no padding, not a single obvious route, independent-rotation share);
5. **every mechanic the plan promised is load-bearing on the built board**
   (ablation of each stage);
6. meaningful share, plain share, plausible/hidden share for the band;
7. **shortcut probe** (19.7); 8. greedy policy (19.8).

Rejections are *reported* (`rejections` list with stage + reasons), never hidden.

### 19.7 Shortcut probe (`ProceduralShortcutProbe`) - what it is and is not

A **bounded beam search** over flips of the tiles a beam currently touches
(complete for a minimal solution: flipping an untouched tile changes no
simulation, and the first flipped tile along any beam is touched at the start).
Ordered by *overlap of the lit cells with the intended solved beams* (a stray
beam joining a later part of the intended route lights many intended cells at
once) then by progress score; budget 420 simulations, width 12, depth < intended.
It is **not a proof** ("no shortcut found in budget"); the dev-time audit is the
proof. Evidence (solver = exhaustive, dev-only, on the generated levels; raw =
probe disabled):

| Range | Solver-checked | Raw shortcuts (probe off) | Probe caught | Shortcuts with probe on | Unique shortest |
|---|---|---|---|---|---|
| 1-120 | 120 | not measured with the final rules | - | **0** | 120/120 |
| 121-260 | 140 | not measured with the final rules | - | **0** | 140/140 |
| 401-440 | 40 | 4 (10%) | 4/4 | **0** | 40/40 |
| 441-480 | 40 | - | - | **0** | 39/40 |
| 701-719 | 17 (16 raw) | 1 | 1/1 | **0** | 16/17 |

(Before the colour rule and hardening, 300-360 had 4/61 raw shortcuts and the
probe caught 4/4; before the overlap ordering the probe missed two depth-8
shortcuts in 401-440/701-730 - both are caught now.) Above ~17 rotatable tiles
the exhaustive solver cannot finish (2^n), so Levels ~1100+ are covered by the
probe and the structural rules only - **honestly unverified by an exact solver**.

### 19.8 Greedy heuristic, plausibility, fallback, attempts

- Greedy beam-follower (`greedy_follow_solve`) is a triviality detector, never
  a difficulty proof. Policy: 1-50 allowed; 51-200 recorded (`track`); 201-700
  `prefer_reject`; 701+ `reject` = try the remaining attempts for a puzzle the
  greedy cannot solve and accept a greedy-solvable one (flagged
  `greedy_accepted`) only when none exists. Measured greedy-solvable share of
  accepted puzzles: Foundation 40%, Early Thinking 77% (few moves - allowed), 51-100
  40%, 101-200 24%, **0% from Level 201 up** (about 40 levels sampled per band).
- Start-state quality: `keep_correct` mirrors start already correct (0/10/15% of
  the move target); most required states are additionally *hidden* (downstream of an
  unpowered receiver/closed gate/portal); plausible-or-hidden share measured 74-96%.
- Attempts: 12 (16 from Level 1301 - about 2% of dense plans needed more than 12).
  If all fail: `V3_GENERATION_FAILED` (`push_warning`, `fallback_count++`,
  result flagged `fallback_used` + `v3_generation_failed`), V2 supplies a valid
  puzzle so the game never breaks, HUD shows `V3 FAILED>V2`. **A V2 fallback is
  never counted as a V3 success. Production target: 0.** Measured: 0 fallbacks
  in the 25-level sample, in 286 levels sampled across 3-2000 (step 7), and in
  ~50-level windows of every band except one (`1976`, about 1 in 600 sampled at 12 attempts,
  before the 16-attempt cap for 1301+).
- Performance (desktop, per unique level): Foundation ~1-3 ms, Medium ~5-15 ms,
  Hard ~60 ms, Expert ~100-140 ms, Master/Advanced ~180-330 ms typical
  (build ~55%, probe ~30%, metrics ~7%, greedy ~4%). **Android is slower
  (unmeasured on device); the top bands are the first place a level-load hitch
  would show.** Results are cached by `LevelManager` (one level resident).

### 19.9 Star preparation (not finalised)

Every accepted result exposes `intended_moves`, `verified_optimal_moves` (-1:
filled only by the dev-time solver) and `target_move_range` (the band window).
The existing display-only star preview still uses `level.optimal_moves` (= intended).
Later thresholds must use the verified/accepted optimum, never a static number.

### 19.10 Measured results

Focused 25-level sample (`scripts/tools/v3_progression_sample.tscn`; every level
passes the tool's independent re-checks: fallback, determinism, start unsolved,
intended solves, columns <= 8, comfortable, contract verdict, validator, moves in band):

| Level | Band | Board | Fragments | Moves | Keep | Deps | Depth | Inter. | Br/Sh/Cv | Meaningful | Plain turns | Plausible | Greedy solves | Attempt | ms |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Foundation | 5x8 | route | 3 | 0 | 0 | 1 | 0 | 1/0/0 | 0% | 33% | 67% | false | 0 | 1 |
| 10 | Foundation | 5x8 | F | 3 | 0 | 1 | 2 | 0 | 1/0/0 | 100% | 0% | 67% | false | 0 | 1 |
| 20 | Foundation | 6x8 | F | 5 | 0 | 1 | 2 | 0 | 1/0/0 | 100% | 20% | 80% | false | 0 | 3 |
| 25 | Early Thinking | 5x8 | F+SB | 5 | 0 | 3 | 3 | 1 | 2/0/1 | 100% | 0% | 80% | true | 0 | 3 |
| 50 | Early Thinking | 6x8 | F+SB | 5 | 0 | 3 | 3 | 1 | 2/0/1 | 100% | 0% | 80% | true | 0 | 1 |
| 75 | Developing | 5x9 | PR+P+F | 5 | 1 | 3 | 4 | 3 | 4/0/0 | 100% | 0% | 83% | true | 0 | 3 |
| 100 | Developing | 6x9 | P+F+SB | 7 | 1 | 4 | 4 | 3 | 2/0/1 | 100% | 0% | 88% | false | 0 | 4 |
| 150 | Medium | 6x9 | OW+P+F | 7 | 1 | 3 | 4 | 3 | 1/0/0 | 100% | 0% | 88% | false | 0 | 4 |
| 200 | Medium | 6x9 | G+F | 7 | 1 | 2 | 4 | 3 | 2/0/0 | 100% | 0% | 75% | false | 1 | 7 |
| 300 | Medium-Hard | 6x10 | PG+F | 11 | 2 | 3 | 5 | 6 | 4/0/0 | 100% | 23% | 92% | false | 0 | 33 |
| 400 | Medium-Hard | 7x9 | G+F+SB | 9 | 1 | 4 | 5 | 6 | 3/0/1 | 100% | 0% | 80% | false | 0 | 15 |
| 500 | Hard | 7x11 | SG+OH+F | 13 | 2 | 3 | 5 | 6 | 2/0/0 | 100% | 8% | 93% | false | 2 | 62 |
| 600 | Hard | 7x11 | H+G+OH+F+TM+F2 | 10 | 2 | 5 | 6 | 10 | 3/0/1 | 100% | 0% | 83% | false | 0 | 38 |
| 700 | Hard | 7x10 | PR+H+OH+F | 11 | 2 | 3 | 5 | 6 | 5/0/0 | 100% | 17% | 92% | false | 0 | 19 |
| 800 | Hard+ | 7x10 | SG+OW+F | 15 | 2 | 4 | 6 | 10 | 2/0/0 | 100% | 20% | 94% | false | 0 | 40 |
| 900 | Hard+ | 8x10 | SG+OW+F+TM+F2 | 12 | 2 | 6 | 6 | 10 | 2/0/1 | 100% | 0% | 93% | false | 1 | 249 |
| 1000 | Hard+ | 8x10 | PR+SG+OH+F | 15 | 2 | 4 | 6 | 10 | 5/0/0 | 100% | 7% | 94% | false | 1 | 66 |
| 1200 | Expert | 7x11 | PG+H+F | 14 | 2 | 4 | 7 | 15 | 5/0/0 | 100% | 25% | 94% | false | 3 | 107 |
| 1400 | Expert+ | 8x10 | SG+H+G+F+TM+F2 | 16 | 2 | 7 | 9 | 15 | 4/0/1 | 100% | 0% | 89% | false | 2 | 192 |
| 1600 | Expert+ | 8x10 | SG+H+GG+F+TM+F2 | 17 | 3 | 8 | 11 | 15 | 5/0/1 | 100% | 0% | 90% | false | 0 | 107 |
| 1750 | Master | 8x10 | SG+H+G+OH+F+TM+F2 | 20 | 3 | 7 | 9 | 15 | 4/0/1 | 100% | 0% | 91% | false | 1 | 194 |
| 1850 | Advanced Master | 8x11 | OW+GG+H+F+SB | 21 | 3 | 7 | 10 | 21 | 5/0/1 | 100% | 9% | 88% | false | 0 | 91 |
| 1900 | Advanced Master | 8x11 | PR+SG+SG+H+OH+F | 23 | 3 | 7 | 11 | 21 | 7/0/0 | 100% | 4% | 96% | false | 4 | 284 |
| 1950 | Advanced Master | 8x11 | GG+H+P+OW+OH+F+TM+F2 | 20 | 3 | 8 | 10 | 21 | 4/0/1 | 100% | 0% | 87% | false | 2 | 366 |
| 2000 | Advanced Master | 8x11 | GG+H+P+F+TM+F2+SB | 20 | 3 | 9 | 10 | 21 | 5/0/2 | 100% | 0% | 78% | false | 2 | 197 |

(Level 1 is a pure mirror route - the ablation metric has no mechanic to attach to, so
"meaningful" is 0% and the ratio is skipped by design.)

Band averages (about 40 evenly spaced levels per band, production gates, probe on):

| Band | Moves | Depth | Deps | Interactions | Kinds | Tiles | Board fill | Greedy solves | Plausible |
|---|---|---|---|---|---|---|---|---|---|
| Foundation | 3.8 | 1.7 | 0.9 | 0.0 | 0.7 | 8.0 | 19% | 40% | 74% |
| Early Thinking | 5.2 | 3.0 | 2.4 | 1.0 | 2.0 | 11.5 | 29% | 77% | 79% |
| Developing | 6.0 | 4.0 | 2.7 | 3.0 | 3.0 | 15.0 | 29% | 40% | 81% |
| Medium | 7.3 | 4.0 | 2.2 | 3.0 | 3.0 | 16.3 | 28% | 24% | 85% |
| Medium-Hard | 9.5 | 5.0 | 3.1 | 6.0 | 4.0 | 20.4 | 32% | 0% | 87% |
| Hard | 11.7 | 5.3 | 3.9 | 6.7 | 4.2 | 24.4 | 35% | 0% | 90% |
| Hard+ | 13.9 | 6.9 | 4.6 | 12.8 | 5.6 | 29.4 | 39% | 0% | 88% |
| Expert | 15.0 | 7.5 | 5.3 | 13.2 | 5.5 | 33.2 | 42% | 0% | 87% |
| Expert+ | 16.7 | 8.9 | 6.7 | 16.0 | 6.1 | 37.7 | 48% | 0% | 86% |
| Master | 18.7 | 10.1 | 6.9 | 16.5 | 6.2 | 41.6 | 50% | 0% | 87% |
| Advanced Master | 20.9 | 11.0 | 7.6 | 17.9 | 6.4 | 46.0 | 55% | 0% | 85% |

Dev-time solver subset (`solver_states=200000`, each call state-capped): Levels
**1, 50, 100, 500, 1000: SOLVABLE, optimal == intended (3/5/7/13/15), unique
shortest solution, validator clean.** **1500, 1900, 2000: UNKNOWN** (state cap
reached after 15-29 s; 22-29 rotatable tiles = up to 2^29 states) - *not*
UNSOLVABLE; the intended solution is proven to solve by direct simulation and the
probe found no shortcut, but no exact optimum exists for these. `QA_BUDGET_EXCEEDED`
was reported for the last call of that run (total 72 s across eight solver calls).
Rendered check (non-headless captures at 720x1280, Levels 1/60/500/1950): boards
render, fit and stay readable (8x11 at 1950).

### 19.11 Known limits / inputs for Phase 2C

- Top-band exact verification is impossible (2^n); rely on probe + structural rules.
- About 10% of Hard-band boards contain a shortcut before the probe (probe-off runs);
  each costs an extra attempt. Higher-band raw rates are unknown above 17 rotatables.
- Not implemented: wrong-colour decoy fork routes, reciprocal/linked dependencies
  (two beams each powering the other's chain), full shared-decision variants beyond a
  shared mirror/one-way, four+ independent subsystem convergence. The target-continuation
  pattern exists only as `TM` (Level 401+, 30-50% of eligible plans).
- Level-load time on device for Levels ~1300+ is the first thing to watch; possible
  fixes: shorter probe budget for the topmost band, warm-generating the next level
  on a thread, or caching accepted seeds.
- Star thresholds still need the verified optimum (19.9).
- `ProceduralFragmentsV3.TILE_COST`/`estimate_tiles` are an audit aid only (real tile counts include
  hardening blockers, roughly 10% above the estimate).
- The QA HUD tag (`V3 <band>`) and `LevelManager.USE_V3_FOR_PROCEDURAL_QA`,
  `SHOW_PROCEDURAL_QA_NEXT_BUTTON`, `SHOW_V3_PROTOTYPE_QA` must all be reviewed before a
  production release.

### 19.12 Hints (Global Hint System Phase 1, D97)

Every generator result already exposes `solution_orientations` (V1/V2/V3 and V3 TEST); the shared Hint button
uses it directly (cell -> solved orientation; wrong = current != solved). Generation is unchanged; V1/V2
determinism untouched. Caveat: the intended solution is one valid solution.

### 19.13 Ads (AdMob Foundation V1, D98)

Only normal procedural completions (the branch that records progression) feed the interstitial counter; V3 TEST, QA `+50`, tutorials and campaign QA never do. Generation is untouched.

## 20. Fusion in the main progression - generator V4 (Fusion Phase 2, D100)

Generator V4 = `ProceduralProgressionV3.generate(level, 4)` (`ProceduralLevelGenerator.GENERATOR_VERSION_V4`). V1/V2/V3 are frozen (99/99 fingerprints identical). A saved puzzle regenerates under its saved version.
- **Fragments** (`ProceduralFragmentsV3.FUSION_RECIPES`): F1 basic 2-colour; F2 filter-made inputs (filters sit on the input paths - a Filter after the node would recolour away the fused colour); F3 portal on an input path; F4 Fusion -> Switch -> Gate; F5 Fusion -> Receiver -> Remote (explicit remote colour); F6 Prism channels feed the node; F7 R+G+B -> WHITE -> Prism -> colour-specific targets.
- **Unlock** (`ProceduralDifficultyContract._FUSION_PROGRESSION`): 1-200 none; 201-400 F1 (10%); 401-700 F1-F3 (20%); 701-1000 F1-F4 (24%); 1001-1300 F2-F5 (26%); 1301-1600 F2-F6 (28%); 1601-1800 F2-F7 (28%); 1801-2000 F1-F7 (28%). ONE roll per level (`FUSION_ROLL_STREAM`), tried for the first 6 (8 from 1301) attempts, then an ordinary recipe. Realised share 14/23/17/16/27/28/20% per band.
- **Construction**: the node ends line A; further inputs are goal-directed walks (`fjoin`) ending on a free input side at distance >= 2; the output line is built when the last input has joined; the node starts one clockwise tap from solved.
- **Gates** (`ProceduralFusionCheck`, on the built board): node load-bearing; EVERY input required (cut ablation); fused colour consumed (composite target / Switch / Receiver / Prism for WHITE); no required WHITE target or WHITE remote depends on it; no feedback into its own inputs (cycle rejection) and start/solved/one-tap-away boards settle before the pass cap; unrepairable wrong-direction output rays reject; runtime shortcut probe widened to 1500 sims / width 28; greedy policy as V3.
- **Evidence**: exhaustive search PROVEN OPTIMAL on every checked level up to ~140k states; late levels reported STRUCTURALLY VALID / PROBE PASSED (wide probe: 1/42 with a cheaper alternate solution); 60,000 random boards settle. Levels 1001+ are not exactly provable (state space).
- **Post-2000 readiness**: `INITIAL_CERTIFIED_LEVEL_TARGET = 2000` (`MAX_LEVEL` derives from it, unchanged); the contract/policy/Fusion tables read their LAST row for any level beyond 2000 (verified up to Level 99999); nothing beyond 2000 is exposed. Future direction: combinations of existing mechanics in a curated envelope, never size (D100).
- Dev tools: `scripts/tools/fusion_progression_sample.tscn` (default sample / `freq=1 stride=4 bands=` / `stress=N from=K` / `find=F5`), `fusion_verify.tscn` (`window=A,B max=N states=S` / `levels=` / `plain=1`).


## 21. Fusion Phase 3 - fragment variants, dead-node ablation, shortcut screens (D101, `versionCode=56`)

Everything below is generator V4 only; V1/V2/V3 are FROZEN and were fingerprint-verified identical (tiles + solution hash, 38 levels x 3 versions) before/after; V4 changed only for Fusion-rolled levels (allowed: no V4 puzzle has shipped - after a release any such change needs a new generator version).

**Variants** (`ProceduralFragmentsV3`): recipe-level `FUSION_RECIPE_VARIANTS` (F4: `FUG` / `FUK`, F5: `FU+H` / `FU+H+G`) are drawn ONCE in `roll_fusion_recipe` after the fragment draw (the yes/no + fragment stream is unchanged); atom-level variants are drawn from the attempt rng in `_apply_atom` and recorded in `plan.params["fusion_variant"]` -> result `fusion_variant`. Catalogue: F1 `plain` (colour pair = the shuffled primaries: R+G=YELLOW, R+B=MAGENTA, G+B=CYAN all occur), F2 `filter`, F3 `portal` (input B) / `portal_a` (the node's own route) / `portal_out` (the fused output route), F4 `chain` (`FUG`, Fusion -> Switch -> Gate) / `gate` (`FUK`: a Switch opens a Gate on a prerequisite path; ordered like FU because the node must sit on the root route), F5 `remote` / `remote_gate`, F6 `prism_both` / `prism_one`, F7 `plain` / `portal`. `fusion_fragment_of(rolled recipe)` is the fragment id (escalation may add a Receiver/Gate to any recipe; that never relabels it). Not implemented: F7 "Prism + separate third colour source" (a second Prism is disallowed) and F5 "remote feeds a Filter" (no free primary colour: it would need a composite or duplicate colour, i.e. a bypass).

**Dead-node ablation (the important fix).** `ProceduralComplexity.analyze()` ablates a Fusion by replacing it with a BLOCKER, not by deleting it: a deleted node lets its raw input beams run on through the empty cell into a collinear Switch/Receiver, a state no rotation can reach, and produced false "plan stage (fusion) is not load-bearing" rejections. Placed share of rolled recipes: 701-1000 16/20 -> 20/20, 1001-1300 12/17 -> 15/17. `fusion_verify.tscn` counts the dead-node ablation and only prints the empty-cell one; 30 exactly-checked levels (201-400, 401-700, 701-1000, <= 65,536 states) are PROVEN OPTIMAL with one shortest solution, including 9 whose empty-cell counterfactual solves (a false alarm, not an exploit). Never "prove" an UNKNOWN (1001+ is probe-only).

**Shortcut screens** (`ProceduralFusionCheck.evaluate`, exact, on the solved board's one-tap-away neighbourhood, <= `MAX_NEIGHBOUR_SIMS` = 80): the node in any of its 3 other orientations (wrong-orientation direct hit, missing input, output-side input) and every other single rotatable flip must NOT solve the board; no Emitter/Remote Emitter may be composite-coloured; existing per-input cut, WHITE target/remote guards, consumer, no-feedback and settling checks unchanged. `fusion_report["max_passes"]` reports settling passes (observed 3-4).

**Frequency** (table `_FUSION_PROGRESSION` unchanged; realised = placed rolls, stride-4 samples): 201-400 14%, 401-700 23%, 701-1000 27%, 1001-1300 20%, 1301-1600 31%, 1601-1800 34%, 1801-2000 22%. Stress: six 90-level windows (401/701/1001/1301/1601/1801) = 141 Fusion levels, 0 problems, 0 fallbacks; 0 greedy-solvable Fusion levels; Levels 2001-2060 generate cleanly (dev-only, not exposed).

**Tools** (`scripts/tools/fusion_progression_sample.tscn`, all under the 55 s budget): `freq=1 stride=4 bands=3,4` prints rolled vs realised per band, `fragment:variant` counts and the rejection reasons of unrealised rolls; `stress=90 from=401 list=1` prints one `FUSIONLVL` line per Fusion level (fragment/variant, colours, board, moves, depth/deps/interactions, greedy, settle passes); `quiet=1`, `levels=`, `ascii=1` as before. Report line per level also carries `passes<=N variant= rejected={stage:count}`.

**Post-2000.** No fragment/contract code caps at 2000 (`fusion_policy()` reads the last row beyond it). Future levels are meant to combine existing mechanics inside a curated envelope; chained Fusion (output -> second Fusion) remains a future mechanic that needs an explicit request.

## Phase 4 (D102, `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`) - stars, Hint cap, central QA switch, Fusion tutorial nudge

- **Stars:** one rule in `StarScoring` (OPTIMAL from `verified_optimal_moves` >= 0, else `intended_moves`, else legacy `optimal_moves`; +2 = 3 stars, +6 = 2, else 1; below optimal = 3 + QA warning). A GRANTED gameplay Hint caps the attempt at 2 stars (`game.gd._hint_used_this_attempt`, persisted in `procedural_resume_hint_used`/`campaign_resume_hint_used` so Continue cannot reset it; cleared by Reset/Next/QA +50). Best stars: `SaveManager.procedural_best_stars["<level>|<generator_version>"]` (raise-only) and the existing campaign dictionary. Tutorials, V3 TEST, FUSION TEST: no stars, no records. The popup shows the current run's stars + a small "HINT USED".
- **QA vs production:** ONE constant, `BuildConfig.IS_PRODUCTION_BUILD` (false in this build). It derives every QA-only UI/unlock flag in `LevelManager` and hides the tutorial debug overlay and the generator tag. Tools are hidden, never deleted. Not covered: Google TEST ad ids, and the generator rollout flags `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA`.
- **Fusion tutorial nudge:** one-time non-blocking "NEW TUTORIAL: FUSION" banner on Main Menu (`LevelManager.should_show_fusion_tutorial_nudge()`, persisted `fusion_tutorial_nudge_seen`); never forces the tutorial, never locks progression. `bs_fusion_icon.png` remains unused (no icon support in the tutorial panel).
- Level 2000 remains the certification target; nothing beyond it is exposed; no new mechanic.
