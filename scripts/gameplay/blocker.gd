class_name BlockerTile
extends TileVisual
## Blocker visual. Purely a beam-stopping obstacle - no interactive
## behavior, no simulation-driven state. Milestone 4A: uses the final
## beam-free blocker panel art directly, no tinting needed.
##
## The canonical art lives in its own per-type folder (assets/gameplay/
## blocker/), matching every other tile type - NOT assets/gameplay/pieces/,
## which is entirely excluded from the Android export filter
## (export_presets.cfg) as the unused duplicate-art set (see DECISIONS.md
## D31). Milestone "Android HUD Alignment + Missing Tile Fix" found this
## const had been left pointing at the excluded pieces/ copy since
## Milestone 4A, which made this script fail to parse in any exported
## build and silently broke every tile placed after a blocker in a
## level's tile array (see DECISIONS.md D51). Never point this at
## assets/gameplay/pieces/ again.
const BLOCKER_TEXTURE := preload("res://assets/gameplay/blocker/bs_tile_blocker_runtime.png")


func _draw() -> void:
	super._draw()
	draw_texture_rect(BLOCKER_TEXTURE, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false)
