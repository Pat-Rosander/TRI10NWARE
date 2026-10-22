# A control hint placed in a room's Objects: a pixel-font label shown the first time its room is
# entered in a run (room_enter), held for hint_s, then faded over hint_fade_s. Its clock is the
# run's tick count, so it waits behind the title, while paused and during a crossing's slide. It
# never shows again in the same run; GameState remembers it. Visual only: no rule reads it.
@tool
class_name Hint
extends Node2D

# Waiting on room_enter (IDLE), on screen (SHOWING), or gone for this run (DONE).
enum _Phase { IDLE, SHOWING, DONE }

## The hint's text; the owner rewrites it freely.
@export_multiline var text: String = "": set = _set_text

## "<room_id>/<NodeName>"; read from the Room ancestor on ready.
var id: String = ""

var _phase: _Phase = _Phase.IDLE
# Run ticks counted while showing, and GameState.run_ticks when last read.
var _elapsed: int = 0
var _last_run_ticks: int = 0

@onready var _label: Label = $Label


func _ready() -> void:
	_label.text = text
	if Engine.is_editor_hint():
		return
	id = _room_id() + "/" + String(name)
	hide()
	Trace.event_logged.connect(_on_event_logged)


# Visual only: advances by the run ticks that passed since the last frame, then sets the opacity.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _phase != _Phase.SHOWING:
		return
	var now: int = GameState.run_ticks
	if now > _last_run_ticks:
		if _elapsed == 0:
			# Marked on the first counted tick, not on room_enter: at launch, room_enter comes
			# behind the title, before start() resets the run.
			GameState.mark_hint_shown(id)
		_elapsed += now - _last_run_ticks
	_last_run_ticks = now
	var hold: int = Tuning.hint_ticks
	var fade: int = Tuning.hint_fade_ticks
	if _elapsed >= hold + fade:
		_phase = _Phase.DONE
		hide()
		return
	modulate.a = 1.0 if _elapsed < hold else 1.0 - float(_elapsed - hold) / float(fade)


## True while the hint is on screen (including its fade).
func is_showing() -> bool:
	return _phase == _Phase.SHOWING


func _on_event_logged(entry: Dictionary) -> void:
	if _phase != _Phase.IDLE or entry["event"] != "room_enter":
		return
	if entry["data"].get("room", "") != _room_id() or GameState.is_hint_shown(id):
		return
	_phase = _Phase.SHOWING
	_elapsed = 0
	_last_run_ticks = GameState.run_ticks
	modulate.a = 1.0
	show()


func _set_text(value: String) -> void:
	text = value
	if _label != null:
		_label.text = value


func _room_id() -> String:
	var node: Node = get_parent()
	while node != null:
		if node is Room:
			return String((node as Room).room_id)
		node = node.get_parent()
	return ""
