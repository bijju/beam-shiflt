class_name AspectArtButton
extends Button
## Full-width primary button used by the tutorial UI. Kept as a class (scenes/tests reference it) but
## the redesign dropped the aspect-locked art: it now simply fills its row at `button_height` and takes
## its look from the shared BeamUI theme.

@export var button_height: float = 96.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, button_height)
	size_flags_horizontal = Control.SIZE_FILL
