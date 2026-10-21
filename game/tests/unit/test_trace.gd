# Tests Trace on private instances (the real autoload is never disturbed): the session header,
# tick and room stamping, the catalog check, the ring buffer, file names and JSON Lines. Serves AC D-04, D-05.
extends TestCase

const TraceScript: GDScript = preload("res://autoload/trace.gd")


func test_trace_is_second_autoload() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	assert_eq(String(root.get_child(1).name), "Trace")


func test_header_fields() -> void:
	var trace: Node = _trace()
	var header: Dictionary = trace.get_header()
	assert_eq(header["event"], "session_start", "event")
	assert_eq(header["tick"], 0, "tick")
	var data: Dictionary = header["data"]
	var version: String = ProjectSettings.get_setting("application/config/version")
	assert_eq(data["build"], "%s-dev" % version, "build")
	assert_eq(data["target"], OS.get_name(), "target")
	assert_eq(data["tick_rate"], 60, "tick_rate")
	var tuning: Dictionary = data["tuning"]
	assert_eq(tuning.size(), 47, "every tuning field")
	assert_eq(tuning["coyote_s"], 0.1, "a tuning value")


func test_begin_session_resets_tick_room_and_events() -> void:
	var trace: Node = _trace()
	trace.tick = 5
	trace.room = "level_1"
	trace.record("control_return")
	trace.begin_session()
	assert_eq(trace.tick, 0, "tick")
	assert_eq(trace.room, "", "room")
	assert_eq(trace.get_events().size(), 0, "events cleared")


func test_record_stamps_tick_and_room_and_emits_once() -> void:
	var trace: Node = _trace()
	var emitted: Array[Dictionary] = []
	trace.event_logged.connect(func(entry: Dictionary) -> void: emitted.append(entry))
	trace.tick = 42
	trace.room = "level_1"
	trace.record("press", {"action": "jump"})
	var events: Array[Dictionary] = trace.get_events()
	assert_eq(events.size(), 1, "one event")
	assert_eq(events[0], {"tick": 42, "room": "level_1", "event": "press",
			"data": {"action": "jump"}}, "entry")
	assert_eq(emitted.size(), 1, "emitted once")


func test_catalog_errors_still_record() -> void:
	var trace: Node = _trace()
	trace.record("not_an_event", {})
	var errors: Array[String] = take_errors()
	assert_eq(errors.size(), 1, "unknown event: one error")
	assert_true(errors.size() == 1 and errors[0].contains("not in the trace catalog"), "message")
	trace.record("press", {"button": "jump"})
	errors = take_errors()
	assert_eq(errors.size(), 1, "wrong fields: one error")
	assert_true(errors.size() == 1 and errors[0].contains("expects fields"), "message")
	trace.record("press", {"action": "jump", "extra": 1})
	assert_eq(take_errors().size(), 1, "extra field: one error")
	assert_eq(trace.get_events().size(), 3, "all three still recorded")


func test_ring_keeps_newest_and_header() -> void:
	var trace: Node = _trace()
	var saved_limit: int = Tuning.data.trace_memory_limit
	Tuning.data.trace_memory_limit = 3
	trace.begin_session()
	Tuning.data.trace_memory_limit = saved_limit
	for tick: int in 5:
		trace.tick = tick
		trace.record("control_return")
	var ticks: Array[int] = []
	for entry: Dictionary in trace.get_events():
		ticks.append(entry["tick"])
	assert_eq(ticks, [2, 3, 4] as Array[int], "newest three, oldest first")
	assert_eq(trace.get_header()["event"], "session_start", "header kept")
	assert_true(trace.to_jsonl().begins_with("{\"tick\":0,\"room\":\"\",\"event\":\"session_start\""),
			"header is still line 1")


func test_keep_everything_mode() -> void:
	var trace: Node = _trace()
	var saved_limit: int = Tuning.data.trace_memory_limit
	Tuning.data.trace_memory_limit = 3
	trace.begin_session(true)
	Tuning.data.trace_memory_limit = saved_limit
	for i: int in 200:
		trace.record("control_return")
	assert_eq(trace.get_events().size(), 200)


func test_file_name_format() -> void:
	var trace: Node = _trace()
	var file_name: String = trace.file_name()
	assert_false(file_name.contains(":"), "no colon")
	var pattern: RegEx = RegEx.create_from_string("^\\d{8}-\\d{6}_.+\\.jsonl$")
	assert_true(pattern.search(file_name) != null, "matches YYYYMMDD-HHMMSS_<build>.jsonl: %s" % file_name)
	assert_true(file_name.ends_with("_%s.jsonl" % trace.build_id), "ends with the build id")


func test_saves_in_one_second_get_unique_names() -> void:
	var trace: Node = _trace()
	var first: String = trace.save_to_disk()
	var second: String = trace.save_to_disk()
	assert_false(first.is_empty() or second.is_empty(), "both saved")
	assert_true(first != second, "distinct paths")
	assert_true(FileAccess.file_exists(first) and FileAccess.file_exists(second), "both exist")
	var suffix: RegEx = RegEx.create_from_string("-\\d+\\.jsonl$")
	if first.get_file().substr(0, 15) == second.get_file().substr(0, 15):
		assert_true(suffix.search(second) != null, "same second: numbered suffix: %s" % second)
	for path: String in [first, second]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func test_jsonl_format() -> void:
	var trace: Node = _trace()
	trace.tick = 7
	trace.record("snapshot", {"position": Vector2i(3, 4), "velocity": Vector2(1.5, -2.0),
			"state": "default", "volts": 3, "dash": 1, "countdown": 0, "grounded": true})
	var lines: PackedStringArray = trace.to_jsonl().strip_edges().split("\n")
	assert_eq(lines.size(), 2, "header and one event")
	var parsed: Array[Dictionary] = []
	for line: String in lines:
		var value: Variant = JSON.parse_string(line)
		assert_true(value is Dictionary, "line parses: %s" % line)
		if value is Dictionary:
			parsed.append(value)
	if parsed.size() != 2:
		return
	assert_eq(parsed[0]["event"], "session_start", "line 1 is the header")
	var header_tuning: Dictionary = parsed[0]["data"]["tuning"]
	assert_eq(header_tuning["body_size_px"], [12.0, 15.0], "Vector2i as an array")
	assert_eq((header_tuning["flow_backdrop_color"] as Array).size(), 4, "Color as an array")
	assert_eq(parsed[1].keys(), ["tick", "room", "event", "data"], "key order")
	assert_eq(parsed[1]["data"]["position"], [3.0, 4.0], "position as an array")
	assert_eq(parsed[1]["data"]["velocity"], [1.5, -2.0], "velocity as an array")


func _trace() -> Node:
	return add_node(TraceScript.new())
