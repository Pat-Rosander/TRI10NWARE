# Plays back a list of {tick, press or release} entries: exact, repeatable input for scenarios,
# with no frame delay. Serves AC D-04, D-05 (identical traces) and every scenario from M1.
class_name ScriptedInputSource
extends InputSource

var _entries: Array[Dictionary] = []
var _applied: Array[bool] = []
var _start_tick: int = 0


## Starts playing [param entries] in the scenario format, {"tick": n, "press": "jump"} or
## {"tick": n, "release": "jump"}, with ticks counted from [param start_tick]. Forgets all
## earlier state, so each case starts with nothing held.
func play(entries: Array, start_tick: int = 0) -> void:
	_reset()
	_entries.clear()
	_applied.clear()
	_start_tick = start_tick
	for entry: Variant in entries:
		if not _is_valid(entry):
			push_error("ScriptedInputSource: bad entry %s." % [entry])
			continue
		_entries.append(entry)
		_applied.append(false)


# Applies every entry due by tick that has not run yet, in list order, so a skipped tick
# loses nothing.
func _collect(tick: int) -> void:
	for i: int in _entries.size():
		var entry: Dictionary = _entries[i]
		if _applied[i] or _start_tick + int(entry["tick"]) > tick:
			continue
		_applied[i] = true
		if entry.has("press"):
			_apply(StringName(entry["press"]), true)
		else:
			_apply(StringName(entry["release"]), false)


func _is_valid(entry: Variant) -> bool:
	if not entry is Dictionary:
		return false
	var dict: Dictionary = entry
	if not dict.has("tick") or not (dict["tick"] is int or dict["tick"] is float):
		return false
	if dict.has("press") == dict.has("release"):
		return false
	var action: StringName = StringName(dict.get("press", dict.get("release", "")))
	return action in BUTTONS or action in MOVES
