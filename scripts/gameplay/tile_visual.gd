class_name TileVisual
extends Control
## Shared base for all tile visuals. Draws the common cell background art
## (Milestone 4A final asset) first, so every subclass's own content -
## whether final-art sprite children or a still-procedural _draw()
## override for mechanics without clean beam-free source art yet, see
## ARCHITECTURE.md "Gameplay tile visuals" - renders on top of it.
## grid_manager.gd owns all authoritative gameplay state; this class and
## its subclasses are purely presentational.

const DEFAULT_CELL_BACKGROUND_TEXTURE := preload("res://assets/gameplay/grid/bs_tile_grid_base_runtime.png")

## Era 2: GridManager.load_level() sets this once per level load, from
## EraTheme.for_era(...).grid_cell_empty when the level belongs to Era 2,
## or resets it to DEFAULT_CELL_BACKGROUND_TEXTURE for Era 1 - see
## ERA_2_DESIGN.md "Era visual theme". A static class member (not an
## instance field) so every existing tile subclass's `super._draw()` call
## picks up the active era's cell art with zero per-subclass changes.
static var active_cell_background: Texture2D = DEFAULT_CELL_BACKGROUND_TEXTURE

var grid_position: Vector2i = Vector2i.ZERO

var cell_size: float = 64.0:
	set(value):
		cell_size = value
		custom_minimum_size = Vector2(value, value)
		size = Vector2(value, value)
		_on_cell_size_changed()
		queue_redraw()


## Subclasses that own their own sprite children override this to resize/
## reposition them whenever cell_size changes.
func _on_cell_size_changed() -> void:
	pass


## Subclasses that still draw procedurally MUST call super._draw() first so
## the shared cell background renders underneath their own content. A
## subclass using sprite children instead doesn't need to override this at
## all - the background alone is exactly what should show behind them.
func _draw() -> void:
	draw_texture_rect(active_cell_background, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false)
