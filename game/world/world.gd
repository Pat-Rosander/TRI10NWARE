# World, the referee: the project's only _physics_process. Runs the 11-step tick in a fixed order,
# so every same-tick tie resolves the same way; from M1 it also loads rooms. Serves AC D-04, D-05, R-04.
extends Node2D

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
# M0 only, replaced in M1 step 4: the input source World made itself, freed when replaced.
var _own_input_source: InputSource


func _ready() -> void:
	# M0 only, replaced in M1 step 4: with no Player yet, World makes its own live input source.
	if _input_source == null:
		var live: LiveInputSource = LiveInputSource.new()
		live.name = "InputSource"
		add_child(live)
		_input_source = live
		_own_input_source = live


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
	# M0 only, replaced in M1 step 4: free World's own source so two never run at once.
	if _own_input_source != null and _own_input_source != source:
		_own_input_source.queue_free()
		_own_input_source = null


func _set_slow_divisor(value: int) -> void:
	if value != 1 and value != 2 and value != 4:
		push_error("World: slow_divisor must be 1, 2 or 4, got %d." % value)
		return
	slow_divisor = value
	_slow_phase = 0


# Step 1: read this tick's input.
func _step_input() -> void:
	frame = _input_source.read(tick)


# Step 2: default and flow switch (M2).
func _step_switch() -> void:
	pass


# Step 3: dash (M1).
func _step_dash() -> void:
	pass


# Step 4: at most one jump (M1).
func _step_jump() -> void:
	pass


# Step 5: gravity and speed (M1).
func _step_integrate() -> void:
	pass


# Step 6: move, stopping at anything solid (M1).
func _step_move() -> void:
	pass


# Step 7: grounded, walls, charged-object areas (M1, M2).
func _step_sense() -> void:
	pass


# Step 8: power-source contacts and recharge (M2, M5).
func _step_contacts() -> void:
	pass


# Step 9: countdown and short timers (M1, M2).
func _step_timers() -> void:
	pass


# Step 10: goal, countdown expiry, falls (M2, M3).
func _step_outcomes() -> void:
	pass


# Step 11: publish the new state; the camera target is set here (M1).
func _step_publish() -> void:
	pass
