# references/ci-cd.md — BeamShift iOS CI/CD pipeline

Referenced by `.github/workflows/release.yml`. This is the project's own reference for
the iOS build/signing/TestFlight pipeline: how it's triggered, what each stage does, what
secrets it needs, and how to bring up the first signed build safely. Update it whenever
the workflow changes — a stale reference here is worse than none.

**Status as of 2026-09-29: the iOS lane has never been executed.** Everything below
describes what the workflow is written to do, not what has been observed to work.

## 1. Overview

BeamShift ships from one workflow, `.github/workflows/release.yml` ("Release CD"), covering
both Android and iOS. This file documents the iOS side only — see `STORE_RELEASE.md` for
the Android/Play Console side, which has run successfully (Play Store device-verified).

The iOS lane produces one of two things depending on which secrets exist:
- **No Apple signing secrets**: an unsigned Xcode project, zipped as a build artifact.
  This is the most CI can legally produce without real Apple credentials.
- **Signing secrets present** (`APPLE_TEAM_ID`, `IOS_DIST_CERT_B64`,
  `IOS_PROVISIONING_PROFILE_B64`): a signed `.ipa`.
- **Signing + App Store Connect API secrets present**: the signed `.ipa` is additionally
  uploaded to TestFlight via `xcrun altool`.

## 2. Repository scope

This pipeline is specific to `bijju/beam-shiflt`, branch `dev_abhilas` (and `main` for
tag-triggered releases). It does not touch, and must never be extended to touch, any other
repository, organization secret, or shared Apple/Google resource outside the
BeamShift stores and the `com.foursagez.beamshift` bundle id.

## 3. iOS workflow trigger architecture

The iOS job (`ios-appstore`) only runs on:
- a pushed `v*` tag (must point at a commit already on `main` — enforced by the `guard`
  job), or
- a manual `workflow_dispatch` run with `lanes` set to `both` or `ios`.

It does **not** run on an ordinary push/merge to `main` — only the Android lane
(`android-play`) builds on every merge, to avoid burning macOS runner minutes (billed at a
10x multiplier) on commits with no iOS-specific change.

`workflow_dispatch` inputs relevant to iOS: `version` (required, `MAJOR.MINOR.PATCH`),
`lanes` (`both`/`ios`/`android`).

## 4. macOS runner architecture

`runs-on: macos-26` — pinned, not `macos-latest`. App Store Connect uploads have required
Xcode 26 and the iOS 26 SDK since 2026-04-28; an unpinned `-latest` label moves silently and
could drop below that floor without warning. The first step re-selects
`/Applications/Xcode_26.app` if present and hard-fails if the resolved Xcode major version
is below 26.

## 5. Godot iOS export flow

1. Cache/download Godot `4.7.1-stable` (macOS build) + export templates.
2. Cache AdMob platform binaries (`addons/admob/ios/bin`) — same cache key pattern as
   Android's.
3. Import the signing certificate (`apple-actions/import-codesign-certs`) and decode +
   install the provisioning profile — both gated on `has_ios` (cert + profile + team id all
   present).
4. `tools/ci/stamp_version.sh` — stamps the version everywhere it must agree (see section 7
   below) and, when the secrets exist, the Apple team id and provisioning profile UUID into
   `export_presets.cfg`'s iOS preset.
5. `tools/ci/stamp_store_config.sh ios` — AdMob iOS ids.
6. Install `godot-store-kit` (StoreKit 2 GDExtension, pinned `v1.5.0`) — not vendored in git
   (macOS-only symlinked frameworks a Windows checkout cannot hold).
7. Install `GodotApplePluginsGameCenter` + `GodotApplePluginsAuthenticationServices` +
   `GodotApplePluginsRuntime` from the pinned `GodotApplePlugins` release build
   (`bfade13ff8b6027ede438bac637b5bf93057d404`) — also not vendored, for the same reason.
8. Headless `--import`, then two fail-fast verification steps: the StoreKit extension
   registered in `.godot/extension_list.cfg`, and the Game Center extension registered.
   **A third check, AuthenticationServices registration, was added in this pass** (see
   section 8) — before this pass, only Game Center was checked even though
   AuthenticationServices is installed by the same step.
9. `godot --headless --export-release "iOS" build/ios/BeamShift.ipa` — Godot itself writes
   the Xcode project, archives it, and (when signing material is present) exports the signed
   `.ipa`. Without Apple secrets, `application/export_project_only` is temporarily flipped to
   `true` in `export_presets.cfg` (in-memory on the runner only — this repo's own
   `export_presets.cfg` is never committed with that flip) so Godot writes the unsigned
   Xcode project instead of attempting to sign.

## 6. Apple signing architecture

Signing is **entirely secret-driven, never automatically provisioned**. Three pieces of
material are required together to produce a signed `.ipa`:
- `IOS_DIST_CERT_B64` + `IOS_DIST_CERT_PASSWORD` — a `.p12` (Apple Distribution certificate
  + private key), imported into a temporary runner keychain by
  `apple-actions/import-codesign-certs`.
- `IOS_PROVISIONING_PROFILE_B64` — a `.mobileprovision`, decoded, installed into
  `~/Library/MobileDevice/Provisioning Profiles/`, and its UUID extracted (`plutil -extract
  UUID`) and stamped into `export_presets.cfg`'s `application/provisioning_profile_uuid_release`
  (see section 7 — this key did not exist in the preset before this pass and was the
  confirmed CI blocker).
- `APPLE_TEAM_ID` — stamped into `application/app_store_team_id`. Godot 4.7 refuses to
  export the iOS preset at all with an empty team id (even for the unsigned project export),
  so a placeholder `XXXXXXXXXX` is substituted when the secret is absent.

All signing material is removed from the runner at the end of the job (`if: always()`),
including on failure: the decoded `.p12`/temporary keychain (via
`apple-actions/import-codesign-certs`'s own teardown), the decoded `.mobileprovision`/`.plist`,
the installed profile (by its extracted UUID), and — in the upload step — the decoded ASC
`.p8` private key.

## 7. Provisioning profile architecture

- The profile must be created specifically for `com.foursagez.beamshift` — a profile scoped
  to a different bundle id will fail signing with a clear Apple-side error, not silently
  sign the wrong bundle.
- The profile must authorize **Sign in with Apple** (the `com.apple.developer.applesignin`
  entitlement, already present in `export_presets.cfg`'s `entitlements/additional` — see
  section 9). A profile generated before this entitlement was added to the App ID's
  capabilities will not carry it.
- **Any future entitlement change invalidates the existing profile** — a new/regenerated
  profile is required whenever `entitlements/additional` or `entitlements/game_center`
  changes (this is Apple's own behavior, not a BeamShift-specific rule; `STORE_RELEASE.md`
  Batch D already documents this for the current entitlement set).
- `IOS_PROFILE_UUID` (extracted at runtime, not a secret you supply directly) is threaded
  from the "Install provisioning profile" step into `tools/ci/stamp_version.sh` via
  `$GITHUB_ENV`, which stamps `application/provisioning_profile_uuid_release` in
  `export_presets.cfg` before the export step runs.
- **CI blocker fixed in this pass**: `export_presets.cfg`'s iOS preset did not contain the
  `application/provisioning_profile_uuid_release` key at all — `stamp_version.sh`'s `sub()`
  helper requires an exact count of existing matching lines before substituting, so the
  script would have failed with `stamp failed: ios profile uuid matched 0 line(s), expected 1`
  the first time a real `IOS_PROVISIONING_PROFILE_B64` secret was ever supplied. The key now
  exists, empty (`application/provisioning_profile_uuid_release=""`), exactly like its
  sibling `provisioning_profile_specifier_release`. Verified in isolation: `stamp_version.sh`
  was run against a temporary copy of `export_presets.cfg`/`project.godot` with a dummy team
  id and a dummy UUID and correctly substituted both; the real, committed preset was never
  touched with fake signing data and still carries the empty key.

## 8. AuthenticationServices requirement

Sign in with Apple and the iOS Google Sign-In bridge (both in `scripts/ui/account_screen.gd`)
depend on the `GodotApplePluginsAuthenticationServices` GDExtension module, fetched from the
same pinned `GodotApplePlugins` release build as `GodotApplePluginsGameCenter` (see section
5, step 7) — no separate download, no separate pin. Before this pass, only the Game Center
extension's registration was verified after import; a silently-missing or renamed
AuthenticationServices `.gdextension` inside that release zip would have gone undetected
until a real device tried to use it (`ClassDB.instantiate()` returning `null`, surfaced only
as "Sign in with Apple is unavailable on this build." in the account screen).

**Added in this pass**: a fail-fast step, "Verify the AuthenticationServices extension
registered", immediately after the existing Game Center check. It locates the installed
module's `.gdextension` file by glob (not a hardcoded filename guess) under
`addons/GodotApplePluginsAuthenticationServices/`, fails if none exists, then fails if that
exact filename is not present in `.godot/extension_list.cfg` (i.e. Godot did not register it
during `--import`).

## 9. Sign in with Apple entitlement requirement

`export_presets.cfg`'s iOS preset `entitlements/additional` includes
`<key>com.apple.developer.applesignin</key><array><string>Default</string></array>`
alongside the existing iCloud/Game Center entitlements. This was added in the prior iOS
Authentication pass (see `CLAUDE.md`'s iOS Authentication rules, D116) and is a hard
requirement of the vendored `AuthenticationServices` module's own documented setup — do not
remove it while the account screen offers Sign in with Apple.

## 10. First signed-build procedure

See section 13 below ("first workflow run should NOT upload...") for the exact sequencing.
In short: get signing-only secrets (`APPLE_TEAM_ID`, `IOS_DIST_CERT_B64`,
`IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_B64`) into GitHub Actions secrets
**without** the App Store Connect upload secrets, run `workflow_dispatch` with `lanes: ios`,
confirm a signed `.ipa` artifact is produced, download and inspect it
(`codesign -dv --verbose=4`, `unzip -l`), and only once that is repeatable, add the ASC
secrets to enable the TestFlight upload step.

### 10a. First-run prerequisites (exact)

**Apple assets** (created by the owner in the Apple Developer portal; never auto-generated):
- Apple Distribution certificate exported as `.p12`, and its export password.
- App Store provisioning profile for `com.foursagez.beamshift`, generated **after** the App ID
  has Sign in with Apple, iCloud, Game Center and In-App Purchase enabled, with the iCloud
  container `iCloud.com.foursagez.beamshift` assigned. A profile made earlier lacks those
  entitlements and signing/export will fail.
- Team ID.

**GitHub secrets** (names fixed, do not rename): `APPLE_TEAM_ID`, `IOS_DIST_CERT_B64`,
`IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_B64`. `ASC_KEY_ID` / `ASC_ISSUER_ID` /
`ASC_API_PRIVATE_KEY` are NOT needed and must stay unset for the first run.

**Profile stamping:** the "Install provisioning profile" step reads BOTH `UUID` and `Name`
from the decoded profile's plist (`plutil -extract`), fails with an `::error::` if either is
empty, and exports `IOS_PROFILE_UUID` / `IOS_PROFILE_NAME`. `tools/ci/stamp_version.sh`
stamps them into `provisioning_profile_uuid_release` and `provisioning_profile_specifier_release`
(and refuses a UUID without a Name). No profile name is hardcoded anywhere.

**Versioning:** dispatch `version=1.0.1` -> `CFBundleShortVersionString=1.0.1`,
`CFBundleVersion=10001.<run_number>.<run_attempt>` (e.g. 10001.9.1: major*10000+minor*100+patch, then the GitHub run number and attempt; `IOS_BUILD_RUN` in `tools/ci/stamp_version.sh`, iOS only). It deliberately does not match the
Android build number (10004); Apple needs a higher build number for every upload of the same version, and run_number only grows, so a repeated `1.0.1` run can never collide. Android is unchanged (still major*10000+minor*100+patch).

**IPA validation:** the "Validate the built IPA" step runs after the export and before the TestFlight upload and fails the job on any mismatch (bundle id, version, build number, production AdMob id vs `ADMOB_IOS_APP_ID` without printing it, not the Google sample id, 50 SKAdNetworkItems, no NSUserTrackingUsageDescription, ITSAppUsesNonExemptEncryption=false, PrivacyInfo.xcprivacy with NSPrivacyTracking=false and no tracking domains). **TestFlight upload:** runs only when `has_ios` and `has_ios_upload` (ASC_KEY_ID, ASC_ISSUER_ID, ASC_API_PRIVATE_KEY) are true AND (the ref is a `v*` tag OR the manual `testflight_upload` box is ticked).

**The run:** manual `workflow_dispatch`, `lanes=ios`, `version=1.0.1`, artifact only, no
TestFlight upload. The workflow file must exist on the default branch (`main`) before GitHub
lists the "Run workflow" button; the run itself can then target another branch via the
branch selector.

## 11. TestFlight procedure

The upload step (`Upload to App Store Connect (TestFlight)`) runs only when **both**
`has_ios` (signing) and `has_ios_upload` (`ASC_KEY_ID`, `ASC_ISSUER_ID`,
`ASC_API_PRIVATE_KEY`) are true. It writes the ASC `.p8` key to a temporary path and calls
`xcrun altool --upload-app`. If only the ASC secrets are withheld, the signed `.ipa` is still
produced and kept as a workflow artifact — this is the mechanism for testing signing in
isolation before ever touching TestFlight (see section 13).

## 12. Physical iPhone QA requirement

Per `CLAUDE.md` rule 12a/12d and the iOS Authentication rules (D116), nothing about Sign in
with Apple or the iOS Google Sign-In bridge may be described as device-verified without a
real iPhone/iPad test. `tools/ios_plugin_src/README.md` lists the exact open questions: the
Apple cancellation-message heuristic, whether Google's OAuth endpoint honors
`response_type=id_token` for this iOS client type and returns it in the callback URL's
fragment, and whether an `Info.plist` `CFBundleURLTypes` entry is additionally needed. See
`TEST_PLAN.md`'s manual iPhone test plan for the full checklist once a Mac/iPhone are
available — CI producing a signed `.ipa` is a necessary precondition for that testing, not a
substitute for it.

## 13. Troubleshooting checklist

- **`stamp failed: ... matched 0 line(s)`** — a key `stamp_version.sh` expects to substitute
  does not exist (or exists more than once) in `export_presets.cfg`. Check the exact
  `pattern` argument in `tools/ci/stamp_version.sh` against a `grep -n` of the preset before
  assuming the script is broken.
- **Godot refuses to export the iOS preset at all** — check `application/app_store_team_id`
  is non-empty (a placeholder `XXXXXXXXXX` is used when `APPLE_TEAM_ID` is absent — this is
  expected for an unsigned-project export, not a bug).
- **A signed `.ipa` is missing or under 10 MB** — the export step treats this as a failure
  (`exit 1`); check the Xcode/xcodebuild logs earlier in the same step for the actual signing
  error (wrong bundle id in the profile, expired certificate, missing entitlement in the
  profile).
- **AuthenticationServices/Game Center/StoreKit "not registered" errors** — almost always
  means the `--headless --import` step ran before the extension was copied into `addons/`,
  or the pinned release zip's internal folder layout changed. Re-check the `find`/`unzip`
  commands in the relevant install step, not the Godot project itself.
- **TestFlight upload fails but the `.ipa` was signed successfully** — check `ASC_KEY_ID`/
  `ASC_ISSUER_ID` match the App Store Connect API key's actual values (Users and Access →
  Integrations → Team Keys), and that the key's role has upload permission (App Manager or
  above).
- **A workflow run reports success but nothing was uploaded anywhere** — check `has_ios`/
  `has_ios_upload` in the `guard` job's output; a green run with missing secrets is
  documented, expected behavior (an unsigned project export, or a signed `.ipa` kept only as
  an artifact), never a silent store upload.

## 14. Secret-handling rules

**Never** put secret values in this file, in any other doc, in logs, in screenshots, or in
generated reports — names only, always.

Required for a signed IPA:
- `APPLE_TEAM_ID`
- `IOS_DIST_CERT_B64`
- `IOS_DIST_CERT_PASSWORD`
- `IOS_PROVISIONING_PROFILE_B64`

Required additionally for a TestFlight upload:
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_API_PRIVATE_KEY`

(See `STORE_RELEASE.md` section 6b for the full secret list across both platforms, including
Android's.)

Every secret above is consumed only via `env:`/`secrets.*` context inside the workflow —
never interpolated into a shell command line where it could appear in a trace — and every
step that materializes secret bytes to disk (`.p12`, `.mobileprovision`, `.p8`) removes them
at the end of the job unconditionally (`if: always()`).
