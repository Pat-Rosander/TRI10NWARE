# Tests FlowPresentation through the real main scene and Level 1: the default look on load; a
# switch shows rings, full glows and the `electric` animation on its tick and fades the backdrop
# over flow_fade_s; a switch back and a respawn restore the default look; a refused switch
# changes nothing; a bare charged object's placeholder look, Level 1's own look, and the frames
# and glow_texture exports; the title overlay holds the prewarm material; and the visuals never
# change the rules' trace. Serves AC V-02, V-03.
extends TestCase

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const CHARGED_OBJECT_SCENE: PackedScene = preload(
		"res://objects/charged_object/charged_object.tscn")

var _main: Node
var _world: WorldScript
var _player: Player
var _presentation: Node
var _input: ScriptedInputSource


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
	assert_eq(prewarm.get_child_count(), 1, "one prewarm rect per flow-state material")
	var rect: ColorRect = prewarm.get_child(0) as ColorRect
	var material: CanvasItemMaterial = rect.material as CanvasItemMaterial
	assert_true(material != null, "the rect carries a CanvasItemMaterial")
	assert_eq(material.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "additive, like the glow")
	assert_eq(rect.color, Color.BLACK, "black adds nothing, so the prewarm is invisible")


func test_the_presentation_never_changes_the_trace() -> void:
	var with_it: Array[Dictionary] = _scripted_run(true)
	var without_it: Array[Dictionary] = _scripted_run(false)
	assert_true(with_it.size() > 0, "the run logged events")
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


# Switches, runs, switches back, dies by countdown and respawns, and returns every event,
# without the session header.
func _scripted_run(with_presentation: bool) -> Array[Dictionary]:
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


func _room() -> Room:
	for child: Node in _world.get_node("RoomSlot").get_children():
		if child is Room and not child.is_queued_for_deletion():
			return child
	return null


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
