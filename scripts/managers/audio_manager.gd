extends Node
## Autoload: AudioManager
## Centralized BeamShift SFX system (Audio/SFX Integration Pass, see
## AUDIO_SYSTEM.md). Owns the ONE shared pool of AudioStreamPlayer nodes and
## exposes semantic play_*() methods - callers never reference a file path,
## an AudioStreamPlayer, or a bus name directly. This is what lets all 2000
## procedural levels (and every legacy/campaign/tutorial level) get audio
## for free: LevelData never carries a sound path (see CLAUDE.md's audio
## architecture rule) - every event below is driven by a real gameplay
## transition, not by level content.
##
## Player-caused-only gating: gameplay callers (grid_manager.gd) only ever
## invoke these methods from `_simulate_and_draw(play_impacts=true)`, which
## is ONLY ever passed true by an actual accepted player tap
## (_on_orientable_tile_clicked). Every other call site (load_level(),
## restore_orientations(), reset_level()) uses the false default - so
## Continue/resume restoration, level load, and the procedural generator/
## solver (which never touch GridManager at all - see PROCEDURAL_GENERATION.md
## "self-verification") are silent by construction, with no separate
## suppression flag needed. See AUDIO_SYSTEM.md "Anti-spam and suppression".

const SFX_DIR := "res://assets/sfx/"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

## event key -> {file, bus, gain_db}. gain_db is a centralized per-SFX
## tuning offset (see AUDIO_SYSTEM.md "Per-SFX gain") - never edit the
## source .ogg files themselves. Defaults to 0.0 where the source clips'
## own loudness already reads reasonably; a handful of frequent/prominent
## events are nudged down/up. Placeholder judgment calls (no manual
## Android audio QA has happened yet) - adjust here, in one place, after
## real-device listening feedback.
const SFX_TABLE := {
	"ui_button_press": {"file": "sfx_ui_button_press.ogg", "bus": BUS_UI, "gain_db": -3.0},
	"ui_back": {"file": "sfx_ui_back.ogg", "bus": BUS_UI, "gain_db": -2.0},
	"ui_level_select": {"file": "sfx_ui_level_select.ogg", "bus": BUS_UI, "gain_db": -2.0},
	"ui_locked": {"file": "sfx_ui_locked.ogg", "bus": BUS_UI, "gain_db": -2.0},
	"ui_popup": {"file": "sfx_ui_popup.ogg", "bus": BUS_UI, "gain_db": -2.0},

	"mirror_rotate": {"file": "sfx_mirror_rotate.ogg", "bus": BUS_SFX, "gain_db": -4.0},
	"mirror_locked": {"file": "sfx_mirror_locked.ogg", "bus": BUS_SFX, "gain_db": -3.0},

	"laser_activate": {"file": "sfx_laser_activate.ogg", "bus": BUS_SFX, "gain_db": -2.0},
	"laser_reflect": {"file": "sfx_laser_reflect.ogg", "bus": BUS_SFX, "gain_db": -3.0},
	"laser_split": {"file": "sfx_laser_split.ogg", "bus": BUS_SFX, "gain_db": -2.0},

	"target_activate": {"file": "sfx_target_activate.ogg", "bus": BUS_SFX, "gain_db": 0.0},
	"target_wrong": {"file": "sfx_target_wrong.ogg", "bus": BUS_SFX, "gain_db": 0.0},
	"filter_pass": {"file": "sfx_filter_pass.ogg", "bus": BUS_SFX, "gain_db": -2.0},

	"portal_enter": {"file": "sfx_portal_enter.ogg", "bus": BUS_SFX, "gain_db": -1.0},
	"portal_exit": {"file": "sfx_portal_exit.ogg", "bus": BUS_SFX, "gain_db": -1.0},

	"switch_activate": {"file": "sfx_switch_activate.ogg", "bus": BUS_SFX, "gain_db": 0.0},
	"gate_open": {"file": "sfx_gate_open.ogg", "bus": BUS_SFX, "gain_db": 0.0},
	"hazard_hit": {"file": "sfx_hazard_hit.ogg", "bus": BUS_SFX, "gain_db": 0.0},

	"puzzle_solved": {"file": "sfx_puzzle_solved.ogg", "bus": BUS_SFX, "gain_db": 1.0},
	"level_complete": {"file": "sfx_level_complete.ogg", "bus": BUS_SFX, "gain_db": 2.0},
	"star_appear": {"file": "sfx_star_appear.ogg", "bus": BUS_SFX, "gain_db": 0.0},
	"tutorial_step": {"file": "sfx_tutorial_step.ogg", "bus": BUS_UI, "gain_db": -2.0},
}

## Small shared voice pool (see AUDIO_SYSTEM.md "Player pooling") - fixed
## size, never grown at runtime, so short overlapping SFX (a splitter
## branching into two reflections, several targets activating on the same
## move) can play concurrently without one player node cutting another
## off. Round-robin selection intentionally steals the oldest-started
## voice once the pool is full rather than growing further - a hard,
## predictable ceiling on concurrent gameplay SFX, mobile-friendly by
## construction (Part 22/Part 21 of the audio brief).
const POOL_SIZE := 10

var _streams: Dictionary = {} # event key -> AudioStream (only successfully-loaded entries)
var _pool: Array[AudioStreamPlayer] = []
var _pool_cursor: int = 0
var _sfx_bus_idx: int = 0
var _ui_bus_idx: int = 0


func _ready() -> void:
	_sfx_bus_idx = _resolve_bus_index(BUS_SFX)
	_ui_bus_idx = _resolve_bus_index(BUS_UI)
	_load_streams()
	_build_pool()
	set_sound_enabled(SaveManager.sound_enabled)


func _resolve_bus_index(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		push_warning("AudioManager: audio bus '%s' not found, falling back to Master." % bus_name)
		return AudioServer.get_bus_index("Master")
	return idx


## Part 24 (missing-resource safety): a missing/corrupt file is logged once
## here and its event key is simply absent from _streams - _play() then
## no-ops for that key instead of crashing anything downstream. Uses
## runtime load(), not preload(), specifically so one bad file can never
## take down every other sound (or the whole script).
func _load_streams() -> void:
	for key in SFX_TABLE:
		var path: String = SFX_DIR + String(SFX_TABLE[key]["file"])
		if not ResourceLoader.exists(path):
			push_warning("AudioManager: missing SFX resource for '%s': %s" % [key, path])
			continue
		var stream: AudioStream = load(path)
		if stream == null:
			push_warning("AudioManager: failed to load SFX resource for '%s': %s" % [key, path])
			continue
		_streams[key] = stream


func _build_pool() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		add_child(player)
		_pool.append(player)


## Part 25/29: the ONE mute switch this pass's Settings screen exposes
## (the existing Sound toggle - see settings_menu.gd). Mutes both SFX and
## UI buses together; Master/per-bus volume sliders don't exist in the
## current UI (see AUDIO_SYSTEM.md "Settings integration" for why this
## wasn't redesigned) but set_sfx_volume_linear() below still provides a
## real, testable granular control for a future slider.
func set_sound_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(_sfx_bus_idx, not enabled)
	AudioServer.set_bus_mute(_ui_bus_idx, not enabled)


## Granular volume control (0.0-1.0) for both gameplay-audible buses -
## exists for a future volume slider and for direct QA verification of the
## 100/50/0% cases (Part 29 of the audio brief); not currently wired to any
## UI control, since the existing Settings screen only has an ON/OFF Sound
## toggle (see set_sound_enabled()).
func set_sfx_volume_linear(volume: float) -> void:
	var db := linear_to_db(clampf(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(_sfx_bus_idx, db)
	AudioServer.set_bus_volume_db(_ui_bus_idx, db)


func _play(key: String) -> void:
	if not _streams.has(key):
		return
	var config: Dictionary = SFX_TABLE[key]
	var player: AudioStreamPlayer = _pool[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % _pool.size()
	player.stream = _streams[key]
	player.bus = config["bus"]
	player.volume_db = config["gain_db"]
	player.play()


## --- Semantic UI events -----------------------------------------------

func play_ui_button_press() -> void:
	_play("ui_button_press")


func play_ui_back() -> void:
	_play("ui_back")


func play_ui_level_select() -> void:
	_play("ui_level_select")


## Registered and playable, but not currently called anywhere - Godot's
## disabled Button intercepts no input at all (no `pressed` signal, no
## _gui_input), so there is no real "player tapped a locked level/tutorial
## card" event to hook without artificially enabling a disabled button
## just to catch the tap (explicitly against the brief's own Part 11
## guidance). Kept wired for any future locked-but-tappable UI element.
func play_ui_locked() -> void:
	_play("ui_locked")


func play_ui_popup() -> void:
	_play("ui_popup")


## --- Semantic gameplay events -------------------------------------------

func play_mirror_rotate() -> void:
	_play("mirror_rotate")


func play_mirror_locked() -> void:
	_play("mirror_locked")


## Era 2 reuse: also played for a Remote Emitter's inactive -> active
## transition (see grid_manager.gd) - see AUDIO_SYSTEM.md "Era 2 mapping".
func play_laser_activate() -> void:
	_play("laser_activate")


func play_laser_reflect() -> void:
	_play("laser_reflect")


## Era 2 reuse: also played for a Prism channel split - see
## AUDIO_SYSTEM.md "Era 2 mapping".
func play_laser_split() -> void:
	_play("laser_split")


func play_target_activate() -> void:
	_play("target_activate")


## Registered and playable, but not currently called - LaserSystem has no
## "wrong-color beam reached this target" signal, only "did the beam that
## reached it match" (folded into activated_targets). See AUDIO_SYSTEM.md.
func play_target_wrong() -> void:
	_play("target_wrong")


func play_filter_pass() -> void:
	_play("filter_pass")


func play_portal_enter() -> void:
	_play("portal_enter")


func play_portal_exit() -> void:
	_play("portal_exit")


## Era 2 reuse: also played for a Beam Receiver hit - see
## AUDIO_SYSTEM.md "Era 2 mapping".
func play_switch_activate() -> void:
	_play("switch_activate")


func play_gate_open() -> void:
	_play("gate_open")


func play_hazard_hit() -> void:
	_play("hazard_hit")


func play_puzzle_solved() -> void:
	_play("puzzle_solved")


func play_level_complete() -> void:
	_play("level_complete")


## Registered and playable, but not currently called - LevelCompletePopup
## reveals all 3 star icons at once (show_result()), never one at a time,
## so there is no real per-star reveal event to hook. See
## AUDIO_SYSTEM.md.
func play_star_appear() -> void:
	_play("star_appear")


func play_tutorial_step() -> void:
	_play("tutorial_step")
