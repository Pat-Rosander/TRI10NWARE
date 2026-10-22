# Tests level goals through a real Main scene in Level 1 (M7 step 1): a banner goal logs
# room_complete and goal_banner once per run, never stops play or the run timer, shows the HUD
# banner for level_banner_s and does not fire again after a death or a re-entry; a new run fires it
# again; a completes_game goal ends the run and shows the completion overlay. Serves AC L1-04.
extends TestCase

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const HudScript: GDScript = preload("res://ui/hud.gd")
const STEP: float = 1.0 / 60.0

var _main: Node
var _world: WorldScript
var _player: Player
var _hud: HudScript
var _completion: CanvasLayer


func test_level_1_goal_is_a_banner_goal() -> void:
	_setup()
	var goal: GoalZone = _goal()
	assert_eq(goal.id, "level_1/GoalZone", "room ID plus node name")
	assert_eq(goal.banner_level, 1, "Level 1's banner")
	assert_false(goal.completes_game, "Level 1's goal does not end the game")
	assert_true(GoalZone.new().completes_game, "a new goal ends the game by default")
	_finish()


func test_banner_goal_logs_once_and_play_goes_on() -> void:
	_setup()
	_stand_on_goal()
	_tick(1)
	assert_eq(_count("room_complete"), 1, "room_complete on the landing tick")
	var banners: Array[Dictionary] = _events("goal_banner")
	assert_eq(banners.size(), 1, "goal_banner on the same tick")
	assert_eq(banners[0]["data"]["level"], 1, "with the goal's level")
	assert_eq(banners[0]["tick"], _events("room_complete")[0]["tick"], "both on one tick")
	assert_true(GameState.is_banner_shown("level_1/GoalZone"), "remembered for the run")
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING, "play goes on")
	var ticks: int = GameState.run_ticks
	_tick(30)
	assert_eq(GameState.run_ticks, ticks + 30, "the run timer keeps running")
	assert_eq(_count("room_complete") + _count("goal_banner"), 2, "standing on it logs nothing more")
	assert_false(GameState.completed, "the game is not completed")
	assert_false(_completion.visible, "no completion overlay")
	_finish()


func test_banner_shows_for_level_banner_s() -> void:
	_setup()
	_stand_on_goal()
	assert_false(_hud.is_banner_showing(), "hidden before the goal")
	_tick(1)
	assert_true(_hud.is_banner_showing(), "shown when the goal is reached")
	assert_eq((_hud.get_node("%LevelBanner") as Label).text, "Level 1 complete")
	_frames(600)
	assert_true(_hud.is_banner_showing(), "rendered frames without ticks add no time")
	_tick(Tuning.level_banner_ticks - 1)
	assert_true(_hud.is_banner_showing(), "one tick before level_banner_s")
	_tick(1)
	assert_false(_hud.is_banner_showing(), "gone after level_banner_s of run ticks")
	_finish()


func test_a_fresh_banner_goal_beats_countdown_expiry_on_its_tick() -> void:
	_setup()
	_stand_on_goal()
	_player.flow.countdown_expired = true
	_tick(1)
	assert_eq(_count("goal_banner"), 1, "the goal is step 10's outcome")
	assert_eq(_count("death"), 0, "so the countdown does not kill on that tick")
	_finish()


func test_a_reached_banner_goal_never_blocks_a_death() -> void:
	_setup()
	_stand_on_goal()
	_tick(1)
	_player.flow.countdown_expired = true
	_tick(1)
	assert_eq(_events("death")[0]["data"]["cause"], "countdown", "standing on it, the countdown kills")
	_finish()


func test_no_repeat_after_a_death_or_a_re_entry() -> void:
	_setup()
	_stand_on_goal()
	_tick(1)
	_world.restart_room()
	for i: int in 120:
		if _world.play_state == WorldScript.PlayState.PLAYING:
			break
		_tick(1)
	assert_eq(_world.play_state, WorldScript.PlayState.PLAYING, "respawned")
	_stand_on_goal()
	_tick(5)
	assert_eq(_count("goal_banner"), 1, "not again after a death")
	_world.load_room(&"tutorial_1", &"start")
	_world.load_room(&"level_1", &"start")
	_stand_on_goal()
	_tick(5)
	assert_eq(_count("goal_banner"), 1, "not again on a re-entry")
	assert_eq(_count("room_complete"), 1, "room_complete only the first time")
	_finish()


func test_a_new_run_fires_it_again() -> void:
	_setup()
	_stand_on_goal()
	_tick(1)
	_world.play_state = WorldScript.PlayState.COMPLETE
	_world.replay()
	assert_false(GameState.is_banner_shown("level_1/GoalZone"), "a new run forgets it")
	_world.load_room(&"level_1", &"start")
	_stand_on_goal()
	_tick(1)
	assert_eq(_count("goal_banner"), 2, "fired again in the new run")
	_finish()


func test_completes_game_goal_ends_the_run() -> void:
	_setup()
	_goal().completes_game = true
	_stand_on_goal()
	_tick(1)
	assert_eq(_count("room_complete"), 1, "room_complete")
	assert_eq(_count("goal_banner"), 0, "no banner")
	assert_false(_hud.is_banner_showing(), "no banner shown")
	assert_true(GameState.completed, "the game is completed")
	assert_eq(_world.play_state, WorldScript.PlayState.COMPLETE, "play stops")
	var ticks: int = GameState.run_ticks
	_tick(10)
	assert_eq(GameState.run_ticks, ticks, "the run timer stops")
	assert_true(_completion.visible, "the completion overlay shows")
	_finish()


# A Main scene playing in Level 1, its World reading a ScriptedInputSource.
func _setup() -> void:
	Trace.begin_session(true)
	GameState.reset()
	_main = add_node(MAIN_SCENE.instantiate())
	_world = _main.get_node("World") as WorldScript
	_player = _world.get_node("Player") as Player
	_hud = _main.get_node("HUD") as HudScript
	_completion = _main.get_node("CompletionOverlay") as CanvasLayer
	var input: ScriptedInputSource = add_node(ScriptedInputSource.new()) as ScriptedInputSource
	_world.set_input_source(input)
	_world.start()
	_world.load_room(&"level_1", &"start")


# The current room's goal.
func _goal() -> GoalZone:
	return _world._goals[0]


# Places the player's feet on the middle of the current room's goal.
func _stand_on_goal() -> void:
	var goal: GoalZone = _goal()
	_player.respawn(Vector2i(roundi(goal.position.x + goal.width_px / 2.0), roundi(goal.position.y)),
			_player.mover.grid)


# Runs [param ticks] ticks, each followed by one rendered HUD frame.
func _tick(ticks: int) -> void:
	for i: int in ticks:
		_world._physics_process(STEP)
		_hud._process(STEP)


# Runs [param count] rendered HUD frames with no tick.
func _frames(count: int) -> void:
	for i: int in count:
		_hud._process(STEP)


func _events(name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in Trace.get_events():
		if entry["event"] == name:
			found.append(entry)
	return found


func _count(name: String) -> int:
	return _events(name).size()


func _finish() -> void:
	GameState.reset()
