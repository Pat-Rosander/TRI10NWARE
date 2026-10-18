# Shows the player: each frame picks the animation and facing from the player's state. Reads
# state only and never changes it (visuals are a window, not a lever). Serves AC M-01, M-02, M-03 (movement shown as decided).
extends Node2D

## Animation name prefix for the default state; M2 adds "electric_" for flow.
const DEFAULT_PREFIX: String = "default_"

@onready var _player: Player = get_parent()
@onready var _sprite: AnimatedSprite2D = $Sprite


func _process(_delta: float) -> void:
	if _player.mover == null:
		return
	var action: String = "idle"
	if _player.dash.is_active():
		action = "dash"
	elif not _player.state.grounded:
		action = "jump"
	elif _player.mover.velocity_x != 0.0:
		action = "run"
	var animation: StringName = StringName(DEFAULT_PREFIX + action)
	if _sprite.animation != animation:
		_sprite.play(animation)
	_sprite.flip_h = _player.state.facing < 0
