# The completion screen: shown when room_complete is logged for a completed game (a completes_game
# goal; a banner goal's room_complete never shows it), with the run's results from GameState
# (coins committed, the run's time, the best time and "New best!"); jump starts a fresh run
# through World.replay(), which builds the start room and marks inputs stale, so the dismissing
# jump never becomes a jump. Serves AC L1-04, V-04.
extends CanvasLayer

const WorldScript := preload("res://world/world.gd")

## The World to replay. Set by Main.
var world: WorldScript

@onready var _coins: Label = %Coins
@onready var _time: Label = %Time
@onready var _best: Label = %Best
@onready var _new_best: Label = %NewBest


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


## Fills the results from GameState. Called when the overlay shows.
func show_results() -> void:
	_coins.text = "Coins: %d" % GameState.committed_ids().size()
	_time.text = "Time: %s" % GameState.format_time(GameState.run_ticks)
	_best.text = "Best: %s" % GameState.format_time(GameState.best_ticks)
	_best.visible = GameState.best_ticks > 0
	_new_best.visible = GameState.last_run_was_best


func _on_event_logged(entry: Dictionary) -> void:
	if entry.get("event", "") == "room_complete" and GameState.completed:
		show_results()
		show()
