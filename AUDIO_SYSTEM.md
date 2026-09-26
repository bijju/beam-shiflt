# AUDIO_SYSTEM.md

BeamShift's centralized SFX architecture (Audio/SFX Integration Pass,
`versionCode=46`, `4.0.1-AUDIO-SFX-QA`). Read this before touching
`scripts/managers/audio_manager.gd`, `assets/audio/default_bus_layout.tres`,
`assets/sfx/**`, or any `AudioManager.play_*()` call site. See
`DECISIONS.md` D89 for the implementation writeup and `CLAUDE.md`'s audio
architecture rule for the permanent, standing rule this doc expands on.

## 1. Source audio

22 SFX files live at `res://assets/sfx/` (confirmed the real, only audio
folder in the project — no `assets/audio/sfx/` or similar exists). Sourced
from the Kenney `interface-sounds` and `sci-fi-sounds` packs per the user's
own naming; the unverified `Digital_SFX_Set` was NOT used, per instruction.
All 22 files exist, import cleanly (`.import` siblings present), are valid
non-zero-length OGG streams (4.5–29 KB each), and are NOT excluded from
the Android export (`export_presets.cfg`'s `exclude_filter` has no
`assets/sfx` entry — everything under it ships via the default
`export_filter="all_resources"`).

`assets/audio/default_bus_layout.tres` is new (this pass) — the project's
audio bus layout, referenced from `project.godot`'s `[audio]` section.

## 2. AudioManager architecture

`scripts/managers/audio_manager.gd`, autoload name `AudioManager`, 4th
autoload after `SaveManager`/`LevelManager`/`GameManager`. This clears
CLAUDE.md rule 6's "earned, not default" bar: audio feedback is needed
from every single screen (menus, gameplay, popups) and must persist across
scene changes (`get_tree().change_scene_to_file()` never survives a
locally-scoped node), exactly the same justification the existing three
autoloads already have. No `class_name` (same convention as
`SaveManager`/`LevelManager`/`GameManager` — none of them declare one
either; callers reference it by autoload name).

Levels never reference audio. `LevelData`/`TilePlacement` gained zero new
fields — no sound path, no volume, no `AudioStreamPlayer`, nothing. Every
one of the 22 semantic events below is driven by a real gameplay
transition (a tap, a solve, a state change), never by level content, which
is what makes all 2,000 procedural levels (and every legacy/campaign/
tutorial level) get audio for free.

### Semantic methods

One method per SFX file, exact 1:1 mapping (`scripts/managers/audio_manager.gd`'s
`SFX_TABLE`):

| Method | File | Bus | Notes |
|---|---|---|---|
| `play_ui_button_press()` | `sfx_ui_button_press.ogg` | UI | ordinary buttons |
| `play_ui_back()` | `sfx_ui_back.ogg` | UI | literal Back buttons only |
| `play_ui_level_select()` | `sfx_ui_level_select.ogg` | UI | choosing a level/tutorial card |
| `play_ui_locked()` | `sfx_ui_locked.ogg` | UI | registered, unused — see §11 |
| `play_ui_popup()` | `sfx_ui_popup.ogg` | UI | Pause popup only — see §11 |
| `play_mirror_rotate()` | `sfx_mirror_rotate.ogg` | SFX | accepted player rotation only |
| `play_mirror_locked()` | `sfx_mirror_locked.ogg` | SFX | tap on a fixed Mirror/Splitter/One-Way Reflector |
| `play_laser_activate()` | `sfx_laser_activate.ogg` | SFX | Remote Emitter power-on (Era 2) |
| `play_laser_reflect()` | `sfx_laser_reflect.ogg` | SFX | Mirror reflection this move |
| `play_laser_split()` | `sfx_laser_split.ogg` | SFX | Splitter branch / Prism channel split |
| `play_target_activate()` | `sfx_target_activate.ogg` | SFX | inactive→active transition |
| `play_target_wrong()` | `sfx_target_wrong.ogg` | SFX | registered, unused — see §11 |
| `play_filter_pass()` | `sfx_filter_pass.ogg` | SFX | beam crosses a Filter this move |
| `play_portal_enter()` | `sfx_portal_enter.ogg` | SFX | at the entry cell |
| `play_portal_exit()` | `sfx_portal_exit.ogg` | SFX | at the exit cell, same move, no delay |
| `play_switch_activate()` | `sfx_switch_activate.ogg` | SFX | also Beam Receiver hit (Era 2) |
| `play_gate_open()` | `sfx_gate_open.ogg` | SFX | closed→open transition |
| `play_hazard_hit()` | `sfx_hazard_hit.ogg` | SFX | inactive→hit transition |
| `play_puzzle_solved()` | `sfx_puzzle_solved.ogg` | SFX | is_solved false→true, player move only |
| `play_level_complete()` | `sfx_level_complete.ogg` | SFX | when the Complete popup appears (Campaign, Tutorial, Editor Playtest, Procedural) |
| `play_star_appear()` | `sfx_star_appear.ogg` | SFX | registered, unused — see §11 |
| `play_tutorial_step()` | `sfx_tutorial_step.ogg` | UI | tutorial panel Continue tap |

## 3. Audio buses

New: `Master` (0, implicit), `SFX` (1, sends to Master), `UI` (2, sends to
Master) — `assets/audio/default_bus_layout.tres`. No `Music`/`Ambience`
buses were added — this pass is deliberately SFX-only, per instruction
("DO NOT build music yet"); `SaveManager.music_enabled` remains exactly
as it was before this pass (an unused, pre-existing field with no bus or
UI behind it — nothing here regressed it, nothing here gave it new
meaning).

## 4. Settings integration

`settings_menu.gd`'s existing **Sound** toggle (an ON/OFF `Button`, not a
slider — see its own Milestone 4A.1 doc comment) is now wired to
`AudioManager.set_sound_enabled(enabled)`, which mutes/unmutes both the
`SFX` and `UI` buses together. This was a deliberate adaptation, not a
Settings redesign, per instruction ("adapt cleanly... do not add
unnecessary sliders if the current UI isn't designed for them") — the
screen has exactly one relevant toggle (**Music** is unrelated and
untouched), so that toggle now doubles as the project's one exposed
SFX/UI mute switch.

`AudioManager.set_sfx_volume_linear(volume: float)` (0.0–1.0, converted to
dB via `linear_to_db()`) also exists on both buses, for a future slider —
implemented now specifically so the 100/50/0% test matrix (§14) is
actually exercisable via a direct API call even though no slider exists
in the UI yet. Whichever of `set_sound_enabled()`/`set_sfx_volume_linear()`
ran most recently wins (mute is a bus-level flag independent of
`volume_db`, so a future slider and the existing toggle can coexist
without fighting each other — muting silences regardless of the
slider's last value).

## 5. Volume persistence

Unchanged mechanism: `SaveManager.sound_enabled`/`save_game()` (already
existed, JSON at `user://savegame.json`). `AudioManager._ready()` reads
`SaveManager.sound_enabled` once at startup and applies it
(`AudioServer.set_bus_mute`) — safe because `SaveManager` is autoload #1
and `AudioManager` is autoload #4, so `SaveManager.load_game()` has
already run by the time `AudioManager._ready()` executes (Godot
initializes/`_ready()`s autoloads in `project.godot` declaration order).
No new save field, no new JSON file — the granular volume from
§4 is intentionally NOT persisted (nothing currently sets it outside a
direct QA call, so there is nothing to persist yet).

## 6. Player pooling

`AudioManager` owns a fixed pool of 10 `AudioStreamPlayer` children,
built once in `_ready()`, never grown at runtime
(`POOL_SIZE`/`_build_pool()`). `_play()` advances a round-robin cursor
and reassigns `.stream`/`.bus`/`.volume_db` on whichever player the
cursor lands on, calling `.play()` — this naturally lets short SFX
overlap (a Splitter branch and its own reflection sound can play at the
same time on two different pool players) and, once the pool is fully
busy, the round-robin simply reassigns the oldest-started voice (a hard,
predictable concurrent-voice ceiling — never an unbounded number of
`AudioStreamPlayer` nodes, mobile-friendly by construction).

## 7. Preload strategy

`AudioManager._load_streams()` is the ONE place any `assets/sfx/*.ogg`
path appears in the project. It uses `ResourceLoader.exists()` +
runtime `load()` (not compile-time `preload()`) specifically so one
missing/corrupt file can never break loading of the other 21 — see §12
(missing-resource safety). No other script anywhere `preload()`s or
`load()`s an SFX file directly.

## 8. Per-SFX gain

`AudioManager.SFX_TABLE`'s `gain_db` field, one number per event, applied
as `AudioStreamPlayer.volume_db` at play time — never edits the source
`.ogg` files. Current values are placeholder judgment calls (no manual
Android audio listening pass has happened yet): frequent/subtle events
(`mirror_rotate: -4.0`, `ui_button_press: -3.0`, `laser_reflect: -3.0`)
are pulled down; prominent/rare events (`level_complete: +2.0`,
`puzzle_solved: +1.0`) are pushed up; everything else defaults to `0.0`.
**Expect to retune these after real-device listening feedback** — it's
one dictionary, in one file.

## 9. Anti-spam and suppression

No global "is audio suppressed" flag exists, and none was needed — the
gating is structural:

- **Player-caused-only gate**: `grid_manager.gd`'s
  `_simulate_and_draw(play_impacts: bool)` already existed before this
  pass (Milestone 4A's mirror-impact VFX) with the exact right shape —
  `play_impacts` is `true` for exactly one call site,
  `_on_orientable_tile_clicked()`, which only runs for an ACCEPTED player
  tap (already past the `is_solved`/`interaction_locked`/
  `interaction_restricted_to` guards). `load_level()`, `restore_orientations()`
  (Continue/resume), and `reset_level()`→`load_level()` all use the
  `false` default. All new gameplay-transition/beam-interaction audio in
  this pass (`_play_state_transition_audio()`, `_play_beam_interaction_audio()`,
  and the `puzzle_solved` call) lives INSIDE the `if play_impacts:` branch
  — so Continue/resume restoration, level load, Reset/Retry, and the
  procedural generator/solver/audit (which never touch `GridManager` at
  all — see `PROCEDURAL_GENERATION.md` "self-verification") are silent
  by construction, not by a separate suppression check that could drift
  out of sync.
- **`mirror_rotate` is called from `GridManager._on_orientable_tile_clicked()`
  itself**, at the exact point a rotation is known-accepted — never from
  `MirrorTile`/`SplitterTile`/`OneWayReflectorTile`'s own `_gui_input()`
  (which fires on every tap of a rotatable tile, including one
  `GridManager` will go on to reject).
- **Transition-only playback**: `_play_state_transition_audio()` snapshots
  every target/switch/hazard/gate/receiver/remote-emitter node's PREVIOUS
  state before `_simulate_and_draw()` overwrites it, then only plays a
  sound for a false→true transition — an already-active target holding
  active plays nothing.
- **Beam-interaction de-duplication**: `_play_beam_interaction_audio()`
  de-dupes by grid position (mirror/splitter/prism/filter) or by
  entry/exit position pair (portal) within one evaluation, so a beam that
  revisits a cell (a loop-guarded revisit, or two branches crossing the
  same cell) plays that cell's SFX once, not once per visit.
- **Pool voice ceiling**: §6's round-robin pool is a final, blanket
  concurrency cap regardless of how many events a single move produces.

## 10. Continue/resume + procedural generation suppression

Both are the same structural guarantee as §9's first bullet — Continue
calls `restore_orientations()` (→ `_simulate_and_draw(false)`), and the
procedural generator (`ProceduralLevelGenerator`) and its dev-only audit
(`scripts/tools/procedural_audit.gd`) call `LaserSystem.simulate_until_stable()`
directly and never instantiate a `GridManager` at all — see
`PROCEDURAL_GENERATION.md`. Verified end-to-end by a temporary headless
driver this pass (loaded Level 1 via a real `GridManager`, called
`restore_orientations()` directly, confirmed no crash and — by
construction — no audio call on that path since every audio call site
sits behind `if play_impacts:`).

## 11. Registered-but-unused SFX (explicit, not an oversight)

Three of the 22 files have no real event to hook, per instruction ("do
not invent new failure mechanics/UI states merely to use a sound"):

- **`sfx_target_wrong.ogg`** (`play_target_wrong()`) — `LaserSystem` has
  no "a beam of the wrong color reached this target" signal; it only
  reports which targets a beam successfully activated
  (`activated_targets`). No such failure event exists to detect.
- **`sfx_star_appear.ogg`** (`play_star_appear()`) — `LevelCompletePopup.show_result()`
  sets all 3 star icon textures in one call, not a staggered per-star
  reveal. No such reveal event exists to detect.
- **`sfx_ui_locked.ogg`** (`play_ui_locked()`) — the only "locked" UI
  elements in the project are `level_button.gd`/`tutorial_button.gd`'s
  `Button.disabled = true` state (set by `LevelSelect`/`TutorialSelect`
  for a not-yet-unlocked card). A disabled Godot `Button` intercepts NO
  input at all (`pressed` never fires, `_gui_input()` never runs), so
  there is no real "player tapped while locked" event, without
  artificially enabling a disabled button just to catch the tap — which
  the brief explicitly says not to do.

All three remain fully wired and callable (any future feature that adds
a real event for one of them needs zero `AudioManager` changes).

## 12. Missing-resource safety

`_load_streams()` calls `ResourceLoader.exists()` before `load()`ing each
of the 22 paths; a miss logs one `push_warning()` and that event key is
simply absent from `_streams`. `_play()` no-ops (returns immediately) for
any key not in `_streams` — every `AudioManager.play_*()` call from
anywhere in the codebase is unconditionally safe to call even if every
single SFX file were deleted; nothing downstream (gameplay,
`SaveManager`, `LevelManager`, procedural progression) can be affected by
an audio load failure.

## 13. Era 2 mapping

No new SFX assets were added or requested for Prism / One-Way Reflector /
Beam Receiver / Remote Emitter. Reused, after inspecting each file's
approximate character/duration against the existing Era 1 semantics:

- **Prism** channel split → `play_laser_split()` (same "one beam becomes
  several" shape as a Splitter branch — `_play_beam_interaction_audio()`
  detects a prism position in a beam's path the same way it detects a
  splitter).
- **One-Way Reflector** reflective hit → `play_laser_reflect()` —
  `_play_beam_interaction_audio()` checks `_orientable_nodes.get(pos) is
  OneWayReflectorTile` alongside its `MirrorTile` check. Safe to reuse
  unconditionally because `LaserSystem` only ever records a segment-corner
  point for a One-Way Reflector's REFLECTIVE hits — a pass-through hit
  records no point at all (see `laser_system.gd`) — so reaching this
  branch already guarantees a real reflection happened.
- **Beam Receiver** hit → `play_switch_activate()` (`_play_state_transition_audio()`
  — same "power source hit" shape as a Switch).
- **Remote Emitter** inactive→active → `play_laser_activate()`
  (`_play_state_transition_audio()` — its beam is otherwise identical to
  a real Emitter's, see `laser_system.gd`'s Remote Emitter handling).

## 14. Production checklist

- `AudioManager.set_sound_enabled(false)` must genuinely mute both `SFX`
  and `UI` buses (verified — see §17 test log).
- No `AudioStreamPlayer` is ever instantiated outside `AudioManager`'s
  own fixed pool.
- No level/tile data references an audio path (`LevelData`/`TilePlacement`
  are unchanged by this pass — grep confirms zero new fields).
- `assets/sfx/**` ships in the Android export (confirmed via the real
  exported `.apk`, not editor import status alone — see the final
  report's Android export section, and `CLAUDE.md`'s own standing rule
  about `--export-pack` vs. a real `.apk` check).

## 15. Manual Android audio QA checklist

None of the following can be verified headlessly — mark them
`MANUAL TEST REQUIRED` until a real device confirms them (see
`TEST_PLAN.md`'s own standing rule against claiming a manual-only test
was automated):

1. Every UI button (Play/Continue/Tutorial/Settings/Quit/Back/Reset/
   Pause/Resume/Restart/Next/Retry/Level Select/Main Menu/Tutorial
   Continue) produces an audible, correctly-mapped sound.
2. Mirror/Splitter/One-Way Reflector rotation sounds natural and isn't
   audibly delayed from the tap.
3. Reflection/split/filter/portal/switch/gate/hazard sounds are audible
   and not distractingly loud/quiet relative to each other (§8's gains
   are unlistened placeholders).
4. Puzzle Solved plays once at solve, Level Complete plays once ~0.8s
   later when the popup appears — confirm the pairing doesn't feel
   cluttered (§8/Part 14 of the brief flagged this as a judgment call).
5. Settings' Sound toggle OFF genuinely silences everything; toggling
   back ON restores it; the choice survives an app restart.
6. Continuing a saved game produces NO burst of sound during
   restoration.
7. QA Next produces only a soft button-press tick, never Puzzle
   Solved/Level Complete.
8. Overall gameplay volume balance on a real phone speaker (headless
   testing cannot assess perceived loudness at all).

## 16. Known issues / honest gaps

- **Per-SFX gains (§8) and bus mix are unlistened placeholders** —
  expect real tuning after manual Android audio QA (§15).
- **No slider exists for the granular volume API** (§4/§5) — it's real
  and tested via direct calls, but nothing in the Settings UI exposes it
  yet; a future pass can wire a slider without touching `AudioManager`.

## Fusion Node mapping (D99)

No new SFX (Phase 2 added none). Fusion inactive -> active plays `laser_split` (existing), only inside the accepted-move transition-audio gate; generated Fusion levels use the same path.

## Fusion Phase 3 (D101, `versionCode=56`) - no new audio

The Fusion tutorial pack (T21-T28) reuses the existing tutorial-step cue (`AudioManager.play_tutorial_step()` via the Hint ring, the normal tile-rotate/target/level-complete events) and the already-approved reused Fusion activation SFX. No new SFX asset, no new `play_*()` method, no audio fields on `LevelData`/`TutorialStepData`.
