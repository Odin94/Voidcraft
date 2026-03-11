class_name MoveIndicator
extends Node2D
## Crosshair drawn at the movement destination of a selectable entity.
## Visibility is gated: only shown when _owner_entity is the currently selected entity.

var color: Color = Color.GREEN
var _owner_entity: Node2D = null
var _selected_entity: Node2D = null
var _should_show: bool = false

func setup(owner_entity: Node2D) -> void:
	_owner_entity = owner_entity
	z_index = 10
	visible = false
	EventBus.entity_selected.connect(_on_entity_selected)

func show_at(pos: Vector2, is_attack_move: bool) -> void:
	global_position = pos
	color = Color(1.0, 0.5, 0.0) if is_attack_move else Color.GREEN
	_should_show = true
	visible = is_instance_valid(_owner_entity) and _selected_entity == _owner_entity
	queue_redraw()

func hide_indicator() -> void:
	_should_show = false
	visible = false

func _on_entity_selected(entity: Node2D) -> void:
	_selected_entity = entity
	visible = _should_show and is_instance_valid(_owner_entity) and entity == _owner_entity

func _draw() -> void:
	var r := 10.0
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, color, 2.0)
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), color, 2.0)
	draw_line(Vector2(0.0, -6.0), Vector2(0.0, 6.0), color, 2.0)
