extends Node2D
## Procedural combat map. Tracks enemies and emits map_cleared when all dead.

var enemy_count: int = 0
var depth: int = 1

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var enemies_node: Node2D = $Enemies
@onready var map_generator: Node = $MapGenerator

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

func generate(combat_depth: int) -> void:
	depth = combat_depth
	map_generator.generate_map(self, combat_depth)
	enemy_count = enemies_node.get_child_count()

func _on_enemy_killed(_enemy: Node2D, _position: Vector2) -> void:
	enemy_count -= 1
	if enemy_count <= 0:
		EventBus.map_cleared.emit()
		GameManager.change_state(GameManager.GameState.RESULTS)
		EventBus.combat_results_shown.emit(GameManager.pending_rewards)
