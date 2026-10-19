# Tests EncounterTracker: arming on entry, spending, exit with the margin (hysteresis), no false
# re-arm on the boundary, and that a state switch does nothing.
# Serves AC C-03, C-04.
extends TestCase

const OUTSIDE: EncounterTracker.State = EncounterTracker.State.OUTSIDE
const ARMED: EncounterTracker.State = EncounterTracker.State.ARMED
const SPENT: EncounterTracker.State = EncounterTracker.State.SPENT


func test_a_fresh_tracker_is_outside() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	assert_eq(t.state, OUTSIDE)
	assert_false(t.is_armed())


func test_entry_arms_and_reports_the_change() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	assert_true(t.update(true, true), "outside to armed is a change")
	assert_eq(t.state, ARMED)
	assert_true(t.is_armed())
	assert_false(t.update(true, true), "still inside: no change")
	assert_eq(t.state, ARMED)


func test_armed_stays_armed_inside_the_exit_margin() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	t.update(true, true)
	assert_false(t.update(false, true), "left the region but not the margin")
	assert_eq(t.state, ARMED)


func test_armed_or_spent_becomes_outside_when_no_longer_inside() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	t.update(true, true)
	assert_true(t.update(false, false), "armed to outside")
	assert_eq(t.state, OUTSIDE)
	t.update(true, true)
	t.spend()
	assert_true(t.update(false, false), "spent to outside")
	assert_eq(t.state, OUTSIDE)


func test_spend_works_only_when_armed() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	assert_false(t.spend(), "outside")
	assert_eq(t.state, OUTSIDE)
	t.update(true, true)
	assert_true(t.spend(), "armed")
	assert_eq(t.state, SPENT)
	assert_false(t.is_armed())
	assert_false(t.spend(), "already spent")
	assert_eq(t.state, SPENT)


func test_spent_stays_spent_while_inside() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	t.update(true, true)
	t.spend()
	for i: int in 30:
		assert_false(t.update(true, true), "inside, tick %d" % i)
		assert_false(t.update(false, true), "in the margin, tick %d" % i)
	assert_eq(t.state, SPENT)


func test_inside_the_margin_never_arms_from_outside() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	assert_false(t.update(false, true), "approaching through the margin")
	assert_eq(t.state, OUTSIDE)


func test_resting_on_the_boundary_does_not_re_arm() -> void:
	# A spent player hovering at the region's edge flickers in and out of the entry test but
	# never leaves the margin, so the region stays spent.
	var t: EncounterTracker = EncounterTracker.new()
	t.update(true, true)
	t.spend()
	for i: int in 20:
		t.update(i % 2 == 0, true)
		assert_eq(t.state, SPENT, "tick %d" % i)


func test_leave_and_reenter_arms_again_repeatedly() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	for visit: int in 5:
		t.update(true, true)
		assert_true(t.spend(), "visit %d" % visit)
		t.update(false, false)
		assert_eq(t.state, OUTSIDE, "visit %d" % visit)


func test_a_state_switch_does_nothing() -> void:
	# The tracker takes no state input: a switch cannot reach it. The same overlaps before and
	# after a switch give the same state, so toggling flow inside a spent region never re-arms.
	var t: EncounterTracker = EncounterTracker.new()
	t.update(true, true)
	t.spend()
	var ledger: FlowLedger = FlowLedger.new(3, 180, TuningData.CountdownMode.CONTINUE, false)
	for i: int in 4:
		ledger.request_switch()
		t.update(true, true)
		assert_eq(t.state, SPENT, "after switch %d" % i)


func test_reset_returns_to_outside() -> void:
	var t: EncounterTracker = EncounterTracker.new()
	t.update(true, true)
	t.spend()
	t.reset()
	assert_eq(t.state, OUTSIDE)


func test_state_names_match_the_trace_catalog() -> void:
	assert_eq(EncounterTracker.state_name(OUTSIDE), "outside")
	assert_eq(EncounterTracker.state_name(ARMED), "armed")
	assert_eq(EncounterTracker.state_name(SPENT), "spent")
