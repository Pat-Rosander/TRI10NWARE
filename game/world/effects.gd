# One-shot visual effects: plays the effect for each Trace event that has one, centered on the
# player's body, through a small pool of AnimatedSprite2Ds. It only listens and reads, so no
# rule depends on it and no rule waits for an effect. Serves AC V-04.
extends Node2D

## Emitted each time an effect starts, with its animation and world position. Tests listen to it.
signal effect_played(effect: StringName, at: Vector2)

## How many effects can show at once; the oldest is reused when all are busy (decision log, M3.5).
const POOL_SIZE: int = 8
const FRAMES: SpriteFrames = preload("res://world/effects_frames.tres")

var _pool: Array[AnimatedSprite2D] = []
# The pool index used next: always the effect that started longest ago.
var _next: int = 0

@onready var _player: Player = get_node("../Player")
@onready var _camera: Camera2D = get_node("../Camera")


func _ready() -> void:
	for i: int in POOL_SIZE:
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.sprite_frames = FRAMES
		sprite.visible = false
		# Hiding a finished effect is visual only; nothing waits for it.
		sprite.animation_finished.connect(sprite.hide)
		add_child(sprite)
		_pool.append(sprite)
	Trace.event_logged.connect(_on_event_logged)


## Plays [param effect] centered on [param at], in world pixels, on the next pool sprite.
func play(effect: StringName, at: Vector2) -> void:
	var sprite: AnimatedSprite2D = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	sprite.position = at
	# Physics interpolation would otherwise slide a reused sprite from its last spot.
	sprite.reset_physics_interpolation()
	sprite.visible = true
	sprite.play(effect)
	sprite.frame = 0
	effect_played.emit(effect, at)


## The rectangle the camera shows, in world pixels.
func view_rect() -> Rect2:
	var size: Vector2 = get_viewport_rect().size
	return Rect2(_camera.position - size / 2.0, size)


func _on_event_logged(entry: Dictionary) -> void:
	var data: Dictionary = entry["data"]
	match entry["event"]:
		"death":
			var at: Vector2 = _body_center()
			if data["cause"] == "fell":
				# The player has left the screen; show the effect where they left it.
				var view: Rect2 = view_rect()
				at = at.clamp(view.position, view.end)
			play(&"death", at)
		"respawn":
			play(&"respawn", _body_center())
		"jump":
			if data["kind"] == "charged":
				play(&"charged_jump", _body_center())
		"dash_start":
			play(&"dash", _body_center())
		"land":
			play(&"land", _body_center())
		"room_complete":
			play(&"goal", _body_center())


# The center of the player's collision body at the rule position (the event's tick, before the
# visual position is published).
func _body_center() -> Vector2:
	var body: Rect2i = _player.mover.body_rect(_player.mover.position)
	return Vector2(body.position) + Vector2(body.size) / 2.0
