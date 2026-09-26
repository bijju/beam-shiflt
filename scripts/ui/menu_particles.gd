extends GPUParticles2D
## Main Menu ambience: keeps the emission box matched to the parent Control's rect
## (event-driven via `resized`, no per-frame work) so it covers any portrait aspect.


func _ready() -> void:
	var host := get_parent() as Control
	host.resized.connect(_fit.bind(host))
	_fit(host)


func _fit(host: Control) -> void:
	var size := host.size
	position = size * 0.5
	var mat := process_material as ParticleProcessMaterial
	mat.emission_box_extents = Vector3(size.x * 0.5, size.y * 0.5, 1.0)
	visibility_rect = Rect2(-size * 0.6, size * 1.2)
