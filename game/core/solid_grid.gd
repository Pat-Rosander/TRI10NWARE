# The mover's view of one room: which 16 px cells are solid, one-way platform tops, spikes or
# open, read once from the room's tile layers, plus the room-edge walls, pit and (from M6) openings
# into neighboring rooms. No physics engine.
# Serves AC M-01, M-02, M-03 (collision), R-01 (spike deaths), from M4 P-01 to P-04, from M6 G-01.
class_name SolidGrid
extends RefCounted

## Tile size in pixels (a starting decision, not tuning).
const TILE_PX: int = 16

## The tile set's `solidity` custom data values.
const DECORATION: int = 0
const ORDINARY: int = 1
const DEFAULT_ONLY: int = 2
const FLOW_ONLY: int = 3
const SPIKE_UP: int = 4
const SPIKE_DOWN: int = 5
const SPIKE_LEFT: int = 6
const SPIKE_RIGHT: int = 7

## Cell flags. A cell painted on several layers keeps every flag it was given.
const SOLID: int = 1
const DEFAULT_TOP: int = 2
const FLOW_TOP: int = 4
## Spike cells, one flag per direction the spikes point. Never solid: spikes do not block.
const SPIKE_UP_CELL: int = 8
const SPIKE_DOWN_CELL: int = 16
const SPIKE_LEFT_CELL: int = 32
const SPIKE_RIGHT_CELL: int = 64
const SPIKE_CELLS: int = SPIKE_UP_CELL | SPIKE_DOWN_CELL | SPIKE_LEFT_CELL | SPIKE_RIGHT_CELL

## The room's place on the world map in pixels (its `world_rect`).
var bounds: Rect2i

var _cell_bounds: Rect2i
var _cells: Dictionary[Vector2i, int] = {}
# Neighboring rooms' places in cells: open to the mover until a crossing begins.
var _openings: Array[Rect2i] = []
# Rooms joined during a crossing, in cells: their cells are read from _cells like this room's.
var _joined: Array[Rect2i] = []
var _active_top: int = DEFAULT_TOP
var _spike_depth: int
var _spike_inset: int


## [param room_bounds] is the room's `world_rect`; position and size are whole tiles.
## [param spike_depth_px] and [param spike_inset_px] come from tuning and shape every spike's
## hitbox.
func _init(room_bounds: Rect2i, spike_depth_px: int, spike_inset_px: int) -> void:
	bounds = room_bounds
	_spike_depth = spike_depth_px
	_spike_inset = spike_inset_px
	_cell_bounds = Rect2i(cell_of(bounds.position), bounds.size / TILE_PX)


## Reads every used cell of [param layer] (a room tile layer using `level_tiles.tres`) once.
## Only the layer itself is read; it need not be in the scene tree.
func add_layer(layer: TileMapLayer) -> void:
	for cell: Vector2i in layer.get_used_cells():
		var data: TileData = layer.get_cell_tile_data(cell)
		if data != null:
			set_cell(cell, data.get_custom_data("solidity"))


## Adds [param solidity] (a tile set `solidity` value) to the room-local [param cell].
## Cells outside the room are ignored: the edge rules decide those.
func set_cell(cell: Vector2i, solidity: int) -> void:
	var flag: int
	match solidity:
		DECORATION:
			return
		ORDINARY:
			flag = SOLID
		DEFAULT_ONLY:
			flag = DEFAULT_TOP
		FLOW_ONLY:
			flag = FLOW_TOP
		SPIKE_UP:
			flag = SPIKE_UP_CELL
		SPIKE_DOWN:
			flag = SPIKE_DOWN_CELL
		SPIKE_LEFT:
			flag = SPIKE_LEFT_CELL
		SPIKE_RIGHT:
			flag = SPIKE_RIGHT_CELL
		_:
			push_error("SolidGrid: unknown solidity %d at %s" % [solidity, cell])
			return
	var world_cell: Vector2i = cell + _cell_bounds.position
	if _cell_bounds.has_point(world_cell):
		_cells[world_cell] = _cells.get(world_cell, 0) | flag


## Opens the cells beyond this room's edge that lie inside [param neighbor_rect], a neighboring
## room's `world_rect` in pixels: until a crossing begins they are open to the mover.
func add_opening(neighbor_rect: Rect2i) -> void:
	_openings.append(Rect2i(cell_of(neighbor_rect.position), neighbor_rect.size / TILE_PX))


## Adds [param other]'s cells and room to this grid, so it holds both rooms during a crossing.
## [param other] is unchanged.
func join(other: SolidGrid) -> void:
	_joined.append(other._cell_bounds)
	for cell: Vector2i in other._cells:
		_cells[cell] = _cells.get(cell, 0) | other._cells[cell]


## Chooses which platform family is solid for the player: flow-only tops when [param on],
## default-only tops otherwise.
func set_flow(on: bool) -> void:
	_active_top = FLOW_TOP if on else DEFAULT_TOP


## The flags of the world [param cell]. Outside the room, a joined room's cells are read as
## painted; cells inside an opening or at or below the bottom edge are open (a neighbor or a pit);
## every other cell is [constant SOLID] (a wall or ceiling).
func cell_flags(cell: Vector2i) -> int:
	if _cell_bounds.has_point(cell):
		return _cells.get(cell, 0)
	for joined: Rect2i in _joined:
		if joined.has_point(cell):
			return _cells.get(cell, 0)
	for opening: Rect2i in _openings:
		if opening.has_point(cell):
			return 0
	if cell.y >= _cell_bounds.end.y:
		return 0
	return SOLID


## True if the world-pixel [param rect] overlaps a cell that blocks from every side. Platform
## tops never count, so this is the test for sideways moves, upward moves and walls.
func blocks(rect: Rect2i) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return false
	var first: Vector2i = cell_of(rect.position)
	var last: Vector2i = cell_of(rect.end - Vector2i.ONE)
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			if cell_flags(Vector2i(x, y)) & SOLID:
				return true
	return false


## True if the bottom of the world-pixel [param rect] sits exactly on the top edge of a
## platform tile that is solid for the player now. The test for moving down onto a one-way top.
func platform_top_at(rect: Rect2i) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0 or posmod(rect.end.y, TILE_PX) != 0:
		return false
	var row: int = _floor_div(rect.end.y)
	for x: int in range(_floor_div(rect.position.x), _floor_div(rect.end.x - 1) + 1):
		if cell_flags(Vector2i(x, row)) & _active_top:
			return true
	return false


## True if the world-pixel [param rect] overlaps the hitbox of a spike: a strip spike_depth_px
## deep along the side the spikes stand on, stopping spike_inset_px short of each end. Touching a
## hitbox's edge is not overlapping it, and the rest of a spike cell is harmless.
func touches_spike(rect: Rect2i) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return false
	var first: Vector2i = cell_of(rect.position)
	var last: Vector2i = cell_of(rect.end - Vector2i.ONE)
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			var flags: int = cell_flags(cell) & SPIKE_CELLS
			if flags == 0:
				continue
			for spike: int in [SPIKE_UP_CELL, SPIKE_DOWN_CELL, SPIKE_LEFT_CELL, SPIKE_RIGHT_CELL]:
				if (flags & spike) != 0 and rect.intersects(spike_hitbox(cell, spike)):
					return true
	return false


## The hitbox, in world pixels, of a spike pointing as [param spike] (one of the spike cell flags)
## in the world [param cell].
func spike_hitbox(cell: Vector2i, spike: int) -> Rect2i:
	var origin: Vector2i = cell * TILE_PX
	var length: int = TILE_PX - 2 * _spike_inset
	match spike:
		SPIKE_UP_CELL:
			return Rect2i(origin.x + _spike_inset, origin.y + TILE_PX - _spike_depth,
					length, _spike_depth)
		SPIKE_DOWN_CELL:
			return Rect2i(origin.x + _spike_inset, origin.y, length, _spike_depth)
		SPIKE_LEFT_CELL:
			return Rect2i(origin.x + TILE_PX - _spike_depth, origin.y + _spike_inset,
					_spike_depth, length)
		_:
			return Rect2i(origin.x, origin.y + _spike_inset, _spike_depth, length)


## The world cell containing the world pixel [param px].
static func cell_of(px: Vector2i) -> Vector2i:
	return Vector2i(_floor_div(px.x), _floor_div(px.y))


# Floor division by the tile size. Integer `/` truncates toward zero, which is wrong for
# negative coordinates.
static func _floor_div(value: int) -> int:
	@warning_ignore("integer_division")
	return (value - posmod(value, TILE_PX)) / TILE_PX
