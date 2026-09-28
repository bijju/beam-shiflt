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

1. Game ID via CI secret `PLAY_GAMES_GAME_ID` (never committed); privacy policy URL in `StoreConfig`.
2. (DONE, D114: source is `MODE_PRODUCTION`.) Review `USE_V3_FOR_PROCEDURAL_QA` / `USE_FUSION_PROGRESSION_FOR_QA` and every
   `LevelManager` QA flag (CLAUDE.md release rules) — a gameplay decision, not done in this pass.
3. AdMob ids via CI secrets (`stamp_store_config.sh` writes `config/ad_ids.local.json` + `[admob]` app ids; `USE_TEST_IDS` follows the build mode) only AFTER the public
   listing is linked in AdMob and test devices are registered. `AdConfig.config_problem()` must be "".
4. Open item — **AD_ID permission**: the build carries `com.google.android.gms.permission.AD_ID` (from the Ads SDK). For a game
   treating every player as a child, Families policy expects the advertising ID not to be transmitted; decide whether to strip the
   permission (manifest `tools:node="remove"` via a small export plugin) and answer Play's Advertising ID declaration to match.
5. Settings layout on a real iPad (3:4 canvas is wider) and the store/cloud rows on real phones — MANUAL.

## 6b. Production release checklist, CI secrets, readiness (D114, 2026-09-26)

**State**: SOURCE production-ready = YES (`BuildConfig.BUILD_MODE = MODE_PRODUCTION`; QA UI/unlocks off; no Google test ids used). STORE SUBMISSION-READY = NO on both platforms until the boxes below are ticked. Internal QA build: `tools/ci/set_build_mode.sh internal_qa` (never commit it; `stamp_store_config.sh` and tag builds refuse a non-production source).

**Identity / version (source of truth: export_presets.cfg, stamped by `tools/ci/stamp_version.sh`)**: package/bundle `com.foursagez.beamshift` (all 3 presets); Android versionCode 10000 / versionName 1.0.0; iOS CFBundleShortVersionString 1.0.0 / CFBundleVersion 10000; iOS min 17.0, iPhone+iPad, portrait; Android min/target SDK = Godot defaults (built APK: target 36, arm64-v8a + armeabi-v7a).

**ANDROID**
- [ ] production AdMob ids -> secrets `ADMOB_ANDROID_APP_ID`, `ADMOB_ANDROID_REWARDED_ID`, `ADMOB_ANDROID_INTERSTITIAL_ID` (else ads ship OFF; required on `v*` tags / production track)
- [ ] Play Games project id -> secret `PLAY_GAMES_GAME_ID` (the Android lane fails without it)
- [ ] IAP product `beamshift_no_forced_ads` created in Play Console (same id on both stores - `StoreConfig.NO_FORCED_ADS`)
- [ ] upload keystore -> secrets `ANDROID_KEYSTORE_B64`, `ANDROID_KEYSTORE_USER`, `ANDROID_KEYSTORE_PASSWORD`
- [ ] cloud save: PGS Saved Games enabled, OAuth client with the App Signing SHA-1, testers
- [ ] signed AAB (`Release CD`), uploaded via `PLAY_SERVICE_ACCOUNT_JSON` or by hand
- [ ] Play Console: listing, privacy policy URL (`StoreConfig.PRIVACY_POLICY_URL`, empty = BLOCKER), Data safety, IARC, Families/target audience, Advertising-ID declaration + AD_ID permission decision (item 4 above)

**IOS** (final archive/sign/upload needs macOS: the `ios-appstore` job on `macos-26`)
- [ ] Apple Team ID (`APPLE_TEAM_ID`), bundle id registered with Game Center + iCloud container `iCloud.com.foursagez.beamshift`
- [ ] distribution certificate + provisioning profile (`IOS_DIST_CERT_B64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_B64`)
- [ ] AdMob iOS ids (`ADMOB_IOS_APP_ID`, `ADMOB_IOS_REWARDED_ID`, `ADMOB_IOS_INTERSTITIAL_ID`)
- [ ] privacy policy URL; UMP/child-directed already configured; ATT NOT used (`privacy/tracking_enabled=false`) - keep it that way
- [ ] IAP product in App Store Connect; Paid Apps Agreement
- [ ] Game Center enabled for the app (cloud save = GKSavedGame, iCloud)
- [ ] icon: only the 1024x1024 RGB (no alpha) `bs_app_icon_ios_1024.png` exists - valid single-size AppIcon; launch screen = Godot default (no custom art; do not generate)
- [ ] Xcode archive -> App Store Connect key (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_PRIVATE_KEY`) -> TestFlight test

**All GitHub secrets the workflow reads**: `ANDROID_KEYSTORE_B64/USER/PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`, `PLAY_GAMES_GAME_ID`, `ADMOB_ANDROID_{APP,REWARDED,INTERSTITIAL}_ID`, `ADMOB_IOS_{APP,REWARDED,INTERSTITIAL}_ID`, `APPLE_TEAM_ID`, `IOS_DIST_CERT_B64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_B64`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_PRIVATE_KEY`.

**Audit facts (source, not docs)**: consent = UMP every launch + Privacy Options in Settings when required; every request child-directed (TFCD/TFUA, rating G); rewarded hint survives the IAP by design; tutorials/T-packs/V*-TEST never show ads; purchase restore exists (Settings); cloud = Play Games Saved Games (Android) / Game Center saved games in iCloud (iOS), rule "more play time wins", chooser past 1 h gap, fresh install adopts cloud, offline = local file keeps working and the next local save re-queues the push (no dedicated retry timer). None of the cloud/IAP/consent paths has been run on a device. The iOS lane and `release.yml` YAML are UNVERIFIED (never run).

## 7. Device test checklist (MANUAL — only the owner's devices can confirm)
- Android (installed **from Play internal testing**, license tester account): price shows in local currency; BUY → Play sheet →
  "Thank you!" and interstitials stop; reinstall → Restore Purchases → owned again; cancel → no message, nothing changes.
- Rewarded hint still works for an owner. Interstitial every 4th completion (≥120 s) for a non-owner.
- Cloud: sign in → Settings shows "synced"; delete + reinstall → progress returns without a question; repeat with **> 1 h** of play
  on the cloud side → still no question on the fresh install; two devices far apart → chooser appears on the menu.
- iOS (TestFlight, sandbox): same purchase/restore flow; Game Center sign-in; save/restore round trip; no ATT prompt; no QUIT button.

**2026-09-26:** Android AdMob production ids configured via the stamp script; next internal-test build = versionCode 10001 (1.0.0). Still pending: real Play Games Game ID, iOS AdMob ids, AdMob app review, test-device registration.

## 8. Firebase REST Auth (Phase 1, 2026-09-28)

Owner decision: **Firebase Authentication REST API now, Firestore REST API later (Phase 2)** - not the native Firebase SDK, not `google-services.json`. This is a separate track from the Play Games/Game Center cloud save above; it exists to eventually back a cross-platform account system (Firestore-backed save sync), not to replace `CloudSave`.

**Implemented (Phase 1):**
- `FirebaseAuth` (10th autoload, `scripts/managers/firebase_auth.gd`) - `create_account`, `sign_in`, `send_password_reset`, `refresh_token`, `sign_out`, `ensure_valid_token`, `is_signed_in`, `has_refresh_token`, `get_uid`, `get_email`, `get_id_token`.
- `FirebaseConfig` (`scripts/firebase/firebase_config.gd`) - project id `beamshift-game` + Web API key loader.
- Session persistence (`user://firebase_session.json`: uid/email/refresh_token only, never the password or the id_token) with optimistic sign-in from disk + background token refresh once `InternetManager.is_online`.
- Dev-only manual test harness: `scripts/tools/firebase_auth_test.gd`/`.tscn` (excluded from every export preset).
- Verified headlessly (desktop, no real Firebase project reachable from this pass): autoload boots cleanly inside the full project (`godot --headless --path .`, no parse/autoload errors), `action=status` reports a clean signed-out state with no session file present, `action=sign_in` with no configured key returns `CONFIG_MISSING` immediately with **zero network calls** (confirms the config-missing short-circuit works before ever touching the network).

**NOT implemented / explicitly deferred:**
- Firestore (documents, collections, rules, `firebase_cloud_backend.gd`) - Phase 2.
- Account UI (sign-up/sign-in screen) - not built yet.
- The existing Settings "SIGN IN" button is untouched - still wired to `CloudSave.sign_in()` (Play Games/Game Center), not Firebase.
- `CloudSave`'s backend selection and reconciliation logic are unchanged.

**Unblocked (2026-09-28):** the owner supplied the real Firebase Web API key via `res://config/firebase_config.local.json` (gitignored, never committed, never printed).

**Firebase REST Auth Phase 1: LIVE VERIFIED (2026-09-28)** against the real `beamshift-game` Firebase project, using the dev-only harness (`scripts/tools/firebase_auth_test.gd`/`.tscn`) and a disposable test account:

- Create account: PASS (`signUp` REST call succeeded, uid/email/idToken/refreshToken/expiresIn all returned).
- Firebase Console user creation: NOT independently checked in this pass (no browser automation available) - manual console check still recommended if the owner wants visual confirmation in Authentication → Users.
- Sign out: PASS (in-memory state cleared, `firebase_session.json` removed from disk, `is_signed_in()` false, no network call made).
- Sign in (same account): PASS - UID matched the account-creation UID.
- Token refresh (`securetoken.googleapis.com`): PASS - new ID token issued, UID unchanged.
- Session persistence: PASS - `user://firebase_session.json` created, containing only `uid`/`email`/`refresh_token` keys (no `id_token`, no password).
- Restart/session restore (fresh process, `action=restore`, no credentials supplied): PASS - stored refresh token loaded, refresh succeeded, UID matched the original account.
- Password reset request (`sendOobCode`): PASS - Firebase accepted the request. Email receipt not independently confirmed (no inbox access from this pass).
- Offline fail-fast (temporary driver forcing `InternetManager.is_online = false`, deleted immediately after use): PASS - `refresh_token()` returned `OFFLINE` in 0 ms (no HTTP timeout wait); the stored session (refresh token + UID) was left untouched.
- Stale-response/sign-out safety: verified by code review only (not independently exercised by a live race in this pass) - `_session_generation` is bumped on every `sign_out()` and captured/re-checked by every in-flight request in `firebase_auth.gd` before applying its result.
- Log safety: SAFE - every print statement across `firebase_auth.gd`/`firebase_auth_test.gd` emits only presence booleans and Firebase's stable error codes, never raw password/idToken/refreshToken/Authorization-header content; confirmed against this pass's actual terminal output.
- Firestore: untouched (no reads/writes/collections/rules; `firestore` appears only in doc-comments stating it is Phase 2).
- CloudSave: untouched (`git status` shows zero diff on `scripts/cloud/**`/`store_manager.gd`).
- No AAB/APK built; no commit/push made for this verification pass.

**NOT independently verified in this pass** (need the owner's own check): Firebase Console showing the test user under Authentication → Users; the password-reset email actually landing in the test inbox.

**Next recommended step (superseded below):** owner does the two manual checks above (Console user listing, reset-email receipt) for final confidence, then decide whether to proceed to Phase 2 (Firestore REST API) or the Account UI - neither is started by this pass.

## 9. Firebase REST Cloud Save Phase 2A (2026-09-28) - isolated Firestore transport, LIVE VERIFIED

Owner decision: prove Firestore REST transport in isolation (auth -> token -> Firestore ->
rules -> restart -> offline -> stale-response safety) before touching `CloudSave` or
`SaveManager` at all. Firestore database: `(default)`, region `nam5`. Rules require
`request.auth.uid == userId` under `users/{userId}/**`, deny everything else.

**Implemented (Phase 2A):**
- `FirebaseFirestoreREST` (`scripts/firebase/firebase_firestore_rest.gd`, `RefCounted`, NOT
  an autoload - constructed with an owner `Node`) - `get_document`/`set_document`/
  `update_document`/`delete_document`/`document_exists`/`current_user_document_path`.
- Firestore Value (en/de)serializer (`_encode_value`/`_decode_value`) converting plain
  Godot Dictionaries <-> Firestore's typed JSON Value format, contained entirely inside
  this one file.
- Session-generation staleness guard reusing `FirebaseAuth.get_session_generation()` (new
  minimal public getter added over the already-existing private counter - no new
  session-invalidation logic).
- Dev-only manual test harness: `scripts/tools/firebase_firestore_test.gd`/`.tscn`
  (excluded from every export preset, same as `scripts/tools/**`).
- **Fixed a real pre-existing Phase 1 bug**: `FirebaseAuth.ensure_valid_token()` hung
  forever whenever it needed an actual network round-trip, because its wait loop mutated a
  lambda-captured `bool` that GDScript never propagates back to the outer scope (captures
  are by value). Fixed with a shared Dictionary. See CLAUDE.md/ARCHITECTURE.md for the full
  writeup - this was unexercised in Phase 1's own verification, not a regression from this
  pass.

**LIVE VERIFIED (2026-09-28) against the real `beamshift-game` Firestore database**, using
`kavyabommakanti312@gmail.com` (the same disposable Phase 1 test account) and a tiny
disposable test document at `users/<uid>/save/current`:

- Write (full overwrite via PATCH): PASS.
- Read: PASS.
- Round-trip match: PASS (written and read payloads identical).
- Update (PATCH + `updateMask.fieldPaths`, a true merge): PASS - `counter` changed 1->2,
  `schema_version`/`test_value`/`enabled` unchanged, confirmed by a follow-up read.
- Own-document access: PASS (200).
- Other-UID access blocked: PASS (`403 PERMISSION_DENIED` reading `users/not-the-current-
  user/save/current`).
- Signed-out access blocked: PASS - two independent checks: (a) the wrapper's own local
  guard (`FirebaseAuth.ensure_valid_token()` returns false when signed out) fails fast with
  `NO_AUTH`, zero network calls; (b) a raw `HTTPRequest` with **no** `Authorization` header
  at all (bypassing the wrapper entirely) was denied `403` by Firestore's own rules -
  proves server-side enforcement independent of the client.
- Firestore after forced token refresh: PASS - `FirebaseAuth.refresh_token()` forced, then
  a Firestore read succeeded immediately with no manual re-check needed by the caller.
- Restart/session-restore Firestore read: PASS - a genuinely fresh headless process, no
  credentials re-entered, read succeeded purely from the persisted refresh token via
  `FirebaseAuth`'s existing startup restore.
- Offline fail-fast: PASS - `OFFLINE` returned in ~0 ms (`InternetManager.is_online` forced
  false via the dev harness), no long timeout.
- Session preserved after offline attempt: PASS - `is_signed_in()`/`has_refresh_token()`
  both still true immediately after.
- Stale in-flight response protection: PASS - with the ID token pre-primed (fresh, so the
  actual Firestore HTTP request starts immediately rather than waiting on a token refresh),
  signing out ~20ms into the request caused the eventual response to be discarded as
  `STALE_SESSION` rather than reaching the caller.
- Sensitive logging: SAFE - inspected all terminal output across every test run; no ID
  token, refresh token, password, Authorization header, or API key value was ever printed
  (the harness prints only presence booleans, HTTP codes, and Firestore's own stable error
  codes/document field values, which contain no sensitive data).
- Firestore Console manual check: **MANUAL CONSOLE CHECK REQUIRED** - no browser automation
  available in this pass; the owner can confirm visually under Firestore -> Data ->
  `users/<test uid>/save/current` existed during testing (now deleted).
- Test document cleanup: YES - `delete_document` returned success, confirmed via a
  follow-up read returning `404 NOT_FOUND`.
- `SaveManager` touched: **NO.** `CloudSave` touched: **NO** (`git status` confirms zero
  diff on `scripts/managers/cloud_save.gd`/`scripts/cloud/**`).
- APK built: NO. No commit/push made for this verification pass.

**Remaining risks / not yet proven:**
- Firestore Console visual confirmation is still owner-side manual work (see above).
- The stale-response test exercises a ~20ms race window verified once, not a stress test
  under many overlapping requests - the underlying mechanism (session-generation compare)
  is the same pattern `FirebaseAuth._do_refresh`'s own waiters already rely on, but a
  Firestore-specific concurrent-request stress test has not been run.
- Firestore quota/pricing behavior under real device network conditions (latency, retries)
  is unmeasured - Phase 2A ran entirely from a desktop headless process.

**Next recommended step (superseded below):** build the real `CloudSave` Firestore
backend (a new backend alongside `play_games_cloud_backend.gd`/
`game_center_cloud_backend.gd`) that serializes `SaveManager.to_dict()` through
`FirebaseFirestoreREST`, decide reconciliation/conflict rules against the existing
Play Games/Game Center backends, and only after that wire the real Settings "SIGN IN" flow
and an Account UI. None of this is started or authorized by Phase 2A's completion.

## 10. Firebase Cloud Save Phase 2B (2026-09-28) - real CloudSave integration, LIVE VERIFIED

Owner decision: integrate Firestore with the existing `CloudSave` architecture with the
smallest possible change, reusing `SaveManager.to_dict()`/`adopt_cloud_data()`, push
throttling, conflict resolution, the 1-hour chooser, mid-level protection, and local-first
behavior completely unchanged. Play Games and Game Center are preserved, not removed.

**Implemented (Phase 2B):**
- `scripts/cloud/firebase_cloud_backend.gd` - the real Firestore `CloudSave` backend,
  implementing the exact contract `play_games_cloud_backend.gd`/
  `game_center_cloud_backend.gd` already use (4 signals, 5 methods, `last_error`).
  `is_available()` = `FirebaseAuth.is_signed_in()`, never OS-platform-gated. `pull`/`push`/
  `resolve_conflict` delegate entirely to `FirebaseFirestoreREST` (Phase 2A) at
  `users/{uid}/save/current` - no duplicated token/HTTP/serialization logic.
- `scripts/managers/cloud_save.gd` - backend selection/switching. **Selection priority: a
  signed-in Firebase account always wins over the platform-native backend; native wins over
  nothing.** Both backend nodes created once at `_ready()` and kept alive for the session
  (a switch never destroys/recreates a backend node); only the active-only signal trio
  (`profile_loaded`/`conflict_found`/`push_finished`) is (dis)connected on a switch, guarded
  idempotent. The native backend's own `sign_in_changed` is listened to for its whole
  lifetime (via `_native_authenticated`), independent of whether it is currently active.
  `_reconcile()`/`_cloud_wins()`/`_adopt()`/`_held_cloud`/`PUSH_COOLDOWN` (45s)/
  `CHOOSER_THRESHOLD` (3600s)/the background-pause flush are **completely unchanged**.
- Dev-only test harness: `scripts/tools/cloud_save_test.gd`/`.tscn` (excluded from every
  export preset like the rest of `scripts/tools/**`).

**LIVE VERIFIED (2026-09-28)** against the real `beamshift-game` Firestore database, using
the same `kavyabommakanti312@gmail.com` test account and, per this phase's own instruction,
the REAL local `SaveManager` profile (140 completed campaign levels) rather than a
disposable test blob:

1. Branch/HEAD: `dev_abhilas` @ `92c01ea`, unchanged throughout (no commits).
2. Starting git status: same modified/untracked set as Phase 2A left it, nothing reverted.
3. Files created: `scripts/cloud/firebase_cloud_backend.gd`, `scripts/tools/
   cloud_save_test.gd`/`.tscn` (+ `.uid` sidecars).
4. Files modified: `scripts/managers/cloud_save.gd` only (backend-selection rewrite, see
   ARCHITECTURE.md for the exact diff shape). `play_games_cloud_backend.gd`/
   `game_center_cloud_backend.gd`: zero diff (`git diff --stat` confirmed empty).
5. Firebase backend implementation: see ARCHITECTURE.md "Firebase Cloud Save integration
   (Phase 2B)".
6. Backend interface contract: unchanged from what `play_games_cloud_backend.gd`/
   `game_center_cloud_backend.gd` already established - no new interface was invented.
7. Backend selection priority: Firebase signed-in > native > none, in `CloudSave.
   _select_backend()`.
8. Firebase sign-in backend-switch: PASS - a fresh process with a restored Firebase session
   selected the Firebase backend immediately (`active_backend=firebase`, `is_signed_in=true`,
   `is_available=true`, `service_name=BeamShift Cloud Account`).
9. Firebase sign-out fallback: PASS on this desktop test machine, **with a caveat** - there
   is no native backend to fall back TO on Windows (`OS.get_name()` not in
   `NATIVE_BACKENDS`), so the observed result was `active_backend=none`,
   `is_available=false`, with local save data completely untouched. The native-fallback
   path itself (Firebase sign-out -> Play Games/Game Center becomes active again) is
   code-reviewed correct but **NOT live-exercised** - needs an Android or iOS device.
10. Firestore path used: `users/{uid}/save/current` (identical to Phase 2A's schema).
11. Empty-cloud/local-preservation: PASS - before any push, `pull()` returned `NOT_FOUND`
    (Phase 2A's disposable test document had already been cleaned up), `profile_loaded`
    never emitted, and the real local profile (140 completed levels) was completely
    untouched.
12. First cloud upload: PASS - `CloudSave.sync_now()` forced an immediate push of the real
    `SaveManager.to_dict()` profile; `synced(true)` received.
13. Firestore readback: PASS - read via the Phase 2A `firebase_firestore_test.tscn
    action=read` tool against the same path; the full real profile was returned.
14. Save round-trip: PASS - representative fields verified identical: `version` (5),
    `campaign_highest_unlocked_level` (140), `campaign_completed_levels` (140 entries),
    `campaign_best_stars_per_level`, `procedural_current_level` (1), `procedural_best_stars`,
    `play_time_seconds`, `saved_at` all matched; `entitlements` correctly **absent** from the
    cloud document (the existing `_flush_push()` stripping behavior, unchanged, applies
    identically through Firebase).
15. Measured `SaveManager.to_dict()` JSON payload size: **≈3.4 KB** (3387 bytes for this
    profile) - comfortably below Firestore's ~1 MiB document limit.
16. Fresh-install cloud restore: PASS - a real backup-then-delete of the local save file
    (matching a brand-new device/reinstall) followed by a fresh signed-in process correctly
    pulled the Firebase cloud copy and restored all 140 completed campaign levels via the
    unchanged `_reconcile()` rule. **One important nuance found and documented, not a bug**:
    the real local save predates `play_time_seconds` tracking (`0.0`/`saved_at` `""`), so
    an initial attempt correctly did NOT adopt (both sides tied at the sentinel default
    under the existing rule - working exactly as designed, just with no real signal to
    compare). Re-run after stamping the local save with 1 second of real play time (via
    `SaveManager.add_play_time()`) and a fresh `saved_at` (via `SaveManager.save_game()`)
    then re-pushing - the second attempt correctly adopted via the `play_time_of(local) <=
    0.0 and play_time_of(cloud) > 0.0` "fresh install adopts outright" branch.
17. Conflict-policy reuse: PASS - `_reconcile()`/`_cloud_wins()` were not touched or
    reimplemented; the fresh-install test above exercised the SAME functions a native
    backend would use, live through Firebase.
18. Chooser behavior: not exercised live in this pass (would need a cloud/local play-time
    gap >= 3600s deliberately constructed) - code-reviewed unchanged (`CHOOSER_THRESHOLD`
    untouched, `chooser_needed`/`pending_cloud`/`pending_local` logic untouched).
19. Mid-level protection: not exercised live in this pass (would need driving an actual
    `game.tscn` scene mid-puzzle) - code-reviewed unchanged (`_held_cloud`/`_in_level()`/
    `reconcile_held()` byte-identical to pre-Phase-2B).
20. 45s push throttle preserved: **YES** - `PUSH_COOLDOWN` constant and `_process()`
    accumulation logic untouched; `sync_now()`, which this pass's tests used to force an
    immediate push, bypasses the throttle exactly the same way it always could (a
    deliberate escape hatch, not new).
21. App-background flush preserved: YES - `_notification(NOTIFICATION_APPLICATION_PAUSED)`
    untouched, still calls `_flush_push()` against whichever backend is currently active.
22. Offline local-save behavior: PASS - with `InternetManager.is_online` forced false,
    `SaveManager.save_game()` still succeeded (local file written, `saved_at` stamped) and
    `CloudSave.sync_now()` failed fast with `last_error="No internet connection."`
    immediately (no hang); the Firebase session remained signed in and untouched throughout.
23. Restart/session-restore backend result: PASS - every fresh headless process in this
    pass correctly re-selected the Firebase backend purely from the persisted
    `FirebaseAuth` refresh token, with zero credentials re-entered.
24. Duplicate signal/write protection: PASS - 20 consecutive in-process calls to
    `CloudSave._select_backend()` with no underlying state change left signal connection
    counts at exactly 1 each (`profile_loaded`/`conflict_found`/`push_finished`), confirmed
    via `Signal.get_connections()`; the same idempotent guard structurally prevents a
    duplicate Firestore write path from ever opening.
25. Play Games backend changed? **NO.** 26. Game Center backend changed? **NO.**
27. Firestore rules changed? **NO** (same Phase 2A UID-scoped rules; every access in this
    pass stayed at `users/{authenticated_uid}/save/current`).
28. Account UI built? **NO.**
29. APK built? **NO.**
30. Firestore Console manual verification: **MANUAL CONSOLE CHECK REQUIRED** - no browser
    automation available in this pass, same limitation as Phase 2A.

**Local save handling note**: the real local save (`user://savegame.json`, containing 140
completed campaign levels) was backed up before every test that could modify it, and was
restored/left in a fully correct state at the end (all progress intact). One test-driven
side effect could not be perfectly reversed: 1 second of `play_time_seconds` was
deliberately added (via `SaveManager.add_play_time()`) partway through testing, needed to
give the fresh-install-restore test a real, non-sentinel signal to reconcile against, as
documented in item 16 above - **zero gameplay progress, stars, unlocks, or completion data
was altered**, only this one non-gameplay timing field. The Firestore cloud document at
`users/<uid>/save/current` was deliberately left in place afterward (containing the real
profile) rather than deleted, per this phase's own instruction that it is no longer the
disposable Phase 2A blob.

**Remaining risks:**
- Native-backend-fallback (Firebase sign-out -> Play Games/Game Center reselected) has not
  been live-exercised - no Android/iOS device available from this desktop pass.
- The 1-hour chooser and mid-level-hold paths were not live-exercised through Firebase in
  this pass (code-reviewed unchanged only).
- Firestore Console visual confirmation remains owner-side manual work.
- Real-device network latency/behavior under the Firebase path is unmeasured (desktop-only
  testing, same limitation Phase 2A had).

**Next recommended step (Phase 3, NOT started):** build the Account UI (sign-up/sign-in
screen) and wire the Settings "SIGN IN" button to actually offer a Firebase account as an
alternative to Play Games/Game Center - `firebase_cloud_backend.gd.sign_in()` is currently a
deliberate no-op specifically because no such UI exists yet. Android/iOS device QA of the
native-fallback and chooser paths is also recommended before Phase 3.

## 11. Firebase Account UI Phase 3 (2026-09-28) - player-facing screen + debug APK, LIVE VERIFIED (desktop)

**What was built**: `scenes/ui/account_screen.gd`/`.tscn` (the player-facing screen Phase 3
above said was still missing), and Settings' `CloudSignInButton` now opens it
(`GameManager.go_to_account()`) instead of calling `CloudSave.sign_in()` directly - label
reads ACCOUNT/SIGN IN from `FirebaseAuth.is_signed_in()`. Full design: ARCHITECTURE.md
"Firebase Account UI (Phase 3)", standing rules: CLAUDE.md "Firebase Account UI rules
(Phase 3)".

**Player flows implemented**: SIGN IN, CREATE ACCOUNT (a mode toggle on the same panel, adds
a Confirm Password field, local-only validation before any network call), FORGOT PASSWORD,
SIGN OUT (Cancel/confirm dialog), a "CONTINUE WITH <service>" native fallback when a Play
Games/Game Center backend exists and Firebase isn't signed in, and a Cloud Save status line
in the signed-in view. Every FirebaseAuth error code is translated to player-facing text by
`_friendly_error()` - never a raw code/JSON/token/UID/the word Firebase shown to a player.

**LIVE VERIFIED (2026-09-28, desktop, real network)** against the real `beamshift-game`
project using the existing disposable QA account, by driving the real scene's real
`Button.pressed` signals: sign-out -> real `FirebaseAuth.sign_out()` -> signed-out view;
wrong password -> `INVALID_LOGIN_CREDENTIALS` -> "Email or password is incorrect." shown,
password field cleared; FORGOT PASSWORD -> a real reset email sent; mismatched Confirm
Password in create-account mode -> rejected locally, zero network calls. The persisted
session file was backed up before this test run and restored afterward - the real QA
account's signed-in state on this machine is unchanged.

RENDERED (real, non-headless GPU frames) at 720x1280 / 1080x1920 / 1080x2400, both sign-in
and create-account modes, both signed-in and signed-out views: no clipping, no overlap,
matches the shared blue/cyan UI. **A real bug was caught this way, not assumed away**: the
first draft's panel reused `bs_panel_settings_portrait.png`, which turned out to bake the
word "SETTINGS" directly into the art - fixed with a plain `StyleBoxFlat`, no new art
generated.

**Debug APK built**: `builds/android/beamshift-firebase-account-test.apk` (Android Debug
preset, `com.foursagez.beamshift`, versionCode `10000` / versionName `1.0.0` - confirmed via
`aapt2 dump badging`; **AAB NOT built**, per this pass's own instruction). Zip listing
checked for the D78 "temp files swept into the package" mistake - clean, no `scripts/tools/**`
or other dev/temp files present. `assets/config/firebase_config.local.json` IS bundled
inside the APK by design - the Web API key it holds is a client-visible project identifier,
not an auth secret (see `firebase_config.gd`'s own doc comment); this is expected, not a leak.

**NOT yet verified (needs a real Android device)**:
1. Splash -> internet gate -> Main Menu -> Settings -> ACCOUNT/SIGN IN opens correctly.
2. Email/password virtual-keyboard behavior (`virtual_keyboard_type` set but not device-tested).
3. Wrong-password error shown on a real device (network path only tested from desktop).
4. Correct sign-in on a real device, cloud status updates, return to game.
5. Progress preserved after a real gameplay move + throttled push.
6. Restart the app -> still signed in (session restore) -> Account screen reflects it -> the
   Firebase backend is still the active `CloudSave` backend.
7. Real password-reset email flow end-to-end (email inbox check is owner-side).
8. Sign-out confirmation -> sign out -> local progress intact -> sign back in.
9. The native "CONTINUE WITH <service>" fallback against a real Play Games session (this
   desktop machine has no native backend at all, so this button never rendered locally -
   code-reviewed only).
10. The 1-hour cloud-vs-local chooser actually appearing and both choices working, and the
    mid-level-hold scenario, through this new entry point specifically (both mechanisms
    were already live-verified for the native/Firebase backends in Phase 2B, but not driven
    through the Account screen itself, and not on a device).

**Exact manual device checklist**:
1. Install and launch the APK; confirm the studio splash and internet gate appear normally.
2. Reach Main Menu; open Settings.
3. Confirm the Cloud Save button reads SIGN IN (fresh device, no session) and tap it.
4. Confirm the Account screen opens with email/password fields and the on-screen keyboard
   behaves sensibly (email keyboard for Email, masked/secure keyboard for Password).
5. Attempt sign-in with a deliberately wrong password; confirm "Email or password is
   incorrect." appears and the password field clears.
6. Sign in with the real disposable QA account's correct credentials (ask the owner for the
   password - never hardcode/commit it); confirm the screen switches to the signed-in view
   showing the correct email.
7. Confirm the Cloud Save status line updates (e.g. "Signed in" / "Synced").
8. Return to the game (Back -> Back -> PLAY/CONTINUE); make a few real moves.
9. Return to Main Menu; open Settings -> ACCOUNT; confirm the button now reads ACCOUNT.
10. Fully restart the app; confirm it signs back in automatically (no credentials re-entered)
    and the Account screen still shows signed in, with the cloud profile intact.
11. From the signed-out view, test FORGOT PASSWORD with the QA account's email; confirm the
    "Password reset email sent..." message and that a real email arrives.
12. From the signed-in view, tap SIGN OUT; confirm the Cancel/SIGN OUT confirmation dialog
    appears; tap CANCEL first (confirm nothing changes), then SIGN OUT for real.
13. Confirm local progress/level unlocks are still present after signing out.
14. Sign back in with the same account; confirm the cloud profile reconnects correctly.
15. If a native Google Play Games session is available on the test device, confirm the
    "CONTINUE WITH PLAY GAMES" fallback button appears when signed out of Firebase (renamed
    from "CONTINUE WITH GOOGLE PLAY GAMES" in section 12 below, to not be confused with the
    new placeholder Google Sign-In button), and that tapping it triggers the native sign-in
    flow instead.

**Remaining risks**: everything in the "NOT yet verified" list above is desktop-blind by
definition; the mid-level-hold/1-hour-chooser interaction specifically through Settings-
reached-from-Pause was reasoned about (see ARCHITECTURE.md's note on `_in_level()`'s scene-
path check) but not device-tested.

**Next recommended step**: run the manual device checklist above. If it passes, decide
whether to promote Firebase as the default player-facing account entry point in a future
store-facing pass (no code changes needed - it already is); no AAB/production-signing/store-
submission work should start until that manual QA is done.

## 12. Account/Settings UI fix + Google Sign-In prep pass (2026-09-28) - RENDERED-verified (desktop)

**Why**: the owner tested Phase 3's screens on a real Android device and found two real
button-proportion bugs, plus asked for the Account screen's UX to be prepared for a future
real "Continue with Google" (Firebase) sign-in. No new backend/network logic was added -
this is a UI correction/preparation pass. Files touched:
`scenes/ui/account_screen.tscn`/`.gd`, `scenes/ui/settings_menu.tscn`, `STORE_RELEASE.md`,
`CURRENT_STATUS.md`, `PROJECT_HANDOFF.md`, `NEXT_CLAUDE_PROMPT.md`, `NEXT_AI_PROMPT.md`,
`TEST_PLAN.md`.

**Restore Purchases overflow - cause and fix**: `RestorePurchasesButton` shared `font_size
24` with every other Settings button on the same `460x147` frame (`NO FORCED ADS`, `PRIVACY
OPTIONS`, `PRIVACY POLICY`, `SIGN IN`, `SYNC NOW`, `BACK`), but its label text ("RESTORE
PURCHASES", 18 characters) is longer than any of them - the shared `Button` theme's
`StyleBoxTexture` (`themes/beamshift_theme.tres`) keeps a fixed ~70px unstretched border on
each side regardless of button width, so the usable text area is the same ~320px for every
button at this size, and this one label alone didn't fit inside it. Per the owner's
preferred fix order, width couldn't grow (would break the shared 460-wide row), so only this
one label's `font_size` was reduced, from 24 to 19 - confirmed comfortably inside the
illuminated frame at 720x1280/1080x1920/1080x2400 with a RENDERED screenshot. No other
Settings label was touched.

**Account button stretching - cause and fix**: `account_screen.tscn`'s buttons
(`PrimaryButton`/`SignOutButton`/`BackButton`, and the native fallback button) had no
`custom_minimum_size`/`size_flags_horizontal` override, so as ordinary `VBoxContainer`
children they filled the full panel width (~900px+) - stretching the same
`bs_ui_button_*.png` `StyleBoxTexture` art Settings uses (native 1774x887, `region_rect`
1705x545, i.e. a fixed ~3.13:1 aspect ratio) into a much flatter, unnatural shape. Fixed by
giving every real action button the exact same `Vector2(460, 147)` +
`size_flags_horizontal = 4` (`SHRINK_CENTER`) Settings already uses for its own buttons -
`460/1705 = 0.2698`, `545*0.2698 = 147.0`, i.e. `460x147` is precisely the art's own
aspect ratio at that scale, which is why Settings' buttons never looked stretched in the
first place. `ModeToggleButton`/`ForgotPasswordButton` remain `flat = true` text-style links
(the existing, correct design for those two - no `StyleBoxTexture` involved, so no
stretching risk) and were left alone, per the owner's own instruction.

**A real regression found and fixed mid-pass**: the reported "large empty space below the
Account controls" was actually the pre-existing `ScrollContainer` being force-filled to the
full screen height by its `MarginContainer` parent (`MarginContainer` stretches its one
child to fill, regardless of that child's own content), leaving the content top-aligned
inside it with empty space below. The first fix attempt wrapped `Panel` in a
`CenterContainer` (mirroring Settings' own `CenterContainer -> Panel` structure) - this
INSTEAD collapsed the whole panel down to a thin, empty-looking strip, confirmed with a
RENDERED screenshot (a real, reportable bug, not just a hypothetical). Root cause:
`ScrollContainer.get_minimum_size()` deliberately does not report its content's full
minimum size (that defeats the purpose of scrolling) - so inside a shrink-based
`CenterContainer`, the `ScrollContainer` shrank to its own near-zero default instead of
sizing to fit the VBox inside it. Fixed by dropping the `ScrollContainer` entirely: the
Account screen's content comfortably fits all 3 target resolutions without it (confirmed by
RENDERED screenshots, including 720x1280, the smallest target, in CREATE ACCOUNT mode with
every field visible), so `VBox` is now a direct child of `OuterMargin`, exactly matching
Settings' own scroll-free structure. This is the "smallest robust solution" the owner asked
for, not a scroll-preserving workaround.

**Google Sign-In terminology + UI placeholder**: added `GoogleContinueButton`
("CONTINUE WITH GOOGLE") above the email/password form with a small "OR" divider label,
sized/styled identically to the other real buttons. It is a **deliberate placeholder only**
- `_on_google_continue_pressed()` in `account_screen.gd` shows a status message ("Google
Sign-In is coming soon. Use email/password for now.") and does **not** call `FirebaseAuth`,
does **not** touch `CloudSave`, and never claims a sign-in succeeded. The pre-existing native
fallback button (`NativeContinueButton`, calls `CloudSave.sign_in()` unchanged - see below)
is relabeled from "CONTINUE WITH GOOGLE PLAY GAMES" to "CONTINUE WITH PLAY GAMES"
(`_native_continue_label()` special-cases the Play Games service name; Game Center is
unaffected) specifically so it can never be confused with the new Google button on screen at
the same time - both are visible together whenever a native backend exists and Firebase
isn't signed in (see the native-fallback-visible RENDERED screenshot).

**What the existing "CONTINUE WITH GOOGLE PLAY GAMES" button actually calls** (verified by
reading `account_screen.gd`/`cloud_save.gd`/`play_games_cloud_backend.gd`, unchanged by this
pass): `_on_native_continue_pressed()` -> `CloudSave.sign_in()` -> the currently-selected
backend's `sign_in()` -> on Android, `play_games_cloud_backend.gd`'s wrapped
`GodotPlayGameServices` sign-in flow. This is Google Play Games Services' own player
identity (a real, working, native Android sign-in), entirely separate from a general Google
account/Firebase identity - it was never touched or repurposed by this pass.

**Rendered results** (real non-headless GPU frames, `D:\Godot_v4.7.1-stable_win64.exe --path .`,
D45-D47 tier - not headless, not synthetic input) at 720x1280 / 1080x1920 / 1080x2400:

- Settings: RESTORE PURCHASES fully inside its button on all 3; SIGN IN/BACK/SYNC
  NOW/ACCOUNT unchanged and correct; toggle alignment unchanged; cloud text readable.
- Account signed-out: title/description readable, CONTINUE WITH GOOGLE and Email/Password
  fields correctly sized, SIGN IN/BACK not stretched, controls centered, no clipping.
- Account signed-out with the native button forced visible: CONTINUE WITH GOOGLE and
  CONTINUE WITH PLAY GAMES both fit their frames without touching the decorative corner
  ornaments, both visually distinct in wording.
- Account CREATE ACCOUNT mode: Confirm Password field appears with no overlap against
  CREATE ACCOUNT/the mode-switch link/BACK below it.
- Account signed-in mode (forced for rendering, since a real Firebase test session was
  active in this dev environment): title, signed-in email, cloud status, SIGN OUT (red
  DangerButton), BACK all correctly proportioned and centered - not just the signed-out
  state.

**Google Sign-In implementation requirement (researched, not implemented)**: this project's
`addons/` currently contains `admob`, `GodotGooglePlayBilling`, and `GodotPlayGameServices` -
none of them expose a general Google Identity/OAuth token. `FirebaseAuth`
(`scripts/managers/firebase_auth.gd`) implements only `accounts:signInWithPassword` (email/
password) against the Identity Toolkit REST API; it has no `accounts:signInWithIdp` call and
no OAuth/ID-token exchange logic. The safest real implementation path, consistent with this
project's REST-only Firebase architecture (CLAUDE.md: "no native Firebase SDK, ever"):

1. Add a small new native Android Godot plugin (same pattern as the existing `admob`/
   `GodotGooglePlayBilling`/`GodotPlayGameServices` plugins - a Java/Kotlin `.aar` +
   `.gdap`) wrapping Android's **Credential Manager** API (`androidx.credentials`,
   `GetGoogleIdOption`) to obtain a Google ID token for the signed-in Google account on the
   device. Credential Manager is Google's current recommended API for this - it replaced
   both the legacy Google Sign-In SDK and One Tap (deprecated).
2. The plugin returns the ID token to GDScript (a signal, matching the existing plugins'
   pattern).
3. `FirebaseAuth` gains a new method (e.g. `sign_in_with_google(id_token: String)`) that
   POSTs to Identity Toolkit's `accounts:signInWithIdp` REST endpoint with
   `postBody="id_token=<token>&providerId=google.com"` and a `requestUri`, exactly the same
   `_post_json()`/`_apply_auth_response()` plumbing every other FirebaseAuth call already
   uses - no second HTTP/token implementation.
4. `GoogleContinueButton`'s handler is swapped from the current placeholder to this real
   call once the plugin exists and is tested.

This was not built in this pass, per the owner's explicit instruction not to implement an
unverified Google authentication solution or install a plugin automatically.

**Google account linking strategy (documented, not implemented)**: Firebase's Identity
Toolkit, under its default "one account per email address" project setting, will refuse (or
return a `NEEDS_CONFIRMATION`-class response identifying the existing account) when
`accounts:signInWithIdp` is called with a Google ID token whose email already has an
email/password account on this project. The eventual real implementation must:

1. Detect that response instead of treating it as a generic sign-in failure.
2. Prompt the player to sign in with their existing email/password credentials first
   (reusing the existing `SIGN IN` flow already on this screen).
3. Once that succeeds (and only then), call Identity Toolkit's `accounts:update` with the
   now-valid `idToken` and the Google `postBody`/`providerId` to link the two credentials to
   the SAME Firebase UID, rather than creating a second account.
4. Never silently create a second account for the same email, or the player's existing
   Firestore cloud save (namespaced by UID) would appear to "vanish" on the new UID.

No existing Firestore save data was read, modified, or touched by this pass.

**Regressions**: none found. `FirebaseAuth`/`CloudSave`/`StoreManager`/`AdManager` code was
not touched - only `.tscn` layout/font/label edits and the one new placeholder button
handler in `account_screen.gd`. Restore Purchases still calls
`StoreManager.restore_purchases()` unchanged.

**Build**: debug APK built via `godot --headless --export-debug "Android Debug"
builds/android/beamshift-account-ui-fix-test.apk` (`export_presets.cfg`'s "Android Debug"
preset name required exact quoting - PowerShell's `Start-Process -ArgumentList` silently
split the unquoted two-word preset name into separate argv entries, which caused Godot to
export the *other*, AAB-only preset and fail; wrapping it in literal embedded quotes fixed
it). Verified: `com.foursagez.beamshift`, `version/code=10000`, `version/name="1.0.0"` (both
unchanged from `export_presets.cfg`, confirmed by reading the preset config directly since
`aapt2` was not readily available in this environment); a zip listing of the resulting APK
confirmed no `_tmp_*`/dev/temp files were packaged (the temporary rendering driver used to
produce the screenshots above,
`scripts/tools/_tmp_ui_screenshot.gd`/`.tscn`, was deleted before this export, and
`project.godot`'s `run/main_scene` was reverted back to `studio_splash.tscn` immediately
after use - the D78/rule-9 lesson). AAB **not** built or touched
(`builds/android/beamshift.aab`'s timestamp confirmed unchanged).

**Next step**: manual Android device QA of both screens (this pass only has desktop
RENDERED verification - see CLAUDE.md rule 12a/12d on why that's a real, distinct tier, not
a substitute for a device), then an explicit owner decision on whether to build the
Credential Manager plugin described above.

## 13. Google Sign-In + Firebase Auth Phase 4A (2026-09-28) - BLOCKED MID-PASS, NOT a console gap

**Owner-confirmed console prerequisites (all present before this pass started):**
1. Firebase Authentication -> Google provider: enabled.
2. Firebase public project name: BeamShift (Google Cloud project id `beamshift-game`,
   unchanged from Phase 1).
3. Firebase Android app: `com.foursagez.beamshift`.
4. Debug signing certificate registered in Firebase's Android app: the certificate that
   signs `builds/android/beamshift-account-ui-fix-test.apk` (per the owner's own message,
   a Godot debug certificate) - SHA-1 `F6:B7:C8:8B:89:16:E7:E8:26:78:86:42:70:DD:B3:BE:74:83:D7:A7`.
   **This pass did not independently re-verify this fingerprint** - `apksigner` could not
   be run (see below); it is recorded here as owner-supplied, not this pass's own
   confirmation.
5. Google Auth Platform auto-created both OAuth clients (Android + Web); no new client
   was created by this pass, per instruction.
6. Web OAuth client id for Credential Manager's `serverClientId` / Firebase's ID-token
   audience: `516411257761-3ufb515qh3tknvkbad1qvt5kqeoafpit.apps.googleusercontent.com` -
   stored as `FirebaseConfig.GOOGLE_WEB_CLIENT_ID` (see below; not a secret, so it is a
   plain source const rather than routed through the gitignored local config file).

**What actually blocked this pass**: not a missing console item - a session-wide sandbox
fault. Every `Bash`/`PowerShell`/`WebFetch`/`WebSearch` tool call failed with "the
server-side auto mode classifier gave no verdict" from the very first command (even a
bare `echo`), repeatedly, across the entire session, including after a fresh user
message. File read/write tools (`Read`/`Write`/`Edit`/`Glob`/`Grep`) were unaffected.
Concretely this means: no `apksigner verify --print-certs` (the SHA-1 re-verification the
owner asked for at the top of this session could not be completed either), no Gradle
build of the new native plugin, no `godot --headless --export-debug`, and no live
doc-fetch to re-confirm the current official Credential Manager / Firebase REST API
shapes before writing code (the owner explicitly asked for that re-check "if tool access
has recovered" - it had not).

**Implemented in this pass (file edits only - no command execution needed to write
them, and none of it has been run or tested)**:

- `scripts/firebase/firebase_config.gd`: added `GOOGLE_WEB_CLIENT_ID` const (the Web
  client id above - non-secret, matches the existing `StoreConfig.NO_FORCED_ADS`
  precedent for plain source consts vs the gitignored-file pattern used for the actual
  secret, the Web API key).
- `scripts/managers/firebase_auth.gd`: two new public methods, built as a close
  structural mirror of the already-verified `sign_in()`/`_apply_auth_response()`
  plumbing in this same file (same `_post_json`/session-generation/in-progress-guard
  patterns, no second HTTP implementation):
  - `sign_in_with_google_id_token(id_token: String)` - POSTs to
    `accounts:signInWithIdp` with `postBody="id_token=<token>&providerId=google.com"`.
    On a normal success, applies the session exactly like `sign_in()`/`create_account()`.
    On Firebase's `needConfirmation` response (the email already has a password
    account under Firebase's default "one account per email" policy), caches the
    Google id_token and email **in memory only** (never persisted, never logged) and
    emits `google_sign_in_finished(false, "NEEDS_LINK", true, false)` instead of
    treating it as a generic failure.
  - `link_pending_google_credential()` - POSTs to `accounts:update` with the
    CURRENTLY signed-in user's `idToken` plus the cached Google `postBody`, attaching
    the Google credential to the EXISTING Firebase UID (never creates a second
    account, per the owner's explicit requirement). Called from the UI only after a
    normal password sign-in succeeds while a link is pending. Clears the pending
    token on both success and failure - a stale token is never replayed.
  - Two new signals: `google_sign_in_finished(success, error_code, needs_link,
    is_new_user)`, `google_link_finished(success, error_code)`.
  - `sign_out()` now also clears any pending Google-link state.
- `scripts/ui/account_screen.gd`: `GoogleContinueButton`'s handler now:
  1. Lazily resolves `Engine.get_singleton("GodotGoogleSignIn")` (only ever on
     `OS.get_name() == "Android"`), caching the result. **Currently always returns
     null** - see below - so the button currently shows "Google Sign-In is only
     available in the Android app." on every platform, same fail-safe behavior as
     before this pass, not a regression.
  2. If present, calls `plugin.signIn(FirebaseConfig.GOOGLE_WEB_CLIENT_ID)` and
     listens for its `google_id_token_obtained`/`google_sign_in_failed` signals.
  3. On a token, calls `FirebaseAuth.sign_in_with_google_id_token()`.
  4. On `NEEDS_LINK`, prefills the email field, forces Sign In mode (leaving Create
     Account would abandon the pending link - handled explicitly in
     `_set_create_mode()`), and shows "An account already exists for this email. Sign
     in with your password to link Google." The player's next successful password
     sign-in then triggers `link_pending_google_credential()` automatically
     (`_on_sign_in_finished()`), and sign-in itself is never blocked or undone by a
     link failure.
  5. New friendly-error mappings for `FEDERATED_USER_ID_ALREADY_LINKED`,
     `INVALID_IDP_RESPONSE`, `NOT_SIGNED_IN`, `NO_PENDING_CREDENTIAL`.
  - Email/Password sign-in, Create Account, Forgot Password, Sign Out, and the
    `CONTINUE WITH PLAY GAMES` native fallback are all **untouched** by this pass
    (confirmed by reading the diff - only the Google-related methods and
    `_on_sign_in_finished`/`_set_create_mode`/`_on_sign_out_confirmed`'s new
    link-state-clearing lines changed).

**NOT implemented - the native Android plugin, and everything after it**:

- `tools/android_plugin_src/google_signin/` contains reviewed-but-**uncompiled** Kotlin
  plugin source (`GoogleSignInPlugin.kt`, wrapping `androidx.credentials` Credential
  Manager) plus its `build.gradle` and `AndroidManifest.xml` - see that folder's own
  `README.md` for the complete, honest status: dependency versions are approximate
  (training-data knowledge, not re-verified against Maven Central this pass), it has
  never been compiled, and at least one API surface (`GodotPlugin`'s Activity accessor)
  is flagged as unverified against this project's actual `godot-lib` AAR.
  Exposes intended singleton `"GodotGoogleSignIn"` with `signIn(server_client_id)` and
  signals `google_id_token_obtained(id_token)` / `google_sign_in_failed(reason)` -
  this is the exact contract `account_screen.gd` already expects, so once compiled and
  wired in, no GDScript changes should be needed.
- `addons/GodotGoogleSignIn/plugin.cfg`/`export_plugin.gd` do **not** exist -
  deliberately not added, since pointing Godot's Android export at a nonexistent `.aar`
  path risks breaking the export rather than failing safely.
- No `.aar` was built. No Gradle command ran.
- **No APK was built.** `builds/android/beamshift-google-signin-test.apk` does not
  exist.
- **No SHA-1 was verified or reported** - neither the pre-existing debug APK's (the
  owner's own opening request this session) nor a new one's, because `apksigner`
  could not be run at any point in this session.
- Live official-docs re-verification of Credential Manager's current API shape and
  Firebase's `signInWithIdp`/`accounts:update` request/response shape (the owner's own
  explicit ask, conditional on tool access) did **not** happen - `WebFetch`/`WebSearch`
  failed the same sandbox check as every shell command.

**Regressions**: none found by inspection - `FirebaseAuth`'s existing email/password
methods, `CloudSave`, `firebase_cloud_backend.gd`, Firestore rules, and the Game Center/
Play Games backends were not touched by this pass. This could not be confirmed by
actually running the project, only by re-reading every changed file's diff.

**Next step (for whoever resumes this, in an environment where command execution
actually works)**:
1. Confirm shell/Gradle/`apksigner` execution works before doing anything else (a
   trivial `echo`/`gradle --version` check) - do not assume it works just because a
   prior session's docs describe successful builds.
2. Re-verify Credential Manager's and Firebase's current REST/API shapes against live
   docs (this pass could not) before trusting `tools/android_plugin_src/google_signin/`'s
   Kotlin source as-is - bump dependency versions, confirm the `GodotPlugin` Activity
   accessor name against the actual `godot-lib` AAR in this repo.
3. Compile the plugin, add `addons/GodotGoogleSignIn/plugin.cfg` + `export_plugin.gd`
   mirroring `addons/GodotPlayGameServices/export_plugin.gd` exactly.
4. Build the debug APK to `builds/android/beamshift-google-signin-test.apk`, then run
   `apksigner verify --print-certs --verbose` on it and confirm the signer SHA-1 matches
   the Firebase-registered debug SHA-1 above (`F6:B7:C8:8B:89:16:E7:E8:26:78:86:42:70:DD:B3:BE:74:83:D7:A7`) -
   this is the one check this pass was specifically asked to do and could not.
5. Only then proceed to real device QA of the Google Sign-In and account-linking flows -
   nothing in this pass has been exercised beyond a source-code read-through.
6. Per this pass's own instructions: no AAB, no Play Console upload, no commit/push/
   merge/branch switch happened or should happen until the owner asks.

**Update (see section 14 below): the plugin WAS since compiled, wired in, exported, and
device-tested - it just wasn't discovered as a Godot singleton at runtime. That was a
distinct bug (manifest registration metadata), now fixed. Steps 1-4 above are done;
step 5 (real device QA of the actual sign-in flow) is the current next step.**

## 14. Google Sign-In Android plugin registration fix (2026-09-28)

**Context**: section 13 above describes a session that could not run any shell/Gradle
command at all. In a later session (untracked in this doc until now), the plugin WAS
compiled (`GodotGoogleSignIn-debug.aar` exists), `addons/GodotGoogleSignIn/plugin.cfg` +
`export_plugin.gd` were added, and a debug APK (`beamshift-google-signin-test.apk`) was
built and installed on a real device. The Account screen opened correctly (proof
`OS.get_name() == "Android"` was true) but showed "Google Sign-In is only available in
the Android app." - i.e. `Engine.has_singleton("GodotGoogleSignIn")` was false.

**Root cause (proven, not assumed)**: `tools/android_plugin_src/google_signin/src/main/
AndroidManifest.xml` had NO `<application>` element and no `org.godotengine.plugin.v2.*`
`<meta-data>` entry - it was just an empty manifest with a comment saying Credential
Manager needs no manifest permissions. That's true for permissions, but Godot's Android
plugin v2 discovery mechanism itself depends on this exact meta-data tag existing inside
the plugin AAR's own manifest (`android:name="org.godotengine.plugin.v2.<PluginName>"`,
`android:value="<fully-qualified class>"`) - without it, the compiled class ships fine
inside the APK's `classes.dex` (confirmed present) but Godot's plugin registry never
learns it exists, so `has_singleton()` stays false. Confirmed by unzipping both the old
`GodotGoogleSignIn-debug.aar` and the known-working `GodotPlayGameServices-debug.aar` and
diffing their manifests side by side - `GodotPlayGameServices`'s AAR manifest has exactly
this `<application><meta-data .../></application>` block; the old GodotGoogleSignIn AAR's
manifest had no `<application>` element at all. `export_plugin.gd`, `plugin.cfg`, and the
Kotlin class itself (`getPluginName()`, `@UsedByGodot`, `GodotPlugin(godot)` constructor)
were all already correct and needed no changes.

**Fix**: added the missing `<application><meta-data android:name=
"org.godotengine.plugin.v2.GodotGoogleSignIn" android:value=
"com.foursagez.beamshift.googlesignin.GoogleSignInPlugin"/></application>` block to
`tools/android_plugin_src/google_signin/src/main/AndroidManifest.xml`, matching
`GodotPlayGameServices`'s exact pattern.

**Build environment note for future sessions**: this environment has no `java`/Gradle-
compatible JDK on `PATH`. Android Studio's bundled JBR (`C:\Program Files\Android\Android
Studio\jbr`) is JDK 25, which this project's Gradle 8.11.1 cannot run under (`Unsupported
class file major version 69` during settings evaluation - Gradle 8.11.x's embedded ASM
tops out around Java 23). A portable Temurin JDK 17 was downloaded from
`api.adoptium.net` (internet access confirmed available) and used as `JAVA_HOME`
instead - this worked cleanly. `ANDROID_HOME`/`ANDROID_SDK_ROOT` must also be set
(`%LOCALAPPDATA%\Android\Sdk`, which already has `android-36`/`36.1.0` installed - matches
`android/build/config.gradle`'s versions). To rebuild the AAR: temporarily add
`include ':google_signin'` +
`project(':google_signin').projectDir = new File(settingsDir, '../../tools/
android_plugin_src/google_signin')` to `android/build/settings.gradle` (gitignored, so
this never needs to be committed or reverted in git - just revert it in the working
tree so a real export build doesn't pick up the stray include), run
`gradlew.bat :google_signin:assembleDebug`, copy
`tools/android_plugin_src/google_signin/build/outputs/aar/google_signin-debug.aar` to
`addons/GodotGoogleSignIn/bin/debug/GodotGoogleSignIn-debug.aar`, then revert
`settings.gradle`.

**Verification performed**:
- Unzipped the newly-built AAR: confirmed its `AndroidManifest.xml` now contains the
  `org.godotengine.plugin.v2.GodotGoogleSignIn` meta-data entry, and `classes.jar` still
  contains `GoogleSignInPlugin.class`.
- Exported a new debug APK (`builds/android/beamshift-google-signin-plugin-fix-test.apk`,
  APK only, no AAB) via `Godot_v4.7.1-stable_win64.exe --headless --export-debug
  "Android Debug"`.
- Used `aapt2 dump xmltree <apk> --file AndroidManifest.xml` (binary AXML - plain
  `grep`/`strings` cannot read it) to confirm the REAL exported APK's merged manifest
  contains `org.godotengine.plugin.v2.GodotGoogleSignIn ->
  com.foursagez.beamshift.googlesignin.GoogleSignInPlugin`, sitting alongside the other
  working plugins' own identical entries (AdMob's `PoingGodotAdMob*`,
  `GodotGooglePlayBilling`, `GodotPlayGameServices`).
- Confirmed `GoogleSignInPlugin` symbols and `androidx/credentials/CredentialManager`
  references are present in `classes.dex`/`classes4.dex` inside the APK.
- `apksigner verify --print-certs` on the new APK: SHA-1
  `F6:B7:C8:8B:89:16:E7:E8:26:78:86:42:70:DD:B3:BE:74:83:D7:A7` - **unchanged**, matches
  the Firebase-registered debug SHA-1 exactly. Debug keystore/signing untouched.
- No AAB was built. No git commit/push/merge/branch switch was performed.
  `android/build/settings.gradle`'s temporary module include was reverted (that file is
  gitignored regardless).

**Not yet done (real-device-only, per this project's own standing rule - CLAUDE.md
12a/12d)**: installing `beamshift-google-signin-plugin-fix-test.apk` on the real device
and confirming (a) the "only available in the Android app" message no longer appears,
and (b) tapping CONTINUE WITH GOOGLE opens the Android Credential Manager / Google
account chooser and completes a real sign-in round-trip through
`FirebaseAuth.sign_in_with_google_id_token()`. This is the next required step before the
Google Sign-In flow can be called verified.

**Update (2026-09-28, same day, real device): all of the above IS now real-device
verified.** CONTINUE WITH GOOGLE opens the Android account chooser; selecting an account
completes Firebase auth; the Account screen shows signed-in state with the correct
Google email; Cloud Save reports Synced; Sign Out works; signing back in with the same
Google account works; the session survives a full app close/restart when the player does
not explicitly sign out; Firestore cloud save remains available; the APK's SHA-1 matches
the SHA-1 registered in Firebase. Normal (non-linking) Google Sign-In is therefore
REAL-DEVICE VERIFIED end-to-end.

## 15. Phase 4B - existing-account linking QA + Android keyboard/IME fix (2026-09-28)

**Part A - account-linking implementation: inspected, not rewritten.** Per this pass's
brief, the existing NEEDS_LINK/linking implementation (`FirebaseAuth.
sign_in_with_google_id_token()`/`link_pending_google_credential()`, Phase 4A; `account_
screen.gd`'s `_on_google_sign_in_finished()`/`_on_sign_in_finished()` handling, Phase 4A)
was read in full before any change was considered. Found structurally correct:
- A Google sign-in whose email already owns a password-provider Firebase account makes
  `accounts:signInWithIdp` return `needConfirmation` instead of a session. `FirebaseAuth`
  caches the Google id_token + email in memory only (`_pending_google_id_token`/
  `_pending_google_email` - never written to `user://firebase_session.json`, never
  logged) and emits `google_sign_in_finished(success=false, "NEEDS_LINK", needs_link=
  true, ...)`.
- `account_screen.gd` prefills the email, forces sign-in mode (Create Account is
  disabled while a link is pending - switching to it explicitly cancels the pending
  link via `_set_create_mode()`), and shows "An account already exists for this email.
  Sign in with your password to link Google."
- Once the player's real password sign-in succeeds (`_on_sign_in_finished`), `link_
  pending_google_credential()` runs automatically: `accounts:update` is called with
  `idToken: _id_token` (the CURRENT, just-signed-in session's token - i.e. the EXISTING
  password account's UID) plus the pending Google credential's `postBody`/`providerId`,
  which per Firebase's Identity Toolkit contract attaches the Google provider to that
  SAME UID rather than creating a second account. The pending token is cleared on both
  success and failure (`_clear_pending_google_link()`), so it can never be replayed
  against a different account. A link failure is deliberately non-blocking (the
  password sign-in itself already succeeded and is never undone by a link failure) -
  "Signed in. Google linking will be retried later." (unless offline, where the pending
  credential is deliberately KEPT so a retry can complete it without redoing Google
  Sign-In).
- No code changes were made in this part - no bug was found on inspection.

**Live end-to-end linking test: NOT performed this pass.** It requires a real Google
account whose email matches an existing Firebase Email/Password account (the disposable
QA account, `kavyabommakanti312@gmail.com`, was found still signed in via a persisted
session from an earlier pass - see Part B below - but there is no Google account known
to correspond to that exact email available/authorized in this session). Per the
brief's own explicit instruction, this is reported as **MANUAL QA REQUIRED**, not faked
as a pass - the implementation is left exactly as found.

**Part B - Android keyboard/IME fix on the Account screen: implemented and RENDERED-
verified.** The brief reported a real-device screenshot where the Android keyboard could
obscure/crowd the lower Account-screen controls, and explicitly warned against blindly
repeating a previous `CenterContainer`+`ScrollContainer` attempt that collapsed the panel
to a hairline (`ScrollContainer` does not report its content's true minimum size to a
shrink-type parent like `CenterContainer` - documented in `CURRENT_STATUS.md`'s Account/
Settings UI fix entry). The scene hierarchy was inspected first, then restructured so
that failure mode structurally cannot recur:

- `scenes/ui/account_screen.tscn`: `SafeMargin > KeyboardVBox (new VBoxContainer) >
  [ScrollContainer (new, `size_flags_vertical=3`, `horizontal_scroll_mode=0`) >
  CenterContainer > Panel > ...same content as before, unchanged proportions/460x147
  buttons/art..., KeyboardSpacer (new plain Control, 0 height normally)]`.
  `ScrollContainer` is now the OUTER, size-OWNING layout element (sized by `KeyboardVBox`,
  a normal container, not a shrink-type one) - the exact inversion of the pattern that
  collapsed the panel before. With no keyboard, `KeyboardSpacer` stays at 0 height,
  `ScrollContainer`'s content fits without scrolling, and the screen is visually
  byte-identical to before this pass (confirmed by RENDERED screenshot comparison).
- `scripts/ui/account_screen.gd`: two independent, complementary mechanisms, because
  Android's soft-keyboard behavior is not uniform across devices/OEMs/Godot window
  modes - covering only one would leave real devices broken:
  1. **Viewport resize** (`android:windowSoftInputMode="adjustResize"` devices): each
     of Email/Password/ConfirmPassword's `focus_entered` calls `ScrollContainer.
     ensure_control_visible(field)` (Godot's own built-in scroll-into-view helper - no
     manual pixel math, no second scroll-position system); `get_viewport().size_
     changed` re-runs the same call one frame after the signal fires, since the real
     resize settles asynchronously after the focus event that opened the keyboard.
  2. **Keyboard overlay** (no resize - the more common real-Android behavior when the
     OS doesn't resize the window): a lightweight `_process()` polls `DisplayServer.
     virtual_keyboard_get_height()` (Godot 4.2+, Android/iOS only, always 0 on desktop -
     confirmed a true no-op there) and, only on a real height transition (not every
     frame), sets `KeyboardSpacer.custom_minimum_size.y` to match. Because `KeyboardVBox`
     is a plain `VBoxContainer` dividing its rect between its two children by their
     minimum sizes, growing the spacer directly shrinks `ScrollContainer`'s own rect by
     the keyboard's height - which is exactly what `ensure_control_visible()` needs in
     order to correctly reason about what's actually still visible versus covered.

**Verification method and its honest limits.** A first attempt simulated "the keyboard
opened" by shrinking `get_window().size` on desktop - this turned out to be an INVALID
proxy: this project's `canvas_items`/`expand` stretch mode (`DECISIONS.md` D86) does not
shrink the logical UI canvas the way it shrinks real window pixels (confirmed directly -
`ScrollContainer.get_global_rect()` stayed ~1728px tall regardless of how much the
window height was shrunk, because "expand" mode reveals MORE logical width instead of
losing logical height once height becomes the binding constraint below the 1080x1920
reference floor). The correct, honest test instead drove the REAL mechanism directly -
set `KeyboardSpacer.custom_minimum_size.y` to a representative simulated keyboard
height (820px, exactly what `_process()` does once `virtual_keyboard_get_height()`
reports a real nonzero value) and called `ensure_control_visible()` on each field, the
same way the real code path does. This is the honest ceiling of what a desktop machine
with no real Android keyboard can verify - the `DisplayServer.virtual_keyboard_get_
height()` INPUT itself is genuinely untestable without a real device (CLAUDE.md rule
12a/12d): a value of 0 there is indistinguishable between "desktop, no keyboard exists"
and "a real device whose keyboard API happens to misreport."

RENDERED (real GPU, `Godot_v4.7.1-stable_win64.exe --path .`, temporary `run/main_scene`
swap to a throwaway driver scene under `_qa_tmp/`, reverted and the driver deleted
immediately after) at 720x1280 / 1080x1920 / 1080x2400:
- No-keyboard state: screenshot compared against the pre-existing layout - centered,
  identical button proportions, no visible change.
- Simulated-keyboard state (Create Account mode, the deepest content): Email, Password,
  Confirm Password, and the BACK button (the single deepest reachable control) were each
  focused/targeted in turn and confirmed FULLY inside `ScrollContainer`'s shrunk visible
  rect (`Rect2.encloses()` check, not just eyeballed) at all three resolutions, including
  the smallest (720x1280) - screenshots captured and personally inspected, not just
  asserted true from the boolean check alone.
- A pre-existing disposable QA Firebase session (`kavyabommakanti312@gmail.com`) was
  found still signed in via `user://firebase_session.json` from an earlier pass; the
  driver called `FirebaseAuth.sign_out()` locally (never touches the real Firebase/
  Google account) so the actual IME-affected Signed-Out view could be exercised. This
  means the disposable account now shows signed-out on this local machine the next time
  Account is opened - a real, expected, and easily-reversible (sign back in) side effect
  of this local-only test, not a data-loss risk (CloudSave data itself lives in
  Firestore, untouched).

Zero gameplay/FirebaseAuth/CloudSave/SaveManager code touched. No new mechanic, no new
autoload, no export-filter change.

**APK build: BLOCKED, not skipped.** Since Part B's changes are pure GDScript/scene
(no native Android code touched - `addons/GodotGoogleSignIn/bin/debug/
GodotGoogleSignIn-debug.aar` from the section 14 fix above is unchanged and did not need
rebuilding), only a plain `godot --export-debug` was needed. A portable Temurin JDK 17
download from `api.adoptium.net` succeeded (190MB, confirmed on disk), but the
subsequent extraction step - and every other `Bash`/`PowerShell` call attempted
afterward - hit a repeated "the server-side auto mode classifier gave no verdict"
sandbox failure, the identical session-wide tooling outage the Phase 4A pass (section
13 above) hit for `Bash`/`PowerShell`/`WebFetch`/`WebSearch`. Per that entry's own
documented precedent, this was not retried in a loop (the environment's own guidance:
"if it keeps failing, continue with other tasks... come back to it later"); `Read`/
`Edit`/`Write` tools were unaffected throughout, so every code/doc change in this pass
is real, complete, and already on disk - only the build step itself is unbuilt. No new
APK exists (`builds/android/beamshift-google-link-ime-test.apk` was NOT created this
pass). No commit/push/merge/branch switch was performed.

**Next**: once tooling recovers, extract the already-downloaded JDK (or re-download),
export a fresh debug APK reusing the unchanged plugin AAR, then run (a) the real
existing-account-linking test end-to-end with a real matching Google account, and (b)
real Android-device IME QA (keyboard open/close on each field, in both Sign In and
Create Account modes, at real device resolutions) - neither can be completed without a
human/real device per CLAUDE.md 12a/12d.

## 16. Internal Testing AAB versionCode 10001 (2026-09-28) - BUILT, SIGNED, VERIFIED

**Owner-supplied state going in**: Play Console Internal Testing already has versionCode
10000/1.0.0 live. The upload keystore was recovered to
`D:/4Sagez/GodotGames/Keys/BeamShift/beamshift-signing/beamshift-upload.keystore`
(alias `beamshift`) and already configured in `.godot/export_credentials.cfg` (gitignored,
local-only - never in source control). Play App Signing SHA-1 already registered in
Firebase alongside the debug SHA-1 (owner-confirmed; not independently re-checked in the
Firebase console by this pass - no browser access). Google Sign-In already real-device
verified end-to-end via the debug APK (section 14 above).

**Keystore verification**: `keytool -list -v` on the keystore file itself, in this session,
without ever printing the password, gave alias `beamshift`, SHA-1
`A4:82:77:62:47:1D:00:AE:09:CA:AA:FB:34:20:5B:24:1B:1E:60:5A` - **exact match** to the
owner-supplied Play Console upload-key SHA-1.

**A real bug found and fixed before building**: `addons/GodotGoogleSignIn/export_plugin.gd`'s
`_get_android_libraries()` returned an **empty array for a non-debug (release) export** -
only `bin/debug/GodotGoogleSignIn-debug.aar` existed (see section 13's own doc comment,
written when the plugin was first added: "release variant is a follow-up step before any
store-facing build uses this plugin" - that follow-up had never happened). Confirmed by
building an AAB with the unmodified plugin and inspecting its `base/manifest/AndroidManifest.xml`
directly (extracted from the .aab and grepped): no `org.godotengine.plugin.v2.GodotGoogleSignIn`
entry anywhere, alongside AdMob/GodotGooglePlayBilling/GodotPlayGameServices's own entries
which WERE present. **This means every release/Internal-Testing build up to this pass would
have shipped with the Google Sign-In button non-functional** (`Engine.has_singleton(...)`
false), even though the debug APK worked. Fixed by building the real release `.aar` from the
existing plugin source (`tools/android_plugin_src/google_signin/`, unchanged) via
`gradlew.bat :google_signin:assembleRelease` (using the section 14 JDK 17 workflow: a
temporary `include ':google_signin'` line added to the gitignored
`android/build/settings.gradle`, reverted immediately after the build), copying the result to
`addons/GodotGoogleSignIn/bin/release/GodotGoogleSignIn-release.aar`, and updating
`_get_android_libraries()`'s release branch to reference it - mirroring
`GodotPlayGameServices/export_plugin.gd`'s existing if/else pattern exactly. No Kotlin
source, `plugin.cfg`, or Gradle dependency list was changed. Re-exported the AAB and
re-inspected its manifest: `org.godotengine.plugin.v2.GodotGoogleSignIn ->
com.foursagez.beamshift.googlesignin.GoogleSignInPlugin` now present; `androidx/credentials`
classes confirmed present in `classes.dex`/`classes2.dex` (grepped directly from the
extracted dex bytes, since `dexdump` was not available in this environment).

**Play Games `game_services_project_id` - re-verified against the CURRENT project, not
assumed from old docs**: `godot_play_game_services/game_id` is still `""` on both Android
presets. `GodotPlayGameServices/export_plugin.gd`'s `_export_begin()` prints
`"[GodotPlayGameServices] Export [Game id] is empty."` to the export log when this happens
but does **not** abort the export - it just skips writing `strings.xml`'s
`game_services_project_id` value. **A real export was run twice in this pass with the game
id empty and both succeeded** (AAB produced, correctly signed, correct package/version).
This means CLAUDE.md's/this file's own earlier claim that an empty Game ID blocks Android
export (AAPT `string/game_services_project_id not found`) **does not reproduce with this
project's current Godot 4.7.1 / AGP 8.6.1 / plugin versions** - either the underlying AAPT2
behavior changed, or the original observation was against a different condition. This is
now corrected here rather than repeated on trust; CLAUDE.md's `godot_play_game_services`
guidance should be treated as no longer accurate for a build-blocking claim (a genuine,
separate runtime risk remains: the "CONTINUE WITH PLAY GAMES" native fallback button and
PGS Saved Games almost certainly won't work correctly at runtime without a real Game ID -
untested this pass, unrelated to whether the AAB builds).

**AdMob in this exact AAB**: no `config/ad_ids.local.json` exists locally, so
`AdConfig.production_ids()` returns empty, `config_problem()` reports a missing id, and
`ads_active()` is **false** - by design (CLAUDE.md D114/STORE_RELEASE.md section 6): ads
ship OFF and the rewarded hint stays free rather than requesting ads with sample/empty unit
ids. This is expected, safe behavior for this build, not a defect - production ad ids still
need to come from the CI stamp script (or a locally-placed `config/ad_ids.local.json`)
before a real store-facing build.

**Verified facts about the final AAB** (`builds/android/beamshift.aab`, 123,750,289 bytes /
~118 MiB):
- `com.foursagez.beamshift`, versionCode 10001, versionName "1.0.0" (read directly from the
  extracted `base/manifest/AndroidManifest.xml`).
- Signing cert extracted directly from the AAB's own `META-INF/*.RSA` (not just the keystore
  file): SHA-1 `A4:82:77:62:47:1D:00:AE:09:CA:AA:FB:34:20:5B:24:1B:1E:60:5A`, SHA-256
  `1A:BC:7D:9A:BA:75:FC:3C:89:FB:5E:EC:95:8B:46:DC:0E:CB:F9:8E:D5:85:DB:6E:97:31:D7:A5:D1:0C:5D:33`
  - identical to the keystore's own certificate. `jarsigner -verify` on the .aab: "jar
  verified."
- `godotengine.plugin.v2.GodotGoogleSignIn` + `GoogleSignInPlugin` class + `androidx/credentials`
  classes all present (see above).
- `firebase_auth.gdc`, `firebase_firestore_rest.gdc`, `firebase_cloud_backend.gdc`,
  `firebase_config.gdc`, `cloud_save.gdc`, `account_screen.gdc`/`.scn`, `internet_manager.gdc`,
  `studio_splash.gdc`/`.scn`, `ad_manager.gdc`/`ad_config.gdc` all present in the packaged
  assets.
- `config/firebase_config.local.json` (web API key only, client-visible by design) IS bundled;
  `config/ad_ids.local.json` is NOT (doesn't exist locally - ads off, see above).
- Zip listing checked for `_qa_tmp/**`, `scripts/tools/**`, and every known dev-harness
  filename (`firebase_auth_test`, `firebase_firestore_test`, `cloud_save_test`, `v3_prototype_audit`,
  `v5_sample`, `selector_verify`, `difficulty_inspect`) - **none present**, matching
  `export_presets.cfg`'s `exclude_filter`.
- Source `BuildConfig.BUILD_MODE` confirmed `MODE_PRODUCTION` (QA tools off).

**Files changed this pass**: `addons/GodotGoogleSignIn/export_plugin.gd` (release .aar wiring,
doc comment updated) and a new, untracked `addons/GodotGoogleSignIn/bin/release/
GodotGoogleSignIn-release.aar`. `export_presets.cfg`'s `version/code=10001` on the release
Android preset was **already present before this pass started** (pre-existing uncommitted
change from an earlier session, not made by this one). `android/build/settings.gradle`'s
temporary module include was reverted in the working tree (that file is gitignored either
way). Gradle build intermediates under `tools/android_plugin_src/google_signin/build/**`
were left on disk (untracked; **not currently covered by `.gitignore`** - worth adding a
`build/` ignore rule under `tools/android_plugin_src/` in a future pass so `git status`
doesn't show Gradle cache noise).

**No commit, push, merge, or branch switch was performed.** The AAB was **not** uploaded
to Google Play. `addons/GodotGoogleSignIn/bin/release/GodotGoogleSignIn-release.aar` is
currently untracked - it needs to be committed alongside the debug `.aar` (which IS already
tracked) for a future session's export to reproduce this build without rebuilding the
plugin from source again.

**Not verified by this pass** (same honest gaps as every prior section): the AAB has not
been installed on a real device (it's a release/signed build tied to the upload key, so it
can only be meaningfully tested after upload to Play Internal Testing, per Android's own
signing model); Play Games Saved Games / the native fallback button at runtime with an
empty Game ID; real Play App Signing SHA-1 re-confirmation in the Firebase console (owner-
reported only); AdMob production ads (deliberately off in this build).

**Next step**: owner uploads `builds/android/beamshift.aab` to Play Console Internal
Testing by hand, confirms the Play App Signing re-signed APK still carries a Google-Sign-In-
working build, and runs the device checklist in section 11/15 above against the newly
installed Internal Testing build (not a sideloaded debug APK, so Play-Store-only paths like
Play Billing/Play App Signing behavior can finally be exercised for real).
