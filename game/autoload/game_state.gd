# GameState autoload, the save record: committed collectible IDs, permanent unlock flags and the
# completion flag, kept apart from the temporary electricity a death resets. In memory for the
# session only; nothing is written to disk (saving is parked). Serves AC G-02.
extends Node

## Whether the final room's goal has been reached (M7).
var completed: bool = false

var _collectibles: Dictionary = {}
var _unlocks: Dictionary = {}


## Records the collectible [param id] as committed for the rest of the session.
func commit(id: String) -> void:
	_collectibles[id] = true


## True if the collectible [param id] has been committed this session.
func is_committed(id: String) -> bool:
	return _collectibles.has(id)


## Every committed collectible ID, sorted.
func committed_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in _collectibles:
		ids.append(id)
	ids.sort()
	return ids


## Sets the permanent unlock flag [param flag].
func unlock(flag: StringName) -> void:
	_unlocks[flag] = true


## True if the permanent unlock flag [param flag] is set.
func is_unlocked(flag: StringName) -> bool:
	return _unlocks.has(flag)


## Records that the game has been completed.
func mark_completed() -> void:
	completed = true


## Starts a new game's progress: no collectibles, no unlocks, not completed.
func reset() -> void:
	_collectibles.clear()
	_unlocks.clear()
	completed = false
