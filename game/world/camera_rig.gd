# The camera: World sets its target during the tick, so it moves on the physics step and physics
# interpolation smooths it together with the player. Never shows past the room's bounds; from M6,
# slides from one room's view to the next during a crossing. Serves AC V-01, G-01.
extends Camera2D

# Camera2D's own default limits: no clamping.
const _NO_LIMIT: int = 10000000

var _bounds: Rect2i = Rect2i()
var _slide_from: Vector2i = Vector2i.ZERO
var _slide_to: Vector2i = Vector2i.ZERO


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
	position = Vector2(_clamped(target, _bounds))


## Starts a crossing's slide: from the current (old room's clamped) view to [param target]'s
## view clamped to [param new_bounds]. Clears the limits so both rooms can show.
func begin_slide(target: Vector2i, new_bounds: Rect2i) -> void:
	_slide_from = Vector2i(position.round())
	_slide_to = _clamped(target, new_bounds)
	_bounds = Rect2i()
	limit_left = -_NO_LIMIT
	limit_top = -_NO_LIMIT
	limit_right = _NO_LIMIT
	limit_bottom = _NO_LIMIT


## Moves the view [param fraction] (0 to 1) of the way through the slide, eased out, on whole
## pixels. Visual only; World calls it on each physics step of the crossing.
func slide(fraction: float) -> void:
	var t: float = clampf(fraction, 0.0, 1.0)
	var eased: float = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)
	position = (Vector2(_slide_from) + Vector2(_slide_to - _slide_from) * eased).round()


## Ends the slide: the new room's limits apply, and the view rests on [param target].
func end_slide(target: Vector2i, new_bounds: Rect2i) -> void:
	set_bounds(new_bounds)
	move_to(target)


func _clamped(target: Vector2i, rect: Rect2i) -> Vector2i:
	var half: Vector2i = Vector2i(get_viewport_rect().size) / 2
	var point: Vector2i = target
	if rect.has_area():
		point.x = clampi(point.x, rect.position.x + half.x, rect.end.x - half.x)
		point.y = clampi(point.y, rect.position.y + half.y, rect.end.y - half.y)
	return point
