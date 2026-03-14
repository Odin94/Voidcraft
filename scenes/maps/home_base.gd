extends Node2D
## Home base map where player builds and prepares before combat.

func _ready() -> void:
	_add_debug_panel()

func _add_debug_panel() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 15
	add_child(canvas)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(970, 10)
	vbox.add_theme_constant_override("separation", 4)
	canvas.add_child(vbox)

	var header := Label.new()
	header.text = "[ DEBUG ]"
	header.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	_add_btn(vbox, "+200 Crystal",  func(): ResourceManager.add_resource("crystal", 200))
	_add_btn(vbox, "+200 Metal",    func(): ResourceManager.add_resource("metal", 200))
	_add_btn(vbox, "+50 XP",        func(): GameManager.add_player_xp(50))

func _add_btn(parent: VBoxContainer, label: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.pressed.connect(callback)
	parent.add_child(btn)
