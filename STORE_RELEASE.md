# STORE_RELEASE.md — Google Play + App Store release (store-release pass, 2026-09-26)

Built with the `godot-store-release` playbook. This file is the project's own reference for everything store-facing:
decisions, architecture, what is done in code, and the console work that only the owner can do. Update it as batches
complete — a stale checklist is worse than none.

## 1. Decisions (owner, 2026-09-26)

| Item | Decision |
|---|---|
| Bundle / package id | **`com.foursagez.beamshift`** (fixed forever after the first upload; the old `com.beamshift.game` was internal QA only) |
| Accounts | Play Console + Apple Developer, both **organization** accounts (no 12-tester/14-day closed test) |
| Devices | Android phones/tablets (arm64 + armeabi-v7a); **iPhone + iPad** (iPad 13" screenshots required) |
| Audience | **Includes children under 13** → Play Families policy + COPPA apply; **not** in Apple's Kids category |
| Ads | Existing rewarded hint + interstitial, **child-safe for everyone** (`AdConfig.CHILD_DIRECTED`: TFCD + TFUA + rating G, non-personalised, no ATT/IDFA) — `ADS_MONETIZATION.md` 6a |
| IAP | ONE non-consumable: **`beamshift_no_forced_ads`, "No Forced Ads", US $3.99** — removes interstitials only; the optional rewarded hint video stays (owner decision). Never call it "Remove Ads" |
| Cloud save | **Yes**: Play Games Services Saved Games (Android), Game Center saved games stored in iCloud (iOS) |
| Version | Stores start at **1.0.0 = build code 10000** (`major*10000+minor*100+patch`, one scheme for both stores, stamped by `tools/ci/stamp_version.sh`) |

## 2. Architecture (all store SDKs behind SDK-free autoloads)

| Autoload (knows no SDK) | Android backend | iOS backend | Config |
|---|---|---|---|
| `AdManager` (existing) | `scripts/ads/ad_backend_admob.gd` (both platforms) | same | `AdConfig` |
| **`StoreManager`** (6th) | `scripts/store/play_billing_backend.gd` (GodotGooglePlayBilling 3.3.0) | `scripts/store/store_kit_backend.gd` (godot-store-kit 1.5, StoreKit 2, iOS 17) | `StoreConfig` |
| **`CloudSave`** (7th, after the plugin's `GodotPlayGameServices` autoload) | `scripts/cloud/play_games_cloud_backend.gd` (GodotPlayGameServices 3.4.0) | `scripts/cloud/game_center_cloud_backend.gd` (GodotApplePlugins, pinned build) | constants in `cloud_save.gd` |

Rules (each fixed a real bug in the reference game — do not relax):
- Backends are loaded **by path**, only on Android/iOS, and kept only if their plugin is present. Desktop/editor: no store, no
  cloud, the game is unchanged (Settings hides those rows).
- iOS GDExtensions are driven through `ClassDB` by name and **every plugin signal is `CONNECT_DEFERRED`** (SwiftGodot calls back
  off the main thread; `add_child()` there is refused and UI comes up empty). The autoloads also connect their backends deferred.
- **Entitlements live in `SaveManager.entitlements`** (offline, first frame) and are re-checked with the store every launch. Only a
  completed full purchase query may revoke. Entitlements **never travel with a cloud profile**.
- Purchases are acknowledged on Play (unacknowledged = auto-refund after 3 days). Restore Purchases is in Settings (Apple 3.1.1).
- AdMob callbacks are named methods only + `release()` teardown (iOS swipe-away crash under Godot 4.7) + an 8 s consent watchdog.
- iOS plugins are **not vendored**: the macOS CI job downloads godot-store-kit v1.5.0 and GodotApplePlugins
  `build-bfade13…` (their macOS frameworks use symlinks a Windows checkout cannot hold).

### Cloud save policy (`scripts/managers/cloud_save.gd`)
- Pull **once**, on the first successful sign-in. Merge = **more `play_time_seconds` wins, ties on `saved_at`**.
- `play_time_seconds` counts only a board on screen, not paused, not solved, not an editor playtest (`game.gd _process`) — menu time
  never counts, so a fresh install stays at 0.
- **Fresh install (local play time 0) adopts the cloud copy without asking** (before the threshold check). Past **1 h** difference the
  main menu shows a chooser ("WHICH PROGRESS?", level + play time for each side); Back leaves the question pending.
- A cloud copy that lands mid-level is held until the main menu. Push throttled to one per 45 s, flushed on app pause.
- `SaveManager.adopt_cloud_data()` keeps LOCAL: entitlements, sound/music, interstitial cadence (`ad_*`).
- NEW GAME keeps `play_time_seconds` (a lifetime total) so the reset run is pushed, not overwritten by the old cloud copy.

## 3. Where every identifier goes

| Value | Where | Status |
|---|---|---|
| Bundle id | `export_presets.cfg` all 3 presets | done |
| Play Games **Game ID** (PGS project number) | both Android presets `godot_play_game_services/game_id` | **EMPTY — every Android build fails until set** (AAPT: `string/game_services_project_id not found`) |
| AdMob **App IDs** (`~`) | `project.godot` `admob/general/android/app_id`, `admob/general/ios/app_id` (plugin default = Google sample) | sample IDs |
| AdMob **unit IDs** (`/`) | `AdConfig.PRODUCTION_IDS` (never committed) + `USE_TEST_IDS=false` | test IDs |
| IAP product id | `StoreConfig.NO_FORCED_ADS` — must equal both consoles | done |
| Privacy policy URL | `StoreConfig.PRIVACY_POLICY_URL` (Settings button hidden while empty) | **EMPTY** |
| Apple Team ID / profile UUID | stamped by CI from secrets — **left empty in git** | — |
| iCloud container | `iCloud.com.foursagez.beamshift` in the iOS preset `entitlements/additional` | must be registered + ASSIGNED in the portal |

## 4. Verified in this pass (AUTOMATED / RENDERED — not MANUAL)

- Headless import + game boot: no errors. `_qa_tmp` driver, 25/25: every backend compiles against its plugin; desktop store/cloud
  unavailable and purchase reports unavailable; fallback price; owned → interstitial dropped and never shown, rewarded hint still
  an ad; not owned → interstitials reload; save round-trip of the new fields; adopt keeps entitlements/sound; fresh-install adopt,
  two-unplayed no-op, far-behind-still-asks, small-gap silent. The real user save was restored byte-identical.
- RENDERED Settings (1080x1920 logical, all rows forced visible): fits (panel 1802 px); absolute worst case incl. Privacy Options +
  message 1918 px.
- Local debug APK (placeholder Game ID, then reverted): `com.foursagez.beamshift` 1.0.0/10000, arm64+armeabi-v7a, `BILLING`,
  `ProxyBillingActivity`, PGS `APP_ID`, AdMob `APPLICATION_ID` (sample), no dev folders in the APK.
- iOS Xcode project exported on Windows (project-only, placeholder team, reverted): entitlements = Game Center + iCloud container +
  ubiquity + CloudDocuments; iOS 17.0; device family 1,2; `ITSAppUsesNonExemptEncryption=false`; 50 SKAdNetwork ids;
  `GADApplicationIdentifier` (sample); `NSPrivacyTracking=false`; no `NSUserTrackingUsageDescription`; 1024 icon RGB (no alpha).
- NOT verified: anything on a device, real purchases, sign-in, the CI workflow (never run), the YAML (no linter on this machine).

## 4b. Current target: INTERNAL TESTING ONLY (owner, 2026-09-26)

Minimum path (Play internal track; no review, no listing, no Data safety/IARC, no privacy policy yet, Google TEST ad ids,
`BuildConfig` stays `MODE_EXTERNAL_TEST`):
1. Play Console → Create app (B.1). 2. Create the PGS project + Cloud project (C.1-C.4) → **Game ID** → I set it in both Android
presets. 3. Owner makes the upload keystore (A.4) and enters it in Godot's Export dialog (Release keystore/alias/password → stored in
the gitignored `.godot/export_credentials.cfg`; the password never goes through chat). 4. I export the signed AAB
(`--export-release "Android"`) and verify it (`keytool -printcert -jarfile`, manifest). 5. Owner uploads it by hand to Internal testing,
accepts Play App Signing, adds testers, rolls out. 6. Then (Play needs a BILLING build uploaded first): the IAP product (B.5), License
testers (B.4), App Signing SHA-1 → PGS credentials + PGS testers (C.5-C.6). 7. Testers install from the opt-in link (billing and
Play-signed sign-in only work in Play-installed builds).
iOS TestFlight internal testing needs Batch D + F.1-F.2 + the CI secrets (Batch G); the Paid Apps Agreement only gates IAP testing.
Everything else in section 5 (policy, listing, AdMob live ids, forms) is deferred to the public release.

## 5. Console batches for the owner

Do them in order; each ends with what to send back. Keep every signing file in `%USERPROFILE%\Documents\beamshift-signing\`
(outside the repo), backed up offline.

### Batch A — lead-time items (start today)
1. **Apple → Business → Paid Apps Agreement** (Account Holder): accept → Contacts → Bank → Tax (W-9 for a US entity, W-8BEN-E otherwise) →
   wait for **Active**. StoreKit returns NO products until then, and no build fixes it.
2. **AdMob account** in the **payee's country** (fixed at sign-up) + payment verification.
3. **Host a privacy policy** (e.g. GitHub Pages `index.html`) covering: ads (AdMob, child-directed, non-personalised), advertising ID,
   the in-app purchase, cloud save via Google Play Games / Game Center + iCloud, children under 13 (COPPA), contact email.
   Also a **developer website** with `/app-ads.txt` (see Batch E).
4. **Upload keystore** (run yourself; choose and keep the password safe — never share it in chat):
   ```
   "C:\Users\shiva\tools\jdk-17.0.20.1+1\bin\keytool.exe" -genkeypair -v -keystore "%USERPROFILE%\Documents\beamshift-signing\beamshift-upload.keystore" -alias beamshift -keyalg RSA -keysize 2048 -validity 9125
   ```
   Then set it in Godot: Project → Export → Android (both presets) → Keystore → Release (stored in the gitignored
   `.godot/export_credentials.cfg`).
**Send back:** the privacy policy URL, the developer website URL, your support email + phone, and "Paid Apps Agreement: Active" when it flips.

### Batch B — Play Console, part 1 (create the app, get the signing SHA-1)
1. All apps → **Create app**: name "BeamShift", English, **Game**, **Free**, accept declarations.
2. I produce a signed AAB once the Game ID exists (Batch C gives it) — or, to break the loop, create the PGS project first (C.1-4)
   and send me its Game ID. Upload that first AAB **by hand** to **Test and release → Internal testing**, accept **Play App Signing**.
3. **Setup → App signing → App signing key certificate → SHA-1**: copy it.
4. **Settings → License testing**: add every tester Gmail (free test purchases). **Internal testing → Testers**: the same emails.
5. **Monetise → Products → One-time products → Create**: id `beamshift_no_forced_ads`, name "No Forced Ads", description
   "Removes all interrupting ads. Optional hint videos stay available.", one purchase option, **US $3.99** → **Activate**.
**Send back:** the App Signing SHA-1, confirmation the product is Active.

### Batch C — Play Games Services + Google Cloud (cloud save)
1. console.cloud.google.com → new project "BeamShift" (no billing needed).
2. APIs & Services → Library → enable **Google Drive API** and **Google Play Games Services API** (not Publishing/Management).
3. OAuth consent screen (Google Auth Platform): External, app name, support + developer email.
4. Play Console → **Grow users → Play Games Services → Setup and management → Configuration** → create a PGS project, link the
   Cloud project. **Edit properties → Saved games: On** (one-way once published), add the description.
5. **Credentials → Add credential → Android**, anti-piracy **off**: one for the **App Signing SHA-1** (Batch B.3), and a second with
   **"Use for new installs" unchecked** for your debug keystore — its SHA-1:
   ```
   "C:\Users\shiva\tools\jdk-17.0.20.1+1\bin\keytool.exe" -list -v -keystore "%APPDATA%\Godot\keystores\debug.keystore" -storepass android
   ```
6. **Testers** (PGS list — a third, separate list): add every tester email.
7. Families check: confirm in the Console that Play Games sign-in is permitted for a mixed-audience (includes under-13) game; if
   Play flags it, cloud save can be hidden without touching progress (the game is complete without a backend).
**Send back:** the **Game ID** (the PGS project *number*, e.g. 123456789012 — not the Cloud project's string id).

### Batch D — Apple Developer portal (Account Holder/Admin; from Windows)
1. Identifiers → **iCloud Containers** → register `iCloud.com.foursagez.beamshift`.
2. Identifiers → App IDs → explicit `com.foursagez.beamshift`; tick **In-App Purchase**, **Game Center**, **iCloud** → **assign the
   container** so it reads **Enabled iCloud Containers (1)** → Save.
3. Apple Distribution certificate (Git Bash, in the signing folder):
   `openssl req -new -newkey rsa:2048 -nodes -keyout dist.key -out dist.csr` → Certificates → **Apple Distribution** → upload
   `dist.csr` → download `distribution.cer`.
4. Profiles → **App Store Connect** → the App ID → that certificate → name "BeamShift App Store" → download the `.mobileprovision`.
   (Any later capability change invalidates it — regenerate.)
5. App Store Connect → Users and Access → Integrations → **Team Keys** → role App Manager → download `AuthKey_<KEYID>.p8` (once only).
6. In the signing folder create `ids.env` with `APPLE_TEAM_ID=...` and `ASC_ISSUER_ID=...` (Membership page / Integrations page).
**Send back:** "Batch D done" — then run `tools/ci/set_apple_secrets.sh` yourself (it uploads the secrets with `gh`), or tell me to.

### Batch E — AdMob
1. Create **two apps** (Android, iOS; "not listed yet" is fine) and in each an **Interstitial** and a **Rewarded** unit.
2. Settings → **Test devices**: register every dev phone BEFORE live ads are switched on.
3. Privacy & messaging: create + publish **European regulations (GDPR)** and **US state regulations** messages pointing at the
   privacy policy. No IDFA explainer (no tracking, child-directed).
4. Host `app-ads.txt` at the developer website root: `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0`.
**Send back:** 2 App IDs (`~`) and 4 unit IDs (`/`). I put them in `project.godot`/`AdConfig` locally or via CI, never committed.

### Batch F — App Store Connect app record
1. My Apps → + New App → iOS, "BeamShift", bundle `com.foursagez.beamshift`, SKU `beamshift`.
2. **Game Center**: enable. **In-App Purchases** → + Non-Consumable, product id `beamshift_no_forced_ads`, display name
   "No Forced Ads" (≤30), description "No interrupting ads. Hints stay." (≤45), US $3.99, all territories, review screenshot
   exactly **640x920** (I can crop one from a Settings render), review note "Settings → NO FORCED ADS; Restore in Settings".
3. **App Privacy**: no tracking. Declare what AdMob collects per Google's App Store data disclosure (Device ID / Advertising Data /
   diagnostics as Third-party advertising + Analytics, **not used for tracking**). Age rating: answer honestly (ads: yes, G-rated).
4. Availability: consider excluding China mainland, South Korea, Vietnam (game licences).
**Send back:** "Batch F done".

### Batch G — first builds and review (together)
GitHub → Actions secrets (11, see `tools/ci/set_apple_secrets.sh` + `tools/ci/print_github_secrets.ps1`), a manual workflow run
(`Actions → Release CD → Run workflow`, version `1.0.0`), read the **guard** outputs (a green run with missing secrets ships
nothing), TestFlight internal group, device tests (section 7), listings/screenshots, Play **App content** (Target audience incl.
under-13, Ads: yes, Advertising ID, Data safety, IARC), then submit: Play internal → production; Apple version page with the IAP
added via **"Draft Submission (N)"** (never "Create New Submission"). Before Play production: **publish the PGS project** (one-way).

## 6. Code-side release checklist (before the first store build)

1. Game ID in both Android presets; privacy policy URL in `StoreConfig`.
2. `BuildConfig.BUILD_MODE = MODE_PRODUCTION`; review `USE_V3_FOR_PROCEDURAL_QA` / `USE_FUSION_PROGRESSION_FOR_QA` and every
   `LevelManager` QA flag (CLAUDE.md release rules) — a gameplay decision, not done in this pass.
3. AdMob App IDs in `project.godot`; `AdConfig.PRODUCTION_IDS` filled locally/CI + `USE_TEST_IDS=false` only AFTER the public
   listing is linked in AdMob and test devices are registered. `AdConfig.config_problem()` must be "".
4. Open item — **AD_ID permission**: the build carries `com.google.android.gms.permission.AD_ID` (from the Ads SDK). For a game
   treating every player as a child, Families policy expects the advertising ID not to be transmitted; decide whether to strip the
   permission (manifest `tools:node="remove"` via a small export plugin) and answer Play's Advertising ID declaration to match.
5. Settings layout on a real iPad (3:4 canvas is wider) and the store/cloud rows on real phones — MANUAL.

## 7. Device test checklist (MANUAL — only the owner's devices can confirm)
- Android (installed **from Play internal testing**, license tester account): price shows in local currency; BUY → Play sheet →
  "Thank you!" and interstitials stop; reinstall → Restore Purchases → owned again; cancel → no message, nothing changes.
- Rewarded hint still works for an owner. Interstitial every 4th completion (≥120 s) for a non-owner.
- Cloud: sign in → Settings shows "synced"; delete + reinstall → progress returns without a question; repeat with **> 1 h** of play
  on the cloud side → still no question on the fresh install; two devices far apart → chooser appears on the menu.
- iOS (TestFlight, sandbox): same purchase/restore flow; Game Center sign-in; save/restore round trip; no ATT prompt; no QUIT button.
