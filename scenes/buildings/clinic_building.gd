extends "res://scenes/buildings/building_base.gd"
## Clinic: heals the player while at the home base. Upgrade for larger heals.

const BASE_HEAL      := 30.0
const HEAL_PER_LEVEL := 20.0
const HEAL_COST      := {"crystal": 15}

func get_building_actions() -> Array:
	var player      := _get_player()
	var heal_amount := BASE_HEAL + (level - 1) * HEAL_PER_LEVEL
	var actions     := [
		{
			"label": "Heal Player  +%.0f HP  (Crystal: %d)" % [heal_amount, HEAL_COST["crystal"]],
			"enabled": is_instance_valid(player) and ResourceManager.can_afford_dict(HEAL_COST),
			"callback": func(): _do_heal(player, heal_amount)
		}
	]

	if level < building_data.max_level:
		var upgrade_cost := get_upgrade_cost()
		var next_heal    := BASE_HEAL + level * HEAL_PER_LEVEL
		var uc_text      := ""
		for key in upgrade_cost:
			uc_text += "%s: %d  " % [key.capitalize(), upgrade_cost[key]]
		actions.append({
			"label": "Upgrade Clinic  (next heal: +%.0f HP)  %s" % [next_heal, uc_text.strip_edges()],
			"enabled": ResourceManager.can_afford_dict(upgrade_cost),
			"callback": func(): upgrade()
		})
	else:
		actions.append({
			"label": "Max level  (%.0f HP per heal)" % heal_amount,
			"enabled": false,
			"callback": func(): pass
		})

	return actions

func _do_heal(player: Node2D, amount: float) -> void:
	if not is_instance_valid(player) or not ResourceManager.spend_dict(HEAL_COST):
		return
	player.heal_player(amount)
	print("[Clinic] healed player for %.0f HP" % amount)

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
