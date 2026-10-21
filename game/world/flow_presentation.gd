# All flow visuals in one place: on each switch it fades the room's Backdrop toward
# flow_backdrop_color and shows the charged objects' rings, full glows and `electric`
# animations (or reverses that);
# on room_enter and respawn it snaps to the player's state with no fade, and a room built for a
# crossing gets that look as soon as it is ready. It only reads Trace events and the player's
# state, and never changes rule state, so no rule depends on it. Serves AC V-02, V-03, G-01.
extends Node

## The fade in progress, if any.
var _fade: Tween

@onready var _player: Player = get_node("../Player")
@onready var _room_slot: Node = get_node("../RoomSlot")


func _ready() -> void:
	Trace.event_logged.connect(_on_event_logged)
	_room_slot.child_entered_tree.connect(_on_room_added)


## The current room's Backdrop, or null while no room is loaded.
func backdrop() -> CanvasItem:
	var room: Room = _current_room()
	return room.get_node_or_null("Backdrop") as CanvasItem if room != null else null


## The fade in progress, or null. Exposed so tests can step it.
func fade() -> Tween:
	return _fade


func _on_event_logged(entry: Dictionary) -> void:
	match entry["event"]:
		"switch":
			_show(entry["data"]["to"] == FlowLedger.state_name(FlowLedger.State.FLOW), true)
		"room_enter", "respawn":
			_show(_player.flow.is_flow(), false)


# Shows [param in_flow]'s look; the backdrop fades over flow_fade_s if [param animate], and
# rings, glows and animations change at once.
func _show(in_flow: bool, animate: bool) -> void:
	var room: Room = _current_room()
	if room == null:
		return
	for object: ChargedObject in room.charged_objects():
		object.ring_shown = in_flow
		object.glow_strength = 1.0 if in_flow else Tuning.data.glow_hint_alpha
		object.electric_look = in_flow
	if _fade != null:
		_fade.kill()
		_fade = null
	var target: Color = Tuning.data.flow_backdrop_color if in_flow else Color.WHITE
	var back: CanvasItem = backdrop()
	if back == null:
		return
	if animate and Tuning.data.flow_fade_s > 0.0:
		_fade = create_tween()
		_fade.tween_property(back, "modulate", target, Tuning.data.flow_fade_s)
	else:
		back.modulate = target


# A room entering RoomSlot (a crossing's neighbor, or a rebuilt room) shows the player's current
# look once ready, so a neighbor never slides in looking like the wrong state.
func _on_room_added(node: Node) -> void:
	var room: Room = node as Room
	if room != null:
		room.ready.connect(func() -> void: _snap(room), CONNECT_ONE_SHOT)


func _snap(room: Room) -> void:
	if _player.flow.ledger == null:
		return
	var in_flow: bool = _player.flow.is_flow()
	for object: ChargedObject in room.charged_objects():
		object.ring_shown = in_flow
		object.glow_strength = 1.0 if in_flow else Tuning.data.glow_hint_alpha
		object.electric_look = in_flow
	var back: CanvasItem = room.get_node_or_null("Backdrop") as CanvasItem
	if back != null:
		back.modulate = Tuning.data.flow_backdrop_color if in_flow else Color.WHITE


func _current_room() -> Room:
	for child: Node in _room_slot.get_children():
		if child is Room and not child.is_queued_for_deletion():
			return child
	return null
