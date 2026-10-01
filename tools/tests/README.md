# BeamShift automated tests + coverage

Dev-only (`tools/` is excluded from every export preset). Nothing here ships.

## Run

```powershell
powershell -ExecutionPolicy Bypass -File tools/tests/run_coverage.ps1            # everything
powershell -ExecutionPolicy Bypass -File tools/tests/run_coverage.ps1 -Filter ads # one test file (substring)
```

Prerequisite (once, and after adding a new `class_name` script): `godot --headless --editor --import`.

Output: pass/fail summary on the console and the full per-file report in
`tools/tests/coverage_report.txt` (uncovered line ranges per file). Exit code is non-zero if a test fails,
a test aborts (a GDScript runtime error after an `await` silently kills a test, so the runner has a
150 s watchdog), or the engine logged a `SCRIPT ERROR`.

## How it works

* `run_coverage.ps1` copies the project to `%TEMP%\bs_cov` (never touches the working tree), runs
  `instrument.gd` over the copy, registers the `Cov` autoload there, and runs `test_runner.tscn`.
* **Godot has no GDScript coverage tool**, so `instrument.gd` inserts a `Cov.h(id)` call before every
  statement inside a function body of `scripts/**` and `levels/**` (statement coverage, not branch coverage).
  Class-level declarations (`const`, `var`, `signal`, `enum`), `else`/`elif`/`match` arm labels and lambdas'
  inner lines are not counted.
* The copy uses its own user dir (`%APPDATA%\BeamShiftCoverageTmp`) so tests can never touch the real save,
  platform account file. The runner resets `SaveManager` to a fresh profile before every test and
  stops `InternetManager`'s background probe (no real network traffic from tests).
* Tests live in `tools/tests/cases/test_*.gd` (`extends TestCase`, methods named `test_*`, `await` allowed).
  Test doubles are in `tools/tests/fakes/`: fake ad / store backends (PlatformAccount is driven
  directly through its callbacks).
* Dev tools that end with `get_tree().quit()` run as child Godot processes (`test_dev_tools.gd`); their counts
  are merged back through `Cov`'s `cov_dump=` file.

## What is deliberately not covered

* Code that only runs on a device with the native plugin/OS (e.g. `CloudSave._load_native_backend`, `StoreManager`'s
  backend selection, Android safe-area branches of `SafeAreaMargin`, `AdBackendAdMob` plugin calls) is exercised
  through fakes where possible; the OS-gated lines themselves cannot execute on desktop.
* Unreachable code behind constants (e.g. the `match` in `EraTheme.for_era` after `UNIFIED_BLUE_THEME_ONLY`).
* The one-off `make_ios_icon` tool.
* `tools/level_editor/**`, `tools/ci/**` and scene/`.tscn` wiring are outside the instrumented roots.
* Pixel-level / real-touch behaviour: still MANUAL (see `TEST_PLAN.md`).
