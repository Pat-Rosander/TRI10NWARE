# Tests JumpResolver: every combination of ground, coyote, charged and wall eligibility, with and
# without an active dash, returns the documented winner; the both-walls rule; trace names.
# Serves AC M-01, M-02, M-05, M-06, C-07, C-08.
extends TestCase

const DASH_START: int = 100


func test_without_a_dash_the_first_eligible_kind_wins() -> void:
	for mask: int in 16:
		var e: Array[bool] = _eligibility(mask)
		var got: JumpResolver.Kind = JumpResolver.resolve(e[0], e[1], e[2], e[3], false,
				DASH_START + 5, DASH_START)
		assert_eq(got, _first_eligible(e), _describe(e))


func test_during_a_dash_only_a_later_charged_press_wins() -> void:
	for mask: int in 16:
		var e: Array[bool] = _eligibility(mask)
		var label: String = _describe(e)
		for press: int in [DASH_START - 3, DASH_START]:
			assert_eq(JumpResolver.resolve(e[0], e[1], e[2], e[3], true, press, DASH_START),
					JumpResolver.Kind.NONE, "%s, press on tick %d" % [label, press])
		var later: JumpResolver.Kind = JumpResolver.Kind.CHARGED if e[2] else JumpResolver.Kind.NONE
		for press: int in [DASH_START + 1, DASH_START + 8]:
			assert_eq(JumpResolver.resolve(e[0], e[1], e[2], e[3], true, press, DASH_START),
					later, "%s, press on tick %d" % [label, press])


func test_one_wall_is_always_the_one_jumped_off() -> void:
	for held: int in [-1, 0, 1]:
		for facing: int in [-1, 1]:
			var label: String = "held %d, facing %d" % [held, facing]
			assert_eq(JumpResolver.wall_jump_side(true, false, held, facing), -1, "left, " + label)
			assert_eq(JumpResolver.wall_jump_side(false, true, held, facing), 1, "right, " + label)


func test_both_walls_jump_off_the_wall_opposite_the_held_direction() -> void:
	for facing: int in [-1, 1]:
		var label: String = "facing %d" % facing
		assert_eq(JumpResolver.wall_jump_side(true, true, 1, facing), -1, "held right, " + label)
		assert_eq(JumpResolver.wall_jump_side(true, true, -1, facing), 1, "held left, " + label)


func test_both_walls_with_nothing_held_jump_off_the_wall_behind() -> void:
	assert_eq(JumpResolver.wall_jump_side(true, true, 0, 1), -1, "facing right")
	assert_eq(JumpResolver.wall_jump_side(true, true, 0, -1), 1, "facing left")


func test_kind_names_match_the_trace_catalog() -> void:
	assert_eq(JumpResolver.kind_name(JumpResolver.Kind.GROUND), "ground")
	assert_eq(JumpResolver.kind_name(JumpResolver.Kind.COYOTE), "coyote")
	assert_eq(JumpResolver.kind_name(JumpResolver.Kind.CHARGED), "charged")
	assert_eq(JumpResolver.kind_name(JumpResolver.Kind.WALL), "wall")
	assert_eq(JumpResolver.kind_name(JumpResolver.Kind.NONE), "none")


# Ground, coyote, charged, wall eligibility from the four bits of [param mask].
func _eligibility(mask: int) -> Array[bool]:
	return [mask & 1 != 0, mask & 2 != 0, mask & 4 != 0, mask & 8 != 0]


# The documented order, written out independently of the resolver.
func _first_eligible(e: Array[bool]) -> JumpResolver.Kind:
	var order: Array[JumpResolver.Kind] = [JumpResolver.Kind.GROUND, JumpResolver.Kind.COYOTE,
			JumpResolver.Kind.CHARGED, JumpResolver.Kind.WALL]
	for i: int in 4:
		if e[i]:
			return order[i]
	return JumpResolver.Kind.NONE


func _describe(e: Array[bool]) -> String:
	return "ground %s, coyote %s, charged %s, wall %s" % e
