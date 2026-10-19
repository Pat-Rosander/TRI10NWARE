# Tests Geometry: rectangle and circle overlap edge cases (touching edges and corners, zero
# sizes, containment, the corner diagonal) and rectangle inflation.
# Serves AC C-01, C-03, C-04.
extends TestCase

const BOX: Rect2i = Rect2i(10, 20, 12, 15)


func test_rects_overlap_when_they_share_area() -> void:
	assert_true(Geometry.rects_overlap(BOX, Rect2i(21, 34, 5, 5)), "one pixel at the corner")
	assert_true(Geometry.rects_overlap(BOX, Rect2i(0, 0, 100, 100)), "b contains a")
	assert_true(Geometry.rects_overlap(BOX, Rect2i(12, 22, 2, 2)), "a contains b")
	assert_true(Geometry.rects_overlap(BOX, BOX), "identical")


func test_rects_do_not_overlap_when_apart_or_touching() -> void:
	assert_false(Geometry.rects_overlap(BOX, Rect2i(40, 20, 5, 5)), "apart")
	assert_false(Geometry.rects_overlap(BOX, Rect2i(22, 20, 5, 5)), "touching the right edge")
	assert_false(Geometry.rects_overlap(BOX, Rect2i(5, 20, 5, 5)), "touching the left edge")
	assert_false(Geometry.rects_overlap(BOX, Rect2i(10, 35, 5, 5)), "touching the bottom edge")
	assert_false(Geometry.rects_overlap(BOX, Rect2i(10, 15, 5, 5)), "touching the top edge")
	assert_false(Geometry.rects_overlap(BOX, Rect2i(22, 35, 5, 5)), "touching a corner")


func test_zero_size_rects_overlap_nothing() -> void:
	assert_false(Geometry.rects_overlap(BOX, Rect2i(15, 25, 0, 5)), "zero width inside")
	assert_false(Geometry.rects_overlap(BOX, Rect2i(15, 25, 5, 0)), "zero height inside")
	assert_false(Geometry.rects_overlap(Rect2i(15, 25, 0, 0), BOX), "a point inside, either order")


func test_circle_overlaps_a_rect_it_reaches() -> void:
	assert_true(Geometry.circle_overlaps_rect(Vector2i(16, 27), 1, BOX), "center inside")
	assert_true(Geometry.circle_overlaps_rect(Vector2i(16, 27), 100, BOX), "circle contains rect")
	assert_true(Geometry.circle_overlaps_rect(Vector2i(30, 27), 9, BOX), "8 px right, radius 9")
	assert_true(Geometry.circle_overlaps_rect(Vector2i(16, 10), 11, BOX), "10 px above, radius 11")


func test_circle_only_touching_a_side_does_not_overlap() -> void:
	assert_false(Geometry.circle_overlaps_rect(Vector2i(30, 27), 8, BOX), "8 px right, radius 8")
	assert_false(Geometry.circle_overlaps_rect(Vector2i(16, 10), 10, BOX), "10 px above, radius 10")
	assert_false(Geometry.circle_overlaps_rect(Vector2i(2, 27), 8, BOX), "8 px left, radius 8")
	assert_false(Geometry.circle_overlaps_rect(Vector2i(16, 45), 10, BOX), "10 px below, radius 10")


func test_circle_at_a_corner_uses_the_true_distance() -> void:
	# The corner (22, 35) is 3 right and 4 down from (25, 39): distance exactly 5.
	var center: Vector2i = Vector2i(25, 39)
	assert_false(Geometry.circle_overlaps_rect(center, 5, BOX), "distance 5, radius 5")
	assert_true(Geometry.circle_overlaps_rect(center, 6, BOX), "distance 5, radius 6")
	# 3 px off on each axis is 4.24 px diagonally: radius 4 misses, radius 5 reaches.
	assert_false(Geometry.circle_overlaps_rect(Vector2i(25, 38), 4, BOX), "3 and 3 off, radius 4")
	assert_true(Geometry.circle_overlaps_rect(Vector2i(25, 38), 5, BOX), "3 and 3 off, radius 5")


func test_radius_zero_and_zero_size_rects_overlap_nothing() -> void:
	assert_false(Geometry.circle_overlaps_rect(Vector2i(16, 27), 0, BOX), "radius 0, center inside")
	assert_false(Geometry.circle_overlaps_rect(Vector2i(16, 27), -3, BOX), "negative radius")
	assert_false(Geometry.circle_overlaps_rect(Vector2i(16, 27), 50, Rect2i(16, 27, 0, 0)),
			"a point at the center")
	assert_false(Geometry.circle_overlaps_rect(Vector2i(16, 27), 50, Rect2i(10, 27, 12, 0)),
			"a zero-height line")


func test_inflate_grows_every_side() -> void:
	assert_eq(Geometry.inflate(BOX, 4), Rect2i(6, 16, 20, 23), "grow by 4")
	assert_eq(Geometry.inflate(BOX, 0), BOX, "grow by 0")
	assert_eq(Geometry.inflate(BOX, -2), Rect2i(12, 22, 8, 11), "shrink by 2")
