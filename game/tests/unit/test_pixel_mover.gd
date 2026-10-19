# Tests PixelMover against small hand-made grids: stopping flush at walls, floors and ceilings at
# every speed up to dash speed, one-way tops, sub-pixel rounding, the grounded and wall queries,
# the wall_check_px guard, and each movement assist, including where it must not apply.
# Serves AC M-01, M-02, M-03, D-04, D-05.
extends TestCase

const T: int = SolidGrid.TILE_PX
const TICKS: int = 60
const BODY: Vector2i = Vector2i(12, 15)
const WALL_CHECK: int = 6
const DASH_SPEED: int = 480
# The assist values of tuning.tres.
const CORNER: int = 8
const DASH_CORNER: int = 8
const ONEWAY: int = 8
const SNAP: int = 6
const APEX_THRESHOLD: float = 80.0
# A one-screen room at the origin: 40 x 23 tiles.
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
# The box built by _make_box(): its open inside, in pixels.
const BOX: Rect2i = Rect2i(6 * T, 6 * T, 24 * T, 9 * T)


func test_body_rect_has_its_feet_at_the_bottom_center() -> void:
	var mover: PixelMover = _make_mover(SolidGrid.new(ROOM), Vector2i(100, 200))
	assert_eq(mover.body_rect(mover.position), Rect2i(94, 185, 12, 15))
	assert_eq(mover.body_rect(Vector2i(0, 0)).end, Vector2i(6, 0), "feet line is the bottom edge")


func test_stops_flush_at_every_speed_up_to_dash_speed() -> void:
	var grid: SolidGrid = _make_box()
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for dir: Vector2i in directions:
		for gap: int in [20, 21, 27]:
			for speed: int in range(1, DASH_SPEED + 1):
				var problem: String = _run_into_box_side(grid, dir, gap, speed)
				if not problem.is_empty():
					assert_eq(problem, "", "dir %s, gap %d px, %d px/s" % [dir, gap, speed])
					return


func test_blocked_axis_stops_while_the_other_continues() -> void:
	var grid: SolidGrid = _make_box()
	# A diagonal dash down-right, starting just above the floor: it lands and slides on.
	var mover: PixelMover = _make_mover(grid, Vector2i(200, BOX.end.y - 4))
	var diagonal: float = DASH_SPEED * 0.7071067811865476
	mover.velocity_x = diagonal
	mover.velocity_y = diagonal
	mover.move()
	assert_true(mover.floor_hit, "floor contact")
	assert_eq(mover.position.y, BOX.end.y, "on the floor")
	assert_eq(mover.velocity_y, 0.0, "vertical velocity stopped")
	assert_eq(mover.velocity_x, diagonal, "horizontal velocity kept")
	assert_eq(mover.position.x, 200 + roundi(diagonal / TICKS), "moved the full horizontal step")
	assert_eq(mover.wall_hit, 0, "no wall contact")


func test_room_edges_are_walls_and_the_bottom_is_a_pit() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	var mover: PixelMover = _make_mover(grid, Vector2i(30, 100))
	for i: int in 10:
		mover.velocity_x = -DASH_SPEED
		mover.move()
	assert_eq(mover.body_rect(mover.position).position.x, 0, "stops at the left edge")
	assert_eq(mover.wall_hit, -1, "left wall contact")
	mover.position = Vector2i(ROOM.end.x - 30, 100)
	for i: int in 10:
		mover.velocity_x = DASH_SPEED
		mover.move()
	assert_eq(mover.body_rect(mover.position).end.x, ROOM.end.x, "stops at the right edge")
	assert_eq(mover.wall_hit, 1, "right wall contact")
	mover.position = Vector2i(200, 40)
	for i: int in 10:
		mover.velocity_y = -DASH_SPEED
		mover.move()
	assert_eq(mover.body_rect(mover.position).position.y, 0, "stops at the top edge")
	assert_true(mover.ceiling_hit, "ceiling contact")
	mover.position = Vector2i(200, ROOM.end.y - 10)
	var fell_through: bool = true
	for i: int in 20:
		mover.velocity_y = 320.0
		mover.move()
		fell_through = fell_through and not mover.floor_hit
	assert_true(fell_through, "nothing stops a fall at the bottom edge")
	assert_true(mover.position.y > ROOM.end.y + 50, "fell below the room")


func test_one_way_top_catches_a_falling_body() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(10, 10), SolidGrid.DEFAULT_ONLY)
	var mover: PixelMover = _make_mover(grid, Vector2i(10 * T + 8, 10 * T - 30))
	var landed: bool = false
	for i: int in 30:
		mover.velocity_y = 320.0
		mover.move()
		if mover.floor_hit:
			landed = true
			break
	assert_true(landed, "landed")
	assert_eq(mover.position.y, 10 * T, "feet on the top")
	assert_eq(mover.remainder_y, 0.0, "remainder reset")
	assert_true(mover.is_grounded(), "grounded")


func test_one_way_top_lets_rising_and_sideways_bodies_through() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(10, 10), SolidGrid.DEFAULT_ONLY)
	# Rising from below the tile, through it.
	var mover: PixelMover = _make_mover(grid, Vector2i(10 * T + 8, 11 * T + 20))
	mover.velocity_y = -210.0
	var hit: bool = false
	for i: int in 20:
		mover.move()
		hit = hit or mover.ceiling_hit
	assert_false(hit, "no ceiling contact while rising")
	assert_true(mover.position.y < 10 * T, "rose above the top")
	# Walking sideways through the tile's row.
	mover = _make_mover(grid, Vector2i(9 * T - 10, 10 * T + 8))
	mover.velocity_x = 180.0
	hit = false
	for i: int in 20:
		mover.move()
		hit = hit or mover.wall_hit != 0
	assert_false(hit, "no wall contact sideways")
	assert_true(mover.position.x > 11 * T + 6, "walked past the tile")


func test_one_way_top_lets_a_body_already_inside_fall_through() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(10, 10), SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(10, 11), SolidGrid.ORDINARY)
	# Feet 5 px into the platform row: it falls on to the solid tile below, not the top.
	var mover: PixelMover = _make_mover(grid, Vector2i(10 * T + 8, 10 * T + 5))
	for i: int in 10:
		mover.velocity_y = 120.0
		mover.move()
		if mover.floor_hit:
			break
	assert_eq(mover.position.y, 11 * T, "landed on the solid tile below")


func test_one_way_top_of_the_inactive_family_does_not_catch() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(10, 10), SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(20, 10), SolidGrid.FLOW_ONLY)
	grid.set_flow(true)
	assert_eq(_fall_onto(grid, 10 * T + 8), -1, "default-only top, in flow")
	assert_eq(_fall_onto(grid, 20 * T + 8), 10 * T, "flow-only top, in flow")
	grid.set_flow(false)
	assert_eq(_fall_onto(grid, 10 * T + 8), 10 * T, "default-only top, in default")
	assert_eq(_fall_onto(grid, 20 * T + 8), -1, "flow-only top, in default")


func test_exact_half_rounds_away_from_zero() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	for sign_x: int in [1, -1]:
		var mover: PixelMover = _make_mover(grid, Vector2i(320, 200))
		mover.velocity_x = sign_x * 30.0
		var steps: Array[int] = []
		for i: int in 6:
			var before: int = mover.position.x
			mover.move()
			steps.append(mover.position.x - before)
			if i == 0:
				assert_eq(mover.remainder_x, sign_x * -0.5, "remainder after the first half")
		var expected: Array[int] = []
		for i: int in 6:
			expected.append(sign_x if i % 2 == 0 else 0)
		assert_eq(steps, expected, "steps, sign %d" % sign_x)


func test_mirrored_moves_give_mirrored_positions() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	var start: Vector2i = Vector2i(320, 200)
	for speed: float in [1.0, 7.5, 13.0, 47.3, 100.0, 179.9, 210.0, 333.3, 480.0]:
		var right: PixelMover = _make_mover(grid, start)
		var left: PixelMover = _make_mover(grid, start)
		right.velocity_x = speed
		left.velocity_x = -speed
		var mirrored: bool = true
		for i: int in 40:
			right.move()
			left.move()
			mirrored = mirrored and right.position.x - start.x == start.x - left.position.x
		assert_true(mirrored, "%s px/s" % speed)


func test_block_resets_the_remainder_of_that_axis_only() -> void:
	var grid: SolidGrid = _make_box()
	@warning_ignore("integer_division")
	var mover: PixelMover = _make_mover(grid, Vector2i(BOX.end.x - BODY.x / 2, 200))
	mover.remainder_x = 0.3
	mover.remainder_y = 0.2
	mover.velocity_x = 60.0
	mover.move()
	assert_eq(mover.wall_hit, 1, "wall contact")
	assert_eq(mover.remainder_x, 0.0, "horizontal remainder reset")
	assert_eq(mover.velocity_x, 0.0, "horizontal velocity stopped")
	assert_eq(mover.remainder_y, 0.2, "vertical remainder kept")


func test_no_drift_at_constant_speed() -> void:
	var grid: SolidGrid = SolidGrid.new(Rect2i(0, 0, 4000, 368))
	var mover: PixelMover = _make_mover(grid, Vector2i(100, 200))
	mover.velocity_x = 180.0
	for i: int in 600:
		mover.move()
	assert_eq(mover.position.x, 1900, "180 px/s for 600 ticks")
	for speed: float in [100.0, 37.0, 13.7]:
		mover = _make_mover(grid, Vector2i(100, 200))
		mover.velocity_x = speed
		var bounded: bool = true
		for tick: int in range(1, 601):
			mover.move()
			var exact: float = 100.0 + speed * tick / TICKS
			bounded = bounded and absf(mover.position.x - exact) <= 0.5 + 1e-9
			bounded = bounded and absf(mover.remainder_x) <= 0.5
		assert_true(bounded, "within half a pixel of the exact path at %s px/s" % speed)
		assert_eq(mover.position.x, 100 + roundi(speed * 10.0), "after 10 s at %s px/s" % speed)


func test_is_grounded() -> void:
	var grid: SolidGrid = _make_box()
	grid.set_cell(Vector2i(10, 8), SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(14, 8), SolidGrid.FLOW_ONLY)
	assert_true(_make_mover(grid, Vector2i(200, BOX.end.y)).is_grounded(), "on solid ground")
	assert_false(_make_mover(grid, Vector2i(200, BOX.end.y - 1)).is_grounded(), "1 px above it")
	assert_true(_make_mover(grid, Vector2i(10 * T + 8, 8 * T)).is_grounded(), "on a live top")
	assert_false(_make_mover(grid, Vector2i(10 * T + 8, 8 * T - 1)).is_grounded(),
			"1 px above a live top")
	assert_false(_make_mover(grid, Vector2i(10 * T + 8, 8 * T + 1)).is_grounded(),
			"1 px inside a live top")
	assert_false(_make_mover(grid, Vector2i(14 * T + 8, 8 * T)).is_grounded(),
			"on an inactive top")
	assert_false(_make_mover(SolidGrid.new(ROOM), Vector2i(200, ROOM.end.y)).is_grounded(),
			"at the pit")


func test_wall_query_reaches_the_full_wall_check_distance() -> void:
	# Shifted the full wall_check_px, the body overlaps a wall up to wall_check_px - 1 px away;
	# a wall exactly wall_check_px away is only touched.
	var grid: SolidGrid = _make_box()
	@warning_ignore("integer_division")
	var half: int = BODY.x / 2
	var y: int = 200
	for gap: int in [0, 1, WALL_CHECK - 1]:
		assert_true(_make_mover(grid, Vector2i(BOX.end.x - gap - half, y)).wall_at(1),
				"right wall %d px away" % gap)
		assert_true(_make_mover(grid, Vector2i(BOX.position.x + gap + half, y)).wall_at(-1),
				"left wall %d px away" % gap)
	assert_false(_make_mover(grid, Vector2i(BOX.end.x - WALL_CHECK - half, y)).wall_at(1),
			"right wall just out of reach")
	assert_false(_make_mover(grid, Vector2i(BOX.position.x + WALL_CHECK + half, y)).wall_at(-1),
			"left wall just out of reach")
	assert_false(_make_mover(grid, Vector2i(BOX.end.x - half, y)).wall_at(-1),
			"no wall on the other side")


func test_platforms_are_never_walls_and_room_edges_are() -> void:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	grid.set_cell(Vector2i(10, 10), SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(12, 10), SolidGrid.FLOW_ONLY)
	var y: int = 10 * T + 12
	assert_false(_make_mover(grid, Vector2i(10 * T - 8, y)).wall_at(1), "default-only, in default")
	assert_false(_make_mover(grid, Vector2i(12 * T - 8, y)).wall_at(1), "flow-only, in default")
	grid.set_flow(true)
	assert_false(_make_mover(grid, Vector2i(10 * T - 8, y)).wall_at(1), "default-only, in flow")
	assert_false(_make_mover(grid, Vector2i(12 * T - 8, y)).wall_at(1), "flow-only, in flow")
	@warning_ignore("integer_division")
	var half: int = BODY.x / 2
	assert_true(_make_mover(grid, Vector2i(WALL_CHECK - 1 + half, 100)).wall_at(-1), "left room edge")
	assert_true(_make_mover(grid, Vector2i(ROOM.end.x - WALL_CHECK + 1 - half, 100)).wall_at(1),
			"right room edge")


func test_tuning_keeps_wall_check_below_one_tile() -> void:
	var data: TuningData = load("res://config/tuning.tres") as TuningData
	assert_true(data.wall_check_px < T,
			"wall_check_px is %d; the one-overlap wall check is exact only below %d (spec, "
			% [data.wall_check_px, T] + "M1, Decide before step 2, Wall-check distance)")


# Corner correction. The ceiling tile (10, 5) spans x 160-175 and ends at y 96; feet at y 111
# put the head exactly under it.

func test_corner_correction_shifts_a_head_that_clips_an_edge() -> void:
	var grid: SolidGrid = _grid_with([Vector2i(10, 5)])
	# The body spans x 173-184: its left 3 px are under the tile.
	var mover: PixelMover = _make_mover(grid, Vector2i(179, 111))
	mover.velocity_y = -60.0
	mover.move()
	assert_eq(mover.corner_shift, 3, "shifted right 3 px")
	assert_eq(mover.position, Vector2i(182, 110), "clear of the tile and 1 px higher")
	assert_false(mover.ceiling_hit, "no ceiling contact")
	assert_eq(mover.velocity_y, -60.0, "keeps rising")
	# The mirror case: the body's right 2 px under the tile shift left, even facing right.
	mover = _make_mover(grid, Vector2i(156, 111))
	mover.velocity_y = -60.0
	mover.move(1)
	assert_eq(mover.corner_shift, -2, "the smallest shift wins")


func test_corner_correction_reaches_exactly_its_limit() -> void:
	var grid: SolidGrid = _grid_with([Vector2i(10, 5)])
	var mover: PixelMover = _make_mover(grid, Vector2i(176 - 8 + 6, 111))
	mover.velocity_y = -60.0
	mover.move()
	assert_eq(mover.corner_shift, CORNER, "an 8 px overlap is corrected")
	mover = _make_mover(grid, Vector2i(176 - 9 + 6, 111))
	mover.velocity_y = -60.0
	mover.move()
	assert_eq(mover.corner_shift, 0, "a 9 px overlap is not")
	assert_true(mover.ceiling_hit, "it hits the ceiling")
	assert_eq(mover.position, Vector2i(173, 111), "and stops flush")
	assert_eq(mover.velocity_y, 0.0, "vertical velocity stopped")


func test_corner_correction_never_moves_into_a_solid_cell() -> void:
	# Tile (11, 5) beside it: the 3 px shift that cleared tile (10, 5) now meets another.
	var grid: SolidGrid = _grid_with([Vector2i(10, 5), Vector2i(11, 5)])
	var mover: PixelMover = _make_mover(grid, Vector2i(179, 111))
	mover.velocity_y = -60.0
	mover.move()
	assert_eq(mover.corner_shift, 0, "no shift")
	assert_true(mover.ceiling_hit, "ceiling contact")


func test_corner_correction_only_applies_when_rising() -> void:
	# Falling on to a floor tile's edge with the same 3 px overlap: an ordinary landing.
	var grid: SolidGrid = _grid_with([Vector2i(10, 10)])
	var mover: PixelMover = _make_mover(grid, Vector2i(179, 10 * T - 1))
	mover.velocity_y = 120.0
	mover.move()
	assert_eq(mover.corner_shift, 0, "no shift")
	assert_true(mover.floor_hit, "landed")
	assert_eq(mover.position, Vector2i(179, 10 * T), "on the edge, not shifted")


func test_corner_correction_tie_prefers_velocity_then_facing() -> void:
	# Centered under the tile, both ways need 14 px: a tie only a wider limit can reach (the
	# tuning's 8 px never ties with 16 px tiles and a 12 px body).
	var grid: SolidGrid = _grid_with([Vector2i(10, 5)])
	var cases: Array[Array] = [[1.0, -1, 14], [-1.0, 1, -14], [0.0, 1, 14], [0.0, -1, -14]]
	for c: Array in cases:
		var mover: PixelMover = _make_mover(grid, Vector2i(168, 111), 14)
		mover.velocity_y = -60.0
		# Horizontal speed below half a pixel per tick, so the body does not move sideways.
		mover.velocity_x = c[0] * 10.0
		mover.move(c[1])
		assert_eq(mover.corner_shift, c[2], "velocity %s, facing %d" % [c[0], c[1]])


func test_corner_correction_applies_at_most_once_per_move() -> void:
	# After clearing tile (10, 5) to the right, the body meets tile (11, 4) 15 px higher. A wider
	# limit would let a second correction (10 px right) fit; it must not be used.
	var grid: SolidGrid = _grid_with([Vector2i(10, 5), Vector2i(11, 4)])
	var mover: PixelMover = _make_mover(grid, Vector2i(179, 111), 20)
	mover.velocity_y = -1200.0
	mover.move()
	assert_eq(mover.corner_shift, 3, "the first correction")
	assert_true(mover.ceiling_hit, "the second block stops the body")
	assert_eq(mover.position, Vector2i(182, 95), "flush under tile (11, 4)")


# Dash corner correction. The lip is tile (11, 10): x 176-191, top at y 160. The body starts
# with its right edge at x 175, its feet [param below] px under the lip's top.

func test_dash_corner_correction_lifts_a_dash_over_a_lip() -> void:
	for below: int in [1, 4, DASH_CORNER]:
		var mover: PixelMover = _dash_at_lip(_grid_with([Vector2i(11, 10)]), below,
				Vector2i(1, 0))
		assert_eq(mover.dash_corner_shift, -below, "%d px below: lifted" % below)
		assert_eq(mover.position, Vector2i(169 + 8, 160), "%d px below: on the top" % below)
		assert_eq(mover.wall_hit, 0, "%d px below: no wall contact" % below)
		assert_eq(mover.velocity_x, float(DASH_SPEED), "%d px below: keeps dashing" % below)
	var up: PixelMover = _dash_at_lip(_grid_with([Vector2i(11, 10)]), 4, Vector2i(1, -1))
	assert_eq(up.dash_corner_shift, -4, "an up-diagonal dash is lifted too")


func test_dash_corner_correction_refusals() -> void:
	var lip: SolidGrid = _grid_with([Vector2i(11, 10)])
	var mover: PixelMover = _dash_at_lip(lip, DASH_CORNER + 1, Vector2i(1, 0))
	assert_eq(mover.dash_corner_shift, 0, "9 px below: not lifted")
	assert_eq(mover.wall_hit, 1, "9 px below: wall contact")
	assert_eq(mover.position, Vector2i(170, 169), "9 px below: stopped flush")
	mover = _dash_at_lip(lip, 4, Vector2i.ZERO)
	assert_eq(mover.wall_hit, 1, "not dashing: no lift")
	mover = _dash_at_lip(lip, 4, Vector2i(1, 1))
	assert_eq(mover.wall_hit, 1, "a down-diagonal dash: no lift")
	# A wall two tiles tall: lifting onto tile (11, 10) would put the body into tile (11, 9).
	mover = _dash_at_lip(_grid_with([Vector2i(11, 10), Vector2i(11, 9)]), 4, Vector2i(1, 0))
	assert_eq(mover.dash_corner_shift, 0, "a wall, not a lip: no lift")
	assert_eq(mover.wall_hit, 1, "a wall: wall contact")


func test_dash_corner_correction_applies_at_most_once_per_move() -> void:
	# Two steps 16 px apart: lifted over the first, then stopped by the second, which a wider
	# limit could otherwise lift over too.
	var grid: SolidGrid = _grid_with([Vector2i(11, 10), Vector2i(12, 9)])
	var mover: PixelMover = PixelMover.new(grid, BODY, WALL_CHECK, TICKS, CORNER, 20, ONEWAY,
			SNAP, APEX_THRESHOLD)
	mover.position = Vector2i(169, 164)
	mover.velocity_x = 1200.0
	mover.move(1, Vector2i(1, 0))
	assert_eq(mover.dash_corner_shift, -4, "the first lift")
	assert_eq(mover.wall_hit, 1, "the second step stops the body")
	assert_eq(mover.position, Vector2i(186, 160), "flush against tile (12, 9)")


# One-way platform help. The platform is tile (10, 10): x 160-175, top at y 160.

func test_oneway_help_lifts_a_slow_rising_body_onto_the_top() -> void:
	for below: int in [1, 5, ONEWAY]:
		var mover: PixelMover = _make_mover(_grid_with([Vector2i(10, 10)],
				SolidGrid.DEFAULT_ONLY), Vector2i(168, 160 + below))
		mover.velocity_y = -50.0
		mover.remainder_y = -0.3
		assert_eq(mover.oneway_help(), -below, "%d px below: lifted" % below)
		assert_eq(mover.position, Vector2i(168, 160), "%d px below: on the top" % below)
		assert_eq(mover.velocity_y, 0.0, "%d px below: vertical speed 0" % below)
		assert_eq(mover.remainder_y, 0.0, "%d px below: remainder 0" % below)
		assert_true(mover.is_grounded(), "%d px below: grounded" % below)
	var edge: PixelMover = _oneway_at(SolidGrid.DEFAULT_ONLY, 5, -APEX_THRESHOLD + 1.0)
	assert_eq(edge.oneway_help(), -5, "just under the apex threshold")


func test_oneway_help_refusals() -> void:
	assert_eq(_oneway_at(SolidGrid.DEFAULT_ONLY, 5, -APEX_THRESHOLD).oneway_help(), 0,
			"rising at the apex threshold")
	assert_eq(_oneway_at(SolidGrid.DEFAULT_ONLY, 5, -200.0).oneway_help(), 0, "rising fast")
	assert_eq(_oneway_at(SolidGrid.DEFAULT_ONLY, 5, 0.0).oneway_help(), 0, "not moving")
	assert_eq(_oneway_at(SolidGrid.DEFAULT_ONLY, 5, 50.0).oneway_help(), 0, "falling")
	assert_eq(_oneway_at(SolidGrid.DEFAULT_ONLY, ONEWAY + 1, -50.0).oneway_help(), 0,
			"9 px below")
	assert_eq(_oneway_at(SolidGrid.DEFAULT_ONLY, 0, -50.0).oneway_help(), 0,
			"feet already on the top")
	assert_eq(_oneway_at(SolidGrid.FLOW_ONLY, 5, -50.0).oneway_help(), 0,
			"a platform of the inactive family")
	assert_eq(_oneway_at(SolidGrid.ORDINARY, 5, -50.0).oneway_help(), 0, "an ordinary tile")
	# Room above: an ordinary tile directly on top of the platform.
	var grid: SolidGrid = _grid_with([Vector2i(10, 10)], SolidGrid.DEFAULT_ONLY)
	grid.set_cell(Vector2i(10, 9), SolidGrid.ORDINARY)
	var mover: PixelMover = _make_mover(grid, Vector2i(168, 165))
	mover.velocity_y = -50.0
	assert_eq(mover.oneway_help(), 0, "no room for the body above")
	assert_eq(mover.position, Vector2i(168, 165), "not moved")


# Post-dash floor snap. The floor is tile (10, 10): top at y 160.

func test_post_dash_snap_moves_down_onto_a_near_floor() -> void:
	for above: int in range(1, SNAP + 1):
		var mover: PixelMover = _make_mover(_grid_with([Vector2i(10, 10)]),
				Vector2i(168, 160 - above))
		assert_eq(mover.post_dash_snap(0), above, "%d px above: snapped" % above)
		assert_eq(mover.position.y, 160, "%d px above: on the floor" % above)
	var down: PixelMover = _make_mover(_grid_with([Vector2i(10, 10)]), Vector2i(168, 157))
	assert_eq(down.post_dash_snap(1), 3, "a downward dash snaps too")
	var top: PixelMover = _make_mover(_grid_with([Vector2i(10, 10)], SolidGrid.DEFAULT_ONLY),
			Vector2i(168, 157))
	assert_eq(top.post_dash_snap(0), 3, "on to an active one-way top")


func test_post_dash_snap_refusals() -> void:
	var grid: SolidGrid = _grid_with([Vector2i(10, 10)])
	var mover: PixelMover = _make_mover(grid, Vector2i(168, 160 - SNAP - 1))
	assert_eq(mover.post_dash_snap(0), 0, "7 px above: no snap")
	assert_eq(mover.position.y, 160 - SNAP - 1, "7 px above: not moved")
	mover = _make_mover(grid, Vector2i(168, 160))
	assert_eq(mover.post_dash_snap(0), 0, "already grounded")
	mover = _make_mover(grid, Vector2i(168, 157))
	assert_eq(mover.post_dash_snap(-1), 0, "an upward dash")
	assert_eq(mover.position.y, 157, "an upward dash: not moved")


func _make_mover(grid: SolidGrid, feet: Vector2i, corner: int = CORNER,
		dash_corner: int = DASH_CORNER) -> PixelMover:
	var mover: PixelMover = PixelMover.new(grid, BODY, WALL_CHECK, TICKS, corner, dash_corner,
			ONEWAY, SNAP, APEX_THRESHOLD)
	mover.position = feet
	return mover


# One dash-speed move toward the lip tile (11, 10) from feet [param below] px under its top,
# the body's right edge at x 175, with the active dash direction [param dash_dir].
func _dash_at_lip(grid: SolidGrid, below: int, dash_dir: Vector2i) -> PixelMover:
	var mover: PixelMover = _make_mover(grid, Vector2i(169, 160 + below))
	mover.velocity_x = DASH_SPEED
	mover.move(1, dash_dir)
	return mover


# A body rising at [param vy] with its feet [param below] px under the top of tile (10, 10),
# painted with [param solidity].
func _oneway_at(solidity: int, below: int, vy: float) -> PixelMover:
	var mover: PixelMover = _make_mover(_grid_with([Vector2i(10, 10)], solidity),
			Vector2i(168, 160 + below))
	mover.velocity_y = vy
	return mover


# A grid in ROOM with [param solidity] painted at each of [param cells].
func _grid_with(cells: Array[Vector2i], solidity: int = SolidGrid.ORDINARY) -> SolidGrid:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	for cell: Vector2i in cells:
		grid.set_cell(cell, solidity)
	return grid


# A closed box of ordinary tiles around BOX, one tile thick, inside ROOM.
func _make_box() -> SolidGrid:
	var grid: SolidGrid = SolidGrid.new(ROOM)
	var cells: Rect2i = Rect2i(BOX.position / T, BOX.size / T).grow(1)
	for y: int in range(cells.position.y, cells.end.y):
		for x: int in range(cells.position.x, cells.end.x):
			if x == cells.position.x or x == cells.end.x - 1 \
					or y == cells.position.y or y == cells.end.y - 1:
				grid.set_cell(Vector2i(x, y), SolidGrid.ORDINARY)
	return grid


# Moves a body at [param speed] toward one side of BOX, starting [param gap] px from it, until
# it stops. Returns "" if it stopped flush, never overlapping a solid cell, with that axis
# zeroed and the right contact noted; otherwise a description of what went wrong.
func _run_into_box_side(grid: SolidGrid, dir: Vector2i, gap: int, speed: int) -> String:
	@warning_ignore("integer_division")
	var half: int = BODY.x / 2
	var start: Vector2i
	match dir:
		Vector2i.RIGHT:
			start = Vector2i(BOX.end.x - gap - half, 200)
		Vector2i.LEFT:
			start = Vector2i(BOX.position.x + gap + half, 200)
		Vector2i.DOWN:
			start = Vector2i(200, BOX.end.y - gap)
		_:
			start = Vector2i(200, BOX.position.y + gap + BODY.y)
	var mover: PixelMover = _make_mover(grid, start)
	# The contact is noted on the first pixel attempt past flush, so allow gap + 1 pixels.
	@warning_ignore("integer_division")
	var max_ticks: int = (gap + 1) * TICKS / speed + 2
	for tick: int in max_ticks:
		mover.velocity_x = dir.x * speed
		mover.velocity_y = dir.y * speed
		mover.move()
		var body: Rect2i = mover.body_rect(mover.position)
		if grid.blocks(body):
			return "embedded on tick %d at %s" % [tick, mover.position]
		var stopped: bool = mover.wall_hit != 0 if dir.x != 0 else (
				mover.ceiling_hit or mover.floor_hit)
		if not stopped:
			continue
		var flush: bool
		match dir:
			Vector2i.RIGHT:
				flush = body.end.x == BOX.end.x and mover.wall_hit == 1
			Vector2i.LEFT:
				flush = body.position.x == BOX.position.x and mover.wall_hit == -1
			Vector2i.DOWN:
				flush = body.end.y == BOX.end.y and mover.floor_hit
			_:
				flush = body.position.y == BOX.position.y and mover.ceiling_hit
		if not flush:
			return "stopped at %s, not flush" % mover.position
		var zeroed: bool = mover.velocity_x == 0.0 and mover.remainder_x == 0.0 if dir.x != 0 \
				else mover.velocity_y == 0.0 and mover.remainder_y == 0.0
		if not zeroed:
			return "blocked axis not zeroed"
		return ""
	return "never stopped (at %s after %d ticks)" % [mover.position, max_ticks]


# Drops a body from above row 10 at [param x]. Returns its feet y where it landed, or -1.
func _fall_onto(grid: SolidGrid, x: int) -> int:
	var mover: PixelMover = _make_mover(grid, Vector2i(x, 10 * T - 30))
	for i: int in 30:
		mover.velocity_y = 320.0
		mover.move()
		if mover.floor_hit:
			return mover.position.y
	return -1
