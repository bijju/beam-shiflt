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
| Advertising identifiers | WARNING | Merged debug manifest contains `android.permission.AD_ID` + `com.google.android.gms.permission.AD_ID` (added by the ad SDK, not by `export_presets.cfg`). Policy words it as "may use a device advertising or app identifier". Play Console: Data safety / Advertising-ID declaration must be answered consistently, and for a Families/child-directed app Play may require the AD_ID permission to be removed (`tools:node="remove"`) - owner decision, not done here |
| Approximate location from ad SDK | WARNING | Policy says IP-derived approximate location may be inferred by Google. Cannot prove the SDK's exact behaviour from source |
| Android permissions | WARNING | Preset: INTERNET only. Merged manifest also has ACCESS_NETWORK_STATE, READ_BASIC_PHONE_STATE, WAKE_LOCK, FOREGROUND_SERVICE, BILLING (from SDKs). No camera/mic/contacts/storage/location. Re-check the merged manifest of the RELEASE build before submission |
| iOS privacy config | PASS | no camera/mic/photo usage strings, no collected-data declarations set to true, tracking off, Apple sign-in entitlement only |
| Internet requirement | PASS | `InternetManager` probe `https://www.gstatic.com/generate_204` (Google; IP exposed; no payload). Disclosed in section 4 |
| Cloud save absence | PASS | none; policy says no cloud save and no server |
| Retention / deletion | PASS | local only: NEW GAME, clear storage, uninstall; Apple local flag removable via sign-out. Google/Apple-held data referred to their controls |
| Children / child-directed config | PASS | `CHILD_DIRECTED=true` -> TFCD + TFUA + max rating G, UMP `tag_for_under_age_of_consent` |
| Production ad IDs / consent form | WARNING | prod IDs injected by CI only; UMP behaviour with child-directed tagging (Privacy Options button visibility) is SDK-determined and was not exercised on a device |
| Policy URL for store consoles | WARNING | GitHub Pages not published; `StoreConfig.PRIVACY_POLICY_URL` intentionally empty until verified live |

## Corrections to the brief's assumptions
None contradicted the source, but three things needed careful wording rather than "we receive nothing":
Apple sign-in *requests* email (not stored); the connectivity probe goes to a Google host; the ad SDK adds the AD_ID permission.
