class_name Era2ActivationFX
extends Node2D
## One-shot cosmetic burst for Era 2 mechanic activation (Prism split,
## One-Way Reflector reflective hit, Beam Receiver powered, Remote
## Emitter firing) - same architecture as LaserMirrorImpactFX (CLAUDE.md
## rule 14: a new pass following that pattern, not a tweak to it). Purely
## visual: GridManager decides when/where to spawn it from the
## ALREADY-computed simulation result; this node never reads or writes
## gameplay state, is input-transparent, self-freeing, and bounded by
## GridManager's existing IMPACT_FX_MAX_COUNT cap (shared with mirror
## impacts - both live under the same _impact_root container).

enum Kind { PRISM, ONE_WAY_REFLECTOR, RECEIVER, REMOTE_EMITTER }

const DURATION := 0.3
const RING_START_RADIUS := 0.1
const RING_END_RADIUS := 0.42
const FLASH_FRACTION := 0.4

## Era 2's violet/magenta accent palette (ERA_2_DESIGN.md "visual
## language") - deliberately distinct from LaserMirrorImpactFX's cyan
## Era-1 accent, so an Era 2 activation reads as a different kind of
## event even at a glance.
const VIOLET := Color(0.55, 0.3, 0.95)
const MAGENTA_ACCENT := Color(0.85, 0.45, 1.0)

var cell_size: float = 64.0
var kind: Kind = Kind.PRISM
## Only meaningful for Kind.REMOTE_EMITTER (the one beam it fires has a
## single well-defined color). Prism activation deliberately always uses
## the neutral violet accent instead of one channel's color - a Prism
## event means "multiple colors emerged," and any one channel's color
## would misrepresent that. Ignored for One-Way Reflector/Receiver too.
var beam_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE

var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

var _ring_color: Color


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

	_ring_color = _pick_ring_color()

	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, DURATION)
	tween.tween_callback(queue_free)


func _pick_ring_color() -> Color:
	if kind == Kind.REMOTE_EMITTER:
		return GridTypes.beam_color_to_render_color(beam_color)
	return VIOLET


func _draw() -> void:
	var t := progress
	var out_t := 1.0 - pow(1.0 - t, 3.0)

	_draw_flash(t)
	_draw_ring(t, out_t)


func _draw_flash(t: float) -> void:
	var life := clampf(1.0 - t / FLASH_FRACTION, 0.0, 1.0)
	if life <= 0.0:
		return
	var a := life * life
	var radius := cell_size * 0.16
	var core := _ring_color.lerp(Color.WHITE, 0.6)
	draw_circle(Vector2.ZERO, radius, Color(core.r, core.g, core.b, 0.55 * a))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(1, 1, 1, 0.85 * a))


func _draw_ring(t: float, out_t: float) -> void:
	var alpha := pow(1.0 - t, 1.2)
	if alpha <= 0.01:
		return
	var radius := cell_size * lerpf(RING_START_RADIUS, RING_END_RADIUS, out_t)
	var width := maxf(2.0, cell_size * lerpf(0.06, 0.015, t))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(_ring_color.r, _ring_color.g, _ring_color.b, alpha), width, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(MAGENTA_ACCENT.r, MAGENTA_ACCENT.g, MAGENTA_ACCENT.b, alpha * 0.35), width * 2.2, true)
