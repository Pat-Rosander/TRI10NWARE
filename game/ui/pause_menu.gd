# The pause menu: pauses and unpauses the scene tree, which stops World's ticks and so freezes the
# countdown. Resume marks inputs stale; Restart room is a death with cause restart. Fullscreen,
# Sound on/off, and Quit (hidden on web). Serves AC R-04, D-07.
extends CanvasLayer

const WorldScript := preload("res://world/world.gd")

## The World to pause. Set by Main.
var world: WorldScript
## Main's fullscreen toggle and quit, set by Main.
var toggle_fullscreen: Callable
var quit_game: Callable

@onready var _resume: Button = %Resume
@onready var _restart: Button = %Restart
@onready var _fullscreen: Button = %Fullscreen
@onready var _sound: Button = %Sound
@onready var _quit: Button = %Quit


func _ready() -> void:
	hide()
	_resume.pressed.connect(resume)
	_restart.pressed.connect(_on_restart)
	_fullscreen.pressed.connect(_on_fullscreen)
	_sound.pressed.connect(_on_sound)
	_quit.pressed.connect(_on_quit)
	_quit.visible = not OS.has_feature("web")
	_show_sound_state()


## Pauses the tree and shows the menu. Only while World's ticks run (not on the title or
## completion screens).
func open() -> void:
	if visible or world == null or not world.ticks_run():
		return
	get_tree().paused = true
	show()
	_resume.grab_focus()


## Hides the menu, unpauses the tree and marks inputs stale, so a button held through the pause
## never acts.
func resume() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = false
	world.mark_inputs_stale()


func _on_restart() -> void:
	resume()
	world.restart_room()


func _on_fullscreen() -> void:
	toggle_fullscreen.call()


func _on_sound() -> void:
	var master: int = AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(master, not AudioServer.is_bus_mute(master))
	_show_sound_state()


func _on_quit() -> void:
	quit_game.call()


func _show_sound_state() -> void:
	var muted: bool = AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Master"))
	_sound.text = "Sound: off" if muted else "Sound: on"
