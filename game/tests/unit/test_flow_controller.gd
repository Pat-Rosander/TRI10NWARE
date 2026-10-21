# Tests the flow wiring in the real player scene: switch cost and refusal, the platform family
# flip, coyote start when the floor vanishes, countdown death on the 180th tick, and no change to
# position, velocity or an active dash. Stands in for s01–s04 until their scenarios run.
# Serves AC S-01, S-02, S-03, S-04.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const COUNTDOWN: int = 180
# A 20 × 10 tile room: an ordinary floor under columns 0–9 and a default-only platform under
# columns 12–19, both with their tops at y = 144.
const ROOM: Rect2i = Rect2i(0, 0, 320, 160)
const ON_FLOOR: Vector2i = Vector2i(40, 144)
const ON_PLATFORM: Vector2i = Vector2i(240, 144)


func test_entering_flow_costs_one_volt_and_leaving_costs_none() -> void:
	var player: Player = _player(ON_FLOOR)
	player.step_switch(_press())
	assert_true(player.flow.is_flow(), "in flow")
	assert_eq(player.flow.ledger.volts, 2)
	assert_eq(_event_names(), ["switch", "volts"])
	Trace.begin_session(true)
	player.step_switch(_press())
	assert_false(player.flow.is_flow(), "back in default")
	assert_eq(player.flow.ledger.volts, 2)
	assert_eq(_event_names(), ["switch"])


func test_holding_switch_without_a_fresh_press_does_nothing() -> void:
	var player: Player = _player(ON_FLOOR)
	var frame: InputFrame = InputFrame.new()
	frame.switch_held = true
	for i: int in 10:
		player.step_switch(frame)
	assert_false(player.flow.is_flow(), "still default")
	assert_eq(player.flow.ledger.volts, 3)
	assert_eq(_event_names(), [])


func test_flow_entry_at_zero_volts_is_refused_without_touching_the_countdown() -> void:
	var player: Player = _player(ON_FLOOR)
	_spend_every_volt(player)
	player.step_switch(_press())
	assert_false(player.flow.is_flow(), "default, countdown running")
	player.step_timers()
	var left: int = player.flow.ledger.countdown_ticks_left
	Trace.begin_session(true)
	player.step_switch(_press())
	assert_false(player.flow.is_flow(), "still default")
	assert_eq(player.flow.ledger.volts, 0)
	assert_eq(player.flow.ledger.countdown_ticks_left, left, "countdown unchanged")
	assert_eq(_event_names(), ["switch_refused"])


func test_the_solid_platform_family_follows_the_state() -> void:
	var player: Player = _player(ON_PLATFORM)
	assert_true(player.mover.is_grounded(), "default-only top is solid in default")
	player.step_switch(_press())
	assert_false(player.mover.is_grounded(), "and open in flow")
	player.step_switch(_press())
	assert_true(player.mover.is_grounded(), "and solid again in default")


func test_coyote_starts_when_the_floor_vanishes() -> void:
	var player: Player = _player(ON_PLATFORM)
	player.state.coyote_ticks = 0
	player.step_switch(_press())
	assert_false(player.state.grounded, "airborne at once")
	assert_eq(player.state.coyote_ticks, Tuning.coyote_ticks, "coyote window")
	# The switch tick is the first airborne decision tick: a coyote jump fires on it.
	player.jump_buffer.press(1)
	Trace.begin_session(true)
	player.step_jump(InputFrame.new(), 1)
	var jumps: Array[Dictionary] = _events("jump")
	assert_eq(jumps.size(), 1, "one jump")
	if jumps.size() == 1:
		assert_eq(jumps[0]["data"]["kind"], "coyote")


func test_a_switch_on_an_ordinary_floor_stays_grounded() -> void:
	var player: Player = _player(ON_FLOOR)
	player.step_switch(_press())
	assert_true(player.state.grounded, "grounded")
	assert_eq(player.state.coyote_ticks, Tuning.coyote_ticks)


func test_the_countdown_kills_on_its_180th_tick_once() -> void:
	var player: Player = _player(ON_FLOOR)
	_spend_every_volt(player)
	assert_eq(_events("countdown_start").size(), 1, "countdown started")
	# The switch was step 2 of tick 1; step 9 of the same tick counts tick 1.
	for t: int in range(1, COUNTDOWN):
		player.step_timers()
		assert_false(player.flow.countdown_expired, "alive on tick %d" % t)
	player.step_timers()
	assert_true(player.flow.countdown_expired, "dead on tick %d" % COUNTDOWN)
	for t: int in 30:
		player.step_timers()
	assert_eq(_events("countdown_expire").size(), 1, "expires exactly once")


func test_a_switch_leaves_position_velocity_and_an_active_dash_alone() -> void:
	var player: Player = _player(ON_FLOOR)
	player.mover.position = Vector2i(60, 100)
	player.state.grounded = false
	player.dash.start(Vector2i(1, -1), 1, 1)
	player.mover.velocity_x = 123.5
	player.mover.velocity_y = -40.25
	for i: int in 2:
		player.step_switch(_press())
		assert_eq(player.mover.position, Vector2i(60, 100), "position, switch %d" % i)
		assert_eq(player.mover.velocity_x, 123.5, "vx, switch %d" % i)
		assert_eq(player.mover.velocity_y, -40.25, "vy, switch %d" % i)
		assert_true(player.dash.is_active(), "dash active, switch %d" % i)
		assert_eq(player.dash.active_ticks, Tuning.dash_ticks, "dash ticks, switch %d" % i)
		assert_eq(player.dash.direction, Vector2i(1, -1), "dash direction, switch %d" % i)
	assert_eq(_events("jump").size() + _events("dash_start").size(), 0, "no jump or dash")


func test_respawn_replaces_the_ledger() -> void:
	var player: Player = _player(ON_PLATFORM)
	_spend_every_volt(player)
	var old: FlowLedger = player.flow.ledger
	player.respawn(ON_PLATFORM, player.mover.grid)
	assert_true(player.flow.ledger != old, "a new ledger")
	assert_false(player.flow.is_flow(), "default")
	assert_eq(player.flow.ledger.volts, 3)
	assert_false(player.flow.ledger.countdown_running(), "no countdown")
	assert_false(player.flow.countdown_expired, "not expired")
	assert_true(player.mover.is_grounded(), "default family solid again")


# A player standing at [param feet] in a fresh test room, with an empty trace.
func _player(feet: Vector2i) -> Player:
	var grid: SolidGrid = _new_grid(ROOM)
	for x: int in 10:
		grid.set_cell(Vector2i(x, 9), SolidGrid.ORDINARY)
	for x: int in range(12, 20):
		grid.set_cell(Vector2i(x, 9), SolidGrid.DEFAULT_ONLY)
	var player: Player = add_node(PLAYER_SCENE.instantiate()) as Player
	player.respawn(feet, grid)
	Trace.begin_session(true)
	return player


# Three entries into flow and two returns: ends in flow at 0 volts with the countdown started.
func _spend_every_volt(player: Player) -> void:
	for i: int in 5:
		player.step_switch(_press())


func _press() -> InputFrame:
	var frame: InputFrame = InputFrame.new()
	frame.switch_pressed = true
	frame.switch_held = true
	return frame


func _event_names() -> Array[String]:
	var names: Array[String] = []
	for e: Dictionary in Trace.get_events():
		names.append(e["event"])
	return names


func _events(event_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for e: Dictionary in Trace.get_events():
		if e["event"] == event_name:
			found.append(e)
	return found


# A grid for [param room] with the spike hitbox from tuning.
func _new_grid(room: Rect2i) -> SolidGrid:
	return SolidGrid.new(room, Tuning.data.spike_depth_px, Tuning.data.spike_inset_px)
