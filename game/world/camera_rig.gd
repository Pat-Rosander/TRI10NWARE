# The camera: World sets its target during the tick, so it moves on the physics step and physics
# interpolation smooths it together with the player. Never shows past the room's bounds. Serves AC V-01.
extends Camera2D

var _bounds: Rect2i = Rect2i()


## Clamps the view to [param rect], the current room's bounds in world pixels.
func set_bounds(rect: Rect2i) -> void:
	_bounds = rect
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.end.x
	limit_bottom = rect.end.y


## Centers the view on [param target], clamped so the view stays inside the bounds.
## Called only from World's tick.
func move_to(target: Vector2i) -> void:
	var half: Vector2i = Vector2i(get_viewport_rect().size) / 2
	var point: Vector2i = target
	if _bounds.has_area():
		point.x = clampi(point.x, _bounds.position.x + half.x, _bounds.end.x - half.x)
		point.y = clampi(point.y, _bounds.position.y + half.y, _bounds.end.y - half.y)
	position = Vector2(point)
