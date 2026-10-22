# Tests FlowPresentation through the real main scene and Level 1: the default look on load; a
# switch shows rings, full glows and the `electric` animation on its tick and fades the backdrop
# over flow_fade_s; a switch back and a respawn restore the default look; a refused switch
# changes nothing; a bare charged object's placeholder look, Level 1's own look, and the frames
# and glow_texture exports; the title overlay holds the prewarm materials; and the visuals never
# change the rules' trace. From M5 step 2, through Level 1 rebuilt with two networks and a
# decorative wire: wires and power-source glows in default and flow, an activation powering and
# pulsing only its own network's wires, a respawn rebuilding them unpowered, and the trace
# unchanged with networks too. From M4 step 3: the platform family that is not solid now is drawn
# at inactive_platform_alpha in each of those cases, keeping the layer's tint, and a room built for
# a crossing shows the current state's platforms. Serves AC V-02, V-03, N-02.
extends TestCase

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const CHARGED_OBJECT_SCENE: PackedScene = preload(
		"res://objects/charged_object/charged_object.tscn")
const ROOT_SCENE: PackedScene = preload("res://objects/power_root/power_root.tscn")
const WIRE_SHADER: Shader = preload("res://objects/wire/wire_current.gdshader")

var _main: Node
var _world: WorldScript
var _player: Player
var _presentation: Node
var _input: ScriptedInputSource
# Level 1's own scene while _setup_with_networks has swapped the catalog's copy.
var _original_scene: PackedScene


func test_default_look_on_load() -> void:
	_setup()
	_assert_default("on load")


func test_switch_shows_flow_look_and_fades_the_backdrop() -> void:
	_setup()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_true(_player.flow.is_flow(), "in flow")
	for object: ChargedObject in _objects():
		assert_true(object.ring_shown, "%s: ring shown on the switch tick" % object.name)
		assert_eq(object.glow_strength, 1.0, "%s: full glow on the switch tick" % object.name)
		assert_eq(_sprite(object).animation, &"electric",
				"%s: electric animation on the switch tick" % object.name)
		assert_true(_sprite(object).is_playing(), "%s: electric is playing" % object.name)
	assert_eq(_backdrop().modulate, Color.WHITE, "the fade has not started yet")
	var fade: Tween = _presentation.call(&"fade") as Tween
	assert_true(fade != null and fade.is_valid(), "a fade is running")
	fade.custom_step(Tuning.data.flow_fade_s)
	assert_eq(_backdrop().modulate, Tuning.data.flow_backdrop_color, "dimmed after the fade")


func test_switch_back_restores_the_default_look() -> void:
	_setup()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"},
			{"tick": 3, "press": "switch"}, {"tick": 4, "release": "switch"}])
	_run(1)
	(_presentation.call(&"fade") as Tween).custom_step(Tuning.data.flow_fade_s)
	_run(2)
	assert_false(_player.flow.is_flow(), "back in default")
	(_presentation.call(&"fade") as Tween).custom_step(Tuning.data.flow_fade_s)
	_assert_default("after switching back")


func test_switch_swaps_the_faint_platform_family_on_its_tick() -> void:
	_setup()
	var tint: Color = Color(0.8, 0.6, 1.0)
	_layer("FlowTiles").modulate = Color(tint, Tuning.data.inactive_platform_alpha)
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_true(_player.flow.is_flow(), "in flow")
	assert_eq(_layer("FlowTiles").modulate, Color(tint, 1.0),
			"flow-only platforms drawn fully on the switch tick, tint kept")
	assert_near(_layer("DefaultTiles").modulate.a, Tuning.data.inactive_platform_alpha, 0.0001,
			"default-only platforms faint on the switch tick")
	assert_eq(_layer("WorldTiles").modulate, Color.WHITE, "ordinary tiles never change")


func test_a_crossing_neighbor_shows_the_current_platforms() -> void:
	_setup()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	var neighbor: Room = WorldScript.CATALOG.find(&"level_1").scene.instantiate() as Room
	neighbor.position = Vector2(100000, 100000)
	_world.get_node("RoomSlot").add_child(neighbor)
	assert_eq((neighbor.get_node("FlowTiles") as CanvasItem).modulate.a, 1.0,
			"the neighbor's flow-only platforms are drawn fully in flow")
	assert_near((neighbor.get_node("DefaultTiles") as CanvasItem).modulate.a,
			Tuning.data.inactive_platform_alpha, 0.0001,
			"the neighbor's default-only platforms are faint")
	neighbor.free()


func test_respawn_snaps_to_default_with_no_fade() -> void:
	_setup()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	(_presentation.call(&"fade") as Tween).custom_step(Tuning.data.flow_fade_s)
	_player.flow.countdown_expired = true
	_run(1)
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_run(1)
	assert_eq(_presentation.call(&"fade"), null, "no fade after a respawn")
	_assert_default("after a respawn")


func test_refused_switch_changes_nothing() -> void:
	_setup()
	_player.flow.ledger.volts = 0
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_eq(_count("switch_refused"), 1, "the switch is refused")
	assert_eq(_presentation.call(&"fade"), null, "no fade")
	_assert_default("after a refused switch")


func test_empty_frames_use_the_placeholder_look() -> void:
	_setup()
	var object: ChargedObject = add_node(CHARGED_OBJECT_SCENE.instantiate()) as ChargedObject
	var frames: SpriteFrames = _sprite(object).sprite_frames
	assert_eq(object.frames, null, "a bare charged object sets no look")
	assert_eq(frames, ChargedObject.DEFAULT_FRAMES, "placeholder look")
	for animation: StringName in [&"default", &"electric"]:
		assert_eq(frames.get_frame_count(animation), 1, "%s has one frame" % animation)
		assert_eq(frames.get_frame_texture(animation, 0).resource_path,
				"res://art/objects/charged_object.png",
				"%s shows charged_object.png" % animation)
	assert_eq(_glow(object).texture, ChargedObject.DEFAULT_GLOW, "default glow")


func test_level_1_objects_use_their_own_look() -> void:
	_setup()
	for object: ChargedObject in _objects():
		assert_true(object.frames != null, "%s: Level 1 sets the owner's look" % object.name)
		assert_eq(_sprite(object).sprite_frames, object.frames, "%s: that look is used" % object.name)
		for animation: StringName in [&"default", &"electric"]:
			assert_true(object.frames.has_animation(animation),
					"%s: the look has %s" % [object.name, animation])


func test_frames_and_glow_texture_exports_replace_the_look() -> void:
	_setup()
	var object: ChargedObject = _objects()[0]
	var look: SpriteFrames = SpriteFrames.new()
	look.add_animation(&"electric")
	look.add_frame(&"default", PlaceholderTexture2D.new())
	look.add_frame(&"electric", PlaceholderTexture2D.new())
	var glow: Texture2D = PlaceholderTexture2D.new()
	object.frames = look
	object.glow_texture = glow
	assert_eq(_sprite(object).sprite_frames, look, "the assigned look is used")
	assert_eq(_sprite(object).animation, &"default", "it plays default outside flow")
	assert_eq(_glow(object).texture, glow, "the assigned glow is used")
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_eq(_sprite(object).animation, &"electric", "the assigned look plays electric in flow")
	object.frames = null
	object.glow_texture = null
	assert_eq(_sprite(object).sprite_frames, ChargedObject.DEFAULT_FRAMES,
			"empty restores the placeholder")
	assert_eq(_sprite(object).animation, &"electric", "and keeps the current state's animation")
	assert_eq(_glow(object).texture, ChargedObject.DEFAULT_GLOW, "empty restores the default glow")


func test_main_scene_has_presentation_and_prewarm() -> void:
	_setup()
	assert_true(_presentation != null, "World/FlowPresentation exists")
	var prewarm: Control = _main.get_node("TitleOverlay/Root/Prewarm") as Control
	assert_eq(prewarm.get_child_count(), 2, "one prewarm rect per flow-state material")
	var rect: ColorRect = prewarm.get_child(0) as ColorRect
	var material: CanvasItemMaterial = rect.material as CanvasItemMaterial
	assert_true(material != null, "the rect carries a CanvasItemMaterial")
	assert_eq(material.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "additive, like the glow")
	assert_eq(rect.color, Color.BLACK, "black adds nothing, so the prewarm is invisible")
	var wire_rect: ColorRect = prewarm.get_child(1) as ColorRect
	var current: ShaderMaterial = wire_rect.material as ShaderMaterial
	assert_true(current != null and current.shader == WIRE_SHADER,
			"the second rect carries the wire current shader")
	assert_eq(wire_rect.color, Color.TRANSPARENT,
			"the shader blends normally, so its rect is transparent")


func test_the_presentation_never_changes_the_trace() -> void:
	var with_it: Array[Dictionary] = _scripted_run(true)
	var without_it: Array[Dictionary] = _scripted_run(false)
	assert_true(with_it.size() > 0, "the run logged events")
	assert_eq(with_it, without_it, "identical traces with and without FlowPresentation")


# --- wires and power sources (M5 step 2) ---

func test_wires_and_roots_start_unpowered_in_the_default_look() -> void:
	_setup_with_networks()
	for wire: Wire in _all_wires():
		assert_false(wire.flow_mode, "%s: default look" % wire.name)
		assert_eq(wire.pulse_progress, 1.0, "%s: no pulse band" % wire.name)
		assert_eq(wire.pulse(), null, "%s: no pulse running" % wire.name)
		assert_eq(wire.texture, Wire.STRIP, "%s: the strip texture" % wire.name)
		assert_eq(wire.texture_mode, Line2D.LINE_TEXTURE_STRETCH, "%s: stretched" % wire.name)
		var material: ShaderMaterial = wire.material as ShaderMaterial
		assert_true(material != null and material.shader == WIRE_SHADER,
				"%s: the current shader" % wire.name)
	for wire: Wire in _network("NetA").wires() + _network("NetB").wires():
		assert_false(wire.powered, "%s: a network's wire starts unpowered" % wire.name)
	assert_true(_decor().powered, "a decorative wire keeps decorative_powered")
	for network: Network in [_network("NetA"), _network("NetB")]:
		assert_eq(network.root().glow_strength, Tuning.data.glow_hint_alpha,
				"%s: root glow at hint strength" % network.name)
	assert_false(_wire("NetA", "W1").root_at_end(), "W1 starts at the root")
	assert_true(_wire("NetA", "W2").root_at_end(), "W2 ends at the root")
	assert_false(_decor().root_at_end(), "a decorative wire has no root")
	_restore_catalog()


func test_a_switch_sets_wire_modes_and_root_glows() -> void:
	_setup_with_networks()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"},
			{"tick": 3, "press": "switch"}, {"tick": 4, "release": "switch"}])
	_run(1)
	for wire: Wire in _all_wires():
		assert_true(wire.flow_mode, "%s: flow look on the switch tick" % wire.name)
	assert_eq(_network("NetB").root().glow_strength, 1.0, "unpowered root: full glow in flow")
	assert_eq(_network("NetA").root().glow_strength, 0.0, "powered root: glow off")
	_run(2)
	assert_false(_player.flow.is_flow(), "back in default")
	for wire: Wire in _all_wires():
		assert_false(wire.flow_mode, "%s: default look again" % wire.name)
	assert_eq(_network("NetB").root().glow_strength, Tuning.data.glow_hint_alpha,
			"unpowered root: hint again")
	assert_eq(_network("NetA").root().glow_strength, 0.0, "powered root: still off in default")
	_restore_catalog()


func test_activation_powers_and_pulses_only_its_own_wires() -> void:
	_setup_with_networks()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_eq(_count("network_activated"), 1, "NetA activated on the switch tick")
	assert_true(_network("NetA").powered and not _network("NetB").powered, "only NetA powered")
	for wire: Wire in _network("NetA").wires():
		assert_true(wire.powered, "%s: powered" % wire.name)
		assert_eq((wire.material as ShaderMaterial).get_shader_parameter(&"powered"), true,
				"%s: the shader sees it" % wire.name)
		assert_true(wire.pulse() != null and wire.pulse().is_running(), "%s: pulsing" % wire.name)
		assert_eq(wire.pulse_progress, 0.0, "%s: the band starts at the root" % wire.name)
	var glow: Sprite2D = _network("NetA").root().get_node("Glow") as Sprite2D
	assert_false(glow.visible, "the powered root's glow is hidden")
	var pulse: Tween = _wire("NetA", "W1").pulse()
	pulse.custom_step(Tuning.data.wire_pulse_s * 0.5)
	assert_near(_wire("NetA", "W1").pulse_progress, 0.5, 0.01, "halfway at half wire_pulse_s")
	pulse.custom_step(Tuning.data.wire_pulse_s * 0.5 + 0.001)
	assert_eq(_wire("NetA", "W1").pulse_progress, 1.0, "the band is gone after wire_pulse_s")
	assert_false(pulse.is_running(), "the pulse has ended")
	for wire: Wire in _network("NetB").wires():
		assert_false(wire.powered, "%s: the other network is unchanged (N-02)" % wire.name)
		assert_eq(wire.pulse(), null, "%s: no pulse" % wire.name)
	assert_eq(_network("NetB").root().glow_strength, 1.0, "the other root still glows in flow")
	assert_true(_decor().powered, "the decorative wire is unchanged")
	assert_eq(_decor().pulse(), null, "a decorative wire never pulses")
	_decor().play_pulse()
	assert_eq(_decor().pulse(), null, "not even when asked")
	_restore_catalog()


func test_a_respawn_rebuilds_wires_and_glow_unpowered() -> void:
	_setup_with_networks()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_true(_network("NetA").powered, "activated before the death")
	_player.flow.countdown_expired = true
	_run(1)
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_run(1)
	assert_false(_network("NetA").powered, "the rebuilt network is unpowered")
	for wire: Wire in _network("NetA").wires():
		assert_false(wire.powered, "%s: unpowered after the respawn" % wire.name)
		assert_false(wire.flow_mode, "%s: default look after the respawn" % wire.name)
		assert_eq(wire.pulse(), null, "%s: no pulse after the respawn" % wire.name)
	assert_eq(_network("NetA").root().glow_strength, Tuning.data.glow_hint_alpha,
			"the root glows at hint strength again")
	_restore_catalog()


func test_the_presentation_never_changes_the_trace_with_networks() -> void:
	var with_it: Array[Dictionary] = _scripted_run(true, true)
	var without_it: Array[Dictionary] = _scripted_run(false, true)
	var activations: int = 0
	for entry: Dictionary in with_it:
		if entry["event"] == "network_activated":
			activations += 1
	assert_true(activations > 0, "the run activated a network")
	assert_eq(with_it, without_it, "identical traces with and without FlowPresentation")


# A main scene in Playing, its World reading a ScriptedInputSource. Without
# [param with_presentation], World/FlowPresentation is removed before the scene enters the tree.
func _setup(with_presentation: bool = true) -> void:
	Trace.begin_session(true)
	_main = MAIN_SCENE.instantiate()
	if not with_presentation:
		var node: Node = _main.get_node("World/FlowPresentation")
		node.get_parent().remove_child(node)
		node.free()
	add_node(_main)
	_world = _main.get_node("World") as WorldScript
	# The game starts in tutorial_1 (M6 step 2); these tests run in Level 1.
	_world.load_room(&"level_1", &"start")
	_player = _main.get_node("World/Player") as Player
	_presentation = _main.get_node_or_null("World/FlowPresentation")
	_input = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(_input)
	_world.start()


# Level 1 built from a copy of its scene that also holds two networks and a decorative wire, so
# loads and respawns build them like a room's own; call _restore_catalog at the end. Network
# NetA's root sits on the player at the start entrance, so switching into flow activates it; NetB
# is far from the player.
func _setup_with_networks(with_presentation: bool = true) -> void:
	var entry: RoomEntry = WorldScript.CATALOG.find(&"level_1")
	_original_scene = entry.scene
	var room: Room = _original_scene.instantiate() as Room
	var feet: Vector2i = room.entrance(&"start").feet()
	var objects: Node = room.get_node("Objects")
	objects.add_child(_make_network("NetA", feet + Vector2i(0, -8)))
	objects.add_child(_make_network("NetB", feet + Vector2i(260, -120)))
	var decor: Wire = Wire.new()
	decor.name = "Decor"
	decor.decorative_powered = true
	decor.points = PackedVector2Array([Vector2(feet + Vector2i(-60, -40)),
			Vector2(feet + Vector2i(-20, -40))])
	objects.add_child(decor)
	_own(room, room)
	var packed: PackedScene = PackedScene.new()
	packed.pack(room)
	room.free()
	entry.scene = packed
	_setup(with_presentation)


func _restore_catalog() -> void:
	if _original_scene != null:
		WorldScript.CATALOG.find(&"level_1").scene = _original_scene
		_original_scene = null


# A network with its root at [param root_at] and two unpowered members: W1 runs from the root
# to M1, and W2 from M2 back to the root.
func _make_network(network_name: String, root_at: Vector2i) -> Network:
	var network: Network = Network.new()
	network.name = network_name
	var root: PowerRoot = ROOT_SCENE.instantiate() as PowerRoot
	root.position = Vector2(root_at)
	network.add_child(root)
	var ends: Array[Vector2] = []
	for i: int in 2:
		var member: ChargedObject = CHARGED_OBJECT_SCENE.instantiate() as ChargedObject
		member.name = "M%d" % (i + 1)
		member.always_powered = false
		member.position = Vector2(root_at + Vector2i(40 * (i + 1), -60))
		network.add_child(member)
		ends.append(member.position)
	var first: Wire = Wire.new()
	first.name = "W1"
	first.points = PackedVector2Array([Vector2(root_at), ends[0]])
	network.add_child(first)
	var second: Wire = Wire.new()
	second.name = "W2"
	second.points = PackedVector2Array([ends[1], Vector2(root_at)])
	network.add_child(second)
	return network


# Gives every node under [param node] that has no owner to [param owner], so packing keeps it.
func _own(node: Node, owner: Node) -> void:
	for child: Node in node.get_children():
		if child.owner == null:
			child.owner = owner
		_own(child, owner)


func _network(network_name: String) -> Network:
	for network: Network in _room().networks():
		if String(network.name) == network_name:
			return network
	assert_true(false, "no network %s" % network_name)
	return null


func _wire(network_name: String, wire_name: String) -> Wire:
	return _network(network_name).get_node(wire_name) as Wire


func _decor() -> Wire:
	return _room().get_node("Objects/Decor") as Wire


func _all_wires() -> Array[Wire]:
	var wires: Array[Wire] = _network("NetA").wires() + _network("NetB").wires()
	wires.append(_decor())
	return wires


# Switches, runs, switches back, dies by countdown and respawns, and returns every event,
# without the session header. With [param with_networks], Level 1 holds two networks and the
# switch on tick 1 activates one.
func _scripted_run(with_presentation: bool, with_networks: bool = false) -> Array[Dictionary]:
	if with_networks:
		_setup_with_networks(with_presentation)
	else:
		_setup(with_presentation)
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 3, "release": "switch"},
			{"tick": 2, "press": "move_right"}, {"tick": 20, "press": "jump"},
			{"tick": 24, "release": "jump"}, {"tick": 30, "press": "switch"},
			{"tick": 31, "release": "switch"}, {"tick": 40, "press": "switch"},
			{"tick": 41, "release": "switch"}])
	_run(60)
	_player.flow.countdown_expired = true
	_run(60)
	var events: Array[Dictionary] = Trace.get_events()
	_main.free()
	_input.free()
	_restore_catalog()
	return events


func _assert_default(when: String) -> void:
	assert_eq(_backdrop().modulate, Color.WHITE, "backdrop undimmed %s" % when)
	for object: ChargedObject in _objects():
		assert_false(object.ring_shown, "%s: ring hidden %s" % [object.name, when])
		assert_eq(object.glow_strength, Tuning.data.glow_hint_alpha,
				"%s: glow at hint strength %s" % [object.name, when])
		assert_eq(_sprite(object).animation, &"default",
				"%s: default animation %s" % [object.name, when])
		assert_true(_sprite(object).is_playing(), "%s: default is playing %s" % [object.name, when])
	assert_eq(_layer("DefaultTiles").modulate.a, 1.0,
			"default-only platforms drawn fully %s" % when)
	assert_near(_layer("FlowTiles").modulate.a, Tuning.data.inactive_platform_alpha, 0.0001,
			"flow-only platforms faint %s" % when)
	assert_eq(_layer("WorldTiles").modulate, Color.WHITE, "ordinary tiles unchanged %s" % when)


func _room() -> Room:
	for child: Node in _world.get_node("RoomSlot").get_children():
		if child is Room and not child.is_queued_for_deletion():
			return child
	return null


func _layer(layer_name: String) -> CanvasItem:
	return _room().get_node(layer_name) as CanvasItem


func _backdrop() -> CanvasItem:
	return _room().get_node("Backdrop") as CanvasItem


func _objects() -> Array[ChargedObject]:
	var objects: Array[ChargedObject] = _room().charged_objects()
	assert_true(objects.size() > 0, "Level 1 has a charged object")
	return objects


func _sprite(object: ChargedObject) -> AnimatedSprite2D:
	return object.get_node("Sprite") as AnimatedSprite2D


func _glow(object: ChargedObject) -> Sprite2D:
	return object.get_node("Glow") as Sprite2D


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


func _count(name: String) -> int:
	var found: int = 0
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == name:
			found += 1
	return found
