# iOS Authentication Bridge — SOURCE-LEVEL DECISION RECORD, NOT A BUILDABLE PLUGIN FOLDER

> **2026-10-01:** Firebase was removed. Only Sign in with Apple (`scripts/managers/platform_account.gd`) uses the
> AuthenticationServices module now; the iOS Google OAuth bridge and every Firebase token exchange described below are gone.

Written during the iOS Authentication + Cross-Platform Cloud Save pass (2026-09-29).
Unlike `tools/android_plugin_src/google_signin/` (an uncompiled Kotlin *source* module
you build yourself), this folder holds no native source at all — because none was
needed. Read this before assuming a Swift plugin needs to be written here.

## What was found during inspection

This project already vendors one third-party iOS GDExtension for native Apple APIs:
**GodotApplePlugins** (`github.com/migueldeicaza/GodotApplePlugins`, SwiftGodot-based),
pinned at build `bfade13ff8b6027ede438bac637b5bf93057d404` in
`.github/workflows/release.yml`, currently used for `GodotApplePluginsGameCenter`
(`scripts/cloud/game_center_cloud_backend.gd`, cloud save).

That same repository — and the exact same pinned release build (confirmed by downloading
and inspecting its zip contents during this pass) — also ships
**`GodotApplePluginsAuthenticationServices`**, a module wrapping Apple's
`AuthenticationServices` framework with two classes relevant here:

- **`ASAuthorizationController`** — Sign in with Apple. `signin_with_scopes(["email",
  "full_name"])` → `authorization_completed(credential)` /
  `authorization_failed(error_message)`. `credential` (an
  `ASAuthorizationAppleIDCredential`) exposes `identity_token` (`PackedByteArray`, the
  JWT to hand to Firebase), `email`, `full_name`, `user`.
- **`ASWebAuthenticationSession`** — a generic system-presented OAuth browser sheet
  (`start(auth_url, callback_scheme, prefers_ephemeral)` →
  `completed(callback_url)` / `canceled()` / `failed(message)`). Not Apple-specific —
  this is what the iOS Google Sign-In bridge below reuses.

Both are plain `RefCounted` GDExtension classes, **not** Engine singletons — instantiated
per use via `ClassDB.instantiate("ASAuthorizationController")` /
`ClassDB.instantiate("ASWebAuthenticationSession")`, exactly the pattern
`game_center_cloud_backend.gd` already uses for `GameCenterManager`. Signals are
`CONNECT_DEFERRED` for the same documented reason as Game Center's (SwiftGodot calls back
off the main thread).

## Why no new native code was written

`ASWebAuthenticationSession` is a *generic* OAuth bridge, not tied to Apple's own
identity system. Google publishes no first-party Godot plugin, and this project's
standing architecture deliberately avoids vendoring a large third-party Google iOS SDK
(the brief itself: "Do NOT blindly add a large third-party Firebase SDK if it is not
required"). Opening Google's own OAuth 2.0 authorization endpoint
(`https://accounts.google.com/o/oauth2/v2/auth`) directly inside the SAME
`ASWebAuthenticationSession` sheet — requesting `response_type=id_token` so the callback
URL's fragment already carries a Firebase-ready ID token, no server-side code exchange
needed — reuses the one already-vendored extension for both providers. Writing a second,
bespoke Swift plugin (Apple *and* Google) would have duplicated functionality this
project already ships and trusts for Game Center, for no benefit.

**Net result: zero new Swift source, zero new GDExtension, one new CI vendoring step**
(`.github/workflows/release.yml`'s "Install the Game Center + AuthenticationServices
extensions" step — same pinned build, one more module name in the existing loop), one
new entitlement (`export_presets.cfg`'s `entitlements/additional` gained
`com.apple.developer.applesignin`, exactly as the module's own
`AuthenticationServicesGuide.md` documents), and the GDScript bridge logic living
directly in `scripts/ui/account_screen.gd` (its "Sign in with Apple" and "Google
Sign-In on iOS" sections) + `scripts/managers/firebase_auth.gd` (`sign_in_with_apple_id_token()`
/ `link_pending_apple_credential()`, a structural mirror of the already-verified
`sign_in_with_google_id_token()`/`link_pending_google_credential()` pair from the Android
pass).

## What is verified vs. not

**Verified this pass (desktop, source-level):**
- The pinned GodotApplePlugins release build genuinely contains a built
  `GodotApplePluginsAuthenticationServices.xcframework` (real device arm64 + simulator
  slices) — downloaded and inspected directly, not assumed from the repo's docs alone.
- `account_screen.gd`/`firebase_auth.gd` parse cleanly (a temporary `run/main_scene` swap
  to `account_screen.tscn`, headless run, reverted immediately — the project's own
  established technique).
- The GDScript never references `ASAuthorizationController`/`ASWebAuthenticationSession`
  as a static type (only by string via `ClassDB`), so this script compiles and no-ops
  safely on every platform where the extension isn't loaded — confirmed by the same
  headless run succeeding on this Windows desktop machine, which has neither.

**NOT verified — needs macOS/Xcode and a physical iPhone (see `TEST_PLAN.md`'s iOS
manual test plan and `STORE_RELEASE.md`'s iOS section):**
1. That the CI vendoring step actually produces a working export (needs a real macOS CI
   run or local Xcode export).
2. That `ASAuthorizationController.signin_with_scopes()` actually returns a usable
   `identity_token` end-to-end through `FirebaseAuth.sign_in_with_apple_id_token()` on a
   real Apple ID.
3. That `authorization_failed`'s message text for a user-cancelled sheet really does
   contain "cancel" (account_screen.gd's `_on_apple_authorization_failed()` heuristic) —
   if this module distinguishes cancellation differently, that function needs a fix
   before Phase 8's TEST G ("cancel without a false failure state") can pass.
4. That Google's OAuth endpoint actually honors `response_type=id_token` for an
   "iOS" OAuth client type via a custom-scheme `ASWebAuthenticationSession` redirect, and
   that the resulting callback URL's **fragment** (not query string) carries `id_token=`
   as assumed by `account_screen.gd`'s `_extract_fragment_param()`. If Google instead
   requires an authorization-code + PKCE flow for this client type, the iOS Google bridge
   needs a real (larger) follow-up: exchange the `code` for tokens via
   `https://oauth2.googleapis.com/token` (still no vendored SDK required, just one more
   `HTTPRequest` call, structurally similar to `FirebaseAuth`'s own `_post_form()`).
5. That no additional `CFBundleURLTypes` entry is required in the iOS Info.plist for
   `ASWebAuthenticationSession`'s custom-scheme callback to route back into the app
   reliably on every iOS version this project targets (`min_ios_version="17.0"`) —
   Apple's documented behavior is that the session itself intercepts the callback without
   requiring `open(_:options:)` handling, but this has not been confirmed on-device.

Do not mark iOS Sign in with Apple or Google as DEVICE VERIFIED until items 2–5 are
confirmed on a real iPhone, per `CLAUDE.md` rule 12a/12d and this pass's own brief.
