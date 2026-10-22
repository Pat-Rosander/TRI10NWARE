# Tests the run's results through a real Main scene on Level 1: the run's tick count across a death,
# a pause and a crossing's slide; the time formatting; the best-time comparison; the save and load
# round trip (to a test path); replay starting a fresh run; the HUD's coin counter; and the
# completion overlay's results (M6 step 5). Serves AC G-02, L1-04, V-04.
extends TestCase

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const PauseMenuScript: GDScript = preload("res://ui/pause_menu.gd")
const RUN_PATH: String = "user://test_run_results.cfg"

var _main: Node
var _world: WorldScript
var _player: Player


func test_run_ticks_count_from_start_through_a_death() -> void:
	_setup()
	_run(5)
	assert_eq(GameState.run_ticks, 0, "no ticks on the title")
	_world.start()
	_run(10)
	assert_eq(GameState.run_ticks, 10, "every tick of play")
	_player.flow.countdown_expired = true
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.DYING)
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING, "control returned")
	assert_eq(GameState.run_ticks, _world.tick, "the death freeze and respawn lock count")


func test_pause_and_a_crossing_slide_add_no_ticks() -> void:
	_setup()
	_world.start()
	_run(3)
	var pause: PauseMenuScript = _main.get_node("PauseMenu") as PauseMenuScript
	pause.open()
	assert_true(_main.get_tree().paused, "paused")
	assert_false(_world.can_process(), "World gets no physics steps while paused")
	pause.resume()
	assert_true(_world.can_process())
	_world.play_state = WorldScript.PlayState.TRANSITION
	_world._slide_steps_left = 100
	_run(5)
	assert_eq(GameState.run_ticks, 3, "the slide counts no tick")
	assert_eq(GameState.run_ticks, _world.tick)


func test_format_time() -> void:
	assert_eq(GameState.format_time(0), "0:00.00")
	assert_eq(GameState.format_time(59), "0:00.98", "hundredths round down")
	assert_eq(GameState.format_time(60), "0:01.00")
	assert_eq(GameState.format_time(3601), "1:00.01")
	assert_eq(GameState.format_time(60 * 60 * 75 + 30), "75:00.50", "minutes keep counting")


func test_best_time_comparison() -> void:
	assert_true(GameState.is_new_best(500, 0), "the first completion is a new best")
	assert_true(GameState.is_new_best(499, 500), "faster")
	assert_false(GameState.is_new_best(500, 500), "a tie is not")
	assert_false(GameState.is_new_best(501, 500), "slower")
	var path: String = GameState.best_path
	GameState.best_path = RUN_PATH
	GameState.best_ticks = 0
	GameState.run_ticks = 600
	assert_true(GameState.finish_run(), "first run")
	assert_eq(GameState.best_ticks, 600)
	GameState.run_ticks = 700
	assert_false(GameState.finish_run(), "slower run")
	assert_false(GameState.last_run_was_best)
	assert_eq(GameState.best_ticks, 600, "the best is kept")
	GameState.run_ticks = 550
	assert_true(GameState.finish_run(), "faster run")
	assert_eq(GameState.best_ticks, 550)
	_clean_up(path)


func test_best_time_save_and_load_round_trip() -> void:
	var path: String = GameState.best_path
	GameState.best_path = RUN_PATH
	GameState.best_ticks = 1234
	GameState.save_best()
	GameState.best_ticks = 0
	GameState.load_best()
	assert_eq(GameState.best_ticks, 1234, "loaded back")
	var file: ConfigFile = ConfigFile.new()
	file.set_value(GameState.BEST_SECTION, GameState.BEST_KEY, "garbage")
	file.save(RUN_PATH)
	GameState.best_ticks = 0
	GameState.load_best()
	assert_eq(GameState.best_ticks, 0, "an invalid value is ignored")
	DirAccess.remove_absolute(RUN_PATH)
	GameState.load_best()
	assert_eq(GameState.best_ticks, 0, "a missing file is ignored")
	assert_eq(take_errors(), [] as Array[String], "nothing errors")
	_clean_up(path)


func test_completion_shows_results_and_replay_starts_a_fresh_run() -> void:
	var path: String = GameState.best_path
	GameState.best_path = RUN_PATH
	GameState.best_ticks = 0
	_setup()
	_world.start()
	GameState.commit("level_1/Collectible")
	_run(4)
	_stand_on_goal()
	_run(1)
	assert_eq(_world.play_state, WorldScript.PlayState.COMPLETE)
	assert_eq(GameState.run_ticks, 5, "the completing tick counts")
	assert_eq(GameState.best_ticks, 5, "the first completion is the best")
	var completion: CanvasLayer = _main.get_node("CompletionOverlay") as CanvasLayer
	assert_true(completion.visible, "the completion overlay shows")
	assert_eq(_text(completion, "Coins"), "Coins: 1")
	assert_eq(_text(completion, "Time"), "Time: 0:00.08")
	assert_eq(_text(completion, "Best"), "Best: 0:00.08")
	assert_true(completion.get_node("%NewBest").visible, "New best!")
	_world.replay()
	assert_eq(GameState.committed_ids().size(), 0, "collectibles cleared")
	assert_eq(GameState.run_ticks, 0, "the timer restarts")
	assert_eq(GameState.best_ticks, 5, "the best is kept")
	assert_eq(_world.room_id, WorldScript.CATALOG.start_room, "the start room")
	assert_eq(_world.checkpoint, WorldScript.CATALOG.start_entrance, "at its start")
	_world.load_room(&"level_1", &"start")
	_run(9)
	_stand_on_goal()
	_run(1)
	assert_eq(GameState.run_ticks, 10)
	assert_false(completion.get_node("%NewBest").visible, "slower: no New best!")
	assert_eq(_text(completion, "Best"), "Best: 0:00.08", "the old best stays")
	_clean_up(path)


func test_hud_coin_counter_slides_in_and_hides() -> void:
	_setup()
	_world.start()
	var hud: CanvasLayer = _main.get_node("HUD") as CanvasLayer
	var counter: Control = hud.get_node("%CoinCounter") as Control
	var step: float = 1.0 / 60.0
	hud.call(&"_process", step)
	assert_false(counter.visible, "hidden at the start")
	Trace.record("collectible", {"id": "level_1/Collectible", "change": "touched"})
	_frames(hud, 0.5)
	assert_true(counter.visible, "a touch shows it")
	assert_eq(counter.position.x, 0.0, "fully slid in")
	assert_eq(_text(hud, "CoinCount"), "0", "the count only goes up on commit")
	GameState.commit("level_1/Collectible")
	Trace.record("collectible", {"id": "level_1/Collectible", "change": "committed"})
	hud.call(&"_process", step)
	assert_eq(_text(hud, "CoinCount"), "1", "a commit ticks it up")
	_frames(hud, Tuning.data.coin_counter_s - 0.1)
	assert_true(counter.visible, "still there just before coin_counter_s")
	_frames(hud, 0.5)
	assert_false(counter.visible, "slid out after coin_counter_s")
	var pause: PauseMenuScript = _main.get_node("PauseMenu") as PauseMenuScript
	pause.open()
	_frames(hud, 5.0)
	assert_true(counter.visible, "shown while the pause menu is open")
	pause.resume()
	_frames(hud, 0.5)
	assert_false(counter.visible, "hidden again after resuming")
	GameState.reset()


# A Main scene on Level 1, on the title, its World reading a ScriptedInputSource.
func _setup() -> void:
	Trace.begin_session(true)
	GameState.reset()
	_main = add_node(MAIN_SCENE.instantiate())
	_world = _main.get_node("World") as WorldScript
	_player = _world.get_node("Player") as Player
	var input: ScriptedInputSource = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(input)
	# The game starts in tutorial_1 (M6 step 2); these tests run in Level 1.
	_world.load_room(&"level_1", &"start")


# Moves the player onto Level 1's goal.
func _stand_on_goal() -> void:
	var goal: GoalZone = _world._goals[0]
	# Level 1's goal is a banner goal (M7 step 1); here it stands in for the final room's goal.
	goal.completes_game = true
	_player.respawn(Vector2i(roundi(goal.position.x + goal.width_px / 2.0), roundi(goal.position.y)),
			_player.mover.grid)


func _run(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(1.0 / Tuning.TICKS_PER_SECOND)


# Runs [param hud]'s _process for [param seconds] of rendered 60 Hz frames.
func _frames(hud: CanvasLayer, seconds: float) -> void:
	for i: int in roundi(seconds * 60.0):
		hud.call(&"_process", 1.0 / 60.0)


func _text(layer: CanvasLayer, unique_name: String) -> String:
	return (layer.get_node("%" + unique_name) as Label).text


# Restores the best-time path and removes the test file.
func _clean_up(path: String) -> void:
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(RUN_PATH)
	GameState.best_path = path
	GameState.best_ticks = 0
	GameState.reset()
