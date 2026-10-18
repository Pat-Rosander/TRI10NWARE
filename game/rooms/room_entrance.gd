# A spawn point and checkpoint inside a room. Its position, in room-local whole pixels, is where
# the player's feet appear. Serves AC R-01.
class_name RoomEntrance
extends Marker2D

## Unique within its room.
@export var entrance_id: StringName
## The direction the player faces on arrival: -1 left, 1 right.
@export_enum("Left:-1", "Right:1") var facing: int = 1


## The feet position in room-local whole pixels.
func feet() -> Vector2i:
	return Vector2i(position.round())
