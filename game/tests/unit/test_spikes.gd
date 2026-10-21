# Tests spikes through a real World and player scene: standing on, walking into and dashing into
# spikes kills; grazing their tips does not; they kill in both states; step 10's order (goal, then
# spike, then countdown and fall); one `death` with cause `spike`, then the same reset as every
# death. Stands in for h01_spikes until it runs. Serves AC R-01, R-02.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const CameraRigScript: GDScript = preload("res://world/camera_rig.gd")
# A one-screen room with an ordinary floor on row 15 (its top at y 240).
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
const COLUMNS: int = 40
const FLOOR_ROW: int = 15
const FLOOR_Y: int = FLOOR_ROW * 16
# An up-pointing spike on the floor at column 10: its hitbox is x 162-173, y 234-239.
const FLOOR_SPIKE: Vector2i = Vector2i(10, FLOOR_ROW - 1)
# A right-pointing spike at column 21, against a wall at column 20: its hitbox is x 336-341,
# y 226-237.
const WALL_SPIKE: Vector2i = Vector2i(21, FLOOR_ROW - 1)

var _world: WorldScript
var _player: Player
var _input: ScriptedInputSource
var _grid: SolidGrid


func test_standing_on_a_spike_kills_on_the_first_tick() -> void:
	_setup(Vector2i(168, FLOOR_Y))
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING, "dies on the first tick")
	assert_eq(_count("death"), 1, "one death")
	assert_eq(_events("death")[0]["data"]["cause"], "spike")


func test_walking_into_a_spike_kills_at_the_first_overlap() -> void:
	_setup(Vector2i(120, FLOOR_Y))
	_input.play([{"tick": 1, "press": "move_right"}])
	_run_until_dead(60)
	assert_eq(_events("death")[0]["data"]["cause"], "spike")
	var body: Rect2i = _player.mover.body_rect(_player.mover.position)
	assert_true(_grid.touches_spike(body), "dies overlapping the hitbox")
	# A run step is at most 3 px (180 px/s), so the tick before it was still clear.
	var before: Rect2i = body
	before.position.x -= 3
	assert_false(_grid.touches_spike(before), "and not a tick late")


func test_dashing_into_a_spike_kills_mid_dash() -> void:
	_setup(Vector2i(120, FLOOR_Y))
	_input.play([{"tick": 1, "press": "move_right"}, {"tick": 1, "press": "dash"}])
	_run_until_dead(30)
	assert_eq(_events("death")[0]["data"]["cause"], "spike")
	assert_true(_player.dash.is_active(), "the dash was still running: no invulnerability")


func test_grazing_the_tips_does_not_kill() -> void:
	# Beside the wall spike, standing still. Feet at x 349 put the body's left edge at x 343,
	# 1 px into the tips (x 342-351): alive. At x 348 the left edge lies on the hitbox's edge:
	# still alive. At x 347 it is 1 px inside the hitbox: dead.
	_setup(Vector2i(349, FLOOR_Y))
	_run(10)
	assert_eq(_count("death"), 0, "the tips are harmless")
	_player.mover.position.x = 348
	_run(10)
	assert_eq(_count("death"), 0, "touching the hitbox's edge is harmless")
	_player.mover.position.x = 347
	_run(1)
	assert_eq(_count("death"), 1, "1 px into the hitbox: dead")


func test_spikes_kill_in_flow_too() -> void:
	_setup(Vector2i(120, FLOOR_Y))
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"},
			{"tick": 3, "press": "move_right"}])
	_run_until_dead(60)
	assert_true(_player.flow.is_flow(), "died in flow")
	assert_eq(_events("death")[0]["data"]["cause"], "spike")


func test_goal_beats_a_spike_and_a_spike_beats_the_countdown_and_a_fall() -> void:
	_setup(Vector2i(168, FLOOR_Y))
	_player.step_sense()
	_player.step_move()
	assert_true(_player.touched_spike(), "the move touched the spike")
	var goal: GoalZone = GoalZone.new()
	goal.position = Vector2(160, FLOOR_Y)
	goal.width_px = 32
	add_node(goal)
	var goals: Array[GoalZone] = [goal]
	var none: Array[GoalZone] = []
	assert_eq(WorldScript.outcome(_player, goals), WorldScript.Outcome.COMPLETE, "goal first")
	assert_eq(WorldScript.outcome(_player, none), WorldScript.Outcome.SPIKE, "then the spike")
	_player.flow.countdown_expired = true
	assert_eq(WorldScript.outcome(_player, none), WorldScript.Outcome.SPIKE, "before the countdown")
	_player.flow.countdown_expired = false
	_player.mover.position.y = ROOM.end.y + Tuning.data.fall_margin_px + 1
	assert_true(_player.fell(), "below the failure line")
	assert_eq(WorldScript.outcome(_player, none), WorldScript.Outcome.SPIKE, "before a fall")


func test_spike_death_resets_like_every_death() -> void:
	_setup(Vector2i(168, FLOOR_Y))
	_run(1)
	var death: int = _tick_of("death")
	_run_until_control()
	assert_eq(_count("death"), 1, "death logged once")
	assert_eq(_tick_of("respawn") - death, Tuning.death_freeze_ticks, "rebuilt after the freeze")
	assert_eq(_tick_of("control_return") - _tick_of("respawn"), Tuning.respawn_ticks,
			"control returns after the respawn lock")
	assert_eq(_world.checkpoint, &"start", "at the checkpoint entrance")
	assert_false(_player.flow.is_flow(), "default state")
	assert_eq(_player.flow.ledger.volts, Tuning.data.max_volts, "full volts")
	assert_eq(_player.dash.charges, 1, "dash charge 1")
	assert_false(_player.touched_spike(), "the rebuilt room's grid has no test spike")


# A World (with its start room loaded) whose player stands at [param feet] in the test room,
# started, with an empty trace and input from a ScriptedInputSource.
func _setup(feet: Vector2i) -> void:
	var node: Node2D = Node2D.new()
	node.set_script(WorldScript)
	var slot: Node2D = Node2D.new()
	slot.name = "RoomSlot"
	node.add_child(slot)
	var player: Node = PLAYER_SCENE.instantiate()
	player.name = "Player"
	node.add_child(player)
	var camera: Camera2D = Camera2D.new()
	camera.set_script(CameraRigScript)
	camera.name = "Camera"
	node.add_child(camera)
	_world = add_node(node) as WorldScript
	_player = player as Player
	_input = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(_input)
	_grid = SolidGrid.new(ROOM, Tuning.data.spike_depth_px, Tuning.data.spike_inset_px)
	for x: int in COLUMNS:
		_grid.set_cell(Vector2i(x, FLOOR_ROW), SolidGrid.ORDINARY)
	_grid.set_cell(FLOOR_SPIKE, SolidGrid.SPIKE_UP)
	for y: int in range(FLOOR_ROW - 4, FLOOR_ROW):
		_grid.set_cell(Vector2i(20, y), SolidGrid.ORDINARY)
	_grid.set_cell(WALL_SPIKE, SolidGrid.SPIKE_RIGHT)
	_player.respawn(feet, _grid)
	_world.start()
	Trace.begin_session(true)


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


func _run_until_dead(max_ticks: int) -> void:
	for i: int in max_ticks:
		if _world.play_state == WorldScript.PlayState.DYING:
			return
		_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING, "died within %d ticks" % max_ticks)


func _run_until_control() -> void:
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			return
		_run(1)


func _events(event_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == event_name:
			found.append(entry)
	return found


func _count(event_name: String) -> int:
	return _events(event_name).size()


func _tick_of(event_name: String) -> int:
	var found: Array[Dictionary] = _events(event_name)
	return int(found[0]["tick"]) if not found.is_empty() else -1
