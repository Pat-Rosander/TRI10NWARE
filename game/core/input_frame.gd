# One tick of gameplay input: what is held, what was freshly pressed, and the 8-way direction.
# The only form in which input reaches gameplay (ground rule 5). Serves AC M-03, M-06, M-07, R-01, R-04.
class_name InputFrame
extends RefCounted

## The tick this frame was read for.
var tick: int = 0

var jump_held: bool = false
## True on exactly one frame per fresh press; holding never repeats it.
var jump_pressed: bool = false
var dash_held: bool = false
var dash_pressed: bool = false
var switch_held: bool = false
var switch_pressed: bool = false

## Each axis is -1, 0 or 1; y is positive downward. Only the direction counts, so diagonals
## are never faster (M-03).
var direction: Vector2i = Vector2i.ZERO
