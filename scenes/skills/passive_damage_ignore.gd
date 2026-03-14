class_name PassiveDamageIgnore
extends "res://scenes/skills/skill_base.gd"
## Passive skill: 20% chance to completely ignore incoming damage.

func _init() -> void:
	display_name = "Iron Will"
	description = "20% chance to ignore incoming damage entirely."
	is_passive = true
	icon_color = Color(0.3, 0.6, 1.0)

func apply_to_player(player: Node) -> void:
	player.health_component.damage_ignore_chance = 0.2
	print("[Skill] Iron Will applied: 20%% damage ignore")

func remove_from_player(player: Node) -> void:
	player.health_component.damage_ignore_chance = 0.0
	print("[Skill] Iron Will removed")
