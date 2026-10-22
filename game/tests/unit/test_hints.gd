# Tests the control hints through a real Main scene: the first entry to a room shows its hint, held
# for hint_s and faded over hint_fade_s; it waits behind the title and while paused; it does not
# come back after a death or a re-entry; a new run shows it again (M6 step 6). Visual only.
extends TestCase

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const PauseMenuScript: GDScript = preload("res://ui/pause_menu.gd")
const STEP: float = 1.0 / 60.0

var _main: Node
var _world: WorldScript
var _player: Player
var _hold: int = 0
var _fade: int = 0


func test_first_entry_shows_it_and_it_waits_behind_the_title() -> void:
	_setup()
	var hint: Hint = _hint()
	assert_eq(hint.id, "tutorial_1/Hint", "room ID plus node name")
	assert_true(hint.visible, "shown on the first entry, behind the title")
	_run(60)
	_frames(hint, 60)
	assert_eq(GameState.run_ticks, 0, "no ticks on the title")
	assert_eq(hint.modulate.a, 1.0, "fully shown")
	assert_false(GameState.is_hint_shown(hint.id), "its timer has not started")
	_world.start()
	_tick(hint, _hold - 1)
	assert_true(GameState.is_hint_shown(hint.id), "remembered once its timer runs")
	assert_true(hint.visible, "still shown one tick before hint_s")
	assert_eq(hint.modulate.a, 1.0, "not fading yet")
	@warning_ignore("integer_division")
	var half: int = _fade / 2
	_tick(hint, 1 + half)
	assert_true(hint.modulate.a > 0.0 and hint.modulate.a < 1.0, "fading")
	_tick(hint, _fade - half - 1)
	assert_true(hint.visible, "one tick before the fade ends")
	_tick(hint, 1)
	assert_false(hint.visible, "gone after hint_s plus hint_fade_s")
	assert_false(hint.is_showing())
	_finish()


func test_timer_stands_still_while_paused() -> void:
	_setup()
	var hint: Hint = _hint()
	_world.start()
	_tick(hint, 10)
	var pause: PauseMenuScript = _main.get_node("PauseMenu") as PauseMenuScript
	pause.open()
	assert_false(_world.can_process(), "World gets no physics steps while paused")
	assert_false(hint.can_process(), "the hint pauses with its room")
	_frames(hint, 600)
	pause.resume()
	_tick(hint, _hold + _fade - 11)
	assert_true(hint.visible, "the pause added no time")
	_tick(hint, 1)
	assert_false(hint.visible, "gone exactly hint_s plus hint_fade_s of play later")
	_finish()


func test_no_repeat_after_a_death_or_a_re_entry() -> void:
	_setup()
	_world.start()
	_tick(_hint(), 10)
	_player.flow.countdown_expired = true
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING)
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING, "respawned")
	var rebuilt: Hint = _hint()
	_tick(rebuilt, 5)
	assert_false(rebuilt.visible, "not shown after a death")
	_world.load_room(&"level_1", &"start")
	_world.load_room(&"tutorial_1", &"start")
	var again: Hint = _hint()
	_tick(again, 5)
	assert_false(again.visible, "not shown on a re-entry")
	_finish()


func test_a_new_run_shows_it_again() -> void:
	_setup()
	_world.start()
	_tick(_hint(), _hold + _fade)
	assert_true(GameState.is_hint_shown("tutorial_1/Hint"))
	_world.play_state = WorldScript.PlayState.COMPLETE
	_world.replay()
	assert_false(GameState.is_hint_shown("tutorial_1/Hint"), "a new run forgets it")
	var hint: Hint = _hint()
	assert_true(hint.visible, "shown again in the new run")
	_tick(hint, 1)
	assert_eq(hint.modulate.a, 1.0)
	_finish()


func test_level_1_shows_its_switch_hint() -> void:
	_setup()
	_world.start()
	_world.load_room(&"level_1", &"start")
	var hint: Hint = _hint()
	assert_eq(hint.id, "level_1/Hint")
	assert_true(hint.visible, "shown on entering level_1")
	assert_false(hint.text.is_empty(), "it has text")
	_tick(hint, 1)
	assert_true(GameState.is_hint_shown("level_1/Hint"))
	_finish()


# A Main scene on the title, in the start room (tutorial_1), its World reading a
# ScriptedInputSource.
func _setup() -> void:
	Trace.begin_session(true)
	GameState.reset()
	_hold = Tuning.hint_ticks
	_fade = Tuning.hint_fade_ticks
	_main = add_node(MAIN_SCENE.instantiate())
	_world = _main.get_node("World") as WorldScript
	_player = _world.get_node("Player") as Player
	var input: ScriptedInputSource = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(input)


# The current room's hint.
func _hint() -> Hint:
	return _world._room.get_node("Objects/Hint") as Hint


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(STEP)


# Runs [param ticks] ticks, each followed by one rendered frame of [param hint].
func _tick(hint: Hint, ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(STEP)
		hint._process(STEP)


# Runs [param count] rendered frames of [param hint] with no tick.
func _frames(hint: Hint, count: int) -> void:
	for i: int in count:
		hint._process(STEP)


func _finish() -> void:
	_main.get_tree().paused = false
	GameState.reset()
