# GodotGoogleSignIn plugin — SOURCE ONLY, NOT COMPILED, NOT VERIFIED

Written during BeamShift Google Sign-In + Firebase Auth Phase 4A (2026-09-28). This
folder is a **buildable Gradle Android library module**, not yet compiled into an `.aar`
and not yet placed under `addons/`. It could not be compiled or tested in the pass that
wrote it because the environment's command-execution sandbox (the tool that runs shell/
Gradle commands) was unavailable for the entire session — see `STORE_RELEASE.md` section
13 for the full status. Nothing here has been built, imported by Godot, or run.

## What this is

A Godot 4.x Android plugin (same shape as `addons/GodotPlayGameServices` and
`addons/GodotGooglePlayBilling`, which ship as prebuilt `.aar` files in this project —
their Kotlin/Java source isn't in this repo, only their compiled output) wrapping
Android's **Credential Manager** API (`androidx.credentials`) to obtain a Google ID
token for `FirebaseAuth.sign_in_with_google_id_token()`
(`scripts/managers/firebase_auth.gd`).

Exposed to GDScript as singleton `"GodotGoogleSignIn"`:
- `signIn(server_client_id: String)` — launches Credential Manager's Google Sign-In
  flow for the current Activity.
- signal `google_id_token_obtained(id_token: String)`
- signal `google_sign_in_failed(reason: String)`

`scripts/ui/account_screen.gd`'s `_google_plugin_instance()` already checks
`Engine.has_singleton("GodotGoogleSignIn")` and fails safely (shows a message, never
crashes) when this plugin isn't present — which is the case for every build until this
module is actually compiled and wired in. Desktop and iOS are unaffected either way
(`OS.get_name() == "Android"` gates every lookup).

## What is NOT done

1. **Not compiled.** No `.aar` exists. `./gradlew assembleDebug` (or equivalent) has
   never been run against this module in this environment.
2. **Not wired into the export.** `addons/GodotGoogleSignIn/plugin.cfg` +
   `export_plugin.gd` (the files that make Godot's Android export embed the `.aar`,
   following `addons/GodotPlayGameServices/export_plugin.gd`'s exact pattern) do not
   exist yet — deliberately not added yet, since a `plugin.cfg` pointing at a
   non-existent `.aar` path would risk breaking the Android export rather than failing
   safely.
3. **Dependency versions are approximate**, chosen from training-data knowledge (cutoff
   January 2026) and NOT re-verified against Maven Central / current Google docs in this
   pass (the same sandbox outage blocked `WebFetch`/`WebSearch` too). Bump
   `androidx.credentials:credentials`, `androidx.credentials:credentials-play-services-auth`,
   and `com.google.android.libraries.identity.googleid:googleid` to their current stable
   versions before building.
4. **Never compiled against this project's actual `godot-lib` AAR.** The
   `compileOnly files(...)` path below points at
   `android/build/libs/debug/godot-lib.template_debug.aar`, which does exist in this repo
   (confirmed by directory listing), but the module has never actually been built
   against it.
5. **No device/emulator test of any kind.**

## To finish this (once command execution is available)

1. Review/bump the dependency versions in `build.gradle` below against current Maven
   Central listings.
2. `./gradlew :google_signin:assembleDebug` (from a Gradle root that includes this
   module — the simplest path is temporarily adding it as a module of
   `android/build/`'s existing Gradle project, or building it as its own standalone
   Gradle project against the vendored `godot-lib` AAR).
3. Copy the resulting `.aar` to `addons/GodotGoogleSignIn/bin/debug/GodotGoogleSignIn-debug.aar`.
4. Add `addons/GodotGoogleSignIn/plugin.cfg` + `export_plugin.gd`, mirroring
   `addons/GodotPlayGameServices/plugin.cfg`/`export_plugin.gd` exactly (name
   `GodotGoogleSignIn`, `_get_android_libraries()` returning this AAR path, no extra
   manifest metadata needed since Credential Manager needs no API key in the manifest).
5. Re-export the debug APK and confirm `Engine.has_singleton("GodotGoogleSignIn")` is
   true on-device, then run the real Google Sign-In flow against the account screen.
6. Only after a real device confirms an ID token round-trip should this be considered
   verified — per this project's own standing rule (CLAUDE.md 12a/12d), a desktop/
   headless run cannot exercise this at all (Credential Manager needs a real Activity +
   a real Google account on the device).
