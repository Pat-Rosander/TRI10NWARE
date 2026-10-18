# The base every unit test extends: asserts that record failures with a message, plus helpers
# for nodes and for errors a test causes on purpose. Run by tests/test_runner.gd. Serves AC D-08.
class_name TestCase
extends RefCounted

## The test method being run; the runner sets it, and failure messages start with it.
var current_test: String = ""
## Every failure recorded during the current test.
var failures: Array[String] = []
## How many errors this test took with take_errors(), for the runner's summary.
var claimed_errors: int = 0

## Where add_node() puts nodes; the runner sets it.
var host: Node = null
var _nodes: Array[Node] = []
# Errors and push_error messages raised during the current test; the runner's logger fills it.
var _errors: Array[String] = []
var _errors_mutex: Mutex = Mutex.new()


## Fails unless [param actual] equals [param expected] and has the same type.
func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> bool:
	if typeof(actual) != typeof(expected):
		return _fail(msg, "expected %s (%s), got %s (%s)" % [
				expected, type_string(typeof(expected)), actual, type_string(typeof(actual))])
	if actual != expected:
		return _fail(msg, "expected %s, got %s" % [expected, actual])
	return true


## Fails unless [param condition] is true.
func assert_true(condition: bool, msg: String = "") -> bool:
	return true if condition else _fail(msg, "expected true")


## Fails unless [param condition] is false.
func assert_false(condition: bool, msg: String = "") -> bool:
	return true if not condition else _fail(msg, "expected false")


## Fails unless [param actual] is within [param tolerance] of [param expected].
func assert_near(actual: float, expected: float, tolerance: float, msg: String = "") -> bool:
	if absf(actual - expected) <= tolerance:
		return true
	return _fail(msg, "expected %s ± %s, got %s" % [expected, tolerance, actual])


## Adds [param node] to the scene tree (so its _ready runs) and frees it when the test ends.
func add_node(node: Node) -> Node:
	_nodes.append(node)
	host.add_child(node)
	return node


## Returns and clears the errors raised so far in this test. Any error a test does not take
## this way fails it.
func take_errors() -> Array[String]:
	_errors_mutex.lock()
	var taken: Array[String] = _errors.duplicate()
	_errors.clear()
	_errors_mutex.unlock()
	claimed_errors += taken.size()
	return taken


## Called by the runner's logger, possibly from another thread.
func capture_error(message: String) -> void:
	_errors_mutex.lock()
	_errors.append(message)
	_errors_mutex.unlock()


## Called by the runner when the test ends.
func free_nodes() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _fail(msg: String, detail: String) -> bool:
	var text: String = detail if msg.is_empty() else "%s: %s" % [msg, detail]
	failures.append("%s: %s" % [current_test, text])
	return false
