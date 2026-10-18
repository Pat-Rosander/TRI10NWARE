# Trace autoload: the one tick-stamped log of every rule event, saved as JSON Lines.
# Sound and visuals listen to event_logged; no rule ever reads the trace. Serves AC D-04, D-05 (evidence).
extends Node

## Emitted for every recorded entry, including the session_start header.
signal event_logged(entry: Dictionary)

const TRACE_DIR: String = "user://traces"
const BUILD_INFO_PATH: String = "res://config/build_info.cfg"

## Every event the game may record, with its data fields (spec, M0 step 5). New events are added
## to the spec first, then here.
const CATALOG: Dictionary = {
	"session_start": ["build", "target", "tick_rate", "tuning"],
	"press": ["action"],
	"press_spent": ["action", "created_tick", "spent_on"],
	"press_expired": ["action", "created_tick"],
	"switch": ["from", "to", "volts_before", "volts_after"],
	"switch_refused": ["reason"],
	"volts": ["before", "after", "cause"],
	"countdown_start": ["ticks"],
	"countdown_cancel": ["cause"],
	"countdown_expire": [],
	"jump": ["kind", "vx", "vy", "object"],
	"dash_start": ["dir_x", "dir_y", "vx", "vy"],
	"dash_end": ["vx", "vy", "interrupted"],
	"dash_refill": ["cause"],
	"land": ["vx", "vy_before"],
	"encounter": ["object", "from", "to"],
	"platform_pending": ["family", "tiles"],
	"platform_solid": ["family", "tiles"],
	"overlap_snap": ["family", "dy"],
	"network_activated": ["network", "members"],
	"assist": ["kind", "dx", "dy"],
	"death": ["cause"],
	"respawn": ["room", "entrance"],
	"control_return": [],
	"room_enter": ["room", "entrance"],
	"transition_start": ["from_room", "to_room", "edge"],
	"transition_end": ["room", "checkpoint"],
	"room_complete": ["room"],
	"goal_banner": ["level"],
	"collectible": ["id", "change"],
	"snapshot": ["position", "velocity", "state", "volts", "dash", "countdown", "grounded"],
}

## The current tick. World sets it at the start of every tick.
var tick: int = 0
## The id of the room being played. World sets it when a room is built; empty until M1.
var room: String = ""
## "<version>-<commit>" for exported builds, "<version>-dev" for editor runs.
var build_id: String = ""

var _header: Dictionary = {}
# Ring buffer of events: once full, _head is the index of the oldest entry.
var _ring: Array[Dictionary] = []
var _head: int = 0
# Maximum events kept; 0 keeps everything (scenario runs).
var _limit: int = 0


func _ready() -> void:
	build_id = _read_build_id()
	begin_session()


## Clears the log and stores a new session_start header with the build, platform, tick rate and
## every tuning value. Scenario runs pass keep_everything = true to disable trimming.
func begin_session(keep_everything: bool = false) -> void:
	tick = 0
	room = ""
	_ring.clear()
	_head = 0
	_limit = 0 if keep_everything else Tuning.data.trace_memory_limit
	_header = _make_entry("session_start", {
		"build": build_id,
		"target": OS.get_name(),
		"tick_rate": Engine.physics_ticks_per_second,
		"tuning": _tuning_values(),
	})
	event_logged.emit(_header)


## Appends {tick, room, event, data} to the log and emits event_logged.
func record(event: String, data: Dictionary = {}) -> void:
	_check_catalog(event, data)
	var entry: Dictionary = _make_entry(event, data)
	if _limit <= 0 or _ring.size() < _limit:
		_ring.append(entry)
	else:
		_ring[_head] = entry
		_head = (_head + 1) % _limit
	event_logged.emit(entry)


## The session_start header of the current session.
func get_header() -> Dictionary:
	return _header


## The recorded events, oldest first (the header is not included).
func get_events() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for i: int in _ring.size():
		events.append(_ring[(_head + i) % _ring.size()])
	return events


## The header and every event as JSON Lines, one entry per line.
func to_jsonl() -> String:
	var lines: PackedStringArray = [_stringify(_header)]
	for entry: Dictionary in get_events():
		lines.append(_stringify(entry))
	return "\n".join(lines) + "\n"


## "<YYYYMMDD-HHMMSS>_<build>.jsonl", from the local clock. Never contains a colon.
func file_name() -> String:
	return "%s_%s.jsonl" % [_timestamp(), build_id]


## Writes the trace to user://traces/ and returns the file's path, or "" on failure.
func save_to_disk() -> String:
	var err: Error = DirAccess.make_dir_recursive_absolute(TRACE_DIR)
	if err != OK:
		push_error("Trace: cannot create %s (%s)." % [TRACE_DIR, error_string(err)])
		return ""
	var base: String = file_name().trim_suffix(".jsonl")
	var path: String = "%s/%s.jsonl" % [TRACE_DIR, base]
	var copy: int = 2
	while FileAccess.file_exists(path):
		path = "%s/%s-%d.jsonl" % [TRACE_DIR, base, copy]
		copy += 1
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Trace: cannot write %s (%s)." % [path, error_string(FileAccess.get_open_error())])
		return ""
	file.store_string(to_jsonl())
	file.close()
	return path


func _make_entry(event: String, data: Dictionary) -> Dictionary:
	return {"tick": tick, "room": room, "event": event, "data": data}


func _check_catalog(event: String, data: Dictionary) -> void:
	if not CATALOG.has(event):
		push_error("Trace: event '%s' is not in the trace catalog." % event)
		return
	var expected: Array = CATALOG[event]
	var given: Array = data.keys()
	expected = expected.duplicate()
	expected.sort()
	given.sort()
	if given != expected:
		push_error("Trace: event '%s' expects fields %s, got %s." % [event, expected, given])


# Every stored field of TuningData, in designer units.
func _tuning_values() -> Dictionary:
	var values: Dictionary = {}
	var stored: int = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE
	for property: Dictionary in Tuning.data.get_property_list():
		var usage: int = property["usage"]
		if usage & stored == stored:
			var field: String = property["name"]
			values[field] = Tuning.data.get(field)
	return values


func _read_build_id() -> String:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	var info: ConfigFile = ConfigFile.new()
	if info.load(BUILD_INFO_PATH) != OK:
		return "%s-dev" % version
	var built_version: String = info.get_value("build", "version", version)
	var commit: String = info.get_value("build", "commit", "unknown")
	return "%s-%s" % [built_version, commit]


func _timestamp() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d-%02d%02d%02d" % [
		now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"]]


# Keys stay in insertion order (tick, room, event, data); floats keep full precision for D-04.
func _stringify(entry: Dictionary) -> String:
	return JSON.stringify(_to_json_value(entry), "", false, true)


# JSON has no vectors or colors; write them as arrays instead of strings like "(12, 15)".
func _to_json_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [value.x, value.y]
		TYPE_COLOR:
			return [value.r, value.g, value.b, value.a]
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key: Variant in value:
				out[key] = _to_json_value(value[key])
			return out
		TYPE_ARRAY:
			var items: Array = []
			for item: Variant in value:
				items.append(_to_json_value(item))
			return items
	return value
