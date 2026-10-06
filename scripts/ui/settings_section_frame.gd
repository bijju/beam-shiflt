class_name SettingsSectionFrame
extends PanelContainer
## Settings section frame (settings_section_panel.png) drawn as a NinePatchRect at FRAME_SCALE.
## NinePatch margins draw at source size, so the patch is laid out at 1/FRAME_SCALE and scaled down
## to keep the metal corners and the header strip unstretched at any panel width/height.

const FRAME := preload("res://assets/ui/settings/settings_section_panel.png")
const FRAME_SCALE := 0.4
# Source-pixel patch margins: corner ornaments + header strip (top), corner ornaments (bottom/sides).
const PATCH := Vector4(190, 310, 190, 290)
# Transparent source padding around the visible frame, so the visible edge lands on the panel edge.
const PAD := Vector4(50, 85, 50, 97)

var frame: NinePatchRect

var _holder: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_holder = Control.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	move_child(_holder, 0)
	frame = NinePatchRect.new()
	frame.name = "Frame"
	frame.texture = FRAME
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.patch_margin_left = int(PATCH.x)
	frame.patch_margin_top = int(PATCH.y)
	frame.patch_margin_right = int(PATCH.z)
	frame.patch_margin_bottom = int(PATCH.w)
	frame.scale = Vector2.ONE * FRAME_SCALE
	_holder.add_child(frame)
	_holder.resized.connect(_layout_frame)
	_layout_frame()


func _layout_frame() -> void:
	frame.position = Vector2(-PAD.x, -PAD.y) * FRAME_SCALE
	frame.size = _holder.size / FRAME_SCALE + Vector2(PAD.x + PAD.z, PAD.y + PAD.w)
