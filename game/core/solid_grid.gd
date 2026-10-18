# The mover's view of one room: which 16 px cells are solid, one-way platform tops or open,
# read once from the room's tile layers, plus the room-edge walls and pit. No physics engine.
# Serves AC M-01, M-02, M-03 (collision) and, from M4, P-01 to P-04.
class_name SolidGrid
extends RefCounted

## Tile size in pixels (a starting decision, not tuning).
const TILE_PX: int = 16

## The tile set's `solidity` custom data values.
const DECORATION: int = 0
const ORDINARY: int = 1
const DEFAULT_ONLY: int = 2
const FLOW_ONLY: int = 3

## Cell flags. A cell painted on several layers keeps every flag it was given.
const SOLID: int = 1
const DEFAULT_TOP: int = 2
const FLOW_TOP: int = 4

## The room's place on the world map in pixels (its `world_rect`).
var bounds: Rect2i

var _cell_bounds: Rect2i
var _cells: Dictionary[Vector2i, int] = {}
var _active_top: int = DEFAULT_TOP


## [param room_bounds] is the room's `world_rect`; position and size are whole tiles.
func _init(room_bounds: Rect2i) -> void:
	bounds = room_bounds
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
		_:
			push_error("SolidGrid: unknown solidity %d at %s" % [solidity, cell])
			return
	var world_cell: Vector2i = cell + _cell_bounds.position
	if _cell_bounds.has_point(world_cell):
		_cells[world_cell] = _cells.get(world_cell, 0) | flag


## Chooses which platform family is solid for the player: flow-only tops when [param on],
## default-only tops otherwise.
func set_flow(on: bool) -> void:
	_active_top = FLOW_TOP if on else DEFAULT_TOP


## The flags of the world [param cell]. Outside the room, cells at or below the bottom edge
## are open (a pit) and every other cell is [constant SOLID] (a wall or ceiling).
func cell_flags(cell: Vector2i) -> int:
	if _cell_bounds.has_point(cell):
		return _cells.get(cell, 0)
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


## The world cell containing the world pixel [param px].
static func cell_of(px: Vector2i) -> Vector2i:
	return Vector2i(_floor_div(px.x), _floor_div(px.y))


# Floor division by the tile size. Integer `/` truncates toward zero, which is wrong for
# negative coordinates.
static func _floor_div(value: int) -> int:
	return (value - posmod(value, TILE_PX)) / TILE_PX
