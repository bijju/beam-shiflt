#!/usr/bin/env bash
# Stamp one release version everywhere it must agree. Run by the release
# workflow; usable by hand:  tools/ci/stamp_version.sh 1.0.6
#
# Derives a monotonic build number from the version (major*10000 +
# minor*100 + patch, so 1.0.6 -> 10006) and rewrites:
#   export_presets.cfg  both Android presets  version/name + version/code
#   export_presets.cfg  iOS preset            application/short_version + application/version
#   project.godot                             config/version (the credits screen reads it)
#
# Optional env, set by the workflow when the Apple secrets exist:
#   APPLE_TEAM_ID     -> iOS application/app_store_team_id
#   IOS_PROFILE_UUID  -> iOS application/provisioning_profile_uuid_release
#
# Every substitution must hit the expected number of lines or the script
# fails: a silent miss would ship a stale versionCode and Play would refuse it.
set -euo pipefail

version="${1:-}"
version="${version#v}"
if ! [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "usage: $0 MAJOR.MINOR.PATCH (got '${1:-}')" >&2
  exit 2
fi
major="${BASH_REMATCH[1]}"; minor="${BASH_REMATCH[2]}"; patch="${BASH_REMATCH[3]}"
if (( minor > 99 || patch > 99 )); then
  echo "minor and patch must stay below 100 to keep build codes monotonic" >&2
  exit 2
fi
code=$(( major * 10000 + minor * 100 + patch ))

root="$(cd "$(dirname "$0")/../.." && pwd)"
presets="$root/export_presets.cfg"
project="$root/project.godot"

# sub FILE PATTERN REPLACEMENT EXPECTED_COUNT LABEL
sub() {
  local file="$1" pattern="$2" repl="$3" want="$4" label="$5"
  local have
  have=$(grep -cE "$pattern" "$file" || true)
  if [ "$have" != "$want" ]; then
    echo "stamp failed: $label matched $have line(s), expected $want (pattern $pattern)" >&2
    exit 1
  fi
  local tmp="$file.stamp.tmp"
  sed -E "s|$pattern|$repl|" "$file" > "$tmp" && mv "$tmp" "$file"
}

sub "$presets" '^version/code=[0-9]+$'                 "version/code=$code"                       2 "android version/code"
sub "$presets" '^version/name=".*"$'                   "version/name=\"$version\""                2 "android version/name"
sub "$presets" '^application/short_version=".*"$'      "application/short_version=\"$version\""   1 "ios short_version"
sub "$presets" '^application/version=".*"$'            "application/version=\"$code\""            1 "ios version"
sub "$project" '^config/version=".*"$'                 "config/version=\"$version\""              1 "project config/version"

team="${APPLE_TEAM_ID:-}"
if [ -n "$team" ]; then
  sub "$presets" '^application/app_store_team_id=".*"$' "application/app_store_team_id=\"$team\"" 1 "ios team id"
fi
uuid="${IOS_PROFILE_UUID:-}"
if [ -n "$uuid" ]; then
  sub "$presets" '^application/provisioning_profile_uuid_release=".*"$' \
      "application/provisioning_profile_uuid_release=\"$uuid\"" 1 "ios profile uuid"
fi

echo "stamped version=$version build_code=$code team=${team:--} profile=${uuid:--}"
