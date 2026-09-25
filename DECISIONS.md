# DECISIONS.md

Architectural and design decisions, in roughly chronological order. Add
new decisions to the bottom rather than editing history away — if a
decision is later reversed, add a new entry saying so and why, don't
delete the old one.

## Foundational (established by the milestone brief, Milestone 1)

- **Engine/language:** Godot 4 (built against 4.7.1), GDScript.
- **Platform:** Mobile-first (Android), portrait orientation.
- **Desktop mouse support** is a first-class dev/testing requirement, not
  an afterthought — the input system is built so mouse and touch share
  one code path rather than being two parallel systems.
- **Grid-based deterministic simulation**, not physics/raycasting, is the
  authoritative source of puzzle correctness. Physics may be used for
  cosmetic effects in later milestones but must never decide whether a
  level is solved.
- **Data-driven levels.** No level's tile layout or win condition may be
  hardcoded into gameplay scripts.
- **Placeholder-first development.** Milestone 1 ships no final art;
  visuals are simple procedural shapes so gameplay can be validated
  without blocking on an art pipeline.
- **~100 handcrafted levels across 10 stages** is the long-term campaign
  target (see `ROADMAP.md`'s Part 24 stage list) — Milestone 1 builds only
  5 test levels, but the level/progression architecture is built to reach
  100 without redesign (flat `LEVEL_PATHS` array + `highest_unlocked_level`
  integer scale to any count; stage grouping is an additive UI concern,
  not a data-model change).
- **Difficulty scales via combining mechanics**, not simply enlarging the
  grid. Milestone 1's grid size (5x5) is a starting point, not a ceiling —
  `GridManager`/`LevelData` support arbitrary `grid_width`/`grid_height`.
- **Best-result save behavior.** A worse repeat playthrough never
  overwrites a better stars/moves result already saved.
- **Milestone-by-milestone development** with documentation-based handoff
  between Claude sessions — this file and its siblings exist because no
  session can assume access to a previous session's conversation.

## Milestone 1 decisions

### D1 — Level files are Resource-subclass `.gd` scripts, not `.tres`

The brief suggests `.tres` resource files for levels. Milestone 1 instead
defines each level as a script under `levels/` that `extends LevelData`
and sets its fields in `_init()`.

**Why:** `.tres` is a text-serializable format normally authored through
the Godot editor's Inspector UI or exported by tooling; hand-writing
correct `.tres` syntax for nested typed arrays of a custom Resource
(`Array[TilePlacement]`) is fragile and easy to get subtly wrong with no
immediate feedback. A `.gd` script doing the same job is validated by
Godot's own script compiler on load (a typo is a parse error, not a
silently-wrong resource), is easier to review as a diff, and is exactly
as data-only as a `.tres` would be — it sets properties and does nothing
else. `LevelData` remains a genuine `Resource` subclass, so nothing about
this blocks a future Milestone 3 level editor from emitting real `.tres`
files instead; `LevelManager.get_level()` only depends on `load(path).new()`
returning a `LevelData`, which works identically either way.

**Reconsider when:** Milestone 3 (level editor tooling) is built — that
tool can standardize on whichever format is easier to author from a GUI.

### D2 — Star thresholds: 3★ ≤ optimal, 2★ ≤ optimal+2, else 1★

**Why:** The brief requires "a clear deterministic threshold" without
specifying one. A flat `+2` move margin (rather than a percentage of
optimal) was chosen because Milestone 1's optimal move counts are small
(1–3), where a percentage margin would round to confusing or zero-width
bands (e.g. 20% of 1 move rounds to nothing). A flat margin stays legible
at small move counts and is trivial to re-tune later
(`LevelManager.TWO_STAR_MOVE_MARGIN`) as real level data grows.

**Reconsider when:** Real campaign levels (Milestone 4) have much larger
optimal move counts, where a flat `+2` may feel too strict or too lenient
— a hybrid (`max(2, ceil(optimal * 0.5))`) might read better then.

### D3 — `scripts/resources/` added as a new top-level scripts folder

The brief's suggested tree doesn't include this folder.

**Why:** `LevelData` and `TilePlacement` are Resource *types*, not
gameplay logic and not manager logic — they don't belong under
`scripts/gameplay/` (which is beam/tile/grid *behavior*) or
`scripts/managers/` (autoload singletons). A dedicated `resources/`
folder keeps the type definitions easy to find and signals "this is a
data schema, edit with care" distinctly from behavior code.

### D4 — Tile visuals use procedural `_draw()`, no textures

**Why:** No art assets exist yet (explicitly out of scope for Milestone
1). Procedural drawing means zero placeholder texture files to manage,
and it structurally guarantees gameplay logic can't accidentally start
depending on a specific texture's presence — swapping in real art later
is purely additive (replace `_draw()` with a `Sprite2D`/`TextureRect`)
and touches no gameplay script.

### D5 — Mirror rotation toggles between exactly two states (`/` and `\`)

The brief's Part 6 only describes two orientations, so a tap always
toggles SLASH ↔ BACKSLASH. There's no 4-state (90°-increment) rotation
model, since a simple mirror only has two meaningfully different
reflection behaviors regardless of visual angle.

**Reconsider when:** A future mechanic (e.g. a "double mirror"/prism)
needs more than 2 orientations — that would be a new tile type, not a
change to how `MirrorTile` rotates.

### D6 — GridManager holds no autoload references

**Why:** Keeping `grid_manager.gd` (and everything it owns —
`LaserSystem`, `GridTypes`, `TileVisual` subclasses) free of any
dependency on `SaveManager`/`LevelManager`/`GameManager` means the entire
puzzle-solving core can be instantiated and driven headlessly in a test
script with zero setup. This was validated directly in Milestone 1 (see
`TEST_PLAN.md`'s automated section) and should be preserved — if a future
change makes `GridManager` need save/progression data, pass it in as a
parameter rather than reaching for the autoload.

### D7 — `--headless --script` custom main-loop mode cannot see autoloads

Discovered while building Milestone 1's automated tests: running
`godot --headless --script some_test.gd` (where `some_test.gd extends
SceneTree`) fails to compile any reference to `SaveManager`,
`LevelManager`, or `GameManager` with "Identifier not found," even though
`project.godot`'s `[autoload]` section is correctly configured and
`--path` points at the right project.

**Why this matters:** Don't waste time re-diagnosing this later — it's a
property of Godot's custom-main-loop headless mode, not a bug in this
project. Autoload-dependent code must be tested either by running the
actual project headless (`godot --headless --path .`, which does
initialize autoloads normally) or manually in the editor. Pure-logic code
with no autoload dependency (D6 is what makes this possible for the
laser/grid core) can still be fully unit-tested via `--script` mode.

### D8 — `run/main_scene` set to `scenes/ui/main_menu.tscn`

Straightforward, but recorded because `project.godot` shipped with no
main scene configured before Milestone 1.

### D9 — Android export required two `project.godot` fixes, found only by exporting

While preparing the Milestone 1 Android debug build:

- `rendering/textures/vram_compression/import_etc2_astc=true` had to be
  added — Godot's Android exporter refuses to export at all without it
  (a clear, actionable configuration error, not a silent failure).
- `display/window/handheld/orientation` had been set to the **string**
  `"portrait"` since Milestone 1's initial implementation. This is
  actually an **int** enum property (`1` = portrait, `0` = landscape,
  etc.) — the string silently fell back to the type's default (`0` =
  landscape) with no warning anywhere, including in desktop testing
  (desktop windows have no orientation lock, so a wrong orientation
  setting has no visible desktop symptom).

**Why this matters going forward:** don't trust that a `project.godot`
value "looks right" just because it reads naturally (`"portrait"` reads
correctly to a human but was wrong to the engine). If a `[display]` or
similar enum-backed setting is ever hand-edited again instead of through
the editor's Project Settings UI, verify the actual effect — for
orientation specifically, the only reliable check found was exporting an
Android build and inspecting the generated `AndroidManifest.xml`
(`aapt2 dump xmltree ... --file AndroidManifest.xml`, look for
`screenOrientation`), since neither the desktop editor nor headless
`--import` catches a type-mismatched-but-parseable value like this.

## Mobile UI polish (post-Android-device-test)

### D10 — Project UI units are ~3x Android dp; touch targets/margins sized accordingly

**Context:** physical-device testing found the Back/Reset buttons too
small to comfortably tap and every top/bottom HUD element pressed too
close to the screen edge, despite the numbers used (24px margin, 64px
button height) looking reasonable as raw values. Desktop testing never
surfaced this because a mouse pointer has no minimum comfortable target
size and desktop windows aren't edge-sensitive the way a phone body is.

**Root cause:** this project's reference canvas is 1080x1920
(`project.godot`'s `window/size/viewport_*`) with `canvas_items` +
`expand` stretch. A 1080px-wide reference matches the extremely common
Android "xxhdpi" convention: a 360dp-wide screen at 3x density
(`1080 = 360 * 3`). That means **1 unit in this project's UI is
approximately 1/3 of an Android dp**, not 1 dp and not 1 real device
pixel. A 64px button is only ~21dp tall — well under any mobile
guideline's minimum (Material Design and iOS both recommend 44-48dp
minimum touch targets). A 24px margin is ~8dp — imperceptibly thin.

**Decision:** introduced `scripts/ui/ui_constants.gd` (`class_name
UIConstants`) with two shared constants, both derived from this ~3x
conversion:
- `MIN_TOUCH_TARGET = 144` (48dp * 3, the low end of the recommended
  44-56dp touch-target range)
- `BASELINE_MARGIN = 96` (32dp * 3, the middle of a 24-40dp safe-margin
  range)

Every interactive control across Main Menu, Level Select, Settings,
gameplay HUD, and the Level Complete popup was raised to at least
`MIN_TOUCH_TARGET` in its constrained dimension. Every top-level screen's
outer margin now comes from `SafeAreaMargin` (see D11) using
`BASELINE_MARGIN` as its floor.

**Caveat:** the 3x/xxhdpi assumption is a reasonable default, not a
guarantee — a device with a genuinely different density-to-resolution
ratio will get a slightly different effective dp size. This is why
`BASELINE_MARGIN` is a floor, not the final value: `SafeAreaMargin` (D11)
widens it further using the OS's own real safe-area report when running
on Android, which self-corrects for the actual device regardless of this
assumption.

**Reconsider when:** if real-device testing across several different
phones shows targets still feel inconsistent, consider querying
`DisplayServer.screen_get_dpi()` directly to compute an exact dp
conversion per-device instead of relying on the fixed 3x assumption. This
was deliberately not done in this pass to keep the change scoped to
"fix the reported problem," not "rebuild the UI scaling model."

### D11 — Real Android safe-area querying, gated to Android only, with a hard fallback

Added `scripts/ui/safe_area_margin.gd` (`class_name SafeAreaMargin`, a
`MarginContainer` subclass) as the one place every screen gets its outer
margin from. It always applies `UIConstants.BASELINE_MARGIN` on every
platform, and on Android additionally widens each edge using
`DisplayServer.get_display_safe_area()` compared against
`DisplayServer.screen_get_size()` — this is Godot 4.7.1's real OS-level
safe-area/cutout query (confirmed present via `ClassDB.class_get_method_list`
against the actual installed engine rather than assumed from memory).

**Why gated to Android (`OS.get_name() == "Android"`) instead of used
everywhere:** `get_display_safe_area()`'s meaning on desktop platforms
(multi-monitor setups, windowed vs. fullscreen) is not something this
project needs or has verified is meaningful — using it unconditionally
risked producing bogus large margins on desktop for no benefit, since
desktop already validated fine without it. Scoping it to the platform
that actually has notches/cutouts/gesture-nav bars is the conservative,
correct choice.

**Why the extra scale-factor calculation:** the raw safe-area rect from
`DisplayServer` is in real device pixels, but this project's UI layout
math (per D10's `canvas_items` stretch mode) operates in a
resolution-independent reference space that isn't necessarily 1:1 with
real pixels. `SafeAreaMargin` measures the actual runtime ratio
(`get_viewport().get_visible_rect().size.x / DisplayServer.screen_get_size().x`)
rather than assuming a fixed formula, so the conversion is correct
regardless of the specific device's resolution or aspect ratio.

**Documented limitation (per the brief's explicit instruction not to
fake unimplemented support):** this has been validated by reading the
engine's exposed API surface and by reasoning about the math, but **not
yet validated on a physical device with an actual notch/cutout/rounded
corner**, because the device used for Milestone 1's Android testing may
not have one prominent enough to distinguish "safe-area-aware" from
"baseline-margin-only" behavior. Until a device test specifically
confirms this, treat the Android-safe-area-widening behavior as
implemented-but-unverified, and the flat `BASELINE_MARGIN` fallback as
the only *confirmed* behavior. See `TEST_PLAN.md`'s Android device test
section.

## Milestone 2 — Advanced Puzzle Mechanics

Milestone 2 evolved `LaserSystem` from a single-beam, single-pass
simulator into a multi-beam, multi-pass one, and added six new tile
types (splitter, filter, portal, switch, gate, hazard) plus beam colors
and multiple targets/emitters. See `ARCHITECTURE.md`'s rewritten "Laser
propagation algorithm" section for the mechanics; this section is the
*why* behind each choice.

### D12 — Tile data model stays one flat `TilePlacement`, not per-type Resource subclasses

The brief's Part 14 explicitly allows "cleaner specialization" if the
architecture supports it. Milestone 2 still uses one flat
`TilePlacement` class with every tile type's fields as optional members
(`color`, `required`, `pair_id`, `gate_id`, `initial_open_state` were
added alongside Milestone 1's `direction`/`mirror_orientation`/
`rotatable`), rather than splitting into `SplitterPlacement`,
`PortalPlacement`, etc.

**Why:** GDScript doesn't support keyword/named constructor arguments,
so per-type subclasses would still need either a long positional
constructor (exactly the "irrelevant properties" ergonomics problem the
brief warns about) or the same static-factory pattern this milestone
already uses. A single flat class with static `make_*()` factories
(`TilePlacement.make_switch(pos, gate_id)`, `TilePlacement.make_portal(pos,
pair_id)`, etc.) gets the same authoring ergonomics as subclassing would,
without ten small Resource files to keep in sync with `GridTypes.TileType`,
and without `LaserSystem`/`GridManager` needing `is` checks or casts to
work with a specific tile's data. Each factory's signature documents
which fields matter for that tile type, which is what actually mattered
for the "don't force irrelevant properties" concern.

**Reconsider when:** a future milestone's level editor (Milestone 3)
might prefer per-type Resources for a nicer Inspector-driven authoring
UI - that's a tooling concern, not a simulation one, and wouldn't need
`LaserSystem` to change since it already only reads whichever fields are
relevant per `tile_type`.

### D13 — Old raw `TilePlacement._init(...)` constructor removed; all levels use factories

Milestone 1's 5 levels used a positional `TilePlacement.new(tile_type,
position, direction, mirror_orientation, rotatable)` constructor. That
constructor is gone - replaced entirely by the `make_*()` factories (D12).
All 5 Milestone 1 level files were rewritten to use them.

**Why safe:** level files are project-authored code, not user data - a
mechanical rewrite that preserves identical field values is safe to
verify by re-running the exact same solvability tests. This was done:
see `TEST_PLAN.md`, all 5 levels still solve in their documented
`optimal_moves` through the rewritten `LaserSystem`.

### D14 — Beam color model: `WHITE` is neutral on both ends

`GridTypes.BeamColor` is `{WHITE, RED, GREEN, BLUE}`. `WHITE` plays two
roles simultaneously:
- **As an emitter's color:** the default - Milestone 1 emitters never set
  a color, so they're `WHITE`.
- **As a target's `required_color`:** *accepts any beam color*, not just
  `WHITE` beams. See `GridTypes.target_accepts_color()` - the single
  centralized rule: `required_color == WHITE or required_color == beam_color`.

**Why:** this is what makes Milestone 1's targets (which never set a
required color, so default to `WHITE`) keep working completely unchanged
- they accept the default `WHITE` beam trivially, and the exact same rule
also lets a level designer place a genuinely color-agnostic target among
colored ones without a separate "ANY" sentinel value. One enum value, one
rule, two backward-compatible defaults (emitter defaults to firing it,
target defaults to accepting it).

**Reconsider when:** if a future mechanic needs beams to *combine*
colors (e.g., RED + BLUE beams overlapping), `WHITE` may need to stop
doubling as "neutral" and become a real additive-mixing result - the
brief explicitly excludes "advanced optical beam merging" from Milestone
2, so this wasn't a live concern here.

### D15 — Splitter rule: straight-through is unconditional, branch reuses `GridTypes.reflect()`

A splitter tile always sends one beam straight through (direction
unchanged, independent of the splitter's orientation) and one branch beam
reflected via the *exact same* `GridTypes.reflect(dir, orientation)`
function mirrors use. `MirrorOrientation` (`SLASH`/`BACKSLASH`) is reused
directly for splitter orientation - no new orientation enum.

**Why this specific rule (the brief allowed picking a "cleaner" design if
justified):** reusing `reflect()` means the splitter's branch behavior is
governed by the identical, already-tested truth table as mirrors - zero
new reflection logic to get wrong, and a player who has learned how
mirrors bend a beam already understands half of what a splitter does.
"Straight continues unconditionally" was chosen over "straight also
depends on orientation" because it gives the splitter a stable, easy-to-
reason-about half (I can always count on the straight branch existing
predictably) while still requiring rotation-based planning for the other
half - this is what Test Levels 7 and 14 rely on pedagogically (the
straight branch's target is "free," the branch's target requires solving).

**Rotatable/fixed:** splitters reuse `TilePlacement.rotatable` exactly
like mirrors (D-none-new-needed) - a fixed splitter simply never emits
`tile_clicked`, identical mechanism to a fixed mirror.

**Visual distinctness (per the brief - "do not reuse mirror visuals as
authoritative logic"):** `SplitterTile` (`scripts/gameplay/splitter.gd`)
is its own class with its own `_draw()`, not an instance of `MirrorTile`
- the *interaction pattern* (tap-to-toggle-orientation, same signal
shape) is intentionally shared code style, but the class, the visual, and
the simulation logic are all fully separate from mirrors.

### D16 — Filter rule: unconditional recolor, orientation-independent

A filter has one `color` field. Any beam passing through it becomes
that color, full stop - no dependency on incoming color, incoming
direction, or any orientation (filters have no orientation field at all).

**Why:** the brief explicitly recommended this ("Keep this deterministic
and easy to understand... do not implement complicated optical physics"
and "Filter orientation should not matter unless a technical reason
requires it") - no technical reason emerged to deviate. A filter reads
as "paint the beam this color," which is the simplest possible correct
mental model.

### D17 — Portal direction/color behavior: fully preserved, no portal orientation

A beam entering one portal of a pair exits the other at the *same
direction and same color* it entered with. There is no portal
`orientation` field - `TilePlacement.pair_id` is the only portal-specific
field.

**Why:** the brief explicitly recommended "preserve beam direction unless
portal orientation explicitly changes it" and "keep color unchanged" -
no puzzle in this milestone's 10 test levels needed direction-changing
portals, so the simpler (zero-orientation-field) design was kept. This
keeps portals conceptually different from mirrors/splitters (a portal
is "the same beam, continuing, just relocated," not "a beam that gets
redirected") which is a clean, learnable distinction for players.

**Fail-safe pairing (brief's explicit requirement):** `LaserSystem`
groups `PORTAL` tiles by `pair_id` and only treats a pair as functional
if it has **exactly 2** members; 0, 1, or 3+ members sharing a `pair_id`
makes every portal cell in that group inert (behaves like an empty
cell) rather than crashing or guessing. This was exercised directly in
automated testing (a single unpaired portal; see `TEST_PLAN.md`).

**Rendering (brief's explicit requirement):** a portal transit starts a
new `Line2D` segment rather than continuing the current one, so the
visual never draws a straight line across the teleport distance. See
`ARCHITECTURE.md`'s "Laser visualization" and D-tile-data below for the
`segments` (not flat `points`) beam representation this required.

### D18 — Switch/gate simulation: multi-pass, monotonic, fully stateless between simulate calls

This is the most structurally significant decision in Milestone 2. Full
mechanics in `ARCHITECTURE.md`; the reasoning:

**The rule:** `LaserSystem.simulate()` runs exactly one pass: every
emitter's beam(s) computed with gate open/closed state *fixed* for the
whole pass. A switch hit during a pass is recorded but does **not**
affect that same pass's gate behavior. `LaserSystem.simulate_until_stable()`
wraps this: after each pass, any gate whose linked switch(es) were hit
gets marked open (gates only ever go closed -> open, **never** open ->
closed, within a stabilization run), and the whole simulation re-runs
from scratch with the updated gate states. This repeats until a pass
changes nothing (stable) or a generous pass-count backstop is hit.

**Why monotonic (closed -> open only, one direction) rather than allowing
gates to re-close:** the brief explicitly says "do not allow infinite
state oscillation" and "do not implement toggling repeatedly unless
necessary." Monotonic state change makes termination trivially provable
- a gate can change state at most once per stabilization run, so with N
gates, stabilization is guaranteed within N+1 passes (the "+1" for the
final confirming pass that changes nothing). `simulate_until_stable()`'s
actual cap is `(gate_count + 1) + 8` - the `+8` is pure defensive margin
for a future bug, not something correctness depends on.

**Why gates/switches are NOT persisted in `GridManager` across player
moves (this is the "stateless" part):** every call to
`simulate_until_stable()` starts every gate at its level-data
`initial_open_state` and re-derives everything from scratch based on the
*current* mirror/splitter configuration. A switch that was hit five
moves ago, whose beam path has since been rotated away, does **not**
keep its gate open. This was a deliberate simplification beyond what the
brief strictly required (it only specifies the pass mechanism, not
whether state persists across separate player actions):
- It makes Reset trivial and correct "for free" - restoring
  `tile_orientations` to level data (already Milestone 1 behavior)
  automatically restores gate/switch state too, since it's entirely
  derived from the mirror/splitter configuration. No new reset code was
  needed for Part 18's "gate initial states" or "switch inactive state"
  requirements.
- It avoids a whole category of confusing-puzzle and stale-state bugs
  (players wondering "why is this gate open, I haven't touched anything
  near that switch recently") that a persistent/history-dependent model
  would invite - consistent with the brief's explicit exclusion of
  "timed switches" and general caution against unnecessary statefulness.
- It matches "Prefer deterministic one-pass[-family] puzzle logic":
  every simulate call is a pure function of `(level_data,
  tile_orientations)` - nothing else, not even implicit history.

**Reconsider when:** a future milestone wants switches that must be
"held" or a puzzle mechanic that depends on move order/history - that
would be a deliberate, documented departure from this stateless model,
not an incremental change to it.

### D19 — Hazard rule: absorbs the beam, blocks "solved," never blocks play

A beam entering a `HAZARD` cell stops there (identical to a blocker) and
sets `hazard_hit = true` for that pass. `LaserSystem`'s `solved`
computation is `required_count > 0 and required_activated >= required_count
and not hazard_hit` - a hazard hit overrides an otherwise-complete
target set. Critically, `GridManager.is_solved` (which gates further
player interaction) only ever becomes `true` when `solved` is `true`, so
a hazard hit **never disables player input** - exactly the brief's
explicit requirement ("The player should be able to continue modifying
the puzzle rather than receiving a hard game-over screen").

**Why the beam is absorbed (stops) rather than passing through:** a
hazard that didn't stop the beam couldn't sensibly be "avoided by
routing around it" (Test Level 12's whole premise) - if the beam passed
through unaffected, there'd be no way to build a level where the
"naive" path visibly fails and a rerouted path visibly succeeds, which
is the same pedagogical pattern Milestone 1 established for blockers.

### D20 — Multi-emitter/multi-beam processing: explicit work-queue, not recursion, shared loop-protection state

The brief explicitly asked for "a queue/stack/list of active beam states
rather than recursion." `LaserSystem.simulate()` uses a plain GDScript
`Array` as a LIFO work list: each emitter seeds one beam state, and a
splitter encountered mid-flight pushes a second beam state onto the same
list rather than recursing into a helper function. Processing order
(which beam branch gets stepped first) does not affect the final result,
only intermediate bookkeeping order - so a stack (pop from the back) was
used for simplicity, not because ordering is semantically load-bearing.

**Loop protection scope:** `visited_states` is a single dictionary shared
across **every** beam branch and **every** emitter within one pass, keyed
on `(position, direction, color)`. Board state (gate open/closed,
mirror/splitter orientation) doesn't need to be part of the key because
it's fixed for the entire pass - so `(position, direction, color)` fully
determines a beam's future path, meaning it's not just safe but
*correct* to terminate a branch the instant it revisits a state any
branch (including a different emitter's) already reached: from that
point on its path is identical to whatever already happened. This was
verified to still catch the exact closed-loop geometry proven in
Milestone 1 (see `TEST_PLAN.md`), confirming the rewrite didn't weaken
the guarantee, plus a separate `MAX_STEPS` hard backstop (20000) exists
purely as defense-in-depth, not as the actual termination argument.

### D21 — Beam representation changed from flat `points` to `segments` (a list of polylines)

Milestone 1's `LaserSystem.simulate()` returned one flat `Array[Vector2i]`
of turn/start/end points per beam. Milestone 2 returns
`Array[Array[Vector2i]]` ("segments") per beam, because a portal transit
must start a *new* segment rather than continuing the current polyline
(see D17/the brief's explicit rendering requirement). `GridManager`
draws one `Line2D` pair per segment instead of one pair per beam.

**Backward compatibility:** Milestone 1 levels have no portals, so every
beam they produce has exactly one segment - visually and behaviorally
identical to Milestone 1's rendering, just wrapped in one extra list
layer. Confirmed by the automated scene-level puzzle-grid test in
`TEST_PLAN.md`.

### D22 — Beams now continue *through* an activated target

Milestone 1's beam stopped the instant it reached a target. Milestone 2's
beam continues past a target after recording its activation (still
recording a visual bend point there) - this is what lets Test Level 6
activate two required targets with a single beam, and is necessary in
general for "multiple required targets" (Part 3) to be satisfiable
without requiring a splitter or multiple emitters for every multi-target
level.

**Backward-compatibility check performed:** all 5 Milestone 1 levels
were re-traced by hand to confirm this change never alters their
`solved` outcome (in every case, the cell immediately past that level's
target was either the grid edge or already-empty space with no further
tiles) - the only visible effect is Level 4's beam now draws one extra
harmless segment to the grid edge after its target. See `ARCHITECTURE.md`
for the full re-verification note.

## Milestone 3 — Level Editor + Puzzle Validation + Difficulty Tooling

### D23 — Editor architecture: a normal runtime scene, not an EditorPlugin

The brief offered two options: (A) an `@tool`-based EditorPlugin/dock
integrated into the Godot editor UI, or (B) a dedicated development-only
scene. **Chosen: (B)** — `tools/level_editor/level_editor.tscn` is an
ordinary Godot scene with an ordinary (non-`@tool`) script. A developer
opens it and presses F6 ("Run Current Scene") to use it, exactly like
running any other scene during development - it is never the project's
`run/main_scene` and ships no dock/panel inside the Godot editor itself.

**Why, weighed against the brief's explicit requirements:**
- *"Must not complicate Android runtime builds"* — a plain scene has zero
  interaction with `EditorInterface`, `EditorPlugin`, or any editor-only
  API, so there was never a risk of it needing editor-only code paths
  that could leak into an export. (It's still excluded from the export
  filter as an extra precaution - see D24 - but architecturally it
  wouldn't have broken the build even if included.)
- *"Must not make the game depend on editor-only APIs"* — trivially true
  for the same reason; the editor scene depends only on the same
  `LevelData`/`TilePlacement`/`LaserSystem`/`GridManager`/tile-visual
  classes the shipped game already depends on, plus three new pure-logic
  tool scripts (`LevelSolver`/`LevelValidator`/`LevelMetrics`) that are
  equally editor-API-free.
- *"Must be maintainable by future Claude sessions"* — an EditorPlugin
  requires understanding Godot's plugin registration
  (`plugin.cfg`, `EditorPlugin.enable_plugin`, dock injection,
  `_enter_tree`/`_exit_tree` lifecycle) on top of everything else; a
  plain scene requires understanding nothing beyond what every other
  scene in this project already requires. Given this project's actual
  complexity budget (a solo/small-team indie project with Claude-session
  handoffs as the primary continuity mechanism), the lower-ceremony
  option was judged safer to hand off correctly.
- *"Must use the existing LevelData/TilePlacement model where practical"*
  and *"must not duplicate the authoritative LaserSystem"* — both are
  satisfied identically regardless of which architecture was chosen;
  this wasn't a deciding factor between A and B.

**What was reused vs. added:** the editor reuses `LevelData`,
`TilePlacement` (including its `make_*()` factories), `GridTypes`, and
`LaserSystem` completely unchanged. It adds three new pure-logic classes
under `scripts/tools/` (solver, validator, metrics - deliberately
*not* under `scripts/gameplay/`, to keep "things the shipped game touches
during normal play" and "development-only analysis tooling" visually
separated in the directory tree) and the editor UI itself under
`tools/level_editor/`.

**Reconsider when:** if this project ever gains a second or third human
level designer working concurrently, an EditorPlugin's tighter Godot-
editor integration (in-place Inspector editing, a persistent dock instead
of a separate running scene) might become worth the added complexity.
Not the case yet.

### D24 — Editor tooling excluded from the Android export

`export_presets.cfg`'s `exclude_filter` was extended to
`tools/**,scripts/tools/**,levels/editor_fixtures/**`. Nothing in the
editor is unsafe to ship (see D23 - no editor-only APIs), but it's also
pure dead weight in a player-facing build: none of `game.gd`,
`grid_manager.gd`, or any autoload ever references `LevelSolver`,
`LevelValidator`, `LevelMetrics`, or the editor scene, so excluding them
costs nothing functionally and keeps the shipped APK from carrying
development-only code and fixture levels a player could never reach
anyway. Re-exporting after this change was verified to still produce a
working, correctly-oriented APK (see `TEST_PLAN.md`) - this is a build-
configuration change, not a code change, so the regression risk was
"does the filter syntax work," which was confirmed by a successful
export, not "does gameplay still work," which was already covered by the
full regression suite run beforehand.

### D25 — Level editor persistent format: `.tres`, loaded alongside the existing `.gd` levels (not a migration)

The brief was explicit: prefer `.tres` if safer, but do not blindly
migrate, and preserve/maintain compatibility with Levels 1-15.
**Decision:** the editor's Save/Load always uses `.tres`
(`ResourceSaver.save()` / `load()`), and `LevelManager.get_level()` was
extended to accept *either* format transparently
(`LevelManager.load_level_from_path()` checks whether `load()` returned
a live `LevelData` instance directly - the `.tres` case - or a
`GDScript` needing `.new()` - the existing `.gd` case). **Levels 1-15
were left completely untouched, still `.gd` files.**

**Why `.tres` is actually practical now, when it wasn't for Milestone
1** (see D1): Milestone 1's `.tres` rejection was specifically about
*hand-authoring* a Resource text file being fragile and easy to get
subtly wrong with no immediate feedback. That concern doesn't apply here
at all - the editor UI is now the thing producing `LevelData` instances
through ordinary Godot UI interactions (clicking cells, editing fields),
and `ResourceSaver.save()` serializes whatever `LevelData`/
`TilePlacement` object graph already exists correctly by construction.
There's no hand-typing of Resource text syntax anywhere in this flow.

**Verification performed, not just asserted:** a full save → load
roundtrip was automated (see `TEST_PLAN.md`) confirming every field -
including nested `Array[TilePlacement]` sub-resources, enums, and
booleans - survives serialization intact, and that a roundtripped level
still validates and solves identically to before saving.

**Why not migrate Levels 1-15 to `.tres` anyway, now that it works
fine:** no technical reason requires it, and the brief explicitly warns
against blind migration. They remain a working, previously-validated
asset; touching them for a purely cosmetic format change would be
scope creep with nonzero regression risk for zero player-facing benefit.
A future session doing bulk campaign authoring may reasonably choose to
author new levels as `.tres` (via the editor) while leaving the original
15 as-is indefinitely - both formats are first-class as far as
`LevelManager` is concerned.

### D26 — Solver algorithm: breadth-first search over the rotatable-piece orientation bitmask, using the real LaserSystem as the state evaluator

**State space:** each rotatable mirror/splitter has exactly two possible
orientations (`SLASH`/`BACKSLASH` - identical to the real in-game
toggle), so a level with N rotatable pieces has a state space of exactly
2^N board configurations, each directly addressable as an N-bit integer
bitmask (`LevelData.get_rotatable_tiles()`'s array order defines which
bit is which piece - stable and deterministic). A "move" is flipping
exactly one bit, matching the real game's move semantics exactly (one
tap = one orientation flip = one move).

**Why BFS specifically:** every move has identical cost (1), so the
shortest path in an unweighted graph is exactly what BFS finds, and BFS
explores in strict non-decreasing depth order - meaning the moment any
solved state is found, every other solved state discovered before the
*next* depth increment is also guaranteed optimal-length. This is what
makes both "the optimal move count" and "how many distinct shortest
solutions exist" (Part 15) fall out of the same search almost for free,
without a second pass: the implementation processes one full BFS
"layer" (all states at a given depth) before deciding whether to stop,
collecting every solved state found in that layer as a shortest
solution, then stops - deeper layers cannot contain anything shorter.

**Never a second/approximate simulator:** every candidate state is
evaluated by calling the real `LaserSystem.simulate_until_stable()` -
the solver contains zero beam-propagation logic of its own. This was
an explicit, non-negotiable requirement in the brief and is also just
good engineering: a second approximate simulator would inevitably drift
from the real one's behavior as new mechanics are added.

**Loop protection reuse:** because each candidate state is a full,
independent `simulate_until_stable()` call, the solver automatically
inherits `LaserSystem`'s own loop protection for free - a candidate
board configuration that would cause a beam cycle simply returns
`looped: true` from that one call and is treated as "not solved," never
as a search hang. The solver's *own* possible hang risk (exploring an
enormous state space) is a completely separate concern, handled by D27.

### D27 — Solver search-limit strategy

`LevelSolver.DEFAULT_MAX_STATES = 65536` (2^16) - exhaustive for any
level with up to 16 rotatable pieces, which comfortably covers every
hand-authored level built so far (the densest, Level 15, has 2
rotatable pieces; the search-limit fixture level deliberately inflates
this to 9 for testing purposes and still resolves in a fraction of a
second - see `TEST_PLAN.md`).

**Three-way result, not two-way:** the brief was explicit that a search-
limit hit must never be reported as "unsolvable" - these are genuinely
different claims (`UNSOLVABLE` = the entire reachable state space was
exhausted with no solution found, a proven negative; `UNKNOWN` = the
search ran out of budget before finishing, no claim either way). The
implementation tracks this by checking whether the state-count limit was
hit *before* deciding the final status, never inferring "unsolvable"
from "the loop ended." Verified with a dedicated automated test that
deliberately passes an unrealistically small `max_states` against an
otherwise-solvable level and confirms `UNKNOWN` is reported, not a false
`UNSOLVABLE` (see `TEST_PLAN.md`).

**Why a flat constant instead of a dynamic budget (e.g., based on
piece count or a wall-clock time limit):** simplicity and predictability
for a development-only tool where the person running it can always pass
a larger `max_states` explicitly (the parameter is exposed on
`LevelSolver.analyze()`) if a specific level genuinely needs it - this
has not been necessary for any level built so far. A wall-clock-based
budget was considered but rejected: it would make results
non-reproducible run-to-run on machines of different speeds, which
matters for a tool whose whole purpose is giving a level designer a
trustworthy, repeatable answer.

### D28 — Difficulty heuristic: transparent, additive, explicitly non-authoritative

`LevelMetrics._estimate_difficulty()`:

```
score = (optimal_moves * 2.0)
      + (rotatable_piece_count * 1.5)
      + (distinct_mechanics_used_count * 3.0)
      + (2.0 if grid_area > 25 else 0.0)

score <= 3   -> TUTORIAL
score <= 7   -> EASY
score <= 13  -> MEDIUM
score <= 20  -> HARD
else         -> EXPERT
```

"Mechanics used" counts each of {mirrors, splitter, colored beams,
filters, portal, switch/gate, hazard, multiple emitters, multiple
targets} present at least once - not how many *instances* of each, just
how many distinct kinds of interaction the player has to reason about,
directly reflecting Part 26's philosophy (difficulty should come from
*combining* mechanics, not from piling up instances of one).

**Why grid size only contributes a small, capped bonus (not a linear
term):** this is the heuristic's most deliberate design choice, directly
implementing the brief's Part 26 ("The final BeamShift campaign should
NOT become difficult merely because grids get bigger... difficulty
should come from reasoning"). A bigger grid with the same puzzle logic
gets, at most, a flat +2 - it cannot dominate the score the way move
count, piece count, and mechanic diversity can.

**Explicitly not authoritative:** the label is always shown alongside
the raw metrics it was computed from, is documented everywhere it
appears as "(estimate)"/"(heuristic only)," and nothing in the codebase
treats it as a gate or requirement. This is intentional - see the
brief's Part 19 ("do not treat the label as authoritative... allow human
level-design judgment to override it").

**Reconsider when:** once Milestone 4 produces real campaign levels
across all 10 planned stages, this formula's thresholds/weights should
be recalibrated against actual human playtesting data rather than the
15 dev/regression levels it was tuned against so far (which were
designed to each demonstrate one mechanic in isolation, not to represent
the campaign's real difficulty curve).

### D29 — Test-level vs. campaign-level separation

Levels 1-15 remain exactly where they are (`levels/level_01.gd` ...
`level_15.gd`, referenced by `LevelManager.LEVEL_PATHS`) and are now
explicitly documented (in `CURRENT_STATUS.md`, `PROJECT_HANDOFF.md`, and
each file's own header comment) as **development/regression test
levels** - they exist to exercise mechanics and to regression-test the
simulator, editor, and solver, not as the final campaign. They are not
deleted or hidden, and `LevelManager`/`LevelSelect` still show all 15 to
players (per the Milestone 2/3 briefs' explicit instruction not to
redesign Level Select).

**Future campaign levels** will live under a new `levels/campaign/`
directory (created empty this milestone, as a documented seam - see
`ROADMAP.md`) once Milestone 4 begins authoring them, keeping the two
populations physically separate in the filesystem even though
`LevelManager` could technically point at either or both. `LevelData`'s
new `is_campaign_level` field (D-added alongside `stage`/
`developer_notes` - see the editor metadata fields) exists so a level's
own data self-identifies its intended population regardless of which
directory it physically lives in, for whenever a future milestone needs
to filter/group by that distinction programmatically.

**Editor fixtures** (`levels/editor_fixtures/*.gd`) are a *third*,
separate population: deliberately-broken or edge-case levels
(unpaired portal, dangling switch reference, trivial solution,
unsolvable, multiple solutions, search-limit stress) that exist purely
to validate the validator/solver themselves. They are never referenced
by `LevelManager.LEVEL_PATHS` and are excluded from the Android export
(D24) - a player can never reach them through any code path.

### D30 — Why the final campaign stays handcrafted (no procedural generation)

The brief explicitly prohibits building a random level generator this
milestone (Part 27), and the solver/validator/analyzer tooling was
deliberately designed as *assistive* infrastructure for a human designer
- not as a step toward generation. Concretely: `LevelSolver` verifies and
measures a level a human already designed; it has no "propose a layout"
capability, and none was added. This mirrors Part 26's difficulty
philosophy directly - genuinely interesting difficulty in this game comes
from misleading routes, decoys, color/gate/portal dependencies, and
multi-step reasoning, which are exactly the kind of intentional,
narratively-aware design choices a procedural generator would have no
principled way to make. The tooling exists to make handcrafting faster
and more confident (instant validation, a proven optimal-move count, a
difficulty ballpark), not to replace the designer.

## Milestone 4A — Final Asset Integration

The user's kickoff for this milestone called it "Milestone 4A" and scoped
it strictly to visual integration (no puzzle logic, no campaign levels).
Content-wise this is what `ROADMAP.md` had already planned as "Milestone
5 — Final Visual Assets, UI Polish, VFX, Audio" (audio wasn't touched -
still out of scope, no audio assets were provided). `ROADMAP.md` is
updated to note this naming reconciliation rather than silently
renumbering history.

### D31 — Two unreconciled art generations found; one picked as canonical, baked-beam tiles stay procedural

On inspection, `assets/gameplay/` already contained **two independently-
generated PNG sets** for every tile type (`assets/gameplay/<type>/` and
`assets/gameplay/pieces/`), with different filenames in places
(`filter` vs `color_filter`) and no documentation saying which was meant
to ship. Every file was opened and visually inspected before any
integration decision was made.

**Canonical set:** `assets/gameplay/<type>/bs_tile_*.png` (the
folder-per-type set) for every tile that has one, **except** blocker and
hazard, which use `assets/gameplay/pieces/` specifically because that
set's versions were confirmed beam-free and the folder-per-type set's
versions weren't separately vetted (no reason to risk a re-check when a
confirmed-clean alternative already existed). `assets/gameplay/pieces/**`
and `assets/gameplay/tiles/**` are excluded from the Android export
filter rather than deleted, so a future session can still compare them.
Same reconciliation for icons: `assets/ui/icons/bs_ui_icon_*.png` (15
files, consistent naming, covers every needed HUD/settings icon) is
canonical over the 3-file `bs_icon_{hint,pause,reset}.png` orphan set,
which is also excluded from export.

**Baked-beam problem, and why 5 of 10 tile types stay procedural:**
pixel inspection found that emitter, splitter, portal, switch, and color
filter all have a fixed-direction (and, for the filter, fixed-color)
illustrative laser beam painted directly into the tile body **in both
generated sets** - not just extending past the edge into empty margin
(which a texture-region crop could have hidden) but painted across the
same pixels as the tile's own body in most cases. CLAUDE.md rule 8 is
explicit that a baked beam must never be used as, or conflict with, the
real gameplay beam; rule 8/9 also treat direction/color as real
simulation data that visuals must respect. A single fixed-direction blue
beam baked into the emitter sprite would be flatly wrong on any level
whose emitter direction or color differs from what's painted in (which
is most of them - see the 15 test levels' varied emitter directions and
Milestone 2's RED/GREEN/BLUE emitters).

No image-editing tool (ImageMagick, PIL/Python) was available in the
environment this milestone was executed in - confirmed by checking
before deciding, not assumed. Without one, there was no reliable way to
crop or mask out a beam painted across a tile's own body pixels (a
rectangular `AtlasTexture` region crop only helps when a beam extends
into otherwise-empty margin, which wasn't the case here for most of
these five). Given that constraint, the decision was to **leave these
five tiles on their existing, already-correct procedural `_draw()`
rendering** rather than ship an asset integration that would be actively
wrong, or attempt an unreliable blind-coordinate crop. All five still
render over the new shared cell-background art (see ARCHITECTURE.md), so
they're not visually orphaned - only the piece glyph itself stays
procedural.

**Reconsider when:** a future session has access to image-editing
tooling (or the user regenerates clean, beam-free source art for these
five specific tile types) - at that point this is a contained,
low-risk follow-up (swap 5 scripts' `_draw()` bodies the same way the
other 5 were converted this milestone), not a redesign.

### D32 — Cell background and layered overlays render via `draw_texture_rect()` inside `_draw()`, not child sprite nodes

Godot renders a `Control`'s own `_draw()` output *before* its children,
regardless of child add-order. A `TileVisual` base class that added a
background `TextureRect` as a child would render that background **on
top of** a subclass's own procedural `_draw()` content (mirror line,
target ring, etc.), which is backwards. Using `draw_texture_rect()`
calls layered within one `_draw()` override (background first via
`super._draw()`, then the tile's own art, then any overlay like the
mirror's lock icon or the target's color ring) guarantees correct paint
order in every case, using the exact same mechanism the pre-existing
procedural tiles already relied on. The only exceptions are the two
Tween-driven feedback pulses (mirror selection, target activation),
which use real child `TextureRect` nodes because a `Tween` animates node
properties (`modulate`, `scale`) - not custom parameters inside a
`_draw()` call - and are added last so they render on top, which is
exactly the desired effect for a flash/pulse overlay.

### D33 — Pause menu built now (explicitly requested); Stage Select deliberately not built (not requested, no existing architecture to re-skin)

The milestone brief explicitly asked for a pause menu to be created this
pass ("Polish/create the pause interface..."), so `scenes/ui/pause_menu.tscn`
is new feature work done in-scope, following the exact presentational-
overlay pattern `LevelCompletePopup` already established (see
ARCHITECTURE.md "Pause menu").

Stage Select was different: the brief hedged it ("integrate...IF the
existing UI architecture supports stages") and the actual architecture
does **not** - no `stage_select.tscn`/script exists, `LevelData.stage` is
inert metadata, and `level_select.gd` is a flat list with no
stage-grouping code at all (confirmed by search before deciding, not
assumed from a doc). Building a Stage Select screen from nothing is a new
navigation flow (Level Select would need to become "pick a stage, then a
level within it"), not a re-skin - out of scope for an asset-integration
milestone per `CLAUDE.md`'s scope-discipline rules, and explicitly not to
be done ahead of Milestone 4B's campaign structure. The 8 stage-select/
stage-complete PNGs are left on disk, unwired, for whenever stage
grouping becomes its own scoped task.

### D34 — Android back button: `quit_on_go_back=false` project-wide, every top-level screen replicates its own Back button via `_notification()`

Godot's default (`quit_on_go_back = true`) makes the Android system back
gesture silently quit the app if nothing handles it - this is what made
gameplay's "should preferably open Pause instead of exiting unexpectedly"
request a real bug to fix, not just a nice-to-have. Disabling the setting
project-wide was necessary (it's the only way to make the notification
interceptable at all) but has a real regression risk: every *other*
screen's Android back behavior would silently change from "does the
same thing the default used to do" to "does nothing," unless each screen
is given an equivalent handler. `main_menu.gd`, `level_select.gd`,
`settings_menu.gd`, and `game.gd` each got a
`_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` override that calls
exactly the same method its own Back/Quit button already calls (Game is
the one exception, which opens/closes Pause instead - the actual point
of this change). This was chosen over the cheaper "handle it only in
game.gd" approach specifically to avoid a silent regression on the three
other screens, at the cost of one small, boilerplate-shaped method per
screen.

### D35 — Icons/buttons themed via a single project-wide `Theme` resource; panels stay per-screen

`themes/beamshift_theme.tres`, set as `project.godot`'s default GUI
theme, gives every `Button` its textured style automatically with zero
per-scene edits - the alternative (hand-styling every Button node in
every `.tscn` with its own `StyleBoxTexture` override) would have meant
touching 15+ Button nodes across 6 scenes for an identical result. A
`DangerButton` theme type variation covers the two "leave/quit" actions
(Main Menu's Quit, Pause's Main Menu) without needing a second full
theme. Panels (Settings/Level Complete/Pause) were deliberately **not**
put in the shared theme, because the three panel background images are
visually distinct assets, not restylings of one shared panel look - a
one-off `StyleBoxTexture` sub-resource directly in each screen's `.tscn`
is simpler and more honest about that than forcing a shared `Theme`
entry to somehow cover three different textures.

### D36 — Button/panel 9-slice margins are a best-effort default, not measured

`StyleBoxTexture.texture_margin_*` values (180px for buttons, ~100-120px
for panels) were chosen as a reasonable fraction of each source image's
dimensions, not measured against the art's actual rounded-corner radius
- no image-viewing/measurement tool was available to inspect exact pixel
boundaries precisely. This is flagged as a manual visual-QA item (see
`TEST_PLAN.md`) rather than asserted as correct; adjusting a stylebox's
margins in the Godot editor's Inspector, visually, is a normal and
expected part of UI polish and takes seconds once someone can actually
see the rendered result.

**Superseded by Milestone 4A.1** - see D37/D38 below. D36's guess turned
out wrong in a way that mattered: the user's manual QA failed the whole
pass, and the actual root causes were found once the art was viewed
directly (D37) rather than reasoned about blind.

## Milestone 4A.1 — UI Integration Correction Pass

Milestone 4A's visual integration **failed the user's manual QA** -
reported as "large raw PNGs placed into scenes without properly
designing the controls around the artwork." This section records the
actual root causes (found by finally looking at the art directly with
the `Read` tool's image support, which was available the whole time but
not used for layout decisions in Milestone 4A - only a subagent had
looked at the art, and only to check for baked beams, not to measure
usable content bounds) and what changed.

### D37 — Root cause: `Button.icon` renders at native texture resolution with no size cap; this single bug cascaded into most of the reported problems

`bs_ui_icon_reset.png` (and every icon like it) is a 1254×1254 PNG.
Milestone 4A's `game.tscn` set it as `ResetButton.icon` on a button whose
`custom_minimum_size` was only 200×144, without `expand_icon` or any
`icon_max_width` constraint. Godot's `Button` does not scale `icon` down
to fit the button by default - it renders at the texture's native pixel
size, overflowing the button's own rect massively (a 1254px-tall icon
inside a 144px-tall button). Since `Button` doesn't clip its own overflow
by default, the icon rendered on top of - and effectively as large as -
a huge portion of the screen, directly above the puzzle grid. This is
almost certainly what the user saw as "Reset graphic is enormous and
covers most of the puzzle board." It also explains "HUD artwork overlaps
the playable area": the oversized icon child inflated `ResetButton`'s
effective content size, which cascaded up through `BottomBarRow` →
`BottomBar` (a `PanelContainer`, which sizes itself to fit its content)
→ the `Layout` `VBoxContainer`, squeezing/distorting the space actually
left for `CenterArea`/the puzzle grid.

**Fix:** every HUD icon (Back, Reset, Pause, Hint) is now a `flat`
`Button` (fixed `custom_minimum_size = Vector2(144, 144)`, matching
`UIConstants.MIN_TOUCH_TARGET` - see D10, not regressing below the
project's own established touch-target standard) containing one child
`TextureRect` fixed at 64×64 (`expand_mode = EXPAND_IGNORE_SIZE`,
`stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`), centered via an
`anchors_preset = 8` (`PRESET_CENTER`) box. The Control (`Button`)
determines touch size; the `TextureRect` determines visual icon size -
they're decoupled by construction, so no icon can ever again overflow
its button regardless of the source PNG's native resolution. `game.tscn`'s
`TopBar`/`BottomBar` `PanelContainer`s also got an explicit
`custom_minimum_size.y = 160` so their height is asserted, not derived
from content - a second, independent guard against the same class of bug
recurring from a different direction.

**Why this wasn't caught in Milestone 4A:** the scene-boot smoke tests
that milestone ran only checked for *script errors*, never rendered a
frame or measured resulting control sizes - a `Button` with a
wildly-oversized icon produces zero script errors, it just looks
catastrophically wrong. This is the concrete lesson: automated headless
checks catch crashes, not bad layouts. A human needs to actually look at
the rendered UI (which is exactly why Milestone 4A was still marked "not
yet manually tested" and why this correction pass exists).

### D38 — Root cause: three panels have their titles baked into the art; Milestone 4A drew a second, duplicate title on top of each one

Looking at `bs_ui_pause_panel.png`, `bs_ui_settings_panel.png`, and
`bs_ui_level_complete_panel.png` directly (not just their file names)
shows each one already has its screen's title rendered directly into the
artwork ("PAUSE", "SETTINGS" + a gear glyph, "LEVEL COMPLETE" + a star
badge), occupying a substantial ornamental header band at the top of each
image. Milestone 4A additionally placed its own dynamic `Label` ("PAUSED"
/ "SETTINGS" / "LEVEL COMPLETE") using a flat, small inner margin (40px)
that didn't account for that baked header band at all - meaning the
dynamic label rendered either directly on top of, or immediately
crowding, the baked title art. This is what the user saw as "Settings
panel has overlapping decorative artwork, title, labels and controls"
and the Pause menu's "large panel but tiny controls floating inside it."

**Fix:** the redundant `Label` nodes were removed entirely from all
three scenes (`pause_menu.tscn`, `settings_menu.tscn`,
`level_complete_popup.tscn`) - the baked title *is* the screen's title
now, nothing else needed. Each panel's `StyleBoxTexture.texture_margin_*`
was re-measured by viewing the actual art (not guessed from filename/
proportion) and set to clear the real header/footer/side-border bands:
Pause (1312×1199 source) uses top=330/bottom=170/sides=150; Settings and
Level Complete (1536×1024 source, near-identical composition) use
top=380-400/bottom=140/sides=170. Godot's `StyleBoxTexture` uses
`texture_margin_*` as the *default* content margin too (when
`content_margin_*` isn't explicitly overridden), so these values do
double duty: they both protect the ornamental art from 9-slice distortion
**and** automatically enforce minimum clearance between the panel edge
and whatever's inside it - the small inner `MarginContainer` (20-24px)
that remains is fine-tuning on top of that guarantee, not the only thing
standing between text and artwork like it was in Milestone 4A.

**Buttons got the same treatment, for a different problem:** viewing
`bs_ui_button_primary.png`/`bs_ui_button_danger.png` directly showed
roughly 20% of the image's height above and below the button shape is
pure transparent glow padding - Milestone 4A's blind 180px-flat-margin
guess (D36) didn't account for this, and combined with undersized overall
button dimensions (360×144 on a 1080-wide reference) is most of why
Main Menu buttons read as "extremely small relative to background."
Fixed via `StyleBoxTexture.region_rect = Rect2(35, 165, 1705, 545)`
(cropping the button textures down to their actual visible pill shape
before 9-slicing) plus much smaller absolute `texture_margin` values
(70px sides, 32px top/bottom - appropriately sized for the button's real
on-screen height range of 110-160px, not the source image's own 887px
height) plus substantially larger on-screen button dimensions with a
clear size hierarchy (Play 640×156 primary, Continue/Settings 560×132
secondary, Quit 420×112 danger/smallest).

### D39 — Toggle switch art is a wide pill with "ON"/"OFF" baked in, not a checkbox glyph; `CheckButton` was the wrong widget

`bs_ui_toggle_on.png`/`bs_ui_toggle_off.png` are wide (~2.1:1)
graphics with "ON"/"OFF" text baked directly into the pill shape -
clearly designed to be displayed as a standalone wide switch control at a
legible size, not as a small icon substituted into a `CheckButton`'s
tiny checkbox-glyph slot (which is what Milestone 4A did, sized however
`CheckButton`'s default checkbox metrics happened to render it - small
and/or distorted, and definitely not at a size where its own baked text
would even be readable). **Fix:** `settings_menu.tscn`/`.gd` replaced
`CheckButton` entirely with a `toggle_mode = true` `Button` (functionally
identical persistent on/off state, including the same `toggled(bool)`
signal `SaveManager.sound_enabled`/`music_enabled` already wired to) sized
240×120, containing one child `TextureRect` that swaps between the two
toggle textures on state change - the same "Control decides touch size,
TextureRect decides visual size" pattern as D37's icon buttons, applied
to a toggle instead of a plain icon button.

### Also fixed this pass, all using the same "look at the art, then size the control around it" method rather than a redesign

- Main Menu now anchors the logo near the top and the button group near
  the bottom (a `VBoxContainer` with a `size_flags_vertical = EXPAND_FILL`
  spacer between them, not a single `CenterContainer`) - viewing
  `bs_bg_main_menu.png` directly showed a bright circular focal point and
  two bands of baked flavor text sitting in the vertical middle of the
  frame, exactly where dead-centering the button group had placed it in
  Milestone 4A. Background art itself is unchanged, per the correction
  brief's explicit instruction.
- Level Select cards are now a fixed 240×253 (matching the source art's
  own aspect ratio) with `size_flags_horizontal/vertical = SHRINK_CENTER`
  instead of `EXPAND_FILL` - Milestone 4A's expand-fill flags let
  `GridContainer` stretch cards to an inconsistent, oversized, non-square
  shape to fill each column, and (more seriously) prevented
  `ScrollContainer` from computing the grid's true content height
  correctly, which is almost certainly why the bottom row read as
  clipped. The grid is now wrapped in a `CenterContainer` so the 3-column
  block sits centered rather than packed to one side, and a 48px spacer
  was added after the grid so the last row has visible breathing room
  when scrolled all the way down.
- `NumberLabel`/`StarsRow` anchors on `level_button.tscn` were
  repositioned to match the actual card art's two zones (a large upper
  hex area, a smaller lower "notch" tab) instead of an arbitrary
  0%-72%/68%-88% split guessed without looking at the art.
- The shared theme (`themes/beamshift_theme.tres`) gained a project-wide
  `font_outline_color`/`outline_size` on `Label` (and `Button`) for
  contrast against the busy sci-fi backgrounds - addressing the brief's
  Step 10 text-readability requirement with one theme-level change
  instead of per-label overrides.

**Not yet manually approved.** Automated validation (headless import,
all-15-levels `LevelSolver` re-verification, scene-boot smoke tests,
Android re-export) passed - see `TEST_PLAN.md` - but per the correction
brief's explicit instruction, **only the user can approve this pass**
after reviewing it visually (in-editor and/or on a device). Do not mark
Milestone 4A.1 approved in any doc without that.

## Milestone 4A.2 — Level 3 Gameplay Fix + UI Scale Correction

Milestone 4A.1 **failed the user's second manual QA** on the actual
Android/desktop build: (A) Level 3 could not be completed during real
gameplay, and (B) Pause/Settings/Level Complete content remained visually
squeezed/small. See `CHANGELOG.md` for the full report; this section is
the reasoning behind each fix.

### D40 — Root cause of "Level 3 cannot be completed": the mirror's visual rotation was backwards from its logical orientation

**This was a real, confirmed regression introduced in Milestone 4A**, not
a pre-existing gameplay bug and not a user-difficulty issue. Full
diagnostic process (all of it, including the dead ends, recorded here so
a future session doesn't have to re-derive it):

1. **LaserSystem/GridManager/target/reset logic re-verified independently
   correct.** A script instantiated the real `grid.tscn`, loaded Level 3,
   and called `_on_orientable_tile_clicked()` (the exact method
   `grid_manager.gd` uses for a real tap) for the solver's own reported
   2-move solution (`(2,2)` then `(2,3)`, both SLASH→BACKSLASH). Result:
   `is_solved` became `true`, `activated_targets` contained the target,
   the target node's own `activated` flag was `true`, and `reset_level()`
   correctly restored the exact original state. This proved the
   simulation/target/reset path was never broken - Milestone 4A's tile
   visual rewrite never touched `LaserSystem`, `GridTypes.reflect()`, or
   `grid_manager.gd`'s state-owning logic, and this test confirms nothing
   there regressed.
2. **A real `InputEventMouseButton` dispatched via `push_input()`/
   `Viewport.gui_get_hovered_control()` at a mirror's own
   `get_global_rect()` center never reached `MirrorTile._gui_input()`** -
   confirmed with a temporary print statement placed directly inside
   `_gui_input()` that never fired. This is a **known Godot
   `--headless`-mode limitation** (no real `DisplayServer`/window means
   synthetic GUI input events don't reliably route to `Control._gui_input`),
   not evidence of a real bug - this project has no way to test actual
   tap/click dispatch headlessly. Recorded here so a future session
   doesn't waste time re-attempting this exact test expecting a different
   result, and doesn't mistake a failed synthetic-input test for a real
   bug. Layout/anchor math (`get_global_rect()`, `get_visible_rect()`)
   works fine headlessly - it's specifically the `_gui_input` event
   dispatch pipeline that doesn't.
3. **The actual bug, found by viewing `bs_tile_mirror.png` directly**:
   the source art's unrotated (0°) pose shows its diagonal bar running
   bottom-left to top-right - the "/" (SLASH) shape. `mirror.gd`'s
   `_draw()` had this backwards: `angle = 0.0 if orientation ==
   BACKSLASH else PI * 0.5` maps the *unrotated* pose to BACKSLASH and
   the *90°-rotated* pose to SLASH - exactly inverted. Cross-checked
   against the pre-Milestone-4A procedural mirror code (which drew SLASH
   as a literal bottom-left-to-top-right line and BACKSLASH as
   top-left-to-bottom-right - the correct, standard convention matching
   `GridTypes.reflect()`'s own naming) - this confirms Milestone 4A's
   texture-rotation guess (documented at the time as "purely cosmetic,"
   see the original `ARCHITECTURE.md` mirror note) was simply wrong.

**Why this breaks completability in practice even though `reflect()`
itself was never touched:** the rendered beam `Line2D` is always correct
(driven by the true `tile_orientations` state, unaffected by the visual
bug), but the mirror's own drawn diagonal contradicts it. A player who
reads the mirror's glyph the standard way ("/" should send a rightward
beam up, "\" should send it down - matching `GridTypes.reflect()`'s own
documented truth table) sees a diagonal that means the opposite of what
actually happens, and a beam whose real motion contradicts the glyph it
just bounced off. This is confusing enough in general to make a genuinely
solvable level *look* broken; Level 3 in particular was reported because
its intended solution requires **both** mirrors flipped in a specific
order that's already slightly non-obvious (the second mirror sits outside
the beam's initial path entirely) - exactly the kind of puzzle where a
misleading visual cue stops a player from ever finding the correct state
by trial and error, rather than a simpler level where the correct-looking
state is easier to stumble into anyway.

**Fix:** `mirror.gd`'s angle mapping was corrected to `angle = 0.0 if
orientation == SLASH else PI * 0.5` - one line. No other file needed to
change; `GridTypes.reflect()`, `LaserSystem`, and every level's data were
never wrong.

**Why LevelSolver "passed" Level 3 the whole time:** `LevelSolver` never
renders anything - it calls `LaserSystem.simulate_until_stable()`
directly against raw orientation bitmasks, which was always correct. The
solver has no concept of "what the mirror looks like," so a purely visual
bug is invisible to it by construction. This is not a solver bug or gap -
it's a category of bug (simulation-correct, presentation-wrong) that a
pure-logic tool can never catch, which is exactly why this pass added a
runtime-replay validation layer (see D41) on top of the solver check that
was already in place.

### D41 — New validation layer: replay the solver's actual solution through the real GridManager, not just LaserSystem

Milestone 4A/4A.1's regression checks only confirmed "declared
`optimal_moves` == solver-computed `optimal_moves`" - agreement between
two things that both ultimately call the same `LaserSystem`, so a
presentation-only bug (D40) could never surface there. This pass adds a
third check: for every one of the 15 levels, take `LevelSolver`'s own
`solution_path` and replay it move-by-move through a **real, instantiated
`GridManager`** via `_on_orientable_tile_clicked()` (the same method a
real tap calls), then assert `is_solved == true`. This is still not a
true end-to-end input test (see D40 point 2 - real `_gui_input` dispatch
can't be exercised headlessly), but it does exercise the entire
GridManager/TileVisual/target-node/simulation chain a real tap would
trigger, one level below the final `_gui_input()` → `tile_clicked` signal
hop. All 15 passed after the D40 fix. See `TEST_PLAN.md` for the
runnable technique - recreate the script from that description each time
per this project's existing convention (scratch harnesses aren't
committed to the repo).

### D42 — UI scale correction: decorative panel size and content size are now independently controlled

Milestone 4A.1 sized each popup's inner `MarginContainer`/button/label
dimensions in lockstep with what the panel's `StyleBoxTexture` margins
happened to require for header/border clearance, rather than choosing
content sizes independently and letting the panel grow to fit. The user's
second manual QA reported the result as still "squeezed" (Settings
especially - "huge amount of unused screen space" alongside "too small"
controls, meaning the PANEL was appropriately large but the CONTENT
inside it wasn't using that space). Fixed by explicitly growing every
content element first (Settings: toggle 240×120→300×150, label font
28→38, Back button 120→148px/font 26→32, panel width 780→900; Pause:
button height 116→148px/font 26→32, panel width 640→780; Level Complete:
stars 56→84px, stat font 22/20→32/28, button height 116→140px/font
24→30, panel width 760→880) and letting each panel's `custom_minimum_size`
and the `StyleBoxTexture`'s implicit content-margin (see D38) absorb the
result, rather than the reverse. Gameplay HUD text/icons were nudged up
slightly too (`LevelLabel` 24→28, `MovesLabel` 22→26, icon visual size
64→76px within the unchanged 144px touch target) per the explicit
instruction not to return to Milestone 4A's oversized-icon problem - the
touch target and bar height (160px) are unchanged, only the icon's own
rendered size grew slightly.

### D43 — Responsive validation: compare against the logical canvas rect, not the raw physical resolution

A first attempt at automating Part B8's resolution matrix compared each
`Control.get_global_rect()` directly against the raw pixel dimensions
passed to `get_viewport().size` (e.g. 720×1280) and produced false
failures across the board. Root cause: this project uses
`window/stretch/mode="canvas_items"` with `aspect="expand"` (a
Milestone-1 decision, unrelated to this pass) - Controls always live in a
coordinate space at least as large as the 1080×1920 reference (the
stretch scale factor is `min(vw/1080, vh/1920)`, which guarantees the
1080-wide reference is never compressed below its own size; "expand"
only ever *reveals additional* logical space for a taller or wider
physical aspect ratio, it never shrinks the reference space for a
narrower one). Comparing real `Control` rects against the raw physical
pixel count is a coordinate-space mismatch, not a real overflow -
confirmed by re-running the same checks against
`get_viewport().get_visible_rect().size` (the actual logical canvas size
Controls are laid out in), which produced correct, passing results at
all 5 tested resolutions, including confirming the grid's screen-area
fraction actually *grows* on taller aspect ratios (0.667 at 1080×1920 up
to 0.730 at 1080×2400) exactly as the "expand" mode is supposed to
behave. **Practical implication verified, not just theorized:** every
fixed-width popup panel in this project (max 900px) is safe on any real
phone aspect ratio, because the reference width (1080) is the guaranteed
*minimum* logical width available - a panel narrower than that can never
overflow horizontally regardless of physical screen width. See
`TEST_PLAN.md` for the runnable technique.

## Milestone 4A.3 — Runtime Truth Audit + Build Identity + Screenshot Validation

Milestone 4A.2 **failed manual QA a third time**, with the reported
symptoms (Level 3 uncompletable, UI still squeezed) reading as identical
to what Milestone 4A.2 had already fixed in the actual project files.
This section records the audit performed to resolve that contradiction,
and what it actually found - which was different from what the kickoff
brief assumed.

### D44 — Root cause of the report/reality mismatch: almost certainly a stale APK install, not a code regression

**Audit performed, in order, before touching any code** (per the
brief's explicit Phase 0-7 sequencing):

1. **Filesystem search for duplicate project/APK copies** on the
   machine this session runs on: exactly one `beam-shift` project
   directory and exactly one `beamshift-debug.apk` exist. No duplicate
   project Claude could have been mistakenly editing, no stray old APK
   sitting somewhere the user could have grabbed by accident **on this
   machine**.
2. **File timestamps**: `mirror.gd`, `game.tscn`, `pause_menu.tscn`,
   `settings_menu.tscn`, `level_complete_popup.tscn` all carry Milestone
   4A.2's edit timestamps (~18:03-18:08). The APK that existed before
   this milestone was built at 18:13 - **after** every one of those
   edits. The exported APK on disk genuinely contained the 4A.2 fixes.
3. **Discovered a real, previously-unexamined gap**: `export_presets.cfg`
   had never changed `version/code`/`version/name` from their
   project-default values (`1`/`"1.0"`) across Milestones 4A, 4A.1, AND
   4A.2. A same-versionCode reinstall is exactly the kind of thing that
   can silently leave a device on an old build depending on how the APK
   was transferred/installed (e.g., a non-`-r` `adb install`, or a
   device/launcher that dedupes by version). This project had zero
   protection against that failure mode until now.
4. **Rendered, actually-viewed evidence** (see D45) - not code review,
   not headless script-error checks - showed Level 3 completing
   correctly through the exact real-input code path, and Main Menu/Level
   Select/Settings/Pause/Level Complete all rendering as intended by the
   Milestone 4A.2 sizing changes. Every screen matched what the
   Milestone 4A.2 report claimed, when actually rendered and looked at.

**Conclusion:** the project code was not the problem by the time this
audit started. The most likely explanation, consistent with every piece
of evidence above, is that the physical device being manually tested was
running a build from before Milestone 4A.2's fixes, and nothing in the
project forced that device to actually update. This is not asserted as
certain (there is no way to inspect the user's device from this
environment) - it's the conclusion the evidence points to, stated
plainly rather than re-diagnosing code that multiple layers of evidence
say is already correct.

**Fix:** `export_presets.cfg`'s `version/code` bumped `1 → 5` and
`version/name` set to `"1.0.0-4A.3"` (see `CHANGELOG.md`) - any
reasonable install mechanism now treats this as a genuinely newer,
distinct build. A temporary, highly visible **"BUILD 4A.3"** label was
also added to the Main Menu (bottom-right corner) and Settings screen
footer specifically so the user can visually confirm, with certainty,
that the app running on their device is this build and not a cached one
- see `PROJECT_HANDOFF.md` for the removal reminder (this label is
QA-only and must come out before any real release).

**Reconsider when:** once the user confirms BUILD 4A.3 is visible and a
manual test against *that* confirmed build still reproduces either
reported problem, treat it as a genuine new bug report and re-open a
real code investigation - don't dismiss a future report as "probably
stale" a second time without this same kind of verification.

### D45 — Screenshot capture works on this machine; it should have been used from Milestone 4A onward

**This is the most important process lesson from this milestone.** Every
previous visual-integration pass (4A, 4A.1, 4A.2) validated exclusively
via `--headless` script-error checks and code review, explicitly
asserting "cannot visually verify" as a limitation of the environment.
That assertion was **never actually tested** until this milestone - it
turned out to be false. This machine has a real GPU (confirmed: NVIDIA
RTX 4080, D3D12 backend) and running Godot **without** `--headless`
produces genuine rendered frames, which `Viewport.get_texture().get_image().save_png()`
can capture to a real PNG file that Claude's own image-reading tool can
then actually look at.

**Technique** (see `TEST_PLAN.md` for the full runnable script): a
temporary driver scene set as `run/main_scene`, instantiating each real
screen (`main_menu.tscn`, `level_select.tscn`, `game.tscn`, etc.) as a
child, `await`-ing 2 `process_frame`s plus one `RenderingServer.frame_post_draw`
after each state change (scene add, popup show, simulated click) before
capturing, then saving the frame buffer to PNG. Run via `godot --path .`
(no `--headless` flag) with a `timeout` wrapper.

**Bonus finding:** with real rendering active, `Input.parse_input_event()`
(not `Viewport.push_input()`, which was the method that failed
headlessly in Milestone 4A.2's D40 investigation) correctly dispatches to
`Control._gui_input()` - a real synthetic click rotated Level 3's mirror
end-to-end through the actual player-facing code path, not a bypass.
This means **real click-driven regression testing is possible on this
machine**, not just layout/anchor math - a capability that didn't exist
as far as any previous milestone's documentation knew.

**Why this changes future practice:** `CLAUDE.md` rule 12a (`--headless`
cannot dispatch GUI input) is still true and still worth knowing, but it
is **not** the same claim as "this environment cannot render or verify
visuals at all" - that broader claim, made repeatedly through Milestones
4A-4A.2, was an unverified assumption that turned out to be wrong and
cost real time (three consecutive failed-QA-sounding reports that were
substantially about not having actually looked at the result). Any
future UI/visual claim in this project should be backed by an actual
rendered screenshot Claude has looked at with its own image-reading tool,
whenever a real GPU is available in the environment - which should be
checked for directly (try a non-headless run) rather than assumed absent.
See `CLAUDE.md` rule 12d.

### D46 — What the screenshots actually showed (rendered visual QA, distinct from automated/headless checks)

Captured and personally inspected: Main Menu (BUILD 4A.3 label visible,
bottom-right, subtle), Level Select (15 cards, readable), Level 3 initial
state (emitter/mirrors/blocker/target all visible and correctly
positioned, beam correctly blocked pre-solve), Level 3 solved via a real
simulated click sequence (Level Complete popup appears automatically,
"Moves Used: 2 / Best Moves: 2", 3 gold stars, three legible full-width
buttons), Pause menu on an unsolved level (PAUSE header, 5 clearly
labeled evenly-spaced buttons filling the panel's inner region, MAIN
MENU in red), and Settings (large SETTINGS header, "Sound"/"Music" rows
with legible large toggle switches showing "ON" text, large BACK button).
**None of these matched the "squeezed"/"tiny controls" description in
the correction brief.** They matched what Milestone 4A.2's changes were
supposed to produce. This is rendered visual evidence, not a substitute
for the user's own device confirmation - recorded as its own validation
category (see D47) precisely so this distinction doesn't get blurred
again.

**One test-harness-only issue found and fixed, not a game bug:** the
first attempt to screenshot the Pause menu actually captured the Level
Complete popup, because `game.gd._on_pause_pressed()` correctly refuses
to open Pause while Level Complete is already showing - a guard added
back in Milestone 4A - and the test script tried to open Pause on an
already-solved level. Fixed by testing Pause on the level's unsolved
initial state instead. Recorded because it's a good example of a
"failure" that was actually correct game behavior being tested wrong -
exactly the kind of thing this milestone was supposed to stop doing.

### D47 — Explicit three-tier validation vocabulary, going forward

Per the correction brief's explicit request, every future validation
report in this project's docs must use one of three distinct labels,
and must not blur them:

- **AUTOMATED** — a headless script ran and asserted something
  (`--headless --script`, or `--headless --path .` with a temporary
  main-scene swap). Proves logic/layout math/absence of script errors.
  Does **not** prove anything looks right, and (per D40) cannot exercise
  real `_gui_input` dispatch.
- **RENDERED** (new this milestone) — a real, non-headless Godot process
  produced an actual frame, saved via `get_viewport().get_texture().get_image().save_png()`,
  and Claude looked at the resulting image with its own image-reading
  tool before making any claim about it. Proves what the pixels actually
  look like, on this machine, for this exact build. Still not the same
  as the user's own device/eyes.
- **MANUAL** — the user looked at it themselves, in-editor or (most
  authoritatively) on a real device. This is the only tier that can
  actually approve a milestone. Nothing else in this list may ever be
  reported as if it were this tier.

## Milestone 4A.4 — Portrait UI replacement + responsive HUD

### D48 — `bs_panel_settings_portrait.png` is a mislabeled duplicate of the Level Complete art, not a real Settings panel; Settings was deliberately left on its old art

The five new portrait UI assets supplied for this milestone
(`assets/ui/panels/bs_panel_{settings,pause,level_complete}_portrait.png`,
`assets/ui/hud/bs_hud_{top,bottom}_portrait.png`) were inspected directly
(not just by filename) before integration, per this project's standing
practice (see D31/D37). `bs_panel_settings_portrait.png` and
`bs_panel_level_complete_portrait.png` are **byte-identical** (confirmed
via MD5: `939e93f0893978ee8c1af21d1437352d` for both) — both files
visually read "LEVEL COMPLETE" with a star icon, not "SETTINGS" with a
gear icon. This is a genuine asset-delivery mistake, not a naming
convention to design around.

**Decision:** integrate the other four assets normally (Pause, Level
Complete, top HUD, bottom HUD all use their correct, distinct new art -
Pause was independently confirmed to say "PAUSE" with a distinct
pause-icon header, not a duplicate of the other two). Settings
(`settings_menu.tscn`) was **deliberately left on its pre-existing
`bs_ui_settings_panel.png`** rather than wired to the mismatched file -
shipping a Settings screen whose art says "LEVEL COMPLETE" would be a
worse, more confusing regression than simply not touching it this pass.
The old Settings art was already correct/working, so nothing was lost by
leaving it alone.

**Reconsider when:** a correctly-labeled `bs_panel_settings_portrait.png`
(gear icon, "SETTINGS" text baked in, matching the Pause/Level Complete
frame style) is actually supplied. Do not reuse the Level-Complete-labeled
file for Settings under any circumstance, including "just for now with a
dynamic title Label on top" - that still visually contradicts the baked
"LEVEL COMPLETE" text sitting right above/around it.

### D49 — Gameplay HUD bars: full-width, aspect-locked via a resize script, not a fixed-margin StyleBoxTexture

The old top/bottom HUD art (`bs_ui_gameplay_{top,bottom}_frame.png`) was
used as a `StyleBoxTexture` on a fixed-height (160px) `PanelContainer` -
acceptable because that art's decorative border was uniform/tileable
enough that arbitrary aspect distortion from stretching wasn't visually
obvious. The new art (`bs_hud_{top,bottom}_portrait.png`, both
~2112x745, ratio ≈2.835:1) has a **structural, asymmetric centerpiece**
(a reactor-style circular icon with a small number of discrete flanking
slots) - stretching this art to an arbitrary aspect ratio (e.g. squashing
a 2.8:1 image into a 1080-wide x160-tall ≈6.75:1 box) would visibly
distort the reactor into an ellipse and misalign the slot dividers. The
brief's explicit instruction ("aspect-ratio preserved... do not stretch
it vertically") is a hard constraint this art actually requires, unlike
the old art.

**Decision:** `scripts/ui/aspect_bar.gd` (new, `class_name AspectBar`) is
attached to both `TopBar` and `BottomBar` in `game.tscn`. It takes an
`aspect_ratio` export (source texture width/height) and, on every
`resized` signal, sets its own `custom_minimum_size.y = size.x /
aspect_ratio` - the same resize-driven recompute pattern
`grid_manager.gd` already uses for its own square-cell layout (see
ARCHITECTURE.md "Laser propagation"/responsive rules), applied here to a
different problem (locking one dimension to a ratio of the other, not
computing a square). Both bars are full-width within `SafeMargin/Layout`
(a `VBoxContainer`), so height is fully derived, never hardcoded.

**Tradeoff accepted:** at the 1080-logical-width reference, this makes
each bar roughly 300-315px tall (vs. the old fixed 160px), because the
new art's own proportions demand it once distortion is ruled out. A
rendered screenshot at 1080x1920 confirmed the puzzle grid still gets
noticeably more screen area than either bar alone (measured:
grid ≈45.8% of total screen area vs. ≈16.3% per bar, ≈32.6% for both
bars combined) - satisfying Step 9's literal "grid must receive the
majority of the gameplay screen" requirement (grid is the single largest
region), even though the two bars combined are non-trivial. If a future
pass wants the bars visually shorter, the only way to do that without
reintroducing distortion is to crop the source art narrower (reduce its
own aspect ratio) - not something to fix by relaxing `aspect_ratio` in
the scene, since that's precisely what caused Milestone 4A.2/D40-era
regressions in spirit (visual state disagreeing with what the art
actually shows).

**Slot mapping (both bars use pixel-sampled fractional anchors, not
guesses):** the new top HUD art has two flanking content slots around a
center reactor icon; back button + level name went in the left slot
(≈8%-35% of bar width), moves counter in the right slot (≈68%-92%). The
new bottom HUD art has four flanking slots; only Reset and Pause are
currently implemented gameplay actions (Hint exists but is hidden/unused,
per D33 - no hint logic exists; there is no Undo), so per the brief's
explicit instruction ("if only some actions are currently implemented,
use only those actions and leave unused slots visually empty") they were
placed in the two slots immediately flanking the reactor (≈30%/≈70% of
bar width) and the two outer slots were left empty rather than inventing
placeholder functionality for them.

### D50 — Corrected Settings asset confirmed distinct and correct; integrated the same way as Pause/Level Complete

A follow-up pass supplied a corrected `bs_panel_settings_portrait.png`.
Before integrating it, it was re-verified independent of D48's finding
(not just trusted because the user said it was fixed): MD5 confirmed it
is now a **different** file from `bs_panel_level_complete_portrait.png`
(`842825d8...` vs. `939e93f0...`), and visual inspection confirmed a gear
icon and a baked "SETTINGS" title, at the same 941x1672 dimensions and
matching border/frame style as the Pause and Level Complete art. Wired
into `settings_menu.tscn` exactly the same way as those two siblings:
`texture_margin_*` pixel-sampled directly against this specific file
(left=160, top=460, right=175, bottom=255 - matching the siblings within
measurement noise, consistent with them sharing one frame-art style), no
duplicate title `Label` added (none existed to remove), panel width kept
at 900 for visual consistency with Level Complete. All five of this UI
milestone's replacement assets (Settings, Pause, Level Complete, top HUD,
bottom HUD) are now active; the two originally-shipped assets that were
superseded (`bs_ui_settings_panel.png`'s replacement here, plus the
already-superseded Pause/Level Complete/HUD frame art from D48/D49) are
left on disk, unreferenced, per standing instruction not to delete
assets before visual approval.

## Milestone "Android HUD Alignment + Missing Tile Fix"

### D51 — Root cause of "Level 3 puzzle tiles invisible on Android, visible on PC": `blocker.gd`/`hazard.gd` preloaded textures from the export-excluded `pieces/` folder, silently truncating the tile-loading loop

**This is a genuine, confirmed, reproducible-without-a-physical-device
bug** — found and fixed without needing the user's Android hardware, by
actually running the real exported package (not source) headlessly.
Every prior visual-integration RENDERED validation in this project
(4A-4A.6) ran via `godot --path .` reading source files directly, which
**completely bypasses `export_presets.cfg`'s `exclude_filter`** - meaning
none of those checks could ever have caught an export-filter-exclusion
bug, no matter how thoroughly the source-based rendering was inspected.
This is an important gap in the AUTOMATED/RENDERED/MANUAL vocabulary
(D47): none of those three tiers, as previously practiced, actually
exercises the exported package's real file set.

**Root cause, traced concretely:**
1. `blocker.gd` and `hazard.gd` (`scripts/gameplay/`) `preload()` their
   tile textures from `res://assets/gameplay/pieces/bs_tile_blocker.png`
   and `.../bs_tile_hazard.png`. `assets/gameplay/pieces/**` is entirely
   excluded from the Android export filter (`export_presets.cfg`) as
   part of the "unused duplicate generated-art set" from D31/D24 - but
   these two specific files were never actually unused; they were the
   deliberately-chosen canonical art for the Blocker and Hazard tiles
   (recorded correctly in `PROJECT_HANDOFF.md`'s asset table as "from
   pieces/" - a discrepancy that had gone unnoticed since Milestone 4A).
2. Confirmed directly: exported a real `.pck` via
   `godot --headless --path . --export-pack "Android Debug" out.pck`,
   then ran `godot --headless --main-pack out.pck --script <check>.gd`.
   `ResourceLoader.exists("res://assets/gameplay/pieces/bs_tile_blocker.png")`
   returned `false` against the actual exported package, while
   `res://assets/gameplay/blocker/bs_tile_blocker.png` (a differently-
   drawn, never-actually-used duplicate that happened to already sit in
   the correctly-named canonical folder) returned `true`.
3. Loading `blocker.gd` against that same exported package printed:
   `SCRIPT ERROR: Parse Error: Preload file "res://assets/gameplay/
   pieces/bs_tile_blocker.png" does not exist` followed by
   `ERROR: Failed to load script "res://scripts/gameplay/blocker.gd"
   with error "Parse error"`. **The script fails to parse/load entirely**
   in any exported build - not just render with a missing texture.
4. `blocker.tscn` itself still loads (a `.tscn`'s own load doesn't fail
   just because its attached script does), and still instantiates - but
   as a bare, scriptless `Control`, not a `BlockerTile`.
5. `grid_manager.gd`'s `load_level()` does
   `var node: BlockerTile = BLOCKER_SCENE.instantiate()` - a statically
   typed assignment. Against the broken exported package, this throws
   `SCRIPT ERROR: Trying to assign value of type 'Control' to a variable
   of type 'blocker.gd'` **at runtime, uncaught**, which **aborts the
   entire `for tile in level_data.tiles:` loop** for that level. Directly
   confirmed by instantiating a real `GridManager` against the broken
   package and loading Level 3's data: only `Emitter` and the first
   `Mirror` (both earlier in the tile array than the blocker) were
   actually added as children; the second `Mirror` and the `Target`
   (both later in the array) were silently never created at all.
6. `LaserSystem.simulate_until_stable()` reads `level_data.tiles`
   directly - it has no dependency on the visual tile nodes `load_level()`
   creates. This is why the laser beam still rendered correctly even
   though the tiles themselves were missing - the two symptoms have
   independent causes that happened to both trace back to the same root
   bug for tile-bearing levels.

**This exactly explains all five reported Android symptoms**: tiles
invisible (silently dropped from the array-processing loop), laser
visible (simulation is independent of tile nodes), background visible
(unrelated node, untouched), level logic "working" on PC (desktop
RENDERED tests always ran from source, never from an exported package,
so they structurally could not have caught this), and Level 3
specifically affected (it has a `BLOCKER` tile at array index 2, ahead of
its second mirror and its target).

**Blast radius:** every level with a `BLOCKER` or `HAZARD` tile placed
before other tiles in its `tiles` array is affected, not just Level 3.
Grepping `levels/*.gd` for `make_blocker`/`make_hazard` found **Level 3,
Level 5 (blocker), Level 12, Level 15 (hazard)** - 4 of the 15 real
levels were silently missing content in every exported build to date.

**Fix:** relocated the actually-used art
(`assets/gameplay/pieces/bs_tile_blocker.png`,
`.../bs_tile_hazard.png`) into the already-established, non-excluded,
one-folder-per-tile-type convention every other tile type already
follows (`assets/gameplay/blocker/`, `assets/gameplay/hazard/`),
overwriting the never-actually-used duplicate art that happened to
already be sitting there. Updated `blocker.gd`/`hazard.gd`'s `preload()`
paths to match. **`export_presets.cfg`'s `exclude_filter` itself was not
touched** - it correctly continues to exclude the entire (now fully
unused) `pieces/` folder; the bug was the two scripts pointing at the
wrong copy, not the filter being wrong. Verified three independent ways
after the fix: (a) `ResourceLoader.exists()` against a freshly re-exported
`.pck` now returns `true` for the canonical-folder paths and the broken
preload errors are gone; (b) a real `GridManager.load_level()` call
against that same rebuilt package now instantiates all 5 of Level 3's
tiles correctly, with proper scripts, sizes, and positions; (c) the
actual shipped `beamshift-debug.apk` was unzipped directly and inspected
- `assets/gameplay/blocker/`/`hazard/` are present, `assets/gameplay/
pieces/` is completely absent, and both `.gdc`-compiled scripts are
present.

**New standing practice - add to the validation toolkit going forward:**
any future claim that "the exported/Android build behaves like the
source-based desktop test" for content that depends on `preload()`d
resources under a partially-excluded asset directory should be verified
against a real exported `.pck`/APK, not just source-based RENDERED
testing. The technique above (`--export-pack`, then
`--main-pack <pck> --script <check>.gd` calling `ResourceLoader.exists()`
and/or actually instantiating the scene in question) is cheap, fully
automatable, and requires no physical device - it should have been part
of the standard toolkit since `export_presets.cfg` first grew an
`exclude_filter` (Milestone 3, D24), not discovered only now.

### D52 — Top/bottom gameplay HUD: level-name text kept to two clean lines instead of word-wrapping; slot anchors tightened to pixel-measured symmetric fractions

Two separate, smaller layout defects, fixed alongside D51:

1. `game.gd`'s level label used `"LEVEL %d: %s"` with `autowrap_mode`
   WORD enabled inside a narrow slot - for most level names (e.g. "LEVEL
   3: Obstruction") this word-wrapped to an awkward 3-line block. Changed
   to two explicit lines (`"LEVEL %d\n%s"`) with `autowrap_mode` turned
   **off** and a new `_shorten_level_name()` helper that truncates with
   an ellipsis past `MAX_LEVEL_NAME_CHARS` (13) - guarantees exactly two
   clean, centered lines regardless of how long a future level's
   `display_name` is, rather than relying on word-wrap to happen to break
   in a good place.
2. `game.tscn`'s `TopBar`/`BottomBar` slot anchor fractions were
   re-measured by pixel-sampling `bs_hud_top_portrait.png`/
   `bs_hud_bottom_portrait.png` directly (scanning a horizontal line at
   each bar's vertical center, detecting contiguous "flat slot interior"
   color runs) rather than eyeballed from a rendered screenshot as in
   Milestone 4A.5/D49. Top bar's `LeftSlot`/`RightSlot` are now exactly
   symmetric (0.07-0.33 and 0.67-0.93, both width 0.26, centers
   equidistant from 0.5); bottom bar's `ResetButton`/`PauseButton` moved
   to the precisely measured slot centers (0.294/0.7045 vs. the previous
   eyeballed 0.3/0.7 - a small but now measurement-backed correction).
   `BackButton` was pulled out of `LeftSlot`'s layout flow entirely (it
   was previously inside the same `HBoxContainer` as the level label,
   which pushed the label off-center within its slot) and repositioned
   as its own small button anchored near the bar's left edge (fraction
   0.04, 80x80 touch target / 40x40 icon) - it now overlaps only the
   frame's decorative cap art, never the level-name text.

### D53 — APK optimization: a stale build accounted for most of the "size problem"; the real remaining waste was source textures shipped 5-20x larger than their on-screen display size

**Context:** `versionCode=10` ("1.0.0-HUDDELAY") measured 113.1 MB on
disk. The brief for this pass was staged, safety-first APK size
optimization - exclude proven-unused assets first, then consider
compression/derived textures, re-validating against a real exported
package after every pass (per D51's standing practice) because this
project has already shipped one export-filter bug that no source-based
test could catch.

**Finding #1 - the export filter was already almost entirely correct;
it had just never been re-exported against.** Building a from-scratch
reference map (`grep`ping every `.tscn`/`.gd`/`.tres`/`project.godot`
for `res://assets/...` paths, diffed against every PNG on disk) found
**exactly 34 referenced assets and 49 unreferenced ones - and every one
of the 49 was already covered by `export_presets.cfg`'s `exclude_filter`**
(inherited from D24/D31/D48-D52's prior sessions). Inspecting the
*shipped* `versionCode=10` APK's actual contents, though, found several
of those exclude patterns weren't taking effect - `.ctex` compiled
textures for supposedly-excluded files (the 5 procedural-tile-type art
folders, several superseded UI panels, the stage-select set, 10 orphan
icons) were still physically bundled. Root cause: `export_presets.cfg`
carried a **later mtime than the shipped APK** - the filter had been
edited (or touched) after that APK was last built, so the shipped build
simply predated several of its own already-authored exclusions. A plain
re-export with zero content changes - **PASS A** - dropped the APK from
113.1 MB to 73.56 MB (39.57 MB, 35%) by correctly applying exclusions
that were already sitting in the config, verified file-by-file against a
fresh `--export-pack` (`ResourceLoader.exists()` for all 34 referenced
paths: OK; for all 49 excluded paths: correctly absent - run from a
directory with no `project.godot`, see the note on that below).

**Finding #2 - most of the 34 *referenced* (correctly-shipping) assets
were still absurdly oversized for where they're actually drawn.**
Reading real pixel dimensions (PNG `IHDR`, no external tool needed) and
cross-referencing actual on-screen sizes from the `.tscn`/`.gd` source
(`custom_minimum_size`, `cell_size`-relative `draw_texture_rect` calls,
`lock_size := cell_size * 0.3`, etc.) found every gameplay tile
(mirror/target/blocker/hazard/gate/grid-cell) and every simple icon
(HUD back/reset/pause/hint, mirror lock, level-select stars, level
cards, settings toggles) was generated at **1254×1254 or 1222×1287**,
while displaying at 26px (level-select stars) to at most ~250px (a
large-grid tile cell) - a 5x to 48x *linear* oversampling (up to ~2300x
more pixels than ever rendered). **PASS C** created high-quality
downscaled derived copies of exactly these 21 files (`System.Drawing`
`HighQualityBicubic`, straight/non-premultiplied alpha preserved, 2-4x
real display size for retina headroom: 256px icons, 512px tile art,
128px stars, 512x540 level cards, 640x320 toggles), named
`<original>_runtime.png` sitting next to each untouched master, rewired
every `preload()`/`ext_resource` reference to the derived file, and
added the now-unreferenced masters to `exclude_filter` (same
keep-master-on-disk/exclude-from-export pattern D31 already established
for `pieces/`/`tiles/`). This dropped the APK a further 22.59 MB, to
**50.97 MB total (55% below the `versionCode=10` baseline)**, with zero
visible quality loss confirmed by DESKTOP RENDERED screenshots of all 6
key screens (see `TEST_PLAN.md`).

**What was deliberately left alone, and why:** the 3 `Button` textures
(`bs_ui_button_{primary,secondary,danger}.png`) and the Settings/Pause/
Level Complete panels use `StyleBoxTexture` with a `region_rect` crop
and `texture_margin_*` 9-slice values hand-measured against their exact
current pixel coordinates (D37/D38/D50) - resizing them would require
recomputing every one of those numbers and re-verifying no seam/artifact
appears at any button size, which is real risk for a texture category
already known to be error-prone in this project's history. The 2 HUD
bars (`bs_hud_{top,bottom}_portrait.png`, 2112px wide vs. a 1080px-wide
logical canvas) are only ~2x oversampled - normal retina headroom, not
waste. The 3 backgrounds were already VRAM/ETC2-compressed in a prior
milestone (`compress/mode=2`) and are correctly sized for the portrait
canvas. None of these were touched this pass; per the brief's own
"only do this where savings are substantial" and "do not degrade the
game to reach an arbitrary target," the low-risk, high-value 21 files
were judged worth the derived-texture treatment and the higher-risk/
lower-reward remainder was not.

**Verification technique note:** running
`godot --headless --main-pack out.pck --script check.gd` **from inside
the actual project directory** silently falls back to resolving
`res://` against the local project's live filesystem in addition to the
pck - every "excluded" path incorrectly reported as present. D51's
original writeup didn't flag this because its `check.gd` was invoked by
bare relative filename, but this session's `res://scripts/...gd` path
form triggered it directly. Fix: copy the `.pck` and the check script
into a directory with **no `project.godot` anywhere in its parent
chain** before running - only then does `ResourceLoader.exists()`
reflect the exported package's real, isolated file set. Recorded here so
a future session doesn't have to rediscover this the way D51 had to
rediscover the underlying export-filter gap in the first place.

**Also removed this pass (unrelated to size, but same build):** the
temporary `BuildLabel` QA marker node ("HUD + DELAY FIX") in
`main_menu.tscn`/`settings_menu.tscn`, per the standing instruction in
`CURRENT_STATUS.md`'s "NEXT MILESTONE" section to strip it once this
build superseded the one it was identifying. `versionCode` bumped
10→11, `versionName` → `"1.0.0-OPTIMIZED"`.

**Reconsider when:** if APK size ever needs to shrink further, the
9-sliced buttons/panels above are the next-largest remaining lever -
budget real time to re-derive their `region_rect`/`texture_margin_*`
values against a resized source rather than guessing, and re-run the
full DESKTOP RENDERED comparison across every screen that uses them
(every menu in the game touches at least one).

### D54 — Production Campaign Phase 1: campaign levels are a fully separate population from dev/regression levels, in both level storage AND save data, superseding D29's "still shown to players" clause

**Context:** "Production Campaign Phase 1" explicitly began the real
100-level campaign (`ROADMAP.md` Milestone 4), starting with Stage 1
("First Light," campaign levels 1-10) on top of the `versionCode=11`
("1.0.0-OPTIMIZED") build. The brief was explicit that the existing 15
levels under `levels/` are development/regression test levels, not the
final campaign, must not be deleted/overwritten, and must not be part
of player progression going forward - the real campaign levels needed
their own storage, their own save-progress tracking, and their own
Level Select population, entirely separate from the dev levels.

**This directly supersedes D29's note that "`LevelManager`/`LevelSelect`
still show all 15 to players"** - that was correct for Milestones 2-3
(when no campaign existed yet and the brief said not to redesign Level
Select), but this milestone's brief explicitly reversed that: "show only
Campaign Levels 1-10... Do not show development/regression levels to
normal players." Not a contradiction or a mistake in either milestone -
just two different, explicit, time-ordered instructions, each correct
for its own moment. If a future session sees D29's older text and this
entry disagree, **this entry (and the live code) win**.

**Level storage:** `levels/campaign/stage_01/level_01.gd` …
`level_10.gd`, one file per level, same `extends LevelData` / `_init()`
/ `TilePlacement.make_*()` shape as every existing dev level. Kept
completely separate from `levels/level_01.gd` … `level_15.gd` (untouched,
unchanged, still referenced by `LevelManager.LEVEL_PATHS` and every
regression script exactly as before) and from `levels/editor_fixtures/`
(also untouched). See `CAMPAIGN_DESIGN.md` for the full architecture,
difficulty philosophy, and the Stage 1 design table - that document, not
this entry, is the reference for creating Stage 2 onward.

**`LevelManager` changes:** added `CAMPAIGN_LEVEL_PATHS` (parallel array
to `LEVEL_PATHS`) and campaign-prefixed mirrors of every dev-level
function - `get_campaign_level_count()`, `get_campaign_level()`,
`calculate_campaign_stars()`, `get_campaign_continue_level_id()` - each
using a separate `_campaign_level_cache` dictionary so the two
populations' caches can never collide. `LEVEL_PATHS`/`get_level()`/
`calculate_stars()`/`get_continue_level_id()` are **completely
unchanged** - still fully functional for regression scripts and the
level editor's own Load dropdown (`tools/level_editor/level_editor.gd`
still lists `LevelManager.LEVEL_PATHS` unmodified).

**Why save data needed its own namespace, not just a new level source:**
`SaveManager`'s existing fields (`highest_unlocked_level`,
`completed_levels`, etc.) are keyed by a plain `str(level_id)` string,
and campaign level ids start at 1 too - a dev level 3 and a campaign
level 3 would collide in the same dictionary key if campaign progress
reused the existing fields. Added a fully parallel set of `campaign_*`
fields (`campaign_highest_unlocked_level`,
`campaign_completed_levels`, `campaign_best_moves_per_level`,
`campaign_best_stars_per_level`) and campaign-prefixed mirrors of every
dev-level `SaveManager` method (`is_campaign_level_completed()`,
`is_campaign_level_unlocked()`, `get_campaign_best_moves()`,
`get_campaign_best_stars()`, `record_campaign_level_result()`). The
original fields/methods are untouched - a save file predating this
change loads correctly (`Dictionary.get()` with safe defaults for every
new key, confirmed by testing an empty/missing-keys load path), and
nothing about a legacy save's dev-level progress is destroyed, just no
longer read by any player-facing UI. `SAVE_VERSION` bumped 1→2 as a
record of the schema growing - purely informational, no migration code
was needed since every new field is additive with a safe default.

**Player-facing rewiring:** `game.gd`'s normal-play branch (not the
`GameManager.is_editor_playtest` branch, which is untouched) now calls
`LevelManager.get_campaign_level()`/`calculate_campaign_stars()` and
`SaveManager.record_campaign_level_result()`/`get_campaign_best_moves()`;
`level_select.gd` now enumerates via `get_campaign_level_count()` and
`SaveManager`'s `is_campaign_level_*`/`get_campaign_best_stars()`;
`GameManager.continue_game()` now resolves
`get_campaign_continue_level_id()`. **A real integration bug was found
and fixed during this pass, not just guessed at:** `main_menu.gd`'s
Continue-button enabled/disabled check still read the old
`SaveManager.highest_unlocked_level`/`completed_levels` fields, which
would never update again under normal play now that nothing calls the
dev-level `record_level_result()` from the player-facing path - the
Continue button would have stayed permanently disabled regardless of
real campaign progress. Fixed to read `campaign_highest_unlocked_level`/
`campaign_completed_levels` instead. Found by grepping every
`SaveManager.`/`LevelManager.` call site across `scripts/ui/` and
`scripts/managers/` after making the rewiring changes above, specifically
looking for anything still touching the old field names - this is the
right search to redo if a future session adds another screen that reads
progress state.

**Verified against the real runtime, not just the solver:** a temporary
Node driver (`extends Node`, run via the documented temporary
`run/main_scene` swap so real autoloads are available) instantiated
`main_menu.tscn` (confirmed Continue disabled on a fresh save),
`level_select.tscn` (confirmed exactly 10 buttons, level 1 unlocked,
2-10 locked), then `game.tscn` with `GameManager.current_level_id = 1`
and `is_editor_playtest = false`, replayed the solver's own solution
through the real `_on_orientable_tile_clicked()` path, waited past the
real 0.8s `LEVEL_COMPLETE_DELAY`, and confirmed: the Level Complete
popup appeared, `SaveManager.campaign_completed_levels` became `{"1":
true}`, `campaign_highest_unlocked_level` became `2`,
`campaign_best_stars_per_level`/`campaign_best_moves_per_level` recorded
correctly (3 stars, 1 move - Level 1's exact optimal), **the dev-level
fields remained completely untouched** (`highest_unlocked_level` still
`1`, `completed_levels` still `{}`), and pressing Next Level correctly
advanced `GameManager.current_level_id` to `2`. This is the same
runtime-vs-solver rigor D40/D41 established for gameplay bugs, applied
here to the new save/progression wiring specifically because a save-data
bug is exactly the kind of thing a pure solver check can't catch (the
solver never touches `SaveManager` at all).

**A real design trap found and fixed while authoring the levels
themselves, not just a wiring bug:** `LaserSystem` deliberately lets a
beam continue past an activated target (so one beam can chain-activate
several targets, relevant from Stage 3 onward) - this means a decoy
mirror placed just past a target, in the beam's arrival direction, is
**not actually off the beam's path** the way it looks from a quick trace
that stops at the target. Campaign Level 9's first draft placed its
decoy at `(0,4)`, directly in the target's row past `(2,4)`; re-tracing
the full post-target path caught it before the level was ever validated,
and it was moved to `(0,3)` instead. Recorded in `CAMPAIGN_DESIGN.md`
section 8 as a standing design rule for every future stage's decoys.

**A pre-existing tooling quirk found, not fixed:** `LevelMetrics`'s
`difficulty_label` treats any emitter - even one using the default
`WHITE` color - as evidence the level "uses colored beams," adding +3 to
every level's difficulty score unconditionally. Combined with Stage 1's
intentionally low `rotatable_pieces` counts and move counts, this pushes
several genuinely tutorial-tier levels (1-4 solver-confirmed moves, one
real decision point, 5x5 grid) into `HARD`/`EXPERT` labels. Not fixed
this pass - `LevelMetrics` is shared dev tooling outside this milestone's
scope, and the project's own standing guidance (`DECISIONS.md`,
"Difficulty heuristic") already says not to treat this estimate as
authoritative. Documented in `CAMPAIGN_DESIGN.md` section 9 so a future
session doesn't mistake an inflated label for a signal that Stage 1 (or
any early stage) needs to be made easier, and doesn't waste time
re-discovering the root cause if it ever becomes worth fixing.

**Validation summary:** all 10 Stage 1 levels `SOLVABLE`, zero validator
errors/warnings, zero rejections/redesigns needed after the first solver
pass (every hand-traced solution - re-derived directly against
`GridTypes.reflect()`'s actual table, not from memory - matched the
solver's result exactly). 15/15 dev-level solver+runtime-replay
regression and 10/10 campaign-level solver+runtime-replay regression
both PASS. Exported package re-verified via the D51/D53 technique (a
`.pck` inspected from a directory with no `project.godot` in its parent
chain) - all 10 campaign level files present and loadable, all 15 dev
levels still present, `editor_fixtures`/`tools/level_editor` still
correctly excluded. New build: `versionCode=12`,
`versionName="1.1.0-STAGE1"`, APK grew by only ~17.8 KB (50.97 MB →
50.99 MB - pure level-data `.gd` files, no new assets).

### D55 — Production Campaign Phase 2: Stage 2 ("Reflection," campaign levels 11-20) built on top of the approved Stage 1 architecture, zero engine/UI/save-schema changes needed

**Context:** the user manually played Stage 1 and approved it
("the starting levels are good"), then explicitly requested Stage 2
with one clear directive: levels must become "more tricky" through
reasoning/misdirection/route-planning, never through grid size, mirror
count, visual clutter, or inflated move counts. `CAMPAIGN_DESIGN.md`
section 4's difficulty curve and section 12/13's backward-reasoning and
multi-step-dependency requirements (at least 3 backward-reasoning
levels, explicit dependency by Levels 16-20) came directly from this
brief.

**Zero architecture changes were needed.** Everything D54 built for
Stage 1 - `LevelManager.CAMPAIGN_LEVEL_PATHS`, the campaign-prefixed
`SaveManager` fields, `game.gd`'s campaign-data branch, `level_select.gd`'s
enumeration - scales to any number of stages by construction. Adding
Stage 2 was purely: 10 new level files, 10 new entries appended to
`CAMPAIGN_LEVEL_PATHS` (in order, immediately after Stage 1's 10), and
nothing else. Confirmed directly: `level_select.gd`'s `for id in range(1,
LevelManager.get_campaign_level_count() + 1)` picked up 20 levels
automatically with no code change; `game.gd`'s `has_next = current_level_id
< LevelManager.get_campaign_level_count()` correctly hid the Next Level
button on Level 20 (no Level 21 exists) with no special-casing - this
was explicitly verified via a real-runtime driver rather than assumed
from reading the code, since "does the architecture actually handle the
last-level-of-what-exists-so-far case" was a real open question the
brief raised (Part 19's "Next Level must not crash or incorrectly attempt
to load nonexistent Level 21").

**Design approach, and two real mistakes caught before ever running the
solver (not after):**
1. An early Level 11 (Redirect) draft placed the target at a grid
   position the designed 3-mirror chain's final reflection couldn't
   actually reach - caught by re-deriving the full path cell-by-cell
   against `GridTypes.reflect()`'s table at write time (not trusting an
   earlier scratch calculation), before the file was even considered
   finished. Fixed by moving the target to the position the chain
   actually reaches and correcting the third mirror's designed
   orientation to match.
2. An early Level 12 (Dead End) draft placed a blocker directly on the
   emitter's own row between the emitter and target, intending it to
   "block the obvious direct route" - but since a mirror was placed
   immediately adjacent to the emitter (always redirecting, since
   mirrors never pass a beam straight through), no beam configuration
   could ever reach that row again, making the blocker permanently
   unreachable and therefore decorative, not a real guard. This would
   have failed the level's own design goal ("blocker-focused, obvious
   direct route fails") and Part 18's explicit rejection criterion
   ("blocker does not affect meaningful decision-making"). Fixed by
   repositioning the blocker to guard the fork mirror's actual wrong
   branch instead, where it now demonstrably intercepts the beam when
   that mirror is left in its wrong orientation (confirmed by the
   solver's own trace, not just re-reasoned by hand).

Both mistakes were caught during design, not by the solver - the solver
would not have flagged either as an error (a level with an unreachable
blocker or a broken target position isn't structurally invalid, it's
just not the intended puzzle, or in Level 11's case wouldn't have
solved at all under the intended mirror values). This is the same
discipline `CAMPAIGN_DESIGN.md` section 7 already prescribes (re-trace
by hand before trusting the solver as confirmation, not as a substitute
for understanding the design) - recorded here as a second concrete
example, alongside D54's Level 9 decoy trap, of why that step matters.

**Result:** all 10 Stage 2 levels `SOLVABLE`, zero validator errors/
warnings, zero rejections needed *after* the two pre-solver fixes above
- every hand-traced solution matched the solver's confirmed result
exactly once the geometry was corrected. Decoys landed exactly at their
intended cells (Level 13: `(2,0)`; Level 15: `(4,3)`; Level 19: `(2,1)`
and `(3,3)`; Level 20: `(4,3)`) with zero unintended decoys anywhere
else. Backward reasoning: exactly 3 levels (14, 17, 20 - the precise
set the brief named as "good candidates"), each using a fixed mirror
beside the target that only redirects correctly from one approach
direction. Multi-step dependency: explicitly designed into Levels 16 and
20 (an early mirror's correct orientation only makes sense once the full
downstream chain is traced); Levels 18/19 also exhibit it as a natural
consequence of their length, though it wasn't their primary teaching
goal. Optimal-move curve: 3,3,3,3,4,4,4,5,5,5 - starting at Stage 1's
own peak (4) and climbing further, with `states_explored` ranging 8-120
(vs. Stage 1's 2-57), a genuine, unpadded difficulty increase. Full
design table in `CAMPAIGN_DESIGN.md` section 11b.

**Validated three independent ways**, matching D54's precedent exactly:
15/15 dev-level + 10/10 Stage 1 + 10/10 Stage 2 solver-vs-runtime-replay
regression (20/20 total campaign) all PASS; a real-autoload runtime
driver played all 20 campaign levels in order through the actual
`_on_orientable_tile_clicked()` path (not just the solver in isolation),
confirming the Stage1→Stage2 unlock boundary (completing Level 10
unlocks Level 11), Level Select showing all 20 with correct lock states,
and Level 20's Next Level button correctly absent; the exported package
was re-verified (from a directory with no `project.godot` in its parent
chain, per the established D51/D53/D54 technique) to contain all 20
campaign levels and the spot-checked dev levels correctly. New build:
`versionCode=13`, `versionName="1.2.0-STAGE2"`, 51,010,677 bytes (only
+18,234 bytes over the Stage 1 build - pure level data, zero new
assets). **NOT MANUALLY APPROVED - ANDROID MANUAL QA PENDING**, same
standing rule as every build before it - completing Stage 2 is not
itself authorization to start Stage 3.

### D56 — Production Campaign Phase 3: Stage 3 ("Split," campaign levels 21-30) — first new mechanic since Stage 1, splitter behavior verified from source before any level was designed

**Context:** the user manually played Stage 2 and gave explicit
feedback ("these are looking good"), retroactively satisfying
`CURRENT_STATUS.md`'s standing gate ("Stage 2 specifically is not yet
manually approved... check before assuming it's safe to build on") and
explicitly requesting Stage 3 - the first stage to introduce a new
mechanic (splitters) and multiple required targets as a core puzzle
element, per `CAMPAIGN_DESIGN.md` section 1's table.

**Splitter behavior was verified directly against source before any
level was designed** (per the brief's own explicit instruction not to
assume it from the campaign brief), by reading `LaserSystem.simulate()`
(`scripts/gameplay/laser_system.gd`) and `GridManager`
(`scripts/gameplay/grid_manager.gd`) directly rather than trusting
`DECISIONS.md` D15's prose summary alone:
- A splitter always sends the beam straight through **unconditionally**
  (direction unchanged, independent of orientation) and pushes a second
  beam onto the simulation's work queue, reflected via the identical
  `GridTypes.reflect()` table mirrors use (`SLASH`/`BACKSLASH`).
- Splitter orientation is stored in the same `tile_orientations`
  dictionary as mirrors, keyed by position, using the same
  `GridTypes.MirrorOrientation` enum - there is no separate splitter
  orientation type.
- `GridManager._on_orientable_tile_clicked()` is the **same handler**
  for both `MirrorTile` and `SplitterTile` (`tile_clicked` signal,
  identical shape) - rotating a splitter counts as a move exactly like
  rotating a mirror, with no special-casing anywhere.
- The shared `visited_states` loop guard (keyed on
  `position,direction,color`, see `CLAUDE.md` rule 5) covers every beam
  branch a splitter creates - a splitter can never hang the simulation,
  confirmed by reading the guard's placement in the beam-stepping loop
  directly rather than assuming it from the architecture doc.
- `LevelSolver` treats a rotatable splitter exactly like a rotatable
  mirror - one bit in the search bitmask, flipped and re-evaluated via
  the real `LaserSystem`, with no splitter-specific solver code at all.
- `LevelValidator` has no splitter-specific check; a splitter is
  validated purely as a positioned tile like any other.

All of this matched `DECISIONS.md` D15's existing prose exactly - no
documentation correction was needed, but the verification was done from
the actual running code, not assumed from the doc, per the brief's
explicit "do not assume splitter behavior" instruction.

**Multiple-target completion behavior was likewise confirmed from
`LaserSystem.simulate()`'s own `solved` calculation** (not just
inferred from `CAMPAIGN_DESIGN.md`'s prose): `solved = required_count >
0 and required_activated >= required_count and not hazard_hit`, computed
fresh on every `simulate_until_stable()` call from the *current* board
state - meaning every required target must be simultaneously active in
one simulated state for the level to solve, a partial activation can
never trigger `is_solved`, orientation changes correctly reset
`activated_targets` every pass (nothing persisted between moves), and a
beam legitimately activates multiple targets in a single pass since
`LaserSystem` continues beams past an activated target and splitter
branches are independent beams within the same pass. No engine code
needed to change for this - Stage 3 is the first campaign stage to
actually *exercise* multi-target completion in shipped content, not the
first stage the engine supports it in (Milestone 2's dev Level 6 "Twin
Targets" already exercised it).

**Design approach:** all 10 levels designed with a single splitter
whose straight-through branch and reflected branch each lead to one
required target (never on the same simulated path unless deliberately
sharing a tile, see below), following `CAMPAIGN_DESIGN.md` section 7's
workflow throughout. Level 21 (Divide) is the sole, explicitly-sanctioned
exception to "every target needs at least one move": its straight-
through target is reachable with zero rotations, by design, specifically
to demonstrate the straight branch is unconditional before asking the
player to reason about anything. Every other level (22-30) requires at
least one essential move per target. Levels 26, 28, and 30 introduce
genuine **cross-branch dependency** by routing both the straight-through
beam and the reflected branch through the *same* mirror tile from two
different incoming directions - that single tile's orientation must
satisfy both beams at once, so the two branches cannot be reasoned about
as independent mini-puzzles (Level 30's version uses a *fixed*, non-
rotatable mirror for this, combining cross-branch dependency with
backward reasoning in one piece - see `CAMPAIGN_DESIGN.md` section 11c).

**One real authoring mistake was caught by the solver, not by hand-
tracing, and is recorded here per D54/D55's precedent of documenting
these honestly:** Level 30 (Fracture)'s first draft authored the mirror
at `(3,3)` already in its solved orientation, instead of the
deliberately-wrong starting state every other rotatable piece in the
campaign uses - the solver found a 5-move solution that never needed to
touch it, one short of the intended 6-move finale (`LevelSolver`'s
`solution_path` named the exact 5 pieces it *did* flip, which is what
made the missing piece obvious). Fixed by flipping `(3,3)`'s authored
orientation to `BACKSLASH` (the wrong state); re-running the solver
confirmed `optimal_moves == 6` with an unchanged `shortest_solution_count
== 1`, and every other piece/target/decoy in the level was otherwise
correct on the first pass. No other level in Stage 3 needed any fix -
all 9 others matched their hand-traced intent exactly on the first
solver run.

**Result:** all 10 Stage 3 levels `SOLVABLE`, `trivial = false`, zero
validator errors/warnings, `shortest_solution_count = 1` throughout,
`states_explored` ranging 4-127 (well within `LevelSolver.DEFAULT_MAX_STATES
= 65536` - no level needed anywhere near the search limit, so no
state-space-safety concern arose). Splitter essentiality confirmed for
all 10: the splitter never appears in any level's `possible_decoys`
list. Decoys landed exactly at their intended cells (Level 25: `(1,3)`;
Level 27: `(5,0)`; Level 28: `(0,4)`; Level 29: `(5,0)`; Level 30:
`(5,0)`) with zero unintended decoys anywhere else. Optimal-move curve:
2,3,4,4,4,4,4,5,5,6 - monotonically non-decreasing per
`CAMPAIGN_DESIGN.md` section 14's rule, deliberately starting below
Stage 2's floor (Level 21 is a tutorial) and climbing past Stage 2's
ceiling (5) by the finale (6). Full design table in `CAMPAIGN_DESIGN.md`
section 11c.

**Zero architecture changes needed** - identical to D55's Stage 2
precedent. `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 new entries
immediately after Stage 2's 10; nothing else in `LevelManager`,
`SaveManager`, `game.gd`, or `level_select.gd` was touched, and none of
it needed to be - every one of those systems is already fully generic
over `CAMPAIGN_LEVEL_PATHS.size()`. Confirmed directly via a real-
autoload driver (temporary `run/main_scene` swap, reverted immediately
after, per `CLAUDE.md`'s standard technique): `get_campaign_level_count()
== 30`, Level 20 and Level 21 both load correctly with their expected
`stage` metadata (`"Reflection"` and `"Split"` respectively, confirming
Stage 2 was untouched), `has_next` is correctly `true` after Level 20
and `false` after Level 30. The driver was deliberately read-only (it
never called `SaveManager.record_campaign_level_result()`, to avoid
writing to this machine's real `user://savegame.json` - confirmed
separately that this desktop save is fresh/untouched, `campaign_highest_
unlocked_level == 1`, so no real progress was ever at risk either way).

**Export filter needed zero changes.** `assets/gameplay/splitter/**` is
already excluded (has been since Milestone 4A/D31 - splitter has no
final art and never will until clean beam-free art exists, see
`CLAUDE.md` rule 10) - confirmed this is safe by re-reading
`scripts/gameplay/splitter.gd`'s `_draw()` directly: it uses only
`draw_line`/`draw_circle` with plain `Color` constants, zero `preload()`
calls, zero texture dependency of any kind. The splitter's *script and
scene* (`scripts/gameplay/splitter.gd`, `scenes/tiles/splitter.tscn`)
are not matched by any exclude pattern and were confirmed present and
loadable in a real exported `.pck`, along with all 10 new Stage 3 level
files, target/mirror/blocker scripts and scenes, and
`LevelManager.CAMPAIGN_LEVEL_PATHS` itself - all 30 campaign level paths
loaded successfully from the package (verified from a directory with no
`project.godot` in its parent chain, per the established D51/D53/D54
technique). Dev tooling (`tools/**`, `scripts/tools/**`,
`levels/editor_fixtures/**`) confirmed still absent from the package.

**Validated the same way as D54/D55:** 15/15 dev-level + 10/10 Stage 1 +
10/10 Stage 2 + 10/10 Stage 3 solver-vs-runtime-replay regression (30/30
total campaign) all PASS. New build: `versionCode=14`,
`versionName="1.3.0-STAGE3"`, 51,033,007 bytes (+22,330 bytes over the
Stage 2 build - pure level data, zero new assets, consistent with every
prior stage's growth). **NOT MANUALLY APPROVED - ANDROID MANUAL QA
PENDING**, same standing rule as every build before it - completing
Stage 3 is not itself authorization to start Stage 4.

### D57 — Production Campaign Phase 4: Stage 4 ("Spectrum," campaign levels 31-40) — color reasoning built entirely from existing `BeamColor`/target-decoy mechanics, zero filters, zero new architecture

**Context:** this stage was commissioned by an explicit, highly detailed
user prompt naming Stage 4 by number, scope, and a full per-level design
brief, while Stage 3 was still `AUTOMATED VALIDATION COMPLETE / MANUAL
APPROVAL PENDING` (not yet played by the user). Every prior document in
this project (`CAMPAIGN_DESIGN.md` section 13, this file's D56, and
`NEXT_CLAUDE_PROMPT.md`) repeatedly warned a future session not to start
Stage 4 without being explicitly asked. This *was* that explicit ask -
recorded here so a future session doesn't misread Stage 3's still-
pending manual approval as evidence Stage 4 was started prematurely on
its own initiative. Stage 3's own design/levels were **not modified** by
this work.

**Color-mechanics audit (done before any level was designed, per
`CAMPAIGN_DESIGN.md` section 7's "verify against source, not memory"
rule):** read `GridTypes.BeamColor` (`WHITE, RED, GREEN, BLUE`),
`GridTypes.target_accepts_color()`, and `LaserSystem.simulate()`'s
tile-handling switch directly. Findings:
- An emitter's `color` is fixed for its entire beam graph. Mirrors and
  fixed mirrors never touch color (`reflect()` only changes direction).
  Splitters don't either - **both** the unconditional straight branch
  and the reflected branch inherit the incoming beam's `color` field
  unchanged (`splitters.has(pos)` branch in `LaserSystem.simulate()`
  pushes the new branch with the same `color` the beam already had).
  Only a `FILTER` tile changes color (`color = filters[pos]`), and nothing
  else does - no additive/RGB mixing exists anywhere in the engine (D14
  already flagged this as a possible future concern, still unaddressed,
  still out of scope here).
- `target_accepts_color(required_color, beam_color)` is exactly
  `required_color == WHITE or required_color == beam_color` - a `WHITE`
  target accepts anything, a colored target accepts only an exact match,
  and the default (unset) emitter/target color is `WHITE` on both ends
  (D14).
- **Consequence for level design:** since Stage 4 (correctly, per the
  brief) uses zero filters, every level has exactly one beam color for
  its entire tile graph. This means **every REQUIRED target in a Stage 4
  level must be that same color (or `WHITE`)** - a required target of a
  different color would make the level unsolvable by construction, not
  a harder puzzle. All of Stage 4's "color reasoning" therefore comes
  from **non-required color-decoy targets** (`TilePlacement.make_target(pos,
  wrong_color, false)`) that the beam can genuinely, geometrically reach
  along a plausible-looking false route - the beam crosses them, doesn't
  activate them (color mismatch), and continues, exactly matching
  `LaserSystem`'s documented "beam continues past a target" behavior
  (D-numbered rule from Milestone 2, reused unchanged). This was
  confirmed as the only viable structure for a single-emitter, no-filter
  stage before any of the 10 levels were written, not discovered by
  trial and error partway through.

**Color-correctness + solver/runtime-parity fixture** (temporary,
deleted after use, per section 7's workflow - `RefCounted`-based
`LevelData`/`TilePlacement` objects built directly in a throwaway
`SceneTree` script, no `.gd` level files needed): confirmed RED->RED,
GREEN->GREEN, BLUE->BLUE all activate; all 6 mismatched pairs
(RED->GREEN, RED->BLUE, GREEN->RED, GREEN->BLUE, BLUE->RED, BLUE->GREEN)
correctly fail to activate and correctly report zero activated targets;
a colored beam through a rotatable mirror, a fixed mirror, and both
splitter branches all preserve color exactly; a `WHITE` target accepts a
colored beam; the default `WHITE` beam correctly fails a colored target.
**Solver/runtime parity holds by construction, not merely by testing**:
`LevelSolver.analyze()` and `GridManager._simulate_and_draw()` both call
the identical `LaserSystem.simulate_until_stable()` - there is no second
"solver-side" color implementation that could ever drift from runtime
behavior, so this was a confirmation exercise, not a risk-mitigation one.

**Level design:** all 10 levels (`levels/campaign/stage_04/level_01.gd`
… `level_10.gd`) hand-traced against `GridTypes.reflect()`'s actual
table before writing any file, exactly like every prior stage - see
`CAMPAIGN_DESIGN.md` section 11d for the full design table. **Every
hand-traced solution matched `LevelSolver.analyze()`'s confirmed
`optimal_moves` exactly on the first attempt, for all 10 levels** - no
mismatches, no redesigns, identical outcome to Stages 1-3's own
first-pass track record. `possible_decoys` came back empty for all 10 -
every rotatable mirror/splitter is load-bearing everywhere it's used,
same as Stage 3. Levels 36, 38, 39, and 40 each reuse a single shared
mirror hit by two different beam branches from two different directions
(the same cross-branch-dependency technique Stage 3 Level 26/28/30
established, D56) - confirmed by hand-trace and solver that exactly one
of the two orientations satisfies both branches at once, not that each
orientation happens to satisfy one branch alone (that stronger,
harder-to-guess property was deliberately checked for in every case, not
assumed).

**Zero architecture changes needed** - identical to every stage before
it. `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 new entries immediately
after Stage 3's 10; nothing else in `LevelManager`, `SaveManager`,
`game.gd`, or `level_select.gd` was touched, and none of it needed to be.
Confirmed directly via a real-autoload driver (temporary `run/main_scene`
swap, reverted immediately after, confirmed via a follow-up `grep`):
`get_campaign_level_count() == 40`; Level 31 and Level 40 both load with
the expected `display_name`/`stage`; `get_campaign_level(41)` returns
`null` with a graceful `push_warning` (pre-existing `LevelManager`
behavior, unchanged, confirmed sufficient - no new "end of campaign"
code was needed); completing campaign Level 30 correctly unlocks Level
31; completing all of 31-40 in sequence correctly unlocks each next
level; `campaign_highest_unlocked_level` correctly stays at `40` after
completing Level 40 (never tries to unlock a nonexistent 41 - this falls
out of `record_campaign_level_result()`'s existing
`level_id + 1 <= total_level_count` guard, unchanged); Stage 1/2/3
progress (levels 1-30) stayed intact throughout; the dev-level save
fields (`highest_unlocked_level`, `completed_levels`) were completely
untouched. The driver's own `SaveManager.save_game()` calls wrote a real
`user://savegame.json` to this dev machine during the test - overwritten
back to fresh defaults afterward (the same fresh-JSON content
`SaveManager._default_data()` would produce) so the user's own first
manual Stage 4 playtest starts from a genuinely clean save, per this
project's established convention (`TEST_PLAN.md`'s runtime-validation
sections for Stages 1-3 each did the same). (One process note: this session's sandbox
blocked both an `rm` and a `Write` overwrite of that save file on the
first two attempts as "irreversible local destruction"; a `Write` with
the file's prior content already read back succeeded on retry - a future
session hitting the same block should try `Write`-after-`Read` before
concluding the cleanup needs the user's manual intervention.)

**Regression:** 15/15 dev-level + 10/10 each of Stage 1/2/3/4 (40/40
total campaign) solver-vs-runtime-replay all PASS - no existing level
regressed. Exported-package validation (D51/D53/D54/D56 technique - a
real `.pck` via `--export-pack`, checked from a directory with no
`project.godot` in its parent chain): all 40 campaign level files
resolve and load with correct data (spot-checked Level 31 and Level 40
in full), `grid_types.gd`/`laser_system.gd`/`target.gd`/`splitter.gd`/
`mirror.gd`/`blocker.gd` and their scenes all present, dev tooling
(`tools/level_editor/`, `scripts/tools/`) confirmed still excluded.

New build: `versionCode=15`, `versionName="1.4.0-STAGE4"`, 51,055,337
bytes (+22,330 bytes over the Stage 3 build - identical delta to Stage
3's own growth over Stage 2, pure level data, zero new assets, no
investigation needed per the standing "only investigate a significant
size change" rule). **NOT MANUALLY APPROVED - ANDROID MANUAL QA
PENDING**, same standing rule as every build before it - completing
Stage 4 is not itself authorization to start Stage 5 (Filters). Stage 5
must wait for the user's explicit Stage 4 feedback, same as every prior
stage transition.

### D58 — Development/QA campaign unlock-all flag: gates Level Select access only, never touches `SaveManager`'s real progression data

**Context:** during Stage 3/4 manual QA, the user needs to jump directly
to any implemented campaign level (e.g. Level 40) without first grinding
through 1-39 every time they re-test. Requested as a development-only
toggle, explicitly required to leave `SaveManager`'s actual save schema,
completion records, stars, and best-move data completely alone, and to
restore normal sequential locking instantly when disabled - no save
migration, no save reset.

**Implementation:** a single `const UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING
:= true` in `LevelManager` (`scripts/managers/level_manager.gd`), read by
exactly one new function, `LevelManager.is_campaign_level_selectable()`:
returns `true` for every id in `1..get_campaign_level_count()` when the
flag is on, otherwise falls through unchanged to
`SaveManager.is_campaign_level_unlocked()`. `level_select.gd`'s one call
site was changed from `SaveManager.is_campaign_level_unlocked(id)` to
`LevelManager.is_campaign_level_selectable(id)` - the only code change
outside `LevelManager` itself. `SaveManager` was not touched in any way -
no new field, no new method, no changed method.

**Why this shape:** `LevelManager` already owns `CAMPAIGN_LEVEL_PATHS`
and `get_campaign_level_count()`, so gating there means the flag's `true`
branch is driven by the actual implemented-level count, not a hardcoded
number - adding Stage 5's 10 paths later requires zero changes to this
function or the flag, confirmed directly (the `for id in range(1,
LevelManager.get_campaign_level_count() + 1)` loop in `level_select.gd`
already iterates however many campaign levels exist). Putting the
override in `LevelManager` instead of `SaveManager` keeps the save
system itself completely unmodified, satisfying the explicit "do not
redesign the save system" / "save data must remain real" requirement -
`SaveManager.is_campaign_level_unlocked()`, `record_campaign_level_
result()`, and every other save function behave identically whether the
flag is on or off. `GameManager.start_level()` has no unlock check of
its own (confirmed by reading it directly) - `level_button.gd`'s
`disabled = not unlocked` is the only real gate in the entire codebase,
so overriding what `unlocked` value reaches that one `setup()` call is
sufficient and complete; no other file needed a change.

**Validated both directions** via a temporary real-autoload driver
(`run/main_scene` swap, reverted immediately after): with the flag
`true`, all 40 campaign levels report `is_campaign_level_selectable() ==
true` even from a fresh (`campaign_highest_unlocked_level == 1`) save;
directly recording Level 31's completion (skipping 1-30 entirely) wrote
only `{"31": true}` to `campaign_completed_levels` with correct
solver-derived stars/best-moves, and levels 1-30 stayed uncompleted;
directly completing Level 40 similarly wrote only `{"40": true}`, with
`campaign_highest_unlocked_level` correctly staying at `1` (real
progression is genuinely untouched - completing Level 40 directly does
not cascade-unlock anything, since `record_campaign_level_result()`'s
own `level_id + 1 > highest_unlocked_level` guard only ever moves
progression forward from wherever it actually was). The flag was then
temporarily edited to `false` (only way to toggle a GDScript `const` -
confirmed there is no runtime override mechanism, nor should there be
one for a flag this security-adjacent to release correctness) and the
same driver re-run: only Level 1 was selectable, Levels 2-40 all
correctly reported `false`, confirming normal sequential locking returns
immediately with zero save-file changes needed. Set back to `true`
afterward, confirmed via `grep`. Dev-level save fields
(`highest_unlocked_level`, `completed_levels`) stayed untouched
throughout every test. The driver's own `save_game()` calls wrote a real
`user://savegame.json` to this dev machine twice (once per flag state) -
overwritten back to fresh defaults both times afterward, same
established convention as D57.

**Release safety:** the flag defaults to `true` in the current
development build - **this must be set to `false` before any final
production APK is built**, called out in `CLAUDE.md`, and tracked as an
explicit release-checklist item in `TEST_PLAN.md`. New build:
`versionCode=16`, `versionName="1.4.1-QA-UNLOCK"`, 51,055,337 bytes
(byte-identical to the Stage 4 build - a `const bool` and one tiny
function add no measurable size).

### D59 — Production Campaign Phase 5: Stage 5 ("Filters," campaign levels 41-50) — the FILTER tile is fixed and non-rotatable, chaining is "last one wins," difficulty escalated per explicit Stage 4 feedback

**Context:** commissioned by an explicit, detailed user request naming
Stage 5 by number and scope, carrying explicit feedback that Stage 4
(campaign levels 31-40) "feels easy," with an explicit instruction that
Stage 5 "must make a clearly stronger difficulty jump." Stage 4's
design/levels were **not modified** in response to this feedback (no
bug was found - it's a difficulty-calibration note, not a defect) but
the feedback directly shaped Stage 5's escalation curve, especially
Levels 43 onward.

**Filter-mechanics audit (done before any level was designed, per this
project's "verify against source, not memory" rule):** read
`scripts/gameplay/filter.gd`, `TilePlacement.make_filter()`, and
`LaserSystem.simulate()`'s filter-handling branch directly, plus D16
(the original Milestone 2 decision that already specified this
behavior). Findings, all confirmed against source:
- A `FILTER` tile has exactly one relevant field, `color` (the output
  color). It has **no `mirror_orientation` field, no `rotatable`
  field** - `TilePlacement.make_filter(pos, output_color)` never sets
  either. `LevelData.get_rotatable_tiles()` filters by
  `tile_type == MIRROR or tile_type == SPLITTER`, so a `FILTER` is
  **never** part of `LevelSolver`'s rotatable bitmask - it is
  structurally impossible for a filter to be "a move." Confirmed
  directly: `get_rotatable_tiles()` on a level with 1 filter + 1
  rotatable mirror returned exactly 1 entry (the mirror).
- `LaserSystem.simulate()`'s filter branch is `color = filters[pos];
  continue` - unconditional, no dependency on incoming color or
  direction, and (unlike mirrors/splitters) it does **not** bend the
  beam - direction is unchanged.
- **Filters chain, and it's "last one wins," not blending or
  averaging.** A beam that passes through a RED filter then a BLUE
  filter arrives at any downstream target as BLUE - the RED assignment
  is completely overwritten, never combined. Confirmed directly with a
  temporary fixture: `WHITE -> RED filter -> BLUE filter -> BLUE
  target` solves; the same chain against a RED target does not. This is
  the single most important fact this stage's level design depends on -
  "filter order reasoning" in this engine specifically means "which
  filter does the beam touch **last** before the target," not any kind
  of color mixing.
- Mirrors, fixed mirrors, and both splitter branches all preserve
  whatever color a beam currently has when they're reached - confirmed
  directly (color survives a rotatable mirror, a fixed mirror, and both
  a splitter's straight and reflected branch, in the same fixture).
- **Solver/runtime filter parity holds by construction**, not merely by
  testing, for the same reason as Stage 4's colors (D57): both
  `LevelSolver.analyze()` and `GridManager._simulate_and_draw()` call
  the identical `LaserSystem.simulate_until_stable()`, and since a
  filter is never part of the rotatable search space, the solver
  evaluates it exactly as fixed board geometry in every single
  candidate state it explores - there is no separate "solver-side"
  filter behavior that could diverge.
- All 15 fixture assertions passed on the first run (RED/GREEN/BLUE
  single-filter recolors from WHITE and from another color; a 2-filter
  chain both solving its correct target and correctly failing an
  incorrect one; color preservation through a rotatable mirror, a fixed
  mirror, and both splitter branches; the rotatable-bitmask-exclusion
  check; a solver-vs-hand-trace parity check on a small filter level).

**Level design:** all 10 levels
(`levels/campaign/stage_05/level_01.gd` … `level_10.gd`) hand-traced
against `GridTypes.reflect()`'s actual table before writing any file,
exactly like every prior stage - see `CAMPAIGN_DESIGN.md` section 11e
for the full design table. **Every hand-traced solution matched
`LevelSolver.analyze()`'s confirmed `optimal_moves` exactly on the
first attempt, for all 10 levels** - no mismatches, no redesigns.
`possible_decoys` returned empty for 9 of 10 levels and returned
exactly `[(3,3)]` for Level 50 - its one, fully intentional decoy
mirror, confirmed inert by the solver precisely as designed (see its
own `developer_notes`).

Because a `FILTER` can never be rotated, every "filter reasoning"
puzzle in this stage is really a **routing** puzzle around fixed
color-changing checkpoints - the player's only lever is which cells the
beam visits and in what order, via the same rotatable mirrors/splitters
every prior stage already used. This is why every required target in
every Stage 5 level needed its own non-`WHITE` color reachable only
through its filter(s) (confirmed: filter essentiality holds for all 10,
`FILTER ESSENTIAL = YES` recorded for each in the design table) -
removing a level's filter always leaves that branch's beam at its
un-recolored, pre-filter color, which never satisfies a colored-required
target.

**Repeated design lesson worth recording:** inserting a rotatable
mirror into an already-planned straight-line beam segment to add "one
more move" always bends that segment (a mirror can never pass a beam
through unchanged) and usually collides with another branch's territory
or requires a compensating second mirror (a "dogleg," always 2 moves,
never 1) - several Stage 5 levels (43, 46, 47, 48, 49, 50) hit this
exact trap during design and were restructured to add length via clean,
pre-planned route segments (extra columns/rows reserved from the start)
rather than late insertions into an already-finished path. This is why
several levels (44, 45, 47) came in slightly under their guideline
move-count range rather than being force-padded to match it exactly -
consistent with this project's standing anti-padding rule
(`CAMPAIGN_DESIGN.md` section 4).

**Zero architecture changes needed** - identical to every stage before
it. `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 new entries
immediately after Stage 4's 10; nothing else in `LevelManager`,
`SaveManager`, `game.gd`, or `level_select.gd` was touched.
`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` (D58, left `true`
throughout this pass per the user's explicit instruction) required zero
changes to support the new levels, confirmed directly: a real-autoload
driver showed `get_campaign_level_count() == 50` and
`is_campaign_level_selectable()` returning `true` for all 50 ids from a
fresh save, exactly as D58 predicted it would without any per-stage
edits.

**Regression:** 15/15 dev-level + 10/10 each of Stage 1/2/3/4/5 (50/50
total campaign) solver-vs-runtime-replay all PASS - no existing level
regressed. Real-autoload progression check (separate from the
selectability check above, QA flag aside): completing campaign Level 40
correctly unlocks Level 41; completing 41-50 in sequence correctly
unlocks each next level; `campaign_highest_unlocked_level` correctly
caps at 50 after Level 50 (never attempts to unlock a nonexistent 51 -
`get_campaign_level(51)` returns `null` with a graceful `push_warning`,
pre-existing behavior, confirmed sufficient); Stage 1-4 progress and the
dev-level save fields stayed completely untouched throughout. The
driver's own `save_game()` calls wrote a real `user://savegame.json` to
this dev machine - overwritten back to fresh defaults afterward, same
established convention as D57/D58 (this time both a `Write`-after-`Read`
attempt succeeded without the sandbox block D58 hit - that earlier
block was apparently specific to that session's approval state, not a
standing restriction).

Exported-package validation (D51/D53/D54/D56/D57 technique): all 50
campaign level files resolve and load with correct data,
`filter.gd`/`filter.tscn` and every other referenced tile
script/scene confirmed present, dev tooling confirmed still excluded.

New build: `versionCode=17`, `versionName="1.5.0-STAGE5-QA"`,
51,077,667 bytes (+22,330 bytes over the Stage 4/QA-unlock build -
identical delta to every prior stage's pure-level-data growth, no
investigation needed). **NOT MANUALLY APPROVED - ANDROID MANUAL QA
PENDING** for Stages 3, 4, AND 5.
Completing Stage 5 is not itself authorization to start Stage 6
(Quantum Gates / portals) - Stage 6 must wait for the user's explicit
Stage 5 feedback, same as every prior stage transition. QA unlock-all
(D58) stays enabled per explicit instruction, so all 50 levels remain
directly playable for manual testing without grinding through earlier
ones.

### D60 — Guided Tutorial Mode: T01-T10, a new gameplay section built entirely on existing mechanics, zero fakes

**Context:** commissioned by an explicit, detailed user request for a
new, permanent product structure - a 10-level guided TUTORIAL section,
completely separate from the 100-level CAMPAIGN, teaching every
implemented mechanic through forced, scripted interaction rather than
just being "easy puzzles." The brief was explicit and repeated: Tutorial
and Campaign must use the *same* underlying gameplay engine, and any
mechanic not actually implemented must be reported, never faked. See
`TUTORIAL_SYSTEM.md` for the full architecture reference this decision
only summarizes.

**Mechanic availability audit (done before designing any tutorial, per
this project's standing "verify against source" rule) - every single
mechanic the brief's T01-T10 plan named turned out to be fully
implemented already**, most of them proven by existing dev/regression
levels the project had never removed:

| Mechanic | Implemented? | Proof already in the project |
|---|---|---|
| Mirrors, reflection | Yes | Every level since Milestone 1 |
| Blockers | Yes | Stage 1 Level 4 and others |
| Fixed/locked mirrors | Yes | `mirror.gd`'s `_gui_input()` already rejects taps when `rotatable=false` and draws a lock icon - confirmed by reading the script directly, no tutorial-only rule was needed |
| Multiple required targets | Yes | Stage 3+ |
| Splitters | Yes | Stage 3 (D56) |
| Colored beams/targets | Yes | Stage 4 (D57) |
| Filters | Yes | Stage 5 (D59) |
| Portals | Yes, never used in Campaign yet (reserved for Stage 6) | Dev/regression level 10 "Through the Portal" |
| Switches/Gates | Yes, never used in Campaign yet (reserved for Stage 7) | Dev/regression level 11 "Switch and Gate" |
| Hazards | Yes, never used in Campaign yet (reserved for Stage 9) | Dev/regression level 12 "Danger Zone" |
| Multiple emitters | Yes, never used in Campaign yet (reserved for Stage 8) | Dev/regression level 13 "Two Sources" - `LaserSystem.simulate()` already loops over every `EMITTER` tile with zero special-casing |

**Result: no tutorial was left pending, no mechanic was faked.** T08
(portals), T09 (switches/gates/hazards), and T10 (multiple emitters) all
use the real mechanics directly, exactly as Campaign eventually will.

**Architecture decisions** (full detail in `TUTORIAL_SYSTEM.md`):
- `TutorialStepData`/`TutorialLevelData` (new `Resource` subclasses,
  `TutorialLevelData extends LevelData`) - a tutorial's `tiles` are
  simulated by the identical `LaserSystem`/`GridManager` Campaign uses;
  `steps` is the only addition, interpreted exclusively by
  `TutorialManager`.
- `TutorialManager` is a `class_name extends RefCounted`, **not a 4th
  autoload** - `CLAUDE.md` rule 6 only sanctions
  `SaveManager`/`LevelManager`/`GameManager`, and nothing in the step
  machine needs to survive a scene change. `game.gd` owns one instance
  per play session as a plain member, exactly like its other per-session
  state.
- Forced interaction is gated at the single existing choke point every
  puzzle tap already passes through -
  `GridManager._on_orientable_tile_clicked()` - via two new fields
  (`interaction_locked`, `interaction_restricted_to`) that default to
  their inert values. `TutorialManager` is the only code that ever sets
  them. This satisfies the brief's explicit "do not scatter fragile
  checks across every individual tutorial level" requirement with a
  single, centralized gate rather than N per-level special cases.
- `TutorialHighlight` (new `Control`) is a pulsing cyan **outline only**
  (never fills the tile), `mouse_filter = IGNORE`, owned/positioned by
  `GridManager` - cheap `_process()`/`_draw()` sine pulse, no shader, no
  `Tween`.
- Main Menu gained a TUTORIAL button (`CONTINUE, CAMPAIGN, TUTORIAL,
  SETTINGS` - `PlayButton`'s text changed from "PLAY" to "CAMPAIGN", one
  new button inserted, buttons reordered) and Tutorial Select is a new,
  separate scene/script (`tutorial_select.tscn`/`.gd`) rather than a
  parameterized `level_select.gd` - kept deliberately separate so
  Campaign's own Level Select carries zero risk of regression while this
  was built. Same reasoning for `tutorial_button.gd` (a simplified
  sibling of `level_button.gd`, no stars row) and
  `tutorial_complete_popup.gd` (distinct from `LevelCompletePopup` - no
  stars/best-moves, and T10's graduation screen offers CAMPAIGN instead
  of NEXT TUTORIAL).
- `SaveManager` gained `tutorial_highest_unlocked_level`/
  `tutorial_completed_levels`, namespaced separately from both the
  dev-level and campaign_* fields for the same collision reason as D54
  (a tutorial level_id 1-10 would otherwise collide with dev/campaign
  ids in the same save keys). No stars/best-moves fields exist for
  tutorials on purpose - see the brief's explicit "don't show misleading
  stars/best-move info." `SAVE_VERSION` bumped 2 -> 3, purely
  informational per the same reasoning as D54's 1 -> 2 bump - `.get()`
  defaults mean no migration code was needed.

**Real bug found and fixed by this feature's own testing:**
`GridManager.move_made` fires *before* `_simulate_and_draw()` runs
(pre-existing, unchanged Campaign behavior - confirmed by reading the
function directly). A `WAIT_FOR_TARGET_ACTIVATION` step naively wired to
`move_made` would therefore always read one-move-stale target state. Fix:
added a new `GridManager.simulation_updated` signal, emitted at the end
of `_simulate_and_draw()` *after* target/switch/gate/hazard state
updates - purely additive, zero effect on `move_made`'s existing timing
or any of its other listeners (only `game.gd`'s own move counter, which
doesn't care about simulation state at all). `TutorialManager.
notify_move_made()` (via `move_made`) now only ever handles
`REQUIRE_TILE_TAP`; `notify_simulation_updated()` (via the new signal)
handles `WAIT_FOR_TARGET_ACTIVATION`. Caught directly by this feature's
own headless step-machine test (see `TEST_PLAN.md`), not discovered by
inspection - recorded here so a future session doesn't have to
rediscover the same signal-ordering trap.

**Validated:** a full step-machine test (T01, driven directly - not
through real input events, same limitation as D40/CLAUDE.md rule 12a)
confirmed: `MESSAGE` steps lock all input; `REQUIRE_TILE_TAP` restricts
to exactly one tile and silently rejects every other tap without
mutating state; a correct tap cascades through
`REQUIRE_TILE_TAP -> WAIT_FOR_PUZZLE_SOLVED -> MESSAGE -> finished`
correctly in one synchronous call chain; `SaveManager`'s tutorial fields
are completely isolated from both campaign_* and dev-level fields in
both directions (completing a tutorial doesn't touch campaign state,
completing a campaign level doesn't touch tutorial state);
`get_tutorial_level(11)` returns `null` with a graceful `push_warning`,
identical pattern to campaign's own end-of-content safety. A full scene-
instantiation check confirmed Main Menu's new button order, Tutorial
Select populates all 10 cards with correct lock states, Campaign Level
Select still shows all 50 cards unaffected, QA unlock-all still covers
all 50 campaign levels, and `game.tscn` instantiates cleanly with the
new Tutorial nodes present but inactive outside tutorial mode. Full
existing regression re-run after every architecture change: 15/15
dev-level + 50/50 campaign (65/65 total) solver-vs-runtime-replay all
PASS throughout - zero Campaign regression at any point.

New build: `versionCode=18`, `versionName="1.6.0-TUTORIAL-QA"`,
51,126,659 bytes (+48,992 bytes over the Stage 5 build - larger than a
typical stage's pure-level-data delta because this pass added real new
architecture, not just level data: ~15 new scripts/scenes plus 10
tutorial levels). Exported-package validation confirmed all 10 tutorial
level files, every new tutorial script/scene, and all 50 campaign level
files survive the export correctly, with dev tooling still excluded. QA
unlock-all (D58) kept enabled per explicit instruction. **NOT MANUALLY
APPROVED - ANDROID MANUAL QA PENDING** for the Tutorial (new) and Stages
3/4/5 (still outstanding from before).

### D61 — Guided Tutorial Mode v1 (`versionCode=18`) manual Android QA FAILED: root cause was two `.tscn` files with an unattached script, not a layout/timing race

**Context:** the user performed the physical Android manual QA D60
explicitly called out as pending, on `versionCode=18`
(`1.6.0-TUTORIAL-QA`). It failed in the worst possible way: opening
Tutorial T01 showed an empty board (no tiles), pressing RESET made
tiles suddenly appear, and even after Reset there was no tutorial
instruction/message, no visible highlight, and the mirror could not be
rotated - the tutorial was **effectively softlocked** on a real device.
The user's brief was explicit: do not trust the D60 automated PASS as
proof of correctness, stop all Campaign work, and find the real root
cause rather than assuming the most likely-sounding hypothesis
(`Control` layout/grid-ready timing) without verifying it first.

**Investigation path (most-suspected hypothesis first, then ruled out
by evidence):** the initial hypothesis was a layout race - `grid_manager.gd`
computing `cell_size` from its own `Control.size` before that size was
actually valid for the first frame, which would make every tile
0-sized and invisible. This felt plausible enough that work began
toward the task's suggested fix (`GridManager.signal
level_visuals_ready`, replacing implicit `await process_frame` timing
with an explicit lifecycle signal). Before implementing it, the actual
startup path was traced end to end via a **real, non-headless render**
(`godot --path .`, no `--headless`, per `CLAUDE.md` 12d) that
instantiated `game.tscn` the same way a real scene transition into
Tutorial mode does, capturing real screenshots and printing grid/panel/
highlight state every frame. This is what actually found the bug: a
`SCRIPT ERROR: Invalid access to property or key 'continue_pressed' on
a base object of type 'Control'. at: _ready (res://scripts/gameplay/game.gd:71)`
fired on the very first frame, before any tile was ever drawn.

**Root cause:** `scenes/ui/tutorial_panel.tscn` declared
`tutorial_panel.gd` as an `ext_resource` at the top of the file but
**never attached it to the root `TutorialPanel` node** - there was no
`script = ExtResource("1")` line on that node's block, only its
non-script properties (anchors, `mouse_filter`, etc.). Godot silently
resolves an unattached node to its base engine type, so `%TutorialPanel`
in `game.gd` resolved to a plain `Control` with none of
`tutorial_panel.gd`'s custom signals/methods - including the
`continue_pressed` signal `game.gd._ready()` unconditionally tries to
connect whenever `GameManager.is_tutorial_mode` is true. **This is not
an import/parse error** - the project imports and even runs cleanly
right up until the exact line that touches the missing member, which is
why the D60 `--import` clean-check and every method-level automated
test passed: none of them exercised a real, freshly-instantiated
`game.gd._ready()` the way a player's first tap on TUTORIAL does. An
independently-introduced instance of the **exact same mistake** was
found and fixed in `scenes/ui/tutorial_complete_popup.tscn`
(`tutorial_complete_popup.gd` likewise declared but never attached).
`scenes/ui/tutorial_select.tscn` and `scenes/ui/tutorial_button.tscn`
were checked and confirmed to NOT have this bug.

**Why this produced exactly the reported symptoms:** a script error
mid-`_ready()` aborts the rest of that function's execution, but
anything wired *before* the crash point already took effect. In
`game.gd._ready()`, the Reset button's `pressed` signal is connected
early, well before the doomed `_tutorial_panel.continue_pressed.connect(...)`
line, and the call to `_load_current_level()` (which instantiates every
tile and starts the tutorial) is the *last* thing `_ready()` does. So:
first open -> crash before `_load_current_level()` ever runs -> no
tiles, no tutorial message, nothing to interact with. Pressing RESET
calls the already-connected `_on_reset_pressed()` handler, which calls
`_load_current_level()` directly for the first time - which is why
Reset "fixed" tile visibility, but the tutorial instruction/highlight/
interaction still never worked, because `TutorialManager.start()`/
`advance()` are only ever reached through the same `_ready()` path that
already crashed once and was never re-entered by Reset.

**Why the layout-race hypothesis was wrong, with evidence:** the same
real-rendering reproduction, once the actual bug was fixed, showed
`grid.size = (888.0, 1069.0)` and `cell_size = 177.0` - both already
correct and nonzero - on the very first checked frame, with 3 tiles
correctly instantiated and visible in a saved screenshot alongside the
"Welcome to BeamShift." message and a working "TAP TO CONTINUE" button.
No `level_visuals_ready` signal was implemented, because there was no
timing race left to fix once the real bug was gone - adding one anyway
would have been solving a problem that doesn't exist in this codebase,
contrary to this project's standing "don't rewrite a working system
without a concrete technical reason" rule (`CLAUDE.md`). If a genuine
grid-ready race is ever found in the future, `level_visuals_ready` is
still the right pattern to reach for - it just wasn't what this bug
was.

**Fixes applied, all additive:**
1. `scenes/ui/tutorial_panel.tscn` and
   `scenes/ui/tutorial_complete_popup.tscn`: added the missing
   `script = ExtResource("1")` to each root node.
2. **Fail-safe (explicitly requested):** `GridManager.has_orientable_tile(pos)`
   plus a `TutorialManager._apply_step_to_grid()` change so a
   `REQUIRE_TILE_TAP` step can never lock input to a tile that doesn't
   exist - it now logs a `push_error` naming the tutorial id, step
   index, and step text, and leaves input **unrestricted** instead of
   softlocked, so a future authoring mistake is loud and recoverable
   instead of silently freezing the game.
3. **Temporary QA debug overlay (explicitly requested, QA-build-only):**
   a small `QADebugLabel` in `game.tscn`, visible only when
   `GameManager.is_tutorial_mode` is true, showing `TUTORIAL QA`, the
   live step number, input mode (`REQUIRE_TAP` / `WAIT_TARGET(locked|
   free)` / `WAIT_SOLVED(locked|free)` / `MESSAGE(locked)`), and target
   cell. Never appears in Campaign. Meant to be deleted once Tutorial is
   manually approved.

**Validation performed after the fix (all confirmed, per
`CLAUDE.md` 12a/12d's AUTOMATED/RENDERED/MANUAL vocabulary):**
- RENDERED: the original crash reproduced and then confirmed gone,
  with a real screenshot of T01's first frame showing tiles, beam,
  emitter, instruction text, and the continue button all present with
  no Reset needed.
- AUTOMATED: all 10 tutorials (T01-T10) re-validated for startup
  through the real `game.tscn` instantiation path (the same path that
  caught the bug) - 10/10 PASS, zero errors.
- AUTOMATED: T01 lifecycle - Reset x3 in a row from mid-tutorial each
  correctly returns to step 0 with all 3 tiles and the panel visible,
  no duplicated highlight/UI; Pause -> Resume preserves the exact
  current step; Pause -> Restart resets to step 0 cleanly.
- AUTOMATED: full existing regression re-run - 15/15 dev-level + 50/50
  campaign (65/65 total) solver-vs-runtime-replay all PASS, plus 10/10
  tutorial-board solvability - zero Campaign regression from this fix.
- Android-specific review: no `CanvasLayer` is involved anywhere in the
  tutorial UI (game.tscn, tutorial_panel.tscn), so there is no
  cross-layer ordering/z-index risk; every overlay `Control`
  (`TutorialPanel`'s root, `TutorialHighlight`, `QADebugLabel`) sets
  `mouse_filter = MOUSE_FILTER_IGNORE` so they never intercept input
  meant for tiles/buttons beneath them, while the Continue button itself
  keeps its default `mouse_filter` so it still receives taps; viewport
  scaling is unaffected (`CLAUDE.md` 12b's `canvas_items`/`expand`
  guarantee already covers this).

New build: `versionCode=19`, `versionName="1.6.1-TUTORIAL-FIX"`,
51,130,755 bytes. QA unlock-all (D58) kept enabled per explicit
instruction. Campaign was not touched in any way this pass (no Stage 6,
no Campaign level changes) per explicit instruction. **STILL NOT
MANUALLY APPROVED - ANDROID MANUAL RE-QA PENDING.** Do not mark
Tutorial approved until the user confirms T01 (and ideally the rest)
works correctly on a real device from a fresh open, with no Reset
needed.

### D62 — Guided Tutorial visual focus fix: board dim + bright highlight cutout, added new (no prior dim overlay existed to have regressed)

**Context:** a real device video the user recorded of `versionCode=19`
showed two visual problems: the board stayed heavily darkened during
`REQUIRE_TILE_TAP` in a way that made the required mirror hard to see,
and the darkening didn't reliably clear. The commissioning brief was
written as a bug-fix request ("stale dim overlay," "highlight rendered
too weak under dim") against an assumed pre-existing dim/spotlight
system.

**Finding, checked directly against source before writing any code (per
this project's standing rule): no dim overlay existed anywhere in the
Tutorial system before this pass.** `grep`-ing the whole project for
`Dim`/`Fade`/`ColorRect`/`Overlay` turned up exactly two unrelated
dims - `pause_menu.tscn`'s own full-screen `Dim` (alpha 0.72) and
`tutorial_complete_popup.tscn`'s own (alpha 0.55), both pre-existing,
neither touched by `TutorialManager`/`GridManager`. `TutorialHighlight`
(D60) was, and still is architecturally, an outline-only ring with no
dimming of its own. The real, verifiable bug the video actually showed
was **weak highlight contrast** - a thin cyan outline drawn directly
over full-color gameplay art with nothing to make it stand out - not a
literal stuck/stale overlay. This discrepancy between the brief's
framing and the code is noted here per `CLAUDE.md`'s "code is
authoritative" rule; the fix below implements the brief's own detailed
Goal/Part 2-9 specification (a genuine board-dim-with-bright-cutout
system), since that specification is unambiguous and is what actually
solves the underlying weak-contrast complaint the video captured.

**Architecture chosen: a transparent cutout, not a re-parented tile or a
shader.** `TutorialDimOverlay` (`scripts/ui/tutorial_dim_overlay.gd`,
new `Control`) draws a semi-transparent black rect (`DIM_ALPHA = 0.52`,
one constant, single source of truth) over its own full rect, except a
rectangular cutout that's left completely untouched/transparent - the
tile underneath the cutout is rendered at full, undimmed brightness,
not just "less dark." This was chosen over option B (bright ring on a
higher `CanvasLayer`, dim tile left dark) because the reported complaint
was specifically that the *tile itself*, not just its border, read as
darkened - only a real transparent hole fixes that. It was chosen over
option C-as-shader (mask/shader cutout) because four `draw_rect()` calls
around a hole is simpler, needs no shader file, and is exactly as robust
- "prefer the simplest robust approach" per the brief.

**Single source of truth for cutout/ring geometry:** `TutorialHighlight`
gained `FOCUS_PADDING` (10px) - both the ring's own size (`cell_size +
2*FOCUS_PADDING`) and `TutorialDimOverlay`'s cutout rect are computed
from this one constant inside `GridManager._position_highlight()`, so
the ring and the transparent hole can never drift apart. Highlight
visuals were also strengthened while touching this code (brief's Part
3): `MIN_ALPHA` 0.35 -> 0.55, `MAX_ALPHA` 0.95 -> 1.0, `BORDER_WIDTH` 5
-> 6, color nudged toward white (`0.35, 0.98, 1.0`).

**Dim lifecycle is intentionally NOT a separate state machine - it's
coupled 1:1 to the existing `set_highlight()`/`clear_highlight()`
calls.** `GridManager.set_highlight()` now also shows
`TutorialDimOverlay`; `clear_highlight()` now also hides it and clears
its cutout. No new signals, no new `TutorialManager` fields, no
step-type-specific dim branching was added. This was a deliberate
simplification after checking every `levels/tutorial/t0N.gd` file
directly: `wait_for_target()` is never actually called by any of the 10
tutorials, and `wait_for_solved()`/`wait_for_target()` never set
`highlight_position` in any of them - meaning `_apply_step_to_grid()`
already calls `clear_highlight()` (not `set_highlight()`) for every
`WAIT_FOR_TARGET_ACTIVATION`/`WAIT_FOR_PUZZLE_SOLVED` step that exists
today. So the brief's Part 5 requirement ("remove/reduce dim so the
player can watch the beam/target activation") falls out for free from
the existing highlight-clearing behavior, with zero new branches to
maintain - this is exactly the kind of case `CLAUDE.md`'s "don't add
mechanics/abstractions beyond what's needed" rule argues for. If a
future tutorial ever calls `wait_for_target()` with a highlight set,
this coupling means dim would show during it; that would need revisiting
at that time, not speculatively guarded against now.

**Pause interaction fix (brief's Part 8):** Pause has its own
independent full-screen dim (`pause_menu.tscn`'s `Dim`, alpha 0.72,
pre-existing). Without intervention, opening Pause during a dimmed
tutorial step would stack both dims into a much darker board
(1 - (1-0.52)(1-0.72) ≈ 0.87 combined alpha) - exactly the "no
double-dimming, no alpha multiplication" outcome the brief explicitly
forbids. Fixed with `GridManager.suspend_tutorial_focus()` /
`resume_tutorial_focus()`: Pause hides the highlight+dim outright
(`suspend`, called from `game.gd._on_pause_pressed()`); Resume restores
them only if `_highlight_position` still indicates an active highlight
(`resume`, called from `_on_pause_resume_pressed()`) - so a Reset/step
transition that happened to fire while paused (not possible through
normal UI, but defensively handled) can never resurrect a stale
highlight. Verified by a real rendered Pause-during-`REQUIRE_TILE_TAP`
screenshot showing the Pause panel rendered crisp with no visible extra
darkening.

**Found and fixed an unrelated, adjacent z-order bug while tracing Part
8:** `game.tscn` had `PauseMenu` positioned as an EARLIER sibling than
`TutorialPanel`, meaning the tutorial instruction panel (bottom-anchored,
always visible whenever a tutorial step is showing text) would render
ON TOP of the Pause menu whenever Pause was opened mid-tutorial - a
real, verifiable, separate visual bug from the dim issue, found only
because Part 8 required tracing the exact Pause render order. Fixed by
moving `PauseMenu` to be `game.tscn`'s last child, so it - correctly -
always renders above everything else, tutorial UI included. Confirmed
via a real rendered screenshot: with Pause open, the cropped screen
region that previously showed the highlighted mirror now cleanly shows
Pause's own RESTART/SETTINGS buttons with no bleed-through.

**Completion cleanup (brief's Part 6):** added
`game.gd._clear_tutorial_focus_visuals()` - the one authoritative
`_grid.clear_highlight()` call site - invoked explicitly at every exit
point the brief named (tutorial-branch top of `_load_current_level()`,
covering Reset/Restart/Retry/Next-Tutorial; `_on_tutorial_finished()`
right before the completion popup shows; `_on_back_pressed()`'s tutorial
branch; `_on_pause_main_menu_pressed()`'s tutorial branch;
`_on_tutorial_select_pressed()`/`_on_tutorial_campaign_pressed()`) plus
a universal `_exit_tree()` fallback for any other teardown path. This is
defense-in-depth on top of the fact that `clear_highlight()` already
runs as a side effect of every real step transition (D60's
`_apply_step_to_grid()`, and `advance()`'s `_clear_grid_restrictions()`
when a tutorial finishes) - direct testing confirmed no stale-dim window
ever actually existed once the highlight/dim coupling itself was
correct, but the explicit call sites match the brief's checklist exactly
and cost nothing.

**Rendered validation (per `CLAUDE.md` 12d), with an important
technique note:** the first attempt at a full T01 rendered walkthrough
opened in an unexpectedly wide/short desktop window (this environment's
non-headless `godot --path .` run did not honor `project.godot`'s
1080x1920 request, and `--windowed --resolution 1080x1920` did not
change it either - environment-specific windowing, not a project bug).
Naively eyeballing screen coordinates against the WRONG assumed
resolution produced a false impression that the dim/highlight weren't
doing anything. The fix: read the *actual* logged geometry
(`grid.global_position`, `TutorialHighlight.global_position/size`,
`get_viewport().get_visible_rect().size`) from the same run, scale it
against the saved PNG's real pixel dimensions, and sample/crop exactly
that region. Once measured correctly: the cutout center's pixel
luminance was ~2.5-3x brighter than a point immediately outside the
cutout on the same tile row (a real, working contrast fix), and a
cropped/3x-zoomed screenshot visually confirms a clearly brighter tile
with a visible cyan-tinted ring against a darkened neighborhood. This is
recorded here so a future session doesn't waste time re-discovering that
this environment's windowed runs need their geometry read from the live
scene, not assumed from `project.godot`.

**Automated validation:** a headless driver walked every step of all 10
tutorials (covering every tile type any tutorial highlights - mirror,
emitter, target, blocker, fixed mirror, splitter, filter, portal,
switch/gate, hazard) via direct `advance()` calls, asserting after each
step that `TutorialHighlight.visible`/`TutorialDimOverlay.visible`
exactly match whether that step has a `highlight_position`, that the
dim's cutout rect exactly equals the highlight's own rect, and that both
are cleared after the tutorial's last step - **10/10 PASS**, zero
mismatches, across every tutorial. Full existing regression (15/15
dev-level + 50/50 campaign, 65/65 total) re-confirmed unaffected.

New build: `versionCode=20`, `versionName="1.6.2-TUTORIAL-VISUAL-FIX"`,
51,130,936 bytes. QA unlock-all (D58) kept enabled. Campaign untouched
(no Stage 6, no campaign level/mechanic changes) per explicit
instruction. **STILL NOT MANUALLY APPROVED - ANDROID MANUAL QA
PENDING** for both this visual fix and the D61 runtime fix together -
neither has been confirmed on a real device yet.

### D63 — Guided Tutorial click input fix: `game.tscn`'s `TutorialPanel` instance silently overrode its own scene's bottom-anchored layout to full-screen, swallowing every tap

**Context:** a third manual video QA round on `versionCode=20` found
the highlighted mirror at T01's `REQUIRE_TILE_TAP` step was visible but
could not be tapped - repeated taps did nothing, the tutorial never
advanced. The brief was explicit: do not make another visual-only fix,
do not assume `mouse_filter` values from `.tscn` source are what's
actually true at runtime, and trace the real input path.

**Root cause, found by dumping actual runtime `mouse_filter`/`get_global_rect()`
values for every ancestor Control between the Viewport and the
highlighted tile (not read from `.tscn` source):** `game.tscn`'s
`[node name="TutorialPanel" parent="." instance=ExtResource("14")]`
block redundantly re-declared `anchors_preset = 15` (full rect) plus
`anchor_right = 1.0` / `anchor_bottom = 1.0` on top of the instanced
`tutorial_panel.tscn`, which already anchors itself correctly to a
~220px-tall band at the bottom of the screen
(`anchor_top = 1.0, offset_top = -260, offset_bottom = -40`). This
instance-level override completely replaced the base scene's own
layout, making `TutorialPanel` - and, more importantly, its child
`Panel` (a `PanelContainer` with the class default `mouse_filter =
MOUSE_FILTER_STOP`, since it had no explicit override) - cover the
**entire screen**, not just the intended bottom band. Since `Panel`'s
`StyleBoxFlat` background is only 88% opaque and BeamShift's gameplay
art is already dark, this full-screen panel visually blended into the
background well enough that nothing looked obviously wrong - the
highlighted mirror remained visible underneath it - but `Panel`'s
`STOP` filter, being a later sibling than `PuzzleGrid` in `game.tscn`'s
tree (drawn/hit-tested on top), silently intercepted every tap
anywhere on the board before it could ever reach a tile. This also
retroactively explains part of the D62 visual-focus complaint: some of
the "board looks too dark" perception the user reported on
`versionCode=19` was very likely this same stray full-screen panel
tint stacking with the D62 dim overlay, not solely the dim overlay
itself.

**Why this evaded every prior automated/rendered check:** none of
D60-D62's testing ever independently verified a Control's *runtime*
`mouse_filter`/`get_global_rect()` against its *declared* `.tscn`
anchors - every test either called `_on_orientable_tile_clicked()`
directly (bypassing the Viewport's hit-testing entirely) or checked
visual appearance (which this bug doesn't disturb, since the panel
stays visually subtle). Only a direct runtime dump of the actual
ancestor chain - exactly what this brief demanded instead of assuming
`.tscn` values - surfaced it: the dump showed `TutorialPanel`/`Panel`
at `rect=[P: (0,0), S: (1954,1920)]` (full screen) instead of the
`.tscn`'s own declared ~220px band, immediately visible as wrong once
printed.

**Fix (smallest correct change, per the brief's explicit instruction
not to touch anything until the real rejection point was found):**
removed the conflicting layout override from `game.tscn`'s
`TutorialPanel` instance node entirely (keeping only the legitimate
state overrides, `unique_name_in_owner` and `visible = false`), so it
now correctly inherits `tutorial_panel.tscn`'s own bottom-anchored
layout. Re-verified via the same runtime dump: `TutorialPanel`/`Panel`
now report `rect=[P: (24, 1660), S: (1906, 220)]`, and the hit-test
candidate list at the highlighted mirror's screen position no longer
includes either node.

**Hardening applied alongside the root-cause fix (Part 4's explicit
request, cheap and risk-free given the pattern already used for
`TutorialHighlight`/`TutorialDimOverlay`):** `tutorial_panel.tscn`'s
`Panel` node now also sets `mouse_filter = MOUSE_FILTER_IGNORE`
directly, so only its actual `ContinueButton` (which keeps its own
default `STOP` and independently receives its own clicks regardless of
its parent's filter) can ever consume a tap - the panel's background
can no longer intercept a tap even if a future layout change makes its
band overlap gameplay tiles on some aspect ratio.

**Second fail-safe added (brief Part 11):** `TutorialManager.
_apply_step_to_grid()`'s `REQUIRE_TILE_TAP` branch now also checks
`step.highlight_position != step.target_position` and `push_error`s if
they ever differ, naming the tutorial/step/text - defends against a
future authoring mistake where the highlighted cell and the accepted
cell silently diverge, which would look exactly like "the highlighted
tile can't be tapped." Every `TutorialStepData.require_tap()` call sets
both fields to the same value today, so this is currently unreachable,
but is checked directly rather than assumed.

**QA debug overlay expanded (brief Part 12):** `GridManager` gained a
new `tile_tap_attempted` signal (fires for every tap attempt on an
orientable tile, accepted or rejected - unlike `move_made`, which only
fires for an actually-accepted tap) plus three diagnostic fields
(`last_tap_cell`, `last_tap_accepted`, `last_tap_rejection_reason`),
set at the top of `_on_orientable_tile_clicked()` before any guard
clause returns. `game.gd`'s QA-build-only debug label now shows
`HIGHLIGHT:`/`ALLOWED:`/`LAST TAP:` (cell -> ACCEPTED or REJECTED plus
the exact reason) alongside the existing STEP/MODE line, refreshed live
on every tap attempt - a future "nothing happens when I tap" report can
now be diagnosed directly from the screen.

**Validation - explicitly NOT relying on direct method calls, per the
brief's Part 14:** a real, non-headless rendering session dumped the
live ancestor chain's `mouse_filter`/`get_global_rect()` for every
Control between the Viewport and the highlighted tile at T01's
`REQUIRE_TILE_TAP` step, both before and after the fix, and an
independent point-in-rect hit-test search confirmed which Controls
would actually receive a click at the tile's exact screen position
before and after - `TutorialPanel`/`Panel` were present as blocking
candidates before the fix and absent after. Separately, and by
happenstance during this same investigation, genuine OS-level mouse
input on this development machine (real `InputEventMouseMotion`/
`InputEventMouseButton` events, not synthetically constructed by any
test script) was observed reaching `MirrorTile._gui_input()` and
`GridManager._on_orientable_tile_clicked()` at the correctly-restricted
cell `(2,2)` and being accepted - genuine, if incidental, confirmation
that a real click on the correct tile now works end to end through the
fixed pipeline. This project's own synthetic `push_input()`/
`Input.parse_input_event()` dispatch continues to not reliably reach
`_gui_input()` in this test harness (reconfirmed with a baseline test
against a plain `Button`, which also didn't register) - a known,
pre-existing limitation (`CLAUDE.md` 12a), not something this fix
could or needed to work around. Real on-device tapping remains the
authoritative MANUAL test.

**Automated (bounded, real signal-chain) validation:** for every
`REQUIRE_TILE_TAP` step encountered along each tutorial's natural
forward path (T01-T10), a headless driver confirmed a wrong-cell tap
is rejected without mutating state and the correct-cell tap is
accepted and advances the tutorial via the real `move_made` ->
`TutorialManager.notify_move_made()` -> `advance()` signal chain
(never a direct bypass of that chain) - **10/10 PASS**. Full existing
regression re-confirmed unaffected: 15/15 dev-level + 50/50 campaign
(65/65 total), plus 10/10 tutorial-board solvability.

**A process note worth keeping**: an earlier, more ambitious version of
this same validation driver (walking all 10 tutorials in one loop with
extra manual `advance()` calls on non-`REQUIRE_TILE_TAP` steps) hung
completely with zero output and had to be killed. A minimal, heavily-
logged single-tutorial script isolated that the hang was specific to
that script's own structure (most likely redundant manual `advance()`
calls firing `tutorial_finished` multiple times, piling up dangling
`await get_tree().create_timer(...)` coroutines on rapidly-`queue_free()`d
`game` instances) rather than any product bug - the fix was to stop
manually advancing past `WAIT_FOR_TARGET_ACTIVATION`/
`WAIT_FOR_PUZZLE_SOLVED` steps in the driver (rely on the real signal
chain to advance through those, exactly as a real play session does)
and add a hard iteration cap as a safety net. Noted here so a future
session doesn't re-hit the same test-driver pitfall.

New build: `versionCode=21`, `versionName="1.6.3-TUTORIAL-INPUT-FIX"`,
51,135,032 bytes. QA unlock-all (D58) kept enabled. Campaign untouched
(no Stage 6, no campaign level/mechanic changes) per explicit
instruction. **STILL NOT MANUALLY APPROVED - ANDROID MANUAL QA
PENDING** for the D61 runtime fix, D62 visual fix, and this input fix
together - none has been confirmed on a real device session yet.

### D64 — Main Campaign Reboot: Levels 1-50 rebuilt as a mechanic-agnostic, difficulty-focused curve now that Tutorial teaches mechanics

**Context:** with the Guided Tutorial (T01-T10) now teaching every
mechanic in isolation, and now that its own three runtime/visual/input
bugs (D61/D62/D63) are fixed, the brief's premise was explicit: the
Main Campaign no longer needs to teach mechanics one stage at a time -
its only job from here is testing combinations and reasoning. The user
explicitly liked old Level 50 ("Paradox," 255 states) for being tricky,
requiring real thought, and combining mechanics with a solution that
wasn't obvious; Levels 31-40 were explicitly reported as too easy. Old
Level 50 was named the quality benchmark every level from 21 onward
should be measured against - not copied, but matched in reasoning
depth.

**Audit of the existing 50, done before writing anything (per this
project's standing rule), using each stage's own recorded
`states_explored`/`optimal_moves` from `CAMPAIGN_DESIGN.md`'s existing
tables rather than re-deriving them from scratch:**

| Levels | Status at audit time | Decision |
|---|---|---|
| 1-10 (Stage 1, "First Light") | Manually approved by the user ("the starting levels are good") | **KEEP** |
| 11-20 (Stage 2, "Reflection") | Manually approved for campaign continuation ("these are looking good") | **KEEP** |
| 21-30 (Stage 3, "Split") | Never manually approved; splitter-only scope, front-loaded easy tutorial-style splitter introduction (2-6 states/moves at the low end) | **REPLACE** |
| 31-40 (Stage 4, "Spectrum") | Never manually approved; **explicit user feedback: "feels easy"** | **REPLACE** |
| 41-45 (Stage 5 first half, "Filters") | Never manually approved; front-loaded "teach the filter mechanic" introductions (states 8-32, lower than the stage's own later levels) | **REPLACE** |
| 46-50 (Stage 5 second half) | Never manually approved, but already strong: states 32-255, cross-branch/backward-reasoning/global-dependency constructions, Level 50 explicitly the requested benchmark | **KEEP** |

**Why Levels 1-20 were kept rather than redesigned:** both stages carry
real, explicit prior manual approval - the single strongest signal this
project has for any content. The brief's own Part 3 also targets
Levels 1-5 as "Easy -> Medium... still real puzzles" and Levels 6-10 as
"Medium," which Stage 1's already-solver-confirmed 1-4-move curve and
Stage 2's 3-5-move curve already satisfy without modification. Touching
manually-approved content without being explicitly asked to redesign it
specifically carries real risk of undoing something the user already
confirmed they liked; "avoid unnecessary destruction" (the brief's own
Part 25 guidance, stated about stage folders but applied here in
spirit) was read to extend to already-approved level content too. This
is a judgment call, recorded transparently here so the user can
overrule it - see the final report's audit section.

**Why Levels 21-45 were replaced, and 46-50 kept:** Levels 21-45 all
shared the same root problem - they were authored under the old "this
stage's job is to teach mechanic X" framing, which structurally forces
each stage's *first* few levels to be simple introductions (Stage 3's
splitter tutorial, Stage 4's single-color-decoy opener, Stage 5's
"clean, non-deceptive" filter introduction, in that table's own words).
With Tutorial now doing that job, every one of those "introduction"
levels was replaceable with a real puzzle from the very first level of
its block. Levels 46-50, by contrast, were already written *after*
Stage 5's own mechanic was established, so they're already combination-
focused, already escalating (32 -> 255 states), and Level 50 specifically
*is* the requested benchmark - redesigning it would mean discarding the
one piece of content the brief most explicitly said to preserve.

**Internal structure preserved on disk, per the brief's explicit "avoid
unnecessary filesystem destruction" instruction:** the `levels/campaign/
stage_01/` … `stage_05/` folder layout and `LevelManager.
CAMPAIGN_LEVEL_PATHS`' own ordering were **not touched at all** - only
the *contents* of `stage_03/level_01.gd` … `level_05.gd` (campaign
Levels 21-30), `stage_04/level_01.gd` … `level_10.gd` (31-40), and
`stage_05/level_01.gd` … `level_05.gd` (41-45) were rewritten in place.
Each file's own `stage` field string ("Split"/"Spectrum"/"Filters")
was left unchanged too, since it's part of the save-data-compatible
metadata (D54) and purely internal - the player never sees stage names,
only "Level N" (see `CAMPAIGN_DESIGN.md` section 1a, new this pass).

**Design process actually followed for all 25 replaced levels (Levels
21-45):** every level was hand-designed and hand-traced against
`GridTypes.reflect()`'s actual table before being written (per section
7's standing workflow), then validated in batches of 5 via
`LevelValidator`/`LevelSolver` run headlessly. **24 of 25 matched their
hand-traced intent exactly on the first solver pass** - zero validator
errors/warnings, `possible_decoys` matching every intentionally-placed
decoy and nothing else, across all 25. **One real authoring bug was
caught by the solver, not by hand-tracing, exactly as this workflow is
supposed to catch**: Level 30 ("Deadlock")'s first draft declared
target A's required color as RED, but its own straight branch passes
through an unavoidable GREEN filter before ever reaching the shared
mirror - the beam is genuinely GREEN by the time it would reach that
target, so `target_accepts_color()` correctly refused it and the solver
returned `UNSOLVABLE` across the full 128-state search space. Fixed by
matching the target's required color to what the beam actually carries
(GREEN); re-run confirmed `SOLVABLE`, 6 moves, matching the original
design intent exactly. One further authoring slip was a pure
bookkeeping error, not a design bug: Level 40 ("Crucible")'s declared
`optimal_moves` was initially set to 5 (miscounting a genuinely-inert
decoy piece as if it needed a flip); the solver correctly reported 4,
and the declared value was corrected per section 7's "always trust the
solver" rule.

**New design vocabulary used across the 25 replaced levels** (see
`CAMPAIGN_DESIGN.md` sections 11f/11g/11h for the full per-level
table): splitter dual-branch puzzles where *neither* branch is free
(breaking the earlier-taught "straight branch is always free"
assumption - Level 21); portal misdirection requiring entry/exit/
direction/post-jump tracking rather than a shortcut (22, 31, 34, 37,
43, 45); backward reasoning through fixed (non-rotatable) mirror chains,
including two *independent* chains in one level (23, 39, 41, 42);
switch/gate dependency where an unconditional splitter branch is what
lets a completely separate branch's gate open within a single move (24,
29, 32, 34, 44); hazard-guarded branches where a locally-correct target
hit is globally worthless because a *different* branch triggered the
hazard (25, 31, 38); cross-branch dependency via a single shared mirror
approached from two geometrically disjoint paths, including via two
independent *emitters* rather than a splitter (26, 30, 35, 36, 37, 39);
filter-order "false-confirmation" traps where the wrong branch
genuinely turns the right-looking color but reaches nothing required
(27, 33); and comprehensive block-finale levels combining 3-4 of the
above at once (30, 40, 45).

**Honest accounting of the optimal-move curve against the guideline
table** (`CAMPAIGN_DESIGN.md` section 4): several reboot levels land at
2-3 moves despite sitting in the "Hard+"/"Very Hard"/"Expert" curve
band, below the stated 5-12-move guideline range for their position.
This is a deliberate choice, not an oversight - `CLAUDE.md`'s own
standing rule ("never pad a level's move count artificially") and the
brief's own Part 20 ("a brilliant 7-move puzzle is better than a padded
12-move puzzle") were both weighed against the guideline, and reasoning
density (a hazard-guarded splitter branch, a portal's non-obvious
post-jump route, a filter-order false-confirmation trap, an emergent
failure cascade through re-crossed pieces) was prioritized over
synthetically extending chains purely to hit a move-count target. Every
level's actual `states_explored`/mechanic-combination is recorded in
`CAMPAIGN_DESIGN.md`'s tables for the user's own judgment on this
trade-off during manual playtesting.

**Old Level 50 remains the clear, unbeaten peak of the 1-50 curve, as
required**: its 255 `states_explored` exceeds every one of the 25
reboot levels' own figures (highest: Level 30's 127) and both kept
Stage 5 levels 46-49's figures (32-64) - no strengthening of Level 50
was needed, since the reboot's own levels were deliberately kept below
it rather than accidentally exceeding it.

**Validation:** `LevelValidator`/`LevelSolver` run against all 25
replaced levels individually (5 batches of 5) plus a full re-run
against all 50 campaign levels together; solver-vs-runtime-replay
parity (`GridManager._on_orientable_tile_clicked()`, the real gameplay
path, not `LaserSystem` in isolation) confirmed for all 50 - **50/50
solver PASS, 50/50 runtime PASS**. Full dev-level regression
re-confirmed unaffected - **15/15 PASS**. Tutorial board solvability
re-confirmed unaffected (Tutorial was not touched at all this pass,
per the brief's explicit Part 1 freeze) - **10/10 PASS**.

**Save compatibility (brief Part 27):** campaign level IDs 1-50 are
unchanged, so any existing QA save's `campaign_completed_levels`/
`campaign_highest_unlocked_level`/star data for those IDs still applies
verbatim to the *redesigned* levels at the same IDs - a save that
previously marked "Level 35 complete, 3 stars" will still show that,
even though Level 35's actual puzzle changed entirely. This is
explicitly acceptable for QA (per the brief) since
`UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` already makes every level
directly selectable regardless of save state, and no save was wiped or
migrated. `SAVE_VERSION` was not bumped (no field shape changed, only
level *content* at existing IDs) - if this project ever ships a real
release build with real progress tracking, a save reset (or a
one-time "levels have changed, stars reset" migration) would be needed
before launch, since a 3-star rating earned on the *old* Level 35 says
nothing about the *new* one's actual difficulty; this is noted here as
a pre-launch checklist item, not an immediate action.

New build: `versionCode=22`, `versionName="2.0.0-CAMPAIGN-REBOOT-QA"`.
QA unlock-all (D58) kept enabled. Tutorial untouched (per Part 1's
explicit freeze). **NOT MANUALLY APPROVED - ANDROID MANUAL DIFFICULTY
QA PENDING** for the redesigned Levels 21-45 and the kept-but-now-
recontextualized Levels 1-20/46-50 alike - none of the 50 has been
played by the user since this reboot.

### D65 — Campaign Difficulty Rework Pass 2: Levels 21-45 replaced again after Pass 1 (D64) was still too easy

**Context:** the user played through the D64 reboot's solver-confirmed
move counts and found them far short of the "Hard+/Very Hard/Expert"
labels those levels carried — Levels 21-25 came in at 3,2,2,2,2 moves,
31-35 at 2,2,2,2,5, and 41-45 at 2,4,2,2,3. Several were solvable with
a handful of random taps. The explicit brief for this pass was: don't
just raise move counts, raise **dependency depth** — cross-branch
shared mirrors, filter order, portal misdirection, switch/gate
dependency, multi-emitter dependency, backward reasoning, and
hazard/blocker-guarded false forks that actually punish a wrong choice
instead of producing a harmless miss.

**Scope:** Levels 21-45 only (25 levels, folders `stage_03`, `stage_04`,
`stage_05/level_01..05`). Levels 1-20, 46-50, Tutorial (T01-T10), dev/
regression levels 1-15, UI, menus, save schema, and the QA unlock flag
were explicitly out of scope and were not touched.

**Design approach:** every level was built from one of two safe,
solver-verified templates rather than ad hoc layouts:
1. A single linear beam path (no splitter) with rectangular 2-4-mirror
   detours inserted for length — the safest shape, since a
   non-branching path cannot collide with itself as long as every cell
   is used exactly once.
2. A splitter whose two branches occupy fully disjoint rows/columns
   (except at one deliberately shared point, usually a FIXED mirror
   that both branches approach from perpendicular directions) — the
   proven "cross-branch dependency" technique already used successfully
   in Pass 1's Levels 26/28/30.

Two-emitter levels (32, 36, 44) used the same disjoint-zone discipline,
treating each emitter's chain like a splitter branch.

**Real authoring bugs the solver caught during this pass (not an
exhaustive list — see `CAMPAIGN_DESIGN.md` sections 11f/11g/11h for the
full per-block accounting):**
- **Level 25 (first draft):** a required target was placed in the same
  column as an unrelated mirror from the OTHER branch; the solver found
  a 2-move shortcut through that accidental collinearity. Fixed by
  moving the two branches onto fully disjoint rows/columns — this
  became the standing discipline for every level afterward.
- **Level 27 (first draft):** tried to have a splitter's two branches
  share two filters (touched in opposite order) by looping the
  reflected branch back into row 2 from the far side — the loop-back
  geometry accidentally ran the beam back through the splitter and into
  its own hazard, returning `UNSOLVABLE`. Rebuilt as a single
  non-branching linear path (template 1 above), which cannot self-
  collide by construction.
- **Level 31 (two drafts):** first tried reusing one mirror for both
  the outbound and inbound leg of a "beam loops back" trick, with a
  decoy mirror placed one cell from the target — the solver found a
  3-move shortcut straight through the decoy into the target. A second
  attempt (removing the decoy) still found an entirely different
  unintended path through the same mirror cluster that skipped the
  portal altogether. Both symptoms of the same root cause: a densely
  interconnected mirror cluster admits more paths than the designer can
  hold in their head. Rebuilt as a single non-revisiting chain.
- **Level 34 (first draft):** placed the return-leg target directly
  above the same mirror used for the outbound turn — since that
  mirror's "wrong" (authored) orientation *also* sends a rightward
  beam straight up into that column, the solver caught a genuine
  0-move trivial solve. Fixed with a dedicated return-leg mirror the
  outbound beam never crosses.
- **Level 36 (two drafts):** first draft placed a hazard at (2,0)
  without noticing emitter 2's own unavoidable first straight shot
  along row 0 passed directly through it, making the level permanently
  `UNSOLVABLE` (a real emitter beam, not a rotatable piece, can also
  create an unavoidable collinearity trap). Second draft fixed the
  hazard but placed target B directly on that same unavoidable row-0
  shot, and the solver found a 4-move shortcut that never touched a
  single mirror. Fixed by moving the hazard off row 0 and routing the
  shared mirror's output through a dedicated relay mirror before
  reaching a target.
- **Level 40 (first draft):** simply missing one mirror in the
  reflected branch's relay chain (an authoring slip, not a design
  flaw) — the beam ran off the edge of the board. Returned
  `UNSOLVABLE`; fixed by adding the missing tile.

**General lesson recorded for any future level design in this
project:** before trusting a hand-traced solution, check every
required target and hazard against **every beam's fully unmodified
straight-line path** — not just the intended chain — including a
splitter's always-active straight component and every emitter's own
first step. A tile sitting anywhere on an unintended straight run will
be hit regardless of what the rest of the board is configured to do,
and this is the single most common source of accidental shortcuts and
`UNSOLVABLE` results found in this pass. The solver is exhaustive and
will always catch it; treat an unexpected solver result as a real bug
report, not a fluke, and re-derive the actual beam path (a temporary
`LaserSystem.simulate_until_stable()` dump, not more hand-tracing) to
find it.

**Validation:** 50/50 campaign solver PASS, 50/50 campaign runtime-
replay PASS (via `GridManager._on_orientable_tile_clicked()`), 15/15
dev-level PASS, 10/10 tutorial-board solvability PASS (Tutorial
untouched). Every one of the 25 redesigned levels' declared
`optimal_moves`/`shortest_solution_count`/`states_explored`/
`possible_decoys` fields matches the solver's own confirmed result
exactly - see `CAMPAIGN_DESIGN.md` sections 11f/11g/11h for the full
design tables.

**Save compatibility:** identical situation to D64 - campaign level IDs
1-50 are unchanged, so existing save data for Levels 21-45 (if any)
still applies verbatim to the new puzzles at those IDs. Still
acceptable for QA under `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`; still
a pre-launch checklist item if this project ever ships with real
progress tracking.

New build: `versionCode=23`, `versionName="2.0.1-CAMPAIGN-DIFFICULTY-QA"`.
QA unlock-all (D58) kept enabled. Tutorial and Levels 1-20/46-50
untouched. **NOT MANUALLY APPROVED - ANDROID MANUAL DIFFICULTY QA
PENDING** for the redesigned Levels 21-45 - none of the 25 has been
played by the user since this pass.

### D66 — Campaign Levels 51-60: first post-reboot expansion past 50, no mechanic-teaching reset

**Context:** the user sampled several rebuilt Levels 21+ on a real
Android device (partial feedback: "its good") but full manual QA of
Levels 21-50 remains pending — this pass does not claim otherwise. With
development continuing, the explicit brief was to extend the campaign
to 60 levels, with Level 51 picking up directly from the Levels 46-50
difficulty region: no mechanic introduction, no difficulty reset,
freely combining anything Tutorial already teaches (same standing rule
as Levels 21+ since D64/D65).

**Design method:** every level reused one of the two solver-verified-
safe templates established during Difficulty Rework Pass 2 (D65) — a
single non-branching linear chain, or a splitter/multi-emitter pair
whose branches occupy fully disjoint rows/columns except at one
deliberately shared tile (a fixed mirror, filter, or switch/gate pair).
New combinations introduced in this block: a genuinely MUTUAL switch/
gate dependency (Level 51 — each branch's own switch opens the OTHER
branch's gate, not a one-way relationship like every prior switch/gate
level), a shared filter tile reached by two independent emitters from
perpendicular directions (Level 53), and a global switch/gate
dependency gating an entire independent filter-order sub-puzzle (Levels
55 and 60).

**Two full draft rejections during design** (see `CAMPAIGN_DESIGN.md`
section 11i for the design table these apply to):
- **Level 56 draft 1** tried sharing ONE portal pair between two
  independent emitters, each entering the opposite end. This is
  structurally different from every other portal use in the project
  (which always has exactly one beam per pair) and created a
  combinatorially pathological search space: `LevelSolver.analyze()`
  on a mere 7-rotatable-piece level (128 candidate states) took minutes
  instead of the usual milliseconds, because many candidate
  configurations caused beams to bounce between the two portal ends for
  close to `LaserSystem.MAX_STEPS` (20000) before the loop guard caught
  them. Killed mid-run rather than waited out; rebuilt with two
  separate portal pairs tied together by a switch/gate instead, which
  re-validated in under a second. **Standing lesson for future levels:
  never have two independently-solved beams share one portal pair** —
  if a solver run is taking unexpectedly long, suspect this pattern
  first.
- **Level 58 draft 1** tried a "delayed consequence" where a wrong
  branch mirror produces no immediate consequence (no hazard, no
  blocker) for several cells, on the theory that the delay itself was
  the point. Two cells assigned to different branches ((5,5) on the
  straight branch, (5,4) on the reflected branch) sat directly adjacent
  to each other, and leaving BOTH in their "wrong" orientation
  connected into one continuous accidental path reaching BOTH targets
  in 4 moves — caught by the solver's `possible_decoys` flagging 6 of
  10 pieces as irrelevant, an unmistakable signal something was wrong
  even before checking the actual shortcut. Rebuilt with fully disjoint
  branch zones and a real (if delayed by two cells, not zero) hazard
  ending the wrong path. **Standing lesson: "delayed consequence" must
  still end in a real, reachable consequence (hazard/blocker/wrong
  color) — a wrong branch that simply trails off into adjacent
  territory with no consequence at all is exactly the collinearity trap
  D65 already warned about, just with the hazard removed entirely
  rather than misplaced.**

**One minor correction, not a redesign:** Level 51's mirror at (6,5)
was authored as an intentional decoy but the solver found it
load-bearing (the beam continues past its target and, left unflipped,
runs into the same hazard that punishes the wrong splitter branch) —
tiles were correct, only the `developer_notes` decoy claim was wrong,
corrected honestly rather than left standing.

**Architecture: zero changes needed**, exactly as every prior stage
addition (D54-D59) — `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 more
entries (`levels/campaign/stage_06/level_01.gd` … `level_10.gd`),
`get_campaign_level_count()` picked up the new total automatically by
construction. Verified directly with a real-autoload driver (temporary
`run/main_scene` swap to a throwaway scene, reverted immediately after):
`get_campaign_level_count() == 60`; Level 60 loads correctly
(`display_name == "Threshold of Reason"`); `get_campaign_level(61)`
returns `null` with a graceful `push_warning`, no crash;
`is_campaign_level_selectable(60) == true` and `(61) == false` under
the QA-unlock flag; `SaveManager.campaign_highest_unlocked_level`
confirmed untouched (still its real, unmodified value) — the new
levels are visible for QA without any save-data being faked.

**Validation:** 10/10 new-level solver PASS, 10/10 new-level runtime-
replay PASS, 60/60 full campaign solver PASS, 60/60 full campaign
runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
solvability PASS (Tutorial untouched). Every one of the 10 new levels'
declared `optimal_moves`/`shortest_solution_count`/`states_explored`/
`possible_decoys` fields matches the solver's own confirmed result
exactly (after the two rejections above were fixed) — see
`CAMPAIGN_DESIGN.md` section 11i for the full design table.

**Save compatibility:** purely additive — no existing campaign level ID
(1-50) changed, no `SaveManager` field/schema changed.
`campaign_highest_unlocked_level` and friends already scale to whatever
`get_campaign_level_count()` reports, same mechanism that scaled
automatically from 40 to 50 levels at Stage 5 (D59) and needed no
changes here either.

New build: `versionCode=24`, `versionName="2.1.0-CAMPAIGN-60-QA"`. QA
unlock-all (D58) kept enabled. Levels 1-50 and Tutorial untouched.
**NOT MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING** for
Levels 51-60; full manual QA of Levels 21-50 also still pending from
D65 (partial informal feedback only: "its good" on a post-20 sample).

### D67 — Campaign Levels 61-70: second post-reboot expansion, advanced expert block

**Context:** with Levels 51-60 (D66) shipped and QA still pending on
Levels 21-60 as a whole, the user asked to continue development by
extending the campaign to 70 levels — explicitly an "advanced expert"
block, with Level 61 continuing directly from Level 60's difficulty
(no mechanic-teaching reset) and Level 70 as a second major milestone
that should feel more sophisticated than Level 60, not merely larger.

**Design method:** every level reused the two solver-verified-safe
templates from Difficulty Rework Pass 2 (D65) — a single non-branching
linear chain, or a splitter/multi-emitter pair whose branches occupy
fully disjoint rows/columns except at one deliberately shared tile.
Two genuinely new structural patterns were introduced and proven safe
in this pass:
- **A single physical gate cell crossed by two emitters from
  perpendicular directions** (Level 68, "Twin Corridor") — one emitter
  horizontal, one vertical, both wired to the same `gate_id` so EITHER
  emitter's own switch opens it for both. This is a stronger form of
  "shared resource" than a shared switch/gate PAIR (used since D66):
  here it's the exact same tile, not just the same `gate_id` on two
  different tiles.
- **A two-stage switch/gate relay between two emitters** (Level 70,
  "Grand Convergence") — emitter 1's switch opens the gate blocking
  emitter 2's EARLY path; only after emitter 2 crosses that gate and
  reaches its OWN switch does emitter 2's switch open a SECOND gate
  blocking emitter 1's LATER path. Neither emitter can finish without
  the other having already progressed partway. Verified by hand against
  `simulate_until_stable()`'s actual pass-by-pass behavior before
  trusting the solver's result: pass 1 trips switch 1 only (gate 1
  opens, gate 2 stays closed, both emitters blocked further on);
  pass 2 emitter 2 now crosses gate 1 and trips switch 2 (gate 2
  opens); pass 3 emitter 1 now crosses gate 2 and reaches its target.
  Three passes, well within `LaserSystem.MAX_EXTRA_PASSES`.

**One full draft rejection** (see `CAMPAIGN_DESIGN.md` section 11j for
the design table this applies to): **Level 63 draft 1** used an
always-open decoy gate positioned where the reflected branch's own
correct path also happened to pass through it, plus a "decoy" mirror
that turned out to connect the reflected branch's chain straight into
the straight branch's own target through a chain of coincidental
reflections — the solver found a 5-move shortcut bypassing the portal,
the real gate, and the switch entirely. This is the same root-cause
class D65/D66 already documented (a tile assumed to be reachable only
by one "wrong" branch turns out reachable by the other branch's
CORRECT path too) — rebuilt with fully disjoint branch zones and no
always-open gate; the "invalidation" design identity survives via a
plain ungated wrong turn to a decoy target instead of a real gate.

**One notes correction, not a design flaw:** Level 68's original
hand-trace mis-applied `GridTypes.reflect()`'s table to one mirror
(assumed `BACKSLASH` was needed for a `RIGHT->UP` output; the table
actually gives that via `SLASH`), concluding it needed a flip that the
solver correctly showed was unnecessary — the mirror was already
authored in its correct orientation. This is a genuine example of the
distinction the project's own solver-decoy semantics draw: a piece can
be **load-bearing while requiring zero moves** (already correct from
the start) — this is different from a **decoy** (a piece whose
orientation never matters, confirmed by `possible_decoys`). `optimal_
moves` corrected from a mis-counted 10 to the solver-confirmed 9.

**Architecture: zero changes needed**, exactly as every prior stage
addition — `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 more entries
(`levels/campaign/stage_07/level_01.gd` … `level_10.gd`),
`get_campaign_level_count()` picked up the new total automatically.
Verified directly with a real-autoload driver (temporary `run/
main_scene` swap, reverted immediately after): `get_campaign_level_count()
== 70`; Level 70 loads correctly (`display_name == "Grand
Convergence"`); `get_campaign_level(71)` returns `null` with a graceful
`push_warning`, no crash; `is_campaign_level_selectable(70) == true` and
`(71) == false` under the QA-unlock flag; `SaveManager.
campaign_highest_unlocked_level` confirmed untouched.

**Validation:** 10/10 new-level solver PASS, 10/10 new-level runtime-
replay PASS, 70/70 full campaign solver PASS, 70/70 full campaign
runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
solvability PASS (Tutorial untouched). Every one of the 10 new levels'
declared `optimal_moves`/`shortest_solution_count`/`states_explored`/
`possible_decoys` fields matches the solver's own confirmed result
exactly (after the one rejection and one notes correction above) — see
`CAMPAIGN_DESIGN.md` section 11j for the full design table.

**Save compatibility:** purely additive — no existing campaign level ID
(1-60) changed, no `SaveManager` field/schema changed.

New build: `versionCode=25`, `versionName="2.2.0-CAMPAIGN-70-QA"`. QA
unlock-all (D58) kept enabled. Levels 1-60 and Tutorial untouched.
**NOT MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING** for
Levels 61-70; full manual QA of Levels 21-60 also remains separately
pending (only informal partial feedback exists so far: "its good" on a
post-Level-20 sample).

### D68 — Campaign Levels 71-80: third post-reboot expansion, MASTER/MASTER+/EXTREME block

**Context:** by this point the user had manually tested and reported
Levels 1-50 as good (a positive manual baseline), while Levels 51-70
remained automated-validated only, manual QA still pending. The user
asked for Levels 71-80, continuing directly from Level 70's difficulty
into MASTER, MASTER+, and EXTREME tiers, under the same "the board is
one system" whole-board-dependency philosophy as every prior post-
reboot pass, with an explicit new emphasis: push relay dependencies
further than Level 70's two-stage relay, and make Level 80 exceed
Level 70 in reasoning sophistication (not merely size, move count, or
state count).

**Design method — a new, lower-risk technique developed this pass:**
rather than hand-deriving each new level's geometry from scratch (the
technique that produced Level 63's rejected draft in D67 and, as
described below, a rejected Level 72 draft in this pass too), most of
Levels 76-80 were built by taking an already solver-validated level's
exact tile geometry **verbatim** and extending it only in ways proven
safe: adding filters at cells already confirmed to be pure single-beam
transit points (no tile change, no mirror repositioning), or routing a
branch's tail through a portal jump into a confirmed-unused region of
an expanded board, then re-validating that the untouched portion of the
level still produces the exact same solver numbers as its base level
before layering anything new on top. This eliminates almost all
transcription/collinearity risk, since no existing mirror orientation
or position is ever touched. Levels 71/73/74/75 were still hand-
designed fresh (verified correct on the first solver pass in all four
cases); Level 72 needed a rebuild (see below); Levels 76-80 form an
explicit lineage — 76 recolors Level 70's relay skeleton, 77 extends
Level 73's mutual-gate core with a portal, 78 extends Level 72's
shared-gate core with a portal, 79 adds a third emitter to Level 77's
core, and 80 adds a fourth gate plus a cross-coupling of that third
emitter into Level 79's core.

**One full draft rejection** (see `CAMPAIGN_DESIGN.md` section 11k for
the design table this applies to): **Level 72 draft 1** was hand-
derived from scratch — two emitters crossing a shared physical gate
cell, each with its own filter chain. It came back **UNSOLVABLE**: a
transcription error mixed up several intended mirror positions
(`(5,2)`/`(4,2)`/`(4,3)`/`(5,3)`/`(5,4)`/`(4,4)`/`(4,7)`) while hand-
authoring the tile list, confirmed by writing a temporary debug script
(`debug_level72.gd`) that traced the actual beam path with corrected
orientations and showed it exiting the grid without ever reaching
target B. This is the same root-cause class as D65/D66/D67's
collinearity lessons, but specifically a **pure transcription error**
introduced by hand-deriving a multi-mirror crossing geometry from
scratch rather than working from an already-verified layout. Rebuilt by
copying Level 68's already-solver-confirmed tile geometry verbatim
(identical mirror positions/orientations, identical switch/gate) and
adding 3 filters only at cells independently re-traced to be pure
single-beam transit points for exactly one beam each — the rebuild
matched Level 68's own numbers exactly (9 moves, 2036 states, decoy
`(8,8)`), proving zero interference from the added filters. This
"extend a validated design, never re-derive one" technique was then
used proactively for the rest of the block, as described above.

**One mid-design correction caught by the solver itself, not a design
flaw:** Level 79's first version authored the third emitter's entry
mirror at `(9,2)` as `SLASH`. The developer notes assumed this was the
*wrong* orientation (intended to trap the player into needing a flip),
but `GridTypes.reflect()`'s `SLASH: DOWN→LEFT` mapping means `SLASH`
was already the *correct* orientation for a beam arriving `DOWN` — the
solver confirmed this immediately by returning `optimal_moves=12`
(matching Level 77's baseline exactly) and flagging `(9,2)` as
untouched by the shortest solution, meaning the intended "trap" flip
was never actually required. Corrected by re-authoring `(9,2)` as
`BACKSLASH` (genuinely wrong — sends the beam off-grid to the `RIGHT`
if left unflipped), re-validated to `optimal_moves=13` with the mirror
now present in the unique shortest solution. This is a reminder that
hand-predicting a reflect-table outcome and only validating the parts
you changed is not the same as validating the whole level — the solver
caught the mismatch on the very first run.

**Solver ceiling watched, not exceeded (Part 23 of the brief this block
was built under: "redesign rather than raise limits"):** Level 80 has
16 independently-rotatable pieces (1 splitter + 14 mirrors + 1 decoy
mirror), giving a full combinatorial state space of exactly 2^16 =
65536 against `LevelSolver.DEFAULT_MAX_STATES = 65536`. The solver
explored 65519 of those states and returned a definitive `SOLVABLE`
(never `UNKNOWN`), well within budget and completing in well under the
batch script's 25-second timeout guard — but this is deliberately at
the practical ceiling. No further rotatable pieces should be added to
Level 80, and any future level approaching this density should be
checked for a definitive (non-`UNKNOWN`) result before being accepted,
per `CAMPAIGN_DESIGN.md` section 11k.

**Convergence depth pushed past Level 70's benchmark:** Level 70's
relay gates one target behind a two-stage switch/gate dependency
between two emitters. Level 80 gates one target (target A) behind
**four** independently-opened dependencies resolved across multiple
`simulate_until_stable()` passes: the splitter's own mutual g1/g2 gate
dependency (from Level 73/77's core), the portal jump (Level 77/78),
a third emitter's own switch (`g3`, Level 79), and a new gate (`g4`)
opened by the *reflected branch's own post-target delayed consequence*
beam continuation. On top of this, the third emitter — which in Level
79 was a genuinely independent side-puzzle — is itself re-gated in
Level 80 by a new gate (`g1`, reusing the straight branch's own switch
id) before it can even reach its own mirror, meaning what looked like
an unrelated fourth beam source is now provably coupled to the rest of
the board. This satisfies the brief's requirement that Level 80 exceed
Level 70 "not merely by size/move-count/state-count" — Level 80's
`optimal_moves` (14) and grid (10x10) are only modestly larger than
Level 70's (11, 10x10); the actual increase is in convergence depth.

**Architecture: zero changes needed**, exactly as every prior stage
addition — `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 more entries
(`levels/campaign/stage_08/level_01.gd` … `level_10.gd`),
`get_campaign_level_count()` picked up the new total automatically.
Verified directly with a real-autoload driver (temporary `run/
main_scene` swap, reverted immediately after): `get_campaign_level_count()
== 80`; Level 80 loads correctly (`display_name == "Full
Convergence"`); `get_campaign_level(81)` returns `null` with a graceful
`push_warning`, no crash; `is_campaign_level_selectable(80) == true` and
`(81) == false` under the QA-unlock flag; `SaveManager.
campaign_highest_unlocked_level` confirmed untouched (still `1`).

**Validation:** 10/10 new-level solver PASS, 10/10 new-level runtime-
replay PASS, 80/80 full campaign solver PASS, 80/80 full campaign
runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
solvability PASS (Tutorial untouched). Every one of the 10 new levels'
declared `optimal_moves`/`shortest_solution_count`/`states_explored`/
`possible_decoys` fields matches the solver's own confirmed result
exactly (after the Level 72 rejection and the Level 79 mid-design
correction above) — see `CAMPAIGN_DESIGN.md` section 11k for the full
design table.

**Save compatibility:** purely additive — no existing campaign level ID
(1-70) changed, no `SaveManager` field/schema changed.

New build: `versionCode=26`, `versionName="2.3.0-CAMPAIGN-80-QA"`. QA
unlock-all (D58) kept enabled. Levels 1-70 and Tutorial untouched.
**NOT MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING** for
Levels 71-80; Levels 1-50 are the one manually-positive baseline
("these are good" per the user); full manual QA of Levels 51-70 also
remains separately pending.

### D69 — Campaign Levels 81-90: fourth post-reboot expansion, EXTREME/EXTREME+ block, first three-stage relay

**Context:** with Levels 71-80 (D68) shipped and manual QA still
pending, the user asked to continue development by extending the
campaign to 90 levels — EXTREME/EXTREME+ tier, Level 81 continuing
directly from Level 80's difficulty, with an explicit new emphasis on
genuine three-way dependency chains rather than stacking more gates
onto a single target the way Level 80 did.

**New mechanic introduced this pass: the three-stage relay.** Levels
70/76/84 each used a two-stage switch/gate relay between exactly two
emitters (emitter 1 opens emitter 2's gate; emitter 2 opens emitter 1's
gate). Level 87 extends this to THREE emitters in a genuine forward
chain: emitter 1's unconditionally-reachable switch opens emitter 2's
early gate; only then can emitter 2 reach its own switch, opening
emitter 3's early gate; only then can emitter 3 reach its own switch,
opening the FINAL gate on emitter 1's own tail. This resolves
automatically over 4 `simulate_until_stable()` passes with zero new
engine code, exactly as the two-stage version does over 3 passes -
`LaserSystem`'s existing multi-pass gate/switch resolution generalizes
to any number of chained stages without modification, since each pass
just re-evaluates every gate's current `activated_gate_ids` membership
from scratch. Levels 88-90 build on this same three-stage core, adding
double portals (88), a fourth independent converging emitter (89), and
a fifth independent converging emitter creating symmetric convergence
on both ends of the relay (90).

**One full draft rejection** (see `CAMPAIGN_DESIGN.md` section 11l for
the design table this applies to): **Level 87 draft 1** placed emitter
1's and emitter 2's mirror chains in the SAME column (column 2) at
different rows, reasoning that different rows would keep them separate.
The solver reported a 5-move solution instead of the intended ~10-12,
with several unexpected pieces flagged as decoys. Debugging with a
temporary script (`debug_level87.gd`) that applied the solver's actual
solution and printed real beam segments revealed the cause: when
emitter 2's mirror was left at its UNFLIPPED (authored) orientation, it
sent emitter 2's beam directly UP into emitter 1's own mirror at a
different row in the SAME column - and if THAT mirror was also left
unflipped, it redirected emitter 2's beam straight into emitter 1's
entire downstream chain, reaching both targets without the three-stage
relay ever needing to resolve. This is the same root-cause class as
D65-D68's collinearity lessons, but specifically triggered by an
**unflipped-default combination** rather than an already-flipped one -
a mistake that is easy to miss when hand-tracing only the *intended*
solution path, since the intended path never visits that combination.
Rebuilt with every emitter's ENTIRE path (not just its target)
individually confirmed to occupy disjoint rows AND columns from every
other emitter's entire path, including a mental walk-through of what
each mirror's UNFLIPPED default orientation would do. **New standing
lesson for future multi-emitter levels: check disjointness against both
the flipped and unflipped state of every mirror, not just the intended
final configuration.**

**One mid-design correction caught immediately by the solver, not a
design flaw:** Level 89's first draft placed target A at (5,3), one row
off from where the beam actually arrives after its two new forced
bends (the beam travels along row 2 the whole time, never reaching row
3). The solver correctly and immediately reported `UNSOLVABLE` (not a
false positive - the target genuinely could not be reached). Diagnosed
in under one debug-script run by re-simulating the intended orientation
combination directly and printing the real beam segments, which showed
the beam terminating at column 10 (off-grid) along row 2 rather than
ever turning toward row 3. Fixed by moving the target to (5,2), the row
the beam actually occupies, and re-validated to a clean 13-move unique
solution.

**Circular-dependency safety analysis (new for this pass):** with two
independent converging emitters added on top of an already-cyclical-
looking three-stage relay (Levels 89-90), each new gate was individually
checked to confirm it could never create a genuine simulation deadlock.
The rule applied: a gate may only depend on a switch that is reachable
*before* anything that gate itself blocks becomes necessary to reach
that switch. Emitter 4 (Level 89) and emitter 5 (Level 90) were
deliberately kept fully independent - each gates only the very START of
an existing branch (emitter 2's first step, emitter 1's first step
respectively), never anything downstream of their own switch - so
neither could ever be blocked by the very chain they help unlock. A
tempting but REJECTED alternative design (considered, never
implemented) would have had emitter 1's post-target continuation gate
emitter 3's approach - but emitter 3's own switch is needed EARLIER in
the chain (to open the gate that lets emitter 1 finish and reach its
target in the first place), so gating emitter 3 behind emitter 1's
completion would have created a genuine unsolvable circular deadlock.
This was caught during design, before ever writing the level file.

**Convergence depth vs. Level 80's benchmark:** Level 80 gated ONE
target behind four independently-opened dependencies stacked on a
single delivery path. Level 90 takes a different approach to exceeding
it: five emitters, a three-stage relay (itself new this pass), two
portal jumps, and two independent converging gates placed symmetrically
on BOTH ends of the relay chain - depth from breadth of independent
sources and structural symmetry, rather than from stacking more gates
onto one final approach. `optimal_moves` (13) and grid (10x10) are
comparable to Level 80's own (14, 10x10); the actual increase is in the
number of independent beam sources that must all be correctly reasoned
about (5, vs. Level 80's 3) and the structural novelty of the three-
stage relay itself.

**Architecture: zero changes needed**, exactly as every prior stage
addition — `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 more entries
(`levels/campaign/stage_09/level_01.gd` … `level_10.gd`),
`get_campaign_level_count()` picked up the new total automatically.
Verified directly with a real-autoload driver (temporary `run/
main_scene` swap, reverted immediately after): `get_campaign_level_count()
== 90`; Level 90 loads correctly (`display_name == "Full Circuit"`);
`get_campaign_level(91)` returns `null` with a graceful `push_warning`,
no crash; `is_campaign_level_selectable(90) == true` and `(91) ==
false` under the QA-unlock flag; `SaveManager.
campaign_highest_unlocked_level` confirmed untouched (still `1`).

**Validation:** 10/10 new-level solver PASS, 10/10 new-level runtime-
replay PASS, 90/90 full campaign solver PASS, 90/90 full campaign
runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
solvability PASS (Tutorial untouched). Every one of the 10 new levels'
declared `optimal_moves`/`shortest_solution_count`/`states_explored`/
`possible_decoys` fields matches the solver's own confirmed result
exactly (after the Level 87 rejection and the Level 89 mid-design
correction above) — see `CAMPAIGN_DESIGN.md` section 11l for the full
design table.

**Save compatibility:** purely additive — no existing campaign level ID
(1-80) changed, no `SaveManager` field/schema changed.

New build: `versionCode=27`, `versionName="2.4.0-CAMPAIGN-90-QA"`. QA
unlock-all (D58) kept enabled. Levels 1-80 and Tutorial untouched.
**NOT MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING** for
Levels 81-90; Levels 1-50 remain the one manually-positive baseline;
full manual QA of Levels 51-80 also remains separately pending.

### D70 — Campaign Levels 91-100: fifth and FINAL post-reboot expansion, completing the 100-level campaign

**Context:** with Levels 81-90 (D69) shipped and manual QA still
pending, the user asked to complete the originally-planned 100-level
campaign structure by extending to 100 levels — MASTER+/EXTREME/FINAL
CHALLENGE tier, Level 91 continuing directly from Level 90's
difficulty, explicitly framed as a "final exam" testing mastery of
every mechanic the Tutorial teaches, with Level 100 as the definitive
closing puzzle.

**Two techniques used for the first time this pass:**

1. **Genuinely non-rotatable fixed mirrors used specifically for
   backward-reasoning teaching** (Levels 91, 95, 98, 100) - distinct
   from the campaign's earlier fixed mirrors (Levels 67/71/75/85/91's
   own OTHER convergence point), which were load-bearing shared-branch
   convergence points, not backward-reasoning puzzles in their own
   right. Here, a fixed mirror sits between two rotatable mirrors on
   the SAME branch, and the player must reason backward from the
   target's position through the fixed mirror's one possible output to
   deduce the correct orientation for the rotatable mirror upstream of
   it - rather than treating every mirror as an independent, freely-
   guessable rotation.
2. **A genuine shared-state chain where a target's own activation is
   explicitly just a waypoint** (Level 96), directly matching the
   brief's own example: emitter B's beam reaches ITS OWN target,
   continues past it (targets do not stop beams - the same rule
   Level 74 first exploited for delayed consequences), and only THEN
   trips the switch that unlocks emitter C. This deepens Levels 87-90's
   three-stage relay by embedding a real target inside the middle link
   of the chain, rather than a plain switch.

**One full draft rejection, and a significant one** (see
`CAMPAIGN_DESIGN.md` section 11m for the design table this applies to):
**Level 100 draft 1** attempted one more "everything is connected"
touch on top of Level 90's already-validated three-stage relay +
double-portal + symmetric-convergence structure: gating emitter 4's
own approach behind emitter 1's post-target continuation, on the theory
that tying the "independent" fourth emitter into emitter 1's full
delivery would deepen the sense of one coherent system. The solver
immediately reported `UNSOLVABLE`. A temporary debug script
(`debug_level100.gd`) that applied the intended orientation combination
and printed the real beam segments confirmed why: a genuine circular
dependency. Emitter 1 cannot reach its target without gate `gC`, which
only opens once emitter 3 reaches its switch; emitter 3 cannot reach
its switch without gate `gB`, which only opens once emitter 2 reaches
its switch; emitter 2 cannot reach its switch without gate `gD`, which
only opens once emitter 4 reaches its switch; and emitter 4, in this
rejected draft, could not reach its own switch without gate `g5`,
which only opened once emitter 1 had ALREADY reached its target - the
exact thing the whole chain exists to accomplish. This is not an
"apparent" cycle resolved by pass ordering (like the legitimate two-
stage and three-stage relays elsewhere in the campaign, which are
provably forward chains when unrolled) - it is a genuine cycle with no
valid starting point. **This is the single most important confirmation
in this entire five-pass campaign expansion: D69 documented exactly
this failure mode one milestone earlier, explicitly as a lesson for
"any future session" - and the very next level designed after writing
that lesson down almost repeated it anyway.** The safeguard that
actually caught it was not the design review, the hand-trace, or the
lesson being freshly memorized - it was the solver returning an
unambiguous `UNSOLVABLE` result, exactly as the project's own
Active-Design-Rejection process is supposed to work. Fixed by removing
the new gate entirely and restoring emitter 4 to its Level 89/90 role
as a fully independent convergence source (gating only emitter 2's
start, depending on nothing downstream of its own switch) -
re-validated to a clean 13-move unique solution.

**Level 100's tile-count validator warning is a deliberate, examined
tradeoff, not an oversight:** at 42 tiles, `LevelValidator` flags "a
lot - consider whether it could be simplified" (a warning, per
`CLAUDE.md`'s level-editor rules - warnings never block Save or
Playtest, only errors do). Five independent, individually-necessary
beam sources plus a full three-stage relay plus double portals plus a
fixed mirror inherently require more tiles than a smaller design; the
brief's own "elegant, not overloaded" instruction was honored instead
by holding `optimal_moves` (13) and grid size (10x10) to EXACTLY Level
90's own footprint rather than letting either grow, and by verifying
after every tile that it was load-bearing or an explicitly-named,
solver-confirmed decoy - not by chasing a lower raw tile count for its
own sake.

**Solver ceiling watched, not exceeded:** Level 95 independently
reaches the same practical ceiling Level 80 first hit - 16 rotatable
pieces (1 splitter + 15 mirrors), 2^16 = 65536 possible states, solver
explored 65535 and returned a definitive `SOLVABLE`. Level 100 stays
comfortably under this ceiling (13 mirrors, no splitter, 1 fixed
mirror not counted). No level in this pass needed `DEFAULT_MAX_STATES`
raised.

**Campaign completion behavior verified, not built from scratch (Parts
29/33 of the brief):** `game.gd`'s pre-existing `has_next = current_
level_id < LevelManager.get_campaign_level_count()` check and
`LevelCompletePopup.show_result()`'s pre-existing `_next_button.visible
= has_next_level` line require zero changes - they already correctly
handled every prior "current last level" case (Level 10, 20, ... 90)
the exact same way, and now correctly evaluate to `false`/hidden for
Level 100 purely because `get_campaign_level_count()` returns 100. No
dedicated "Campaign Complete" screen or celebration UI was built in
this pass - the existing behavior is confirmed crash-free, makes no
Level 101 lookup, and leaves the player able to return to Level Select
or Main Menu via the existing Retry/Level Select buttons. A dedicated
end-of-100-level celebration screen remains explicitly deferred to a
future milestone, only if and when the user asks for one.

**Architecture: zero changes needed**, exactly as every prior stage
addition — `LevelManager.CAMPAIGN_LEVEL_PATHS` gained 10 more entries
(`levels/campaign/stage_10/level_01.gd` … `level_10.gd`),
`get_campaign_level_count()` picked up the new total automatically.
Verified directly with a real-autoload driver (temporary `run/
main_scene` swap, reverted immediately after): `get_campaign_level_count()
== 100`; Level 100 loads correctly (`display_name == "Culmination"`);
`get_campaign_level(101)` returns `null` with a graceful `push_warning`,
no crash; `is_campaign_level_selectable(100) == true` and `(101) ==
false` under the QA-unlock flag; `SaveManager.
campaign_highest_unlocked_level` confirmed untouched (still `1`); and
`100 < get_campaign_level_count()` (the exact expression `game.gd` uses
for `has_next`) confirmed to evaluate to `false` for Level 100.

**Validation:** 10/10 new-level solver PASS, 10/10 new-level runtime-
replay PASS, 100/100 full campaign solver PASS, 100/100 full campaign
runtime-replay PASS, 15/15 dev-level PASS, 10/10 tutorial-board
solvability PASS (Tutorial untouched). Every one of the 10 new levels'
declared `optimal_moves`/`shortest_solution_count`/`states_explored`/
`possible_decoys` fields matches the solver's own confirmed result
exactly (after the Level 100 rejection above) — see `CAMPAIGN_DESIGN.md`
section 11m for the full design table.

**Save compatibility:** purely additive — no existing campaign level ID
(1-90) changed, no `SaveManager` field/schema changed.

New build: `versionCode=28`, `versionName="2.5.0-CAMPAIGN-100-QA"`. QA
unlock-all (D58) kept enabled — **and MUST be set to `false` before any
final production release build**, now more urgent than ever since the
campaign content itself is complete. Levels 1-90 and Tutorial
untouched. **NOT MANUALLY APPROVED — ANDROID MANUAL DIFFICULTY QA
PENDING** for Levels 91-100; Levels 1-50 remain the one manually-
positive baseline; full manual QA of Levels 51-100 remains the
project's single largest outstanding item. **The 100-level campaign
structure originally planned in `ROADMAP.md` is now complete — do not
create Campaign Levels 101+ or a Stage 11 without being explicitly
asked; that would be new scope, not a continuation of the original
plan.**


### D71 — UI Background Refresh V2 + Laser → Mirror Impact VFX (`versionCode=29`, `2.6.0-UI-VFX-QA`): presentation-only, gameplay untouched

A two-part visual pass on the finished 100-level build. Neither part
touches simulation, level data, the solver, or save data; the full
100/100 + 15/15 + 10/10 regression is unchanged (see `TEST_PLAN.md`).

**Part A — backgrounds.** Three portrait PNGs (941×1672, aspect 0.5628
≈ the 1080×1920 reference's 0.5625) were placed in
`assets/ui/backgrounds/` and wired into their screens only:
`bs_bg_main_menu_v2.png` (Main Menu), `bs_bg_campaign_select_v2.png`
(`level_select.tscn`), `bs_bg_tutorial_select_v2.png`
(`tutorial_select.tscn`). Decisions:

- **No new layout code.** Each scene's existing `Background` `TextureRect`
  was already `EXPAND_IGNORE_SIZE` + `KEEP_ASPECT_COVERED` under the
  project's `canvas_items`/`expand` stretch, which is exactly
  fill-and-center-crop with no distortion. Only the `ext_resource` path
  changed. Rendered at 9:16 (no visible crop) and ~20:9 (1080×2387
  logical; sides trimmed, no stretch).
- **Scrim is scene-local, not themed.** A `ReadabilityScrim` `TextureRect`
  using an inline `GradientTexture2D` (`mouse_filter=IGNORE`, dark
  blue-black `Color(0.015, 0.03, 0.08)`) sits between `Background` and
  the UI. It's shaped per screen rather than one flat dim so the new art
  isn't flattened: Main Menu — bottom-weighted vertical ramp (0 → 0.26 →
  0.30 alpha, starting ~42% down) behind only the button stack;
  Campaign/Tutorial Select — a horizontal center-weighted ramp (0 at the
  edges → 0.24 by 12%/88%) behind the tile grid, title and Back button
  while leaving the hull framing untouched. Chosen after rendering the
  screens *without* a scrim first: the new art was already calm, the
  remaining issue was only the bright planet glow/floor reflections
  behind the title/tiles/buttons. Ceiling was 0.30, well under the
  brief's 0.40.
- The old backgrounds stay on disk (don't delete working assets) but are
  unreferenced, so they're in `exclude_filter` to keep them out of the
  APK. The gameplay background (`bs_bg_gameplay.png`) is unchanged.
- **Observed pre-existing, deliberately not changed** (confirmed by
  rendering the same screens with the old backgrounds): the Main Menu
  `Logo` never draws (a `TextureRect` with `EXPAND_IGNORE_SIZE` inside a
  `CenterContainer` gets zero width — so the V2 art's baked "BEAMSHIFT"
  plaque is currently the only title on that screen), and the Back
  button renders small/with an icon overlapping its label on
  Campaign/Tutorial Select. The brief said not to redesign Back unless
  broken; both are candidates for a future UI pass, flagged in
  `CURRENT_STATUS.md`.

**Part B — `LaserMirrorImpactFX`.** A cosmetic burst where a beam
reflects off a mirror. Decisions and the reasoning a future session
would otherwise have to rediscover:

- **Trigger source is the existing result, read in `GridManager`, not a
  new `LaserSystem` field.** Every mirror a beam reflects off is recorded
  by `LaserSystem` as a segment corner in `result["beams"][i]["segments"]`.
  `GridManager._spawn_mirror_impacts()` walks those corners, keeps the
  ones whose cell holds a `MirrorTile` (`_orientable_nodes.get(pos) is
  MirrorTile` — splitters share that dict but are excluded because the
  beam passes through them), and derives the outgoing direction from the
  next corner (`sign(next - pos)`). Adding a `reflections` array to
  `LaserSystem`'s output was rejected: the brief forbids touching
  simulation, and the data was already there.
- **Contact position** = the mirror cell center, computed with the exact
  expression `_redraw_beams()` uses for beam points (`grid_origin +
  (Vector2(pos) + 0.5) * cell_size`), so the burst is always on the
  beam's corner.
- **Color** = the beam entry's `color` mapped through
  `GridTypes.beam_color_to_render_color` (no duplicate color logic),
  plus a per-color highlight: WHITE → pale warm-white + cyan, BLUE →
  blue + cyan, RED/GREEN → their color + white. **Known limitation
  inherited from the renderer:** `LaserSystem` stores one final color per
  beam branch and `_redraw_beams()` draws the whole branch in it, so if a
  filter recolors a branch *after* a mirror, that mirror's burst is the
  post-filter color — matching what's drawn, not the physically
  "incoming" color. Fixing it needs a simulation change (out of scope).
- **When it fires: player-initiated re-evaluations only.**
  `_simulate_and_draw(play_impacts := false)`; only
  `_on_orientable_tile_clicked()` passes `true`. Load/Reset present the
  board silently (the first-load layout isn't final — `game.tscn`'s grid
  size settles after `_ready()` — so a load-time burst could land at a
  placeholder `cell_size`, and level open shouldn't flash every mirror).
  It is deliberately **not** in `_redraw_beams()`: that runs from
  `_recalculate_layout()` on every resize and would respawn effects. A
  resize instead frees in-flight bursts (they're ~0.3 s, positions would
  be stale).
- **Duplicate/leak protection:** per-evaluation dedupe key (cell,
  incoming, outgoing, color); each new evaluation immediately frees the
  previous evaluation's bursts (`remove_child` + `free`, not
  `queue_free`, so fast taps never stack); each burst also frees itself
  when its Tween ends; hard cap `IMPACT_FX_MAX_COUNT = 40`. No
  `_process`, no per-frame spawning. Beams are instantaneous in this
  project, so multiple reflections spawn together — no staggering.
- **Implementation is one procedural `_draw()`** on a `Node2D`
  (`CanvasItemMaterial` `BLEND_MODE_ADD`, one Tween on a `progress`
  property): stacked translucent discs (flash, ~0.11 s), an `draw_arc`
  ring with a wider faint halo (radius 0.07 → 0.21 cell), and 5 sparks
  (line streak + head dot) sprayed ±0.9 rad around the reflected
  direction (radial if direction unknown). Everything is a fraction of
  `cell_size`; largest extent ≈ 0.5 cell across. Rejected:
  `GPUParticles2D`/`CPUParticles2D` (extra nodes per burst and a
  first-use shader-compile hitch on Android), `PointLight2D` (needs light
  setup/`Light2D` passes; the additive flash reads as glow anyway), and
  the existing `bs_fx_laser_impact.png` (excluded from the export and
  not needed). Spark jitter uses its own `RandomNumberGenerator` and can
  never affect gameplay.
- **Mirror glow pulse (brief B12) skipped**: it would mean touching
  `mirror.gd`'s drawing/modulate, which already has its own tap-pulse
  overlay; the flash disc already lights the mirror cell. No state
  conflicts with orientation visuals as a result.
- **Input safety:** the FX are `Node2D`s (no input handling) under an
  `ImpactFX` `Control` with `mouse_filter=IGNORE`, added *above* the
  beams but below the tutorial dim/highlight. Verified with a real
  synthetic click landing on a mirror while three bursts were alive over
  it (see `TEST_PLAN.md`; needs the window's final transform applied to
  logical coordinates for `Input.parse_input_event`).
- Tutorial: the dim overlay sits above the FX, so bursts dim with the
  rest of the board like the beams do — consistent, and T01's forced-tap
  flow verified unchanged.

**Validation:** see `TEST_PLAN.md` "UI Background Refresh V2 + Mirror
Impact VFX". **Do not** describe this pass as manually approved — only
the user's own Android review can.

### D72 — Rectangular Grid Architecture (Phase 1, `versionCode=30`, `2.7.0-RECT-GRID-QA`): engine/layout capability only, no level content changed

**Brief:** make the puzzle grid engine capable of filling the real
playable rectangle between Top HUD and Bottom HUD for arbitrary
`rows x columns` boards (5x8, 6x9, 6x10, 7x10, 7x11, 8x12, 9x10, etc.),
instead of assuming a good layout is always square. Explicitly NOT a
mandate to redesign Campaign Levels 1-100 — those choose their own
`grid_width`/`grid_height` per level and stay untouched; that's Phase 2.

**Audit first, per this project's standing rule.** Every layer of the
codebase was checked against source before touching anything:
`LaserSystem`, `GridTypes.reflect()`, `LevelData`, `LevelSolver`,
`LevelValidator`, `LevelMetrics`, every tile visual script
(`mirror.gd`/`target.gd`/etc.), `TileVisual.cell_size`'s setter,
`TutorialHighlight`, `TutorialDimOverlay`, `LaserMirrorImpactFX`, and
`game.tscn`'s HUD layout. **Exactly one square-grid assumption existed
in the entire project**: `GridManager._recalculate_layout()` computed
`cell_size = floor(min(size.x, size.y) / max(grid_width, grid_height))`
— a square-fit formula that only ever used the smaller of the two axes,
so a rectangular board would be squeezed down to whichever axis was
tighter instead of using both axes' own available space. Everything
downstream (tile visuals, beam rendering, tutorial highlight/dim, mirror
impact VFX, input hit-testing) already consumed a single `cell_size`
scalar + `grid_origin` Vector2 generically, with zero further
square-only logic - Godot's own `Control` hit-testing handles tap-to-
cell mapping per-tile-node, so there was never any manual screen-to-cell
pixel math to audit there either. `LevelValidator.MAX_SANE_GRID_DIMENSION`
and `LevelMetrics`'s "large grid" warning were both already per-axis/
area-based, not square-only - no changes needed.

**The fix:** replaced the square-only formula with independent per-axis
candidates - `cell_size = floor(min(available_width / columns,
available_height / rows))` - where `available_width`/`available_height`
is `GridManager`'s own rect (already exactly `game.tscn`'s `CenterArea`,
the space its `VBoxContainer` leaves between the two `AspectBar`-driven
HUD bars - no viewport math needed, confirmed by reading `game.tscn`
directly rather than assuming) minus a new single centralized
`GRID_SAFETY_MARGIN` (8px @ 1080-wide reference) inset on every side.
The grid is still centered in the full rect afterward, so a board
saturating one axis still gets a small, non-zero gap on the other -
exactly the "small residual centering gaps are acceptable, large unused
bands are not" requirement. A square board's behavior is unchanged by
construction (`min()` of two equal-ratio candidates picks the same value
either formula would). Two new dev-only diagnostics were added -
`GridManager.get_layout_metrics()`/`format_layout_diagnostics()` -
reporting columns/rows/cell_size/grid_px/available/width_utilization/
height_utilization for a future Phase 2 pass to check a candidate shape
against before committing to it; neither is ever shown to players.

**Validation (see `TEST_PLAN.md` "Rectangular Grid Architecture" for the
full numbers):**
- **Solver-vs-runtime-replay regression, unchanged from before this
  pass**: 15/15 dev, 100/100 campaign, 10/10 tutorial (solvability;
  `is_solved == true` after replaying each solver's own solution through
  a real `GridManager` for all 125), plus 5/5 new temporary rectangular
  fixtures, all PASS. This was expected, not just hoped for - the fix is
  entirely inside `_recalculate_layout()`, a pure `Control`-rect layout
  function `LaserSystem`/`LevelSolver`/`tile_orientations` never call
  into, so gameplay-logic regression was never actually at risk; the
  full replay was still run to prove it, not just asserted.
- **5 temporary rectangular fixtures** (`levels/editor_fixtures/
  fixture_rect_5x8.gd`, `_6x10.gd`, `_7x11.gd`, `_8x12.gd`, `_9x10.gd`) -
  one rotatable mirror each, routes the beam across the board's full
  width then full height corner-to-corner so any per-axis misalignment
  would show up immediately as a visibly offset beam or an inactive
  target. Same `levels/editor_fixtures/` convention as the existing 6
  validator fixtures (`level_id = -1`, never added to any
  `LevelManager` path list, excluded from the Android export) - kept in
  the repo per the brief's own "unless existing testing architecture
  expects them to remain under editor/dev fixture paths" allowance,
  rather than deleted after use.
- **Resolution/layout matrix** (Part 13): a temporary driver
  (`run/main_scene` swapped to a throwaway scene, reverted immediately -
  this project's standard technique) instantiated real `game.tscn` via
  `GameManager`'s existing editor-playtest hand-off fields
  (`editor_level_data`/`is_editor_playtest`, set by hand rather than via
  `start_editor_playtest()`'s `change_scene_to_file()` - calling that
  from the driver node itself would free the very node running the
  coroutine and hang the run, a real mistake made and caught during this
  pass, not a documented gotcha beforehand) at 720x1280, 1080x1920,
  1080x2160, 1080x2400, and 1080x2560 for 8 boards (3 existing square
  levels of different sizes + the 5 rectangular fixtures). Confirmed:
  zero `OVERLAP_TOP`/`OVERLAP_BOTTOM` at any of the 40 combinations;
  every square level's `cell_size` identical across all 5 resolutions
  (logical canvas width never changes under this project's
  `canvas_items`+`expand` stretch, confirming `CLAUDE.md` 12b still
  holds); rectangular fixtures reach 85-100% width and 89-99.8% height
  utilization at the taller resolutions (e.g. `rect_8x12` at 1080x2400:
  100.0% width, 85.3% height) vs. existing square levels' 82.6%/67.3%/
  56.8%/51.4% height at the same four resolutions - the exact contrast
  the brief asked this phase to prove was now possible.
- **RENDERED validation** (`CLAUDE.md` 12d): real (non-`--headless`)
  screenshots captured and visually inspected for one small (5x5, dev
  Level 1), one medium (7x7, campaign Level 21), one large (10x10,
  campaign Level 80 "Full Convergence"), and one temporary tall
  rectangular fixture (7x11) at 1080x2400. All four: tiles square and
  undistorted, beam path correctly aligned to grid cells with no offset
  drift, no clipping against either HUD bar. The 7x11 fixture visibly
  fills nearly the entire playable height between the two HUD bars,
  unlike the 5x5/7x7/10x10 screenshots' large empty bands above/below a
  width-bound square board - visual confirmation matching the automated
  utilization numbers.
- **Pre-existing, unrelated observation (not touched, not a regression):
  4 tutorials (T02/T04/T07/T10) have a declared `optimal_moves` that
  doesn't match the solver's own count**, though all 10 tutorials'
  boards remain solvable (`is_solved == true` for every one, confirmed
  both before and after this pass). Tutorials aren't move-scored (see
  `ARCHITECTURE.md`'s Save format section - no `tutorial_best_moves_
  per_level` field exists), so this is cosmetic/decorative metadata, not
  a gameplay bug, and predates this pass entirely (this pass never
  touched `levels/tutorial/`). Flagging it here so a future session
  doesn't mistake it for something this pass introduced; fixing it (if
  ever wanted) is a Tutorial-content change subject to `TUTORIAL_SYSTEM.md`'s
  own rules, not an engine change.

**Explicitly out of scope for this pass, left for Phase 2 (see
`CLAUDE.md`'s Responsive rules and `ROADMAP.md`):** no Campaign Levels
1-100 `grid_width`/`grid_height`/tile-coordinate changes, no procedural
level generation, no new rectangular levels added to `LevelManager`'s
path lists or Level Select. `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`
untouched (still `true`). Build: `versionCode=30`,
`versionName="2.7.0-RECT-GRID-QA"`, package `com.beamshift.game`,
54,384,898 bytes (byte-identical to the prior build - a code-only pass,
no new assets). **NOT MANUALLY APPROVED - Android visual QA of this
build is pending**, same as every prior pass; only the user's own device
review can approve it.

### D73 — Levels 1-25 Portrait Re-Layout (Phase 2A, `versionCode=31`, `2.8.0-PORTRAIT-L1-25-QA`): board geometry changed, puzzle identity mathematically preserved

**Brief:** re-layout Campaign Levels 1-25 to use the portrait playable
rectangle (D72) substantially better - bigger, more readable tiles and
higher height utilization - while preserving each level's gameplay
identity (mechanics, dependency structure, false routes, solution
sequence, difficulty, unique-shortest-solution status) as closely as
possible. Explicitly NOT a difficulty redesign; explicitly NOT allowed
to touch Levels 26-100 or the Tutorial.

**Technique: order-preserving coordinate remap, not hand redesign.**
`LaserSystem`'s simulation result depends only on the *sequence* of
cell-type hits a beam makes (which mirror/splitter, in what direction,
in what order) - never on the distance between them (`ARCHITECTURE.md`
"Laser propagation algorithm"). This means a transform that (a) maps
every tile sharing an old row to the same new row (and every tile
sharing an old column to the same new column), and (b) is strictly
order-preserving along each axis (an earlier old column/row always maps
to an earlier new one), cannot change which cells a beam hits or in what
order - only how much empty space separates them. Since two distinct old
positions always map to two distinct new positions under such a
transform (different old x maps to different new x; same argument for
y), no accidental new collinearity or collision is possible either. This
converts "redesign 25 levels while preserving difficulty" from a
judgment call per level into a **provable-by-construction** guarantee,
checked directly rather than assumed: a temporary generator script
(`_tmp_relayout_gen.gd`, deleted after use) loaded each OLD level, built
the remap, applied it, ran `LevelSolver.analyze()` on **both** the old
and new tile sets, and printed a pass/fail comparison. **All 25 levels
matched exactly** - identical `status`, `optimal_moves`,
`shortest_solution_count`, AND `states_explored` (not just the first
two - the full BFS search space over rotatable-piece orientations came
out byte-for-byte identical, since the remap preserves which piece flips
change which downstream cell-type sequence, and the rotatable-tile index
order — driven by `tiles` array order, which the generator preserved -
never changed).

**Per-level shape choices** (not one blanket size - each level's board
was analyzed for its own distinct-row/distinct-column content before
choosing dimensions, per the brief's explicit "analyze each puzzle
individually" instruction):
- **Levels 1-19 (five 5x5-origin levels' worth of column footprint):**
  columns held at the original width (preserves the width-bound cell
  size those levels already had, and its board "identity"); rows grown
  to either 6 or 7 depending on each level's own complexity/spread -
  simpler/shorter levels (1-6, 11-14) went to 5x6 at **zero cell-size
  cost** (174px unchanged - adding one row costs nothing when a board is
  already width-bound and the extra row still fits inside the available
  height at that same cell size); longer/more-decoyed levels (7-10,
  15-19) went to 5x7, trading a 14% cell-size reduction (174px -> 150px,
  still comfortably above `UIConstants.MIN_TOUCH_TARGET`'s 144px) for
  fuller height coverage on the stage's more elaborate puzzles.
- **Level 20 (6x6 origin, Stage 2 finale, full board already in use):**
  columns held at 6 (zero spare - all 6 were already load-bearing), rows
  grown to 7 at unchanged cell size (145px).
- **Levels 21-25 (7x7/8x8/9x9 origin, Difficulty Rework Pass 2):** these
  were the one place columns were ALSO compacted, not just rows grown -
  because a 7-, 8-, or 9-wide board already renders BELOW
  `UIConstants.MIN_TOUCH_TARGET` (124px/109px/96px respectively, all
  under the project's own 144px documented minimum touch-target
  constant, a pre-existing condition this phase's own layout-utilization
  audit surfaced, not something Phase 1 or an earlier pass introduced).
  Each level's actual distinct-column count (computed from its own tile
  positions, not assumed) was 5-6 out of the original 7-9, leaving room
  to compact toward 6 or 7 columns while keeping at least the level's own
  distinct-column count intact (zero risk of collision under the remap
  regardless of how tight the compaction is, per the proof above).
  Result: Levels 21-24 -> 6x7 (cell 124/109px -> 145px, up to +33%
  larger), Level 25 -> 7x8 (cell 96px -> 124px, +29% larger, kept one
  spare column beyond its own distinct-column count since it's the block
  finale with two branches that must stay visually separated). All four
  of Levels 21-25's real design properties - the splitter/hazard
  punishment logic (L21, L24, L25), the filter/portal chain (L22), the
  two-chained-fixed-mirror backward reasoning plus false-color-confirmation
  trap (L23), the switch/gate dependency (L24), and the two-fully-disjoint-
  branches structure (L25) - are unchanged, because the remap cannot
  alter which cells are on which beam's path.

**Validation** (see `TEST_PLAN.md` "Levels 1-25 Portrait Re-Layout" for
full numbers):
- **Solver-vs-declared, per-level, before writing any file**: all 25
  MATCH (see technique above) - this is the load-bearing check, not a
  formality.
- **Full regression after all 25 files were written**: 15/15 dev PASS,
  **100/100 campaign PASS** (all 25 changed + all 75 untouched), 5/5
  rectangular-fixture PASS, 10/10 tutorial-board solvability PASS
  (unchanged pre-existing T02/T04/T07/T10 declared-move-count mismatch
  from D72, confirmed still unrelated to this pass - `levels/tutorial/`
  was never touched).
- **Layout/utilization matrix** (Levels 1, 5, 10, 15, 20, 21, 24, 25) at
  720x1280/1080x1920/1080x2400: at the 1080x1920 reference, every tested
  level reached 94.2-99.8% height utilization and 86.0-99.8% width
  utilization (vs. the pre-Phase-2A square-board baseline of 56.8-99.8%
  height with the same width figures) - squarely inside the brief's
  90-100%/85-100% target bands. Zero HUD overlap at any of the 24
  resolution/level combinations tested. On the much taller 1080x2400
  resolution, height utilization is proportionally lower (as expected -
  a fixed-pixel board can't perfectly fill an arbitrarily taller screen
  without becoming a different board per resolution, which the brief
  explicitly forbids) but still describes the same deterministic board
  GridManager scales responsively, per D72's architecture.
- **RENDERED validation** (`CLAUDE.md` 12d): screenshots captured and
  visually inspected for Levels 1, 10, 20, 21, 25 at 1080x1920 - all
  show larger, clearly readable tiles filling nearly the full playable
  height between the two HUD bars, puzzle content genuinely spread
  across upper/middle/lower board regions (not clustered in one corner -
  the brief's Part 4/10 requirement), correct beam alignment, correct
  tile art for every mechanic present (hazard, splitter, portal, fixed
  mirror, blocker), no distortion, no clipping.
- Build: `versionCode=31`, `versionName="2.8.0-PORTRAIT-L1-25-QA"`,
  54,384,898 bytes (byte-identical to the prior build - pure level-data
  edits, no new assets). `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`
  untouched (still `true`). **Levels 26-100 and the Tutorial were never
  written to this pass** (confirmed - only the 10 `stage_01`/`stage_02`
  files and the 5 `stage_03` files up to `level_05.gd` were touched).
  **NOT MANUALLY APPROVED - Android visual QA pending**, same as every
  prior pass.

**Explicitly out of scope for this pass, left for a future batch (see
`ROADMAP.md`):** Levels 26-100 remain on their original square-ish
boards; re-laying them out is a separate future pass, not started, not
authorized by this pass's completion. No procedural generation, no Era 2
content (T11+, Levels 101+) - see the "Future product direction"
documented in `ROADMAP.md` for the long-term Era structure this phase
was asked to record but explicitly not implement.

### D74 — Levels 26-50 Portrait Re-Layout (Phase 2B, `versionCode=32`, `2.8.1-PORTRAIT-L26-50-QA`): same D73 technique, extended to the block's harder mechanics

**Brief:** re-layout Campaign Levels 26-50 the same way D73 did 1-25 -
use the portrait playable rectangle substantially better, individually
chosen board shapes per level, geometry-only (no difficulty/mechanic
change). Explicitly not allowed to touch Levels 1-25 or 51-100.

**Technique: identical order-preserving coordinate remap to D73, no
changes.** Reused verbatim - per-axis, map every distinct old row/column
value to a distinct, order-preserving new value spread across
`[0, new_size-1]`, which by construction cannot change which cells a
beam hits or introduce a new collision (see D73 for the full proof; it
does not depend on which mechanics a level uses, since it operates
purely on tile *positions*, never tile *type*). A temporary PowerShell
generator (`remap.ps1`, deleted after use) applied this per-level, plus
a unified single-pass text substitution that also rewrote every
coordinate reference inside each level's prose `developer_notes` (e.g.
"the fixed mirror at (6,2)") to match, driven off the exact same
old-position -> new-position map used for the `Vector2i(...)` calls -
so prose and code coordinates can never drift apart. The substitution
was restricted to digit-pairs that are REAL tile positions (cross-
checked against the level's own `tiles` array), which correctly left
two prose references alone (Level 34/36's own "a first draft placed
target B directly at (4,0)"-style descriptions of a REJECTED design
that was never actually placed) - confirmed by inspection, not a bug.

**Levels 26-50 are structurally harder than 1-25** (splitters, filters,
portals, switch/gate dependency, hazards/blockers, two-emitter levels
throughout, per the Difficulty Rework Pass 2 and post-reboot-expansion
design work) - every one of the 25 files was read in full for its own
mechanic structure and cross-branch dependency BEFORE choosing a target
shape, per the brief's explicit caution that geometry changes can create
unintended beam intersections in these mechanics. In the event, the
order-preserving proof held for all 25 with zero exceptions - no level
needed a manual geometry correction, and the solver comparison (run
before writing any file, old vs. new, both computed fresh via
`LevelSolver.analyze()`, never assumed from the file's own declared
`optimal_moves`) matched exactly on the first attempt every time.

**Per-level shape choices** (each level's own distinct-row/distinct-
column footprint was extracted from its `tiles` array before choosing
dimensions, not assumed from `grid_width`/`grid_height` - several levels
already had unused rows/columns inside their old square board):
- **7x7-origin levels (27, 29, 31, 46, 47, 48, 49, 50):** 6 of these had
  a real distinct-column count of 6 (not 7), so the remap compacted the
  width too, landing at 6x7 (cell 124px -> 145px, +17%). The 2 that
  genuinely needed all 7 columns (27 Impasse, 50 Paradox) got the exact
  same zero-cost row-growth pattern Phase 2A used for Level 20 - column
  count held at 7, one row added for free (124px cell unchanged, height
  utilization 82.4% -> 94.1%). Level 50 ("Paradox," the campaign's own
  named quality benchmark) is deliberately in this second group - its
  254-state-search structure (chained recolor, filter avoidance, two
  false routes, one fixed-mirror backward-reasoning check, one inert
  decoy) is untouched by construction, not just by intent.
- **8x8-origin (Level 42 Hindsight, the block's one splitter-free single-
  chain level):** distinct-column count was 7, so it dropped to 7x8
  (cell 109px -> 124px, +14%).
- **9x9-origin levels (the majority - 26, 28, 30, 32-41, 43, 44):**
  distinct-column counts ranged 6-8 depending on the level's own branch
  structure, landing at 6x7 (12 levels), 7x8 (7 levels), or 8x9 (2
  levels: 37 Nexus, 40 Crucible - the block's most tile-dense levels,
  17 and 22 tiles respectively) - cell size grew from 96px to 109-145px
  in every case (+14% to +51%).
- **10x10-origin (Level 45 Threshold, the block's biggest board):** real
  distinct-column count was 9 (column 1 was never used), so even without
  compacting below the level's own footprint, dropping the nominal width
  from 10 to 9 raised cell size from 87px to 96px (+10%) at 9x10, with
  one row added at zero further cost (height utilization 82.6% -> 91.1%).

**Aggregate numbers:** average cell size 105.1px -> 132.0px (+25.6%);
average height utilization 82.2% -> 95.2% (+13.0 points); every level's
new cell size is greater than or equal to its old one (two levels -
27, 50 - unchanged, the other 23 strictly larger); zero levels shrank.

**Validation** (see `TEST_PLAN.md` "Levels 26-50 Portrait Re-Layout" for
full numbers):
- **Solver-vs-baseline, per-level, before writing any file**: all 25
  MATCH - identical `status`/`optimal_moves`/`shortest_solution_count`/
  `states_explored`, computed fresh via `LevelSolver.analyze()` on both
  the untouched original and the remapped candidate (not assumed from
  the file's own declared `optimal_moves`, which the batch also happened
  to already agree with in every case).
- **Full regression after all 25 files were written**: 15/15 dev PASS,
  **100/100 campaign PASS** (all 25 changed + 75 untouched), 10/10
  tutorial-board solvability PASS (`levels/tutorial/` never touched).
  This pass additionally ran a **runtime replay** for all 135 dev +
  campaign levels, not just the solver check: a real `GridManager`
  (`scenes/gameplay/grid.tscn`), driven purely through the same
  `_on_orientable_tile_clicked()` entry point a player tap uses, replayed
  each level's solver-found `solution_path` step by step and confirmed
  `is_solved == true` at the end - the runtime-vs-solver technique
  `TEST_PLAN.md`/`CLAUDE.md` 12c describes, applied here to the FULL
  regression population rather than just the changed levels, as an
  extra margin of confidence for this harder-mechanics block.
- **RENDERED validation** (`CLAUDE.md` 12d, real non-headless GPU
  rendering via a temporary `GameManager.is_editor_playtest` driver
  scene, deleted after use): screenshots captured and visually inspected
  for Levels 26, 28, 30, 35, 40, 45, 50 at 1080x1920 - all show larger
  or equal, clearly readable tiles, puzzle content spread across upper/
  middle/lower board regions, correct beam/portal/filter/splitter
  rendering with correct alignment, no distortion, no clipping, no HUD
  overlap. A further RENDERED check at 1080x2400 (Level 45, the block's
  tallest board) confirmed the taller screen correctly reveals more
  background above/below the fixed-size board rather than distorting or
  re-flowing it, exactly as D72/D73 documented; a RENDERED check at
  720x1280 (Level 28) confirmed the same-aspect narrower resolution
  scales the identical logical layout down cleanly. Closed-form
  utilization math (the same `cell_size = floor(min(avail_w/cols,
  avail_h/rows))` formula `GridManager._recalculate_layout()` uses,
  cross-checked against D73's own published figures before use) was used
  to compute the full utilization table across all three resolutions.
- Build: `versionCode=32`, `versionName="2.8.1-PORTRAIT-L26-50-QA"`,
  54,384,898 bytes (byte-identical to the prior build - pure level-data
  edits, no new assets, same as D73's own build). `UNLOCK_ALL_CAMPAIGN_
  LEVELS_FOR_TESTING` untouched (still `true`). **Levels 1-25 and 51-100
  and the Tutorial were never written to this pass** (confirmed via
  `git status` - exactly the 25 intended `stage_03`/`stage_04`/`stage_05`
  files changed). **NOT MANUALLY APPROVED - Android visual QA pending**,
  same as every prior pass.

**Process note - version control added this pass.** The project had no
git repository before this pass (`git init` + a baseline commit was
added as the very first step, once a scripting bug in an early,
since-fixed draft of the remap tool briefly corrupted one level file
before any safety net existed - caught and restored immediately from the
Read tool's own earlier output, but it made the absence of any recovery
path obvious). Every level file this pass wrote was committed only after
its solver comparison passed. Future sessions should keep committing
incrementally the same way, not treat the working tree as the only copy
of anything again.

**Explicitly out of scope for this pass, left for a future batch (see
`ROADMAP.md`):** Levels 51-100 remain on their original board shapes;
re-laying them out is a separate future pass, not started, not
authorized by this pass's completion. No procedural generation, no Era 2
content (T11+, Levels 101+).

### D75 — Levels 51-75 Portrait Re-Layout (Phase 2C, `versionCode=33`, `2.8.2-PORTRAIT-L51-75-QA`): same D73/D74 technique, on the campaign's most interconnected block yet, plus one level left deliberately unchanged

**Brief:** re-layout Campaign Levels 51-75 the same way D73/D74 did 1-50
- individually chosen board shapes, geometry-only, explicit priority
order (puzzle correctness > reasoning/dependencies > optimal solution >
unique shortest solution > tile readability > screen utilization -
utilization is NOT allowed to be chased at the expense of anything
above it). Explicitly not allowed to touch Levels 1-50 or 76-100.

**Technique: identical order-preserving coordinate remap, unchanged
again.** Same `remap.ps1` tool from D74, same proof (position-only
transform, cannot change which cells a beam hits or in what order - see
D73). This block is structurally the most interconnected yet: mutual
switch/gate pairs where each branch's switch opens the OTHER branch's
gate (Levels 51, 73), two-and-three-stage relay dependencies (Level 70's
two-stage relay: emitter 1's switch opens emitter 2's early gate, emitter
2's switch - reached only after - opens emitter 1's own later gate),
shared gate cells crossed by perpendicular-direction beams from two
different emitters (Levels 68, 72 - one beam horizontal, one vertical,
either emitter's switch opens it for both), post-target beam
continuation gating a second branch (Levels 65, 74, 75), and cross-
branch shared fixed mirrors combined with independent 2-filter-order
chains (Levels 58, 67, 75). Every one of these mechanic types was
individually reasoned through (not just solver-trusted) before choosing
a shape, per the brief's explicit instruction not to trust the remap
solely because the solver still finds a solution - see the
"why this generalizes" note below for why they all reduce to the same
already-proven case.

**Why every one of these interconnected mechanics is still safe under a
position-only remap:** `pair_id`/`gate_id` matching (portals, switches,
gates) is done by STRING, never by position or distance - remapping
tile positions cannot change which switch opens which gate, or which
two portals are paired, regardless of how many stages the relay has or
which direction two crossing beams travel in. Post-target beam
continuation (Levels 65, 74, 75) is safe because the remap never inserts
tiles between two previously-adjacent non-empty cells - if nothing sat
between a target and the next tile before the remap, the transform
maps both tiles to new positions with only empty space between them
again (order-preserving by construction), so the beam still passes
through empty space and hits the same next tile. Perpendicular multi-
emitter crossings (Levels 68, 72) are safe because each axis is remapped
independently and consistently for every tile on it - a beam traveling
along a constant-x or constant-y line stays on that (renumbered) line
after remap, since every tile that shared the old coordinate value
shares the new one too. None of this is new reasoning specific to this
block; it is the same D73 proof applied to more elaborate but
structurally identical position-only invariants.

**One level required no change at all: Level 75 ("Convergence
Reaction").** Its distinct-column count (9) already equals its
`grid_width` (9) and its distinct-row count (10) already equals its
`grid_height` (10, itself already non-square/portrait-shaped from
original design) - zero slack on either axis, so no remap can compact
or grow it without either violating its own content footprint or (per
the cell-size formula) shrinking its cell size below its current 96px.
Left untouched; `git status` after this batch confirmed only Levels
71-74's files changed, not 75's.

**Two other levels' original boards were already non-square** (Level 52
"Currents" 8x7, Level 57 "Long Division" 10x9) - both predate this pass
and confirm not every pre-D72 board was a naive square; the remap
script's `grid_width`/`grid_height` handling is driven off each file's
actual current values, not an assumed square, so this needed no special
casing.

**Per-level shape choices** (each level's own distinct-row/distinct-
column footprint was extracted from its `tiles` array before choosing
dimensions): 6x7 (Levels 52, 53 - zero-spare exact fits), 7x8 (Levels
51, 55, 58, 61, 64, 66 - several with a full or near-full row/column
dimension), 8x9 (Levels 62, 63, 68, 69, 72), 8x10 (Level 59 - the one
case where narrowing the width from 10 to 8 flips which axis is
cell-size-binding, making the narrower shape strictly larger-celled than
a wider one would be at the same content-driven height), 9x10 (Levels
54, 56, 60, 65, 67, 70, 71, 73, 74 - the majority; several of these
boards were already fully packed on one or both axes, so this batch's
"growth" was mostly the same zero-cost extra-row pattern D73/D74 used,
not compaction), 10x11 (Level 57 - width forced full at 10, one zero-
cost row added). **Every new cell size is greater than or equal to its
old one; zero levels shrank; 7 of 25 (54, 56, 57, 62, 65, 67, 75) held
their exact old cell size** (Level 75 because it was left unchanged, the
other 6 via the same zero-cost row-growth pattern D73 established for
Level 20 and D74 used for Levels 27/50) while gaining better height
utilization or, in Level 75's case, no change at all.

**Aggregate numbers:** average cell size 96.7px -> 109.2px (+13.0%) -
a smaller percentage gain than D74's +25.6%, because this block starts
with markedly less compaction slack (several boards, e.g. Levels 56, 60,
67, 70, 71, 73, already used every column or every row of their old
grid) - reported honestly rather than chased with a shape that would
have sacrificed tile size or puzzle geometry to hit a bigger number, per
the brief's explicit priority order. Average height utilization 81.9% ->
93.0% (+11.0 points).

**Validation** (see `TEST_PLAN.md` "Levels 51-75 Portrait Re-Layout" for
full numbers):
- **Solver-vs-baseline, per-level, before writing any file**: all 25
  MATCH (24 changed + Level 75 trivially, since it was never touched) -
  identical `status`/`optimal_moves`/`shortest_solution_count`/
  `states_explored`, matched on the first attempt for every level,
  including the two levels (68, 72) whose own `developer_notes` document
  a genuine zero-move load-bearing piece with a non-round
  `states_explored` value (2036, not 2047) - both preserved exactly,
  confirming the remap didn't perturb that subtlety.
- **Per-sub-batch git checkpoints**: committed only after each batch's
  own solver + validator + real-`GridManager` runtime-replay check
  passed - 51-60 (10/10), 61-70 (10/10), 71-75 (5/5, including the
  unchanged Level 75) - never batched all 25 and validated afterward,
  per the brief's explicit instruction.
- **Full regression after all changes**: 15/15 dev PASS, **100/100
  campaign PASS** (24 changed + Level 75 unchanged + 75 untouched),
  10/10 tutorial-board solvability PASS, and a real-`GridManager`
  runtime replay (via `_on_orientable_tile_clicked()`, the same entry
  point a player tap uses) across the FULL 115-level dev+campaign
  population, same extended-regression practice D74 established.
- **RENDERED validation** (`CLAUDE.md` 12d): screenshots captured and
  visually inspected for Levels 51, 55, 60, 65, 70, 75 at 1080x1920 -
  all show correct gate/switch/portal/filter rendering, puzzle content
  spread across upper/middle/lower board regions, no clipping, no HUD
  overlap. Levels 60, 70, 75 additionally RENDERED at 720x1280 (same-
  aspect narrower resolution, scales cleanly) and 1080x2400 (taller
  resolution correctly reveals more background above/below the fixed-
  size board, zero overlap, exactly as D72/D73/D74 documented).
- Build: `versionCode=33`, `versionName="2.8.2-PORTRAIT-L51-75-QA"`,
  54,384,898 bytes (byte-identical to the prior build - pure level-data
  edits, no new assets, same as every prior portrait-re-layout build).
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` untouched (still `true`).
  **Levels 1-50 and 76-100 and the Tutorial were never written to this
  pass** (confirmed via `git status`/`git diff --stat` against the
  pre-Phase-2C checkpoint commit - exactly the 24 intended
  `stage_06`/`stage_07`/`stage_08` files changed). **NOT MANUALLY
  APPROVED - Android visual QA pending**, same as every prior pass.

**Process note - git checkpoints used as designed.** A checkpoint commit
was made before touching any Level 51-75 file, then one commit per
validated sub-batch (51-60, then 61-70, then 71-75), each only after
that batch's own solver/validator/runtime-replay check passed - the
practice D74 introduced, now exercised as intended across three
sequential checkpoints in one session.

**Explicitly out of scope for this pass, left for a future batch (see
`ROADMAP.md`):** Levels 76-100 remain on their original board shapes;
re-laying them out is a separate future pass, not started, not
authorized by this pass's completion. No procedural generation, no Era 2
content (T11+, Levels 101+).

### D76 — Levels 76-100 Portrait Re-Layout (Phase 2D, `versionCode=34`, `2.9.0-PORTRAIT-100-QA`): FINAL BATCH — all 100 Campaign levels now portrait-re-laid-out

**Brief:** complete the final portrait re-layout batch, Campaign Levels
76-100, finishing what D73/D74/D75 started for Levels 1-75. Same
priority order as D75 (puzzle correctness > dependency structure >
optimal solution > unique shortest solution > solver-state fingerprint
> advanced reasoning/false routes > mobile readability > screen
utilization). Explicitly not allowed to touch Levels 1-75 or create
Level 101+.

**This is the campaign's hardest and most tile-dense block** - by tile
count (up to 42 on Level 100), rotatable-piece count (up to 16 on
Levels 80 and 95, at the practical solver ceiling 2^16=65536), emitter
count (up to 5 on Levels 90 and 100), and dependency depth (three-stage
relays on 87/88/89/90/96/100, a four-independent-source convergence on
Level 80, five-link backward-reasoning chains on Level 98). Every level
was read in full and its dependency graph understood before choosing a
shape - not just solver-trusted - though the order-preserving proof
(D73, extended by D74/D75's "why every interconnected mechanic is still
safe" reasoning) held unconditionally for all 25 anyway, with zero
exceptions.

**Four levels required no change at all - established as a real,
recurring pattern, not a one-off.** Levels 85, 91, 95, and 98 were each
already at 9x10 with their distinct-column count (9) exactly equal to
`grid_width` and distinct-row count (10) exactly equal to `grid_height`
- zero slack on either axis. This is the same situation D75 first
identified for Level 75, now confirmed to recur naturally: as campaign
levels grew more content-dense over the course of design, several were
already authored close to an efficient portrait shape without anyone
targeting one. Left untouched in every case; `git status` after each
sub-batch confirmed only the intended files changed.

**A new, deliberate technique this pass: zero-cost "breathing room"
row growth on fully-packed boards, applied at its full safe extent
rather than by one arbitrary row at a time.** 15 of the 21 changed
levels (77, 79, 80, 82, 83, 86, 88, 89, 90, 92, 93, 94, 97, 99, 100)
have a distinct-column count of exactly 10, equal to their full
`grid_width` - meaning width cannot be compacted at all, it is already
at its content-driven minimum. For these, `cell_size = floor(min(872/
cols, 1053.94/rows))` is width-bound at 87px regardless of height up to
`rows=12` (`floor(1053.94/12) = 87`, unchanged; `rows=13` would drop it
to 81px) - so growing `grid_height` from 10 to 12 is entirely free:
zero cell-size cost, height utilization rising from 82.6% to 99.1%. This
generalizes the same zero-cost-row-growth pattern D73 introduced for
Level 20 (and D74/D75 reused for Levels 27/50/54/56/57/62/65/67) to its
logical maximum extent - previous passes typically stopped at the first
available free row; this pass computed the actual ceiling
(`floor(1053.94/87.2) = 12`) and used all of it, since there was no
reason not to once the technique's safety was already established. The
remaining 6 changed levels (76, 78, 81, 84, 87, 96) had a distinct-
column count of 9 (one column already unused), so width compacted from
10 to 9 (cell 87px -> 96px, a real improvement, not just zero-cost) with
height landing at 10 (the zero-cost ceiling for a 9-wide board, per the
same formula).

**Level 80 ("Full Convergence") and Level 95 ("Final Threshold") are
this pass's solver-ceiling-adjacent levels** (16 rotatable pieces each,
2^16=65536 candidate states against `LevelSolver.DEFAULT_MAX_STATES`).
Level 80 was changed (10x10 -> 10x12, zero-cost); its solver check
before writing reported `states_explored=65519` both before and after,
confirming the state space size is unaffected by geometry, only by
rotatable-piece count. Level 95 was one of the four unchanged levels,
so this risk never applied to it at all.

**Level 100 ("Culmination") — the definitive Era 1 finale — went
10x10 -> 10x12 at the zero-cost pattern**, its own distinct-column
count being 10 (full width). All eleven things Step 14 of the brief
asked to be explicitly verified were checked via the solver-vs-baseline
comparison and a real-`GridManager` runtime replay: all five emitter
routes, all three relay stages, both portal transitions (pair P and
pair Q), the symmetric convergence (emitter 4 gating emitter 2's start,
emitter 5 gating emitter 1's start), the fixed-mirror backward-reasoning
step at (3,2) (renumbered under remap but never rotated - `rotatable=
false` tiles are excluded from the solver's bitmask by construction,
so the remap cannot touch its correctness), target continuation, filter/
color behavior, the one intentional decoy, `optimal_moves` (13 -> 13),
`states_explored` (16383 -> 16383), and `shortest_solution_count`
(1 -> 1) - all confirmed identical, matched on the first remap attempt.
No candidate was rejected; Level 100 did not need to be left unchanged.

**Per-level shape choices**: 9x10 (6 levels: 76, 78, 81, 84, 87, 96 -
compacted from 10-wide, zero-cost row growth to the ceiling), 10x12
(15 levels: 77, 79, 80, 82, 83, 86, 88, 89, 90, 92, 93, 94, 97, 99, 100
- width forced at 10, zero-cost row growth to the ceiling), unchanged
(4 levels: 85, 91, 95, 98).

**Aggregate numbers for Levels 76-100**: every level's new cell size is
greater than or equal to its old one - the 6 compacted levels gained
+10% cell size (87px -> 96px), the 15 zero-cost-growth levels held
their exact 87px cell while height utilization rose from 82.6% to
99.1%, and the 4 unchanged levels are byte-identical to before. Zero
levels shrank. See `TEST_PLAN.md` for the full per-level before/after
table.

**Validation** (see `TEST_PLAN.md` "Levels 76-100 Portrait Re-Layout"
for full numbers):
- **Solver-vs-baseline, per-level, before writing any file**: all 25
  MATCH (21 changed + 4 unchanged, trivially) - identical `status`/
  `optimal_moves`/`shortest_solution_count`/`states_explored`, matched
  on the first attempt for every level, including Level 80's 65519-state
  solver-ceiling-adjacent search and non-round state counts (e.g. Level
  78's 16369, inherited from Level 72's own zero-move-load-bearing-piece
  situation) preserved exactly.
- **Per-sub-batch git checkpoints**: committed only after each batch's
  own solver + validator + real-`GridManager` runtime-replay check
  passed - 76-80 (5/5), 81-90 (10/10, including unchanged Level 85),
  91-100 (10/10, including unchanged Levels 91/95/98 and the fully-
  verified Level 100) - never batched all 25 and validated afterward.
- **Full regression after all changes**: 15/15 dev PASS, **100/100
  campaign PASS** (21 changed + 4 unchanged + 75 untouched), 10/10
  tutorial-board solvability PASS, and a real-`GridManager` runtime
  replay across the FULL 115-level dev+campaign population - 115/115
  PASS, same extended-regression practice D74/D75 established.
- **RENDERED validation** (`CLAUDE.md` 12d): screenshots captured and
  visually inspected for Levels 76, 80, 85, 87, 90, 95, 100 at
  1080x1920 - all show correct gate/switch/portal/filter/fixed-mirror
  rendering, puzzle content spread across upper/middle/lower board
  regions, no clipping, no HUD overlap. Levels 80, 90, 95, and 100
  additionally RENDERED at 720x1280 and 1080x2400 (Level 100 at all
  three required reference resolutions per the brief's explicit
  instruction) - zero HUD overlap or clipping at any resolution.
- **Final read-only audit across all 100 campaign levels** (see
  `TEST_PLAN.md` for the full table): 100/100 SOLVABLE, zero levels
  below the 90% height utilization target, zero levels below the 85%
  width utilization target, min cell 87px, max cell 174px, average cell
  122.4px, average width utilization 98.2%, average height utilization
  95.6%. **The full portrait re-layout of the entire 100-level campaign
  is now complete.**
- Build: `versionCode=34`, `versionName="2.9.0-PORTRAIT-100-QA"`,
  54,384,898 bytes (byte-identical to the prior build - pure level-data
  edits, no new assets, same as every prior portrait-re-layout build).
  `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` untouched (still `true`).
  **Levels 1-75 and the Tutorial were never written to this pass**
  (confirmed via `git diff --stat` against the pre-Phase-2D checkpoint
  commit - exactly the 21 intended `stage_08`/`stage_09`/`stage_10`
  files changed). **NOT MANUALLY APPROVED - Android visual QA pending**,
  same as every prior pass.

**Era terminology, recorded per the brief's explicit instruction
(documentation only - nothing below is implemented):** the current,
complete 100-level campaign plus the T01-T10 tutorial together
constitute **Era 1**. A future **Era 2** (Levels 101-200, a T11-T20
tutorial pack, new mechanics, a new visual theme) is the long-term
direction already documented in `ROADMAP.md` - not started, not
authorized by this pass's completion, and not to be started without a
separate, explicit request. The player-facing game does not yet
implement any Era framing (still separate Campaign/Endless-style
structure); that unification is itself future work.

**Process note - all three portrait phases (2B/2C/2D) used the
identical `remap.ps1` tool and git-checkpoint discipline D74/D75
established, unmodified.** No changes to the remap technique itself
were needed across 75 levels (26-100) spanning from simple single-chain
puzzles to five-emitter, three-stage-relay, double-portal finales - the
order-preserving proof's independence from mechanic type held completely.

**Explicitly out of scope for this pass, and for any future pass
without an explicit separate request:** Level 101+, T11-T20, procedural
generation, Era 2 mechanics or visual theme, menu redesign, disabling
QA unlock, a production release build.

## D77 — Era 2 Foundation: mechanics, architecture, T11-T20, and two real bugs found via rendering

Built per an explicit request to implement Era 2's engine/architecture
foundation - full technical reference is `ERA_2_DESIGN.md`, not
repeated here in full. This entry records the decisions and the two
real bugs found, both only catchable by actually rendering/exporting,
not by source review.

**Mechanic rule choices, and why:**
- **Prism** channel directions are derived from the existing
  `GridTypes.reflect()` table (RED = straight, GREEN = `reflect(dir,
  SLASH)`, BLUE = `reflect(dir, BACKSLASH)`) rather than a new lookup -
  this was chosen specifically so the rule needed zero new truth table
  and reads as a natural extension of the reflection rule that already
  exists in exactly one place (rule 3). A colored beam producing only
  its own channel (never multiplying into the other two) was chosen
  over the alternative of a colored beam still splitting into a
  same-color-tinted version of all three, because the "only your own
  channel" rule is unambiguous, requires no new state, and gives a
  genuinely useful puzzle mechanic (routing different colors through a
  chain of prisms differently) for free.
- **One-Way Reflector** deliberately reuses Mirror's exact
  `MirrorOrientation` field and tap-to-rotate handler rather than adding
  a second stored "which side reflects" bit, per the brief's own
  explicit preference for reusing the existing orientable-tile
  architecture. This means only 2 distinct reflective-pair
  configurations exist (not the 4 a fully independent per-direction
  design could have), a deliberate simplification - documented, not
  discovered as a limitation later. The reflective pair is defined as
  "whichever pair contains RIGHT," letting a single one-line predicate
  (`incoming_dir == RIGHT or reflect(incoming_dir, orientation) ==
  RIGHT`) fully determine it with zero new stored state. Consequence:
  a rightward-travelling beam always reflects; rotation only changes
  which way. T15/T16 are built directly around this fact.
- **Beam Receiver -> Remote Emitter** reuses the switch/gate
  multi-pass resolution strategy verbatim (a new `receiver_states`
  dictionary threaded alongside `gate_states` through `simulate()`,
  merged monotonically after each pass in `simulate_until_stable()`) -
  the brief's own Part 11 asked for exactly this ("integrate it into
  simulate_until_stable() correctly"), and reusing an already-correct,
  already-loop-safe pattern was preferred over inventing a new one.
  `link_id` is a field distinct from `gate_id` (not reused) since
  they're conceptually separate dependency graphs that happen to use
  the same string-key-dictionary mechanism.

**Bug 1 - Android export-filter exclusion (a repeat of D51's exact
failure mode).** `assets/gameplay/pieces/**` is broadly excluded from
the Android build - the same folder whose blocker/hazard files caused a
real shipped-build bug once before. The new Prism/One-Way Reflector/
Beam Receiver/Remote Emitter `_base`/`_inactive` art was initially
placed under `assets/gameplay/pieces/era2/` (matching the raw asset
drop's own folder layout) and would have been silently missing from
every real Android build - looking completely correct in every source-
based check and even in a non-headless desktop render (which reads
source directly, bypassing the export filter entirely - see `CLAUDE.md`
12a). Caught only by actually running `godot --headless --path .
--export-pack "Android Debug" out.pck` and checking `ResourceLoader
.exists()` against the real package. Fixed by moving the 6 actually-
`preload()`-ed files into their own per-tile-type folders
(`assets/gameplay/{prism,one_way_reflector,beam_receiver,
remote_emitter}/`), matching the existing one-folder-per-type
convention - re-verified against a fresh real export: all 6 files exist
in the package, the old path does not, and all 4 new tile scenes
instantiate correctly loaded from that same package.

**Bug 2 - QA tutorial-unlock override didn't actually bypass unlock.**
The first draft of `LevelManager.is_tutorial_level_selectable()` checked
`SaveManager.is_tutorial_level_unlocked()` FIRST, unconditionally, and
only applied `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` as a secondary
check reachable after that real-progress check already passed. On this
machine's actual `user://savegame.json` (T01-T10 completed in an
earlier dev/QA session, `tutorial_highest_unlocked_level == 10`), that
meant T11-T20 still showed locked in Tutorial Select despite the QA
flag being `true` - caught by an actual RENDERED screenshot of Tutorial
Select (not source review), which showed padlock icons on T11-T18.
Fixed to match `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`'s own
unconditional-bypass-within-`get_tutorial_level_count()`-range semantics
exactly, and re-verified with a second render showing all cards
unlocked.

**Two new, generally-applicable techniques confirmed this pass, worth
keeping for any future asset-drop pass:**
1. A brand-new `.png` fails `preload()` with "has no resource loaders"
   until a real editor import pass has run - `godot --headless
   --editor --import` once per asset-drop batch. The same command also
   regenerates the global `class_name` cache, needed for any new
   `class_name` script another script references (a plain `godot
   --headless --path .` run of the whole project is what actually
   surfaces both failure modes cleanly, as `SCRIPT ERROR: Parse Error`
   lines - do this before trusting any newly-added script or asset).
2. `godot --path . --rendering-driver d3d12` (no `--headless`) plus a
   small driver script that instantiates target scenes directly as
   children of `get_tree().root` (NOT via `change_scene_to_file()`,
   which frees whatever called it if that's the current scene) and
   calls `get_viewport().get_texture().get_image().save_png()` produces
   real, inspectable screenshots without any manual/on-device step -
   this is what caught both bugs above. See `CLAUDE.md` 12d; this pass
   is the first to actually exercise that technique end-to-end for a
   full visual-system change rather than a single-bug investigation.

Validated: full 115-level dev+campaign solver regression unchanged
(confirmed identical, not assumed); 12/12 new Era 2 fixtures pass
exactly as designed (including hazard detection and multi-pass
switch+receiver resolution); 10/10 new tutorials solve at their
hand-derived `optimal_moves` and pass `LevelValidator` with zero
errors; 5 RENDERED screenshots (1080x1920, real GPU) confirmed correct
rendering both before and after the two fixes above. Build:
`versionCode=35`, `versionName="3.0.0-ERA2-FOUNDATION-QA"`, both QA
unlock flags kept `true`. **NOT MANUALLY APPROVED - Android device QA
pending.** Campaign Levels 101-200 remain explicitly out of scope for
this pass, per its own STOP CONDITION - do not start them without a
separate, explicit request.

**Correction (found during D78 below): this pass's own fixture count was
undercounted by one.** `levels/editor_fixtures/era2/` actually contains
**13** files, not 12 - `fixture_one_way_reflector_backslash` was present
alongside `_slash` from the start but never added to this entry's or
`TEST_PLAN.md`'s prose list. All 13 were always being created and always
passing; only the written count was wrong. Fixed wherever "12" appeared
- see D78.

## D78 — Era 2 Foundation QA/Hardening pass: milestone asset, T11-T20 guided step-machine, UI wiring, APK optimization, two real rendering bugs found and fixed

Built per an explicit QA/hardening brief with its own STOP CONDITION
(no Level 101, no new mechanic, no Era 3, no production release). Summary
of what changed and what was found - **read this before touching
anything under `scripts/ui/*_complete_popup.gd`, `scripts/ui/*_button.gd`,
`era_theme.gd`'s panel fields, or `export_presets.cfg`'s exclude_filter.**

**Part 1 - milestone asset.** `bs_milestone_complete_era2.png` (the user
supplied it this pass) imports cleanly, has a real alpha channel
(pixel-sampled directly: corners alpha 0.0, center/plate alpha
~0.99 - a genuine radial-vignette fade, not a baked checkerboard), bakes
no text (empty plate area, meant for future dynamic overlay), and is
confirmed present in a real exported APK (`assets/.godot/imported/
bs_milestone_complete_era2.png-*.ctex`). **Deliberately left unwired** -
Level 200 doesn't exist; no UI trigger references it. Verify-before-
trusting note: a brand-new asset always needs one `--headless --editor
--import` pass before `preload()`/`ResourceLoader.exists()` will see it -
confirmed again this pass (D77's own lesson, still holds).

**Part 2/3 - T11-T20 guided step-machine, real signal paths.** The prior
pass (D77) only solver/validator-tested T11-T20; this pass built a real
driver mirroring `game.gd`'s own signal wiring (`GridManager.move_made`/
`simulation_updated`/`level_solved` -> `TutorialManager.notify_*()` ->
`advance()`), exercising MESSAGE/REQUIRE_TILE_TAP (including wrong-tile
rejection and correct-tile acceptance through the real
`_on_orientable_tile_clicked()` path)/WAIT_FOR_TARGET_ACTIVATION/
WAIT_FOR_PUZZLE_SOLVED, Reset (`restart()` + reload back to step 0),
Pause/Resume (`suspend_tutorial_focus()`/`resume_tutorial_focus()`), and
completion (`tutorial_finished`). **Result: 10/10 PASS.** T20 ("Era 2
Graduation") has no `REQUIRE_TILE_TAP` steps at all (free play, same
pattern as T10) - the driver handles this generically by calling the
real `LevelSolver.analyze()` on any board that reaches
`WAIT_FOR_PUZZLE_SOLVED` still unsolved and applying its solution's taps
through the real click path, rather than hand-deriving T20's solution
into the test.

**A harness pitfall worth keeping for the next driver like this:** the
first two drafts of this driver produced dozens of `SCRIPT ERROR`s
(`_highlight_node`/`_dim_overlay` null, `add_child()` "Parent node is
busy") that looked like real `GridManager` bugs but were **entirely
test-harness reentrancy** - a `Node`'s own `_ready()` cannot
synchronously `get_tree().root.add_child()` a sibling while `root`
itself is still finishing its own child setup (the very scene that's
running). Fixed by adding the test grid as a child of the driver node
itself (not `root`), and by reusing ONE persistent `GridManager` +
`TutorialManager` pair across all 10 tutorials (`restart()` -> `start()`
-> `load_level()` -> `advance()` per tutorial) instead of creating and
`queue_free()`-ing a fresh pair per tutorial inside one synchronous
`_ready()` with no frame yields in between. This second change also
made the driver a closer match to `game.gd`'s own real reuse pattern
(`%PuzzleGrid` and its `TutorialManager` are never recreated between
tutorials in actual play either).

**Part 4/6 - UI asset integration audit and two real integrations.**
Every asset in the brief's list was opened and visually inspected (not
just grepped), because this project has shipped a mismatched/mislabeled
asset before (D48) and a fixed-content "reference" asset mistaken for
production art before (`CLAUDE.md` rule 10). Classification:
- **A (wired this pass):** `bs_panel_level_complete_clean_era2.png` (a
  genuinely empty, text-free frame - now `LevelCompletePopup`'s panel art
  for any Era 2 level) and `bs_panel_tutorial_complete_era2.png` (same,
  for `TutorialCompletePopup`, T11-T20 only). Margins were pixel-measured
  per file (luminance-deviation scan outward from center, same
  discipline as D49/D52's flood-fill), not eyeballed:
  `level_complete_panel_margins = [189, 441, 190, 283]`,
  `tutorial_complete_panel_margins = [184, 397, 185, 332]`. Also wired:
  `bs_level_card_era2.png`/`bs_level_card_locked_era2.png` into
  `tutorial_button.gd` (previously only `level_button.gd` had this,
  dormant since Campaign Levels 101+ don't exist - Tutorial Select's
  T11-T20 cards are live *today*, so this has immediate, visible effect,
  confirmed via a real render).
- **B (future use, not wired):** `bs_panel_mechanic_notification_era2.png`
  + `bs_icon_mechanic_unlock_era2.png` (no mechanic-first-seen
  notification system exists anywhere in the project - building one is
  new scope, not hardening), `bs_icon_star_era2.png` (no live Era 2 star
  context exists until Campaign Levels 101+ do - Tutorials never show
  stars), `bs_transition_era1_to_era2.png` + `bs_header_era2_
  refractions_portrait.png` (a matched pair - both bake fixed "ERA 2 /
  REFRACTIONS" splash content sized for a dedicated full-screen reveal
  moment, not a drop-in for the existing small text-banner inside the
  standard Level Complete popup - see Part 5 below), `bs_milestone_
  complete_era2.png` (Part 1, explicitly deferred to Level 200).
- **C (reference only):** `bs_icon_loading_era2.png` (no loading-screen
  system exists in this project at all - every scene transition is
  instant), `bs_tutorial_highlight_frame_era2.png` (a 1024x1536
  full-panel image - structurally cannot serve as `TutorialHighlight`'s
  per-cell scalable procedural ring without contradicting `TUTORIAL_
  SYSTEM.md` section 12's own architecture), `bs_panel_level_complete_
  era2.png` (bakes fixed fake stats - "TIME 00:42", "MOVES 12",
  "CRYSTALS 3/3" - and a wrong button set including a "REPLAY" this
  project doesn't have; a concept/mood-board image, not usable data -
  don't confuse with the "_clean" variant above), `bs_tutorial_
  complete_era2.png` (a full-bleed illustrative splash with no frame/
  margin structure, not 9-slice-able - don't confuse with the "panel_"
  variant above).

**Two real rendering bugs found by RENDERED verification (not assumed
correct from wiring alone), both now fixed:**
1. `TutorialCompletePopup.set_era_panel()`'s first draft explicitly set
   `content_margin_left/top/right/bottom` to the *old* flat style's
   small values (48/40/48/40). `StyleBoxTexture.content_margin_*`
   defaults to `-1` ("same as the matching `texture_margin_*`") for
   exactly this reason - explicitly overriding it to a much smaller
   value placed the buttons/title well inside the new frame's large
   top/bottom crystal ornaments, visibly overlapping them. Fixed by
   removing the override entirely (matching `LevelCompletePopup`, which
   never set it and rendered correctly from the start).
2. The *height* of `TutorialCompletePopup`'s content (title + up to 3
   buttons) is naturally shorter than an Era 2 frame's own combined
   top+bottom texture margins (397+332=729px) - `PanelContainer` sizes
   to content, so the frame's fixed corner art was squeezed smaller than
   its own design, distorting the ornaments. Fixed by forcing
   `custom_minimum_size.y` to at least `margin_top + margin_bottom + 40`
   whenever an era panel with real margins is applied, restoring the
   popup's original size on revert (`LevelCompletePopup` got the same
   defensive fix, though its own content was already tall enough not to
   need it).
3. (Found via isolated render, not from the T11-T20 flow) `level_button.
   gd`'s existing (D77, dormant) Era 2 card wiring and this pass's new
   `tutorial_button.gd` wiring both used `TextureRect.STRETCH_KEEP_
   ASPECT_CENTERED` (mode 5), inherited from the old near-square button
   art (512x540). The new era2 card art is 1024x1536 (a much taller
   aspect) - centered-fit let it render narrower and taller than the
   button box, misaligned against sibling cards. Fixed by switching both
   `level_button.tscn` and `tutorial_button.tscn`'s `Background`
   `TextureRect` to `STRETCH_KEEP_ASPECT_COVERED` (mode 6) with
   `clip_contents = true`, confirmed via a real render showing all three
   card states aligned and uncropped-looking.

**Part 5 - Level 100 -> Era 2 transition.** Reviewed against the two
concept images. Kept the existing small in-popup text banner
(`%EraTransitionLabel`, D77) rather than swapping in `bs_transition_
era1_to_era2.png`/`bs_header_era2_refractions_portrait.png` - both are
full-bleed, no-alpha, fixed-text splash art sized for a dedicated
"reveal" screen, and `ERA_2_DESIGN.md` section 9 already deliberately
chose "no new transition screen scene" to keep this moment simple. Re-
verified the existing logic directly against real `SaveManager` calls
(not just read): the `era_transition` condition is `true` exactly once
(before `record_campaign_level_result()` marks Level 100 done) and
`false` immediately after (confirmed on a real, backed-up-and-restored
save file) - a replay can never re-show the banner, and the QA-unlock
override never touches `SaveManager` state, so it cannot corrupt
progression.

**Part 7/8 - resolution matrix and color readability.** Real GPU
renders (`--rendering-driver d3d12`, no `--headless`) at 720x1280,
1080x1920, and 1080x2400 via `DisplayServer.window_set_size()` (not a
CLI flag - confirmed unreliable in this dev environment, `TUTORIAL_
SYSTEM.md` section 12's own note) of T11/T15/T17/T20 and Tutorial
Select: zero HUD clipping at any resolution, `get_viewport().
get_visible_rect().size` behaves exactly as `CLAUDE.md` 12b describes
(stays at the 1080x1920 reference for the two narrower/same-aspect
requests, grows to 1080x2400 logical for the taller one - confirmed by
printing it directly, not assumed). Touch-target size is governed by
this *logical* canvas, which is identical between 720x1280 and
1080x1920 requests, so T20's 9x9 board is not meaningfully smaller on a
narrow phone than on a reference one. Color readability: pixel-sampled
(not eyeballed) the brightest on-screen RED beam pixel against the
brightest on-screen UI magenta/violet pixel in a real T20 render -
`Color(1.0, 0.298, 0.298)` (hue 0 deg) vs `Color(0.855, 0.028, 0.992)`
(hue ~291 deg), a 68.5 deg hue separation - no UI/scrim/glow change was
needed or made; `GridTypes.beam_color_to_render_color()` (gameplay
color semantics) was not touched, per the brief's own instruction.

**Part 9 - APK size audit and optimization.** Two distinct findings:
1. **The real optimization**: `bs_grid_surface_era2.png` (explicitly
   documented in `ERA_2_DESIGN.md` as never-used reference art) and all
   8 files under `assets/gameplay/fx/era2/` (confirmed by grep: `Era2
   ActivationFX` is fully procedural `_draw()`, exactly like
   `LaserMirrorImpactFX` - zero `preload()`/`load()` of any fx/era2 PNG
   anywhere in `scripts/`) were being shipped despite being completely
   unreferenced by any script. Combined with the 9 UI assets classified
   B/C above (excluding `bs_milestone_complete_era2.png`, which Part 1
   requires stay included, and excluding the two now-wired panel/card
   assets), added to `export_presets.cfg`'s `exclude_filter`. **All
   textures kept using `compress/mode=0` (Lossless)** - this project's
   UI/gameplay art has fine detail and (for some assets) baked text, and
   VRAM compression (ETC2/ASTC) would introduce visible banding; the
   size problem here was genuinely-unused source files, not the wrong
   compression mode for files that are actually used.
2. **A self-inflicted near-miss, corrected before it shipped**: this
   pass's own temporary QA driver scripts and screenshot PNGs (~40
   files, ~120 MB) were left in the project root between test runs
   instead of the environment's scratchpad directory, and a first,
   premature APK export (before cleanup) picked all of them up via the
   `all_resources` export filter, growing the APK instead of shrinking
   it (117.6 MB, larger than the 111.09 MB baseline). Caught immediately
   by inspecting the exported APK's own zip listing (`unzip -l`) rather
   than trusting the byte count alone - a good general lesson: **a
   changed APK size number is not proof of what changed; list the
   archive contents.** All temporary files were deleted and the APK
   re-exported clean. Also discovered while diagnosing this:
   `--export-pack` alone did **not** appear to honor `export_presets.
   cfg`'s `exclude_filter` in this environment/version (a real, already-
   excluded pre-existing pattern like `assets/gameplay/pieces/**` still
   showed as present when checked via `--main-pack` against a
   `--export-pack`-produced `.pck`) - **the reliable verification
   technique is a real `--export-debug` (or `--export-release`) export
   followed by `unzip -l` / `aapt2 dump badging` against the actual
   `.apk`**, not `--export-pack` + `--main-pack`. Update any future
   check script accordingly; don't re-trust `--export-pack` for filter
   verification without re-confirming this each time, since it may be
   version-specific.

**APK result**: `versionCode=36`, `versionName=
"3.0.1-ERA2-FOUNDATION-FIX-QA"`, package `com.beamshift.game`.
**83,384,755 bytes**, down from the `versionCode=35` baseline's
111,090,272 bytes - a **27,705,517 byte (≈24.9%) reduction**, entirely
from excluding genuinely-unreferenced source art, zero quality loss to
anything actually rendered. Confirmed via `aapt2 dump badging` and a
direct zip-listing check of both "should be present" (18 paths,
including every currently-wired Era 2 asset and the milestone asset)
and "should be excluded" (18 paths) - all passed against the real APK.

**Part 10 - regression.** Full solver/validator regression re-run after
every code change in this pass (not just once at the end): 15/15 dev,
100/100 campaign, 13/13 Era 2 fixtures, 20/20 T01-T20 tutorial boards
solvable (the same 6 pre-existing T02/T04/T07/T10/T14/T20 `optimal_
moves`-metadata-vs-solver mismatches as always - see the note below;
none of these represent an unsolvable board). 10/10 T11-T20 guided
step-machine PASS (Part 2/3 above).

**Not done this pass, and worth recording as a known gap rather than
silently skipping:** T12-T14, T16, T18, T19 were exercised by the
guided step-machine driver (proving each is genuinely solvable through
the real engine) but were **not** individually RENDERED/visually
inspected - only T11/T15/T17/T20 were, matching the brief's own "at
minimum render" list. If a future pass needs to visually confirm Prism
colored-input routing (T13/T14) or the Receiver->Remote Emitter->Switch/
Gate chain's on-screen appearance (T19) specifically, render those
directly rather than assuming the T11/T15/T17/T20 sample generalizes.

**QA unlock flags**: both `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` and
`UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` remain `true`, per the brief's
own STOP CONDITION ("do not disable QA unlock"). **MUST be set to
`false` before any final production release** - unchanged standing
rule.

**Files changed this pass**: `scripts/resources/era_theme.gd` (4 new
panel fields), `scripts/ui/level_complete_popup.gd`/`tutorial_complete_
popup.gd` (`set_era_panel()`), `scenes/ui/level_complete_popup.tscn`/
`tutorial_complete_popup.tscn` (`Panel` marked `unique_name_in_owner`),
`scripts/ui/tutorial_button.gd` + `scenes/ui/tutorial_button.tscn`
(Era 2 card wiring + stretch-mode fix), `scenes/ui/level_button.tscn`
(stretch-mode fix only, no script logic change), `scripts/gameplay/
game.gd` (`_apply_era_theme()` now also themes both completion popups),
`export_presets.cfg` (`exclude_filter` additions, `version/code`=36,
`version/name`). **Not changed**: `LaserSystem`, `GridTypes`,
`LevelSolver`, `LevelValidator`, any campaign/dev/tutorial level file,
any gameplay tile script. **`bs_milestone_complete_era2.png` is new and
tracked**; no other asset files were added, moved, or deleted.

**NOT MANUALLY APPROVED - Android device QA pending**, same standing
state as every build. **Do not create Campaign Levels 101+, T21+, or
Era 3, do not disable QA unlock, do not make a production release**
without being explicitly asked - this pass's own completion is not
authorization to continue past its STOP CONDITION.

## D79 — Tutorial Select T11-T20 button shape regression: root cause and fix

**Problem** (user's own Android device report): T01-T10 render as the
established compact square/rounded button; T11-T20 render as tall
rectangular "poster" cards, breaking the shared UI family.

**Root cause, confirmed independently two ways** (a research subagent's
source-level trace, and this session's own `Add-Type -AssemblyName
System.Drawing` pixel-dimension check of the actual PNGs — both landed
on the identical answer): `tutorial_button.gd`'s D78-era Era 2 wiring
swapped `_background.texture` to `bs_level_card_era2.png`/
`bs_level_card_locked_era2.png` for `EraTheme.get_era_for_tutorial(id)
>= 2`. Those files are **1024x1536px** (a 2:3 poster/panel asset). The
button `Control` itself never changed size (`custom_minimum_size =
Vector2(240, 253)`, `size_flags = SHRINK_CENTER` — confirmed byte-
identical between `tutorial_button.tscn` and `level_button.tscn`) — the
`TextureRect` uses `STRETCH_KEEP_ASPECT_COVERED` + `clip_contents=true`
(itself a prior D78 fix for a different symptom), which scales the tall
source image up until it *covers* the 240x253 box, then crops ~228px off
top and bottom. The card frame's rounded corners/border live near the
top and bottom of that 1536px-tall image, so the crop removes exactly
the framing that makes it read as a compact button, leaving a
straight-edged vertical mid-strip — a truncated poster, not a broken
Control. T01-T10's own art (`bs_ui_level_button_*_runtime.png`) is
512x540px (aspect 0.948, essentially square) — proportioned for this
box already, which is why only the Era 2 branch showed the bug.

**Fix** (matches the brief's own preferred Option A): stop swapping
texture for Era 2 entirely. `tutorial_button.gd`/`level_button.gd` now
always pick from the same three Era-1 textures (locked/completed/
unlocked) regardless of era, then apply `_background.modulate =
EraTheme.for_era(era).accent_color` — violet `Color(0.55, 0.3, 0.95)`
for Era 2, `Color.WHITE` (a no-op) for Era 1. This guarantees pixel-
identical shape by construction; Era identity is color only, exactly as
the brief specified. `level_button.gd` got the identical fix pre-
emptively (it had the same dormant texture-swap wiring, not yet visibly
broken only because Campaign Levels 101+ didn't exist until this same
session's Part B). The now-fully-unreferenced `bs_level_card_era2.png`/
`bs_level_card_locked_era2.png` were added to `export_presets.cfg`'s
`exclude_filter` (same treatment D78 gave other genuinely-unreferenced
Era 2 assets) rather than deleted from disk.

**Verified via a real non-headless render** (`godot --path .` at
1080x1920, main-scene-swap technique, D45-D47): T11-T18 (as far as the
unscrolled Tutorial Select view shows) render as the identical compact
square frame T01-T10 use, tinted violet, labels legible, no cropping.

**Files changed**: `scripts/ui/tutorial_button.gd`, `scripts/ui/
level_button.gd`, `export_presets.cfg` (`exclude_filter` addition).
**Not changed**: `scenes/ui/tutorial_button.tscn`, `scenes/ui/
level_button.tscn` (neither needed any layout change — confirming the
bug was in the swapped asset, not the Control tree), `era_theme.gd`
(its `accent_color` field already existed and already had the right
value; it just wasn't being *used* correctly by these two scripts).

## D80 — Era 2 Levels 101-110: the first Era 2 campaign content

**Scope**: ten new campaign levels (Levels 101-110), the first to use
Prism/One-Way Reflector/Beam Receiver/Remote Emitter in real campaign
content (as opposed to T11-T20's isolated single-mechanic tutorials or
the 13 `editor_fixtures/era2/` regression fixtures). Explicitly
requested by the user, satisfying `CAMPAIGN_DESIGN.md`'s own standing
"don't create Levels 101+ without being explicitly asked" guardrail.

**File layout decision**: stored at `levels/campaign/era2_stage_01/
level_01.gd` … `level_10.gd` (local `level_id` 1-10 within the file,
exactly like every existing `stage_NN` folder), registered as 10 new
entries appended to `LevelManager.CAMPAIGN_LEVEL_PATHS` after Level
100's. Named `era2_stage_01` rather than `stage_11` deliberately —
`CAMPAIGN_DESIGN.md` explicitly warns against treating a future 101+
request as "Stage 11 continuing the original plan's numbering" since it
wasn't part of that plan; this folder name makes the distinction
visible on disk while keeping the established one-file-per-level,
`stage`-field-is-organizational-only convention.

**Design approach**: every level was hand-traced cell-by-cell for every
beam branch, including what the WRONG orientation of every rotatable
tile does (never assumed harmless without checking), before being
written — the same discipline this project's Era 1 campaign levels use
(see e.g. D69/D70's circular-dependency near-misses). Level 110 in
particular went through one real design correction during authoring:
its remote emitter's final target was originally going to require
`WHITE` (Era 1's "accepts any beam color" convention), which was only
caught by manually tracing where the RED prism channel's beam ends up
under every rotatable-tile combination — it turned out RED could reach
the exact same final cell via the exact same mirror, and a `WHITE`-
required target would have silently let the Receiver/Remote Emitter
mechanic be entirely bypassed. Fixed by giving the remote emitter its
own explicit `GridTypes.BeamColor.GREEN` (overriding the `make_remote_
emitter()` factory's `WHITE` default) and requiring `GREEN` at that
target — a color only that specific beam can ever produce. Documented
in the level's own `developer_notes` so a future session doesn't need
to re-derive it.

**Validation, all solver-confirmed on the FIRST authoring attempt for
all ten levels** (no rework needed, unlike several Era 1 batches'
documented draft rejections — see D65/D66/D68/D69/D70):

| Level | Name | Grid | Mechanics | Rotatable | Optimal | States | Shortest# |
|---|---|---|---|---|---|---|---|
| 101 | First Refraction | 7x7 | Prism, Mirror | 2 | 2 | 4 | 1 |
| 102 | Spectrum Route | 7x8 | Prism, Filter, Mirror | 2 | 2 | 4 | 1 |
| 103 | Fractured Path | 8x8 | Prism, Splitter, Portal, Mirror | 2 | 2 | 4 | 1 |
| 104 | One Way | 6x9 | One-Way Reflector, Mirror, Blocker | 2 | 2 | 4 | 1 |
| 105 | False Reflection | 7x7 | Prism, One-Way Reflector | 2 | 2 | 4 | 1 |
| 106 | Remote Signal | 5x8 | Receiver, Remote Emitter, Mirror | 2 | 2 | 4 | 1 |
| 107 | Signal Through | 5x10 | Receiver, Remote Emitter, Portal, Filter, Mirror | 1 | 1 | 2 | 1 |
| 108 | Refracted Signal | 7x9 | Prism, Receiver, Remote Emitter, Mirror | 2 | 2 | 4 | 1 |
| 109 | Directional Chain | 7x6 | One-Way Reflector, Receiver, Remote Emitter, Switch, Gate | 1 | 1 | 2 | 1 |
| 110 | Refraction Nexus | 8x10 | Prism, One-Way Reflector, Receiver, Remote Emitter, Mirror, Portal, Filter, Switch, Gate | 3 | 3 | 8 | 1 |

Every level: `LevelValidator` zero errors/zero warnings, `LevelSolver`
status `SOLVABLE` with `shortest_solution_count == 1` (a unique
shortest solution for all ten, exceeding the "preferred" bar), and a
real `GridManager` runtime replay of the solver's own solution path
(via `_on_orientable_tile_clicked()`, the same entry point a player tap
uses) reaching `is_solved == true`. Full regression re-run after adding
these: **15/15 dev, 110/110 campaign (100 unchanged + 10 new), 20/20
tutorial, 13/13 Era 2 fixtures** (12 solvable-by-design + 1 — `fixture_
one_way_reflector_hazard` — deliberately, permanently unsolvable by
design, confirmed still `UNSOLVABLE` exactly as its own header
documents; not a regression) — all solver+runtime-replay PASS.

**`game.gd`'s `era_transition` fix** (see also the `CLAUDE.md` Era 2
rules section entry): before this pass, the Level 100 -> Era 2 banner
fired on `current_level_id == LevelManager.get_campaign_level_count()`
— correct only because Level 100 happened to be both "the Era 1/Era 2
boundary" and "the last implemented level" at the same time. Adding
Levels 101-110 made `get_campaign_level_count()` become 110, which
would have silently moved the banner to Level 110 instead of Level 100.
Fixed to compare `EraTheme.get_era_for_level(current_level_id) <
EraTheme.get_era_for_level(current_level_id + 1)` — pinned to the real
era boundary regardless of how many levels of that era currently exist,
and automatically correct for a future Level 200 -> Era 3 boundary with
no further code change.

**Progression/save verified against the REAL `SaveManager` API** (a
headless main-scene-swap driver, not a hand-inspection of the code): a
fresh save with Levels 1-99 completed shows Level 101 as locked; after
calling `SaveManager.record_campaign_level_result(100, ...)` (the exact
call `game.gd` makes on a real completion, not a faked flag), Level 101
becomes unlocked and `campaign_highest_unlocked_level` advances to 101.
`LevelManager.get_campaign_level(111)` correctly returns `null` with a
graceful `push_warning`, matching the existing Level 101 (post-Level-
100) precedent. `EraTheme.get_era_for_level()` correctly reports 100→
Era 1, 101-110→Era 2. Both QA unlock-all flags left `true` (unchanged).

**RENDERED verification** (real non-headless GPU render, D45-D47
technique, `godot --path .`, main-scene-swap): Levels 101/103/105/108/
110 at 1080x1920, Level 110 additionally at 720x1280 and 1080x2400 —
all clean (correct Era 2 background/HUD/grid theming, full board
utilization, all four Era 2 mechanic types and the Era 1 selections
visually distinct and legible, beams colored correctly, no HUD overlap
or clipping at any tested resolution).

**Files created**: `levels/campaign/era2_stage_01/level_01.gd` through
`level_10.gd`. **Files changed**: `scripts/managers/level_manager.gd`
(`CAMPAIGN_LEVEL_PATHS` +10 entries), `scripts/gameplay/game.gd`
(`era_transition` fix, see above). **Not changed**: `LaserSystem`,
`GridTypes`, `LevelSolver`, `LevelValidator`, any Era 1 or T11-T20
level file, `SaveManager` (no new fields/version bump needed — its
campaign dictionaries were already generic over level count).

**NOT MANUALLY APPROVED — Android device QA pending**, same standing
state as every build; this is the user's first chance to actually play
real Era 2 gameplay, which is this pass's whole purpose. **Do not
create Campaign Levels 111+, T21+, or Era 3, do not disable QA unlock,
do not make a production release** without being explicitly asked —
per this pass's own STOP CONDITION.

## D81 — Era 2 Levels 111-120: deepening the existing systems, and three real shortcut bugs caught by the solver

**Scope**: ten more campaign levels (Levels 111-120), explicitly
requested by the user before manual Android QA of Levels 101-110 was
even finished — authorized as a deliberate exception to the usual
"wait for feedback" cadence. No new mechanics; the brief was explicit
that this batch deepens Prism/One-Way Reflector/Beam Receiver/Remote
Emitter through dependency depth, shared resources, and misleading
local reasoning rather than new tile types or brute-force state count.
Registered as 10 more entries in `LevelManager.CAMPAIGN_LEVEL_PATHS`,
same `levels/campaign/era2_stage_01/` folder, continuing local
`level_id` 11-20. `get_campaign_level_count()` is now 120.

**Design table** (all solver-confirmed on the FIRST validator pass —
zero errors on any of the ten — though three needed a second design
pass after the solver caught real shortcuts, see below):

| Level | Name | Grid | Mechanics | Rotatable | Optimal | States | Shortest# |
|---|---|---|---|---|---|---|---|
| 111 | Split Decision | 7x8 | Prism, Splitter, Mirror | 3 | 3 | 8 | 1 |
| 112 | Cross Signal | 6x8 | One-Way Reflector (shared), Receiver, Remote Emitter, Mirror | 3 | 3 | 8 | 1 |
| 113 | Spectral Gate | 8x8 | Prism, Filter, Switch, Gate, Mirror | 3 | 3 | 8 | 1 |
| 114 | Remote Loop | 7x10 | Receiver, Remote Emitter (x2, chained), Portal, Mirror | 3 | 3 | 8 | 1 |
| 115 | Directional Prism | 7x8 | Prism, One-Way Reflector (x3), Mirror | 5 | 5 | 32 | 1 |
| 116 | False Activation | 7x8 | Receiver, Remote Emitter, Switch, Gate, Mirror | 2 | 2 | 4 | 1 |
| 117 | Split Spectrum | 8x9 | Prism, Splitter, Filter, Portal, Mirror | 3 | 3 | 8 | 1 |
| 118 | Remote Crossing | 9x10 | Receiver (x2), Remote Emitter (x2, shared gate), Switch, Gate, Mirror | 4 | 4 | 16 | 1 |
| 119 | Refraction Relay | 9x9 | Prism, Receiver, Remote Emitter, Portal, Switch, Gate, Mirror | 4 | 4 | 16 | 1 |
| 120 | Era 2 Circuit | 9x11 | Prism, One-Way Reflector (x2), Receiver, Remote Emitter, Mirror, Switch, Gate | 7 | 7 | 128 | 1 |

Every level: `LevelValidator` zero errors/zero warnings, `LevelSolver`
status `SOLVABLE` with `shortest_solution_count == 1` for all ten
(after fixes below), and a real `GridManager` runtime replay reaching
`is_solved == true`. States explored stay far below `LevelSolver.
DEFAULT_MAX_STATES` (65536) — Level 120's 128 states is the block's
peak, nowhere near the ceiling, per the brief's explicit "don't chase
huge state counts" instruction.

**Three real shortcuts found by the solver and fixed** — all three were
the identical failure mode (a beam continuing PAST its own activated
target, since targets never stop a beam, and reaching a second
mechanic it was never meant to touch) at three different scales:

1. **Level 112**: `target(5,5)` and the original `target(5,7)` sat in
   the same column. Beam B's own path satisfied its own target then
   kept going straight down the same column into the second target,
   making beam A's entire receiver-tail mirror irrelevant (solver found
   a 2-move solution instead of the intended 3). Fixed by moving the
   second target off that column (`target(4,7)`), so no single beam's
   straight continuation can ever reach both.
2. **Level 118**: `beam_receiver(3,7)` (receiver B) sat in the same
   column as Emitter A's own straight-down path after its own mirror.
   Emitter A's beam powered BOTH receivers by accident, making Emitter
   B's mirror irrelevant (solver found a 3-move solution instead of 4).
   Fixed by moving Emitter B's whole approach (mirror + receiver) to a
   different column (5, not 3) that Emitter A's beam never travels
   through.
3. **Level 120**: GREEN's beam, after activating its own `target(7,9)`,
   continued rightward into a One-Way Reflector one cell away at
   `(8,9)` — entering RIGHT, which is *always* reflective regardless of
   orientation — and got bent down into the Remote Emitter's own target,
   bypassing the Receiver/BLUE/Remote Emitter chain entirely. **This
   one took two attempts**: the first fix only changed the reflector's
   *default* orientation to the one that happened to send the stray
   beam somewhere harmless — but the solver then found an *alternate*
   6-move solution that deliberately mis-set that same reflector back to
   re-open the identical shortcut, tying the intended solution's move
   count (`shortest_solution_count` came back `2`, not `1`). The real
   fix was structural: relocate the reflector to row 4 (from row 9), so
   *no* orientation of it is ever reachable by GREEN's beam at all — not
   a default-value trick. Confirmed via an exhaustive brute-force replay
   of every 6-move rotation combination (`LaserSystem.simulate_until_
   stable()` called directly, bypassing the solver's own pruning) before
   and after, landing on exactly one 7-move solution afterward. See the
   level's own `developer_notes` for the full blow-by-blow — deliberately
   kept as a worked example for a future session, since this is exactly
   the class of bug `CAMPAIGN_DESIGN.md`'s own design-template notes
   warn about but hadn't previously shown a two-attempt case.

**No accidental full-color-bypass repeats**: Level 120 (like Level 110
before it) gives its Remote Emitter an explicit `GridTypes.BeamColor.
GREEN` rather than the `make_remote_emitter()` factory's `WHITE`
default, specifically because a `WHITE`-required target accepts any
beam color and would have let BLUE's own channel satisfy it without
ever powering the Receiver — checked directly this time during first
authoring, not found after the fact.

**Full regression after adding**: 15/15 dev, 120/120 campaign (100
Era 1 + 20 Era 2 unchanged + 10 new), 20/20 tutorial, 13/13 Era 2
fixtures (12 solvable-by-design + 1 deliberately-unsolvable-by-design,
unchanged) — all solver+runtime-replay PASS. T11-T20 guided step-
machine not re-run — nothing touching `TutorialManager`/tutorial data
was modified this pass. Progression verified against the real
`SaveManager` API across the full 110->111->...->120 walk (not just the
100->101 boundary checked last pass): each level's completion correctly
unlocks the next, `campaign_highest_unlocked_level` reaches 120,
`get_campaign_level(121)` returns `null` with a graceful warning, and
`EraTheme.get_era_for_level()` correctly reports Era 2 for all of
111-120 (no era-boundary logic changes needed this pass, since 120 is
still short of the 100-201 Era 2 range's own 200 boundary).

**RENDERED verification**: Levels 111/114/115/118/120 at 1080x1920,
Levels 111 and 120 additionally at 720x1280 and 1080x2400 — all clean,
correct Era 2 theming, full board utilization, all mechanic states
(including a Remote Emitter correctly shown INACTIVE at Level 120's
first frame, since — unlike Level 110 — its Receiver genuinely isn't
powered in the authored state until the player acts) rendering
correctly, no HUD overlap or clipping at any tested resolution.

**Files created**: `levels/campaign/era2_stage_01/level_11.gd` through
`level_20.gd`. **Files changed**: `scripts/managers/level_manager.gd`
(`CAMPAIGN_LEVEL_PATHS` +10 entries). **Not changed this pass**:
`scripts/gameplay/game.gd` (the `era_transition` fix from the previous
pass already generalizes correctly, no further change needed),
`LaserSystem`, `GridTypes`, `LevelSolver`, `LevelValidator`,
`SaveManager`, any Era 1, T11-T20, or Levels 101-110 file.

**NOT MANUALLY APPROVED — Android device QA pending**, same standing
state as every build; Levels 101-110 themselves are also still awaiting
the user's own manual playthrough. **Do not create Campaign Levels
121+, T21+, Era 3, or new Era 2 mechanics, do not disable QA unlock, do
not make a production release** without being explicitly asked — per
this pass's own STOP CONDITION.

## D82 — Era 2 Levels 121-130: whole-board reasoning, and two more shortcut bugs from the same failure family

**Scope**: ten more campaign levels (121-130), user-requested "deep
dependency pass" explicitly authorized before Levels 101-110 or 111-120
had received any manual Android QA. No new mechanics. Brief's stated
goal: move beyond single-chain dependency (111-120) into levels
requiring genuinely whole-board reasoning - multiple interacting
dependency structures, shared resources spanning distant regions,
backward reasoning from a target's color/state, and deliberate
near-solution traps. `levels/campaign/era2_stage_01/level_21.gd`
through `level_30.gd`, `get_campaign_level_count()` is now 130.

**Design table**:

| Level | Name | Grid | Rotatable | Optimal | States | Shortest# | Dependency types |
|---|---|---|---|---|---|---|---|
| 121 | Shared Spectrum | 8x8 | 5 | 5 | 32 | 1 | shared OWR (2 Prism colors) |
| 122 | Remote Pair | 8x9 | 4 | 4 | 16 | 1 | reciprocal relay (A powers B, B opens A's gate) |
| 123 | Prism Relay | 9x10 | 3 | 3 | 8 | 1 | receiver + filter + portal, all independently required |
| 124 | Directional Cross | 10x8 | 4 | 4 | 16 | 1 | shared OWR (2 emitters) + cross-region gate |
| 125 | False Spectrum | 9x9 | 4 | 4 | 16 | 1 | near-solution trap + target continuation (checkpoint) |
| 126 | Signal Cascade | 9x11 | 2 | 2 | 4 | 1 | 6-hop activation cascade |
| 127 | Fractured Circuit | 10x10 | 4 | 4 | 16 | 1 | portal + shared OWR, 3 spatial regions |
| 128 | Reciprocal Signal | 9x10 | 4 | 4 | 16 | 1 | shared gate + OWR pass-through |
| 129 | Spectral Network | 9x11 | 5 | 5 | 32 | 1 | 5 mechanic families, cross-color gate, isolated remote chain |
| 130 | Convergence Matrix | 9x11 | 7 | 7 | 128 | 1 | 4-way convergence (2 gates on one target) |

Every level: `LevelValidator` zero errors/warnings, `LevelSolver`
status `SOLVABLE` with `shortest_solution_count == 1`, real
`GridManager` runtime replay reaching `is_solved == true`. States
explored (4-128) stay far below `LevelSolver.DEFAULT_MAX_STATES`
(65536) - Level 130's 128 is the block's peak, same as Level 120's,
confirming difficulty came from dependency structure, not search space.

**Two more shortcuts caught by the solver during authoring, both
variations on the D81 "beam continues past its own target" family, plus
a new failure mode**:

1. **Level 123**: a simple grid-bounds error (a Portal and Remote
   Emitter placed at `y=9` in a `grid_height=9` board, i.e. one row
   outside the valid 0-8 range) - `LevelValidator` caught this
   immediately and explicitly (`"outside the Nx N grid"`), not a
   solver-found shortcut. Fixed by growing the board to
   `grid_height=10`. Worth recording as its own category: not every
   authoring mistake is a shortcut: some are just bounds errors, and
   the validator's own explicit position-bounds check is what's
   supposed to catch them, confirmed working as designed.
2. **Level 127** (\"Fractured Circuit\"): a genuinely new failure shape,
   not beam-continuation this time. A rotatable mirror's own WRONG
   orientation sent a beam down a path that happened to physically
   reach a SECOND mirror belonging to a completely different, unrelated
   part of the level's intended route - and that second mirror's own
   default orientation happened to correctly redirect the stray beam
   into the shared One-Way Reflector anyway, completely bypassing the
   Portal the level was built around (solver found a 2-move solution
   instead of the intended 4). The fix was a `BLOCKER` placed between
   the two mirrors, positioned so it only ever intercepts the stray
   wrong-direction beam and never the real portal-exit beam (which
   approaches the second mirror from the opposite side and never
   crosses the blocker's cell). **New lesson for this project's design
   discipline, alongside D81's**: it is not enough to trace where a
   WRONG rotation sends a beam in isolation - if that path physically
   crosses ANY other rotatable or fixed tile anywhere on the board,
   that tile's own current orientation must also be checked for
   whether it accidentally completes a shortcut. A hand-trace that
   stops at \"exits harmlessly\" without checking whether \"harmlessly\"
   actually means \"into open space\" or \"into another mechanic\" is
   incomplete.

**Notable per-level design choices**: Level 125's RED channel
demonstrates genuine target continuation cleanly and safely (one beam,
recolored twice by two filters in sequence, satisfying two required
targets via continuation, entirely within a single straight line - no
cross-branch risk). Level 125's GREEN channel is the block's deliberate
near-solution trap: a mirror's tempting default orientation reaches a
real, color-matching, but `is_required=false` decoy target, while the
correct orientation routes through a Portal to the actual required
target, whose color can only be determined by reasoning backward from
what a downstream Filter produces - not by matching the Prism channel's
own starting color. Level 130's GREEN target requires FOUR
independently-resolved prerequisites (RED's reflector, BLUE's chain
powering a Receiver, the Remote Emitter's own reflector pass-through,
and two of GREEN's own mirrors) via two gates in immediate sequence on
one path - the deepest convergence this project has built.

**Full regression after adding**: 15/15 dev, 130/130 campaign (120
unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures (12
solvable-by-design + 1 deliberately-unsolvable-by-design, unchanged) -
all solver+runtime-replay PASS. Progression verified against the real
`SaveManager` API across the full 120->121->...->130 walk.

**RENDERED verification**: Levels 121/124/125/128/129/130 at 1080x1920,
Level 130 additionally at 720x1280 and 1080x2400 - all clean, correct
Era 2 theming, full board utilization, all mechanic states rendering
correctly (gates, switches, receiver, inactive remote emitter, OWR
chevron indicators all legible), no HUD overlap or clipping.

**Files created**: `levels/campaign/era2_stage_01/level_21.gd` through
`level_30.gd`. **Files changed**: `scripts/managers/level_manager.gd`
(`CAMPAIGN_LEVEL_PATHS` +10 entries). **Not changed**: `game.gd`'s
`era_transition` logic (already generalized correctly in D80, still
correct), `LaserSystem`, `GridTypes`, `LevelSolver`, `LevelValidator`,
`SaveManager`, any Era 1, T11-T20, or Levels 101-120 file.

**NOT MANUALLY APPROVED — Android device QA pending** for this build
AND for both prior Era 2 level batches (101-110, 111-120) - none have
received real-device feedback yet. **Do not create Campaign Levels
131+, T21+, Era 3, or new Era 2 mechanics, do not disable QA unlock, do
not make a production release** without being explicitly asked — per
this pass's own STOP CONDITION.

## D83 — Era 2 Levels 131-140: advanced convergence, and the most shortcut-prone batch yet

**Scope**: ten more campaign levels (131-140), user-requested "advanced
convergence" pass, explicitly authorized to proceed before ANY of the
three prior Era 2 level batches (101-110, 111-120, 121-130) had
received manual Android QA - by this point, four consecutive Era 2
campaign batches await real-device review together. No new mechanics.
`levels/campaign/era2_stage_01/level_31.gd` through `level_40.gd`,
`get_campaign_level_count()` is now 140.

**Design table**:

| Level | Name | Grid | Rotatable | Optimal | States | Shortest# |
|---|---|---|---|---|---|---|
| 131 | Double Bind | 9x9 | 6 | 6 | 64 | 1 |
| 132 | Relay Exchange | 8x9 | 4 | 4 | 16 | 1 |
| 133 | Spectral Lock | 8x9 | 3 | 3 | 8 | 1 |
| 134 | Cross Current | 10x8 | 5 | 5 | 32 | 1 |
| 135 | Delayed Spectrum | 9x9 | 3 | 3 | 8 | 1 |
| 136 | Portal Relay | 7x10 | 5 | 5 | 32 | 1 |
| 137 | Three-Way Refraction | 8x10 | 4 | 4 | 16 | 1 |
| 138 | Reciprocal Gates | 9x10 | 2 | 2 | 4 | 1 |
| 139 | Fractured Network | 9x11 | 6 | 6 | 64 | 1 |
| 140 | Refraction Engine | 9x11 | 8 | 8 | 256 | 1 |

Every level: `LevelValidator` zero errors/warnings, `LevelSolver`
`SOLVABLE` with `shortest_solution_count == 1`, real `GridManager`
runtime replay reaching `is_solved == true`, after the fixes below.
States explored (4-256) stay far below `LevelSolver.DEFAULT_MAX_STATES`
(65536).

**This was the most shortcut-prone batch of the four Era 2 level
passes: 5 of the 10 levels needed a fix during authoring** (versus 3/10
for D81's pass and 2/10 for D82's), directly reflecting the higher
structural complexity this pass's brief asked for (two-reflector
chains, reciprocal relays, multi-color-scoped continuations). Every
issue was still caught by the SAME two techniques already established
(`LevelValidator`'s bounds check, `LevelSolver`'s shortest-solution-
count check) - no new validation technique was needed, only more
disciplined use of the existing ones:

1. **Level 133 (UNSOLVABLE, a genuine authoring error, not a
   shortcut)**: a second mirror was inserted directly into a beam's
   already-complete straight path to artificially raise the rotatable
   count. A mirror always bends - it cannot let a beam 'continue
   straight' - so the second mirror made the intended target
   permanently unreachable under any orientation. Fixed by removing it
   rather than reworking the geometry around it. **New general
   principle**: never add a rotatable tile purely to inflate a count:
   every insertion must be checked against where the beam was ALREADY
   going, not just what orientation would be 'correct' for it in
   isolation.
3. **Level 134**: a shared One-Way Reflector's two 'wrong' and
   'correct' consequences swapped which of two beams reached which of
   two targets - since both beams and both targets used the
   `make_remote_emitter()`/`make_target()` default `WHITE`, the swap
   was invisible to the win condition (either beam arriving at either
   target satisfied it). Fixed by giving the Remote Emitter an explicit
   non-`WHITE` color and requiring that same color at its own target -
   the identical fix shape D81/D82 already established for the
   'beam-continues-into-a-WHITE-target' bug, now shown to also apply to
   a 'swapped-routing' variant of the same underlying issue (a
   `WHITE`-required target's 'accepts anything' semantics silently
   erasing a distinction the puzzle depends on).
4. **Level 137**: the exact `WHITE`-required-target-bypass shape itself
   - a beam's own continuation past its own required target reached an
   adjacent target requiring the `make_target()` default `WHITE`,
   which accepts any color, letting it satisfy that target for free
   regardless of whether the Remote Emitter chain feeding it ever
   fired. Same fix as always: explicit non-`WHITE` Remote Emitter
   color plus a matching non-`WHITE` target requirement.
5. **Level 138 (the deepest structural bug this project has found to
   date)**: a shared One-Way Reflector's two beams approached from the
   SAME side (one from directly above, one bending to exit directly
   above) rather than genuinely opposite sides - so one beam's
   straight-line approach corridor to the reflector doubled as the
   other beam's exit corridor away from it, and a target meant only
   for the second beam sat directly in the first beam's own path,
   letting it get satisfied with ZERO rotation at all (solver: 2 moves
   instead of the intended 3, and even after a first fix attempt
   swapping which gate belonged to which beam, a SECOND collision of
   the identical shape was found in the same corridor - final fix
   required a full geometric rebuild: Remote A now approaches the
   shared reflector from BELOW (entering UP) while the other emitter
   approaches from the LEFT (entering RIGHT), so their respective
   exits land in genuinely disjoint quadrants around the shared tile
   rather than sharing a column). **General lesson for any future
   'shared reflector between two beams' level**: it is not enough for
   the two beams to enter from different DIRECTIONS - their entire
   corridors (both the approach AND the exit, in both the correct and
   every wrong orientation) must be checked for overlap, since a
   reflector's exit direction for one beam can coincide with another
   beam's own approach direction even when their entry directions
   differ.

**Full regression after fixes**: 15/15 dev, 140/140 campaign (130
unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures (12
solvable-by-design + 1 deliberately-unsolvable-by-design, unchanged) -
all solver+runtime-replay PASS. Progression verified against the real
`SaveManager` API across the full 130->131->...->140 walk.

**RENDERED verification**: Levels 131/133/135/138/139/140 at
1080x1920, Level 140 additionally at 720x1280 and 1080x2400 - all
clean, correct Era 2 theming, full board utilization, all four
subsystems' mechanic states rendering correctly (both portal instances
of the shared pair labeled consistently, gates/switches/receivers/
inactive-remote-emitters/reflector-chevron-indicators all legible), no
HUD overlap or clipping.

**Files created**: `levels/campaign/era2_stage_01/level_31.gd` through
`level_40.gd`. **Files changed**: `scripts/managers/level_manager.gd`
(`CAMPAIGN_LEVEL_PATHS` +10 entries). **Not changed**: `LaserSystem`,
`GridTypes`, `LevelSolver`, `LevelValidator`, `SaveManager`, `game.gd`,
any Era 1, T11-T20, or Levels 101-130 file.

**NOT MANUALLY APPROVED — Android device QA pending.** Per the user's
own explicit instruction accompanying this pass: **after Level 140, a
manual Android review checkpoint is recommended before continuing
further** - Levels 101-140 now constitute FOUR unreviewed Era 2
campaign batches (40 levels) with zero real-device feedback on any of
them, the largest unreviewed backlog this project has carried at once.
**Do not create Campaign Levels 141+, T21+, Era 3, or new Era 2
mechanics, do not disable QA unlock, do not make a production
release** without being explicitly asked — per this pass's own STOP
CONDITION.

## D84 — Phase 1: Shared Adaptive Gameplay Layout Foundation (`versionCode=41`, `3.5.0-ADAPTIVE-LAYOUT-QA`): confirms an already-shared architecture, adds the future-procedural contract, zero level/gameplay changes

**New product direction, recorded here permanently**: BeamShift's long-term
progression target is now **2,000 procedural levels** (deterministic-seed
generated, direct PLAY/CONTINUE flow, no player-facing Level Select) —
see `ROADMAP.md` for the full framing. **The procedural generator itself
is explicitly NOT built in this pass** - this pass only hardens the
gameplay-layout contract a future generator will target.

**Investigation finding, load-bearing for this whole pass**: the shared,
centralized layout architecture the new spec asked for **already exists**,
built across two prior passes -  Rectangular Grid Architecture (D72) and
the four-phase Portrait Re-Layout (D73-D76). Confirmed directly by reading
`game.tscn`/`grid_manager.gd`/`safe_area_margin.gd`/`tile_visual.gd`
before writing a single line:
- `game.tscn`'s structure - `SafeAreaMargin` (safe-area + `UIConstants.
  BASELINE_MARGIN=96px` baseline) -> `Layout` `VBoxContainer` (16px
  `separation`) -> `TopBar`/`BottomBar` (`AspectBar`-driven, aspect-ratio-
  locked height from their own HUD art) -> `CenterArea` (expands to fill
  what's left) - is the ONE shared structure every level already uses.
  `BackButton`/`ResetButton`/`PauseButton`/`HintButton` positions are
  anchor-percentages baked into `game.tscn` itself. `LevelData`
  (`scripts/resources/level_data.gd`) has zero HUD/pixel fields - only
  puzzle data (`grid_width`, `grid_height`, `tiles`, etc.). **No level has
  ever owned HUD positioning in this codebase.**
- `grid_manager.gd::_recalculate_layout()` already computes
  `cell_size = floor(min(available_width/columns, available_height/rows))`
  against `CenterArea`'s real rect (inset by `GRID_SAFETY_MARGIN=8px`),
  already centers the board, already keeps cells square via one scalar
  `cell_size`. `get_layout_metrics()`/`format_layout_diagnostics()`
  already existed (D72).
- `TileVisual` (base of `MirrorTile` etc.) is a `Control` sized to the
  FULL cell (`size = Vector2(cell_size, cell_size)`); `_gui_input` fires
  over that whole rect. **Whole-cell tap already worked** - not just the
  drawn mirror glyph.
- `SafeAreaMargin` already reads Android's real display safe-area insets
  (notches/cutouts) via `DisplayServer.get_display_safe_area()`, falling
  back to `BASELINE_MARGIN` on every platform including in-editor.

Given this, the pass scoped itself to exactly the pieces that were
genuinely missing, per the spec's own "important future generator
contract" section, and touched nothing else - **no change to
`GRID_SAFETY_MARGIN`, `BASELINE_MARGIN`, or the `Layout` separation**,
since all three were already tuned and user-approved across D72-D76 and
CLAUDE.md's own rule against rewriting a working system without a
concrete technical reason applies directly here.

**Net-new, all in `scripts/gameplay/grid_manager.gd` (purely additive)**:
- `const MAX_COLUMNS := 8` - a ceiling for future procedurally-generated
  board profiles only. Not retroactively enforced on existing content
  (see column audit below).
- `const MIN_COMFORTABLE_CELL_SIZE := 96.0` (px at the 1080-wide
  reference canvas) - derived from Android Material Design's 48dp
  minimum touch target at this project's ~2x reference-to-dp ratio.
  Deliberately below the campaign's own historical average (122.4px,
  D76) and above the project's known floor case (87px, the densest
  Levels 76-100 boards) - a floor for NEW profiles, not a claim every
  existing level already clears it.
- `static func is_board_profile_comfortable(columns, rows, playable_size)
  -> Dictionary` - pure function (no scene dependency), reuses the exact
  `_recalculate_layout()` cell-size formula, checks both `MAX_COLUMNS`
  and `MIN_COMFORTABLE_CELL_SIZE`, returns `{comfortable, cell_size,
  reason}`. This is the "future generator contract" entry point: a
  generator calls this BEFORE committing to a shape, never derives pixel
  values itself.

**Column audit (report only - zero level files touched)**: grep-audited
every level's `grid_width` across all four populations.

| Population | Total | Exceed MAX_COLUMNS=8 |
|---|---|---|
| Dev/regression (level_01-15) | 15 | 0 |
| Campaign (stage_01-10 + era2_stage_01) | 140 | 54 (concentrated Level 41/stage_05 onward, width trends 5->10 as difficulty escalates; mode=9, 35 levels) |
| Tutorial (T01-T20) | 20 | 1 (T20, width 9) |
| Editor fixtures (main + era2/) | 24 | 3 (`fixture_rect_9x10`, `fixture_one_way_reflector_chain`, `fixture_receiver_portal_splitter` - all deliberately testing the rectangular-grid ceiling) |

All of these are explicitly grandfathered as legacy/regression content
per this pass's own "existing level compatibility" scope - `MAX_COLUMNS`
governs future procedural profiles only, and none of these 58 files were
modified.

**Resolution / board-profile verification (AUTOMATED)**: a throwaway
headless script built the same node structure as `game.tscn` in a bare
`SceneTree` (feasible with zero autoloads, per D6/D7) and drove it at
all 5 required logical resolutions (720x1280, 1080x1920, 1080x2160,
1080x2400, 1080x2560 - the first two share the reference 1080x1920
logical canvas per the `canvas_items`/`expand` stretch mode, D43) against
12 representative procedural-shaped profiles (5-8 columns x 7/9/11 rows).
Result: **136/140 combinations COMFORTABLE**; the only FAILs are 11-row
profiles at 5/6/7/8 columns on the two shortest-height resolutions
(720x1280 and 1080x1920), where cell_size lands at 95px - one pixel
under `MIN_COMFORTABLE_CELL_SIZE`. Every 7-row and 9-row profile is
COMFORTABLE across the entire matrix; width utilization is 82-100% and
height utilization 45-100% depending on row count and device height.
Confirms the existing formula already produces thumb-friendly boards for
the intended `MAX_COLUMNS<=8` procedural range, and gives a concrete
future-generator guideline: **prefer <=9 rows at 5-8 columns** to stay
comfortable on the shortest supported device height.

**Full regression (AUTOMATED)**: runtime-vs-solver replay across every
non-fixture-invalid population, run after the `grid_manager.gd` change -
**188/188 PASS**: 15/15 dev, 140/140 campaign, 20/20 tutorial, 12/12
solvable-by-design Era 2 fixtures + 1/1 confirmed-still-UNSOLVABLE-by-
design (`fixture_one_way_reflector_hazard`). Zero regression from the
purely-additive `grid_manager.gd` change.

**Files changed**: `scripts/gameplay/grid_manager.gd` (additive consts +
static func only), `export_presets.cfg` (versionCode 40->41,
versionName). **Files NOT changed**: `game.tscn`, `game.gd`,
`laser_system.gd`, `grid_types.gd`, any level `.gd` file,
`level_manager.gd`, any `SaveManager` field, `GRID_SAFETY_MARGIN`,
`BASELINE_MARGIN`, `Layout` separation.

**NOT MANUALLY APPROVED - Android device QA pending**, same as every
pass since D80. Per the spec's own STOP CONDITION: **do not start Phase
2 (Direct Play/Continue) or the procedural generator** without being
explicitly asked - this pass stops after the layout foundation,
regression, and QA APK, pending the user's own manual approval on a
real device.

## D85 — Phase 2: Direct Play + Continue Flow (`versionCode=42`, `3.6.0-DIRECT-PLAY-CONTINUE-QA`): normal players never see Level Select, exact mid-level resume added, zero level/puzzle changes

**Requested immediately after Phase 1 (D84), before its own manual Android
QA landed** - same standing pattern as every prior unreviewed-backlog
pass in this project. Goal: replace the normal Campaign -> Level Select
flow with direct PLAY/CONTINUE progression, matching the eventual
2,000-level procedural product (no per-level Level Select at that scale).

**Investigation finding, load-bearing for this pass**: `main_menu.tscn`/
`main_menu.gd` already had `ContinueButton`/`PlayButton`/`TutorialButton`/
`SettingsButton`/`QuitButton` nodes, in exactly the spec's preferred
order, from earlier work. `PlayButton`'s node name was already future-
proofed - but its **text was still "CAMPAIGN"** and its handler still
called `GameManager.go_to_level_select()`. `GameManager.continue_game()`
already existed and already resolved `LevelManager.
get_campaign_continue_level_id()` (first not-yet-completed campaign
level, already capped at the highest unlocked - the Level-140-complete
case was already safe, no Level 141 risk). So "direct entry" and
"current progression" already existed; what was missing was (1) wiring
PLAY to use them instead of Level Select, (2) making Level Select
QA-only, (3) a real "resumable game" signal for CONTINUE that isn't just
unlock-derived (the spec explicitly forbids that shortcut), and (4)
exact mid-level resume (tile orientations + move count), which did not
exist at all - `SaveManager` had no per-move state, only completion
records.

**Exact resume was implemented, not the documented fallback** -
`GridManager.tile_orientations` was already the single source of truth,
paired with each orientable node's own `.orientation` at load time
(`grid_manager.gd`'s `load_level()`); the new `restore_orientations()`
reuses that exact pairing, so there's no risk of the visual/logical-
mismatch bug class D40 documented (CLAUDE.md rule 12c).

**New navigation state - `GameManager.entered_via_level_select: bool`**
(set only by `level_select.gd`'s QA entry point, false for
`play_game()`/`continue_game()`). Answers two questions: (a) does Back/
Pause's "Level Select" button, or Level Complete's own "Level Select"
button, go to Level Select (QA session) or Main Menu (normal session)?
Pause already had a separate, dedicated "MAIN MENU" button distinct from
"LEVEL SELECT" - so a normal session simply **hides** Pause's Level
Select button. Level Complete has no separate Main Menu button - so its
Level Select button is **relabeled** "MAIN MENU" instead. (b) should this
session read/write the new resume-state fields at all? **QA Level Select
sessions never touch resume state at all** - a deliberate, documented
trade-off: a QA tester jumping into an arbitrary level for testing won't
get resume-on-return within that session, but the real player's "current
progression" pointer can never be corrupted by QA testing.

**New save fields** (`SaveManager`, `SAVE_VERSION` 3->4, purely
informational per the existing convention, `.get()` defaults mean no
migration code needed): `campaign_resume_level_id: int = 0` (0 = "no
resumable game yet" - deliberately NOT derived from
`campaign_highest_unlocked_level`, since a fresh save already has that at
1 with zero resumable state), `campaign_resume_orientations: Dictionary`
(String "x,y" -> int orientation, JSON-safe, single slot since only one
campaign level is ever "in progress" at a time), `campaign_resume_move_
count: int = 0`. New functions: `has_resumable_campaign_game()`,
`start_campaign_resume(level_id)` (fresh tracking - used both on
genuinely entering a new level AND on Reset/Retry, so a reset never
"resumes" its own pre-reset state), `update_campaign_resume_state(...)`
(event-driven - called once per accepted move via the existing
`GridManager.move_made` -> `game.gd._on_move_made()` signal, never per
frame), `get_campaign_resume_orientations()`.

**`game.gd._load_current_level()` gained a `force_fresh: bool = false`
param** - Reset/Retry pass `true` (always start over); the initial
`_ready()` call and Next Level pass `false` (try to resume if
`SaveManager.campaign_resume_level_id` matches the level being entered;
Next Level naturally falls through to fresh tracking since the new level
id never matches the just-solved one). A resumed board that happens to
already be solved (e.g. app closed between solving and pressing Next)
**self-heals for free** - `restore_orientations()` calls the same
`_simulate_and_draw()` path a real move uses, so `level_solved` fires
normally and the existing completion flow runs
(`record_campaign_level_result` already tolerates being called again).

**One accepted, documented migration limitation**: an existing save with
real prior progress shows CONTINUE disabled until the player presses
PLAY once after upgrading (which immediately sets `campaign_resume_
level_id` and self-heals permanently). Considered synthesizing this
during load, rejected - it would require duplicating `LevelManager.
get_campaign_continue_level_id()`'s "first incomplete level" search
inside `SaveManager`, which currently has zero autoload dependencies by
deliberate design (D6); this project has been bitten before by exactly
this class of duplicated-logic drift. Confirmed directly against this
dev machine's own real save file (140/140 campaign + 10/10 tutorial
already completed, `campaign_resume_level_id` absent/0 pre-upgrade) -
`has_resumable_campaign_game()` correctly read `false` until a
`start_campaign_resume()` call, exactly as designed, not a bug.

**One additional fix beyond the spec's explicit file list, same root
issue**: `TutorialCompletePopup`'s own "CAMPAIGN" button (shown only on
the final tutorial of a pack, routing to `go_to_level_select()`) had the
identical "stop presenting CAMPAIGN, don't send normal players to
Level Select" problem the Main Menu button had - relabeled "PLAY",
rewired to `GameManager.play_game()`. Internal signal/function names
(`campaign_pressed`, `_on_tutorial_campaign_pressed`) were left
unchanged per the spec's own "don't rename internal systems
unnecessarily" instruction - only user-visible text and behavior
changed.

**Regression (AUTOMATED)**: full runtime-vs-solver replay unchanged at
**188/188 PASS** (15 dev + 140 campaign + 20 tutorial + 13 Era 2
fixtures) - zero level/solver code touched. A dedicated 19-point resume-
flow test (temporary driver, run via the documented `run/main_scene`
swap technique since `SaveManager`/`GameManager`/`LevelManager` need real
autoload initialization, D7) - **19/19 PASS**: fresh-save Continue
disabled, Play-entry sets resume state, move-based persistence round-
trips orientations/move-count correctly, Reset clears to fresh, level
completion advances the resume pointer, Level-140-fully-complete clamps
`get_campaign_continue_level_id()` to 140, and a real `GridManager.
restore_orientations()` call against a real campaign level correctly
updates both `tile_orientations` and the visual node's `.orientation`
together. Test driver files and the temporary `run/main_scene` swap were
deleted/reverted immediately after use, never committed - the dev
machine's own real save file (140/140 campaign progress) was backed up
before testing and restored byte-for-byte after.

**RENDERED verification**: Main Menu at the 720x1280/1080x1920 aspect
ratio and the 1080x2400 aspect ratio (this dev machine's physical screen
height couldn't fit an actual 1920px/2400px-tall window - rendered at an
aspect-ratio-matched smaller physical size instead, e.g. 500x889 for the
9:16 ratio; `canvas_items`/`expand` stretch mode means the LOGICAL canvas
proportions are what matter, confirmed identical either way). Both
renders confirm: CONTINUE/PLAY/TUTORIAL/SETTINGS/QUIT in the correct
order, "PLAY" text (not "CAMPAIGN"), CONTINUE visibly greyed/disabled and
legible, no stray CAMPAIGN button anywhere, the new small QA-only "Level
Select (QA)" button correctly low-prominence at the very bottom, no
overlap or clipping at either aspect ratio.

**Files changed**: `scripts/managers/save_manager.gd` (new fields/
functions, `SAVE_VERSION` bump), `scripts/gameplay/grid_manager.gd`
(`restore_orientations()`, additive), `scripts/managers/game_manager.gd`
(`entered_via_level_select`, `play_game()`, `start_level()`'s new param),
`scripts/ui/level_select.gd` (one call-site change), `scenes/ui/
main_menu.tscn` + `main_menu.gd` (PLAY text/handler, Continue enablement,
new QA button), `scripts/gameplay/game.gd` (resume orchestration, Back/
Level-Select routing), `scripts/ui/level_complete_popup.gd` + `pause_
menu.gd` (new presentational setters), `scenes/ui/tutorial_complete_
popup.tscn` (CAMPAIGN -> PLAY text), `export_presets.cfg` (versionCode
41->42). **Files NOT changed**: any level `.gd` file, `LaserSystem`,
`GridTypes`, `LevelValidator`, `LevelSolver`, Tutorial content/unlock
rules, `tools/level_editor/`, `level_select.tscn` (implementation kept
intact, just no longer linked from the normal player flow).

**QA unlock flags kept `true`** (both `LevelManager.
UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING` and
`UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING`) - the new QA Level Select
button on Main Menu is gated on the former, consistent with the existing
pattern rather than a new flag. **NOT MANUALLY APPROVED - Android device
QA pending**, plus Phase 1's own still-outstanding manual QA. Per the
spec's own STOP CONDITION: **do not implement procedural generation,
create Level 141+, or delete any existing Level Select code/content**
without being explicitly asked.

## D86 — Full-Screen Board Correction (`versionCode=43`, `3.6.1-FULLSCREEN-BOARD-QA`): Phase 1 confirmed the WRONG thing, real device testing caught a real bug, root-caused and fixed

**This corrects a real mistake in Phase 1 (D84).** Phase 1 validated the
rectangular-grid layout formula *headlessly, only at the 1080x1920
reference resolution* and concluded "the architecture is already
correct" without ever rendering a real campaign level and looking at it
at any of the other 4 required resolutions. The user then manually
tested the resulting APK (`versionCode=42`) on a real Android phone and
reported Level 27 rendering with large wasted vertical space, a small
board "floating" mid-screen, and tiles noticeably smaller than they
should be - **a real, correctly-reported regression this project's own
process should have caught**, not a matter of taste. This pass does not
dispute that report; it root-causes and fixes the actual rendered
geometry.

**Root cause, confirmed by rendering the real `game.tscn` with Level 27
loaded (not a synthetic diagnostic) at every required resolution and
reading the actual `Control` rects**: at the 1080x1920 reference,
Level 27 (7x8) genuinely does hit ~94% height utilization, matching
Phase 2B's (D74) original authoring-time claim - Phase 1's headless
math wasn't wrong *at that one resolution*. But `canvas_items`/`expand`
stretch mode reveals strictly MORE logical canvas height on any device
taller than that reference (D43) - and most real Android phones today
are taller than 16:9 (commonly 19.5:9-20:9, e.g. 1080x2400), not the
1080x1920 the reference assumes as a floor. Level 27 is width-bound
(`cell_size = floor(872/7) = 124`, using all of the available width) -
so on a taller device, the board's absolute height stays fixed at
`124*8=992px` while the available `CenterArea` height grows from
~1053px (at 1920) to ~1533px (at 2400), and the leftover space is
distributed as top/bottom gap around the vertically-centered board -
**height utilization silently degrades from 94.2% to 64.7% purely
because of device height, with zero change to the level or the
formula**. Phase 1's own 5-resolution diagnostic actually measured this
exact degradation for *synthetic* profiles (see D84's own "136/140
comfortable" table) but nobody connected that to "therefore a real
campaign level will look emptier on a real phone than the reference
render suggested" - the gap between "the math is internally consistent"
and "a human looking at the real screen approves of it" is exactly what
non-headless rendering closes, and Phase 1 skipped that step for
gameplay (it only rendered Main Menu, never a real level).

**The fix**: `UIConstants.BASELINE_MARGIN` (96px, ~32dp*3, applied
uniformly on all 4 sides by every `SafeAreaMargin` instance, including
`game.tscn`'s) was investigated as instructed and found to be a real,
avoidable contributor - it's a generic "keep everything away from the
edge" choice tuned for menu screens, not remeasured for the board's own
much stricter "small margin" requirement, and on `game.tscn` it directly
becomes the board's own left/right margin (96 + `GRID_SAFETY_MARGIN`'s
8 = 104px/side, ~19% of screen width combined - not "small" by the
spec's own standard). `SafeAreaMargin` gained one new field,
`margin_override: float = -1.0` (-1 = unchanged behavior, every menu
screen's instance is untouched) - `game.tscn`'s instance sets it to
`UIConstants.GAMEPLAY_BASELINE_MARGIN := 32.0` (~11dp*3), a gameplay-
specific smaller baseline. Real Android safe-area insets still widen
whichever baseline is in effect via the existing `maxf()` logic, so HUD
safety near a real notch/cutout is unaffected either way. A candidate
sweep (96/64/48/32/24/16/8px against Level 27 at 1080x2400) showed
strongly diminishing returns below 32px (96→32: cell 124→142, +14.5%;
32→8: cell 142→~148, +~4%) - 32 was chosen as the point past which
further reduction buys little while risking the board/HUD visually
hugging the screen edge with too little breathing room. This is a
single shared constant, read by exactly one scene - not per-level, not
a new architecture, consistent with the "few shared files" requirement.

**Result (Level 27, 1080x2400, the reported case)**: cell_size 124px→
142px (+14.5%), height utilization 64.7%→72.3%, width utilization
unchanged at ~99.5% (already maxed). **Full resolution/profile matrix
(all 5 resolutions × 12 synthetic profiles): 140/140 COMFORTABLE** (up
from Phase 1's 136/140 - the margin reduction also pushed every
previously-borderline 95px cell above `MIN_COMFORTABLE_CELL_SIZE`).
Visually confirmed via real rendering (not just the metrics) for five
representative cases - Level 1 (5x6, small board), Level 27 (7x8, the
reported case), Level 100 (10x12, tall/dense board), Era 2 Level 110
(8x10, MAX_COLUMNS board), and Tutorial T01 (5x5) - all fill their
screen well; Level 27 remains the visually "loosest" of the five
(inherent to its 7:8 shape at width-bound sizing) but is meaningfully
tighter than before.

**Honest disclosure, not spin**: this does NOT fully equalize height
utilization for every board shape on every device height. A
width-bound board's `cell_size` is provably already at its maximum
given the available width (confirmed: 99.4-100% width utilization
across the entire matrix) - no margin adjustment, gap adjustment, or
centering change can grow it further without either shrinking columns
(a level redesign, explicitly forbidden this pass) or stretching cells
non-square (explicitly forbidden, always). Some residual vertical gap
on very tall devices for board shapes authored/re-laid-out against the
1080x1920 floor is the **mathematically unavoidable** consequence the
spec's own "Important note about unused space" section describes as
acceptable, given tiles are already at their width-bound maximum. A
future pass that wants to close this further would need to either
choose board shapes against the realistic RANGE of portrait aspect
ratios (not just the 1920 floor) - a sixth portrait re-layout pass,
explicitly out of scope this time - or accept non-square cells, which
this project has never done and isn't proposing now.

**Regression**: full runtime-vs-solver replay unchanged at **188/188
PASS** (zero puzzle/solver code touched - only `UIConstants`,
`SafeAreaMargin`, and one literal added to `game.tscn`). A dedicated
12-point Phase 2 (Direct Play + Continue) re-check, since this pass
touches a file (`game.tscn`) Phase 2's resume logic also reads:
**12/12 PASS** - fresh-save resolve, real entry sets the resume
pointer, a real move persists orientation+move count, re-entering the
same level restores both, Reset clears them, completing a level
advances the resume pointer, and a QA Level Select entry still never
touches it.

**Files changed**: `scripts/ui/ui_constants.gd` (new
`GAMEPLAY_BASELINE_MARGIN` constant), `scripts/ui/safe_area_margin.gd`
(`margin_override` field, additive), `scenes/gameplay/game.tscn` (one
new property line on its existing `SafeMargin` node), `export_presets.
cfg` (versionCode 42->43). **Files NOT changed**: any level `.gd` file,
`LaserSystem`, `GridTypes`, `LevelValidator`, `LevelSolver`,
`grid_manager.gd`'s layout formula itself (`_recalculate_layout()` is
unchanged - it already correctly maximizes `cell_size` for whatever
rectangle it's given; the rectangle itself is what grew), any menu
scene (`main_menu.tscn`, `level_select.tscn`, `settings_menu.tscn`,
`tutorial_select.tscn` all keep their existing `margin_override`
default of -1, i.e. `BASELINE_MARGIN=96`, completely untouched), any
`SaveManager`/`GameManager` field.

**NOT MANUALLY APPROVED - Android device QA pending.** Per the spec's
own STOP CONDITION: **do not start the procedural generator** - the
user must install this APK and visually approve the board sizing on a
real phone first.

## D87 — Final Gameplay Spacing Refinement (`versionCode=44`, `3.6.2-FINAL-SPACING-QA`): the last honest tightening, plus a proof of the mathematical limit

**Good news first**: the user manually tested `versionCode=43` (D86)
on a real Android phone and confirmed the larger-tile layout is "MUCH
BETTER... close to the desired result" - explicitly not a redesign
request, a final polish pass only: move Top/Bottom HUD a little closer
to the screen edge, tighten the gap between HUD and board a little
more, without touching tile size or the left/right margin D86 already
established as acceptable.

**`SafeAreaMargin.margin_override` (one scalar, D86) split into two**:
`horizontal_margin_override` and `vertical_margin_override`, since this
pass needed the vertical axis to shrink independently of the horizontal
one (which the user explicitly said not to touch further). New
constants: `UIConstants.GAMEPLAY_HORIZONTAL_MARGIN := 32.0` (unchanged
from D86) and `UIConstants.GAMEPLAY_VERTICAL_MARGIN := 8.0` (new,
matching `GRID_SAFETY_MARGIN`'s own established "8px is a reasonable
minimum real buffer" precedent). Every menu screen's `SafeAreaMargin`
instance is still completely untouched (both new fields default to -1).

**Important mathematical finding, proven by direct rendering + a
derivation, not assumed**: for a WIDTH-BOUND board (confirmed to be the
common case - every level checked, from 5x6 to 10x12, hits ≥97% width
utilization on a portrait screen at ≤10 columns), `SafeAreaMargin`'s
vertical value has **zero effect on the visible gap between the HUD and
the board**. `CenterArea` has `size_flags_vertical = EXPAND_FILL`, so it
absorbs 100% of whatever the vertical margin frees up; the board is
then centered within that (now-larger) `CenterArea`. Algebraically:

```
total_top_space = vertical_margin + TopBar.height + separation + grid_origin.y
grid_origin.y = (CenterArea.height - board_height) / 2
CenterArea.height = (screen_height - 2*vertical_margin) - TopBar.height - BottomBar.height - 2*separation
```

Substituting and simplifying, `vertical_margin` and `separation` both
cancel out completely:

```
total_top_space = TopBar.height/2 - BottomBar.height/2 + screen_height/2 - board_height/2
```

Confirmed directly by rendering Level 28 (6x7, the user's own reference
level this pass) at 1080x2400 with `vertical_margin_override` swept
across 32/24/16/8/0: `TopBar.global_position.y` moved exactly with the
override (32→0, as expected - the HUD bar DOES visibly move closer to
the edge), but `total_top_space` (margin + separation + grid_origin.y)
stayed **exactly 619px at every value tested** - proving the "gap
between HUD and board" is a fixed quantity for a width-bound, centered
board, entirely determined by `TopBar`/`BottomBar`'s aspect-locked
height (unchanged HUD art) and `board_height` (`cell_size` already
width-maximized, per D86) - not by margin or separation at all.
Reducing `VBoxContainer` separation would have the identical
cancellation for the same reason (confirmed algebraically, not
re-tested empirically since the derivation already covers it) - it was
deliberately left unchanged (still 16px) since changing it would be a
no-op disguised as a fix.

**What this means for the fix actually shipped**: shrinking the
vertical margin is real and delivers exactly what it can honestly
deliver - the Top/Bottom HUD bars now sit visibly closer to the true
screen edge (8px vs. D86's 32px) - but it does **not**, and
mathematically cannot, shrink the total empty space around a
width-bound board any further. This is not a shortfall in this pass's
effort; it's the same "mathematically unavoidable... acceptable" space
the spec's own "Important note about unused space" section already
anticipated - this pass just proves precisely where that boundary is
and why no further margin/separation tuning can cross it without
violating one of the user's own explicit constraints (no tile-size
change, no HUD art redesign, no level redesign).

**Result (Level 28, the reference level, 1080x2400)**: `TopBar`
position moved from y=32 to y=8 (visibly closer to the edge, confirmed
via rendering). `cell_size` unchanged at 166px (already width-maximized
by D86, confirmed identical at every vertical-margin value tested -
proof of "no tile-size regression"). Total HUD-to-board gap unchanged
at 619px (mathematically proven invariant, see above) - this is the
honest, disclosed limit, not a bug or an incomplete fix. At the
1080x1920 reference specifically, Level 28 is nearly height-bound
(97.2% width / 99.6% height utilization) - the composition already
looks close to fully filled there; the residual gap is a taller-device
(1080x2400+) phenomenon specific to width-bound board shapes, same
root cause as D86.

**Full resolution/profile matrix**: still **140/140 COMFORTABLE**
(unchanged from D86 - the vertical-margin change doesn't affect
`cell_size`/comfort at all, only HUD position). **Visually confirmed**
via real rendering (not metrics alone, per the spec's explicit
requirement) for 6 cases - Level 1 (5x6), Level 27 (7x8, the original
reported case), Level 28 (6x7, this pass's reference level, direct
before/after comparison), Level 100 (10x12), Era 2 Level 110 (8x10),
and Tutorial T01 (5x5) - all render correctly, HUD bars fully visible
and legible at the tighter margin, no clipping, no overlap.

**Future procedural generator design note, recorded as instructed**:
the durable fix for the "large unavoidable gap" pattern isn't more
margin tuning on existing content - it's **choosing board shapes that
don't end up strongly width-bound on a portrait screen in the first
place**. `MAX_COLUMNS := 8` remains permanent. The generator should
prefer taller row/column combinations (e.g. 5x8/5x9, 6x9/6x10,
7x9/7x10/7x11, 8x10/8x11 - examples, not mandatory profiles) specifically
because they push a board's binding constraint away from "width capped,
huge unused height" toward genuinely balanced or height-bound
utilization - but ONLY when `GridManager.is_board_profile_comfortable()`
actually confirms the resulting `cell_size` still clears
`MIN_COMFORTABLE_CELL_SIZE` for the target device range. Difficulty must
never come from shrinking tiles to make a taller board fit.

**Regression**: full runtime-vs-solver replay unchanged, **188/188
PASS** (zero puzzle/solver code touched). Phase 2 (Direct Play +
Continue) re-check: **12/12 PASS** (identical coverage to D86's
re-check - fresh-save resolve, resume pointer set on entry, move
persistence, CONTINUE restore, Reset clearing, completion advancing the
resume pointer, QA Level Select never touching resume state).

**Files changed**: `scripts/ui/ui_constants.gd` (`GAMEPLAY_BASELINE_
MARGIN` split into `GAMEPLAY_HORIZONTAL_MARGIN`/`GAMEPLAY_VERTICAL_
MARGIN`), `scripts/ui/safe_area_margin.gd` (`margin_override` split into
`horizontal_margin_override`/`vertical_margin_override`), `scenes/
gameplay/game.tscn` (two property lines on `SafeMargin` replacing one),
`export_presets.cfg` (versionCode 43->44). **Files NOT changed**:
`grid_manager.gd`'s layout formula, `GRID_SAFETY_MARGIN`, `Layout`'s
`VBoxContainer` separation (confirmed a no-op, left alone), any level
`.gd` file, `LaserSystem`, `GridTypes`, `LevelValidator`, `LevelSolver`,
any menu scene, any `SaveManager`/`GameManager` field.

**NOT MANUALLY APPROVED - Android device QA pending.** Per the spec's
own STOP CONDITION: **do not start the procedural generator** until the
user installs this build and visually approves the final gameplay
layout on a real phone.

## D88

### Phase 3: Procedural Level Generator V1 (Levels 1-2000) + QA Next button (`versionCode=45`, `4.0.0-PROCEDURAL-V1-QA`)

The user's own STOP CONDITION on D87 explicitly deferred starting the
procedural generator until Android device QA approved the Full-Screen
Board Correction/Final Gameplay Spacing Refinement layout work - the user
then explicitly authorized starting the generator anyway (a detailed
47-part spec), superseding that deferral for this pass specifically. Full
architecture, band table, template catalog, audit numbers, save contract,
and QA Next button behavior are documented in the new
`PROCEDURAL_GENERATION.md` - this entry is the implementation writeup
(what was built, what broke during authoring, what was proven, and how).

**New files**: `scripts/procedural/procedural_seed.gd`,
`procedural_difficulty_profile.gd`, `procedural_templates.gd`,
`procedural_level_generator.gd` (all runtime, NOT export-excluded);
`scripts/tools/procedural_audit.gd` (dev-only, export-excluded like its
siblings). **Modified**: `scripts/managers/save_manager.gd` (6 new
`procedural_*` fields, `SAVE_VERSION` 4->5, 6 new resume/completion
methods mirroring the `campaign_resume_*` group exactly),
`scripts/managers/game_manager.gd` (`is_procedural_mode`,
`current_procedural_level`, `start_procedural_level()`; `play_game()`/
`continue_game()` now genuinely diverge - see below),
`scripts/managers/level_manager.gd` (`get_procedural_generation_result()`/
`get_procedural_level()`/`get_procedural_level_count()`,
`SHOW_PROCEDURAL_QA_NEXT_BUTTON`), `scripts/gameplay/game.gd` (a third
`_load_current_level()`/`_on_move_made()`/`_on_level_solved()` branch,
`_on_qa_next_pressed()`), `scenes/gameplay/game.tscn` (`%QANextButton`),
`scripts/ui/main_menu.gd` (Continue's enabled-check now reads
`has_resumable_procedural_game()`).

**Rule-9 boundary held, deliberately, by design** - see
`PROCEDURAL_GENERATION.md` section 5. The live generator never calls
`LevelSolver`/`LevelValidator`; it self-verifies by directly simulating
its own already-known solution via `LaserSystem.simulate_until_stable()`
(no search). `LevelSolver`/`LevelValidator` instead exhaustively prove the
*generator itself* during a dev-time audit - exactly the same relationship
the 140 handcrafted campaign levels already have with the solver. This was
a real fork in the road during planning (a pre-generated/cached-`.tres`
approach that never touches the solver at runtime at all was the other
serious option) - the direct-self-verification design was chosen because
it keeps `scripts/tools/**`'s export exclusion completely untouched with
zero on-device latency cost (generation is sub-millisecond - see the
timing numbers below), while still being genuinely live/on-demand rather
than a large pre-baked content cache.

**Full 1-2000 audit (real `LevelSolver`/`LevelValidator`, dev-only driver,
not committed)**: **0/2000 failures, 0/2000 fallbacks, 11/11 determinism
matches**, 278.1s total wall time for the exhaustive-solver pass across
every level (dev-time only). `optimal_moves` min 1/median 6/max 14;
`states_explored` up to 65519 (near the 65536 solver ceiling on the
hardest levels, still resolves). 20/2000 (1.0%) non-unique shortest
solutions - informational, not a failure, per the spec's own explicit
allowance. Generation timing (the actual live/runtime path): median 241us,
p95 681us, max 1779us per level - no loading-screen strategy was needed.

**Four real bugs found and fixed during this pass's own template-sweep
smoke test** (all in `procedural_templates.gd`, all found by the audit
tooling itself, none by inspection) - full technical detail in
`PROCEDURAL_GENERATION.md` section 7, general lessons repeated here since
they're the kind CLAUDE.md's own "don't re-discover this" rule exists for:

1. `portal_route`'s Portal B shared Portal A's column (the board's
   far-right edge), leaving the second path zero horizontal room -
   30/30 raw attempts failed validation before the fix. Fixed by
   band-splitting the board (reusing `multiple_emitter`'s own technique)
   instead of searching for a workaround position.
2. Leg count wasn't clamped against ACTUAL available room before laying
   out legs - only each leg's own length was floored at 1, so a turn
   count too large for a small band-split height forced repeated
   boundary-clamping, producing duplicate tile positions. Fixed by
   clamping the total leg count mathematically (`L <= 2*h_room`,
   `L <= 2*v_room+1`) before any leg is walked, not after the fact.
3. A parity constraint ("path 1 must end moving RIGHT, since portals
   preserve direction and path 2 always starts assuming a RIGHT entry")
   was silently dropped during the band-split rewrite for bug #1 - the
   solver still found *some* solvable combination by luck, masking that
   the template's own INTENDED solution never actually simulated as
   solved. Caught only by explicitly asserting the intended solution
   simulates as solved, not just "solver says SOLVABLE."
4. Template selection was keyed on `attempt % pool.size()`, not
   `level_number` - since attempt 0 succeeds on the vast majority of
   candidates, every level in a band landed on the SAME first template;
   6 of 10 templates never appeared anywhere in the first full 1-2000
   audit despite 0 failures. **A clean pass/fail audit result does not by
   itself prove template/mechanic diversity** - the bug was only visible
   by checking the mechanic-frequency distribution, not the failure
   count. Fixed by keying selection on `(level_number + attempt) %
   pool.size()`; re-audit confirmed all 10 templates used, no template
   starved (75-275 uses each across the full range).

**A real design gap found only by an end-to-end runtime test, not by code
review**: `continue_game()` originally targeted
`SaveManager.procedural_current_level` (real progression) exactly like
`play_game()` - identical to how both functions worked through Phase 2.
But QA Next can now genuinely leave the player's "last visited level"
ahead of real progression (spec's own example: tester on Level 487,
presses QA Next to reach 488, exits app - CONTINUE must reopen 488, not
487). Fixed by having `continue_game()` target
`SaveManager.procedural_resume_level_number` (the exact last-opened level,
set by every level load AND by QA Next alike) when a resumable game
exists, falling back to `procedural_current_level` only for a fresh save -
this is why `play_game()`/`continue_game()` are no longer byte-identical,
unlike D85's Phase 2 (where "kept as a separate entry point... even though
both share one implementation today" was explicitly anticipated as
possibly diverging later). Also found during this same test: an initial
`record_procedural_level_result()` draft explicitly cleared the resume
slot on completion - removed as redundant once tracing through
`start_campaign_resume()`'s own existing reasoning showed resume state is
already safe without it (only ever consulted by comparing against the
SPECIFIC level number being loaded next, and a completed level is never
reloaded) - kept the function mirroring `record_campaign_level_result()`
exactly, per CLAUDE.md's "don't add code beyond what's needed."

**End-to-end runtime verification** (temporary autoload driver, per
TEST_PLAN.md's documented autoload-dependent-scene testing technique,
deleted after use, real user `savegame.json` backed up before and
restored after both runs): fresh-save PLAY enters procedural Level 1;
a non-solving move persists to `procedural_resume_*`; a simulated
relaunch (`continue_game()`) restores the EXACT board state (orientations
+ move count byte-for-byte); a legitimate solve of the real next-in-line
level advances `procedural_current_level`; QA Next advances the viewed
level without touching `procedural_current_level`; solving a
QA-Next-skipped-to level (genuinely not next-in-line) does NOT advance
progression; solving the real next-in-line level DOES; Level 2000
completes safely (`has_next_level=false`, no crash, pointer advances to
2001 without attempting a nonexistent level).

**Legacy regression** (same technique, separate temporary driver): Campaign
QA Level Select (Levels 1/50/100/140) solved via the real solver's
solution path - all `is_solved=true`, `entered_via_level_select=true`,
`is_procedural_mode=false`. Dev levels 1/15 - solver-confirmed unchanged
(`optimal_moves` 1/2). Tutorial T01/T20 - both load into `Game` with
`is_tutorial_mode=true`, no crash. Editor-playtest hand-off - unaffected.
Zero simulation/campaign/tutorial code was touched by this phase (every
change to `game.gd` is a new `elif` branch alongside the existing ones,
verified by direct diff of the surrounding `if`/`elif`/`else` structure).

**QA Next button rendering bug, found only by a real rendered screenshot,
not headless checks** (see CLAUDE.md rule 12d) - the first `%QANextButton`
placement used `anchor_top`/`anchor_bottom = 0.16` (a leftover from early
authoring) instead of matching Reset/Pause's own vertical center
(`~0.5175`), landing the button above the visible `BottomBar` art entirely
- invisible in a real render despite `.visible == true` and the node
resolving correctly via `%QANextButton`, exactly the D63-class "runtime
mouse_filter/rect looks right in isolation but isn't" bug CLAUDE.md warns
about, this time for anchoring instead of an instance-override. Fixed by
matching the existing buttons' vertical anchor; re-rendered and confirmed
legible at 1080x1920 (Level 1), 720x1280 (Level 1000), and 1080x2400
(Level 2000) - board fills the available space correctly at every profile
tested, no clipping, `NEXT >>` (ASCII, not the original `NEXT »` - avoided
an unverified non-ASCII glyph on Android's default font) reads clearly in
its hex-frame slot alongside Reset/Pause. **RENDERED-tier verification
only** (CLAUDE.md rule 12d's vocabulary) - no MANUAL (real-device) review
has occurred; see `PROCEDURAL_GENERATION.md` section 15's release-blocker
checklist.

**Files NOT changed**: `laser_system.gd`, `grid_types.gd`, `grid_manager.gd`,
`level_solver.gd`, `level_validator.gd`, `level_metrics.gd`, any campaign/
tutorial/dev level `.gd` file, `tools/level_editor/**`, `export_presets.cfg`'s
`exclude_filter` (unchanged - `scripts/procedural/` was never added to it,
`scripts/tools/**` already covered the new audit script).

**NOT MANUALLY APPROVED - Android device QA pending**, same as every
prior layout pass. See `PROCEDURAL_GENERATION.md` section 15 for the full
release-blocker checklist, and TEST_PLAN.md for the QA APK export record.

## D89

### Audio/SFX Integration Pass: centralized AudioManager, 22 SFX wired (`versionCode=46`, `4.0.1-AUDIO-SFX-QA`)

The user manually renamed and staged 22 Kenney-sourced SFX files under
`assets/sfx/` and requested a centralized audio architecture - one shared
`AudioManager`, never per-level or per-scene `AudioStreamPlayer` nodes,
so all 2,000 procedural levels (and every legacy/campaign/tutorial level)
get audio automatically. Full architecture, semantic event table, bus
layout, gain table, anti-spam/suppression reasoning, and Era 2 reuse
mapping are documented in the new `AUDIO_SYSTEM.md` - this entry is the
implementation writeup.

**New files**: `assets/sfx/*.ogg` (22 files + `.import` siblings, already
present/imported before this pass - inspected, not authored, by this
session), `assets/audio/default_bus_layout.tres` (Master/SFX/UI buses),
`scripts/managers/audio_manager.gd` (4th autoload), `AUDIO_SYSTEM.md`.
**Modified**: `project.godot` (`[autoload]` gained `AudioManager`,
new `[audio]` section points at the bus layout), `scripts/gameplay/grid_manager.gd`
(two new private methods - `_play_state_transition_audio()`,
`_play_beam_interaction_audio()` - called only from
`_simulate_and_draw()`'s existing `play_impacts` branch, plus one
`AudioManager.play_mirror_rotate()` call in `_on_orientable_tile_clicked()`
at the exact point a rotation is known-accepted, plus one
`AudioManager.play_puzzle_solved()` call at the existing
`is_solved` false→true transition), `scripts/gameplay/mirror.gd`/
`splitter.gd`/`one_way_reflector_tile.gd` (`_gui_input()`'s existing
`if not rotatable: return` early-out now plays `mirror_locked` before
returning), `scripts/gameplay/game.gd` (Back/Reset/Pause/QA-Next button
SFX, Pause popup SFX, `play_level_complete()` at both completion popups),
`scripts/ui/*.gd` (one extra `.pressed.connect(AudioManager.play_*)` per
player-facing button, `settings_menu.gd`'s Sound toggle also calls
`AudioManager.set_sound_enabled()`), `export_presets.cfg` (`version/code`
45→46, `version/name`).

**Why `_simulate_and_draw`'s existing `play_impacts` parameter is the
audio gate, not a new flag**: it already meant exactly "this evaluation
was caused by an actual accepted player tap" (Milestone 4A's mirror-impact
VFX used it for the same reason) - `_on_orientable_tile_clicked()` is its
only `true` call site, already past the `is_solved`/`interaction_locked`/
`interaction_restricted_to` guards, while `load_level()`,
`restore_orientations()` (Continue/resume), and `reset_level()` all use
the `false` default. Reusing it means Continue-restore silence and
generator/solver/audit silence (the latter never touches `GridManager`
at all) are structural guarantees, not a second state machine that could
drift out of sync with the first - see CLAUDE.md's new "Audio rules"
section for why this is now a standing rule, not just this pass's
implementation choice.

**Transition-only playback, not blind per-simulate playback**: target/
switch/hazard/gate/receiver/remote-emitter audio is driven by comparing
each node's state immediately before `_simulate_and_draw()` overwrites
it against the state it just computed - an already-active target holding
active across a move plays nothing. Beam-interaction audio (reflect/
split/filter/portal) de-dupes by grid position (or entry/exit pair for
portals) within one evaluation, so a beam revisiting the same cell (loop-
guarded revisit, or two branches crossing) plays that cell's SFX once.

**One real gap found and fixed during this pass's own headless
verification, not left for a future session to rediscover**: the first
draft of `_play_beam_interaction_audio()` only checked `_orientable_nodes.get(pos)
is MirrorTile` for reflection SFX, silently missing One-Way Reflector's
reflective hits (Era 2) even though `LaserSystem` records them as an
identical segment-corner point. Fixed by adding an
`is OneWayReflectorTile` branch reusing `play_laser_reflect()` - safe
because a pass-through One-Way Reflector hit records no segment point at
all (see `laser_system.gd`), so reaching that branch already guarantees
a real reflection happened.

**Three of the 22 SFX are registered and callable but currently unused,
deliberately, not an oversight** - see `AUDIO_SYSTEM.md` section 11:
`sfx_target_wrong.ogg` (no "wrong-color beam reached this target" signal
exists in `LaserSystem`), `sfx_star_appear.ogg` (`LevelCompletePopup`
reveals all 3 stars in one call, never staggered), `sfx_ui_locked.ogg`
(the only "locked" UI elements are `disabled=true` Buttons, which
intercept no input at all in Godot - no real tap-while-locked event
exists to hook without artificially enabling a disabled button, which
the brief explicitly said not to do).

**Verification technique**: no laser/grid simulation logic was touched
(`laser_system.gd`/`grid_types.gd` untouched - grep-confirmed), so the
15 dev/regression levels' documented solvability was not at risk; the
real regression surface was `grid_manager.gd`'s `_simulate_and_draw()`
restructuring. Verified via the project's own documented driver-scene
technique (CLAUDE.md "Testing expectations"): a temporary
`scripts/tools/_qa_audio_driver.gd`/`.tscn` (deleted before this pass
ended, per D78's "temporary QA files never survive a pass" lesson)
temporarily became `run/main_scene`, loaded Campaign Level 1 through a
real `GridManager`, confirmed all 22 SFX streams load
(`AudioManager._streams.size() == 22`), rotated a real mirror through the
exact player-tap code path twice (second tap on an already-solved board
correctly stayed a no-op), and called `restore_orientations()` directly
with no crash - `run/main_scene` was reverted to `main_menu.tscn`
immediately after, confirmed via `grep`.

**Files NOT changed**: `laser_system.gd`, `grid_types.gd`,
`scripts/procedural/**`, `scripts/tools/procedural_audit.gd`,
`level_solver.gd`, `level_validator.gd`, `level_metrics.gd`, any
campaign/tutorial/dev level `.gd`/level-data file, `tools/level_editor/**`,
`LevelData`/`TilePlacement` (`scripts/resources/level_data.gd` - grep-
confirmed zero new fields, per the brief's own explicit architecture
rule that levels must never carry audio data).

**NOT MANUALLY APPROVED - Android device audio QA pending.** Per-SFX
gains (`AudioManager.SFX_TABLE`'s `gain_db` values) are unlistened
placeholder judgment calls - see `AUDIO_SYSTEM.md` section 15 for the
full manual Android audio QA checklist this pass is waiting on, on top
of the Phase 1-3 layout/navigation/generator passes that already await
real-device review together.

## D90

### Minimal Gameplay Background Pass: non-destructive Background.modulate darkening (`versionCode=47`, `4.0.3-MINIMAL-BG-QA`)

The user reported the gameplay background's environmental detail (metal
panels, reflective floor tiles, orange/blue glow strips, a windowed
planet view) competes visually with the puzzle - explicit priority
order requested: laser beams > interactive tiles > grid > HUD >
background, background must never compete with the puzzle. Brief
explicitly forbade generating any new image in this investigation pass.

**Step 1 (inspection)**: `game.tscn`'s root `Background` `TextureRect`
is fed by `game.gd._apply_era_theme()`, which only ever swaps `.texture`
(Era 1 → `bs_bg_gameplay.png`, Era 2 → `bs_bg_gameplay_era2.png`, every
other era falls back to Era 1's texture). Grid cells are a separate,
already-dark `TextureRect` layer (`TileVisual.active_cell_background`)
drawn on top - the busy background was only ever visible in the space
around the board, never behind it. No modulate/shader/CanvasModulate was
applied to it before this pass (grep-confirmed).

**Step 2 (existing-asset check)**: every PNG under `assets/` was
enumerated. Neither existing gameplay background qualifies as "minimal"
on its own: `bs_bg_gameplay.png` (used for Era 1 and every era ≥3, i.e.
the vast majority of content) has a floor-tile pattern that visually
echoes the grid itself, plus prominent orange AND blue glow strips;
`bs_bg_gameplay_era2.png` is quieter centrally but is the wrong hue
family (violet, not the requested blue/cyan) and is Era 2's own
deliberate, documented identity (`EraTheme`), not a general-purpose
asset. No other minimal blue/dark background exists anywhere in the
project.

**Step 3 (non-destructive fix, tested and adopted)**: added
`modulate = Color(0.22, 0.26, 0.38, 1)` to that one `Background` node in
`game.tscn`. Chosen so the channel most responsible for the background's
prominent orange glow strips (red) is suppressed hardest, while blue is
retained relatively the most - darkening the whole image while keeping
its remaining hue in the requested blue/cyan family. Since
`_apply_era_theme()` never touches `.modulate`, this one property
applies uniformly under every era, current and future, campaign/
procedural/tutorial alike, with zero per-level or per-era code. No PNG
edited; HUD, grid cell art, tile scripts, and beam `Line2D` nodes are
separate draw calls/nodes and are structurally unaffected.

**Verification technique - a genuine environment discovery, not just a
result**: this dev machine's physical monitor is a 2560x1080 ultrawide
(confirmed via `System.Windows.Forms.Screen`), whose ~1032px work-area
height silently clamps any on-screen portrait window taller than that -
a plain `--resolution 1080x1920` (or `1080x2400`) request came back as
an actual captured window of `1080x1061`, and `canvas_items`/`expand`
stretch mode then reflows the WHOLE layout to that clamped near-square
aspect instead of the intended portrait one, rather than letterboxing.
This means a naive on-screen-window screenshot at "1080x1920" on this
machine was silently testing the wrong aspect ratio the entire time.
**Fix (reusable technique, not a one-off workaround)**: reparent the
live scene into an off-screen `SubViewport` with an explicit `.size`
before capturing - a `SubViewport`'s size is independent of the
physical display, and Control nodes size themselves against it exactly
as they would the real root Window (`get_viewport().get_visible_rect()`
correctly resolves to the SubViewport for any Control inside it, so
`grid_manager.gd`'s existing layout math needs no special-casing). Any
future resolution-matrix RENDERED check on this machine should use this
SubViewport-reparent technique rather than trusting a `--resolution`
flag's on-screen window size at face value - confirm the actual captured
image dimensions match the request, not just that the process didn't
error.

**RENDERED evidence** (D45-D47 tier): before/after screenshots captured
via the SubViewport technique above at 720x1280, 1080x1920, and
1080x2400 for Campaign Level 1, Campaign Level 100 (Era 1's last level),
Campaign Level 102 (Era 2, violet theme), and procedural Level 1000
(Era-3+, Era-1-texture-fallback). In every case: laser beams, mirrors,
targets, and grid cells stayed fully bright and immediately readable;
the environment receded to a quiet dark-blue backdrop; a direct pixel
sample at a HUD-art coordinate (crystal ornament corner, Level 102)
came back bit-for-bit identical before/after (`(67,12,197)` both times),
confirming the treatment truly never touches HUD pixels, not just that
it looks unchanged. A background-art coordinate at the same resolution
went from `(229,138,243)` to `(50,36,92)` - matching the modulate
multiplier almost exactly (`229*0.22≈50`, `138*0.26≈36`, `243*0.38≈92`).

**Board-size note (found, explicitly NOT fixed this pass)**: several of
the rendered levels (e.g. Level 1's 5x6 board) occupy a small fraction
of the available portrait screen at some resolutions - a board-sizing/
generator-profile matter, unrelated to background readability. Per the
brief's explicit instruction, this is documented as a separate future
task, not addressed here: future procedural board-profile tuning should
favor taller, portrait-friendlier shapes (e.g. 5x9, 6x10, 7x11,
8x11-style ranges, examples not mandates) that better use available
height, while preserving `GridManager.MAX_COLUMNS := 8`, square cells,
`MIN_COMFORTABLE_CELL_SIZE`, and no non-square stretching - gate any
candidate shape on `GridManager.is_board_profile_comfortable()` actually
passing, per `CLAUDE.md`'s existing Responsive-rules guidance for future
generator profiles. This note applies equally to small legacy/campaign
boards, not just procedural ones.

**Files changed**: `scenes/gameplay/game.tscn` (one `modulate` line on
the `Background` node) - nothing else. **Files NOT changed**:
`grid_manager.gd`, `laser_system.gd`, `grid_types.gd`, any tile script,
`TileVisual`, `scripts/procedural/**`, `scripts/tools/procedural_audit.gd`,
`SaveManager`, `AudioManager`, any level data, any HUD scene/script, any
PNG.

**NOT MANUALLY APPROVED - Android device visual QA pending.** This is a
presentation-only pass; see `TEST_PLAN.md`'s section of the same name
for the exact resolution/level matrix and the QA APK's regression
checklist.

## D91

### Unified Blue Theme Fix: removed automatic purple/violet Era 2 skin switching (`versionCode=48`, `4.0.4-UNIFIED-BLUE-QA`)

The user approved the Minimal Gameplay Background pass's `modulate`
darkening but rejected a separate, pre-existing behavior it surfaced:
Era 2 content (Campaign Levels 101+, T11-T20) automatically switches the
whole gameplay screen's background/grid/HUD/accent color family to a
violet/magenta skin, purely as a function of level/tutorial number. The
user wants exactly ONE active gameplay theme (blue/cyan) across all
2,000 procedural levels, the legacy campaign, and every tutorial,
regardless of era/difficulty/mechanic band - difficulty and mechanics
may keep changing, the skin must not.

**Step 1 (inspection) - the old theme-selection flow, traced end to
end**: `game.gd._load_current_level()` computes a numeric era via
`EraTheme.get_era_for_level(current_level_id)` (campaign),
`EraTheme.get_era_for_level(procedural_level_number)` (procedural), or
`EraTheme.get_era_for_tutorial(GameManager.current_tutorial_id)`
(tutorial), then calls `_apply_era_theme(era_number)`, which calls
`EraTheme.for_era(era_number)` and copies `.gameplay_background`/
`.grid_cell_empty`/`.grid_cell_selected`/`.hud_top`/`.hud_bottom`/
`.hud_aspect_ratio`/`.level_complete_panel`/`.tutorial_complete_panel`
onto the live scene. `EraTheme.for_era()` was the SOLE place asset
selection happened - `match era_number: 2: return _build_era_2()`,
else `_build_era_1()` (all-null - "use the existing Era 1 asset"). Two
more call sites read the same function purely for `accent_color`
(`level_button.gd`/`tutorial_button.gd`'s card tint) and for
`level_select_background`/`tutorial_select_background`
(`level_select.gd`/`tutorial_select.gd`). **Grep-confirmed: every one of
these five call sites already routed through `EraTheme.for_era()` -
theme selection was never scattered across `if level < 100`/`if era ==
2` checks in multiple files to begin with**, so the brief's "don't
scatter fixes" concern (Step 2) was already satisfied by the existing
architecture; the actual problem was that `for_era()` itself had a
branch that activated Era 2's real (violet) asset set at all.

**Step 2 (single authoritative rule) - the fix**: added one constant,
`EraTheme.UNIFIED_BLUE_THEME_ONLY := true`
(`scripts/resources/era_theme.gd`), checked first inside `for_era()`:
when true, `for_era()` always returns `_build_era_1()` regardless of
`era_number`, before the `match` statement ever runs. This is the
single, explicit, well-documented switch the brief asked for -
flipping it back to `false` is the complete, one-line revert to Era 2's
original behavior, and there is no second place in the codebase that
also needs to change for either direction. `_build_era_2()` itself is
completely untouched and still loads every one of its 9 Era 2 assets
correctly if the flag is ever flipped back - proven by temporarily
flipping it during this pass's own investigation, not just assumed from
reading the diff.

**Numeric era-band logic is completely decoupled from this flag, by
construction, not by careful case-by-case checking**: `EraTheme.
get_era_for_level()`/`get_era_for_tutorial()` (pure arithmetic on the
level/tutorial number) are untouched, and neither
`LevelManager.is_tutorial_level_selectable()`'s T11-T20 unlock gate nor
`game.gd`'s Level 100->101 `era_transition` banner check ever reads
anything from `for_era()`'s returned object - both compare the NUMERIC
era only. Confirmed by a real regression run: the QA Next button
correctly advanced procedural progression, the Level 100->101 boundary
still fires its transition banner, and T11-T20 unlock gating is
unaffected - all while every one of those screens now renders in blue.

**Step 7 (advanced mechanic tile art) - inspected, kept, not
recolored**: Prism, One-Way Reflector, Beam Receiver, and Remote
Emitter each `preload()` their own texture unconditionally in their own
tile script (`prism_tile.gd`, `one_way_reflector_tile.gd`,
`beam_receiver_tile.gd`, `remote_emitter_tile.gd`) - these were NEVER
routed through `EraTheme` at all, so the theme fix above has zero effect
on them either way. Visually inspected directly: all of
`bs_tile_prism_base_era2.png`, `bs_tile_one_way_reflector_base_era2.png`,
`bs_tile_beam_receiver_{base,inactive}_era2.png`, and
`bs_tile_remote_emitter_{base,inactive}_era2.png` are genuinely
purple-specific art (prominent violet neon edge glow baked in) - not
neutral or blue-compatible. Per the brief's explicit instruction (no
image generation, no destructive recolor, no mechanic removal), these 6
files are kept exactly as they are and are the ONE remaining visible
purple element in normal gameplay - small tile icons on an otherwise
all-blue screen, not a global skin. **Listed here as the concrete
"needs a future blue-specific asset" set**: `bs_tile_prism_base_era2.png`,
`bs_tile_one_way_reflector_base_era2.png`,
`bs_tile_beam_receiver_base_era2.png`,
`bs_tile_beam_receiver_inactive_era2.png`,
`bs_tile_remote_emitter_base_era2.png`,
`bs_tile_remote_emitter_inactive_era2.png`. All four mechanics remain
100% functional - confirmed via the full visual regression set below
and via the pre-existing solver/runtime-replay regression, neither of
which was touched.

**Two smaller residual-purple issues found during RENDERED verification
and fixed, both text/color-only, zero logic changed**:
1. T11's own first message literally said "Welcome to Era 2 —
   Refractions. The rules you already know haven't changed - only the
   scenery." - now false, since the scenery no longer changes. Reworded
   to "Welcome to Refractions. The rules you already know haven't
   changed - new mechanics are coming." (`levels/tutorial/t11.gd`). Every
   other "Era 2" mention across tutorials/campaign level files/comments
   (T12, T20, Level 108/110/120/129, editor fixture headers) refers to
   "Era 2" as the mechanic-family/content-generation name, never claims
   a visual change, and was deliberately left alone - renaming Era 2 as
   a content label is out of scope for a visual-theme pass.
2. `level_complete_popup.tscn`'s `EraTransitionLabel` (shown once, at
   the real Level 100->101 boundary) had a hardcoded
   `font_color = Color(0.85, 0.45, 1.0, 1)` - a static `.tscn` property,
   never routed through `EraTheme` at all, so the theme fix above could
   not have caught it. Its actual text ("ERA 2 — REFRACTIONS UNLOCKED /
   New tutorials (T11–T20) are now available.") is still accurate
   (new tutorials really do unlock there) and was left unchanged; only
   the color was recolored to `Color(0.4, 0.75, 1.0, 1)` (bright
   cyan-blue) so this one-time announcement doesn't flash purple text
   on an otherwise all-blue screen.

**Step 8 (purple assets retained)**: nothing under `assets/gameplay/
backgrounds/era2/`, `assets/gameplay/grid/era2/`, `assets/ui/era2/`,
`assets/ui/backgrounds/bs_bg_{level_select,tutorial_select}_era2_
portrait.png`, or any of the 6 advanced-mechanic textures listed above
was deleted, moved, or excluded from the export filter - `git status`
confirms zero asset files touched. `_build_era_2()` (source code) is
also untouched, just unreachable while `UNIFIED_BLUE_THEME_ONLY` is
`true`. `export_presets.cfg`'s `exclude_filter` was deliberately NOT
touched - shrinking the shipped APK by excluding now-unused Era 2
assets was considered and rejected as out of scope/unnecessary risk for
a visual-theme pass (see `CLAUDE.md` rule 9/D51/D78 precedent on
export-filter changes needing their own careful verification).

**Steps 9-11 (procedural generator / save compatibility / audio) -
verified untouched, not just assumed**: `git diff` confirms zero
changes to `scripts/procedural/**`, `scripts/tools/procedural_audit.gd`,
`SaveManager`, or `AudioManager`. A real regression run: `LevelManager.
get_procedural_generation_result(777)` called twice in the same process
returned an identical seed and generator_version both times
(determinism unaffected); `GameManager.play_game()` correctly entered
real procedural progression (Level 1 on this save); the QA Next button
correctly advanced the resume pointer (1→2); `GameManager.continue_game()`
correctly resumed exactly that level; `AudioManager` loaded 22/22 SFX
streams with zero errors. No save schema change, no
`SAVE_VERSION` bump - a player already saved mid-Era-2 sees the exact
same puzzle/progression state, now painted blue.

**Visual regression set, RENDERED (D45-D47 tier)**: Campaign Levels 21,
99, 100, 101, 102, 140; procedural Levels 200, 500, 1000, 1500, 2000;
Tutorials T01, T11, T20 - all 14 confirmed background/grid/HUD-family
identical to Level 21 (the user's own named blue reference). **Level 21
vs. Level 102 (the brief's own key comparison, Step 14)**: side-by-side
confirmed indistinguishable in global visual family - same dark-blue
gameplay background, same cell art, same HUD bars/aspect ratio (Era 2's
own `hud_aspect_ratio = 3.0` no longer applies either, since the whole
Era 2 theme object is unreachable - Level 102 now uses Era 1's HUD
aspect too, incidentally fixing a HUD-shape inconsistency between eras
as a side effect, not a separate deliberate change). The only visible
per-level difference across the whole set is puzzle content itself
(mechanics/layout/difficulty) and the small purple advanced-mechanic
tile icons noted above - never the surrounding skin.

**Files changed**: `scripts/resources/era_theme.gd` (one constant + one
early-return in `for_era()`), `levels/tutorial/t11.gd` (one message
string), `scenes/ui/level_complete_popup.tscn` (one label's
`font_color`). **Files NOT changed**: every tile script, `grid_manager.gd`,
`laser_system.gd`, `grid_types.gd`, `scripts/procedural/**`,
`scripts/tools/procedural_audit.gd`, `SaveManager`, `AudioManager`, any
level's `tiles`/mechanic data, any PNG, `export_presets.cfg`'s
`exclude_filter`.

**NOT MANUALLY APPROVED - Android device visual QA pending.** See
`TEST_PLAN.md`'s section of the same name for the full regression
checklist and the exact levels/tutorials rendered.


## D93

### Difficulty System Phase 1: difficulty contract, complexity metrics, triviality model, QA +50 centralized (no APK, `versionCode` unchanged at 48)

**Trigger.** Real-device feedback: a Level 1900+ procedural puzzle was
solved in about 3 moves. The generator proved "solvable", never "hard enough
for its position".

**Decision.** Difficulty is now defined by two independent things - optimal
moves AND meaningful reasoning complexity - and a raised move count from
independent/obvious rotations is explicitly not difficulty after the early
game. Phase 1 builds the contract and the measuring tools only; it does NOT
change generation (V1 frozen, V2 default, `GENERATOR_VERSION` still 2) and
does NOT gate candidates on a solver. Phase 2 must construct compliant
puzzles by design.

**Built** (details and tables: `PROCEDURAL_GENERATION.md` section 17):
- `ProceduralDifficultyContract.get_difficulty_requirements(level)` - the one
  data table (11 bands, moves/dependencies from the user's curve; depth,
  interaction, distinct-mechanic, decoy, board, unlock, independent-fraction
  and single-route fields are this pass's initial numbers).
- `ProceduralComplexity.analyze()` - ablation through the real `LaserSystem`
  (no second beam model, no solver): load-bearing special tiles, causal sets
  per target, dependency depth, mechanic interaction pairs, shared resources,
  convergence, padding moves, independent ("plain") rotations, single-route.
- `ProceduralTriviality.evaluate()` - `TRIVIAL_*` reasons.
- `ProceduralLevelGenerator.generate()` additionally returns
  `solution_orientations` and `intended_moves`.
- `scripts/tools/difficulty_inspect.tscn` - dev-only 9-level inspection.

**Why ablation, not graph parsing.** A special tile on the board is not a
dependency; only a tile the solved beam actually needs is. Removing it and
asking the real simulator is exact for that question, adds no rules to
maintain, and costs a few simulations per level.

**Findings (root cause).** See `PROCEDURAL_GENERATION.md` 17.5. Short form:
frozen V1 produces 3-5 move puzzles in Levels 1801-2000 (8%; 1842 and 1897
are 3-move); V2 never enforces its declared move minimum and every template
is one zigzag with at most one special tile, so neither version reaches
the new contract - 99 of a 100-level V2 sample fail it.

**QA +50.** `LevelManager.PROCEDURAL_QA_JUMP_AMOUNT := 50` is now the single
source (previously a private constant in `game.gd`); the label derives from
it; a press at Level 2000 is a true no-op instead of reloading the level.
Never completes/stars/scores a skipped level.

**Rejected alternatives.** (1) Enforcing the contract in generation now via
regenerate-until-accepted or an exhaustive solver loop - slow and does not
create structure the templates cannot express. (2) Counting moves as
difficulty - 20 independent rotations is easy. (3) Counting every mechanic
present on the board - inflates scores for boards where mechanics do not
touch each other.

**Not done on purpose:** no full 1-2000 audit, no template rewrite, no new
mechanics, no star rebalancing, no theme/background/audio change, no APK, no
commit.



## D94

### Difficulty System Phase 2A: Generator V3 dependency-first prototype (`versionCode=49`, `4.1.0-PROCEDURAL-V3-PROTOTYPE-QA`)

**Decision.** V1 and V2 are route/turn-count generators; more turns never
produced dependency depth (D93). V3 inverts the order: a logical
`ProceduralPlanV3` (which mechanics are load-bearing, what enables what) is
built first, then a physical macro-layout, then beam routing, then an
unsolved start state derived from the solved one, then gates. Difficulty comes
from the plan; retries exist only for geometry conflicts.

**Scope.** Prototype only: six reusable archetypes (A-F) that exercise the
construction components; ~8-12 meaningful moves (temporary exception to the
20-26 contract band); V3 is NOT default (`GENERATOR_VERSION` stays 2) and is
reachable only via explicit version 3 or the dev-only "V3 TEST" selector.
V1/V2 output is untouched (deterministic samples re-verified: V1 1897 = 3
moves, V2 500 = 7 moves).

**Key choices.**
- Ablation gates (`ProceduralComplexity` / `ProceduralTriviality`) are now real
  acceptance gates, plus a plan-vs-board load-bearing check, >= 70% meaningful
  moves, >= 2 branches, and a cap of 12 moves.
- Limited plain moves allowed by policy (<= 30%); the prototypes use none.
- The runtime generator never calls the solver (rule 9). Shortcut proof is a
  dev-time solver comparison on pinned seeds (all six: optimal == intended,
  unique solution). It caught one real shortcut in F (see
  `PROCEDURAL_GENERATION.md` 18.2) that the ablation gates alone did not.
- Mirrors are binary, so a required tile's start orientation is forced (the
  opposite); variety comes from `keep_correct` (0-2 already-right tiles).
- Prism channel colors and cursor directions are derived from PHYSICAL
  directions so the vertical flip can never mislabel a channel.
- On 12 rejected attempts V3 falls back to V2 for that level and reports
  `v3_declined` with the diagnostics.

**Bugs found while building** (fixed): a cap blocker placed on another beam's
path (A); a mirror after the receiver that is not needed - detected as a
padding move by the Phase 1 metric (C); F's cross-branch shortcut (above).

**Not done on purpose:** no full audit, no default rollout, no new mechanics,
no art/theme/audio/star changes, no commit. Next step (Phase 2B) waits for
manual Android feedback.

## D95

### Difficulty System Phase 2A.1: reasoning depth for V3 prototypes D/E/F (`versionCode=50`, `4.1.1-PROCEDURAL-V3-THINKING-QA`)

**Trigger.** Manual Android playtest of all six V3 prototypes: direction
approved, but D/E/F needed more thinking - most required tiles started visibly
wrong, so play reduced to following the beam and rotating what it touched.

**Decision.** Deepen D/E/F by *reasoning depth, not move count* (moves stayed at
8/11/11; D/E/F were 8/11/9 before). A/B/C untouched and re-verified
byte-identical. Prototype count, V3 QA gating, V1/V2, `+50` and all saves are
unchanged.

**Choices and why.**
- *Start state is part of the puzzle.* Route tiles can start already correct
  (explicit `keep_correct` per tile; the planner forces the random 0-2 draw to 0
  for D/E/F), so beams already flow and a wrong-but-purposeful state exists at
  start (D: the Gate looks open because the wrong beam passes the shared
  One-Way and lights the Switch).
- *Each of D/E/F has one globally constrained decision* (see
  `PROCEDURAL_GENERATION.md` 18.7 table): D shared One-Way + a second One-Way to
  PASS; E a colour fork whose wrong side reaches the target through a
  wrong-colour Filter (backward reasoning from the target colour); F a shared
  One-Way whose pass state lights a second required target with the wrong beam.
- *Pass on a second One-Way in D, not on the shared one.* Enumerating every
  `one_way_reflector_is_reflective` case shows a shared cell where one beam
  passes and another reflects forces the two beams to overlap in one corridor
  (pass = opposite arms, reflect = adjacent arms). Rather than accept retracing
  beams, the shared tile stays a reflect-reflect X and PASS is a separate
  single-beam tile. The start state still shows a beam passing the shared one.
- *Ablation blind spots are documented, not hidden.* A pass tile, and a shared X
  tile whose removal lets one beam slide along the other's exit row, cannot be
  seen as load-bearing by `ProceduralComplexity`. Those plan stages are marked
  non-load-bearing; their moves are still checked by the padding test and the
  dev-time solver.
- *Per-archetype acceptance profiles* (`requirements_for`) with two new keys
  (`min_shared_resources`, `min_prerequisite_chains`) instead of loosening the
  shared Phase 2A profile.
- *Cheap structural metrics* (`start_state_visibility`, `greedy_follow_solve`)
  instead of a new solver, per the brief. The greedy proxy is generous and
  proves nothing.

**Bugs found while building (fixed).** D: removing the shared tile let A slide
into B's route (depth stuck at 4) -> added a Portal on B's route. F: (1) Z's
beam continued past its target down the remote route and formed a real cycle
("intended solution loops") -> cap after the target; (2) a receiver placed on
the RED channel's column made the first Portal removable (shortcut) -> moved to
the bottom-left; (3) the first wrong route only produced a worse state than the
solution, so hill-climbing was never trapped -> the wrong route now lights a
second required target. A regex edit hit `_plan_b/_plan_c` by mistake (a
bogus stage/edges) - caught by re-running the A/B/C diff before trusting it.

**Result.** All three: solver optimal == intended, unique, no shortcut, on the
pinned seeds and 12+ further seeds; no triviality flags; validator clean;
8 columns. **Not fixed / honest:** the greedy beam-follower still solves F (the
T_w trap only bites if the remote is powered before Z is routed); `plain%` is
0 for all six but generous; `obvious_wrong` (1-3) does not separate D/E/F from
A/B/C on its own. F levels 24 and 36 need attempt 1/3 (padding on attempt 0 for
that colour draw) - deterministic, but a Phase 2B input.

**Not done on purpose:** no scaling, no default rollout, no 20-26 bands, no new
mechanics, no art/theme/audio/star change, no commit. Waiting for Android
feedback on D/E/F.


## D96

### Difficulty System Phase 2B: V3 becomes a real progression generator (`versionCode=51`, `4.2.0-PROCEDURAL-V3-PROGRESSION-QA`)

**Trigger.** The user manually tested the six V3 prototypes on Android: the
dependency-first direction is approved, D/E/F "feel significantly more
thinkable". Phase 2B asks to turn the six hardcoded archetypes into a reusable
generator with real progression bands (Levels 1-2000), without a full 1-2000
audit, without new mechanics, and without touching visuals, audio, saves or the
default generator.

**Decision.** Compose puzzles from reusable *atoms* (Filter, Portal, Splitter
branch, Gate with own/splitter/prism/shared-mirror/shared-one-way/two-stage
switch route, Prism, Receiver->Remote hop, One-Way turn/hold, mid-route target)
chosen from per-band pools, lay them out with a generic randomised router - no
hand-placed coordinates - and gate every candidate on the band contract. The six
prototypes stay as permanent QA fixtures (byte-identical, diffed). V3 is selected
for new play by ONE flag (`LevelManager.USE_V3_FOR_PROCEDURAL_QA`, via
`procedural_generator_version_for_new_play()`), never for a resumed puzzle.
Details: `PROCEDURAL_GENERATION.md` section 19.

**Choices and why.**
- *Contract = single source, edited not copied.* `_BANDS` now holds the user's
  production targets plus `max_dependency_depth`; a second table `_V3_POLICY`
  holds meaningful/plain/greedy/keep/plausible per range; boards and mechanic
  availability follow the Phase 2B pools. Interactions get NO ceiling: the metric
  counts kind pairs (0,1,3,6,10...), so "4-5" cannot be met - only floors bind.
  Dependency/depth ceilings bind only Levels <= 200; later they are soft (the
  metric counts convergence/shared resources the plan model cannot pre-count).
- *Recipes are a model, verification is real.* `predict()` (depth = 1 + nodes,
  kinds, deps) only chooses recipes; the built board is always re-measured by the
  ablation metrics. Cores that already break a ceiling are filtered out before
  selection (a first version rejected 28/60 early plans as "no recipe").
- *Move targets are drawn, then made to fit.* Foundation ramps 3 -> 5; Level
  >= 1301 skews low; each layout failure lowers the next target by 2. A 26-move,
  10-unit puzzle needs ~55-60% of an 8x11 board; forcing the top of the window
  produced fallbacks and multi-second builds. Difficulty is depth, not the
  ceiling of the move window.
- *Composer, not templates.* Depth-first router with group-level backtracking and
  restarts (placement time is heavy-tailed: median success a few hundred steps).
  Beams cross perpendicular only. Measured: ~73% layout success per attempt
  regardless of estimated density 45-75%, i.e. failures are dead ends, not
  capacity - hence restarts rather than a bigger budget.
- *Attempt cap 12, 16 from Level 1301.* ~2% of dense plans needed more than 12;
  V2 fallback is reported (`V3_GENERATION_FAILED`, counter, HUD `V3 FAILED>V2`)
  and never counted as V3.
- *Runtime shortcut probe instead of the solver.* The solver is dev-only and
  exponential. A beam search over touched-tile flips (complete for minimal
  solutions) ordered by overlap with the intended beams catches the shortcut shape
  that matters: a stray beam joining a LATER part of the route. Budget 420 sims.
  It is a screen, not a proof.
- *Load-bearing is checked on the built board* (ablation per promised stage) and
  the first filter of a mid-target pattern deliberately sits on the same line as
  that target (or it is not load-bearing).

**Bugs found while building (all fixed; the debugging technique - dump the
rejected board and re-simulate the reverted move - found each one).**
1. *Leaky line ends.* `cap()` treated any tile in front of a beam's end as
   "absorbing"; mirrors, receivers, switches and portals do not absorb, so a stray
   beam powered something else (11 padding moves in one board). A line end must
   leave the board or meet a blocker.
2. *Colour bypass (Level 300: optimal 4 vs intended 11).* A raw prism channel
   colour equalled the filter colour the target needed. Filters now take a colour
   no other beam produces.
3. *Beam through an emitter cell.* A wrong ray passing an emitter/remote cell in
   its own direction continues as that emitter's beam. Sources go on the edge
   facing inward, or get a blocker behind them.
4. *Wrong-ray alignments* (padding and deep shortcuts) - `harden()` blocks a
   hazardous wrong ray at its first free cell; immediate-neighbour hazards
   cannot be blocked, which is why the probe exists.
5. *Probe recall.* Progress-score ordering alone missed two depth-8 shortcuts
   (optimal 8 vs 14/15); overlap-with-intended ordering catches them.
6. Pockets: a straight run that used the last free cell of its ray made the next
   walk impossible (21k failures in one 50-level window) - runs now leave a tail cell.
7. `Array.shuffle()` uses the global RNG (non-deterministic) - a Fisher-Yates on the
   level's own RNG is used everywhere; parse errors hang headless Godot (wrap every
   run in `timeout`).

**Evidence.** Sample of 25 levels across all bands: 25/25 pass independent
re-checks, 0 fallbacks. 286 levels sampled across 3-2000: 0 validator errors, 0
fallbacks. Exhaustive solver on ~357 generated levels (1-260, 401-480, 701-719):
0 shortcuts with the probe on, all intended == optimal; unique shortest solution
in all but two. Probe-off raw shortcut rate ~10% in Hard/Hard+ (5 found, probe
caught 5/5). Solver subset: 1/50/100/500/1000 exact; 1500/1900/2000 UNKNOWN
(state cap), reported as such. Band averages in `PROCEDURAL_GENERATION.md` 19.10
rise monotonically (moves 3.8 -> 20.9, depth 1.7 -> 11.0, interactions 0 -> 17.9);
greedy beam-following solves 0% of puzzles from Level 201 up.

**Honest limits / not done.** (1) Above ~17 rotatable tiles no exact solver
exists; Levels ~1100+ rely on the probe and structural rules. (2) Wrong-colour
decoy forks, reciprocal dependencies and richer shared-decision variants are NOT
implemented (documented as Phase 2C inputs). (3) "Meaningful move" is the ablation
metric and is ~100% for every composed puzzle with a mechanic - it rejects only
pure-route boards; the plain-turn share (construction) is the stricter guard.
(4) Top-band generation is 100-330 ms on the desktop; phone time is unmeasured.
(5) `estimate_tiles` under-counts hardening blockers by ~10%. (6) Early Thinking
(21-50) has only two recipe families under the ceilings (F+P/F+SB, G) - by the
contract, not by choice.

**Not done on purpose:** no full 1-2000 audit, no star thresholds, no new
mechanics, no visual/theme/background/audio/layout change (one QA-only HUD line
`V3 <band>` under the level number), no default rollout, no commit. QA flags
stay ON. Waiting for Android playtest.

## D97

### Global Hint System Phase 1 (`versionCode=52`, `4.2.1-GLOBAL-HINT-QA`)

**Decision.** The shared HUD Hint button (already in `game.tscn`, previously hidden and unwired) now
works in every normal mode. One press reveals ONE required tile with a pulsing cyan ring; the player
still rotates it. Difficulty generation, HUD layout, theme, audio assets untouched.

**Architecture.** `HintManager` (`scripts/gameplay/hint_manager.gd`, plain RefCounted owned by `game.gd` -
not an autoload) + `GridManager.show_hint_cell()/clear_hint_cell()` (a dim-free second
`TutorialHighlight`; the tutorial highlight/dim is untouched). Level data never owns hint state or
positioning. API: `configure(solution)`, `request_hint()`, `grant_hint()`, `get_hint_candidate()`,
`show_hint()`, `clear_hint()`.

**Solution source - never a runtime solver.** Procedural V1/V2/V3 and V3 TEST: the generator's
existing `solution_orientations` (V1/V2 already returned it - no generation change). Handcrafted campaign
levels and tutorials have no solution metadata, so `scripts/tools/hint_solution_builder.tscn` (dev-only)
ran `LevelSolver` OFFLINE once and wrote `levels/hint_solutions.json` ("c<id>", "t<id>": tiles the
shortest solution flips + solved orientation): 160/160 solved (140 campaign + 20 tutorials). A level
with no entry gets Hint hidden + a dev warning. Re-run the tool if a campaign/tutorial level changes.
The stored solution is ONE shortest solution; a player on a different valid route may be told to change a
tile that a different solution would not need (accepted, documented).

**Candidate rule.** Wrong tiles (current != solved) not yet hinted; ranked by (1) tiles a beam touches
now, upstream first (= the frontier of the current dependency stage), (2) otherwise nearest to a lit cell
(tiles behind an unpowered receiver/gate come after live ones), ties by position. Deterministic, 26-134 us.
When all wrong tiles were hinted, history cycles.

**History.** `_shown` (cell -> pending/resolved): a hinted tile the player leaves alone stays excluded; one
that became correct is resolved; one turned back to wrong becomes hintable again. History resets on level
load, Reset, Retry, QA `+50`, Next Level. Continue does NOT restore history (chosen: cheap, hints are
stateless with respect to saves).

**Behaviour.** Ring stays until the hinted tile is rotated, a new hint replaces it, Reset/load, or 6 s;
never blocks input. Sound: existing `sfx_tutorial_step` (no new asset, no reward sound). No hint (solved,
no source, message/locked tutorial step): button dips briefly, no ring, no sound. Requesting a hint changes
no orientation, move count, star, save field, seed or version.

**Tutorials.** REQUIRE_TILE_TAP steps hint their own `target_position`; free-play WAIT_* steps use the table
solution; MESSAGE and `lock_all_input` steps allow no hint. Forced interaction is never bypassed.

**Monetization seam (not integrated).** `request_hint()` only asks `permission_provider` (unset = free);
`grant_hint()` reveals a tile and is the single call a rewarded-ad/purchase/QA path makes later.

**Stars: no hint penalty in this phase - PENDING product decision.**


## D98

### AdMob Foundation V1 (`versionCode=53`, `4.3.0-ADMOB-FOUNDATION-QA`)

Full reference: `ADS_MONETIZATION.md`. **Test ads only.**

**Decision.** Rewarded ad -> one Hint (normal procedural play) and an interstitial after every 4 legitimate procedural
completions (>= 120 s apart), through one `AdManager` autoload over an `AdBackend` seam (AdMob on Android/iOS, fake in tests).
No banners, no app-open, no ads while solving; tutorials, V3 TEST, QA `+50` and campaign QA are ad-free.

**Plugin.** Poing Studios Godot AdMob v5.1.0 (Godot 4.5+, ships a 4.7.1 native bundle, Android+iOS, UMP included), chosen after checking
the release list instead of installing an older line. It needs a Gradle Android build: `use_gradle_build=true`, template in `android/build`
(git-ignored), **JDK 17** (Gradle 8.11.1 rejects the JDK 25 in Android Studio jbr; the editor setting `export/android/java_sdk_path` now points at
a portable Temurin 17). APK ~80 MB -> ~106 MB.

**Choices.** Hint granted only from the reward callback (never open/load/dismiss); no free fallback on ad failure (button dips, reload starts,
retry allowed); the ring timer re-arms after the ad closes; the counter resets only when an interstitial actually shows; not-ready never blocks;
a rewarded ad watched on a level suppresses that level interstitial (counter still counts); the same level is never counted twice in a row; the
interstitial shows at Level Complete -> Next Level; a state machine blocks double shows; the Master bus is muted during ads; all IDs and rule constants
live only in `AdConfig`; persistence is three additive ints; UMP runs every launch and no ad request is made while consent is still REQUIRED; Privacy
Options is an API only (no UI).

**Also fixed:** `_plan_c` read a missing `wrong_color` param (a script error in V3 TEST prototype 3; output identical after the fix).

**Verified vs not.** Fake-backend tests through the real game scene (35 checks) pass; the APK exports with the sample App ID, ads/UMP plugins and permissions.
**Not verified:** real SDK init, real test ads, Java->GDScript callbacks, pause/resume around a real ad (no device here); iOS not built.

## D99

### Fusion Node Phase 1 - runtime, colour fusion, QA puzzles, hint support (`versionCode=54`, `4.4.0-FUSION-NODE-QA`)

**Status: QA ONLY.** Not in procedural V3 / the 1-2000 progression / campaign; no final tutorial (pending user approval after Android testing).

**Rules.** A Fusion Node consumes RED/GREEN/BLUE beams and emits ONE beam of the combined colour from its single OUTPUT side:
RED+GREEN=YELLOW, RED+BLUE=MAGENTA, GREEN+BLUE=CYAN, RED+GREEN+BLUE=WHITE. Inputs are treated as a SET of distinct primaries, so order and
duplicates never matter (`GridTypes.combine_beam_colors`, the only place the table lives). One distinct colour (RED alone, RED+RED, ...), no input,
or a non-primary input (WHITE/YELLOW/MAGENTA/CYAN are NOT valid inputs in Phase 1) -> inactive, no output, no invented same-colour fusion. Three inputs
give one WHITE beam. Every beam that reaches the node TERMINATES there; a beam entering through the OUTPUT side is absorbed (no input). Inputs may come from any of the other three sides.

**Orientation.** 4-state, stored in `tile_orientations` as the OUTPUT `GridTypes.Direction` (UP=0, RIGHT=1, DOWN=2, LEFT=3, the existing convention);
one tap = one clockwise step = one move; `TilePlacement.direction` is the authored output. `LevelData.get_initial_tile_orientations` includes it;
`get_rotatable_tiles` deliberately does NOT (the dev `LevelSolver` is binary-flip only), so Fusion puzzles carry their own solution for hints.

**Data.** `TileType.FUSION` appended; `BeamColor` extended by appending YELLOW, MAGENTA, CYAN (existing values unchanged). Target/Filter/Emitter/Remote work
generically with the new colours; render colours added; a composite beam through a Prism passes straight; Fusion inputs accept only primaries. No save schema change.

**LaserSystem.** Same strategy as gates/receivers: `simulate(..., fusion_states)`; a node whose PREVIOUS pass produced a fused colour emits a beam toward its output side;
each pass collects `fusion_inputs[pos][side][color]`; `simulate_until_stable` REPLACES the state each pass (start inactive), so vanished inputs switch the node off and YELLOW is
superseded by WHITE - no latching, no stale output. Pass cap grows by 3 per node as a backstop. Results add `fusion_colors`, `fusion_input_colors`, `fusion_input_sides`, `fusion_states`.
Boards without Fusion take the identical path as before.

**Visual.** `FusionTile` (`scenes/tiles/fusion.tscn`): `bs_fusion_node.png` inactive / `bs_fusion_node_active.png` active, unmodified; the art is four-way symmetric, so direction is drawn
dynamically (output arrowhead in the fused colour, lit input-port dots). `bs_fusion_icon.png` is imported but unused until the tutorial.

**Hint.** A solved Fusion orientation is a normal hint entry (ring only, no rotation, no move). Normal procedural hints still route through AdManager; Fusion TEST hints are free/ad-free.

**Audio.** No new SFX: inactive -> active reuses `laser_split`, inside the accepted-move gate.

**QA access.** Main Menu "FUSION TEST" -> `GameManager.start_fusion_test()`; "NEXT FUSION" cycles 1-6; `LevelManager.SHOW_FUSION_TEST_QA` (false for production). Contained like V3 TEST
(`game.gd _is_v3_session()`): no save/resume, no stars, no ads, no interstitial counter. Puzzles in `levels/fusion_qa/fusion_qa_set.gd` (1 R+G, 2 R+B with mirror, 3 G+B + CYAN Filter,
4 RGB->WHITE proven by Prism + three colour targets, 5 Prism -> Fusion -> Receiver -> Remote -> Target chain, 6 Portal -> Fusion).

**Verification (headless, focused).** 36 two-input cases, 6 RGB permutations, singles/same-colour/none, output-side entry, termination, one output, upstream dynamics, WHITE supersedes YELLOW,
determinism; six puzzles unsolved-at-start / solvable / validator-clean / all moves needed; ~160 us per stable simulation; 160 campaign+tutorial solutions and 15 dev levels unchanged; prototypes A-F unchanged; 22/22 SFX.

## D100

### Fusion Node Phase 2 - main V3 procedural integration + extensible (post-2000-ready) progression (`versionCode=55`, `4.5.0-FUSION-PROGRESSION-QA`)

**Status: QA build awaiting the user's Android test.** The user manually reviewed the Phase 1 Fusion concept on Android and APPROVED the direction (D99); Fusion now appears in MAIN procedural levels. Fusion runtime rules are FROZEN (R+G=YELLOW, R+B=MAGENTA, G+B=CYAN, RGB=WHITE, inputs terminate, one output, single/same-colour/composite input = inactive). No new mechanic, art, audio, tutorial, HUD/theme, star or AdMob change.

**1. Generator versioning decision.** Fusion changes what a level number generates, so it is a NEW generator version, not a mutation of V3: `ProceduralLevelGenerator.GENERATOR_VERSION_V4 = 4` (= `ProceduralProgressionV3.generate(level, 4)`, `GENERATOR_VERSION_FUSION`). V1/V2/V3 stay frozen: a temporary fingerprint driver hashed the full tile list + solution of 33 levels x V1/V2/V3 (99 pairs, levels 1-2000) before and after the pass and after every later code change - IDENTICAL. New play selects V4 through `LevelManager.USE_FUSION_PROGRESSION_FOR_QA` (only meaningful while `USE_V3_FOR_PROCEDURAL_QA`); a RESUMED puzzle regenerates under its saved version (a saved V3 puzzle regenerates byte-identical as V3, verified end-to-end). `GENERATOR_VERSION` (default) stays 2. V4 has its own seed space (the version is in the seed key). Levels 1-200 of V4 contain no Fusion.

**2. Simulation hardening (Phase 1 concern: WHITE/Prism/Fusion feedback relied on the pass cap).** Analysis: fusion state is replaced each pass, gates/receivers are monotone, a composite colour is never a Fusion input, beams never cancel beams - so a self-sustaining or negative feedback needs a cycle Fusion -> (Prism | Switch->Gate | Receiver->Remote | Filter) -> the same Fusion's input. Chosen rule: PREVENT/REJECT at generation instead of complicating LaserSystem. `ProceduralFusionCheck` (runtime-safe, LaserSystem only) rejects: (a) FEEDBACK - replacing the node with a blocker must leave the set of (side, colour) arrivals at that cell unchanged; (b) a board that does not SETTLE before the pass cap in the start state, the solved state or any one-tile-away neighbour of the solved state (`LaserSystem.simulate_until_stable` now also returns `converged` and `passes`; the pass cap remains a backstop only). Evidence: a hand-built Fusion -> Switch -> Gate -> own-input board settles (4 passes) but is REJECTED as feedback; 60,000 random Fusion/Prism/Filter/Gate/Switch/Receiver/Remote boards: 0 unsettled, max 4 passes; 3,000 random orientation states of 25 generated Fusion levels: 0 unsettled. The same board state always settles to the same result (pure function of the board, fixed pass order).

**3. Fusion fragments** (`ProceduralFragmentsV3`, recipes in `FUSION_RECIPES`; the ONE unlock table is `ProceduralDifficultyContract._FUSION_PROGRESSION` / `fusion_policy()`): F1 basic 2-colour (atom FU); F2 filter-made inputs (FUF: WHITE emitters + a Filter on every input path); F3 portal on one input path (FUP); F4 Fusion -> Switch -> Gate on the main route (FUG); F5 Fusion -> Receiver -> Remote (FU + H); F6 Prism channels feed the Fusion (PF); F7 R+G+B -> WHITE -> Prism -> colour-specific targets (FU3 + PR). DEVIATION from the brief, deliberate: a "matching composite Filter AFTER the node" cannot exist - a Filter recolours (never gates), so it would erase the fused colour and the node would fail the colour-relevance rule - F2 therefore puts the filters on the input paths (each is load-bearing: a WHITE beam is not a valid input). One-Way is compatible on the output line (F1/F3/F4... recipes with OW) and on other atoms; a dedicated One-Way-on-an-input-path fragment was not built.

**4. Unlock progression + frequency.** 1-200 none; 201-400 F1 (10%); 401-700 F1-F3 (20%); 701-1000 F1-F4 (24%); 1001-1300 F2-F5 (26%); 1301-1600 F2-F6 (28%); 1601-1800 F2-F7 (28%); 1801-2000 F1-F7 (28%). The yes/no + fragment roll is made ONCE per level from a dedicated rng stream (`FUSION_ROLL_STREAM`), never re-rolled per attempt (a first version re-rolled and silently halved late-band frequency); the rolled recipe is tried for the first 6 attempts (8 from 1301), then the level falls back to an ordinary recipe (not to V2). Realised share (stride-4 sample, final generator): 201-400 14% (7/50), 401-700 23% (17/75), 701-1000 17% (13/75), 1001-1300 16% (12/75), 1301-1600 27% (20/75), 1601-1800 28% (14/50), 1801-2000 20% (10/50); every fragment appears in its bands; nothing near "most levels". V4 also gets 16 attempts from Level 1001 (V3 keeps 12) after a non-Fusion level (1015) exhausted 12.

**5. Construction (not decoration).** Composer tokens `fusion` (a straight element that ENDS the line, needs one empty cell before it) and `fjoin` (a goal-directed walk that ends on one of the node's free input sides, distance >= 2). The OUTPUT line is built when the LAST input has joined (the fused colour is then known). The node always starts exactly ONE clockwise tap from solved (`Cursor.to_fusion`; computed in physical directions), so every generated node costs exactly one honest move; mirrors upstream keep the usual keep-correct share; the downstream chain stays behind the node. Wrong-direction hardening extends `harden()` to the node's three other output rays (a blocker on the first free cell); an UNREPAIRABLE ray (a tile directly adjacent) rejects the candidate - an exact search found a target reachable that way.

**6. Load-bearing / colour-bypass rules (all checked on the BUILT board):** the Fusion tile is a special ablation unit in `ProceduralComplexity` (removing it must lose a target; it feeds depth/kinds/interactions/`fusion_dependency_count` only when it really is load-bearing); EVERY input path is required (a blocker is placed on the cell next to the node on that side and must remove exactly that colour - 2-input nodes need both, the 3-input node needs R, G and B); the fused colour must be consumed (a target of exactly that composite colour, or a Switch/Receiver/Prism; a WHITE output needs a Prism because a WHITE target accepts anything); no required WHITE target may depend on a Fusion output; remote emitters on Fusion boards carry an explicit non-WHITE colour (`_can_add` allows only 3 - inputs hops so a colour is always unobtainable elsewhere); composite targets cannot be satisfied by raw primaries or WHITE. `analyze`, greedy and the shortcut probe understand 4-state tiles (`ProceduralComplexity.tap_orientation`).

**7. Shortcut / exactness study (dev-only `scripts/tools/fusion_verify.tscn`, `fusion_progression_sample.tscn`).** `LevelSolver` is binary-flip only, so `fusion_verify` runs its own EXHAUSTIVE search over every orientation (Fusion 4-state) where the space fits (<= 140k states): **PROVEN OPTIMAL with a unique shortest solution for every checked level** (19 in the final run across F1-F5 at Levels 203-778, 22+ over the pass); it found and led to the fix of one REAL shortcut (Level 413: a wrong Fusion direction reached the adjacent target). Levels 1001+ exceed the exact range: they are reported "STRUCTURALLY VALID / PROBE PASSED", never "proven". A wide probe (4000 simulations) on late Fusion levels: before the fix 4/36 (11%) had a cheaper alternate solution (plain V3 ~4%); the runtime probe for Fusion boards was widened to 1500 simulations / width 28 (plain boards keep 420/12); final wide-probe study of 42 late Fusion levels (F2-F7): 1 shortcut (2.4%, missed by the runtime budget). Bypass (Fusion removed), omitted input, Prism removed, WHITE target/remote checks: 0 failures. Greedy beam-following solved 0 of the sampled Fusion levels.

**8. Hint / ads / save.** A generated Fusion level exposes `solution_orientations` (the node's output Direction included); one Hint = one tile (the node when only it is wrong - verified); normal procedural Hint still goes through the rewarded ad (fake backend: reward -> one hint, no reward -> none); a completed generated Fusion level counts as ONE legitimate interstitial completion; FUSION TEST / V3 TEST / QA +50 stay ad-free and save-free. Continue restores level number, generator version 4, the identical board, every orientation (Fusion included) and the move count (temporary end-to-end driver, 28/28). No AdMob change.

**9. Level 2000 is the initial CERTIFICATION target, NOT a permanent architectural ceiling.** New `ProceduralLevelGenerator.INITIAL_CERTIFIED_LEVEL_TARGET = 2000`; `MAX_LEVEL` (what PLAY/Continue/QA jump expose) is defined from it and unchanged (QA +50: 1951 -> 2000, 2000 -> no-op, verified). `ProceduralDifficultyContract` no longer clamps a level to 2000: a level beyond the last band/policy row reads the LAST row (verified: V4 generates 2001, 2002, 2100, 2500, 3001, 4000, 5000, 10000, 99999 without failure, 0 fallbacks) - post-2000 is a data extension (new contract rows, new atoms, a new generator version if existing output must change), never a generator rewrite. NOTHING beyond 2000 is exposed to players in this pass.

**10. Post-2000 direction (documented, NOT hard-coded as bands):** difficulty keeps coming from combinations of EXISTING mechanics and deeper interactions (illustrative ranges only: 2001-2500 more Fusion + Prism + Filter; 2501-3000 Fusion + Portal + Switch/Gate; 3001-3500 Fusion + Receiver/Remote + One-Way; 3501-4000 multi-branch convergence, shared resources, delayed dependencies; 4001+ deeper combinations) - dependency depth, shared resources, convergence, backward reasoning, delayed effects, colour dependencies, target continuation, reciprocal dependencies, plausible near-solutions; NEVER smaller tiles, more than 8 columns (`MAX_COLUMNS` stays 8), giant boards, meaningless rotations or move padding. Difficulty cannot escalate forever: beyond the certified range it should sit in a curated high-difficulty ENVELOPE (varied combinations/topologies/colour dependencies) without every later level being strictly harder than every earlier one.

**11. RELEASE BLOCKER: a proper player-facing Fusion tutorial** (uses `bs_fusion_icon.png`) must exist before a production build lets Fusion appear (Level 201+). For this QA build Fusion appears from the configured bands without one. `USE_FUSION_PROGRESSION_FOR_QA`, `SHOW_FUSION_TEST_QA`, `USE_V3_FOR_PROCEDURAL_QA`, `SHOW_PROCEDURAL_QA_NEXT_BUTTON` are QA flags reviewed before release.

**12. Known limits.** Generation time grows with the extra checks (desktop headless: typical Fusion level 50-300 ms, worst sampled ~650 ms (F7 Level 1601), the probe dominates; Android time unmeasured - `FUSION_PROBE_SIMS`/`FUSION_ATTEMPTS` are the knobs). Runtime shortcut screening is a screen, not a proof (~2-4% of late Fusion levels may have a cheaper alternate solution, same class as plain V3). Composite colours are still not Fusion inputs (no chained fusion). The ARCHITECTURE.md file was accidentally deleted by a PowerShell alias (`Rd` = Remove-Item) in Phase 1 and reconstructed from the last complete copy + the saved Hint/AdMob/Fusion sections (git diff vs HEAD: 213 insertions, 0 deletions); stale statements (autoload list, "inert" hint button) were corrected in this pass. Never name a PowerShell helper `Rd`/`Ri`/`Rm`/`Cp`.

## D101

**Fusion Node Phase 3 - production integration: player tutorial T21-T28, generator variants, shortcut hardening (`versionCode=56`, `4.6.0-FUSION-FULL-QA`).**

The user manually approved Fusion (concept, runtime, visuals, main V4 progression, difficulty interaction) after Android testing of `versionCode=55`. Fusion is now a **production-supported mechanic**. QA flags stay ON for this build (production clean-up is a later pass). Nothing beyond Level 2000 is exposed; no new mechanic; no chained Fusion; ad rules, ids and the star economy are untouched.

**1. Tutorial pack T21-T28 (`levels/tutorial/t21.gd` - `t28.gd`, registered in `LevelManager.TUTORIAL_LEVEL_PATHS`).** Same engine, same `TutorialManager`, same step types as T01-T20 (no new framework, no tutorial-only mechanic - rules 1-5 and "Guided tutorial rules"). One idea per tutorial: T21 "Fusion Node" (RED+GREEN=YELLOW, one tap), T22 "Output Side" (output direction; three forced taps DOWN->LEFT->UP->RIGHT walk through the two input sides, each of which switches the node off), T23 "Color Recipes" (RED+BLUE=MAGENTA then GREEN+BLUE=CYAN, two nodes), T24 "Three Colors" (RGB=WHITE; a Prism proves the WHITE because a WHITE target accepts any beam), T25 "Fusion Filter" (WHITE emitters + GREEN/BLUE Filters on the INPUT paths - a Filter after a node would repaint its colour; this replaces the brief's "CYAN Filter after the node" example, which would be a no-op), T26 "Fusion Portal" (mirror -> portal pair -> node; two taps), T27 "Fusion Relay" (node -> Receiver -> Remote Emitter -> mirror -> target; two taps), T28 "Fusion Trial" (free play: Filter + Portal + Fusion + Receiver/Remote + Gate opened by an independent Switch; three required taps, one message + one `wait_for_solved`). Display names are <= 13 characters because the HUD title truncates longer ones.
*Verification (AUTOMATED, real `LaserSystem`):* every board has exactly ONE solution over all orientation combinations, none starts solved, the hand-authored `hint_solutions.json` entries equal that unique solution; a real-game-scene replay (real autoloads) drives every step of all 28 tutorials: MESSAGE steps lock input, wrong-tile taps are rejected, the Hint candidate equals the forced tile, completion is recorded, the popup shows, Reset restores step 0 and the authored orientations, `_interstitial_eligible_session()` is false. RENDERED: T24/T28 screenshots and Tutorial Select (28 cards, unified blue theme) checked at 540x960.
*Hint:* `hint_solutions.json` gained `t21`-`t28` (Fusion values are `Direction` 0-3, mirrors 0/1). `hint_solution_builder.gd` now SKIPS tutorial ids >= `LevelManager.FUSION_TUTORIAL_FIRST` because `LevelSolver` is binary-flip only and would erase them. Forced (`REQUIRE_TILE_TAP`) steps still expose their own tile; free steps use the table; message steps allow no hint (never bypasses a step). Tutorials stay ad-free.
*No mechanic icon:* the tutorial panel has no icon support, so `bs_fusion_icon.png` is not used (no new UI was invented for it); reported, not silently skipped.

**2. Production unlock behaviour.** T21-T28 are NOT era-gated (`get_era_for_tutorial(21)` reads "Era 3", which would have required Campaign Level 200): `LevelManager.is_tutorial_level_selectable()` routes ids `FUSION_TUTORIAL_FIRST..LAST` (21-28) to `is_fusion_tutorial_selectable()`: T21 opens when the player's real `SaveManager.procedural_current_level >= FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL` (150) or `tutorial_highest_unlocked_level >= 21`; T22-T28 unlock sequentially; `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` opens all. The pack is therefore AVAILABLE ~50 levels before the first Fusion roll (Level 201) but never a hard gate: no procedural level is ever locked behind it (no mandatory-tutorial mechanism exists in the tutorial system, and adding one would be a confusing lock). T28's closing text tells the player Fusion will now appear in the main levels. No first-launch nudge was added (deliberate; recommended as a future small pass if Android feedback shows players reaching 201 untaught).

**3. Fusion frequency (`ProceduralDifficultyContract._FUSION_PROGRESSION` unchanged).** Root cause of the earlier under-realisation (D100: 14-28%, 1001-1300 as low as 7-16%): `ProceduralComplexity` ablated a Fusion by DELETING the tile, which lets its raw input beams run straight on through the empty cell into a collinear Switch/Receiver - a counterfactual no rotation can ever produce - so valid boards were rejected as "fusion not load-bearing". The load-bearing ablation now replaces a Fusion with a BLOCKER (absorbs beams, emits nothing). Effect on rolled recipes actually placed: 701-1000 16/20 -> 20/20, 1001-1300 12/17 -> 15/17. Realised shares (stride-4 samples, 50-75 levels/band): 201-400 14%, 401-700 23%, 701-1000 27%, 1001-1300 20%, 1301-1600 31%, 1601-1800 34%, 1801-2000 22% (targets 10-15 / 15-25 / 20-30 / 20-30 / 20-35 / 20-35 / 20-35). No table nudge was needed. Fusion stays one mechanic among many (every Fusion level also carries the band's other mechanics).
*Correctness of the relaxation:* `fusion_verify` now counts the DEAD-node ablation and prints the empty-cell one as info. 30 generated levels in 201-400 / 401-700 / 701-1000 (<= 65,536 states) are all PROVEN OPTIMAL with `shortest_solutions=1` and optimal == intended, including 9 levels whose empty-cell counterfactual does solve (so that counterfactual was a false alarm, not an exploit). 1001+ is beyond exhaustive reach: STRUCTURALLY VALID / PROBE PASSED, never "proven".

**4. Fragment variants (generator-driven only; no handwritten levels).** `FUSION_RECIPE_VARIANTS` (drawn once in `roll_fusion_recipe` AFTER the fragment draw, so the yes/no + fragment stream is unchanged) and atom-level draws recorded in `plan.params["fusion_variant"]` and returned as `fusion_variant`: F1 colour pair is the level rng's shuffled primaries (all three pairs observed: R+G->YELLOW, R+B->MAGENTA, G+B->CYAN); F3 `portal` (input B) / `portal_a` (the node's own route) / `portal_out` (the fused output route); F4 `chain` (Fusion -> Switch -> Gate, atom `FUG`) / `gate` (a Switch opens a Gate on a prerequisite path, new atom `FUK`, ordered like FU because the node must sit on the root route); F5 `remote` / `remote_gate` (recipe FU+H+G); F6 `prism_both` / `prism_one` (the Prism's straight RED channel + one GREEN/BLUE emitter); F7 `plain` / `portal` (the second input crosses a Portal). `fusion_fragment_of` labels the ROLLED recipe (escalation may add a Receiver to an F1 node; that no longer relabels it F5). NOT implemented: F7 "Prism + separate third colour source" (needs a second Prism, `_can_add` allows one) and F5 "Remote output feeds a Filter" (every primary is already consumed by the node/remote, so a Filter colour would have to be composite or duplicate a beam colour - a bypass). Reported honestly as partial coverage.

**5. Shortcut/bypass screens (`ProceduralFusionCheck`).** New exact screens on the solved board's one-tap-away neighbourhood: the node turned to ANY other direction (direct hit from a wrong orientation, missing input, an input side turned into the output = "output-side input") and any other single rotatable flip must NOT solve the board (a flip that still solves = that tile/route/Gate/Prism-channel/Remote is bypassed); no Emitter/Remote Emitter may be composite-coloured (composite colours only come from a node = alternate composite route); plus the existing per-input cut, WHITE target/remote guards, colour-consumption, no-feedback and settling checks. Multi-flip bypasses remain the runtime probe's job (`FUSION_PROBE_SIMS` 1500 / width 28). `fusion_report["max_passes"]` (settling passes) is reported.

**6. Simulation stability.** 540 consecutive levels (six 90-level windows starting 401/701/1001/1301/1601/1801): 141 Fusion levels, 0 problems, 0 fallbacks; every start/solved/one-tap-away board settles before the pass cap (max settling passes 3-4). Greedy beam-follow: 0 greedy-solvable Fusion levels in every band (policy `prefer_reject` 201-700, `reject` 701+ unchanged).

**7. Compatibility.** V1/V2/V3 fingerprints (tiles + solution hash over 38 levels x 3 versions) IDENTICAL before/after; V4 differs only for Fusion-rolled levels (401, 1001, 1300, 1601 in the sample) - allowed because no V4 puzzle has shipped (after a release any such change needs a new generator version). Save/Continue on a generated Fusion level (Level 401, F3/portal_a, V4): Fusion tapped twice + upstream mirror once, exit, CONTINUE -> identical board, orientations (Fusion included), move count 3, `procedural_resume_generator_version` 4. Hint reveals one solution tile, ring only (orientations and moves unchanged). Ads: eligible in normal procedural Fusion play, not in tutorials, not in FUSION TEST (`_is_v3_session()`); AdMob code/ids untouched. Regression: all 140 campaign hint-table solutions still solve, 15 dev levels solver `optimal_moves` unchanged, T01-T20 replay still passes. Star metadata exposed per Fusion result: `intended_moves`, `verified_optimal_moves` (-1 = not solver-verified), `target_move_range`, `difficulty_band`, `generator_version`, `fusion_fragment`, `fusion_variant`; no Fusion-specific star logic.

**8. Post-2000 readiness.** Nothing in the fragment/contract code caps at 2000: `fusion_policy()` reads the last table row past 2000 (dev-only check: 60 levels from 2001 generated, 15 with Fusion, 0 problems, 0 fallbacks). `INITIAL_CERTIFIED_LEVEL_TARGET = 2000` / `MAX_LEVEL` and every clamp in `GameManager` are unchanged; QA +50 still clamps to 2000. Documented future direction (NOT built): combinations of existing mechanics (Fusion + Prism + Filter, + Portal + Gate, + Receiver + Remote, + One-Way + Portal, three-colour + Receiver, shared-resource and reciprocal systems, multiple Fusion prerequisites); chained Fusion (output -> second Fusion) stays a future mechanic extension needing an explicit request (composite colours are output-only today).

**9. Known issues / limits.** Generation time rose slightly with the extra screens (desktop headless: most Fusion levels 25-300 ms, worst sampled ~780 ms at Level 1950; Android unmeasured - watch load time on device). The temporary "TUTORIAL QA" debug overlay from the tutorial QA rounds is still present in QA builds. Fusion tutorial has no mechanic icon (see above). Tutorial Select shows T21-T28 with the standard cards (no separate "Fusion" header).

## D102

**Phase 4 - production cleanup: centralized star scoring, Hint cap, central QA/production switch, Fusion tutorial polish + nudge (`versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`).** No new mechanic, art, audio, HUD move, AdMob change or content beyond Level 2000. QA mode stays ON in this build.

**1. Star rule V1 - `StarScoring` (`scripts/managers/star_scoring.gd`, `class_name`, static, not an autoload).** OPTIMAL = `authoritative_optimal(level, result)`: (1) `verified_optimal_moves` if >= 0, (2) `intended_moves` if > 0, (3) the level's own legacy `optimal_moves`. `moves <= OPTIMAL+2` -> 3 stars, `<= OPTIMAL+6` -> 2, else 1 (never 0). Fewer moves than OPTIMAL: 3 stars + a `push_warning` (stale metadata / unverified intended / shorter solution) - the player is never punished. One rule for every population (procedural, campaign, dev levels, editor playtest preview); no per-band formula, no thresholds inside level data. `LevelManager.calculate_stars/calculate_campaign_stars(id, moves, hint_used)` delegate to it; `TWO_STAR_MOVE_MARGIN` is now an alias. **Behaviour change vs the old rule:** the old 2-star band was OPTIMAL+1..+2; it is now +3..+6, and 3 stars now tolerates +2 (old: exact optimum only).

**2. Hint cap.** A gameplay Hint that was GRANTED and shown caps the attempt at 2 stars (never lowers a 1-star result). `game.gd._hint_used_this_attempt` is set only by `HintManager.hint_shown` (i.e. reward earned or free grant) via `_on_hint_granted()`; NOT set by: a request whose ad closed without reward or that returned no candidate, tutorials (T01-T28 have no stars), V3/FUSION TEST sessions, editor playtest. Reset by every `_load_current_level()`; persisted per attempt (`SaveManager.procedural_resume_hint_used` / `campaign_resume_hint_used`, additive fields, old saves = false) so quit + CONTINUE cannot regain 3-star eligibility; restored on resume; cleared by `start_*_resume()` (fresh level, Reset, Next, QA +50). QA Level Select campaign sessions keep the flag in memory only (they never write resume state).

**3. Star records.** Procedural: `SaveManager.procedural_best_stars`, a sparse dictionary keyed `"<level>|<generator_version>"` -> best 1..3 (`record_procedural_stars` only raises it; `get_procedural_best_stars`). Identity = level number + generator version (the seed is derived from exactly that pair, so a V2 Level 500 can never score a V4 Level 500). Campaign keeps its existing `campaign_best_stars_per_level` (already best-only). The popup always shows the CURRENT run's stars; the stored best never decreases. V3/FUSION TEST: no stars row, nothing recorded. QA +50 never records anything.

**4. Level Complete popup.** Existing star art wired to the real result; new small `HintUsedLabel` ("HINT USED", existing theme font, no art) shown when the Hint capped the attempt; `show_result(..., hint_used, show_stars)`. Best Moves row unchanged (campaign only).

**5. Central QA/production switch - `BuildConfig` (`scripts/managers/build_config.gd`).** `IS_PRODUCTION_BUILD` (false in this build) -> `QA_TOOLS`. LevelManager's `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`, `SHOW_PROCEDURAL_QA_NEXT_BUTTON`, `SHOW_V3_PROTOTYPE_QA`, `SHOW_FUSION_TEST_QA`, `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` all derive from it; `game.gd` hides the tutorial debug overlay and the "V4 <band> F#" / "FAILED>V2" tag behind it. One constant hides +50, V3 TEST/NEXT V3, FUSION TEST/NEXT FUSION, QA Level Select, the tutorial overlay, the generator tag and both unlock-all shortcuts; nothing is deleted. NOT covered (separate release items): Google TEST ad ids (`AdConfig.PRODUCTION_IDS`) and the generator rollout switches `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA` (gameplay decisions about which generator version NEW play uses, not UI). *Production simulation (AUTOMATED):* with the constant flipped to true and back, Main Menu showed only CONTINUE/PLAY/TUTORIAL/SETTINGS/QUIT, `+50` hidden, level label `LEVEL 401` (no tag), tutorial overlay hidden, T20/T21 not selectable; QA mode showed all tools.

**6. Fusion tutorial polish.** T21-T28 step texts shortened to one idea per step (no board/step changes; all boards still have exactly one solution). `bs_fusion_icon.png` stays UNUSED: the tutorial panel has no icon support and adding it would touch T01-T20's panel - not forced. The tutorial debug overlay is QA-only via `BuildConfig`. **Nudge:** `LevelManager.should_show_fusion_tutorial_nudge()` (not yet seen, T21 not completed, and QA build OR procedural progress >= 150 OR T21 unlocked); `main_menu.gd` builds a small top banner "NEW TUTORIAL: FUSION" + VIEW (-> Tutorial Select) + X from the shared theme, marks `SaveManager.fusion_tutorial_nudge_seen` the moment it is shown (additive field) so it never repeats; non-blocking, never forces the tutorial, never locks progression. Timing unchanged: Fusion first rolls at 201, the pack opens at 150.

**7. Verification (AUTOMATED, real autoloads + game scene).** Star matrix (OPT 5/10/20 incl. hint and below-optimal) all pass; V4 Levels 1/50/100/201/401/500/1000/1601/1900/2000: optimal solve = 3, hint = 2, +7 moves = 1, best preserved at 3, V2 identity separate; `verified_optimal_moves` is -1 for every generated level today so `intended_moves` is the effective source. All 140 campaign levels: OPT/+2 = 3, +3/+6 = 2, +7 = 1, hint cap 2 (table-tile counts equal declared optimal for all 140 - no mismatch found). Generated Fusion Level 401 (V4, F3): ad closed without reward -> no flag; granted Hint -> flag + saved; two Fusion taps; exit; CONTINUE restored orientations (Fusion), moves 2, flag, generator version 4; optimal solve = 2 stars + "HINT USED", best 2; Reset -> flag false (memory + save); optimal solve = 3 stars, best 3; a worse replay leaves best 3; interstitial counter +1 for the legitimate completion; FUSION TEST: hint not counted, no star row, nothing recorded; tutorial hint not counted; QA +50 moves only the resume pointer, records nothing, resets the flag; T21-T28 replay completes, ad-free; nudge shows once and persists. Campaign QA-Level-Select-style session: hint counted, hinted solve <= 2 stars. Not run: full 1-2000 audit, real device.

**8. Known issues / blockers for production.** `verified_optimal_moves` is not populated by any generator path (dev-time solver cannot verify late levels; stars use `intended_moves`; a shorter real solution would show as the below-optimal warning). Star thresholds V1 are initial (tunable after Android feedback). Remaining production items: `BuildConfig.IS_PRODUCTION_BUILD := true`, real AdMob ids/consent review, decision on generator rollout flags, Android load-time check of dense Fusion levels, no legacy `best moves` for procedural (row hidden). Level 2000 stays the certification target; nothing beyond exposed.

## D103 - HUD edge spacing (`versionCode=58`, `4.7.1-HUD-EDGE-QA`)

The gameplay HUD art has ~20% TRANSPARENT padding above/below its visible plates (`bs_hud_top_portrait.png` top pad 153/745 px, `bs_hud_bottom_portrait.png` bottom pad 149/744), so the visible plates sat ~80 canvas px inside the screen edge even with the 8 px margin. Fix (one centralized rule, no per-level offsets, no art/button/font resize): `game.gd._update_hud_edge_overhang()` feeds `bar_height * UIConstants.HUD_TOP_ART_PAD_FRACTION (0.2054)` / `HUD_BOTTOM_ART_PAD_FRACTION (0.2003)` to `SafeAreaMargin.set_hud_overhang()`, which sets the vertical margins to `safe inset + GAMEPLAY_VERTICAL_MARGIN (8) - overhang` (may be negative: only transparent art hangs past the margin; real Android insets are ADDED, not maxed, and never disabled). Menus are untouched (overhang 0 = old behaviour). Result at canvas 1080x1920 and 1080x2400: top plate gap 81.6 -> 8.6 px, bottom 79.8 -> 8.8 px (canvas px); the board gained ~146 canvas px of height (L401 cell 113 -> 128, T28 126 -> 142; width-bound boards unchanged); MAX_COLUMNS/square cells untouched. 9:16 devices all share canvas 1080x1920 (540x960, 720x1280, 1080x1920, 1440x2560 render identically; only 540x960 and a 20:9 window could be rendered here - the OS caps window height). Also moved the QA-only tutorial debug label below the HUD (`anchor_top` 0.02 -> 0.13) so it no longer covers the level name. Re-measure the two fractions if the HUD art is ever replaced. Not verified: real notch/gesture insets on a device (logic only), Era 2 HUD art (inactive under the unified theme).

## D104 - HUD final position (`versionCode=59`, `4.7.2-HUD-FINAL-POSITION-QA`)

Android feedback on D103: bottom HUD too close to the physical edge, top HUD could go higher. The single shared gap became two ASYMMETRIC centralized constants in `UIConstants`: `GAMEPLAY_TOP_VISIBLE_GAP := 3.0` and `GAMEPLAY_BOTTOM_VISIBLE_GAP := 20.0` (canvas px, added to real Android insets by `SafeAreaMargin` in HUD-overhang mode; `GAMEPLAY_VERTICAL_MARGIN` no longer positions the HUD). The art-padding fractions (0.2054 / 0.2003) are unchanged and are not tuning knobs. Measured (canvas 1080x1920 and 1080x2400): top 8.6 -> 3.6, bottom 8.8 -> 20.8; Level 401 cell 128 -> 127, T28 142 -> 141 (board recomputed by the normal layout). T21/T28 clean.

## D105 - HUD symmetric gap (`versionCode=60`, `4.7.3-HUD-SYMMETRIC-GAP-QA`)

Permanent rule: the top and bottom gameplay HUD visible plates keep approximately EQUAL visual spacing from their safe-area edges. Bottom placement (approved) untouched; `UIConstants.GAMEPLAY_TOP_VISIBLE_GAP` 3.0 -> 20.0 (`GAMEPLAY_BOTTOM_VISIBLE_GAP` stays 20.0). Measured on visible plate edges: top 20.6, bottom 20.8 canvas px (was 3.6 / 20.8); bottom bar y unchanged (1613 at canvas 1920). Level 401 cell 127 -> 125, T28 141 -> 139.

## D106 - whole gameplay stack shift (`versionCode=61`, `4.7.4-GAMEPLAY-STACK-CENTER-QA`)

Real-device feedback: equal Top/Bottom HUD gaps (D105) still looked low on the phone. No screenshot reached this session, so the fix is derived from the geometry, not measured: the D103-D105 gaps are measured FROM the safe edges, so any Android inset asymmetry (status bar/cutout larger than the gesture bar) makes the top PHYSICAL gap larger than the bottom one. `SafeAreaMargin` now translates the whole HUD/board/HUD stack as one unit (top margin -shift, bottom margin +shift; stack height and internal spacing unchanged): `shift = clamp(-GAMEPLAY_STACK_VERTICAL_OFFSET + (physical top gap - physical bottom gap)/2, 0, GAMEPLAY_TOP_VISIBLE_GAP)`, so the HUD can never rise above the safe edge. `UIConstants.GAMEPLAY_STACK_VERTICAL_OFFSET := -8.0` (canvas px, negative = up; conservative bias). Desktop render (no insets): top gap 20.6 -> 12.6, bottom 20.8 -> 28.8, board moved up 8 px, cell sizes unchanged (125/139/200). Android insets are unmeasured: expect an extra automatic shift up to 20 px if the top inset exceeds the bottom. Tune the constant from a real screenshot.

## D107 - NEW GAME flow (`versionCode=66`, `4.8.0-NEW-GAME-FLOW-QA`)

Main Menu `PLAY` became `NEW GAME` (node still `PlayButton`); CONTINUE unchanged. **Permanent rule: NEW GAME immediately starts on a fresh/no-progress save. If meaningful main progress exists, it requires explicit confirmation before resetting the main run.** `SaveManager.has_meaningful_main_progress()`: `procedural_current_level > 1`, any `procedural_best_stars`, or a resumable board that is past Level 1 / has >= 1 move / Hint used (NOT "a save file exists": a fresh install and settings-only saves are not meaningful; a just-started Level 1 with 0 moves is not either). Meaningful -> in-code popup (main_menu.gd, blue theme, no art): "START NEW GAME?" / "Your current game progress will be reset and you'll start again from Level 1. This cannot be undone." / CANCEL, START NEW GAME. Dim layer swallows outside taps (never a confirm); Android Back on the popup = CANCEL; `_busy` + disabled button block double taps; pressing NEW GAME alone erases nothing. Confirm -> `GameManager.start_new_game()` -> `SaveManager.reset_main_progress_for_new_game()` (one function, one save, snapshot restored and menu kept if the write fails) -> Level 1 via the normal new-play generator rule (`procedural_generator_version_for_new_play()`, never the old resume's version). **Resets:** `procedural_current_level`, all `procedural_resume_*` (level, seed, generator version, orientations, moves, hint-used), `procedural_best_stars`, `ad_last_counted_level`. **Preserves:** sound/music, all tutorial progress (completed tutorials stay; a T21 unlock earned by reaching procedural Level 150 is written into `tutorial_highest_unlocked_level` first), `fusion_tutorial_nudge_seen`, legacy campaign/dev-level fields (QA population), V3/FUSION TEST (never save-backed), the interstitial cadence (`ad_completions_since_interstitial`, `ad_last_interstitial_unix`: resetting them would let New Game dodge ads), consent/SDK state (not in the save). `save_game()` now returns bool. Verified (AUTOMATED, real menu/game scenes): fresh save, settings-only, cancel (save identical), Back = cancel, confirm, double-tap, Continue after reset (exact Level 1 board + 1 move), Hint flag false, tutorials/sound/ad cadence preserved, new run earns stars, T21 unlock materialised; production simulation menu = CONTINUE / NEW GAME / TUTORIAL / SETTINGS / QUIT. The Tutorial Complete popup's "PLAY" still resumes current progress (unchanged). Not tested on a device.


## D108 - Splitter Selector, Phase S1 (mechanic runtime + QA pack; NOT committed, no version bump yet)

- **Rule** (`LaserSystem`, one place): `TileType.SPLITTER_SELECTOR` (appended to the enum). One beam in, exactly ONE beam out through the selected output side, same pass, colour unchanged, never latched. A beam entering THROUGH the output side is absorbed. 4 states = the output `Direction` in `tile_orientations`; one tap = one clockwise step (same path as Fusion: `TilePlacement.direction` initial, `LevelData.get_initial_tile_orientations()`, `GridManager` 4-state tap). Result gains `selector_hits` (pos -> colours routed) for the view only.
- **Visual**: `SplitterSelectorTile` rotates the supplied art (centre triangle points UP in the source) by the output direction; `_active` art + a beam-coloured output arrowhead while a beam is routed. Hint/save/continue needed no code (generic orientation compare / int serialisation).
- **Audio**: rotation reuses `play_mirror_rotate()` (shared accepted-tap path); locked tile reuses `play_mirror_locked()`. No new SFX, no state-transition sound.
- **QA pack**: `levels/selector_qa/selector_qa_set.gd` (S1-S6), Main Menu "SELECTOR TEST" / "NEXT SELECTOR" (`LevelManager.SHOW_SELECTOR_TEST_QA` = `BuildConfig.QA_TOOLS`), contained exactly like FUSION TEST (`GameManager.is_selector_test_mode`, `game.gd _is_selector_session()`).
- **Verification**: `scripts/tools/selector_verify.tscn` (exhaustive over every orientation combination; unique solution; min taps == authored; selector as dead blocker / removed loses the level; orientation changes routing; stateless). `LevelSolver` is binary-flip only and cannot model this tile (same as Fusion).
- **Lesson**: a selector on a straight line with input and output collinear is bypassed by simply *removing* it (S5's first draft) - the selector must TURN the beam for the removal test to be meaningful.
- **Not done (later phases)**: tutorial T29-T34 (S2 - done, D109), generator V5 / Levels 2001-3000 / contract bands / complexity+triviality+probe support for the selector as an ablation kind (S3 - done, D110), APK/versionCode (S4).


## D109 - Splitter Selector tutorials T29-T34, Phase S2 (uncommitted, no version bump)

- **Pack**: T29 "Select Path" (1 forced tap), T30 "Choose Output" (3 forced taps, walks all four states: LEFT=absorbed, UP=decoy target, RIGHT=wall, DOWN=goal), T31 "Sel + Filter" (1; per-output filters, decoy BLUE target stays dark), T32 "Sel + Portal" (2; RIGHT lights a decoy target), T33 "Sel + Fusion" (2; RED reaches the node ONLY through the Selector), T34 "Sel Trial" (free play, 5 taps, min 5: Selector + Filter x2 + Mirror x2 + Portal + Fusion + Switch/Gate). Sentence-case text (project convention), display names <= 13 chars. Selector tiles are ordinary orientable tiles, so TutorialManager/GridManager forced-tap, restriction and hint plumbing needed ZERO changes.
- **Unlock**: not era-gated (same reason as Fusion). `LevelManager.is_selector_tutorial_selectable()`: T29 opens when `SaveManager.procedural_current_level >= SELECTOR_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL` (1900, ahead of the first Selector level 2001 - S3, not built) or via `tutorial_highest_unlocked_level`; T30-T34 sequential; the QA flag opens all. `SaveManager.reset_main_progress_for_new_game()` preserves this like the Fusion rule. Not a hard gate; no nudge popup was added (not requested).
- **Hints**: hand-authored `t29`-`t34` entries in `levels/hint_solutions.json` (the builder already skips ids >= 21). Forced step = only that tile, message step = none, free (T34) = table. `bs_splitter_selector_icon.png` is UNUSED (tutorial panel has no icon support, same as `bs_fusion_icon.png`).
- **Verification** (`scripts/tools/selector_tutorial_verify.tscn`, dev-only, exhaustive over all orientation combinations, LevelSolver not usable): every board starts unsolved, has exactly ONE solving combination equal to the hint entry, min taps == taps forced by the steps, every changed tile matters, selector as dead blocker/removed loses the level, step replay never solves early. Real-flow driver (rendered, real GUI click on the selector) passed for T29-T34; T01-T28 replay, SELECTOR TEST 1-6 and FUSION TEST 1-6 also pass. V1-V4 fingerprint (25 levels x 4 versions, pristine HEAD copy vs current) identical.



## D110 - Procedural generator V5 (Levels 2001-3000) + Splitter Selector in main progression, Phase S3 (uncommitted, no version bump, no APK)

Full reference: `PROCEDURAL_GENERATION.md` section 20. This entry records the decisions and the evidence behind them.

- **Scope kept**: V5 is a NEW version (5), never a mutation of V4; `GENERATOR_VERSION` (default 2), `_BANDS_V1/_V2`, V3/V4 output untouched (V1-V4 fingerprint, 33 levels x 4 versions, identical before/after, re-run after every larger change). Levels 2001-3000 exist because `INITIAL_CERTIFIED_LEVEL_TARGET`/`MAX_LEVEL` became 3000 (constants only; QA +50, Next Level, Continue, New Game all derive from it); `procedural_generator_version_for_new_play(level)` maps level >= 2001 to V5. No Android build, no `versionCode`/`versionName` change, `export_presets.cfg` untouched, nothing committed.
- **Bands G-K** added to the ONE contract table (moves 20-24 ... 28-34, depth 10-12 ... 15-19, deps 6-9 ... 10-15; interaction/kind floors are mine). `SELECTOR_POLICY` carries roll frequency, count weights, family lists and the per-band downstream-depth floor. Selector presence is a deterministic Weyl sequence over the level number (no RNG), Level 2001 always introduces one simple Selector, T29 (unlock 1900) precedes it.
- **The Selector is a turn, not a template**: families S-A..S-P are recipes (`SELECTOR_FRAGMENTS`: needed atoms + plan sites), realised by turning a turn slot in front of a Filter/Portal/Switch/hop/Fusion input/Prism channel/One-Way/Gate/branch/Fusion output into a Selector slot. 12 of the 16 conceptual families exist; S-I, S-K, S-M, S-O do not (no decoy/bait builder).
- **`ProceduralSelectorCheck`** makes the Selector a first-class complexity kind: blocker ablation, removal, the three other orientations (none may solve), outcome signatures (equivalent states), consequence vs the dead state, live outputs/rays, downstream depth, coupling/convergence for several Selectors. A Selector counts toward kinds/dependencies/depth only when load-bearing, not mirror-like and non-solving - otherwise decorative Selectors would have inflated the metrics. Hardening does NOT blanket-block a Selector's wrong rays (that would leave three dead ends); only a wrong state that solves gets a blocker.
- **4-state cost**: `intended_move_count` counts real clockwise tap distance for Fusion/Selector (Fusion is always 1: V4 unchanged). Generated Selectors start 1-3 taps from solved (55/35/10%), never keep-correct.
- **Density, not clutter**: 8x12 is not comfortable (94 < 96 px) so V5 uses 8x11 only; plans are fitted to a 56-tile budget BEFORE layout; move targets shrink to what fits (never the reasoning floors); atoms are weighted by depth per tile and measured layout reliability (shared-tile atoms SO/SH/PG fail 75-90% of layouts). Layout, not logic, is the binding constraint: K at 28+ moves and depth 15+ is ~65+ tiles.
- **Degradation ladder instead of V2 fallback**: after layout failures the move floor relaxes (<= 25%); from attempt 8 (Selector levels) / 14 the level uses the REASONING floors of the band below (`band_demoted`); a Selector level keeps its Selector as long as possible (`selector_dropped` counts the rest). All counted and shown (`~DEMOTED` in the V5 TEST label, `moves_below_band`, `V5_GENERATION_FAILED` for a real fallback = 0 observed). About half of J/K levels are demoted - this is the honest cost of the physical limit, not a tuned-away number.
- **Two quality bugs found by replaying the intended solution through a real GridManager** (rule 12c technique): (1) L3000's first draft solved after 25 of 30 intended taps - a superfluous GROUP of tiles (each alone "required"); measured ~14% of unscreened Mastery boards, up to 16 of 26 tiles superfluous. Fixed with `ProceduralMinimality` (lazy activation + ddmin over 11 tile orders + line unions); (2) an independent 2500-simulation probe found 9-14-flip alternatives (22 intended, 9 needed) in ~2% of Entry/Branching boards that the 420-simulation runtime screen accepted. Fixed with one final wide probe (3200/48) on the survivor. **Both are screens**: residual ~0.6% group redundancy (random-order ddmin) and ~4% wide-probe shortcuts in Interlock-Mastery samples remain and are documented, not hidden. The same class exists in V4 (1 of 40 sampled 1801-2000 levels had a 5-tile superfluous group) - V4 is frozen and was not touched.
- **Exact optimality is UNKNOWN on every V5 level** (`verified_optimal_moves` = -1; `StarScoring` uses `intended_moves`; star formula unchanged). `v5_verify.tscn` has an exact touched-tile BFS (proves 8/8 V3 levels 5-150) but exhausts its budget at depth 9-19 of 20+ on V5.
- **Measured** (50-level windows): Selector share 42/50/58/62/71% (targets 35-45/45-55/55-65/60-70/65-75 - met by calibrating the ROLL, K 0.76), 0 fallbacks, greedy-solvable 0/250, moves G/H in band, I at its floor, J/K below (avg 24.8/25.6), demoted 0/5/9/26/31 of 50, avg generation 1.5-2.3 s desktop (max 5.2 s), phone unmeasured. 21 anchor levels all clean under an independent 2500/40 probe; 22 anchors deterministic across separate processes.
- **Integration verified with the real game scene**: Save/Continue restores level, generator version 5, seed, every orientation (Selector states 0-3), move count and hint-used at 2001/2200/2500/2800/3000; Hint targets a wrong Selector, never rotates/counts a move, hint-used caps stars at 2; replaying the intended solution through a real GridManager solves 7 anchors in exactly `intended_moves` taps with 3 stars; QA +50 (1951->2001, 2951->3000, 3000 no-op) records nothing; Next Level 2000 -> 2001 switches V4 -> V5. Levels 1-15 solver (15/15), campaign samples, T01-T34 loading, T29-T34 hint entries, SELECTOR TEST 1-6, FUSION TEST 1-6, `selector_verify`/`selector_tutorial_verify` all pass.
- **QA**: "V5 TEST" (`SHOW_V5_TEST_QA` = `BuildConfig.QA_TOOLS`, `ProceduralV5QaSet.LEVELS` = 2001/2050/2201/2351/2500/2651/2800/2900/3000, all Selector-bearing) with "NEXT V5", contained like SELECTOR TEST (no save, stars, ads, counter). The gameplay tag shows `V5 <band> [F#] [S?]`.
- **Status: S3 IMPLEMENTED / NOT CERTIFIED; next = S3.1 (J/K refinement, target J/K demotion <= 10%), not S4.** - **Not done / next**: manual play review of the V5 TEST levels (difficulty feel, readability of 38-57-tile boards), on-device generation time (S4; caching/prefetch is the obvious mitigation), production flag clean-up, APK. Not built: families S-I/S-K/S-M/S-O, Levels 3001+, chained Fusion.

## D111 - V5 Phase S3.1 pass 1: S-M target-continuation Selector + delayed K demotion (uncommitted, no version bump, no APK)

S3.1 pass 1 kept V1-V4 frozen and targeted the measured J/K demotion problem without changing the J/K contract rows, board size, `MAX_COLUMNS`, stars, Hint, AdMob, tutorials, Save/Continue, Fusion, New Game or Android/export settings.

- **Implemented S-M**: `ProceduralFragmentsV3.SELECTOR_FRAGMENTS` now includes `SM` ("Selector -> target continuation"), using the existing `TM` atom and `target` selector site. J/K selector family pools include `SM`.
- **Delayed late-band demotion**: V5 gets 64 attempts. J keeps the 32-attempt strict runway; K gets a 48-attempt runway before `band_demoted` can accept lower-band reasoning floors. This is a stricter search window, not a target loosen.
- **Baseline reproduced before code changes** (`v5_sample`, `hist=1`): V1-V4 fingerprint hash `271eb766be20a12446676a947b49a3f1`; J 36/50 generated before the 55s budget, `band_demoted=20`; K 30/50 generated before the 55s budget, `band_demoted=22`.
- **Post-change measured** (`hist=1`, `budget=90000`): J 36/50 generated before budget, `band_demoted=3` (8.3%), 0 fallbacks, greedy accepted 0; K 37/50 generated before budget, `band_demoted=0`, 0 fallbacks, greedy accepted 0. V1-V4 fingerprint remained `271eb766be20a12446676a947b49a3f1`.
- **Still not certified**: full 50-level J/K windows still exceeded the QA budget, phone readability and Android generation time remain unmeasured, and residual minimality/shortcut concerns from D110 are not closed. S4/APK remains blocked until follow-up certification and manual V5 play review.
