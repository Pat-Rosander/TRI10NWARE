# A power network: one PowerRoot, its member ChargedObjects and (from M5 step 2) its wires, all as
# children. Starts unpowered, and so do its members; World calls try_activate() in step 8, and a
# powered network never activates again. Power lives in the room instance, so a rebuilt room is
# unpowered again. Warns in the editor unless it has exactly one root. Serves AC N-01 to N-04.
@tool
class_name Network
extends Node2D

## Set by an activation; never cleared while the room lives.
var powered: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		child_entered_tree.connect(_on_children_changed)
		child_exiting_tree.connect(_on_children_changed)
		child_order_changed.connect(update_configuration_warnings)
		return
	for member: ChargedObject in members():
		member.powered = false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var roots: int = 0
	for child: Node in get_children():
		if child is PowerRoot:
			roots += 1
	if roots != 1:
		warnings.append("A network needs exactly one PowerRoot child; it has %d." % roots)
	for member: ChargedObject in members():
		if member.always_powered:
			warnings.append("'%s' has always_powered on; network members start unpowered." %
					member.name)
	return warnings


## The power source, or null if there is none.
func root() -> PowerRoot:
	for child: Node in get_children():
		if child is PowerRoot:
			return child
	return null


## The member charged objects (direct children), sorted by node name.
func members() -> Array[ChargedObject]:
	var found: Array[ChargedObject] = []
	for child: Node in get_children():
		if child is ChargedObject:
			found.append(child)
	found.sort_custom(func(a: ChargedObject, b: ChargedObject) -> bool:
			return String(a.name) < String(b.name))
	return found


## Step 8: if [param in_flow], unpowered, and [param body] (world pixels) overlaps the root's
## contact area, powers the network and every member and logs `network_activated`. Returns true
## if it activated; the caller recharges the player (once per tick).
func try_activate(body: Rect2i, in_flow: bool) -> bool:
	if not in_flow or powered:
		return false
	var source: PowerRoot = root()
	if source == null or not source.touches(body):
		return false
	powered = true
	var names: Array[String] = []
	for member: ChargedObject in members():
		member.powered = true
		names.append(String(member.name))
	Trace.record("network_activated", {"network": String(name), "members": names})
	return true


func _on_children_changed(_child: Node) -> void:
	update_configuration_warnings()
