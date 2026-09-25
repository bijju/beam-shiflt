class_name AspectBar
extends Control
## Keeps a full-width decorative HUD bar's height locked to its source
## art's aspect ratio on every resize, so bs_hud_top/bottom_portrait.png
## (Milestone 4A.4) never gets stretched/distorted. Mirrors the same
## resize-driven recompute pattern grid_manager.gd already uses for its
## own square-cell layout - see CLAUDE.md's responsive rules (no fixed
## pixel layout for gameplay/menu elements).

@export var aspect_ratio: float = 1.0 ## source texture width / height


func _ready() -> void:
	resized.connect(_update_height)
	_update_height()


## Era 2: game.gd calls this when swapping in a themed HUD bar texture
## whose own aspect ratio differs from Era 1's - see EraTheme.hud_aspect_ratio.
func set_aspect_ratio(ratio: float) -> void:
	aspect_ratio = ratio
	_update_height()


func _update_height() -> void:
	if size.x <= 0.0:
		return
	var target_height := size.x / aspect_ratio
	if not is_equal_approx(custom_minimum_size.y, target_height):
		custom_minimum_size.y = target_height
