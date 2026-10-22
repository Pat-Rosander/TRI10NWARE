# A power source: touching its contact area in flow activates its network (World, step 8). The
# contact area is the art rectangle grown by root_contact_margin_px; the editor outlines it. Not
# solid: a room paints ordinary tiles under it if it needs footing. Serves AC N-01.
@tool
class_name PowerRoot
extends Node2D

## Read directly in the editor, where the Tuning autoload does not run.
const TUNING_PATH: String = "res://config/tuning.tres"
const _AREA_COLOR: Color = Color(0.4, 1.0, 0.6, 0.9)

## The art's rectangle in px, relative to this node's origin.
@export var art_rect_px: Rect2i = Rect2i(-8, -8, 16, 16): set = _set_art_rect_px


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(_local_contact_rect()), _AREA_COLOR, false, 1.0)


## The contact area in world pixels: the art rectangle grown by root_contact_margin_px.
func contact_rect() -> Rect2i:
	var area: Rect2i = _local_contact_rect()
	area.position += Vector2i(global_position.round())
	return area


## True if [param body], in world pixels, overlaps the contact area.
func touches(body: Rect2i) -> bool:
	return contact_rect().intersects(body)


func _local_contact_rect() -> Rect2i:
	return art_rect_px.grow(_margin())


func _margin() -> int:
	if not Engine.is_editor_hint():
		return Tuning.data.root_contact_margin_px
	var data: Resource = load(TUNING_PATH)
	return int(data.get(&"root_contact_margin_px")) if data != null else 0


func _set_art_rect_px(value: Rect2i) -> void:
	art_rect_px = value
	queue_redraw()
