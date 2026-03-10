class_name HealthComponent
extends Node
## Reusable health component. Attach to any entity that can take damage.

signal health_changed(current_hp: float, max_hp: float)
signal died

@export var max_hp: float = 100.0
var current_hp: float

func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	current_hp = minf(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func reset() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

func get_hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp
