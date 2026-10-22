# Tests power networks through a real World and player scene, tick by tick: no activation in
# default; activation in flow on the first tick the body overlaps the contact area (margin
# included) by walking, falling, jumping and dashing, and on the switch tick while overlapping;
# members powered, recharge and countdown cancel, other networks unchanged; no recharge farming;
# several roots on one tick recharging once; a recharge winning on the expiry tick; fresh networks
# unpowered and Level 1's object powered across a death; the room lookup and the editor warnings.
# Stands in for n01–n04 and s04's recharge cases until their scenarios run (M1.8).
# Serves AC N-01 to N-04, S-04.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const OBJECT_SCENE: PackedScene = preload("res://objects/charged_object/charged_object.tscn")
const ROOT_SCENE: PackedScene = preload("res://objects/power_root/power_root.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const CameraRigScript: GDScript = preload("res://world/camera_rig.gd")
const RoomScript: GDScript = preload("res://rooms/room.gd")
# A one-screen room with an ordinary floor on row 15 (its top at y 240), as in test_collectibles.
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
const COLUMNS: int = 40
const FLOOR_ROW: int = 15
const FLOOR_Y: int = FLOOR_ROW * 16
# Feet on the floor; the 12 px body spans x 94-105.
const START: Vector2i = Vector2i(100, FLOOR_Y)
# A root standing on the floor: art y 224-239.
const ROOT_Y: int = FLOOR_Y - 8

var _world: WorldScript
var _player: Player
var _input: ScriptedInputSource


# N-01: walking into a root in default never activates it.
func test_default_contact_does_not_activate() -> void:
	_setup(START)
	var network: Network = _network("A", Vector2i(160, ROOT_Y))
	_input.play([{"tick": 1, "press": "move_right"}])
	_run(90)
	assert_true(_player.mover.position.x > 200, "walked past the root")
	assert_eq(_events("network_activated").size(), 0, "no activation")
	assert_false(network.powered, "still unpowered")


# N-01: in flow, walking activates on the first tick the body overlaps the contact area.
func test_walking_in_flow_activates_on_the_first_overlap_tick() -> void:
	_setup(START)
	var network: Network = _network("A", Vector2i(160, ROOT_Y))
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 1, "press": "move_right"}])
	var first_overlap: int = _run_until_overlap(network, 90)
	assert_true(first_overlap > 1, "the body reached the contact area by walking")
	assert_eq(_tick_of("network_activated"), first_overlap, "activated on that very tick")
	assert_true(network.powered, "powered")


# N-01: the contact area is the art grown by root_contact_margin_px; edges touching is no overlap.
func test_the_margin_counts_and_touching_edges_do_not() -> void:
	var margin: int = Tuning.data.root_contact_margin_px
	# The body's right edge is x 105 (end 106); the art's left edge is root.x - 8.
	var reach: int = 106 + 8 + margin - 1
	_setup(START)
	var inside: Network = _network("A", Vector2i(reach, ROOT_Y))
	var art: Rect2i = inside.root().art_rect_px
	art.position += Vector2i(reach, ROOT_Y)
	assert_false(art.intersects(_body()), "the art alone does not reach the body")
	_input.play([{"tick": 1, "press": "switch"}])
	_run(1)
	assert_eq(_tick_of("network_activated"), 1, "inside the margin only: activates")

	_setup(START)
	var outside: Network = _network("A", Vector2i(reach + 1, ROOT_Y))
	_input.play([{"tick": 1, "press": "switch"}])
	_run(3)
	assert_eq(_events("network_activated").size(), 0, "contact edge on the body's edge: none")
	assert_false(outside.powered)


# N-01: switching into flow while already overlapping activates on the switch tick.
func test_switching_to_flow_while_overlapping_activates_that_tick() -> void:
	_setup(START)
	var network: Network = _network("A", START + Vector2i(0, -8))
	_input.play([{"tick": 3, "press": "switch"}])
	_run(2)
	assert_eq(_events("network_activated").size(), 0, "in default: nothing")
	_run(1)
	assert_eq(_tick_of("switch"), 3, "switched on tick 3")
	assert_eq(_tick_of("network_activated"), 3, "activated on tick 3")
	assert_true(network.powered)


# N-01: falling onto a root activates it.
func test_falling_onto_a_root_activates() -> void:
	_setup(Vector2i(200, FLOOR_Y - 100))
	var network: Network = _network("A", Vector2i(200, ROOT_Y))
	_input.play([{"tick": 1, "press": "switch"}])
	var first_overlap: int = _run_until_overlap(network, 90)
	assert_true(first_overlap > 1, "fell into the contact area")
	assert_eq(_tick_of("network_activated"), first_overlap, "on the first overlap tick")
	assert_false(_player.state.grounded, "still in the air when it activated")


# N-01: jumping up to a root activates it.
func test_jumping_up_to_a_root_activates() -> void:
	_setup(START)
	# Art y 176-191: out of reach while standing (body top 225), reached by a jump.
	var network: Network = _network("A", Vector2i(100, 184))
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "press": "jump"}])
	var first_overlap: int = _run_until_overlap(network, 60)
	assert_true(first_overlap > 2, "reached by the jump")
	assert_eq(_tick_of("jump"), 2, "jumped on tick 2")
	assert_eq(_tick_of("network_activated"), first_overlap, "on the first overlap tick")


# N-01: dashing into a root activates it during the dash.
func test_dashing_into_a_root_activates() -> void:
	_setup(START)
	var network: Network = _network("A", Vector2i(150, ROOT_Y))
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "press": "move_right"},
			{"tick": 2, "press": "dash"}])
	var first_overlap: int = _run_until_overlap(network, 30)
	assert_eq(_tick_of("dash_start"), 2, "dashed on tick 2")
	assert_eq(_tick_of("network_activated"), first_overlap, "on the first overlap tick")
	assert_true(_tick_of("dash_end") == -1 or _tick_of("dash_end") >= first_overlap,
			"while the dash was active")


# N-02: members powered, volts to 3, countdown cancelled, the other network unchanged.
func test_activation_powers_members_recharges_and_cancels_the_countdown() -> void:
	_setup(START)
	_player.flow.ledger.volts = 1
	var network: Network = _network("A", Vector2i(140, ROOT_Y), ["Gate", "Arch"])
	var other: Network = _network("B", Vector2i(500, ROOT_Y), ["Far"])
	for member: ChargedObject in network.members() + other.members():
		assert_false(member.powered, "%s starts unpowered" % member.name)
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 1, "press": "move_right"}])
	_run(1)
	assert_eq(_tick_of("countdown_start"), 1, "the last volt started the countdown")
	_run_until_overlap(network, 60)
	var at: int = _tick_of("network_activated")
	assert_true(network.powered, "network powered")
	for member: ChargedObject in network.members():
		assert_true(member.powered, "%s powered" % member.name)
	assert_eq(_events("network_activated")[0]["data"],
			{"network": "A", "members": ["Arch", "Gate"]}, "logged with its members, sorted")
	assert_eq(_player.flow.ledger.volts, Tuning.data.max_volts, "volts back to max")
	assert_false(_player.flow.ledger.countdown_running(), "countdown cancelled")
	assert_eq(_events_at(at, "volts"), [{"before": 0, "after": 3, "cause": "recharge"}])
	assert_eq(_events_at(at, "countdown_cancel"), [{"cause": "recharge"}])
	assert_false(other.powered, "the other network is unchanged")
	assert_false(other.members()[0].powered, "and so is its member")


# N-03: touching a powered root again gives nothing.
func test_touching_a_powered_root_again_gives_no_volts() -> void:
	_setup(START)
	_network("A", START + Vector2i(0, -8))
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"},
			{"tick": 3, "press": "switch"}, {"tick": 4, "release": "switch"},
			{"tick": 5, "press": "switch"}])
	_run(6)
	assert_eq(_events("switch").size(), 3, "flow, default, flow")
	assert_eq(_events("network_activated").size(), 1, "activated once, on tick 1")
	assert_eq(_player.flow.ledger.volts, Tuning.data.max_volts - 1,
			"the second flow entry cost a volt and nothing refunded it")


# Same-tick contract: two roots on one tick both activate, in node-name order, with one recharge.
func test_two_roots_on_one_tick_recharge_once() -> void:
	_setup(START)
	_player.flow.ledger.volts = 1
	var b: Network = _network("B", START + Vector2i(0, -8))
	var a: Network = _network("A", START + Vector2i(4, -8))
	_world._networks = [a, b]
	_input.play([{"tick": 1, "press": "switch"}])
	_run(1)
	var names: Array[String] = []
	for entry: Dictionary in _events("network_activated"):
		names.append(entry["data"]["network"])
	assert_eq(names, ["A", "B"], "both activate, in node-name order")
	assert_eq(_events_at(1, "volts"), [{"before": 1, "after": 0, "cause": "switch"},
			{"before": 0, "after": 3, "cause": "recharge"}], "one recharge volts event")
	assert_eq(_events_at(1, "countdown_cancel").size(), 1, "one countdown_cancel")
	var order: Array[String] = []
	for entry: Dictionary in Trace.get_events():
		if entry["event"] in ["network_activated", "volts", "countdown_cancel"]:
			order.append(entry["event"])
	assert_eq(order.slice(1), ["network_activated", "network_activated", "volts",
			"countdown_cancel"], "activations first, then the single recharge")


# S-04: a recharge on the countdown's expiry tick wins; without it the player dies that tick.
func test_a_recharge_on_the_expiry_tick_wins() -> void:
	_setup(START)
	_player.flow.ledger.volts = 1
	var network: Network = _network("A", Vector2i(400, ROOT_Y))
	_input.play([{"tick": 1, "press": "switch"}])
	_run(1)
	_player.flow.ledger.countdown_ticks_left = 1
	network.root().position = Vector2(START + Vector2i(0, -8))
	_run(1)
	assert_eq(_tick_of("network_activated"), 2, "activated on tick 2")
	assert_eq(_events("countdown_expire").size(), 0, "no expiry")
	assert_eq(_events("death").size(), 0, "the player lives")
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING)

	_setup(START)
	_player.flow.ledger.volts = 1
	_input.play([{"tick": 1, "press": "switch"}])
	_run(1)
	_player.flow.ledger.countdown_ticks_left = 1
	_run(1)
	assert_eq(_tick_of("countdown_expire"), 2, "control: without a root it expires on tick 2")
	assert_eq(_tick_of("death"), 2, "and the player dies")


# N-04: a network and its members start unpowered, even a member wrongly left always_powered.
func test_a_new_network_starts_unpowered() -> void:
	var network: Network = _make_network("A", Vector2i(100, 100), ["Wrong"])
	network.members()[0].always_powered = true
	add_node(network)
	assert_false(network.powered, "network unpowered")
	assert_false(network.members()[0].powered, "member unpowered")


# N-04: Level 1's always-powered object belongs to no network and stays powered across a death.
func test_level_1_object_stays_powered_across_a_death() -> void:
	_setup_world()
	_world.start()
	assert_eq(_world._networks.size(), 0, "Level 1 has no network")
	_world.restart_room()
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_run(1)
	var objects: Array[ChargedObject] = _world._room.charged_objects()
	assert_true(objects.size() > 0, "Level 1 has a charged object")
	for object: ChargedObject in objects:
		assert_true(object.powered, "%s powered after the respawn" % object.name)


# Room.networks(): every network under Objects, at any depth, in node-name order.
func test_room_finds_networks_in_node_name_order() -> void:
	var room: Node2D = Node2D.new()
	room.set_script(RoomScript)
	var objects: Node2D = Node2D.new()
	objects.name = "Objects"
	room.add_child(objects)
	var group: Node2D = Node2D.new()
	group.name = "Group"
	objects.add_child(group)
	group.add_child(_make_network("C", Vector2i.ZERO))
	objects.add_child(_make_network("B", Vector2i.ZERO))
	objects.add_child(_make_network("A", Vector2i.ZERO))
	add_node(room)
	var names: Array[String] = []
	for network: Network in (room as Room).networks():
		names.append(String(network.name))
	assert_eq(names, ["A", "B", "C"])


# The editor warnings: exactly one root, and no always-powered members.
func test_configuration_warnings() -> void:
	var good: Network = _make_network("Good", Vector2i.ZERO, ["M"])
	assert_eq(good._get_configuration_warnings().size(), 0, "one root, a proper member")
	var none: Network = Network.new()
	assert_eq(none._get_configuration_warnings().size(), 1, "no root")
	var two: Network = _make_network("Two", Vector2i.ZERO)
	two.add_child(ROOT_SCENE.instantiate())
	assert_eq(two._get_configuration_warnings().size(), 1, "two roots")
	var bad: Network = _make_network("Bad", Vector2i.ZERO, ["M"])
	bad.members()[0].always_powered = true
	assert_eq(bad._get_configuration_warnings().size(), 1, "an always-powered member")
	for network: Network in [good, none, two, bad]:
		network.free()


# A World with RoomSlot, Player and Camera, Level 1 loaded at its start, and scripted input.
func _setup_world() -> void:
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
	_world.load_room(&"level_1", &"start")
	_input = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(_input)


# A started World whose player stands at [param feet] on the test grid's floor, with no
# collectibles, goals or networks, fresh progress and an empty trace.
func _setup(feet: Vector2i) -> void:
	_setup_world()
	var grid: SolidGrid = SolidGrid.new(ROOM, Tuning.data.spike_depth_px,
			Tuning.data.spike_inset_px)
	for x: int in COLUMNS:
		grid.set_cell(Vector2i(x, FLOOR_ROW), SolidGrid.ORDINARY)
	_player.respawn(feet, grid)
	_world._collectibles = []
	_world._goals = []
	_world._networks = []
	_world.start()
	Trace.begin_session(true)


# A network named [param network_name] whose root is at [param root_at], with unpowered members
# named [param member_names]; added to the tree and to the World's networks (kept sorted).
func _network(network_name: String, root_at: Vector2i,
		member_names: Array[String] = []) -> Network:
	var network: Network = _make_network(network_name, root_at, member_names)
	add_node(network)
	_world._networks.append(network)
	_world._networks.sort_custom(func(a: Network, b: Network) -> bool:
			return String(a.name) < String(b.name))
	return network


func _make_network(network_name: String, root_at: Vector2i,
		member_names: Array[String] = []) -> Network:
	var network: Network = Network.new()
	network.name = network_name
	var root: PowerRoot = ROOT_SCENE.instantiate() as PowerRoot
	root.position = Vector2(root_at)
	network.add_child(root)
	for i: int in member_names.size():
		var member: ChargedObject = OBJECT_SCENE.instantiate() as ChargedObject
		member.name = member_names[i]
		member.always_powered = false
		member.position = Vector2(root_at + Vector2i(40 * (i + 1), -60))
		network.add_child(member)
	return network


# Runs ticks until the body overlaps [param network]'s contact area after a tick (at most
# [param limit]); returns that tick, or -1.
func _run_until_overlap(network: Network, limit: int) -> int:
	for i: int in limit:
		_run(1)
		if network.root().touches(_body()):
			return _world.tick
	return -1


func _body() -> Rect2i:
	return _player.mover.body_rect(_player.mover.position)


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


func _events(event_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == event_name:
			found.append(entry)
	return found


# The data of every [param event_name] logged on tick [param t].
func _events_at(t: int, event_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in _events(event_name):
		if entry["tick"] == t:
			found.append(entry["data"])
	return found


func _tick_of(event_name: String) -> int:
	var found: Array[Dictionary] = _events(event_name)
	return found[0]["tick"] if not found.is_empty() else -1
