# ARCHITECTURE.md

Describes the **actual implementation**, updated incrementally as the
project progresses (not frozen at Milestone 3 — see `CURRENT_STATUS.md`
for what milestone is actually current). If this ever disagrees with the
code, the code wins — fix this file. Some sections below are explicitly
labeled with the milestone that last touched them (e.g. "Milestone 4A.1
correction"); a section with no such label describes foundational
behavior that hasn't changed since it was written, not necessarily
something written at Milestone 3 specifically.

## Directory structure

```
scenes/ui/main_menu.tscn            Main menu
scenes/ui/level_select.tscn         Level select (dynamic buttons)
scenes/ui/level_button.tscn         One level-select button
scenes/ui/settings_menu.tscn        Sound/Music toggles
scenes/ui/level_complete_popup.tscn Level-complete overlay
scenes/gameplay/game.tscn           Play session root: HUD + grid + popup
scenes/gameplay/grid.tscn           The puzzle grid (PuzzleGrid/GridManager)
scenes/gameplay/laser_mirror_impact_fx.tscn  Cosmetic mirror-hit burst (D71)
scenes/tiles/emitter.tscn           Emitter visual
scenes/tiles/mirror.tscn            Mirror visual (rotatable or fixed)
scenes/tiles/target.tscn            Target visual
scenes/tiles/blocker.tscn           Blocker visual
scenes/tiles/splitter.tscn          Splitter visual (rotatable or fixed)
scenes/tiles/filter.tscn            Color filter visual
scenes/tiles/portal.tscn            Portal visual
scenes/tiles/switch.tscn            Switch visual
scenes/tiles/gate.tscn              Gate visual (open/closed)
scenes/tiles/hazard.tscn            Hazard visual

scripts/managers/save_manager.gd    Autoload: local JSON save
scripts/managers/level_manager.gd   Autoload: level list + star formula
scripts/managers/game_manager.gd    Autoload: scene navigation + selected level
scripts/managers/audio_manager.gd   Autoload: centralized semantic SFX (AUDIO_SYSTEM.md)
scripts/managers/ad_manager.gd      Autoload: AdMob rewarded Hint + interstitial over scripts/ads/ (ADS_MONETIZATION.md)

scripts/gameplay/grid_types.gd      Enums + reflect()/color helpers (RefCounted, class_name GridTypes)
scripts/gameplay/laser_system.gd    Deterministic multi-beam simulation (RefCounted, class_name LaserSystem)
scripts/gameplay/grid_manager.gd    Owns all live puzzle state + layout + drawing
scripts/gameplay/tile_visual.gd     Base class for tile visuals (cell background)
scripts/gameplay/emitter.gd         EmitterTile : TileVisual
scripts/gameplay/mirror.gd          MirrorTile : TileVisual
scripts/gameplay/target.gd          TargetTile : TileVisual
scripts/gameplay/blocker.gd         BlockerTile : TileVisual
scripts/gameplay/splitter.gd        SplitterTile : TileVisual
scripts/gameplay/filter.gd          FilterTile : TileVisual
scripts/gameplay/portal.gd          PortalTile : TileVisual
scripts/gameplay/switch.gd          SwitchTile : TileVisual
scripts/gameplay/gate.gd            GateTile : TileVisual
scripts/gameplay/hazard.gd          HazardTile : TileVisual
scripts/gameplay/fusion_tile.gd     FusionTile : TileVisual (Beam Fusion Node, D99; direction drawn dynamically)
scripts/gameplay/hint_manager.gd    HintManager : RefCounted (Global Hint System, D97)
scripts/procedural/**               Procedural generators V1-V4 + difficulty contract/complexity/fusion check (PROCEDURAL_GENERATION.md)
scripts/gameplay/laser_mirror_impact_fx.gd  LaserMirrorImpactFX : Node2D (flash/ring/sparks, self-freeing)
scripts/gameplay/game.gd            game.tscn root: session/HUD orchestration

scripts/resources/level_data.gd     class_name LevelData extends Resource
scripts/resources/tile_placement.gd class_name TilePlacement extends Resource (one flat class + static make_*() factories - see DECISIONS.md D12)

scripts/ui/main_menu.gd
scripts/ui/level_select.gd
scripts/ui/level_button.gd
scripts/ui/settings_menu.gd
scripts/ui/level_complete_popup.gd
scripts/ui/ui_constants.gd
scripts/ui/safe_area_margin.gd

levels/level_01.gd .. level_05.gd   Milestone 1 test levels (basic mechanics) - dev/regression only, no longer player-facing (see Milestone 4 below)
levels/level_06.gd .. level_15.gd   Milestone 2 test levels (advanced mechanics - see "Milestone 2 test levels" below) - dev/regression only, no longer player-facing
levels/editor_fixtures/*.gd         Milestone 3: deliberately-broken/edge-case levels for validator+solver testing only (never in LevelManager.LEVEL_PATHS or CAMPAIGN_LEVEL_PATHS)
levels/campaign/stage_01/*.gd       Milestone 4: the real, player-facing production campaign - Stage 1 ("First Light," campaign levels 1-10, MANUALLY APPROVED). See CAMPAIGN_DESIGN.md and DECISIONS.md D54.
levels/campaign/stage_02/*.gd       Milestone 4: Stage 2 ("Reflection," campaign levels 11-20, manual approval pending); stage_03+ not yet created. See CAMPAIGN_DESIGN.md and DECISIONS.md D55.

scripts/tools/level_solver.gd       Milestone 3: BFS puzzle solver (RefCounted, class_name LevelSolver) - development-only, not in the shipped gameplay path
scripts/tools/level_validator.gd    Milestone 3: structural validator (RefCounted, class_name LevelValidator)
scripts/tools/level_metrics.gd      Milestone 3: design metrics + difficulty estimate (RefCounted, class_name LevelMetrics)

tools/level_editor/level_editor.tscn  Milestone 3: the level editor (run directly via F6, not part of the shipped game)
tools/level_editor/level_editor.gd    Editor UI/interaction logic

themes/beamshift_theme.tres          Milestone 4A: shared Theme resource (default font size, Button/DangerButton styles) - see "UI theme" below
scenes/ui/pause_menu.tscn            Milestone 4A: new gameplay pause overlay
scripts/ui/pause_menu.gd             Pause overlay UI/interaction logic
assets/                              Milestone 4A: final generated art - see "Final asset integration" below
```

## Autoloads

Registered in `project.godot` under `[autoload]`, in load order:

1. `SaveManager` (`scripts/managers/save_manager.gd`)
2. `LevelManager` (`scripts/managers/level_manager.gd`)
3. `GameManager` (`scripts/managers/game_manager.gd`)
4. `AudioManager` (`scripts/managers/audio_manager.gd`) - centralized SFX, see "Audio architecture"
5. `AdManager` (`scripts/managers/ad_manager.gd`) - AdMob rewarded Hint / interstitial, see "Advertising"

`LevelManager.get_continue_level_id()` reads `SaveManager` directly, so
`SaveManager` must load first - this ordering is load-bearing. (Corrected in D100: this list once still said
three autoloads; `project.godot` is authoritative and lists five.)

No other systems are autoloads. `grid_manager.gd` deliberately does **not**
touch any autoload — it is pure Control + gameplay state, which is what
makes it independently testable headlessly (see `TEST_PLAN.md`).

## Scene transitions

All handled by `GameManager` via `get_tree().change_scene_to_file()`:

- `MainMenu` → (Play) → `LevelSelect` → (pick level) → `Game`
- `Game` → (Back) → `LevelSelect`
- `Game` → (Level Complete → Level Select) → `LevelSelect`
- `Game` → (Level Complete → Next Level) → reloads `Game` in place with
  `current_level_id + 1` (no scene change, just `_load_current_level()`)
- `Game` → (Retry / Reset) → reloads the same level in place
- `MainMenu` → (Settings) → `SettingsMenu` → (Back) → `MainMenu`
- `MainMenu` → (Continue) → `LevelManager.get_continue_level_id()` decides
  the target level, then goes straight to `Game`

`GameManager.current_level_id` is the only piece of state carried across
the `LevelSelect` → `Game` scene change (Godot scene changes don't pass
arguments directly, so this is the hand-off point).

### Editor playtest hand-off (Milestone 3)

A second, parallel hand-off path exists purely for the level editor's
Playtest button:

- `GameManager.start_editor_playtest(level_data)` sets
  `editor_level_data = level_data` and `is_editor_playtest = true`, then
  changes to `Game` exactly like `start_level()` does.
- `game.gd._load_current_level()` checks `is_editor_playtest` first: if
  true, it loads `GameManager.editor_level_data` directly instead of
  asking `LevelManager` for a saved level by ID, and labels the HUD
  "EDITOR PLAYTEST: <name>" instead of "LEVEL N: <name>".
- `game.gd._on_level_solved()` also checks the flag: in playtest mode it
  **never calls `SaveManager.record_level_result()`** (a playtest must
  never write to the player's real save data) and computes a preview
  star count against the editor level's own `optimal_moves` using
  duplicated threshold logic (see `LevelManager.TWO_STAR_MOVE_MARGIN`),
  since the real `LevelManager.calculate_stars()` needs a saved
  `level_id` this in-progress level doesn't have.
- Back/Level Select from the popup call
  `GameManager.return_to_editor_from_playtest()` instead of
  `go_to_level_select()`, which sets a one-shot
  `_editor_return_pending` flag and changes to
  `tools/level_editor/level_editor.tscn`.
- `level_editor.gd._ready()` checks
  `GameManager.is_editor_playtest_return_pending()`; if true, it calls
  `GameManager.take_editor_level_data()` (which also clears the pending
  flag - a genuine one-shot consume, so a later fresh editor open never
  mistakes itself for a playtest return) and restores that exact
  `LevelData` object into the editor for continued editing.

This path is completely inert during normal play - `is_editor_playtest`
defaults `false` and nothing except the editor ever sets it `true`.

## Grid coordinate system

- `Vector2i(x, y)`, origin `(0,0)` at the grid's top-left cell.
- `x` increases rightward, `y` increases downward (screen convention).
- `GridTypes.Direction` is `{UP, RIGHT, DOWN, LEFT}`;
  `GridTypes.direction_vector()` maps each to a `Vector2i` step
  (`UP = (0,-1)`, `RIGHT = (1,0)`, `DOWN = (0,1)`, `LEFT = (-1,0)`).

## Mirror and splitter representation

- `GridTypes.MirrorOrientation` is `{SLASH, BACKSLASH}` (`/` and `\`).
  Shared by both `MIRROR` and `SPLITTER` tiles (see DECISIONS.md D15) -
  there is no separate splitter-orientation enum.
- `GridTypes.reflect(dir, orientation)` is the **single** source of truth
  for the reflection truth table, used by mirrors AND by a splitter's
  branch beam:

  ```
  "/"  (SLASH):     RIGHT->UP    LEFT->DOWN   UP->RIGHT   DOWN->LEFT
  "\"  (BACKSLASH): RIGHT->DOWN  LEFT->UP     UP->LEFT    DOWN->RIGHT
  ```
- A mirror/splitter's `rotatable` flag (on `TilePlacement`, mirrored onto
  the visual node) determines whether player taps do anything.
  `MirrorTile`/`SplitterTile._gui_input()` early-returns if
  `rotatable == false`, so a fixed tile never emits `tile_clicked` — no
  move is counted, no state changes.
- `GridManager.tile_orientations: Dictionary` (`Vector2i ->
  GridTypes.MirrorOrientation`) is the single live-state dict for
  **both** mirrors and splitters (renamed from Milestone 1's
  `mirror_orientations` once splitters needed to share it).
  `GridManager._on_orientable_tile_clicked(pos)` is the one handler both
  `MirrorTile.tile_clicked` and `SplitterTile.tile_clicked` connect to.

## Beam colors

`GridTypes.BeamColor` is `{WHITE, RED, GREEN, BLUE}`. `WHITE` is
deliberately overloaded as both "the Milestone 1 default emitter color"
and "a target that accepts any beam color" — see DECISIONS.md D14 for
why this single value safely covers both roles and keeps every
Milestone 1 level's behavior unchanged.

- `GridTypes.target_accepts_color(required_color, beam_color) -> bool`
  is the **single** source of truth for color matching:
  `required_color == WHITE or required_color == beam_color`.
- `GridTypes.beam_color_to_render_color(color) -> Color` is the **single**
  source of truth for how each `BeamColor` is drawn (used by the beam
  `Line2D`s, `EmitterTile`'s body, and `TargetTile`'s color ring).
- Color is carried on the beam-state dictionary throughout simulation
  (`beam["color"]`) - it is real simulation data, not a rendering-only
  tint, per the brief's explicit requirement.

## Laser propagation algorithm

`LaserSystem` (`scripts/gameplay/laser_system.gd`) has two entry points,
both pure functions - neither reads or writes any node, autoload, or
global state:

```
simulate(level_data, tile_orientations, gate_states) -> Dictionary   # exactly ONE pass
simulate_until_stable(level_data, tile_orientations) -> Dictionary   # re-runs simulate() to resolve switches/gates
```

`GridManager` only ever calls `simulate_until_stable()`. `simulate()` is
exposed separately because it's useful (and was used) for isolated unit
testing of a single pass without the multi-pass machinery.

**Inputs:**
- `level_data: LevelData` — grid size and every tile's static data,
  read fresh from `level_data.tiles` each call.
- `tile_orientations: Dictionary` (`Vector2i -> GridTypes.MirrorOrientation`)
  — current mirror/splitter orientation (see previous section).
- `gate_states: Dictionary` (`String gate_id -> bool`, `simulate()` only)
  — fixed for the whole pass; `simulate_until_stable()` manages this
  internally and callers never construct it by hand.

**Multi-beam stepping (one pass, `simulate()`):**

An explicit work list (`Array`, used as a LIFO stack) replaces recursion,
per the architecture requirement - see DECISIONS.md D20. Every `EMITTER`
tile seeds one beam state `{position, direction, color, segments}` onto
the list. The list is processed until empty:

1. Pop a beam state; step it forward in a loop until it terminates.
2. At each step, build a state key from `(position, direction, color)`.
   If already seen (by **this beam or any other, including different
   emitters** — the guard is shared, see below), the beam is in a
   **cycle** — mark `looped = true` and stop this branch.
3. Step one cell in the current direction. Off-grid → stop.
4. Cell-type rules, each ending the step (`continue`) or the branch
   (`break`):
   - **Blocker** → stop (absorbed).
   - **Hazard** → record the hit position, stop (absorbed) — see
     "Hazards" below.
   - **Gate** → if closed (per `gate_states`), stop (absorbed) like a
     blocker; if open, pass through like empty space — see
     "Switches and gates" below.
   - **Switch** → record the hit, pass through unaffected (doesn't stop
     or bend the beam).
   - **Portal** (only if its pairing is valid — see "Portals" below) →
     jump to the paired portal's position, same direction, same color;
     **starts a new visual segment** (see "Laser visualization").
   - **Filter** → beam's `color` becomes the filter's configured color;
     pass through, no bend.
   - **Splitter** → append a bend point; push a **second** beam state
     onto the work list with direction `GridTypes.reflect(dir,
     orientation)` (the branch); the current beam continues in this
     loop with its direction **unchanged** (the straight-through half) —
     see "Splitters" below.
   - **Mirror** → append a bend point; reflect the direction via
     `GridTypes.reflect()`; keep going.
   - **Target** → append a point; if `GridTypes.target_accepts_color()`
     matches, mark it activated; the beam **continues past it** (see
     DECISIONS.md D22 — this is a Milestone 2 behavior change from
     Milestone 1, where the beam always stopped at a target).
   - Empty cell → keep going, no point recorded.
5. When a branch terminates, its `{segments, color}` is appended to the
   pass's `beams` result list.

**Pass result (`simulate()`'s return value):**

```
{
  "beams": Array[{ "segments": Array[Array[Vector2i]], "color": GridTypes.BeamColor }],
  "activated_targets": Array[Vector2i],
  "activated_switch_positions": Array[Vector2i],   # which SWITCH tiles were hit, for visuals
  "activated_gate_ids": Array[String],             # which gate_id(s) should open as a result
  "hit_hazard_positions": Array[Vector2i],
  "hazard_hit": bool,
  "solved": bool,        # all REQUIRED targets activated AND no hazard hit
  "looped": bool,
  "gate_states": Dictionary,   # the gate_states this pass actually ran with
}
```

`solved = required_target_count > 0 and required_activated_count >=
required_target_count and not hazard_hit`. `required_target_count`
counts only `TilePlacement`s with `required == true` (the default, so
every Milestone 1 target — which never set this field — still counts).

### Loop protection

`visited_states` is **one dictionary shared across every beam branch and
every emitter within a single pass**, keyed on
`"%d,%d|%d|%d" % [x, y, direction, color]`. Because board state (gate
open/closed, mirror/splitter orientation) is fixed for the entire pass,
`(position, direction, color)` alone fully determines a beam's future
path — so it is not just *safe* but *correct* to stop a branch the
instant it revisits a state any beam already reached: nothing new would
happen from there. A `MAX_STEPS` constant (20000) is an additional hard
backstop purely for defense-in-depth; the finite `(position, direction,
color)` state space already guarantees termination on its own. Both the
exact Milestone 1 closed-loop geometry (re-verified after this rewrite)
and Milestone 2's own splitter/portal/switch/gate mechanics rely on this
same single guard — see `TEST_PLAN.md` and DECISIONS.md D20.

### Splitters

A splitter always sends the straight-through beam onward with its
direction **unchanged**, independent of the splitter's orientation, and
spawns a second (branch) beam via `GridTypes.reflect()` — the exact same
function mirrors use. See DECISIONS.md D15 for why this specific split
was chosen over alternatives. `SplitterTile`
(`scripts/gameplay/splitter.gd`) is a fully separate visual/interaction
class from `MirrorTile`, sharing only the tap-to-toggle interaction
*pattern*, not any code or authoritative logic (the brief's explicit
requirement).

### Filters

A `FILTER` tile has one `color` field. Any beam passing through
unconditionally becomes that color — no dependency on incoming color,
direction, or any orientation (filters have no orientation field). See
DECISIONS.md D16.

### Portals

`PORTAL` tiles carry a `pair_id: String`. `LaserSystem` groups all portal
tiles by `pair_id` at the start of each pass; a pair is only "live" if it
has **exactly 2** members. A beam entering a live portal jumps straight
to its partner's position, continuing in the **same direction** with the
**same color** — no portal orientation field exists (DECISIONS.md D17).
An invalid pairing (0, 1, or 3+ tiles sharing a `pair_id`) makes every
portal cell in that group **inert** (treated as an empty cell) — this
fail-safe behavior is exercised directly in automated testing (a single
unpaired portal; see `TEST_PLAN.md`).

### Switches and gates

`SWITCH` tiles carry `gate_id: String` (the gate they open). `GATE`
tiles carry their own `gate_id: String` plus `initial_open_state: bool`.
A beam passing over a switch doesn't stop or bend — it's recorded in
`activated_gate_ids`. A beam reaching a gate stops if `gate_states.get(
gate_id, initial_open_state)` is `false` (closed, like a blocker);
passes through untouched if `true` (open).

**Multi-pass stabilization** (`simulate_until_stable()`, DECISIONS.md
D18) is what actually lets a switch open a gate at all — `simulate()`
never mutates `gate_states` mid-pass:

1. Seed `gate_states` from every `GATE` tile's `initial_open_state`.
2. Run `simulate()`. For every `gate_id` in the result's
   `activated_gate_ids`, if it isn't already open, mark it open
   (`gate_states[gate_id] = true`) — this only ever moves closed → open,
   **never** the reverse, which is what makes termination trivially
   provable (see below).
3. If any gate changed, repeat from step 2 (a full re-simulation from
   scratch — not an incremental continuation). If nothing changed, the
   last pass's result is final.
4. Hard cap: `max(1, gate_count + 1) + 8` passes. The `gate_count + 1`
   term is the actual correctness bound (a gate can open at most once,
   so at most `gate_count` state-changing passes plus one confirming
   pass that changes nothing); the `+8` is pure defensive margin.

**Statelessness (important):** `GridManager` does **not** persist gate
or switch state across separate player moves. Every rotation triggers a
brand-new `simulate_until_stable()` call that starts every gate at its
`initial_open_state` again. A switch hit five moves ago whose beam path
has since been rotated away does *not* keep its gate open. This is what
makes Reset work correctly for gates/switches with **zero** gate/switch-
specific reset code — restoring `tile_orientations` (already Milestone 1
behavior) is sufficient. See DECISIONS.md D18 for the full reasoning.

### Hazards

A beam entering a `HAZARD` cell stops there (like a blocker) and its
position is recorded in `hit_hazard_positions`; `hazard_hit` becomes
`true` for that pass, which unconditionally prevents `solved` from being
`true` regardless of target state. Critically, `GridManager.is_solved`
(which gates further player interaction) is only ever set from `solved`
— so a hazard hit **never blocks the player from continuing to rotate
tiles**, per the brief's explicit requirement. See DECISIONS.md D19.

### Multiple emitters

Every `EMITTER` tile in `level_data.tiles` seeds its own beam state at
the start of `simulate()` — there is no special-casing for "the" emitter
versus "additional" ones. Loop protection, target activation, and gate/
switch interaction are all naturally shared across every emitter's beam
via the single per-pass `visited_states`/`activated_*` collections
described above.

## Laser visualization

Rendering is fully separate from simulation — `GridManager._redraw_beams()`
only *reads* `LaserSystem`'s result, never influences it. For each beam in
`result["beams"]`, and for **each of that beam's `segments`** (not each
beam — see DECISIONS.md D21), `GridManager` builds a fresh `Line2D` pair
(a wide, low-alpha "glow" line and a narrow "core" line) colored via
`GridTypes.beam_color_to_render_color(beam["color"])`, converts each
`Vector2i` grid point to pixel space, and adds them as children of a
dedicated `Beams` container. The whole pool is freed and rebuilt on every
`_simulate_and_draw()` call — simple and correct, and cheap enough at
this scale (a handful of short-lived `Line2D` nodes) that no pooling
optimization was needed.

**Why per-segment, not per-beam:** a portal transit starts a new segment
specifically so a `Line2D` never has to draw a straight line across the
map between a portal's entry and its partner's exit — see DECISIONS.md
D17. A beam with no portal in its path (every Milestone 1 level, and
most Milestone 2 tiles) simply has exactly one segment, so rendering is
visually identical to Milestone 1's single-`Line2D`-per-beam behavior.

### Mirror impact VFX (`LaserMirrorImpactFX`, D71)

A purely cosmetic burst where a beam reflects off a mirror, layered on the
same read-only relationship as beam rendering: `GridManager` reads
`_last_result`, never feeds anything back into `LaserSystem`.

- **Trigger:** `GridManager._simulate_and_draw(play_impacts)` calls
  `_spawn_mirror_impacts()` right after `_redraw_beams()`, but only when
  `play_impacts` is true — i.e. from `_on_orientable_tile_clicked()` (a
  player tap). Load/Reset call it with the default `false`. It is NOT in
  `_redraw_beams()` (that also runs on every resize — see
  `_recalculate_layout()` — and would respawn effects).
- **Which reflections:** `LaserSystem` records every mirror the beam
  bends at as a segment corner. For each segment point whose cell holds a
  `MirrorTile` (`_orientable_nodes` also holds splitters — excluded, they
  pass the beam straight through), one burst is spawned. Outgoing
  direction = `sign(next_point - point)`; if the mirror is a segment's
  last point (loop-guard cut) the burst is radial. Dedupe key: cell +
  incoming + outgoing + color.
- **Position/color:** cell center via the same expression `_redraw_beams()`
  uses; color from `beam["color"]` through
  `GridTypes.beam_color_to_render_color` (so a filter downstream of a
  mirror in the same branch recolors that mirror's burst, exactly as the
  beam line itself is drawn).
- **Node layout:** `PuzzleGrid` children are now `CellBackgrounds`,
  `Tiles`, `Beams`, `ImpactFX`, `TutorialDimOverlay`, `TutorialHighlight`.
  `ImpactFX` is a `Control` with `mouse_filter=IGNORE`; its children are
  `Node2D` `LaserMirrorImpactFX` instances (scene
  `scenes/gameplay/laser_mirror_impact_fx.tscn`, root has the script
  attached) that draw everything in one additive-blend `_draw()` driven by
  a `progress` 0→1 Tween (`DURATION = 0.32 s`), then `queue_free()`.
- **Lifecycle:** each new evaluation and each layout change immediately
  frees whatever bursts are still alive (`_clear_impact_fx()`); hard cap
  `IMPACT_FX_MAX_COUNT`; skipped while `cell_size <
  IMPACT_FX_MIN_CELL_SIZE` (pre-layout). No `_process` anywhere.
- **Tunables** are constants at the top of `laser_mirror_impact_fx.gd`
  (all sizes are fractions of a cell). Extending to another tile type
  (target/portal/gate…) should copy the pattern — a new component fed
  from `_last_result` — not add anything to `LaserSystem`.

## Rectangular grid layout (Phase 1, D72)

`GridManager` fits an arbitrary `grid_width` (columns) x `grid_height`
(rows) board against the real playable rectangle, not just a square one.

- **The playable rectangle is `GridManager`'s own `Control` rect** —
  no viewport math needed. `game.tscn` wires this up structurally:
  `SafeMargin/Layout` is a `VBoxContainer` with `TopBar` (an `AspectBar`-
  driven, aspect-ratio-locked decorative HUD bar), `CenterArea`
  (`size_flags_vertical = EXPAND_FILL`), and `BottomBar` (another
  `AspectBar` bar) as its three children. `PuzzleGrid` (`GridManager`)
  fills `CenterArea` with full-rect anchors, so whatever space the
  `VBoxContainer` leaves between the two HUD bars after they claim their
  own aspect-locked height *is* `GridManager.size` — already exactly the
  "available rectangle between Top HUD and Bottom HUD" a rectangular
  board needs to fill.
- **`_recalculate_layout()`** (triggered by the `resized` signal, so it
  reruns on load, window resize, and HUD geometry changes — never every
  frame):
  ```
  available = size - GRID_SAFETY_MARGIN * 2  (both axes)
  cell_size = floor(min(available.x / grid_width, available.y / grid_height))
  grid_pixel_size = cell_size * Vector2(grid_width, grid_height)
  grid_origin = (size - grid_pixel_size) * 0.5   # still centered in the FULL rect
  ```
  `GRID_SAFETY_MARGIN` (8px @ 1080-wide reference) is one constant used
  symmetrically on all four sides — not separate top/bottom/left/right
  values. This replaces the pre-D72 square-only formula
  (`cell_size = floor(min(size.x, size.y) / max(grid_width, grid_height))`,
  which only ever used the smaller of the two axes) with two independent
  per-axis candidates, so a wide board fills width and a tall board
  fills height instead of both being squeezed to whichever axis is
  tighter. A square board's result is identical either way (min() of two
  equal-ratio candidates), so every existing campaign/dev/tutorial level
  renders exactly as before this pass — confirmed by the Phase 1
  regression (`TEST_PLAN.md`).
- **Tiles stay square by construction**: `cell_size` is a single float
  applied to both axes via `TileVisual.cell_size`'s setter
  (`Vector2(value, value)` for `custom_minimum_size`/`size`), so nothing
  downstream needs rectangular-awareness of its own — beam rendering
  (`_redraw_beams()`), the tutorial highlight/dim (`TutorialHighlight`/
  `TutorialDimOverlay`, via `_position_highlight()`), and mirror impact
  VFX (`LaserMirrorImpactFX`) already consumed `cell_size` + `grid_origin`
  generically before this pass and needed zero changes. Tap-to-cell
  input needs no screen-to-cell pixel math either: each tile is its own
  `Control` positioned/sized by `_recalculate_layout()`, so Godot's own
  `Control` hit-testing does the mapping.
- **Diagnostics (development-only, never shown to players)**:
  `GridManager.get_layout_metrics() -> Dictionary` returns
  `columns`/`rows`/`cell_size`/`grid_width_px`/`grid_height_px`/
  `available_width`/`available_height`/`width_utilization`/
  `height_utilization`; `format_layout_diagnostics() -> String` prints
  it in the `GRID CxR / CELL n / WIDTH USE n% / HEIGHT USE n%` shape.
  Intended for a future Phase 2 pass choosing rectangular
  `grid_width`/`grid_height` values for real campaign levels — see
  `CLAUDE.md`'s Responsive rules and `DECISIONS.md` D72.

### No level ever owns HUD positioning (confirmed, Phase 1 / D84)

`LevelData` (`scripts/resources/level_data.gd`) has exactly `grid_width`,
`grid_height`, `tiles`, and puzzle metadata (id/name/`optimal_moves`/
etc.) — zero HUD, pixel-position, or layout fields of any kind. Every
HUD element's position is instead baked into `game.tscn` itself, once,
shared by every level:

- `SafeAreaMargin` (`scripts/ui/safe_area_margin.gd`) applies
  `UIConstants.BASELINE_MARGIN` (96px @ 1080-wide reference) on every
  platform, widened by `DisplayServer.get_display_safe_area()`'s real
  notch/cutout insets on Android.
- `Layout` (a `VBoxContainer`, `separation = 16`) stacks `TopBar` →
  `CenterArea` → `BottomBar`. `TopBar`/`BottomBar` are `AspectBar`-driven
  (`scripts/ui/aspect_bar.gd`): their height is locked to their own HUD
  art's aspect ratio, never a fixed pixel value.
  `BackButton`/`LevelLabel`/`MovesLabel` (`TopBar`) and
  `ResetButton`/`PauseButton`/`HintButton` (`BottomBar`) are anchor-
  percentage `Control`s positioned within those bars, in `game.tscn`
  only — moving any of them (Reset, Hint, Pause, Back, the HUD bars
  themselves) is a `game.tscn` edit, never a per-level one.
- `CenterArea` gets whatever rect is left; `GridManager` fills it per
  the formula above. A future Level 2000 uses the exact same
  `game.tscn`/`grid_manager.gd` path as Level 1 — nothing scales per
  level count.
- **Whole-cell tap** (no need for a separate "make mirrors easier to
  tap" pass): `TileVisual` (base of every orientable tile visual) is a
  `Control` sized to the full `cell_size x cell_size` cell
  (`custom_minimum_size`/`size` both set in its `cell_size` setter), and
  `_gui_input` (e.g. `MirrorTile._gui_input()`) fires over that entire
  rect — a tap anywhere in the cell rotates the tile, not just a tap on
  the drawn glyph.

### Future-procedural board-profile contract (Phase 1 / D84)

`GridManager.MAX_COLUMNS := 8` and `GridManager.
MIN_COMFORTABLE_CELL_SIZE := 96.0` (px @ 1080-wide reference,
~Android's 48dp minimum touch target at this project's reference scale)
are the ceiling/floor a future procedural generator's board profiles
must satisfy. `GridManager.is_board_profile_comfortable(columns: int,
rows: int, playable_size: Vector2) -> Dictionary` is the pure,
scene-free entry point that checks both against the same cell-size
formula `_recalculate_layout()` uses, returning
`{comfortable: bool, cell_size: float, reason: String}`. A generator (or
a diagnostic script) calls this **before** committing to a shape — it
never derives a pixel value itself, matching the "generator owns puzzle
structure, layout system owns presentation" contract. Existing content
that predates `MAX_COLUMNS` (54 campaign levels, 1 tutorial level, 3
editor fixtures — all wider than 8 columns) is grandfathered and
unaffected; this function is not retroactively run against them.

### Full-Screen Board Correction (D86) + Final Gameplay Spacing Refinement (D87) — gameplay-specific safe margins

Phase 1's rendered validation gap (headless math at the 1080x1920
reference only, no real campaign level ever rendered at the other 4
required resolutions) let a real wasted-space bug ship in `versionCode=
42` — see `DECISIONS.md` D86 for the full root-cause writeup. The fix:
`SafeAreaMargin` (`scripts/ui/safe_area_margin.gd`) gained two `@export`
overrides — `horizontal_margin_override` and `vertical_margin_override`
(originally one combined `margin_override` field in D86; split into two
in D87 once the user asked for a smaller vertical value specifically
without touching the horizontal one). Every existing `SafeAreaMargin`
instance (Main Menu, Level Select, Settings, Tutorial Select) leaves
both at their -1.0 default and is completely unaffected. `game.tscn`'s
`SafeMargin` node sets `horizontal_margin_override = UIConstants.
GAMEPLAY_HORIZONTAL_MARGIN` (32.0) and `vertical_margin_override =
UIConstants.GAMEPLAY_VERTICAL_MARGIN` (8.0), replacing the menu-tuned
`UIConstants.BASELINE_MARGIN := 96.0` for gameplay specifically on both
axes independently. Real Android safe-area insets still widen whichever
value is active via the existing `maxf(baseline, real_inset)` logic in
`_update_margins()`, applied per side, so this never reduces protection
near a real notch/cutout — it only shrinks the margin on devices that
don't need the full 96px, which most phones don't on any edge in
portrait.

D86's horizontal-margin reduction grows `CenterArea` on every side,
which `_recalculate_layout()` (unchanged) turns into a bigger
`cell_size` automatically for a width-bound board — no layout formula
change needed, only a bigger rectangle to feed it. **D87 proved,
algebraically and by direct rendering, that the SAME trick does not
work for the vertical axis on a width-bound board**: since `CenterArea`
has `size_flags_vertical = EXPAND_FILL` and the board is centered
within it, `total_top_space = TopBar.height/2 - BottomBar.height/2 +
screen_height/2 - board_height/2` — independent of both
`vertical_margin` and `VBoxContainer` `separation`, which cancel out of
the equation entirely. Shrinking the vertical margin still moves the
HUD bar's own screen position closer to the true edge (real, requested,
delivered), but cannot shrink the empty space between the HUD and a
width-bound board any further — that space is fixed by `TopBar`/
`BottomBar`'s aspect-locked height (unchanged HUD art) and `board_
height` (`cell_size` already width-maximized). Closing it further would
require either different HUD art (a redesign) or a board shape that
isn't width-bound in the first place (see the future-generator guidance
below) — not more margin tuning.

This does not make board sizing device-height-independent — a
width-bound board's `cell_size` is capped by available width alone, so
some vertical gap on very tall devices for board shapes authored
against the 1080x1920 reference remains mathematically unavoidable
without either a level redesign or non-square cells (both off the
table). See D86/D87 for the honest before/after numbers and the proof.
**Future procedural board profiles should prefer taller row/column
combinations** (e.g. 5x9, 6x10, 7x11, 8x11 — examples) specifically to
avoid landing strongly width-bound, gated on `GridManager.
is_board_profile_comfortable()` actually passing for the target device
range — this is the durable fix for new content, not a retroactive
change to Levels 1-140.

### Direct Play + Continue navigation (Phase 2 / D85)

Main Menu no longer routes normal players to Level Select at all.
`GameManager.play_game()`/`continue_game()` both resolve `LevelManager.
get_campaign_continue_level_id()` and call `start_level(id, false)`
directly — Level Select's own `_on_level_selected()` is the only caller
that ever passes `from_level_select = true`, setting `GameManager.
entered_via_level_select`. That one flag is read in exactly two places:

- `game.gd`'s Back/Pause/Level-Complete "Level Select" navigation — a
  `true` session goes to Level Select (QA), a `false` session goes to
  Main Menu. Pause's dedicated "Level Select" button is hidden outright
  for a `false` session (Pause already has a separate "Main Menu"
  button); Level Complete's "Level Select" button (no separate Main Menu
  button exists there) is relabeled "MAIN MENU" instead — both set once
  per level load in `_load_current_level()`, via a small presentational
  setter each popup exposes (`set_level_select_visible()`/
  `set_navigation_label()`), keeping the popups themselves logic-free.
- Whether `game.gd` reads/writes `SaveManager.campaign_resume_*` at all.
  A `true` (QA) session never does, by design — see the flag's own
  `game_manager.gd` doc comment for why.

**Exact mid-level resume.** `SaveManager` gained `campaign_resume_
level_id`/`campaign_resume_orientations`/`campaign_resume_move_count`
(`SAVE_VERSION` 3→4). `campaign_resume_orientations` is a single slot
(String `"x,y"` → int orientation) — only one campaign level is ever "in
progress" under this project's linear-progression model, so there's no
per-level history to manage. `GridManager.restore_orientations(saved:
Dictionary)` applies it: for each `Vector2i → orientation` pair with a
matching `_orientable_nodes` entry, it updates `tile_orientations[pos]`
AND the node's own `.orientation` together — the identical paired-update
`load_level()` itself already does, so restore can never desync the
drawn glyph from the simulated result (the D40 bug class). One
`_simulate_and_draw(false)` call at the end redraws beams/targets/gates
to match; since this is the same code path a real move uses, a resumed
board that happens to already be solved correctly re-fires
`level_solved` and runs the normal completion flow — no special-casing
needed.

`game.gd._load_current_level(force_fresh: bool = false)`: the campaign
branch, after `_grid.load_level()`, either restores (`not force_fresh`
and the saved resume level id matches `current_level_id`) or calls
`SaveManager.start_campaign_resume(current_level_id)` for fresh tracking
— which is also exactly what happens naturally on Next Level, since the
new level id never matches the just-solved one. Reset/Retry explicitly
pass `force_fresh = true` so they never "resume" the state they're
meant to discard. Persistence itself is event-driven: `start_campaign_
resume()` writes once on level entry/reset, `update_campaign_resume_
state()` writes once per accepted move (via the pre-existing
`GridManager.move_made` signal → `game.gd._on_move_made()`) — never
per-frame, and reliable against an ungraceful Android process kill
specifically because it's move-triggered rather than exit-triggered
(there's no dependable "clean exit" notification to hook on mobile
anyway).

Level Select (`level_select.tscn`/`.gd`) itself is completely unchanged
code — still the exact same scene, still calls `GameManager.
start_level()`, just now passes `true` for `from_level_select` and is
reached only via Main Menu's small QA-only button (gated on
`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`, the same flag
Level Select's own selectability already used).

- **Phase 2A (D73) re-laid out Campaign Levels 1-25** using an
  **order-preserving coordinate remap**: every tile sharing an old row/
  column still shares the new row/column, and relative order along each
  axis is preserved. Since `LaserSystem` only ever depends on the
  *sequence* of cell-type hits a beam makes (never the distance between
  them - see "Laser propagation algorithm" below), this class of
  transform cannot change which cells a beam hits or in what order, only
  the empty space between them - so it's a general, reusable technique
  for re-laying out any level's geometry with a checked, not assumed,
  guarantee that `LevelSolver.analyze()` returns identical
  `status`/`optimal_moves`/`shortest_solution_count`/`states_explored`
  before and after. Prefer this over hand-editing tile coordinates for
  any future geometry-only level change. **Phase 2B (D74) applied the
  identical technique to Campaign Levels 26-50, Phase 2C (D75) to
  Levels 51-75, and Phase 2D (D76) to the final batch, Levels 76-100**
  (five levels across the four phases — 75, 85, 91, 95, 98 — were left
  unchanged, already fully packed on both axes with zero slack to
  remap) — all three confirmed the guarantee holds unconditionally even
  on the campaign's hardest, most tile-dense, most mechanically
  interconnected levels (mutual switch/gate pairs, three-stage relays,
  shared-gate multi-emitter crossings, post-target beam continuation,
  fixed-mirror backward reasoning), since the proof depends only on
  tile *position*, never tile *type* or *mechanic*. **All 100 Campaign
  levels have now been portrait-re-laid-out** — this completes the
  portrait conversion effort begun in Phase 1 (D72). Final audit: 100/100
  SOLVABLE, zero levels below the 90% height / 85% width utilization
  targets, cell sizes ranging 87-174px, average 122.4px.

## Level data format

**Deviation from the milestone brief's suggested `.tres` files** — see
`DECISIONS.md` D1/D12/D13 for the reasoning. A level is a GDScript file
under `levels/` that `extends LevelData` and sets its fields in
`_init()`, using `TilePlacement`'s static factory methods:

```gdscript
extends LevelData

func _init() -> void:
    level_id = 1
    display_name = "First Light"
    grid_width = 5
    grid_height = 5
    optimal_moves = 1
    tiles = [
        TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
        TilePlacement.make_mirror(Vector2i(2, 2), GridTypes.MirrorOrientation.BACKSLASH),
        TilePlacement.make_target(Vector2i(2, 0)),
    ]
```

`TilePlacement` (`scripts/resources/tile_placement.gd`) is one flat
`Resource` subclass covering every tile type's optional fields (see
DECISIONS.md D12 for why this was kept over per-type subclasses). Each
`make_*()` factory documents which fields matter for its tile type:

```gdscript
TilePlacement.make_emitter(pos, direction, color := WHITE)
TilePlacement.make_mirror(pos, orientation, rotatable := true)
TilePlacement.make_splitter(pos, orientation, rotatable := true)
TilePlacement.make_target(pos, required_color := WHITE, required := true)
TilePlacement.make_blocker(pos)
TilePlacement.make_filter(pos, output_color)
TilePlacement.make_portal(pos, pair_id)
TilePlacement.make_switch(pos, linked_gate_id)
TilePlacement.make_gate(pos, own_gate_id, starts_open := false)
TilePlacement.make_hazard(pos)
```

- `LevelData` (`scripts/resources/level_data.gd`) is still a proper
  `Resource` subclass.
- `LevelManager.LEVEL_PATHS` is the ordered list of dev/regression level
  scripts. Adding level 16 means adding one path to that array and one
  file — nothing else changes. This scaled cleanly from 5 to 15 levels in
  Milestone 2 with zero changes to `LevelManager`, `LevelSelect`, or the
  save format.
- **Milestone 4 (`DECISIONS.md` D54) added `LevelManager.CAMPAIGN_LEVEL_PATHS`**,
  an identically-shaped, separately-cached parallel array for the real,
  player-facing 100-level campaign (`levels/campaign/stage_0N/`). Adding
  a level works exactly the same way - one path, one file - and adding a
  whole new stage is just 10 more paths appended in order (see
  `CAMPAIGN_DESIGN.md` section 13). `LEVEL_PATHS`/`get_level()` and
  `CAMPAIGN_LEVEL_PATHS`/`get_campaign_level()` are completely
  independent - see the "Save format" section below for why the save
  data backing them had to be namespaced separately too, not just the
  level source.

### `.tres` support (Milestone 3)

The level editor (`tools/level_editor/`, see "Editor architecture"
below) saves/loads levels as real `.tres` Resource files via
`ResourceSaver.save()`/`load()`, rather than generating `.gd` scripts.
`LevelManager.load_level_from_path(path) -> LevelData` is the one place
that resolves either format transparently:

```gdscript
static func load_level_from_path(path: String) -> LevelData:
    var resource = load(path)
    if resource is LevelData:
        return resource          # .tres: already a live instance
    if resource is GDScript:
        return resource.new()    # .gd: extends LevelData, needs instantiation
    return null
```

`LevelManager.get_level(level_id)` calls this internally, so every
existing caller (`GridManager.load_level()`, `game.gd`, etc.) is
unaffected regardless of which format a given `LEVEL_PATHS` entry
happens to be. See DECISIONS.md D25 for why `.tres` is used by the
editor specifically (not a blanket migration - Levels 1-15 remain `.gd`
files) and why this is safe now in a way it wasn't for Milestone 1's
hand-authored-`.tres` concern (D1).

A full save → load roundtrip (including nested `Array[TilePlacement]`
sub-resources, enums, and booleans) was automated and confirmed lossless
- see `TEST_PLAN.md`.

## Save format

`SaveManager` (`scripts/managers/save_manager.gd`) persists to
`user://savegame.json` as a flat JSON object:

```json
{
  "version": 2,
  "highest_unlocked_level": 3,
  "completed_levels": { "1": true, "2": true },
  "best_moves_per_level": { "1": 1, "2": 3 },
  "best_stars_per_level": { "1": 3, "2": 2 },
  "sound_enabled": true,
  "music_enabled": true,
  "campaign_highest_unlocked_level": 2,
  "campaign_completed_levels": { "1": true },
  "campaign_best_moves_per_level": { "1": 1 },
  "campaign_best_stars_per_level": { "1": 3 }
}
```

- Missing file → defaults (`highest_unlocked_level` / 
  `campaign_highest_unlocked_level = 1`, everything else empty/true).
- Malformed JSON (parse failure, or top-level value isn't a `Dictionary`)
  → defaults, with a `push_warning`, not a crash.
- `record_level_result(level_id, moves_used, stars, total_level_count)` is
  the single write path used after a **dev/regression** level is solved
  (in practice, no longer called by any player-facing code path as of
  Milestone 4 — see below): it only raises `best_stars_per_level`/lowers
  `best_moves_per_level` (never overwrites a better result with a worse
  one) and unlocks `level_id + 1` if it isn't already unlocked. It calls
  `save_game()` itself — callers don't need to.
- **Milestone 4 (Production Campaign Phase 1, `DECISIONS.md` D54) added a
  fully parallel `campaign_*` field set and a `record_campaign_level_result()`
  write path**, identical in shape and behavior to the fields/method
  above, used by `game.gd`'s real player-facing solve path instead.
  Namespaced separately - not reusing the original fields - specifically
  because dev-level ids and campaign-level ids both start at 1 and would
  otherwise collide in the same `String` dictionary keys. `SAVE_VERSION`
  bumped 1→2 to record the schema growing; no migration code exists or
  is needed since every new field is additive with a `Dictionary.get()`
  safe default; a version-1 save loads correctly with fresh campaign
  progress and its original fields fully intact.
- Dictionary keys are level IDs converted to `String` (JSON object keys
  are always strings; this is intentional, not an oversight) - true for
  both the original and `campaign_*` field sets.
- **Guided Tutorial Mode added a third, similarly-namespaced field pair:
  `tutorial_highest_unlocked_level`/`tutorial_completed_levels`** (see
  `DECISIONS.md` D60, `TUTORIAL_SYSTEM.md`). No `tutorial_best_moves_
  per_level`/`tutorial_best_stars_per_level` fields exist - tutorials
  aren't scored. `record_tutorial_level_result(tutorial_level_id,
  total_level_count)` mirrors `record_campaign_level_result()` minus the
  stars/moves bookkeeping. `SAVE_VERSION` bumped 2→3 for the same
  purely-informational reason as the 1→2 bump - no migration code, a
  pre-Tutorial save loads correctly with fresh tutorial progress.

## Guided tutorial system

See `TUTORIAL_SYSTEM.md` for the full architecture (step types, forced-
interaction gate, highlight system, UI scenes, authoring guide) -
summarized here only for cross-reference from this file's other
sections. Key points that intersect with architecture documented
elsewhere in this file:
- A `TutorialLevelData` (`extends LevelData`) is simulated by the
  identical `LaserSystem`/`GridManager` described throughout this
  document - a tutorial adds only a `steps: Array[TutorialStepData]`
  field, never a parallel simulation path.
- `GridManager` gained two forced-interaction fields
  (`interaction_locked`, `interaction_restricted_to`, both inert by
  default) checked at the top of `_on_orientable_tile_clicked()` - the
  single tap handler described in "Progression logic"/gameplay sections
  below - and a `simulation_updated` signal, emitted at the end of
  `_simulate_and_draw()` (after target/switch/gate/hazard state is
  current), additive alongside the pre-existing `move_made`/
  `level_solved` signals.
- `TutorialManager` (`scripts/managers/tutorial_manager.gd`) is
  deliberately a `class_name extends RefCounted`, not a 4th autoload -
  see `CLAUDE.md` rule 6. `game.gd` owns one instance per tutorial play
  session.
- `GridManager.has_orientable_tile(pos)` (added by the D61 runtime fix):
  a fail-safe check `TutorialManager` calls before locking input to a
  `REQUIRE_TILE_TAP` step's target - if no MIRROR/SPLITTER exists at
  that position, input is left unrestricted and a `push_error` fires,
  instead of a silent, permanent input softlock.
- `TutorialDimOverlay` (added by the D62 visual focus fix, `scripts/
  ui/tutorial_dim_overlay.gd`): a `GridManager`-owned board dim with a
  transparent cutout around the highlighted tile, shown/hidden 1:1 with
  `set_highlight()`/`clear_highlight()` (no separate state). `GridManager.
  suspend_tutorial_focus()`/`resume_tutorial_focus()` temporarily hide/
  restore it around the Pause menu's own independent dim, so the two
  never stack into a near-black board.
- `GridManager.last_tap_cell` / `last_tap_accepted` /
  `last_tap_rejection_reason` / `tile_tap_attempted` signal (added by
  the D63 click input fix): QA-only diagnostics set at the very top of
  `_on_orientable_tile_clicked()`, before any guard clause returns, so
  even a rejected tap is recorded - `game.gd`'s QA debug overlay reads
  these to show `LAST TAP:`/`HIGHLIGHT:`/`ALLOWED:` live. The actual
  D63 root cause was unrelated to this gating logic - a `game.tscn`
  instance-level anchor override on `TutorialPanel` was silently
  intercepting taps before they ever reached `GridManager` at all - see
  `TUTORIAL_SYSTEM.md` section 13.

## Progression logic

- `SaveManager.is_level_unlocked(id)`: `id <= highest_unlocked_level`.
  `is_campaign_level_unlocked(id)`: same shape, against
  `campaign_highest_unlocked_level` - see D54.
- Level 1 (and campaign level 1) is unlocked by construction
  (`highest_unlocked_level`/`campaign_highest_unlocked_level` both
  default to `1`).
- `LevelManager.get_continue_level_id()`: the first unlocked-but-not-yet-
  completed dev/regression level, or `highest_unlocked_level` if
  everything unlocked has been completed. **`GameManager.continue_game()`
  calls `get_campaign_continue_level_id()` instead** (same logic, against
  the campaign fields) - this is the one real player-facing path today.

## Star calculation

`LevelManager.calculate_stars(level_id, moves_used)`:

```
moves_used <= optimal_moves                      -> 3 stars
moves_used <= optimal_moves + TWO_STAR_MOVE_MARGIN (2)   -> 2 stars
otherwise                                        -> 1 star
```

Completion always awards at least 1 star — there is no move-count path to
0 stars or to failing a level. See `DECISIONS.md` for why the margin is a
flat `+2` rather than a percentage.

## UI architecture

- Every screen is a `Control`-rooted scene using anchors/containers, not
  fixed coordinates — `CenterContainer`, `VBoxContainer`, `HBoxContainer`,
  `MarginContainer`, `GridContainer`, `ScrollContainer`.
- `unique_name_in_owner = true` + `%NodeName` lookups (`@onready var x =
  %NodeName`) are used instead of long `get_node()` path strings, so
  reparenting a node inside its own scene doesn't break the script.
- `level_select.gd` builds one `level_button.tscn` instance per level at
  runtime from `LevelManager.get_level_count()` — there is no hand-placed
  per-level UI, which is what lets this scale toward ~100 levels/10 stages
  without a rewrite (see `ROADMAP.md`; stage headers/grouping would be an
  additive change to `_populate_levels()`, not a redesign).

### Mobile UI sizing: touch targets and safe margins

Two shared scripts (`scripts/ui/`) standardize mobile-safe sizing across
every screen — see `DECISIONS.md` D10/D11 for the full reasoning:

- **`UIConstants`** (`ui_constants.gd`): two constants,
  `MIN_TOUCH_TARGET` (144) and `BASELINE_MARGIN` (96), both expressed in
  this project's UI units. These aren't arbitrary — the project's
  1080x1920 reference canvas approximates the Android "xxhdpi" convention
  (360dp-wide screen at 3x density), so these values are `48dp * 3` and
  `32dp * 3` respectively, landing inside the standard 44-56dp
  touch-target and 24-40dp safe-margin guidance ranges. Every button's
  `custom_minimum_size` across Main Menu, Level Select, Settings, the
  gameplay HUD, and the Level Complete popup is at least
  `MIN_TOUCH_TARGET` in its constrained dimension.
- **`SafeAreaMargin`** (`safe_area_margin.gd`, a `MarginContainer`
  subclass): the single node type every top-level screen uses for its
  outer margin, replacing Milestone 1's flat hardcoded margin values.
  Always applies `UIConstants.BASELINE_MARGIN` as a floor; on Android
  (`OS.get_name() == "Android"`), additionally widens each edge using
  `DisplayServer.get_display_safe_area()` vs. `DisplayServer.screen_get_size()`
  to react to real notches/cutouts/rounded-corners/gesture-nav areas,
  converting the real-pixel inset into this screen's own UI coordinate
  space via a runtime-measured scale factor (not an assumed formula —
  see the script's comments). Recomputes on `get_viewport().size_changed`,
  so window resizing (desktop) or rotation (device) doesn't require a
  scene reload.
- Applied to: `main_menu.tscn`, `level_select.tscn`, `settings_menu.tscn`,
  `game.tscn` (the gameplay HUD's `SafeMargin` node), and
  `level_complete_popup.tscn` (wrapping its `CenterContainer`, while the
  full-screen `Dim` overlay stays outside the margin so the dim still
  covers unsafe edges — only the interactive panel respects the inset).

## Input flow

- `MirrorTile`/`SplitterTile._gui_input(event)` checks for
  `InputEventMouseButton` with `pressed == true` and `button_index ==
  MOUSE_BUTTON_LEFT`, then emits `tile_clicked(grid_position)`. Both
  classes have the identical signal shape and are wired to the same
  handler (see below) — this is the only interactive-tap pattern in the
  game; every other new Milestone 2 tile (filter, portal, switch, gate,
  hazard) is non-interactive, changed only by the simulation result.
- This single path covers **both** desktop mouse and mobile touch: Godot's
  default project setting `input_devices/pointing/emulate_mouse_from_touch`
  (on by default) converts touch events into the same `InputEventMouseButton`
  stream that `_gui_input` receives. No separate touch-handling code exists
  or is needed.
- `grid_manager._on_orientable_tile_clicked(pos)` (renamed from Milestone
  1's `_on_mirror_clicked` once splitters needed to share it) is the only
  place mirror/splitter state actually changes: it flips the orientation
  in `tile_orientations`, updates the visual, emits `move_made` (which
  `game.gd` uses to increment the on-screen counter), and re-runs
  `LaserSystem.simulate_until_stable()`.
- Interaction after level completion: `grid_manager.is_solved` gates
  `_on_orientable_tile_clicked` — once solved, taps are ignored until
  `reset_level()` (which fully reloads from `level_data`, clearing
  `is_solved`) runs via Reset, Retry, or Next Level. A hazard hit does
  **not** set `is_solved` (see "Hazards" above), so it never blocks
  interaction either.

## Data flow summary (one full turn)

```
tap on a mirror or splitter (mouse or touch)
  -> MirrorTile/SplitterTile._gui_input()
  -> tile_clicked(grid_position) signal
  -> GridManager._on_orientable_tile_clicked(grid_position)
       - flips tile_orientations[grid_position]
       - updates the tile's visual orientation
       - emits move_made
       - calls _simulate_and_draw()
            -> LaserSystem.simulate_until_stable(level_data, tile_orientations)
                 -> internally: simulate() one or more passes, opening
                    gates between passes as their linked switches are hit
                    (see "Switches and gates" above)
            -> updates each TargetTile.activated / SwitchTile.activated /
               HazardTile.triggered / GateTile.is_open
            -> redraws one Line2D pair per beam SEGMENT (portal transits
               start a new segment - see "Laser visualization")
            -> if solved and not already solved: sets is_solved, emits level_solved
  -> game.gd._on_move_made() increments the HUD move counter
  -> game.gd._on_level_solved() [if solved]
       - LevelManager.calculate_stars(...)
       - SaveManager.record_level_result(...)
       - shows LevelCompletePopup with moves/stars/has-next-level
```

## Editor architecture (Milestone 3)

`tools/level_editor/level_editor.tscn` is an ordinary Godot scene (root
`Control`, non-`@tool` script) - run directly via F6 in the Godot
editor, never the project's `run/main_scene`. See DECISIONS.md D23 for
why this was chosen over an `@tool`/`EditorPlugin` approach, and D24 for
why it's excluded from the Android export filter.

**Runtime/editor separation:** the editor depends only on classes the
shipped game already depends on (`LevelData`, `TilePlacement`,
`GridTypes`, `LaserSystem`) plus three new pure-logic classes under
`scripts/tools/` (`LevelSolver`, `LevelValidator`, `LevelMetrics`) that
nothing in `scripts/gameplay/` or `scripts/managers/` ever references.
This one-directional dependency (editor → gameplay core, never the
reverse) is what makes the exclusion in D24 safe - removing
`tools/**` and `scripts/tools/**` from a build cannot break anything
that remains.

**State model:** the editor holds exactly one live `LevelData` instance
(`current_level`) at a time. Every UI action - placing a tile, editing a
property field, resizing the grid - mutates that same object graph
directly (GDScript objects are references, so a property field's
callback mutating `selected_tile.color` is immediately visible
everywhere else that reads the same `TilePlacement`). There is no
separate "editor model" translated to/from `LevelData` - the thing being
edited *is* the real data structure the game will eventually load.

**Grid view:** a `GridContainer` of plain `Button` cells (not the
gameplay `TileVisual` scenes - a deliberate simplification, see
`LEVEL_EDITOR.md` "Known limitations"), each showing a short text
abbreviation plus a color tint reflecting the tile's beam color/state
(e.g. `E>` for an emitter facing right, `S/` for a splitter in `/`
orientation, `G:A / OPEN` for a gate). Clicking a cell either places the
currently-selected palette tool's tile, erases whatever's there, or
selects it for inspection, depending on which palette tool is active
(a `ButtonGroup`-backed toggle row).

**Properties panel:** rebuilt from scratch (`_rebuild_properties_panel()`)
every time the selection changes, showing only fields relevant to the
selected tile's `tile_type` (see `LEVEL_EDITOR.md`'s table). Each field
control's change callback mutates the selected `TilePlacement` directly
and calls `_refresh_cell_visual()` to update that one grid cell's label.

**Save/Load:** `_on_save_pressed()` re-validates before writing (see
"Level validator" below) and blocks on any error; `_on_load_pressed()`
replaces `current_level` wholesale via
`LevelManager.load_level_from_path()`, then repopulates every UI field
from the freshly-loaded data (`_load_fields_from_level()`).

**Playtest:** `_on_playtest_pressed()` re-validates, then calls
`GameManager.start_editor_playtest(current_level)` - see "Editor
playtest hand-off" above for the full round-trip mechanism.

## Level solver (Milestone 3)

`LevelSolver.analyze(level_data, max_states) -> Dictionary`
(`scripts/tools/level_solver.gd`) - development-only, pure function,
zero dependency on the editor or any autoload. Full algorithm and
reasoning in DECISIONS.md D26/D27; summary of the actual mechanics:

- **State representation:** each rotatable `MIRROR`/`SPLITTER`
  (`LevelData.get_rotatable_tiles()`, stable array order) maps to one
  bit of an integer bitmask; a full board configuration is one bitmask.
  Fixed (non-rotatable) mirrors/splitters keep their authored
  orientation for every candidate state.
- **Search:** breadth-first, processed one full depth-layer at a time
  (`frontier`/`next_frontier` arrays), so every solved state discovered
  in the same layer is guaranteed to share the true minimum move count.
  A solved state is never expanded further (it's a terminal node in the
  search). The search stops the moment any layer contains at least one
  solved state - deeper layers cannot be shorter.
- **State evaluation:** every candidate calls the real
  `LaserSystem.simulate_until_stable()` - no separate/approximate beam
  logic exists in the solver.
- **Safety limit:** `DEFAULT_MAX_STATES = 65536`, checked per-state
  during the search; hitting it produces `status: "UNKNOWN"`, never a
  false `"UNSOLVABLE"` (see DECISIONS.md D27 for why these are tracked
  as genuinely distinct outcomes).
- **Solution reconstruction:** a `parent` dictionary
  (`bits -> {from, flip}`) recorded during the search lets
  `_reconstruct_path()` walk backward from any found solved state to the
  initial state, yielding one concrete move-by-move solution
  (`Array[{position, from, to}]`).
- **Decoy detection:** `_find_possible_decoys()` takes every found
  shortest-depth solution and, for each rotatable piece, checks whether
  toggling just that one bit (independently) still solves the level. A
  piece flagged this way didn't matter for that particular solution -
  purely informational, bounded cost
  (`shortest_solution_count * rotatable_count` extra `simulate_until_stable()`
  calls).

Result dictionary: `status` (`"SOLVABLE"`/`"UNSOLVABLE"`/`"UNKNOWN"`),
`trivial` (solved with zero moves), `optimal_moves` (-1 if not found),
`shortest_solution_count`, `states_explored`, `elapsed_ms`,
`solution_path`, `possible_decoys`.

## Level validator (Milestone 3)

`LevelValidator.validate(level_data) -> {"errors": Array[String], "warnings": Array[String]}`
(`scripts/tools/level_validator.gd`) - deliberately separate from the
solver (a structural/data check, no search). Checks performed (see
`LEVEL_EDITOR.md` for the player-facing description of each):

**Errors** (block Save/Playtest in the editor): non-positive or
implausibly large grid dimensions, any tile outside grid bounds, two
tiles sharing one cell, no `EMITTER` tile, no `required` `TARGET` tile,
a `PORTAL` `pair_id` with other than exactly 2 members, an empty
`pair_id`/`gate_id` where one is required, a `SWITCH` referencing a
`gate_id` no `GATE` tile has.

**Warnings** (advisory only): no rotatable pieces at all, an unusually
high tile count (>40), a `GATE` no `SWITCH` ever opens, and - the one
check that isn't purely structural - a "trivial solution" warning
(`_check_trivial_solution()` runs exactly one
`LaserSystem.simulate_until_stable()` call against the level's *authored*
initial orientations, not a full solver search, to check whether it's
already solved with zero moves).

## Level metrics (Milestone 3)

`LevelMetrics.compute(level_data, solver_result) -> Dictionary`
(`scripts/tools/level_metrics.gd`) - pure data aggregation: counts of
each tile type, rotatable vs. fixed piece counts, distinct beam colors
used, and (if a `solver_result` was supplied) the solver's
`optimal_moves`/`states_explored`/`shortest_solution_count` folded in
alongside the level's own declared `optimal_moves`. Also computes a
`mechanics_used` list and a `difficulty_band`/`difficulty_label` via a
transparent, documented heuristic - see DECISIONS.md D28 for the exact
formula and why it's explicitly non-authoritative.

## Milestone 2 test levels

10 additional development/test levels (`levels/level_06.gd` through
`level_15.gd`), one per major new mechanic (see `PROJECT_HANDOFF.md` for
the full per-level description and `TEST_PLAN.md` for each one's
hand-traced and automatically-verified solution). **As of Milestone 2
through the "APK Optimization + Asset Cleanup" build**, they were
exposed in Level Select alongside the 5 Milestone 1 levels via the same
`LevelManager.LEVEL_PATHS`/dynamic-button mechanism — no Level Select
code changed at the time (per that milestone's own explicit instruction
not to redesign it). **This is no longer current** - Milestone 4
(`DECISIONS.md` D54) repointed `level_select.gd` at
`LevelManager.CAMPAIGN_LEVEL_PATHS` instead, so none of these 15 levels
are player-reachable today. They remain fully intact and still used by
every regression script.

## Milestone 3 editor fixtures

`levels/editor_fixtures/*.gd` — 6 deliberately-broken or edge-case
levels used only to validate `LevelValidator`/`LevelSolver` themselves,
never referenced by `LevelManager.LEVEL_PATHS` or `CAMPAIGN_LEVEL_PATHS`
and excluded from the Android export (DECISIONS.md D24). See
`TEST_PLAN.md` for what each one proves:

- `fixture_invalid_portal.gd` — a portal with no partner (validator error, simulator fail-safe)
- `fixture_invalid_gate_ref.gd` — a switch referencing a nonexistent gate (validator error)
- `fixture_zero_move.gd` — solved with zero moves (validator warning, solver `trivial: true`)
- `fixture_unsolvable.gd` — genuinely no solution exists (solver `status: "UNSOLVABLE"`)
- `fixture_multi_solution.gd` — two independent one-move solutions to the same target (solver `shortest_solution_count: 2`)
- `fixture_search_limit.gd` — 9 rotatable pieces (8 purely decorative) to demonstrate `status: "UNKNOWN"` under an artificially small `max_states`, without affecting the level's real (fast, exhaustive) solve under the default limit

## Final asset integration (Milestone 4A)

Godot 4.7's Android exporter requires `rendering/textures/vram_compression/import_etc2_astc=true`, which was already set in Milestone 1 (D9) - no change needed for this milestone's new textures to compress correctly for Android.

### Where the final art actually came from - two overlapping generations, not one

Before this milestone, `assets/` contained **two separate, independently-generated art sets** covering the same gameplay tile types, with no documentation reconciling them: one folder-per-tile-type (`assets/gameplay/<type>/bs_tile_*.png`) and a second flat `assets/gameplay/pieces/bs_tile_*.png` set with slightly different names and extra variants (`mirror_locked`/`mirror_movable`) the first set lacks. Every PNG was pixel-inspected before use. **The folder-per-tile-type set (`assets/gameplay/<type>/`) is canonical** except for blocker and hazard, where that set's own version wasn't vetted and the `pieces/` version was confirmed clean - those two specifically come from `pieces/`. The `assets/gameplay/pieces/**` and `assets/gameplay/tiles/**` folders are excluded from the Android export filter (see `export_presets.cfg`) rather than deleted, so a future session can still inspect them if better source art needs picking later. Same situation for icons: `assets/ui/icons/` contains both a `bs_icon_{hint,pause,reset}.png` trio (an earlier, orphaned generation) and a full `bs_ui_icon_*.png` set covering every HUD/settings icon needed with consistent naming - **`bs_ui_icon_*` is canonical**, the three `bs_icon_*` files are excluded from export and unused. `assets/branding/bs_app_icon.png` (not the `assets/branding/app_icon/` copy) is the canonical app icon.

### Gameplay tile visuals: texture where safe, procedural where not (rule 7/8 in CLAUDE.md)

Every generated gameplay-tile PNG was opened and visually inspected for a **baked-in illustrative laser beam** - a beam painted directly into the tile artwork at a fixed direction and, in the case of the color filter, a fixed color pair (blue-in/red-out). This was pervasive: **in both art generations**, the emitter, splitter, portal, switch, and color filter tiles all bake in a fixed-direction/fixed-color beam that would actively misrepresent per-level data (an emitter's `direction`/`beam_color` are level data, per rule 8; a filter's `output_color` likewise) and would visually conflict with the real, dynamically-simulated `Line2D` beam `grid_manager.gd` already draws (rule 8/9's whole point). No image-editing tool (ImageMagick, PIL) was available in the environment this milestone was done in, so these five tiles could not be safely cropped/masked into clean derived art - see DECISIONS.md D31 for the full reasoning and what a future session with image tooling could do instead.

**Result - which tiles use final art vs. which stay procedural:**

| Tile | Visual today | Why |
|---|---|---|
| Mirror | Final art (`mirror/bs_tile_mirror.png`), rotated 90° per orientation, tinted grey + a lock icon overlay when fixed | Source art's diagonal is self-illuminated, not a beam-in-flight - confirmed clean. **Rotation-to-orientation mapping verified correct as of Milestone 4A.2** (unrotated = SLASH, 90° = BACKSLASH) after Milestone 4A shipped it backwards - see DECISIONS.md D40, and CLAUDE.md rule 12c for the general lesson. |
| Target | Final art (`target/bs_tile_target.png`), tinted red/green for inactive/active, dimmed for optional; the colored required-color ring stays a procedural overlay (per-level, per-color data with no art equivalent) | Confirmed clean |
| Blocker | Final art (`pieces/bs_tile_blocker.png`) | Confirmed clean |
| Gate | Final art, swaps `gate/bs_tile_gate_open.png` / `bs_tile_gate_closed.png` on `is_open` | Confirmed clean, matched pair |
| Hazard | Final art (`pieces/bs_tile_hazard.png`), tinted brighter red when triggered | Confirmed clean |
| Emitter | **Still procedural `_draw()`, unchanged from Milestone 1/2** | Every available source bakes a fixed-direction beam through the body |
| Splitter | **Still procedural**, unchanged | Same |
| Portal | **Still procedural**, plus a new idle pulse animation (see below) | Same |
| Switch | **Still procedural**, unchanged | Same |
| Filter | **Still procedural**, unchanged | Baked art also hardcodes blue-in/red-out, doubly wrong for data-driven color |

Every tile - textured or procedural - now sits on a shared cell background (`assets/gameplay/grid/bs_tile_grid_base.png`), drawn by `TileVisual._draw()` itself (`scripts/gameplay/tile_visual.gd`) before any subclass content, so a subclass calling `super._draw()` first (every procedural tile already did, unchanged) gets the new background for free with zero script changes. `GridManager` additionally fills every **empty** grid cell (no tile placed) with the same background texture via a new `_background_root` layer, positioned/resized alongside `_tiles_root` in `_recalculate_layout()` - previously an empty cell showed nothing but the thin grid line.

The 5 texture-based tiles use `draw_texture_rect()` inside their own `_draw()` override (not `Sprite2D`/`TextureRect` child nodes) specifically so layered content (a tint, an overlay ring, a lock icon) composites in the correct paint order within one canvas draw call - a child node would render *after* the parent's own `_draw()` regardless of add order, which would put a background-texture child on top of procedural body art. The two Tween-driven feedback overlays (mirror selection pulse, target activation pulse - see "Interaction feedback" below) are the only tile elements using real child `TextureRect` nodes, because a Tween animates node properties (`modulate`, `scale`), not custom draw-call parameters.

### Interaction feedback (Milestone 4A)

- **Mirror**: tapping a rotatable mirror plays a brief scale/fade pulse of `bs_fx_mirror_selection.png` (`MirrorTile._play_selection_pulse()`), purely cosmetic.
- **Target**: the moment `activated` transitions false→true, a brief pulse of `bs_fx_target_activated.png` plays (`TargetTile._play_activation_pulse()`).
- **Portal**: since it's still procedural, a lightweight continuous idle pulse (`_process()` accumulating a phase, `sin()`-driven ring alpha/radius wobble) replaces a static ring - cheap enough per-portal (a level has at most a handful) to run continuously; it naturally stops while `get_tree().paused` is true (default `PROCESS_MODE_INHERIT` under the paused tree).
- **Gate**: already covered by the closed/open texture swap above.
- **Switch/hazard**: already covered by their existing tint-swap `_draw()` logic (brighter yellow when activated / brighter red when triggered) - no new asset needed.
- **Laser impact** (`bs_fx_laser_impact.png`): deliberately **not** wired up. The target-activation pulse already gives beam-reaches-target feedback; a second overlay at the same location would be redundant draw-call cost for no clearer signal, and the brief explicitly says to use impact VFX "selectively" and to avoid expensive mobile VFX.

### Laser visual upgrade (Step 9) - rendering only, zero simulation change

`GridManager._redraw_beams()` (unchanged data: `LaserSystem`'s `beams`/`segments`/`color` result) got a purely cosmetic tuning pass: `BEAM_GLOW_WIDTH` raised slightly, the core `Line2D`'s color is now `render_color.lerp(Color.WHITE, BEAM_CORE_BRIGHTEN)` for a brighter, more saturated center against the glow (a free "bloom" look, zero shader/extra-draw-call cost), and both `Line2D`s now use `LINE_JOINT_ROUND`/`LINE_CAP_ROUND`/`antialiased = true` for smoother segment joins. The portal no-line-across-the-gap behavior (D17/D21) was already correct before this milestone and needed no change - a portal transit already starts a new segment, so there was never a line to remove.

### UI theme (`themes/beamshift_theme.tres`)

A single shared `Theme` resource, set as the project-wide default via `project.godot`'s `[gui] theme/custom`. Every `Button` across every scene picks up its `normal`/`hover`/`pressed`/`disabled`/`focus` `StyleBoxTexture` (built from `bs_ui_button_primary.png`, tinted via `modulate_color` for hover/pressed rather than needing separate art) automatically, with **zero per-scene Button styling code** required. A `DangerButton` theme type variation (`bs_ui_button_danger.png`) is applied via `theme_type_variation = "DangerButton"` on Quit (Main Menu) and Main Menu (Pause menu) specifically - the two "leave what you're doing" actions.

**Milestone 4A.1 correction:** Milestone 4A's original flat 180px margin guess (D36) was wrong - viewing `bs_ui_button_primary.png` directly showed roughly 20% of the image's height is transparent glow padding above/below the actual button shape, and margins that large don't fit inside the project's real button heights (110-160px) anyway. Each button `StyleBoxTexture` now has `region_rect = Rect2(35, 165, 1705, 545)` (crops the padding out before 9-slicing) plus much smaller `texture_margin` values (70px sides, 32px top/bottom) sized for the actual on-screen button height range - see D37/D38.

Panels (Settings, Level Complete, Pause) are **not** themed globally - each screen's own `PanelContainer` gets a one-off `StyleBoxTexture` sub-resource pointing at that screen's own panel art directly in its `.tscn`, since the three panels are visually distinct assets, not variations of one shared panel style. **Milestone 4A.1 correction:** all three panels have their screen's title baked directly into the art (a "PAUSE"/"SETTINGS"+gear/"LEVEL COMPLETE"+star header band) - Milestone 4A additionally drew a second, dynamic title `Label` on top with a flat 40px inner margin that didn't clear that header, causing visible overlap. The duplicate `Label`s were removed and each panel's `texture_margin_top` was re-measured against the actual art. See D38.

**Superseded by Milestones 4A.5/4A.6 (D48-D50):** the specific filenames
(`bs_ui_settings_panel.png`/`bs_ui_level_complete_panel.png`/
`bs_ui_pause_panel.png`) and margin values in the paragraph above are
from the *original* Milestone 4A/4A.1 art. All three panels were later
replaced with new portrait-oriented art
(`assets/ui/panels/bs_panel_{settings,pause,level_complete}_portrait.png`)
with different pixel-sampled `texture_margin_*` values - see
`CHANGELOG.md`'s "Milestone 4A.5"/"Milestone 4A.6" sections and
`DECISIONS.md` D48-D50 for the current art/margins. The *structural*
pattern described above (one-off `StyleBoxTexture` per panel, title
baked into the art, no duplicate title `Label`) is still accurate and
unchanged - only the specific asset files and measured margins changed.

The shared theme also gained `Label`/`Button` `font_outline_color`/`outline_size` (Milestone 4A.1, addressing the brief's text-readability requirement project-wide) and a defensive `Button/constants/icon_max_width = 64` in case `Button.icon` is ever used again (see the HUD icon note below for why this matters).

### Main Menu layout

`main_menu.tscn`'s content is a `VBoxContainer` with three children: a `CenterContainer`-wrapped Logo (natural size, sits at the top of the flow), a plain `Control` with `size_flags_vertical = EXPAND_FILL` (absorbs all leftover vertical space), and a `ButtonGroup` `VBoxContainer` (natural size, sits at the bottom of the flow). This is a standard "pin two things to opposite ends with a flexible spacer between them" pattern - it keeps the logo near the top and the buttons near the bottom regardless of screen height, without anchor-offset math. Buttons use `size_flags_horizontal = SHRINK_CENTER` (not `EXPAND_FILL`) with an explicit size hierarchy: Play 640×156 (primary, largest, font 34), Continue/Settings 560×132 (secondary, font 26), Quit 420×112 (`DangerButton`, smallest, font 24, desktop-only).

**Milestone 4A.1 correction:** Milestone 4A used one `CenterContainer` dead-centering logo+buttons together, and sized buttons at only 360×144 on the 1080-wide reference. Viewing `bs_bg_main_menu.png` directly showed a bright circular portal focal point and two bands of baked flavor text sitting in the exact vertical middle of the frame - dead-centering the button group placed it right on top of that, and the undersized buttons read as lost against the busy background. The background image itself is unchanged (kept per the correction brief's explicit instruction) - only where the logo/buttons sit relative to it, and how large they are, changed. See D38.

### Menu backgrounds V2 + readability scrim (D71)

Main Menu, Campaign Level Select and Tutorial Select each have their own
portrait background (`assets/ui/backgrounds/bs_bg_main_menu_v2.png`,
`bs_bg_campaign_select_v2.png`, `bs_bg_tutorial_select_v2.png`; 941×1672).
Each scene's full-rect `Background` `TextureRect` is `EXPAND_IGNORE_SIZE` +
`KEEP_ASPECT_COVERED` — fill and center-crop, never stretch — so on taller
phones the side edges are trimmed rather than distorted. Between
`Background` and the UI each scene has a `ReadabilityScrim` `TextureRect`
(`mouse_filter=IGNORE`, inline `GradientTexture2D`, dark blue-black,
alpha ≤ 0.30): a bottom-weighted vertical ramp on the Main Menu, a
center-weighted horizontal ramp on the two select screens. Scene-local by
design — see D71 before moving it into the shared theme. The Main Menu
`Logo` not drawing (zero width in its `CenterContainer`) and the small
Back button on the select screens are pre-existing and unchanged.

### Gameplay background — minimal treatment (D90)

`game.tscn`'s root `Background` `TextureRect` (`unique_name_in_owner`,
`%Background`) is fed by `game.gd._apply_era_theme()`, which swaps only
its `.texture` (Era 1 → `assets/backgrounds/gameplay/bs_bg_gameplay.png`,
Era 2 → `assets/gameplay/backgrounds/era2/bs_bg_gameplay_era2.png`, any
future era with no theme built yet → falls back to Era 1's texture, same
as every other Era-1-default field on `EraTheme`). As of the Minimal
Gameplay Background pass this node also carries a fixed
`modulate = Color(0.22, 0.26, 0.38, 1)`, set once in `game.tscn` and
never touched by `_apply_era_theme()` or any other script — so the
darkening is a permanent property of the node itself, applied uniformly
under whichever texture is active, current or future, with no per-era or
per-level branching. The rationale: the source background art (both
Era 1's and Era 2's) has enough environmental detail — reflective
panels, glow strips, corner set-dressing — to visually compete with the
puzzle content once a board doesn't fill the whole playable rect (see
"Rectangular grid layout" below and `CLAUDE.md`'s Responsive rules for
why that gap exists on many boards/resolutions); a uniform multiply
tint recedes it without touching the PNG, the grid cell art
(`TileVisual.active_cell_background`, drawn as a separate `TextureRect`
per cell on top of `Background`), any tile script, or the beam `Line2D`
nodes `LaserSystem`/`_redraw_beams()` produce. RENDERED-verified
(D45-D47 tier) at 720x1280/1080x1920/1080x2400 for Campaign Levels 1,
100, 102 (Era 2), and procedural Level 1000 — HUD pixels confirmed
bit-for-bit unchanged by direct sampling, not just visual inspection.
See `CLAUDE.md` rule 16 and `DECISIONS.md` D90 for the full writeup and
the standing "don't re-tune this value casually" rule.

### Level Select rework

`level_button.tscn`/`level_button.gd` changed from composing everything as `Button.text` (including Unicode star glyphs) to a background `TextureRect` swapped per state (`bs_ui_level_button_{locked,unlocked,completed}.png`) plus a dynamic `NumberLabel` (level number, still real Godot text, never baked into an image) and a row of 3 `TextureRect` stars swapped between `bs_ui_star_earned.png`/`bs_ui_star_unearned.png`. The button itself is `flat = true` so the shared theme's pill-shaped Button stylebox doesn't draw underneath the card art. `NumberLabel`/`StarsRow` anchors are positioned to match the card art's actual two zones (a large upper hex area for the number, a smaller lower notch tab for the stars) - re-measured in Milestone 4A.1 after viewing the art directly (Milestone 4A had guessed an arbitrary 0-72%/68-88% split).

`level_complete_popup.tscn`/`.gd` got the identical star-icon treatment (replacing its `_stars_to_text()` Unicode approach) plus a new **Best Moves** row (`SaveManager.get_best_moves()`, read *after* `record_level_result()` so it reflects an improved run) - the star/move **calculation** itself (`LevelManager.calculate_stars()`, `SaveManager.record_level_result()`) is completely untouched, per the milestone's explicit "preserve the existing scoring algorithm exactly" requirement.

**Milestone 4A.1 correction (card sizing):** Milestone 4A gave cards a small `custom_minimum_size` but left `size_flags_horizontal/vertical = EXPAND_FILL`, letting `GridContainer` stretch them to fill each column at an inconsistent, non-square size - and, more seriously, preventing `ScrollContainer` from computing the grid's true content height (cards reporting a stretched size rather than their natural size broke the scroll-height calculation, which is almost certainly why the bottom row read as clipped). Cards are now a fixed 240×253 with `SHRINK_CENTER` flags, the grid is wrapped in a `CenterContainer` (so the 3-column block sits centered instead of packed to one side), and a 48px spacer follows the grid so the last row has breathing room when fully scrolled.

### Pause menu (new in Milestone 4A) and Android back handling

No pause menu existed before Milestone 4A - `scenes/ui/pause_menu.tscn`/`scripts/ui/pause_menu.gd` are new, following the exact same presentational-overlay pattern as `LevelCompletePopup` (signals relayed to `game.gd`, which owns all actual navigation/state). A new `PauseButton` in the gameplay HUD's bottom bar opens it; `game.gd._on_pause_pressed()` sets `get_tree().paused = true` and shows the overlay. The Pause menu's root `Control` (and `Game`'s own root) are `process_mode = PROCESS_MODE_ALWAYS` so the overlay's buttons and `game.gd`'s own script logic keep responding while the tree is paused - everything else (the grid, tile input, the portal idle-pulse `_process()`) inherits the default `PROCESS_MODE_PAUSABLE` and correctly freezes.

**Milestone 4A.1 correction:** the Pause panel's title-overlap and margin issues (see "UI theme" above) applied here too - fixed the same way (duplicate "PAUSED" `Label` removed, margins re-measured to 330/170/150 top/bottom/sides).

### Gameplay HUD icons - the dominant root cause of Milestone 4A's failure

`game.tscn`'s Back/Reset/Pause/Hint buttons originally (Milestone 4A) set a raw `Button.icon` (a 1254×1254 source PNG) with no `expand_icon` or `icon_max_width` constraint. Godot's `Button` renders `icon` at its native texture resolution by default - it does **not** scale down to fit the button - so the icon overflowed its ~150px button by close to 10x, visibly covering most of the puzzle board (this is what the user's manual QA reported as "Reset graphic is enormous"). The oversized icon also inflated its parent containers' computed minimum sizes, cascading up through the `HBoxContainer` → `PanelContainer` (which sizes itself to content) → the HUD's outer `VBoxContainer`, squeezing the space actually left for the puzzle grid - the second reported problem ("HUD artwork overlaps the playable area") was the same root cause, not a separate bug.

**Milestone 4A.1 fix:** every HUD icon button became a `flat = true` `Button` with a fixed touch-target `custom_minimum_size` containing exactly one child `TextureRect` at a fixed smaller size (`anchors_preset = PRESET_CENTER`, `expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`). The Control determines touch size; the `TextureRect` determines visual icon size - permanently decoupled from the source texture's own resolution, so no future icon swap can reintroduce this bug. This decoupling principle is still in effect today. See D37 for the full story, including why this shipped with zero automated errors in Milestone 4A (headless smoke tests check for script errors, not resulting control sizes).

**Superseded by "Android HUD Alignment + Missing Tile Fix" (D49/D52):**
`TopBar`/`BottomBar` are no longer `PanelContainer`s with a fixed
`custom_minimum_size.y = 160` and a `StyleBoxTexture` background. They
are now plain `Control`s running a new `scripts/ui/aspect_bar.gd`
(`class_name AspectBar`) that locks bar height to the current HUD art's
aspect ratio on every resize (so the art is never stretched/distorted),
with a plain `TextureRect` background and interactive children
positioned via pixel-measured fractional anchors instead of an
`HBoxContainer`. See D49 for why (the new HUD art has a structural
reactor-icon centerpiece a fixed-height stretch would distort) and D52
for the exact current slot-anchor fractions. The icon-decoupling pattern
in the paragraph above is unchanged; only the bar's own sizing/background
mechanism changed.

### Settings toggle widgets

`bs_ui_toggle_on.png`/`bs_ui_toggle_off.png` are wide (~2.1:1) pill graphics with "ON"/"OFF" text baked directly into them - Milestone 4A used them as a `CheckButton` icon override, which renders at `CheckButton`'s small checkbox-glyph scale (illegible, and not what the art was designed for). **Milestone 4A.1 fix:** `settings_menu.tscn`/`.gd` replaced both `CheckButton` nodes with a `toggle_mode = true` `Button` (same persistent on/off state and `toggled(bool)` signal, still wired to `SaveManager.sound_enabled`/`music_enabled` identically) sized 240×120, containing one child `TextureRect` whose `texture` is swapped between the on/off art in the `toggled` handler - the same "Control decides touch size, TextureRect decides visual size" pattern as the HUD icons above. See D39.

Resume/Restart/Settings/Level Select/Main Menu each unpause first, then either hide the overlay (Resume) or navigate exactly like the equivalent existing button already did (Restart = `_load_current_level()`, Level Select = the same `_on_back_pressed()` the HUD Back button uses, Main Menu = `GameManager.go_to_main_menu()`). Settings navigated to from Pause returns to Main Menu on its own Back button (existing `settings_menu.gd` behavior, unchanged) rather than back into the paused game - a deliberate, documented minimal-scope choice rather than rearchitecting Settings' return path; no puzzle progress is lost either way since nothing is saved until a level is solved.

**Android back button:** previously unhandled - Godot's default `application/config/quit_on_go_back = true` meant the OS back gesture during gameplay would silently exit the app. This milestone sets it `false` project-wide and gives every top-level screen (`main_menu.gd`, `level_select.gd`, `settings_menu.gd`, `game.gd`) its own `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` handler that replicates exactly what its own Back/Quit button already does - Main Menu quits (matching the previous default), Level Select/Settings go to Main Menu, and **Game specifically opens/closes the Pause menu instead** (or does nothing if the Level Complete popup is showing, so it can't be dismissed accidentally mid-completion). The level editor (`tools/level_editor/`) intentionally has no such handler - it never ships (rule 9), so Android back-button behavior is meaningless there.

### Hint button (Step 11 -> Global Hint System, D97)

The Step 11 placeholder (a hidden, inert `HintButton`) was replaced by the real Global Hint System - see "Global Hint System (Phase 1, D97)" below and CLAUDE.md "Global Hint System rules". (Corrected in D100: this section once still claimed no hint system exists.)

### Stage Select - assets present, deliberately not wired up

`LevelData.stage` (Milestone 3 metadata) remains completely unused by any UI, exactly as before this milestone. `assets/ui/stage_select/`/`assets/ui/stage_complete/` (8 PNGs) exist but there is still no `scenes/ui/stage_select.tscn` or equivalent script anywhere - building one would be a new screen and a new navigation flow (Level Select would need to change from "flat list of levels" to "pick a stage, then pick a level within it"), which is feature work, not visual re-skinning of something that already exists. See DECISIONS.md D33 for why this was deliberately deferred rather than attempted partially.

### Temporary QA build identifier (Milestone 4A.3)

`main_menu.tscn` and `settings_menu.tscn` each carry a small, low-opacity
`Label` ("BUILD 4A.3") in the bottom-right corner, added so a physical
device tester can visually confirm which build is actually installed -
see `DECISIONS.md` D44 for why this was needed (a same-versionCode
reinstall can silently leave a device on a stale APK). **This is QA-only
and must be removed before any real release build** - it's not gated
behind a debug flag, it will show in a release export too if left in.
`export_presets.cfg`'s Android `version/code`/`version/name` were also
bumped (`1`/`"1.0"` → `5`/`"1.0.0-4A.3"`) for the same reason, on the
theory that install tooling is more likely to treat a version bump as
"genuinely new" even if the build-label removal is missed.

### App icon / Android launcher icons

`project.godot`'s `config/icon` and `export_presets.cfg`'s `launcher_icons/main_192x192`/`launcher_icons/adaptive_foreground_432x432` all point at `assets/branding/bs_app_icon.png` directly (1254×1254, no alpha). Godot's Android exporter generates the actual `mipmap-*dpi` webp variants and the adaptive-icon XML from this one source at export time - confirmed by inspecting the exported APK's `res/mipmap-*/icon*.webp` and `res/mipmap-anydpi-v26/icon.xml` after export. `launcher_icons/adaptive_background_432x432`/`adaptive_monochrome_432x432` were left empty (no dedicated background-layer or monochrome-silhouette source art exists) - a future pass with image-editing tooling could split the icon into proper adaptive foreground/background layers instead of one flat image.

## Era system and Era 2 mechanics (Era 2 Foundation)

Full technical reference: `ERA_2_DESIGN.md`. Summarized here for the
architecture overview:

- **`EraTheme`** (`scripts/resources/era_theme.gd`) is a plain
  `Resource` with static helpers (`get_era_for_level()`,
  `get_era_for_tutorial()`, `for_era()`) — not an autoload, since it
  owns no per-session state, only a lookup table from a level/tutorial
  number to that era's themed assets. Era 1's theme fields are all
  `null`, read by every caller as "use the existing hardcoded Era 1
  asset" — this is the mechanism that keeps Levels 1-100/T01-T10
  visually unchanged no matter how many future eras get added.
- **Unified Blue Theme Fix (D91)**: `EraTheme.UNIFIED_BLUE_THEME_ONLY :=
  true` is checked first inside `for_era()` and, when true, makes it
  always return the Era 1 asset set regardless of `era_number` — Era 2's
  own violet/magenta theme (`_build_era_2()`) is fully intact in source
  but unreachable while this flag is on, so every gameplay screen
  (background/grid/HUD via `game.gd._apply_era_theme()`, plus
  `level_button.gd`/`tutorial_button.gd`'s accent tint and
  `level_select.gd`/`tutorial_select.gd`'s background, all of which
  already routed through this same function) renders in the one blue/
  cyan theme regardless of level/tutorial number. `get_era_for_level()`/
  `get_era_for_tutorial()` and their two non-visual callers
  (`LevelManager.is_tutorial_level_selectable()`'s unlock gate, `game.gd`'s
  Level 100→101 `era_transition` banner) read the numeric era directly
  and never touch this flag, so unlock progression and mechanic-teaching
  order are completely unaffected by the theme decision. Prism/One-Way
  Reflector/Beam Receiver/Remote Emitter's own tile textures are
  unconditional `preload()`s in their own scripts, never routed through
  `EraTheme` — they were, are, and remain genuinely purple-specific art,
  independent of this flag entirely.
- **Four new `GridTypes.TileType` values** (`PRISM`,
  `ONE_WAY_REFLECTOR`, `BEAM_RECEIVER`, `REMOTE_EMITTER`), appended at
  the end of the enum so every Era 1 value keeps its numeric identity.
  Each has an exact, fully deterministic rule documented in
  `ERA_2_DESIGN.md` sections 3-5 and implemented in `GridTypes`/
  `LaserSystem`. One-Way Reflector reuses the existing rotatable-tile
  abstraction (`LevelData._ORIENTABLE_TILE_TYPES`) with zero
  `LevelSolver` changes; Prism/Beam Receiver/Remote Emitter are never
  rotatable, so they don't touch the solver at all.
- **`LaserSystem.simulate()` gained a 4th parameter, `receiver_states`**
  (`link_id -> bool`), threaded through `simulate_until_stable()`
  alongside `gate_states` and resolved by the identical monotonic-merge
  multi-pass strategy already used for switch → gate (see "Switch/gate
  simulation strategy" in `DECISIONS.md`). `simulate()` has no other
  callers outside `simulate_until_stable()`, so this was a safe, fully
  internal signature change.
- **Four new tile visual scripts** (`PrismTile`, `OneWayReflectorTile`,
  `BeamReceiverTile`, `RemoteEmitterTile`, all `extends TileVisual`) use
  the confirmed beam-free `_base`/`_inactive` Era 2 art, following the
  exact rule 10 the original 5 tile types established — the plain
  (non-`_base`) Era 2 reference art bakes in fixed-direction/fixed-color
  illustrative content and is never `preload()`-ed by any script.
  `TileVisual.active_cell_background` became a *static* class member
  (was a per-script constant) so `game.gd` can swap the active era's
  grid cell art in one place and have every tile subclass's
  `super._draw()` pick it up for free.
- **`Era2ActivationFX`** (`scripts/gameplay/era2_activation_fx.gd`) is a
  second, parallel VFX system alongside `LaserMirrorImpactFX` — same
  architecture (procedural `_draw()`, one `CanvasItem` + one `Tween`,
  self-freeing, player-taps-only, reads only the already-computed
  `_last_result`), different trigger set (Prism/reflective One-Way
  Reflector/Beam Receiver/Remote Emitter instead of Mirror), different
  palette (violet/magenta instead of cyan).
- **QA/Hardening pass addition (D78)**: `EraTheme` gained `level_
  complete_panel`/`level_complete_panel_margins` and `tutorial_
  complete_panel`/`tutorial_complete_panel_margins`. `LevelCompletePopup`/
  `TutorialCompletePopup` each gained a `set_era_panel(texture, margins)`
  method that swaps their `PanelContainer`'s `StyleBoxTexture` at
  runtime (`texture == null` restores the popup's own `.tscn`-authored
  default), called from `game.gd._apply_era_theme()` alongside the
  existing background/HUD/grid swap — the same per-screen-art-but-era-
  aware pattern `CLAUDE.md` rule 11 already established for HUD bars,
  extended to the two completion popups. Two rendering pitfalls to
  remember if extending this pattern further: `StyleBoxTexture.
  content_margin_*` defaults to `-1` ("same as `texture_margin_*`") —
  don't override it with a smaller value copied from a different style;
  and a `PanelContainer` sizes to its own content, so a themed frame
  with large top/bottom margins needs `custom_minimum_size.y` forced to
  at least that margin sum or the frame's own corner art gets squeezed.
- **Levels 101-110 pass addition**: `tutorial_button.gd`/`level_button.gd`
  no longer swap texture per era at all — the section above's Era 2 card
  art (`bs_level_card_era2.png`, a 1024x1536px asset) turned out to be
  proportioned for a panel/poster, not the 240x253 button box it was
  wired into, producing a cropped, frame-less look once actually
  rendered. Both scripts now always use the same three Era 1 textures
  (locked/completed/unlocked) and apply `_background.modulate =
  EraTheme.for_era(era).accent_color` instead — `Color.WHITE` for Era 1
  is a no-op tint, so this is the general pattern any future Era's
  button identity should follow, not a one-off fix. Campaign Levels
  101-110 (`levels/campaign/era2_stage_01/`) are the first level
  population to actually exercise `EraTheme.get_era_for_level() >= 2`
  in Level Select — see `CAMPAIGN_DESIGN.md` section 15 and `ERA_2_
  DESIGN.md` section 12.
- **Levels 111-120 pass**: pure level-data addition, zero engine/
  architecture changes — every mechanic these ten levels use already
  existed. Confirms the level-authoring discipline itself, not new
  code: a beam that has already activated its own required target
  keeps traveling (targets never stop a beam, by design — see "Laser
  propagation algorithm" below), so any level design that places a
  second meaningful tile in that continuation's path risks an
  unintended interaction. Three real instances were caught by the
  solver during authoring, not by architecture review — see
  `CAMPAIGN_DESIGN.md` section 16 and `DECISIONS.md` D81.
- **Levels 121-130 pass**: also pure level-data addition, zero engine
  changes. Surfaced a related but distinct authoring-discipline lesson:
  a wrong-orientation rotatable tile's stray beam path can cross
  ANOTHER tile elsewhere on the board, and that second tile's own
  default orientation may silently complete an unintended shortcut —
  `LaserSystem` has no concept of "which mechanic a cell belongs to,"
  so it treats a stray beam exactly like an intentional one. See
  `CAMPAIGN_DESIGN.md` section 17 and `DECISIONS.md` D82 (Level 127).
- **Levels 131-140 pass**: also pure level-data addition, zero engine
  changes - the most shortcut-prone batch yet (5/10 levels needed
  fixes), confirming the same two lessons above generalize further: a
  `WHITE`-required target's "accepts any color" semantics can make a
  wrong-orientation shortcut invisible even when the shortcut SWAPS
  which beam reaches which target (Level 134), and a shared reflector's
  two beams must be checked for corridor overlap in BOTH directions
  (approach and exit), not just differing entry directions (Level 138,
  which needed a full geometric rebuild). See `CAMPAIGN_DESIGN.md`
  section 18 and `DECISIONS.md` D83.

## Procedural level generator (Phase 3)

Full architecture in `PROCEDURAL_GENERATION.md` (read that first);
summarized here for the project's own architecture-map continuity.

`scripts/procedural/` (runtime, NOT export-excluded) generates a
deterministic `LevelData` for any level number 1-2000 on demand:
`ProceduralSeed` derives a seed from `(level_number, generator_version,
attempt)`; `ProceduralDifficultyProfile` looks up that level's difficulty
band (board-profile candidates, template pool, tile/rotatable budgets);
`ProceduralTemplates` builds a solution-first `LevelData` (the intended
solved path first, then scrambles rotatable tiles away from it) using
only the existing `TilePlacement.make_*()`/`GridTypes` API - no new
simulation logic; `ProceduralLevelGenerator` orchestrates attempt/retry
and self-verifies each candidate via a direct
`LaserSystem.simulate_until_stable()` call against the template's own
known solution (never a BFS search, never `LevelSolver`/`LevelValidator`
- those stay dev-only, see rule 9 and `PROCEDURAL_GENERATION.md` section
5).

`scripts/tools/procedural_audit.gd` (dev-only, export-excluded like
`LevelSolver`/`LevelValidator`/`LevelMetrics`) is the one place those
dev-only tools ever run against generated content - it exhaustively
proved the generator's own output across the full 1-2000 range during
this phase (see `DECISIONS.md` D88), the same "prove it once during
authoring, never at runtime" relationship the 140 handcrafted campaign
levels already have with `LevelSolver`.

Runtime integration follows the exact same branching pattern Tutorial/
editor-playtest already established in `game.gd`/`GameManager`: a new
`is_procedural_mode` flag, a new `_load_current_level()` branch, new
`SaveManager.procedural_*` fields mirroring `campaign_resume_*` (see
`PROCEDURAL_GENERATION.md` section 10 for the exact schema). Main Menu's
`PLAY`/`CONTINUE` now target this population instead of Campaign; the
legacy Campaign remains reachable only through the existing QA Level
Select screen, unchanged.

## Audio architecture (Audio/SFX Integration Pass)

Full architecture in `AUDIO_SYSTEM.md` (read that first); summarized here
for the project's own architecture-map continuity.

`scripts/managers/audio_manager.gd`, autoload `AudioManager` (4th
autoload, after `SaveManager`/`LevelManager`/`GameManager`), owns the
project's ONE audio pipeline: 22 semantic `play_*()` methods, a fixed
10-voice `AudioStreamPlayer` pool (round-robin, never grown at runtime),
and the `Master`/`SFX`/`UI` bus routing (`assets/audio/default_bus_layout.tres`).
No script anywhere else references an `assets/sfx/*.ogg` path or
instantiates its own `AudioStreamPlayer`.

Gameplay audio is driven entirely by state transitions read out of
`GridManager`'s already-computed simulation result, gated behind
`_simulate_and_draw()`'s existing `play_impacts` parameter (the same
flag Milestone 4A's mirror-impact VFX already used) so it only ever
plays for a genuine accepted player move:
`_play_state_transition_audio()` diffs each target/switch/hazard/gate/
receiver/remote-emitter node's state before vs. after this pass;
`_play_beam_interaction_audio()` walks `_last_result["beams"]`'s segments
to detect (and de-dupe, per grid position) mirror/one-way-reflector
reflections, splitter/prism branches, filter crossings, and portal
traversal. `mirror_rotate` and `puzzle_solved` are each called from the
one exact point in `GridManager` where that event is structurally
guaranteed real (an accepted rotation; the `is_solved` false→true
transition). UI audio is ordinary per-button `.pressed.connect(AudioManager.play_*)`
wiring across every screen script - a second signal connection alongside
each button's existing action, never a replacement for it.

`LevelData`/`TilePlacement` gained zero fields for this - audio is
entirely event-driven, so every existing and future level (including all
2,000 procedural levels) gets it automatically with no per-level
authoring.



## Procedural difficulty contract (Difficulty System Phase 1)

Three runtime-safe, solver-free `RefCounted` classes in `scripts/procedural/`
sit beside the generator but are **not yet on its accept path**:
`ProceduralDifficultyContract` (pure data: `get_difficulty_requirements(level)`),
`ProceduralComplexity` (metrics by ablation - remove a special tile / revert a
move, re-run `LaserSystem.simulate_until_stable()`, compare activated targets),
`ProceduralTriviality` (metrics x requirements -> `TRIVIAL_*` reasons). None
re-implements a beam rule (rules 1/3/9). The contract is the product target;
`ProceduralDifficultyProfile` remains how current templates are configured
(V1/V2 frozen). Phase 2 wires templates to the contract via construction
(`GENERATOR_VERSION` 3). Dev-only `scripts/tools/difficulty_inspect.tscn`
prints contract/metrics/verdict per level. See `PROCEDURAL_GENERATION.md`
section 17 and `DECISIONS.md` D93.



## Generator V3 (Difficulty System Phase 2A)

`ProceduralGeneratorV3` pipeline: requirements -> `ProceduralPlannerV3`
(logical `ProceduralPlanV3`) -> `ProceduralLayoutV3` (macro-layout) ->
`ProceduralBoardV3` + `Cursor` (beam routing, orientations via
`GridTypes.reflect`) -> derived start state -> `ProceduralComplexity` /
`ProceduralTriviality` gates. Runtime-safe (LaserSystem only). Entry: explicit
`generate(n, 3)` or `GameManager.start_v3_prototype()` (dev-only sub-mode of
procedural mode, no SaveManager access). Dev-only audit:
`scripts/tools/v3_prototype_audit.tscn`. See `PROCEDURAL_GENERATION.md` 18.

**Phase 2A.1 (D95):** D/E/F layouts were rebuilt for reasoning depth
(globally constrained shared-tile decisions, decoy routes, explicit
per-tile `keep_correct` start states). New `Cursor` primitives
`to_one_way_hold` (a One-Way the beam must PASS) and `to_join` (a second route
ending on an existing tile); `ProceduralGeneratorV3.requirements_for(archetype)`
holds per-archetype acceptance profiles (A/B/C keep the Phase 2A one);
`ProceduralComplexity.start_state_visibility()`/`greedy_follow_solve()` are
runtime-safe structural QA metrics (LaserSystem only, no solver). See
`PROCEDURAL_GENERATION.md` 18.7.

## Generator V3 progression (Difficulty System Phase 2B)

`ProceduralProgressionV3.generate(level)` (reached by `ProceduralLevelGenerator.generate(n, 3)`)
scales the Phase 2A idea to Levels 1-2000. Pipeline: `ProceduralDifficultyContract`
band (+ `_V3_POLICY`) -> `ProceduralFragmentsV3.compose` (atom recipe: core pool +
escalation, predicted depth/kinds/deps; builds a *line tree* of source + tokens and a
turn-slot budget) -> `ProceduralComposerV3.build` (randomised depth-first router with
group-level backtracking and restarts; `Cursor` primitives place tiles and compute
mirror orientations via `GridTypes.reflect`) -> `ProceduralBoardV3.center_content()` ->
`ProceduralComposerV3.harden()` (wrong-ray blockers) -> `apply_keep_correct` ->
`ProceduralGeneratorV3._check` (validity, ablation metrics, load-bearing promises,
triviality) -> extra gates (early ceilings, plain/plausible shares) ->
`ProceduralShortcutProbe` (bounded beam search over touched-tile flips) -> greedy policy.
Runtime uses only `LaserSystem`; `LevelSolver`/`LevelValidator` stay dev-only
(`scripts/tools/v3_progression_sample.tscn`, `v3_progression_stats.tscn`).

Board additions used by the composer: `path_axis` (perpendicular-only crossing),
`snapshot()`/`restore()` (local rollback), `tile_line`, `center_content()`. The
six-prototype layout code (`ProceduralLayoutV3`, `ProceduralPlannerV3`) is unchanged.

Selection/versions: `LevelManager.USE_V3_FOR_PROCEDURAL_QA` +
`procedural_generator_version_for_new_play()` (new play only); `game.gd` keeps the loaded
puzzle's version in `_procedural_generator_version` (the completion branch and resume use
the SAME version); `SaveManager.procedural_resume_generator_version` decides resumes.
Result dictionary extras: `atoms`, `predicted`, `difficulty_band`, `target_move_range`,
`verified_optimal_moves` (-1), `greedy_solved`/`greedy_accepted`, `hardening`,
`tile_count`, `v3_generation_failed`. See `PROCEDURAL_GENERATION.md` section 19.

## Global Hint System (Phase 1, D97)

`HintManager` (RefCounted, per game scene) + `GridManager.show_hint_cell()` + the shared `HintButton`.
Flow: button -> `game.gd._on_hint_pressed()` -> `HintManager.request_hint()` (permission seam) ->
`grant_hint()` -> `get_hint_candidate()` (wrong required tile, beam-frontier first) -> `show_hint()` (ring +
existing `sfx_tutorial_step`). Grid `move_made` updates history and clears the ring when the hinted tile is
rotated. Solution sources: generator `solution_orientations` (procedural incl. V3 TEST),
`levels/hint_solutions.json` (offline solver, campaign "c<id>", tutorial "t<id>"), tutorial REQUIRE_TILE_TAP
target. `game.gd._load_current_level()` calls `configure()` on every load/Reset/QA jump.


## Advertising (AdMob Foundation V1, D98)

`AdManager` (autoload) -> `AdBackend` (`AdBackendAdMob` via the Poing AdMob plugin on Android/iOS; `AdBackendFake` in tests); `AdConfig` holds every ID/switch.
`game.gd` wires the Hint permission (`HintManager.permission_provider` -> `AdManager.show_rewarded_hint`), registers legitimate completions after
`record_procedural_level_result`, and asks `maybe_show_interstitial_after_completion` in `_on_next_level_pressed`. `SaveManager` gained three additive
ad fields. Android exports through Gradle (template in `android/build`, JDK 17). See `ADS_MONETIZATION.md`.


## Beam Fusion Node (Fusion Phase 1, D99)

`TileType.FUSION` + `FusionTile` (`fusion.tscn`) + LaserSystem fusion state (`simulate(..., fusion_states)`, replaced each pass in `simulate_until_stable`) + `GridTypes.combine_beam_colors`
+ appended `BeamColor` YELLOW/MAGENTA/CYAN. `GridManager` instantiates the tile into the shared orientable path and `_fusion_nodes` (active/colour/input display, `laser_split` on activation);
a Fusion tap rotates 4 states. QA puzzles: `levels/fusion_qa/fusion_qa_set.gd`, reached only via `GameManager.start_fusion_test`. Procedural use: see "Fusion procedural integration" below (Phase 2).

## Fusion procedural integration (Fusion Phase 2, D100)

Pipeline (generator V4 = `ProceduralProgressionV3.generate(level, 4)`): `ProceduralDifficultyContract.fusion_policy()` (band -> fragments F1-F7 + probability) -> ONE per-level roll (`ProceduralFragmentsV3.roll_fusion_recipe`, dedicated rng stream) -> recipe atoms (FU/FUF/FUP/FUG/PF/FU3 + escalation extras; Filters/second Prisms excluded, hops limited to 3 - inputs) -> line tree with `fusion`/`fjoin` tokens -> `ProceduralComposerV3` (`_place_fusion`, `_run_fjoin`, `_fusion_complete`: the node ends the first line, further inputs are goal-directed walks, the OUTPUT line is built when the last input has joined) -> `harden()` (also the node's wrong output rays) -> `ProceduralGeneratorV3._check` (ablation metrics, `fusion` is a special unit) -> `ProceduralFusionCheck` (per-input ablation, colour consumption, no feedback, settling of start/solved/neighbour states, WHITE guards) -> widened shortcut probe (1500 sims/width 28) -> greedy policy. Results add `fusion_fragment`, `fusion_report`, `fusion_present`. `LaserSystem.simulate_until_stable` now also returns `passes`/`converged`. `ProceduralComplexity.tap_orientation()/rotatable_types()` model the 4-state Fusion tap for greedy/probe. HUD QA tag: `V4 <band> <F1..F7>`.

Versioning/extension: V1/V2/V3 frozen (fingerprint-verified); `INITIAL_CERTIFIED_LEVEL_TARGET = 2000` (`MAX_LEVEL` derives from it); the contract reads its LAST band/policy/Fusion row for any level beyond 2000, so post-2000 progression is a data extension (see `DECISIONS.md` D100). Dev tools: `scripts/tools/fusion_progression_sample.tscn` (sample/frequency/stress/find), `fusion_verify.tscn` (bypass/omit/exact). Only `scripts/procedural/procedural_fusion_check.gd` is runtime.

## Fusion tutorial + generator hardening (Fusion Phase 3, D101)

- Tutorial: `levels/tutorial/t21.gd`-`t28.gd` (registered in `LevelManager.TUTORIAL_LEVEL_PATHS`), unlocked via `LevelManager.is_fusion_tutorial_selectable()` (not era-gated). No new autoload, no new tutorial class: `TutorialManager` (RefCounted, owned by `game.gd`) drives them exactly like T01-T20. Hint entries `t21`-`t28` are hand-authored in `levels/hint_solutions.json` (the offline builder skips them).
- Generator (V4 only): `ProceduralFragmentsV3` gained atom `FUK`, `FUSION_RECIPE_VARIANTS` and variant draws recorded in `plan.params["fusion_variant"]`; `ProceduralComplexity` ablates a Fusion into a blocker; `ProceduralFusionCheck` gained exact one-tap-away shortcut screens and `max_passes`. Still LaserSystem-only at runtime (rules 1/3/9); V1/V2/V3 frozen.

## Star scoring, Hint cap and QA/production switch (Phase 4, D102)

- `StarScoring` (`scripts/managers/star_scoring.gd`, static, no state) is the only star rule; `LevelManager.calculate_*_stars` and `game.gd._on_level_solved()` call it. `game.gd._hint_used_this_attempt` (set from `HintManager.hint_shown`) feeds it and is persisted in `SaveManager.procedural_resume_hint_used` / `campaign_resume_hint_used`. Records: `SaveManager.procedural_best_stars` (`"<level>|<generator_version>"`), existing campaign dictionary. Popup: `level_complete_popup.show_result(..., hint_used, show_stars)`.
- `BuildConfig` (`scripts/managers/build_config.gd`, constants only, not an autoload) -> `LevelManager` QA/unlock flags, `game.gd` tutorial overlay + generator tag.
- Main Menu builds the one-time Fusion tutorial nudge in code (`SaveManager.fusion_tutorial_nudge_seen`).

## Known architectural deviations from the milestone brief

See `DECISIONS.md` for full reasoning; summarized here for quick
reference:

- Levels are `.gd` Resource-subclass scripts, not hand-authored `.tres`
  files (still `Resource`-based, still data-only, still swappable later).
- `scripts/resources/` was added (not in the brief's suggested tree) to
  hold `LevelData`/`TilePlacement` — these are shared data types used by
  both the gameplay and level files, so they didn't fit cleanly under
  `scripts/gameplay/` or `scripts/managers/`.
- Tile visuals used procedural `_draw()` calls instead of textures/sprites
  through Milestones 1-3 (no art assets existed yet). **Milestone 4A
  partially superseded this**: 5 of 10 tile types (mirror, target,
  blocker, gate, hazard) now draw final generated art via
  `draw_texture_rect()` inside `_draw()`; the other 5 (emitter, splitter,
  portal, switch, filter) remain procedural because every available
  generated asset for them bakes in a fixed-direction/fixed-color
  illustrative beam - see "Final asset integration" above. Gameplay
  logic remains fully decoupled from this either way, per the original
  requirement.
- `TilePlacement` stayed one flat class with static factories rather than
  splitting into per-tile-type Resource subclasses (Milestone 2,
  DECISIONS.md D12) — GDScript's lack of keyword constructor arguments
  made the factory pattern equally ergonomic without the added file count.
- Switch/gate state is fully stateless/derived across player moves
  (Milestone 2, DECISIONS.md D18) rather than persisted — a deliberate
  simplification beyond what the brief strictly required, chosen because
  it makes Reset correct for free and avoids history-dependent puzzle
  confusion.
- Beams continue through an activated target instead of stopping there
  (Milestone 2, DECISIONS.md D22) — required for multi-target levels to
  work with a single beam; re-verified not to change any Milestone 1
  level's solved outcome.
- The level editor is a plain runtime scene (F6-run), not an
  `@tool`/`EditorPlugin` dock (Milestone 3, DECISIONS.md D23) — chosen
  for lower maintenance ceremony given this project's actual team size,
  at the cost of not being integrated into the Godot editor's own UI.
- New levels can be authored as `.tres` via the editor, loaded
  transparently alongside the existing `.gd`-script levels (Milestone 3,
  DECISIONS.md D25) — not a migration; Levels 1-15 remain `.gd` files
  with no technical need to change them.

## HUD edge spacing (D103)

`SafeAreaMargin` has an optional HUD overhang (top/bottom px of transparent HUD art) set by `game.gd._update_hud_edge_overhang()`; vertical margins become safe inset + `GAMEPLAY_VERTICAL_MARGIN` - overhang. Menus use overhang 0 (unchanged).


## Generator V5 and the Splitter Selector in procedural progression (D110)

`ProceduralLevelGenerator.generate(level, 5)` -> `ProceduralProgressionV3.generate(level, 5)`: rolls (Fusion stream 90, Selector stream 91, both once per level) -> `ProceduralFragmentsV3.compose` (atoms + `SELECTOR_FRAGMENTS` sites -> line tree, density fit against `v5_tile_budget`) -> `ProceduralComposerV3.build` (kind "selector" is a turn via `ProceduralBoardV3.Cursor.to_selector_turn`; `_bias_selector`; per-plan search budgets) -> `harden` (Selector wrong rays screened, not blanket-blocked) -> `ProceduralGeneratorV3._check` (`ProceduralComplexity.analyze` -> `ProceduralSelectorCheck.analyze`; a Selector counts only when load-bearing, not mirror-like, non-solving) -> `ProceduralSelectorCheck.reasons_for` -> pre-probe -> greedy -> `ProceduralMinimality.find_cheaper` -> ONE final wide `ProceduralShortcutProbe`. Ladder on failure: move relax (<= 25%) -> `band_demoted` (reasoning floors of the band below, from attempt 8 for Selector levels / 14) -> V2 fallback (`V5_GENERATION_FAILED`, 0 observed). All of it is runtime-safe (LaserSystem only, never LevelSolver/LevelValidator); dev tools `v5_sample`/`v5_verify` live in `scripts/tools/` (never exported). Version mapping: `LevelManager.procedural_generator_version_for_new_play(level)` (level >= 2001 -> V5); QA: `GameManager.is_v5_test_mode` + `ProceduralV5QaSet` ("V5 TEST", contained like SELECTOR TEST).

## External-test build mode (D113)

`BuildConfig` is the central build-presentation switch. `MODE_INTERNAL_QA` exposes development tools; `MODE_EXTERNAL_TEST` hides them while keeping normal gameplay and test-safe ad configuration; `MODE_PRODUCTION` is reserved for the later public-release pass. `LevelManager` derives QA/unlock flags from `BuildConfig.QA_TOOLS`, `game.gd` gates the tutorial debug overlay and generator labels behind the same flag, and `UIConstants.ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET` now follows it too. QA systems are hidden, not deleted.

## Build mode and store config injection (D114)

`BuildConfig.BUILD_MODE` (committed: `MODE_PRODUCTION`) drives `QA_TOOLS` and `AdConfig.USE_TEST_IDS`. Production ad ids: `AdConfig.production_ids()` reads the CI-written, gitignored `res://config/ad_ids.local.json`; `AdConfig.ads_active(platform)` is false when any id is missing (AdManager then loads nothing, hints stay free). `tools/ci/stamp_store_config.sh` (called from `release.yml` in both lanes) also stamps the AdMob export App ID (`project.godot [admob]`) and the Play Games Game ID (Android presets). See `STORE_RELEASE.md` 6b.
