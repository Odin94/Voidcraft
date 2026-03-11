extends Control
## Minimap: draws a scaled-down overview of the current map showing entity positions.

const MAP_SIZE := Vector2(1280, 720)
const BG_COLOR := Color(0.05, 0.05, 0.1, 0.85)
const BORDER_COLOR := Color(0.5, 0.5, 0.6, 1)
const PLAYER_COLOR := Color(0.2, 0.95, 0.2, 1)
const ENEMY_COLOR := Color(0.95, 0.2, 0.2, 1)
const BUILDING_COLOR := Color(0.3, 0.6, 1.0, 1)
const DOT_RADIUS := 3.5

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var sz := size
	if sz.x == 0 or sz.y == 0:
		return
	draw_rect(Rect2(Vector2.ZERO, sz), BG_COLOR)
	draw_rect(Rect2(Vector2.ZERO, sz), BORDER_COLOR, false, 1.5)

	for entity in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(entity):
			_draw_dot(entity.global_position, PLAYER_COLOR, sz)

	for entity in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(entity):
			_draw_dot(entity.global_position, ENEMY_COLOR, sz)

	for entity in get_tree().get_nodes_in_group("buildings"):
		if is_instance_valid(entity):
			_draw_dot(entity.global_position, BUILDING_COLOR, sz)

func _draw_dot(world_pos: Vector2, color: Color, sz: Vector2) -> void:
	var mapped := Vector2(
		(world_pos.x / MAP_SIZE.x) * sz.x,
		(world_pos.y / MAP_SIZE.y) * sz.y
	)
	draw_circle(mapped, DOT_RADIUS, color)
