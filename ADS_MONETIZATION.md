# ADS_MONETIZATION.md — AdMob Foundation V1 (D98)

Build: `versionCode=53`, `versionName="4.3.0-ADMOB-FOUNDATION-QA"`. **This build uses Google TEST ads only.**
Android is built and configured; **runtime ad behaviour on a device is NOT yet verified** (no device or
emulator in the build environment) - it is the first thing the user tests. iOS is prepared, **not built or tested**.

## 1. Product rules

1. **Rewarded ad -> one Hint** (normal procedural play only).
2. **Interstitial after every 4 legitimate procedural completions**, at the natural transition, with a
   120-second minimum gap.
3. No banners, no App Open ads, no ads during active solving, no ads in tutorials / V3 TEST / QA Level Select /
   QA `+50`. Tutorials and V3 TEST keep the free Phase 1 hint.

## 2. Plugin choice and compatibility

- **Poing Studios Godot AdMob plugin v5.1.0** (stable release 2026-09-13, MIT, `github.com/poingstudios/godot-admob-plugin`),
  chosen after checking releases: it ships a per-Godot-version native bundle (`android-template-v4.7.1.zip`,
  `ios-template-v4.7.1.zip`), so it matches **Godot 4.7.1** exactly; Godot 4.5+, Android + iOS, GDScript, Google Mobile
  Ads SDK (`ads-mobile-sdk:1.4.0`) and the UMP consent SDK. The older Godot-3 and 4.0-4.3 plugin lines were not used.
- Installed to `addons/admob/` (C# sources and AI "skills" folders removed; native binaries downloaded by the
  plugin itself on first headless editor run: `addons/admob/android/bin`, `addons/admob/ios/bin`). Enabled in
  `project.godot` `[editor_plugins]`. Mediation adapters: none enabled.
- **Android build path changed**: the plugin uses the Godot Android plugin v2 system, which needs a **Gradle build**.
  `export_presets.cfg`: `gradle_build/use_gradle_build=true`, `compress_native_libraries=true`; the Android build
  template lives in `android/build/` (extracted from `export_templates/4.7.1.stable/android_source.zip`, `android/.build_version`
  = `4.7.1.stable`, plus `android/build/.gdignore`; `/android/` is git-ignored). To recreate on a new machine: extract the
  zip to `android/build`, write `.build_version`, add `.gdignore`, and delete any `*.import` Godot generated inside.
- **JDK 17 is required** (Gradle 8.11.1 rejects the JDK 25 that Android Studio's `jbr` ships). A portable Temurin 17 was
  unpacked to `C:\Users\shiva\tools\jdk-17.0.20.1+1` and Godot's editor setting `export/android/java_sdk_path` now points at
  it (original value `C:/Program Files/Android/Android Studio/jbr`; backup of the settings file: %TEMP%\editor_settings-4.7.tres.bak
  at the time). The APK grew from ~80 MB (non-Gradle) to ~106 MB (Gradle + Google Ads/UMP).
- Manifest verified in the built APK: `com.google.android.gms.ads.APPLICATION_ID` = the Google **sample** App ID,
  permissions INTERNET / ACCESS_NETWORK_STATE / AD_ID, all `org.godotengine.plugin.v2.PoingGodotAdMob*` plugins registered,
  minSdk 29, targetSdk 36.

## 3. Architecture

```
game.gd / HintManager                     (no SDK calls anywhere in gameplay)
        |
  AdManager  (autoload, scripts/managers/ad_manager.gd)  - state IDLE / SHOWING_REWARDED / SHOWING_INTERSTITIAL,
        |                                                  counter, cooldown, preload, retry, signals, audio duck
   AdBackend  (scripts/ads/ad_backend.gd)  - the platform seam (signals + load/show/has)
     |- AdBackendAdMob  (Android + iOS, one implementation through the plugin's platform-agnostic GDScript API)
     |- AdBackendFake   (tests/dev only, scripted outcomes)
  AdConfig (scripts/ads/ad_config.gd)  - ADS_ENABLED, USE_TEST_IDS, QA_BYPASS_REWARDED, rule constants, ALL ad-unit IDs
```

`AdManager` is the 5th autoload: ad state (preloaded ads, cooldown, consent, the completion counter) must outlive every
scene, so it meets the "earned autoload" bar of rule 6. On desktop/editor there is no ad platform: no backend, hints stay free.
There is one monetization implementation for both platforms; only the plugin's native bridges differ.

`AdManager` API: `initialize_ads()`, `is_rewarded_ready()`, `load_rewarded()`, `show_rewarded_hint(on_result)`,
`is_interstitial_ready()`, `load_interstitial()`, `register_completion(level)`, `is_interstitial_due()`,
`maybe_show_interstitial_after_completion(suppressed, on_done)`, `show_interstitial(on_done)`, `hint_requires_ad()`,
`is_privacy_options_required()`, `show_privacy_options()`. Signals: `rewarded_loaded/failed/opened/closed`, `reward_earned`,
`interstitial_loaded/failed/opened/closed`.

## 4. Rewarded Hint flow

`Hint button -> HintManager.request_hint() -> permission_provider (game.gd) -> AdManager.show_rewarded_hint()
-> ad -> **reward callback** -> HintManager.grant_hint() -> ring on one tile`.

- **The hint is granted ONLY from the reward-earned callback**, at most once per ad. Loaded / opened / dismissed / failed
  never grant. The ring's 6-second auto-clear timer is re-armed when the ad closes (`HintManager.rearm()`), so the reward
  callback (which precedes the close) does not consume it behind the ad.
- Provider is wired only for normal procedural play (`game.gd._configure_hint_permission()`); tutorials, V3 TEST and campaign QA
  sessions keep the free hint; `AdConfig.QA_BYPASS_REWARDED` or an unsupported platform also means free.
- **Failure UX (QA decision):** ad not ready / failed to load / failed to show / closed without reward -> **no hint and no free
  fallback**; the Hint button dips briefly (existing "no hint" cue), a reload starts immediately, and the player may press again.
- **Preload:** rewarded (and interstitial) are loaded once the SDK is ready; the next one loads right after a show, a close or a
  failure. Failed loads retry with back-off (30 s, doubling to 240 s) - no tight loops.
- **Double show protection:** one state machine; a second Hint tap or a stray/duplicate callback while an ad is up is ignored
  (`"busy"`), a second `reward_earned` never grants twice.
- Requesting a hint still changes no orientation, move count, star, save field, seed or generator version.

## 5. Interstitial rule

- `SaveManager.ad_completions_since_interstitial` counts LEGITIMATE completions: only `game.gd`'s normal procedural solve
  branch (the same branch that calls `record_procedural_level_result`) calls `AdManager.register_completion(level)`. The same level
  number is never counted twice in a row (Continue-restore of a solved board, Retry). **Not counted:** QA `+50`, V3 TEST, tutorials,
  Reset, Retry, Back, Continue/load, campaign/QA Level Select, generation, solver, hints.
- Due = counter >= 4 **and** now - last_interstitial >= `INTERSTITIAL_MIN_SECONDS` (120).
- Shown at the natural transition: Level Complete popup -> **Next Level** (`_on_next_level_pressed`); the next level loads when the ad
  closes (`on_done`, called exactly once, also on a failed show). No ad on Retry / Main Menu / Level Select buttons.
- **The counter resets ONLY when an interstitial actually shows** (then `last_interstitial_unix` = now). Not ready / cooldown / suppressed
  -> progression continues immediately, the counter is kept (>= 4) and the next eligible completion shows.
- **Rewarded suppression:** if a rewarded ad was OPENED on the current level, that level's interstitial opportunity is skipped
  (no two full-screen ads back to back). The completion still counts (counter continues), so the next completion without a
  rewarded ad shows.
- No app-open ad; the 4-completion rule protects the first session.
- Persistence (additive, old saves default to 0): `ad_completions_since_interstitial`, `ad_last_interstitial_unix`,
  `ad_last_counted_level`. Nothing else (no ad objects / SDK state / callbacks) is saved.

## 6. Consent / privacy (UMP)

Implemented through the plugin's supported UMP API in `AdBackendAdMob.initialize()`: every launch
`consent_information.update()` -> if a form is available and status is REQUIRED, show it -> `MobileAds.initialize()`.
**No ad request is made while consent is still REQUIRED** (`initialized(false)`). Not verified on a device; EEA testing needs
`ConsentDebugSettings` (not enabled).

### 6a. Child-directed configuration (store-release pass, 2026-09-26 - SUPERSEDES the old "decision still to make")

The owner decided the target audience **includes children under 13** and chose **child-safe ads for everyone** (no age screen).
`AdConfig.CHILD_DIRECTED = true` makes EVERY request: `tag_for_child_directed_treatment = TRUE`, `tag_for_under_age_of_consent = TRUE`,
`max_ad_content_rating = G` (`RequestConfiguration`, set before `MobileAds.initialize`), and `ConsentRequestParameters.tag_for_under_age_of_consent
= true`. Consequences: non-personalised ads only (lower eCPM), UMP normally shows no consent form and reports privacy options NOT_REQUIRED (the
Settings "PRIVACY OPTIONS" button therefore stays hidden - it appears only if UMP ever reports REQUIRED), **no IDFA / no ATT prompt on iOS**
(no `NSUserTrackingUsageDescription`, iOS preset `privacy/tracking_enabled=false`), no AdMob IDFA explainer message. Store forms must match:
Play "Target audience" includes under-13 (Families policy applies), Data safety declares no tracking; App Store "App Privacy" declares no tracking
and the app is NOT in the Kids category. Changing `CHILD_DIRECTED` is a policy decision (Play Families / COPPA / Apple 1.3), never a tuning knob.

### 6b. Hardening (store-release pass)

`AdBackendAdMob` now hands the plugin **named methods only** (inline lambdas stored in the plugin's static slots crash iOS on swipe-away under Godot
4.7), `release()` empties those slots from `AdManager._exit_tree()`, and a **consent watchdog** (`AdConfig.CONSENT_TIMEOUT_SECONDS = 8`) starts the SDK
if UMP never calls back. The Settings screen has the PRIVACY OPTIONS entry (visible only when required) and a PRIVACY POLICY link
(`StoreConfig.PRIVACY_POLICY_URL`, hidden while empty - must be filled before release).

### 6c. No Forced Ads (IAP)

Owning `StoreConfig.NO_FORCED_ADS` (`beamshift_no_forced_ads`, $3.99) stops interstitials only: `AdManager.forced_ads_removed()` gates
`load_interstitial()` and `maybe_show_interstitial_after_completion()`, and `on_forced_ads_removed()` drops a preloaded one the moment the purchase
lands. **The rewarded hint ad is unchanged for owners** (owner decision), which is why the product is named "No Forced Ads", never "Remove Ads" -
store copy must say optional hint videos remain. See `STORE_RELEASE.md`.

## 7. Failure and lifecycle behaviour

Ads are optional: no network / SDK error / timeout only means "no ad" - hints, saves, generation, completion, Continue, Next Level, audio and UI are
unaffected. All ad events are asynchronous plugin callbacks (deferred to the main thread); nothing waits on the network. While a full-screen ad is up
the Master audio bus is muted and restored (to its previous state) afterwards; the game is not paused (screens are static during an ad) and nothing
stays paused after dismissal.

## 7b. Test IDs (all in `scripts/ads/ad_config.gd`; App IDs also in the plugin project settings)

| | Android | iOS |
|---|---|---|
| App ID | `ca-app-pub-3940256099942544~3347511713` | `ca-app-pub-3940256099942544~1458002511` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` | `ca-app-pub-3940256099942544/1712485313` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-3940256099942544/4411468910` |

## 8. Android QA status

**Built:** APK exports; manifest/plugins/permissions verified (section 2). **Automated (fake backend through the real game scene, 37 checks, all pass):**
rewarded preload, exactly one ad on double tap, one hint from the reward, move count unchanged, reload after show, close-without-reward -> no hint, show
failure -> no hint, no ad available -> no hint and no crash, V3 TEST / tutorial / campaign QA free, completions 1-3 no ad / 4th shows / reset only after
show / cooldown blocks then allows / not-ready never blocks and keeps the counter / rewarded-suppression / QA `+50`, Reset, V3 TEST, Continue and duplicate
solved callbacks never increment, old save loads, 22/22 SFX, Master bus not left muted. **NOT verified (needs the user's device):** the real SDK/UMP
initialisation, real test-ad loading and showing, callback delivery from Java, app pause/resume around a real ad.

## 9. iOS - prepared, NOT validated

Prepared: plugin iOS binaries downloaded (`addons/admob/ios/bin`, ~12 MB), the same `AdBackendAdMob` code path, test IDs in `AdConfig`, plugin project
setting `admob/general/ios/app_id` defaults to the Google sample iOS App ID (the plugin's iOS exporter writes `GADApplicationIdentifier` into Info.plist
and adds the frameworks/Swift package). **No iOS export preset exists and nothing was built** (needs macOS + Xcode). Remaining: create the iOS preset (bundle id,
team, signing), export on a Mac, confirm Info.plist `GADApplicationIdentifier`, add the `NSUserTrackingUsageDescription`/ATT decision, confirm the current
SKAdNetwork requirements against Google's docs (do not hand-copy a list), verify UMP + ads on a device, and check `MobileAds.set_ios_app_pause_on_background`.

## 10. Production-ID replacement / release checklist

**External-test status (2026-09-26):** S4 pass 1 keeps `AdConfig.USE_TEST_IDS = true` and `QA_BYPASS_REWARDED = false`. This is the safest review/default state until the user explicitly approves live AdMob units. Rewarded Hint and interstitial architecture remain intact; tutorials and hidden QA sessions remain ad-free/free-hint by design. Before any public production release, replace IDs and manifest app IDs as listed below.

1. `AdConfig.USE_TEST_IDS = false`; fill `PRODUCTION_IDS` (locally / CI - never commit); `AdConfig.config_problem()` must return "".
2. Change the export App IDs: project setting `admob/general/android/app_id` (manifest) and `admob/general/ios/app_id` (Info.plist).
3. Verify on a device that ads load with child-directed tagging (6a) and no consent form / no ATT prompt appears; publish the AdMob GDPR + US-states messages anyway (UMP only shows forms that exist). The Privacy Options entry exists in Settings.
4. Test Android with production units (real ads, then remove any test-device IDs). Test iOS on a Mac/device; verify Info.plist and SKAdNetwork.
5. Set `LevelManager` QA flags (`UNLOCK_ALL_*`, `SHOW_PROCEDURAL_QA_NEXT_BUTTON`, `SHOW_V3_PROTOTYPE_QA`, `USE_V3_FOR_PROCEDURAL_QA` review) and the HUD QA tag.
6. `AdConfig.QA_BYPASS_REWARDED = false`; confirm no test-ad configuration remains; use a release keystore (currently debug-signed).
7. Re-check Play Console data-safety / ads declarations (AD_ID permission is present).

## Generated Fusion levels (D100)

Levels generated by procedural generator V4 that contain a Fusion node are NORMAL procedural levels: they use the normal rewarded-Hint flow and count as legitimate completions for the interstitial rule exactly like any other. FUSION TEST, V3 TEST, tutorials and QA +50 stay ad-free. No ad rule or ID changed in Phase 2 (verified end-to-end with the fake backend).

## Fusion Phase 3 (D101, `versionCode=56`) - no change

AdMob rules, ids and switches are untouched. Normal procedural levels that contain a Fusion node count exactly like any other normal procedural level (rewarded Hint, interstitial every 4 completions, 120 s, same-level suppression). The new Fusion tutorials T21-T28 are tutorials (ad-free, free Hint); FUSION TEST / NEXT FUSION stay ad-free through `_is_v3_session()`. Verified in the real game scene: `_interstitial_eligible_session()` is true for a generated Fusion level, false for T21-T28 and for FUSION TEST. Still Google TEST ids only.

## Phase 4 (D102, `versionCode=57`, `4.7.0-STARS-PRODUCTION-QA`) - stars, Hint cap, central QA switch, Fusion tutorial nudge

- **Stars:** one rule in `StarScoring` (OPTIMAL from `verified_optimal_moves` >= 0, else `intended_moves`, else legacy `optimal_moves`; +2 = 3 stars, +6 = 2, else 1; below optimal = 3 + QA warning). A GRANTED gameplay Hint caps the attempt at 2 stars (`game.gd._hint_used_this_attempt`, persisted in `procedural_resume_hint_used`/`campaign_resume_hint_used` so Continue cannot reset it; cleared by Reset/Next/QA +50). Best stars: `SaveManager.procedural_best_stars["<level>|<generator_version>"]` (raise-only) and the existing campaign dictionary. Tutorials, V3 TEST, FUSION TEST: no stars, no records. The popup shows the current run's stars + a small "HINT USED".
- **QA vs production:** ONE constant, `BuildConfig.IS_PRODUCTION_BUILD` (false in this build). It derives every QA-only UI/unlock flag in `LevelManager` and hides the tutorial debug overlay and the generator tag. Tools are hidden, never deleted. Not covered: Google TEST ad ids, and the generator rollout flags `USE_V3_FOR_PROCEDURAL_QA`/`USE_FUSION_PROGRESSION_FOR_QA`.
- **Fusion tutorial nudge:** one-time non-blocking "NEW TUTORIAL: FUSION" banner on Main Menu (`LevelManager.should_show_fusion_tutorial_nudge()`, persisted `fusion_tutorial_nudge_seen`); never forces the tutorial, never locks progression. `bs_fusion_icon.png` remains unused (no icon support in the tutorial panel).
- Level 2000 remains the certification target; nothing beyond it is exposed; no new mechanic.

## Production build behaviour (D114, 2026-09-26)

`AdConfig.USE_TEST_IDS` now follows `BuildConfig` (production = never test ids). Production ids are read from the gitignored `res://config/ad_ids.local.json` written by `tools/ci/stamp_store_config.sh` from the `ADMOB_*` secrets, and the export App ID is stamped into `project.godot` `[admob]` at the same time (verified: built manifest carried the stamped App ID and the json was packed). Any missing production id for the platform => `AdConfig.ads_active()` false => `AdManager` loads no SDK/consent and hints stay free (an empty unit id would otherwise make Hint permanently unavailable). Non-production builds keep the Google test ids. Tutorials/V*-TEST remain ad-free. Open: AD_ID permission decision for a child-directed audience (STORE_RELEASE.md 6 item 4).
