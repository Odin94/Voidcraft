extends CanvasLayer
## HUD showing resources, player HP, and current map/depth indicator.

@onready var resource_label: Label = $MarginContainer/VBoxContainer/ResourceLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPLabel
@onready var depth_label: Label = $MarginContainer/VBoxContainer/DepthLabel

var _player: Node2D

func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.return_to_home.connect(_on_return_to_home)
	_update_resources()
	_update_depth_label()

func set_player(player: Node2D) -> void:
	_player = player
	if not is_instance_valid(_player):
		return
	if _player.has_node("HealthComponent"):
		_player.get_node("HealthComponent").health_changed.connect(_on_player_health_changed)
		var hc: HealthComponent = _player.get_node("HealthComponent")
		_update_hp(hc.current_hp, hc.max_hp)

func _on_resources_changed(_name: String, _amount: int) -> void:
	_update_resources()

func _update_resources() -> void:
	var res := ResourceManager.get_all_resources()
	var text := ""
	for key in res:
		text += "%s: %d  " % [key.capitalize(), res[key]]
	resource_label.text = text.strip_edges()

func _on_player_health_changed(current: float, max_hp: float) -> void:
	_update_hp(current, max_hp)

func _update_hp(current: float, max_hp: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(max_hp)]

func _on_map_entered(_type: String, depth: int) -> void:
	depth_label.text = "Combat - Depth %d" % depth
	depth_label.visible = true

func _on_return_to_home() -> void:
	_update_depth_label()

func _update_depth_label() -> void:
	if GameManager.current_state == GameManager.GameState.HOME:
		depth_label.text = "Home Base"
	else:
		depth_label.text = "Combat - Depth %d" % GameManager.combat_depth
