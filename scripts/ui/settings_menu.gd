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
@onready var _store_section: Control = %StoreSection
@onready var _buy_button: Button = %BuyNoForcedAdsButton
@onready var _store_status: Label = %StoreStatusLabel
@onready var _restore_button: Button = %RestorePurchasesButton
@onready var _cloud_section: Control = %CloudSection
@onready var _cloud_status: Label = %CloudStatusLabel
@onready var _cloud_sign_in: Button = %CloudSignInButton
@onready var _cloud_sync: Button = %CloudSyncButton
@onready var _privacy_options: Button = %PrivacyOptionsButton
@onready var _privacy_policy: Button = %PrivacyPolicyButton
@onready var _message: Label = %StoreMessageLabel

const MESSAGE_SECONDS := 4.0

# The buy button's label is dynamic (a live, localized Play Store price string -
# see StoreManager.price_text()) so its width can't be guaranteed at authoring time.
# Widening the button (scenes/ui/settings_menu.tscn) covers most locales; this is a
# last-resort shrink so an unusually long localized price never overflows/clips the
# button art instead of being truncated.
const BUY_BUTTON_DEFAULT_FONT_SIZE := 24
const BUY_BUTTON_MIN_FONT_SIZE := 15
# The button's StyleBoxTexture has a 70px left/right texture_margin (its content
# margin, per CLAUDE.md's content_margin note) plus a little breathing room so text
# never touches the metallic end caps.
const BUY_BUTTON_TEXT_SIDE_INSET := 90.0

var _cloud_failed := false


func _ready() -> void:
	_ready_audio_rows()
	_ready_store_rows()


func _ready_store_rows() -> void:
	# Store rows appear only where a store exists (phones with the plugin); the game is
	# complete without them on desktop/editor.
	_store_section.visible = StoreManager.has_store()
	_buy_button.pressed.connect(_on_buy_pressed)
	_restore_button.pressed.connect(_on_restore_pressed)
	StoreManager.changed.connect(_refresh_store)
	StoreManager.purchase_finished.connect(_on_purchase_finished)
	_refresh_store()

	# Firebase Account UI Phase 3: the account entry is always offered (a BeamShift
	# account works regardless of OS platform), separate from whether a native
	# platform backend happens to exist - unlike the pre-Phase-3 gate on
	# CloudSave.is_available(), which would hide this on desktop/no-native-backend.
	_cloud_section.visible = true
	_cloud_sign_in.pressed.connect(func() -> void: GameManager.go_to_account())
	_cloud_sync.pressed.connect(CloudSave.sync_now)
	CloudSave.signed_in_changed.connect(_on_cloud_signed_in_changed)
	CloudSave.synced.connect(_on_cloud_synced)
	FirebaseAuth.auth_state_changed.connect(_on_firebase_auth_state_changed)
	_refresh_cloud()

	_privacy_options.visible = AdManager.is_privacy_options_required()
	_privacy_options.pressed.connect(_on_privacy_options_pressed)
	_privacy_policy.visible = StoreConfig.PRIVACY_POLICY_URL != ""
	_privacy_policy.pressed.connect(_on_privacy_policy_pressed)


func _refresh_store() -> void:
	_store_status.visible = false
	if StoreManager.owns_no_forced_ads():
		_set_buy_button_label("NO FORCED ADS - OWNED")
		_buy_button.disabled = true
	elif StoreManager.is_busy():
		_set_buy_button_label("WORKING...")
		_buy_button.disabled = true
	elif StoreManager.can_purchase():
		_set_buy_button_label("NO FORCED ADS - %s" % StoreManager.price_text())
		_buy_button.disabled = false
	else:
		# Never a dead-looking BUY button: say why it can't be pressed, on a plain line under the art.
		_store_status.text = "Store unavailable right now."
		_store_status.visible = true
		_set_buy_button_label("NO FORCED ADS")
		_buy_button.disabled = true
	_restore_button.disabled = StoreManager.is_busy()


func _set_buy_button_label(label: String) -> void:
	_buy_button.text = label
	var font: Font = _buy_button.get_theme_font("font")
	var max_width: float = _buy_button.custom_minimum_size.x - BUY_BUTTON_TEXT_SIDE_INSET
	var size := BUY_BUTTON_DEFAULT_FONT_SIZE
	while size > BUY_BUTTON_MIN_FONT_SIZE and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		size -= 1
	_buy_button.add_theme_font_size_override("font_size", size)


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
	var service := CloudSave.service_name()
	if not CloudSave.is_signed_in:
		_cloud_status.text = "Cloud save: not signed in. Progress is saved on this device."
	elif _cloud_failed:
		var reason := CloudSave.last_error()
		_cloud_status.text = "Cloud save: the last sync failed. Your progress is safe on this device." + ("\n" + reason if reason != "" else "")
	elif CloudSave.last_synced_at != "":
		_cloud_status.text = "Cloud save: synced with %s at %s." % [service, CloudSave.last_synced_at.substr(11, 5)]
	else:
		_cloud_status.text = "Cloud save: signed in to %s." % service
	# Firebase Account UI Phase 3: this button always opens the Account screen now
	# (never a direct CloudSave.sign_in() call) - its label reflects whether a
	# BeamShift account is already signed in.
	_cloud_sign_in.text = "ACCOUNT" if FirebaseAuth.is_signed_in() else "SIGN IN"
	_cloud_sync.visible = CloudSave.is_signed_in


func _on_cloud_signed_in_changed(_signed_in: bool) -> void:
	_refresh_cloud()


func _on_firebase_auth_state_changed(_signed_in: bool) -> void:
	_refresh_cloud()


func _on_cloud_synced(ok: bool) -> void:
	_cloud_failed = not ok
	_refresh_cloud()


func _on_privacy_options_pressed() -> void:
	AdManager.show_privacy_options(_on_privacy_options_closed)


func _on_privacy_options_closed() -> void:
	_privacy_options.visible = AdManager.is_privacy_options_required()


func _on_privacy_policy_pressed() -> void:
	OS.shell_open(StoreConfig.PRIVACY_POLICY_URL)


func _ready_audio_rows() -> void:
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
