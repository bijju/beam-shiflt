extends Control
## Startup studio splash (Studio Splash pass). Set as project.godot's
## run/main_scene. Plays the MaclePro logo
## then the 4Sagez logo, each fading in/hold/fading out, then hands off to
## Main Menu. Branding only - owns no
## gameplay/menu state and is never navigated back to once left (nothing
## else in the project references this scene's path).

const NEXT_SCENE_PATH := "res://scenes/ui/main_menu.tscn"

const FADE_DURATION := 0.35
const HOLD_DURATION := 1.4
const GAP_DURATION := 0.15
const SCALE_FROM := 0.97

@onready var maclepro_logo: TextureRect = %MacleProLogo
@onready var sagez_logo: TextureRect = %SagezLogo


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for logo in [maclepro_logo, sagez_logo]:
		logo.modulate.a = 0.0
		logo.pivot_offset = logo.size / 2.0
		logo.resized.connect(_on_logo_resized.bind(logo))
	_run_sequence()


func _on_logo_resized(logo: TextureRect) -> void:
	logo.pivot_offset = logo.size / 2.0


func _run_sequence() -> void:
	await _show_logo(maclepro_logo)
	await get_tree().create_timer(GAP_DURATION).timeout
	await _show_logo(sagez_logo)
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _show_logo(logo: TextureRect) -> void:
	logo.scale = Vector2(SCALE_FROM, SCALE_FROM)
	var tween_in := create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(logo, "modulate:a", 1.0, FADE_DURATION)
	tween_in.tween_property(logo, "scale", Vector2.ONE, FADE_DURATION)
	await tween_in.finished

	await get_tree().create_timer(HOLD_DURATION).timeout

	var tween_out := create_tween()
	tween_out.tween_property(logo, "modulate:a", 0.0, FADE_DURATION)
	await tween_out.finished


## project.godot sets quit_on_go_back=false project-wide (see
## game.gd/main_menu.gd's own identical handler) - without this override,
## Back would silently do nothing here, leaving the player stuck on a screen
## with no way to interact with or exit it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.quit_game()
