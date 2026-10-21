# Tests World's play states through a real World, player scene and Level 1 room: the title gate,
# the death freeze and respawn lock with their exact ticks, the reset after a death, restart,
# completion and replay; and that main.tscn wires the overlays. Stands in for r01 and r02, and for
# l1_04's retry case, until their scenarios run. Serves AC R-01, R-02, R-04, L1-04.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const CameraRigScript: GDScript = preload("res://world/camera_rig.gd")
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
const SURFACE_ROW: int = 15
const SURFACE_Y: int = SURFACE_ROW * 16

var _world: WorldScript
var _player: Player
var _input: ScriptedInputSource


func test_title_counts_no_ticks() -> void:
	_setup()
	assert_eq(_world.play_state, WorldScript.PlayState.TITLE, "starts on the title")
	assert_false(_world.ticks_run(), "no ticks on the title")
	_run(5)
	assert_eq(_world.tick, 0, "the title advances no tick")
	_world.start()
	_run(1)
	assert_eq(_world.tick, 1, "ticks count once started")
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING)


func test_death_freeze_then_respawn_lock_then_control() -> void:
	_setup()
	_world.start()
	_player.flow.countdown_expired = true
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING, "the death starts the freeze")
	_run_until_control()
	var death: int = _tick_of("death")
	assert_eq(_count("death"), 1, "death logged once")
	assert_eq(_events("death")[0]["data"]["cause"], "countdown")
	assert_eq(_tick_of("respawn") - death, Tuning.death_freeze_ticks, "rebuilt after the freeze")
	assert_eq(_tick_of("control_return") - _tick_of("respawn"), Tuning.respawn_ticks,
			"control returns after the respawn lock")
	assert_true(_tick_of("control_return") - death <= 60, "death to control within 1 s (R-02)")
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING)


func test_player_frozen_while_dying() -> void:
	_setup()
	_world.start()
	_player.flow.countdown_expired = true
	_run(1)
	var at_death: Vector2i = _player.mover.position
	_run(Tuning.death_freeze_ticks - 1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING, "still in the freeze")
	assert_eq(_player.mover.position, at_death, "the player does not move during the freeze")


func test_reset_after_death() -> void:
	_setup()
	_world.start()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 3, "release": "switch"}])
	_run(4)
	assert_true(_player.flow.is_flow(), "in flow before the death")
	_player.flow.countdown_expired = true
	_run(1)
	_run_until_control()
	assert_false(_player.flow.is_flow(), "default state")
	assert_eq(_player.flow.ledger.volts, Tuning.data.max_volts, "full volts")
	assert_false(_player.flow.ledger.countdown_running(), "no countdown")
	assert_eq(_player.dash.charges, 1, "dash charge 1")
	assert_eq(_player.dash.active_ticks, 0, "no dash active")
	assert_eq(_player.dash.cooldown_ticks_left, 0, "no cooldown")
	assert_eq(Vector2(_player.mover.velocity_x, _player.mover.velocity_y), Vector2.ZERO,
			"standing still")
	assert_eq(_world.checkpoint, &"start", "at the checkpoint entrance")


func test_jump_held_through_death_never_fires() -> void:
	_setup()
	_world.start()
	_player.flow.countdown_expired = true
	_input.play([{"tick": 1, "press": "jump"}])
	# The press fires a ground jump on the death tick itself (step 4 runs before step 10).
	_run(1)
	_run_until_control()
	_run(Tuning.jump_buffer_ticks + 2)
	assert_false(_world.frame.jump_held, "the held jump is stale after respawn")
	assert_false(_world.frame.jump_pressed, "and never pressed")
	var control: int = _tick_of("control_return")
	for entry: Dictionary in _events("jump"):
		assert_true(int(entry["tick"]) < control, "no jump fires after respawn")


func test_press_during_the_lock_is_ignored() -> void:
	_setup()
	_world.start()
	_player.flow.countdown_expired = true
	var press_at: int = 1 + Tuning.death_freeze_ticks + 3
	_input.play([{"tick": 3, "press": "dash"}, {"tick": 4, "release": "dash"},
			{"tick": press_at, "press": "jump"}, {"tick": press_at + 1, "release": "jump"}])
	_run(1)
	_run_until_control()
	_run(5)
	assert_eq(_count("press"), 0, "presses during the freeze and the lock make no token")
	assert_eq(_count("jump") + _count("dash_start"), 0, "and no action")


func test_restart_is_a_death_with_cause_restart() -> void:
	_setup()
	_world.start()
	_run(2)
	_world.restart_room()
	assert_eq(_world.play_state, WorldScript.PlayState.DYING, "restart starts the freeze")
	_world.restart_room()
	_run_until_control()
	assert_eq(_count("death"), 1, "a restart during the freeze is ignored")
	assert_eq(_events("death")[0]["data"]["cause"], "restart")
	assert_eq(_tick_of("control_return") - _tick_of("death"),
			Tuning.death_freeze_ticks + Tuning.respawn_ticks, "the same sequence as any death")


func test_completion_stops_ticks_until_replay() -> void:
	_setup()
	_world.start()
	_stand_on_goal()
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.COMPLETE, "the goal completes the room")
	assert_false(_world.ticks_run(), "no ticks on the completion screen")
	var done_tick: int = _world.tick
	_run(10)
	assert_eq(_world.tick, done_tick, "ticks stop")
	assert_eq(_count("room_complete"), 1, "room_complete logged once")
	_world.restart_room()
	assert_eq(_count("death"), 0, "no restart from the completion screen")
	var entered: int = _count("room_enter")
	_world.replay()
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING, "replay plays again")
	assert_eq(_count("room_enter"), entered + 1, "the room was rebuilt")
	assert_eq(_events("room_enter")[1]["data"]["entrance"], "start", "at its start")
	_run(1)
	assert_eq(_world.tick, done_tick + 1, "ticks resume")


func test_camera_follows_the_player_clamped_to_the_room() -> void:
	_setup()
	_world.start()
	_run(3)
	var camera: Camera2D = _world.get_node("Camera") as Camera2D
	var half: Vector2i = Vector2i(camera.get_viewport_rect().size) / 2
	var feet: Vector2i = _player.mover.position
	var expected: Vector2i = Vector2i(clampi(feet.x, half.x, ROOM.end.x - half.x),
			clampi(feet.y, half.y, ROOM.end.y - half.y))
	assert_eq(Vector2i(camera.position), expected, "centered on the player, clamped to the room")
	assert_false(camera.position_smoothing_enabled, "no smoothing")


func test_main_scene_wires_the_overlays() -> void:
	Trace.begin_session(true)
	var main: Node = add_node(MAIN_SCENE.instantiate())
	var world: WorldScript = main.get_node("World") as WorldScript
	var title: CanvasLayer = main.get_node("TitleOverlay") as CanvasLayer
	var pause: CanvasLayer = main.get_node("PauseMenu") as CanvasLayer
	var completion: CanvasLayer = main.get_node("CompletionOverlay") as CanvasLayer
	assert_true(title.visible, "the title shows at launch")
	assert_false(pause.visible, "the pause menu starts hidden")
	assert_false(completion.visible, "the completion overlay starts hidden")
	pause.call(&"open")
	assert_false(main.get_tree().paused, "no pause on the title")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	title.call(&"_unhandled_input", key)
	assert_false(title.visible, "a key hides the title")
	assert_eq(world.play_state, WorldScript.PlayState.PLAYING, "and starts play")
	pause.call(&"open")
	assert_true(main.get_tree().paused, "pause pauses the tree")
	assert_true(pause.visible)
	pause.call(&"resume")
	assert_false(main.get_tree().paused, "resume unpauses")
	Trace.record("room_complete", {"room": "level_1"})
	assert_true(completion.visible, "room_complete shows the completion overlay")


# A World with the start room loaded, its input from a ScriptedInputSource.
func _setup() -> void:
	Trace.begin_session(true)
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
	# The game starts in tutorial_1 (M6 step 2); these tests run in Level 1.
	_world.load_room(&"level_1", &"start")
	_input = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(_input)


# Moves the player onto a pillar built in code, under a goal zone covering its top.
func _stand_on_goal() -> void:
	var grid: SolidGrid = _new_grid(ROOM)
	for x: int in range(10, 15):
		for y: int in range(SURFACE_ROW, 23):
			grid.set_cell(Vector2i(x, y), SolidGrid.ORDINARY)
	var goal: GoalZone = GoalZone.new()
	goal.position = Vector2(160, SURFACE_Y)
	goal.width_px = 80
	add_node(goal)
	_world._goals = [goal]
	_player.respawn(Vector2i(200, SURFACE_Y), grid)


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


func _run_until_control() -> void:
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			return
		_run(1)


func _events(name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == name:
			found.append(entry)
	return found


func _count(name: String) -> int:
	return _events(name).size()


func _tick_of(name: String) -> int:
	var found: Array[Dictionary] = _events(name)
	return int(found[0]["tick"]) if not found.is_empty() else -1


# A grid for [param room] with the spike hitbox from tuning.
func _new_grid(room: Rect2i) -> SolidGrid:
	return SolidGrid.new(room, Tuning.data.spike_depth_px, Tuning.data.spike_inset_px)
