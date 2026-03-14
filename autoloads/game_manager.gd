extends Node
## Manages game state, scene transitions, and combat depth.

enum GameState { HOME, COMBAT, RESULTS }

var current_state: GameState = GameState.HOME
var combat_depth: int = 0
var pending_rewards: Dictionary = {}

# XP / level system
var player_xp: int = 0
var player_level: int = 1
const XP_TO_LEVEL_UP: int = 50

var _map_container: Node2D
var _player: CharacterBody2D

func setup(map_container: Node2D, player: CharacterBody2D) -> void:
	_map_container = map_container
	_player = player

func change_state(new_state: GameState) -> void:
	current_state = new_state

func enter_combat() -> void:
	combat_depth = 1
	pending_rewards = {}
	_load_combat_map()

func push_luck() -> void:
	combat_depth += 1
	_load_combat_map()

func return_home() -> void:
	combat_depth = 0
	change_state(GameState.HOME)
	_clear_map()
	var home_scene := load("res://scenes/maps/home_base.tscn") as PackedScene
	var home := home_scene.instantiate()
	_map_container.add_child(home)
	_player.global_position = Vector2(640, 360)
	_player.revive()
	EventBus.return_to_home.emit()

func add_pending_rewards(rewards: Dictionary) -> void:
	for key in rewards:
		if pending_rewards.has(key):
			pending_rewards[key] += rewards[key]
		else:
			pending_rewards[key] = rewards[key]

func collect_rewards() -> void:
	for key in pending_rewards:
		ResourceManager.add_resource(key, pending_rewards[key])
	pending_rewards = {}

func get_difficulty_multiplier() -> float:
	return 1.0 + combat_depth * 0.3

func get_reward_multiplier() -> float:
	return 1.0 + combat_depth * 0.2

func get_enemy_count() -> int:
	return 3 + combat_depth * 2

func add_player_xp(amount: int) -> void:
	player_xp += amount
	var new_level := 1 + player_xp / XP_TO_LEVEL_UP
	while player_level < new_level:
		player_level += 1
		print("[GameManager] player leveled up to %d (total XP: %d)" % [player_level, player_xp])
		EventBus.player_leveled_up.emit(player_level)

func _load_combat_map() -> void:
	change_state(GameState.COMBAT)
	_clear_map()
	# Depth 1 uses a hand-crafted level; deeper depths use procedural generation
	var scene_path := "res://scenes/maps/combat_map_1.tscn" if combat_depth == 1 \
		else "res://scenes/maps/combat_map.tscn"
	var combat_scene := load(scene_path) as PackedScene
	var combat_map := combat_scene.instantiate()
	_map_container.add_child(combat_map)
	if combat_map.has_method("generate"):
		combat_map.generate(combat_depth)
	_player.global_position = Vector2(640, 360)
	EventBus.map_entered.emit("combat", combat_depth)

func _clear_map() -> void:
	for child in _map_container.get_children():
		child.queue_free()
