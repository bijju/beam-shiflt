# Dev-only: copies the project, instruments the copy, runs every test case in it,
# and writes tools/tests/coverage_report.txt. The real working tree is never modified.
#   powershell -File tools/tests/run_coverage.ps1 [-Godot D:\Godot_v4.7.1-stable_win64.exe] [-Filter name[,name]] [-SkipQa]
#
# Two passes: the PRODUCTION pass (BuildConfig.BUILD_MODE as committed) runs every test; the
# INTERNAL-QA pass flips BuildConfig to MODE_INTERNAL_QA in a second copy and re-runs the tests that
# reach QA-only branches (QA buttons, QA HUD labels). Its counts are merged into the one report;
# tests that assert production-only behaviour may fail in that pass and are reported as warnings.
param(
	[string]$Godot = "D:\Godot_v4.7.1-stable_win64.exe",
	[string]$Filter = "",
	[string]$QaFilter = "ui_screens,game_session,game_flow,managers,production_leak",
	[int]$TimeoutSec = 2400,
	[switch]$SkipQa
)
$ErrorActionPreference = "Stop"
$src = (Resolve-Path "$PSScriptRoot\..\..").Path
$report = Join-Path $src "tools\tests\coverage_report.txt"
$prodDump = Join-Path $env:TEMP "bs_cov_prod_counts.json"

function Run-Godot([string[]]$GodotArgs, [string]$Log, [string]$Err) {
	$p = Start-Process -FilePath $Godot -ArgumentList $GodotArgs -NoNewWindow -PassThru -RedirectStandardOutput $Log -RedirectStandardError $Err
	if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); throw "tests exceeded ${TimeoutSec}s" }
	$p.WaitForExit()
	return $p.ExitCode
}

function Build-Copy([string]$Name, [bool]$Qa) {
	$dst = Join-Path $env:TEMP $Name
	robocopy $src $dst /MIR /XD android builds .git .claude coverage_work /NFL /NDL /NJH /NJS /NP | Out-Null
	if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }
	if ($Qa) {
		$bc = Join-Path $dst "scripts\managers\build_config.gd"
		(Get-Content $bc -Raw).Replace("const BUILD_MODE := MODE_PRODUCTION", "const BUILD_MODE := MODE_INTERNAL_QA") | Set-Content $bc -NoNewline -Encoding utf8
	}
	$ip = Start-Process -FilePath $Godot -ArgumentList @("--headless", "--path", $src, "--script", "res://tools/tests/instrument.gd", "--", "$dst") -NoNewWindow -PassThru -Wait
	if ($ip.ExitCode -ne 0) { throw "instrument failed" }

	# Register Cov as the FIRST autoload of the copy only, and isolate user:// so tests can never
	# touch the real save or platform account.
	$pg = Join-Path $dst "project.godot"
	$txt = Get-Content $pg -Raw
	$txt = $txt.Replace("[autoload]`r`n", "[autoload]`r`n`r`nCov=`"*res://tools/tests/cov.gd`"`r`n").Replace("[autoload]`n", "[autoload]`n`nCov=`"*res://tools/tests/cov.gd`"`n")
	$txt = $txt.Replace("config/name=`"BeamShift`"", "config/name=`"BeamShift`"`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"BeamShiftCoverageTmp`"")
	Set-Content $pg $txt -NoNewline -Encoding utf8
	$udir = Join-Path $env:APPDATA "BeamShiftCoverageTmp"
	if (Test-Path $udir) { Remove-Item -Recurse -Force $udir }
	return $dst
}

function Run-Pass([string]$Label, [string]$Dst, [string[]]$Extra, [string]$PassFilter) {
	$log = Join-Path $env:TEMP "bs_cov_run.log"
	$err = Join-Path $env:TEMP "bs_cov_run.err"
	$a = @("--headless", "--path", $Dst, "res://tools/tests/test_runner.tscn", "--", "report=$report") + $Extra
	if ($PassFilter -ne "") { $a += "filter=$PassFilter" }
	$code = Run-Godot $a $log $err
	$out = (Get-Content $log, $err -ErrorAction SilentlyContinue) -join "`n"
	# A GDScript runtime error aborts a test function without failing an assertion, so treat it as a failure.
	$scriptErrors = @($out -split "`n" | Where-Object { $_ -match "^SCRIPT ERROR" -or $_ -match "^ERROR: .*(Invalid|Out of bounds|Nonexistent)" })
	Write-Host "---- $Label pass ----"
	$out -split "`n" | Where-Object { $_ -match "^(FAIL|TESTS|slow|OVERALL|EXCL|STATEMENT)|^\s+\d+\.\d%|^ +expected|^SCRIPT ERROR|^    [^ ]" } | ForEach-Object { Write-Host $_ }
	if ($scriptErrors.Count -gt 0) { Write-Host "SCRIPT ERRORS: $($scriptErrors.Count)"; $scriptErrors | Select-Object -First 15 | ForEach-Object { Write-Host $_ } }
	return @{ Code = $code; ScriptErrors = $scriptErrors.Count }
}

$prod = Build-Copy "bs_cov" $false
$dumpArgs = @()
if (-not $SkipQa) { $dumpArgs = @("cov_dump=$prodDump") }
$r = Run-Pass "production" $prod $dumpArgs $Filter
$exit = $r.Code
if ($r.ScriptErrors -gt 0) { $exit = 3 }

if (-not $SkipQa -and $Filter -eq "") {
	$qa = Build-Copy "bs_cov_qa" $true
	$q = Run-Pass "internal-qa (counts merged, failures here are warnings)" $qa @("merge=$prodDump") $QaFilter
	if ($q.ScriptErrors -gt 0) { $exit = 3 }
}
exit $exit
