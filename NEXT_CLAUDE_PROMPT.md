# NEXT_CLAUDE_PROMPT.md

Copy-paste this into a new Claude session/account working on BeamShift.

---

You're continuing work on **BeamShift**, a Godot 4.7.1 mobile-first
(portrait) laser-reflection logic puzzle game. Before doing anything
else:

1. Read, in order: `CLAUDE.md`, `PROJECT_HANDOFF.md`, `CURRENT_STATUS.md`,
   `ARCHITECTURE.md`, `DECISIONS.md`, `ROADMAP.md`, `TEST_PLAN.md`,
   `LEVEL_EDITOR.md`, `CAMPAIGN_DESIGN.md` (Milestone 4+ — the real
   100-level campaign's own architecture/design reference; read it
   before touching anything under `levels/campaign/`), and
   `TUTORIAL_SYSTEM.md` (Guided Tutorial Mode — the T01–T10 tutorial's
   own architecture/design reference; read it before touching anything
   under `levels/tutorial/`, `scripts/managers/tutorial_manager.gd`,
   `scripts/resources/tutorial_*.gd`, `scripts/ui/tutorial_*.gd`, or
   `scenes/ui/tutorial_*.tscn`), and `ERA_2_DESIGN.md` (Era 2
   "Refractions" — the Era architecture, the four new mechanics'
   exact rules, T11-T20, and now Campaign Levels 101-110; read it
   before touching any Era 2 code, `levels/campaign/era2_stage_01/`,
   or `levels/tutorial/t11.gd`-`t20.gd`), `PROCEDURAL_GENERATION.md`
   (Phase 3+ — the procedural level generator's own reference, incl. section 19 = the V3 progression generator; read it
   before touching `scripts/procedural/**`), and `AUDIO_SYSTEM.md`
   (Audio/SFX Integration Pass+ — the centralized SFX architecture's own
   reference; read it before touching `scripts/managers/audio_manager.gd`,
   `assets/sfx/**`, or any `AudioManager.play_*()` call site).
2. Do not assume you have access to any previous chat history.
3. **Inspect actual project state before trusting the documentation** —
   if a doc and the code disagree, the code is authoritative; fix the
   doc, note the discrepancy, move on.
4. **Read `DECISIONS.md`'s D40, D44-D55 and `CLAUDE.md` rules 12a-12e
   before touching any UI/visual code, level-completion logic, export
   filters, or writing any test.** This project has a documented history
   of visual/gameplay passes that looked "fixed" by every automated check
   but still failed real manual QA multiple times in a row (Milestones
   4A, 4A.1, 4A.2, and again with Level 3's tiles vanishing on Android
   despite passing every source-based check - D51). The techniques that
   actually resolved that pattern, and that you should use by default now
   rather than rediscovering:
   - **A source-based check (even a rendered screenshot) can never catch
     an export-filter-exclusion bug.** `godot --path .` reads source
     files directly and completely bypasses `export_presets.cfg`'s
     `exclude_filter`. If a script `preload()`s a resource under a
     partially-excluded folder (see the filter's current patterns:
     `tools/**`, `scripts/tools/**`, `levels/editor_fixtures/**`,
     `assets/gameplay/pieces/**`, `assets/gameplay/tiles/**`,
     `assets/branding/app_icon/**`), it can pass every desktop test ever
     devised and still fail to parse/load in the real exported build
     (D51 - this exact thing happened to `blocker.gd`/`hazard.gd` and
     silently broke 4 of 15 levels). **Whenever you touch, add, or move
     a gameplay-referenced asset, or touch the export filter itself,
     verify against a real exported package**: `godot --headless --path .
     --export-pack "Android Debug" out.pck`, then
     `godot --headless --main-pack out.pck --script check.gd` using
     `ResourceLoader.exists(path)` and/or actually instantiating the
     scene in question. This needs no physical device and is fully
     automatable - see `TEST_PLAN.md`'s "Android HUD Alignment + Missing
     Tile Fix" section for the exact commands.
   - **Non-headless screenshot capture works on this machine** (real GPU
     confirmed — NVIDIA RTX 4080, D3D12). Running `godot --path .` (no
     `--headless`) and calling
     `get_viewport().get_texture().get_image().save_png()` produces a
     real PNG you can open and look at with your own image-reading tool.
     **Use this before claiming any UI "looks right."** With real
     rendering active, `Input.parse_input_event()` also correctly
     dispatches to `Control._gui_input()` — so a genuine simulated click
     test (not a bypass) is possible too, unlike under `--headless`
     (`Viewport.push_input()` does not reach `_gui_input()` there — a
     confirmed, real Godot limitation, not a bug to "fix").
   - **A "the fix isn't in my build" report is a build-identity question
     first.** Before re-diagnosing code that automated checks and
     rendered screenshots both say is correct, check
     `export_presets.cfg`'s Android `version/code`/`version/name` and
     verify the actual built APK's metadata with
     `aapt2 dump badging <apk>` — don't just trust the source file. A
     same-versionCode reinstall can silently leave a device on a stale
     APK. **But also don't over-apply this** — Milestone 4A.3 concluded
     "stale APK" for a Level 3 report, the user then confirmed the build
     WAS current and the bug still reproduced, which meant Milestone
     4A.3's conclusion (though reasonable at the time) was wrong; the
     4A.4 re-investigation had to actually re-trace everything again
     rather than re-assert the stale-build theory a second time. Treat
     "stale build" as a hypothesis to verify, not a default answer.
   - This project uses a strict three-tier validation vocabulary:
     **AUTOMATED** (headless script/layout checks — proves logic/layout
     math, not visuals, and cannot dispatch real `_gui_input`),
     **RENDERED** / **DESKTOP RENDERED** (a real screenshot you've
     actually looked at, on this machine), **MANUAL** / **ANDROID MANUAL
     QA** (the user's own device/eyes). Only the MANUAL tier can approve
     a milestone. Never present a lower tier as a higher one in any
     report you write.

## Where things stand

**Read `CURRENT_STATUS.md` first for what's actually true right now** —
everything below this point in this file is a chronological narrative
that has not been kept current across every pass (it stops mid-"Stage 5"
in its own "What to do next" section, long before the 100-level campaign
even finished). If anything below disagrees with `CURRENT_STATUS.md` or
`DECISIONS.md`'s latest entry, trust those, not this file's older
sections. This file's own final section (below the historical narrative)
has been refreshed as of Phase 1 (`DECISIONS.md` D84) — that's the
accurate "what to do next."

**Milestones 1-3** are implemented and validated to varying degrees (see
`CURRENT_STATUS.md` for the exact split — Milestone 1 is fully
device-validated, Milestone 2 has no itemized manual report, Milestone 3
has never been touched by a human in the editor).

**Milestones 4A → 4A.3** progressively built and corrected final visual
asset integration, including a real Level 3 mirror-rotation bug (fixed in
4A.2, D40), and then an audit (4A.3, D44-D47) that found the code correct
via rendered screenshots and pointed to a stale APK install as the likely
cause of a third failed manual QA round — versionCode was bumped and a
"BUILD 4A.3" QA label added so build identity could be confirmed with
certainty going forward.

**Milestone 4A.4 — Level 3 Device/Runtime Re-Investigation** (same day as
4A.5 below): the user confirmed BUILD 4A.3 genuinely was installed and
Level 3 **still** failed on their device — ruling out 4A.3's stale-APK
conclusion. A full re-trace (runtime level resource, tile dump, target
visibility, input path, orientation mapping, a REAL rendered click-driven
test through the actual `_gui_input` path, and a full 15-level + Reset
regression) found **no code defect whatsoever** — everything traced and
worked correctly, this time confirmed via genuine click-through rather
than a re-assertion. A temporary "L3 DEBUG" on-screen overlay was added
(Moves/mirror A+B orientation/Targets/Solved, Level 3 only) so the user's
own device could report what state it actually reaches, in case the real
cause is something genuinely Android-only that neither headless nor
desktop-rendered testing can reproduce (a digitizer quirk, a specific
device's input driver double-firing, etc.). **This overlay has since been
removed** (Milestone 4A.5, once Level 3 was treated as confirmed working)
— if you're picking this project up and Level 3 is reported broken again
on-device, know that a very thorough re-trace already happened and found
nothing; re-adding a similar debug overlay before doing another full
guess-and-fix cycle is a reasonable next step.

**Milestone 4A.5 — Portrait UI Replacement + Responsive HUD Integration**
(the user's own brief for this pass called it "Milestone 4A.4" — numbered
4A.5 in the docs only to avoid colliding with the Level 3
re-investigation pass above, which claimed "4A.4" first the same day).
Five new portrait UI assets were supplied
(`assets/ui/panels/bs_panel_{settings,pause,level_complete}_portrait.png`,
`assets/ui/hud/bs_hud_{top,bottom}_portrait.png`):
- **Pause, Level Complete, and the gameplay top/bottom HUD** were
  integrated with the new art. The HUD bars now use a new
  `scripts/ui/aspect_bar.gd` (`class_name AspectBar`) attached to
  `TopBar`/`BottomBar` in `game.tscn`, which locks the bar's height to
  the source art's aspect ratio on every resize (same resize-driven
  pattern `grid_manager.gd` uses for its own square cells) — the new HUD
  art has a structural reactor-icon centerpiece that would visibly
  distort under the old fixed-height `StyleBoxTexture` approach. See
  `DECISIONS.md` D49 for the exact slot-fraction mapping (pixel-sampled,
  not guessed) and the accepted tradeoff (bars are now ~300-315px tall
  at the 1080-logical-width reference, vs. the old fixed 160px, because
  the art's own proportions require it once distortion is ruled out —
  the puzzle grid was measured at ≈45.8% of screen area vs. ≈16.3% per
  bar, still the single largest region).
- **Settings was, in this pass only, deliberately left on its old art.**
  The originally-supplied `bs_panel_settings_portrait.png` was a
  byte-identical mislabeled duplicate of
  `bs_panel_level_complete_portrait.png` (confirmed via MD5 — both said
  "LEVEL COMPLETE", not "SETTINGS"). Shipping that would have made the
  Settings screen visibly say the wrong thing. See `DECISIONS.md` D48.
  **This was fixed the same day in Milestone 4A.6 below** — don't treat
  Settings as still broken.

**Milestone 4A.6 — Corrected Settings Panel Integration + Final UI QA**
(current). The user manually supplied a corrected
`bs_panel_settings_portrait.png`. Verified independently before
integrating (MD5 now differs from the Level Complete asset; gear icon +
baked "SETTINGS" title visually confirmed) and wired into
`settings_menu.tscn` exactly like Pause/Level Complete
(`texture_margin_*` re-measured against this specific file, not reused
from the old asset). **All five Milestone 4A.5 replacement assets are
now active and correct** — Settings, Pause, Level Complete, top HUD,
bottom HUD. See `DECISIONS.md` D50.
- Zero gameplay/simulation code was touched by either 4A.5 or 4A.6. All
  15 levels' solver-vs-runtime-replay regression still PASS (confirmed,
  not assumed, after every pass). The temporary Milestone 4A.4
  "L3 DEBUG" overlay was removed in 4A.5.
- Current build at the time: `versionCode=8`, `versionName="1.0.0-UIFINAL"`.
  Check `CURRENT_STATUS.md` for whether a newer build exists.
- DESKTOP RENDERED screenshots were captured and personally inspected
  across both passes — all correct visually. **But this pass's desktop
  testing method (running from source) turned out to be structurally
  unable to catch the real bug the user's first Android test then found
  — see below.**

**"Android HUD Alignment + Missing Tile Fix"** (current). The user's
first real Android manual QA pass on the 4A.6 build found: top/bottom HUD
alignment problems, and — far more seriously — **Level 3's puzzle tiles
were completely invisible on Android** (laser beam and background still
rendered fine, level logic still worked). **Root cause found and fixed
without any physical Android device**, by actually running the real
exported package headlessly instead of testing from source (a technique
this milestone introduces — see `TEST_PLAN.md`'s section of the same name
and `DECISIONS.md` D51 for the full trace):
- `blocker.gd`/`hazard.gd` preloaded their tile textures from
  `assets/gameplay/pieces/`, which is entirely excluded from the Android
  export filter (`export_presets.cfg`) as an "unused duplicate art"
  folder — except these two specific files were never actually unused.
  In a real exported build this makes both scripts fail to parse, which
  makes `grid_manager.gd`'s statically-typed
  `var node: BlockerTile = BLOCKER_SCENE.instantiate()` throw an uncaught
  runtime error that **silently truncates the rest of that level's
  tile-loading loop** — every tile placed after a blocker/hazard in the
  array never gets created. The laser still renders because
  `LaserSystem` reads level data directly, independent of the visual
  nodes — exactly explaining "tiles gone, beam fine."
- **4 of 15 levels were affected, not just Level 3: Levels 3, 5, 12, 15**
  (every level with a `BLOCKER`/`HAZARD` tile).
- Fixed by moving the actually-used art into the already-established,
  non-excluded, one-folder-per-tile-type convention (`assets/gameplay/
  blocker/`, `assets/gameplay/hazard/`) and repointing the two scripts.
  `export_presets.cfg`'s exclude filter itself was correct and untouched.
- Verified three independent ways, not just asserted: (a) `ResourceLoader
  .exists()` against a real exported `.pck`, (b) a real `GridManager
  .load_level()` call against that package, (c) directly unzipping the
  actual shipped APK and confirming its contents. **If you're auditing
  this claim, redo all three — don't just trust this paragraph.**
- HUD alignment also fixed: level-name label now formats as two explicit
  clean lines (was word-wrapping to 3 lines for most level names) with a
  new ellipsis-truncation fallback; both bars' slot anchors were
  re-measured by pixel-sampling the actual art instead of eyeballing a
  screenshot. See `DECISIONS.md` D52.
- Zero gameplay/simulation logic touched. All 15 levels' solver-vs-
  runtime-replay regression still PASS (confirmed after every pass, not
  assumed).
- Build at the time: `versionCode=9`, `versionName="1.0.0-TILEFIX"`.

**"Final HUD Alignment + Level Complete Delay"** (current). Small polish
pass on top of the build above. No puzzle logic, level data, scoring, or
assets touched.
- **Bottom HUD:** re-measured `bs_hud_bottom_portrait.png`'s Reset/Pause
  slots with a pixel flood-fill (seeded inside each slot, full 2D
  bounding box - not just a single horizontal scan line like the
  previous pass used). Horizontal anchors (`0.294`/`0.7045`) turned out
  to already be accurate; the real residual offset was **vertical** -
  both buttons were anchored to the bar's exact center (`0.5`), but each
  slot's true center sits ≈6px lower at the reference resolution.
  Corrected to `≈0.5175` (Reset) / `≈0.5161` (Pause).
- **Level Complete delay:** `game.gd` gained `const LEVEL_COMPLETE_DELAY
  := 0.8` and a `_completion_pending: bool` guard. `GridManager.is_solved`
  is still set the instant the puzzle is solved - **that calculation was
  never touched**. Only `LevelCompletePopup.show_result()` is delayed,
  via `await get_tree().create_timer(LEVEL_COMPLETE_DELAY).timeout`
  inside `_on_level_solved()`, so the player sees the final beam/target
  activation for ~0.8s before the popup appears. Further mirror/splitter
  clicks during that window are rejected by a **pre-existing**
  `GridManager._on_orientable_tile_clicked()` guard
  (`if is_solved: return`) that was already there before this pass - no
  new input-locking code was written, only verified with a real click
  test. `_load_current_level()` (Reset/Retry/Next Level) clears
  `_completion_pending` immediately, so a stale delayed popup can never
  appear for a board that's moved on.
- Verified with a real (non-headless) driver using
  `Input.parse_input_event()`: Levels 1, 3, 5, 12, 15 all solved with the
  popup appearing at ≈0.75-0.90s; a click during the delay left
  `tile_orientations` unchanged; Retry/Next Level/Reset-before-solve all
  behaved correctly. All 15 levels' solver-vs-runtime-replay regression
  still PASS (checks `is_solved` directly, unaffected by the UI delay).
- Current build: `versionCode=10`, `versionName="1.0.0-HUDDELAY"`, "HUD
  + DELAY FIX" build-identity label (Main Menu/Settings, bottom-right —
  check `CURRENT_STATUS.md` for whether a newer build exists by the time
  you're reading this).
- **NOT MANUALLY APPROVED — ANDROID MANUAL QA PENDING.** This is the
  single next required step. See `TEST_PLAN.md`'s "Final HUD Alignment +
  Level Complete Delay" section for the exact checklist.

**"Era 2 Levels 131-140"** (current, `versionCode=40`,
`versionName="3.4.0-ERA2-L131-140-QA"`). "Advanced convergence pass" -
user-requested, explicitly authorized before ANY of three prior Era 2
batches had manual QA. No new mechanics. Full detail in `DECISIONS.md`
D83. Summary:
- Levels 131-140 (`levels/campaign/era2_stage_01/level_31.gd`-
  `level_40.gd`), `get_campaign_level_count()` is now 140. Highlights:
  131 shares one reflector between two Prism colors; 132/138 build
  reciprocal relay chains; 140 ("Refraction Engine") combines four
  subsystems including a two-stage Remote Emitter chain and a Portal.
- **Most shortcut-prone batch yet - 5/10 levels needed fixes**: one
  genuine authoring error (a mirror inserted into an already-complete
  straight path, making its target unreachable - `UNSOLVABLE`); two
  instances of the `WHITE`-target-bypass shortcut (including a new
  "swapped routing" variant); one genuinely new failure shape (a
  shared reflector's two beams approaching from the SAME side instead
  of opposite sides, requiring a full geometric rebuild).
- Regression: 15/15 dev, 140/140 campaign, 20/20 tutorial, 13/13 Era 2
  fixtures - all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 130->140 walk.
  RENDERED verification at three resolutions. **NOT MANUALLY APPROVED -
  Android device QA pending. A MANUAL ANDROID REVIEW CHECKPOINT is now
  recommended before Levels 141+** - four consecutive unreviewed Era 2
  batches (40 levels) await real-device feedback. Do not create
  Campaign Levels 141+, T21+, Era 3, or new Era 2 mechanics, do not
  disable QA unlock, do not make a production release** without being
  explicitly asked.

**"Era 2 Levels 121-130"** (previous, `versionCode=39`,
`versionName="3.3.0-ERA2-L121-130-QA"`). "Deep dependency pass" -
user-requested, authorized before ANY prior Era 2 batch had manual QA.
No new mechanics. Full detail in `DECISIONS.md` D82. Summary:
- Moves beyond single-chain dependency into whole-board reasoning
  across Levels 121-130 (`levels/campaign/era2_stage_01/level_21.gd`-
  `level_30.gd`). `get_campaign_level_count()` is now 130. Highlights:
  121 shares one One-Way Reflector between two Prism colors; 122/128
  build reciprocal relay chains; 125 is a backward-reasoning near-
  solution trap; 130 needs four independently-resolved prerequisites
  converging on one target.
- **Two issues found and fixed during authoring**: Level 123's grid-
  bounds error (caught by `LevelValidator`); Level 127's new shortcut
  shape - a stray beam crossed an unrelated mirror whose own default
  orientation completed an accidental Portal-bypassing shortcut, fixed
  with a precisely placed blocker.
- Regression: 15/15 dev, 130/130 campaign, 20/20 tutorial, 13/13 Era 2
  fixtures - all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 120->130 walk.
  RENDERED verification at three resolutions. **NOT MANUALLY APPROVED -
  Android device QA pending (none of the three Era 2 level batches have
  real-device feedback yet). Do not create Campaign Levels 131+, T21+,
  Era 3, or new Era 2 mechanics, do not disable QA unlock, do not make
  a production release** without being explicitly asked.

**"Era 2 Levels 111-120"** (previous, `versionCode=38`,
`versionName="3.2.0-ERA2-L111-120-QA"`). User-requested follow-up,
authorized before manual Android QA of Levels 101-110 finished. Full
detail in `DECISIONS.md` D81. Summary:
- No new mechanics - deepens Prism/One-Way Reflector/Beam Receiver/
  Remote Emitter through dependency depth, shared resources, and
  misleading local reasoning across Levels 111-120 (`levels/campaign/
  era2_stage_01/level_11.gd`-`level_20.gd`). `get_campaign_level_
  count()` is now 120.
- **Three real shortcut bugs found and fixed by the solver during
  authoring**, all the same failure shape (a beam continuing past its
  own activated target - targets never stop a beam - into a second
  mechanic it was never meant to reach): Levels 112 and 118 each
  needed one fix (moving a tile off a column shared with another
  beam); Level 120 needed two attempts - a first fix that only changed
  a default orientation left an alternate same-length shortcut behind,
  fixed for real by relocating the tile so no orientation of it was
  ever reachable by the stray beam.
- Regression: 15/15 dev, 120/120 campaign, 20/20 tutorial, 13/13 Era 2
  fixtures - all solver+runtime-replay PASS. Progression verified
  against the real `SaveManager` API across the full 110->120 walk.
  RENDERED verification at three resolutions. **NOT MANUALLY APPROVED -
  Android device QA pending (Levels 101-110 also still awaiting the
  user's own playthrough). Do not create Campaign Levels 121+, T21+,
  Era 3, or new Era 2 mechanics, do not disable QA unlock, do not make
  a production release** without being explicitly asked.

**"Era 2 Levels 101-110"** (previous, `versionCode=37`,
`versionName="3.1.0-ERA2-L101-110-QA"`). Two-part, user-requested pass.
Full detail in `DECISIONS.md` D79/D80. Summary:
- **Part A**: fixed a real Tutorial Select regression the user found on
  a real device - T11-T20's cards had become tall rectangular "poster"
  cards (a 1024x1536px asset covered/cropped into the button's 240x253
  box). Fix: stop swapping texture for Era 2 - tint the same square
  T01-T10 frame via `TextureRect.modulate`. Applied to both
  `tutorial_button.gd` and `level_button.gd`.
- **Part B**: added Campaign Levels 101-110 (`levels/campaign/
  era2_stage_01/`, not `stage_11/`), the first real Era 2 campaign
  content, combining Prism/One-Way Reflector/Beam Receiver/Remote
  Emitter with selected Era 1 mechanics. `get_campaign_level_count()`
  is now 110. All ten solver-confirmed `SOLVABLE` with a unique
  shortest solution and zero validator errors on the first authoring
  attempt. Fixed `game.gd`'s `era_transition` logic (previously keyed
  off "last implemented level," now pinned to the real Era 1/Era 2
  boundary via `EraTheme`).
- Regression: 15/15 dev, 110/110 campaign, 20/20 tutorial, 13/13 Era 2
  fixtures - all solver+runtime-replay PASS. Progression/save verified
  against the real `SaveManager` API. RENDERED verification at three
  resolutions. **NOT MANUALLY APPROVED - Android device QA pending.**
  **Do not create Campaign Levels 111+, T21+, or Era 3, do not disable
  QA unlock, do not make a production release** without being
  explicitly asked - this pass's own completion is not authorization to
  continue past its STOP CONDITION.

**"Era 2 Foundation QA/Hardening Pass"** (previous, `versionCode=36`,
`versionName="3.0.1-ERA2-FOUNDATION-FIX-QA"`). Closed the gaps the
"Era 2 Foundation" pass below left open, under its own STOP CONDITION
(no Campaign Levels 101+, no T21+, no Era 3, no production release).
Full detail in `DECISIONS.md` D78. Summary:
- The user-supplied `bs_milestone_complete_era2.png` verified (real
  alpha, no baked text/checkerboard, present in a real exported APK)
  and deliberately left unwired - Level 200 doesn't exist yet.
- **T11-T20 now have a real guided-step-machine test** (the pass below
  only solver/validator-tested them) - a driver mirroring `game.gd`'s
  own `GridManager` signal wiring drove all 10 through every step type
  including wrong-tile-tap rejection, Reset, Pause/Resume, and
  completion. **10/10 PASS.**
- **Two new UI integrations, each with a real rendering bug found and
  fixed before shipping** (both invisible from source, only caught by
  RENDERED verification): `LevelCompletePopup`/`TutorialCompletePopup`
  now swap in real Era 2 panel art via `EraTheme` (fixed a
  `content_margin` override and a content-shorter-than-frame-margins
  sizing issue), and Tutorial Select's T11-T20 cards now use the Era 2
  card art, mirroring `level_button.gd`'s previously-dormant wiring
  (fixed a `TextureRect` stretch-mode misalignment). Six other Era 2 UI
  assets reviewed and deliberately left unwired - see `DECISIONS.md`
  D78's A/B/C classification for the reasoning on each one.
- **APK size cut 24.9%** (111,090,272 → 83,384,755 bytes) by excluding
  `bs_grid_surface_era2.png` and all 8 `assets/gameplay/fx/era2/*.png`
  files (confirmed completely unreferenced - `Era2ActivationFX` is
  procedural) plus 9 unwired UI assets from `export_presets.cfg`'s
  `exclude_filter`, verified against a real exported APK's own zip
  listing (not `--export-pack`, which did not appear to honor the
  filter in this environment - see `DECISIONS.md` D78 and `CLAUDE.md`).
- **A self-inflicted near-miss worth internalizing**: this pass's own
  temporary QA scripts/screenshots were briefly left in the project
  root and got swept into a premature APK export, growing it instead of
  shrinking it - caught by listing the APK's own contents, not by
  trusting the byte count. Always use the scratchpad directory (or
  delete immediately after use) for this kind of file - see `CLAUDE.md`.
- Resolution matrix (720x1280/1080x1920/1080x2400) and color readability
  (RED beam vs. UI magenta - 68.5° hue separation, pixel-measured)
  re-confirmed clean; no gameplay color or UI scrim/glow changes made.
- Fixed a documentation undercount: the Era 2 fixture population is 13
  files, not 12.
- Regression: 15/15 dev, 100/100 campaign, 13/13 Era 2 fixtures, 20/20
  tutorial boards solvable, 10/10 T11-T20 guided step-machine - all
  PASS. **NOT MANUALLY APPROVED - Android device QA pending.**
  **Do not create Campaign Levels 101+, T21+, or Era 3, do not disable
  QA unlock, do not make a production release** without being
  explicitly asked - this pass's own completion is not authorization to
  continue past its STOP CONDITION.

**"Era 2 Foundation"** (previous, `versionCode=35`,
`versionName="3.0.0-ERA2-FOUNDATION-QA"`). Built Era 2 ("Refractions")'s
engine/architecture foundation only - **not** its 100-level campaign,
explicitly out of scope for this pass. Full detail in `ERA_2_DESIGN.md`
and `DECISIONS.md` D77:
- **Era architecture**: `EraTheme` (`scripts/resources/era_theme.gd`, a
  plain `Resource`, not an autoload) maps a campaign level/tutorial
  number to its Era and fetches that Era's themed assets - Era 1's theme
  is all-null by construction, so Levels 1-100/T01-T10 stay visually
  unchanged (verified via full regression).
- **Four new fully-deterministic mechanics** (see `ERA_2_DESIGN.md` for
  the exact rules): Prism, One-Way Reflector, Beam Receiver/Remote
  Emitter. Zero `LevelSolver` code changes needed. 13 new dev fixtures
  under `levels/editor_fixtures/era2/` cover every named interaction,
  all solver/runtime-verified.
- **T11-T20**: the Era 2 tutorial pack, locked until Level 100 is
  legitimately completed, with a QA override mirroring the existing
  campaign one. No `SAVE_VERSION` bump needed.
- **Visual theming**: per-era gameplay background/HUD/grid art in
  `game.gd`; Level Select/Tutorial Select background theming; a Level
  100 -> Era 2 transition banner in `LevelCompletePopup`; a new
  `Era2ActivationFX` violet/magenta burst (same architecture as the
  existing `LaserMirrorImpactFX`).
- **Two real bugs found via actual rendered/exported verification, not
  source review alone** - read `DECISIONS.md` D77 before assuming a
  fresh asset drop or a flag toggle is correct just because it looks
  right in source: (1) new piece art was initially placed under the
  Android-export-excluded `assets/gameplay/pieces/**` (a repeat of D51's
  exact failure mode - confirmed it would have shipped invisible Era 2
  tiles, fixed by moving into per-tile-type folders, re-verified against
  a REAL exported `.pck`); (2) the QA tutorial-unlock override didn't
  actually bypass a save with real T01-T10 progress, only caught by an
  actual rendered Tutorial Select screenshot showing T11+ still locked.
  **A new PNG or `class_name` script needs `godot --headless --editor
  --import` run once before `preload()`/type resolution works** -
  confirmed directly this pass, don't re-diagnose the resulting Parse
  Error as a code bug.
- Validated: full 115-level dev+campaign solver regression unchanged;
  all 13 new fixtures pass; all 10 new tutorials solve at their
  hand-derived `optimal_moves` (`1,1,1,2,1,1,1,1,1,2`) and pass the
  validator with zero errors; 5 RENDERED screenshots (1080x1920, real
  GPU) confirmed correct rendering, including catching bug (2) above.
- New build: `versionCode=35`, `versionName="3.0.0-ERA2-FOUNDATION-QA"`,
  111,090,272 bytes (roughly double the prior build - the new Era 2 art
  set). Both QA unlock flags kept enabled. **NOT MANUALLY APPROVED -
  Android device QA pending.** **Do not create Campaign Levels 101+,
  T21+, or Era 3 without being explicitly asked** - this pass's own
  completion is not authorization to continue; its brief had an
  explicit STOP CONDITION.

**"Levels 76-100 Portrait Re-Layout — Phase 2D, FINAL BATCH"** (previous).
Geometry-only pass on Campaign Levels 76-100's `grid_width`/
`grid_height`/tile positions — **explicitly NOT a difficulty redesign**
(see `DECISIONS.md` D76, `CLAUDE.md`'s Level editor rules/Responsive
rules, `TEST_PLAN.md`'s section of the same name). **THIS COMPLETES THE
PORTRAIT RE-LAYOUT OF ALL 100 CAMPAIGN LEVELS.**
- **Technique: identical order-preserving coordinate remap** — applied
  in three validated sub-batches (76-80, 81-90, 91-100) with a git
  checkpoint after each. This is the campaign's hardest and most
  tile-dense block (up to 42 tiles, up to 16 rotatable pieces at the
  solver ceiling 2^16=65536, up to 5 emitters) — every level was read
  in full for its own dependency graph before choosing a shape.
- **Levels 85, 91, 95, and 98 deliberately left unchanged** — already
  fully packed on both axes, zero slack to remap.
- **New technique: zero-cost row growth computed to its full safe
  ceiling** — 15 levels held their exact cell size while height
  utilization rose from 82.6% to 99.1%; 6 levels compacted 10-wide→
  9-wide for a genuine +10% cell-size gain.
- **Level 100 ("Culmination") fully verified**: all five emitter
  routes, three relay stages, both portals, symmetric convergence, and
  the fixed-mirror backward-reasoning step all confirmed identical;
  `optimal_moves`=13, `states_explored`=16383, unique solution, all
  unchanged; went 10x10→10x12 at zero cell-size cost.
- **Final read-only audit across all 100 campaign levels**: 100/100
  SOLVABLE, zero levels below 90% height / 85% width utilization, cell
  sizes 87-174px (avg 122.4px), avg width util 98.2%, avg height util
  95.6%.
- Validated: 15/15 dev + 100/100 campaign (21 changed + 4 unchanged + 75
  untouched) + 10/10 tutorial-board solvability PASS, PLUS a real-
  `GridManager` runtime replay across all 115 dev+campaign levels
  (115/115 PASS); RENDERED screenshots of Levels 76/80/85/87/90/95/100
  confirmed correct rendering; resolution checks at
  720x1280/1080x1920/1080x2400 (Level 100 at all three) confirmed zero
  HUD overlap.
- Build: `versionCode=34`, `versionName="2.9.0-PORTRAIT-100-QA"`, QA
  unlock still `true`, byte-identical size to the prior build. **Next
  required step: the user's manual Android visual QA — and given this
  is the final batch, ideally a sampled review across all four phases
  (2A-2D), since none of the portrait re-layout has been confirmed on a
  real device yet.** **Do not create Campaign Levels 101+ or start any
  further re-layout work without being explicitly asked** — the
  100-level portrait conversion effort is complete.
- **Era terminology recorded** (documentation only, not implemented):
  the complete 100-level campaign plus T01-T10 together constitute
  **Era 1**; a future Era 2 (Levels 101-200, T11-T20, new mechanics, new
  visual theme) is documented in `ROADMAP.md`, not started. Do not
  begin Era 2 without a separate, explicit request.

**"Levels 51-75 Portrait Re-Layout — Phase 2C"** (previous). Geometry-only
pass on Campaign Levels 51-75's `grid_width`/`grid_height`/tile
positions — **explicitly NOT a difficulty redesign** (see `DECISIONS.md`
D75, `CLAUDE.md`'s Level editor rules/Responsive rules, `TEST_PLAN.md`'s
section of the same name).
- **Technique: identical order-preserving coordinate remap** — applied
  in three validated sub-batches (51-60, 61-70, 71-75) with a git
  checkpoint after each, not batch-converted and validated afterward.
  This is the campaign's most mechanically interconnected block yet
  (mutual switch/gate pairs, a two-stage relay, shared-gate
  perpendicular multi-emitter crossings, post-target beam continuation)
  — every mechanic type was individually reasoned through before
  choosing a shape, not just solver-trusted, though the proof held
  unconditionally for all 25 anyway.
- **Level 75 ("Convergence Reaction") deliberately left unchanged** —
  already fully packed on both axes, zero slack to remap.
- Shapes chosen: 6x7 (2), 7x8 (6), 8x9 (5), 8x10 (1, Level 59), 9x10
  (9), 10x11 (1). Average cell size 96.7px→109.2px (+13.0%); average
  height utilization 81.9%→93.0%.
- Validated: 15/15 dev + 100/100 campaign (24 changed + Level 75
  unchanged + 75 untouched) + 10/10 tutorial-board solvability PASS,
  PLUS a real-`GridManager` runtime replay across all 115 dev+campaign
  levels (115/115 PASS); RENDERED screenshots of Levels 51/55/60/65/70/75
  confirmed correct rendering; resolution checks at
  720x1280/1080x1920/1080x2400 confirmed zero HUD overlap.
- Build: `versionCode=33`, `versionName="2.8.2-PORTRAIT-L51-75-QA"`, QA
  unlock still `true`, byte-identical size to the prior build. **Next
  required step: the user's manual Android visual QA.** **Levels 76-100
  are unchanged — re-laying out the final batch is future work, not
  started, not authorized by this pass's completion.**
- **Git checkpoints used as designed this pass**: one before touching
  any file, then one per validated sub-batch — the practice the
  previous pass introduced, now exercised across three checkpoints.

**"Levels 26-50 Portrait Re-Layout — Phase 2B"** (previous). Geometry-only
pass on Campaign Levels 26-50's `grid_width`/`grid_height`/tile
positions — **explicitly NOT a difficulty redesign** (see `DECISIONS.md`
D74, `CLAUDE.md`'s Level editor rules/Responsive rules, `TEST_PLAN.md`'s
section of the same name).
- **Technique: identical order-preserving coordinate remap to Phase 2A**
  — prefer this over hand-editing tile coordinates for ANY future
  geometry-only level change (Levels 51-100, or touching 1-50 further).
  This batch is structurally harder (splitters, filters, portals,
  switch/gate dependency, hazards/blockers, two-emitter levels) than
  1-25, so every level was read in full for its own mechanic structure
  before choosing a shape — the order-preserving proof held for all 25
  anyway, zero manual corrections needed.
- Shapes chosen: 6x7 (12 levels), 7x8 (9 levels, Level 50 "Paradox"
  among them at an unchanged 124px cell size), 8x9 (2 levels), 6x8 (1),
  9x10 (1). Average cell size 105.1px→132.0px (+25.6%); average height
  utilization 82.2%→95.2%.
- Validated: 15/15 dev + 100/100 campaign + 10/10 tutorial-board
  solvability PASS, PLUS a real-`GridManager` runtime replay across all
  115 dev+campaign levels (115/115 PASS); RENDERED screenshots of Levels
  26/28/30/35/40/45/50 confirmed larger/equal readable tiles, no
  distortion; resolution checks at 720x1280/1080x1920/1080x2400
  confirmed zero HUD overlap.
- Build: `versionCode=32`, `versionName="2.8.1-PORTRAIT-L26-50-QA"`, QA
  unlock still `true`, byte-identical size to the prior build. **Next
  required step: the user's manual Android visual QA.** **Levels 51-100
  are unchanged — re-laying out further batches is future work, not
  started, not authorized by this pass's completion.**
- **The project now has a git repository** (it had none before this
  pass — `git init` plus incremental commits after each validated batch
  is now the standing practice; don't treat the working tree as the only
  copy of anything).

**"Levels 1-25 Portrait Re-Layout — Phase 2A"** (previous). Geometry-only
pass on Campaign Levels 1-25's `grid_width`/`grid_height`/tile positions
— **explicitly NOT a difficulty redesign** (see `DECISIONS.md` D73,
`CLAUDE.md`'s Level editor rules/Responsive rules, `TEST_PLAN.md`'s
section of the same name).
- **Technique: order-preserving coordinate remap** — prefer this over
  hand-editing tile coordinates for ANY future geometry-only level
  change (Levels 26-100, or touching 1-25 further). It's provably safe:
  `LaserSystem` only depends on the *sequence* of cell-type hits a beam
  makes, never the distance between them, so mapping every tile sharing
  an old row/column to the same new row/column (with relative order
  preserved per axis) cannot change which cells a beam hits or in what
  order. Solver-confirmed identical `optimal_moves`/
  `shortest_solution_count`/`states_explored` for all 25 levels, checked
  directly (not assumed) before any file was written.
- Levels 1-19 grew 5x5→5x6/5x7; Level 20 grew 6x6→6x7; Levels 21-25 (the
  only ones below `UIConstants.MIN_TOUCH_TARGET`) had columns compacted
  alongside row growth, ending 29-33% LARGER per cell than before.
- Validated: 15/15 dev + 100/100 campaign + 5/5 rect fixtures + 10/10
  tutorial-board solvability PASS; 94.2-99.8% height / 86.0-99.8% width
  utilization at 1080x1920 (vs. the old boards' 56.8-99.8% height), zero
  HUD overlap; RENDERED screenshots of Levels 1/10/20/21/25 confirmed
  larger readable tiles, content spread across the board, no distortion.
- Build: `versionCode=31`, `versionName="2.8.0-PORTRAIT-L1-25-QA"`, QA
  unlock still `true`, byte-identical size to the prior build (no new
  assets). **Next required step: the user's manual Android visual QA** —
  this build's checklist has two goals: confirm the re-layout genuinely
  improved presentation, AND confirm difficulty/solvability truly held
  (the first pass to change tile *coordinates* on already-designed,
  partially-approved levels).
  **Levels 26-100 are unchanged — re-laying out further batches is
  future work, not started, not authorized by this pass's completion.**
- **Future "Era" product direction documented in `ROADMAP.md`, NOT
  implemented**: Tutorial + one continuous PLAY mode eventually replaces
  the separate Campaign/Endless framing; current content = Era 1 (T01-
  T10 + Levels 1-100); future Eras add T11-T20/Levels 101-200, etc. No
  Era 2 content exists or should be started without a separate explicit
  request.

**"Rectangular Grid Architecture — Phase 1"** (previous). Engine/layout
pass — `GridManager` can now fit an arbitrary `columns x rows` board
against the real playable rectangle between Top HUD and Bottom HUD,
instead of assuming a good layout is always square. **Zero Campaign/dev/
tutorial level content changed** (see `DECISIONS.md` D72,
`ARCHITECTURE.md` "Rectangular grid layout," `CLAUDE.md`'s Responsive
rules, `TEST_PLAN.md`'s section of the same name).
- The one square-grid assumption in the whole project (found by full
  audit) was `GridManager._recalculate_layout()`'s
  `cell_size = floor(min(size.x,size.y)/max(grid_width,grid_height))`.
  Replaced with independent per-axis candidates
  (`cell_size = floor(min(available_width/columns, available_height/rows))`),
  a new single `GRID_SAFETY_MARGIN` constant (8px @ 1080-wide reference)
  insetting the available rect on all 4 sides. A square board's result
  is unchanged by construction — this is why every existing level still
  renders exactly as before.
- New dev-only diagnostics: `GridManager.get_layout_metrics()`/
  `format_layout_diagnostics()` — never shown to players, meant for a
  future Phase 2 pass choosing real rectangular campaign-level shapes.
- 5 temporary rectangular layout fixtures under `levels/editor_fixtures/`
  (`fixture_rect_5x8/6x10/7x11/8x12/9x10.gd`) for validation only — same
  convention as the 6 existing validator fixtures, never Campaign-
  reachable.
- Validated: 15/15 dev + 100/100 campaign + 10/10 tutorial (solvability)
  solver+runtime-replay regression unchanged; 5/5 rectangular fixtures
  PASS; a resolution/layout matrix (5 resolutions x 8 boards) confirmed
  zero HUD overlap and rectangular fixtures reaching 85-100% width /
  89-99.8% height utilization vs. existing square levels' width-bound-
  only behavior; RENDERED screenshots confirmed correct alignment.
- Build: `versionCode=30`, `versionName="2.7.0-RECT-GRID-QA"`, QA unlock
  still `true`, byte-identical size to the prior build (no new assets).
  **Next required step: the user's manual Android visual QA** (this
  build is a pure regression check — no player-visible rectangular board
  exists yet, since Campaign Levels 1-100 weren't re-laid out).
  **Phase 2 (choosing real rectangular shapes for Campaign Levels
  1-100) is NOT started and NOT authorized by this pass's completion —
  wait to be explicitly asked.**
- Pre-existing, unrelated, not fixed by this pass: 4 tutorials (T02/T04/
  T07/T10) have a declared `optimal_moves` that doesn't match the
  solver's count (all remain genuinely solvable) — cosmetic Tutorial
  metadata, out of scope for an engine pass.

**"UI Background Refresh V2 + Laser → Mirror Impact VFX"** (previous).
Visual-only pass on the finished 100-level build — no gameplay/level/
solver/save changes (see `DECISIONS.md` D71 and `TEST_PLAN.md`'s section
of the same name).
- Main Menu / Campaign Select / Tutorial Select each use their own V2
  background (`res://assets/ui/backgrounds/bs_bg_main_menu_v2.png`,
  `bs_bg_campaign_select_v2.png`, `bs_bg_tutorial_select_v2.png`) via the
  scenes' existing cover-crop `TextureRect`, plus a scene-local
  `ReadabilityScrim` gradient (≤ 0.30 alpha). Old backgrounds are
  unreferenced and export-excluded.
- `LaserMirrorImpactFX` = a ~0.32 s procedural flash/ring/spark burst per
  reflection off a `MirrorTile`, spawned by `GridManager.
  _spawn_mirror_impacts()` from `_last_result` on player taps only.
  **Don't move the trigger into `_redraw_beams()` (runs on resize) and
  don't add fields to `LaserSystem` for it.** Splitters are deliberately
  excluded; the optional mirror glow was skipped (see D71).
- Build: `versionCode=29`, `versionName="2.6.0-UI-VFX-QA"`, QA unlock
  still `true`. **Next required step: the user's manual Android visual
  QA** (checklist in `TEST_PLAN.md`). Levels 51-100 manual QA is still
  pending too. Flagged-not-fixed: Main Menu `Logo` draws at zero width
  (pre-existing), small Back button on select screens (pre-existing).
- Testing tip from this pass: to drive real clicks with
  `Input.parse_input_event`, pass window pixels
  (`get_window().get_final_transform() * logical_pos`), not logical
  coordinates; back up `user://savegame.json` before any rendered run that
  can solve a level/tutorial.

**"Campaign Levels 91-100 — final campaign block, 100-level campaign
complete"** (previous). With Levels 81-90 (`versionCode=27`) shipped and
manual QA still pending, the user asked to complete the originally-
planned 100-level campaign structure. See `DECISIONS.md` D70 and
`CAMPAIGN_DESIGN.md` section 11m. Summary:
- **No mechanic-teaching reset** — Level 91 continues directly from
  Level 90's difficulty.
- Created Levels 91-100: Inferred Convergence, Delayed Verdict,
  Pre-Split Signal, Traced Colors, Final Threshold, Chain of Custody,
  Triple Verdict, Triple Inference, Penultimate Verdict, Culmination.
- **Two new techniques**: a genuinely non-rotatable fixed mirror used
  specifically for backward-reasoning teaching (Levels 91/95/98/100),
  and a shared-state chain where a target's own activation is just a
  waypoint toward a later emitter's conditions (Level 96).
- Optimal-move curve 13,13,11,11,15,12,14,14,14,13 — Level 95 is the
  "final exam" checkpoint, Level 100 is the definitive final puzzle:
  Level 90's own three-stage relay + double-portal + symmetric
  convergence plus one fixed mirror for backward reasoning, deliberately
  held to Level 90's exact move count and grid size, not padded.
- **One full draft rejection, and a significant one**: Level 100's
  first draft gated emitter 4 behind emitter 1's own post-target
  continuation, creating a genuine circular deadlock — exactly the
  failure mode D69 documented one milestone earlier, and the very next
  level almost repeated it. Caught immediately by the solver reporting
  UNSOLVABLE, removed rather than reworked.
- **Campaign completion behavior verified, not built from scratch**:
  `game.gd`'s existing `has_next` check and `LevelCompletePopup`'s
  existing Next-Level-button visibility logic both already correctly
  handle Level 100 as the last level — zero code changes needed.
- **Zero architecture changes** — `LevelManager.CAMPAIGN_LEVEL_PATHS`
  gained 10 entries; count picked up 100 automatically, verified via a
  real-autoload driver (count=100, Level 100 loads, Level 101 returns
  null gracefully, QA-unlock correct, real save data untouched).
- Validated: 10/10 new-level solver+runtime PASS, 100/100 full campaign
  solver+runtime PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
  Levels 1-90 and Tutorial untouched.
- New build: `versionCode=28`, `versionName="2.5.0-CAMPAIGN-100-QA"`.
  QA unlock-all kept enabled (MUST be `false` before any final release
  build, now more urgent than ever). **NOT MANUALLY APPROVED — ANDROID
  MANUAL DIFFICULTY QA PENDING** for Levels 91-100. **Levels 1-50 ARE
  user-tested and reported good; full manual QA of Levels 51-90 also
  remains separately pending.** **The 100-level campaign structure is
  now COMPLETE — do not create Campaign Levels 101+ or a Stage 11, do
  not redesign Tutorial, do not disable QA unlock** — this pass's own
  completion is not authorization to continue; wait for manual
  difficulty feedback before considering anything beyond Level 100.

**"Campaign Levels 81-90 — EXTREME/EXTREME+ block, fourth expansion
past 80"** (previous). With Levels 71-80 (`versionCode=26`) shipped and
manual QA still pending, the user asked to continue by extending the
campaign to 90 levels. See `DECISIONS.md` D69 and `CAMPAIGN_DESIGN.md`
section 11l. Summary:
- **No mechanic-teaching reset** — Level 81 continues directly from
  Level 80's difficulty.
- Created Levels 81-90: Third Signal, Crossed Corridors, Silent Detour,
  Distant Relay, Convergence Threshold, Reciprocal Corridor, Triple
  Relay, Distant Triple Relay, Fourfold Relay, Full Circuit.
- **New mechanic: the three-stage relay** (Level 87 onward) — extends
  the two-stage relay (Levels 70/76/84) to THREE emitters in a genuine
  forward chain, resolved over 4 simulation passes with zero new engine
  code.
- Optimal-move curve 12,11,11,12,14,12,10,12,13,13 — Level 85 is a major
  checkpoint, Level 90 is a major milestone: five emitters, the
  three-stage relay, two portal jumps, and two independent converging
  gates symmetric on both ends of the relay — exceeding Level 80's
  convergence depth through breadth of independent sources, not size.
- **One full draft rejection**: Level 87's first draft shared a column
  between two emitters; leaving both mirrors unflipped let one beam bend
  into the other's chain, producing a 5-move shortcut bypassing the
  relay — rebuilt with every emitter's entire path confirmed disjoint,
  checking unflipped defaults too.
- **One mid-design correction caught by the solver itself**: Level 89's
  target was one row off from the beam's actual path — the solver
  reported UNSOLVABLE, diagnosed with a debug script, fixed by
  relocating the target.
- **Circular-dependency safety check**: every new converging gate
  verified to depend only on a switch reachable before anything it
  blocks becomes necessary — a rejected alternative would have created
  a genuine deadlock, caught during design.
- **Zero architecture changes** — `LevelManager.CAMPAIGN_LEVEL_PATHS`
  gained 10 entries; count picked up 90 automatically, verified via a
  real-autoload driver (count=90, Level 90 loads, Level 91 returns null
  gracefully, QA-unlock correct, real save data untouched).
- Validated: 10/10 new-level solver+runtime PASS, 90/90 full campaign
  solver+runtime PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
  Levels 1-80 and Tutorial untouched.
- New build: `versionCode=27`, `versionName="2.4.0-CAMPAIGN-90-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 81-90. **Levels 1-50 ARE user-
  tested and reported good; full manual QA of Levels 51-80 also
  remains separately pending.** **Do not start Stage 10 / Campaign
  Levels 91+, do not redesign Tutorial, do not disable QA unlock** —
  this pass's own completion is not authorization to continue.

**"Campaign Levels 71-80 — MASTER/MASTER+/EXTREME block, third
expansion past 70"** (previous). With Levels 61-70 (`versionCode=25`)
shipped and manual QA still pending, and Levels 1-50 now user-tested on
a real device and reported good, the user asked to continue by
extending the campaign to 80 levels. See `DECISIONS.md` D68 and
`CAMPAIGN_DESIGN.md` section 11k. Summary:
- **No mechanic-teaching reset** — Level 71 continues directly from
  Level 70's difficulty.
- Created Levels 71-80: Deliberate Detour, Locked Corridor, Locked
  Splitter, Twin Portals, Convergence Reaction, Reverse Relay, Distant
  Splitter, Distant Corridor, Silent Third, Full Convergence.
- **New technique**: extend an already-validated level's exact
  geometry (portal jump into a confirmed-unused board region, or
  filters at confirmed single-beam transit cells) rather than
  hand-deriving fresh geometry — used for Levels 76-80.
- Optimal-move curve 11,9,11,8,13,11,12,12,13,14 — Level 75 is a major
  mid-block checkpoint, Level 80 is a major milestone: one target gated
  by FOUR independently-opened dependencies (mutual splitter gate pair,
  portal jump, third emitter's own gate, reflected branch's post-target
  delayed consequence), with the third emitter itself re-coupled into
  the straight branch's own switch — exceeding Level 70's relay in
  depth, not size.
- **One full draft rejection**: Level 72's from-scratch geometry mixed
  up mirror positions and came back UNSOLVABLE — rebuilt on Level 68's
  proven geometry plus 3 filters at confirmed transit cells, matching
  Level 68's own numbers exactly.
- **One mid-design correction caught by the solver itself**: Level 79's
  entry mirror was authored assuming the wrong orientation was a "trap,"
  but the reflect table showed it was already correct — corrected and
  re-validated to 13 moves.
- **Solver ceiling watched, not exceeded**: Level 80 has 16 rotatable
  pieces (2^16 = 65536 states, exactly `DEFAULT_MAX_STATES`) — explored
  65519 states, returned a definitive SOLVABLE. Don't add more
  rotatable pieces to it.
- **Zero architecture changes** — `LevelManager.CAMPAIGN_LEVEL_PATHS`
  gained 10 entries; count picked up 80 automatically, verified via a
  real-autoload driver (count=80, Level 80 loads, Level 81 returns null
  gracefully, QA-unlock correct, real save data untouched).
- Validated: 10/10 new-level solver+runtime PASS, 80/80 full campaign
  solver+runtime PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
  Levels 1-70 and Tutorial untouched.
- New build: `versionCode=26`, `versionName="2.3.0-CAMPAIGN-80-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 71-80. **Levels 1-50 ARE user-
  tested and reported good; full manual QA of Levels 51-70 also
  remains separately pending.** **Do not start Stage 9 / Campaign
  Levels 81+, do not redesign Tutorial, do not disable QA unlock** —
  this pass's own completion is not authorization to continue.

**"Campaign Levels 61-70 — advanced expert block, second expansion
past 60"** (previous). With Levels 51-60 (`versionCode=24`) shipped and
manual QA still pending (only informal partial feedback so far), the
user asked to continue by extending the campaign to 70 levels. See
`DECISIONS.md` D67 and `CAMPAIGN_DESIGN.md` section 11j. Summary:
- **No mechanic-teaching reset** — Level 61 continues directly from
  Level 60's difficulty.
- Created Levels 61-70: Peripheral, Longcut, Invalidation, Twin Anchor,
  Convergence Point, Portal Trap, Chain Reaction, Twin Corridor, Color
  Conflict, Grand Convergence.
- **Two new structural patterns**: a single gate cell crossed by two
  emitters from perpendicular directions, EITHER switch opening it for
  both (68); and a genuine two-stage switch/gate relay between two
  emitters where each unlocks the other in sequence (70) — hand-
  verified against `simulate_until_stable()`'s real 3-pass resolution.
- Optimal-move curve 10,10,10,10,12,7,11,9,12,11 — Level 70 is a second
  major milestone, more sophisticated than Level 60 through its relay
  dependency, not through size (4095 states vs. Level 60's 32767,
  deliberately not chasing state count).
- **One full draft rejection**: Level 63's always-open decoy gate sat
  where the reflected branch's own correct path also passed through
  it, and a "decoy" mirror connected that chain straight into the
  straight branch's target — solver found a 5-move shortcut. Rebuilt
  with fully disjoint zones.
- **One notes correction**: Level 68's hand-trace mis-applied the
  reflect table to one mirror; the solver correctly showed no flip was
  needed there (already correctly authored) — `optimal_moves` fixed
  from 10 to the solver-confirmed 9.
- **Zero architecture changes** — `LevelManager.CAMPAIGN_LEVEL_PATHS`
  gained 10 entries; count picked up 70 automatically, verified via a
  real-autoload driver (count=70, Level 70 loads, Level 71 returns null
  gracefully, QA-unlock correct, real save data untouched).
- Validated: 10/10 new-level solver+runtime PASS, 70/70 full campaign
  solver+runtime PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
  Levels 1-60 and Tutorial untouched.
- New build: `versionCode=25`, `versionName="2.2.0-CAMPAIGN-70-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 61-70. **Full manual QA of Levels
  21-60 also remains separately pending.** **Do not start Stage 8 /
  Campaign Levels 71+, do not redesign Tutorial, do not disable QA
  unlock** — this pass's own completion is not authorization to
  continue.

**"Campaign Levels 51-60 — first post-reboot expansion past 50"**
(previous). With Difficulty Rework Pass 2 (`versionCode=23`) shipped and
informally sampled on a real device ("its good" — NOT a full review),
the user asked to continue development by extending the campaign to 60
levels. See `DECISIONS.md` D66 and `CAMPAIGN_DESIGN.md` section 11i.
Summary:
- **No mechanic-teaching reset** — Level 51 continues directly from the
  Levels 46-50 difficulty region.
- Created Levels 51-60: Interlock, Currents, Shared Line, Dual Transit,
  Sequence Lock, Shared Transit, Long Division, Delayed Fault, Near
  Convergence, Threshold of Reason — new patterns include a genuinely
  MUTUAL switch/gate dependency (51), a filter shared by two emitters
  (53), and a global switch/gate gating an independent filter-order
  sub-puzzle (55, 60).
- Optimal-move curve 10,8,7,11,11,8,9,11,11,14 — Level 60 explores
  32767 states, the highest in the campaign (old Level 50: 255;
  Pass 2's own peak, Levels 40/45: 4095 each).
- **Two full draft rejections**: Level 56's first draft shared ONE
  portal pair between two emitters — pathologically slow to solver-
  validate (minutes instead of milliseconds on 7 pieces), killed and
  rebuilt with separate portals + a switch/gate. Level 58's first draft
  left a wrong branch with zero immediate consequence, and two adjacent
  cells from different branches accidentally connected into a 4-move
  shortcut — rebuilt with disjoint zones and a real delayed hazard.
  Both are standing lessons in `DECISIONS.md` D66.
- Every level built from Pass 2's two solver-verified-safe templates
  (single linear chain, or splitter/multi-emitter on disjoint rows/
  columns except one shared tile) — caught zero new collinearity bugs
  beyond the two rejections above.
- **Zero architecture changes** — `LevelManager.CAMPAIGN_LEVEL_PATHS`
  gained 10 entries; `get_campaign_level_count()` picked up 60
  automatically, verified via a real-autoload driver (count=60, Level
  60 loads, Level 61 returns null gracefully, QA-unlock correct, real
  save data untouched).
- Validated: 10/10 new-level solver+runtime PASS, 60/60 full campaign
  solver+runtime PASS, 15/15 dev PASS, 10/10 tutorial-board PASS.
  Levels 1-50 and Tutorial untouched.
- New build: `versionCode=24`, `versionName="2.1.0-CAMPAIGN-60-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for Levels 51-60. **Full manual QA of Levels
  21-50 also remains separately pending** — do not conflate the
  informal "its good" sample with a completed review. **Do not start
  Stage 7 / Campaign Levels 61+, do not redesign Tutorial, do not
  disable QA unlock** — this pass's own completion is not authorization
  to continue.

**"Campaign Difficulty Rework Pass 2 — Levels 21-45 replaced again"**
(previous). The reboot pass below (`versionCode=22`) was solver-valid
but still too easy in Levels 21-45 (optimal-move curves 3,2,2,2,2 /
2,2,2,2,5 / 2,4,2,2,3 — several solvable with a handful of random
taps). See `DECISIONS.md` D65 and `CAMPAIGN_DESIGN.md` sections
11f/11g/11h. Summary:
- Replaced all 25 of Levels 21-45 a second time, built for real
  dependency depth (cross-branch shared mirrors, filter order, portal
  misdirection, switch/gate dependency, multi-emitter dependency,
  backward reasoning, hazard/blocker-guarded false forks) rather than
  padded move counts.
- New optimal-move curve: 5,6,5,6,6 / 7,8,6,7,7 / 6,7,6,5,7 / 9,9,6,9,11
  / 8,9,10,7,11 — `states_explored` now peaks at 4095 (Levels 40, 45),
  exceeding old Level 50's 255-state benchmark.
- **Every level built from one of two solver-verified-safe templates**
  (a single non-branching linear chain, or a splitter with two branches
  on fully disjoint rows/columns except at one shared fixed mirror)
  after six early drafts hit the same class of bug: a target/hazard/
  emitter accidentally collinear with an unrelated beam's unmodified
  straight path, producing an unintended shortcut or `UNSOLVABLE`
  result (Levels 25, 27, 31 x2, 34, 36 x2, 40) — each caught by the
  solver, fixed, and recorded in `DECISIONS.md` D65 along with the
  general lesson for future level design in this project: **check every
  target/hazard against every beam's fully unmodified straight-line
  path, not just the intended chain.**
- Levels 1-20 and 46-50 untouched. Tutorial untouched.
- Validated: 50/50 campaign solver PASS, 50/50 runtime-replay PASS,
  15/15 dev PASS, 10/10 tutorial-board PASS.
- New build: `versionCode=23`, `versionName="2.0.1-CAMPAIGN-DIFFICULTY-QA"`.
  QA unlock-all kept enabled. **NOT MANUALLY APPROVED — ANDROID MANUAL
  DIFFICULTY QA PENDING** for all 25 redesigned levels. **Do not start
  Stage 6 / Campaign Levels 51+, do not redesign Tutorial, do not
  disable QA unlock** — this pass's own completion is not authorization
  to continue.

**"Main Campaign Reboot — Levels 1-50 rebuilt mechanic-agnostic"**
(previous). With Tutorial (T01-T10) now teaching every mechanic in
isolation, Campaign Levels 1-50 were rebuilt so it's mechanic-agnostic
from Level 1 onward, testing combinations/reasoning instead of teaching
one mechanic per stage — see `DECISIONS.md` D64 and
`CAMPAIGN_DESIGN.md` sections 1a/2/11f/11g/11h. Summary:
- Audited all 50 existing levels first. **Levels 1-10/11-20 KEPT**
  (real prior manual approval). **Levels 21-30/31-40/41-45 REPLACED**
  (never approved; 31-40 had explicit "feels easy" feedback; the
  others were front-loaded mechanic introductions). **Levels 46-50
  KEPT**, including Level 50 "Paradox" — the user's own named quality
  benchmark (255 states), left completely unchanged and still the clear
  unbeaten peak.
- Internal `stage_01/`-`stage_05/` folders and `LevelManager.
  CAMPAIGN_LEVEL_PATHS` ordering untouched — only specific files'
  contents rewritten. Player-facing, it's just "Level 1"-"Level 50."
- 25 levels (21-45) hand-designed and solver-validated in 5 batches of
  5, freely combining any mechanic (portals/filters/switches-gates/
  hazards/multiple emitters no longer stage-reserved). 24/25 matched
  hand-traced intent on the first solver pass; Level 30 needed a
  color-tracking fix after the solver correctly caught an `UNSOLVABLE`
  authoring mistake (a target's required color didn't match what an
  unavoidable filter actually produced — read `DECISIONS.md` D64
  before assuming a color-tagged target is correct without re-tracing
  every filter on its beam's actual path).
- Validated: 50/50 campaign solver PASS, 50/50 runtime-replay PASS,
  15/15 dev PASS, 10/10 tutorial-board PASS (Tutorial untouched, per
  the brief's explicit freeze).
- New build: `versionCode=22`, `versionName="2.0.0-CAMPAIGN-REBOOT-QA"`,
  51,130,936 bytes. QA unlock-all kept enabled. **NOT MANUALLY
  APPROVED — ANDROID MANUAL DIFFICULTY QA PENDING** for all 50 levels.
  **Do not start Stage 6 / Campaign Levels 51+, do not redesign Tutorial,
  do not disable QA unlock** — this pass's own completion is not
  authorization to continue.

**"Guided Tutorial Click Input Fix — highlighted tile visible but not
tappable"** (previous). A manual VIDEO QA of `versionCode=20` (the D62
visual fix build) found the highlighted mirror at T01's
`REQUIRE_TILE_TAP` step was clearly visible but repeated taps did
nothing — the tutorial never advanced. See `DECISIONS.md` D63 and
`TUTORIAL_SYSTEM.md` section 13 for the full writeup. Summary:
- **Root cause found by dumping RUNTIME `mouse_filter`/
  `get_global_rect()` values, not `.tscn` source**, for every Control
  between the Viewport and the highlighted tile: `game.tscn`'s
  `TutorialPanel` instance node redundantly re-declared full-screen
  anchors on top of `tutorial_panel.tscn`'s own correct bottom-anchored
  layout, making its `Panel` child (default `mouse_filter = STOP`)
  silently cover the entire screen and intercept every tap — invisible
  because the panel's 88%-opaque background blended into the
  already-dark gameplay art. This also retroactively explains part of
  the D62 "board looks too dark" complaint.
- Fixed by removing the conflicting override from `game.tscn`'s
  `TutorialPanel` instance node; hardened `Panel` to
  `mouse_filter = IGNORE`; added a highlight/allowed-cell mismatch
  fail-safe in `TutorialManager`; expanded the QA debug overlay with
  live `HIGHLIGHT:`/`ALLOWED:`/`LAST TAP:` tracking via a new
  `GridManager.tile_tap_attempted` signal.
- Validated: a runtime ancestor-chain dump confirmed the intercepting
  node before the fix and its absence after; genuine OS-level mouse
  input observed during the investigation (not synthetically
  generated) reached the correct tile and was accepted — real, if
  incidental, confirmation; a headless driver confirmed every
  `REQUIRE_TILE_TAP` step across all 10 tutorials correctly rejects a
  wrong-cell tap and accepts the correct one via the real signal chain
  (10/10 PASS); full existing regression re-confirmed (15/15 dev +
  50/50 campaign) — zero Campaign regression.
- New build: `versionCode=21`, `versionName="1.6.3-TUTORIAL-INPUT-FIX"`,
  51,135,032 bytes. QA unlock-all kept enabled. Campaign untouched.
  **STILL NOT MANUALLY APPROVED — ANDROID MANUAL QA PENDING** for all
  three tutorial fixes (runtime, visual, input) together — this is the
  Tutorial's fourth manual QA attempt.

**"Guided Tutorial Visual Focus Fix — dim overlay + highlight visibility
+ completion cleanup"** (previous). A manual VIDEO QA of `versionCode=19`
(the D61 runtime fix build) found two visual bugs — see `DECISIONS.md`
D62 and `TUTORIAL_SYSTEM.md` section 12 for the full writeup. Summary:
- The board stayed heavily dimmed during `REQUIRE_TILE_TAP` with the
  required mirror hard to see under it, and the dim wasn't reliably
  clearing.
- **Source check first, per this project's standing rule**: no dim
  overlay had ever existed anywhere in the Tutorial system before this
  pass — the commissioning brief was framed as a bug report against an
  assumed pre-existing system. The real, verifiable problem was
  `TutorialHighlight`'s thin outline having too little contrast against
  full gameplay art. The fix proceeds per the brief's own detailed
  specification anyway, since that's what genuinely resolves the
  complaint.
- New `TutorialDimOverlay`: a board dim (`DIM_ALPHA = 0.52`) with a
  fully transparent cutout around the highlighted tile — the tile
  itself stays at full brightness. Coupled 1:1 to `GridManager.
  set_highlight()`/`clear_highlight()` — no new state machine, no
  step-type branching (verified no existing tutorial ever highlights
  during `WAIT_FOR_TARGET_ACTIVATION`/`WAIT_FOR_PUZZLE_SOLVED`).
- `TutorialHighlight` strengthened (brighter, thicker border) and
  enlarged by a shared `FOCUS_PADDING` constant so the ring and the
  dim's cutout can never drift apart.
- **Found and fixed Pause double-dimming** (`suspend_tutorial_focus()`/
  `resume_tutorial_focus()`) and an **adjacent z-order bug**
  (`PauseMenu` used to render under `TutorialPanel` in `game.tscn`;
  reordered so Pause is always topmost).
- Added `game.gd._clear_tutorial_focus_visuals()` as the one
  authoritative highlight/dim cleanup path, called at every tutorial
  exit point.
- Validated: a headless driver walked every step of all 10 tutorials
  (every tile type any tutorial highlights) confirming highlight/dim
  stay exactly in sync — 10/10 PASS; real rendered screenshots with
  pixel-luminance sampling objectively confirmed the highlighted tile
  reads ~2.5-3x brighter than its dimmed neighbors (after correctly
  reading this environment's actual window geometry — see D62's
  technique note, worth reading before capturing screenshots again);
  full existing regression re-confirmed (15/15 dev + 50/50 campaign) —
  zero Campaign regression.
- New build: `versionCode=20`, `versionName="1.6.2-TUTORIAL-VISUAL-FIX"`,
  51,130,936 bytes. QA unlock-all kept enabled. Campaign untouched.
  **STILL NOT MANUALLY APPROVED — ANDROID MANUAL QA PENDING** for the
  D61 runtime fix and this visual fix together.

**"Guided Tutorial Runtime Fix — T01 initial-load/instruction/forced-
interaction bug"** (previous). The user performed the Android manual QA
the previous pass left pending on `versionCode=18` — **it FAILED**: T01
opened with an empty board (no tiles), Reset made tiles appear but the
tutorial stayed softlocked (no instruction/message, no highlight, no
mirror interaction) — see `DECISIONS.md` D61 and `TUTORIAL_SYSTEM.md`
section 11 for the full writeup. Summary:
- **Root cause found via a real, non-headless render** (`CLAUDE.md`
  12d) — NOT the initially-suspected `Control`-layout/grid-ready timing
  race: `scenes/ui/tutorial_panel.tscn` and
  `scenes/ui/tutorial_complete_popup.tscn` each declared their script as
  an `ext_resource` but never attached it (`script =
  ExtResource(...)`) to their root node — so `%TutorialPanel` resolved
  to a plain `Control` missing `continue_pressed`, and `game.gd._ready()`
  crashed connecting to it, aborting the rest of `_ready()` (including
  the final call to `_load_current_level()`) before any tile ever
  loaded. Reset "fixed" tile visibility only because the Reset button's
  `pressed` connection is wired earlier in `_ready()`, before the crash.
- Fixed both `.tscn` files. **No `level_visuals_ready` signal was
  needed** — `grid.size`/`cell_size` were already correct on the very
  first frame once the real bug was fixed.
- Added a fail-safe (`GridManager.has_orientable_tile()` +
  `TutorialManager`'s `REQUIRE_TILE_TAP` handling): a step can no longer
  silently lock input to a nonexistent tile — it now logs a
  `push_error` and leaves input unrestricted instead.
- Added a temporary, tutorial-mode-only QA debug overlay
  (`QADebugLabel`) showing step number/input mode/target cell.
- Validated: real rendered reproduction of the crash and its fix
  (screenshot of T01's first frame, tiles/beam/instruction/continue-
  button all present, no Reset needed); all 10 tutorials (T01-T10)
  re-validated for startup through the real `game.tscn` path; T01
  Reset x3/Pause-Resume/Pause-Restart lifecycle all correct with no
  duplicated UI/highlights; full existing regression re-confirmed
  (15/15 dev + 50/50 campaign, 65/65 total, plus 10/10 tutorial-board
  solvability) — zero Campaign regression.
- New build: `versionCode=19`, `versionName="1.6.1-TUTORIAL-FIX"`,
  51,130,755 bytes. QA unlock-all kept enabled. Campaign untouched (no
  Stage 6, no campaign level changes) per explicit instruction.
  **STILL NOT MANUALLY APPROVED — ANDROID MANUAL RE-QA PENDING**, this
  time starting from a completely fresh open with no Reset. Real
  on-device tap-driven input dispatch was not independently
  re-verified by this pass's own automated testing (a synthetic-input
  test-harness limitation, disclosed in `TEST_PLAN.md` — not a known
  bug).

**"Guided Tutorial Mode — T01-T10 + Full Menu Integration"** (previous).
Built from an explicit, detailed user request for a new, permanent
product structure: a 10-level guided TUTORIAL section (T01-T10),
completely separate from the 100-level CAMPAIGN (currently 1-50
implemented) — see `DECISIONS.md` D60 and `TUTORIAL_SYSTEM.md` for the
full writeup. Summary:
- **Mechanic audit first**: every mechanic the brief's T01-T10 plan
  named was confirmed already fully implemented before designing
  anything - portals/switches-gates/hazards/multiple-emitters had
  simply never been *used* in Campaign yet, proven by dev/regression
  levels 10-13 ("Through the Portal," "Switch and Gate," "Danger Zone,"
  "Two Sources"). No tutorial was left pending, no mechanic was faked.
- New architecture: `TutorialStepData`/`TutorialLevelData` (a
  tutorial's `tiles` are simulated by the identical `LaserSystem`/
  `GridManager` Campaign uses - only `steps` is new, 4 step types:
  `MESSAGE`, `REQUIRE_TILE_TAP`, `WAIT_FOR_TARGET_ACTIVATION`,
  `WAIT_FOR_PUZZLE_SOLVED`), `TutorialManager` (a `class_name extends
  RefCounted` owned locally by `game.gd` per play session - deliberately
  **not** a 4th autoload, `CLAUDE.md` rule 6), forced interaction gated
  at the single existing tap handler
  (`GridManager._on_orientable_tile_clicked()`, two new fields that
  default to their inert, Campaign-unaffecting values), a pulsing cyan
  outline-only highlight (`TutorialHighlight`), a new instruction panel
  and completion popup (distinct from `LevelCompletePopup` - no stars/
  best-moves), and new `SaveManager` fields (`tutorial_highest_
  unlocked_level`/`tutorial_completed_levels`, `SAVE_VERSION` 2 -> 3,
  additive only).
- Main Menu reordered to CONTINUE / CAMPAIGN / TUTORIAL / SETTINGS /
  QUIT; new, separate Tutorial Select scene
  (`tutorial_select.tscn`/`.gd`) - kept apart from `level_select.gd` on
  purpose, zero Campaign regression risk.
- Created all 10 tutorials (`levels/tutorial/t01.gd` … `t10.gd`): First
  Light (mirrors), Two Turns (reflection, progressively less forced),
  Locked In (blockers + fixed mirrors), Both Lights (multiple targets),
  Split Path (splitters), True Color (colored beams/targets), Recolor
  (filters), Through the Portal (portals), Switch and Gate (switches/
  gates/hazards together), Graduation (multiple emitters, near-free-play
  finale).
- **Found and fixed a real signal-timing bug during this feature's own
  testing**: `GridManager.move_made` fires *before* simulation runs
  (pre-existing, unchanged Campaign behavior), so a target-activation
  check wired to it would read stale state - fixed with a new, purely
  additive `GridManager.simulation_updated` signal (fires *after*), zero
  effect on `move_made`'s existing Campaign timing.
- Validated: full T01 step-machine test (forced-tap accept/reject,
  cascading advancement, save isolation in both directions,
  `get_tutorial_level(11) == null`); all 10 tutorial boards confirmed
  solvable through a real `GridManager`; a real scene-instantiation
  check (Main Menu button order, Tutorial Select's 10 cards, Campaign
  Level Select's 50 cards and QA-unlock-all completely unaffected);
  exported-package validation (all 10 tutorial levels + every new
  script/scene + all 50 campaign levels present and loadable); full
  existing regression re-confirmed after every change - 15/15 dev-level
  + 50/50 campaign (65/65 total) solver-vs-runtime-replay all PASS
  throughout, zero Campaign regression at any point.
- New build: `versionCode=18`, `versionName="1.6.0-TUTORIAL-QA"`,
  51,126,659 bytes (+48,992 bytes over the Stage 5 build - larger than a
  typical stage's pure-level-data delta since this pass added real new
  architecture, not just level data). QA unlock-all kept enabled per
  explicit instruction. **NOT MANUALLY APPROVED — ANDROID MANUAL QA
  PENDING** for the Tutorial (new) and Stages 3/4/5 (still outstanding),
  this is the next required step. **Do not start Stage 6, add Tutorial
  levels beyond T10, or begin any other follow-on work** — this pass's
  own completion is not authorization to continue.

**"Production Campaign Phase 5 — Stage 5: Filters, Campaign Levels
41-50"** (previous). Built from an explicit, detailed user request naming
Stage 5 by number and scope, carrying explicit feedback that Stage 4
"feels easy" and an instruction that Stage 5 make a clearly stronger
difficulty jump — see `DECISIONS.md` D59 for the full writeup. Summary:
- **Stage 4 feedback recorded without editing Stage 4**: status stays
  `IMPLEMENTED / VALIDATED`, no bug was found - the feedback shaped
  Stage 5's escalation curve instead.
- **Audited the `FILTER` tile directly from source before designing
  anything**: no orientation field, never rotatable (structurally
  excluded from the solver's bitmask), unconditionally overwrites a
  beam's color, and chains as "last filter touched wins," never
  blending - verified with a temporary fixture (15 assertions, all
  passed first run, deleted after use). Solver/runtime parity holds by
  construction, same reasoning as Stage 4's colors (D57).
- Created Stage 5 — "Filters" (campaign levels 41-50) under
  `levels/campaign/stage_05/`: Filter, Shift, Cipher, Channel,
  Conversion, Frequency, Transmute, Waveform, Vortex, Paradox.
- Level 50 chains two filters on one branch (only the last survives)
  while the other avoids both, using an early global gate, a
  shared-mirror cross-branch dependency, a fixed backward-reasoning
  mirror, two distinct false-route types, and one solver-confirmed
  inert decoy - 255 states explored, clearly exceeding every prior
  stage's finale (Stage 3's 127 included).
- **Zero architecture changes needed** - everything D54/D55/D56/D57/D58
  built for Stages 1-4 plus the QA-unlock flag scaled to Stage 5 by
  simply appending 10 more paths to `LevelManager.CAMPAIGN_LEVEL_PATHS`.
- **Zero level-authoring mistakes this pass** - every hand-trace matched
  the solver's confirmed `optimal_moves` on the first attempt.
- Optimal-move curve 3,4,4,5,5,6,5,6,6,7 (Stage 4 was
  2,3,4,4,4,5,5,6,6,6) - no 1-2-move levels this time; `states_explored`
  8-255 (Stage 4 was 4-64).
- Verified four independent ways: 50/50 total campaign (10/10 per
  stage) + 15/15 dev-level solver+runtime-replay regression PASS (65/65
  grand total); a real-autoload runtime driver confirmed the
  Stage4→Stage5 boundary AND full progression (Level 40 unlocks Level
  41, sequential unlock through 50, no Level 51 ever offered, Stage 1-4
  progress and dev-level save fields untouched, QA unlock covering all
  50 levels automatically); the exported package re-verified to contain
  all 50 campaign levels and `filter.gd`/`filter.tscn` correctly.
- New build: `versionCode=17`, `versionName="1.5.0-STAGE5-QA"`, 51.08 MB
  (+22.3 KB — pure level data, identical delta to every prior stage's
  growth). QA unlock-all kept enabled per explicit instruction. **NOT
  MANUALLY APPROVED — ANDROID MANUAL QA PENDING** (for Stages 3, 4, AND
  5), this is the next required step. **Do not start Stage 6, introduce
  portals, or begin any other follow-on work** — this pass's own
  completion is not authorization to continue.

**"Production Campaign Phase 4 — Stage 4: Spectrum, Campaign Levels
31-40"** (previous). Built from an explicit, detailed user request naming
Stage 4 by number and scope, while Stage 3 was still pending manual
approval — see `DECISIONS.md` D57 for that context (this was an
exception to the standing "don't start the next stage without being
asked" rule, made because the user's own request was that ask; it is
not a precedent for skipping the rule again). See `CAMPAIGN_DESIGN.md`
section 11d and `DECISIONS.md` D57 for the full writeup. Summary:
- **Audited every color mechanic directly from `GridTypes`/`LaserSystem`
  source before designing anything**: an emitter's color is fixed for
  its entire beam graph; mirrors, fixed mirrors, and BOTH splitter
  branches preserve color unchanged; only a `FILTER` tile recolors a
  beam. Since Stage 4 uses zero filters (per the brief), every level has
  one beam color throughout, so color reasoning had to come from
  **non-required color-decoy targets** the beam can genuinely reach
  along a plausible false route — this was determined as the only
  viable structure before any level was written, not discovered
  partway through.
- Verified color correctness (3 matches, 6 mismatches) and color
  preservation through mirrors/fixed mirrors/both splitter branches in a
  temporary headless fixture, deleted after use. Solver/runtime parity
  holds by construction (`LevelSolver` and `GridManager` call the same
  `LaserSystem.simulate_until_stable()`).
- Created Stage 4 — "Spectrum" (campaign levels 31-40) under
  `levels/campaign/stage_04/`: Prism, Wavelength, Refraction, Photon,
  Chromatic, Diffraction, Phase, Radiance, Pulse, Spectral. The first
  stage to introduce `BeamColor` reasoning as a core mechanic.
- Levels 36, 38, 39, 40 reuse Stage 3's cross-branch-dependency
  technique (a mirror shared by two beam branches from different
  directions) layered with color; Level 38 additionally makes the first
  mirror gate the entire rest of the board; Levels 39/40 each combine a
  "geometrically correct, wrong color" false route with a "color
  compatible, blocked" one — only the true route satisfies both.
- **Zero architecture changes needed** — everything D54/D55/D56 built
  for Stages 1-3 scaled to Stage 4 by simply appending 10 more paths to
  `LevelManager.CAMPAIGN_LEVEL_PATHS`. No new `FILTER` usage; existing
  `target.gd` color rendering (built for Milestone 2's dev levels)
  handled every need unchanged.
- **Zero level-authoring mistakes this pass** — every one of the 10
  hand-traces matched the solver's confirmed `optimal_moves` exactly on
  the first attempt (unlike Stage 3's Level 30, D56).
- Optimal-move curve 2,3,4,4,4,5,5,6,6,6 (Stage 3 was
  2,3,4,4,4,4,4,5,5,6); `states_explored` 4-64 (Stage 3 was 4-127).
- Verified four independent ways: 40/40 total campaign (10/10 per stage)
  + 15/15 dev-level solver+runtime-replay regression PASS (55/55 grand
  total); a real-autoload runtime driver confirmed the Stage3→Stage4
  boundary AND full progression (Level 30 completion unlocks Level 31,
  sequential unlock through 40, no Level 41 ever offered, Stage 1-3
  progress and dev-level save fields untouched); the exported package
  re-verified to contain all 40 campaign levels and every referenced
  color/tile script/scene correctly.
- New build: `versionCode=15`, `versionName="1.4.0-STAGE4"`, 51.06 MB
  (+22.3 KB — pure level data, zero new assets, identical delta to Stage
  3's own growth). **NOT MANUALLY APPROVED — ANDROID MANUAL QA
  PENDING** (for both Stage 3 and Stage 4), this is the next required
  step. **Do not start Stage 5, introduce filters/beam recoloring, or
  begin any other follow-on work** — this pass's own completion is not
  authorization to continue, same standing pattern as every prior phase
  in this project.

**"Production Campaign Phase 3 — Stage 3: Split, Campaign Levels
21-30"** (previous). Built after the user manually played Stage 2 and
gave explicit continuation approval ("these are looking good"). See
`CAMPAIGN_DESIGN.md` section 11c and `DECISIONS.md` D56 for the full
writeup. Summary:
- Created Stage 3 — "Split" (campaign levels 21-30) under
  `levels/campaign/stage_03/`: Divide, Dual Signal, Fork Path, Branch
  Cut, False Fork, Cross Branch, Relay Split, Split Trap, Parallel,
  Fracture. The first stage to introduce splitters and multiple required
  targets as a core mechanic, built directly against the user's explicit
  directive — difficulty from reasoning about beam branches, never from
  adding pieces.
- **Splitter and multi-target behavior verified directly from
  `LaserSystem`/`GridManager` source before any level was designed**,
  per the brief's explicit instruction not to assume it: a splitter
  always sends the beam straight through unconditionally plus one branch
  reflected via the same `GridTypes.reflect()` table mirrors use, is
  rotated by the identical `_on_orientable_tile_clicked()` handler as a
  mirror (counts as a move the same way), and is covered by the same
  shared loop guard — no splitter-specific solver/validator code exists
  or is needed.
- Level 21 is the sole, explicitly-sanctioned exception to "every target
  needs a move" (its straight-through target is free, by design, to
  teach the splitter's unconditional branch). Levels 26, 28, and 30
  build genuine cross-branch dependency: a single mirror tile is hit by
  both the straight-through beam and the reflected branch from different
  directions, so its orientation must satisfy both at once. Level 30
  combines this with backward reasoning via a *fixed* shared mirror.
- **Found and fixed one real level-authoring mistake via the solver, not
  hand-tracing:** Level 30's first draft authored one mirror already in
  its solved orientation, so the solver found a 5-move solution skipping
  it — fixed by correcting the authored orientation to the intended
  wrong starting state, restoring the designed 6-move finale.
- **Zero architecture changes needed** — everything D54/D55 built for
  Stages 1-2 scaled to Stage 3 by simply appending 10 more paths to
  `LevelManager.CAMPAIGN_LEVEL_PATHS`. Confirmed
  `assets/gameplay/splitter/**`'s pre-existing export exclusion is safe —
  the splitter has zero texture dependency (pure procedural `_draw()`).
- Optimal-move curve 2,3,4,4,4,4,4,5,5,6 (Stage 2 was
  3,3,3,3,4,4,4,5,5,5); `states_explored` 4-127 (Stage 2 was 8-120).
- Verified three independent ways: 30/30 total campaign (10/10 per
  stage) + 15/15 dev-level solver+runtime-replay regression PASS (45/45
  grand total); a **read-only** real-autoload runtime driver confirmed
  the Stage2→Stage3 boundary without writing to real save data; the
  exported package re-verified to contain all 30 campaign levels, the
  splitter's script/scene, and every other referenced tile resource
  correctly.
- New build: `versionCode=14`, `versionName="1.3.0-STAGE3"`, 51.03 MB
  (+22.3 KB — pure level data, zero new assets). **NOT MANUALLY
  APPROVED — ANDROID MANUAL QA PENDING**, this is the next required
  step. **Do not start Stage 4, introduce colored beams/targets, or
  begin any other follow-on work** — this pass's own completion is not
  authorization to continue, same standing pattern as every prior phase
  in this project.

**"Production Campaign Phase 2 — Stage 2: Reflection, Campaign Levels
11-20"** (previous). Built on the manually-approved Stage 1 (the user
played it for real and said "the starting levels are good" — the
project's first MANUAL-tier campaign approval). **UPDATE: this pass's
build (`versionCode=13`, `"1.2.0-STAGE2"`) was subsequently played and
MANUALLY APPROVED FOR CAMPAIGN CONTINUATION** by the user ("these are
looking good") — see the current milestone above for what came next.
See `CAMPAIGN_DESIGN.md` section 11b and `DECISIONS.md` D55 for the full
writeup. Original summary, kept for history:
- Created Stage 2 — "Reflection" (campaign levels 11-20) under
  `levels/campaign/stage_02/`: Redirect, Dead End, Fork Point, Reverse
  Trace, Mirage, Cascade, Backtrack, Echo Path, Interference,
  Culmination. Built directly against the user's explicit directive —
  difficulty from reasoning/misdirection/dependency, never grid
  size/mirror count/clutter/padded moves.
- Exactly 3 levels use backward reasoning (14, 17, 20 — the precise set
  requested): a fixed mirror beside the target only redirects correctly
  from one approach direction. Levels 16 and 20 are explicitly built
  around multi-step dependency.
- **Zero architecture changes needed** — everything D54 built for Stage
  1 scaled to Stage 2 by simply appending 10 more paths to
  `LevelManager.CAMPAIGN_LEVEL_PATHS`. Specifically verified (not
  assumed) that Level 20's "no Next Level, since Level 21 doesn't exist"
  case is already handled correctly by `game.gd`'s existing generic
  `has_next` check.
- **Found and fixed two real level-design mistakes before ever running
  the solver** (not after): an early Level 11 draft's target was
  unreachable by its own mirror chain, and an early Level 12 draft's
  blocker sat on a cell no beam configuration could ever reach. Both
  caught by re-deriving each path by hand against
  `GridTypes.reflect()`'s table at write time — see `DECISIONS.md` D55.
- Optimal-move curve 3,3,3,3,4,4,4,5,5,5 (Stage 1 was
  1,2,2,2,2,3,3,4,3,4); `states_explored` 8-120 (Stage 1 was 2-57) — a
  genuine, solver-confirmed escalation, not padded.
- Verified three independent ways: 20/20 total campaign (10/10 Stage 1 +
  10/10 Stage 2) + 15/15 dev-level solver+runtime-replay regression
  PASS; a real-autoload runtime driver played all 20 campaign levels in
  order, confirming the Stage1→Stage2 unlock boundary and Level 20's
  safe end-of-content behavior; the exported package re-verified to
  contain all 20 campaign levels correctly.
- New build: `versionCode=13`, `versionName="1.2.0-STAGE2"`, 51.01 MB
  (+18.2 KB — pure level data, zero new assets). **UPDATE: subsequently
  MANUALLY APPROVED FOR CAMPAIGN CONTINUATION** — see the current
  milestone above (Production Campaign Phase 3) for what came next.

**"Production Campaign Phase 1 — Campaign Architecture + Real Levels
1-10"** (previous). The real 100-level campaign begins (`ROADMAP.md`
Milestone 4). **UPDATE: this pass's build (`versionCode=12`,
`"1.1.0-STAGE1"`) was subsequently played and MANUALLY APPROVED** by
the user — see the current milestone above for what came next. Original
summary, kept for history:
- Created Stage 1 — "First Light" (campaign levels 1-10) under
  `levels/campaign/stage_01/`, newly designed (not copied from the dev
  levels), each solver-validated with zero rejections/redesigns needed.
  Full design table in `CAMPAIGN_DESIGN.md` section 11.
- Kept campaign levels a fully separate population from the 15 dev/
  regression levels, in both level storage (`levels/campaign/` vs
  `levels/`, the latter untouched) and save data (`SaveManager`'s new
  `campaign_*` fields, additive/parallel, never replacing the originals
  — necessary since both populations' level ids start at 1 and would
  collide in the same save keys otherwise).
- Repointed `game.gd`/`level_select.gd`/`GameManager`/`main_menu.gd`'s
  player-facing paths to campaign data. **Found and fixed a real
  integration bug**, not just a guess: `main_menu.gd`'s Continue button
  was still reading the old dev-level save fields, which would never
  update again under normal play.
- **Found and fixed a real design trap during level authoring**:
  `LaserSystem` lets a beam continue past an activated target: Campaign
  Level 9's first-draft decoy sat on that post-target path and wasn't
  actually untouched by the beam. Caught before validation, moved to a
  safe cell. Now a standing design rule in `CAMPAIGN_DESIGN.md` section 8
  — read it before placing any future decoy near a target.
- **Found, not fixed** (out of scope, shared dev tooling): `LevelMetrics`
  mislabels several genuinely-easy Stage 1 levels `HARD`/`EXPERT` due to
  a pre-existing quirk (any emitter counts as "colored beams" regardless
  of actual color). See `CAMPAIGN_DESIGN.md` section 9 before trusting
  this estimate for any future stage.

**"APK Optimization + Asset Cleanup"** (previous). Explicitly-requested,
staged, safety-first APK size reduction on the "Final HUD Alignment +
Level Complete Delay" build. Zero gameplay/level-data/scoring/UI-layout
changes. See `DECISIONS.md` D53 for the full writeup. Two passes:
(A) a from-scratch asset reference-map audit found the shipped
`versionCode=10` APK actually *predated* several exclusion rules already
sitting in `export_presets.cfg` from prior sessions — a plain re-export
recovered 39.57 MB (113.1 → 73.56 MB) with zero content changes;
(C) 21 gameplay-tile/icon assets were found shipping at 1254×1254 (or
1222×1287) source resolution while displaying at 26-250px on screen
(5x-48x oversampled) — created downscaled `<name>_runtime.png` derived
copies, rewired every reference, kept originals on disk unused/excluded
(same pattern as D31). Recovered a further 22.59 MB (73.56 → 50.97 MB).
The 3 `Button` textures, the 3 9-sliced panels, the 2 HUD bars, and the
3 backgrounds were deliberately left untouched (recompute risk or
already-optimal — see D53 for exactly why each one was skipped).
Verified against a real exported `.pck` after every pass (a new gotcha
was found in this technique: running the check script from inside the
project directory silently blends pck contents with the local
filesystem — must run from a directory with no `project.godot` in its
parent chain, see D53/`TEST_PLAN.md`). DESKTOP RENDERED screenshots of
all 6 key screens confirmed no visible quality loss. 15/15 solver +
15/15 runtime-replay regression PASS throughout. The temporary "HUD +
DELAY FIX" QA label was also removed this pass. New build:
`versionCode=11`, `versionName="1.0.0-OPTIMIZED"`, **50.97 MB (55%
below the `versionCode=10` baseline)**. **NOT MANUALLY APPROVED —
ANDROID MANUAL QA PENDING**, this is the next required step. This pass's
own completion is not authorization to start a further optimization
pass, production-pipeline prep, or the 100-level campaign.

**Still true, unchanged since Milestone 4A:**
- 5 of 10 gameplay tile types (emitter, splitter, portal, switch, filter)
  still use pre-Milestone-4A procedural rendering (`DECISIONS.md` D31).
- No Stage Select screen, no real Hint system — don't build either
  unless explicitly asked.
- ~~APK is large (~113 MB)~~ — **addressed** in the "APK Optimization +
  Asset Cleanup" pass above; now 50.97 MB. If size ever needs to shrink
  further, the 3 `Button` textures and the 3 9-sliced panels are the
  next-largest remaining lever (D53) — budget real time to recompute
  their `region_rect`/`texture_margin_*` values correctly rather than
  guessing.

## Development/QA unlock-all flag is currently ENABLED

`LevelManager.UNLOCK_ALL_CAMPAIGN_LEVELS_FOR_TESTING = true` — every
implemented campaign level (currently 1-50) is directly selectable from
Level Select regardless of real unlock progress, to make manual QA of
Stages 3/4/5 faster. It does **not** touch `SaveManager`'s real
completion/star/best-move/unlock data in any way — see `DECISIONS.md`
D58. **This must be set back to `false` before any final production
release build** (`scripts/managers/level_manager.gd`) — see
`TEST_PLAN.md`'s "Development Test Mode" release checklist. Do not
disable it on your own initiative while manual QA is still in progress
unless the user explicitly asks — they are actively using it to test
Stages 3/4/5. It required zero changes when Stage 5 (or the Tutorial)
was added (it's driven by `get_campaign_level_count()`, and the
Tutorial has no equivalent bypass — tutorial unlock is always the real
sequential progression), and will similarly need none for Stage 6+.

## [SUPERSEDED — kept for history only] What things looked like as of an earlier pass

**Everything in this subsection is stale** (it dates from mid-"Stage 5",
long before the 100-level campaign finished, Era 2, or Phase 1). It's
kept for the branch-on-feedback playbooks below, which are still useful
patterns even though the specific level numbers they reference are out
of date. **Skip straight to "What to do next (current, Phase 1)" further
below for the accurate current state.**

**This is now FOUR things at once: (1) CAMPAIGN LEVELS 61-70 MANUAL
TESTING (brand new, never played), (2) CAMPAIGN LEVELS 51-60 MANUAL
TESTING (also still not played), (3) the still-outstanding CAMPAIGN
DIFFICULTY REWORK PASS 2 FULL MANUAL TESTING (Levels 21-45, the
twice-replaced block — only informally sampled so far, "its good" is
NOT a completed review), and (4) GUIDED TUTORIAL RE-TESTING.** Do not
automatically begin Stage 8 (campaign levels 71-100), do not create
Campaign Level 71, do not add Tutorial levels beyond T10, do not
redesign Tutorial content, and do not start any other follow-on work.
Levels 1-20 carry real prior manual approval ("the starting levels are
good"; "these are looking good") **but that approval predates the
reboot (D64), Difficulty Rework Pass 2 (D65), AND both the 51-60 (D66)
and 61-70 (D67) expansions** — a full-campaign playthrough (with
focused attention on 21-45 and dedicated attention on the brand-new
51-70) is still the right ask, not just a check of the newest levels
in isolation. The Tutorial has now had **three** failed manual QA
rounds, back to back:
1. `versionCode=18` — T01 opened with no tiles, softlocked after Reset
   (root cause: two `.tscn` files with an unattached script — see
   `TUTORIAL_SYSTEM.md` section 11 and `DECISIONS.md` D61). Fixed at
   `versionCode=19`.
2. `versionCode=19` — a manual **video** QA found the board dim during
   `REQUIRE_TILE_TAP` too strong/unreliable and the highlight hard to
   see under it (root cause: no dim overlay had ever actually existed —
   the highlight's own contrast was just weak — see `TUTORIAL_SYSTEM.md`
   section 12 and `DECISIONS.md` D62). Fixed at `versionCode=20`.
3. `versionCode=20` — a manual **video** QA found the highlighted
   mirror was visible but could NOT be tapped (root cause: `game.tscn`'s
   `TutorialPanel` instance node redundantly overrode its own base
   scene's bottom-anchored layout to full-screen, so its `Panel` child's
   default `STOP` mouse filter silently intercepted every tap anywhere
   on the board — see `TUTORIAL_SYSTEM.md` section 13 and
   `DECISIONS.md` D63). Fixed at `versionCode=21`.

All three fixes are strongly verified by automated/rendered testing,
but **none has actually been confirmed on a real, successful device
session yet** — every "manual" round so far has been either a live
device test that failed, or a video the user recorded and sent showing
a different failure, never a live device pass that succeeded. The
current build (`versionCode=25`, `"2.2.0-CAMPAIGN-70-QA"`) ships the
Tutorial fixes, Campaign Difficulty Rework Pass 2, AND both the 51-60
and 61-70 Levels all together - check `CURRENT_STATUS.md` for whether a
newer build exists by the time you're reading this. The single next
required step is the user manually playing (1) T01 first from a
completely fresh open (no Reset) to confirm the softlock, dim/highlight
visibility, AND tap-interaction are all actually fixed together, then
T02-T10, and (2) the full 70-level
Campaign - see `TEST_PLAN.md`'s "Campaign Difficulty Rework Pass 2"
section (Levels 21-45, still the outstanding full review), "Campaign
Levels 51-60" section, AND "Campaign Levels 61-70" section (each
block's own recommended review set) - full 70-level playthrough not
required for a first pass, but all three sections' focused review sets
should be covered - and "Guided Tutorial Mode" section (including its
"Runtime fix validation"/"Visual focus fix validation"/"Click input
validation" subsections) for the exact Tutorial checklist.
`CURRENT_STATUS.md` has the current summary for all four.

**Nothing else is blocking on you right now — wait for the user.**
Completing this pass is not itself authorization to start Stage 8,
create Campaign Level 71, introduce portals as a *Campaign* mechanic
(they're already in use post-reboot, but Stage 8 itself is still a
separate ask), add Tutorial levels beyond T10, redesign anything, or
begin any other work — this project has never treated finishing one
explicitly-requested phase as permission for the next, and this
handoff is no exception.

**If the user reports back on the Campaign Reboot, branch on the
result:**
- **If they report a specific rebuilt level (21-50) feels too easy,
  unfairly obscure, or has a real bug**: investigate that level first
  via its own `developer_notes` (every level records its design intent
  and every intentional decoy) and `CAMPAIGN_DESIGN.md` section 11f/
  11g/11h's table. Re-run the solver against it directly before
  assuming the design is wrong - a report of "I couldn't find the
  solution" might mean the intended solution genuinely wasn't traced
  correctly by a human, or might mean the level really is too obscure;
  a report of "this was trivial" might mean a `possible_decoys` piece
  was missed by the original design (re-run `LevelSolver.analyze()` and
  check `possible_decoys` against every rotatable piece). If it's a
  real design/bug issue, fix that ONE level (redesign + re-validate via
  the same batch-solver technique), re-run the full 50/50 regression
  afterward, and don't touch levels that weren't flagged.
- **If they report a KEPT level (1-20 or 46-50) feels different/worse
  than before**: this would be unexpected since these files weren't
  touched by the reboot at all - verify the file genuinely wasn't
  modified (`git diff` if this becomes a real git repo, or just re-read
  the file against `CAMPAIGN_DESIGN.md`'s original section 11/11b/11e
  tables) before assuming a regression; it's more likely a difficulty-
  *perception* shift from playing right after much harder neighboring
  levels than an actual content change.
- **If they report the curve itself feels wrong** (a later level easier
  than an earlier one, a jarring jump, a block that doesn't escalate):
  this is exactly what `CAMPAIGN_DESIGN.md` section 3/4's guideline
  tables and `DECISIONS.md` D64's honest accounting exist to be checked
  against - the reboot deliberately allows some low-move-count levels
  in exchange for reasoning density (see D64's own disclosure of which
  levels land below the guideline and why); don't assume every low
  number is a bug, but do take a genuine "this got easier, not harder"
  report seriously and re-examine that specific transition.
- **If it's approved**: do not proceed to Stage 6, Campaign Levels
  51-100, or any other unrequested work - wait for explicit
  instruction, same as every prior milestone.

**If the user reports a tiles-missing/softlock symptom again**: do not
assume the D61 fix is incomplete without first checking whether a
*different* tutorial `.tscn` file (or any other hand-written `.tscn` in
the project) has the identical missing-`script=ExtResource(...)`
mistake — this bug class produces a generic runtime error, not
something that points at itself, and was found twice independently in
one pass already. Grep every relevant `.tscn`'s `[node name="..." ...]`
root block for a `script =` line matching its `ext_resource` declaration
before assuming a new root cause.

**If the user reports a dim/highlight/darkness symptom again** (board
too dark, highlight still hard to see, dim not clearing, Pause looks
double-dark): re-read `TUTORIAL_SYSTEM.md` section 12 first - the
mechanism is a `TutorialDimOverlay` cutout coupled 1:1 to
`GridManager.set_highlight()`/`clear_highlight()`, not a separate state
machine, so a stale-dim report almost certainly means something called
`set_highlight()` without a matching `clear_highlight()`, not a missing
cleanup call. Reproduce with a real (non-headless) rendered screenshot
before changing constants like `DIM_ALPHA`/`FOCUS_PADDING` blind - and
if you capture screenshots in this dev environment, read `DECISIONS.md`
D62's note about this machine's non-headless window not matching
`project.godot`'s declared resolution before trusting assumed pixel
coordinates.

**If the user reports a "the highlighted tile is visible but tapping it
does nothing" symptom again** (anywhere, not just T01): do not assume
`_on_orientable_tile_clicked()`'s own accept/reject logic first — check
the QA debug overlay's `LAST TAP:`/`HIGHLIGHT:`/`ALLOWED:` line first
(it will say REJECTED with a reason if the tap even reached that
function at all). If `LAST TAP:` never updates no matter where the
player taps, the tap isn't reaching the gameplay layer at all — dump
runtime `mouse_filter`/`get_global_rect()` for every Control between
the Viewport and the tile (per `TUTORIAL_SYSTEM.md` section 13), don't
trust any `.tscn` file's declared anchors in isolation - the exact bug
this fixed was a *different* file's instance-level override silently
replacing a *correct* base scene's layout, so both files need checking,
not just the one that "looks like" the UI element in question.

**When the user reports back on the Tutorial, branch on the result —
don't assume either outcome:**
- **If they report a specific tutorial step feels unclear or broken**
  (instruction text confusing, highlight not visible, forced tap not
  registering, wrong tile accepted when it shouldn't be, a step advances
  too early/late): investigate **only** the tutorial(s) actually
  reported. Re-open that specific `levels/tutorial/t0N.gd` file first —
  the bug is very likely in that level's own `steps` array (wrong
  `target_position`, wrong `step_type` for the intended behavior) rather
  than in `TutorialManager`/`GridManager` shared architecture, since the
  architecture itself was validated by the T01 step-machine test (see
  `TEST_PLAN.md`). If it turns out to be a real architecture bug, fix it
  in the one central place (`TutorialManager`/`GridManager`'s forced-
  interaction fields) — never add a per-tutorial workaround. Re-run the
  full 65/65 regression plus the 10-tutorial solvability check afterward
  regardless of which layer you touched, and don't touch tutorials that
  weren't flagged.
- **If they report the forced interaction feels too restrictive or not
  restrictive enough**: re-read `TUTORIAL_SYSTEM.md` section 6's
  step-type table and section 2's "progressively hand more freedom
  back" philosophy before changing anything — T01-T03 are meant to be
  fully forced, T04+ progressively freer, T10 nearly free play. A
  report that "T02 already feels too easy/hard" is a design-calibration
  note like Stage 4's "feels easy" was — record it, don't necessarily
  redesign on the spot without asking which direction they want.
- **If they report the highlight or panel has a real device layout
  problem** (covers a tile, unreadable text, too small a touch target):
  this is exactly the kind of thing `CLAUDE.md` rules 12a-12e warn
  headless/automated checks can't catch — see `TEST_PLAN.md`'s "Android
  UI/readability assessment" for what was and wasn't actually verified.
  A minimal, targeted fix (panel position, font size) is in scope; a UI
  redesign is not.
- **If they report a mechanic in the Tutorial behaves differently from
  the same mechanic in Campaign**: treat this as a serious bug report,
  not a design note — `TUTORIAL_SYSTEM.md` section 3's core rule is that
  Tutorial and Campaign share the identical simulation. Verify by
  loading the same tile layout in both contexts if needed; the fix
  should almost always be in the tutorial level's own tile data, not in
  `LaserSystem`/`GridTypes`.
- **If it PASSES / is approved**: do not proceed to Stage 6, extend the
  Tutorial, or any other work on your own initiative. Approval of the
  Tutorial is not itself a request to start Stage 6 — wait for the
  user's explicit instruction.

**Stage 5's own outstanding feedback-handling guidance (from before this
pass, still valid if the user reports on Stage 5 instead of/alongside
the Tutorial):**

**When the user reports back on Stage 5 (or Stage 3/4), branch on the
result — don't assume either outcome:**
- **If they report a specific level plays badly** (solution too obvious,
  a filter/decoy that reads as random rather than plausible, a
  cross-branch/global-dependency level (46/47/48/50) that doesn't
  actually feel like "one shared decision," a backward-reasoning level
  (47/50) that doesn't reward backward thinking, a filter tile that's
  hard to tell apart from a target on their actual screen, a level that
  feels harder or easier than its neighbors, a genuine bug): investigate
  **only** the level(s) actually reported. Re-open that specific
  `levels/campaign/stage_05/level_0N.gd` file, re-run
  `LevelValidator`/`LevelSolver` against your fix, re-run the full 50/50
  campaign + 15/15 dev regression (never just the one level you touched
  — confirm nothing else in Stages 1-5 regressed), and re-export before
  reporting back. Don't touch levels that weren't flagged (Stages 1-4's
  levels are approved or pending their own separate QA — leave them
  alone unless a genuine regression is found, not just because you're
  editing nearby files), and don't start Stage 6 as part of a Stage 5
  fix.
- **If they report the difficulty curve feels off** (too hard, too easy,
  not noticeably trickier than Stage 4, inconsistent) for the stage as a
  whole: read `CAMPAIGN_DESIGN.md` sections 2-4 again, and remember
  section 9's warning — don't reach for `LevelMetrics`'s raw
  `difficulty_label` as a fix target, since it's already known to
  mislabel early campaign levels (see D54/D55/D56/D57/D59). Trust the
  human feedback over the auto-estimate — this is exactly the mistake
  Stage 4 avoided by recording real feedback ("feels easy") instead of
  trusting an auto-estimate that would have said otherwise.
- **If they report Level 41 doesn't teach the filter lesson clearly**:
  it's deliberately minimal (one fixed filter, three mirrors, no
  decoys) — investigate whether the color change reads as confusing
  rather than illustrative before adding pieces; re-read
  `CAMPAIGN_DESIGN.md` section 11e's Level 41 row and `DECISIONS.md`
  D59 before changing its geometry.
- **If they report filters are hard to distinguish from targets on
  their device**: this is a real, unresolved risk this pass could only
  reason about, not device-test — see `TEST_PLAN.md`'s "Android color/
  filter readability" section. Check `FilterTile._draw()`
  (`scripts/gameplay/filter.gd`) first; a minimal contrast/stroke
  adjustment there is in scope, a UI redesign is not (`CLAUDE.md`'s
  scope-discipline rules still apply).
- **If they report Level 50 specifically feels weak as a finale**: it's
  meant to be the hardest puzzle in the game so far (an early mirror
  gating the entire board, a chained two-filter recolor on one branch
  vs. filter-avoidance on the other, two distinct false-route types, a
  fixed backward-reasoning mirror, one solver-confirmed inert decoy,
  7x7 grid, 255 states explored) — investigate what specifically feels
  anticlimactic rather than assuming more pieces is the fix — re-read
  `CAMPAIGN_DESIGN.md` section 2's "difficulty from reasoning, not
  clutter" philosophy before changing anything.
- **If it PASSES / is approved**: do not proceed to Stage 6, portals, or
  any other campaign work on your own initiative. Approval of Stage 5 is
  not itself a request to start Stage 6 — wait for the user's explicit
  instruction, even though the eventual sequence (Stage 1 → Stage 2 →
  … → Stage 10) is now obviously implied by the project's own structure.

**Settings is no longer a known issue** — the D48 asset mismatch was
fixed in Milestone 4A.6 (D50) with a correctly-labeled asset, verified by
MD5 and visual inspection before integrating. If the user reports a new
Settings-screen problem, treat it as a fresh report, not a recurrence of
D48.

**Levels 3, 5, 12, and 15's tiles are no longer a known issue** — the D51
export-filter bug was found and fixed, and their tile art (resized
smaller in the APK Optimization pass, D53) was re-confirmed to
instantiate correctly against a real exported package afterward. **Note:
these are dev/regression levels, no longer reachable from any
player-facing menu as of Production Campaign Phase 1 (D54)** — a report
about them could now only come from someone using the level editor or a
regression script directly, not from normal play. If the user (or a
regression run) reports tiles missing OR looking blurry/pixelated,
redo the exported-package verification technique (D51/D53/`TEST_PLAN.md`)
immediately as your first diagnostic step for "missing," and actually
look at a real rendered screenshot for "blurry/pixelated" — both are
proven to catch things source-based testing can't. The same techniques
apply equally to a report about a **campaign** level (1-50, or any
future stage) — don't assume campaign levels are immune just because
they're new.

**If the user reports yet another visual or gameplay-feel problem:**
1. **Actually render and look at the screen in question** (non-headless
   screenshot) before changing any layout code. Don't guess from
   filenames or code review alone.
2. If it's a "can't complete this level" or "X is invisible" report,
   don't stop at source-based testing — also verify against a real
   exported package (`--export-pack` then `--main-pack ... --script`,
   see D51/`TEST_PLAN.md`) if the report is Android-specific and source-
   based checks all pass. This is now a confirmed, real failure mode in
   this project, not a hypothetical.
3. If it's specifically a "can't complete this level" report, replay the
   solver's solution through a real `GridManager` first (headless is fine
   for this part), and if that works, run a real
   `Input.parse_input_event()`-driven click test under non-headless
   rendering before concluding anything about input dispatch.
4. Check build identity (`export_presets.cfg` version, `aapt2 dump
   badging` on the actual APK) — but verify it, don't just assert it,
   especially if a prior session already claimed "stale build" once for
   this same report (see Milestone 4A.3→4A.4 above for exactly this
   trap).
5. If everything traces correctly (including against the exported
   package) and the user's device still disagrees, consider that the gap
   may be genuinely Android-only (a specific device's input driver, a
   digitizer quirk) — a small temporary on-screen debug overlay (see the
   removed `L3 DEBUG` overlay in `CHANGELOG.md`'s Milestone 4A.4 section
   for the exact pattern used) is a reasonable way to get on-device state
   without guessing further.
6. Report findings using the AUTOMATED / DESKTOP RENDERED / ANDROID
   MANUAL QA vocabulary explicitly — never blur them, and never call
   something "Android verified" unless the user manually confirmed it.

**Historical note on procedural generation**: `DECISIONS.md` D30
originally excluded a procedural/random level generator entirely. That
exclusion is **superseded** — the user has since set 2,000 procedural
levels as the explicit long-term direction (see below) — but the
generator itself is still not authorized to be *built* without a
separate, explicit request. Don't start it on your own initiative just
because it's now a documented direction.

If the user's request is ambiguous about scope, ask rather than guessing
big. If documentation and implementation have drifted apart, reconcile
the docs to match the real code as part of your work.

---

## What to do next (current, Final Gameplay Spacing Refinement, `versionCode=44`)

**Read this file's D86 section first if you haven't** (still below,
kept for context) — the short version: Phase 1 claimed a layout was
correct from headless math at one resolution; a real device test proved
it wasn't; D86 fixed the real bug by shrinking the gameplay screen's
outer safe margin, which grows `cell_size` for width-bound boards. This
D87 pass is the user-approved follow-up.

**Good news**: the user manually tested `versionCode=43` (D86) and
confirmed the larger-tile layout is "MUCH BETTER... close to the
desired result" — a final polish request only, not a redesign: move
Top/Bottom HUD a little closer to the screen edge, without touching
tile size or D86's left/right margin.

**Current state**: `SafeAreaMargin.margin_override` (one field, D86)
split into `horizontal_margin_override` (kept at `UIConstants.
GAMEPLAY_HORIZONTAL_MARGIN := 32.0`, unchanged) and a new
`vertical_margin_override` (`UIConstants.GAMEPLAY_VERTICAL_MARGIN :=
8.0`). Full resolution/profile matrix unchanged at 140/140 comfortable
(vertical margin doesn't affect `cell_size`). Visually confirmed via 6
real rendered levels/tutorial. Full regression unchanged: 188/188 PASS.
A dedicated 12-point Phase 2 re-check: 12/12 PASS. QA APK exported and
verified (`versionCode=44`, `versionName="3.6.2-FINAL-SPACING-QA"`,
`builds/android/beamshift-debug.apk`). **NOT MANUALLY APPROVED — the
user has not yet tested this build, or any of the three before it, on a
real device.**

**IMPORTANT MATHEMATICAL FINDING — read before attempting to tighten
gameplay spacing again**: for a width-bound board (the common case at
≤10 columns on a portrait screen — confirmed across every level
checked, 5x6 through 10x12), the outer vertical safe margin has
**provably zero effect** on the visible gap between the HUD and the
board. `CenterArea` absorbs 100% of whatever margin is freed
(`size_flags_vertical = EXPAND_FILL`), and the board is centered within
it, so `total_top_space = TopBar.height/2 - BottomBar.height/2 +
screen_height/2 - board_height/2` — algebraically independent of both
the vertical margin AND `VBoxContainer` separation (both cancel out of
the derivation). Confirmed empirically: sweeping the margin 32→0
against Level 28 moved the HUD bar's own screen position exactly as
expected, but `total_top_space` stayed at exactly 619px throughout. **Do
not re-attempt to shrink margin or separation to close this gap
further — it's mathematically proven pointless, not a matter of trying
a different number.** The only real levers are `TopBar`/`BottomBar`
height (aspect-locked to HUD art — needs new/redesigned art) or `board_
height` (already width-maximized by D86 — needs more columns' worth of
width, or a level redesign). Both are out of scope without an explicit
new request. See `DECISIONS.md` D87 for the full derivation.

**Recorded future-generator guidance** (per this pass's explicit
instruction): a future procedural generator should prefer taller board
profiles (e.g. 5x9, 6x10, 7x11, 8x11 — examples, not mandatory) over
wide-short ones like Level 27 (7x8) or Level 28 (6x7), specifically to
avoid landing strongly width-bound in the first place — gated on
`GridManager.is_board_profile_comfortable()` actually passing for the
target device range, never by shrinking `cell_size` to force a fit.
This is the durable fix for the "large gap" pattern going forward;
existing Levels 1-140 are not being redesigned to chase it.

**What is explicitly NOT started yet, and must not be begun without a
separate explicit request**: the procedural generator itself (Generator
V1), Campaign Levels 141+, T21+, Era 3, or any redesign of existing
content/deletion of Level Select code. Same standing "don't build ahead
of an explicit ask" rule as every prior milestone.

**The single next required step is the user manually testing the QA
APK on a real device** — this build (`versionCode=44`) carries Phase
1's layout foundation, Phase 2's navigation/resume flow, D86's board
correction, AND this spacing refinement, so all four can reasonably be
reviewed together. Use this pass's own manual QA checklist (final
report) — specifically look at Level 28 (the reference level) and Level
27, and confirm the HUD bars now sit close to the screen edge. Also
still applicable from Phase 2 (unaffected by this pass): Main Menu
shows CONTINUE/PLAY/TUTORIAL/SETTINGS/QUIT with no CAMPAIGN button;
PLAY on a fresh save goes to Level 1; PLAY/CONTINUE on a returning save
go to the correct current level; making a few moves, backing to Main
Menu, then CONTINUE restores the exact same tile orientations and move
count; Reset then backing out does NOT restore the pre-reset state;
completing a level advances PLAY/CONTINUE to the next one; completing
Level 140 doesn't crash and NEXT is hidden/absent; Back/Pause from a
normal session never shows Level Select, only Main Menu; the small
"Level Select (QA)" button still works for manual level picking and,
once used, Back/Pause from that session correctly return to Level
Select instead of Main Menu.

**One documented, accepted limitation to know about before diagnosing a
"Continue is disabled but I have progress" report**: an existing save
predating this phase will show `CONTINUE` disabled until the player
presses `PLAY` once (which immediately sets `campaign_resume_level_id`
and self-heals permanently) — this is intentional, not a bug (see
`DECISIONS.md` D85's "one accepted, documented migration limitation").
Don't "fix" this without being asked; it's a one-time, self-resolving,
deliberate trade-off, not a defect.

**If the user reports the resume state didn't restore correctly**: check
whether the report involves the QA Level Select button — sessions
started that way deliberately never read/write `campaign_resume_*` (see
`GameManager.entered_via_level_select`'s doc comment). If the report is
from a genuine PLAY/CONTINUE session, verify `SaveManager.campaign_
resume_level_id` actually matches the level being resumed and that
`GridManager.restore_orientations()` is being called with the level
already loaded (must run after `load_level()`, never before — see
`grid_manager.gd`'s own doc comment on that function for why).

**If the user approves the board sizing (and Phase 1/Phase 2 generally)**:
the natural next ask is the procedural generator itself (Generator V1)
and/or fleshing out `ROADMAP.md`'s 2,000-level direction further — but
**do not start either without the user explicitly asking**. If they
instead ask for something else (more campaign content, a bug fix,
visual polish, or a further tightening of the still-honest residual
height-utilization gap on very tall devices), treat that as its own
request.

**Levels 101-140 (Era 2) and Levels 1-100 (Era 1) still have their own
separate, older manual-QA backlog** (see `CURRENT_STATUS.md` for the
exact current state) — neither Phase 1 nor Phase 2 touched any level
content, so that backlog is unaffected and still worth asking about if
the user brings it up independently.

---

## UPDATE: Phase 3 — Procedural Level Generator V1 + QA Next button (current)

Everything above this line describes Phases 1-2 (`versionCode=41-44`).
**The user then explicitly requested the procedural generator itself**
(a detailed spec), superseding the "don't start it without an explicit
ask" guidance above for this one pass. It is now built. **Read
`PROCEDURAL_GENERATION.md` before touching `scripts/procedural/**`,
`scripts/tools/procedural_audit.gd`, or the procedural branches in
`GameManager`/`SaveManager`/`LevelManager`/`game.gd`/`game.tscn`** — it's
now in `CLAUDE.md`'s "Before touching anything" reading order (item 12).

**Current build**: `versionCode=45`, `versionName="4.0.0-PROCEDURAL-V1-QA"`.
Full writeup: `DECISIONS.md` D88.

**What changed, in one paragraph**: BeamShift's main progression is now
2,000 deterministic, on-device-generated levels. Main Menu `PLAY`/
`CONTINUE` target this population directly (`GameManager.play_game()`/
`continue_game()` now genuinely diverge — PLAY targets real progression,
CONTINUE targets the exact last-opened level, which QA Next can leave
ahead of real progression). The legacy Campaign (1-140) is completely
unchanged, reachable only via the existing "Level Select (QA)" button.
The live generator (`scripts/procedural/ProceduralLevelGenerator`) never
calls `LevelSolver`/`LevelValidator` (dev-only, export-excluded) — it
self-verifies via a direct `LaserSystem` simulation of its own
already-known solution. Those dev-only tools instead exhaustively proved
the generator's own output during a dev-time audit
(`scripts/tools/procedural_audit.gd`): full 1-2000 range, **0 failures,
0 fallbacks, 11/11 determinism matches, all 10 templates used** (a
template-selection bug that silently starved 6 of 10 templates despite a
100%-pass audit was found and fixed — see D88's "a clean audit doesn't
prove diversity" lesson, now also in `CLAUDE.md`'s new "Procedural
generator rules" section). A temporary QA-only "NEXT" skip button
(`LevelManager.SHOW_PROCEDURAL_QA_NEXT_BUTTON`, currently `true`, MUST be
`false` before release) is proven end-to-end to never mark a level
legitimately completed. Zero `LaserSystem`/`GridTypes`/campaign/tutorial/
dev-level code was touched; full legacy regression re-confirmed
unaffected.

**What is explicitly NOT started yet, and must not be begun without a
separate explicit request**: Campaign Levels 141+, T21+, a new Era,
procedural Levels 2001+, any of the documented future-work items in
`PROCEDURAL_GENERATION.md` section 16 (genuinely-reachable decoys,
remaining spec template names, a general N-template layering combinator),
or a production release build (both `SHOW_PROCEDURAL_QA_NEXT_BUTTON` and
the two pre-existing `UNLOCK_ALL_*_FOR_TESTING` flags must be `false`
first, per `PROCEDURAL_GENERATION.md` section 15's release-blocker
checklist).

**The single next required step is the user manually testing this QA
APK on a real device** — this build carries Phases 1-2's layout/
navigation foundation AND the procedural generator, so all of it can
reasonably be reviewed together (four consecutive unreviewed passes now
await real-device feedback). Beyond Phases 1-2's own still-applicable
checklist (above), specifically also check: `PLAY` on a fresh save
enters procedural Level 1; a few procedural levels across the difficulty
range (early/mid/late) look and feel right on a real phone, not just in
a desktop render; the small "NEXT >>" QA button in the bottom HUD is
visible and works during a procedural session only (never during
Campaign/Tutorial); completing a procedural level and pressing NEXT
advances correctly; `CONTINUE` after backing out mid-puzzle restores the
exact board state.

## UPDATE: Audio/SFX Integration Pass + Minimal Gameplay Background Pass (current)

Two passes shipped after Phase 3 above without this file being updated
in between — read `CURRENT_STATUS.md` for the authoritative current
state; this entry exists so this file isn't misread as current through
Phase 3 alone.

**Audio/SFX Integration Pass** (`versionCode=46`, `4.0.1-AUDIO-SFX-QA`,
`DECISIONS.md` D89, new `AUDIO_SYSTEM.md`): a centralized `AudioManager`
autoload (4th autoload — read `AUDIO_SYSTEM.md` before touching it,
`assets/sfx/**`, or any `AudioManager.play_*()` call site) provides 22
semantic gameplay/UI SFX. `LevelData` carries zero audio fields, so all
2,000 procedural levels get audio automatically; gameplay audio reuses
`GridManager._simulate_and_draw()`'s existing `play_impacts` gate, so it
only ever plays for a genuine accepted move.

**Minimal Gameplay Background Pass** (current, `versionCode=47`,
`4.0.3-MINIMAL-BG-QA`, `DECISIONS.md` D90): the user found the gameplay
background's environmental detail (metal panels, reflective floor,
orange/blue glow strips) competing visually with the puzzle. After
confirming neither existing background PNG qualifies as "minimal" and
per the brief's explicit instruction not to generate new art, the fix is
one non-destructive property: `game.tscn`'s root `Background`
`TextureRect` now carries `modulate = Color(0.22, 0.26, 0.38, 1)`. Since
`_apply_era_theme()` only ever swaps this node's `.texture`, this
applies uniformly under every Era with zero per-level code; HUD, grid,
tiles, and beams are structurally unaffected (pixel-sampled, not just
eyeballed). **A genuine environment finding worth knowing before
attempting any future resolution-matrix RENDERED check on this specific
machine**: its physical 2560x1080 monitor silently clamps any on-screen
portrait test window taller than ~1032px, which was quietly reflowing
every prior "1080x1920" on-screen capture on this machine to the wrong
aspect ratio — the fix is capturing through an off-screen `SubViewport`
with an explicit `.size` instead of trusting a `--resolution` flag's
on-screen window at face value; see `TEST_PLAN.md`'s "Minimal Gameplay
Background Pass" section for the exact technique. A board-size gap
(small boards under-using available portrait height on some
resolutions) was found and deliberately left unfixed, per the brief, as
a separate future generator/layout task — see `CLAUDE.md`'s Procedural
generator rules.

**Do not re-tune the modulate value, do not create Campaign Levels 141+,
T21+, a new Era, or procedural Levels 2001+, and do not start the
board-size generator-tuning task without being explicitly asked.** Both
passes above are **NOT MANUALLY APPROVED — Android device QA pending**,
on top of every prior unreviewed pass. The single next required step is
the user's own manual Android review of the QA APK this pass exported.

## UPDATE: Unified Blue Theme Fix (current, `versionCode=48`)

The user approved the Minimal Gameplay Background pass above but
rejected a separate, pre-existing behavior it surfaced: Era 2 content
(Campaign Levels 101+, T11-T20) automatically switched the whole
gameplay screen to a violet/magenta skin — purely as a function of
level/tutorial number, unrelated to the background-darkening fix.
Full detail: `DECISIONS.md` D91.

**What changed, in one paragraph**: BeamShift now uses exactly ONE
active gameplay visual theme (blue/cyan) across all 2,000 procedural
levels, the legacy campaign, and every tutorial — difficulty, procedural
band, and mechanic availability keep changing freely; the skin does
not. The fix is `EraTheme.UNIFIED_BLUE_THEME_ONLY := true`
(`scripts/resources/era_theme.gd`), the single authoritative switch
checked first inside `for_era()` — every visual-theme call site in the
codebase already routed through that one function (grep-confirmed, no
scattered per-file era checks existed), so this one constant is the
complete fix, and flipping it back to `false` is the complete revert.
Numeric era-band logic (T11-T20 unlock gating, the Level 100→101
transition banner) reads `get_era_for_level()`/`get_era_for_tutorial()`
directly and is completely unaffected. Purple Era 2 assets and
`_build_era_2()` are fully retained in source/on disk, just unreachable
while the flag is on. **Read `CLAUDE.md`'s Era 2 rules section before
touching `EraTheme` again** — it documents exactly why a second,
competing "is this Era 2" check anywhere else would break the
single-authority guarantee this flag exists to provide.

**One deliberately-NOT-fixed item, worth knowing before assuming this
pass is "done"**: Prism, One-Way Reflector, Beam Receiver, and Remote
Emitter each `preload()` their own tile texture unconditionally in their
own script — never routed through `EraTheme` at all, so this fix has no
effect on them either way. All 6 of their texture files
(`bs_tile_prism_base_era2.png`, `bs_tile_one_way_reflector_base_era2.png`,
`bs_tile_beam_receiver_{base,inactive}_era2.png`,
`bs_tile_remote_emitter_{base,inactive}_era2.png`) are genuinely
purple-specific art, confirmed by direct visual inspection, not
neutral/blue-compatible. Per the brief's explicit "never generate
images, never destructively recolor a source PNG" instruction, these
were left exactly as they are — they're the one remaining visible
purple element in normal gameplay (small tile icons on an otherwise
all-blue screen), listed in `DECISIONS.md` D91 as the concrete set that
needs a future blue-specific replacement asset. Don't treat their
continued purple color as a bug this pass should have caught.

Two small residual-purple text/color issues were also found and fixed
along the way (both content/style-only): T11's own tutorial message no
longer claims "only the scenery" changes (`levels/tutorial/t11.gd`);
`level_complete_popup.tscn`'s one-time Era 2 unlock announcement
(`EraTransitionLabel`, shown at the real Level 100→101 boundary) was
recolored from violet to cyan-blue — its text content was left
unchanged (still accurate).

RENDERED-verified (D45-D47 tier) across 14 screens: Campaign Levels
21/99/100/101/102/140, procedural Levels 200/500/1000/1500/2000,
Tutorials T01/T11/T20. Level 21 vs. Level 102 (the user's own key
comparison) confirmed visually indistinguishable in background/grid/HUD
family. Procedural determinism (same level+generator-version → identical
seed), PLAY/CONTINUE/QA Next, and AudioManager (22/22 streams) all
re-confirmed unaffected via a real autoload-driven regression run. No
save schema change — `git status` confirms exactly 3 files touched
(`era_theme.gd`, `t11.gd`, `level_complete_popup.tscn`), zero PNGs,
zero procedural/audio/save files.

**Do not generate images, delete purple assets, remove any mechanic,
change procedural difficulty/generator structure, change audio, remove
QA Next, or make a production release build without being explicitly
asked.** **NOT MANUALLY APPROVED — Android device visual QA pending.**
The single next required step is the user's own manual Android review
of this QA APK.

## UPDATE: Difficulty System Phase 1 (current, no new `versionCode`)

Done: difficulty contract, ablation-based complexity metrics, triviality
model, QA +50 centralized (`LevelManager.PROCEDURAL_QA_JUMP_AMOUNT`), root-cause
analysis (D93, `PROCEDURAL_GENERATION.md` 17). Generation unchanged. **Do not
start Phase 2 (templates constructing dependency chains, `GENERATOR_VERSION`
3) until the user approves.** Standing rules: no long audits (use
`scripts/tools/difficulty_inspect.tscn`, stop past ~60 s with
`QA_BUDGET_EXCEEDED`); V1/V2 frozen; QA buttons/flags stay release blockers;
no commit unless asked.

## UPDATE: Difficulty System Phase 2A - V3 prototype (current, `versionCode=49`)

Done: Generator V3 (`scripts/procedural/procedural_*_v3.gd`), six archetypes,
dev-only "V3 TEST"/"NEXT V3", audit tool, APK 49. Default generator is still
V2. **Do not start Phase 2B (scaling V3, making it default) until the user
reports Android feedback.** Before changing any layout re-run
`scripts/tools/v3_prototype_audit.tscn` (shortcut proof). Keep tests under
~60 s; no long audits; no commits unless asked.

## UPDATE: Difficulty System Phase 2A.1 - D/E/F reasoning depth (current, `versionCode=50`)

Done: D/E/F rebuilt (see `DECISIONS.md` D95, `PROCEDURAL_GENERATION.md` 18.7),
APK 50 built. A/B/C untouched. **Wait for the user's Android feedback on D/E/F
before anything else; do not start Phase 2B.** Use `timeout` on every Godot run
(a parse error hangs headless). Inputs for Phase 2B: F still solved by the
greedy proxy; F levels 24/36 retry (padding); pass on a shared One-Way is
geometrically overlapping (D uses a second One-Way). No commit unless asked.


## UPDATE: Difficulty System Phase 2B - V3 progression (current, `versionCode=51`)

Done: V3 is a reusable progression generator (`ProceduralFragmentsV3` atoms ->
`ProceduralComposerV3` layout -> `ProceduralProgressionV3` gates + `ProceduralShortcutProbe`),
per-band contract in `ProceduralDifficultyContract` (Phase 2B targets + `_V3_POLICY`), selected
for new play by `LevelManager.USE_V3_FOR_PROCEDURAL_QA`. Six prototypes untouched (diffed), V1/V2
frozen, `+50`/V3 TEST/saves verified end-to-end through the real game scene. APK
`4.2.0-PROCEDURAL-V3-PROGRESSION-QA` built. Read `PROCEDURAL_GENERATION.md` section 19 and
`DECISIONS.md` D96 first. **Wait for the user's Android playtest** (early not too hard, difficulty
noticeable after ~20-30 levels, mid game more reasoning, high levels not greedy-solvable, tiles
large). Do not run a full 1-2000 audit, do not finalise stars, do not add mechanics, do not make
V3 default, do not commit unless asked. Use `timeout` on every Godot run; keep tests < ~60 s.
Known: above ~17 rotatable tiles only the probe + structural rules cover shortcuts (solver
UNKNOWN); wrong-colour decoys/reciprocal dependencies not implemented; top-band generation
100-330 ms on desktop (device unmeasured).


## UPDATE: Global Hint System Phase 1 (current, `versionCode=52`)

Done: shared Hint button -> `HintManager` -> one ringed required tile from known solutions (D97). No runtime
solver; campaign/tutorial solutions are offline (`levels/hint_solutions.json`, rebuild with
`scripts/tools/hint_solution_builder.tscn` if those levels change). No star penalty, no ads (seam only). Wait for
Android testing before Phase 2C. Use `timeout` on Godot runs; no commit unless asked.


## UPDATE: AdMob Foundation V1 (current, `versionCode=53`)

Done: `AdManager` + `AdBackend` + Poing AdMob v5.1.0, rewarded hint (reward callback only), interstitial every 4 legitimate completions (120 s), TEST ids only - read `ADS_MONETIZATION.md` and D98 first.
Do not add production ids to source control, banners or app-open ads. Android needs Gradle + JDK 17. Real ad behaviour is unverified until the device test; iOS unbuilt. No commit unless asked.

## UPDATE: Fusion Node Phase 2 (current, `versionCode=55`)

Fusion is generated by procedural generator V4 (D100): fragments F1-F7 (`ProceduralFragmentsV3.FUSION_RECIPES`), unlock table `ProceduralDifficultyContract._FUSION_PROGRESSION` (none in 1-200), checks in `ProceduralFusionCheck`. V1/V2/V3 are FROZEN - fingerprint them before/after any composer/fragment/probe change. Level 2000 is the certification target, not a ceiling; NEVER expose Level 2001+, build a post-2000 progression or a Fusion tutorial (a production RELEASE BLOCKER) unless asked. `MAX_COLUMNS` stays 8, no smaller tiles. AdMob test ads are device-verified; do not change monetization. Wait for the user's Android feedback before tuning (knobs: `_FUSION_PROGRESSION` probabilities, `FUSION_PROBE_SIMS`, `FUSION_ATTEMPTS`). Use `timeout` (a parse error hangs headless Godot); never commit unless asked; never name a PowerShell helper `Rd`/`Ri`/`Rm`/`Cp`.


## UPDATE: Fusion Node Phase 3 (current, `versionCode=56`, `4.6.0-FUSION-FULL-QA`)

Fusion is a PRODUCTION-SUPPORTED mechanic (D101): tutorial pack T21-T28 exists (`levels/tutorial/t21.gd`-`t28.gd`, `TUTORIAL_SYSTEM.md` section 14; unlock `LevelManager.is_fusion_tutorial_selectable()` - not era-gated), the "Fusion tutorial = release blocker" line above is RESOLVED. Generator V4 gained variants/`FUK`, a dead-node-blocker ablation (never revert it to deleting the tile - it caused false rejections) and exact shortcut screens (`PROCEDURAL_GENERATION.md` section 21). V1/V2/V3 stay FROZEN - fingerprint before/after any composer/fragment/complexity change. Level 2000 remains the certification target; NEVER expose Level 2001+, build a post-2000 progression, add chained Fusion, another mechanic, or a star economy unless asked. All QA flags are still ON (production clean-up is a separate pass); Google TEST ads only. Wait for the user's Android feedback before tuning. Use `timeout`; never commit unless asked; never name a PowerShell helper `Rd`/`Ri`/`Rm`/`Cp`; after editing `ARCHITECTURE.md` verify it exists and is non-empty.

## Phase 4 (D102, `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`) - stars, Hint cap, central QA switch, Fusion tutorial nudge

- **Stars:** one rule in `StarScoring` (OPTIMAL from `verified_optimal_moves` >= 0, else `intended_moves`, else legacy `optimal_moves`; +2 = 3 stars, +6 = 2, else 1; below optimal = 3 + QA warning). A GRANTED gameplay Hint caps the attempt at 2 stars (`game.gd._hint_used_this_attempt`, persisted in `procedural_resume_hint_used`/`campaign_resume_hint_used` so Continue cannot reset it; cleared by Reset/Next/QA +50). Best stars: `SaveManager.procedural_best_stars["<level>|<generator_version>"]` (raise-only) and the existing campaign dictionary. Tutorials, V3 TEST, FUSION TEST: no stars, no records. The popup shows the current run's stars + a small "HINT USED".
- **QA vs production:** ONE constant, `BuildConfig.IS_PRODUCTION_BUILD` (false in this build). It derives every QA-only UI/unlock flag in `LevelManager` and hides the tutorial debug overlay and the generator tag. Tools are hidden, never deleted. Not covered: Google TEST ad ids, and the generator rollout flags `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA`.
- **Fusion tutorial nudge:** one-time non-blocking "NEW TUTORIAL: FUSION" banner on Main Menu (`LevelManager.should_show_fusion_tutorial_nudge()`, persisted `fusion_tutorial_nudge_seen`); never forces the tutorial, never locks progression. `bs_fusion_icon.png` remains unused (no icon support in the tutorial panel).
- Level 2000 remains the certification target; nothing beyond it is exposed; no new mechanic.

## UPDATE: HUD edge spacing (`versionCode=58`, `4.7.1-HUD-EDGE-QA`)

Top/Bottom HUD plates now sit `UIConstants.GAMEPLAY_VERTICAL_MARGIN` (8 px) inside the safe area: `SafeAreaMargin.set_hud_overhang()` compensates for the HUD art's transparent padding (`UIConstants.HUD_TOP_ART_PAD_FRACTION` / `HUD_BOTTOM_ART_PAD_FRACTION`, fed by `game.gd`). Do not "fix" it with per-level offsets or by disabling safe-area margins; re-measure the fractions if the HUD art changes. See DECISIONS.md D103.

## UPDATE: HUD final position (`versionCode=59`)

HUD gaps are asymmetric and centralized: `UIConstants.GAMEPLAY_TOP_VISIBLE_GAP` (3) / `GAMEPLAY_BOTTOM_VISIBLE_GAP` (20). Art-padding fractions are not tuning knobs. See D104.

## UPDATE: HUD symmetric gap (`versionCode=60`)

Top and bottom HUD visible gaps are equal by rule (`GAMEPLAY_TOP_VISIBLE_GAP` = `GAMEPLAY_BOTTOM_VISIBLE_GAP` = 20). Bottom placement is user-approved; do not move it. See D105.

## UPDATE: gameplay stack shift (`versionCode=61`)

The whole gameplay stack is offset by `UIConstants.GAMEPLAY_STACK_VERTICAL_OFFSET` (-8) plus an automatic Android inset-asymmetry balance in `SafeAreaMargin`, clamped so the HUD never leaves the safe area. Not yet tuned against a real screenshot (none was received). See D106.

## UPDATE: stack offset -20 (`versionCode=62`)

`UIConstants.GAMEPLAY_STACK_VERTICAL_OFFSET` is -20.0 (was -8) as a comparison build; the clamp caps the shift at `GAMEPLAY_TOP_VISIBLE_GAP` (20). Wait for a real screenshot before further tuning.

## UPDATE: stack -100 px QA TEST (`versionCode=63`) - NOT production

`GAMEPLAY_STACK_VERTICAL_OFFSET` = -120 and `ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET` = true bypass the safe-edge shift cap (QA only). The previous -20 build was capped at 20 px of shift (effective 12 px more than -8). Restore the clamped rule (flag false, sane offset) after the user picks a value.

## UPDATE: stack calibration (`versionCode=64`) - QA only

`GAMEPLAY_STACK_VERTICAL_OFFSET` = -70 (build 62 was effectively 20 up, build 63 120 up), cap override `ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET` still true. Not production approved; restore the clamp once the user picks a value.

## UPDATE: stack calibration (`versionCode=65`) - QA, pending approval

`GAMEPLAY_STACK_VERTICAL_OFFSET` = -30 (real screenshot of build 64 was too high). QA cap override still true; convert to the final production-safe implementation only after the user approves a position.

## UPDATE: NEW GAME flow (`versionCode=66`)

Main Menu button is NEW GAME (node `PlayButton`). Rule and preserve/reset lists: DECISIONS.md D107 and CLAUDE.md. Use `SaveManager.reset_main_progress_for_new_game()` for any future main-run reset. HUD stack calibration (-30, QA cap override) is unchanged and still pending approval.

## UPDATE: Hint attention pulse (`versionCode=68`, `4.8.2-HINT-ATTENTION-PULSE-QA`)

Visual-only Hint button pulse in `game.gd` (`_hint_attention_*`), tunables `UIConstants.HINT_*`. Awaiting Android testing; no commit made.

## UPDATE: Level Complete button fix (`versionCode=67`, `4.8.1-LEVEL-COMPLETE-BUTTON-FIX-QA`)

Fixed the stretched NEXT LEVEL/RETRY/LEVEL SELECT buttons on `scenes/ui/level_complete_popup.tscn`'s `ButtonRow`: they were missing `size_flags_horizontal` and had `custom_minimum_size.x = 0`, so Godot's default `FILL` sizing stretched the `StyleBoxTexture` button art to the full ~812px panel width instead of the intended proportion. Fix was `size_flags_horizontal = 4` (SHRINK_CENTER) + `custom_minimum_size = Vector2(600, 140)` on all three buttons, matching the pattern `main_menu.tscn`'s buttons already use. Rendered-verified at 540x960 and 1080x2400 (both produced identical 600x140 button rects, ratio 4.2857). `pause_menu.tscn` and `tutorial_complete_popup.tscn` have the exact same missing-pattern bug (each is its own hand-authored scene, not a shared component) but were deliberately left untouched — out of scope for this pass, fix them the same way if a future pass is asked to. Stars/Moves Used/panel position/HUD/board were not touched. Awaiting the user's Android screenshot approval.
