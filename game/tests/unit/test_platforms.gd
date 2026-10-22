# Tests platform families and the overlap policy in the real player scene: the state matrix,
# one-way support, support changes on a switch, snaps (a landing on the switch tick, logged once),
# pending tiles and their clearing, and a switch back cancelling them. Stands in for p01–p04 until
# their scenarios run. Serves AC P-01, P-02, P-03, P-04.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const T: int = SolidGrid.TILE_PX
# A 30 × 12 tile room: an ordinary floor along row 11 (top y = 176), a default-only platform in
# row 8 at columns 2–5 and a flow-only one at columns 8–11 (tops y = 128), and a second flow-only
# platform in row 10 under columns 9–10 (top y = 160).
const ROOM: Rect2i = Rect2i(0, 0, 480, 192)
const TOP: int = 128
const ON_FLOOR: Vector2i = Vector2i(400, 176)
const ON_DEFAULT: Vector2i = Vector2i(48, TOP)
const ON_FLOW: Vector2i = Vector2i(160, TOP)
# The flow-only tiles a 12 px body with its feet at x = 160 overlaps in row 8.
const FLOW_TILES: Array = [[9, 8], [10, 8]]


func test_the_state_matrix() -> void:
	var player: Player = _player(ON_FLOOR)
	for feet: Vector2i in [ON_FLOOR, ON_DEFAULT, ON_FLOW]:
		player.mover.position = feet
		assert_eq(player.mover.is_grounded(), feet != ON_FLOW, "default state, feet %s" % feet)
	player.step_switch(_press())
	for feet: Vector2i in [ON_FLOOR, ON_DEFAULT, ON_FLOW]:
		player.mover.position = feet
		assert_eq(player.mover.is_grounded(), feet != ON_DEFAULT, "flow state, feet %s" % feet)


func test_a_platform_is_passed_from_below_and_from_the_side() -> void:
	var player: Player = _player(Vector2i(48, 170))
	player.mover.velocity_y = -400.0
	for i: int in 8:
		player.step_move()
		assert_false(player.mover.ceiling_hit, "no ceiling, tick %d" % i)
	assert_true(player.mover.position.y < TOP, "rose through the default-only platform")
	# Inside the platform row, moving right across all four tiles: never a wall.
	player.mover.position = Vector2i(16, TOP + 8)
	player.mover.velocity_y = 0.0
	player.mover.velocity_x = 480.0
	for i: int in 12:
		player.step_move()
		assert_eq(player.mover.wall_hit, 0, "no wall, tick %d" % i)
		player.mover.velocity_y = 0.0
	assert_true(player.mover.position.x > 6 * T, "crossed the platform")
	player.mover.position = Vector2i(2 * T - 7, TOP + 8)
	assert_false(player.mover.wall_at(1), "a platform's side is not a wall")


func test_switching_off_a_flow_platform_starts_coyote() -> void:
	var player: Player = _player(ON_FLOW)
	player.step_switch(_press())
	player.state.grounded = player.mover.is_grounded()
	assert_true(player.state.grounded, "standing on the flow-only platform in flow")
	player.state.coyote_ticks = 0
	player.step_switch(_press())
	assert_false(player.state.grounded, "airborne at once")
	assert_eq(player.state.coyote_ticks, Tuning.coyote_ticks, "coyote window")


func test_a_shallow_falling_switch_snaps_onto_the_top_as_a_landing() -> void:
	var snap: int = Tuning.data.overlap_snap_px
	var player: Player = _airborne(Vector2i(160, TOP + snap), 100.0)
	player.step_switch(_press())
	assert_eq(player.mover.position, ON_FLOW, "snapped onto the top")
	assert_eq(player.mover.velocity_y, 0.0, "vertical speed 0")
	assert_true(player.state.grounded, "grounded on the switch tick")
	assert_eq(_event_names(), ["switch", "volts", "overlap_snap", "platform_solid", "land"])
	assert_eq(_events("overlap_snap")[0]["data"], {"family": "flow", "dy": -snap})
	assert_eq(_events("platform_solid")[0]["data"], {"family": "flow", "tiles": []})
	assert_eq(_events("land")[0]["data"]["vy_before"], 100.0)
	assert_eq(player.mover.grid.pending_cells().size(), 0, "nothing pending")
	# The switch tick is the landing tick: a jump on it is a ground jump.
	player.jump_buffer.press(1)
	player.step_jump(InputFrame.new(), 1)
	var jumps: Array[Dictionary] = _events("jump")
	assert_eq(jumps.size(), 1, "one jump")
	if jumps.size() == 1:
		assert_eq(jumps[0]["data"]["kind"], "ground")


func test_a_snap_logs_land_once_on_its_tick() -> void:
	var player: Player = _airborne(Vector2i(160, TOP + 3), 100.0)
	var frame: InputFrame = _press()
	player.step_switch(frame)
	player.step_dash(frame, 1)
	player.step_jump(frame, 1)
	player.step_integrate(frame)
	player.step_move()
	player.step_sense()
	assert_eq(_events("land").size(), 1, "land from step 2 only; step 7 adds none")
	assert_true(player.state.grounded, "still grounded after step 7")


func test_one_pixel_past_the_snap_distance_waits() -> void:
	var player: Player = _airborne(Vector2i(160, TOP + Tuning.data.overlap_snap_px + 1), 100.0)
	player.step_switch(_press())
	assert_eq(player.mover.position, Vector2i(160, TOP + Tuning.data.overlap_snap_px + 1),
			"not moved")
	assert_false(player.state.grounded, "airborne")
	assert_eq(_event_names(), ["switch", "volts", "platform_pending"])
	assert_eq(_events("platform_pending")[0]["data"], {"family": "flow", "tiles": FLOW_TILES})


func test_a_rising_body_never_snaps() -> void:
	var player: Player = _airborne(Vector2i(160, TOP + 3), -50.0)
	player.step_switch(_press())
	assert_eq(player.mover.position, Vector2i(160, TOP + 3), "not moved")
	assert_eq(_event_names(), ["switch", "volts", "platform_pending"])


func test_no_snap_under_a_low_ceiling() -> void:
	# With a 15 px body the only ceiling that blocks the snap is one the body is already inside;
	# the policy still refuses to snap into it.
	var player: Player = _airborne(Vector2i(160, TOP + 3), 100.0)
	player.mover.grid.set_cell(Vector2i(9, 7), SolidGrid.ORDINARY)
	player.step_switch(_press())
	assert_eq(player.mover.position, Vector2i(160, TOP + 3), "not moved")
	assert_eq(_event_names(), ["switch", "volts", "platform_pending"])


func test_a_pending_tile_gets_no_help_and_turns_solid_once_cleared() -> void:
	# Rising slowly 7 px into the flow-only platform: the one-way help would lift a solid top.
	var player: Player = _airborne(Vector2i(160, TOP + 7), -50.0)
	player.step_switch(_press())
	assert_eq(player.mover.grid.pending_cells().size(), 2, "both tiles pending")
	player.step_sense()
	assert_eq(_events("assist").size(), 0, "no one-way help onto a pending tile")
	assert_eq(_events("platform_solid").size(), 0, "still overlapped")
	# The body rises clear of the row: the tiles turn solid, and a fall lands on them.
	player.mover.position = Vector2i(160, TOP - 1)
	player.step_sense()
	var solid: Array[Dictionary] = _events("platform_solid")
	assert_eq(solid.size(), 1, "released once")
	if solid.size() == 1:
		assert_eq(solid[0]["data"], {"family": "flow", "tiles": FLOW_TILES})
	player.mover.velocity_y = 100.0
	player.step_move()
	assert_eq(player.mover.position, ON_FLOW, "landed on the released tiles")


func test_a_pending_tile_never_lets_the_body_through_another_platform() -> void:
	# Falling 10 px into the row 8 platform: those tiles wait, but row 10's are solid at once.
	var player: Player = _airborne(Vector2i(160, TOP + 10), 300.0)
	player.step_switch(_press())
	assert_eq(_event_names(), ["switch", "volts", "platform_pending"])
	var frame: InputFrame = InputFrame.new()
	for i: int in 30:
		player.step_integrate(frame)
		player.step_move()
		player.step_sense()
	assert_eq(player.mover.position, Vector2i(160, 160), "caught by the row 10 platform")
	assert_true(player.state.grounded, "grounded")
	assert_eq(player.mover.grid.pending_cells().size(), 0, "row 8 released once cleared")


func test_a_switch_back_cancels_pending_tiles() -> void:
	var player: Player = _airborne(Vector2i(160, TOP + 10), 100.0)
	player.step_switch(_press())
	assert_eq(player.mover.grid.pending_cells().size(), 2, "pending")
	player.step_switch(_press())
	assert_eq(player.mover.grid.pending_cells().size(), 0, "cancelled")
	assert_false(player.flow.is_flow(), "back in default")


func test_a_mid_dash_switch_moves_the_body_at_most_the_snap_distance() -> void:
	var snap: int = Tuning.data.overlap_snap_px
	for depth: int in range(1, 16):
		var feet: Vector2i = Vector2i(160, TOP + depth)
		var player: Player = _airborne(feet, 0.0)
		player.dash.start(Vector2i(1, 0), 1, 1)
		player.mover.velocity_x = Tuning.data.dash_speed_px_s
		player.step_switch(_press())
		var moved: Vector2i = player.mover.position - feet
		assert_eq(moved.x, 0, "never sideways, depth %d" % depth)
		assert_true(moved.y <= 0 and -moved.y <= snap, "at most the snap, depth %d" % depth)
		assert_eq(moved.y, -depth if depth <= snap else 0, "snap or wait, depth %d" % depth)
		assert_true(player.dash.is_active(), "the dash goes on, depth %d" % depth)
		var body: Rect2i = player.mover.body_rect(player.mover.position)
		assert_false(player.mover.grid.blocks(body), "never embedded, depth %d" % depth)
		free_nodes()


func test_no_platform_solid_when_the_room_has_none_of_the_family() -> void:
	var player: Player = _player(ON_FLOOR, false)
	player.step_switch(_press())
	assert_eq(_event_names(), ["switch", "volts"], "no flow-only tiles: nothing logged")


# A player with its feet at [param feet] in a fresh test room (with its platforms unless
# [param platforms] is false), grounded or not as sensed, with an empty trace.
func _player(feet: Vector2i, platforms: bool = true) -> Player:
	var grid: SolidGrid = SolidGrid.new(ROOM, Tuning.data.spike_depth_px,
			Tuning.data.spike_inset_px)
	for x: int in 30:
		grid.set_cell(Vector2i(x, 11), SolidGrid.ORDINARY)
	if platforms:
		for x: int in range(2, 6):
			grid.set_cell(Vector2i(x, 8), SolidGrid.DEFAULT_ONLY)
		for x: int in range(8, 12):
			grid.set_cell(Vector2i(x, 8), SolidGrid.FLOW_ONLY)
		for x: int in range(9, 11):
			grid.set_cell(Vector2i(x, 10), SolidGrid.FLOW_ONLY)
	var player: Player = add_node(PLAYER_SCENE.instantiate()) as Player
	player.respawn(feet, grid)
	Trace.begin_session(true)
	return player


# An airborne player in default with its feet at [param feet] and vertical speed [param vy].
func _airborne(feet: Vector2i, vy: float) -> Player:
	var player: Player = _player(feet)
	assert_false(player.state.grounded, "airborne at %s" % feet)
	player.mover.velocity_y = vy
	player.state.coyote_ticks = 0
	return player


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
