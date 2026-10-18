# The shared interface for live and scripted input: read(tick) -> InputFrame and mark_all_stale().
# Holds the rules both share (fresh presses, stale buttons, most-recent direction). Serves AC M-03, M-07, R-01, R-04.
class_name InputSource
extends Node

## Buttons that make press tokens and can be marked stale.
const BUTTONS: Array[StringName] = [&"jump", &"dash", &"switch"]
## Movement actions; never marked stale.
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _held: Dictionary[StringName, bool] = {}
var _stale: Dictionary[StringName, bool] = {}
# Buttons freshly pressed since the last read().
var _fresh: Dictionary[StringName, bool] = {}
# For each held move action, when it was pressed, so the most recent of two opposing keys wins.
var _press_order: Dictionary[StringName, int] = {}
var _press_count: int = 0


## Returns the input for [param tick]. Fresh presses are reported on one frame only.
func read(tick: int) -> InputFrame:
	_collect(tick)
	var frame: InputFrame = InputFrame.new()
	frame.tick = tick
	frame.jump_held = _is_live_held(&"jump")
	frame.dash_held = _is_live_held(&"dash")
	frame.switch_held = _is_live_held(&"switch")
	frame.jump_pressed = _fresh.has(&"jump")
	frame.dash_pressed = _fresh.has(&"dash")
	frame.switch_pressed = _fresh.has(&"switch")
	_fresh.clear()
	frame.direction = _digital_direction()
	if frame.direction == Vector2i.ZERO:
		frame.direction = _analog_direction()
	return frame


## Marks every held button (jump, dash, switch) stale: it reports neither held nor pressed until
## it is released. Directions are untouched. Presses not yet read are discarded. World calls
## this on respawn, on unpause and when the title screen is dismissed.
func mark_all_stale() -> void:
	_drain_pending()
	_fresh.clear()
	for action: StringName in BUTTONS:
		if _held.has(action):
			_stale[action] = true


# Subclasses apply every input transition due by tick, in order, through _apply().
func _collect(_tick: int) -> void:
	pass


# Subclasses apply transitions that arrived but have not been read yet.
func _drain_pending() -> void:
	pass


# Subclasses may return a direction from an analog stick; used only when no move key is held.
func _analog_direction() -> Vector2i:
	return Vector2i.ZERO


# Feeds one press or release of a gameplay action into the shared state.
func _apply(action: StringName, pressed: bool) -> void:
	if pressed:
		if _held.has(action):
			return
		_held[action] = true
		if action in MOVES:
			_press_count += 1
			_press_order[action] = _press_count
		else:
			_fresh[action] = true
	else:
		if not _held.has(action):
			return
		_held.erase(action)
		_stale.erase(action)
		_press_order.erase(action)


# Forgets all held, stale and pending state.
func _reset() -> void:
	_held.clear()
	_stale.clear()
	_fresh.clear()
	_press_order.clear()
	_press_count = 0


func _is_live_held(action: StringName) -> bool:
	return _held.has(action) and not _stale.has(action)


func _digital_direction() -> Vector2i:
	return Vector2i(_axis(&"move_left", &"move_right"), _axis(&"move_up", &"move_down"))


# -1, 0 or 1 for one axis; with both keys held, the one pressed most recently wins.
func _axis(negative: StringName, positive: StringName) -> int:
	var neg: int = _press_order.get(negative, 0)
	var pos: int = _press_order.get(positive, 0)
	if neg == 0 and pos == 0:
		return 0
	return -1 if neg > pos else 1
