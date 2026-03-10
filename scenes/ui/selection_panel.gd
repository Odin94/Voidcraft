extends CanvasLayer
## Shows info for the currently selected entity (player or building).
## Player: name, HP bar, stats.
## Building: name, level, upgrade button.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var hp_bar_bg: ColorRect = $Panel/VBox/HPBarBG
@onready var hp_bar_fill: ColorRect = $Panel/VBox/HPBarBG/HPBarFill
@onready var detail_label: Label = $Panel/VBox/DetailLabel
@onready var actions_box: VBoxContainer = $Panel/VBox/ActionsBox

const HP_BAR_MAX_WIDTH := 180.0

var _selected: Node2D = null

func _ready() -> void:
	EventBus.entity_selected.connect(_on_entity_selected)
	EventBus.entity_deselected.connect(_on_entity_deselected)

func _on_entity_selected(entity: Node2D) -> void:
	_selected = entity
	_refresh()

func _on_entity_deselected() -> void:
	_selected = null
	_refresh()

func _refresh() -> void:
	_clear_actions()
	if not is_instance_valid(_selected):
		title_label.text = "Nothing selected"
		detail_label.text = ""
		_set_hp(0.0, 0.0)
		return

	if _selected.is_in_group("player"):
		_show_player(_selected)
	elif _selected is StaticBody2D and _selected.has_method("upgrade"):
		_show_building(_selected)

func _show_player(player: Node2D) -> void:
	title_label.text = "Player"
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc:
		_set_hp(hc.current_hp, hc.max_hp)
		if not hc.health_changed.is_connected(_on_hp_changed):
			hc.health_changed.connect(_on_hp_changed)
	detail_label.text = "ATK: 15  |  ATK Speed: 0.5s  |  Move: 200"

func _show_building(building: Node2D) -> void:
	var data: BuildingData = building.building_data
	var lvl: int = building.level
	title_label.text = "%s  Lv %d / %d" % [data.display_name, lvl, data.max_level]
	_set_hp(0.0, 0.0)  # Buildings don't have HP
	hp_bar_bg.visible = false
	detail_label.text = data.description if data.description != "" else "No description."

	if lvl < data.max_level:
		var cost: Dictionary = building.get_upgrade_cost()
		var cost_text := ""
		for key in cost:
			cost_text += "%s: %d  " % [key.capitalize(), cost[key]]
		var can := ResourceManager.can_afford_dict(cost)
		var btn := Button.new()
		btn.text = "Upgrade  (%s)" % cost_text.strip_edges()
		btn.disabled = not can
		btn.modulate.a = 1.0 if can else 0.5
		btn.pressed.connect(_on_upgrade_pressed.bind(building))
		actions_box.add_child(btn)
	else:
		var lbl := Label.new()
		lbl.text = "Max level reached"
		lbl.add_theme_font_size_override("font_size", 11)
		actions_box.add_child(lbl)

func _on_upgrade_pressed(building: Node2D) -> void:
	if building.upgrade():
		_refresh()

func _set_hp(current: float, maximum: float) -> void:
	hp_bar_bg.visible = maximum > 0.0
	if maximum > 0.0:
		var ratio := clampf(current / maximum, 0.0, 1.0)
		hp_bar_fill.size.x = HP_BAR_MAX_WIDTH * ratio
		if ratio > 0.5:
			hp_bar_fill.color = Color(0.2, 0.9, 0.2, 1)
		elif ratio > 0.25:
			hp_bar_fill.color = Color(0.9, 0.9, 0.2, 1)
		else:
			hp_bar_fill.color = Color(0.9, 0.2, 0.2, 1)

func _on_hp_changed(current: float, maximum: float) -> void:
	_set_hp(current, maximum)

func _clear_actions() -> void:
	for child in actions_box.get_children():
		child.queue_free()
	hp_bar_bg.visible = true
