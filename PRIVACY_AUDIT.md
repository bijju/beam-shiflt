# BeamShift privacy audit (2026-10-03)

Canonical policy text: `scripts/ui/privacy_policy_text.gd` (`PrivacyPolicyText`). In-game screen:
`scenes/ui/privacy_policy_screen.tscn` + `privacy_policy_screen.gd`. Web copy (GENERATED, never hand-edit):
`docs/privacy-policy/index.html` via `godot --headless --path . --script res://tools/privacy/build_policy_html.gd`.
`tools/tests/cases/test_privacy_policy.gd` fails when the HTML drifts. **Change the game's data practices => change the
text, regenerate, bump "Last updated"** (and re-check the store forms: Data safety / App Privacy).

## Audit table (PASS = proven from source/config; WARNING = cannot be proven from source)

| Topic | Result | Evidence / note |
|---|---|---|
| Local save | PASS | `SaveManager` -> `user://savegame.json`; fields listed in policy section 2 match `_default_data()` |
| Play Games (Android) | PASS | `PlatformAccount`: silent `is_authenticated()`, display name only; no snapshots/leaderboards used. Game ID still empty in presets (build item, not a policy claim) |
| Sign in with Apple | PASS | scopes `email`,`full_name` requested; only `{apple:true,name}` stored in `user://platform_account.json`; tokens never read/stored. Policy says exactly that |
| AdMob | PASS | `AdBackendAdMob`, rewarded + interstitial only, no banners/app-open |
| Rewarded ads | PASS | hint granted only on reward callback |
| Interstitial ads | PASS | every 4 completions and >=120 s (`AdConfig`); tutorials never |
| No Forced Ads | PASS | removes interstitials only; rewarded stays |
| Google Play Billing | PASS | `play_billing_backend.gd`; `BILLING` permission in merged manifest |
| StoreKit | PASS | `store_kit_backend.gd` (iOS GDExtension downloaded by CI; not testable on desktop) |
| Firebase absence | PASS | no Firebase/Firestore/Crashlytics/analytics SDK in scripts, addons, gradle config, presets |
| Analytics | PASS | none in the project (BeamShift's own). Google Play services/AdMob have their own diagnostics - policy says so |
| Crash reporting | PASS | none in the project |
| ATT | PASS | no ATT call, no `NSUserTrackingUsageDescription`, `privacy/tracking_enabled=false`, CI checks `NSPrivacyTracking=false` |
| Advertising identifiers | WARNING | Merged debug manifest contains `android.permission.AD_ID` + `com.google.android.gms.permission.AD_ID` (added by the ad SDK, not by `export_presets.cfg`). Policy words it as "may use identifiers ..." and states that BeamShift's own code does not read the Android advertising ID and that Google documents the AAID as not transmitted for child-directed requests (Next-Gen SDK 1.4.0 docs; NOT source-proven). Release AAB 1.0.1 (10005) carries both AD_ID permissions: `com.google.android.gms.permission.AD_ID` (ads-mobile-sdk 1.4.0 / play-services-ads-identifier 18.0.0) and the non-standard `android.permission.AD_ID` (Poing bridge AAR). Play Console: Data safety / Advertising-ID declaration must be answered consistently, and for a Families/child-directed app Play may require the AD_ID permission to be removed (`tools:node="remove"`) - owner decision, not done here |
| Approximate location from ad SDK | WARNING | Policy says IP-derived approximate location may be inferred by Google. Cannot prove the SDK's exact behaviour from source |
| Android permissions | WARNING | Preset: INTERNET only. Merged manifest also has ACCESS_NETWORK_STATE, READ_BASIC_PHONE_STATE, WAKE_LOCK, FOREGROUND_SERVICE, BILLING (from SDKs). No camera/mic/contacts/storage/location. Re-check the merged manifest of the RELEASE build before submission |
| iOS privacy config | PASS | no camera/mic/photo usage strings, no collected-data declarations set to true, tracking off, Apple sign-in entitlement only |
| Internet requirement | PASS | `InternetManager` probe `https://www.gstatic.com/generate_204` (Google; IP exposed; no payload). Disclosed in section 4 |
| Cloud save absence | PASS | none; policy says no cloud save and no server |
| Retention / deletion | PASS | local only: NEW GAME, clear storage, uninstall; Apple local flag removable via sign-out. Google/Apple-held data referred to their controls |
| Children / child-directed config | PASS | `CHILD_DIRECTED=true` -> TFCD + TFUA + max rating G, UMP `tag_for_under_age_of_consent` |
| Production ad IDs / consent form | WARNING | prod IDs injected by CI only; UMP behaviour with child-directed tagging (Privacy Options button visibility) is SDK-determined and was not exercised on a device |
| Policy URL for store consoles | PASS | Live at https://abhilashdeva.github.io/beamshift-privacy/ (HTTPS, byte-identical to docs/privacy-policy/index.html); `StoreConfig.PRIVACY_POLICY_URL` set. Still to be entered in the store consoles |
| Age range screen (Android) | PASS | `age_selection.tscn/.gd`, `AgeGroup`: UNKNOWN / CHILD_12_OR_YOUNGER / TEEN_13_TO_17 / ADULT_18_PLUS. Shown once on Android (splash -> screen while UNKNOWN); desktop/iOS never. A range only: no exact age, no date of birth, no name/email. Policy sections 1, 2, 7, 10 |
| Age range storage / transmission | PASS | Only `SaveManager.age_group` (local `user://savegame.json`, additive field, kept by NEW GAME). No network code reads it: `test_families.gd::test_age_range_is_never_transmitted` allow-lists every script that mentions `age_group` / `AgeGroup.` (age_group, age_selection, platform_account, save_manager, studio_splash). Policy words it as "BeamShift does not send it to any BeamShift server or other BeamShift-operated service" - a claim about BeamShift, not about every third-party SDK |
| Age range and ads | PASS | `AdConfig.CHILD_DIRECTED` is a constant `true`; ad scripts never reference the age range (tested). TFCD + TFUA + max rating G for every group. No personalised / adult-targeted path exists |
| Play Games vs age range (BeamShift code) | PASS | `PlatformAccount.apply_age_group()` is the only starter: TEEN/ADULT only. UNKNOWN and CHILD never call `GodotPlayGameServices.initialize()` / `is_authenticated()` / `load_current_player()`; `is_supported()` false so Account shows the local profile. 13+ stays optional; nothing requires sign-in |
| PlayGamesInitProvider | WARNING | **Provider behaviour, not confirmed data collection.** The `play-services-games-v2` library registers `com.google.android.gms.games.provider.PlayGamesInitProvider` (merged manifest, authority `<applicationId>.playgamesinitprovider`) which Android starts at process launch, outside BeamShift GDScript control; the plugin also calls `PlayGamesSdk.initialize` from `GodotAndroidPlugin.initialize()` (only reached for 13+). What the provider alone does (e.g. any automatic sign-in attempt) was NOT verified on a device. The policy therefore says "BeamShift's own code does not start sign-in ..." and "the Play Games library ... may run its own checks when the app starts", never "Play Games never initializes". Possible hard fix (owner decision, not done): remove the provider via a manifest `tools:node="remove"` entry |
| Rewarded Hint confirmation | PASS | `HintAdDialog` ("GET A HINT?", CANCEL / WATCH AD) before an AVAILABLE rewarded ad; WATCH AD calls the existing `AdManager.show_rewarded_hint`; hint only from the reward callback. Not shown when no ad can start, in tutorials, QA or desktop. No Forced Ads does not remove it. Policy section 5 |

## Corrections to the brief's assumptions
None contradicted the source, but three things needed careful wording rather than "we receive nothing":
Apple sign-in *requests* email (not stored); the connectivity probe goes to a Google host; the ad SDK adds the AD_ID permission.

## Families / age-screen update (2026-10-03)

Policy text, generated web copy and tests updated for the Android age-range screen, Play Games gating, the
rewarded-Hint confirmation and the child-directed-for-everyone ad statement. Effective date / Last updated stay
3 October 2026 (the policy has not been published since this change - the public repo copy is prepared, uncommitted).
Wording decisions: (1) no in-game age editor is implied - the policy says the range is asked once and "does not currently
provide a setting to change the range"; clear-data instructions are not repeated there (section 8 already covers
clearing storage); (2) no absolute Play Games claim (see PlayGamesInitProvider row); (3) advertising-ID text is precise,
not absolute; (4) no ad frequency is promised in the legal text. Play Console target audience being prepared:
9-12, 13-15, 16-17, 18+. The Families declaration has NOT been submitted and Play Console setup is NOT complete.
