class_name EnemyData
extends Resource
## Data definition for an enemy type.

@export var display_name: String = "Enemy"
@export var hp: float = 50.0
@export var damage: float = 10.0
@export var speed: float = 120.0
@export var attack_range: float = 40.0
@export var aggro_range: float = 200.0
@export var attack_cooldown: float = 1.0
@export var color: Color = Color.RED
## 0=Square  1=Triangle  2=Diamond  3=Pentagon
@export var shape_type: int = 0
@export var rewards: Dictionary = { "crystal": 5 }
@export var xp_reward: int = 10
