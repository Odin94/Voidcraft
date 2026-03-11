extends CanvasLayer
## Bottom HUD bar for building selection.
## Visible only on the home base. Refreshes affordability live as resources change.

@onready var panel: PanelContainer = $Panel
@onready var buttons_col: VBoxContainer = $Panel/VBox/ButtonsCol
@onready var hint_label: Label = $Panel/VBox/HintLabel

var _building_data: Array[BuildingData] = []
var _player: Node2D

func _ready() -> void:
	_load_building_data()
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.return_to_home.connect(_on_return_to_home)
	EventBus.player_state_changed.connect(_on_player_state_changed)
	panel.visible = false  # hidden until player is on home base

func set_player(player: Node2D) -> void:
	_player = player

func _load_building_data() -> void:
	var dir := DirAccess.open("res://resources/buildings/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var data := load("res://resources/buildings/" + file_name) as BuildingData
			if data:
				_building_data.append(data)
		file_name = dir.get_next()
	_build_buttons()

func _build_buttons() -> void:
	for child in buttons_col.get_children():
		child.queue_free()
	for data in _building_data:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 55)
		btn.pressed.connect(_on_selected.bind(data))
		buttons_col.add_child(btn)
	_refresh_buttons()

func _refresh_buttons() -> void:
	var i := 0
	for child in buttons_col.get_children():
		if i >= _building_data.size():
			break
		var data: BuildingData = _building_data[i]
		var can_afford := ResourceManager.can_afford_dict(data.cost)
		child.disabled = not can_afford
		var cost_parts: Array[String] = []
		for key in data.cost:
			cost_parts.append("%s: %d" % [key.capitalize(), data.cost[key]])
		child.text = "%s\n%s" % [data.display_name, "\n".join(cost_parts)]
		child.modulate.a = 1.0 if can_afford else 0.5
		i += 1

func _on_selected(data: BuildingData) -> void:
	if _player and _player.has_method("start_placing_building"):
		_player.start_placing_building(data)

func _on_resources_changed(_name: String, _amount: int) -> void:
	_refresh_buttons()

func _on_player_state_changed(new_state: int) -> void:
	# 3 = PLACING_BUILDING from player.gd State enum
	if new_state == 3:
		hint_label.text = "Right-click or Left-click to place  |  ESC to cancel"
	else:
		hint_label.text = "Click a building to place it"

func _on_map_entered(_type: String, _depth: int) -> void:
	panel.visible = false

func _on_return_to_home() -> void:
	panel.visible = true
	_refresh_buttons()
