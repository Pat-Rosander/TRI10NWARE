# The only owner of state (default or flow), volts and the zero-volt countdown (ground rule 6).
# Every change returns the trace events it caused; the adapter (FlowController) logs them.
# Serves AC S-02, S-03, S-04, M-08.
class_name FlowLedger
extends RefCounted

enum State { DEFAULT, FLOW }

const STATE_NAMES: Array[String] = ["default", "flow"]

var state: State = State.DEFAULT
## Always between 0 and max_volts.
var volts: int
## Ticks of countdown left; 0 when no countdown is running.
var countdown_ticks_left: int = 0

var _max_volts: int
var _countdown_ticks: int
var _countdown_mode: TuningData.CountdownMode
var _allow_entry_at_zero: bool


## The values come from tuning: max_volts, Tuning.countdown_ticks, countdown_in_default and
## allow_flow_entry_at_zero. A fresh ledger is reset: default, full volts, no countdown.
func _init(max_volts: int, countdown_ticks: int, countdown_mode: TuningData.CountdownMode,
		allow_entry_at_zero: bool) -> void:
	_max_volts = max_volts
	_countdown_ticks = countdown_ticks
	_countdown_mode = countdown_mode
	_allow_entry_at_zero = allow_entry_at_zero
	volts = max_volts


## True while the countdown is running.
func countdown_running() -> bool:
	return countdown_ticks_left > 0


## Step 2, on a fresh switch press. Default → flow costs one volt and starts the countdown when
## that was the last volt; at 0 volts it is refused unless allow_flow_entry_at_zero is on.
## Flow → default is free; the countdown follows countdown_in_default. Returns the trace events
## as [{"event": name, "fields": {...}}], in the order they happen.
func request_switch() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state == State.FLOW:
		state = State.DEFAULT
		events.append(_switch_event(State.FLOW, State.DEFAULT, volts, volts))
		if _countdown_mode == TuningData.CountdownMode.STOP and countdown_running():
			countdown_ticks_left = 0
			events.append(_event("countdown_cancel", {"cause": "default"}))
		return events
	if volts == 0 and not _allow_entry_at_zero:
		events.append(_event("switch_refused", {"reason": "zero_volts"}))
		return events
	var before: int = volts
	volts = maxi(volts - 1, 0)
	state = State.FLOW
	events.append(_switch_event(State.DEFAULT, State.FLOW, before, volts))
	if volts != before:
		events.append(_event("volts", {"before": before, "after": volts, "cause": "switch"}))
	if volts == 0 and not countdown_running():
		countdown_ticks_left = _countdown_ticks
		events.append(_event("countdown_start", {"ticks": _countdown_ticks}))
	return events


## A network activation (M5): volts to max_volts and the countdown off. Logs volts only if the
## count changed, and countdown_cancel only if it was running.
func recharge() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if volts != _max_volts:
		events.append(_event("volts", {"before": volts, "after": _max_volts, "cause": "recharge"}))
		volts = _max_volts
	if countdown_running():
		countdown_ticks_left = 0
		events.append(_event("countdown_cancel", {"cause": "recharge"}))
	return events


## Step 9: counts the countdown down by one if it is running (in pause mode, only while in
## flow). Returns true exactly once, on the tick it reaches 0 (the caller logs countdown_expire
## and step 10 kills the player). A countdown started on tick t expires on tick t + 179.
func tick() -> bool:
	if not countdown_running():
		return false
	if _countdown_mode == TuningData.CountdownMode.PAUSE and state == State.DEFAULT:
		return false
	countdown_ticks_left -= 1
	return countdown_ticks_left == 0


## Respawn: default, max_volts, no countdown. Logs nothing; the respawn event covers it.
func reset() -> void:
	state = State.DEFAULT
	volts = _max_volts
	countdown_ticks_left = 0


## The trace name of [param s]: default or flow.
static func state_name(s: State) -> String:
	return STATE_NAMES[s]


func _switch_event(from: State, to: State, before: int, after: int) -> Dictionary:
	return _event("switch", {"from": state_name(from), "to": state_name(to),
			"volts_before": before, "volts_after": after})


func _event(event: String, fields: Dictionary) -> Dictionary:
	return {"event": event, "fields": fields}
