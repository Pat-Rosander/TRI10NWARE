# The completion screen: shown when room_complete is logged; jump plays the room again through
# World.replay(), which rebuilds it and marks inputs stale, so the dismissing jump never becomes a
# jump. Serves AC L1-04, V-04.
extends CanvasLayer

const WorldScript := preload("res://world/world.gd")

## The World to replay. Set by Main.
var world: WorldScript


func _ready() -> void:
	hide()
	Trace.event_logged.connect(_on_event_logged)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or world == null:
		return
	if event.is_action_pressed(&"jump") and not event.is_echo():
		get_viewport().set_input_as_handled()
		hide()
		world.replay()


func _on_event_logged(entry: Dictionary) -> void:
	if entry.get("event", "") == "room_complete":
		show()
