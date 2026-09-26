class_name EraTheme
extends Resource
## Centralized visual identity for one "Era" (a 100-level campaign block +
## its 10-tutorial pack, see ROADMAP.md). Not an autoload (CLAUDE.md rule
## 6 - a lookup table has no persistent/global state to own); callers
## call the static helpers below to find out which era a given level/
## tutorial belongs to and to fetch that era's themed assets, instead of
## branching on level/tutorial ids themselves. See ERA_2_DESIGN.md "Era
## architecture" for the full writeup.
##
## Era 1 fields are deliberately left null - every Era 1 caller already
## has its own existing hardcoded asset (game.tscn's ext_resources,
## TileVisual.DEFAULT_CELL_BACKGROUND_TEXTURE, etc.) and must keep using
## it unconditionally, so Era 1 content is never visually touched by this
## system. Only Era 2+ themes carry real texture references.

@export var era_number: int = 1
@export var era_name: String = "Era 1"

@export var gameplay_background: Texture2D
@export var grid_cell_empty: Texture2D
@export var grid_cell_selected: Texture2D
@export var hud_top: Texture2D
@export var hud_bottom: Texture2D
@export var hud_aspect_ratio: float = 0.0 ## 0.0 = keep Era 1's existing per-bar ratio
@export var level_select_background: Texture2D
@export var tutorial_select_background: Texture2D
@export var accent_color: Color = Color.WHITE

## Level Complete / Tutorial Complete popup panel art (QA/Hardening pass -
## see CLAUDE.md rule 11's per-screen-art exception, extended here to be
## era-aware at runtime exactly like hud_top/hud_bottom already are).
## null = keep the popup's own .tscn-authored default style (Era 1).
## Margins are [left, top, right, bottom] in source-texture pixels,
## pixel-measured against each specific file - see DECISIONS.md.
@export var level_complete_panel: Texture2D
@export var level_complete_panel_margins: PackedFloat32Array
@export var tutorial_complete_panel: Texture2D
@export var tutorial_complete_panel_margins: PackedFloat32Array

const LEVELS_PER_ERA := 100
const TUTORIALS_PER_ERA := 10


## 1-100 -> Era 1, 101-200 -> Era 2, 201-300 -> Era 3, etc. Takes a
## campaign-wide level number (not a per-era one) - today that's simply
## CAMPAIGN_LEVEL_PATHS' 1-based index, since Era 1 is Levels 1-100.
static func get_era_for_level(campaign_level_number: int) -> int:
	return ((maxi(campaign_level_number, 1) - 1) / LEVELS_PER_ERA) + 1


## T01-T10 -> Era 1, T11-T20 -> Era 2, T21-T30 -> Era 3, etc.
static func get_era_for_tutorial(tutorial_level_number: int) -> int:
	return ((maxi(tutorial_level_number, 1) - 1) / TUTORIALS_PER_ERA) + 1


## Unified Blue Theme Fix (see CLAUDE.md rule 17, DECISIONS.md D91): the
## single authoritative switch for whether Era 2+'s own built visual
## theme (background/grid/HUD/accent/popup panel art) is actually
## active anywhere in the game. false = every gameplay screen -
## Campaign, procedural, tutorials, every level/tutorial number - always
## renders with Era 1's existing blue/cyan look, regardless of which
## numeric era get_era_for_level()/get_era_for_tutorial() reports for
## it. This is deliberately the ONLY place that decision is made -
## don't add a second "if level >= 100" check anywhere else; every
## caller already goes through for_era(), so flipping this one constant
## is the complete fix or the complete revert.
##
## Era-BAND logic (unlock gating, the Level 100->101 transition banner)
## is entirely numeric and reads get_era_for_level()/get_era_for_tutorial()
## directly, never anything from this function's returned object - see
## LevelManager.is_tutorial_level_selectable() and game.gd's
## era_transition check - so turning this off changes ZERO progression/
## unlock/mechanic behavior, only which asset set painting the screen.
const UNIFIED_BLUE_THEME_ONLY := true


## Returns the themed asset set for the given era number. Falls back to
## Era 1 (all-null - "use your own existing Era 1 asset") for any era
## that doesn't have a theme built yet, so calling this for a future,
## not-yet-designed Era never crashes or shows the wrong theme's assets.
static func for_era(era_number: int) -> EraTheme:
	if UNIFIED_BLUE_THEME_ONLY:
		return _build_era_1()
	match era_number:
		2:
			return _build_era_2()
	return _build_era_1()


static func _build_era_1() -> EraTheme:
	var t := EraTheme.new()
	t.era_number = 1
	t.era_name = "Era 1"
	return t


static func _build_era_2() -> EraTheme:
	var t := EraTheme.new()
	t.era_number = 2
	t.era_name = "Era 2 — Refractions"
	t.gameplay_background = load("res://assets/gameplay/backgrounds/era2/bs_bg_gameplay_era2.png")
	t.grid_cell_empty = load("res://assets/gameplay/grid/era2/bs_tile_grid_empty_era2.png")
	t.grid_cell_selected = load("res://assets/gameplay/grid/era2/bs_tile_grid_selected_era2.png")
	t.hud_top = load("res://assets/ui/era2/bs_hud_top_era2.png")
	t.hud_bottom = load("res://assets/ui/era2/bs_hud_bottom_era2.png")
	t.hud_aspect_ratio = 3.0 # bs_hud_{top,bottom}_era2.png are both 2172x724
	t.level_select_background = load("res://assets/ui/backgrounds/bs_bg_level_select_era2_portrait.png")
	t.tutorial_select_background = load("res://assets/ui/backgrounds/bs_bg_tutorial_select_era2_portrait.png")
	t.accent_color = Color(0.55, 0.3, 0.95) # dark violet/magenta - see ERA_2_DESIGN.md
	t.level_complete_panel = load("res://assets/ui/era2/bs_panel_level_complete_clean_era2.png")
	t.level_complete_panel_margins = PackedFloat32Array([189, 441, 190, 283])
	t.tutorial_complete_panel = load("res://assets/ui/era2/bs_panel_tutorial_complete_era2.png")
	t.tutorial_complete_panel_margins = PackedFloat32Array([184, 397, 185, 332])
	return t
