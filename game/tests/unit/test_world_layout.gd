# Checks the world map in room_catalog.tres: unique IDs, scene IDs matching their records, whole-
# tile rects of at least 640 x 368, no overlaps, the start room and entrance, an entrance within
# 48 px of every shared edge on both sides, and every entrance's body inside its room. Every game
# room (not under verification/) has a complete, affordable RoomInfo, and every doorway matches
# both ways: a cell open on one side of a shared edge is not solid on the other. Small layouts and
# records built in code prove each check catches its mistake. Serves AC G-01, G-03, R-01.
extends TestCase

const CATALOG_PATH: String = "res://rooms/room_catalog.tres"
const WorldScript: GDScript = preload("res://world/world.gd")
const TILE_PX: int = 16
const MIN_SIZE: Vector2i = Vector2i(640, 368)
const BODY: Vector2i = Vector2i(12, 15)
const VERIFICATION_DIR: String = "res://verification/"
const MAX_VOLTS: int = 3


func test_catalog_has_no_layout_problems() -> void:
	var catalog: RoomCatalog = load(CATALOG_PATH) as RoomCatalog
	var scene_ids: Dictionary = {}
	var entrances: Dictionary = {}
	for entry: RoomEntry in catalog.rooms:
		if entry == null or entry.scene == null:
			continue
		var room: Room = entry.scene.instantiate() as Room
		scene_ids[entry.room_id] = room.room_id
		entrances[entry.room_id] = _entrance_feet(room)
		room.free()
	var problems: Array[String] = layout_problems(catalog.rooms, catalog.start_room,
			catalog.start_entrance, scene_ids, entrances, Tuning.data.body_size_px)
	assert_eq(problems, [] as Array[String], "\n  " + "\n  ".join(problems))


func test_catalog_doorways_match() -> void:
	var catalog: RoomCatalog = load(CATALOG_PATH) as RoomCatalog
	var grids: Dictionary = {}
	for entry: RoomEntry in catalog.rooms:
		if entry == null or entry.scene == null \
				or entry.scene.resource_path.begins_with(VERIFICATION_DIR):
			continue
		var room: Room = entry.scene.instantiate() as Room
		var grid: SolidGrid = SolidGrid.new(entry.world_rect, Tuning.data.spike_depth_px,
				Tuning.data.spike_inset_px)
		for layer_name: String in ["WorldTiles", "DefaultTiles", "FlowTiles"]:
			grid.add_layer(room.get_node(layer_name) as TileMapLayer)
		grids[entry.room_id] = grid
		room.free()
	var problems: Array[String] = doorway_problems(catalog.rooms, grids)
	assert_eq(problems, [] as Array[String], "\n  " + "\n  ".join(problems))


func test_matching_doorways_have_no_problems() -> void:
	var layout: Dictionary = _pair()
	var grids: Dictionary = _doorway_grids(layout.rooms)
	grids[&"a"].set_cell(Vector2i(39, 15), SolidGrid.ORDINARY)
	grids[&"b"].set_cell(Vector2i(0, 15), SolidGrid.ORDINARY)
	assert_eq(doorway_problems(layout.rooms, grids), [] as Array[String])


func test_a_cell_solid_on_one_side_and_open_on_the_other_is_caught() -> void:
	var layout: Dictionary = _pair()
	var grids: Dictionary = _doorway_grids(layout.rooms)
	grids[&"a"].set_cell(Vector2i(39, 16), SolidGrid.ORDINARY)
	assert_eq(doorway_problems(layout.rooms, grids),
			["'a' cell (39, 16) is solid but 'b' cell (0, 16) is open"] as Array[String])
	# Platform tops and decoration are not solid, so they match an open cell.
	grids = _doorway_grids(layout.rooms)
	grids[&"a"].set_cell(Vector2i(39, 16), SolidGrid.DECORATION)
	grids[&"b"].set_cell(Vector2i(0, 16), SolidGrid.DEFAULT_ONLY)
	assert_eq(doorway_problems(layout.rooms, grids), [] as Array[String])


func test_stacked_doorways_compare_the_bottom_and_top_rows() -> void:
	var layout: Dictionary = _pair()
	layout.rooms[1].world_rect = Rect2i(0, 368, 640, 368)
	var grids: Dictionary = _doorway_grids(layout.rooms)
	grids[&"b"].set_cell(Vector2i(5, 0), SolidGrid.ORDINARY)
	assert_eq(doorway_problems(layout.rooms, grids),
			["'a' cell (5, 22) is open but 'b' cell (5, 0) is solid"] as Array[String])


func test_reach_matches_world() -> void:
	assert_eq(WorldScript.CHECKPOINT_REACH_PX, 48, "World's checkpoint reach is 3 tiles")


func test_a_good_layout_has_no_problems() -> void:
	assert_eq(_problems_of(_pair()), [] as Array[String])


func test_duplicate_ids() -> void:
	var layout: Dictionary = _pair()
	layout.rooms[1].room_id = &"a"
	_expect(layout, "duplicate room ID 'a'")


func test_scene_id_must_match_its_record() -> void:
	var layout: Dictionary = _pair()
	layout.scene_ids[&"b"] = &"c"
	_expect(layout, "'b': its scene's room_id is 'c'")


func test_rect_must_be_whole_tiles() -> void:
	var layout: Dictionary = _pair()
	layout.rooms[1].world_rect = Rect2i(640, 8, 640, 368)
	_expect(layout, "'b': world_rect (640, 8, 640, 368) is not whole tiles")


func test_rect_must_cover_a_screen() -> void:
	var layout: Dictionary = _pair()
	layout.rooms[1].world_rect = Rect2i(640, 0, 640, 352)
	_expect(layout, "'b': size (640, 352) is smaller than 640 x 368")


func test_rooms_must_not_overlap() -> void:
	var layout: Dictionary = _pair()
	layout.rooms[1].world_rect = Rect2i(624, 0, 640, 368)
	_expect(layout, "'a' and 'b' overlap")


func test_start_room_must_exist() -> void:
	var layout: Dictionary = _pair()
	layout.start_room = &"z"
	_expect(layout, "start room 'z' is not in the catalog")


func test_start_entrance_must_exist() -> void:
	var layout: Dictionary = _pair()
	layout.start_entrance = &"nowhere"
	_expect(layout, "start room 'a' has no entrance 'nowhere'")


func test_shared_edge_needs_an_entrance_on_each_side() -> void:
	var layout: Dictionary = _pair()
	# b's west entrance moves to 49 px from the shared edge: one pixel out of reach.
	layout.entrances[&"b"] = {&"west": Vector2i(49, 256)}
	_expect(layout, "'b': no entrance within 48 px of its left edge (shared with 'a')")


func test_an_entrance_at_exactly_48_px_is_in_reach() -> void:
	var layout: Dictionary = _pair()
	layout.entrances[&"b"] = {&"west": Vector2i(48, 256)}
	assert_eq(_problems_of(layout), [] as Array[String])


func test_stacked_rooms_check_top_and_bottom_edges() -> void:
	var layout: Dictionary = _pair()
	layout.rooms[1].world_rect = Rect2i(0, 368, 640, 368)
	layout.entrances[&"b"] = {&"west": Vector2i(48, 200)}
	_expect(layout, "'a': no entrance within 48 px of its bottom edge (shared with 'b')")
	_expect(layout, "'b': no entrance within 48 px of its top edge (shared with 'a')")


func test_entrance_body_must_stay_inside_its_room() -> void:
	var layout: Dictionary = _pair()
	# Feet at x 5: the 12 px body spans x -1 to 10, one pixel past the left edge.
	layout.entrances[&"a"][&"start"] = Vector2i(5, 256)
	_expect(layout, "'a': entrance 'start' puts the body outside the room")
	layout.entrances[&"a"][&"start"] = Vector2i(6, 256)
	assert_false(_problems_of(layout).has(
			"'a': entrance 'start' puts the body outside the room"), "x 6 fits exactly")
	layout.entrances[&"a"][&"start"] = Vector2i(48, 14)
	_expect(layout, "'a': entrance 'start' puts the body outside the room")


func test_game_rooms_have_room_info() -> void:
	var catalog: RoomCatalog = load(CATALOG_PATH) as RoomCatalog
	var problems: Array[String] = []
	for entry: RoomEntry in catalog.rooms:
		if entry == null or entry.scene == null \
				or entry.scene.resource_path.begins_with(VERIFICATION_DIR):
			continue
		var room: Room = entry.scene.instantiate() as Room
		var entrance_ids: Array[StringName] = []
		for entrance: RoomEntrance in room.entrances():
			entrance_ids.append(entrance.entrance_id)
		var existing: Dictionary = {}
		if room.info != null:
			for path: NodePath in room.info.recharge_points:
				if room.has_node(path):
					existing[path] = true
		problems.append_array(room_info_problems(entry.room_id, room.info, entrance_ids,
				existing, Tuning.data.max_volts))
		room.free()
	assert_eq(problems, [] as Array[String], "\n  " + "\n  ".join(problems))


func test_good_room_info_has_no_problems() -> void:
	assert_eq(_info_problems_of(_info()), [] as Array[String])


func test_room_info_must_exist() -> void:
	assert_eq(room_info_problems(&"a", null, [&"start"] as Array[StringName], {}, MAX_VOLTS),
			["'a': no RoomInfo"] as Array[String])


func test_every_entrance_needs_a_state_and_volts() -> void:
	var info: RoomInfo = _info()
	info.entry_states.erase(&"east")
	_expect_info(info, "'a': entrance 'east' has no entry state")
	info = _info()
	info.entry_volts.erase(&"east")
	_expect_info(info, "'a': entrance 'east' has no entry volts")


func test_room_info_must_not_name_unknown_entrances() -> void:
	var info: RoomInfo = _info()
	info.entry_states[&"north"] = FlowLedger.State.DEFAULT
	info.entry_volts[&"north"] = 3
	_expect_info(info, "'a': room info names unknown entrance 'north'")


func test_entry_volts_must_be_in_range() -> void:
	var info: RoomInfo = _info()
	info.entry_volts[&"east"] = 4
	_expect_info(info, "'a': entrance 'east' assumes 4 volts, outside 0 to 3")
	info.entry_volts[&"east"] = -1
	_expect_info(info, "'a': entrance 'east' assumes -1 volts, outside 0 to 3")


func test_volt_budget_must_be_in_range() -> void:
	var info: RoomInfo = _info()
	info.recharge_points = [^"Objects/Source"] as Array[NodePath]
	info.volt_budget = 4
	_expect_info(info, "'a': volt budget 4 is outside 0 to 3")


func test_recharge_points_must_exist() -> void:
	var info: RoomInfo = _info()
	info.recharge_points = [^"Objects/Missing"] as Array[NodePath]
	_expect_info(info, "'a': recharge point 'Objects/Missing' is not in the room")


func test_route_must_be_written() -> void:
	var info: RoomInfo = _info()
	info.route = "  \n"
	_expect_info(info, "'a': no completion route")


func test_budget_must_be_affordable_from_every_entrance() -> void:
	var info: RoomInfo = _info()
	info.entry_volts[&"east"] = 0
	_expect_info(info,
			"'a': entrance 'east' assumes 0 volts, below the budget of 1, with no recharge point")
	# Entering with exactly the budget is affordable.
	info.entry_volts[&"east"] = 1
	assert_eq(_info_problems_of(info), [] as Array[String])
	# A recharge point makes a short entry affordable (level design rule 3).
	info.entry_volts[&"east"] = 0
	info.recharge_points = [^"Objects/Source"] as Array[NodePath]
	assert_eq(_info_problems_of(info), [] as Array[String])


## Every layout rule [param rooms] breaks, as readable messages; empty when the layout is good.
## [param scene_ids] maps each room ID to its scene's `room_id`; [param entrances] maps each room
## ID to a Dictionary of entrance ID to room-local feet; [param body] is the player's body size.
static func layout_problems(rooms: Array[RoomEntry], start_room: StringName,
		start_entrance: StringName, scene_ids: Dictionary, entrances: Dictionary,
		body: Vector2i) -> Array[String]:
	var problems: Array[String] = []
	var seen: Dictionary = {}
	var catalog: RoomCatalog = RoomCatalog.new()
	catalog.rooms = rooms
	for entry: RoomEntry in rooms:
		var id: StringName = entry.room_id
		if seen.has(id):
			problems.append("duplicate room ID '%s'" % id)
		seen[id] = true
		if scene_ids.has(id) and scene_ids[id] != id:
			problems.append("'%s': its scene's room_id is '%s'" % [id, scene_ids[id]])
		var rect: Rect2i = entry.world_rect
		if rect.position.x % TILE_PX != 0 or rect.position.y % TILE_PX != 0 \
				or rect.size.x % TILE_PX != 0 or rect.size.y % TILE_PX != 0:
			problems.append("'%s': world_rect %s is not whole tiles" % [id, _rect_text(rect)])
		if rect.size.x < MIN_SIZE.x or rect.size.y < MIN_SIZE.y:
			problems.append("'%s': size (%d, %d) is smaller than 640 x 368" % [
					id, rect.size.x, rect.size.y])
		var feet: Dictionary = entrances.get(id, {})
		for entrance_id: StringName in _sorted_keys(feet):
			var at: Vector2i = feet[entrance_id]
			@warning_ignore("integer_division")
			var body_rect: Rect2i = Rect2i(at.x - body.x / 2, at.y - body.y, body.x, body.y)
			if not Rect2i(Vector2i.ZERO, rect.size).encloses(body_rect):
				problems.append("'%s': entrance '%s' puts the body outside the room" % [
						id, entrance_id])
		for other: RoomEntry in catalog.neighbors(entry):
			var edge: String = _edge_toward(rect, other.world_rect)
			if not _has_entrance_near(feet, rect, edge):
				problems.append("'%s': no entrance within %d px of its %s edge (shared with '%s')"
						% [id, WorldScript.CHECKPOINT_REACH_PX, edge, other.room_id])
	for i: int in rooms.size():
		for j: int in range(i + 1, rooms.size()):
			if rooms[i].world_rect.intersects(rooms[j].world_rect):
				problems.append("'%s' and '%s' overlap" % [rooms[i].room_id, rooms[j].room_id])
	if not seen.has(start_room):
		problems.append("start room '%s' is not in the catalog" % start_room)
	elif not (entrances.get(start_room, {}) as Dictionary).has(start_entrance):
		problems.append("start room '%s' has no entrance '%s'" % [start_room, start_entrance])
	return problems


## Every G-03 record rule [param info] breaks for room [param room_id], whose entrances are
## [param entrance_ids]; [param existing_paths] holds each recharge point that resolves to a node.
## Empty when the record is complete and the budget is affordable from every entrance.
static func room_info_problems(room_id: StringName, info: RoomInfo,
		entrance_ids: Array[StringName], existing_paths: Dictionary,
		max_volts: int) -> Array[String]:
	var problems: Array[String] = []
	if info == null:
		problems.append("'%s': no RoomInfo" % room_id)
		return problems
	var sorted_ids: Array[StringName] = entrance_ids.duplicate()
	sorted_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for entrance_id: StringName in sorted_ids:
		if not info.entry_states.has(entrance_id):
			problems.append("'%s': entrance '%s' has no entry state" % [room_id, entrance_id])
		if not info.entry_volts.has(entrance_id):
			problems.append("'%s': entrance '%s' has no entry volts" % [room_id, entrance_id])
	var named: Dictionary = {}
	for entrance_id: StringName in info.entry_states.keys() + info.entry_volts.keys():
		named[entrance_id] = true
	for entrance_id: StringName in _sorted_keys(named):
		if not entrance_ids.has(entrance_id):
			problems.append("'%s': room info names unknown entrance '%s'" % [room_id, entrance_id])
	for entrance_id: StringName in _sorted_keys(info.entry_volts):
		var volts: int = info.entry_volts[entrance_id]
		if volts < 0 or volts > max_volts:
			problems.append("'%s': entrance '%s' assumes %d volts, outside 0 to %d" % [
					room_id, entrance_id, volts, max_volts])
		elif volts < info.volt_budget and info.recharge_points.is_empty():
			problems.append("'%s': entrance '%s' assumes %d volts, below the budget of %d, with no recharge point"
					% [room_id, entrance_id, volts, info.volt_budget])
	if info.volt_budget < 0 or info.volt_budget > max_volts:
		problems.append("'%s': volt budget %d is outside 0 to %d" % [
				room_id, info.volt_budget, max_volts])
	for path: NodePath in info.recharge_points:
		if not existing_paths.has(path):
			problems.append("'%s': recharge point '%s' is not in the room" % [room_id, path])
	if info.route.strip_edges().is_empty():
		problems.append("'%s': no completion route" % room_id)
	return problems


## Every doorway mismatch between neighboring [param rooms], as readable messages; empty when every
## shared edge matches. [param grids] maps each room ID to its SolidGrid, built at its
## `world_rect`; rooms without one are skipped. Facing cells across a shared edge must agree on
## being solid. Cells are room-local; the left or upper room is named first.
static func doorway_problems(rooms: Array[RoomEntry], grids: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var catalog: RoomCatalog = RoomCatalog.new()
	catalog.rooms = rooms
	for i: int in rooms.size():
		for other: RoomEntry in catalog.neighbors(rooms[i]):
			if rooms.find(other) <= i:
				continue
			var first: RoomEntry = rooms[i]
			var second: RoomEntry = other
			if second.world_rect.end.x <= first.world_rect.position.x \
					or second.world_rect.end.y <= first.world_rect.position.y:
				first = other
				second = rooms[i]
			if not grids.has(first.room_id) or not grids.has(second.room_id):
				continue
			problems.append_array(_edge_mismatches(first, second, grids[first.room_id],
					grids[second.room_id]))
	return problems


# The mismatched facing cells across the edge [param first] shares with [param second], which lies
# to its right or below it.
static func _edge_mismatches(first: RoomEntry, second: RoomEntry, first_grid: SolidGrid,
		second_grid: SolidGrid) -> Array[String]:
	var problems: Array[String] = []
	var a: Rect2i = Rect2i(first.world_rect.position / TILE_PX, first.world_rect.size / TILE_PX)
	var b: Rect2i = Rect2i(second.world_rect.position / TILE_PX, second.world_rect.size / TILE_PX)
	var side_by_side: bool = b.position.x == a.end.x
	var step: Vector2i = Vector2i(1, 0) if side_by_side else Vector2i(0, 1)
	var along: Vector2i = Vector2i(0, 1) if side_by_side else Vector2i(1, 0)
	var start: int
	var stop: int
	var edge_cell: Vector2i
	if side_by_side:
		start = maxi(a.position.y, b.position.y)
		stop = mini(a.end.y, b.end.y)
		edge_cell = Vector2i(a.end.x - 1, 0)
	else:
		start = maxi(a.position.x, b.position.x)
		stop = mini(a.end.x, b.end.x)
		edge_cell = Vector2i(0, a.end.y - 1)
	for k: int in range(start, stop):
		var here: Vector2i = edge_cell + along * k
		var there: Vector2i = here + step
		var here_solid: bool = first_grid.cell_flags(here) & SolidGrid.SOLID != 0
		var there_solid: bool = second_grid.cell_flags(there) & SolidGrid.SOLID != 0
		if here_solid != there_solid:
			var here_local: Vector2i = here - a.position
			var there_local: Vector2i = there - b.position
			problems.append("'%s' cell (%d, %d) is %s but '%s' cell (%d, %d) is %s" % [
					first.room_id, here_local.x, here_local.y,
					"solid" if here_solid else "open", second.room_id, there_local.x,
					there_local.y, "solid" if there_solid else "open"])
	return problems


# The edge of [param here] that [param rect] (a neighbor) lies beyond, as World._edge_toward.
static func _edge_toward(here: Rect2i, rect: Rect2i) -> String:
	if rect.end.x <= here.position.x:
		return "left"
	if rect.position.x >= here.end.x:
		return "right"
	if rect.end.y <= here.position.y:
		return "top"
	return "bottom"


# Whether any of [param feet] (room-local) is within the checkpoint reach of [param edge],
# measured across the edge, as World._edge_distance does.
static func _has_entrance_near(feet: Dictionary, rect: Rect2i, edge: String) -> bool:
	for at: Vector2i in feet.values():
		var distance: int
		match edge:
			"left":
				distance = at.x
			"right":
				distance = rect.size.x - at.x
			"top":
				distance = at.y
			_:
				distance = rect.size.y - at.y
		if absi(distance) <= WorldScript.CHECKPOINT_REACH_PX:
			return true
	return false


static func _rect_text(rect: Rect2i) -> String:
	return "(%d, %d, %d, %d)" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


static func _sorted_keys(dictionary: Dictionary) -> Array:
	var keys: Array = dictionary.keys()
	keys.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return keys


# A room's entrances as entrance ID to room-local feet.
func _entrance_feet(room: Room) -> Dictionary:
	var feet: Dictionary = {}
	for entrance: RoomEntrance in room.entrances():
		feet[entrance.entrance_id] = entrance.feet()
	return feet


# A good layout: rooms 'a' and 'b' side by side, each with an entrance 48 px from the shared edge.
func _pair() -> Dictionary:
	return {
		"rooms": [_entry(&"a", Rect2i(0, 0, 640, 368)),
				_entry(&"b", Rect2i(640, 0, 640, 368))] as Array[RoomEntry],
		"start_room": &"a",
		"start_entrance": &"start",
		"scene_ids": {&"a": &"a", &"b": &"b"},
		"entrances": {&"a": {&"start": Vector2i(592, 256)}, &"b": {&"west": Vector2i(48, 256)}},
	}


# An empty SolidGrid for each of [param rooms], keyed by room ID.
func _doorway_grids(rooms: Array[RoomEntry]) -> Dictionary:
	var grids: Dictionary = {}
	for entry: RoomEntry in rooms:
		grids[entry.room_id] = SolidGrid.new(entry.world_rect, 0, 0)
	return grids


func _entry(id: StringName, rect: Rect2i) -> RoomEntry:
	var entry: RoomEntry = RoomEntry.new()
	entry.room_id = id
	entry.world_rect = rect
	return entry


func _problems_of(layout: Dictionary) -> Array[String]:
	return layout_problems(layout.rooms, layout.start_room, layout.start_entrance,
			layout.scene_ids, layout.entrances, BODY)


func _expect(layout: Dictionary, problem: String) -> void:
	var problems: Array[String] = _problems_of(layout)
	assert_true(problems.has(problem), "expected '%s', got %s" % [problem, problems])


# A good record for room 'a': entrances 'east' and 'start' at 3 volts in default, budget 1, a
# route, and no recharge point. 'Objects/Source' is the one path that resolves.
func _info() -> RoomInfo:
	var info: RoomInfo = RoomInfo.new()
	info.entry_states = {&"east": FlowLedger.State.DEFAULT, &"start": FlowLedger.State.DEFAULT}
	info.entry_volts = {&"east": 3, &"start": 3}
	info.volt_budget = 1
	info.route = "From start to the goal."
	return info


func _info_problems_of(info: RoomInfo) -> Array[String]:
	return room_info_problems(&"a", info, [&"east", &"start"] as Array[StringName],
			{^"Objects/Source": true}, MAX_VOLTS)


func _expect_info(info: RoomInfo, problem: String) -> void:
	var problems: Array[String] = _info_problems_of(info)
	assert_true(problems.has(problem), "expected '%s', got %s" % [problem, problems])
