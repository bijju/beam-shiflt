extends Control
## Milestone 4A.1: Sound/Music toggles are custom toggle-mode Buttons
## showing the wide bs_ui_toggle_on/off.png switch art (which bakes in its
## own "ON"/"OFF" text) rather than a CheckButton with a tiny icon
## override - the source art is a wide pill graphic, not a small checkbox
## glyph. See ARCHITECTURE.md "Settings" and DECISIONS.md D37.

const TEXTURE_TOGGLE_ON := preload("res://assets/ui/settings/bs_ui_toggle_on_runtime.png")
const TEXTURE_TOGGLE_OFF := preload("res://assets/ui/settings/bs_ui_toggle_off_runtime.png")

@onready var _sound_toggle: Button = %SoundToggle
@onready var _sound_toggle_icon: TextureRect = %SoundToggleIcon
@onready var _music_toggle: Button = %MusicToggle
@onready var _music_toggle_icon: TextureRect = %MusicToggleIcon
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_sound_toggle.button_pressed = SaveManager.sound_enabled
	_music_toggle.button_pressed = SaveManager.music_enabled
	_update_toggle_icon(_sound_toggle_icon, _sound_toggle.button_pressed)
	_update_toggle_icon(_music_toggle_icon, _music_toggle.button_pressed)

	_sound_toggle.toggled.connect(_on_sound_toggled)
	_music_toggle.toggled.connect(_on_music_toggled)
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	_back_button.pressed.connect(AudioManager.play_ui_back)


func _on_sound_toggled(enabled: bool) -> void:
	SaveManager.sound_enabled = enabled
	SaveManager.save_game()
	AudioManager.set_sound_enabled(enabled)
	_update_toggle_icon(_sound_toggle_icon, enabled)


func _on_music_toggled(enabled: bool) -> void:
	SaveManager.music_enabled = enabled
	SaveManager.save_game()
	_update_toggle_icon(_music_toggle_icon, enabled)


func _update_toggle_icon(icon: TextureRect, enabled: bool) -> void:
	icon.texture = TEXTURE_TOGGLE_ON if enabled else TEXTURE_TOGGLE_OFF


## project.godot's quit_on_go_back=false means every top-level screen
## must replicate its own Back button's behavior for the system Back
## gesture/button itself - see main_menu.gd's _notification().
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.go_to_main_menu()
