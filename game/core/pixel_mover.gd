# Moves the player's body against a SolidGrid in whole pixels: a per-axis sub-pixel remainder,
# then horizontal and vertical moves one pixel at a time, the grounded and wall queries, the
# four movement assists, and spike contact at every pixel. Serves AC M-01, M-02, M-03, D-04, D-05,
# R-01 (spike deaths).
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
## True if the last move() touched a spike hitbox: at its start position or at any pixel it
## passed through. Spikes never stop the move.
var spike_hit: bool = false
## Assists applied by the last move(), as the displacement each added: the corner correction's
## sideways shift, and the dash corner correction's upward shift (negative). 0 if none.
var corner_shift: int = 0
var dash_corner_shift: int = 0

var _body_size: Vector2i
var _wall_check_px: int
var _ticks_per_second: float
var _corner_px: int
var _dash_corner_px: int
var _oneway_px: int
var _snap_px: int
var _apex_threshold: float


## [param body_size], [param wall_check_px], the four assist distances and
## [param apex_threshold_px_s] come from tuning; [param ticks_per_second] is the fixed tick rate
## (Tuning.TICKS_PER_SECOND).
func _init(room_grid: SolidGrid, body_size: Vector2i, wall_check_px: int,
		ticks_per_second: int, corner_correction_px: int, dash_corner_correction_px: int,
		oneway_assist_px: int, post_dash_snap_px: int, apex_threshold_px_s: float) -> void:
	grid = room_grid
	_body_size = body_size
	_wall_check_px = wall_check_px
	_ticks_per_second = ticks_per_second
	_corner_px = corner_correction_px
	_dash_corner_px = dash_corner_correction_px
	_oneway_px = oneway_assist_px
	_snap_px = post_dash_snap_px
	_apex_threshold = apex_threshold_px_s


## The body rectangle in world pixels with its feet at [param at]. Its bottom edge is the feet
## line, so a body standing on a tile has its feet at the tile's top.
func body_rect(at: Vector2i) -> Rect2i:
	# The remainder is meant to be dropped: for an odd width the extra pixel goes to the right.
	@warning_ignore("integer_division")
	return Rect2i(at.x - _body_size.x / 2, at.y - _body_size.y, _body_size.x, _body_size.y)


## Moves by one tick of velocity: horizontal first, then vertical, one pixel at a time. An
## axis that is blocked stops flush, and its velocity and remainder become 0, unless its assist
## fits: the dash corner correction for a horizontal or up-diagonal dash ([param dash_dir] is
## the active dash's direction, or zero), and the corner correction for a rising body, which
## breaks a tie toward the horizontal velocity, then [param facing]. Each at most once per move.
## Every position the body takes, the start included, is tested against spike hitboxes.
func move(facing: int = 1, dash_dir: Vector2i = Vector2i.ZERO) -> void:
	wall_hit = 0
	ceiling_hit = false
	floor_hit = false
	corner_shift = 0
	dash_corner_shift = 0
	spike_hit = false
	_note_spike()
	var dash_corner_allowed: bool = dash_dir.x != 0 and dash_dir.y <= 0
	remainder_x += velocity_x / _ticks_per_second
	var dx: int = roundi(remainder_x)
	remainder_x -= dx
	var sx: int = signi(dx)
	for _i: int in absi(dx):
		if grid.blocks(body_rect(position + Vector2i(sx, 0))):
			var lift: int = 0
			if dash_corner_allowed and dash_corner_shift == 0:
				lift = _dash_corner_lift(sx)
			if lift == 0:
				velocity_x = 0.0
				remainder_x = 0.0
				wall_hit = sx
				break
			position.y -= lift
			dash_corner_shift = -lift
			_note_spike()
		position.x += sx
		_note_spike()
	remainder_y += velocity_y / _ticks_per_second
	var dy: int = roundi(remainder_y)
	remainder_y -= dy
	var sy: int = signi(dy)
	for _i: int in absi(dy):
		if _blocked_vertically(sy):
			var shift: int = 0
			if sy < 0 and corner_shift == 0:
				shift = _corner_correction(facing)
			if shift == 0:
				velocity_y = 0.0
				remainder_y = 0.0
				if sy < 0:
					ceiling_hit = true
				else:
					floor_hit = true
				break
			position.x += shift
			corner_shift = shift
			_note_spike()
		position.y += sy
		_note_spike()


## True if moving the body one pixel down would be blocked: by a solid cell, or by a platform
## top that is solid for the player now and sits exactly at the feet.
func is_grounded() -> bool:
	return _blocked_vertically(1)


## True if the body shifted the full wall_check_px toward [param side] (-1 left, 1 right)
## overlaps an ordinary solid cell. Platform tops are never walls.
func wall_at(side: int) -> bool:
	return grid.blocks(body_rect(position + Vector2i(side * _wall_check_px, 0)))


## Step 7's one-way platform help: a body rising slower than the apex threshold, with its feet
## within oneway_assist_px below the top of a platform tile that is solid for the player now and
## room for the body above, is lifted onto that top with vertical speed 0. Returns the lift
## (negative), or 0 if it did not apply.
func oneway_help() -> int:
	if velocity_y >= 0.0 or -velocity_y >= _apex_threshold or is_grounded():
		return 0
	# The nearest tile top strictly above the feet.
	var top: int = position.y - 1 - posmod(position.y - 1, SolidGrid.TILE_PX)
	var lift: int = position.y - top
	if lift > _oneway_px:
		return 0
	var at: Vector2i = Vector2i(position.x, top)
	if not grid.platform_top_at(body_rect(at)) or grid.blocks(body_rect(at)):
		return 0
	position = at
	velocity_y = 0.0
	remainder_y = 0.0
	return -lift


## Step 9's post-dash floor snap: when a dash ends moving horizontally or downward
## ([param dash_dir_y] 0 or 1) and the body is not grounded, moves it down onto a floor within
## post_dash_snap_px. Returns the distance moved, or 0 if it did not apply.
func post_dash_snap(dash_dir_y: int) -> int:
	if dash_dir_y < 0 or is_grounded():
		return 0
	var start: int = position.y
	for _i: int in _snap_px:
		position.y += 1
		if is_grounded():
			return position.y - start
	position.y = start
	return 0


# Notes a spike contact at the body's current position.
func _note_spike() -> void:
	if not spike_hit and grid.touches_spike(body_rect(position)):
		spike_hit = true


# Moving up, only solid cells block. Moving down, a platform top blocks only when the feet are
# exactly on it, so a body whose feet are already inside a platform row passes through.
func _blocked_vertically(dir: int) -> bool:
	if grid.blocks(body_rect(position + Vector2i(0, dir))):
		return true
	return dir > 0 and grid.platform_top_at(body_rect(position))


# The smallest sideways shift (signed) that lets a blocked rising body go one pixel higher, up to
# corner_correction_px; 0 if none fits. On a tie, the horizontal velocity's side wins, then the
# facing side.
func _corner_correction(facing: int) -> int:
	var first: int = int(signf(velocity_x)) if velocity_x != 0.0 else facing
	for k: int in range(1, _corner_px + 1):
		for dir: int in [first, -first]:
			if _corner_fits(dir, k):
				return dir * k
	return 0


# True if the body can slide [param k] pixels toward [param dir] at its height, every pixel
# free, and is then free one pixel higher.
func _corner_fits(dir: int, k: int) -> bool:
	for j: int in range(1, k + 1):
		if grid.blocks(body_rect(position + Vector2i(dir * j, 0))):
			return false
	return not grid.blocks(body_rect(position + Vector2i(dir * k, -1)))


# The smallest lift, up to dash_corner_correction_px, after which the body can take its next
# pixel toward [param sx]; 0 if none fits. The body rises straight up, every pixel free.
func _dash_corner_lift(sx: int) -> int:
	for k: int in range(1, _dash_corner_px + 1):
		if grid.blocks(body_rect(position + Vector2i(0, -k))):
			return 0
		if not grid.blocks(body_rect(position + Vector2i(sx, -k))):
			return k
	return 0
