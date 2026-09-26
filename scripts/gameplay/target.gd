class_name TargetTile
extends TileVisual
## Target visual. activated toggles when the laser reaches it with an
## accepted color (see GridTypes.target_accepts_color()). Milestone 4A:
## uses the final beam-free target reticle art, tinted red/green for
## inactive/active and dimmed for optional targets; the required-color
## ring stays a procedural overlay since it's per-level, per-color data
## with no fixed-color art equivalent.

const TARGET_TEXTURE := preload("res://assets/gameplay/target/bs_tile_target_runtime.png")
const ACTIVATED_FX_TEXTURE := preload("res://assets/gameplay/effects/bs_fx_target_activated_runtime.png")

var activated: bool = false:
	set(value):
		var was_active := activated
		activated = value
		queue_redraw()
		if activated and not was_active and _fx:
			_play_activation_pulse()

## WHITE (the Milestone 1 default / "neutral") renders exactly as before -
## no extra ring - so existing levels are visually unchanged. A non-WHITE
## required_color adds a thin colored ring so the player can see which
## beam color this target needs.
var required_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE:
	set(value):
		required_color = value
		queue_redraw()

## Optional targets (required = false) are drawn slightly dimmer so the
## player can tell them apart from required ones at a glance.
var required: bool = true:
	set(value):
		required = value
		queue_redraw()

const TINT_INACTIVE := Color(0.85, 0.55, 0.55, 1)
const TINT_ACTIVE := Color(0.65, 1.25, 0.75, 1)

var _fx: TextureRect


func _ready() -> void:
	_fx = TextureRect.new()
	_fx.texture = ACTIVATED_FX_TEXTURE
	_fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fx.stretch_mode = TextureRect.STRETCH_SCALE
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.modulate = Color(1, 1, 1, 0)
	_fx.size = Vector2(cell_size, cell_size)
	_fx.pivot_offset = Vector2(cell_size, cell_size) * 0.5
	add_child(_fx)


func _on_cell_size_changed() -> void:
	if _fx:
		_fx.size = Vector2(cell_size, cell_size)
		_fx.pivot_offset = Vector2(cell_size, cell_size) * 0.5


## Brief feedback pulse the moment a target transitions to activated -
## purely cosmetic, driven by GridManager's simulation result, never a
## source of gameplay state itself.
func _play_activation_pulse() -> void:
	_fx.scale = Vector2(0.6, 0.6)
	_fx.modulate = Color(1, 1, 1, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_fx, "scale", Vector2(1.3, 1.3), 0.35)
	tween.tween_property(_fx, "modulate:a", 0.0, 0.35)


func _draw() -> void:
	super._draw()
	var tint := TINT_ACTIVE if activated else TINT_INACTIVE
	tint.a = 1.0 if required else 0.55
	draw_texture_rect(TARGET_TEXTURE, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false, tint)

	if required_color != GridTypes.BeamColor.WHITE:
		var ring_color := GridTypes.beam_color_to_render_color(required_color)
		var center := Vector2(cell_size, cell_size) * 0.5
		draw_arc(center, cell_size * 0.47, 0, TAU, 28, ring_color, 3.0, true)
