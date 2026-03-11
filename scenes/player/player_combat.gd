class_name PlayerCombat
extends Node
## Provides fire_at() and find_enemy_at() for the player's attack commands.

const ATTACK_RANGE := 150.0
const ATTACK_COOLDOWN := 0.5
const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")

var damage: float = 15.0

var _player: CharacterBody2D
var _sprite: Polygon2D

func setup(player: CharacterBody2D, sprite: Polygon2D) -> void:
	_player = player
	_sprite = sprite

## Fire a projectile toward target immediately. Caller is responsible for cooldown.
func fire_at(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = _player.global_position
	proj.direction = _player.global_position.direction_to(target.global_position)
	proj.damage = damage
	proj.source = "player"
	_player.get_tree().current_scene.add_child(proj)
	EventBus.projectile_fired.emit(proj)

## Returns the nearest enemy body within range of origin, or null if none.
func find_nearest_enemy_in_range(origin: Vector2, range: float) -> Node2D:
	var space := _player.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = range
	query.shape = shape
	query.transform = Transform2D(0.0, origin)
	query.collision_mask = 4  # Layer 3 (Enemy)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var results := space.intersect_shape(query)
	var nearest: Node2D = null
	var nearest_dist := INF
	for r in results:
		var body := r.collider as Node2D
		if is_instance_valid(body):
			var dist := origin.distance_to(body.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = body
	return nearest

## Physics point query for an enemy body at world position.
func find_enemy_at(pos: Vector2) -> Node2D:
	var space := _player.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 4  # Layer 3 (Enemy)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var results := space.intersect_point(query, 1)
	if results.size() > 0:
		return results[0].collider
	return null
