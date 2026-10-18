# World, the referee: the project's only _physics_process. Runs the 11-step tick in a fixed order,
# so every same-tick tie resolves the same way; from M1 it also loads rooms. Serves AC D-04, D-05, R-04.
extends Node2D

const CameraRigScript := preload("res://world/camera_rig.gd")

# M1 step 4 only, replaced by load_room() in step 5: the temporary test floor and its spawn.
const _TEST_SIZE: Vector2i = Vector2i(640, 368)
# M1 step 4 only: the feet on the floor's top, 4.5 tiles from the left edge.
const _TEST_SPAWN: Vector2i = Vector2i(72, 336)
# M1 step 4 only: areas of solid cells (position and size in cells), painted with atlas tile (0, 0).
const _TEST_SOLIDS: Array[Rect2i] = [
	Rect2i(0, 21, 22, 2),   # floor, left of the pit
	Rect2i(26, 21, 14, 2),  # floor, right of the pit (cells 22–25 are the pit)
	Rect2i(0, 0, 1, 21),    # left wall
	Rect2i(39, 0, 1, 21),   # right wall
	Rect2i(7, 19, 5, 2),    # a 2-tile step, to walk off for coyote jumps
	Rect2i(16, 6, 2, 15),   # a tall pillar, for wall jumps
	Rect2i(30, 19, 6, 2),   # a 2-tile ledge past the pit
]

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

var _input_source: InputSource
var _step_requested: bool = false
# Physics steps since the last tick that ran, for slow motion.
var _slow_phase: int = 0
# True when the player was placed rather than moved this tick, so step 11 resets the camera's
# interpolation after moving it.
var _teleported: bool = false
# M1 step 4 only: the grid of the temporary test floor.
var _test_grid: SolidGrid

@onready var _player: Player = $Player
@onready var _camera: CameraRigScript = $Camera


func _ready() -> void:
	if _input_source == null:
		_input_source = _player.input_source
	_build_test_floor()
	_player.respawn(_TEST_SPAWN, _test_grid)
	_camera.set_bounds(_test_grid.bounds)
	_camera.move_to(_player.mover.position)
	_camera.reset_physics_interpolation()


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


# Step 2: default and flow switch (M2).
func _step_switch() -> void:
	pass


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


# Step 7: grounded, walls, charged-object areas (M2).
func _step_sense() -> void:
	_player.step_sense()


# Step 8: power-source contacts and recharge (M2, M5).
func _step_contacts() -> void:
	pass


# Step 9: countdown (M2) and short timers.
func _step_timers() -> void:
	_player.step_timers()


# Step 10: goal (M3), countdown expiry (M2), falls. In M1 a fall resets the player at once;
# M3 adds the full death sequence.
func _step_outcomes() -> void:
	if _player.fell():
		Trace.record("death", {"cause": "fell"})
		# M1 step 4 only: the test floor's spawn; step 5 respawns at the current entrance.
		_player.respawn(_TEST_SPAWN, _test_grid)
		_input_source.mark_all_stale()
		_teleported = true


# Step 11: publish the new state; the camera target is set here.
func _step_publish() -> void:
	_player.publish()
	_camera.move_to(_player.mover.position)
	if _teleported:
		_camera.reset_physics_interpolation()
		_teleported = false


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


# M1 step 4 only, replaced by load_room() in step 5: paints the temporary test floor into a
# tile layer under RoomSlot and builds its SolidGrid.
func _build_test_floor() -> void:
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = "TestFloor"
	layer.tile_set = load("res://tiles/level_tiles.tres")
	for area: Rect2i in _TEST_SOLIDS:
		for y: int in range(area.position.y, area.end.y):
			for x: int in range(area.position.x, area.end.x):
				layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	$RoomSlot.add_child(layer)
	_test_grid = SolidGrid.new(Rect2i(Vector2i.ZERO, _TEST_SIZE))
	_test_grid.add_layer(layer)
