#!/usr/bin/env bash
# Turns the files downloaded from the Apple developer portal into the
# repository secrets the release workflow reads, using the GitHub CLI.
#
# Expects, in $APPLE_DIR (default ~/Documents/beamshift-signing):
#   dist.key                 private key made with openssl (tools/ci made it)
#   distribution.cer         the Apple Distribution certificate downloaded
#                            after uploading dist.csr
#   *.mobileprovision        the App Store provisioning profile
#   AuthKey_<KEYID>.p8       the App Store Connect API key
#   ids.env                  two lines:  APPLE_TEAM_ID=XXXXXXXXXX
#                                        ASC_ISSUER_ID=<uuid>
# Optional: beamshift-upload.keystore + keystore.env (ANDROID_KEYSTORE_USER=..., ANDROID_KEYSTORE_PASSWORD=...)
# to set the Android secrets in the same pass.
#
# Run from Git Bash:  tools/ci/set_apple_secrets.sh [owner/repo]
# Needs `gh auth status` to pass first.
set -euo pipefail
APPLE_DIR="${APPLE_DIR:-$HOME/Documents/beamshift-signing}"
REPO="${1:-bijju/beam-shiflt}"
cd "$APPLE_DIR"
umask 077

need() { [ -s "$1" ] || { echo "missing: $APPLE_DIR/$1" >&2; exit 1; }; }
need dist.key; need distribution.cer; need ids.env
# shellcheck disable=SC1091
source ids.env
: "${APPLE_TEAM_ID:?set in ids.env}"; : "${ASC_ISSUER_ID:?set in ids.env}"

profile=$(ls -1 *.mobileprovision 2>/dev/null | head -1) || true
[ -n "$profile" ] || { echo "missing: a .mobileprovision in $APPLE_DIR" >&2; exit 1; }
p8=$(ls -1 AuthKey_*.p8 2>/dev/null | head -1) || true
[ -n "$p8" ] || { echo "missing: AuthKey_<KEYID>.p8 in $APPLE_DIR" >&2; exit 1; }
key_id=$(basename "$p8" .p8); key_id="${key_id#AuthKey_}"

# The .cer from Apple is DER; the p12 needs PEM. The p12 password is random,
# kept only in p12.pass beside the key and in the secret.
openssl x509 -inform DER -in distribution.cer -out distribution.pem 2>/dev/null \
  || cp distribution.cer distribution.pem
[ -s p12.pass ] || openssl rand -base64 24 > p12.pass
pass=$(cat p12.pass)
openssl pkcs12 -export -inkey dist.key -in distribution.pem -out dist.p12 -passout "pass:$pass"
openssl pkcs12 -in dist.p12 -passin "pass:$pass" -nokeys -noout 2>/dev/null || { echo "p12 did not verify" >&2; exit 1; }

b64() { base64 -w0 "$1" 2>/dev/null || base64 "$1" | tr -d '\n'; }

gh secret set APPLE_TEAM_ID                 -R "$REPO" --body "$APPLE_TEAM_ID"
gh secret set IOS_DIST_CERT_B64             -R "$REPO" --body "$(b64 dist.p12)"
gh secret set IOS_DIST_CERT_PASSWORD        -R "$REPO" --body "$pass"
gh secret set IOS_PROVISIONING_PROFILE_B64  -R "$REPO" --body "$(b64 "$profile")"
gh secret set ASC_ISSUER_ID                 -R "$REPO" --body "$ASC_ISSUER_ID"
gh secret set ASC_KEY_ID                    -R "$REPO" --body "$key_id"
gh secret set ASC_API_PRIVATE_KEY           -R "$REPO" < "$p8"

if [ -s beamshift-upload.keystore ] && [ -s keystore.env ]; then
  # shellcheck disable=SC1091
  source keystore.env
  gh secret set ANDROID_KEYSTORE_B64      -R "$REPO" --body "$(b64 beamshift-upload.keystore)"
  gh secret set ANDROID_KEYSTORE_USER     -R "$REPO" --body "${ANDROID_KEYSTORE_USER:?}"
  gh secret set ANDROID_KEYSTORE_PASSWORD -R "$REPO" --body "${ANDROID_KEYSTORE_PASSWORD:?}"
fi

echo; gh secret list -R "$REPO"
