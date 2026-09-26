class_name LevelData
extends Resource
## Data-only description of one puzzle level. Individual level files under
## res://levels/ extend this class and populate its fields in _init().
## See ARCHITECTURE.md for why levels are authored as Resource subclasses
## instead of hand-authored .tres files for Milestone 1.

@export var level_id: int = 0
@export var display_name: String = ""
@export var grid_width: int = 5
@export var grid_height: int = 5

## Move count required to earn 3 stars. See DECISIONS.md for the
## star-threshold formula.
@export var optimal_moves: int = 1

@export var tiles: Array[TilePlacement] = []

## Optional development/campaign-planning metadata (Milestone 3). None of
## these affect gameplay, simulation, or save data - purely organizational,
## authored by the level editor. Every existing level file leaves these at
## their defaults and is entirely unaffected.
@export var stage: String = ""
@export var developer_notes: String = ""
## false = development/regression test level (levels 1-15 today);
## true = intended for the future handcrafted 100-level campaign
## (Milestone 4+ - no campaign levels exist yet). See DECISIONS.md
## ("Test-level vs. campaign-level separation").
@export var is_campaign_level: bool = false


func get_tiles_of_type(tile_type: GridTypes.TileType) -> Array[TilePlacement]:
	var result: Array[TilePlacement] = []
	for t in tiles:
		if t.tile_type == tile_type:
			result.append(t)
	return result


## Tile types that carry a rotatable MirrorOrientation - MIRROR/SPLITTER
## (Era 1) plus ONE_WAY_REFLECTOR (Era 2, reuses the identical
## orientation field/toggle - see GridTypes.one_way_reflector_is_reflective()).
## Centralized so get_initial_tile_orientations()/get_rotatable_tiles()
## (and therefore LevelSolver, which is generic over "whatever this
## returns") pick up a new orientation-bearing tile type in one place.
const _ORIENTABLE_TILE_TYPES: Array[GridTypes.TileType] = [
	GridTypes.TileType.MIRROR, GridTypes.TileType.SPLITTER, GridTypes.TileType.ONE_WAY_REFLECTOR,
]


## The live tile_orientations dict LaserSystem/GridManager expect, seeded
## from this level's authored (initial) mirror/splitter/one-way-reflector
## orientations. Centralized here so GridManager, LevelSolver, and
## LevelValidator all build it identically instead of three copies of the
## same loop - see DECISIONS.md ("Level editor architecture").
func get_initial_tile_orientations() -> Dictionary:
	var result := {}
	for t in tiles:
		if t.tile_type in _ORIENTABLE_TILE_TYPES:
			result[t.position] = t.mirror_orientation
		elif t.tile_type == GridTypes.TileType.FUSION or t.tile_type == GridTypes.TileType.SPLITTER_SELECTOR:
			result[t.position] = t.direction # 4-state: the OUTPUT Direction (Fusion Phase 1, D99)
	return result


## Every MIRROR/SPLITTER/ONE_WAY_REFLECTOR tile the player can actually
## rotate. Order is stable (matches `tiles` array order) so solver
## bit-index <-> tile mapping is deterministic and reproducible across
## runs.
func get_rotatable_tiles() -> Array[TilePlacement]:
	var result: Array[TilePlacement] = []
	for t in tiles:
		if t.tile_type in _ORIENTABLE_TILE_TYPES and t.rotatable:
			result.append(t)
	return result
