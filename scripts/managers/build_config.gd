class_name BuildConfig
extends RefCounted
## THE one place that decides "internal QA" vs "external test" vs "production".
## Not an autoload (rule 6): it owns no state, only compile-time constants
## that other scripts derive their QA-only UI flags from.
##
## EXTERNAL_TEST is the polished beta/tester configuration: it looks like a
## normal game, but does not imply final store production monetization/signing.
## Every QA-only UI/unlock flag in LevelManager derives from QA_TOOLS, and
## game.gd hides the tutorial debug overlay and generator debug tag behind it.
## This hides: QA +50, V3 TEST / NEXT V3, FUSION TEST / NEXT FUSION, SELECTOR
## TEST / NEXT SELECTOR, V5 TEST / NEXT V5, QA Level Select, the tutorial debug
## overlay, the "V4/V5 <band>" tags, and unlock-all shortcuts. QA systems are
## hidden, never deleted.
##
## NOT covered (separate release items, see ADS_MONETIZATION.md and PROCEDURAL_GENERATION.md):
## Google TEST ad ids (AdConfig) and the generator rollout switches LevelManager.USE_V3_FOR_PROCEDURAL_QA /
## USE_FUSION_PROGRESSION_FOR_QA (which generator version NEW play uses - a gameplay decision, not UI).
const MODE_INTERNAL_QA := 0
const MODE_EXTERNAL_TEST := 1
const MODE_PRODUCTION := 2

const BUILD_MODE := MODE_EXTERNAL_TEST

const IS_INTERNAL_QA_BUILD := BUILD_MODE == MODE_INTERNAL_QA
const IS_EXTERNAL_TEST_BUILD := BUILD_MODE == MODE_EXTERNAL_TEST
const IS_PRODUCTION_BUILD := BUILD_MODE == MODE_PRODUCTION
const QA_TOOLS := IS_INTERNAL_QA_BUILD
