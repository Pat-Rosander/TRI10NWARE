# Jump precedence in one place: given what is possible this tick, which jump fires (ground,
# coyote, charged, wall or none), and which wall a wall jump leaves. Stateless.
# Serves AC M-01, M-02, M-05, M-06, C-07, C-08.
class_name JumpResolver
extends RefCounted

## The jump kinds, in precedence order after NONE.
enum Kind { NONE, GROUND, COYOTE, CHARGED, WALL }


## Picks the jump for a press made on [param press_tick]: the first eligible of ground, coyote,
## charged and wall. During an active dash only a charged jump is eligible, and only if the
## press came after [param dash_start_tick]; otherwise NONE, and the press waits in its buffer.
static func resolve(grounded: bool, has_coyote: bool, charged_eligible: bool,
		wall_in_reach: bool, dash_active: bool, press_tick: int, dash_start_tick: int) -> Kind:
	if dash_active:
		if charged_eligible and press_tick > dash_start_tick:
			return Kind.CHARGED
		return Kind.NONE
	if grounded:
		return Kind.GROUND
	if has_coyote:
		return Kind.COYOTE
	if charged_eligible:
		return Kind.CHARGED
	if wall_in_reach:
		return Kind.WALL
	return Kind.NONE


## The wall a wall jump leaves (-1 left, 1 right); the jump goes the other way. With walls on
## both sides, the wall opposite [param held_x], or with none held, the wall behind
## [param facing]. Call only when at least one wall is in reach.
static func wall_jump_side(wall_left: bool, wall_right: bool, held_x: int, facing: int) -> int:
	if wall_left and not wall_right:
		return -1
	if wall_right and not wall_left:
		return 1
	if held_x != 0:
		return -held_x
	return -facing


## The kind's name in the trace catalog (`jump` event, field `kind`), or "none".
static func kind_name(kind: Kind) -> String:
	match kind:
		Kind.GROUND:
			return "ground"
		Kind.COYOTE:
			return "coyote"
		Kind.CHARGED:
			return "charged"
		Kind.WALL:
			return "wall"
	return "none"
