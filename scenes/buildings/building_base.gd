extends StaticBody2D
## Placed building with visual, level tracking, and upgrade support.

signal upgraded(new_level: int)

var building_data: BuildingData
var level: int = 1
var _label: Label
var _selection_border: ColorRect

func _ready() -> void:
	add_to_group("buildings")
	EventBus.entity_selected.connect(_on_entity_selected)

func _on_entity_selected(entity: Node2D) -> void:
	if is_instance_valid(_selection_border):
		_selection_border.visible = (entity == self)

## Called by the player's input router when this building is selected.
## Extend here to add building-specific interactions (e.g. rally points).
func handle_input(_event: InputEvent) -> void:
	pass

func setup(data: BuildingData) -> void:
	building_data = data
	level = 1
	collision_layer = 32  # Layer 6 (Building)
	collision_mask = 0
	# Selection border — rendered first so it sits behind the building visual.
	var border_size := Vector2(data.size) * 32 + Vector2(6, 6)
	_selection_border = ColorRect.new()
	_selection_border.size = border_size
	_selection_border.position = -border_size / 2
	_selection_border.color = Color(1.0, 0.9, 0.1, 1.0)
	_selection_border.visible = false
	_selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_selection_border)
	var visual := ColorRect.new()
	visual.size = Vector2(data.size) * 32
	visual.position = -visual.size / 2
	visual.color = data.color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


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
