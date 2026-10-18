# Moves the player's body against a SolidGrid in whole pixels: a per-axis sub-pixel remainder,
# then horizontal and vertical moves one pixel at a time, plus the grounded and wall queries.
# Assists arrive in M1 step 6. Serves AC M-01, M-02, M-03, D-04, D-05.
class_name PixelMover
extends RefCounted

## The room the body moves in. Replaced on a room change; the remainders are kept.
var grid: SolidGrid
## The feet: the bottom center of the body, in world pixels.
var position: Vector2i = Vector2i.ZERO
## Velocity in pixels per second, one 64-bit float per axis (never a Vector2, which is 32-bit).
var velocity_x: float = 0.0
var velocity_y: float = 0.0
## Sub-pixel movement not yet applied, between -0.5 and 0.5 per axis.
var remainder_x: float = 0.0
var remainder_y: float = 0.0

## Contacts noted by the last move(): the side of a wall that stopped it (-1 left, 1 right,
## 0 none), and whether a ceiling or a floor stopped it.
var wall_hit: int = 0
var ceiling_hit: bool = false
var floor_hit: bool = false

var _body_size: Vector2i
var _wall_check_px: int
var _ticks_per_second: float


## [param body_size] and [param wall_check_px] come from tuning; [param ticks_per_second] is
## the fixed tick rate (Tuning.TICKS_PER_SECOND).
func _init(room_grid: SolidGrid, body_size: Vector2i, wall_check_px: int,
		ticks_per_second: int) -> void:
	grid = room_grid
	_body_size = body_size
	_wall_check_px = wall_check_px
	_ticks_per_second = ticks_per_second


## The body rectangle in world pixels with its feet at [param at]. Its bottom edge is the feet
## line, so a body standing on a tile has its feet at the tile's top.
func body_rect(at: Vector2i) -> Rect2i:
	# The remainder is meant to be dropped: for an odd width the extra pixel goes to the right.
	@warning_ignore("integer_division")
	return Rect2i(at.x - _body_size.x / 2, at.y - _body_size.y, _body_size.x, _body_size.y)


## Moves by one tick of velocity: horizontal first, then vertical, one pixel at a time. An
## axis that is blocked stops flush, and its velocity and remainder become 0.
func move() -> void:
	wall_hit = 0
	ceiling_hit = false
	floor_hit = false
	remainder_x += velocity_x / _ticks_per_second
	var dx: int = roundi(remainder_x)
	remainder_x -= dx
	var sx: int = signi(dx)
	for _i: int in absi(dx):
		if grid.blocks(body_rect(position + Vector2i(sx, 0))):
			velocity_x = 0.0
			remainder_x = 0.0
			wall_hit = sx
			break
		position.x += sx
	remainder_y += velocity_y / _ticks_per_second
	var dy: int = roundi(remainder_y)
	remainder_y -= dy
	var sy: int = signi(dy)
	for _i: int in absi(dy):
		if _blocked_vertically(sy):
			velocity_y = 0.0
			remainder_y = 0.0
			if sy < 0:
				ceiling_hit = true
			else:
				floor_hit = true
			break
		position.y += sy


## True if moving the body one pixel down would be blocked: by a solid cell, or by a platform
## top that is solid for the player now and sits exactly at the feet.
func is_grounded() -> bool:
	return _blocked_vertically(1)


## True if the body shifted the full wall_check_px toward [param side] (-1 left, 1 right)
## overlaps an ordinary solid cell. Platform tops are never walls.
func wall_at(side: int) -> bool:
	return grid.blocks(body_rect(position + Vector2i(side * _wall_check_px, 0)))


# Moving up, only solid cells block. Moving down, a platform top blocks only when the feet are
# exactly on it, so a body whose feet are already inside a platform row passes through.
func _blocked_vertically(dir: int) -> bool:
	if grid.blocks(body_rect(position + Vector2i(0, dir))):
		return true
	return dir > 0 and grid.platform_top_at(body_rect(position))
