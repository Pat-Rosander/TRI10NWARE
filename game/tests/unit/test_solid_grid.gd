# Tests SolidGrid: building from tile data, state-dependent platform tops, room-edge walls and
# pits, and the shipped level_tiles.tres. Pending tiles are added with M4.
# Serves AC M-01, M-02, M-03.
extends TestCase

const T: int = SolidGrid.TILE_PX
# A one-screen room at the origin: 40 x 23 tiles.
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
# Atlas coordinates of the test tile set's tiles, one per solidity value.
const ATLAS_DECORATION: Vector2i = Vector2i(0, 0)
const ATLAS_ORDINARY: Vector2i = Vector2i(1, 0)
const ATLAS_DEFAULT: Vector2i = Vector2i(2, 0)
const ATLAS_FLOW: Vector2i = Vector2i(3, 0)


func test_add_layer_reads_solidity() -> void:
	var tiles: TileSet = _make_tile_set()
	var layer: TileMapLayer = _make_layer(tiles)
	layer.set_cell(Vector2i(2, 3), 0, ATLAS_ORDINARY)
	layer.set_cell(Vector2i(4, 3), 0, ATLAS_DEFAULT)
	layer.set_cell(Vector2i(6, 3), 0, ATLAS_FLOW)
	layer.set_cell(Vector2i(8, 3), 0, ATLAS_DECORATION)
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.add_layer(layer)
	assert_eq(grid.cell_flags(Vector2i(2, 3)), SolidGrid.SOLID, "ordinary")
	assert_eq(grid.cell_flags(Vector2i(4, 3)), SolidGrid.DEFAULT_TOP, "default-only")
	assert_eq(grid.cell_flags(Vector2i(6, 3)), SolidGrid.FLOW_TOP, "flow-only")
	assert_eq(grid.cell_flags(Vector2i(8, 3)), 0, "decoration")
	assert_eq(grid.cell_flags(Vector2i(3, 3)), 0, "empty")
	layer.free()


func test_layers_in_one_cell_combine() -> void:
	var tiles: TileSet = _make_tile_set()
	var default_layer: TileMapLayer = _make_layer(tiles)
	var flow_layer: TileMapLayer = _make_layer(tiles)
	default_layer.set_cell(Vector2i(5, 5), 0, ATLAS_DEFAULT)
	flow_layer.set_cell(Vector2i(5, 5), 0, ATLAS_FLOW)
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.add_layer(default_layer)
	grid.add_layer(flow_layer)
	assert_eq(grid.cell_flags(Vector2i(5, 5)), SolidGrid.DEFAULT_TOP | SolidGrid.FLOW_TOP)
	default_layer.free()
	flow_layer.free()


func test_room_offset_maps_local_cells_to_world() -> void:
	for origin: Vector2i in [Vector2i(320, 160), Vector2i(-6400, -3200)]:
		var grid: SolidGrid = SolidGrid.new(Rect2i(origin, ROOM.size))
		grid.set_cell(Vector2i(1, 2), SolidGrid.ORDINARY)
		var world_cell: Vector2i = origin / T + Vector2i(1, 2)
		assert_eq(grid.cell_flags(world_cell), SolidGrid.SOLID, "origin %s" % origin)
		var px: Vector2i = origin + Vector2i(T, 2 * T)
		assert_true(grid.blocks(Rect2i(px, Vector2i(1, 1))), "first pixel, origin %s" % origin)
		assert_false(grid.blocks(Rect2i(px - Vector2i(1, 0), Vector2i(1, 1))),
				"pixel left of it, origin %s" % origin)


func test_cell_of_floors_negative_pixels() -> void:
	assert_eq(SolidGrid.cell_of(Vector2i(0, 15)), Vector2i(0, 0))
	assert_eq(SolidGrid.cell_of(Vector2i(16, 31)), Vector2i(1, 1))
	assert_eq(SolidGrid.cell_of(Vector2i(-1, -16)), Vector2i(-1, -1))
	assert_eq(SolidGrid.cell_of(Vector2i(-17, -15)), Vector2i(-2, -1))


func test_blocks_is_pixel_exact() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(10, 10), SolidGrid.ORDINARY)
	var tile: Rect2i = Rect2i(10 * T, 10 * T, T, T)
	var body: Vector2i = Vector2i(12, 15)
	# Touching each side from outside does not overlap.
	assert_false(grid.blocks(Rect2i(tile.position.x - body.x, tile.position.y, body.x, body.y)),
			"touching the left side")
	assert_false(grid.blocks(Rect2i(tile.end.x, tile.position.y, body.x, body.y)),
			"touching the right side")
	assert_false(grid.blocks(Rect2i(tile.position.x, tile.position.y - body.y, body.x, body.y)),
			"standing on top")
	assert_false(grid.blocks(Rect2i(tile.position.x, tile.end.y, body.x, body.y)),
			"just below")
	# One pixel in, from each side, overlaps.
	assert_true(grid.blocks(Rect2i(tile.position.x - body.x + 1, tile.position.y, body.x, body.y)),
			"1 px into the left side")
	assert_true(grid.blocks(Rect2i(tile.end.x - 1, tile.position.y, body.x, body.y)),
			"1 px into the right side")
	assert_true(grid.blocks(Rect2i(tile.position.x, tile.position.y - body.y + 1, body.x, body.y)),
			"1 px into the top")
	assert_true(grid.blocks(Rect2i(tile.position.x, tile.end.y - 1, body.x, body.y)),
			"1 px into the bottom")
	assert_false(grid.blocks(Rect2i(tile.position, Vector2i.ZERO)), "an empty rect")


func test_decoration_and_platforms_never_block() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(3, 3), SolidGrid.DECORATION)
	grid.set_cell(Vector2i(4, 3), SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(5, 3), SolidGrid.FLOW_ONLY)
	var row: Rect2i = Rect2i(3 * T, 3 * T, 3 * T, T)
	assert_false(grid.blocks(row), "in default")
	grid.set_flow(true)
	assert_false(grid.blocks(row), "in flow")


func test_platform_tops_follow_state() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(4, 10), SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(8, 10), SolidGrid.FLOW_ONLY)
	var on_default: Rect2i = Rect2i(4 * T + 2, 10 * T - 15, 12, 15)
	var on_flow: Rect2i = Rect2i(8 * T + 2, 10 * T - 15, 12, 15)
	assert_true(grid.platform_top_at(on_default), "default-only top, in default")
	assert_false(grid.platform_top_at(on_flow), "flow-only top, in default")
	grid.set_flow(true)
	assert_false(grid.platform_top_at(on_default), "default-only top, in flow")
	assert_true(grid.platform_top_at(on_flow), "flow-only top, in flow")
	grid.set_flow(false)
	assert_true(grid.platform_top_at(on_default), "default-only top, back in default")


func test_platform_top_needs_exact_alignment() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(4, 10), SolidGrid.DEFAULT_ONLY)
	var body: Rect2i = Rect2i(4 * T + 2, 10 * T - 15, 12, 15)
	assert_true(grid.platform_top_at(body), "feet on the top edge")
	assert_false(grid.platform_top_at(body.grow_individual(0, 1, 0, -1)), "1 px above")
	assert_false(grid.platform_top_at(body.grow_individual(0, -1, 0, 1)), "1 px inside")
	# Overlapping the platform's column by a single pixel is enough.
	assert_true(grid.platform_top_at(Rect2i(4 * T - 11, body.position.y, 12, 15)),
			"1 px over its left edge")
	assert_false(grid.platform_top_at(Rect2i(4 * T - 12, body.position.y, 12, 15)),
			"touching its left edge")
	assert_false(grid.platform_top_at(Rect2i(body.position, Vector2i.ZERO)), "an empty rect")


func test_solid_cells_are_not_platform_tops() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(4, 10), SolidGrid.ORDINARY)
	assert_false(grid.platform_top_at(Rect2i(4 * T, 10 * T - 15, 12, 15)))


func test_edges_are_walls_and_the_bottom_is_a_pit() -> void:
	var room: Rect2i = Rect2i(320, 160, 640, 368)
	var grid: SolidGrid = SolidGrid.new(room)
	var body: Vector2i = Vector2i(12, 15)
	var mid_y: int = room.position.y + 100
	var mid_x: int = room.position.x + 100
	assert_true(grid.blocks(Rect2i(room.position.x - 1, mid_y, body.x, body.y)),
			"1 px past the left edge")
	assert_false(grid.blocks(Rect2i(room.position.x, mid_y, body.x, body.y)),
			"touching the left edge")
	assert_true(grid.blocks(Rect2i(room.end.x - body.x + 1, mid_y, body.x, body.y)),
			"1 px past the right edge")
	assert_false(grid.blocks(Rect2i(room.end.x - body.x, mid_y, body.x, body.y)),
			"touching the right edge")
	assert_true(grid.blocks(Rect2i(mid_x, room.position.y - 1, body.x, body.y)),
			"1 px past the top edge")
	assert_false(grid.blocks(Rect2i(mid_x, room.end.y - 5, body.x, body.y)),
			"crossing the bottom edge")
	assert_false(grid.blocks(Rect2i(mid_x, room.end.y + 200, body.x, body.y)),
			"far below the bottom edge")


func test_corner_cells() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	@warning_ignore("integer_division")
	var cells: Rect2i = Rect2i(0, 0, ROOM.size.x / T, ROOM.size.y / T)
	assert_eq(grid.cell_flags(Vector2i(-1, -1)), SolidGrid.SOLID, "above-left")
	assert_eq(grid.cell_flags(Vector2i(cells.end.x, -1)), SolidGrid.SOLID, "above-right")
	assert_eq(grid.cell_flags(Vector2i(-1, cells.end.y - 1)), SolidGrid.SOLID,
			"left of the bottom row")
	assert_eq(grid.cell_flags(Vector2i(-1, cells.end.y)), 0, "below-left")
	assert_eq(grid.cell_flags(Vector2i(cells.end.x, cells.end.y)), 0, "below-right")
	assert_eq(grid.cell_flags(Vector2i(5, cells.end.y)), 0, "below")


func test_cells_painted_outside_the_room_are_ignored() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	@warning_ignore("integer_division")
	var below: Vector2i = Vector2i(5, ROOM.size.y / T + 1)
	grid.set_cell(below, SolidGrid.ORDINARY)
	assert_eq(grid.cell_flags(below), 0, "the pit stays open")


func test_unknown_solidity_is_an_error() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(1, 1), 7)
	assert_eq(take_errors().size(), 1, "one error")
	assert_eq(grid.cell_flags(Vector2i(1, 1)), 0, "ignored")


func test_level_tiles_resource() -> void:
	var tiles: TileSet = load("res://tiles/level_tiles.tres")
	assert_eq(tiles.tile_size, Vector2i(T, T), "tile size")
	assert_eq(tiles.get_physics_layers_count(), 0, "no physics layers")
	assert_eq(tiles.get_custom_data_layers_count(), 1, "one custom data layer")
	assert_eq(tiles.get_custom_data_layer_by_name("solidity"), 0, "named solidity")
	assert_eq(tiles.get_custom_data_layer_type(0), TYPE_INT, "an integer")
	var source: TileSetAtlasSource = tiles.get_source(0)
	# The owner's level_1_tiles_v2.png atlas (2026-10-20): rows 0-2 are stone blocks, except two
	# decoration pieces; rows 3-4 are telephone poles and wires, all decoration (L1-01).
	var decoration_blocks: Array[Vector2i] = [Vector2i(2, 1), Vector2i(5, 2)]
	var solid: int = 0
	for i: int in source.get_tiles_count():
		var id: Vector2i = source.get_tile_id(i)
		var value: int = source.get_tile_data(id, 0).get_custom_data("solidity")
		var expected: int = SolidGrid.ORDINARY
		if id.y >= 3 or id in decoration_blocks:
			expected = SolidGrid.DECORATION
		assert_eq(value, expected, "tile %s" % id)
		if value == SolidGrid.ORDINARY:
			solid += 1
	assert_eq(solid, 16, "the 16 block tiles are solid")


# A four-tile atlas with one tile per solidity value, on a blank texture.
func _make_tile_set() -> TileSet:
	var tiles: TileSet = TileSet.new()
	tiles.tile_size = Vector2i(T, T)
	tiles.add_custom_data_layer()
	tiles.set_custom_data_layer_name(0, "solidity")
	tiles.set_custom_data_layer_type(0, TYPE_INT)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(
			Image.create_empty(4 * T, T, false, Image.FORMAT_RGBA8))
	source.texture_region_size = Vector2i(T, T)
	tiles.add_source(source, 0)
	var values: Dictionary[Vector2i, int] = {
		ATLAS_DECORATION: SolidGrid.DECORATION,
		ATLAS_ORDINARY: SolidGrid.ORDINARY,
		ATLAS_DEFAULT: SolidGrid.DEFAULT_ONLY,
		ATLAS_FLOW: SolidGrid.FLOW_ONLY,
	}
	for atlas: Vector2i in values:
		source.create_tile(atlas)
		source.get_tile_data(atlas, 0).set_custom_data("solidity", values[atlas])
	return tiles


func _make_layer(tiles: TileSet) -> TileMapLayer:
	var layer: TileMapLayer = TileMapLayer.new()
	layer.tile_set = tiles
	return layer
