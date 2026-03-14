extends CanvasLayer
## HUD showing resources, player HP, depth indicator, XP, skill tree button,
## and the active-ability bar.

@onready var resource_label: Label = $MarginContainer/VBoxContainer/ResourceLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPLabel
@onready var depth_label: Label = $MarginContainer/VBoxContainer/DepthLabel

var _player: Node2D

# Added programmatically
var _xp_label: Label
var _skill_tree_btn: Button
var _abilities_bar: HBoxContainer
var _skill_tree_ui: CanvasLayer = null

func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.return_to_home.connect(_on_return_to_home)
	EventBus.active_abilities_changed.connect(_on_active_abilities_changed)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.skill_level_unlocked.connect(_on_skill_level_unlocked)
	_update_resources()
	_update_depth_label()
	_setup_extra_ui()

func set_player(player: Node2D) -> void:
	_player = player
	if not is_instance_valid(_player):
		return
	if _player.has_node("HealthComponent"):
		_player.get_node("HealthComponent").health_changed.connect(_on_player_health_changed)
		var hc: HealthComponent = _player.get_node("HealthComponent")
		_update_hp(hc.current_hp, hc.max_hp)

func _process(_delta: float) -> void:
	_refresh_ability_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T and GameManager.current_state == GameManager.GameState.HOME:
			_open_skill_tree()
			get_viewport().set_input_as_handled()

# ── Setup ──────────────────────────────────────────────────────────────────────

func _setup_extra_ui() -> void:
	var vbox: VBoxContainer = $MarginContainer/VBoxContainer

	# XP / level label below the existing labels
	_xp_label = Label.new()
	_xp_label.name = "XPLabel"
	_xp_label.add_theme_font_size_override("font_size", 11)
	_xp_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_xp_label)

	# Skill tree button (home base only) — wrapped so it doesn't stretch to VBox width
	var btn_row := HBoxContainer.new()
	btn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(btn_row)

	_skill_tree_btn = Button.new()
	_skill_tree_btn.name = "SkillTreeButton"
	_skill_tree_btn.text = "Skill Tree [T]"
	_skill_tree_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_skill_tree_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_skill_tree_btn.pressed.connect(_open_skill_tree)
	_skill_tree_btn.visible = (GameManager.current_state == GameManager.GameState.HOME)
	btn_row.add_child(_skill_tree_btn)

	# Active ability bar — own CanvasLayer above SelectionPanel (layer 12)
	var ability_layer := CanvasLayer.new()
	ability_layer.layer = 15
	add_child(ability_layer)

	_abilities_bar = HBoxContainer.new()
	_abilities_bar.name = "AbilitiesBar"
	_abilities_bar.add_theme_constant_override("separation", 8)
	_abilities_bar.anchor_left = 0.5
	_abilities_bar.anchor_right = 0.5
	_abilities_bar.anchor_top = 1.0
	_abilities_bar.anchor_bottom = 1.0
	_abilities_bar.offset_left = -150
	_abilities_bar.offset_right = 150
	_abilities_bar.offset_top = -65
	_abilities_bar.offset_bottom = -10
	ability_layer.add_child(_abilities_bar)

	_update_xp_label()
	_update_skill_tree_btn_label()

# ── Skill tree ─────────────────────────────────────────────────────────────────

func _open_skill_tree() -> void:
	if _skill_tree_ui == null:
		var scene := load("res://scenes/skills/skill_tree_ui.tscn") as PackedScene
		_skill_tree_ui = scene.instantiate() as CanvasLayer
		get_tree().root.add_child(_skill_tree_ui)
	_skill_tree_ui.open()

func _update_skill_tree_btn_label() -> void:
	if not is_instance_valid(_skill_tree_btn):
		return
	if SkillTree.has_unpicked_levels():
		_skill_tree_btn.text = "★ Skill Tree [T]"
	else:
		_skill_tree_btn.text = "Skill Tree [T]"

# ── Ability bar ────────────────────────────────────────────────────────────────

func _on_active_abilities_changed(_abilities: Array) -> void:
	_rebuild_ability_buttons()

func _rebuild_ability_buttons() -> void:
	for child in _abilities_bar.get_children():
		child.queue_free()
	for skill in SkillTree.get_active_skills():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 50)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var c: Color = skill.icon_color
		btn.modulate = Color(c.r * 0.7 + 0.3, c.g * 0.7 + 0.3, c.b * 0.7 + 0.3, 1.0)
		btn.pressed.connect(_on_ability_button_pressed.bind(skill))
		_abilities_bar.add_child(btn)

func _refresh_ability_buttons() -> void:
	if not is_instance_valid(_abilities_bar):
		return
	var skills: Array = SkillTree.get_active_skills()
	var btns: Array = _abilities_bar.get_children()
	if skills.size() != btns.size():
		return  # Will be rebuilt by _on_active_abilities_changed
	for i in skills.size():
		var btn: Button = btns[i]
		var skill = skills[i]
		var cd: float = skill.get_cooldown_remaining()
		var is_targeting: bool = (is_instance_valid(_player) and _player._targeting_ability == skill)
		if cd > 0.0:
			btn.text = "%s\n%.1fs" % [skill.display_name, cd]
			btn.disabled = true
		elif is_targeting:
			btn.text = "%s\n[targeting…]" % skill.display_name
			btn.disabled = false
		else:
			btn.text = skill.display_name
			btn.disabled = false

func _on_ability_button_pressed(skill) -> void:
	if not is_instance_valid(_player):
		return
	if _player._targeting_ability == skill:
		_player.cancel_ability_targeting()
	elif skill.can_activate():
		_player.start_ability_targeting(skill)

# ── Existing HUD handlers ──────────────────────────────────────────────────────

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
	if is_instance_valid(_skill_tree_btn):
		_skill_tree_btn.visible = false

func _on_return_to_home() -> void:
	_update_depth_label()
	if is_instance_valid(_skill_tree_btn):
		_skill_tree_btn.visible = true
		_update_skill_tree_btn_label()

func _update_depth_label() -> void:
	if GameManager.current_state == GameManager.GameState.HOME:
		depth_label.text = "Home Base"
	else:
		depth_label.text = "Combat - Depth %d" % GameManager.combat_depth

func _update_xp_label() -> void:
	if not is_instance_valid(_xp_label):
		return
	var lvl := GameManager.player_level
	var xp_in_level := GameManager.player_xp % GameManager.XP_TO_LEVEL_UP
	_xp_label.text = "Lv.%d  XP:%d/%d" % [lvl, xp_in_level, GameManager.XP_TO_LEVEL_UP]

func _on_player_leveled_up(new_level: int) -> void:
	_update_xp_label()
	_update_skill_tree_btn_label()
	# Floating level-up notification
	var notif := Label.new()
	var has_new_skill := new_level in SkillTree.SKILL_TREE
	notif.text = "Level Up! %s" % ("New skill unlocked!" if has_new_skill else "")
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 22)
	notif.add_theme_color_override("font_color", Color.YELLOW)
	notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notif.anchor_left = 0.5
	notif.anchor_right = 0.5
	notif.anchor_top = 0.0
	notif.anchor_bottom = 0.0
	notif.offset_left = -200
	notif.offset_right = 200
	notif.offset_top = 80
	notif.offset_bottom = 120
	add_child(notif)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(notif, "modulate:a", 0.0, 2.0)
	tween.tween_callback(notif.queue_free)

func _on_skill_level_unlocked(_level: int) -> void:
	_update_skill_tree_btn_label()
