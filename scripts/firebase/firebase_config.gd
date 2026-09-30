class_name FirebaseConfig
extends RefCounted
## THE one place Firebase project configuration lives (Firebase REST Auth Phase 1).
## Firestore/CloudSave integration is Phase 2 - do not add Firestore fields here yet.
##
## The Web API key is a client-visible config value, not an auth secret (it identifies
## the Firebase project to Google's servers; the real security boundary is Firebase's
## own server-side rules/provider config). Even so, per this project's existing
## config-centralization convention (AdConfig.production_ids() / the gitignored
## config/ad_ids.local.json pattern), it lives in ONE gitignored local file, never
## hardcoded in source or scattered through gameplay scripts:
##
##   res://config/firebase_config.local.json   ->   {"web_api_key": "..."}
##
## To obtain it: Firebase Console (console.firebase.google.com) -> select the
## "BeamShift" project (Google Cloud project id "beamshift-game") -> the gear icon ->
## "Project settings" -> "General" tab -> "Web API Key" field. That value is NOT an
## OAuth client secret and NOT a service-account key - never paste either of those here.
##
## google-services.json is deliberately NOT used - this REST architecture needs no
## native Android/iOS Firebase SDK and no google-services Gradle plugin (see
## STORE_RELEASE.md / CLAUDE.md "Firebase REST Auth" section).

const PROJECT_ID := "beamshift-game"
const CONFIG_FILE := "res://config/firebase_config.local.json"

## Google Auth Platform's Web OAuth client id (Google Sign-In / Credential Manager Phase
## 4A). This is the "Web client (auto created by Google Service)" id, NOT the Android
## OAuth client - Credential Manager's GetGoogleIdOption.setServerClientId() and
## Firebase's accounts:signInWithIdp both need the WEB client id specifically (it is what
## Firebase uses server-side to verify the ID token's audience). This value is not a
## secret - it is compiled into every Google Sign-In request the client makes and is
## visible in any decoded ID token - so unlike the Web API key it is a plain const here,
## matching StoreConfig.NO_FORCED_ADS's precedent for non-secret identifiers.
const GOOGLE_WEB_CLIENT_ID := "516411257761-3ufb515qh3tknvkbad1qvt5kqeoafpit.apps.googleusercontent.com"

## Google Auth Platform's iOS OAuth client id (iOS Google Sign-In bridge, Phase iOS-1).
## Android's Credential Manager flow needs the WEB client id (see GOOGLE_WEB_CLIENT_ID's
## own comment) because it constructs the token server-side; the iOS bridge instead opens
## Google's OAuth endpoint directly (ASWebAuthenticationSession, no vendored Google SDK -
## see tools/ios_plugin_src/google_signin_ios/), so it authenticates AS the iOS client and
## must use the iOS client id here, never the web or Android client id. Both are
## registered under the same Firebase project ("beamshift-game"), so Firebase's
## accounts:signInWithIdp still accepts the resulting ID token's audience.
const GOOGLE_IOS_CLIENT_ID := "516411257761-sv11p2kflgi617bcr1po4jqn4tc0d5ai.apps.googleusercontent.com"

## The iOS OAuth client's reversed-DNS form, required as the custom URL scheme
## ASWebAuthenticationSession's callback redirects to (Google's iOS OAuth convention -
## there is no Android equivalent, Android's flow never leaves the app). Not a secret -
## same visibility as GOOGLE_IOS_CLIENT_ID.
const GOOGLE_IOS_REVERSED_CLIENT_ID := "com.googleusercontent.apps.516411257761-sv11p2kflgi617bcr1po4jqn4tc0d5ai"

static var _cache: Dictionary = {}


static func _load() -> Dictionary:
	if _cache.is_empty() and FileAccess.file_exists(CONFIG_FILE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_FILE))
		if typeof(parsed) == TYPE_DICTIONARY:
			_cache = parsed
	return _cache


static func web_api_key() -> String:
	return str(_load().get("web_api_key", ""))


static func is_configured() -> bool:
	return web_api_key() != ""
