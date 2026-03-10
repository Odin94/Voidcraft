extends Node2D
## ColorRect-based HP bar displayed above entities.

var _bg: ColorRect
var _fill: ColorRect
@export var bar_width := 40.0
@export var bar_height := 4.0
@export var offset := Vector2(0, -25)

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.size = Vector2(bar_width, bar_height)
	_bg.position = offset - Vector2(bar_width / 2, 0)
	_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.size = Vector2(bar_width, bar_height)
	_fill.position = _bg.position
	_fill.color = Color(0.2, 0.9, 0.2, 0.9)
	add_child(_fill)

func update_bar(current: float, maximum: float) -> void:
	if maximum <= 0:
		return
	var ratio := current / maximum
	_fill.size.x = bar_width * ratio
	if ratio > 0.5:
		_fill.color = Color(0.2, 0.9, 0.2, 0.9)
	elif ratio > 0.25:
		_fill.color = Color(0.9, 0.9, 0.2, 0.9)
	else:
		_fill.color = Color(0.9, 0.2, 0.2, 0.9)
