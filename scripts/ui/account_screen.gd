extends Control
## Account screen: shows the optional platform identity (Play Games on Android, Sign in
## with Apple on iOS) over the local profile. Progress is stored on this device only;
## nothing here uploads or syncs anything. Talks only to PlatformAccount.

@onready var _service_label: Label = %ServiceLabel
@onready var _name_label: Label = %NameLabel
@onready var _status_label: Label = %StatusLabel
@onready var _message_label: Label = %MessageLabel
@onready var _action_button: Button = %ActionButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(GameManager.go_to_settings)
	_action_button.pressed.connect(_on_action_pressed)
	for button: Button in [_back_button, _action_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)
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
	if not account.is_supported():
		_service_label.text = "LOCAL PROFILE"
		_name_label.text = ""
		_status_label.text = "Game progress is stored locally on this device."
		_action_button.visible = false
		return
	_service_label.text = account.service_name().to_upper()
	_name_label.text = account.display_name
	_name_label.visible = account.display_name != ""
	_action_button.visible = account.platform == PlatformAccount.Platform.IOS and account.connected \
		or not account.connected
	_action_button.disabled = account.busy
	if account.connected:
		_status_label.text = "Connected"
		_action_button.text = "SIGN OUT"
	else:
		_status_label.text = "Not connected"
		_action_button.text = "RETRY" if account.last_message != "" else \
			("CONNECT" if account.platform == PlatformAccount.Platform.ANDROID else "SIGN IN")


func _on_action_pressed() -> void:
	if PlatformAccount.connected:
		PlatformAccount.sign_out()
	else:
		PlatformAccount.sign_in()
