class_name PlayerCombat
extends Node
## Provides fire_at() and find_enemy_at() for the player's attack commands.

const ATTACK_RANGE := 150.0
const ATTACK_COOLDOWN := 0.5
const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")

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
	proj.damage = 15.0
	proj.source = "player"
	_player.get_tree().current_scene.add_child(proj)
	EventBus.projectile_fired.emit(proj)

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
