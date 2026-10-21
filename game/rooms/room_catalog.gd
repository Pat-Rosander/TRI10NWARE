# The world map: every room's record, plus where the game starts. Rooms never refer to each
# other directly, so no scene loads another in a cycle. Finds rooms by ID, by world point and by
# shared edge. Serves AC R-01 and, from M6, G-01.
class_name RoomCatalog
extends Resource

## Every room's record.
@export var rooms: Array[RoomEntry] = []
## The room the game starts in.
@export var start_room: StringName
## The entrance the game starts at, in [member start_room].
@export var start_entrance: StringName


## The record whose `room_id` is [param room_id], or null (with an error) if there is none.
func find(room_id: StringName) -> RoomEntry:
	for entry: RoomEntry in rooms:
		if entry != null and entry.room_id == room_id:
			return entry
	push_error("RoomCatalog: no room '%s'." % room_id)
	return null


## The record of the room containing the world pixel [param point], or null if none does.
func room_at(point: Vector2i) -> RoomEntry:
	for entry: RoomEntry in rooms:
		if entry != null and entry.world_rect.has_point(point):
			return entry
	return null


## Every room sharing an edge segment with [param entry]'s room, in catalog order: the rooms
## beyond its openings.
func neighbors(entry: RoomEntry) -> Array[RoomEntry]:
	var found: Array[RoomEntry] = []
	var rect: Rect2i = entry.world_rect
	for other: RoomEntry in rooms:
		if other == null or other == entry:
			continue
		var o: Rect2i = other.world_rect
		var side_by_side: bool = (o.end.x == rect.position.x or o.position.x == rect.end.x) \
				and o.position.y < rect.end.y and rect.position.y < o.end.y
		var stacked: bool = (o.end.y == rect.position.y or o.position.y == rect.end.y) \
				and o.position.x < rect.end.x and rect.position.x < o.end.x
		if side_by_side or stacked:
			found.append(other)
	return found
