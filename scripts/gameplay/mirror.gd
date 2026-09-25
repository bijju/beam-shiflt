class_name MirrorTile
extends TileVisual
## Rotatable/fixed mirror tile. This node only renders and reports taps -
## grid_manager.gd is the authoritative owner of mirror orientation state.
##
## Milestone 4A: the source mirror art has no baked beam (its diagonal
## glass bar is self-illuminated, not an illustrative beam-in-flight), so
## it's safe to use directly. Both orientations come from one texture via
## a 90-degree rotation rather than two separate images - see ARCHITECTURE.md.

signal tile_clicked(grid_position: Vector2i)

const MIRROR_TEXTURE := preload("res://assets/gameplay/mirror/bs_tile_mirror_runtime.png")
const LOCK_ICON_TEXTURE := preload("res://assets/ui/icons/bs_ui_icon_lock_runtime.png")
const SELECTION_FX_TEXTURE := preload("res://assets/gameplay/effects/bs_fx_mirror_selection_runtime.png")

var orientation: GridTypes.MirrorOrientation = GridTypes.MirrorOrientation.SLASH:
	set(value):
		orientation = value
		queue_redraw()

var rotatable: bool = true:
	set(value):
		rotatable = value
		queue_redraw()

const TINT_ROTATABLE := Color(1, 1, 1, 1)
const TINT_FIXED := Color(0.72, 0.72, 0.76, 1)

var _fx: TextureRect


func _ready() -> void:
	_fx = TextureRect.new()
	_fx.texture = SELECTION_FX_TEXTURE
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


## Brief tap feedback pulse - purely cosmetic, no gameplay state involved.
func _play_selection_pulse() -> void:
	_fx.scale = Vector2(0.7, 0.7)
	_fx.modulate = Color(1, 1, 1, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_fx, "scale", Vector2(1.15, 1.15), 0.25)
	tween.tween_property(_fx, "modulate:a", 0.0, 0.25)


func _draw() -> void:
	super._draw()
	var half := Vector2(cell_size, cell_size) * 0.5
	# Source art's diagonal renders as SLASH ("/", bottom-left to top-right)
	# at 0 rotation - confirmed by viewing the actual PNG (Milestone 4A.2;
	# Milestone 4A had this backwards, see DECISIONS.md D40). BACKSLASH is
	# the same bar rotated 90 degrees. This mapping is purely cosmetic and
	# never affects GridTypes.reflect()'s actual simulation result - but a
	# wrong mapping here makes the mirror's own drawn diagonal contradict
	# the real (correctly rendered) beam, which is confusing enough to make
	# a solvable level look broken to a player relying on the glyph.
	var angle := 0.0 if orientation == GridTypes.MirrorOrientation.SLASH else PI * 0.5
	draw_set_transform(half, angle, Vector2.ONE)
	var tint := TINT_ROTATABLE if rotatable else TINT_FIXED
	draw_texture_rect(MIRROR_TEXTURE, Rect2(-half, Vector2(cell_size, cell_size)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if not rotatable:
		var lock_size := cell_size * 0.3
		var lock_pos := Vector2(cell_size, cell_size) - lock_size * Vector2(1.05, 1.05)
		draw_texture_rect(LOCK_ICON_TEXTURE, Rect2(lock_pos, Vector2(lock_size, lock_size)), false)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not rotatable:
		accept_event()
		AudioManager.play_mirror_locked()
		return
	accept_event()
	_play_selection_pulse()
	tile_clicked.emit(grid_position)
