extends "res://scenes/buildings/building_base.gd"
## Forge: three independent player upgrade tracks — damage, speed, and max health.
## Each track can be purchased up to MAX_UPGRADES times regardless of building level.

const DAMAGE_BONUS := 5.0
const SPEED_BONUS  := 20.0
const HEALTH_BONUS := 25.0
const MAX_UPGRADES := 3

const DMG_COST := {"crystal": 25, "metal": 20}
const SPD_COST := {"crystal": 20, "metal": 15}
const HP_COST  := {"crystal": 30, "metal": 10}

var damage_upgrades: int = 0
var speed_upgrades:  int = 0
var health_upgrades: int = 0

func get_building_actions() -> Array:
	var player := _get_player()
	return [
		{
			"label": "Upgrade Damage  +%d ATK  [%d/%d]  Crystal:%d  Metal:%d" % [
				int(DAMAGE_BONUS), damage_upgrades, MAX_UPGRADES,
				DMG_COST["crystal"], DMG_COST["metal"]
			],
			"enabled": damage_upgrades < MAX_UPGRADES and ResourceManager.can_afford_dict(DMG_COST),
			"callback": func(): _purchase_damage(player)
		},
		{
			"label": "Upgrade Speed  +%d Move  [%d/%d]  Crystal:%d  Metal:%d" % [
				int(SPEED_BONUS), speed_upgrades, MAX_UPGRADES,
				SPD_COST["crystal"], SPD_COST["metal"]
			],
			"enabled": speed_upgrades < MAX_UPGRADES and ResourceManager.can_afford_dict(SPD_COST),
			"callback": func(): _purchase_speed(player)
		},
		{
			"label": "Upgrade Health  +%d Max HP  [%d/%d]  Crystal:%d  Metal:%d" % [
				int(HEALTH_BONUS), health_upgrades, MAX_UPGRADES,
				HP_COST["crystal"], HP_COST["metal"]
			],
			"enabled": health_upgrades < MAX_UPGRADES and ResourceManager.can_afford_dict(HP_COST),
			"callback": func(): _purchase_health(player)
		}
	]

func _purchase_damage(player: Node2D) -> void:
	if damage_upgrades >= MAX_UPGRADES or not ResourceManager.spend_dict(DMG_COST):
		return
	damage_upgrades += 1
	if is_instance_valid(player):
		player.apply_damage_upgrade(DAMAGE_BONUS)
	print("[Forge] damage upgraded x%d (+%.0f ATK)" % [damage_upgrades, DAMAGE_BONUS])

func _purchase_speed(player: Node2D) -> void:
	if speed_upgrades >= MAX_UPGRADES or not ResourceManager.spend_dict(SPD_COST):
		return
	speed_upgrades += 1
	if is_instance_valid(player):
		player.apply_speed_upgrade(SPEED_BONUS)
	print("[Forge] speed upgraded x%d (+%.0f Move)" % [speed_upgrades, SPEED_BONUS])

func _purchase_health(player: Node2D) -> void:
	if health_upgrades >= MAX_UPGRADES or not ResourceManager.spend_dict(HP_COST):
		return
	health_upgrades += 1
	if is_instance_valid(player):
		player.apply_health_upgrade(HEALTH_BONUS)
	print("[Forge] health upgraded x%d (+%.0f Max HP)" % [health_upgrades, HEALTH_BONUS])

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
