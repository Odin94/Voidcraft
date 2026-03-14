class_name SkillBase
extends Resource
## Base class for all player skills. Passive skills modify player stats on equip;
## active skills register themselves with the player and implement activate().

@export var display_name: String = "Skill"
@export var description: String = ""
@export var is_passive: bool = true
@export var icon_color: Color = Color.WHITE

## If > 0, player.gd draws a range circle of this radius during targeting.
var targeting_range: float = 0.0

var _cooldown: float = 0.0

## Called every frame by SkillTreeManager (only relevant for active skills with cooldowns).
func tick(_delta: float) -> void:
	pass

## Called when this skill is equipped to the player.
func apply_to_player(_player: Node) -> void:
	pass

## Called when this skill is unequipped (e.g., player swaps choices).
func remove_from_player(_player: Node) -> void:
	pass

## For active skills: activate at world position. Returns true on success.
func activate(_player: Node, _target_pos: Vector2) -> bool:
	return false

func can_activate() -> bool:
	return true

func get_cooldown_remaining() -> float:
	return 0.0

func get_cooldown_total() -> float:
	return 0.0
