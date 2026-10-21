# Tests step 10's completion check in the real player scene on a small grid built in code: the
# goal zone's edges, completion on the landing tick, no completion from side contact or flying
# through the zone, and the fixed order goal, countdown, fall. Stands in for l1_04's completion
# cases until its scenarios run. Serves AC L1-04.
extends TestCase

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const WorldScript: GDScript = preload("res://world/world.gd")
const ROOM: Rect2i = Rect2i(0, 0, 640, 368)
# A pillar of ordinary tiles, columns 10–14, from row 15 (top surface y 240) to the bottom.
const PILLAR_COLUMNS: Vector2i = Vector2i(10, 14)
const SURFACE_ROW: int = 15
const SURFACE_Y: int = SURFACE_ROW * 16

var _player: Player


func test_contains_feet_edges() -> void:
	var goal: GoalZone = _goal(Vector2i(100, 200), 32)
	assert_true(goal.contains_feet(Vector2i(100, 200)), "left end, on the surface")
	assert_true(goal.contains_feet(Vector2i(131, 200)), "right end, on the surface")
	assert_false(goal.contains_feet(Vector2i(132, 200)), "one pixel past the right end")
	assert_false(goal.contains_feet(Vector2i(99, 200)), "one pixel before the left end")
	assert_false(goal.contains_feet(Vector2i(110, 201)), "one pixel below the surface")
	assert_true(goal.contains_feet(Vector2i(110, 196)), "the zone's top row")
	assert_false(goal.contains_feet(Vector2i(110, 195)), "one pixel above the zone")


func test_landing_on_top_completes_on_the_landing_tick() -> void:
	var goals: Array[GoalZone] = [_goal(Vector2i(160, SURFACE_Y), 80)]
	_setup(Vector2i(200, SURFACE_Y - 40))
	var landed_on: int = -1
	var completed_on: int = -1
	for t: int in range(1, 60):
		_tick(t, InputFrame.new())
		if landed_on < 0 and _player.state.grounded:
			landed_on = t
		if completed_on < 0 and WorldScript.outcome(_player, goals) == WorldScript.Outcome.COMPLETE:
			completed_on = t
	assert_true(landed_on > 1, "the player fell, then landed")
	assert_eq(completed_on, landed_on, "complete on the landing tick, not before")


func test_side_contact_never_completes() -> void:
	# The zone covers the whole top surface; the player slides down the pillar's left wall.
	var goals: Array[GoalZone] = [_goal(Vector2i(160, SURFACE_Y), 80)]
	_setup(Vector2i(150, SURFACE_Y + 24))
	var right: InputFrame = InputFrame.new()
	right.direction = Vector2i(1, 0)
	var result: int = WorldScript.Outcome.NONE
	for t: int in range(1, 120):
		_tick(t, right)
		result = WorldScript.outcome(_player, goals)
		if result != WorldScript.Outcome.NONE:
			break
	assert_eq(result, WorldScript.Outcome.FELL, "sliding past the side ends in a fall")


func test_flying_through_the_zone_never_completes() -> void:
	# A zone in open air: the falling player's feet pass through it, never grounded.
	var goals: Array[GoalZone] = [_goal(Vector2i(100, 200), 200)]
	_setup(Vector2i(200, 150), false)
	var passed_through: bool = false
	var result: int = WorldScript.Outcome.NONE
	for t: int in range(1, 120):
		_tick(t, InputFrame.new())
		passed_through = passed_through or goals[0].contains_feet(_player.mover.position)
		result = WorldScript.outcome(_player, goals)
		if result != WorldScript.Outcome.NONE:
			break
	assert_true(passed_through, "the feet were inside the zone on some tick")
	assert_eq(result, WorldScript.Outcome.FELL, "falling through ends in a fall, not completion")


func test_goal_beats_countdown_and_countdown_beats_fall() -> void:
	var goals: Array[GoalZone] = [_goal(Vector2i(160, SURFACE_Y), 80)]
	_setup(Vector2i(200, SURFACE_Y))
	_player.flow.countdown_expired = true
	assert_eq(WorldScript.outcome(_player, goals), WorldScript.Outcome.COMPLETE,
			"goal and countdown expiry on one tick: the goal wins")
	_player.state.grounded = false
	assert_eq(WorldScript.outcome(_player, goals), WorldScript.Outcome.COUNTDOWN,
			"airborne in the zone: no goal, so the countdown")
	_player.mover.position = Vector2i(200, ROOM.end.y + Tuning.data.fall_margin_px + 1)
	assert_eq(WorldScript.outcome(_player, goals), WorldScript.Outcome.COUNTDOWN,
			"countdown expiry and a fall on one tick: the countdown wins")
	_player.flow.countdown_expired = false
	assert_eq(WorldScript.outcome(_player, goals), WorldScript.Outcome.FELL, "then the fall")


# A player with its feet at [param feet], on a grid holding the pillar if [param pillar].
func _setup(feet: Vector2i, pillar: bool = true) -> void:
	Trace.begin_session(true)
	var grid: SolidGrid = _new_grid(ROOM)
	if pillar:
		for x: int in range(PILLAR_COLUMNS.x, PILLAR_COLUMNS.y + 1):
			for y: int in range(SURFACE_ROW, 23):
				grid.set_cell(Vector2i(x, y), SolidGrid.ORDINARY)
	_player = add_node(PLAYER_SCENE.instantiate()) as Player
	_player.respawn(feet, grid)


func _goal(origin: Vector2i, width: int) -> GoalZone:
	var goal: GoalZone = GoalZone.new()
	goal.position = Vector2(origin)
	goal.width_px = width
	return add_node(goal) as GoalZone


# One tick of World's steps 1–9 on the player.
func _tick(t: int, frame: InputFrame) -> void:
	Trace.tick = t
	_player.step_switch(frame)
	_player.step_dash(frame, t)
	_player.step_jump(frame, t)
	_player.step_integrate(frame)
	_player.step_move()
	_player.step_sense()
	_player.step_timers()


# A grid for [param room] with the spike hitbox from tuning.
func _new_grid(room: Rect2i) -> SolidGrid:
	return SolidGrid.new(room, Tuning.data.spike_depth_px, Tuning.data.spike_inset_px)
