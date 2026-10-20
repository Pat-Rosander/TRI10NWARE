# Main, the persistent game screen: command-line flags, debug tools, window size, fullscreen, pause
# on the pause key and on focus loss, wiring the overlays, and saving the trace on quit in debug
# runs. Keeps app-level concerns out of the simulation. Serves AC V-01, D-05, D-07, R-04.
extends Node

const WorldScript := preload("res://world/world.gd")
const DebugOverlayScript := preload("res://debug/debug_overlay.gd")
const TitleOverlayScript := preload("res://ui/title_overlay.gd")
const PauseMenuScript := preload("res://ui/pause_menu.gd")
const CompletionOverlayScript := preload("res://ui/completion_overlay.gd")

## True when debug tools are on: --debug-tools, any scenario flag, or ?debug=1 on a local web page.
var debug_tools: bool = false
## True when --run-scenarios was passed; the scenario runner arrives in M1.
var run_scenarios: bool = false
## Only scenario files whose names start with this run; empty runs all.
var scenario_prefix: String = ""
## True when --quit-when-done was passed.
var quit_when_done: bool = false
## Rendering cap from --render-fps; 0 means no cap.
var render_fps: int = 0

@onready var _world: WorldScript = $World
@onready var _debug_overlay: DebugOverlayScript = $DebugOverlay
@onready var _title: TitleOverlayScript = $TitleOverlay
@onready var _pause_menu: PauseMenuScript = $PauseMenu
@onready var _completion: CompletionOverlayScript = $CompletionOverlay


func _ready() -> void:
	parse_args(OS.get_cmdline_user_args())
	if OS.has_feature("web") and _web_debug_requested():
		debug_tools = true
	# Players never get the overlay or its keys; with debug tools on it starts hidden (backtick shows it).
	if debug_tools:
		_debug_overlay.world = _world
	else:
		_debug_overlay.queue_free()
	if render_fps > 0:
		Engine.max_fps = render_fps
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_size_window()
	# The title overlay starts World on the first key or click.
	_title.world = _world
	_completion.world = _world
	_pause_menu.world = _world
	_pause_menu.toggle_fullscreen = toggle_fullscreen
	_pause_menu.quit_game = quit_game


## Reads the user arguments (those after --). Called once at launch; public so tests can feed
## sample lists.
func parse_args(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg == "--debug-tools":
			debug_tools = true
		elif arg == "--run-scenarios":
			run_scenarios = true
		elif arg.begins_with("--run-scenarios="):
			run_scenarios = true
			scenario_prefix = arg.trim_prefix("--run-scenarios=")
		elif arg == "--quit-when-done":
			quit_when_done = true
		elif arg.begins_with("--render-fps="):
			var value: String = arg.trim_prefix("--render-fps=")
			if value.is_valid_int() and value.to_int() > 0:
				render_fps = value.to_int()
			else:
				push_error("Main: --render-fps needs a whole number above 0, got '%s'." % value)
		else:
			push_warning("Main: unknown argument '%s'." % arg)
	if run_scenarios or quit_when_done:
		debug_tools = true


## The largest whole multiple k ≥ 1 of [param base] whose window, plus [param decorations]
## (title bar and borders), fits inside [param usable].
static func window_scale(usable: Vector2i, decorations: Vector2i, base: Vector2i) -> int:
	var room: Vector2i = usable - decorations
	# Whole multiples only: the remainder is meant to be dropped.
	@warning_ignore("integer_division")
	return maxi(1, mini(room.x / base.x, room.y / base.y))


## Quits the game, saving the trace first in debug runs. Every quit Main triggers goes through here.
func quit_game(exit_code: int = 0) -> void:
	_save_trace_if_debug()
	get_tree().quit(exit_code)


## Switches between windowed and fullscreen.
func toggle_fullscreen() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_trace_if_debug()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not run_scenarios and _pause_menu != null:
		# The scenario runner must never be paused by a click elsewhere.
		_pause_menu.open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause") and not event.is_echo():
		if _pause_menu.visible:
			_pause_menu.resume()
		else:
			_pause_menu.open()
		get_viewport().set_input_as_handled()


# Grows the desktop window to the largest whole multiple of the canvas that fits the screen.
func _size_window() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("web") or Engine.is_embedded_in_editor():
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var base: Vector2i = Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Vector2i = DisplayServer.screen_get_usable_rect(screen).size
	var decorations: Vector2i = DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	var window: Window = get_window()
	window.size = base * window_scale(usable, decorations, base)
	window.move_to_center()


# On the web, ?debug=1 counts only when the page is served from this machine (tools/serve_web.sh).
func _web_debug_requested() -> bool:
	var result: Variant = JavaScriptBridge.eval(
			"(function () { var h = window.location.hostname;"
			+ " return (h === 'localhost' || h === '127.0.0.1')"
			+ " && new URLSearchParams(window.location.search).get('debug') === '1'; })()", true)
	return result is bool and result


# Normal player runs and the web build never write trace files (owner decision, M0 step 7).
func _save_trace_if_debug() -> void:
	if debug_tools and not OS.has_feature("web"):
		Trace.save_to_disk()
