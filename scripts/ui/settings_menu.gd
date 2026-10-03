extends Control
## Milestone 4A.1: Sound/Music toggles are custom toggle-mode Buttons
## showing the wide bs_ui_toggle_on/off.png switch art (which bakes in its
## own "ON"/"OFF" text) rather than a CheckButton with a tiny icon
## override - the source art is a wide pill graphic, not a small checkbox
## glyph. See ARCHITECTURE.md "Settings" and DECISIONS.md D37.

const TEXTURE_TOGGLE_ON := preload("res://assets/ui/settings/bs_toggle_on.png")
const TEXTURE_TOGGLE_OFF := preload("res://assets/ui/settings/bs_toggle_off.png")
# Visible (non-transparent) bounds of each toggle PNG, normalized; the two files pad differently.
const RECT_TOGGLE_ON := Rect2(0.1087, 0.0387, 0.7762, 0.9337)
const RECT_TOGGLE_OFF := Rect2(0.0192, 0.0328, 0.9612, 0.9483)

@onready var _sound_toggle: SettingsArtButton = %SoundToggle
@onready var _music_toggle: SettingsArtButton = %MusicToggle
@onready var _back_button: Button = %BackButton
@onready var _store_section: Control = %StoreSection
@onready var _buy_button: SettingsArtButton = %BuyNoForcedAdsButton
@onready var _price_label: Label = %PriceLabel
@onready var _store_status: Label = %StoreStatusLabel
@onready var _restore_button: Button = %RestorePurchasesButton
@onready var _cloud_section: Control = %CloudSection
@onready var _cloud_status: Label = %CloudStatusLabel
@onready var _cloud_sign_in: Button = %CloudSignInButton
@onready var _privacy_options: Button = %PrivacyOptionsButton
@onready var _privacy_policy: Button = %PrivacyPolicyButton
@onready var _about: Button = %AboutButton
@onready var _version: Label = %VersionLabel
@onready var _message: Label = %StoreMessageLabel

const MESSAGE_SECONDS := 4.0

# The price is a live, localized Play Store string (StoreManager.price_text()), so its width
# can't be known at authoring time. It sits in the art's empty right-hand region and shrinks
# (never clips) down to PRICE_MIN_FONT_SIZE for an unusually long string.
const PRICE_DEFAULT_FONT_SIZE := 42
const PRICE_MIN_FONT_SIZE := 22


func _ready() -> void:
	_ready_audio_rows()
	_ready_store_rows()
	for b in [_back_button, _cloud_sign_in, _buy_button, _restore_button, _about]:
		BeamButtonGlow.attach(b)


func _ready_store_rows() -> void:
	# Store rows appear only where a store exists (phones with the plugin); the game is
	# complete without them on desktop/editor.
	_store_section.visible = StoreManager.has_store()
	_buy_button.pressed.connect(_on_buy_pressed)
	_restore_button.pressed.connect(_on_restore_pressed)
	StoreManager.changed.connect(_refresh_store)
	StoreManager.purchase_finished.connect(_on_purchase_finished)
	_refresh_store()

	_cloud_sign_in.pressed.connect(func() -> void: GameManager.go_to_account())
	PlatformAccount.changed.connect(_refresh_cloud)
	_refresh_cloud()

	_privacy_options.visible = AdManager.is_privacy_options_required()
	_privacy_options.pressed.connect(_on_privacy_options_pressed)
	_privacy_policy.pressed.connect(_on_privacy_policy_pressed)
	_about.pressed.connect(func() -> void: GameManager.go_to_about())
	_about.pressed.connect(AudioManager.play_ui_button_press)
	_version.text = "BeamShift v%s" % ProjectSettings.get_setting("application/config/version", "1.0.0")


func _refresh_store() -> void:
	_store_status.visible = false
	if StoreManager.owns_no_forced_ads():
		_set_price_text("OWNED")
		_buy_button.disabled = true
	elif StoreManager.is_busy():
		_set_price_text("...")
		_buy_button.disabled = true
	elif StoreManager.can_purchase():
		_set_price_text(StoreManager.price_text())
		_buy_button.disabled = false
	else:
		# Never a dead-looking BUY button: say why it can't be pressed, on a plain line under the art.
		_store_status.text = "Store unavailable right now."
		_store_status.visible = true
		_set_price_text("")
		_buy_button.disabled = true
	_restore_button.disabled = StoreManager.is_busy()


func _set_price_text(label: String) -> void:
	_price_label.text = label
	var font: Font = _price_label.get_theme_font("font")
	var max_width: float = _buy_button.size.x * (_price_label.anchor_right - _price_label.anchor_left)
	if max_width <= 0.0:
		max_width = _buy_button.display_width * (_price_label.anchor_right - _price_label.anchor_left)
	var size := PRICE_DEFAULT_FONT_SIZE
	while size > PRICE_MIN_FONT_SIZE and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		size -= 1
	_price_label.add_theme_font_size_override("font_size", size)


func _on_buy_pressed() -> void:
	StoreManager.purchase()


func _on_restore_pressed() -> void:
	StoreManager.restore_purchases()


func _on_purchase_finished(_success: bool, message: String) -> void:
	_message.visible = message != ""
	_message.text = message
	_refresh_store()
	if message != "":
		# Transient, so the panel only grows while there is something to say.
		get_tree().create_timer(MESSAGE_SECONDS).timeout.connect(_hide_message.bind(message))


func _hide_message(shown: String) -> void:
	if _message.text == shown:
		_message.visible = false


func _refresh_cloud() -> void:
	if not PlatformAccount.is_supported():
		_cloud_status.text = "Game progress is stored locally on this device."
	elif PlatformAccount.connected:
		var who := PlatformAccount.display_name
		var suffix := " as " + who if who != "" else ""
		_cloud_status.text = "%s: connected%s.\nGame progress is stored on this device." % [PlatformAccount.service_name(), suffix]
	else:
		_cloud_status.text = "%s: not connected.\nGame progress is stored on this device." % PlatformAccount.service_name()


func _on_privacy_options_pressed() -> void:
	AdManager.show_privacy_options(_on_privacy_options_closed)


func _on_privacy_options_closed() -> void:
	_privacy_options.visible = AdManager.is_privacy_options_required()


func _on_privacy_policy_pressed() -> void:
	AudioManager.play_ui_button_press()
	GameManager.go_to_privacy_policy()


func _ready_audio_rows() -> void:
	_sound_toggle.button_pressed = SaveManager.sound_enabled
	_music_toggle.button_pressed = SaveManager.music_enabled
	_update_toggle_art(_sound_toggle, _sound_toggle.button_pressed)
	_update_toggle_art(_music_toggle, _music_toggle.button_pressed)

	_sound_toggle.toggled.connect(_on_sound_toggled)
	_music_toggle.toggled.connect(_on_music_toggled)
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	_back_button.pressed.connect(AudioManager.play_ui_back)


func _on_sound_toggled(enabled: bool) -> void:
	SaveManager.sound_enabled = enabled
	SaveManager.save_game()
	AudioManager.set_sound_enabled(enabled)
	_update_toggle_art(_sound_toggle, enabled)


func _on_music_toggled(enabled: bool) -> void:
	SaveManager.music_enabled = enabled
	SaveManager.save_game()
	_update_toggle_art(_music_toggle, enabled)


func _update_toggle_art(toggle: SettingsArtButton, enabled: bool) -> void:
	toggle.set_art(TEXTURE_TOGGLE_ON if enabled else TEXTURE_TOGGLE_OFF, RECT_TOGGLE_ON if enabled else RECT_TOGGLE_OFF)


## project.godot's quit_on_go_back=false means every top-level screen
## must replicate its own Back button's behavior for the system Back
## gesture/button itself - see main_menu.gd's _notification().
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if InternetManager.is_blocking():
			return # no navigation under the InternetBlocker
		GameManager.go_to_main_menu()
