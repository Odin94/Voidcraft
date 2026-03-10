extends StaticBody2D
## Placed building with visual, level tracking, and upgrade support.

signal upgraded(new_level: int)

var building_data: BuildingData
var level: int = 1
var _label: Label

func setup(data: BuildingData) -> void:
	building_data = data
	level = 1
	collision_layer = 32  # Layer 6 (Building)
	collision_mask = 0
	var visual := ColorRect.new()
	visual.size = Vector2(data.size) * 32
	visual.position = -visual.size / 2
	visual.color = data.color
	visual.mouse_filter = 2
	add_child(visual)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(data.size) * 32
	shape.shape = rect
	add_child(shape)
	_label = Label.new()
	_label.text = data.display_name
	_label.position = -visual.size / 2
	_label.add_theme_font_size_override("font_size", 10)
	_label.mouse_filter = 2
	add_child(_label)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		EventBus.entity_selected.emit(self)
		get_viewport().set_input_as_handled()

func get_upgrade_cost() -> Dictionary:
	var cost := {}
	for key in building_data.cost:
		cost[key] = int(building_data.cost[key] * (level + 1) * 0.75)
	return cost

func can_upgrade() -> bool:
	return level < building_data.max_level and ResourceManager.can_afford_dict(get_upgrade_cost())

func upgrade() -> bool:
	if level >= building_data.max_level:
		return false
	var cost := get_upgrade_cost()
	if not ResourceManager.spend_dict(cost):
		return false
	level += 1
	if _label:
		_label.text = "%s Lv%d" % [building_data.display_name, level]
	upgraded.emit(level)
	return true
