class_name PhaseShifterTile
extends TileVisual
## Phase Shifter visual (Phase Shifter Stage A). PURELY presentational: LaserSystem owns the phase
## simulation; GridManager copies the END-OF-PASS phase and interaction count onto this tile after
## every simulation. Tap-to-rotate is the standard two-state mirror toggle (one tap = one move).
##
## Display convention (documented in DECISIONS/ARCHITECTURE): the core shows the behaviour the NEXT
## beam entering the tile would get at the end of the current simulation - PHASE_A (straight) when no
## beam touched it or it was touched an even number of times, PHASE_B (reflect) after an odd number.
## A fresh simulation (any move, Reset, load) always starts every tile in PHASE_A again, so an untouched
## tile always reads PHASE_A. The diagonal glyph always shows the selected Phase-B reflection ("/" or "\"),
## brighter while the tile is in PHASE_B.
##
## Layers, back to front: BASE frame, CORE (phase A or B art), orientation glyph, ENERGY RING (pulse only).

signal tile_clicked(grid_position: Vector2i)

const BASE_TEXTURE := preload("res://assets/gameplay/phase_shifter/bs_phase_shifter_base.png")
const CORE_A_TEXTURE := preload("res://assets/gameplay/phase_shifter/bs_phase_shifter_core_phase_a.png")
const CORE_B_TEXTURE := preload("res://assets/gameplay/phase_shifter/bs_phase_shifter_core_phase_b.png")
const RING_TEXTURE := preload("res://assets/gameplay/phase_shifter/bs_phase_shifter_energy_ring.png")
const LOCK_ICON_TEXTURE := preload("res://assets/ui/icons/bs_ui_icon_lock_runtime.png")

const INSET := 0.04 # fraction of the cell left empty on every side
const CORE_SCALE := 0.72 # core art relative to the base frame (its disc fills the base's round opening)
const RING_PULSE_SECONDS := 0.35
const TINT_FIXED := Color(0.72, 0.72, 0.76, 1)
const GLYPH_COLOR := Color(0.55, 0.95, 1.0)

var orientation: GridTypes.MirrorOrientation = GridTypes.MirrorOrientation.SLASH:
	set(value):
		orientation = value
		queue_redraw()

var rotatable: bool = true:
	set(value):
		rotatable = value
		queue_redraw()

## End-of-pass phase (GridTypes.PHASE_A / PHASE_B).
var phase: int = GridTypes.PHASE_A:
	set(value):
		phase = value
		queue_redraw()

## Beam interactions in the last pass (0 = untouched this simulation).
var hits: int = 0:
	set(value):
		hits = value
		queue_redraw()

var _ring_alpha: float = 0.0:
	set(value):
		_ring_alpha = value
		queue_redraw()
var _ring_tween: Tween


## Called by GridManager after a simulation. `pulse` is true only for a player-made move.
func apply_result(final_phase: int, hit_count: int, pulse: bool) -> void:
	var changed := hit_count != hits or final_phase != phase
	phase = final_phase
	hits = hit_count
	if pulse and changed and hit_count > 0:
		_play_pulse()


func _play_pulse() -> void:
	if _ring_tween != null and _ring_tween.is_valid():
		_ring_tween.kill()
	_ring_alpha = 0.9
	_ring_tween = create_tween()
	_ring_tween.tween_property(self, "_ring_alpha", 0.0, RING_PULSE_SECONDS)


func _fit_rect(tex: Texture2D, box: float) -> Rect2:
	var tsize := tex.get_size()
	var scale_f := box / maxf(tsize.x, tsize.y)
	var drawn := tsize * scale_f
	var half := Vector2(cell_size, cell_size) * 0.5
	return Rect2(half - drawn * 0.5, drawn)


func _draw() -> void:
	super._draw()
	var s := cell_size
	var box := s * (1.0 - INSET * 2.0)
	var tint := Color.WHITE if rotatable else TINT_FIXED
	draw_texture_rect(BASE_TEXTURE, _fit_rect(BASE_TEXTURE, box), false, tint)
	var core: Texture2D = CORE_B_TEXTURE if phase == GridTypes.PHASE_B else CORE_A_TEXTURE
	draw_texture_rect(core, _fit_rect(core, box * CORE_SCALE), false, tint)
	_draw_orientation_glyph()
	if _ring_alpha > 0.01:
		draw_texture_rect(RING_TEXTURE, _fit_rect(RING_TEXTURE, box * (1.0 + 0.12 * (1.0 - _ring_alpha))), false, Color(1, 1, 1, _ring_alpha))
	if not rotatable:
		var lock_size := s * 0.26
		draw_texture_rect(LOCK_ICON_TEXTURE, Rect2(Vector2(s, s) - Vector2(lock_size, lock_size) * 1.05, Vector2(lock_size, lock_size)), false)


## The selected Phase-B reflection as a thin diagonal across the core: "/" or "\".
func _draw_orientation_glyph() -> void:
	var c := Vector2(cell_size, cell_size) * 0.5
	var arm := cell_size * 0.30
	var dir := Vector2(1, -1) if orientation == GridTypes.MirrorOrientation.SLASH else Vector2(1, 1)
	dir = dir.normalized()
	var alpha := 0.95 if phase == GridTypes.PHASE_B else 0.6
	var col := Color(GLYPH_COLOR.r, GLYPH_COLOR.g, GLYPH_COLOR.b, alpha)
	draw_line(c - dir * arm, c + dir * arm, Color(0, 0.1, 0.2, alpha * 0.8), maxf(cell_size * 0.075, 3.0))
	draw_line(c - dir * arm, c + dir * arm, col, maxf(cell_size * 0.04, 2.0))


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not rotatable:
		accept_event()
		AudioManager.play_mirror_locked()
		return
	accept_event()
	tile_clicked.emit(grid_position)
