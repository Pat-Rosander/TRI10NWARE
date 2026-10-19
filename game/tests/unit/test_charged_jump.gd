# Tests charged objects in the real player scene, tick by tick in World's step order: the
# tick-exact entry and buffer edges, dash cutting, the charged dash, overlapping regions, launch
# speed and kept horizontal speed, the gates and exit hysteresis. Stands in for c01–c08 until
# their scenarios run. Serves AC C-01 to C-08.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const OBJECT_SCENE: PackedScene = preload("res://objects/charged_object/charged_object.tscn")
# An empty 40 × 40 tile room: the player is always airborne.
const ROOM: Rect2i = Rect2i(0, 0, 640, 640)
const CENTER: Vector2i = Vector2i(320, 320)
# Feet well above the region (radius 64): the player falls into it.
const ABOVE: Vector2i = Vector2i(320, 100)
# Feet inside the region, left of its center, so a 72 px dash to the right stays inside.
const INSIDE: Vector2i = Vector2i(270, 330)

var _player: Player


func test_a_region_entered_on_tick_n_gives_a_jump_on_n_plus_1_not_n() -> void:
	var n: int = _entry_tick()
	_setup_falling([_object("A", CENTER)])
	_run_until(n - 1)
	_tick(n, _jump_press())
	assert_eq(_events("jump").size(), 0, "no charged jump on the entry tick %d" % n)
	_tick(n + 1, _frame())
	assert_eq(_jump_ticks(), [n + 1], "the buffered press fires on N + 1")

	_setup_falling([_object("A", CENTER)])
	_run_until(n)
	_tick(n + 1, _jump_press())
	assert_eq(_jump_ticks(), [n + 1], "a press on N + 1 fires on N + 1")


func test_a_press_6_ticks_before_the_entry_tick_fires_and_7_does_not() -> void:
	var entry: int = _entry_tick() + 1
	_setup_falling([_object("A", CENTER)])
	_run_until(entry - 7)
	_tick(entry - 6, _jump_press())
	_run_until(entry)
	assert_eq(_jump_ticks(), [entry], "6 ticks before: fires on the entry tick")

	_setup_falling([_object("A", CENTER)])
	_run_until(entry - 8)
	_tick(entry - 7, _jump_press())
	_run_until(entry + 3)
	assert_eq(_jump_ticks(), [], "7 ticks before: nothing")
	assert_false(_player.jump_buffer.has_token(), "the token expired")


func test_a_press_on_the_dash_start_tick_never_cuts_the_dash() -> void:
	_setup_inside([_object("A", CENTER)])
	var frame: InputFrame = _jump_press()
	frame.dash_pressed = true
	frame.dash_held = true
	_tick(2, frame)
	_run_until(2 + Tuning.dash_ticks + 2)
	assert_eq(_jump_ticks(), [], "no jump from the start-tick press")
	var ends: Array[Dictionary] = _events("dash_end")
	assert_eq(ends.size(), 1, "one dash_end")
	if ends.size() == 1:
		assert_false(ends[0]["data"]["interrupted"], "the dash ran out")
		assert_eq(ends[0]["tick"], 2 + Tuning.dash_ticks - 1, "on its last active tick")
	assert_true(_player.charged[0].tracker.is_armed(), "the region is still armed")


func test_jump_and_dash_on_one_tick_with_no_dash_give_the_charged_jump_then_the_dash() -> void:
	_setup_inside([_object("A", CENTER)])
	_player.dash.charges = 0
	var frame: InputFrame = _jump_press()
	frame.dash_pressed = true
	frame.dash_held = true
	_tick(2, frame)
	_tick(3, _frame())
	assert_eq(_jump_ticks(), [2], "charged jump on the press tick")
	assert_eq(_ticks_of("dash_refill"), [2], "refilled by the charged jump")
	assert_eq(_events("dash_refill")[0]["data"]["cause"], "charged")
	assert_eq(_ticks_of("dash_start"), [3], "the waiting dash fires on the next tick")


func test_one_charged_jump_spends_every_overlapping_region() -> void:
	# A is farther from the body than B; the jump is logged against the nearer B.
	_setup_inside([_object("A", INSIDE + Vector2i(40, 0)), _object("B", INSIDE + Vector2i(0, 10))])
	_tick(2, _jump_press())
	var spent: Array[String] = []
	for e: Dictionary in _events("encounter"):
		if e["tick"] == 2 and e["data"]["to"] == "spent":
			spent.append(e["data"]["object"])
	assert_eq(spent, ["A", "B"], "both spent, in node-name order")
	var jumps: Array[Dictionary] = _events("jump")
	assert_eq(jumps.size(), 1, "one jump")
	if jumps.size() == 1:
		assert_eq(jumps[0]["data"]["object"], "B", "logged against the nearest")
	_run_until(10, _jump_press())
	assert_eq(_events("jump").size(), 1, "fresh presses inside give nothing more")


func test_launch_speed_and_kept_horizontal_speed() -> void:
	_setup_inside([_object("A", CENTER)])
	_player.mover.velocity_x = 123.0
	_tick(2, _jump_press())
	var jump: Dictionary = _events("jump")[0]["data"]
	assert_eq(jump["vy"], -Tuning.data.charged_launch_speed_px_s, "launch speed")
	assert_eq(jump["vx"], 123.0, "horizontal speed kept")


func test_no_charged_jump_in_default_or_from_an_unpowered_object() -> void:
	_setup_inside([_object("A", CENTER)])
	_player.step_switch(_switch_press())
	_tick(2, _jump_press())
	assert_eq(_jump_ticks(), [], "default state")

	var unpowered: ChargedObject = _object("A", CENTER, false)
	_setup_inside([unpowered])
	_tick(2, _jump_press())
	assert_eq(_jump_ticks(), [], "unpowered")
	assert_true(unpowered.tracker.is_armed(), "armed all the same")


func test_the_exit_margin_keeps_a_region_armed_on_its_boundary() -> void:
	Trace.begin_session(true)
	var object: ChargedObject = _object("A", Vector2i.ZERO)
	object.region_radius_px = 10
	var margin: int = Tuning.data.charged_exit_margin_px
	object.sense(Rect2i(9, -2, 4, 4), margin)
	assert_true(object.tracker.is_armed(), "entered at distance 9")
	object.sense(Rect2i(10, -2, 4, 4), margin)
	assert_true(object.tracker.is_armed(), "still inside at distance 10")
	object.sense(Rect2i(10 + margin, -2, 4, 4), margin)
	assert_eq(object.tracker.state, EncounterTracker.State.OUTSIDE, "left past the margin")
	assert_eq(_events("encounter").size(), 2, "armed, then outside")


# The tick on which a player falling from ABOVE first arms the region (step 7).
func _entry_tick() -> int:
	_setup_falling([_object("A", CENTER)])
	for t: int in range(2, 120):
		_tick(t, _frame())
		var armed: Array[Dictionary] = _events("encounter")
		if armed.size() > 0:
			return armed[0]["tick"]
	assert_true(false, "the falling player never entered the region")
	return -1


# A player at ABOVE in flow (switched on tick 1) with [param objects] and an empty trace.
func _setup_falling(objects: Array[ChargedObject]) -> void:
	_setup(ABOVE, objects)


# A player at INSIDE in flow (switched on tick 1) whose regions are already armed.
func _setup_inside(objects: Array[ChargedObject]) -> void:
	_setup(INSIDE, objects)


func _setup(feet: Vector2i, objects: Array[ChargedObject]) -> void:
	_player = add_node(PLAYER_SCENE.instantiate()) as Player
	_player.respawn(feet, SolidGrid.new(ROOM), 1, objects)
	_tick(1, _switch_press())
	Trace.begin_session(true)
	Trace.tick = 1


func _object(object_name: String, center: Vector2i, powered: bool = true) -> ChargedObject:
	var object: ChargedObject = OBJECT_SCENE.instantiate() as ChargedObject
	object.name = object_name
	object.position = Vector2(center)
	object.always_powered = powered
	return add_node(object) as ChargedObject


# One tick of World's steps 1–9 on the player.
func _tick(t: int, frame: InputFrame) -> void:
	Trace.tick = t
	_player.jump_buffer.expire(t)
	_player.dash_buffer.expire(t)
	if frame.jump_pressed:
		_player.jump_buffer.press(t)
	if frame.dash_pressed:
		_player.dash_buffer.press(t)
	_player.step_switch(frame)
	_player.step_dash(frame, t)
	_player.step_jump(frame, t)
	_player.step_integrate(frame)
	_player.step_move()
	_player.step_sense()
	_player.step_timers()


# Runs empty ticks after the current one up to and including [param last].
func _run_until(last: int, frame: InputFrame = null) -> void:
	for t: int in range(Trace.tick + 1, last + 1):
		_tick(t, frame if frame != null else _frame())


func _frame() -> InputFrame:
	return InputFrame.new()


func _jump_press() -> InputFrame:
	var frame: InputFrame = InputFrame.new()
	frame.jump_pressed = true
	frame.jump_held = true
	return frame


func _switch_press() -> InputFrame:
	var frame: InputFrame = InputFrame.new()
	frame.switch_pressed = true
	frame.switch_held = true
	return frame


func _jump_ticks() -> Array[int]:
	return _ticks_of("jump")


func _ticks_of(event_name: String) -> Array[int]:
	var ticks: Array[int] = []
	for e: Dictionary in _events(event_name):
		ticks.append(e["tick"])
	return ticks


func _events(event_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for e: Dictionary in Trace.get_events():
		if e["event"] == event_name:
			found.append(e)
	return found
