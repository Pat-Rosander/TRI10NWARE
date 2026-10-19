# Exact, engine-independent overlap tests on whole pixels: rectangle against rectangle, circle
# against rectangle, and rectangle inflation. Integers only, so results agree on every target.
# Serves AC C-01, C-03, C-04 (charged regions) and everything else that tests overlap.
class_name Geometry
extends RefCounted


## True if [param a] and [param b] share positive area. Touching edges or corners do not count,
## and a rectangle with zero width or height overlaps nothing.
static func rects_overlap(a: Rect2i, b: Rect2i) -> bool:
	if not _has_area(a) or not _has_area(b):
		return false
	return a.position.x < b.end.x and b.position.x < a.end.x \
			and a.position.y < b.end.y and b.position.y < a.end.y


## True if the circle at [param center] with [param radius] shares positive area with
## [param rect]. A circle that only touches the rectangle (distance exactly [param radius])
## does not overlap it; radius 0 and a zero-size rectangle overlap nothing.
static func circle_overlaps_rect(center: Vector2i, radius: int, rect: Rect2i) -> bool:
	if radius <= 0 or not _has_area(rect):
		return false
	var nearest_x: int = clampi(center.x, rect.position.x, rect.end.x)
	var nearest_y: int = clampi(center.y, rect.position.y, rect.end.y)
	var dx: int = center.x - nearest_x
	var dy: int = center.y - nearest_y
	return dx * dx + dy * dy < radius * radius


## [param rect] grown by [param by] pixels on every side (negative shrinks it).
static func inflate(rect: Rect2i, by: int) -> Rect2i:
	return Rect2i(rect.position - Vector2i(by, by), rect.size + Vector2i(2 * by, 2 * by))


static func _has_area(rect: Rect2i) -> bool:
	return rect.size.x > 0 and rect.size.y > 0
