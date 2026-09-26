class_name AdConfig
extends RefCounted
## The ONE place every advertising switch, rule constant and ad-unit ID lives
## (ADS_MONETIZATION.md). Nothing else in the project may contain an AdMob ID.
##
## Non-production builds use GOOGLE'S OFFICIAL SAMPLE (TEST) IDs. A PRODUCTION build
## (BuildConfig) never does: its IDs come from the gitignored PRODUCTION_IDS_FILE that
## tools/ci/stamp_store_config.sh writes from CI secrets, together with the export App ID
## (project setting admob/general/{android,ios}/app_id). If they are missing, ads_active()
## is false: no SDK, no consent flow, hints free - see ADS_MONETIZATION.md.

## Master switch. false = no SDK, no consent flow, hints free, no interstitials.
const ADS_ENABLED := true
## true = Google sample IDs; follows the build mode, so a production build can never use them.
const USE_TEST_IDS := not BuildConfig.IS_PRODUCTION_BUILD
## QA: hints skip the rewarded ad (gameplay testing without a network).
const QA_BYPASS_REWARDED := false
## The audience includes children under 13 (store listings: mixed audience), so every ad
## request is child-directed: TFCD + TFUA + max rating G, non-personalised, no IDFA/ATT.
## Changing this is a policy decision (Play Families / COPPA / Apple 1.3), not a tweak.
const CHILD_DIRECTED := true
## UMP sometimes never calls back; start the SDK anyway after this many seconds.
const CONSENT_TIMEOUT_SECONDS := 8.0

## Interstitial rule: every N legitimate completions AND at least this many seconds
## since the last interstitial. The counter resets ONLY when an interstitial is
## actually shown.
const INTERSTITIAL_EVERY_COMPLETIONS := 4
const INTERSTITIAL_MIN_SECONDS := 120

## Ad load retry back-off after a failed load (seconds, doubles up to the max).
const RETRY_SECONDS := 30.0
const RETRY_MAX_SECONDS := 240.0

const TEST_IDS := {
	"android": {
		"app": "ca-app-pub-3940256099942544~3347511713",
		"rewarded": "ca-app-pub-3940256099942544/5224354917",
		"interstitial": "ca-app-pub-3940256099942544/1033173712",
	},
	"ios": {
		"app": "ca-app-pub-3940256099942544~1458002511",
		"rewarded": "ca-app-pub-3940256099942544/1712485313",
		"interstitial": "ca-app-pub-3940256099942544/4411468910",
	},
}

## Production IDs are never in source control: CI (tools/ci/stamp_store_config.sh) writes this
## gitignored file from secrets before export. Shape: {"android": {"app","rewarded","interstitial"}, "ios": {...}}.
const PRODUCTION_IDS_FILE := "res://config/ad_ids.local.json"
const _ID_KINDS := ["app", "rewarded", "interstitial"]

static var _production_ids_cache: Dictionary = {}


static func production_ids() -> Dictionary:
	if _production_ids_cache.is_empty() and FileAccess.file_exists(PRODUCTION_IDS_FILE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRODUCTION_IDS_FILE))
		if typeof(parsed) == TYPE_DICTIONARY:
			_production_ids_cache = parsed
	return _production_ids_cache


## "android" / "ios" / "" (desktop/editor: no ad platform).
static func platform() -> String:
	match OS.get_name():
		"Android":
			return "android"
		"iOS":
			return "ios"
	return ""


static func unit_id(kind: String, p: String = platform()) -> String:
	if p == "":
		return ""
	var table: Dictionary = TEST_IDS if USE_TEST_IDS else production_ids()
	var row: Variant = table.get(p, {})
	return str(row.get(kind, "")) if typeof(row) == TYPE_DICTIONARY else ""


## Non-empty = a configuration mistake worth a loud warning at startup.
static func config_problem(p: String = platform()) -> String:
	if USE_TEST_IDS:
		return "TEST ad IDs in a RELEASE build - replace before publishing" if OS.has_feature("release") else ""
	for k in _ID_KINDS:
		if p != "" and unit_id(k, p) == "":
			return "production ad ID missing: %s/%s" % [p, k]
	return ""


## Ads run only with a complete ID set. A production build with missing IDs must not load the
## SDK at all (and hints then stay free) rather than request ads with empty/sample units.
static func ads_active(p: String = platform()) -> bool:
	return ADS_ENABLED and (USE_TEST_IDS or config_problem(p) == "")


## Optional developer test devices (AdMob hashed ids, from logcat "Use RequestConfiguration...
## setTestDeviceIds"): a gitignored JSON array in this file, never in tracked source. Lets a
## production-id build show test ads on registered devices only (no invalid traffic).
const TEST_DEVICES_FILE := "res://config/ad_test_devices.local.json"


static func test_device_ids() -> Array[String]:
	var ids: Array[String] = []
	if FileAccess.file_exists(TEST_DEVICES_FILE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_DEVICES_FILE))
		if typeof(parsed) == TYPE_ARRAY:
			for v in parsed:
				ids.append(str(v))
	return ids
