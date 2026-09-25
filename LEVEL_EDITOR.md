# LEVEL_EDITOR.md

The BeamShift level editor: a development-only tool for creating, editing,
validating, solving, and playtesting levels without hand-writing GDScript.
Written so a new Claude session or a human developer can use it with zero
prior context. If anything here disagrees with the actual code, the code
wins — `tools/level_editor/level_editor.gd` and `scripts/tools/*.gd` are
authoritative.

**This is a development tool. It is not part of the shipped player-facing
game** — see ARCHITECTURE.md ("Editor architecture") for how it's kept
separate from the runtime gameplay path and excluded from the Android
export.

## How to open the editor

1. Open the BeamShift project in the Godot 4.7 editor.
2. In the FileSystem dock, navigate to `tools/level_editor/` and open
   `level_editor.tscn`.
3. With that scene as the active tab, press **F6** ("Run Current Scene")
   — not F5 (which runs the project's main scene, the actual game).
4. The editor window opens directly into a blank 5x5 level, ready to edit.

There is no menu item or button inside the shipped game that opens the
editor — it's a separate scene you run directly in the Godot editor, by
design (see DECISIONS.md, "Level editor architecture").

## Creating a level

1. Fill in the top bar: **ID** (a unique integer — doesn't need to match
   an existing level unless you intend to overwrite one), **Name**,
   **W**/**H** (grid width/height — tested at 4x4 through 9x9, but the
   spinboxes accept 3–20 for future flexibility; the underlying
   `LevelData.grid_width`/`grid_height` fields are plain integers with no
   hardcoded size limit), and **Optimal Moves** (your own estimate — the
   solver will tell you the real number later, and warn you if they
   disagree).
2. Click **Apply Grid Size** to build the grid at those dimensions. This
   button is *not* a "start over" button — if you change the width/height
   later after placing tiles, it resizes the grid and keeps every tile
   that still fits inside the new bounds, dropping (and reporting) any
   that don't. To truly start from scratch, place a fresh scene (re-run
   the editor) or manually erase everything with the Eraser tool.
3. Optionally fill in **Stage**/**Notes** in the second bar — these are
   the Milestone 3 development/campaign-planning metadata fields
   (`LevelData.stage`, `developer_notes`, `is_campaign_level`). None of
   them affect gameplay; they're purely organizational. The editor
   doesn't currently expose a control for `is_campaign_level` directly —
   set it via the Godot editor's Inspector on a saved `.tres` file, or
   leave it at its default (`false`, meaning "development/test level")
   until Milestone 4 needs it.

## Tile placement

The palette on the left has one button per tile type, plus two special
tools:

- **Select / Inspect** — click a placed tile to select it (without
  changing it) and see its properties in the right-hand panel.
- **Eraser** — click a cell to remove whatever's there.
- **Emitter, Mirror, Blocker, Target, Splitter, Filter, Portal, Switch,
  Gate, Hazard** — click any cell to place a tile of that type there,
  with sensible defaults (documented in "Tile properties" below).
  Placing a tile on an occupied cell replaces whatever was there.

Only one palette tool is active at a time (they're a toggle group).
Left-click is the only input the editor uses — this is a desktop-mouse
tool, per the milestone's explicit priority; touch has not been tested
and isn't a design goal for this tool.

After placing a tile, it's automatically selected, so its properties
immediately appear in the right-hand panel for you to adjust.

## Tile properties

The properties panel only shows fields relevant to the selected tile's
type:

| Tile | Fields |
|---|---|
| Emitter | Direction (UP/RIGHT/DOWN/LEFT), Beam Color (WHITE/RED/GREEN/BLUE) |
| Mirror | Orientation (`/` or `\`), Rotatable (checkbox) |
| Splitter | Orientation (`/` or `\`), Rotatable (checkbox) |
| Target | Required (checkbox), Required Color (WHITE = accepts any beam) |
| Filter | Output Color (the color it forces any passing beam to become) |
| Portal | Pair ID (a text string — **exactly two** portal tiles must share the same Pair ID to function; see "Validation" below) |
| Switch | Opens Gate ID (the `gate_id` of the GATE tile(s) this switch should open) |
| Gate | Gate ID (its own identity, matched against switches' "Opens Gate ID"), Starts Open (checkbox) |
| Blocker, Hazard | (no properties) |

Every field edits the live `TilePlacement` object directly — there's no
separate "Apply" step, and the grid cell's label updates immediately.

A **Remove This Tile** button at the bottom of the panel deletes the
currently selected tile.

## Validation

Click **Validate** to run `LevelValidator.validate()` against the
current level (see ARCHITECTURE.md for exactly what it checks) and print
the results to the output panel at the bottom. Two categories:

- **Errors** — genuine structural problems: no emitter, no required
  target, a tile outside the grid, two tiles on the same cell, a portal
  not paired with exactly one partner, a switch referencing a gate_id no
  GATE tile has, and similar. **A level with any errors cannot be
  saved** — the Save button re-runs this same check and blocks the save,
  printing why.
- **Warnings** — technically valid but worth a second look: no rotatable
  pieces at all, an unusually high tile count, a gate nothing ever opens,
  or the level already being solved with zero moves ("TRIVIAL
  SOLUTION"). Warnings never block anything.

## Solver / Analyze

Click **Run Solver / Analyze** to run `LevelSolver.analyze()` — a real
breadth-first search over every combination of your rotatable mirrors'
and splitters' orientations, using the actual `LaserSystem` to check each
candidate (never an approximation). It reports, in the output panel:

- **Solvability**: `SOLVABLE`, `UNSOLVABLE`, or `UNKNOWN`.
  - `UNSOLVABLE` means the solver explored *every* reachable
    configuration and found none that solves it — this is a real,
    proven negative, not a guess.
  - `UNKNOWN` means the search's safety limit (65536 states by default —
    see `LevelSolver.DEFAULT_MAX_STATES`) was hit before the search
    could finish. **This is not the same as unsolvable** — it just means
    the level has more rotatable pieces than the default budget covers
    exhaustively. For any hand-authored level with a reasonable number
    of rotatable pieces (roughly ≤16), this should never happen.
- **Declared vs. Calculated Optimal Moves** — if your `Optimal Moves`
  field doesn't match what the solver actually found, you'll see an
  explicit warning telling you which direction the mismatch runs (a
  shorter solution exists, or your declared value was optimistic).
- **Shortest Solutions Found** — how many *distinct* board configurations
  achieve that minimum move count. More than one usually means there's
  more than one valid path to victory, which may or may not be
  intentional design.
- **States Explored** and elapsed time — search statistics.
- **An example shortest solution** — one concrete move-by-move sequence
  (which tile, old orientation → new orientation), for your reference
  only. **This is development information — the shipped game never shows
  players a solution.**
- **Possible decoy pieces** — any rotatable piece whose orientation
  didn't matter in at least one found shortest solution (i.e., flipping
  it doesn't break that solution). This is informational only — nothing
  is ever auto-removed, and a flagged piece may still be a legitimate
  decoy *by design* (Level 5, "Three Turns," has exactly one intentional
  decoy mirror that the solver correctly identifies).
- **Difficulty Estimate** — see the next section.

Running Solve also refreshes the "Difficulty" readout in the metadata
bar.

## Difficulty metrics

`LevelMetrics.compute()` reports grid size, tile-type counts, rotatable
vs. fixed piece counts, which mechanics are present, and a rough
difficulty band (`TUTORIAL`/`EASY`/`MEDIUM`/`HARD`/`EXPERT`) from a
simple, fully transparent formula (see DECISIONS.md, "Difficulty
heuristic," for the exact weights). **This is explicitly an estimate,
not a scientific measurement** — it exists to give a level designer a
quick reference point, not a verdict. Use your own judgment; the label
is not authoritative and is expected to need recalibration once real
campaign levels exist to compare against.

## Saving

The **Save** field holds the target path — it must end in `.tres`
(e.g. `res://levels/level_16.tres`). Clicking **Save**:

1. Re-runs the structural validator. If there are errors, the save is
   blocked and the errors are printed — nothing is written to disk.
2. Prints any warnings (non-blocking).
3. Writes the level via `ResourceSaver.save()` and refreshes the Load
   dropdown so the new file appears immediately.

Levels saved this way are real `LevelData` `.tres` resources —
`LevelManager` loads `.tres` files exactly as it loads the existing
`.gd`-script levels (see ARCHITECTURE.md, "Level data format").

## Loading

The dropdown next to **Load** lists every level in
`LevelManager.LEVEL_PATHS` (the 15 shipped dev/regression levels) plus
every file under `levels/editor_fixtures/` (prefixed `[fixture]`).
Select one and click **Load** — it replaces whatever's currently in the
editor (unsaved changes are lost, there's no prompt, so save first if you
want to keep them) and restores every field: grid size, every tile and
its properties, orientations, colors, IDs, rotatable flags, and metadata.

## Playtesting

Click **Playtest** (blocked the same way Save is, if the level has
structural errors) to launch the level using the **real** gameplay scene
— the exact same `game.tscn`/`GridManager`/`LaserSystem`/tile visuals a
player would see, not a separate preview. While playtesting:

- Solving, resetting, and the Level Complete popup all work normally.
- **Nothing is written to the player's save file** — playtest results
  never touch `SaveManager`.
- The popup's "Next Level" button is hidden (there's no "next" for an
  in-progress editor level) and its star count is a preview computed
  against your currently-declared `Optimal Moves`, not real game state.
- **Back** or **Level Select** on the completion popup both return you
  to the editor, not to the real Level Select — and your in-progress
  level (including any unsaved edits) is restored exactly as you left
  it.

## Interpreting warnings

| Warning | What it means |
|---|---|
| "Level has no rotatable mirrors or splitters" | The player can never make a move — probably not what you want unless this is intentionally a zero-interaction demo. |
| "Level has N tiles, which is a lot" | Just a nudge to reconsider complexity (threshold: 40 tiles). |
| "Gate ... has no switch that opens it" | The gate will sit at its initial state forever — fine if intentional (an always-open or permanently-closed gate), otherwise likely a missing switch. |
| "Level is already solved in its authored (zero-move) state — TRIVIAL SOLUTION" | The player wins without doing anything. Almost always a mistake for a real level. |
| Solver: "declared optimal_moves does not match the solver" | Update your `Optimal Moves` field to the solver's number before shipping this level, so the in-game 3-star threshold is accurate. |
| Solver: "Possible unused/decoy piece(s)" | Not necessarily a problem — verify it's an intentional decoy, not a forgotten leftover piece. |

## Search limits

`LevelSolver.DEFAULT_MAX_STATES` is 65536 — exhaustive for any level with
up to 16 rotatable pieces (2^16 states). This is a hard-coded constant,
not currently exposed as an editor UI field; if a future level design
genuinely needs more, call `LevelSolver.analyze(level, larger_limit)`
directly (e.g. from a temporary script) rather than assuming the editor
button can be reconfigured without a code change. See DECISIONS.md
("Solver search-limit strategy") for the reasoning behind the default.

## Known limitations

- Desktop mouse only — no touch support, no on-screen keyboard
  accommodations. This is intentional (Part 2 of the milestone brief:
  "Desktop mouse interaction is the priority for the development
  editor").
- No undo/redo.
- No copy/paste of tiles.
- No confirmation prompt before Load discards unsaved changes.
- The grid cells are simplified placeholder buttons (text abbreviations
  + color tint), not the actual gameplay `TileVisual` scenes — this was
  a deliberate simplification to keep the editor's own UI code low-risk;
  Playtest uses the real visuals since it launches the actual game scene.
- `is_campaign_level` has no dedicated UI control yet (see "Creating a
  level" above).
- The solver's `DEFAULT_MAX_STATES` isn't exposed in the UI (see "Search
  limits" above).
- Decoy detection only checks single-piece toggles against each found
  shortest solution, not combinations of pieces toggled together.
- No procedural/random level generation — by design, per the milestone
  brief (Part 27): this tool assists a human designer, it doesn't replace
  one.

## Example workflow (matches the manual test plan in the final report)

1. Open `tools/level_editor/level_editor.tscn`, press F6.
2. Set W=5, H=5, click Apply Grid Size.
3. Select Emitter, click a cell; select Mirror, click another cell;
   select Target, click a third cell.
4. With Select/Inspect, click the mirror and set its orientation so the
   puzzle isn't already solved.
5. Click Validate — expect PASS.
6. Click Run Solver / Analyze — note the calculated optimal moves.
7. Click Playtest, solve it manually in the real game window, confirm
   the moves used match what the solver reported.
8. Return to the editor (Back or Level Select from the completion
   popup) — confirm your level is exactly as you left it.
9. Set a Save path ending in `.tres`, click Save.
10. Click Load, pick the file you just saved, confirm every property
    restored correctly.
