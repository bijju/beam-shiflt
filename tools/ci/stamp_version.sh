#!/usr/bin/env bash
# Stamp one release version everywhere it must agree. Run by the release
# workflow; usable by hand:  tools/ci/stamp_version.sh 1.0.6
#
# Rewrites:
#   export_presets.cfg  both Android presets  version/name (+ version/code, see below)
#   export_presets.cfg  iOS preset            application/short_version + application/version
#   project.godot                             config/version (the credits screen reads it)
#
# Android versionCode is NOT derived from the version name (1.0.2 would give
# 10002, below an already-used 10006). It is an independent monotonic counter:
#   ANDROID_VERSION_CODE=10007 tools/ci/stamp_version.sh 1.0.3   -> sets 10007
#   tools/ci/stamp_version.sh 1.0.3                              -> keeps the preset's code
# The value must be an integer, >= the code already in the presets (never
# lower), and both Android presets must currently agree.
# iOS CFBundleVersion still derives from the version (major*10000 + minor*100
# + patch), as before.
#
# Optional env, set by the workflow when the Apple secrets exist:
#   IOS_BUILD_RUN     -> "RUN.ATTEMPT" (GitHub run_number.run_attempt); makes the iOS
#                        CFBundleVersion "CODE.RUN.ATTEMPT" so re-uploading one marketing
#                        version never repeats a build number. Unset -> plain CODE.
#   APPLE_TEAM_ID     -> iOS application/app_store_team_id
#   IOS_PROFILE_UUID  -> iOS application/provisioning_profile_uuid_release
#   IOS_PROFILE_NAME  -> iOS application/provisioning_profile_specifier_release
#                        (required whenever the UUID is set)
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
ios_code=$(( major * 10000 + minor * 100 + patch ))

# iOS CFBundleVersion: 1-3 period-separated integers. "CODE.RUN.ATTEMPT" is numeric,
# App Store compatible, deterministic per (version, run) and strictly increases for
# a given marketing version because run_number only ever grows.
ios_build="$ios_code"
run_suffix="${IOS_BUILD_RUN:-}"
if [ -n "$run_suffix" ]; then
  if ! [[ "$run_suffix" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "stamp failed: IOS_BUILD_RUN must be RUN.ATTEMPT (got '$run_suffix')" >&2
    exit 2
  fi
  ios_build="$ios_code.$run_suffix"
fi

root="$(cd "$(dirname "$0")/../.." && pwd)"
presets="$root/export_presets.cfg"
project="$root/project.godot"

# Android versionCode: explicit override, else keep what the presets already carry.
current_codes=$(grep -E '^version/code=[0-9]+$' "$presets" | cut -d= -f2 | sort -u)
if [ "$(printf '%s
' "$current_codes" | grep -c .)" != 1 ]; then
  echo "stamp failed: the Android presets must carry one identical version/code (found: $(echo $current_codes))" >&2
  exit 1
fi
code="${ANDROID_VERSION_CODE:-$current_codes}"
if ! [[ "$code" =~ ^[0-9]+$ ]] || (( code > 2100000000 )); then
  echo "stamp failed: ANDROID_VERSION_CODE must be an integer <= 2100000000 (got '$code')" >&2
  exit 2
fi
if (( code < current_codes )); then
  echo "stamp failed: android versionCode $code is lower than the current $current_codes (must never decrease)" >&2
  exit 1
fi

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
sub "$presets" '^application/version=".*"$'            "application/version=\"$ios_build\""        1 "ios version"
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

pname="${IOS_PROFILE_NAME:-}"
if [ -n "$uuid" ] && [ -z "$pname" ]; then
  echo "stamp failed: IOS_PROFILE_UUID is set but IOS_PROFILE_NAME is empty" >&2
  exit 1
fi
if [ -n "$pname" ]; then
  # Escape for the .cfg string (\ and "), then for the sed replacement (\ & |).
  esc=$(printf '%s' "$pname" | sed -e 's/[\\"]/\\&/g' -e 's/[\\&|]/\\&/g')
  sub "$presets" '^application/provisioning_profile_specifier_release=".*"$' \
      "application/provisioning_profile_specifier_release=\"$esc\"" 1 "ios profile name"
fi

echo "stamped version=$version android_code=$code ios_build=$ios_build team=${team:--} profile=${uuid:--} profile_name=${pname:--}"
