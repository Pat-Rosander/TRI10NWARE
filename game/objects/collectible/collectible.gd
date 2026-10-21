# A collectible in a room. World touches it in step 7 (body overlap), after which it follows the
# player, and commits or loses it in step 10. Its ID is the room ID plus the node name; it hides
# itself whenever its room is built if GameState already holds that ID. Serves AC G-02.
class_name Collectible
extends Node2D

enum Phase { IDLE, FOLLOWING, COMMITTED }

## Where the follower floats, relative to the followed node (the player's feet): above the head.
const _FOLLOW_OFFSET: Vector2 = Vector2(0, -28)
## How quickly the follower closes on that point, per second (visual only).
const _FOLLOW_RATE: float = 10.0

## The touch hitbox in px, centered on the node's origin.
@export var size_px: Vector2i = Vector2i(16, 16)

## Where the collectible stands in the commitment rule.
var phase: Phase = Phase.IDLE
## "<room_id>/<NodeName>"; read from the Room ancestor on ready unless already set.
var id: String = ""

var _follow: Node2D


func _ready() -> void:
	if id.is_empty():
		id = _room_id() + "/" + String(name)
	if GameState.is_committed(id):
		phase = Phase.COMMITTED
		hide()


# Visual only: the follower trails the followed node. No rule reads this position.
func _process(delta: float) -> void:
	if phase != Phase.FOLLOWING or _follow == null:
		return
	var target: Vector2 = _follow.global_position + _FOLLOW_OFFSET
	global_position = global_position.lerp(target, 1.0 - exp(-_FOLLOW_RATE * delta))


## The touch hitbox in world pixels. Meaningful while IDLE, before the collectible moves.
func rect() -> Rect2i:
	var center: Vector2i = Vector2i(global_position.round())
	return Rect2i(center - size_px / 2, size_px)


## True if [param body], in world pixels, overlaps the hitbox while the collectible is IDLE.
func overlaps(body: Rect2i) -> bool:
	return phase == Phase.IDLE and rect().intersects(body)


## Step 7: touched; from now on it follows [param follow] on screen.
func touch(follow: Node2D) -> void:
	phase = Phase.FOLLOWING
	_follow = follow


## Step 10: committed; it disappears.
func commit() -> void:
	phase = Phase.COMMITTED
	_follow = null
	hide()


func _room_id() -> String:
	var node: Node = get_parent()
	while node != null:
		if node is Room:
			return String((node as Room).room_id)
		node = node.get_parent()
	return ""
