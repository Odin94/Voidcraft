extends Node
## Fog of war: hides enemies outside vision range or inside vision-blocking zones.
## Uses script-based visibility toggling so the map terrain is always fully visible.

const PLAYER_VISION_RANGE := 320.0
const BUILDING_VISION_RANGE := 200.0
const CHECK_INTERVAL := 0.1

var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = CHECK_INTERVAL
	_update_visibility()

func _update_visibility() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var sources: Array = []
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			sources.append(node)
	for node in get_tree().get_nodes_in_group("buildings"):
		if is_instance_valid(node):
			sources.append(node)

	var blockers := get_tree().get_nodes_in_group("vision_blockers")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var visible := false
		var enemy_blocker = _get_blocker_for_node(enemy, blockers)
		for source in sources:
			if enemy_blocker != null:
				# Enemy is in a blocker — only visible if the source is also inside it
				if enemy_blocker.has_node_inside(source):
					visible = true
					break
			else:
				var range := PLAYER_VISION_RANGE if source.is_in_group("player") else BUILDING_VISION_RANGE
				if enemy.global_position.distance_to(source.global_position) <= range:
					visible = true
					break
		enemy.visible = visible

## Returns the VisionBlocker containing the given node, or null.
func get_blocker_for(node: Node) -> Node:
	var blockers := get_tree().get_nodes_in_group("vision_blockers")
	return _get_blocker_for_node(node, blockers)

func _get_blocker_for_node(node: Node, blockers: Array) -> Node:
	for blocker in blockers:
		if is_instance_valid(blocker) and blocker.has_node_inside(node):
			return blocker
	return null
