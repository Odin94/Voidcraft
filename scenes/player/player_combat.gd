class_name PlayerCombat
extends Node
## Handles the player's ATTACKING state: pathfinding to target, firing projectiles.

const ATTACK_RANGE := 150.0
const ATTACK_COOLDOWN := 0.5
const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")

var attack_target: Node2D = null
var attack_timer: float = 0.0

var _player: CharacterBody2D
var _nav_agent: NavigationAgent2D
var _sprite: Polygon2D

func setup(player: CharacterBody2D, nav_agent: NavigationAgent2D, sprite: Polygon2D) -> void:
	_player = player
	_nav_agent = nav_agent
	_sprite = sprite

## Called each physics frame while in ATTACKING state.
## Returns false when the target is lost (caller should exit ATTACKING state).
func process(delta: float) -> bool:
	attack_timer = maxf(attack_timer - delta, 0.0)

	if not is_instance_valid(attack_target):
		attack_target = null
		return false

	var dist := _player.global_position.distance_to(attack_target.global_position)
	if dist > ATTACK_RANGE:
		_nav_agent.target_position = attack_target.global_position
		var next_pos := _nav_agent.get_next_path_position()
		var dir := _player.global_position.direction_to(next_pos)
		_nav_agent.velocity = dir * 200.0
		_face(dir)
	else:
		_player.velocity = Vector2.ZERO
		_player.move_and_slide()
		_face(_player.global_position.direction_to(attack_target.global_position))
		if attack_timer <= 0.0:
			_fire()
			attack_timer = ATTACK_COOLDOWN

	return true

func set_target(enemy: Node2D) -> void:
	attack_target = enemy
	attack_timer = 0.0

func clear_target() -> void:
	attack_target = null

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

func _fire() -> void:
	if not is_instance_valid(attack_target):
		return
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = _player.global_position
	proj.direction = _player.global_position.direction_to(attack_target.global_position)
	proj.damage = 15.0
	proj.source = "player"
	_player.get_tree().current_scene.add_child(proj)
	EventBus.projectile_fired.emit(proj)

func _face(dir: Vector2) -> void:
	if dir.length() > 0.1:
		_sprite.rotation = dir.angle() + PI / 2
