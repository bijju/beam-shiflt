class_name HazardTile
extends TileVisual
## Hazard visual. If a beam touches this cell, the level cannot be solved
## (see LaserSystem's hazard_hit rule) but play is NOT interrupted - the
## player can keep rotating tiles to route around it. triggered is set by
## GridManager after each simulate call. Milestone 4A: uses the final
## beam-free hazard icon art, tinted brighter red when triggered (no
## separate triggered-state art exists yet - see ARCHITECTURE.md).
##
## The canonical art lives in its own per-type folder (assets/gameplay/
## hazard/), matching every other tile type - NOT assets/gameplay/pieces/,
## which is entirely excluded from the Android export filter
## (export_presets.cfg) as the unused duplicate-art set (see DECISIONS.md
## D31). See blocker.gd for the full explanation - same bug, same fix,
## see DECISIONS.md D51. Never point this at assets/gameplay/pieces/ again.
const HAZARD_TEXTURE := preload("res://assets/gameplay/hazard/bs_tile_hazard_runtime.png")

var triggered: bool = false:
	set(value):
		triggered = value
		queue_redraw()

const TINT_NORMAL := Color(1, 1, 1, 1)
const TINT_TRIGGERED := Color(1.5, 0.45, 0.4, 1)


func _draw() -> void:
	super._draw()
	var tint := TINT_TRIGGERED if triggered else TINT_NORMAL
	draw_texture_rect(HAZARD_TEXTURE, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false, tint)
