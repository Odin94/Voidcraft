class_name ActiveExplosionShot
extends "res://scenes/skills/skill_base.gd"
## Active skill: fire a large projectile that explodes on impact or at max range,
## damaging all enemies within the blast radius.

const COOLDOWN_TIME := 8.0
const EXPLOSION_SCENE := preload("res://scenes/projectiles/explosion_projectile.tscn")

func _init() -> void:
	display_name = "Arcane Blast"
	description = "Fire an explosive projectile. Damages all nearby enemies on impact. Click to aim."
	is_passive = false
	icon_color = Color(1.0, 0.6, 0.0)

func tick(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func can_activate() -> bool:
	return _cooldown <= 0.0

func get_cooldown_remaining() -> float:
	return maxf(0.0, _cooldown)

func get_cooldown_total() -> float:
	return COOLDOWN_TIME

func apply_to_player(player: Node) -> void:
	player.register_active_ability(self)
	print("[Skill] Arcane Blast registered")

func remove_from_player(player: Node) -> void:
	player.unregister_active_ability(self)
	print("[Skill] Arcane Blast unregistered")

func activate(player: Node, target_pos: Vector2) -> bool:
	if not can_activate():
		return false
	var proj := EXPLOSION_SCENE.instantiate()
	proj.global_position = player.global_position
	proj.direction = (target_pos - player.global_position).normalized()
	proj.damage = player.combat.damage * 1.5
	player.get_tree().current_scene.add_child(proj)
	_cooldown = COOLDOWN_TIME
	print("[Skill] Arcane Blast fired toward %s" % str(target_pos.snapped(Vector2.ONE)))
	return true
