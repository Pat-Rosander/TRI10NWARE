# Tests collectibles through a real World and player scene: touching in step 7, committing on a
# grounded tick without a death (including the touching tick), losing on a death (a spike death
# while grounded too, and a restart), the rebuilt room showing it again, a committed one hiding
# when its room is built, node-name order, and Level 1's collectible. Stands in for
# g02_permanent_progress until it runs; committing on a crossing arrives in M6 step 2.
# Serves AC G-02.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const CameraRigScript: GDScript = preload("res://world/camera_rig.gd")
const RoomScript: GDScript = preload("res://rooms/room.gd")
const LEVEL_1_ID: String = "level_1/Collectible"
# A one-screen room with an ordinary floor on row 15 (its top at y 240), as in test_spikes.
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
const COLUMNS: int = 40
const FLOOR_ROW: int = 15
const FLOOR_Y: int = FLOOR_ROW * 16
# An up-pointing spike on the floor at column 10 (hitbox x 162-173, y 234-239).
const FLOOR_SPIKE: Vector2i = Vector2i(10, FLOOR_ROW - 1)

var _world: WorldScript
var _player: Player
var _input: ScriptedInputSource


func test_touched_while_grounded_commits_on_the_same_tick() -> void:
	_setup(Vector2i(100, FLOOR_Y))
	var gem: Collectible = _collectible("Gem", Vector2i(100, FLOOR_Y - 8))
	_run(1)
	assert_eq(_changes(), ["touched", "committed"], "touched, then committed")
	assert_eq(_tick_of_change("committed"), _tick_of_change("touched"), "on the same tick")
	assert_true(GameState.is_committed("test/Gem"), "GameState holds it")
	assert_eq(gem.phase, Collectible.Phase.COMMITTED)
	assert_false(gem.visible, "a committed collectible disappears")
	GameState.reset()


func test_touched_in_the_air_commits_on_the_landing_tick() -> void:
	_setup(Vector2i(200, FLOOR_Y - 60))
	var gem: Collectible = _collectible("Gem", Vector2i(200, FLOOR_Y - 70))
	_run(1)
	assert_eq(_changes(), ["touched"], "touched in the air, not committed")
	assert_eq(gem.phase, Collectible.Phase.FOLLOWING, "it follows the player")
	for i: int in 60:
		if gem.phase != Collectible.Phase.FOLLOWING:
			break
		_run(1)
	assert_eq(_changes(), ["touched", "committed"])
	assert_eq(_tick_of_change("committed"), _tick_of("land"), "committed on the landing tick")
	assert_true(GameState.is_committed("test/Gem"))
	GameState.reset()


func test_a_death_while_carrying_loses_it_and_the_rebuilt_room_shows_it_again() -> void:
	# Level 1's own collectible, at (312, 72): the player touches it in the open air of the test
	# grid, then the countdown expires. The respawn rebuilds Level 1.
	_setup(Vector2i(312, 90))
	_world._collectibles = _world.get_node("RoomSlot").get_child(0).collectibles()
	var carried: Collectible = _world._collectibles[0]
	_run(1)
	assert_eq(_changes(), ["touched"], "touched in the air")
	_player.flow.countdown_expired = true
	_run(1)
	assert_eq(_changes(), ["touched", "lost"], "lost on the death")
	assert_eq(_tick_of_change("lost"), _tick_of("death"), "on the death tick")
	_run_until_control()
	assert_false(GameState.is_committed(LEVEL_1_ID), "never committed")
	assert_eq(_changes(), ["touched", "lost"], "no commit after the respawn either")
	var fresh: Collectible = _world._collectibles[0]
	assert_true(fresh != carried, "the rebuilt room has a fresh instance")
	assert_eq(fresh.id, LEVEL_1_ID)
	assert_eq(fresh.phase, Collectible.Phase.IDLE, "idle again")
	assert_true(fresh.visible, "shown again")


func test_a_spike_death_while_grounded_loses_it() -> void:
	_setup(Vector2i(168, FLOOR_Y))
	_collectible("Gem", Vector2i(168, FLOOR_Y - 8))
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING, "the spike kills")
	assert_true(_player.state.grounded, "grounded on the death tick")
	assert_eq(_changes(), ["touched", "lost"], "touched, then lost; never committed")
	assert_false(GameState.is_committed("test/Gem"))


func test_restarting_the_room_while_carrying_loses_it() -> void:
	_setup(Vector2i(200, FLOOR_Y - 60))
	_collectible("Gem", Vector2i(200, FLOOR_Y - 70))
	_run(1)
	_world.restart_room()
	assert_eq(_changes(), ["touched", "lost"])
	assert_eq(_events("death")[0]["data"]["cause"], "restart")
	assert_false(GameState.is_committed("test/Gem"))


func test_a_committed_collectible_hides_when_its_room_is_built() -> void:
	_setup(Vector2i(100, FLOOR_Y))
	GameState.commit(LEVEL_1_ID)
	_world.load_room(&"level_1", &"start")
	var gem: Collectible = _world._collectibles[0]
	assert_eq(gem.phase, Collectible.Phase.COMMITTED)
	assert_false(gem.visible, "hidden")
	assert_false(gem.overlaps(gem.rect()), "it can never be touched again")
	GameState.reset()


func test_collectibles_touched_on_one_tick_go_in_node_name_order() -> void:
	_setup(Vector2i(100, FLOOR_Y))
	var room: Node2D = Node2D.new()
	room.set_script(RoomScript)
	var holder: Node2D = Node2D.new()
	holder.name = "Collectibles"
	room.add_child(holder)
	for gem_name: String in ["GemB", "GemA"]:
		var gem: Collectible = Collectible.new()
		gem.name = gem_name
		gem.id = "test/" + gem_name
		gem.position = Vector2(100, FLOOR_Y - 8)
		holder.add_child(gem)
	add_node(room)
	_world._collectibles = (room as Room).collectibles()
	_run(1)
	var ids: Array[String] = []
	for entry: Dictionary in _events("collectible"):
		ids.append("%s %s" % [entry["data"]["id"], entry["data"]["change"]])
	assert_eq(ids, ["test/GemA touched", "test/GemB touched", "test/GemA committed",
			"test/GemB committed"], "node-name order in step 7 and in step 10")
	GameState.reset()


func test_level_1_collectible_sits_on_the_overhead_geometry() -> void:
	_setup(Vector2i(100, FLOOR_Y))
	_world.load_room(&"level_1", &"start")
	var room: Room = _world.get_node("RoomSlot").get_child(0) as Room
	var gems: Array[Collectible] = room.collectibles()
	assert_eq(gems.size(), 1, "one collectible")
	assert_eq(gems[0].id, LEVEL_1_ID)
	var charged: ChargedObject = room.charged_objects()[0]
	assert_eq(gems[0].position.x, charged.position.x, "straight above the charged object")
	assert_true(gems[0].position.y < charged.position.y, "above it")
	assert_eq(gems[0].phase, Collectible.Phase.IDLE)


# A World (with its start room loaded) whose player stands at [param feet] on the test grid's
# floor (with a spike at column 10), started, with no collectibles, fresh progress, an empty
# trace and input from a ScriptedInputSource.
func _setup(feet: Vector2i) -> void:
	GameState.reset()
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
	var grid: SolidGrid = SolidGrid.new(ROOM, Tuning.data.spike_depth_px,
			Tuning.data.spike_inset_px)
	for x: int in COLUMNS:
		grid.set_cell(Vector2i(x, FLOOR_ROW), SolidGrid.ORDINARY)
	grid.set_cell(FLOOR_SPIKE, SolidGrid.SPIKE_UP)
	_player.respawn(feet, grid)
	_world._collectibles = []
	_world.start()
	Trace.begin_session(true)


# A collectible named [param node_name] centered at [param center], the World's only one.
func _collectible(node_name: String, center: Vector2i) -> Collectible:
	var gem: Collectible = Collectible.new()
	gem.name = node_name
	gem.id = "test/" + node_name
	gem.position = Vector2(center)
	add_node(gem)
	_world._collectibles = [gem]
	return gem


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


func _run_until_control() -> void:
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			return
		_run(1)


# Every collectible change logged so far, in order.
func _changes() -> Array[String]:
	var found: Array[String] = []
	for entry: Dictionary in _events("collectible"):
		found.append(entry["data"]["change"])
	return found


func _tick_of_change(change: String) -> int:
	for entry: Dictionary in _events("collectible"):
		if entry["data"]["change"] == change:
			return entry["tick"]
	return -1


func _events(event_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == event_name:
			found.append(entry)
	return found


func _tick_of(event_name: String) -> int:
	var found: Array[Dictionary] = _events(event_name)
	return found[0]["tick"] if not found.is_empty() else -1
