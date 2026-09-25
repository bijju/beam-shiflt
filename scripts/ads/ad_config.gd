class_name AdConfig
extends RefCounted
## The ONE place every advertising switch, rule constant and ad-unit ID lives
## (ADS_MONETIZATION.md). Nothing else in the project may contain an AdMob ID.
##
## THIS QA BUILD USES GOOGLE'S OFFICIAL SAMPLE (TEST) IDs ONLY. Production IDs
## are intentionally NOT in the repository: fill PRODUCTION_IDS locally (or inject
## them from CI), set USE_TEST_IDS = false, and change the export App ID (project
## setting admob/general/android/app_id and the iOS Info.plist key) - see the
## production checklist in ADS_MONETIZATION.md. A release build that still uses
## test IDs is reported loudly by config_problem().

## Master switch. false = no SDK, no consent flow, hints free, no interstitials.
const ADS_ENABLED := true
## true = Google sample IDs. MUST be false (and PRODUCTION_IDS filled) for production.
const USE_TEST_IDS := true
## QA: hints skip the rewarded ad (gameplay testing without a network).
const QA_BYPASS_REWARDED := false

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

## Deliberately empty in source control (no production IDs committed).
const PRODUCTION_IDS := {
	"android": {"app": "", "rewarded": "", "interstitial": ""},
	"ios": {"app": "", "rewarded": "", "interstitial": ""},
}


## "android" / "ios" / "" (desktop/editor: no ad platform).
static func platform() -> String:
	match OS.get_name():
		"Android":
			return "android"
		"iOS":
			return "ios"
	return ""


static func unit_id(kind: String) -> String:
	var p := platform()
	if p == "":
		return ""
	var table: Dictionary = TEST_IDS if USE_TEST_IDS else PRODUCTION_IDS
	return str(table[p].get(kind, ""))


## Non-empty = a configuration mistake worth a loud warning at startup.
static func config_problem() -> String:
	if USE_TEST_IDS and OS.has_feature("release"):
		return "TEST ad IDs in a RELEASE build - replace before publishing"
	if not USE_TEST_IDS:
		for p in PRODUCTION_IDS:
			for k in PRODUCTION_IDS[p]:
				if PRODUCTION_IDS[p][k] == "":
					return "production ad ID missing: %s/%s" % [p, k]
	return ""
