# The dash rules: one charge, the active and cooldown timers, the 8-way direction with diagonals
# no faster, the start and end velocities, and the ground and charged refills.
# Serves AC M-03, M-04, C-08.
class_name DashState
extends RefCounted

## 1/√2, precomputed so no rule calls sqrt for a diagonal (ground rule 15).
const DIAGONAL: float = 0.7071067811865476

## 0 or 1. A fresh DashState has its charge.
var charges: int = 1
## Ticks of dash left, counting the current tick; 0 when no dash is active.
var active_ticks: int = 0
## Ticks until another dash may start.
var cooldown_ticks_left: int = 0
## The dash direction; each axis is -1, 0 or 1, never both 0 once a dash has started.
var direction: Vector2i = Vector2i.ZERO
## The tick the current or last dash started, or -1 before the first.
var start_tick: int = -1

var _dash_ticks: int
var _cooldown_ticks: int
var _dash_speed: float
var _end_speed: float
var _end_up_mult: float
var _refill_clears_cooldown: bool


## The values come from tuning: Tuning.dash_ticks, Tuning.dash_cooldown_ticks, and the
## dash_speed_px_s, dash_end_speed_px_s, dash_end_up_mult and charged_refill_clears_cooldown
## fields of tuning.tres.
func _init(dash_ticks: int, cooldown_ticks: int, dash_speed_px_s: float,
		dash_end_speed_px_s: float, dash_end_up_mult: float,
		refill_clears_cooldown: bool) -> void:
	_dash_ticks = dash_ticks
	_cooldown_ticks = cooldown_ticks
	_dash_speed = dash_speed_px_s
	_end_speed = dash_end_speed_px_s
	_end_up_mult = dash_end_up_mult
	_refill_clears_cooldown = refill_clears_cooldown


## True if a dash may start now: a charge, no cooldown and no active dash.
func can_start() -> bool:
	return charges > 0 and cooldown_ticks_left == 0 and active_ticks == 0


## Starts a dash on [param tick] toward [param held], or toward [param facing] (-1 or 1) if no
## direction is held (M-03). Spends the charge and starts the cooldown. Check can_start() first.
func start(held: Vector2i, facing: int, tick: int) -> void:
	direction = held if held != Vector2i.ZERO else Vector2i(facing, 0)
	charges = 0
	active_ticks = _dash_ticks
	cooldown_ticks_left = _cooldown_ticks
	start_tick = tick


## True while a dash is active.
func is_active() -> bool:
	return active_ticks > 0


## The horizontal velocity a dash sets when it starts, in px/s.
func start_velocity_x() -> float:
	return direction.x * _axis_speed(_dash_speed)


## The vertical velocity a dash sets when it starts, in px/s.
func start_velocity_y() -> float:
	return direction.y * _axis_speed(_dash_speed)


## The horizontal velocity when a dash ends on its own, in px/s.
func end_velocity_x() -> float:
	return direction.x * _axis_speed(_end_speed)


## The vertical velocity when a dash ends on its own, slowed by dash_end_up_mult if it was
## moving up, in px/s.
func end_velocity_y() -> float:
	var vy: float = direction.y * _axis_speed(_end_speed)
	return vy * _end_up_mult if direction.y < 0 else vy


## Step 9: counts down the active and cooldown ticks. Returns true on the tick the dash runs
## out (the caller applies the end velocity and logs dash_end). A dash started on tick t is
## active on ticks t through t + dash_ticks - 1.
func tick_timers() -> bool:
	if cooldown_ticks_left > 0:
		cooldown_ticks_left -= 1
	if active_ticks > 0:
		active_ticks -= 1
		return active_ticks == 0
	return false


## Ends an active dash at once, for a charged jump (the caller keeps the horizontal velocity
## and logs dash_end as interrupted). The cooldown keeps running.
func interrupt() -> void:
	active_ticks = 0


## Step 7, on every grounded tick: refills the charge if no dash is active and it is 0.
## Returns true if it went from 0 to 1 (the caller logs dash_refill, cause ground).
func refill_ground() -> bool:
	if active_ticks > 0 or charges > 0:
		return false
	charges = 1
	return true


## A charged jump's refill (C-08), after interrupt() if a dash was active. Also clears the
## cooldown when charged_refill_clears_cooldown is on, so a waiting dash press fires on the
## next tick. Returns true if the charge went from 0 to 1 (the caller logs dash_refill, cause
## charged).
func refill_charged() -> bool:
	if _refill_clears_cooldown:
		cooldown_ticks_left = 0
	if charges > 0:
		return false
	charges = 1
	return true


# The per-axis speed for the current direction: full on a straight dash, × 1/√2 on a diagonal.
func _axis_speed(speed: float) -> float:
	return speed * DIAGONAL if direction.x != 0 and direction.y != 0 else speed
