class_name LevelCompleteFx
extends Node2D
## One-shot, self-freeing cosmetic effect for the Level Complete celebration (impact ring + flash, spark burst,
## light sweep). Procedurally drawn, additive, input-transparent; reads nothing from gameplay.

enum Kind { RING, SPARKS, SWEEP }

const GOLD := Color(1.0, 0.78, 0.25)
const CYAN := Color(0.3, 0.88, 1.0)

var kind: int = Kind.RING
var radius := 100.0
var area := Vector2(900, 240)
var seed_offset := 0.0
var t := 0.0:
	set(v):
		t = v
		queue_redraw()


static func spawn(parent: Control, p_kind: int, pos: Vector2, p_radius: float, duration: float, p_area := Vector2.ZERO, p_seed := 0.0) -> LevelCompleteFx:
	var fx := LevelCompleteFx.new()
	fx.kind = p_kind
	fx.radius = p_radius
	fx.seed_offset = p_seed
	if p_area != Vector2.ZERO:
		fx.area = p_area
	fx.position = pos
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = mat
	parent.add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "t", 1.0, duration)
	tw.tween_callback(fx.queue_free)
	return fx


func _draw() -> void:
	match kind:
		Kind.RING: _draw_ring()
		Kind.SPARKS: _draw_sparks()
		Kind.SWEEP: _draw_sweep()


func _draw_ring() -> void:
	var inv := 1.0 - t
	draw_circle(Vector2.ZERO, radius * (0.55 + 0.35 * t), Color(GOLD, 0.35 * inv * inv))
	draw_arc(Vector2.ZERO, radius * (0.45 + 1.0 * t), 0.0, TAU, 48, Color(GOLD, inv * inv), 3.0 + 7.0 * inv)
	draw_arc(Vector2.ZERO, radius * (0.4 + 1.25 * t), 0.0, TAU, 48, Color(CYAN, 0.7 * inv * inv), 2.0 + 3.0 * inv)


func _draw_sparks() -> void:
	var inv := 1.0 - t
	for i in 12:
		var a := TAU * i / 12.0 + seed_offset
		var reach := radius * (0.7 + 0.8 * t) * (1.0 if i % 2 == 0 else 0.75)
		var len := radius * 0.28 * inv
		var dir := Vector2.from_angle(a)
		draw_line(dir * reach, dir * (reach + len), Color(GOLD if i % 3 != 0 else CYAN, inv), 4.0 * inv + 1.0)


func _draw_sweep() -> void:
	var x := lerpf(-area.x * 0.15, area.x * 1.15, t)
	var a := sin(t * PI) * 0.4
	var skew := area.y * 0.35
	for band in [[-70.0, 0.0, 0.0, a], [0.0, 70.0, a, 0.0]]:
		var x0: float = x + band[0]
		var x1: float = x + band[1]
		draw_polygon(
			PackedVector2Array([Vector2(x0 - skew, area.y), Vector2(x0, 0), Vector2(x1, 0), Vector2(x1 - skew, area.y)]),
			PackedColorArray([Color(GOLD, band[2]), Color(GOLD, band[2]), Color(GOLD, band[3]), Color(GOLD, band[3])]))
