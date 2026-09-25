class_name TilePlacement
extends Resource
## Data-only description of a single tile within a LevelData grid.
## Carries no gameplay logic - only what is needed to place and
## initialize a tile in the grid.
##
## One flat field set is shared by all tile types rather than a Resource
## subclass per tile type - see DECISIONS.md ("Tile data model") for why.
## Fields irrelevant to a given tile_type are simply left at their default.
## Prefer the static make_*() factories below over setting fields by hand -
## they document which fields matter for each tile type.

@export var tile_type: GridTypes.TileType = GridTypes.TileType.EMPTY
@export var position: Vector2i = Vector2i.ZERO

## EMITTER: fire direction.
@export var direction: GridTypes.Direction = GridTypes.Direction.UP

## MIRROR and SPLITTER: current/initial orientation.
@export var mirror_orientation: GridTypes.MirrorOrientation = GridTypes.MirrorOrientation.SLASH

## MIRROR and SPLITTER: whether the player can rotate this tile.
@export var rotatable: bool = true

## EMITTER: the color of beam it fires. FILTER: the color it forces
## outgoing beams to become. TARGET: the required beam color (WHITE =
## accepts any color - see GridTypes.target_accepts_color()).
@export var color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE

## TARGET: whether this target must be activated for the level to be
## solved. Defaults to true so existing Milestone 1 target data (which
## never set this) is unaffected.
@export var required: bool = true

## PORTAL: pairing key. Exactly two PORTAL tiles must share a pair_id for
## the pair to function - see LaserSystem for the fail-safe behavior when
## that invariant doesn't hold.
@export var pair_id: String = ""

## SWITCH: the gate_id of the GATE(s) this switch opens when hit.
## GATE: this gate's own identity, matched against switches' gate_id.
@export var gate_id: String = ""

## GATE: whether this gate starts open before any switch has been
## considered. Gates are otherwise stateless/derived - see DECISIONS.md
## ("Switch/gate simulation strategy").
@export var initial_open_state: bool = false

## BEAM_RECEIVER: the link identity this receiver powers when hit.
## REMOTE_EMITTER: the link identity that must be powered for this
## emitter to fire. A separate field from gate_id/SWITCH-GATE linking on
## purpose - receivers/remote emitters are a distinct dependency graph,
## see ERA_2_DESIGN.md "Beam Receiver / Remote Emitter". Many-to-many is
## supported: several receivers may share one link_id, and several
## remote emitters may share one link_id.
@export var link_id: String = ""


static func make_emitter(pos: Vector2i, dir: GridTypes.Direction, beam_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.EMITTER
	t.position = pos
	t.direction = dir
	t.color = beam_color
	return t


static func make_mirror(pos: Vector2i, orientation: GridTypes.MirrorOrientation, is_rotatable: bool = true) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.MIRROR
	t.position = pos
	t.mirror_orientation = orientation
	t.rotatable = is_rotatable
	return t


static func make_splitter(pos: Vector2i, orientation: GridTypes.MirrorOrientation, is_rotatable: bool = true) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.SPLITTER
	t.position = pos
	t.mirror_orientation = orientation
	t.rotatable = is_rotatable
	return t


static func make_target(pos: Vector2i, required_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE, is_required: bool = true) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.TARGET
	t.position = pos
	t.color = required_color
	t.required = is_required
	return t


static func make_blocker(pos: Vector2i) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.BLOCKER
	t.position = pos
	return t


static func make_filter(pos: Vector2i, output_color: GridTypes.BeamColor) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.FILTER
	t.position = pos
	t.color = output_color
	return t


static func make_portal(pos: Vector2i, portal_pair_id: String) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.PORTAL
	t.position = pos
	t.pair_id = portal_pair_id
	return t


static func make_switch(pos: Vector2i, linked_gate_id: String) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.SWITCH
	t.position = pos
	t.gate_id = linked_gate_id
	return t


static func make_gate(pos: Vector2i, own_gate_id: String, starts_open: bool = false) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.GATE
	t.position = pos
	t.gate_id = own_gate_id
	t.initial_open_state = starts_open
	return t


static func make_hazard(pos: Vector2i) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.HAZARD
	t.position = pos
	return t


## PRISM: never rotatable, never stores orientation - see
## GridTypes.prism_output_direction().
static func make_prism(pos: Vector2i) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.PRISM
	t.position = pos
	return t


## ONE_WAY_REFLECTOR: rotatable exactly like a mirror (same
## mirror_orientation field/toggle) - see
## GridTypes.one_way_reflector_is_reflective().
static func make_one_way_reflector(pos: Vector2i, orientation: GridTypes.MirrorOrientation, is_rotatable: bool = true) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.ONE_WAY_REFLECTOR
	t.position = pos
	t.mirror_orientation = orientation
	t.rotatable = is_rotatable
	return t


static func make_beam_receiver(pos: Vector2i, receiver_link_id: String) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.BEAM_RECEIVER
	t.position = pos
	t.link_id = receiver_link_id
	return t


static func make_remote_emitter(pos: Vector2i, dir: GridTypes.Direction, emitter_link_id: String, beam_color: GridTypes.BeamColor = GridTypes.BeamColor.WHITE) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.REMOTE_EMITTER
	t.position = pos
	t.direction = dir
	t.color = beam_color
	t.link_id = emitter_link_id
	return t


## FUSION (Fusion Phase 1, D99): `direction` is the OUTPUT side (initial; the live value is
## the 4-state orientation in tile_orientations, one Direction per rotation), `rotatable`
## lets the player turn it clockwise one step per tap. No runtime input state lives here.
static func make_fusion(pos: Vector2i, output_dir: GridTypes.Direction, is_rotatable: bool = true) -> TilePlacement:
	var t := TilePlacement.new()
	t.tile_type = GridTypes.TileType.FUSION
	t.position = pos
	t.direction = output_dir
	t.rotatable = is_rotatable
	return t
