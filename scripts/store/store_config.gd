class_name StoreConfig
extends RefCounted
## The ONE place every in-app product ID and fallback price lives (STORE_RELEASE.md).
## Product IDs must match Play Console and App Store Connect exactly and can never be
## reused once created, even after deletion - never rename one, add a new one.

## Non-consumable. Removes interstitials only; the optional rewarded hint ad stays, so the
## store copy must never say "remove all ads" (product decision, 2026-09-26).
const NO_FORCED_ADS := "beamshift_no_forced_ads"

## Shown only until the store answers with its own localised price. Update it whenever the
## console price changes.
const FALLBACK_PRICES := {
	NO_FORCED_ADS: "$3.99",
}


## Hosted web copy of the privacy policy (docs/privacy-policy/, GitHub Pages) for the Play Console
## and App Store Connect listings. NOT opened in-game: Settings > Privacy Policy shows the native
## screen (privacy_policy_screen.gd) built from PrivacyPolicyText. Live; verified byte-identical to docs/privacy-policy/index.html.
const PRIVACY_POLICY_URL := "https://abhilashdeva.github.io/beamshift-privacy/"


static func product_ids() -> PackedStringArray:
	return PackedStringArray(FALLBACK_PRICES.keys())


static func sells(product_id: String) -> bool:
	return FALLBACK_PRICES.has(product_id)


static func fallback_price(product_id: String) -> String:
	return str(FALLBACK_PRICES.get(product_id, ""))
