# Editor-only world map: builds every catalog room at its world_rect (never saved into the scene)
# and draws each room's outline, its ID and every shared opening, the way Celeste's map view
# shows a chapter. Excluded from exports. Serves AC G-01.
@tool
extends Node2D

const CATALOG_PATH: String = "res://rooms/room_catalog.tres"
const _OUTLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)
const _OPENING_COLOR: Color = Color(0.2, 1.0, 0.4, 1.0)
const _LABEL_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const _LABEL_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.8)
const _OUTLINE_WIDTH: float = 4.0
const _OPENING_WIDTH: float = 12.0
const _LABEL_SIZE: int = 32
const _LABEL_MARGIN: Vector2 = Vector2(12.0, 44.0)

## Frees the room copies and builds them again from the catalog and the room scenes. Press it
## after editing either.
@export_tool_button("Rebuild map") var rebuild_map: Callable = rebuild

var _catalog: RoomCatalog = null
var _rooms: Array[Node] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		rebuild()


func _draw() -> void:
	if not Engine.is_editor_hint() or _catalog == null:
		return
	var font: Font = ThemeDB.fallback_font
	for entry: RoomEntry in _catalog.rooms:
		if entry == null:
			continue
		var rect: Rect2 = Rect2(entry.world_rect)
		draw_rect(rect, _OUTLINE_COLOR, false, _OUTLINE_WIDTH)
		for neighbor: RoomEntry in _catalog.neighbors(entry):
			var segment: PackedVector2Array = _shared_segment(entry.world_rect,
					neighbor.world_rect)
			draw_line(segment[0], segment[1], _OPENING_COLOR, _OPENING_WIDTH)
		var at: Vector2 = rect.position + _LABEL_MARGIN
		draw_string(font, at + Vector2(2.0, 2.0), String(entry.room_id),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, _LABEL_SIZE, _LABEL_SHADOW)
		draw_string(font, at, String(entry.room_id), HORIZONTAL_ALIGNMENT_LEFT, -1.0,
				_LABEL_SIZE, _LABEL_COLOR)


## Frees the room copies and builds every catalog room again at its place on the map.
func rebuild() -> void:
	if not Engine.is_editor_hint():
		return
	for room: Node in _rooms:
		if is_instance_valid(room):
			room.queue_free()
	_rooms.clear()
	_catalog = ResourceLoader.load(CATALOG_PATH, "", ResourceLoader.CACHE_MODE_REUSE) \
			as RoomCatalog
	if _catalog == null:
		push_error("World map preview: cannot load %s." % CATALOG_PATH)
		return
	for entry: RoomEntry in _catalog.rooms:
		if entry == null or entry.scene == null:
			continue
		var room: Node2D = entry.scene.instantiate() as Node2D
		room.position = Vector2(entry.world_rect.position)
		room.show_behind_parent = true
		# No owner, so the copy is never saved into this scene.
		add_child(room)
		_rooms.append(room)
	queue_redraw()


# The stretch of edge two touching rooms share, as its two end points.
func _shared_segment(a: Rect2i, b: Rect2i) -> PackedVector2Array:
	if b.end.x == a.position.x or b.position.x == a.end.x:
		var x: int = a.position.x if b.end.x == a.position.x else a.end.x
		return PackedVector2Array([Vector2(x, maxi(a.position.y, b.position.y)),
				Vector2(x, mini(a.end.y, b.end.y))])
	var y: int = a.position.y if b.end.y == a.position.y else a.end.y
	return PackedVector2Array([Vector2(maxi(a.position.x, b.position.x), y),
			Vector2(mini(a.end.x, b.end.x), y)])
