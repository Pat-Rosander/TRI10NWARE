# The FlowLedger's adapter to the scene: holds the ledger, makes the grid's solid platform family
# follow the state, applies the overlap policy on every switch, and logs the events the ledger and
# the policy produce, and recharges on a network activation. Serves AC S-01, S-02, S-03, S-04,
# M-08, N-02, P-01 to P-04.
class_name FlowController
extends Node

## State, volts and countdown. Replaced, never reset, on respawn (R-01).
var ledger: FlowLedger
## Set in step 9 on the tick the countdown runs out; step 10 turns it into a death.
var countdown_expired: bool = false
## Set by the last request_switch(): true if the overlap policy snapped the player onto a
## platform top, with the vertical speed just before the snap.
var snapped: bool = false
var snap_vy_before: float = 0.0

var _grid: SolidGrid
var _policy: OverlapPolicy


## Respawn: a fresh ledger (default, full volts, no countdown) and the default family solid in
## [param grid].
func reset(grid: SolidGrid) -> void:
	var data: TuningData = Tuning.data
	ledger = FlowLedger.new(data.max_volts, Tuning.countdown_ticks, data.countdown_in_default,
			data.allow_flow_entry_at_zero)
	countdown_expired = false
	snapped = false
	_policy = OverlapPolicy.new(data.overlap_snap_px)
	_grid = grid
	_grid.set_flow(false)


## A room crossing: keeps the ledger and makes the current state's platform family solid in
## [param grid], the new room's grid.
func set_grid(grid: SolidGrid) -> void:
	_grid = grid
	_grid.set_flow(is_flow())


## True while the player is in flow.
func is_flow() -> bool:
	return ledger.state == FlowLedger.State.FLOW


## Step 2, on a fresh switch press: asks the ledger to switch, makes the new state's platform
## family solid, logs the ledger's events, then applies the overlap policy to [param mover]'s
## body (which may snap it up onto a top). Returns true if the state changed.
func request_switch(mover: PixelMover) -> bool:
	snapped = false
	var before: FlowLedger.State = ledger.state
	var events: Array[Dictionary] = ledger.request_switch()
	var changed: bool = ledger.state != before
	if changed:
		_grid.set_flow(is_flow())
	for e: Dictionary in events:
		Trace.record(e["event"], e["fields"])
	if changed:
		_apply_overlap_policy(mover)
	return changed


## Step 8, once per tick on which a network activated: volts to max_volts and the countdown
## cancelled, logging the ledger's events.
func recharge() -> void:
	for e: Dictionary in ledger.recharge():
		Trace.record(e["event"], e["fields"])


## Step 7: every pending tile [param body] no longer overlaps becomes solid (platform_solid).
func release_pending(body: Rect2i) -> void:
	var released: Array[Vector2i] = _grid.release_pending(body)
	if not released.is_empty():
		Trace.record("platform_solid", {"family": _family(), "tiles": _tile_list(released)})


## Step 9: counts the countdown down; on the tick it runs out, logs countdown_expire and sets
## [member countdown_expired].
func step_timer() -> void:
	if ledger.tick():
		Trace.record("countdown_expire", {})
		countdown_expired = true


# The overlap policy (How the overlap policy works): the solid family's tiles the body overlaps
# become solid at once, snap the player onto their top, or wait as pending. platform_solid with no
# tiles means the whole family, and is logged only if the room has a tile of that family.
func _apply_overlap_policy(mover: PixelMover) -> void:
	var tiles: Array[Vector2i] = _grid.overlapped_platforms(mover.body_rect(mover.position))
	# The tiles under the feet are those in the row holding the body's bottom pixel row.
	var feet_row: int = SolidGrid.cell_of(mover.position - Vector2i(0, 1)).y
	var top: int = feet_row * SolidGrid.TILE_PX
	var depth: int = 0
	for cell: Vector2i in tiles:
		if cell.y == feet_row:
			depth = mover.position.y - top
	var at: Vector2i = Vector2i(mover.position.x, top)
	var fits: bool = not _grid.blocks(mover.body_rect(at))
	match _policy.decide(tiles.size(), depth, mover.velocity_y, fits):
		OverlapPolicy.Result.SOLID:
			if _grid.has_active_family():
				Trace.record("platform_solid", {"family": _family(), "tiles": []})
		OverlapPolicy.Result.SNAP:
			snap_vy_before = mover.velocity_y
			mover.position = at
			mover.velocity_y = 0.0
			mover.remainder_y = 0.0
			snapped = true
			Trace.record("overlap_snap", {"family": _family(), "dy": -depth})
			Trace.record("platform_solid", {"family": _family(), "tiles": []})
			# A tile the snapped body is still inside (a stacked platform) waits too.
			_set_pending(_grid.overlapped_platforms(mover.body_rect(at)))
		OverlapPolicy.Result.PENDING:
			_set_pending(tiles)


func _set_pending(tiles: Array[Vector2i]) -> void:
	if tiles.is_empty():
		return
	_grid.set_pending(tiles)
	Trace.record("platform_pending", {"family": _family(), "tiles": _tile_list(tiles)})


# The solid platform family's name in the trace.
func _family() -> String:
	return "flow" if is_flow() else "default"


# World cells as [x, y] pairs, so the trace's JSON keeps them as numbers.
func _tile_list(cells: Array[Vector2i]) -> Array:
	var list: Array = []
	for cell: Vector2i in cells:
		list.append([cell.x, cell.y])
	return list
