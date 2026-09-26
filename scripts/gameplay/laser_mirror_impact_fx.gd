class_name LaserMirrorImpactFX
extends Node2D
## One-shot cosmetic burst played where a beam reflects off a mirror: a
## soft contact flash, an expanding ring and a few sparks. Purely visual -
## it never reads or writes puzzle state, and GridManager (the only
## caller) decides when and where to spawn it from the ALREADY-computed
## simulation result. See ARCHITECTURE.md ("Mirror impact VFX").
##
## Everything is procedural in one _draw() (no particle nodes, no textures,
## no lights): one CanvasItem + one Tween per impact keeps it cheap on
## mobile and avoids GPUParticles' first-use shader-compile hitch. The
## node frees itself when the tween finishes.

const DURATION := 0.32
const SPARK_COUNT := 5

## All sizes are fractions of one grid cell so the burst scales with the
## board. Largest extent (spark tips) is ~0.5 of a cell across, small
## enough not to hide the mirror, neighbours or the beam itself.
const FLASH_RADIUS := 0.17
const RING_START_RADIUS := 0.07
const RING_END_RADIUS := 0.21
const SPARK_MIN_TRAVEL := 0.19
const SPARK_MAX_TRAVEL := 0.27
const SPARK_STREAK := 0.11
## Fraction of DURATION over which the contact flash fades out (~0.11 s).
const FLASH_FRACTION := 0.35
## Half-angle of the spark spray around the reflected direction, radians.
const SPARK_SPREAD := 0.9

const CYAN := Color(0.55, 0.95, 1.0)

var cell_size: float = 64.0
var beam_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE
## Unit-axis direction the beam leaves the mirror in. Sparks spray around
## it so the burst reads as impact -> reflection. ZERO (e.g. a beam cut
## short by the loop guard right at the mirror) falls back to a radial burst.
var burst_direction: Vector2 = Vector2.ZERO

var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

var _primary: Color
var _accent: Color
var _ring: Color
var _sparks: Array = [] # {angle, travel, use_accent}


func _ready() -> void:
	# Additive blending gives the glow look without a shader.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

	_pick_palette()
	_roll_sparks()

	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, DURATION)
	tween.tween_callback(queue_free)


## Colors follow the real BeamColor mapping (GridTypes.beam_color_to_render_color),
## each with a contrasting highlight: WHITE -> white/cyan, BLUE -> blue/cyan,
## RED and GREEN -> their color/white.
func _pick_palette() -> void:
	var base := GridTypes.beam_color_to_render_color(beam_color)
	match beam_color:
		GridTypes.BeamColor.WHITE:
			_primary = base.lerp(Color.WHITE, 0.7)
			_accent = CYAN
			_ring = CYAN
		GridTypes.BeamColor.BLUE:
			_primary = base
			_accent = CYAN
			_ring = base
		_:
			_primary = base
			_accent = Color.WHITE
			_ring = base


func _roll_sparks() -> void:
	# Cosmetic jitter only - its own RNG, never touches anything gameplay-related.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var directed := burst_direction != Vector2.ZERO
	var base_angle := burst_direction.angle() if directed else rng.randf() * TAU
	for i in range(SPARK_COUNT):
		var angle: float
		if directed:
			var t := float(i) / float(SPARK_COUNT - 1)
			angle = base_angle + lerpf(-SPARK_SPREAD, SPARK_SPREAD, t)
		else:
			angle = base_angle + float(i) * TAU / float(SPARK_COUNT)
		angle += rng.randf_range(-0.12, 0.12)
		_sparks.append({
			"angle": angle,
			"travel": rng.randf_range(SPARK_MIN_TRAVEL, SPARK_MAX_TRAVEL) * cell_size,
			"use_accent": i % 2 == 0,
		})


func _draw() -> void:
	var t := progress
	var out_t := 1.0 - pow(1.0 - t, 3.0) # ease-out: fast start, settles

	_draw_flash(t)
	_draw_ring(t, out_t)
	_draw_sparks(t, out_t)


func _draw_flash(t: float) -> void:
	var life := clampf(1.0 - t / FLASH_FRACTION, 0.0, 1.0)
	if life <= 0.0:
		return
	var a := life * life
	var radius := cell_size * FLASH_RADIUS * lerpf(0.75, 1.15, t / FLASH_FRACTION)
	var core := _primary.lerp(Color.WHITE, 0.65)
	# Stacked translucent discs approximate a radial falloff; additive
	# blending sums them into a bright center.
	draw_circle(Vector2.ZERO, radius, Color(_primary.r, _primary.g, _primary.b, 0.16 * a))
	draw_circle(Vector2.ZERO, radius * 0.66, Color(_primary.r, _primary.g, _primary.b, 0.28 * a))
	draw_circle(Vector2.ZERO, radius * 0.38, Color(core.r, core.g, core.b, 0.6 * a))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(1, 1, 1, 0.9 * a))


func _draw_ring(t: float, out_t: float) -> void:
	var alpha := pow(1.0 - t, 1.3)
	if alpha <= 0.01:
		return
	var radius := cell_size * lerpf(RING_START_RADIUS, RING_END_RADIUS, out_t)
	var width := maxf(2.0, cell_size * lerpf(0.07, 0.02, t))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(_ring.r, _ring.g, _ring.b, alpha), width, true)
	# Soft wider halo so the ring holds up against the bright tile art.
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(_ring.r, _ring.g, _ring.b, alpha * 0.3), width * 2.4, true)


func _draw_sparks(t: float, out_t: float) -> void:
	var alpha := pow(1.0 - t, 1.1)
	if alpha <= 0.01:
		return
	var width := maxf(2.0, cell_size * 0.04)
	var streak := cell_size * SPARK_STREAK * (1.0 - t * 0.6)
	# Linear-ish travel for sparks (vs. the ring's ease-out) so they stay
	# visibly in motion for their whole life instead of hanging in place.
	var travel_t := lerpf(t, out_t, 0.5)
	for spark in _sparks:
		var dir := Vector2.from_angle(spark["angle"])
		var head: Vector2 = dir * (spark["travel"] * travel_t)
		var tail: Vector2 = dir * maxf(spark["travel"] * travel_t - streak, 0.0)
		var c: Color = _accent if spark["use_accent"] else _primary
		c.a = alpha
		draw_line(tail, head, c, width, true)
		draw_circle(head, width * 0.9, Color(1, 1, 1, alpha))
