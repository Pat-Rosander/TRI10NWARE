# World, the referee: the project's only _physics_process. Runs the 11-step tick in a fixed order,
# so every same-tick tie resolves the same way; from M1 it also loads rooms, and from M3 runs the
# play states (title, death and respawn, completion), and from M6 touches, commits and loses
# collectibles and runs crossings between neighboring rooms; it also counts the run's ticks in
# GameState. Serves AC D-04, D-05, R-01, R-02, R-04, L1-04, G-01, G-02.
extends Node2D

const CameraRigScript := preload("res://world/camera_rig.gd")
const CATALOG: RoomCatalog = preload("res://rooms/room_catalog.tres")
## The fallback checkpoint when a room has no entrance near the crossed edge.
const START_ENTRANCE: StringName = &"start"
## How far from the crossed edge an entrance may be to become the checkpoint (48 px, 3 tiles).
const CHECKPOINT_REACH_PX: int = 48

## Step 10's result, decided in this fixed order (Same-tick contract).
enum Outcome { NONE, COMPLETE, SPIKE, COUNTDOWN, FELL }
## The play states. Ticks count only in PLAYING, DYING and RESPAWNING; TRANSITION is a crossing.
enum PlayState { TITLE, PLAYING, DYING, RESPAWNING, COMPLETE, TRANSITION }

## The current tick. Counts only while the rules run, never on skipped or frozen physics steps.
var tick: int = 0
## Where play stands. The title overlay leaves TITLE through start().
var play_state: PlayState = PlayState.TITLE
## The input read on the latest tick; the only input the rules see (ground rule 5).
var frame: InputFrame = InputFrame.new()
## Debug freeze: while on, ticks run only one at a time through request_step().
var debug_frozen: bool = false
## Debug slow motion: 1 runs every physics step, 2 every 2nd, 4 every 4th.
var slow_divisor: int = 1: set = _set_slow_divisor
## The current room's ID, and the entrance a respawn returns to (the checkpoint).
var room_id: StringName
var checkpoint: StringName

# The current room, its record and its grid.
var _room: Room
var _entry: RoomEntry
var _grid: SolidGrid
# The neighbor the body's center entered in step 7 of this tick, or null.
var _pending: RoomEntry
# During a crossing: the room being entered, its grid, the edge crossed and physics steps left.
var _next_room: Room
var _next_entry: RoomEntry
var _next_grid: SolidGrid
var _crossed_edge: String = ""
var _from_bounds: Rect2i = Rect2i()
var _slide_steps_left: int = 0
# The current room's goal zones, sorted by node name.
var _goals: Array[GoalZone] = []
# The current room's collectibles, sorted by node name.
var _collectibles: Array[Collectible] = []
var _input_source: InputSource
var _step_requested: bool = false
# Ticks left in the death freeze (DYING) or the respawn lock (RESPAWNING).
var _lock_ticks: int = 0
# Physics steps since the last tick that ran, for slow motion.
var _slow_phase: int = 0

@onready var _player: Player = $Player
@onready var _camera: CameraRigScript = $Camera


func _ready() -> void:
	if _input_source == null:
		_input_source = _player.input_source
	load_room(CATALOG.start_room, CATALOG.start_entrance)


func _physics_process(_delta: float) -> void:
	if not ticks_run() and play_state != PlayState.TRANSITION:
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
	if play_state == PlayState.TRANSITION:
		_step_transition()
		return
	tick += 1
	Trace.tick = tick
	GameState.count_tick()
	if play_state != PlayState.PLAYING:
		_step_locked()
		return
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


## Leaves the title: starts a fresh run in GameState, marks inputs stale (the start key never
## becomes a jump) and starts play. Ticks advance from the next physics step.
func start() -> void:
	if play_state != PlayState.TITLE:
		return
	GameState.reset()
	_input_source.mark_all_stale()
	play_state = PlayState.PLAYING


## Leaves the completion screen with a fresh run: clears the run in GameState (the best time is
## kept), builds the start room at its start entrance, marks inputs stale (the jump that dismissed
## the screen never becomes a jump) and plays again.
func replay() -> void:
	if play_state != PlayState.COMPLETE:
		return
	GameState.reset()
	load_room(CATALOG.start_room, CATALOG.start_entrance)
	_input_source.mark_all_stale()
	play_state = PlayState.PLAYING


## The pause menu's Restart room: a death with cause `restart`, reset exactly like any other.
## Only while playing; a death already under way is not restarted.
func restart_room() -> void:
	if play_state == PlayState.PLAYING:
		_die("restart")


## Marks every held gameplay button stale, for example on unpause.
func mark_inputs_stale() -> void:
	_input_source.mark_all_stale()


## True while ticks count: in PLAYING, DYING and RESPAWNING. Only then can play be paused.
func ticks_run() -> bool:
	return play_state == PlayState.PLAYING or play_state == PlayState.DYING \
			or play_state == PlayState.RESPAWNING


## True while the pause menu may open: whenever ticks run, and during a crossing's slide.
func can_pause() -> bool:
	return ticks_run() or play_state == PlayState.TRANSITION


## While frozen, runs exactly one tick on the next physics step.
func request_step() -> void:
	_step_requested = true


## Plugs in the input source the rules read from, for example a ScriptedInputSource for a
## scenario run. The source must already be in the scene tree if it reads live events.
func set_input_source(source: InputSource) -> void:
	_input_source = source


## Step 10's decision for [param player] in a room with [param goals]: the goal (grounded, feet
## inside a zone), then a spike touched during the move, then countdown expiry, then a fall; the
## first that applies wins.
static func outcome(player: Player, goals: Array[GoalZone]) -> Outcome:
	if player.state.grounded:
		for goal: GoalZone in goals:
			if goal.contains_feet(player.mover.position):
				return Outcome.COMPLETE
	if player.touched_spike():
		return Outcome.SPIKE
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
	_next_room = null
	var room: Room = _build_room(entry)
	var grid: SolidGrid = _build_grid(room, entry)
	var entrance: RoomEntrance = room.entrance(entrance_id)
	if entrance == null:
		return
	_set_room(room, entry, grid, entrance_id)
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


# Step 7: grounded, walls, charged-object regions; then collectibles the body overlaps start
# following the player, in node-name order; then whether the body's center has left the room
# into a neighbor (a crossing, begun in step 10).
func _step_sense() -> void:
	_player.step_sense()
	var body: Rect2i = _player.mover.body_rect(_player.mover.position)
	_pending = null
	var center: Vector2i = body.position + body.size / 2
	var here: Rect2i = _player.mover.grid.bounds
	if not here.has_point(center):
		var neighbor: RoomEntry = CATALOG.room_at(center)
		if neighbor != null and neighbor.world_rect != here:
			_pending = neighbor
	for collectible: Collectible in _collectibles:
		if collectible.overlaps(body):
			collectible.touch(_player)
			_log_collectible(collectible, "touched")


# Step 8: power-source contacts and recharge (M2, M5).
func _step_contacts() -> void:
	pass


# Step 9: the countdown and short timers.
func _step_timers() -> void:
	_player.step_timers()


# Step 10: goal, spike, countdown expiry, falls, then a crossing, in that order. A completion
# stops the ticks until the completion overlay calls replay(); a death starts the death freeze
# (and loses carried collectibles). Without a death, carried collectibles commit on a grounded
# tick, or on any tick a crossing begins.
func _step_outcomes() -> void:
	var result: Outcome = outcome(_player, _goals)
	if result == Outcome.NONE and _pending != null:
		_begin_crossing(_pending)
		return
	if result == Outcome.NONE or result == Outcome.COMPLETE:
		_commit_carried()
	match result:
		Outcome.COMPLETE:
			# Before the record: the completion overlay reads the results when it is logged.
			GameState.finish_run()
			Trace.record("room_complete", {"room": String(room_id)})
			play_state = PlayState.COMPLETE
		Outcome.SPIKE:
			_die("spike")
		Outcome.COUNTDOWN:
			_die("countdown")
		Outcome.FELL:
			_die("fell")


# Step 11: publish the new state; the camera target is set here, except during a slide.
func _step_publish() -> void:
	_player.publish()
	if play_state != PlayState.TRANSITION:
		_camera.move_to(_player.mover.position)


# A tick in DYING or RESPAWNING: the player is frozen, and input is read and thrown away, so no
# press made during the lock becomes a token. After the death freeze the room is rebuilt (the
# respawn marks inputs stale); after the respawn lock control returns.
func _step_locked() -> void:
	_input_source.read(tick)
	_lock_ticks -= 1
	if _lock_ticks <= 0 and play_state == PlayState.DYING:
		load_room(room_id, checkpoint, true)
		play_state = PlayState.RESPAWNING
		_lock_ticks = Tuning.respawn_ticks
	if _lock_ticks <= 0 and play_state == PlayState.RESPAWNING:
		Trace.record("control_return")
		play_state = PlayState.PLAYING
	_step_publish()


# Logs the death once, loses every carried collectible (the rebuilt room shows it again) and
# starts the death freeze.
func _die(cause: String) -> void:
	Trace.record("death", {"cause": cause})
	for collectible: Collectible in _collectibles:
		if collectible.phase == Collectible.Phase.FOLLOWING:
			_log_collectible(collectible, "lost")
	play_state = PlayState.DYING
	_lock_ticks = Tuning.death_freeze_ticks


# Commits every carried collectible if the player is grounded, or if [param leaving] (a crossing
# out of its room), in node-name order.
func _commit_carried(leaving: bool = false) -> void:
	if not _player.state.grounded and not leaving:
		return
	for collectible: Collectible in _collectibles:
		if collectible.phase == Collectible.Phase.FOLLOWING:
			GameState.commit(collectible.id)
			collectible.commit()
			_log_collectible(collectible, "committed")


# Starts a crossing into [param entry] (How crossings work, 1 to 4): the rules and the tick stop,
# a carried collectible commits, the neighbor is built beside this room and joined into the grid,
# and the camera starts sliding to it.
func _begin_crossing(entry: RoomEntry) -> void:
	_from_bounds = _player.mover.grid.bounds
	_crossed_edge = _edge_toward(entry.world_rect)
	Trace.record("transition_start", {"from_room": String(room_id),
			"to_room": String(entry.room_id), "edge": _crossed_edge})
	_commit_carried(true)
	_next_entry = entry
	_next_room = _build_room(entry)
	_next_grid = _build_grid(_next_room, entry)
	_player.mover.grid.join(_next_grid)
	_camera.begin_slide(_player.mover.position, entry.world_rect)
	_slide_steps_left = Tuning.room_transition_ticks
	play_state = PlayState.TRANSITION
	if _slide_steps_left <= 0:
		_end_crossing()


# One physics step of a crossing's slide; the tick does not advance. Input is read and thrown
# away, so presses made during the slide are discarded while held buttons stay held.
func _step_transition() -> void:
	_input_source.read(tick)
	_slide_steps_left -= 1
	var total: int = maxi(Tuning.room_transition_ticks, 1)
	_camera.slide(float(total - _slide_steps_left) / float(total))
	if _slide_steps_left <= 0:
		_end_crossing()


# Ends a crossing (How crossings work, 5 and 6): frees the old room, moves the player into the
# new one with all state kept, chooses the checkpoint, logs room_enter and transition_end on the
# tick the crossing began, and resumes the rules.
func _end_crossing() -> void:
	var slot: Node = $RoomSlot
	slot.remove_child(_room)
	_room.queue_free()
	var room: Room = _next_room
	var entrance_id: StringName = _choose_checkpoint(room, _next_entry.world_rect.position)
	_set_room(room, _next_entry, _next_grid, entrance_id)
	_next_room = null
	_next_entry = null
	_next_grid = null
	_player.enter_room(_grid, room.charged_objects())
	_camera.end_slide(_player.mover.position, _entry.world_rect)
	Trace.record("room_enter", {"room": String(room_id), "entrance": String(checkpoint)})
	Trace.record("transition_end", {"room": String(room_id), "checkpoint": String(checkpoint)})
	play_state = PlayState.PLAYING


# The new room's entrance nearest the player's feet among those within CHECKPOINT_REACH_PX of
# the edge crossed; ties go to the lowest entrance_id. [param origin] is the room's place.
func _choose_checkpoint(room: Room, origin: Vector2i) -> StringName:
	var feet: Vector2i = _player.mover.position
	var near: Array[RoomEntrance] = []
	for candidate: RoomEntrance in room.entrances():
		if _edge_distance(origin + candidate.feet()) <= CHECKPOINT_REACH_PX:
			near.append(candidate)
	if near.is_empty():
		push_error("World: room '%s' has no entrance within %d px of its %s edge." % [
				room.room_id, CHECKPOINT_REACH_PX, _crossed_edge])
		near = room.entrances()
	var best: RoomEntrance = null
	var best_distance: int = 0
	for candidate: RoomEntrance in near:
		var offset: Vector2i = origin + candidate.feet() - feet
		var distance: int = offset.x * offset.x + offset.y * offset.y
		if best == null or distance < best_distance or (distance == best_distance
				and String(candidate.entrance_id) < String(best.entrance_id)):
			best = candidate
			best_distance = distance
	return best.entrance_id if best != null else START_ENTRANCE


# How far the world pixel [param point] is from the edge being crossed.
func _edge_distance(point: Vector2i) -> int:
	var rect: Rect2i = _from_bounds
	match _crossed_edge:
		"left":
			return absi(point.x - rect.position.x)
		"right":
			return absi(point.x - rect.end.x)
		"top":
			return absi(point.y - rect.position.y)
		_:
			return absi(point.y - rect.end.y)


# The current room's edge that [param rect] (a neighbor) lies beyond; sides before top and bottom.
func _edge_toward(rect: Rect2i) -> String:
	var here: Rect2i = _from_bounds
	if rect.end.x <= here.position.x:
		return "left"
	if rect.position.x >= here.end.x:
		return "right"
	if rect.end.y <= here.position.y:
		return "top"
	return "bottom"


# Builds [param entry]'s room fresh at its place on the map, under RoomSlot.
func _build_room(entry: RoomEntry) -> Room:
	var room: Room = entry.scene.instantiate() as Room
	room.position = Vector2(entry.world_rect.position)
	$RoomSlot.add_child(room)
	return room


# The room's grid, open into every neighbor the catalog lists.
func _build_grid(room: Room, entry: RoomEntry) -> SolidGrid:
	var grid: SolidGrid = room.build_grid()
	for neighbor: RoomEntry in CATALOG.neighbors(entry):
		grid.add_opening(neighbor.world_rect)
	return grid


# Makes [param room] the current room, with [param checkpoint_id] as its checkpoint.
func _set_room(room: Room, entry: RoomEntry, grid: SolidGrid, checkpoint_id: StringName) -> void:
	_room = room
	_entry = entry
	_grid = grid
	_pending = null
	room_id = entry.room_id
	checkpoint = checkpoint_id
	_goals = room.goal_zones()
	_collectibles = room.collectibles()
	Trace.room = String(room_id)


func _log_collectible(collectible: Collectible, change: String) -> void:
	Trace.record("collectible", {"id": collectible.id, "change": change})


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
