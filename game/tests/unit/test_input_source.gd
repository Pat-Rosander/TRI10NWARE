# Tests the shared input rules through ScriptedInputSource and synthetic events fed to
# LiveInputSource, plus stick snapping. Serves AC M-03, M-07, R-01, R-04.
extends TestCase


# --- Scripted source ---

func test_scripted_press_on_its_tick_without_repeat() -> void:
	var source: ScriptedInputSource = _scripted([{"tick": 2, "press": "jump"}])
	assert_false(source.read(1).jump_pressed, "tick 1")
	var frame: InputFrame = source.read(2)
	assert_true(frame.jump_pressed, "pressed on tick 2")
	assert_true(frame.jump_held, "held on tick 2")
	frame = source.read(3)
	assert_false(frame.jump_pressed, "no repeat on tick 3")
	assert_true(frame.jump_held, "still held on tick 3")


func test_scripted_release() -> void:
	var source: ScriptedInputSource = _scripted([
			{"tick": 0, "press": "dash"}, {"tick": 3, "release": "dash"}])
	assert_true(source.read(2).dash_held, "held on tick 2")
	assert_false(source.read(3).dash_held, "released on tick 3")


func test_scripted_press_and_release_on_one_tick_is_one_press() -> void:
	var source: ScriptedInputSource = _scripted([
			{"tick": 1, "press": "switch"}, {"tick": 1, "release": "switch"}])
	var frame: InputFrame = source.read(1)
	assert_true(frame.switch_pressed, "pressed")
	assert_false(frame.switch_held, "not held")
	assert_false(source.read(2).switch_pressed, "reported once")


func test_scripted_skipped_tick_still_applied() -> void:
	var source: ScriptedInputSource = _scripted([{"tick": 3, "press": "jump"}])
	source.read(1)
	assert_true(source.read(5).jump_pressed, "entry for tick 3 applied on tick 5")


func test_scripted_most_recent_direction_wins() -> void:
	var source: ScriptedInputSource = _scripted([
			{"tick": 0, "press": "move_left"}, {"tick": 1, "press": "move_right"},
			{"tick": 2, "release": "move_right"},
			{"tick": 3, "press": "move_down"}, {"tick": 4, "press": "move_up"},
			{"tick": 5, "release": "move_up"}])
	assert_eq(source.read(0).direction, Vector2i(-1, 0), "left")
	assert_eq(source.read(1).direction, Vector2i(1, 0), "right pressed later wins")
	assert_eq(source.read(2).direction, Vector2i(-1, 0), "falls back to left")
	assert_eq(source.read(3).direction, Vector2i(-1, 1), "left and down")
	assert_eq(source.read(4).direction, Vector2i(-1, -1), "up pressed later wins")
	assert_eq(source.read(5).direction, Vector2i(-1, 1), "falls back to down")


func test_scripted_stale_until_release() -> void:
	var source: ScriptedInputSource = _scripted([
			{"tick": 0, "press": "jump"}, {"tick": 2, "release": "jump"},
			{"tick": 3, "press": "jump"}])
	assert_true(source.read(0).jump_pressed)
	source.mark_all_stale()
	var frame: InputFrame = source.read(1)
	assert_false(frame.jump_held, "stale: not held")
	assert_false(frame.jump_pressed, "stale: not pressed")
	source.read(2)
	frame = source.read(3)
	assert_true(frame.jump_pressed, "fresh press after release")
	assert_true(frame.jump_held, "held after release and press")


func test_scripted_directions_never_stale() -> void:
	var source: ScriptedInputSource = _scripted([{"tick": 0, "press": "move_right"}])
	source.read(0)
	source.mark_all_stale()
	assert_eq(source.read(1).direction, Vector2i(1, 0))


func test_scripted_play_resets() -> void:
	var source: ScriptedInputSource = _scripted([
			{"tick": 0, "press": "jump"}, {"tick": 0, "press": "move_left"}])
	source.read(0)
	source.play([])
	var frame: InputFrame = source.read(1)
	assert_false(frame.jump_held, "jump forgotten")
	assert_eq(frame.direction, Vector2i.ZERO, "direction forgotten")


func test_scripted_start_tick_offset() -> void:
	var source: ScriptedInputSource = _scripted([{"tick": 2, "press": "jump"}], 10)
	assert_false(source.read(11).jump_pressed, "tick 11")
	assert_true(source.read(12).jump_pressed, "tick 12 = start 10 + 2")


func test_scripted_rejects_malformed_entries() -> void:
	var source: ScriptedInputSource = _scripted([
			{"tick": 0},
			{"tick": 0, "press": "jump", "release": "jump"},
			{"tick": "0", "press": "jump"},
			{"tick": 0, "press": "fly"},
			5])
	assert_eq(take_errors().size(), 5, "one error per bad entry")
	var frame: InputFrame = source.read(0)
	assert_false(frame.jump_held, "nothing applied")


# --- Live source, fed synthetic key events ---

func test_live_echo_ignored() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_SPACE, true)
	assert_true(source.read(0).jump_pressed)
	_key(source, KEY_SPACE, true, true)
	var frame: InputFrame = source.read(1)
	assert_false(frame.jump_pressed, "echo is not a press")
	assert_true(frame.jump_held, "still held")


func test_live_two_keys_on_one_action() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_SPACE, true)
	assert_true(source.read(0).jump_pressed, "Space presses jump")
	_key(source, KEY_C, true)
	assert_false(source.read(1).jump_pressed, "C while Space is down is no second press")
	_key(source, KEY_SPACE, false)
	assert_true(source.read(2).jump_held, "C still holds jump")
	_key(source, KEY_C, false)
	assert_false(source.read(3).jump_held, "released when both are up")


func test_live_two_taps_in_one_frame_is_one_press() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_X, true)
	_key(source, KEY_X, false)
	_key(source, KEY_X, true)
	_key(source, KEY_X, false)
	var frame: InputFrame = source.read(0)
	assert_true(frame.dash_pressed, "pressed")
	assert_false(frame.dash_held, "not held")
	assert_false(source.read(1).dash_pressed, "reported once")


func test_live_arrows_and_wasd_mixed() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_LEFT, true)
	_key(source, KEY_D, true)
	assert_eq(source.read(0).direction, Vector2i(1, 0), "D pressed after Left wins")
	_key(source, KEY_D, false)
	assert_eq(source.read(1).direction, Vector2i(-1, 0), "falls back to Left")
	_key(source, KEY_W, true)
	_key(source, KEY_DOWN, true)
	assert_eq(source.read(2).direction, Vector2i(-1, 1), "Down pressed after W wins")


func test_live_mark_all_stale_discards_unread_press() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_SPACE, true)
	source.mark_all_stale()
	var frame: InputFrame = source.read(0)
	assert_false(frame.jump_pressed, "unread press discarded")
	assert_false(frame.jump_held, "stale")
	_key(source, KEY_SPACE, false)
	_key(source, KEY_SPACE, true)
	assert_true(source.read(1).jump_pressed, "fresh press after release")


func test_live_focus_loss_releases_everything() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_SPACE, true)
	_key(source, KEY_RIGHT, true)
	source.read(0)
	source.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var frame: InputFrame = source.read(1)
	assert_false(frame.jump_held, "jump released")
	assert_eq(frame.direction, Vector2i.ZERO, "direction released")
	_key(source, KEY_SPACE, true)
	assert_true(source.read(2).jump_pressed, "next press counts")


func test_live_unbound_key_ignored() -> void:
	var source: LiveInputSource = _live()
	_key(source, KEY_Q, true)
	var frame: InputFrame = source.read(0)
	assert_false(frame.jump_pressed or frame.dash_pressed or frame.switch_pressed, "no press")
	assert_eq(frame.direction, Vector2i.ZERO, "no direction")


func test_live_runs_while_paused_and_reads_deadzone() -> void:
	var source: LiveInputSource = _live()
	assert_eq(source.process_mode, Node.PROCESS_MODE_ALWAYS, "process mode")
	assert_eq(source._deadzone, Tuning.data.stick_deadzone, "deadzone from Tuning")


func test_live_digital_beats_stick() -> void:
	var source: LiveInputSource = _live()
	Input.action_press(&"move_right", 0.9)
	assert_eq(source.read(0).direction, Vector2i(1, 0), "stick alone")
	_key(source, KEY_LEFT, true)
	assert_eq(source.read(1).direction, Vector2i(-1, 0), "key beats stick")
	_key(source, KEY_LEFT, false)
	assert_eq(source.read(2).direction, Vector2i(1, 0), "stick again once the key is up")
	Input.action_release(&"move_right")


# --- Stick snapping ---

func test_snap_to_eight_equal_sectors() -> void:
	# tan 22.5° ≈ 0.4142: 0.40 is just inside an axis sector, 0.43 just inside a diagonal one.
	for sx: int in [-1, 1]:
		for sy: int in [-1, 1]:
			_check_snap(Vector2(sx, 0), Vector2i(sx, 0))
			_check_snap(Vector2(0, sy), Vector2i(0, sy))
			_check_snap(Vector2(sx, sy * 0.40), Vector2i(sx, 0))
			_check_snap(Vector2(sx, sy * 0.43), Vector2i(sx, sy))
			_check_snap(Vector2(sx * 0.40, sy), Vector2i(0, sy))
			_check_snap(Vector2(sx * 0.43, sy), Vector2i(sx, sy))
			_check_snap(Vector2(sx, sy), Vector2i(sx, sy))


func test_snap_round_deadzone() -> void:
	_check_snap(Vector2(0.19, 0.0), Vector2i.ZERO)
	_check_snap(Vector2(0.21, 0.0), Vector2i(1, 0))
	_check_snap(Vector2(-0.14, 0.14), Vector2i.ZERO)
	_check_snap(Vector2(-0.15, 0.15), Vector2i(-1, 1))


func _check_snap(raw: Vector2, expected: Vector2i) -> void:
	assert_eq(LiveInputSource.snap_stick(raw, 0.2), expected, "stick %s" % raw)


func _scripted(entries: Array, start_tick: int = 0) -> ScriptedInputSource:
	var source: ScriptedInputSource = add_node(ScriptedInputSource.new())
	source.play(entries, start_tick)
	return source


func _live() -> LiveInputSource:
	return add_node(LiveInputSource.new())


func _key(source: LiveInputSource, keycode: Key, pressed: bool, echo: bool = false) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	source._input(event)
