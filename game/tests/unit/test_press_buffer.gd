# Tests PressBuffer: token lifetime, window edges, replacement and single spend.
# Serves AC M-06, M-07, C-07.
extends TestCase

const WINDOW: int = 6


func test_spendable_from_creation_through_window() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	buffer.press(10)
	assert_false(buffer.can_spend(9), "before the press")
	for tick: int in range(10, 17):
		assert_true(buffer.can_spend(tick), "tick %d" % tick)
	assert_false(buffer.can_spend(17), "one past the window")


func test_expire_reports_first_tick_past_window() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	buffer.press(10)
	for tick: int in range(10, 17):
		assert_eq(buffer.expire(tick), PressBuffer.NONE, "tick %d" % tick)
	assert_eq(buffer.expire(17), 10, "tick 17")
	assert_false(buffer.has_token(), "gone after expiring")
	assert_eq(buffer.expire(18), PressBuffer.NONE, "reported once")


func test_new_press_replaces_unspent_token() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	assert_eq(buffer.press(10), PressBuffer.NONE, "nothing to replace")
	assert_eq(buffer.press(13), 10, "replaced token's tick")
	assert_eq(buffer.created_tick(), 13)
	assert_true(buffer.can_spend(19), "window counts from the new press")
	assert_false(buffer.can_spend(20))


func test_spent_once() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	buffer.press(10)
	assert_eq(buffer.spend(12), 10, "first spend")
	assert_eq(buffer.spend(12), PressBuffer.NONE, "second spend")
	assert_false(buffer.has_token())
	assert_eq(buffer.expire(30), PressBuffer.NONE, "a spent token never expires")


func test_spend_outside_window_keeps_nothing_spent() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	buffer.press(10)
	assert_eq(buffer.spend(17), PressBuffer.NONE, "too late")
	assert_eq(buffer.spend(9), PressBuffer.NONE, "too early")


func test_token_on_tick_zero() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	buffer.press(0)
	assert_true(buffer.has_token())
	assert_true(buffer.can_spend(0))
	assert_eq(buffer.spend(6), 0)


func test_clear_drops_silently() -> void:
	var buffer: PressBuffer = PressBuffer.new(WINDOW)
	assert_eq(buffer.created_tick(), PressBuffer.NONE, "empty at start")
	buffer.press(10)
	buffer.clear()
	assert_false(buffer.has_token())
	assert_eq(buffer.created_tick(), PressBuffer.NONE)
	assert_eq(buffer.expire(30), PressBuffer.NONE, "nothing to report")
