# A room's goal: a thin rectangle on a platform's top surface. The node's origin sits on the
# surface at the zone's left end; World completes the room in step 10 when the player is grounded
# with feet inside it, so touching the platform's side or flying past never counts.
# Serves AC L1-04.
@tool
class_name GoalZone
extends Node2D

const _OUTLINE_COLOR: Color = Color(0.3, 1.0, 0.4, 0.9)

## The zone's width in px, from the origin to the right.
@export var width_px: int = 64: set = _set_width_px
## How far above the surface the zone reaches, in px. The surface row itself is always inside.
@export var height_px: int = 4: set = _set_height_px


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(0, -height_px), Vector2(width_px, height_px + 1)), _OUTLINE_COLOR,
				false, 1.0)


## The zone in world pixels: from [member height_px] above the surface down to and including the
## surface row, where a grounded player's feet are.
func rect() -> Rect2i:
	var origin: Vector2i = Vector2i(global_position.round())
	return Rect2i(origin.x, origin.y - height_px, width_px, height_px + 1)


## True if [param feet], in world pixels, are inside the zone.
func contains_feet(feet: Vector2i) -> bool:
	return rect().has_point(feet)


func _set_width_px(value: int) -> void:
	width_px = value
	queue_redraw()


func _set_height_px(value: int) -> void:
	height_px = value
	queue_redraw()
