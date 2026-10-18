# The world map: every room's record, plus where the game starts. Rooms never refer to each
# other directly, so no scene loads another in a cycle. Serves AC R-01 and, from M6, G-01.
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
