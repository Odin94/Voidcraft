extends Node2D
## Thin arc drawn around a selected entity. Set radius and call queue_redraw().

var radius: float = 20.0
var color: Color = Color(1.0, 1.0, 1.0, 0.30)

func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, 1.5, true)
