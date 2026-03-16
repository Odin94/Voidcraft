extends StaticBody2D
## Placed building with visual, level tracking, and upgrade support.

signal upgraded(new_level: int)

var building_data: BuildingData
var level: int = 1
var _label: Label
var _selection_circle: Node2D = null

func _ready() -> void:
	add_to_group("buildings")
	EventBus.entity_selected.connect(_on_entity_selected)

func _on_entity_selected(entity: Node2D) -> void:
	if is_instance_valid(_selection_circle):
		_selection_circle.visible = (entity == self)

## Called by the player's input router when this building is selected.
## Extend here to add building-specific interactions (e.g. rally points).
func handle_input(_event: InputEvent) -> void:
	pass

func setup(data: BuildingData) -> void:
	building_data = data
	level = 1
	collision_layer = 32  # Layer 6 (Building)
	collision_mask = 0
	# Selection circle — drawn behind the building visual.
	var half := Vector2(data.size) * 32.0 / 2.0
	var sel_radius := maxf(half.x, half.y) + 6.0
	_selection_circle = preload("res://scenes/ui/selection_circle.gd").new()
	_selection_circle.radius = sel_radius
	_selection_circle.visible = false
	add_child(_selection_circle)
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
	var light := PointLight2D.new()
	light.texture = _make_light_texture()
	light.texture_scale = 3.0
	light.energy = 0.4
	light.color = Color(0.95, 0.85, 0.6)
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	light.shadow_enabled = true
	light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	add_child(light)


static func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


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
