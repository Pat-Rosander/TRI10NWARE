# Shows the player: each frame picks the animation (default_ or electric_ by state) and facing from the player's state,
# and plays the switch burst over it on each switch event. Reads state only and never changes it (visuals are a window,
# not a lever). Serves AC M-01, M-02, M-03 (movement shown as decided), V-04.
extends Node2D

## Animation name prefixes for the default and flow states.
const DEFAULT_PREFIX: String = "default_"
const FLOW_PREFIX: String = "electric_"

@onready var _player: Player = get_parent()
@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _switch_fx: AnimatedSprite2D = $SwitchFX


func _ready() -> void:
	_switch_fx.animation_finished.connect(_switch_fx.hide)
	Trace.event_logged.connect(_on_event_logged)


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
	var prefix: String = FLOW_PREFIX if _player.flow.is_flow() else DEFAULT_PREFIX
	var animation: StringName = StringName(prefix + action)
	if _sprite.animation != animation:
		_sprite.play(animation)
	_sprite.flip_h = _player.state.facing < 0


func _on_event_logged(entry: Dictionary) -> void:
	if entry["event"] == "switch":
		_switch_fx.show()
		_switch_fx.stop()
		_switch_fx.play(&"burst")
