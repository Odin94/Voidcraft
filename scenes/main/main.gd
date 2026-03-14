extends Node2D
## Root scene: holds MapContainer, Player, Camera, and UI.

@onready var map_container: Node2D = $MapContainer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $UILayer/HUD
@onready var combat_results: CanvasLayer = $UILayer/CombatResults
@onready var building_menu: CanvasLayer = $UILayer/BuildingMenu

const CAMERA_PAN_SPEED := 350.0

var _is_panning: bool = false

func _ready() -> void:
	get_viewport().physics_object_picking = true
	GameManager.setup(map_container, player)
	SkillTree.setup(player)
	hud.set_player(player)
	building_menu.set_player(player)
	# Start camera centred on player
	camera.global_position = player.global_position
	# Load home base
	var home_scene := load("res://scenes/maps/home_base.tscn") as PackedScene
	var home := home_scene.instantiate()
	map_container.add_child(home)
	# Building menu is visible on home base from the start
	building_menu.panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_panning = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_panning:
		camera.global_position -= event.relative  # inverted: mouse right → camera left
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	var key_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):  key_dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): key_dir.x += 1.0
	if Input.is_key_pressed(KEY_UP):    key_dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):  key_dir.y += 1.0
	camera.global_position += key_dir * CAMERA_PAN_SPEED * delta
