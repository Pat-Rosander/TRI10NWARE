# The player: holds the movement rule objects (PixelMover, DashState, the press buffers and a
# small movement-state record) and the step methods World calls each tick; its FlowController
# holds state, volts and the countdown. Senses the room's charged objects and fires the charged
# jump. No _physics_process.
# Serves AC M-01, M-02, M-03, M-04, M-05, M-06, M-07, R-01, S-01, C-01 to C-08, P-01 to P-04.
class_name Player
extends Node2D

## The player's changing movement state that lives in no rule object. Replaced on respawn.
class MoveState extends RefCounted:
	## Ticks of jump sustain left: while above 0 and jump is held, the rise holds at jump speed.
	var sustain_ticks: int = 0
	## Whether the soft apex (lighter gravity near the top of a held jump) may apply.
	var soft_apex: bool = true
	## Ticks of wall-jump lock left, and the horizontal direction forced meanwhile.
	var wall_lock_ticks: int = 0
	var wall_lock_dir: int = 0
	## Airborne decision ticks left in which a coyote jump may fire.
	var coyote_ticks: int = 0
	## -1 left, 1 right.
	var facing: int = 1
	## What step 7 sensed; steps 3 and 4 of the next tick decide with it.
	var grounded: bool = false
	var wall_left: bool = false
	var wall_right: bool = false


## Every rule object is replaced, never reset, on respawn (R-01).
var mover: PixelMover
var dash: DashState
var jump_buffer: PressBuffer
var dash_buffer: PressBuffer
var state: MoveState
## The current room's charged objects, sorted by node name; set on every respawn.
var charged: Array[ChargedObject] = []

## The live input source in the scene; World reads it unless a scenario swaps in another.
@onready var input_source: InputSource = $InputSource
## State, volts and the zero-volt countdown (M2).
@onready var flow: FlowController = $FlowController

# Vertical velocity before step 6's move, for land's vy_before.
var _vy_before_move: float = 0.0


## Places the feet at [param feet] in [param grid] with fresh rule objects (default state, full
## volts), facing [param facing]. Grounded, walls and coyote are sensed at once (no land is logged), so the
## first tick's decisions see the real state. [param charged_objects] are the room's charged
## objects in node-name order (a rebuilt room brings fresh trackers).
func respawn(feet: Vector2i, grid: SolidGrid, facing: int = 1,
		charged_objects: Array[ChargedObject] = []) -> void:
	charged = charged_objects
	var data: TuningData = Tuning.data
	mover = PixelMover.new(grid, data.body_size_px, data.wall_check_px, Tuning.TICKS_PER_SECOND,
			data.corner_correction_px, data.dash_corner_correction_px, data.oneway_assist_px,
			data.post_dash_snap_px, data.apex_threshold_px_s)
	mover.position = feet
	dash = DashState.new(Tuning.dash_ticks, Tuning.dash_cooldown_ticks, data.dash_speed_px_s,
			data.dash_end_speed_px_s, data.dash_end_up_mult, data.charged_refill_clears_cooldown)
	jump_buffer = PressBuffer.new(Tuning.jump_buffer_ticks)
	dash_buffer = PressBuffer.new(Tuning.dash_buffer_ticks)
	state = MoveState.new()
	state.facing = facing
	flow.reset(grid)
	_vy_before_move = 0.0
	_sense_contacts()
	position = Vector2(feet)
	reset_physics_interpolation()


## Step 2: on a fresh switch press, switches state through the FlowController, which applies
## the overlap policy. A snap onto a platform top is a landing on this tick: land is logged here,
## once, and this tick's decisions see the player grounded. If the floor vanished with the old
## platform family, coyote time starts exactly as on walking off a ledge. Otherwise position,
## velocity and an active dash are untouched (S-01).
func step_switch(frame: InputFrame) -> void:
	if not frame.switch_pressed or not flow.request_switch(mover):
		return
	if flow.snapped:
		var was_grounded: bool = state.grounded
		_sense_contacts()
		if state.grounded and not was_grounded:
			Trace.record("land", {"vx": mover.velocity_x, "vy_before": flow.snap_vy_before})
	elif state.grounded and not mover.is_grounded():
		state.grounded = false
		state.coyote_ticks = Tuning.coyote_ticks


## Step 3: starts a dash if the dash buffer holds a token and DashState allows a start (M-03).
func step_dash(frame: InputFrame, tick: int) -> void:
	if not dash_buffer.can_spend(tick) or not dash.can_start():
		return
	var created: int = dash_buffer.spend(tick)
	Trace.record("press_spent", {"action": "dash", "created_tick": created, "spent_on": tick})
	dash.start(frame.direction, state.facing, tick)
	if dash.direction.x != 0:
		state.facing = dash.direction.x
	mover.velocity_x = dash.start_velocity_x()
	mover.velocity_y = dash.start_velocity_y()
	# A dash replaces a jump's arc completely: no upward pull returns when it ends.
	state.sustain_ticks = 0
	state.soft_apex = false
	Trace.record("dash_start", {"dir_x": dash.direction.x, "dir_y": dash.direction.y,
			"vx": mover.velocity_x, "vy": mover.velocity_y})


## Step 4: at most one jump, chosen by JumpResolver; then the coyote countdown (M-01, M-02,
## M-05, M-06, C-01 to C-08).
func step_jump(frame: InputFrame, tick: int) -> void:
	if jump_buffer.can_spend(tick):
		var kind: JumpResolver.Kind = JumpResolver.resolve(state.grounded, state.coyote_ticks > 0,
				_charged_eligible(), state.wall_left or state.wall_right, dash.is_active(),
				jump_buffer.created_tick(), dash.start_tick)
		if kind != JumpResolver.Kind.NONE:
			_jump(kind, frame, tick)
	if not state.grounded and state.coyote_ticks > 0:
		state.coyote_ticks -= 1


## Step 5: run, air control, gravity, soft apex, sustain and fall cap. Velocity is left alone
## while dashing.
func step_integrate(frame: InputFrame) -> void:
	if dash.is_active():
		return
	var data: TuningData = Tuning.data
	var tps: float = Tuning.TICKS_PER_SECOND
	var x: int = state.wall_lock_dir if state.wall_lock_ticks > 0 else frame.direction.x
	var mult: float = 1.0 if state.grounded else data.air_control_mult
	var target: float = x * data.run_max_speed_px_s
	var vx: float = mover.velocity_x
	if absf(vx) > data.run_max_speed_px_s and int(signf(vx)) == x:
		vx = move_toward(vx, target, data.run_reduce_px_s2 * mult / tps)
	else:
		vx = move_toward(vx, target, data.run_accel_px_s2 * mult / tps)
	mover.velocity_x = vx

	var vy: float = mover.velocity_y
	var gravity_mult: float = 1.0
	if state.soft_apex and frame.jump_held and absf(vy) < data.apex_threshold_px_s:
		gravity_mult = data.apex_gravity_mult
	vy += data.gravity_px_s2 * gravity_mult / tps
	if state.sustain_ticks > 0:
		if frame.jump_held:
			vy = minf(vy, -data.jump_speed_px_s)
		else:
			state.sustain_ticks = 0
	vy = minf(vy, data.max_fall_speed_px_s)
	mover.velocity_y = vy

	if x != 0:
		state.facing = x


## Step 6: moves the body in whole pixels, with the corner and dash corner corrections.
func step_move() -> void:
	_vy_before_move = mover.velocity_y
	mover.move(state.facing, dash.direction if dash.is_active() else Vector2i.ZERO)
	if mover.dash_corner_shift != 0:
		_log_assist("dash_corner", 0, mover.dash_corner_shift)
	if mover.corner_shift != 0:
		_log_assist("corner", mover.corner_shift, 0)


## Step 7: pending platform tiles the body has cleared become solid; then the one-way platform
## help, grounded, landing, the ground refill, coyote and soft apex, walls and ceiling, then each
## charged object's encounter state in node-name order. A lift onto a platform counts as a
## landing.
func step_sense() -> void:
	flow.release_pending(mover.body_rect(mover.position))
	var was_grounded: bool = state.grounded
	var lift: int = mover.oneway_help()
	if lift != 0:
		_log_assist("oneway", 0, lift)
	_sense_contacts()
	if state.grounded and not was_grounded:
		Trace.record("land", {"vx": mover.velocity_x, "vy_before": _vy_before_move})
	if state.grounded and dash.refill_ground():
		Trace.record("dash_refill", {"cause": "ground"})
	if mover.ceiling_hit:
		state.sustain_ticks = 0
	var body: Rect2i = mover.body_rect(mover.position)
	for object: ChargedObject in charged:
		object.sense(body, Tuning.data.charged_exit_margin_px)


## Step 9: counts down the sustain, the wall-jump lock, the dash timers and the zero-volt
## countdown; applies the dash's end velocity and the post-dash floor snap on its last tick (M-03).
func step_timers() -> void:
	if state.sustain_ticks > 0:
		state.sustain_ticks -= 1
	if state.wall_lock_ticks > 0:
		state.wall_lock_ticks -= 1
	if dash.tick_timers():
		mover.velocity_x = dash.end_velocity_x()
		mover.velocity_y = dash.end_velocity_y()
		Trace.record("dash_end", {"vx": mover.velocity_x, "vy": mover.velocity_y,
				"interrupted": false})
		var drop: int = mover.post_dash_snap(dash.direction.y)
		if drop != 0:
			_log_assist("dash_snap", 0, drop)
	flow.step_timer()


## Step 10: true if step 6's move touched a spike hitbox.
func touched_spike() -> bool:
	return mover.spike_hit


## A room crossing: the player moves into [param grid] and [param charged_objects] (the new
## room's, in node-name order) with every rule object and all movement state kept (M6).
func enter_room(grid: SolidGrid, charged_objects: Array[ChargedObject]) -> void:
	mover.grid = grid
	flow.set_grid(grid)
	charged = charged_objects


## Step 10: true if the feet are below the room's failure line (bounds bottom + fall_margin_px).
func fell() -> bool:
	return mover.position.y > mover.grid.bounds.end.y + Tuning.data.fall_margin_px


## Step 11: moves the node to the feet, so the screen shows the tick's result.
func publish() -> void:
	position = Vector2(mover.position)


func _jump(kind: JumpResolver.Kind, frame: InputFrame, tick: int) -> void:
	var data: TuningData = Tuning.data
	var created: int = jump_buffer.spend(tick)
	Trace.record("press_spent", {"action": "jump", "created_tick": created, "spent_on": tick})
	state.coyote_ticks = 0
	state.soft_apex = kind != JumpResolver.Kind.CHARGED
	var object_name: String = ""
	match kind:
		JumpResolver.Kind.GROUND, JumpResolver.Kind.COYOTE:
			mover.velocity_y = -data.jump_speed_px_s
			if frame.direction.x != 0:
				mover.velocity_x += data.jump_h_boost_px_s * frame.direction.x
			state.sustain_ticks = Tuning.jump_sustain_ticks
		JumpResolver.Kind.WALL:
			# A wall jump never refills the dash (M-02).
			var side: int = JumpResolver.wall_jump_side(state.wall_left, state.wall_right,
					frame.direction.x, state.facing)
			mover.velocity_x = -side * data.wall_jump_h_speed_px_s
			mover.velocity_y = -data.jump_speed_px_s
			state.sustain_ticks = Tuning.jump_sustain_ticks
			state.wall_lock_ticks = Tuning.wall_jump_lock_ticks
			state.wall_lock_dir = -side
		JumpResolver.Kind.CHARGED:
			object_name = _charged_jump()
	Trace.record("jump", {"kind": JumpResolver.kind_name(kind), "vx": mover.velocity_x,
			"vy": mover.velocity_y, "object": object_name})


# The charged jump (C-05, C-06, C-08): cuts an active dash, keeping its horizontal speed; launches
# at exactly charged_launch_speed_px_s with no variable height; spends every armed region in
# node-name order; refills the dash. Returns the name of the object the jump is logged against.
func _charged_jump() -> String:
	var nearest: String = _nearest_charged_object()
	if dash.is_active():
		dash.interrupt()
		Trace.record("dash_end", {"vx": mover.velocity_x, "vy": mover.velocity_y,
				"interrupted": true})
	mover.velocity_y = -Tuning.data.charged_launch_speed_px_s
	state.sustain_ticks = 0
	for object: ChargedObject in charged:
		object.spend()
	if dash.refill_charged():
		Trace.record("dash_refill", {"cause": "charged"})
	return nearest


# True if a charged jump is possible now: in flow, airborne, and a powered object is armed.
func _charged_eligible() -> bool:
	if not flow.is_flow() or state.grounded:
		return false
	for object: ChargedObject in charged:
		if object.offers_charged_jump():
			return true
	return false


# Among the objects offering a charged jump, the one whose center is nearest the body's center
# (squared distance, in doubled coordinates so it stays in integers); ties go to the lowest
# node name, which comes first in the sorted list.
func _nearest_charged_object() -> String:
	var body: Rect2i = mover.body_rect(mover.position)
	var body_center2: Vector2i = body.position * 2 + body.size
	var best: String = ""
	var best_d2: int = -1
	for object: ChargedObject in charged:
		if not object.offers_charged_jump():
			continue
		var offset: Vector2i = object.region_center() * 2 - body_center2
		var d2: int = offset.x * offset.x + offset.y * offset.y
		if best_d2 < 0 or d2 < best_d2:
			best = String(object.name)
			best_d2 = d2
	return best


func _log_assist(kind: String, dx: int, dy: int) -> void:
	Trace.record("assist", {"kind": kind, "dx": dx, "dy": dy})


# Senses grounded and walls; while grounded, refreshes the coyote window and the soft apex.
func _sense_contacts() -> void:
	state.grounded = mover.is_grounded()
	state.wall_left = mover.wall_at(-1)
	state.wall_right = mover.wall_at(1)
	if state.grounded:
		state.coyote_ticks = Tuning.coyote_ticks
		state.soft_apex = true
