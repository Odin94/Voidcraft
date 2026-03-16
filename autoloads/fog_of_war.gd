extends Node
## Fog of war: hides enemies outside vision range of any player unit or building.
## Uses script-based visibility toggling so the map is always fully visible.

const PLAYER_VISION_RANGE := 320.0
const BUILDING_VISION_RANGE := 200.0
const CHECK_INTERVAL := 0.25

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

	# Collect all vision sources (player units + player buildings)
	var sources: Array = []
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			sources.append(node)
	for node in get_tree().get_nodes_in_group("buildings"):
		if is_instance_valid(node):
			sources.append(node)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var visible := false
		for source in sources:
			var range := PLAYER_VISION_RANGE if source.is_in_group("player") else BUILDING_VISION_RANGE
			if enemy.global_position.distance_to(source.global_position) <= range:
				visible = true
				break
		enemy.visible = visible
