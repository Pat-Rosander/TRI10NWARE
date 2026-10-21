# Every room scene's root. World talks to rooms only through it: bounds from the catalog, the
# entrance, charged-object, goal-zone and collectible lookups and the room's SolidGrid. In the
# editor it outlines its bounds. Serves AC R-01, L1-04, G-02.
@tool
class_name Room
extends Node2D

## Loaded at runtime, never preloaded: the catalog holds this room's scene, which holds this
## script, so a preload would be a load cycle.
const CATALOG_PATH: String = "res://rooms/room_catalog.tres"
const _BOUNDS_COLOR: Color = Color(1.0, 0.6, 0.1, 0.9)

## Matches this room's `RoomEntry` in the catalog.
@export var room_id: StringName: set = _set_room_id

## The room's `world_rect` from the catalog; empty if the room is not in it.
var bounds: Rect2i = Rect2i()


func _ready() -> void:
	_read_bounds()


func _draw() -> void:
	if Engine.is_editor_hint() and bounds.has_area():
		draw_rect(Rect2(Vector2.ZERO, Vector2(bounds.size)), _BOUNDS_COLOR, false, 2.0)


## The entrance whose `entrance_id` is [param entrance_id], or null (with an error).
func entrance(entrance_id: StringName) -> RoomEntrance:
	for candidate: RoomEntrance in entrances():
		if candidate.entrance_id == entrance_id:
			return candidate
	push_error("Room '%s': no entrance '%s'." % [room_id, entrance_id])
	return null


## Every entrance, sorted by node name (the same-tick ordering rule).
func entrances() -> Array[RoomEntrance]:
	var found: Array[RoomEntrance] = []
	for child: Node in $Entrances.get_children():
		if child is RoomEntrance:
			found.append(child)
	found.sort_custom(func(a: RoomEntrance, b: RoomEntrance) -> bool:
			return String(a.name) < String(b.name))
	return found


## Every charged object under `Objects`, at any depth (from M5 they sit inside networks),
## sorted by node name (the same-tick ordering rule).
func charged_objects() -> Array[ChargedObject]:
	var found: Array[ChargedObject] = []
	_collect_charged($Objects, found)
	found.sort_custom(func(a: ChargedObject, b: ChargedObject) -> bool:
			return String(a.name) < String(b.name))
	return found


## Every goal zone under `Objects`, at any depth, sorted by node name (the same-tick ordering
## rule).
func goal_zones() -> Array[GoalZone]:
	var found: Array[GoalZone] = []
	_collect_goals($Objects, found)
	found.sort_custom(func(a: GoalZone, b: GoalZone) -> bool:
			return String(a.name) < String(b.name))
	return found


## Every collectible under `Collectibles`, sorted by node name (the same-tick ordering rule).
func collectibles() -> Array[Collectible]:
	var found: Array[Collectible] = []
	for child: Node in $Collectibles.get_children():
		if child is Collectible:
			found.append(child)
	found.sort_custom(func(a: Collectible, b: Collectible) -> bool:
			return String(a.name) < String(b.name))
	return found


## Builds the room's SolidGrid from its three tile layers. Call after the room is placed.
func build_grid() -> SolidGrid:
	var grid: SolidGrid = SolidGrid.new(bounds, Tuning.data.spike_depth_px,
			Tuning.data.spike_inset_px)
	for layer_name: String in ["WorldTiles", "DefaultTiles", "FlowTiles"]:
		grid.add_layer(get_node(layer_name) as TileMapLayer)
	return grid


func _collect_charged(parent: Node, found: Array[ChargedObject]) -> void:
	for child: Node in parent.get_children():
		if child is ChargedObject:
			found.append(child)
		_collect_charged(child, found)


func _collect_goals(parent: Node, found: Array[GoalZone]) -> void:
	for child: Node in parent.get_children():
		if child is GoalZone:
			found.append(child)
		_collect_goals(child, found)


func _set_room_id(value: StringName) -> void:
	room_id = value
	if is_inside_tree():
		_read_bounds()


func _read_bounds() -> void:
	bounds = Rect2i()
	if room_id.is_empty():
		return
	var catalog: RoomCatalog = load(CATALOG_PATH) as RoomCatalog
	if catalog == null:
		return
	for entry: RoomEntry in catalog.rooms:
		if entry != null and entry.room_id == room_id:
			bounds = entry.world_rect
	queue_redraw()
