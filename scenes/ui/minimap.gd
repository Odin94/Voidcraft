extends Control
## Minimap: draws a scaled-down overview of the current map showing entity positions.
## Click or drag to move the camera to that world position.

const MAP_SIZE := Vector2(1280, 720)
const BG_COLOR := Color(0.05, 0.05, 0.1, 0.85)
const BORDER_COLOR := Color(0.5, 0.5, 0.6, 1)
const PLAYER_COLOR := Color(0.2, 0.95, 0.2, 1)
const ENEMY_COLOR := Color(0.95, 0.2, 0.2, 1)
const BUILDING_COLOR := Color(0.3, 0.6, 1.0, 1)
const VIEWPORT_RECT_COLOR := Color(1.0, 1.0, 1.0, 0.7)
const DOT_RADIUS := 3.5

var _is_dragging: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(_delta: float) -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_dragging = event.pressed
		if event.pressed:
			_move_camera_to(get_local_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_dragging:
		_move_camera_to(get_local_mouse_position())
		get_viewport().set_input_as_handled()

func _move_camera_to(minimap_pos: Vector2) -> void:
	var sz := size
	if sz.x == 0 or sz.y == 0:
		return
	var world_pos := Vector2(
		minimap_pos.x / sz.x * MAP_SIZE.x,
		minimap_pos.y / sz.y * MAP_SIZE.y
	)
	var cam := get_tree().get_first_node_in_group("camera") as Camera2D
	if is_instance_valid(cam):
		cam.global_position = world_pos

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
		if is_instance_valid(entity) and entity.visible:
			_draw_dot(entity.global_position, ENEMY_COLOR, sz)

	for entity in get_tree().get_nodes_in_group("buildings"):
		if is_instance_valid(entity):
			_draw_dot(entity.global_position, BUILDING_COLOR, sz)

	_draw_viewport_rect(sz)

func _draw_viewport_rect(sz: Vector2) -> void:
	var cam := get_tree().get_first_node_in_group("camera") as Camera2D
	if not is_instance_valid(cam):
		return
	var vp_world_size := get_viewport().get_visible_rect().size / cam.zoom
	var tl := cam.global_position - vp_world_size / 2.0
	var mapped_pos := Vector2(tl.x / MAP_SIZE.x * sz.x, tl.y / MAP_SIZE.y * sz.y)
	var mapped_size := Vector2(vp_world_size.x / MAP_SIZE.x * sz.x, vp_world_size.y / MAP_SIZE.y * sz.y)
	draw_rect(Rect2(mapped_pos, mapped_size), VIEWPORT_RECT_COLOR, false, 1.5)

func _draw_dot(world_pos: Vector2, color: Color, sz: Vector2) -> void:
	var mapped := Vector2(
		(world_pos.x / MAP_SIZE.x) * sz.x,
		(world_pos.y / MAP_SIZE.y) * sz.y
	)
	draw_circle(mapped, DOT_RADIUS, color)
