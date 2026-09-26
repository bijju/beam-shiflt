class_name UIConstants
extends RefCounted
## Shared mobile UI sizing constants. Centralized so every screen uses the
## same touch-target and safe-margin values instead of scattering magic
## numbers across scenes. See DECISIONS.md ("Mobile UI polish") for the
## dp-to-project-pixel conversion this is based on.
##
## This project's reference canvas is 1080x1920 (project.godot's
## window/size/viewport_*), used with the "canvas_items" stretch mode.
## A 1080px-wide reference corresponds to the extremely common Android
## "xxhdpi" convention of a 360dp-wide screen at 3x density (1080 = 360 * 3).
## That makes 1 dp ~= 3 of this project's UI units on a device matching
## that convention. Real devices vary, but this is a reasonable, widely
## applicable baseline for a resolution-independent Godot UI, and matches
## what was actually observed on physical-device testing (values that
## looked reasonable as raw numbers were physically too small to tap).

## Minimum comfortable touch target, in project UI units.
## ~48dp * 3 = 144 - the lower end of Material Design's/iOS's recommended
## 48-56dp minimum touch target range.
const MIN_TOUCH_TARGET := 144.0

## Baseline outer safe-margin applied to every top-level MENU screen
## (Main Menu, Level Select, Settings, Tutorial Select) before any real OS
## safe-area inset is considered. ~32dp * 3 = 96.
const BASELINE_MARGIN := 96.0

## Gameplay-specific outer safe-margins (see DECISIONS.md D86 "Full-
## Screen Board Correction" and D87 "Final Gameplay Spacing Refinement").
## game.tscn's SafeAreaMargin uses these instead of BASELINE_MARGIN, via
## SafeAreaMargin.horizontal_margin_override/vertical_margin_override -
## menu screens are deliberately untouched (their own 96px baseline was
## already tuned/rendered-verified and isn't part of either pass). Real
## Android safe-area insets (notch/cutout/gesture-nav) still widen
## whichever value is in effect via maxf(), independently per side - this
## only shrinks the margin on a device that DOESN'T need the full 96px,
## which most modern phones in portrait don't on any of their four edges.
##
## D86 root-cause investigation: at the 1080x1920 reference this project
## validates against, BASELINE_MARGIN=96 gave Level 27 (7x8) 94.2% height
## utilization - matching Phase 2B's (D74) original claim - but
## `canvas_items`/`expand` stretch mode reveals MORE logical canvas
## height on any device taller than the 1080x1920 reference (most real
## Android phones today, commonly 19.5:9-20:9, e.g. 1080x2400) without
## the board growing to match, since a width-bound board's cell_size is
## capped by width alone - so height utilization silently degraded to
## ~65% on those taller devices. D86 fixed this uniformly (one value on
## all 4 sides); D87 then split it in two, since the user separately
## asked for Top/Bottom HUD to sit closer to the screen edge than
## left/right board margin should shrink further - two different
## requirements the single D86 value couldn't express at once.
##
## Horizontal (left/right): ~11dp * 3 = 32, UNCHANGED from D86 - the
## user explicitly confirmed D86's left/right board margin "looks
## acceptable" and asked not to reduce it further.
const GAMEPLAY_HORIZONTAL_MARGIN := 32.0
## Vertical (top/bottom): ~2.7dp * 3 = 8, new in D87 - matches
## GRID_SAFETY_MARGIN's own established "8px is a reasonable minimum
## real buffer" precedent elsewhere in this project. Top/Bottom HUD can
## safely sit this close to the screen edge (real Android safe-area
## insets still widen it via maxf() when a device actually needs more),
## since the HUD bars are rigid, aspect-locked art, not player-
## interactive content.
##
## IMPORTANT, proven during D87: for a WIDTH-BOUND board (the common
## case - MAX_COLUMNS<=8 on a portrait screen almost always binds on
## width, confirmed across every level checked), this constant's value
## has NO effect on the visible gap between the HUD and the board
## itself. CenterArea always absorbs 100% of whatever this margin frees
## up (size_flags_vertical = EXPAND_FILL), and the board is centered
## within it - so total_gap = screen_height - TopBar.height -
## BottomBar.height - board_height is a constant, independent of this
## margin, VBoxContainer separation, or any redistribution between
## them; shrinking this value only moves the HUD bar's own position
## closer to the true screen edge (a real, distinct, requested change)
## without touching the HUD-to-board gap. Closing that gap further
## would require shrinking TopBar/BottomBar's aspect-locked height
## (needs different HUD art) or growing board_height (needs more
## columns' worth of available width, or a level redesign) - both
## explicitly out of scope. See DECISIONS.md D87 for the full proof and
## the honest numbers.
const GAMEPLAY_VERTICAL_MARGIN := 8.0

## HUD Edge Spacing (D103): fraction of each gameplay HUD bar's height that is TRANSPARENT padding in the source art,
## measured from bs_hud_top_portrait.png (top padding 153/745) and bs_hud_bottom_portrait.png (bottom padding 149/744).
## game.gd feeds bar_height * fraction to SafeAreaMargin.set_hud_overhang() so the visible plates sit
## GAMEPLAY_VERTICAL_MARGIN (the HUD edge gap) inside the safe area. Re-measure if the HUD art is ever replaced.
## Final HUD position (D104, top matched to bottom in D105): equal visible gaps between the visible HUD plate and the safe edge (canvas px,
## added to any real Android inset). Top hugs the edge; the bottom is lifted off the gesture/nav edge.
const GAMEPLAY_TOP_VISIBLE_GAP := 20.0
const GAMEPLAY_BOTTOM_VISIBLE_GAP := 20.0
## Whole gameplay stack (Top HUD + board + Bottom HUD) vertical offset in canvas px (D106); NEGATIVE = up. Applied by
## SafeAreaMargin as one translation (top margin -shift, bottom margin +shift). On Android an extra shift of half the
## physical top/bottom gap difference is added automatically; the total is clamped so the HUD never goes above the
## safe area + 0 px.
const GAMEPLAY_STACK_VERTICAL_OFFSET := -30.0
## QA TEST ONLY (D107): lifts the safe-edge cap on the stack shift so the -100 offset is really applied. The Top HUD may
## cross the safe area in an internal QA build. External test/production restore the normal clamp.
const ALLOW_LARGE_GAMEPLAY_STACK_QA_OFFSET := BuildConfig.QA_TOOLS
const HUD_TOP_ART_PAD_FRACTION := 0.2054
const HUD_BOTTOM_ART_PAD_FRACTION := 0.2003

## Hint attention pulse (visual only, animates the HintIcon child - never the Button or any layout). One cycle =
## idle wait, glow in, hold, glow out. GLOW_ALPHA is the peak alpha of the additive halo layer; GLOW_SCALE is how much
## larger than the (already enlarged) icon the halo is drawn.
const HINT_ATTENTION_INTERVAL := 5.0
const HINT_GLOW_IN_DURATION := 0.35
const HINT_GLOW_HOLD_DURATION := 0.20
const HINT_GLOW_OUT_DURATION := 0.45
const HINT_ATTENTION_SCALE := 1.04
const HINT_GLOW_ALPHA := 0.55
const HINT_GLOW_SCALE := 1.22
const HINT_GLOW_COLOR := Color("ffd84a")
