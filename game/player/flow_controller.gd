# The FlowLedger's adapter to the scene: holds the ledger, makes the grid's solid platform family
# follow the state, and logs the events the ledger returns. Serves AC S-01, S-02, S-03, S-04, M-08.
class_name FlowController
extends Node

## State, volts and countdown. Replaced, never reset, on respawn (R-01).
var ledger: FlowLedger
## Set in step 9 on the tick the countdown runs out; step 10 turns it into a death.
var countdown_expired: bool = false

var _grid: SolidGrid


## Respawn: a fresh ledger (default, full volts, no countdown) and the default family solid in
## [param grid].
func reset(grid: SolidGrid) -> void:
	var data: TuningData = Tuning.data
	ledger = FlowLedger.new(data.max_volts, Tuning.countdown_ticks, data.countdown_in_default,
			data.allow_flow_entry_at_zero)
	countdown_expired = false
	_grid = grid
	_grid.set_flow(false)


## True while the player is in flow.
func is_flow() -> bool:
	return ledger.state == FlowLedger.State.FLOW


## Step 2, on a fresh switch press: asks the ledger to switch, makes the new state's platform
## family solid and logs the ledger's events. Returns true if the state changed.
func request_switch() -> bool:
	var before: FlowLedger.State = ledger.state
	var events: Array[Dictionary] = ledger.request_switch()
	var changed: bool = ledger.state != before
	if changed:
		_grid.set_flow(is_flow())
	for e: Dictionary in events:
		Trace.record(e["event"], e["fields"])
	return changed


## Step 9: counts the countdown down; on the tick it runs out, logs countdown_expire and sets
## [member countdown_expired].
func step_timer() -> void:
	if ledger.tick():
		Trace.record("countdown_expire", {})
		countdown_expired = true
