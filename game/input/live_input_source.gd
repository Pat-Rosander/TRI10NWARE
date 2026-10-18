# The real player's input: queues gameplay key and button events from _input() as they arrive,
# and drains them on the next tick that runs, so no press is lost. Serves AC M-03, M-07, R-01, R-04.
class_name LiveInputSource
extends InputSource

## tan(22.5°) = sqrt(2) - 1. A stick within 22.5° of an axis snaps to that axis.
const SNAP_TAN: float = 0.41421356237309503

var _deadzone: float = 0.0
# Transitions waiting for the next read(), in arrival order.
var _queue_actions: Array[StringName] = []
var _queue_pressed: Array[bool] = []
# For each gameplay action, the physical keys and buttons holding it down, so two keys bound to
# one action never press it twice or release it early.
var _sources: Dictionary[StringName, Dictionary] = {}


func _init() -> void:
	# Keep tracking keys while the tree is paused, so held state is right on unpause.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_deadzone = Tuning.data.stick_deadzone


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var source: String = _source_key(event)
	if source.is_empty():
		return
	for action: StringName in BUTTONS + MOVES:
		if not InputMap.event_is_action(event, action):
			continue
		var holders: Dictionary = _sources.get_or_add(action, {})
		var was_held: bool = not holders.is_empty()
		if event.is_pressed():
			holders[source] = true
		else:
			holders.erase(source)
		var now_held: bool = not holders.is_empty()
		if now_held != was_held:
			_queue_actions.append(action)
			_queue_pressed.append(now_held)


func _notification(what: int) -> void:
	# The key-up events may never arrive once focus is lost, so release everything.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for action: StringName in _sources:
			if not _sources[action].is_empty():
				_sources[action].clear()
				_queue_actions.append(action)
				_queue_pressed.append(false)


## Turns a raw stick vector into an 8-way direction: a radial deadzone of [param deadzone], then
## equal 45° sectors (M-03). Uses only comparisons and multiplication, no trigonometry.
static func snap_stick(raw: Vector2, deadzone: float) -> Vector2i:
	if raw.length_squared() < deadzone * deadzone:
		return Vector2i.ZERO
	var ax: float = absf(raw.x)
	var ay: float = absf(raw.y)
	if ay <= ax * SNAP_TAN:
		return Vector2i(int(signf(raw.x)), 0)
	if ax <= ay * SNAP_TAN:
		return Vector2i(0, int(signf(raw.y)))
	return Vector2i(int(signf(raw.x)), int(signf(raw.y)))


func _collect(_tick: int) -> void:
	_drain_pending()


func _drain_pending() -> void:
	for i: int in _queue_actions.size():
		_apply(_queue_actions[i], _queue_pressed[i])
	_queue_actions.clear()
	_queue_pressed.clear()


# The movement actions have no deadzone in the input map, so with no move key held their raw
# strengths are the raw stick.
func _analog_direction() -> Vector2i:
	var raw: Vector2 = Vector2(
			Input.get_action_raw_strength(&"move_right") - Input.get_action_raw_strength(&"move_left"),
			Input.get_action_raw_strength(&"move_down") - Input.get_action_raw_strength(&"move_up"))
	return snap_stick(raw, _deadzone)


# Names the physical key or button behind a digital event; empty for anything else (the stick
# is read at read() time instead).
func _source_key(event: InputEvent) -> String:
	if event is InputEventKey:
		var key: InputEventKey = event
		return "key:%d" % (key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	if event is InputEventJoypadButton:
		var button: InputEventJoypadButton = event
		return "pad:%d:%d" % [button.device, button.button_index]
	return ""
