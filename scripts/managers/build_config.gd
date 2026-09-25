class_name BuildConfig
extends RefCounted
## THE one place that decides "QA build" vs "production build" (Phase 4, D102). Not an autoload (rule 6):
## it owns no state, only compile-time constants that other scripts derive their QA-only UI flags from.
##
## RELEASE: set IS_PRODUCTION_BUILD := true. Every QA-only UI/unlock flag in LevelManager derives from
## QA_TOOLS, and game.gd hides the tutorial debug overlay and the generator debug tag behind it, so this
## single constant hides: QA +50, V3 TEST / NEXT V3, FUSION TEST / NEXT FUSION, QA Level Select, the
## tutorial debug overlay, the "V4 <band> F#" / "FAILED>V2" tag, and the unlock-all-tutorials /
## unlock-all-campaign shortcuts. QA tools are hidden, never deleted.
##
## NOT covered (separate release items, see ADS_MONETIZATION.md and PROCEDURAL_GENERATION.md):
## Google TEST ad ids (AdConfig) and the generator rollout switches LevelManager.USE_V3_FOR_PROCEDURAL_QA /
## USE_FUSION_PROGRESSION_FOR_QA (which generator version NEW play uses - a gameplay decision, not UI).
const IS_PRODUCTION_BUILD := false
const QA_TOOLS := not IS_PRODUCTION_BUILD
