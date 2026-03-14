class_name PassiveDoubleDamage
extends "res://scenes/skills/skill_base.gd"
## Passive skill: 20% chance for each regular attack to deal double damage.

func _init() -> void:
	display_name = "Deadly Strike"
	description = "20% chance for attacks to deal double damage."
	is_passive = true
	icon_color = Color(1.0, 0.4, 0.1)

func apply_to_player(player: Node) -> void:
	player.combat.double_damage_chance = 0.2
	print("[Skill] Deadly Strike applied: 20%% double damage chance")

func remove_from_player(player: Node) -> void:
	player.combat.double_damage_chance = 0.0
	print("[Skill] Deadly Strike removed")
