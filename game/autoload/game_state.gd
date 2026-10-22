# GameState autoload, the save record: committed collectible IDs, permanent unlock flags and the
# completion flag, kept apart from the temporary electricity a death resets, plus the run's tick
# count, the best completion time, and the control hints and level banners already shown this
# run. Progress lives in memory for the session only; the best time is the one value saved to
# disk (user://best.cfg, M6 step 5). Serves AC G-02.
extends Node

## Where the best completion time is saved. In the browser, user:// is browser storage.
const BEST_PATH: String = "user://best.cfg"
const BEST_SECTION: String = "run"
const BEST_KEY: String = "best_ticks"

## Whether the final room's goal has been reached (M7).
var completed: bool = false
## Ticks the current run has counted: from the title's dismissal, only while the rules run.
var run_ticks: int = 0
## The best (lowest) completion time in ticks; 0 means none yet.
var best_ticks: int = 0
## True if the last finished run set a new best.
var last_run_was_best: bool = false
## The file the best time is saved to and loaded from; tests point it elsewhere.
var best_path: String = BEST_PATH

var _collectibles: Dictionary = {}
var _unlocks: Dictionary = {}
var _hints: Dictionary = {}
var _banners: Dictionary = {}


func _ready() -> void:
	load_best()


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


## Records the hint [param id] ("<room_id>/<NodeName>") as shown for the rest of this run.
func mark_hint_shown(id: String) -> void:
	_hints[id] = true


## True if the hint [param id] has been shown this run.
func is_hint_shown(id: String) -> bool:
	return _hints.has(id)


## Records the banner goal [param id] ("<room_id>/<NodeName>") as reached for the rest of this run.
func mark_banner_shown(id: String) -> void:
	_banners[id] = true


## True if the banner goal [param id] has been reached this run.
func is_banner_shown(id: String) -> bool:
	return _banners.has(id)


## Records that the game has been completed.
func mark_completed() -> void:
	completed = true


## Starts a new run: no collectibles, no unlocks, no hints or banners shown, not completed, the
## timer at zero. The best time is kept.
func reset() -> void:
	_collectibles.clear()
	_unlocks.clear()
	_hints.clear()
	_banners.clear()
	completed = false
	run_ticks = 0
	last_run_was_best = false


## Counts one tick of the run. World calls it on every tick the rules run.
func count_tick() -> void:
	run_ticks += 1


## Ends the run at its current tick count: a new best if it is the first or strictly lower, which
## is then saved. Returns whether it was a new best.
func finish_run() -> bool:
	last_run_was_best = is_new_best(run_ticks, best_ticks)
	if last_run_was_best:
		best_ticks = run_ticks
		save_best()
	return last_run_was_best


## True if [param ticks] beats [param best] (0 means no best yet). A tie is not a new best.
static func is_new_best(ticks: int, best: int) -> bool:
	return ticks > 0 and (best <= 0 or ticks < best)


## A tick count as minutes, seconds and hundredths ("1:05.33"), in whole-number math only, so the
## text is identical on every target. Hundredths are rounded down.
static func format_time(ticks: int) -> String:
	@warning_ignore("integer_division")
	var hundredths: int = ticks * 100 / Tuning.TICKS_PER_SECOND
	@warning_ignore("integer_division")
	var seconds: int = hundredths / 100
	@warning_ignore("integer_division")
	return "%d:%02d.%02d" % [seconds / 60, seconds % 60, hundredths % 100]


## Loads the best time from [member best_path]. A missing, unreadable or invalid file leaves the
## best time unchanged, without an error.
func load_best() -> void:
	if not FileAccess.file_exists(best_path):
		return
	var file: ConfigFile = ConfigFile.new()
	if file.load(best_path) != OK:
		return
	var value: Variant = file.get_value(BEST_SECTION, BEST_KEY, 0)
	if value is int and value > 0:
		best_ticks = value


## Saves the best time to [member best_path]. If storage is unavailable the best time lasts for
## the session only; nothing errors.
func save_best() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(BEST_SECTION, BEST_KEY, best_ticks)
	file.save(best_path)
