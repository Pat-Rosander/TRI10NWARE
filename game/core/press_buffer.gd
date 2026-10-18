# Holds at most one unspent press token for one action: "one press, one action", with a window.
# A token made on tick t can be spent on ticks t through t + window. Serves AC M-06, M-07, C-07.
class_name PressBuffer
extends RefCounted

## Returned when there is no token to report.
const NONE: int = -1

var _window: int
var _created: int = NONE


## [param window_ticks] is the buffer window in ticks, such as Tuning.jump_buffer_ticks.
func _init(window_ticks: int) -> void:
	_window = window_ticks


## Stores a fresh token made on [param tick]. Returns the created tick of the unspent token it
## replaces (the caller logs it as press_expired), or NONE.
func press(tick: int) -> int:
	var replaced: int = _created
	_created = tick
	return replaced


## True if a token exists and a decision on [param tick] may spend it.
func can_spend(tick: int) -> bool:
	return _created != NONE and tick >= _created and tick <= _created + _window


## Spends the token on [param tick]. Returns its created tick (for press_spent), or NONE if
## there was nothing spendable. A token can be spent once.
func spend(tick: int) -> int:
	if not can_spend(tick):
		return NONE
	var created: int = _created
	_created = NONE
	return created


## Removes the token once [param tick] is past its window, and returns its created tick (for
## press_expired). Returns NONE while the token is still spendable or if there is none. Called
## every tick, it reports on tick created + window + 1.
func expire(tick: int) -> int:
	if _created == NONE or tick <= _created + _window:
		return NONE
	var created: int = _created
	_created = NONE
	return created


## Drops the token without reporting it.
func clear() -> void:
	_created = NONE


## True if a token is held, spendable or not.
func has_token() -> bool:
	return _created != NONE


## The held token's created tick, or NONE.
func created_tick() -> int:
	return _created
