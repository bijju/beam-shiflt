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
@onready var _restore_button: Button = %RestorePurchasesButton
@onready var _cloud_section: Control = %CloudSection
@onready var _cloud_status: Label = %CloudStatusLabel
@onready var _cloud_sign_in: Button = %CloudSignInButton
@onready var _cloud_sync: Button = %CloudSyncButton
@onready var _privacy_options: Button = %PrivacyOptionsButton
@onready var _privacy_policy: Button = %PrivacyPolicyButton
@onready var _message: Label = %StoreMessageLabel

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

	_cloud_section.visible = CloudSave.is_available()
	_cloud_sign_in.pressed.connect(CloudSave.sign_in)
	_cloud_sync.pressed.connect(CloudSave.sync_now)
	CloudSave.signed_in_changed.connect(_on_cloud_signed_in_changed)
	CloudSave.synced.connect(_on_cloud_synced)
	_refresh_cloud()

	_privacy_options.visible = AdManager.is_privacy_options_required()
	_privacy_options.pressed.connect(_on_privacy_options_pressed)
	_privacy_policy.visible = StoreConfig.PRIVACY_POLICY_URL != ""
	_privacy_policy.pressed.connect(_on_privacy_policy_pressed)


func _refresh_store() -> void:
	if StoreManager.owns_no_forced_ads():
		_buy_button.text = "NO FORCED ADS - OWNED"
		_buy_button.disabled = true
	elif StoreManager.is_busy():
		_buy_button.text = "WORKING..."
		_buy_button.disabled = true
	elif StoreManager.can_purchase():
		_buy_button.text = "NO FORCED ADS - %s" % StoreManager.price_text()
		_buy_button.disabled = false
	else:
		# Never a dead-looking BUY button: say why it can't be pressed.
		_buy_button.text = "NO FORCED ADS - STORE UNAVAILABLE"
		_buy_button.disabled = true
	_restore_button.disabled = StoreManager.is_busy()


func _on_buy_pressed() -> void:
	StoreManager.purchase()


func _on_restore_pressed() -> void:
	StoreManager.restore_purchases()


func _on_purchase_finished(_success: bool, message: String) -> void:
	_message.visible = message != ""
	_message.text = message
	_refresh_store()


func _refresh_cloud() -> void:
	var service := CloudSave.service_name()
	if not CloudSave.is_signed_in:
		_cloud_status.text = "Cloud save: not signed in to %s. Progress is saved on this device." % service
	elif _cloud_failed:
		var reason := CloudSave.last_error()
		_cloud_status.text = "Cloud save: the last sync failed. Your progress is safe on this device." + ("\n" + reason if reason != "" else "")
	elif CloudSave.last_synced_at != "":
		_cloud_status.text = "Cloud save: synced with %s at %s." % [service, CloudSave.last_synced_at.substr(11, 5)]
	else:
		_cloud_status.text = "Cloud save: signed in to %s." % service
	_cloud_sign_in.visible = not CloudSave.is_signed_in
	_cloud_sync.visible = CloudSave.is_signed_in


func _on_cloud_signed_in_changed(_signed_in: bool) -> void:
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
