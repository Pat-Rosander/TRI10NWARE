# A wire: the visible link from a power source to the objects it controls. A Wire that is a
# direct child of a Network follows it: unpowered until the network activates, then powered, with
# a pulse running away from the root. A Wire anywhere else is decorative: powered is
# decorative_powered forever, and it never pulses. FlowPresentation sets flow_mode on each switch;
# the look comes from wire_current.gdshader. Visual only: no rule reads it. Serves AC V-02, V-03,
# N-02.
@tool
class_name Wire
extends Line2D

const SHADER: Shader = preload("res://objects/wire/wire_current.gdshader")
const STRIP: Texture2D = preload("res://art/props/wire_strip.png")

## A decorative wire's power, fixed for the room's life. Ignored under a Network.
@export var decorative_powered: bool = false

## Whether the wire carries current; set by its network (FlowPresentation, on activation).
var powered: bool = false: set = _set_powered
## Whether the flow look shows; set by FlowPresentation on each switch, respawn and room entry.
var flow_mode: bool = false: set = _set_flow_mode
## The pulse band's progress from the root, 0 to 1; 1 hides it.
var pulse_progress: float = 1.0: set = _set_pulse_progress

var _material: ShaderMaterial
var _pulse: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	texture = STRIP
	texture_mode = Line2D.LINE_TEXTURE_STRETCH
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	_material.set_shader_parameter(&"length_px", maxf(length_px(), 1.0))
	_material.set_shader_parameter(&"root_at_end", root_at_end())
	_material.set_shader_parameter(&"current_speed_px_s", Tuning.data.wire_current_speed_px_s)
	powered = false if is_networked() else decorative_powered
	flow_mode = flow_mode
	pulse_progress = pulse_progress


## True if this wire belongs to a network (its parent is one).
func is_networked() -> bool:
	return get_parent() is Network


## The line's total length in px.
func length_px() -> float:
	var total: float = 0.0
	for i: int in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


## True if the last point is nearer the network's root than the first, so the pulse and the
## dashes run from the end. False for a decorative wire or a network with no root.
func root_at_end() -> bool:
	var network: Network = get_parent() as Network
	if network == null or network.root() == null or points.size() < 2:
		return false
	var source: Vector2 = network.root().global_position
	return (to_global(points[points.size() - 1]).distance_to(source)
			< to_global(points[0]).distance_to(source))


## Runs the pulse band from the root outward over wire_pulse_s. A decorative wire never pulses.
func play_pulse() -> void:
	if not is_networked():
		return
	if _pulse != null:
		_pulse.kill()
	pulse_progress = 0.0
	_pulse = create_tween()
	_pulse.tween_property(self, "pulse_progress", 1.0, Tuning.data.wire_pulse_s)


## The pulse in progress, or null. Exposed so tests can step it.
func pulse() -> Tween:
	return _pulse


func _set_powered(value: bool) -> void:
	powered = value
	if _material != null:
		_material.set_shader_parameter(&"powered", value)


func _set_flow_mode(value: bool) -> void:
	flow_mode = value
	if _material != null:
		_material.set_shader_parameter(&"flow_mode", value)


func _set_pulse_progress(value: float) -> void:
	pulse_progress = value
	if _material != null:
		_material.set_shader_parameter(&"pulse_progress", value)
