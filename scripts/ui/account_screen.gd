extends Control
## Player-facing BeamShift Account screen (Firebase REST Auth Phase 3 - Account UI).
##
## Talks ONLY to FirebaseAuth (sign in/create/reset/sign out) and CloudSave (status
## presentation, sync trigger) - never a second HTTP/token implementation, never
## uploads/downloads save data directly (CloudSave owns synchronization; this file
## only calls CloudSave.sync_now() once, right after a brand-new account is created,
## so an existing local profile starts uploading promptly instead of waiting for the
## next incidental save - see CLAUDE.md's Firebase Cloud Save Phase 2B rules).
##
## Never surfaces internal terms (Firebase/Firestore/UID/REST/token) to the player -
## every FirebaseAuth error code is translated by _friendly_error() before display.

const MIN_PASSWORD_LENGTH := 6

@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _keyboard_spacer: Control = %KeyboardSpacer
@onready var _signed_out_view: VBoxContainer = %SignedOutView
@onready var _explanation_label: Label = %ExplanationLabel
@onready var _email_field: LineEdit = %EmailField
@onready var _password_field: LineEdit = %PasswordField
@onready var _confirm_password_field: LineEdit = %ConfirmPasswordField
@onready var _message_label: Label = %MessageLabel
@onready var _primary_button: Button = %PrimaryButton
@onready var _mode_toggle_button: Button = %ModeToggleButton
@onready var _forgot_password_button: Button = %ForgotPasswordButton
@onready var _google_continue_button: Button = %GoogleContinueButton
@onready var _native_continue_button: Button = %NativeContinueButton

@onready var _signed_in_view: VBoxContainer = %SignedInView
@onready var _email_value_label: Label = %EmailValueLabel
@onready var _cloud_status_value_label: Label = %CloudStatusValueLabel
@onready var _sign_out_button: Button = %SignOutButton

@onready var _back_button: Button = %BackButton

const COLOR_ERROR := Color(1.0, 0.45, 0.45, 1.0)
const COLOR_STATUS := Color(0.8, 0.85, 0.95, 1.0)
const COLOR_SUCCESS := Color(0.55, 0.9, 0.6, 1.0)

var _create_mode := false
var _busy := false
var _sign_out_confirm_layer: Control = null

## Google Sign-In (Phase 4A). Native Android Credential Manager plugin, checked lazily
## and cached - never assumed present (desktop/iOS/a debug build without the plugin must
## all fail safely, never crash). See _google_plugin() / _on_google_continue_pressed().
const _GOOGLE_PLUGIN_NAME := "GodotGoogleSignIn"
var _google_plugin: Object = null
var _google_plugin_checked := false
## True while the player must sign in with their existing password account to link a
## Google credential that NEEDS_LINK surfaced (see FirebaseAuth.google_sign_in_finished).
var _pending_google_link := false

## Android keyboard/IME visibility (Phase 4B-B). Two independent, complementary
## mechanisms, because Android's soft keyboard behaves differently across devices/
## OEMs/Godot's own window mode - covering only one would leave real devices broken:
##
## 1. Viewport RESIZE (android:windowSoftInputMode="adjustResize") - the OS shrinks
##    the actual window/viewport when the keyboard opens, firing
##    get_viewport().size_changed. _scroll_container (SafeMargin > KeyboardVBox >
##    ScrollContainer > CenterContainer > Panel, see account_screen.tscn) is the
##    outer, size-owning layout element - NOT the inner-ScrollContainer-under-
##    CenterContainer pattern that previously collapsed the panel (ScrollContainer
##    doesn't report its content's true minimum size to a shrink-type parent like
##    CenterContainer; here ScrollContainer owns its own size, so that failure mode
##    can't recur). A shrunk viewport naturally shrinks ScrollContainer's rect, and
##    ensure_control_visible() (Godot's own scroll-into-view helper - no manual pixel
##    math) is re-run once the resize settles.
## 2. Keyboard OVERLAY (no resize - the more common real-Android behavior when the
##    OS doesn't resize the window) - the viewport never changes size, so (1) alone
##    would do nothing: ScrollContainer would have no idea part of its rect is
##    covered. DisplayServer.virtual_keyboard_get_height() (Godot 4.2+, Android/iOS
##    only, always 0 on desktop) reports the real keyboard height even when nothing
##    resizes. KeyboardSpacer, a sibling of ScrollContainer inside a shared
##    VBoxContainer (KeyboardVBox), gets that height as its own minimum height -
##    since a VBoxContainer divides its rect between children by their minimum
##    sizes, growing the spacer directly shrinks ScrollContainer's available rect by
##    the same amount, which is exactly what ensure_control_visible() needs to
##    reason about correctly.
var _focused_field: Control = null
var _last_keyboard_height := 0.0


func _ready() -> void:
	_primary_button.pressed.connect(_on_primary_pressed)
	_mode_toggle_button.pressed.connect(_on_mode_toggle_pressed)
	_forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	_google_continue_button.pressed.connect(_on_google_continue_pressed)
	_native_continue_button.pressed.connect(_on_native_continue_pressed)
	_sign_out_button.pressed.connect(_on_sign_out_pressed)
	_back_button.pressed.connect(func() -> void: GameManager.go_to_settings())

	for button: Button in [_primary_button, _mode_toggle_button, _forgot_password_button, _google_continue_button, _native_continue_button, _sign_out_button, _back_button]:
		button.pressed.connect(AudioManager.play_ui_button_press)

	for field: LineEdit in [_email_field, _password_field, _confirm_password_field]:
		field.focus_entered.connect(_on_field_focus_entered.bind(field))
		field.focus_exited.connect(_on_field_focus_exited.bind(field))
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	FirebaseAuth.sign_in_finished.connect(_on_sign_in_finished)
	FirebaseAuth.account_create_finished.connect(_on_account_create_finished)
	FirebaseAuth.password_reset_finished.connect(_on_password_reset_finished)
	FirebaseAuth.auth_state_changed.connect(_on_auth_state_changed)
	FirebaseAuth.google_sign_in_finished.connect(_on_google_sign_in_finished)
	FirebaseAuth.google_link_finished.connect(_on_google_link_finished)
	CloudSave.synced.connect(_on_cloud_synced)
	CloudSave.signed_in_changed.connect(_on_cloud_signed_in_changed)

	_set_create_mode(false)
	_refresh_view()


func _refresh_view() -> void:
	var signed_in := FirebaseAuth.is_signed_in()
	_signed_out_view.visible = not signed_in
	_signed_in_view.visible = signed_in
	if signed_in:
		_email_value_label.text = FirebaseAuth.get_email()
		_refresh_cloud_status()
	else:
		_native_continue_button.visible = CloudSave.has_native_backend()
		_native_continue_button.text = _native_continue_label()


## "Google Play Games" is deliberately relabeled here to drop the word "Google" -
## this button is the native CloudSave.sign_in() fallback, not Firebase Google Sign-In
## (GoogleContinueButton, still a placeholder - see _on_google_continue_pressed()), and
## the two must never read the same on screen. Other native backends (Game Center)
## keep their own name unchanged.
func _native_continue_label() -> String:
	var service := CloudSave.native_service_name()
	if service == "Google Play Games":
		return "CONTINUE WITH PLAY GAMES"
	return "CONTINUE WITH %s" % service.to_upper()


func _refresh_cloud_status() -> void:
	_cloud_status_value_label.text = "Cloud Save: %s" % _cloud_status_text()


func _cloud_status_text() -> String:
	if not CloudSave.is_signed_in:
		return "Local progress only"
	if not InternetManager.is_online:
		return "Waiting for connection"
	if CloudSave.last_error() != "" and CloudSave.last_synced_at == "":
		return "Sync failed"
	if CloudSave.last_synced_at != "":
		return "Synced (%s)" % CloudSave.last_synced_at.substr(11, 5)
	return "Signed in"


## ---- Keyboard/IME-aware scrolling (Phase 4B-B) ----

func _process(_delta: float) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var kh := 0.0
	if _focused_field != null:
		kh = float(DisplayServer.virtual_keyboard_get_height())
	# Only react to a real transition, not every frame - keeps this idle-cheap and
	# avoids fighting ensure_control_visible()'s own scroll animation every tick.
	if is_equal_approx(kh, _last_keyboard_height):
		return
	_last_keyboard_height = kh
	_keyboard_spacer.custom_minimum_size.y = kh
	if kh > 0.0 and _focused_field != null:
		await get_tree().process_frame
		if _focused_field != null and is_instance_valid(_focused_field):
			_scroll_container.ensure_control_visible(_focused_field)


func _on_field_focus_entered(field: Control) -> void:
	_focused_field = field
	_scroll_container.ensure_control_visible(field)


func _on_field_focus_exited(field: Control) -> void:
	if _focused_field == field:
		_focused_field = null


## The Android soft keyboard's resize finishes asynchronously AFTER the focus event
## that opened it - re-run ensure_control_visible() once the viewport (and therefore
## this screen's own layout) has settled into its new size. call_deferred is not
## enough on its own here (the resize can take more than one frame to arrive from the
## OS) - awaiting one process_frame after the signal fires is what actually lines up
## with the settled layout in practice.
func _on_viewport_size_changed() -> void:
	if _focused_field == null:
		return
	await get_tree().process_frame
	if _focused_field != null and is_instance_valid(_focused_field):
		_scroll_container.ensure_control_visible(_focused_field)


## ---- Mode switching (SIGN IN <-> CREATE ACCOUNT) ----

func _on_mode_toggle_pressed() -> void:
	_set_create_mode(not _create_mode)


func _set_create_mode(create: bool) -> void:
	if create and _pending_google_link:
		# A NEEDS_LINK flow requires signing in to the EXISTING account, not creating a
		# new one - switching to Create Account abandons the pending link.
		_pending_google_link = false
		FirebaseAuth.cancel_pending_google_link()
	_create_mode = create
	_confirm_password_field.visible = create
	_forgot_password_button.visible = not create
	_primary_button.text = "CREATE ACCOUNT" if create else "SIGN IN"
	_mode_toggle_button.text = "Have an account? Sign In" if create else "New here? Create Account"
	_clear_message()


## ---- Primary action (SIGN IN / CREATE ACCOUNT) ----

func _on_primary_pressed() -> void:
	if _busy:
		return
	var email := _email_field.text.strip_edges()
	var password := _password_field.text
	if email == "" or not email.contains("@") or not email.contains("."):
		_show_error("Enter a valid email address.")
		return
	if password == "":
		_show_error("Enter your password.")
		return
	if _create_mode:
		if password.length() < MIN_PASSWORD_LENGTH:
			_show_error("Password must be at least %d characters." % MIN_PASSWORD_LENGTH)
			return
		if password != _confirm_password_field.text:
			_show_error("Passwords do not match.")
			return

	_set_busy(true)
	_show_status("Working...")
	if _create_mode:
		FirebaseAuth.create_account(email, password)
	else:
		FirebaseAuth.sign_in(email, password)


func _on_sign_in_finished(success: bool, error_code: String) -> void:
	_set_busy(false)
	if success:
		_on_auth_success()
		if _pending_google_link:
			# The player just proved ownership of the existing password account that a
			# prior Google Sign-In attempt collided with - attach Google to this SAME
			# UID now. Sign-in itself already succeeded regardless of whether linking
			# does; a link failure here must never undo or block the sign-in.
			_show_status("Linking Google account...")
			FirebaseAuth.link_pending_google_credential()
	else:
		_show_error(_friendly_error(error_code))
		_password_field.text = ""


func _on_account_create_finished(success: bool, error_code: String) -> void:
	_set_busy(false)
	if success:
		_on_auth_success()
		# A brand-new account's cloud copy is always empty - push the existing local
		# profile promptly instead of waiting for the next incidental save. CloudSave
		# already selected the Firebase backend synchronously (via auth_state_changed,
		# fired before this handler runs) and never overwrites local progress on an
		# empty cloud (see cloud_save.gd _reconcile()).
		CloudSave.sync_now()
	else:
		_show_error(_friendly_error(error_code))
		_password_field.text = ""
		_confirm_password_field.text = ""


func _on_auth_success() -> void:
	_password_field.text = ""
	_confirm_password_field.text = ""
	_clear_message()
	_refresh_view()


## ---- Forgot password ----

func _on_forgot_password_pressed() -> void:
	if _busy:
		return
	var email := _email_field.text.strip_edges()
	if email == "":
		_show_error("Enter your email address first.")
		return
	_set_busy(true)
	_show_status("Sending...")
	FirebaseAuth.send_password_reset(email)


func _on_password_reset_finished(success: bool, error_code: String) -> void:
	_set_busy(false)
	if success:
		_show_success("Password reset email sent. Check your inbox or spam folder.")
	else:
		_show_error(_friendly_error(error_code))


## ---- Google Sign-In (Firebase, Phase 4A) ----
##
## Android Credential Manager (native plugin, GodotGoogleSignIn) -> a Google ID token ->
## FirebaseAuth.sign_in_with_google_id_token() -> accounts:signInWithIdp. Every step fails
## safely: no plugin (desktop, iOS, or a build without it) shows a message and returns,
## never crashes and never pretends a sign-in happened.
func _on_google_continue_pressed() -> void:
	if _busy:
		return
	var plugin := _google_plugin_instance()
	if plugin == null or not bool(plugin.call("isAvailable")):
		_show_status("Google Sign-In is only available in the Android app.")
		return
	_set_busy(true)
	_show_status("Continue with Google...")
	plugin.call("signIn", FirebaseConfig.GOOGLE_WEB_CLIENT_ID)


## Lazily resolves and caches the native plugin singleton. Returns null (never throws) on
## desktop/iOS or an Android build that doesn't bundle the plugin - callers must always
## null-check (and, before calling signIn(), also check isAvailable()). Connects the
## plugin's three result signals exactly once.
func _google_plugin_instance() -> Object:
	if _google_plugin_checked:
		return _google_plugin
	_google_plugin_checked = true
	if OS.get_name() == "Android" and Engine.has_singleton(_GOOGLE_PLUGIN_NAME):
		_google_plugin = Engine.get_singleton(_GOOGLE_PLUGIN_NAME)
		if _google_plugin.has_signal("google_id_token_obtained"):
			_google_plugin.connect("google_id_token_obtained", _on_google_id_token_obtained)
		if _google_plugin.has_signal("google_sign_in_cancelled"):
			_google_plugin.connect("google_sign_in_cancelled", _on_google_plugin_cancelled)
		if _google_plugin.has_signal("google_sign_in_failed"):
			_google_plugin.connect("google_sign_in_failed", _on_google_plugin_failed)
	return _google_plugin


func _on_google_id_token_obtained(id_token: String) -> void:
	# Never log the token itself - only that one arrived.
	print("[AccountScreen] Google ID token received from plugin.")
	FirebaseAuth.sign_in_with_google_id_token(id_token)


## Reported separately from a real failure (native plugin's google_sign_in_cancelled
## signal) - the player just dismissed the account chooser, not an error.
func _on_google_plugin_cancelled() -> void:
	_set_busy(false)
	_clear_message()


func _on_google_plugin_failed(_reason: String) -> void:
	_set_busy(false)
	_show_status("Google Sign-In failed. Please try again.")


func _on_google_sign_in_finished(success: bool, error_code: String, needs_link: bool, _is_new_user: bool) -> void:
	_set_busy(false)
	if success:
		_pending_google_link = false
		_on_auth_success()
		# Mirrors _on_account_create_finished(): only a brand-new account has an empty
		# cloud copy worth pushing promptly; an existing account's data is handled by
		# CloudSave's own reconciliation exactly as it always is.
		if _is_new_user:
			CloudSave.sync_now()
		return
	if needs_link:
		var email := FirebaseAuth.pending_google_link_email()
		_pending_google_link = true
		_set_create_mode(false)
		if email != "":
			_email_field.text = email
		_password_field.text = ""
		_show_status("An account already exists for this email. Sign in with your password to link Google.")
		return
	_show_error(_friendly_error(error_code))


func _on_google_link_finished(success: bool, error_code: String) -> void:
	if success:
		_show_success("Google account linked.")
	else:
		# The player is already signed in via password at this point (link only ever
		# runs after that succeeds) - a link failure is informational, not blocking.
		print("[AccountScreen] Google link failed: %s" % error_code)
		if error_code != "OFFLINE":
			_show_status("Signed in. Google linking will be retried later.")


## ---- Native (Play Games / Game Center) fallback ----

func _on_native_continue_pressed() -> void:
	CloudSave.sign_in()


## ---- Sign out ----

func _on_sign_out_pressed() -> void:
	if _sign_out_confirm_layer != null:
		return
	_show_sign_out_confirmation()


func _show_sign_out_confirmation() -> void:
	_sign_out_confirm_layer = Control.new()
	_sign_out_confirm_layer.name = "SignOutConfirm"
	_sign_out_confirm_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sign_out_confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0.02, 0.08, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_sign_out_confirm_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sign_out_confirm_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)
	var title := Label.new()
	title.text = "SIGN OUT OF YOUR BEAMSHIFT ACCOUNT?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	var body := Label.new()
	body.text = "Your progress will remain on this device."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 26)
	box.add_child(body)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = "CANCEL"
	cancel.custom_minimum_size = Vector2(480, 120)
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel.add_theme_font_size_override("font_size", 28)
	cancel.pressed.connect(AudioManager.play_ui_button_press)
	cancel.pressed.connect(_close_sign_out_confirmation)
	row.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "SIGN OUT"
	confirm.theme_type_variation = &"DangerButton"
	confirm.custom_minimum_size = Vector2(480, 120)
	confirm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm.add_theme_font_size_override("font_size", 28)
	confirm.pressed.connect(AudioManager.play_ui_button_press)
	confirm.pressed.connect(_on_sign_out_confirmed)
	row.add_child(confirm)
	add_child(_sign_out_confirm_layer)


func _close_sign_out_confirmation() -> void:
	if _sign_out_confirm_layer != null:
		_sign_out_confirm_layer.queue_free()
		_sign_out_confirm_layer = null


func _on_sign_out_confirmed() -> void:
	_close_sign_out_confirmation()
	FirebaseAuth.sign_out()
	FirebaseAuth.cancel_pending_google_link()
	_pending_google_link = false
	_set_create_mode(false)
	_email_field.text = ""
	_clear_message()
	_refresh_view()


## ---- Signal plumbing ----

func _on_auth_state_changed(_is_signed_in: bool) -> void:
	_refresh_view()


func _on_cloud_synced(_ok: bool) -> void:
	if _signed_in_view.visible:
		_refresh_cloud_status()


func _on_cloud_signed_in_changed(_is_signed_in: bool) -> void:
	if _signed_in_view.visible:
		_refresh_cloud_status()


## ---- Busy / messaging helpers ----

func _set_busy(busy: bool) -> void:
	_busy = busy
	_primary_button.disabled = busy
	_mode_toggle_button.disabled = busy
	_forgot_password_button.disabled = busy
	_google_continue_button.disabled = busy
	_native_continue_button.disabled = busy


func _show_status(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = COLOR_STATUS
	_message_label.visible = true


func _show_error(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = COLOR_ERROR
	_message_label.visible = true


func _show_success(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = COLOR_SUCCESS
	_message_label.visible = true


func _clear_message() -> void:
	_message_label.visible = false
	_message_label.text = ""


## ---- Error translation (never show raw Firebase codes/JSON to a player) ----

func _friendly_error(code: String) -> String:
	match code:
		"INVALID_LOGIN_CREDENTIALS", "INVALID_PASSWORD", "EMAIL_NOT_FOUND":
			return "Email or password is incorrect."
		"EMAIL_EXISTS":
			return "An account already exists for this email."
		"INVALID_EMAIL":
			return "Enter a valid email address."
		"WEAK_PASSWORD":
			return "Choose a stronger password (at least %d characters)." % MIN_PASSWORD_LENGTH
		"OFFLINE":
			return "Internet connection required."
		"TOO_MANY_ATTEMPTS_TRY_LATER":
			return "Too many attempts. Please try again later."
		"CONFIG_MISSING":
			return "Account sign-in is unavailable right now."
		"USER_DISABLED":
			return "This account has been disabled."
		"FEDERATED_USER_ID_ALREADY_LINKED":
			return "This Google account is already linked to a different BeamShift account."
		"INVALID_IDP_RESPONSE":
			return "Google Sign-In failed. Please try again."
		"NOT_SIGNED_IN", "NO_PENDING_CREDENTIAL":
			return "Unable to complete the request. Please try again."
		_:
			return "Unable to complete the request. Please try again."


## project.godot's quit_on_go_back=false means every top-level screen must
## replicate its own Back button's behavior for the system Back gesture/button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _sign_out_confirm_layer != null:
			_close_sign_out_confirmation()
			return
		GameManager.go_to_settings()
