# Tests DashState: start and direction, velocities in all 8 directions, duration, cooldown, the
# ground refill on every grounded tick but never mid-dash, interruption, and the charged refill
# with and without clearing the cooldown. Serves AC M-03, M-04, C-08.
extends TestCase

# The tuning start values (test_tuning.gd pins them: 0.15 s and 0.2 s at 60 ticks per second).
const DASH_TICKS: int = 9
const COOLDOWN_TICKS: int = 12
const SPEED: float = 480.0
const END_SPEED: float = 320.0
const END_UP_MULT: float = 0.75
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]


func test_starts_with_a_charge_and_no_dash() -> void:
	var dash: DashState = _make()
	assert_eq(dash.charges, 1)
	assert_false(dash.is_active())
	assert_true(dash.can_start())


func test_start_spends_the_charge_and_records_the_tick() -> void:
	var dash: DashState = _make()
	dash.start(Vector2i(1, -1), 1, 40)
	assert_eq(dash.charges, 0)
	assert_true(dash.is_active())
	assert_eq(dash.start_tick, 40)
	assert_eq(dash.direction, Vector2i(1, -1))
	assert_false(dash.can_start(), "no second dash")


func test_no_direction_held_dashes_toward_the_facing() -> void:
	for facing: int in [-1, 1]:
		var dash: DashState = _make()
		dash.start(Vector2i.ZERO, facing, 0)
		assert_eq(dash.direction, Vector2i(facing, 0), "facing %d" % facing)
		assert_eq(dash.start_velocity_x(), facing * SPEED)
		assert_eq(dash.start_velocity_y(), 0.0)


func test_every_direction_has_the_same_speed() -> void:
	for dir: Vector2i in DIRECTIONS:
		var dash: DashState = _make()
		dash.start(dir, 1, 0)
		var vx: float = dash.start_velocity_x()
		var vy: float = dash.start_velocity_y()
		assert_near(sqrt(vx * vx + vy * vy), SPEED, 1e-9, "speed %s" % dir)
		var axis: float = SPEED * DashState.DIAGONAL if dir.x != 0 and dir.y != 0 else SPEED
		assert_eq(vx, dir.x * axis, "vx %s" % dir)
		assert_eq(vy, dir.y * axis, "vy %s" % dir)


func test_end_velocity_slows_an_upward_dash() -> void:
	for dir: Vector2i in DIRECTIONS:
		var dash: DashState = _make()
		dash.start(dir, 1, 0)
		var axis: float = END_SPEED * DashState.DIAGONAL if dir.x != 0 and dir.y != 0 else END_SPEED
		var up: float = END_UP_MULT if dir.y < 0 else 1.0
		assert_eq(dash.end_velocity_x(), dir.x * axis, "vx %s" % dir)
		assert_eq(dash.end_velocity_y(), dir.y * axis * up, "vy %s" % dir)


func test_active_for_exactly_dash_ticks() -> void:
	var dash: DashState = _make()
	dash.start(Vector2i.RIGHT, 1, 0)
	for n: int in range(1, DASH_TICKS):
		assert_false(dash.tick_timers(), "call %d" % n)
		assert_true(dash.is_active(), "still active after call %d" % n)
	assert_true(dash.tick_timers(), "ends on call %d" % DASH_TICKS)
	assert_false(dash.is_active())
	assert_false(dash.tick_timers(), "reports the end once")


func test_cooldown_blocks_a_restart_even_with_a_charge() -> void:
	var dash: DashState = _make()
	dash.start(Vector2i.RIGHT, 1, 0)
	# Tick t's step 3 starts the dash; its step 9 is the first countdown. Step 3 of tick t + n
	# has seen n countdowns.
	for tick: int in range(1, COOLDOWN_TICKS + 1):
		dash.tick_timers()
		dash.refill_ground()
		if tick < COOLDOWN_TICKS:
			assert_false(dash.can_start(), "tick %d" % tick)
	assert_eq(dash.charges, 1, "refilled on the ground")
	assert_true(dash.can_start(), "tick %d" % COOLDOWN_TICKS)


func test_ground_refill_never_mid_dash() -> void:
	var dash: DashState = _make()
	dash.start(Vector2i.RIGHT, 1, 0)
	for n: int in DASH_TICKS - 1:
		assert_false(dash.refill_ground(), "mid-dash, call %d" % n)
		dash.tick_timers()
	assert_false(dash.refill_ground(), "on the last active tick")
	assert_eq(dash.charges, 0)
	dash.tick_timers()
	assert_true(dash.refill_ground(), "first grounded tick after the dash ends")
	assert_eq(dash.charges, 1)


func test_ground_refill_on_every_grounded_tick_when_empty() -> void:
	var dash: DashState = _make()
	assert_false(dash.refill_ground(), "already full")
	for attempt: int in 3:
		dash.start(Vector2i.UP, 1, attempt * 100)
		dash.interrupt()
		assert_true(dash.refill_ground(), "attempt %d" % attempt)
		assert_false(dash.refill_ground(), "full again, attempt %d" % attempt)
		dash.cooldown_ticks_left = 0


func test_interrupt_ends_the_dash_and_keeps_the_cooldown() -> void:
	var dash: DashState = _make()
	dash.start(Vector2i.RIGHT, 1, 0)
	dash.tick_timers()
	dash.interrupt()
	assert_false(dash.is_active())
	assert_eq(dash.cooldown_ticks_left, COOLDOWN_TICKS - 1)
	assert_false(dash.tick_timers(), "no second end report")


func test_charged_refill_clears_the_cooldown_when_on() -> void:
	var dash: DashState = _make(true)
	dash.start(Vector2i.RIGHT, 1, 0)
	dash.tick_timers()
	dash.interrupt()
	assert_true(dash.refill_charged(), "0 to 1")
	assert_eq(dash.charges, 1)
	assert_eq(dash.cooldown_ticks_left, 0)
	assert_true(dash.can_start(), "the charged dash can start next tick")
	assert_false(dash.refill_charged(), "already full")


func test_charged_refill_keeps_the_cooldown_when_off() -> void:
	var dash: DashState = _make(false)
	dash.start(Vector2i.RIGHT, 1, 0)
	dash.tick_timers()
	dash.interrupt()
	assert_true(dash.refill_charged(), "0 to 1")
	assert_eq(dash.cooldown_ticks_left, COOLDOWN_TICKS - 1)
	assert_false(dash.can_start(), "cooldown still running")


func _make(refill_clears_cooldown: bool = true) -> DashState:
	return DashState.new(DASH_TICKS, COOLDOWN_TICKS, SPEED, END_SPEED, END_UP_MULT,
			refill_clears_cooldown)
