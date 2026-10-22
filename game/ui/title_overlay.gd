# The title screen: title, build ID and a start prompt. While shown, it draws each flow-state
# material once so its shader compiles before play. The first key or click hides it and starts
# World; browsers need that gesture before they play audio, and World marks inputs stale so the
# start key never becomes a jump. Serves AC D-04, D-07, V-02.
extends CanvasLayer

## Emitted once the start key or click has hidden the overlay and started World. Main starts
## the music on it, inside the browser's audio gesture.
signal dismissed

const WorldScript := preload("res://world/world.gd")
const WIRE_SHADER: Shader = preload("res://objects/wire/wire_current.gdshader")

## The World to start. Set by Main.
var world: WorldScript

@onready var _build: Label = %Build
@onready var _prompt: Label = %Prompt
@onready var _prewarm: Control = %Prewarm


func _ready() -> void:
	_build_prewarm()
	_build.text = "Build %s" % Trace.build_id
	# Gamepad buttons are no gesture in browsers, so the web build asks for a click or a key.
	_prompt.text = "Click or press a key to start" if OS.has_feature("web") else "Press any key"


func _unhandled_input(event: InputEvent) -> void:
	if not visible or world == null or not _is_start(event):
		return
	get_viewport().set_input_as_handled()
	hide()
	world.start()
	dismissed.emit()


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


## The materials drawn in flow that would otherwise compile on first use: the charged objects'
## additive glow (M2), and the wires' current shader (M5).
static func prewarm_materials() -> Array[Material]:
	var glow: CanvasItemMaterial = CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var current: ShaderMaterial = ShaderMaterial.new()
	current.shader = WIRE_SHADER
	return [glow, current]


# One 1 x 1 rect per material, on screen: Godot skips drawing items outside the view, so an
# off-screen one would never compile. Black changes no pixel under additive blending; the wire
# shader blends normally, so its rect is transparent black instead.
func _build_prewarm() -> void:
	for material: Material in prewarm_materials():
		var rect: ColorRect = ColorRect.new()
		rect.color = Color.BLACK if material is CanvasItemMaterial else Color.TRANSPARENT
		rect.size = Vector2.ONE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.material = material
		_prewarm.add_child(rect)
