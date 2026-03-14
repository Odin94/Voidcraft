class_name ActiveTeleport
extends "res://scenes/skills/skill_base.gd"
## Active skill: instantly teleport up to MAX_RANGE units to the target position.
## If the target is out of range, the player walks toward it first, then blinks on arrival.

const MAX_RANGE := 200.0
const COOLDOWN_TIME := 5.0

func _init() -> void:
	display_name = "Blink"
	description = "Teleport up to 200 units toward target. Click to aim."
	is_passive = false
	icon_color = Color(0.7, 0.3, 1.0)
	targeting_range = MAX_RANGE

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
	print("[Skill] Blink registered")

func remove_from_player(player: Node) -> void:
	player.unregister_active_ability(self)
	print("[Skill] Blink unregistered")

func activate(player: Node, target_pos: Vector2) -> bool:
	if not can_activate():
		return false
	if player.global_position.distance_to(target_pos) > MAX_RANGE:
		# Out of range: walk to blink range, then cast automatically
		print("[Skill] Blink out of range — queuing approach")
		player.queue_blink_to(target_pos, self)
		return true
	_do_blink(player, target_pos)
	return true

func _do_blink(player: Node, target_pos: Vector2) -> void:
	player.global_position = target_pos
	_cooldown = COOLDOWN_TIME
	print("[Skill] Blink fired → %s" % str(target_pos.snapped(Vector2.ONE)))
