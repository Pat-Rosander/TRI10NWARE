# Checks the world map in room_catalog.tres: unique IDs, scene IDs matching their records, whole-
# tile rects of at least 640 x 368, no overlaps, the start room and entrance, an entrance within
# 48 px of every shared edge on both sides, and every entrance's body inside its room. Small
# layouts built in code prove each check catches its mistake. Serves AC G-01, R-01.
extends TestCase

const CATALOG_PATH: String = "res://rooms/room_catalog.tres"
const WorldScript: GDScript = preload("res://world/world.gd")
const TILE_PX: int = 16
const MIN_SIZE: Vector2i = Vector2i(640, 368)
const BODY: Vector2i = Vector2i(12, 15)


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
