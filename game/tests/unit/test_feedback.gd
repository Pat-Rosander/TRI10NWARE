# Tests Sfx and Effects through the real main scene and Level 1: the charged_dash memory (a
# ground refill, a dash, a respawn or a room_enter clears it); exactly one countdown tick per
# shown second; identical traces with and without both nodes; pools that never grow across
# deaths; and one check per other sound and effect. Serves AC V-04 (owner, M3 step 5). Also the
# music: it starts on the title's dismissal and never stops, and the pause menu's slider sets
# the Music bus (owner, M3 step 7).
extends TestCase

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const SfxScript: GDScript = preload("res://audio/sfx.gd")
const EffectsScript: GDScript = preload("res://world/effects.gd")
const HudScript: GDScript = preload("res://ui/hud.gd")
const PauseMenuScript: GDScript = preload("res://ui/pause_menu.gd")

var _main: Node
var _world: WorldScript
var _player: Player
var _sfx: SfxScript
var _effects: EffectsScript
var _input: ScriptedInputSource
var _sounds: Array[StringName] = []
var _shown: Array[StringName] = []
var _shown_at: Array[Vector2] = []


# --- charged_dash memory (owner priority) ---

func test_a_dash_after_a_charged_refill_plays_charged_dash() -> void:
	_setup()
	_refill("charged")
	_dash()
	assert_eq(_sounds, [&"charged_dash"], "charged refill, then dash")


func test_a_ground_refill_after_a_charged_one_resets_it() -> void:
	_setup()
	_refill("charged")
	_refill("ground")
	_dash()
	assert_eq(_sounds, [&"dash"], "the latest refill was a ground refill")


func test_a_ground_refill_alone_plays_dash() -> void:
	_setup()
	_refill("ground")
	_dash()
	assert_eq(_sounds, [&"dash"], "ground refill, then dash")


func test_a_second_dash_without_a_new_refill_plays_dash() -> void:
	_setup()
	_refill("charged")
	_dash()
	_dash()
	assert_eq(_sounds, [&"charged_dash", &"dash"], "the charged refill is used up by one dash")


func test_a_ground_then_charged_refill_plays_charged_dash() -> void:
	_setup()
	_refill("ground")
	_refill("charged")
	_dash()
	assert_eq(_sounds, [&"charged_dash"], "the latest refill was charged")


func test_a_respawn_clears_a_charged_refill() -> void:
	_setup()
	_refill("charged")
	Trace.record("respawn", {"room": "level_1", "entrance": "start"})
	_dash()
	assert_eq(_sounds, [&"respawn", &"dash"], "a respawn's fresh dash is not charged")


func test_a_room_enter_clears_a_charged_refill() -> void:
	_setup()
	_refill("charged")
	Trace.record("room_enter", {"room": "level_1", "entrance": "start"})
	_dash()
	assert_eq(_sounds, [&"dash"], "a new room's fresh dash is not charged")


# --- countdown (owner priority) ---

func test_a_three_second_countdown_ticks_exactly_three_times() -> void:
	_setup()
	assert_eq(Tuning.countdown_ticks, 3 * Tuning.TICKS_PER_SECOND, "the countdown is 3 seconds")
	_player.flow.ledger.volts = 1
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	var heard_at: Array[int] = []
	var heard_seconds: Array[int] = []
	for t: int in Tuning.countdown_ticks + 60:
		_run(1)
		var before: int = _sounds.count(&"countdown_tick")
		_sfx._process(0.0)
		if _sounds.count(&"countdown_tick") > before:
			heard_at.append(t)
			heard_seconds.append(HudScript.countdown_seconds(
					_player.flow.ledger.countdown_ticks_left, Tuning.TICKS_PER_SECOND))
	assert_eq(_count("countdown_start"), 1, "the countdown started")
	assert_eq(_count("death"), 1, "and killed the player")
	assert_eq(_sounds.count(&"countdown_tick"), 3, "exactly three ticks")
	assert_eq(heard_seconds, [3, 2, 1], "one for each shown second, none at 0")
	assert_eq(heard_at[0], 0, "the first on the tick the countdown starts")
	assert_eq(heard_at[2] - heard_at[1], Tuning.TICKS_PER_SECOND, "one second apart")
	assert_eq(heard_at[1] - heard_at[0], Tuning.TICKS_PER_SECOND - 1,
			"the start tick already counts down once (ledger: expires on t + 179)")


func test_no_countdown_tick_without_a_countdown() -> void:
	_setup()
	for i: int in 30:
		_run(1)
		_sfx._process(0.0)
	assert_eq(_sounds.count(&"countdown_tick"), 0, "no countdown, no tick")


# --- determinism (owner priority) ---

func test_sound_and_effects_never_change_the_trace() -> void:
	var with_them: Array[Dictionary] = _scripted_run(true)
	var without_them: Array[Dictionary] = _scripted_run(false)
	assert_true(with_them.size() > 0, "the run logged events")
	assert_eq(with_them, without_them, "identical traces with and without Sfx and Effects")


# --- pools (owner priority) ---

func test_pools_do_not_grow_across_repeated_deaths() -> void:
	_setup()
	for i: int in 6:
		_die_and_respawn()
	assert_eq(_count("death"), 6, "six deaths")
	assert_eq(_sounds.count(&"death"), 6, "a death sound each time")
	assert_eq(_shown.count(&"respawn"), 6, "a respawn effect each time")
	assert_eq(_sfx.get_child_count(), SfxScript.POOL_SIZE, "the sound pool kept its size")
	assert_eq(_effects.get_child_count(), EffectsScript.POOL_SIZE, "the effect pool kept its size")


func test_a_full_pool_reuses_its_oldest_player() -> void:
	_setup()
	for i: int in SfxScript.POOL_SIZE:
		_sfx.play(&"jump")
	_sfx.play(&"death")
	assert_eq(_sfx.get_child_count(), SfxScript.POOL_SIZE, "no player was added")
	assert_eq((_sfx.get_child(0) as AudioStreamPlayer).stream, SfxScript.STREAMS[&"death"],
			"the oldest player took the new sound")
	for i: int in EffectsScript.POOL_SIZE:
		_effects.play(&"land", Vector2.ZERO)
	_effects.play(&"goal", Vector2(5, 5))
	assert_eq(_effects.get_child_count(), EffectsScript.POOL_SIZE, "no sprite was added")
	var first: AnimatedSprite2D = _effects.get_child(0) as AnimatedSprite2D
	assert_eq(first.animation, &"goal", "the oldest sprite took the new effect")
	assert_eq(first.position, Vector2(5, 5), "at the new position")


# --- the other sounds, one check each ---

func test_ground_jump_sound() -> void:
	_setup()
	_jump("ground")
	assert_eq(_sounds, [&"jump"], "ground jump")


func test_coyote_jump_sound() -> void:
	_setup()
	_jump("coyote")
	assert_eq(_sounds, [&"jump"], "coyote jump")


func test_wall_jump_sound() -> void:
	_setup()
	_jump("wall")
	assert_eq(_sounds, [&"jump"], "wall jump")


func test_charged_jump_sound() -> void:
	_setup()
	_jump("charged")
	assert_eq(_sounds, [&"charged_jump"], "charged jump")


func test_switch_sounds() -> void:
	_setup()
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"},
			{"tick": 3, "press": "switch"}, {"tick": 4, "release": "switch"}])
	_run(4)
	assert_eq(_sounds, [&"switch_to_flow", &"switch_to_default"], "into flow, then back")


func test_refused_switch_sound() -> void:
	_setup()
	_player.flow.ledger.volts = 0
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 2, "release": "switch"}])
	_run(1)
	assert_eq(_sounds, [&"switch_refused"], "refused at zero volts")


func test_death_and_respawn_sounds() -> void:
	_setup()
	_die_and_respawn()
	assert_eq(_sounds, [&"death", &"respawn"], "death, then respawn")


func test_room_complete_sound() -> void:
	_setup()
	Trace.record("room_complete", {"room": "level_1"})
	assert_eq(_sounds, [&"room_complete"], "completion")


func test_collectible_sounds_and_none_for_a_loss() -> void:
	_setup()
	for change: String in ["touched", "committed", "lost"]:
		Trace.record("collectible", {"id": "level_1/Collectible", "change": change})
	assert_eq(_sounds, [&"collectible_touch", &"collectible_commit"],
			"touched and committed have sounds; lost relies on the death sound")


func test_sounds_play_on_the_sfx_bus() -> void:
	_setup()
	assert_true(AudioServer.get_bus_index(&"SFX") >= 0, "the SFX bus exists")
	assert_true(AudioServer.get_bus_index(&"Music") >= 0, "the Music bus exists")
	for child: Node in _sfx.get_children():
		assert_eq((child as AudioStreamPlayer).bus, &"SFX", "%s is on SFX" % child.name)


# --- music (M3 step 7) ---

func test_music_starts_on_title_dismissal_and_not_before() -> void:
	_setup_on_title()
	var music: AudioStreamPlayer = _main.get_node("Music") as AudioStreamPlayer
	assert_eq(music.bus, &"Music", "on the Music bus")
	assert_eq(music.process_mode, Node.PROCESS_MODE_ALWAYS, "process mode Always")
	assert_eq(music.stream.resource_path, "res://audio/music/electrun_theme_1.mp3", "the owner's track")
	assert_true((music.stream as AudioStreamMP3).loop, "looped by its import settings")
	assert_false(music.autoplay, "no autoplay")
	assert_false(music.playing, "silent on the title")
	_dismiss_title()
	assert_true(music.playing, "the start key starts the music")


func test_music_keeps_playing_through_death_pause_and_replay() -> void:
	_setup_on_title()
	var music: AudioStreamPlayer = _main.get_node("Music") as AudioStreamPlayer
	var pause: PauseMenuScript = _main.get_node("PauseMenu") as PauseMenuScript
	_dismiss_title()
	var started: AudioStreamPlayback = music.get_stream_playback()
	_die_and_respawn()
	assert_true(music.playing, "still playing after a death and respawn")
	pause.open()
	assert_true(_main.get_tree().paused, "the menu paused the tree")
	assert_true(music.playing and music.can_process(), "still playing while paused")
	pause.resume()
	assert_true(music.playing, "still playing after resume")
	var goal: GoalZone = _world._goals[0]
	# Level 1's goal is a banner goal (M7 step 1); here it stands in for the final room's goal.
	goal.completes_game = true
	_player.respawn(Vector2i(roundi(goal.position.x + goal.width_px / 2.0), roundi(goal.position.y)),
			_player.mover.grid)
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.COMPLETE, "standing on the goal completes")
	assert_true(music.playing, "still playing on the completion screen")
	var entered: int = _count("room_enter")
	_world.replay()
	assert_eq(_count("room_enter"), entered + 1, "replay rebuilt the room")
	assert_true(music.playing, "still playing after the rebuild")
	assert_eq(music.get_stream_playback(), started, "never restarted")


func test_music_volume_starts_at_tuning() -> void:
	_setup_on_title()
	var slider: HSlider = _main.get_node("PauseMenu").get_node("%MusicVolume") as HSlider
	var bus: int = AudioServer.get_bus_index(&"Music")
	assert_eq(Tuning.data.music_volume, 0.7, "the tuning default")
	assert_eq(slider.value, 70.0, "the slider starts at music_volume")
	assert_false(AudioServer.is_bus_mute(bus), "the Music bus is on")
	assert_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.7), 0.001, "at 70 %")


func test_slider_sets_the_music_bus_and_zero_mutes_it() -> void:
	_setup_on_title()
	var slider: HSlider = _main.get_node("PauseMenu").get_node("%MusicVolume") as HSlider
	var label: Label = _main.get_node("PauseMenu").get_node("%MusicLabel") as Label
	var bus: int = AudioServer.get_bus_index(&"Music")
	var master: int = AudioServer.get_bus_index(&"Master")
	var master_db: float = AudioServer.get_bus_volume_db(master)
	slider.value = 50.0
	assert_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.001, "50 % reaches the bus")
	assert_eq(label.text, "Music: 50 %", "the label follows")
	slider.value = 0.0
	assert_true(AudioServer.is_bus_mute(bus), "0 mutes the Music bus")
	slider.value = 100.0
	assert_false(AudioServer.is_bus_mute(bus), "above 0 unmutes it")
	assert_near(AudioServer.get_bus_volume_db(bus), 0.0, 0.001, "100 % is 0 dB")
	assert_false(AudioServer.is_bus_mute(master), "Master is never muted by the slider")
	assert_eq(AudioServer.get_bus_volume_db(master), master_db, "or changed")
	slider.value = Tuning.data.music_volume * 100.0


# --- the effects, one check each ---

func test_fall_death_effect_is_clamped_into_the_view() -> void:
	_setup()
	_run(1)
	var mover: PixelMover = _player.mover
	mover.position = Vector2i(mover.position.x, mover.grid.bounds.end.y + 500)
	# The camera follows in step 11, after the death in step 10: the death sees this view.
	var view: Rect2 = _effects.view_rect()
	_run(1)
	assert_eq(_count("death"), 1, "the fall killed the player")
	var at: Vector2 = _shown_at[_shown.find(&"death")]
	assert_eq(at.y, view.end.y, "the effect sits on the view's bottom edge")
	assert_true(at.x >= view.position.x and at.x <= view.end.x, "inside the view horizontally")


func test_death_and_respawn_effects() -> void:
	_setup()
	_die_and_respawn()
	assert_eq(_shown, [&"death", &"respawn"], "death, then respawn")


func test_charged_jump_effect_and_none_for_other_jumps() -> void:
	_setup()
	_jump("ground")
	_jump("charged")
	assert_eq(_shown, [&"charged_jump"], "only the charged jump has an effect")


func test_dash_effect() -> void:
	_setup()
	_dash()
	assert_eq(_shown, [&"dash"], "dash")


func test_land_effect() -> void:
	_setup()
	Trace.record("land", {"vx": 0.0, "vy_before": 200.0})
	assert_eq(_shown, [&"land"], "land")


func test_goal_effect_on_the_player() -> void:
	_setup()
	Trace.record("room_complete", {"room": "level_1"})
	assert_eq(_shown, [&"goal"], "goal")
	var body: Rect2i = _player.mover.body_rect(_player.mover.position)
	assert_eq(_shown_at[0], Vector2(body.position) + Vector2(body.size) / 2.0,
			"centered on the player's body")


# A main scene in Playing, its World reading a ScriptedInputSource. Without
# [param with_feedback], Sfx and World/Effects are removed before the scene enters the tree.
func _setup(with_feedback: bool = true) -> void:
	Trace.begin_session(true)
	_sounds.clear()
	_shown.clear()
	_shown_at.clear()
	_main = MAIN_SCENE.instantiate()
	if not with_feedback:
		for path: String in ["Sfx", "World/Effects"]:
			var node: Node = _main.get_node(path)
			node.get_parent().remove_child(node)
			node.free()
	add_node(_main)
	_world = _main.get_node("World") as WorldScript
	# The game starts in tutorial_1 (M6 step 2); these tests run in Level 1.
	_world.load_room(&"level_1", &"start")
	_player = _main.get_node("World/Player") as Player
	_sfx = _main.get_node_or_null("Sfx") as SfxScript
	_effects = _main.get_node_or_null("World/Effects") as EffectsScript
	if with_feedback:
		_sfx.sound_played.connect(func(slot: StringName) -> void: _sounds.append(slot))
		_effects.effect_played.connect(func(effect: StringName, at: Vector2) -> void:
			_shown.append(effect)
			_shown_at.append(at))
	_input = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(_input)
	_world.start()


# A main scene on its title screen, its World reading a ScriptedInputSource once started.
func _setup_on_title() -> void:
	Trace.begin_session(true)
	_main = add_node(MAIN_SCENE.instantiate())
	_world = _main.get_node("World") as WorldScript
	# The game starts in tutorial_1 (M6 step 2); these tests run in Level 1.
	_world.load_room(&"level_1", &"start")
	_player = _main.get_node("World/Player") as Player
	_input = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(_input)


# A key press reaching the title overlay, as in test_play_loop.
func _dismiss_title() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	_main.get_node("TitleOverlay").call(&"_unhandled_input", key)
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING, "the title started play")


# Switches, runs, jumps, dashes, dies by countdown and respawns, and returns every event,
# without the session header.
func _scripted_run(with_feedback: bool) -> Array[Dictionary]:
	_setup(with_feedback)
	_input.play([{"tick": 1, "press": "switch"}, {"tick": 3, "release": "switch"},
			{"tick": 2, "press": "move_right"}, {"tick": 20, "press": "jump"},
			{"tick": 24, "release": "jump"}, {"tick": 26, "press": "dash"},
			{"tick": 27, "release": "dash"}, {"tick": 50, "press": "switch"},
			{"tick": 51, "release": "switch"}])
	for i: int in 90:
		_run(1)
		if _sfx != null:
			_sfx._process(0.0)
	_player.flow.countdown_expired = true
	_run(60)
	var events: Array[Dictionary] = Trace.get_events()
	_main.free()
	_input.free()
	return events


# A countdown death, run until control returns.
func _die_and_respawn() -> void:
	_player.flow.countdown_expired = true
	_run(1)
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_run(1)


func _refill(cause: String) -> void:
	Trace.record("dash_refill", {"cause": cause})


func _dash() -> void:
	Trace.record("dash_start", {"dir_x": 1, "dir_y": 0, "vx": 240.0, "vy": 0.0})


func _jump(kind: String) -> void:
	Trace.record("jump", {"kind": kind, "vx": 0.0, "vy": -200.0, "object": ""})


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


func _count(name: String) -> int:
	var found: int = 0
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == name:
			found += 1
	return found
