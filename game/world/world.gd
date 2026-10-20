# World, the referee: the project's only _physics_process. Runs the 11-step tick in a fixed order,
# so every same-tick tie resolves the same way; from M1 it also loads rooms, and from M3 completes
# them. Serves AC D-04, D-05, R-04, L1-04.
extends Node2D

const CameraRigScript := preload("res://world/camera_rig.gd")
const CATALOG: RoomCatalog = preload("res://rooms/room_catalog.tres")
## Where a completed room replays from, until M3 step 2's completion overlay.
const START_ENTRANCE: StringName = &"start"

## Step 10's result, decided in this fixed order (Same-tick contract).
enum Outcome { NONE, COMPLETE, COUNTDOWN, FELL }

## The current tick. Counts only while the rules run, never on skipped or frozen physics steps.
var tick: int = 0
## Whether the simulation advances. In M0, Main starts it at launch.
var running: bool = false
## The input read on the latest tick; the only input the rules see (ground rule 5).
var frame: InputFrame = InputFrame.new()
## Debug freeze: while on, ticks run only one at a time through request_step().
var debug_frozen: bool = false
## Debug slow motion: 1 runs every physics step, 2 every 2nd, 4 every 4th.
var slow_divisor: int = 1: set = _set_slow_divisor
## The current room's ID, and the entrance a respawn returns to (the checkpoint).
var room_id: StringName
var checkpoint: StringName

# The current room's goal zones, sorted by node name.
var _goals: Array[GoalZone] = []
var _input_source: InputSource
var _step_requested: bool = false
# Physics steps since the last tick that ran, for slow motion.
var _slow_phase: int = 0

@onready var _player: Player = $Player
@onready var _camera: CameraRigScript = $Camera


func _ready() -> void:
	if _input_source == null:
		_input_source = _player.input_source
	load_room(CATALOG.start_room, CATALOG.start_entrance)


func _physics_process(_delta: float) -> void:
	if not running:
		return
	if debug_frozen:
		if not _step_requested:
			return
		_step_requested = false
	else:
		_slow_phase += 1
		if _slow_phase < slow_divisor:
			return
		_slow_phase = 0
	tick += 1
	Trace.tick = tick
	_step_input()
	_step_switch()
	_step_dash()
	_step_jump()
	_step_integrate()
	_step_move()
	_step_sense()
	_step_contacts()
	_step_timers()
	_step_outcomes()
	_step_publish()


## Starts the simulation. Ticks advance from the next physics step.
func start() -> void:
	running = true


## While frozen, runs exactly one tick on the next physics step.
func request_step() -> void:
	_step_requested = true


## Plugs in the input source the rules read from, for example a ScriptedInputSource for a
## scenario run. The source must already be in the scene tree if it reads live events.
func set_input_source(source: InputSource) -> void:
	_input_source = source


## Step 10's decision for [param player] in a room with [param goals]: the goal (grounded, feet
## inside a zone), then countdown expiry, then a fall; the first that applies wins.
static func outcome(player: Player, goals: Array[GoalZone]) -> Outcome:
	if player.state.grounded:
		for goal: GoalZone in goals:
			if goal.contains_feet(player.mover.position):
				return Outcome.COMPLETE
	if player.flow.countdown_expired:
		return Outcome.COUNTDOWN
	if player.fell():
		return Outcome.FELL
	return Outcome.NONE


## Builds [param id] fresh from the catalog and places the player at [param entrance_id] with
## fresh state, replacing any current room. Used at game start, for respawns, by the debug menu
## and by scenarios. Logs `room_enter`, or `respawn` when [param is_respawn] is true.
func load_room(id: StringName, entrance_id: StringName, is_respawn: bool = false) -> void:
	var entry: RoomEntry = CATALOG.find(id)
	if entry == null:
		return
	var slot: Node = $RoomSlot
	for old: Node in slot.get_children():
		slot.remove_child(old)
		old.queue_free()
	var room: Room = entry.scene.instantiate() as Room
	room.position = Vector2(entry.world_rect.position)
	slot.add_child(room)
	var grid: SolidGrid = room.build_grid()
	var entrance: RoomEntrance = room.entrance(entrance_id)
	if entrance == null:
		return
	room_id = id
	checkpoint = entrance_id
	_goals = room.goal_zones()
	Trace.room = String(id)
	_player.respawn(entry.world_rect.position + entrance.feet(), grid, entrance.facing,
			room.charged_objects())
	if is_respawn:
		_input_source.mark_all_stale()
	_camera.set_bounds(room.bounds)
	_camera.move_to(_player.mover.position)
	_camera.reset_physics_interpolation()
	Trace.record("respawn" if is_respawn else "room_enter",
			{"room": String(id), "entrance": String(entrance_id)})


func _set_slow_divisor(value: int) -> void:
	if value != 1 and value != 2 and value != 4:
		push_error("World: slow_divisor must be 1, 2 or 4, got %d." % value)
		return
	slow_divisor = value
	_slow_phase = 0


# Step 1: read this tick's input. Expired tokens are reported first, so a token whose window
# already closed is never reported as replaced by the new press.
func _step_input() -> void:
	frame = _input_source.read(tick)
	_expire_token(_player.jump_buffer, "jump")
	_expire_token(_player.dash_buffer, "dash")
	if frame.jump_pressed:
		_add_token(_player.jump_buffer, "jump")
	if frame.dash_pressed:
		_add_token(_player.dash_buffer, "dash")


# Step 2: default and flow switch.
func _step_switch() -> void:
	_player.step_switch(frame)


# Step 3: dash.
func _step_dash() -> void:
	_player.step_dash(frame, tick)


# Step 4: at most one jump.
func _step_jump() -> void:
	_player.step_jump(frame, tick)


# Step 5: gravity and speed.
func _step_integrate() -> void:
	_player.step_integrate(frame)


# Step 6: move, stopping at anything solid.
func _step_move() -> void:
	_player.step_move()


# Step 7: grounded, walls, charged-object regions.
func _step_sense() -> void:
	_player.step_sense()


# Step 8: power-source contacts and recharge (M2, M5).
func _step_contacts() -> void:
	pass


# Step 9: the countdown and short timers.
func _step_timers() -> void:
	_player.step_timers()


# Step 10: goal, countdown expiry, falls, in that order. Until M3 step 2 adds the play states, a
# death resets the player at once, and a completion replays the room from its start (the
# rebuild means room_complete is logged once per arrival).
func _step_outcomes() -> void:
	match outcome(_player, _goals):
		Outcome.COMPLETE:
			Trace.record("room_complete", {"room": String(room_id)})
			load_room(room_id, START_ENTRANCE)
			_input_source.mark_all_stale()
		Outcome.COUNTDOWN:
			Trace.record("death", {"cause": "countdown"})
			load_room(room_id, checkpoint, true)
		Outcome.FELL:
			Trace.record("death", {"cause": "fell"})
			load_room(room_id, checkpoint, true)


# Step 11: publish the new state; the camera target is set here.
func _step_publish() -> void:
	_player.publish()
	_camera.move_to(_player.mover.position)


# Reports and removes the token in [param buffer] if its window has closed.
func _expire_token(buffer: PressBuffer, action: String) -> void:
	var created: int = buffer.expire(tick)
	if created != PressBuffer.NONE:
		Trace.record("press_expired", {"action": action, "created_tick": created})


# Turns a fresh press into a token; an unspent token it replaces is reported as expired.
func _add_token(buffer: PressBuffer, action: String) -> void:
	var replaced: int = buffer.press(tick)
	if replaced != PressBuffer.NONE:
		Trace.record("press_expired", {"action": action, "created_tick": replaced})
	Trace.record("press", {"action": action})
