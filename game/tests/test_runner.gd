# Finds every res://tests/unit/test_*.gd, runs each method named test_*, prints the results and
# quits with exit code 0 (all passed) or 1. One command answers "do the rules still hold?" Serves AC D-08.
extends Node

const UNIT_DIR: String = "res://tests/unit"
## Where tests save best times, so a run never touches the player's own user://best.cfg.
const TEST_BEST_PATH: String = "user://test_best.cfg"


# Collects every error raised while a test runs. GDScript has no exceptions: a runtime error
# only stops the method, so without this a crashed test could look like a pass.
class ErrorCapture extends Logger:
	var target: TestCase = null
	var _mutex: Mutex = Mutex.new()

	func set_target(test: TestCase) -> void:
		_mutex.lock()
		target = test
		_mutex.unlock()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		if target != null:
			var text: String = rationale if not rationale.is_empty() else code
			target.capture_error("%s (%s:%d in %s)" % [text, file, line, function])
		_mutex.unlock()


var _capture: ErrorCapture = ErrorCapture.new()
var _passed: int = 0
var _failed: int = 0
var _claimed_errors: int = 0


func _ready() -> void:
	OS.add_logger(_capture)
	GameState.best_path = TEST_BEST_PATH
	GameState.best_ticks = 0
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(UNIT_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(file)
	files.sort()
	for file: String in files:
		_run_file("%s/%s" % [UNIT_DIR, file])
	OS.remove_logger(_capture)
	if FileAccess.file_exists(TEST_BEST_PATH):
		DirAccess.remove_absolute(TEST_BEST_PATH)
	if _passed + _failed == 0:
		print("No tests found in %s." % UNIT_DIR)
		_failed = 1
	print("\n%d passed, %d failed." % [_passed, _failed])
	if _claimed_errors > 0:
		print("The %d ERROR messages above were caused on purpose and checked by the tests."
				% _claimed_errors)
	get_tree().quit(0 if _failed == 0 else 1)


func _run_file(path: String) -> void:
	print("\n%s" % path)
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_report(path, ["cannot load the script"])
		return
	var probe: Variant = script.new()
	if not probe is TestCase:
		_report(path, ["does not extend TestCase"])
		return
	var seen: Dictionary[String, bool] = {}
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not seen.has(method_name):
			seen[method_name] = true
			_run_test(script, method_name)


# Each test method gets a fresh instance, so no state leaks from one test to the next.
func _run_test(script: GDScript, method_name: String) -> void:
	var test: TestCase = script.new()
	test.current_test = method_name
	test.host = self
	_capture.set_target(test)
	test.call(method_name)
	test.free_nodes()
	_capture.set_target(null)
	_claimed_errors += test.claimed_errors
	for error: String in test.take_errors():
		test.failures.append("%s: unexpected error: %s" % [method_name, error])
	_report(method_name, test.failures)


func _report(label: String, failures: Array[String]) -> void:
	if failures.is_empty():
		_passed += 1
		print("  PASS %s" % label)
		return
	_failed += 1
	print("  FAIL %s" % label)
	for failure: String in failures:
		print("       %s" % failure)
