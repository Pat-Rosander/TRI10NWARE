# The title screen: title, build ID and a start prompt. The first key or click hides it and starts
# World; browsers need that gesture before they play audio, and World marks inputs stale so the
# start key never becomes a jump. Serves AC D-04, D-07.
extends CanvasLayer

const WorldScript := preload("res://world/world.gd")

## The World to start. Set by Main.
var world: WorldScript

@onready var _build: Label = %Build
@onready var _prompt: Label = %Prompt


func _ready() -> void:
	_build.text = "Build %s" % Trace.build_id
	# Gamepad buttons are no gesture in browsers, so the web build asks for a click or a key.
	_prompt.text = "Click or press a key to start" if OS.has_feature("web") else "Press any key"


func _unhandled_input(event: InputEvent) -> void:
	if not visible or world == null or not _is_start(event):
		return
	get_viewport().set_input_as_handled()
	hide()
	world.start()


# A fresh key, mouse button or (off the web) gamepad button press; fullscreen and the debug
# toggle keep their own meaning.
func _is_start(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	if event.is_action(&"fullscreen") or event.is_action(&"debug_toggle"):
		return false
	if event is InputEventKey or event is InputEventMouseButton:
		return true
	return event is InputEventJoypadButton and not OS.has_feature("web")
