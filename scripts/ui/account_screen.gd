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
@onready var _apple_continue_button: Button = %AppleContinueButton
@onready var _google_continue_button: Button = %GoogleContinueButton
@onready var _or_label: Label = %OrLabel
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

## Google Sign-In (Phase 4A, extended to iOS in the iOS Auth pass). Native Credential
## Manager (Android) / ASWebAuthenticationSession (iOS) plugin, checked lazily and cached
## - never assumed present (desktop, or a build without the plugin, must fail safely,
## never crash). Both platforms register the SAME singleton name/signal contract (see
## tools/android_plugin_src/google_signin/ and tools/ios_plugin_src/google_signin_ios/),
## so this GDScript layer needs no per-platform branching beyond which client id to send.
## See _google_plugin_instance() / _on_google_continue_pressed().
const _GOOGLE_PLUGIN_NAME := "GodotGoogleSignIn"
var _google_plugin: Object = null
var _google_plugin_checked := false
## True while the player must sign in with their existing password account to link a
## Google credential that NEEDS_LINK surfaced (see FirebaseAuth.google_sign_in_finished).
var _pending_google_link := false

## Sign in with Apple (iOS Auth Phase 1). iOS-only, via the vendored GodotApplePlugins
## AuthenticationServices GDExtension (addons/GodotApplePluginsAuthenticationServices/,
## same pinned-release vendoring CI already uses for scripts/cloud/
## game_center_cloud_backend.gd's Game Center backend - see .github/workflows/release.yml).
## UNLIKE the Android/iOS Google plugin above, this is NOT an Engine singleton - it is a
## plain RefCounted extension class (ASAuthorizationController), instantiated via
## ClassDB.instantiate() exactly like game_center_cloud_backend.gd's PLUGIN_CLASS pattern,
## with its signals CONNECT_DEFERRED (SwiftGodot calls back off the main thread - see that
## file's own header comment; the same rule applies here). See
## _apple_auth_instance() / _on_apple_continue_pressed().
const _APPLE_AUTH_CLASS := "ASAuthorizationController"
var _apple_auth: Object = null
var _apple_auth_checked := false

## iOS Google Sign-In (iOS Auth Phase 1) reuses the SAME vendored AuthenticationServices
## extension's generic ASWebAuthenticationSession class (a system-presented OAuth browser
## sheet) rather than a second plugin - Google publishes no first-party Godot bridge, and
## this project's own architecture deliberately avoids vendoring a large third-party
## Google iOS SDK when the generic OS-level primitive already does the job. See
## _google_web_auth_instance() / _start_google_sign_in_ios().
const _GOOGLE_WEB_AUTH_CLASS := "ASWebAuthenticationSession"
var _google_web_auth: Object = null
var _google_web_auth_checked := false

## True while the player must sign in with their existing password account to link an
## Apple credential that NEEDS_LINK surfaced (see FirebaseAuth.apple_sign_in_finished).
var _pending_apple_link := false

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
	_apple_continue_button.pressed.connect(_on_apple_continue_pressed)
	_google_continue_button.pressed.connect(_on_google_continue_pressed)
	_native_continue_button.pressed.connect(_on_native_continue_pressed)
	_sign_out_button.pressed.connect(_on_sign_out_pressed)
	_back_button.pressed.connect(func() -> void: GameManager.go_to_settings())

	for button: Button in [_primary_button, _mode_toggle_button, _forgot_password_button, _apple_continue_button, _google_continue_button, _native_continue_button, _sign_out_button, _back_button]:
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
	FirebaseAuth.apple_sign_in_finished.connect(_on_apple_sign_in_finished)
	FirebaseAuth.apple_link_finished.connect(_on_apple_link_finished)
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
		# Platform-aware provider buttons (iOS Auth Phase 1): Apple only ever shows on
		# iOS (Apple's own guideline - Sign in with Apple has no meaning elsewhere), and
		# both native-provider buttons are hidden entirely on desktop/editor rather than
		# left visible to fail with a click-time message - there is no real account
		# system to try there. Email/password stays available on every platform.
		_apple_continue_button.visible = OS.get_name() == "iOS"
		_google_continue_button.visible = OS.get_name() in ["Android", "iOS"]
		_or_label.visible = _apple_continue_button.visible or _google_continue_button.visible
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
	if create and (_pending_google_link or _pending_apple_link):
		# A NEEDS_LINK flow requires signing in to the EXISTING account, not creating a
		# new one - switching to Create Account abandons the pending link.
		_pending_google_link = false
		_pending_apple_link = false
		FirebaseAuth.cancel_pending_google_link()
		FirebaseAuth.cancel_pending_apple_link()
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
		elif _pending_apple_link:
			_show_status("Linking Apple account...")
			FirebaseAuth.link_pending_apple_credential()
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


## ---- Google Sign-In (Firebase, Phase 4A + iOS Auth Phase 1) ----
##
## Android: Credential Manager (native plugin, GodotGoogleSignIn, Engine singleton) -> a
## Google ID token. iOS: ASWebAuthenticationSession (vendored GodotApplePlugins
## AuthenticationServices extension, a plain instantiated object, NOT an Engine singleton
## - see the class-level comment on _GOOGLE_WEB_AUTH_CLASS) opens Google's OAuth endpoint
## directly and reads the id_token off the callback URL. Both funnel into the SAME
## FirebaseAuth.sign_in_with_google_id_token() -> accounts:signInWithIdp. Every step fails
## safely: no plugin/extension (desktop, or a build without it) shows a message and
## returns, never crashes and never pretends a sign-in happened. This button is hidden
## outright on desktop (see _refresh_view()).
func _on_google_continue_pressed() -> void:
	print("[GoogleSignIn] Sign-in button pressed.")
	if _busy:
		return
	if OS.get_name() == "iOS":
		_start_google_sign_in_ios()
		return
	var plugin := _google_plugin_instance()
	if plugin == null or not bool(plugin.call("isAvailable")):
		print("[GoogleSignIn] Plugin unavailable (plugin=%s)." % [plugin != null])
		_show_status("Google Sign-In is unavailable on this build.")
		return
	_set_busy(true)
	_show_status("Continue with Google...")
	plugin.call("signIn", FirebaseConfig.GOOGLE_WEB_CLIENT_ID)


## Lazily resolves and caches the Android Credential Manager plugin's Engine singleton.
## Returns null (never throws) on desktop, iOS, or an Android build that doesn't bundle
## the plugin - callers must always null-check (and, before calling signIn(), also check
## isAvailable()). Connects the plugin's three result signals exactly once.
func _google_plugin_instance() -> Object:
	if _google_plugin_checked:
		return _google_plugin
	_google_plugin_checked = true
	if OS.get_name() == "Android" and Engine.has_singleton(_GOOGLE_PLUGIN_NAME):
		_google_plugin = Engine.get_singleton(_GOOGLE_PLUGIN_NAME)
		print("[GoogleSignIn] Native plugin singleton found: %s" % _GOOGLE_PLUGIN_NAME)
		if _google_plugin.has_signal("google_id_token_obtained"):
			_google_plugin.connect("google_id_token_obtained", _on_google_id_token_obtained)
		if _google_plugin.has_signal("google_sign_in_cancelled"):
			_google_plugin.connect("google_sign_in_cancelled", _on_google_plugin_cancelled)
		if _google_plugin.has_signal("google_sign_in_failed"):
			_google_plugin.connect("google_sign_in_failed", _on_google_plugin_failed)
	else:
		print("[GoogleSignIn] Native plugin singleton NOT found (os=%s, has_singleton=%s)." % [
			OS.get_name(), OS.get_name() == "Android" and Engine.has_singleton(_GOOGLE_PLUGIN_NAME)])
	return _google_plugin


func _on_google_id_token_obtained(id_token: String) -> void:
	# Never log the token itself - only that one arrived.
	print("[GoogleSignIn] Google ID token obtained: YES (len=%d). Starting Firebase exchange." % id_token.length())
	FirebaseAuth.sign_in_with_google_id_token(id_token)


## Reported separately from a real failure (native plugin's google_sign_in_cancelled
## signal) - the player just dismissed the account chooser, not an error.
func _on_google_plugin_cancelled() -> void:
	_set_busy(false)
	_clear_message()


func _on_google_plugin_failed(reason: String) -> void:
	print("[GoogleSignIn] Native plugin reported failure: %s" % reason)
	_set_busy(false)
	_show_status("Google Sign-In failed. Please try again.")


## ---- Google Sign-In on iOS (ASWebAuthenticationSession bridge, iOS Auth Phase 1) ----
##
## No first-party Google Godot plugin exists, and this project deliberately avoids
## vendoring the large Google Sign-In iOS SDK just for one ID token. Instead this opens
## Google's own OAuth 2.0 / OpenID Connect authorization endpoint in the system-presented
## ASWebAuthenticationSession sheet (the SAME vendored GodotApplePlugins
## AuthenticationServices extension the Apple section below uses), requesting an ID token
## directly (response_type=id_token) so no server-side code exchange is needed - the
## callback URL's fragment already carries a Firebase-ready id_token. Uses
## FirebaseConfig.GOOGLE_IOS_CLIENT_ID (never the Android/web client id - see that
## constant's own comment) and GOOGLE_IOS_REVERSED_CLIENT_ID as both the redirect URL
## scheme and the session's callback_scheme filter. NOT YET LIVE-VERIFIED against a real
## Google OAuth response on a device - confirm the callback URL actually carries
## `id_token=` in its fragment (not `code=`) before treating this as working; if Google's
## endpoint refuses response_type=id_token for this client type, this needs an
## authorization-code + PKCE flow instead (a real, but larger, follow-up).
func _start_google_sign_in_ios() -> void:
	var web_auth := _google_web_auth_instance()
	if web_auth == null:
		print("[GoogleSignIn] ASWebAuthenticationSession unavailable.")
		_show_status("Google Sign-In is unavailable on this build.")
		return
	_set_busy(true)
	_show_status("Continue with Google...")
	var nonce := _random_token()
	var state := _random_token()
	var redirect_uri := "%s:/oauth2redirect" % FirebaseConfig.GOOGLE_IOS_REVERSED_CLIENT_ID
	var auth_url := "https://accounts.google.com/o/oauth2/v2/auth" \
		+ "?client_id=" + FirebaseConfig.GOOGLE_IOS_CLIENT_ID.uri_encode() \
		+ "&redirect_uri=" + redirect_uri.uri_encode() \
		+ "&response_type=id_token" \
		+ "&scope=" + "openid email".uri_encode() \
		+ "&nonce=" + nonce \
		+ "&state=" + state
	var started := bool(web_auth.call("start", auth_url, FirebaseConfig.GOOGLE_IOS_REVERSED_CLIENT_ID, false))
	if not started:
		print("[GoogleSignIn] ASWebAuthenticationSession.start() returned false.")
		_set_busy(false)
		_show_status("Google Sign-In failed. Please try again.")


## Lazily resolves and caches an ASWebAuthenticationSession instance. Returns null (never
## throws) off iOS or on a build that doesn't bundle the extension.
func _google_web_auth_instance() -> Object:
	if _google_web_auth_checked:
		return _google_web_auth
	_google_web_auth_checked = true
	if OS.get_name() == "iOS" and ClassDB.class_exists(_GOOGLE_WEB_AUTH_CLASS):
		_google_web_auth = ClassDB.instantiate(_GOOGLE_WEB_AUTH_CLASS)
		if _google_web_auth != null:
			print("[GoogleSignIn] %s available." % _GOOGLE_WEB_AUTH_CLASS)
			_google_web_auth.connect("completed", _on_google_web_auth_completed, CONNECT_DEFERRED)
			_google_web_auth.connect("canceled", _on_google_web_auth_canceled, CONNECT_DEFERRED)
			_google_web_auth.connect("failed", _on_google_web_auth_failed, CONNECT_DEFERRED)
	else:
		print("[GoogleSignIn] %s NOT available (os=%s)." % [_GOOGLE_WEB_AUTH_CLASS, OS.get_name()])
	return _google_web_auth


func _on_google_web_auth_completed(callback_url: String) -> void:
	var id_token := _extract_fragment_param(callback_url, "id_token")
	if id_token == "":
		print("[GoogleSignIn] Callback URL carried no id_token.")
		_set_busy(false)
		_show_status("Google Sign-In failed. Please try again.")
		return
	print("[GoogleSignIn] Google ID token obtained: YES (len=%d). Starting Firebase exchange." % id_token.length())
	FirebaseAuth.sign_in_with_google_id_token(id_token)


func _on_google_web_auth_canceled() -> void:
	_set_busy(false)
	_clear_message()


func _on_google_web_auth_failed(message: String) -> void:
	print("[GoogleSignIn] ASWebAuthenticationSession failed: %s" % message)
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


## ---- Sign in with Apple (Firebase, iOS Auth Phase 1) ----
##
## ASAuthorizationController (vendored GodotApplePlugins AuthenticationServices extension
## - the SAME addon the iOS Google bridge above and game_center_cloud_backend.gd's Game
## Center backend already use) -> an ASAuthorizationAppleIDCredential's identity_token
## (PackedByteArray, decoded to a UTF-8 JWT string here) ->
## FirebaseAuth.sign_in_with_apple_id_token() -> accounts:signInWithIdp. Structural mirror
## of the Google Sign-In section above's NEEDS_LINK/linking flow. This button is hidden
## outright on every platform except iOS (see _refresh_view()), so reaching here with no
## extension means an iOS build that doesn't bundle it yet. NOT YET LIVE-VERIFIED against
## a real Apple ID on a device.
func _on_apple_continue_pressed() -> void:
	print("[AppleSignIn] Sign-in button pressed.")
	if _busy:
		return
	var auth := _apple_auth_instance()
	if auth == null:
		print("[AppleSignIn] %s unavailable." % _APPLE_AUTH_CLASS)
		_show_status("Sign in with Apple is unavailable on this build.")
		return
	_set_busy(true)
	_show_status("Sign in with Apple...")
	auth.call("signin_with_scopes", ["email", "full_name"])


## Lazily resolves and caches an ASAuthorizationController instance - same
## ClassDB.instantiate() pattern as _google_web_auth_instance() and
## game_center_cloud_backend.gd's PLUGIN_CLASS. iOS-only; every other platform gets null
## and every caller null-checks first.
func _apple_auth_instance() -> Object:
	if _apple_auth_checked:
		return _apple_auth
	_apple_auth_checked = true
	if OS.get_name() == "iOS" and ClassDB.class_exists(_APPLE_AUTH_CLASS):
		_apple_auth = ClassDB.instantiate(_APPLE_AUTH_CLASS)
		if _apple_auth != null:
			print("[AppleSignIn] %s available." % _APPLE_AUTH_CLASS)
			_apple_auth.connect("authorization_completed", _on_apple_authorization_completed, CONNECT_DEFERRED)
			_apple_auth.connect("authorization_failed", _on_apple_authorization_failed, CONNECT_DEFERRED)
	else:
		print("[AppleSignIn] %s NOT available (os=%s)." % [_APPLE_AUTH_CLASS, OS.get_name()])
	return _apple_auth


## credential is an ASAuthorizationAppleIDCredential (identity_token/email/full_name) on a
## real Sign in with Apple, or an ASPasswordCredential (iCloud Keychain autofill - never
## requested by signin_with_scopes()'s email/full_name scopes, so not expected here) or
## null for an unsupported type. Never reference either extension type statically (this
## script must still compile on platforms/builds where the extension isn't loaded) -
## checked structurally via has_method() instead, same convention
## game_center_cloud_backend.gd uses for its own untyped Object results.
func _on_apple_authorization_completed(credential: Object) -> void:
	if credential == null or not credential.has_method("get_identity_token"):
		print("[AppleSignIn] Unsupported credential type returned.")
		_set_busy(false)
		_show_status("Sign in with Apple failed. Please try again.")
		return
	var token_bytes: PackedByteArray = credential.get("identity_token")
	var identity_token := token_bytes.get_string_from_utf8()
	# Never log the token itself - only that one arrived. No nonce is sent: this vendored
	# module's signin_with_scopes() does not expose nonce control, so
	# FirebaseAuth.sign_in_with_apple_id_token() is called with raw_nonce="" (it already
	# handles that case - see its own comment on why a nonce is optional/defense-in-depth,
	# not a hard requirement of every code path).
	print("[AppleSignIn] Apple identityToken obtained: YES (len=%d). Starting Firebase exchange." % identity_token.length())
	FirebaseAuth.sign_in_with_apple_id_token(identity_token, "")


## This module reports both cancellation AND a genuine failure through the SAME
## authorization_failed signal - unlike the Android Google plugin's separate cancelled/
## failed signals, there is no distinct "user dismissed the sheet" signal here. Apple's
## own ASAuthorizationError.canceled case is heuristically detected by checking the
## localized message for "cancel" - THIS IS UNVERIFIED against a real device/iOS version
## (Phase 7/8's TEST G must confirm the real string, or that this even needs handling
## specially at all, before this is considered done).
func _on_apple_authorization_failed(error_message: String) -> void:
	_set_busy(false)
	if error_message.to_lower().contains("cancel"):
		print("[AppleSignIn] Treated as user cancellation: %s" % error_message)
		_clear_message()
		return
	print("[AppleSignIn] Native extension reported failure: %s" % error_message)
	_show_status("Sign in with Apple failed. Please try again.")


## Shared by the iOS Apple/Google bridges above for OAuth nonce/state values - a
## cryptographically random hex string, not tied to either provider's own crypto
## requirements (Google's implicit id_token flow only needs an unguessable nonce/state;
## this project does not itself verify either value, Firebase/Google's own servers do).
func _random_token(byte_length: int = 16) -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(byte_length).hex_encode()


## Extracts one key from a URL's fragment (the part after '#') - Google's implicit
## response_type=id_token flow returns id_token there, never in the query string.
func _extract_fragment_param(url: String, key: String) -> String:
	var frag_index := url.find("#")
	if frag_index == -1:
		return ""
	var fragment := url.substr(frag_index + 1)
	for pair: String in fragment.split("&"):
		var kv := pair.split("=", true, 1)
		if kv.size() == 2 and kv[0] == key:
			return kv[1].uri_decode()
	return ""


func _on_apple_sign_in_finished(success: bool, error_code: String, needs_link: bool, _is_new_user: bool) -> void:
	_set_busy(false)
	if success:
		_pending_apple_link = false
		_on_auth_success()
		if _is_new_user:
			CloudSave.sync_now()
		return
	if needs_link:
		var email := FirebaseAuth.pending_apple_link_email()
		_pending_apple_link = true
		_set_create_mode(false)
		if email != "":
			_email_field.text = email
		_password_field.text = ""
		_show_status("An account already exists for this email. Sign in with your password to link Apple.")
		return
	_show_error(_friendly_error(error_code))


func _on_apple_link_finished(success: bool, error_code: String) -> void:
	if success:
		_show_success("Apple account linked.")
	else:
		# The player is already signed in via password at this point (link only ever
		# runs after that succeeds) - a link failure is informational, not blocking.
		print("[AccountScreen] Apple link failed: %s" % error_code)
		if error_code != "OFFLINE":
			_show_status("Signed in. Apple linking will be retried later.")


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
	panel.theme_type_variation = &"DialogPanel"
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)
	var title := Label.new()
	title.text = "SIGN OUT OF YOUR BEAMSHIFT ACCOUNT?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 50)
	box.add_child(title)
	var body := Label.new()
	body.text = "Your progress will remain on this device."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 32)
	box.add_child(body)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = "CANCEL"
	cancel.custom_minimum_size = Vector2(0, 130)
	cancel.size_flags_horizontal = Control.SIZE_FILL
	cancel.theme_type_variation = &"SecondaryButton"
	cancel.add_theme_font_size_override("font_size", 38)
	cancel.pressed.connect(AudioManager.play_ui_button_press)
	cancel.pressed.connect(_close_sign_out_confirmation)
	row.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "SIGN OUT"
	confirm.theme_type_variation = &"DangerButton"
	confirm.custom_minimum_size = Vector2(0, 130)
	confirm.size_flags_horizontal = Control.SIZE_FILL
	confirm.add_theme_font_size_override("font_size", 38)
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
	FirebaseAuth.cancel_pending_apple_link()
	_pending_google_link = false
	_pending_apple_link = false
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
	_apple_continue_button.disabled = busy
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
		"FEDERATED_USER_ID_ALREADY_LINKED", "CREDENTIAL_ALREADY_IN_USE":
			return "This account is already linked to a different BeamShift account."
		"INVALID_IDP_RESPONSE":
			return "Sign-in failed. Please try again."
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
