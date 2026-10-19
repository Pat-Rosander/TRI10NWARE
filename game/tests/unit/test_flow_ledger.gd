# Tests FlowLedger: every FlowLedger rule, the volt limits, the countdown's exact expiry tick,
# each countdown_in_default mode, the allow_flow_entry_at_zero flag, reset and recharge, and the
# trace events each change returns.
# Serves AC S-02, S-03, S-04, M-08.
extends TestCase

const COUNTDOWN: int = 180
const CONTINUE: TuningData.CountdownMode = TuningData.CountdownMode.CONTINUE
const PAUSE: TuningData.CountdownMode = TuningData.CountdownMode.PAUSE
const STOP: TuningData.CountdownMode = TuningData.CountdownMode.STOP


func test_a_fresh_ledger_is_default_with_full_volts() -> void:
	var l: FlowLedger = _ledger()
	assert_eq(l.state, FlowLedger.State.DEFAULT)
	assert_eq(l.volts, 3)
	assert_false(l.countdown_running())


func test_entering_flow_costs_one_volt() -> void:
	var l: FlowLedger = _ledger()
	var events: Array[Dictionary] = l.request_switch()
	assert_eq(l.state, FlowLedger.State.FLOW)
	assert_eq(l.volts, 2)
	assert_false(l.countdown_running(), "volts left: no countdown")
	assert_eq(events, [
		_ev("switch", {"from": "default", "to": "flow", "volts_before": 3, "volts_after": 2}),
		_ev("volts", {"before": 3, "after": 2, "cause": "switch"}),
	])


func test_leaving_flow_is_free() -> void:
	var l: FlowLedger = _ledger()
	l.request_switch()
	var events: Array[Dictionary] = l.request_switch()
	assert_eq(l.state, FlowLedger.State.DEFAULT)
	assert_eq(l.volts, 2)
	assert_eq(events, [
		_ev("switch", {"from": "flow", "to": "default", "volts_before": 2, "volts_after": 2}),
	])


func test_the_last_volt_starts_the_countdown() -> void:
	var l: FlowLedger = _ledger_at(1)
	var events: Array[Dictionary] = l.request_switch()
	assert_eq(l.volts, 0)
	assert_eq(l.countdown_ticks_left, COUNTDOWN)
	assert_eq(events, [
		_ev("switch", {"from": "default", "to": "flow", "volts_before": 1, "volts_after": 0}),
		_ev("volts", {"before": 1, "after": 0, "cause": "switch"}),
		_ev("countdown_start", {"ticks": COUNTDOWN}),
	])


func test_flow_entry_at_zero_is_refused_without_touching_the_timer() -> void:
	var l: FlowLedger = _ledger_at(1)
	l.request_switch()
	l.request_switch()
	for i: int in 5:
		l.tick()
	var left: int = l.countdown_ticks_left
	var events: Array[Dictionary] = l.request_switch()
	assert_eq(l.state, FlowLedger.State.DEFAULT)
	assert_eq(l.volts, 0)
	assert_eq(l.countdown_ticks_left, left, "timer untouched")
	assert_eq(events, [_ev("switch_refused", {"reason": "zero_volts"})])


func test_refused_with_no_countdown_running_starts_none() -> void:
	var l: FlowLedger = _ledger_at(0)
	assert_eq(l.request_switch(), [_ev("switch_refused", {"reason": "zero_volts"})])
	assert_false(l.countdown_running())


func test_volts_stay_within_zero_and_max() -> void:
	var l: FlowLedger = _ledger()
	for i: int in 20:
		l.request_switch()
		assert_true(l.volts >= 0 and l.volts <= 3, "switch %d: volts %d" % [i, l.volts])
	assert_eq(l.volts, 0)
	l.recharge()
	assert_eq(l.volts, 3)


func test_the_countdown_expires_on_the_180th_tick_counting_its_start() -> void:
	# Step 2 of tick t starts it at 180; step 9 of the same tick is the first count.
	var l: FlowLedger = _ledger_at(1)
	l.request_switch()
	for i: int in COUNTDOWN - 1:
		assert_false(l.tick(), "tick %d of the countdown" % (i + 1))
	assert_true(l.tick(), "tick 180 expires")
	assert_false(l.countdown_running())
	for i: int in 300:
		assert_false(l.tick(), "never a second expiry")


func test_continue_keeps_counting_in_default() -> void:
	var l: FlowLedger = _ledger_at(1, CONTINUE)
	l.request_switch()
	l.tick()
	assert_eq(l.request_switch().size(), 1, "only the switch event")
	assert_eq(l.countdown_ticks_left, COUNTDOWN - 1, "returning to default does not stop it")
	l.tick()
	assert_eq(l.countdown_ticks_left, COUNTDOWN - 2, "still counting in default")


func test_pause_holds_the_countdown_while_in_default() -> void:
	var l: FlowLedger = _ledger_at(1, PAUSE, true)
	l.request_switch()
	l.tick()
	l.request_switch()
	for i: int in 50:
		assert_false(l.tick())
	assert_eq(l.countdown_ticks_left, COUNTDOWN - 1, "paused in default")
	var events: Array[Dictionary] = l.request_switch()
	assert_eq(l.countdown_ticks_left, COUNTDOWN - 1, "re-entry at 0 resumes, never restarts")
	assert_eq(events.size(), 1, "only the switch event: no volts, no countdown_start")
	l.tick()
	assert_eq(l.countdown_ticks_left, COUNTDOWN - 2, "counting again in flow")


func test_stop_cancels_the_countdown_on_entering_default() -> void:
	var l: FlowLedger = _ledger_at(1, STOP)
	l.request_switch()
	l.tick()
	var events: Array[Dictionary] = l.request_switch()
	assert_false(l.countdown_running())
	assert_eq(events, [
		_ev("switch", {"from": "flow", "to": "default", "volts_before": 0, "volts_after": 0}),
		_ev("countdown_cancel", {"cause": "default"}),
	])


func test_allow_entry_at_zero_costs_nothing_and_starts_the_countdown_once() -> void:
	var l: FlowLedger = _ledger_at(0, CONTINUE, true)
	var events: Array[Dictionary] = l.request_switch()
	assert_eq(l.state, FlowLedger.State.FLOW)
	assert_eq(l.volts, 0)
	assert_eq(events, [
		_ev("switch", {"from": "default", "to": "flow", "volts_before": 0, "volts_after": 0}),
		_ev("countdown_start", {"ticks": COUNTDOWN}),
	])
	l.tick()
	l.request_switch()
	l.request_switch()
	assert_eq(l.countdown_ticks_left, COUNTDOWN - 1, "a running countdown is never restarted")


func test_recharge_fills_volts_and_cancels_the_countdown() -> void:
	var l: FlowLedger = _ledger_at(1)
	l.request_switch()
	l.tick()
	var events: Array[Dictionary] = l.recharge()
	assert_eq(l.volts, 3)
	assert_false(l.countdown_running())
	assert_eq(l.state, FlowLedger.State.FLOW, "recharge never changes state")
	assert_eq(events, [
		_ev("volts", {"before": 0, "after": 3, "cause": "recharge"}),
		_ev("countdown_cancel", {"cause": "recharge"}),
	])


func test_recharge_without_a_countdown_logs_only_volts() -> void:
	var l: FlowLedger = _ledger_at(2)
	assert_eq(l.recharge(), [_ev("volts", {"before": 2, "after": 3, "cause": "recharge"})])


func test_recharge_at_full_volts_logs_nothing() -> void:
	assert_eq(_ledger().recharge(), [])


func test_recharge_on_the_expiry_tick_wins() -> void:
	# Step 8 (recharge) runs before step 9 (countdown), so a last-tick recharge saves the player.
	var l: FlowLedger = _ledger_at(1)
	l.request_switch()
	for i: int in COUNTDOWN - 1:
		l.tick()
	l.recharge()
	assert_false(l.tick(), "no expiry after the recharge")


func test_reset_restores_default_full_volts_and_no_countdown() -> void:
	var l: FlowLedger = _ledger_at(1)
	l.request_switch()
	l.tick()
	l.reset()
	assert_eq(l.state, FlowLedger.State.DEFAULT)
	assert_eq(l.volts, 3)
	assert_false(l.countdown_running())
	assert_false(l.tick())


func test_ledger_uses_the_tuned_values() -> void:
	var l: FlowLedger = FlowLedger.new(Tuning.data.max_volts, Tuning.countdown_ticks,
			Tuning.data.countdown_in_default, Tuning.data.allow_flow_entry_at_zero)
	assert_eq(l.volts, 3, "max_volts")
	assert_eq(Tuning.countdown_ticks, COUNTDOWN, "countdown_s is 3 s at 60 ticks per second")
	assert_eq(Tuning.data.countdown_in_default, CONTINUE, "AC value")
	assert_false(Tuning.data.allow_flow_entry_at_zero, "AC value")


func test_state_names_match_the_trace_catalog() -> void:
	assert_eq(FlowLedger.state_name(FlowLedger.State.DEFAULT), "default")
	assert_eq(FlowLedger.state_name(FlowLedger.State.FLOW), "flow")


func test_every_returned_event_matches_the_trace_catalog() -> void:
	var events: Array[Dictionary] = []
	for mode: TuningData.CountdownMode in [CONTINUE, PAUSE, STOP]:
		for allow: bool in [false, true]:
			var l: FlowLedger = _ledger_at(1, mode, allow)
			for i: int in 4:
				events.append_array(l.request_switch())
			events.append_array(l.recharge())
	var seen: Dictionary = {}
	for e: Dictionary in events:
		var event_name: String = e["event"]
		seen[event_name] = true
		assert_true(Trace.CATALOG.has(event_name), "%s is in the catalog" % event_name)
		var keys: Array = (e["fields"] as Dictionary).keys()
		keys.sort()
		var expected: Array = (Trace.CATALOG[event_name] as Array).duplicate()
		expected.sort()
		assert_eq(keys, expected, "%s fields" % event_name)
	for event_name: String in ["switch", "switch_refused", "volts", "countdown_start",
			"countdown_cancel"]:
		assert_true(seen.has(event_name), "%s was produced" % event_name)


func _ledger(mode: TuningData.CountdownMode = CONTINUE, allow: bool = false) -> FlowLedger:
	return FlowLedger.new(3, COUNTDOWN, mode, allow)


# A ledger in default with [param volts] left and no countdown running.
func _ledger_at(volts: int, mode: TuningData.CountdownMode = CONTINUE,
		allow: bool = false) -> FlowLedger:
	var l: FlowLedger = _ledger(mode, allow)
	l.volts = volts
	return l


func _ev(event: String, fields: Dictionary) -> Dictionary:
	return {"event": event, "fields": fields}
