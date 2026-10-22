# Tests OverlapPolicy: every branch of solid, snap and pending, including the exact snap
# boundary, the vertical-speed sign and a body that does not fit. Serves AC P-04.
extends TestCase

const SNAP: int = 6


func test_nothing_overlapped_is_solid() -> void:
	var policy: OverlapPolicy = OverlapPolicy.new(SNAP)
	assert_eq(policy.decide(0, 0, 0.0, true), OverlapPolicy.Result.SOLID)
	assert_eq(policy.decide(0, 0, -200.0, false), OverlapPolicy.Result.SOLID, "whatever else")


func test_the_snap_boundary_is_exact() -> void:
	var policy: OverlapPolicy = OverlapPolicy.new(SNAP)
	assert_eq(policy.decide(1, 1, 0.0, true), OverlapPolicy.Result.SNAP, "1 px")
	assert_eq(policy.decide(1, SNAP, 0.0, true), OverlapPolicy.Result.SNAP, "exactly the snap")
	assert_eq(policy.decide(1, SNAP + 1, 0.0, true), OverlapPolicy.Result.PENDING,
			"one pixel deeper")
	assert_eq(policy.decide(2, 15, 50.0, true), OverlapPolicy.Result.PENDING, "deep inside")


func test_only_a_still_or_falling_body_snaps() -> void:
	var policy: OverlapPolicy = OverlapPolicy.new(SNAP)
	assert_eq(policy.decide(1, 3, 0.0, true), OverlapPolicy.Result.SNAP, "still")
	assert_eq(policy.decide(1, 3, 300.0, true), OverlapPolicy.Result.SNAP, "falling")
	assert_eq(policy.decide(1, 3, -0.5, true), OverlapPolicy.Result.PENDING, "rising slowly")
	assert_eq(policy.decide(1, 3, -300.0, true), OverlapPolicy.Result.PENDING, "rising")


func test_a_body_that_does_not_fit_waits() -> void:
	var policy: OverlapPolicy = OverlapPolicy.new(SNAP)
	assert_eq(policy.decide(1, 3, 0.0, false), OverlapPolicy.Result.PENDING)


func test_no_tile_under_the_feet_waits() -> void:
	# Only the head overlaps the family: there is no top to snap onto.
	var policy: OverlapPolicy = OverlapPolicy.new(SNAP)
	assert_eq(policy.decide(1, 0, 0.0, true), OverlapPolicy.Result.PENDING)


func test_the_snap_distance_comes_from_tuning() -> void:
	var policy: OverlapPolicy = OverlapPolicy.new(2)
	assert_eq(policy.decide(1, 2, 0.0, true), OverlapPolicy.Result.SNAP)
	assert_eq(policy.decide(1, 3, 0.0, true), OverlapPolicy.Result.PENDING)
