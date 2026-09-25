# TUTORIAL_SYSTEM.md

The guided tutorial's own architecture/design reference — read this before
touching anything under `levels/tutorial/`, `scripts/managers/tutorial_
manager.gd`, `scripts/resources/tutorial_*.gd`, `scripts/ui/tutorial_*.gd`,
or `scenes/ui/tutorial_*.tscn`. If anything here disagrees with the actual
code, the code is authoritative — fix this document, don't trust it blindly.

See `DECISIONS.md` D60 for the implementation writeup (why each piece is
shaped the way it is), D61 for the v1 manual-QA-failure root-cause/fix
writeup (**read section 11 below before touching any tutorial `.tscn`
file**), D62 for the visual focus fix (dim overlay + highlight
visibility — **read section 12 below before touching
`TutorialHighlight`/`TutorialDimOverlay` or the dim/highlight coupling
in `GridManager`**), D63 for the click input fix (**read section 13
below before touching any `.tscn` INSTANCE node's layout overrides, or
`GridManager`'s tap-diagnostic fields**), and `CLAUDE.md`'s permanent
rules for the standing constraints this system must never violate.

**Status: NOT YET MANUALLY APPROVED.** Three real bugs found across
three rounds of manual QA, all fixed but none yet reconfirmed on a real
device: v1 (`versionCode=18`) failed with no tiles/softlock after Reset
(fixed at `versionCode=19`, D61); v2 (`versionCode=19`) had weak/
unreliable board dim and highlight visibility (fixed at `versionCode=20`,
D62); v3 (`versionCode=20`) had a highlighted tile that was visible but
could not be tapped (fixed at `versionCode=21` (`"1.6.3-TUTORIAL-INPUT-FIX"`,
current), D63). All three fixes are strongly verified by automated/
rendered testing, but a real device confirmation of any of them has not
happened yet — do not describe this system as "working" or "approved"
without checking `CURRENT_STATUS.md` first.

## 1. Product structure

BeamShift now has two separate, permanently-separate gameplay sections:

- **TUTORIAL** — T01–T10, ten guided interactive lessons. Does **not**
  count toward the 100-level campaign; tutorial level ids (1–10) live in
  a completely separate numbering space and a completely separate
  `SaveManager` field set from campaign level ids (which also run 1–100).
- **CAMPAIGN** — the main puzzle experience, currently levels 1–50
  (Stages 1–5), eventually 1–100. See `CAMPAIGN_DESIGN.md`.

Campaign no longer needs to spend entire stages teaching a mechanic from
scratch — Tutorial's job is teaching mechanics in isolation; Campaign's
job is combining them and raising difficulty. See section 8 below for
what this means for future campaign stage design.

## 2. Core philosophy: guided interactive lessons, not easy puzzles

A tutorial level is not "an easy puzzle" — it's a scripted sequence:

```
EXPLAIN → HIGHLIGHT → RESTRICT INPUT → PLAYER PERFORMS THE ACTION →
SHOW RESULT → EXPLAIN RESULT IF NEEDED → ADVANCE
```

The player must physically perform the important actions themselves —
nothing rotates a mirror or triggers a mechanic on the player's behalf.
Early tutorials (T01–T03) force the single correct tap; later ones
(T02's second mirror onward) progressively hand more freedom back to the
player, and T10 is almost entirely free play. This progression is
intentional — see section 6.

## 3. Non-negotiable: Tutorial and Campaign share the same gameplay engine

Every tutorial level is a `TutorialLevelData` (`extends LevelData`) with
an added `steps` array — its `tiles`/`grid_width`/`grid_height` are
simulated by the exact same `LaserSystem`/`GridManager` Campaign uses.
**There is no tutorial-only gameplay logic anywhere** — mirrors, filters,
splitters, portals, switches/gates, hazards, and multi-emitter levels all
behave in a tutorial exactly as they would in a Campaign level with the
same layout. The only tutorial-specific code is the *scaffolding* around
that real gameplay: forced interaction, highlighting, and instructional
text (all described below). This was a hard requirement in the
commissioning brief and is the reason no mechanic needed to be "faked."

## 4. Architecture overview

| Piece | Type | Owns |
|---|---|---|
| `TutorialStepData` (`scripts/resources/tutorial_step_data.gd`) | `Resource` | One guided step's data: type, text, highlight/target position, input-lock flag |
| `TutorialLevelData` (`scripts/resources/tutorial_level_data.gd`) | `Resource`, extends `LevelData` | `tiles` (real gameplay, inherited) + `steps` (ordered `TutorialStepData` array) |
| `TutorialManager` (`scripts/managers/tutorial_manager.gd`) | `class_name`, extends `RefCounted` — **NOT an autoload** | The step machine: current step index, applies forced-interaction/highlight rules to the active `GridManager`, decides when to advance |
| `LevelManager.TUTORIAL_LEVEL_PATHS` / `get_tutorial_level()` / `get_tutorial_level_count()` | autoload additions | The ordered list of T01–T10 files (parallels `CAMPAIGN_LEVEL_PATHS` exactly) |
| `SaveManager.tutorial_highest_unlocked_level` / `tutorial_completed_levels` | autoload additions | Tutorial progression, namespaced separately from campaign/dev fields |
| `GameManager.is_tutorial_mode` / `current_tutorial_id` / `start_tutorial()` / `go_to_tutorial_select()` | autoload additions | Scene-navigation hand-off, mirrors `is_editor_playtest` exactly |
| `GridManager.interaction_locked` / `interaction_restricted_to` / `set_highlight()` / `clear_highlight()` / `suspend_tutorial_focus()` / `resume_tutorial_focus()` / `is_target_activated()` / `simulation_updated` signal | additions to the existing class | The forced-interaction/highlight/dim mechanism itself — see section 5, section 12 |
| `GridManager.last_tap_cell` / `last_tap_accepted` / `last_tap_rejection_reason` / `tile_tap_attempted` signal | additions to the existing class | QA-only tap diagnostics, set at the top of `_on_orientable_tile_clicked()` before any guard clause - see section 13 |
| `TutorialHighlight` (`scripts/ui/tutorial_highlight.gd`) | `Control` | The pulsing cyan-white outline, owned/positioned by `GridManager` — see section 12 |
| `TutorialDimOverlay` (`scripts/ui/tutorial_dim_overlay.gd`) | `Control` | The board dim with a transparent cutout around the highlighted tile, owned/shown/hidden by `GridManager` in lockstep with `TutorialHighlight` — see section 12 |
| `scenes/ui/tutorial_panel.tscn` / `tutorial_panel.gd` | UI scene | The instruction text + "TAP TO CONTINUE" panel, added to `game.tscn` |
| `scenes/ui/tutorial_complete_popup.tscn` / `tutorial_complete_popup.gd` | UI scene | Lesson/Tutorial-complete popup, distinct from `LevelCompletePopup` (no stars/best-moves) |
| `scenes/ui/tutorial_select.tscn` / `tutorial_select.gd` | UI scene | Tutorial Level Select, a structural sibling of `level_select.tscn` |
| `scenes/ui/tutorial_button.tscn` / `tutorial_button.gd` | UI scene | Tutorial card (locked/unlocked/completed, no stars), reuses Campaign's card textures |
| `scripts/gameplay/game.gd` | existing script, additively modified | Owns one `TutorialManager` instance per play session when `GameManager.is_tutorial_mode`; forwards `GridManager` signals to it; everything else (Campaign/editor-playtest branches) is untouched |

**Why `TutorialManager` is not an autoload:** `CLAUDE.md` rule 6 ("autoloads
are earned, not default") only sanctions `SaveManager`/`LevelManager`/
`GameManager`. Nothing in the step machine needs to survive a scene
change — all of it is scoped to one tutorial play session — so `game.gd`
just owns a plain instance (`var _tutorial := TutorialManager.new()`),
exactly like it already owns other per-session state (`moves_used`,
`_completion_pending`).

## 5. Forced interaction — the single central gate

Every puzzle-tile tap in the entire game (Campaign, editor playtest, and
Tutorial alike) already goes through exactly one function:
`GridManager._on_orientable_tile_clicked()`. Two new fields gate it:

```gdscript
var interaction_locked: bool = false        # true: every tap ignored
var interaction_restricted_to = null         # non-null Vector2i: only THIS tile accepted
```

Both default to their inert values, so Campaign/editor-playtest input is
byte-for-byte unaffected unless something explicitly sets them — and only
`TutorialManager._apply_step_to_grid()` ever does. This satisfies the
brief's "do not scatter fragile checks across every individual tutorial
level" requirement: there is exactly one interaction-filtering choke
point, and exactly one piece of code (`TutorialManager`) that touches it.

`TutorialStepData.step_type` maps to a `GridManager` state:

| step_type | `interaction_locked` | `interaction_restricted_to` |
|---|---|---|
| `MESSAGE` | `true` | `null` |
| `REQUIRE_TILE_TAP` | `false` | the step's `target_position` |
| `WAIT_FOR_TARGET_ACTIVATION` / `WAIT_FOR_PUZZLE_SOLVED` | the step's own `lock_all_input` flag | `null` |

An invalid tap (locked, or restricted to a different tile) is silently
ignored — `_on_orientable_tile_clicked()` returns before mutating any
state or emitting `move_made`, so an invalid tutorial tap can never be
counted as a move or corrupt tutorial state.

## 6. Step-type vocabulary

The brief's full suggested vocabulary (MESSAGE, SHOW_TARGET, TAP_TO_
CONTINUE, REQUIRE_TILE_TAP, REQUIRE_TILE_ROTATION, WAIT_FOR_BEAM_RESULT,
WAIT_FOR_TARGET_ACTIVATION, WAIT_FOR_PUZZLE_SOLVED) collapses into 4
`TutorialStepData.StepType` values — see the enum's own doc comment for
the exact mapping. `text`/`highlight_position` are independent of
`step_type`, so e.g. a `MESSAGE` step can highlight any cell purely to
draw the eye ("this is the emitter") without requiring interaction.

**Signal timing matters and is documented where it bites:**
`GridManager.move_made` fires *before* simulation runs (existing,
unchanged Campaign behavior) — safe for "a tap happened" checks
(`REQUIRE_TILE_TAP`) but never for reading post-move target state. A new
`GridManager.simulation_updated` signal (additive, fires at the end of
`_simulate_and_draw()`, after target/switch/gate/hazard state updates)
is what `WAIT_FOR_TARGET_ACTIVATION` actually listens to. This distinction
was found and fixed during this feature's own testing — see
`DECISIONS.md` D60.

## 7. Highlight visual

`TutorialHighlight` (`scripts/ui/tutorial_highlight.gd`) is a pulsing
cyan-white **outline only** (never a filled overlay, so the tile's own
art stays fully visible), `mouse_filter = IGNORE` (never intercepts a
tap meant for the tile), owned and positioned by `GridManager` itself
(`set_highlight(pos)`/`clear_highlight()`), repositioned automatically on
every layout recalculation so it survives resize/orientation changes.
No shader, no `Tween` — a cheap `_process()` + `_draw()` sine-wave alpha
pulse. Since the visual focus fix (D62, section 12 below), the ring is
drawn `FOCUS_PADDING` larger than the tile and sits inside a matching
transparent hole in `TutorialDimOverlay`, which is what actually makes
it read clearly — see section 12 for the full mechanism.

## 8. What this means for future Campaign design

Campaign no longer needs a "tutorial stage" for each new mechanic the
way Stage 1 (mirrors), Stage 3 (splitters), Stage 4 (color), and Stage 5
(filters) each spent their first 1–2 levels teaching the mechanic from
scratch — Tutorial now owns that job for every mechanic that exists
today. A future campaign stage introducing portals/switches-gates/
hazards/multi-emitters can lean on the Tutorial having already taught
the mechanic, and focus its own levels on *combinations* and difficulty
from the very first level - closer to how Stage 4/5's later levels
(cross-branch dependency, backward reasoning) already work, rather than
Stage 1's "Ignition" (one trivial mirror flip) opening pattern.

**Level 50 ("Paradox," Stage 5's finale, 255 states explored) is the
current difficulty-quality benchmark** for what a "should regularly make
the player stop and analyze before moving" campaign level looks like -
future campaign level design should be measured against it, not against
Stage 1's easier opening levels. This document doesn't redesign Campaign
Levels 1–50 (out of scope for this pass) — it only records the design
direction for whichever future session picks up campaign redesign work.

## 9. Deferred: first-launch tutorial recommendation

The brief explicitly allowed deferring an intrusive onboarding flow if it
adds unnecessary complexity. This pass added the TUTORIAL button to Main
Menu (see section 1) but did **not** add any first-launch popup,
"recommended" badge, or forced pre-Campaign gate — Campaign remains
immediately accessible with zero friction, exactly as it always has been.
If a future session wants to revisit this, the natural hook is
`SaveManager.tutorial_completed_levels.is_empty() and tutorial_highest_
unlocked_level == 1` on Main Menu's `_ready()`.

## 10. Authoring a new tutorial step / level

1. Add tiles to a `TutorialLevelData` subclass's `tiles` array exactly
   like a normal `LevelData` (`TilePlacement.make_*()` factories) — hand-
   trace the intended solution against `GridTypes.reflect()`'s actual
   table first, same discipline as every Campaign level.
2. Build `steps` using `TutorialStepData`'s static factories
   (`message()`, `require_tap()`, `wait_for_target()`, `wait_for_solved()`)
   — see any `levels/tutorial/t0N.gd` file for the pattern.
3. Verify the board is genuinely solvable by replaying your intended
   move sequence through a real `GridManager` (the same throwaway-
   headless-script technique `TEST_PLAN.md` uses for Campaign levels) -
   there is no `LevelSolver` support for tutorials (they don't need
   solver-confirmed `optimal_moves`; `steps` themselves define the
   intended path).
4. Add the new file's path to `LevelManager.TUTORIAL_LEVEL_PATHS`.
5. Re-run the tutorial architecture regression (`TEST_PLAN.md`'s
   "Guided Tutorial Mode" section) to confirm nothing else regressed.

## 11. Pitfall that caused a real shipped failure: an `ext_resource`d script must also be attached

**Read this before creating or hand-editing any `.tscn` file in this
system.** `versionCode=18`'s manual Android QA failed completely (T01
showed no tiles, softlocked after Reset, no instruction/highlight ever
appeared) because `scenes/ui/tutorial_panel.tscn` declared
`tutorial_panel.gd` as an `ext_resource` at the top of the file but
never actually attached it to the root node — there was no `script =
ExtResource("1")` line on the `[node name="TutorialPanel" ...]` block.
`scenes/ui/tutorial_complete_popup.tscn` had the identical mistake,
independently.

**Why this is dangerous:** Godot does not treat this as an import or
parse error. A node with a declared-but-unattached script silently
becomes its plain base engine type (here, `Control`) — no custom
signals, methods, or exported properties. The project imports cleanly,
the scene opens cleanly in the editor, and the bug only surfaces the
instant runtime code touches a member that only the custom script
would have provided (here, `game.gd`'s `_tutorial_panel.continue_pressed.
connect(...)` in `_ready()`), and it surfaces as a **generic runtime
"Invalid access to property or key" error**, not anything that points
at the real cause. Worse: a script error partway through `_ready()`
silently aborts the *rest* of that function — anything wired earlier
(like the Reset button's `pressed` connection) still works, producing
exactly the "Reset fixes it" pattern that made this bug so confusing to
diagnose from symptoms alone.

**When hand-writing or hand-editing a `.tscn` file's root node block,
always double check the node that is supposed to carry a custom script
actually has `script = ExtResource("N")` as one of its own properties**
— not just present somewhere in the file's `ext_resource` list at the
top. `tutorial_select.tscn` and `tutorial_button.tscn` were checked
during the D61 investigation and confirmed correct; only these two
files had the mistake. See `DECISIONS.md` D61 for the full
investigation, including the real-rendering reproduction technique that
actually found it (headless `--import` checks and direct-method-call
tests both missed this bug entirely, because neither exercises a real,
freshly-instantiated scene tree the way a player's first tap does).

## 12. Visual focus: the dim overlay + highlight cutout system

**Read this before touching `TutorialHighlight`, `TutorialDimOverlay`,
or `GridManager`'s `set_highlight()`/`clear_highlight()`/
`suspend_tutorial_focus()`/`resume_tutorial_focus()`.** A manual video
QA of `versionCode=19` found the board stayed heavily dimmed during
`REQUIRE_TILE_TAP` with the required tile hard to see under it, and the
dim wasn't reliably clearing. Investigation (checked directly against
source, not assumed) found **no dim overlay had ever existed anywhere in
this system before** - the real problem was `TutorialHighlight`'s thin
outline having too little contrast against full-color gameplay art. See
`DECISIONS.md` D62 for the full writeup; this section is the lasting
architecture reference.

**How it works:** `TutorialDimOverlay` (`scripts/ui/tutorial_dim_overlay.gd`)
is a `Control` owned by `GridManager`, drawing a semi-transparent black
dim (`DIM_ALPHA = 0.52`, one constant) over its own full rect - except a
rectangular cutout, left completely transparent, around whichever tile
is currently highlighted. The tile inside the cutout renders at full,
undimmed brightness; `TutorialHighlight`'s pulsing ring is drawn on top
of that same transparent hole, which is what makes it actually read
clearly (a ring drawn over a *dimmed* background has much less contrast
than one drawn over full brightness). Both nodes read one shared
constant, `TutorialHighlight.FOCUS_PADDING` (10px), for the cutout/ring
size, so they can never drift apart - `GridManager._position_highlight()`
is the single place both are positioned.

**Dim visibility is coupled 1:1 to the highlight, not a separate state
machine.** `GridManager.set_highlight(pos)` shows both the ring and the
dim; `clear_highlight()` hides both and clears the cutout. There is no
per-`step_type` dim branching anywhere - `_apply_step_to_grid()` (D60)
already calls `clear_highlight()` for any step with no
`highlight_position`, and no tutorial today sets one during a
`WAIT_FOR_TARGET_ACTIVATION`/`WAIT_FOR_PUZZLE_SOLVED` step, so "remove
dim while the player watches the beam/result" falls out for free. If a
future tutorial ever needs a highlight during one of those step types,
revisit this coupling then - don't add speculative branching now.

**Pause interaction:** `pause_menu.tscn` has its own independent
full-screen dim (alpha 0.72, pre-existing, unrelated to Tutorial).
Without intervention, opening Pause during a dimmed step would stack
both dims into a much darker board. `GridManager.suspend_tutorial_focus()`
(called from `game.gd._on_pause_pressed()`) hides the highlight+dim
without forgetting the highlight position; `resume_tutorial_focus()`
(called from `_on_pause_resume_pressed()`) restores them only if a
highlight is still actually active. `game.tscn`'s `PauseMenu` is also
deliberately the LAST child in the scene tree (moved there by this same
fix - it used to render *under* `TutorialPanel`), so Pause always
renders on top of the tutorial instruction panel too.

**Completion cleanup:** `game.gd._clear_tutorial_focus_visuals()` is the
one authoritative place that calls `_grid.clear_highlight()`, invoked
explicitly at every tutorial exit path (completion, restart, back to
Tutorial Select, back to Main Menu, scene teardown via `_exit_tree()`) -
defense-in-depth on top of the fact `clear_highlight()` already runs as
a side effect of every real step transition.

**Environment note for whoever next captures rendered screenshots of
this system:** in this project's dev environment, a non-headless
`godot --path .` run has been observed opening in a desktop window that
does NOT match `project.godot`'s declared 1080x1920 (and an explicit
`--windowed --resolution 1080x1920` CLI flag did not change it either -
environment-specific windowing). Don't assume screen pixel coordinates
from the design resolution; read the actual geometry
(`grid.global_position`, `TutorialHighlight.global_position`/`size`,
`get_viewport().get_visible_rect().size`) from the same run and scale
against the saved screenshot's real pixel dimensions before sampling or
cropping - see `DECISIONS.md` D62 for the technique that found this.

## 13. Pitfall that caused a second real shipped failure: a `.tscn` instance node's layout override can silently replace its own base scene's layout

**Read this before adding an `anchors_preset`/`anchor_*`/`offset_*`
override to any `.tscn` INSTANCE node (a `[node ... instance=ExtResource(...)]`
block), especially for `TutorialPanel`.** `versionCode=20`'s manual video
QA found the highlighted mirror at T01's `REQUIRE_TILE_TAP` step was
clearly visible but could not be tapped - repeated taps did nothing.

**Root cause:** `scenes/ui/tutorial_panel.tscn`'s own root node is
correctly anchored to a ~220px-tall band at the bottom of the screen
(`anchor_top = 1.0, offset_top = -260, offset_bottom = -40`). But
`scenes/gameplay/game.tscn`'s `TutorialPanel` INSTANCE node
redundantly re-declared `anchors_preset = 15` (full rect) plus
`anchor_right = 1.0` / `anchor_bottom = 1.0` on top of it - a
per-instance override in the parent scene completely replaces the
instanced scene's own anchor values for that node. This made
`TutorialPanel`, and critically its `Panel` child (a `PanelContainer`
that had no explicit `mouse_filter` override, so it used the Control
class default of `MOUSE_FILTER_STOP`), cover the **entire game
screen** instead of the intended bottom band. `Panel`'s `STOP` filter,
sitting later than `PuzzleGrid` in `game.tscn`'s sibling order (so it's
hit-tested first), silently intercepted every tap anywhere on the
board before any tile could ever receive it. The bug was invisible on
screen because `Panel`'s `StyleBoxFlat` background is only 88% opaque
and blends into BeamShift's already-dark gameplay art - the highlighted
mirror stayed fully visible underneath it.

**Why this evaded D60-D62's testing entirely:** every prior automated
check either called `GridManager._on_orientable_tile_clicked()`
directly (which bypasses the Viewport's hit-testing/Control-tree
routing completely - it can never catch a Control silently intercepting
input above the grid) or checked visual appearance (which this bug
doesn't disturb). **The only thing that caught it was dumping the
*runtime* `mouse_filter` and `get_global_rect()` value of every Control
between the Viewport and the highlighted tile**, and comparing that
against what the `.tscn` source *appeared* to declare - the mismatch
(full-screen at runtime vs. a ~220px band in the base scene's own file)
was immediately obvious once printed, but invisible from reading either
`.tscn` file in isolation, since `tutorial_panel.tscn`'s own anchors
were never wrong - only `game.tscn`'s instance-level override was.

**Fix:** removed the conflicting override from `game.tscn`'s
`TutorialPanel` instance node entirely, keeping only the legitimate
state overrides (`unique_name_in_owner`, `visible = false`) so it
correctly inherits the base scene's own bottom-anchored layout.
Hardened alongside: `tutorial_panel.tscn`'s `Panel` node now also sets
`mouse_filter = MOUSE_FILTER_IGNORE` directly, so only its actual
`ContinueButton` can ever consume a tap, regardless of what the panel's
own rect ends up covering in the future.

**When adding a new full-screen popup/overlay scene as a `game.tscn`
child, verify its instance node's anchor overrides (if any) actually
match what its own base `.tscn` declares** - if they don't (or if
you're not sure), dump the runtime `mouse_filter`/`get_global_rect()`
of the instantiated node rather than trusting either file's source in
isolation. See `DECISIONS.md` D63 for the full investigation, including
the real-rendering ancestor-chain-dump technique that found it (direct
method calls and visual screenshots both missed this bug entirely,
because neither exercises the Viewport's actual GUI input hit-testing
path).

## Fusion Node (Phase 1, D99)

No Fusion tutorial exists yet. **RELEASE BLOCKER (D100): a proper player-facing Fusion tutorial must exist before production levels can introduce Fusion** (procedural generator V4 already places Fusion from Level 201 in the QA build). Not built in Phase 2; build it only when asked. `assets/ui/icons/bs_fusion_icon.png` is reserved for it. Fusion QA puzzles are not tutorials (no steps, no `TutorialManager`).

## 14. Fusion tutorial pack T21-T28 (Fusion Phase 3, `DECISIONS.md` D101, `versionCode=56`)

Eight more tutorials, built with exactly the same machinery as T01-T20 (`TutorialLevelData` + `TutorialStepData` + `TutorialManager`, the single `GridManager._on_orientable_tile_clicked()` gate, the highlight/dim coupling of section 12) - **no new framework, no tutorial-only mechanic**. Fusion is an orientable tile (`_orientable_nodes`), so `REQUIRE_TILE_TAP`, `has_orientable_tile()` and the Hint's `target` mode work on it unchanged; a Fusion tap advances its 4-state output one clockwise step.

| Id | Name | Teaches | Forced taps |
|---|---|---|---|
| T21 | Fusion Node | RED + GREEN = YELLOW; the node's beam leaves one side | 1 (node) |
| T22 | Output Side | output direction; an input side cannot also be the output (DOWN -> LEFT -> UP -> RIGHT, two of the turns switch the node off) | 3 (node) |
| T23 | Color Recipes | RED + BLUE = MAGENTA, GREEN + BLUE = CYAN (two nodes, one at a time) | 2 |
| T24 | Three Colors | RED + GREEN + BLUE = WHITE (a Prism proves it: only WHITE splits into three colour targets; a WHITE target would accept anything) | 1 |
| T25 | Fusion Filter | WHITE emitters + GREEN/BLUE Filters on the INPUT paths -> CYAN; a Filter AFTER a node would repaint its colour | 1 |
| T26 | Fusion Portal | one input travels mirror -> portal pair -> node; trace inputs to their emitters | 2 (mirror, node) |
| T27 | Fusion Relay | node -> Receiver -> Remote Emitter -> mirror -> target | 2 |
| T28 | Fusion Trial | free play: Filter + Portal + Fusion + Receiver/Remote + Gate (opened by an independent Switch) | 3 (`wait_for_solved`, Hint available) |

Authoring rules that each mattered: every board has exactly ONE solution (brute-force it through `LaserSystem.simulate_until_stable()` over every orientation combination - Fusion has 4 states, so `LevelSolver` cannot); a node that starts facing an input side is dark, which is how T21/T23/T24/T25/T27 make one tap enough; never let a gate depend on a beam that itself needs the gate's own downstream result (T28's Gate is opened by an independent emitter -> mirror -> Switch beam); a WHITE target accepts any colour, so proving a WHITE fusion needs a Prism. Display names stay <= 13 characters (the HUD title truncates).

**Hints.** `levels/hint_solutions.json` holds `t21`-`t28` (Fusion value = `Direction` 0-3, mirror 0/1). They are hand-authored and verified against the brute-force unique solution; `scripts/tools/hint_solution_builder.gd` skips ids >= `LevelManager.FUSION_TUTORIAL_FIRST` so the binary-flip solver can never erase them. Tutorials remain ad-free and free-hint.

**Unlock.** T21-T28 are not era-gated (`EraTheme.get_era_for_tutorial(21)` says Era 3; the era rule would demand Campaign Level 200). `LevelManager.is_fusion_tutorial_selectable()`: T21 when `SaveManager.procedural_current_level >= FUSION_TUTORIAL_UNLOCK_PROCEDURAL_LEVEL` (150) or `tutorial_highest_unlocked_level >= 21`; T22-T28 sequential; `UNLOCK_ALL_ERA_2_TUTORIALS_FOR_TESTING` opens all (must be `false` for production). The pack is available ~50 levels before the first Fusion roll (procedural Level 201) but is not a hard gate.

**Verification recipe (dev-only, do it after any edit to a Txx file or Fusion rules):** a temporary driver scene that (1) brute-forces every orientation combination and asserts exactly one solving combination equal to the hint table, (2) starts `GameManager.start_tutorial(id)` in the real game scene and walks every step (MESSAGE -> `_on_tutorial_panel_continue_pressed()`, REQUIRE_TILE_TAP -> wrong tile rejected, Hint candidate == step target, then tap; free steps -> apply the table), asserting completion/popup/Reset. Back up and restore `user://savegame.json` around it (it records tutorial completion). Render at least the densest board (T28) non-headless.

## Phase 4 (D102, `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`) - stars, Hint cap, central QA switch, Fusion tutorial nudge

- **Stars:** one rule in `StarScoring` (OPTIMAL from `verified_optimal_moves` >= 0, else `intended_moves`, else legacy `optimal_moves`; +2 = 3 stars, +6 = 2, else 1; below optimal = 3 + QA warning). A GRANTED gameplay Hint caps the attempt at 2 stars (`game.gd._hint_used_this_attempt`, persisted in `procedural_resume_hint_used`/`campaign_resume_hint_used` so Continue cannot reset it; cleared by Reset/Next/QA +50). Best stars: `SaveManager.procedural_best_stars["<level>|<generator_version>"]` (raise-only) and the existing campaign dictionary. Tutorials, V3 TEST, FUSION TEST: no stars, no records. The popup shows the current run's stars + a small "HINT USED".
- **QA vs production:** ONE constant, `BuildConfig.IS_PRODUCTION_BUILD` (false in this build). It derives every QA-only UI/unlock flag in `LevelManager` and hides the tutorial debug overlay and the generator tag. Tools are hidden, never deleted. Not covered: Google TEST ad ids, and the generator rollout flags `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA`.
- **Fusion tutorial nudge:** one-time non-blocking "NEW TUTORIAL: FUSION" banner on Main Menu (`LevelManager.should_show_fusion_tutorial_nudge()`, persisted `fusion_tutorial_nudge_seen`); never forces the tutorial, never locks progression. `bs_fusion_icon.png` remains unused (no icon support in the tutorial panel).
- Level 2000 remains the certification target; nothing beyond it is exposed; no new mechanic.
