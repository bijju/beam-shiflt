# ERA_2_DESIGN.md

Era 2 ("Refractions") own architecture/design reference — read this before
touching anything listed in `CLAUDE.md`'s Era 2 read-order entry:
`scripts/resources/era_theme.gd`, the four new tile types (`PRISM`,
`ONE_WAY_REFLECTOR`, `BEAM_RECEIVER`, `REMOTE_EMITTER`) anywhere they
appear (`grid_types.gd`, `laser_system.gd`, `tile_placement.gd`,
`level_data.gd`, `level_validator.gd`, the four new tile visual scripts/
scenes, `era2_activation_fx.gd`), `levels/tutorial/t11.gd`–`t20.gd`, or
`assets/**/era2/`. Same standing rule as every other doc here: if this
disagrees with the code, the code is authoritative.

## 1. Era architecture

`EraTheme` (`scripts/resources/era_theme.gd`) is a plain `Resource` with
static helpers — deliberately **not** a 4th autoload (`CLAUDE.md` rule 6;
it has no per-session state to own, only a lookup table).

- `EraTheme.get_era_for_level(campaign_level_number)` — `1-100 -> 1`,
  `101-200 -> 2`, `201-300 -> 3`, etc.
- `EraTheme.get_era_for_tutorial(tutorial_level_number)` — `T01-T10 -> 1`,
  `T11-T20 -> 2`, `T21-T30 -> 3`, etc.
- `EraTheme.for_era(n)` returns that era's themed asset set. Era 1's
  fields are all left `null` on purpose — every Era 1 caller reads that
  as "use your own existing hardcoded Era 1 asset," so Era 1 content
  never changes no matter how this system grows. Only `for_era(2)` (and
  any future era) carries real texture references.

Callers (`game.gd`, `level_select.gd`, `tutorial_select.gd`,
`level_button.gd`) never branch on a raw level/tutorial id themselves —
they always go through `EraTheme`, so a future Era 3 needs no changes
to any of those files, only a new `_build_era_3()` case.

### What actually themes per-era today

- **Gameplay background** (`game.gd._apply_era_theme()`): swaps the root
  `%Background` `TextureRect`, both HUD bar textures, and each
  `AspectBar`'s aspect ratio (Era 2's HUD art is a different ratio, `3.0`
  vs Era 1's `~2.835`/`~2.839`) — reapplied on every `_load_current_level()`
  call, since Reset/Next Level/Next Tutorial reuse the same `game.tscn`
  instance rather than reloading it.
- **Grid cell art**: `TileVisual.active_cell_background` is a *static*
  class member (not per-instance), set once per level load by
  `_apply_era_theme()`, read by every tile's own `super._draw()` call
  AND by `GridManager`'s own separate `_background_root` per-cell layer
  (both read the exact same value — see `grid_manager.gd`).
- **Level Select / Tutorial Select background**: each screen has no
  single "current level," so it themes itself against the player's
  *furthest unlocked* content's era (`campaign_highest_unlocked_level` /
  `tutorial_highest_unlocked_level`), not any one level. Inert for Level
  Select today (nothing past Level 100 exists yet).
  `level_button.gd` similarly swaps a Level 101+ card's art based on
  `EraTheme.get_era_for_level(id)`.

### What is deliberately NOT wired to a theme yet

- `grid_cell_selected` (`bs_tile_grid_selected_era2.png`) — imported into
  `EraTheme` but there's no existing Era 1 concept of a "selected cell"
  background to swap (`TutorialHighlight` is a ring overlay, not a cell
  background). Left available on the resource for a future pass that
  adds one.
- `bs_grid_surface_era2.png` — a full baked N×N grid image. **Never use
  this as the gameplay grid** (see `CLAUDE.md` rule about `bs_grid_surface_
  era2.png`/Part 3 of the original brief) — BeamShift supports arbitrary
  rectangular boards; only `bs_tile_grid_empty_era2.png` (one cell) is
  used, tiled dynamically like Era 1's `bs_tile_grid_base_runtime.png`.

## 2. Asset placement — read this before adding any more Era 2 art

Two real bugs shipped in this pass's own early commits, both only found
by actually rendering/exporting rather than trusting source:

1. **New PNGs need a real import pass before `preload()` works.**
   `godot --headless --path .` (game mode) does **not** scan for new
   assets — `preload()` fails with "has no resource loaders (unrecognized
   file extension)" until a `.import` sidecar exists. Run
   `godot --headless --editor --import` once after adding/moving any
   asset (also regenerates the global `class_name` cache new
   `class_name` scripts need — same command fixes both). This is a
   one-time, whole-project scan; it also updates `.uid` sidecar files
   for any new script.
2. **`assets/gameplay/pieces/**` is excluded from the Android build.**
   It's `export_presets.cfg`'s "unused reference art" catch-all — the
   exact folder whose blocker/hazard files caused a real silent-tile-
   failure bug once before (`DECISIONS.md` D51). Any Era 2 piece art
   that's actually `preload()`-ed by a tile script **must** live in its
   own per-tile-type folder (`assets/gameplay/prism/`,
   `assets/gameplay/one_way_reflector/`, `assets/gameplay/beam_receiver/`,
   `assets/gameplay/remote_emitter/` — same one-folder-per-type
   convention as `assets/gameplay/mirror/`, `.../target/`, etc.), never
   under `pieces/**`. Verify any new asset addition against a **real
   exported package**, not just source:
   `godot --headless --path . --export-pack "Android Debug" out.pck`
   then `godot --headless --main-pack out.pck --script check.gd` calling
   `ResourceLoader.exists(path)` — see `TEST_PLAN.md`.

The `_base`/`_inactive`-suffixed Era 2 files are the ones actually wired
into gameplay (confirmed beam-free by direct visual inspection). The
plain `bs_tile_*_era2.png` files (no suffix) are **reference art only** —
several of them bake in a fixed-direction beam or a fixed white-in/RGB-
out split, which would misrepresent real per-level data exactly like
`CLAUDE.md` rule 10 warns about for Era 1's tile art. They intentionally
stay under `assets/gameplay/pieces/era2/` (export-excluded, never
`preload()`-ed by any script) — don't "finish the job" by wiring them in.

## 3. Prism (`GridTypes.TileType.PRISM`)

Non-rotatable, never stores orientation state. Placed via
`TilePlacement.make_prism(pos)`.

**Exact rule** (`GridTypes.prism_output_direction()`): each of the three
color channels has a direction fully derived from the beam's own
incoming direction, reusing `reflect()` rather than a new table:

| Channel | Output direction              |
|---------|--------------------------------|
| RED     | `incoming_dir` (straight through) |
| GREEN   | `reflect(incoming_dir, SLASH)` (one turn)   |
| BLUE    | `reflect(incoming_dir, BACKSLASH)` (the other turn) |

- A **WHITE** beam entering a Prism is fully converted: it produces all
  three channel branches at once and does **not** continue as WHITE past
  that point.
- A **RED/GREEN/BLUE** beam entering a Prism produces exactly **one**
  output branch, in that color's own channel direction, keeping the same
  color — i.e. a colored beam only ever uses its own matching channel.
  It never multiplies into the other two.

No solver changes were needed — the Prism is never a rotatable tile, so
`LevelSolver` (generic over `LevelData.get_rotatable_tiles()`) is
unaffected by construction.

## 4. One-Way Reflector (`GridTypes.TileType.ONE_WAY_REFLECTOR`)

Rotatable via the **identical** tap-to-rotate interaction as Mirror/
Splitter — same `GridTypes.MirrorOrientation` field, same
`GridManager._on_orientable_tile_clicked()` handler, same solver bit-
toggle. `LevelData.get_rotatable_tiles()`/`get_initial_tile_orientations()`
were extended to include this type (one shared list,
`_ORIENTABLE_TILE_TYPES`) — this is the *only* change `LevelSolver`
needed, and it's zero lines in `level_solver.gd` itself.

**Exact rule** (`GridTypes.one_way_reflector_is_reflective()`): the
reflective side is *derived* from orientation, never a second stored
bit. `reflect()` already pairs each orientation's four incoming
directions into two 2-element groups:

- `SLASH`: `{RIGHT, UP}` reflect (bend exactly like a Mirror would);
  `{LEFT, DOWN}` pass straight through, untouched, like an empty cell.
- `BACKSLASH`: `{RIGHT, DOWN}` reflect; `{LEFT, UP}` pass through.

The reflective pair is defined as "whichever pair contains RIGHT" —
`incoming_dir == RIGHT or reflect(incoming_dir, orientation) == RIGHT`.
Consequence worth knowing: a beam travelling **RIGHT is always
reflective**, in either orientation — rotating the tile only changes
*which* direction it bends to (`UP` for `SLASH`, `DOWN` for `BACKSLASH`),
not *whether* it bends. This is what T15/T16's puzzles are built around.

A pass-through hit records **no segment point** (LaserSystem never calls
`segments[-1].append(pos)` for it) — this is also what
`GridManager._spawn_era2_activation_fx()` uses to tell a reflective hit
from a pass-through one for free, with no extra bookkeeping.

**Visual**: the wedge-shaped `_base` art rotates with orientation exactly
like Mirror's texture, plus two small procedural chevrons drawn on the
two cell edges a beam must enter from to actually be reflected (derived
directly from `one_way_reflector_is_reflective()`, always correct — see
`one_way_reflector_tile.gd._draw_edge_indicators()`), with the other two
edges left dim. Deliberately not color-only, per spec.

## 5. Beam Receiver / Remote Emitter

`GridTypes.TileType.BEAM_RECEIVER` / `TileType.REMOTE_EMITTER`.
`TilePlacement.link_id` (a new field, separate from `gate_id`) is the
shared key: several receivers may share one `link_id`, several remote
emitters may share one `link_id` — many-to-many.

- **Beam Receiver**: passive, non-rotatable, color-agnostic (any beam
  color powers it, same as Switch not checking color). Does not bend or
  stop the beam — identical interaction shape to `SWITCH`.
- **Remote Emitter**: inactive by default, fires its own beam (its own
  `position`/`direction`/`color`, exactly like a real `EMITTER`) only
  once its `link_id` is *already powered* — i.e. a receiver on that
  `link_id` was hit in a **previous** `simulate()` pass.

### Stable-simulation integration

This is a new dependency layer resolved by `simulate_until_stable()` the
exact same way `gate_states` already resolves switch → gate: a
`receiver_states: Dictionary` (`link_id -> bool`) is threaded through
`simulate()` as a 4th parameter (alongside `gate_states`), seeded all-
`false` (no "initially powered" concept exists), and merged monotonically
after each pass from that pass's `activated_link_ids`. `max_passes` grew
from `gate_count + 1` to `gate_count + receiver_count + 1`
(`+ MAX_EXTRA_PASSES` safety margin unchanged) — termination is still
guaranteed because `receiver_states`, like `gate_states`, only ever grows
(never reverts) within one `simulate_until_stable()` call.

A **chained** dependency (Receiver A → Remote Emitter A → Receiver B →
Remote Emitter B → target) genuinely needs multiple passes to settle —
confirmed directly via `levels/editor_fixtures/era2/fixture_receiver_
chain.gd` and `levels/tutorial/t19.gd`, both requiring exactly 3 passes
(1 per hop + the initial real-emitter pass), comfortably inside the pass
budget.

Both `LevelManager`/`GridManager`'s per-frame board state already show a
Remote Emitter fully active on the level's **first frame** if it was
powered in the authored state — `simulate_until_stable()` runs to
completion inside `GridManager.load_level()`'s first
`_simulate_and_draw()` call, before the player ever taps anything (T18's
whole lesson is built on this).

### Validator

`LevelValidator._check_receivers_and_remote_emitters()` mirrors the
existing switch/gate checks: an empty `link_id` on either tile type is an
**error**; a Remote Emitter whose `link_id` matches no Beam Receiver is
an **error** (it could never fire, unlike an always-open gate, which is
merely a warning); a Beam Receiver with no Remote Emitter on its
`link_id` is a **warning** (harmless — it still pulses when hit, it just
powers nothing).

## 6. Activation VFX

`Era2ActivationFX` (`scripts/gameplay/era2_activation_fx.gd`,
`scenes/gameplay/era2_activation_fx.tscn`) — same architecture as the
existing `LaserMirrorImpactFX` (`CLAUDE.md` rule 14: a new pass following
that pattern, not a tweak to it). A short violet/magenta procedural
ring+flash, spawned by `GridManager._spawn_era2_activation_fx()` from the
already-computed `_last_result`, **player taps only**
(`_simulate_and_draw(true)`), sharing the existing `_impact_root`
container and `IMPACT_FX_MAX_COUNT` cap with mirror impacts. Fires for:
every Prism cell a beam touched, every One-Way Reflector *reflective*
hit (pass-through hits never spawn one — see above), every Beam Receiver
hit, and every currently-active Remote Emitter. Prism bursts always use
the neutral violet accent (never one channel's color — a Prism event
means "multiple colors emerged," any single channel's color would
misrepresent that); Remote Emitter bursts use the actual beam color it
fires.

## 7. T11–T20 guided tutorial pack

Same architecture as T01–T10 in every respect (`TutorialLevelData`/
`TutorialStepData`, `TutorialManager`, forced-interaction gating) — see
`TUTORIAL_SYSTEM.md`. Nothing tutorial-specific was added for any Era 2
mechanic; every tile behaves identically in a tutorial and in Campaign,
per the standing rule.

| # | Title | Teaches |
|---|-------|---------|
| T11 | Welcome to Refractions | Recap only — Era 2 visual theme, zero new mechanics (mirrors T01) |
| T12 | Prism Basics | WHITE → 3-way split; one channel auto-arrives, one needs a familiar mirror tap |
| T13 | Prism Colors | A colored beam only ever produces its own matching channel |
| T14 | Prism Routing | Two channels, two independent mirror routes |
| T15 | Direction Matters | One-Way Reflector: rotation changes bend direction (RIGHT always reflects) |
| T16 | Two Sides | One reflector, two beams from different directions — genuine reflect-vs-pass-through reasoning |
| T17 | Signal Receiver | Introduces the Receiver alone (preview only — the main puzzle doesn't depend on it yet) |
| T18 | Remote Power | Receiver → Remote Emitter is now the whole puzzle; proves it resolves before the first tap |
| T19 | Signal Chain | Receiver → Remote Emitter → Switch → Gate, gating the MAIN beam's own path |
| T20 | Era 2 Graduation | All four new mechanics + Filter/Mirror in one puzzle, minimal hand-holding (T10's pattern) |

Solver-confirmed `optimal_moves`: `1,1,1,2,1,1,1,1,1,2` — hand-derived
during authoring and matched by `LevelSolver.analyze()` on the first
attempt for all 10 (see `TEST_PLAN.md`).

## 8. Unlock rules

- **T11–T20 stay locked until Level 100 is legitimately completed.**
  `LevelManager.is_tutorial_level_selectable()` is the one place this is
  checked — generalizes to future eras via
  `EraTheme.get_era_for_tutorial()`: an era `N` tutorial additionally
  requires campaign level `(N-1)*100` completed. T01–T10 are completely
  unaffected (still the plain sequential `tutorial_highest_unlocked_level`
  check they always had).
- **`LevelManager.UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING`** (currently
  `true`) bypasses that gate **unconditionally** for any valid T11-T20
  id — deliberately matching `UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING`'s
  own bypass-everything-in-range semantics exactly (a version that only
  bypassed the Level-100 gate but still required real T01-T10 completion
  would be far less useful for fresh-save development testing — this was
  a real bug in an earlier draft of this pass, caught by an actual
  rendered Tutorial Select screenshot showing T11+ still locked with the
  flag on). **MUST be set to `false` before any final production
  release**, same standing rule as the campaign flag.
- **No `SAVE_VERSION` bump was needed.** `tutorial_highest_unlocked_level`/
  `tutorial_completed_levels` were already generic over tutorial count
  (a plain int / a `String -> bool` Dictionary, never hardcoded to 10) —
  T11-T20 progress is additive for free, zero migration code.

## 9. Level 100 → Era 2 transition

No new "transition screen" scene — `LevelCompletePopup` gained one
hidden-by-default label (`%EraTransitionLabel`), shown only the first
time Level 100 is completed (`game.gd._on_level_solved()` checks
`SaveManager.is_campaign_level_completed(current_level_id)` **before**
`record_campaign_level_result()` marks it done, so a replay never
re-shows it). Purely presentational — the actual unlock already happens
for free via `is_tutorial_level_selectable()` the instant the completion
is recorded; this banner just tells the player about it.

`bs_milestone_complete_era2.png` (the planned Level 200 asset) was never
supplied in this asset drop — confirmed absent project-wide. Nothing to
import; Level 200 doesn't exist yet regardless.

## 10. Visual language

Dark violet / purple / magenta, crystalline energy, deep indigo, cyan
reserved as a secondary Era 1 continuity accent (used by
`LaserMirrorImpactFX`'s own palette, untouched) — `EraTheme.accent_color`
for Era 2 is `Color(0.55, 0.3, 0.95)`. `Era2ActivationFX` uses a matching
violet/magenta pair, deliberately distinct from `LaserMirrorImpactFX`'s
cyan, so an Era 2 activation reads as a different kind of event even at
a glance. **Confirmed non-confusable with gameplay beam colors** (QA/
Hardening pass, see `DECISIONS.md` D78): a real T20 render's brightest
RED-beam pixel and brightest UI-magenta pixel are 68.5° apart in hue —
`GridTypes.beam_color_to_render_color()` was not touched.

## 11. QA/Hardening pass additions (versionCode 36, "3.0.1-ERA2-FOUNDATION-FIX-QA")

Full writeup: `DECISIONS.md` D78. Summary of what changed relative to
sections 1-10 above (all of which otherwise remain accurate):

- **`EraTheme` gained 4 fields**: `level_complete_panel`/`level_
  complete_panel_margins`, `tutorial_complete_panel`/`tutorial_
  complete_panel_margins`. `LevelCompletePopup`/`TutorialCompletePopup`
  now swap their panel art per era via `set_era_panel()`, called from
  `game.gd._apply_era_theme()` alongside the existing background/HUD/
  grid theming. `null` (Era 1) always restores each popup's own
  original `.tscn`-authored style.
- **Tutorial Select's T11-T20 cards are now Era 2-themed**
  (`tutorial_button.gd`, mirroring `level_button.gd`'s existing
  `EraTheme.get_era_for_level()`/`get_era_for_tutorial()` pattern) —
  previously only the dormant Campaign path had this wiring; it's live
  immediately here since T11-T20 already exist.
- **Section 2's asset-placement guidance gained a corollary**: an asset
  can be correctly placed (own per-tile-type folder, not `pieces/**`)
  and still be entirely unreferenced by any script — `bs_grid_surface_
  era2.png` and all of `assets/gameplay/fx/era2/**` are exactly this
  case (`Era2ActivationFX` is procedural, section 6 above). Both are now
  in `export_presets.cfg`'s `exclude_filter`, verified against a real
  exported APK's zip listing, not assumed safe.
- **Section 9's transition banner reviewed against the two matching
  concept images this drop supplied** (`bs_transition_era1_to_era2
  .png`, `bs_header_era2_refractions_portrait.png`) and **kept
  unchanged** — both bake fixed "ERA 2 / REFRACTIONS" splash text sized
  for a dedicated full-screen reveal moment, not the existing small
  in-popup label; integrating them would mean building the dedicated
  transition screen this section explicitly chose not to build.
- **Fixture count corrected**: 13 files in `levels/editor_fixtures/
  era2/`, not 12 (`fixture_one_way_reflector_backslash` was always
  present, just never counted in prior docs).
- **T11-T20 now have a real guided-step-machine test** (all 10 driven
  through `TutorialManager`'s real signal path, not just solver/
  validator-checked) — 10/10 PASS. See `TEST_PLAN.md`'s "Era 2
  Foundation QA/Hardening Pass" section for the full technique.

## 12. Levels 101-110 pass (`versionCode` 37, "3.1.0-ERA2-L101-110-QA")

Full writeup: `DECISIONS.md` D79/D80. Two parts, both user-requested.

### Part A - Tutorial Select button-shape fix

Section 11 above wired T11-T20's cards to `bs_level_card_era2.png`/
`bs_level_card_locked_era2.png` (mirroring `level_button.gd`'s dormant
pattern). That asset is 1024x1536px - a tall poster/panel image, not a
button frame. Covered/cropped into the button's 240x253 box via
`STRETCH_KEEP_ASPECT_COVERED`, it loses the frame's rounded corners
(which live near the top/bottom of the tall source image) and reads as
a truncated poster rather than a compact button - exactly the
regression the user found on a real device.

**Fix, now the standing pattern for any future Era's button identity**:
never swap a button's texture for Era art unless that art is
proportioned for the existing 240x253 box. Instead, keep using the same
three Era 1 textures (locked/completed/unlocked) for every era, and
apply `_background.modulate = EraTheme.for_era(era).accent_color` -
`Color.WHITE` for Era 1 is a no-op tint, so this changes nothing for
Levels/Tutorials 1-100/T01-T10. Applied to both `tutorial_button.gd`
(the live bug) and `level_button.gd` (the identical dormant wiring,
fixed pre-emptively since Part B below is what first makes Level 101+
reachable). `bs_level_card_era2.png`/`bs_level_card_locked_era2.png`
are now fully unreferenced - added to `export_presets.cfg`'s
`exclude_filter` rather than deleted from disk.

### Part B - Campaign Levels 101-110

The first real Era 2 campaign content - as opposed to T11-T20's
isolated single-mechanic tutorials (section 7) or the 13 `editor_
fixtures/era2/` regression fixtures (section 2). Stored at `levels/
campaign/era2_stage_01/level_01.gd` - `level_10.gd` (local `level_id`
1-10, same convention as every `stage_NN` folder), registered as 10 new
`LevelManager.CAMPAIGN_LEVEL_PATHS` entries appended after Level 100's.
Named `era2_stage_01` rather than continuing "stage_11" - per
`CAMPAIGN_DESIGN.md`'s own guidance, a 101+ request is new scope, not a
continuation of the original 100-level plan's numbering.

`EraTheme.get_era_for_level()`'s pure integer-division math already
classified 101-200 as Era 2 before any Era 2 level existed (section 1) -
Levels 101-110 needed zero new Era-lookup plumbing, confirmed by the
existing `level_select.gd`/`level_button.gd` call sites immediately
theming them correctly.

| # | Title | Mechanics | Grid | Rotatable | Optimal | Shortest# |
|---|-------|-----------|------|-----------|---------|-----------|
| 101 | First Refraction | Prism, Mirror | 7x7 | 2 | 2 | 1 |
| 102 | Spectrum Route | Prism, Filter, Mirror | 7x8 | 2 | 2 | 1 |
| 103 | Fractured Path | Prism, Splitter, Portal, Mirror | 8x8 | 2 | 2 | 1 |
| 104 | One Way | One-Way Reflector, Mirror, Blocker | 6x9 | 2 | 2 | 1 |
| 105 | False Reflection | Prism, One-Way Reflector | 7x7 | 2 | 2 | 1 |
| 106 | Remote Signal | Receiver, Remote Emitter, Mirror | 5x8 | 2 | 2 | 1 |
| 107 | Signal Through | Receiver, Remote Emitter, Portal, Filter, Mirror | 5x10 | 1 | 1 | 1 |
| 108 | Refracted Signal | Prism, Receiver, Remote Emitter, Mirror | 7x9 | 2 | 2 | 1 |
| 109 | Directional Chain | One-Way Reflector, Receiver, Remote Emitter, Switch, Gate | 7x6 | 1 | 1 | 1 |
| 110 | Refraction Nexus | Prism, One-Way Reflector, Receiver, Remote Emitter, Mirror, Portal, Filter, Switch, Gate | 8x10 | 3 | 3 | 1 |

Every level solver-confirmed `SOLVABLE` with a unique shortest solution
(`shortest_solution_count == 1`) and zero `LevelValidator` errors on the
first authoring attempt - every rotatable tile's WRONG orientation was
hand-traced (not assumed harmless) before writing the file, the same
discipline Era 1's campaign batches use. Level 110's remote emitter
uses an explicit `GridTypes.BeamColor.GREEN` (overriding `make_remote_
emitter()`'s `WHITE` default) specifically so its final target can't be
satisfied by the RED prism channel alone via the same mirror - a
`WHITE`-required target (Era 1's "accepts any color" convention) would
have silently let the Receiver/Remote Emitter mechanic be bypassed
entirely; caught during authoring by tracing every beam's color at
every cell it could reach, documented in the level's own
`developer_notes`.

`game.gd`'s `era_transition` banner (section 9) previously fired on
`current_level_id == LevelManager.get_campaign_level_count()` - correct
only because Level 100 happened to be both the Era 1/Era 2 boundary and
the last implemented level at once. Adding Levels 101-110 made
`get_campaign_level_count()` become 110, which would have silently
moved the banner there instead. Fixed to compare `EraTheme.get_era_for_
level()` across the level boundary - correct today and automatically
correct for a future Level 200 -> Era 3 boundary.

**Do not create Campaign Levels 111+ without being explicitly asked** -
same standing scope discipline as every other milestone in this
project (superseded by section 13 below - Levels 111-120 now exist).

## 13. Levels 111-120 pass (`versionCode` 38, "3.2.0-ERA2-L111-120-QA")

Full writeup: `DECISIONS.md` D81. User-requested follow-up, authorized
before manual Android QA of Levels 101-110 was finished. **No new
mechanics** - this pass deepens Prism/One-Way Reflector/Beam Receiver/
Remote Emitter through dependency depth, shared resources, and
misleading local reasoning, per explicit brief instruction not to chase
tile count, grid size, or solver state count. `levels/campaign/
era2_stage_01/level_11.gd` - `level_20.gd`, `get_campaign_level_count()`
is now 120.

| # | Title | Mechanics | Grid | Rotatable | Shortest# |
|---|-------|-----------|------|-----------|-----------|
| 111 | Split Decision | Prism, Splitter, Mirror | 7x8 | 3 | 1 |
| 112 | Cross Signal | One-Way Reflector (shared by 2 beams), Receiver, Remote Emitter | 6x8 | 3 | 1 |
| 113 | Spectral Gate | Prism, Filter, Switch, Gate | 8x8 | 3 | 1 |
| 114 | Remote Loop | Receiver, Remote Emitter (x2, chained), Portal | 7x10 | 3 | 1 |
| 115 | Directional Prism | Prism, One-Way Reflector (x3) | 7x8 | 5 | 1 |
| 116 | False Activation | Receiver, Remote Emitter, Switch, Gate | 7x8 | 2 | 1 |
| 117 | Split Spectrum | Prism, Splitter, Filter, Portal | 8x9 | 3 | 1 |
| 118 | Remote Crossing | Receiver (x2), Remote Emitter (x2), Switch, Gate | 9x10 | 4 | 1 |
| 119 | Refraction Relay | Prism, Receiver, Remote Emitter, Portal, Switch, Gate | 9x9 | 4 | 1 |
| 120 | Era 2 Circuit | Prism, One-Way Reflector (x2), Receiver, Remote Emitter, Switch, Gate | 9x11 | 7 | 1 |

**Three real shortcut bugs, all the identical failure shape**: a beam
that has already activated its own required target keeps traveling in
its current direction (targets never stop a beam, per `LaserSystem`)
and reaches a second mechanic it was never designed to touch.

- **Level 112**: two required targets shared one column; the beam that
  satisfied the first one continued straight into the second,
  bypassing an entire mirror's worth of intended reasoning. Fixed by
  moving the second target off that column.
- **Level 118**: two Beam Receivers shared one column with a single
  emitter's post-mirror path; that one emitter powered both receivers,
  making a second, independent emitter's own mirror decision pointless.
  Fixed by moving the second receiver's whole approach to a different
  column.
- **Level 120**: GREEN's beam, after its own target, walked straight
  into a One-Way Reflector one cell away - entering RIGHT, which is
  *always* reflective regardless of orientation (section 4) - and got
  bent into the Remote Emitter's own target, skipping the Receiver/
  BLUE/Remote Emitter chain entirely. The first fix attempt only
  changed the reflector's *default* orientation to a value that
  happened to send the stray beam somewhere harmless - the solver then
  found an *alternate* same-length solution that deliberately mis-set
  the reflector back to re-open the exact same shortcut
  (`shortest_solution_count` came back 2, not 1). The real fix moved
  the reflector to a row GREEN's beam can never reach under *any*
  orientation - eliminating the interaction structurally rather than
  relying on a default-value coincidence. Worth remembering for any
  future level: a rotatable tile's *default* orientation being "safe"
  today says nothing about whether flipping it stays safe - only
  physical unreachability does.

All ten solver-confirmed `SOLVABLE`, `shortest_solution_count == 1`,
zero `LevelValidator` errors, after the fixes above. Full regression:
15/15 dev, 120/120 campaign (110 unchanged + 10 new), 20/20 tutorial,
13/13 Era 2 fixtures - all solver+runtime-replay PASS. T11-T20 guided
step-machine not re-run (untouched this pass). Progression verified
against the real `SaveManager` API across the full 110->120 walk, not
just a single boundary.

**Do not create Campaign Levels 121+ without being explicitly asked** -
same standing scope discipline as every prior milestone in this
project (superseded by section 14 below - Levels 121-130 now exist).

## 14. Levels 121-130 pass (`versionCode` 39, "3.3.0-ERA2-L121-130-QA")

Full writeup: `DECISIONS.md` D82. "Deep dependency pass" - user-
requested, authorized before ANY prior Era 2 level batch (101-110,
111-120) had received manual Android QA. **No new mechanics** - moves
beyond section 13's single-chain-dependency deepening into whole-board
reasoning: shared resources spanning distant board regions, reciprocal
relay chains, near-solution traps requiring backward reasoning from a
target's color, and (Level 130) a genuine four-way convergence.
`levels/campaign/era2_stage_01/level_21.gd` - `level_30.gd`,
`get_campaign_level_count()` is now 130.

| # | Title | Dependency structure | Grid | Rotatable | Shortest# |
|---|-------|----------------------|------|-----------|-----------|
| 121 | Shared Spectrum | One OWR reused by 2 Prism colors | 8x8 | 5 | 1 |
| 122 | Remote Pair | Reciprocal relay (A powers B, B opens A's gate) | 8x9 | 4 | 1 |
| 123 | Prism Relay | 3 independently-required branches | 9x10 | 3 | 1 |
| 124 | Directional Cross | Shared OWR (2 emitters) + cross-region gate | 10x8 | 4 | 1 |
| 125 | False Spectrum | Near-solution trap + target continuation | 9x9 | 4 | 1 |
| 126 | Signal Cascade | 6-hop activation cascade | 9x11 | 2 | 1 |
| 127 | Fractured Circuit | Portal + shared OWR, 3 spatial regions | 10x10 | 4 | 1 |
| 128 | Reciprocal Signal | Shared gate + OWR pass-through | 9x10 | 4 | 1 |
| 129 | Spectral Network | 5 mechanic families, isolated remote chain | 9x11 | 5 | 1 |
| 130 | Convergence Matrix | 4-way convergence (2 gates, 1 target) | 9x11 | 7 | 1 |

**Two issues found and fixed during authoring, one an extension of
section 13's shortcut family and one genuinely new**:

- **Level 123**: a plain grid-bounds error (a Portal and Remote Emitter
  placed one row outside a `grid_height=9` board) - caught immediately
  and explicitly by `LevelValidator`'s own position-bounds check, not
  by the solver. Fixed by growing the board.
- **Level 127**: a NEW failure shape beyond section 13's "beam
  continues past its own target." A wrong-orientation mirror's stray
  path physically crossed a SECOND, unrelated mirror belonging to a
  different part of the level's intended route - and that second
  mirror's own default orientation happened to correctly complete an
  accidental shortcut into the shared One-Way Reflector, bypassing the
  level's Portal entirely (solver: 2 moves instead of 4). Fixed with a
  `BLOCKER` placed to intercept only the stray path, confirmed never
  touching the real portal-exit beam (which approaches from the
  opposite direction). **General lesson**: tracing a wrong rotation's
  path only as far as "exits harmlessly" is incomplete if that path
  crosses another tile at all - that tile's OWN current orientation
  must also be checked for whether it silently completes a shortcut.

All ten solver-confirmed `SOLVABLE`, `shortest_solution_count == 1`,
zero `LevelValidator` errors, after fixes. States explored top out at
128 (Level 130), matching Level 120's own peak - confirming difficulty
came from dependency structure, not state-space growth, per the
brief's explicit instruction. Full regression: 15/15 dev, 130/130
campaign (120 unchanged + 10 new), 20/20 tutorial, 13/13 Era 2 fixtures
- all solver+runtime-replay PASS. Progression verified against the
real `SaveManager` API across the full 120->130 walk.

**Do not create Campaign Levels 131+ without being explicitly asked** -
same standing scope discipline as every prior milestone in this
project (superseded by section 15 below - Levels 131-140 now exist).

## 15. Levels 131-140 pass (`versionCode` 40, "3.4.0-ERA2-L131-140-QA")

Full writeup: `DECISIONS.md` D83. "Advanced convergence pass" -
user-requested, explicitly authorized before ANY of the three prior
Era 2 level batches (101-110, 111-120, 121-130) had received manual
Android QA. **No new mechanics.** `levels/campaign/era2_stage_01/
level_31.gd` - `level_40.gd`, `get_campaign_level_count()` is now 140.

| # | Title | Structure | Grid | Rotatable | Shortest# |
|---|-------|-----------|------|-----------|-----------|
| 131 | Double Bind | One reflector shared by 2 Prism colors, genuinely different directions | 9x9 | 6 | 1 |
| 132 | Relay Exchange | Reciprocal relay, one Remote Emitter stalls until the other resolves | 8x9 | 4 | 1 |
| 133 | Spectral Lock | Filter+Portal+Gate backward reasoning | 8x9 | 3 | 1 |
| 134 | Cross Current | Shared reflector reused by a Remote Emitter from the opposite side | 10x8 | 5 | 1 |
| 135 | Delayed Spectrum | Fair target continuation into a Receiver | 9x9 | 3 | 1 |
| 136 | Portal Relay | Pass-through-vs-reflect trap on a Receiver-chain corridor | 7x10 | 5 | 1 |
| 137 | Three-Way Refraction | All 3 Prism channels meaningfully different | 8x10 | 4 | 1 |
| 138 | Reciprocal Gates | Shared reflector, opposite-side approach (rebuilt once) | 9x10 | 2 | 1 |
| 139 | Fractured Network | 5+ mechanic families, isolated remote chain | 9x11 | 6 | 1 |
| 140 | Refraction Engine | 4 subsystems, 2-stage remote chain, Portal | 9x11 | 8 | 1 |

**This was the most shortcut-prone batch of the four Era 2 level
passes to date - 5 of 10 levels needed a fix during authoring** (vs.
3/10 for 111-120, 2/10 for 121-130), reflecting the higher structural
complexity this pass required. All caught by the same two established
techniques (`LevelValidator`'s bounds check, `LevelSolver`'s shortest-
solution-count check):

- **Level 133**: a genuine authoring error, not a shortcut - a second
  mirror inserted directly into an already-complete straight path made
  its own target permanently unreachable (a mirror always bends, it
  can never let a beam "continue straight"). Solver reported
  `UNSOLVABLE`. Fixed by removing the superfluous mirror.
- **Levels 134 and 137**: variants of the established `WHITE`-accepts-
  any-color target bypass (see section 13's Level 120 writeup) - 134's
  variant was new: a shared reflector's wrong orientation SWAPPED which
  of two beams reached which of two targets, but since both beams and
  both targets used the `make_remote_emitter()`/`make_target()` default
  `WHITE`, the swap was invisible to the win condition. Fixed the same
  way both times: an explicit non-`WHITE` Remote Emitter color plus a
  matching non-`WHITE` target requirement.
- **Level 138**: the deepest structural bug found to date. A shared
  One-Way Reflector's two beams approached from the SAME side (one
  entering from directly above, the other's own correct exit ALSO
  landing directly above) rather than genuinely opposite sides - one
  beam's straight-line approach corridor doubled as the other's exit
  corridor, letting a target meant only for the second beam get
  satisfied by the first beam's own straight path with zero rotation
  at all. Needed two fix attempts before a full geometric rebuild
  (approaching from genuinely opposite sides - one beam entering from
  BELOW, the other from the LEFT) closed it for good. **General lesson
  for any future shared-reflector level**: check that the two beams'
  entire corridors - both approach AND exit, in every orientation, not
  just their entry directions - never overlap.

All ten solver-confirmed `SOLVABLE`, `shortest_solution_count == 1`,
zero `LevelValidator` errors, after fixes. Full regression: 15/15 dev,
140/140 campaign (130 unchanged + 10 new), 20/20 tutorial, 13/13 Era 2
fixtures - all solver+runtime-replay PASS. Progression verified
against the real `SaveManager` API across the full 130->140 walk.

**NOT MANUALLY APPROVED.** Per the user's own instruction, a manual
Android review checkpoint is now recommended before Levels 141+ - four
consecutive unreviewed Era 2 campaign batches (40 levels) currently
await real-device feedback together.

**Do not create Campaign Levels 141+ without being explicitly asked** -
same standing scope discipline as every prior milestone in this
project.

## Fusion Node (Phase 1, D99) - relation to Era 2

Fusion is not an Era 2 mechanic: unified blue theme, own art (`assets/gameplay/fusion/`); since Phase 2 (D100) it is generated by procedural generator V4 (QA build). It extends the shared colour model (appended YELLOW/MAGENTA/CYAN); a composite beam through a Prism passes straight.

## Fusion Node (Phase 3, D101) - tutorial numbering vs eras

The Fusion tutorial pack occupies T21-T28. `EraTheme.get_era_for_tutorial(21)` numerically reads "Era 3", but Fusion is NOT an era: those tutorials must never be gated by the era rule (it would require Campaign Level 200). `LevelManager.is_tutorial_level_selectable()` therefore routes T21-T28 to `is_fusion_tutorial_selectable()` before any era logic (T21 at procedural Level 150 or after T20, then sequential; QA flag opens all). Visual theme is unaffected (`EraTheme.UNIFIED_BLUE_THEME_ONLY` forces Era 1's set for every number). Do not "fix" this by renaming T21-T28 into an Era; a future Era 3 tutorial pack must start after T28 (T29+) or the constants must be revisited together.
