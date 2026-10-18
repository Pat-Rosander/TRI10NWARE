# DebugOverlay: the debug readout (tick, FPS, physics rate, build ID) and the debug keys
# (backtick toggles; 1 freeze, 2 step, 3 slow motion while shown). Exists only with debug tools on.
# Serves AC D-01, D-05 and the AC page 9 debug-access requirement.
extends CanvasLayer

const WorldScript := preload("res://world/world.gd")

## The World to read and control. Set by Main when debug tools are on.
var world: WorldScript

@onready var _readout: Label = $Readout


func _process(_delta: float) -> void:
	if not visible or world == null:
		return
	var speed: String = "1×"
	if world.slow_divisor == 2:
		speed = "½×"
	elif world.slow_divisor == 4:
		speed = "¼×"
	var lines: PackedStringArray = [
		"Tick %d" % world.tick,
		"FPS %d" % roundi(Engine.get_frames_per_second()),
		"Physics %d Hz" % Engine.physics_ticks_per_second,
		"Build %s" % Trace.build_id,
		"Speed %s%s" % [speed, "  FROZEN" if world.debug_frozen else ""],
	]
	_readout.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if world == null:
		return
	if event.is_action_pressed(&"debug_toggle"):
		visible = not visible
	elif not visible:
		return
	elif event.is_action_pressed(&"debug_freeze"):
		world.debug_frozen = not world.debug_frozen
	elif event.is_action_pressed(&"debug_step"):
		# Only while frozen: a request made while running would leak a tick into the next freeze.
		if not world.debug_frozen:
			return
		world.request_step()
	elif event.is_action_pressed(&"debug_slow"):
		world.slow_divisor = {1: 2, 2: 4, 4: 1}[world.slow_divisor]
	else:
		return
	get_viewport().set_input_as_handled()
