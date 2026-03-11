class_name PlayerBuilding
extends Node
## Handles the player's PLACING_BUILDING state: ghost preview, grid snap, placement.

const GRID_SIZE := 32
const BUILDING_SCENE := preload("res://scenes/buildings/building_base.tscn")

var placing_data: BuildingData = null

var _ghost: Node2D = null
var _player: CharacterBody2D

func setup(player: CharacterBody2D) -> void:
	_player = player

## Begin placing a building: spawns the ghost preview snapped to cursor immediately.
func start_placing(data: BuildingData) -> void:
	print("[PlayerBuilding] start_placing: %s" % data.display_name)
	placing_data = data
	var rect := ColorRect.new()
	rect.size = Vector2(data.size) * GRID_SIZE
	rect.color = Color(data.color.r, data.color.g, data.color.b, 0.5)
	rect.position = -rect.size / 2
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost = Node2D.new()
	_ghost.add_child(rect)
	# Set position before adding to scene so it never appears at (0,0)
	var mouse := _player.get_global_mouse_position()
	_ghost.global_position = Vector2(snapped(mouse.x, GRID_SIZE), snapped(mouse.y, GRID_SIZE))
	_player.get_tree().current_scene.add_child(_ghost)

## Call each frame while in PLACING_BUILDING state; snaps ghost to grid.
func process() -> void:
	if not _ghost:
		return
	var mouse := _player.get_global_mouse_position()
	_ghost.global_position = Vector2(
		snapped(mouse.x, GRID_SIZE),
		snapped(mouse.y, GRID_SIZE)
	)

## Attempt to confirm placement. Returns true if placement succeeded.
func confirm() -> bool:
	if not placing_data:
		print("[PlayerBuilding] confirm: no placing_data, cancelling")
		cancel()
		return false
	if not ResourceManager.can_afford_dict(placing_data.cost):
		print("[PlayerBuilding] confirm: cannot afford %s — placement denied" % placing_data.display_name)
		return false
	var pos := _ghost.global_position
	print("[PlayerBuilding] placing %s at %s" % [placing_data.display_name, str(pos.snapped(Vector2.ONE))])
	ResourceManager.spend_dict(placing_data.cost)
	var building := BUILDING_SCENE.instantiate()
	building.global_position = pos
	building.setup(placing_data)
	_add_to_map(building)
	EventBus.building_placed.emit(building, Vector2i(pos / GRID_SIZE))
	print("[PlayerBuilding] building_placed emitted for: %s" % placing_data.display_name)
	cancel()
	return true

func cancel() -> void:
	if placing_data:
		print("[PlayerBuilding] cancel: clearing ghost for %s" % placing_data.display_name)
	if _ghost and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	placing_data = null

func _add_to_map(building: Node2D) -> void:
	var map_container := _player.get_tree().current_scene.get_node("MapContainer")
	if map_container.get_child_count() > 0:
		var current_map := map_container.get_child(0)
		if current_map.has_node("Buildings"):
			current_map.get_node("Buildings").add_child(building)
			return
	_player.get_tree().current_scene.add_child(building)
