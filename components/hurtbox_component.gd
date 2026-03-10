class_name HurtboxComponent
extends Area2D
## Detects hitbox overlaps and forwards damage to a HealthComponent.

@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent and health_component:
		health_component.take_damage(area.damage)
		if area.has_method("on_hit"):
			area.on_hit()
