# Prints the Android signing values ready to paste into
# GitHub -> repo Settings -> Secrets and variables -> Actions.
# Run:  powershell -ExecutionPolicy Bypass -File tools/ci/print_github_secrets.ps1
# Values print to YOUR terminal only. Never commit this output.
#
# The alias and password are not in the repository (Godot keeps them in the
# gitignored .godot/export_credentials.cfg). Export them first:
#   $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "beamshift"
#   $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "..."

# Kept OUTSIDE the repository, beside the Apple signing files (STORE_RELEASE.md).
$keystore = Join-Path $env:USERPROFILE "Documents\beamshift-signing\beamshift-upload.keystore"
if (-not (Test-Path $keystore)) { Write-Error "Keystore not found: $keystore"; exit 1 }

Write-Host "`n=== ANDROID_KEYSTORE_B64 ===" -ForegroundColor Green
# Base64 of the raw bytes, written as ASCII with no BOM: a value that went
# through the console codepage once arrived with a BOM and broke base64 on
# the runner. Copy it from the file rather than from the terminal.
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystore))
$out = Join-Path $env:TEMP "beamshift_keystore_b64.txt"
[IO.File]::WriteAllText($out, $b64, [Text.Encoding]::ASCII)
Write-Host "written to $out ($($b64.Length) chars)"

Write-Host "`n=== ANDROID_KEYSTORE_USER ===" -ForegroundColor Green
if ($env:GODOT_ANDROID_KEYSTORE_RELEASE_USER) { $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER } else { "<your keystore alias>   (env var GODOT_ANDROID_KEYSTORE_RELEASE_USER not set)" }

Write-Host "`n=== ANDROID_KEYSTORE_PASSWORD ===" -ForegroundColor Green
if ($env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD) { $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD } else { "(set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD first)" }

Write-Host "`nPaste each value into a repo secret with the matching name, then delete $out." -ForegroundColor Yellow
