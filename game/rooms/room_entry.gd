# One room's record on the world map: which scene to build and where it sits. The catalog holds
# one per room. Serves AC R-01 (rebuilding a room from its scene) and, from M6, G-01.
class_name RoomEntry
extends Resource

## Unique room ID; matches the room scene's `room_id`.
@export var room_id: StringName
## The room scene, built fresh on every entry and respawn.
@export var scene: PackedScene
## The room's place and size on the world map, in pixels; whole tiles.
@export var world_rect: Rect2i
