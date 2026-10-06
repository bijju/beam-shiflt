class_name HSliceTexture
extends Control
## Draws a wide ornamental frame at a fixed uniform scale (height-driven) with only its plain middle stretched,
## so the end caps never distort. `src_y`/`src_h` crop the vertical glow padding. With `arrange_columns`, the
## first three Control children become the left cap / middle / right cap columns, which keeps text aligned to
## the dividers baked into the art. Presentation only, never takes input.

@export var texture: Texture2D
@export var cap_src := 700.0
@export var src_y := 0.0
@export var src_h := 0.0
@export var arrange_columns := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_arrange)
	_arrange()


func _scale() -> float:
	var h: float = src_h
	if h <= 0.0:
		h = float(texture.get_height()) if texture != null else 1.0
	return size.y / h


func _draw() -> void:
	if texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var tw := float(texture.get_width())
	var h: float = src_h if src_h > 0.0 else float(texture.get_height())
	var cap := minf(cap_src, tw * 0.5 - 1.0)
	var cap_w := minf(cap * _scale(), size.x * 0.5)
	draw_texture_rect_region(texture, Rect2(0, 0, cap_w, size.y), Rect2(0, src_y, cap, h))
	draw_texture_rect_region(texture, Rect2(cap_w, 0, size.x - cap_w * 2.0, size.y), Rect2(cap, src_y, tw - cap * 2.0, h))
	draw_texture_rect_region(texture, Rect2(size.x - cap_w, 0, cap_w, size.y), Rect2(tw - cap, src_y, cap, h))


func _arrange() -> void:
	queue_redraw()
	if not arrange_columns or texture == null:
		return
	var cols: Array[Control] = []
	for c in get_children():
		if c is Control:
			cols.append(c)
	if cols.size() < 3:
		return
	var cap_w := minf(minf(cap_src, texture.get_width() * 0.5 - 1.0) * _scale(), size.x * 0.5)
	cols[0].position = Vector2.ZERO
	cols[0].size = Vector2(cap_w, size.y)
	cols[1].position = Vector2(cap_w, 0)
	cols[1].size = Vector2(maxf(size.x - cap_w * 2.0, 0.0), size.y)
	cols[2].position = Vector2(size.x - cap_w, 0)
	cols[2].size = Vector2(cap_w, size.y)
