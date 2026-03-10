extends Node2D
## Hand-crafted first combat level. Tracks enemies and emits map_cleared when all dead.

const GRUNT_DATA := preload("res://resources/enemies/grunt.tres")

var enemy_count: int = 0

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	# Count enemies that were pre-placed in the scene
	enemy_count = $Enemies.get_child_count()
	# Apply depth-1 difficulty and data to each pre-placed enemy
	for enemy in $Enemies.get_children():
		enemy.setup(GRUNT_DATA, GameManager.get_difficulty_multiplier())

func _on_enemy_killed(_enemy: Node2D, _pos: Vector2) -> void:
	enemy_count -= 1
	if enemy_count <= 0:
		EventBus.map_cleared.emit()
		GameManager.change_state(GameManager.GameState.RESULTS)
		EventBus.combat_results_shown.emit(GameManager.pending_rewards)
