class_name PrismTile
extends TileVisual
## Prism visual (Era 2). Never rotatable, never player-interactive - see
## GridTypes.prism_output_direction() for the deterministic WHITE ->
## RED+GREEN+BLUE / colored -> same-channel-only rule this tile enacts in
## LaserSystem. Uses the confirmed beam-free "_base" source art (see
## CLAUDE.md rule 10 / ERA_2_DESIGN.md) - the non-"_base" reference art
## bakes a fixed white-in/RGB-out beam and must never be loaded here.

const PRISM_TEXTURE := preload("res://assets/gameplay/prism/bs_tile_prism_base_era2.png")


func _draw() -> void:
	super._draw()
	draw_texture_rect(PRISM_TEXTURE, Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), false)
