extends Area2D
## Vision blocker: units walk through freely but blocks vision and light from outside.
## Enemies inside are only visible to sources (player/buildings) also inside it.
## Works bidirectionally: enemies lose sight of a player who enters a blocker.

var _inside: Array = []

func _ready() -> void:
	add_to_group("vision_blockers")
	collision_layer = 0
	# Detect Player (layer 2 = bit 1 = 2) and Enemy (layer 3 = bit 2 = 4)
	collision_mask = 6
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup(block_size: Vector2) -> void:
	# Collision shape for body tracking
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = block_size
	shape.shape = rect
	add_child(shape)

	# Visual — vivid semi-transparent green
	var visual := ColorRect.new()
	visual.size = block_size
	visual.position = -block_size / 2
	visual.color = Color(0.18, 0.72, 0.22, 0.6)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)

	# Light occluder — casts shadows from PointLight2D sources
	var half := block_size / 2
	var occluder := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2( half.x, -half.y),
		Vector2( half.x,  half.y),
		Vector2(-half.x,  half.y),
	])
	occluder.occluder = poly
	add_child(occluder)

## Returns true if the given node is currently inside this blocker.
func has_node_inside(node: Node) -> bool:
	return node in _inside

func _on_body_entered(body: Node) -> void:
	if body not in _inside:
		_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_inside.erase(body)
