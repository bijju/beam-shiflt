#!/usr/bin/env bash
# Inject store configuration that must never be committed, from environment (CI secrets).
#   tools/ci/stamp_store_config.sh android|ios
#
# Writes/edits (all local to the runner's checkout):
#   config/ad_ids.local.json       AdMob unit ids read by AdConfig.production_ids() (gitignored)
#   project.godot [admob]          export App ID (Android manifest / iOS Info.plist)
#   export_presets.cfg (android)   godot_play_game_services/game_id
#
# Env:  ADMOB_ANDROID_APP_ID ADMOB_ANDROID_REWARDED_ID ADMOB_ANDROID_INTERSTITIAL_ID
#       ADMOB_IOS_APP_ID     ADMOB_IOS_REWARDED_ID     ADMOB_IOS_INTERSTITIAL_ID
#       PLAY_GAMES_GAME_ID   (Android only; the Play build cannot compile without it)
#       REQUIRE_ADMOB=1      fail (instead of warn) when any AdMob value is missing
#
# Without AdMob values a production build ships with ads OFF and hints free
# (AdConfig.ads_active() is false) - safe, never test ids.
set -euo pipefail

lane="${1:-}"
case "$lane" in android|ios) ;; *) echo "usage: $0 android|ios" >&2; exit 2 ;; esac

root="$(cd "$(dirname "$0")/../.." && pwd)"
if ! grep -qE '^const BUILD_MODE := MODE_PRODUCTION$' "$root/scripts/managers/build_config.gd"; then
  echo "::error::BuildConfig.BUILD_MODE is not MODE_PRODUCTION (tools/ci/set_build_mode.sh production)" >&2
  exit 1
fi

upper=$(echo "$lane" | tr '[:lower:]' '[:upper:]')
app_var="ADMOB_${upper}_APP_ID"; rew_var="ADMOB_${upper}_REWARDED_ID"; int_var="ADMOB_${upper}_INTERSTITIAL_ID"
app="${!app_var:-}"; rew="${!rew_var:-}"; int="${!int_var:-}"

# Ids are used inside JSON and a config line: accept the AdMob charset only.
for v in "$app" "$rew" "$int" "${PLAY_GAMES_GAME_ID:-}"; do
  if [[ -n "$v" && ! "$v" =~ ^[A-Za-z0-9~/._-]+$ ]]; then
    echo "::error::a store config value has unexpected characters" >&2; exit 1
  fi
done

if [ -n "$app" ] && [ -n "$rew" ] && [ -n "$int" ]; then
  mkdir -p "$root/config"
  printf '{"%s": {"app": "%s", "rewarded": "%s", "interstitial": "%s"}}\n' "$lane" "$app" "$rew" "$int" > "$root/config/ad_ids.local.json"
  if grep -q '^\[admob\]$' "$root/project.godot"; then
    echo "::error::project.godot already has an [admob] section; edit stamp_store_config.sh to update it" >&2; exit 1
  fi
  printf '\n[admob]\n\ngeneral/%s/app_id="%s"\n' "$lane" "$app" >> "$root/project.godot"
  echo "AdMob production ids stamped for $lane"
elif [ "${REQUIRE_ADMOB:-}" = "1" ]; then
  echo "::error::REQUIRE_ADMOB=1 but $app_var/$rew_var/$int_var are not all set" >&2; exit 1
else
  echo "::warning::AdMob ids for $lane not set - this build ships with ads OFF (hints free)"
fi

if [ "$lane" = "android" ]; then
  gid="${PLAY_GAMES_GAME_ID:-}"
  if [ -z "$gid" ]; then
    echo "::error::PLAY_GAMES_GAME_ID is not set - the Android build cannot compile without the Play Games project id" >&2
    exit 1
  fi
  presets="$root/export_presets.cfg"
  if [ "$(grep -c '^godot_play_game_services/game_id=' "$presets")" != 2 ]; then
    echo "::error::expected 2 game_id lines in export_presets.cfg" >&2; exit 1
  fi
  sed -E "s|^godot_play_game_services/game_id=.*$|godot_play_game_services/game_id=\"$gid\"|" "$presets" > "$presets.tmp" && mv "$presets.tmp" "$presets"
  echo "Play Games game id stamped"
fi
