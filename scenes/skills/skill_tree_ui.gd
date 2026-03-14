extends CanvasLayer
## Skill tree UI — shows all skill levels and lets the player choose one option per level.
## Built entirely in code (no child nodes in the .tscn). Opened from the HUD.

# Explicit preload ensures SkillBase class_name is registered when this script compiles.
const _SkillBase = preload("res://scenes/skills/skill_base.gd")

var _panel: Control
var _content: VBoxContainer
var _xp_label: Label

func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()
	EventBus.skill_changed.connect(_on_skill_changed)
	EventBus.skill_level_unlocked.connect(_on_skill_level_unlocked)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)

## Called by the HUD button — rebuilds and shows the UI.
func open() -> void:
	_rebuild_all()
	visible = true

# ── UI construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Dimmed background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Centered panel wrapper
	_panel = Control.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -320
	_panel.offset_right = 320
	_panel.offset_top = -240
	_panel.offset_bottom = 240
	add_child(_panel)

	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.12, 0.12, 0.18, 1.0)
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(panel_bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SKILL TREE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Scrollable level content
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	vbox.add_child(_content)

	# XP / level line
	_xp_label = Label.new()
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 12)
	_xp_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_xp_label)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close  [Esc / T]"
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)

func _rebuild_all() -> void:
	for child in _content.get_children():
		child.queue_free()
	# Rebuild after queue_free processes (next frame) — use call_deferred
	_content.call_deferred("_notification", 0)  # noop to flush
	for level in SkillTree.SKILL_TREE:
		_build_level_row(level)
	_update_xp_label()

func _build_level_row(level: int) -> void:
	var locked := not SkillTree.is_level_unlocked(level)

	var row := VBoxContainer.new()
	row.name = "Level%d" % level
	row.add_theme_constant_override("separation", 6)
	_content.add_child(row)

	var header := Label.new()
	var lock_text := "  [LOCKED — gain XP to unlock]" if locked else ""
	header.text = "Level %d Ability%s" % [level, lock_text]
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if locked else Color(1.0, 0.9, 0.6))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(header)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	for opt_idx in SkillTree.SKILL_TREE[level].size():
		var info = SkillTree.get_skill_info(level, opt_idx)
		hbox.add_child(_build_skill_card(level, opt_idx, info, locked))

func _build_skill_card(level: int, opt_idx: int, skill, locked: bool) -> Control:
	var is_selected := SkillTree.get_current_pick(level) == opt_idx

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(270, 115)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# Card background style
	var style := StyleBoxFlat.new()
	if is_selected:
		style.bg_color = Color(skill.icon_color.r * 0.25, skill.icon_color.g * 0.25,
				skill.icon_color.b * 0.35, 1.0)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = skill.icon_color
	else:
		style.bg_color = Color(0.17, 0.17, 0.22, 1.0)
	card.add_theme_stylebox_override("panel", style)

	if locked:
		card.modulate = Color(0.45, 0.45, 0.45, 1.0)

	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 8)
	card.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	inner.add_child(vb)

	# Color swatch + name row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	vb.add_child(name_row)

	var swatch := ColorRect.new()
	swatch.color = skill.icon_color
	swatch.custom_minimum_size = Vector2(14, 14)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(swatch)

	var type_tag := "(Active)" if not skill.is_passive else "(Passive)"
	var name_lbl := Label.new()
	name_lbl.text = "%s  %s" % [skill.display_name, type_tag]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color",
			skill.icon_color.lightened(0.3) if is_selected else Color(0.95, 0.95, 0.95))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(name_lbl)

	# Description
	var desc := Label.new()
	desc.text = skill.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(desc)

	# Status / action
	if is_selected:
		var sel_lbl := Label.new()
		sel_lbl.text = "✓ Selected"
		sel_lbl.add_theme_font_size_override("font_size", 12)
		sel_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		sel_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(sel_lbl)
	elif not locked:
		var btn := Button.new()
		btn.text = "Choose"
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pressed.connect(func(): SkillTree.set_pick(level, opt_idx))
		vb.add_child(btn)
	else:
		var lock_lbl := Label.new()
		lock_lbl.text = "Locked"
		lock_lbl.add_theme_font_size_override("font_size", 11)
		lock_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lock_lbl)

	return card

func _update_xp_label() -> void:
	if not is_instance_valid(_xp_label):
		return
	var lvl := GameManager.player_level
	var xp_in_level := GameManager.player_xp % GameManager.XP_TO_LEVEL_UP
	var xp_needed := GameManager.XP_TO_LEVEL_UP
	_xp_label.text = "Player Level %d  |  XP: %d / %d" % [lvl, xp_in_level, xp_needed]

# ── Signal handlers ────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		visible = false
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			visible = false
			get_viewport().set_input_as_handled()

func _on_skill_changed(_level: int, _option: int) -> void:
	if visible:
		_rebuild_all()

func _on_skill_level_unlocked(_level: int) -> void:
	if visible:
		_rebuild_all()

func _on_player_leveled_up(_new_level: int) -> void:
	if visible:
		_rebuild_all()
	else:
		_update_xp_label()
