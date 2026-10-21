# A charged object: a circular region (origin = its center) that gives one charged jump per
# visit while powered. Holds powered and an EncounterTracker, senses the player in step 7, and
# draws its ring from the same radius the rules use, so the cue can never disagree with them;
# FlowPresentation decides when the ring shows and how strong the glow is. Serves AC C-01, C-02,
# C-03, C-04, V-02, V-03.
@tool
class_name ChargedObject
extends Node2D

## Read directly in the editor, where the Tuning autoload does not run.
const TUNING_PATH: String = "res://config/tuning.tres"
const _RING_COLOR: Color = Color(0.45, 0.85, 1.0, 0.8)
const _RING_POINTS: int = 64

## The region's radius in px; -1 uses charged_region_radius_px from tuning.
@export var region_radius_px: int = -1: set = _set_region_radius_px
## Powered from the start, with no network (the always-powered object).
@export var always_powered: bool = true

## Whether the object can give a charged jump. From M5, a network may switch it on.
var powered: bool = false: set = _set_powered
## Outside, armed or spent. Runtime only; a rebuilt room gives a fresh one.
var tracker: EncounterTracker
## Whether the ring is drawn; FlowPresentation shows it in flow only. The editor always draws it.
var ring_shown: bool = false: set = _set_ring_shown
## The glow's alpha, set by FlowPresentation: a faint hint in default, full in flow.
var glow_strength: float = 1.0: set = _set_glow_strength

@onready var _glow: Sprite2D = $Glow


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	tracker = EncounterTracker.new()
	powered = always_powered
	glow_strength = Tuning.data.glow_hint_alpha


func _draw() -> void:
	if not ring_shown and not Engine.is_editor_hint():
		return
	draw_arc(Vector2.ZERO, effective_radius(), 0.0, TAU, _RING_POINTS, _RING_COLOR, 1.0)


## The region's radius in px: [member region_radius_px], or the tuning default if it is -1.
func effective_radius() -> int:
	if region_radius_px >= 0:
		return region_radius_px
	if not Engine.is_editor_hint():
		return Tuning.data.charged_region_radius_px
	var data: Resource = load(TUNING_PATH)
	return int(data.get(&"charged_region_radius_px")) if data != null else 0


## The region's center in world pixels.
func region_center() -> Vector2i:
	return Vector2i(global_position.round())


## True if the tracker is armed and the object is powered: it can give a charged jump now.
func offers_charged_jump() -> bool:
	return powered and tracker.is_armed()


## Step 7: tests the region against [param body] (entry) and against the radius grown by
## [param exit_margin] (still inside), moves the tracker and logs `encounter` if it changed.
func sense(body: Rect2i, exit_margin: int) -> void:
	var radius: int = effective_radius()
	var center: Vector2i = region_center()
	var before: EncounterTracker.State = tracker.state
	if tracker.update(Geometry.circle_overlaps_rect(center, radius, body),
			Geometry.circle_overlaps_rect(center, radius + exit_margin, body)):
		_log_encounter(before)


## Step 4, on a charged jump: armed becomes spent, logged. Returns true if it was armed.
func spend() -> bool:
	var before: EncounterTracker.State = tracker.state
	if not tracker.spend():
		return false
	_log_encounter(before)
	return true


func _log_encounter(before: EncounterTracker.State) -> void:
	Trace.record("encounter", {"object": String(name),
			"from": EncounterTracker.state_name(before),
			"to": EncounterTracker.state_name(tracker.state)})


func _set_region_radius_px(value: int) -> void:
	region_radius_px = value
	queue_redraw()


func _set_ring_shown(value: bool) -> void:
	ring_shown = value
	queue_redraw()


func _set_glow_strength(value: float) -> void:
	glow_strength = value
	if _glow != null:
		_glow.modulate.a = value


func _set_powered(value: bool) -> void:
	powered = value
	if _glow != null:
		_glow.visible = powered
