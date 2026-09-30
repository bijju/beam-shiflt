#!/usr/bin/env bash
# Switch BuildConfig.BUILD_MODE:  tools/ci/set_build_mode.sh production|external_test|internal_qa
# With no argument it only prints the current mode. Committed source must stay `production`.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
file="$root/scripts/managers/build_config.gd"
pattern='^const BUILD_MODE := MODE_[A-Z_]+$'

if [ "$(grep -cE "$pattern" "$file")" != 1 ]; then
  echo "build_config.gd: expected exactly one BUILD_MODE line" >&2
  exit 1
fi

case "${1:-}" in
  "")            grep -E "$pattern" "$file"; exit 0 ;;
  production)    mode=MODE_PRODUCTION ;;
  external_test) mode=MODE_EXTERNAL_TEST ;;
  internal_qa)   mode=MODE_INTERNAL_QA ;;
  *) echo "usage: $0 [production|external_test|internal_qa]" >&2; exit 2 ;;
esac

sed -E "s|$pattern|const BUILD_MODE := $mode|" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
grep -E "$pattern" "$file"
