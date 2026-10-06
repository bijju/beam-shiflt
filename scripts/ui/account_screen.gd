extends Control
## Account screen: shows the optional platform identity (Play Games on Android, Sign in
## with Apple on iOS) over the local profile. Progress is stored on this device only;
## nothing here uploads or syncs anything. Talks only to PlatformAccount.

@onready var _service_label: Label = %ServiceLabel
@onready var _name_label: Label = %NameLabel
@onready var _status_label: Label = %StatusLabel
@onready var _message_label: Label = %MessageLabel
## Plain button, iOS only (SIGN IN / SIGN OUT); Android uses the two art buttons below.
@onready var _action_button: Button = %ActionButton
@onready var _connect_button: Button = %ConnectButton
@onready var _retry_button: Button = %RetryButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(GameManager.go_to_settings)
	_action_button.pressed.connect(_on_action_pressed)
	_connect_button.pressed.connect(_on_action_pressed)
	_retry_button.pressed.connect(_on_action_pressed)
	for button: Button in [_back_button, _action_button, _connect_button, _retry_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)
	for button: Button in [_back_button, _connect_button, _retry_button]:
		BeamButtonGlow.attach(button)
	PlatformAccount.changed.connect(_refresh)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if InternetManager.is_blocking():
			return # no navigation under the InternetBlocker
		GameManager.go_to_settings()


func _refresh() -> void:
	var account := PlatformAccount
	_message_label.text = account.last_message
	_message_label.visible = account.last_message != ""
	_action_button.visible = false
	_connect_button.visible = false
	_retry_button.visible = false
	if not account.is_supported():
		_service_label.text = "LOCAL PROFILE"
		_name_label.text = ""
		_status_label.text = "Game progress is stored locally on this device."
		return
	_service_label.text = account.service_name().to_upper()
	_name_label.text = account.display_name
	_name_label.visible = account.display_name != ""
	var android := account.platform == PlatformAccount.Platform.ANDROID
	if account.connected:
		_status_label.text = "Connected"
		_action_button.text = "SIGN OUT"
		_action_button.visible = not android
	else:
		_status_label.text = "Not connected"
		_action_button.text = "RETRY" if account.last_message != "" else "SIGN IN"
		_action_button.visible = not android
		_retry_button.visible = android and account.last_message != ""
		_connect_button.visible = android and account.last_message == ""
	for button: Button in [_action_button, _connect_button, _retry_button]:
		button.disabled = account.busy


func _on_action_pressed() -> void:
	if PlatformAccount.connected:
		PlatformAccount.sign_out()
	else:
		PlatformAccount.sign_in()
