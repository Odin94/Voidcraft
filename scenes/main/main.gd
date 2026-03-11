extends Node2D
## Root scene: holds MapContainer, Player, Camera, and UI.

@onready var map_container: Node2D = $MapContainer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $UILayer/HUD
@onready var combat_results: CanvasLayer = $UILayer/CombatResults
@onready var building_menu: CanvasLayer = $UILayer/BuildingMenu

func _ready() -> void:
	get_viewport().physics_object_picking = true
	GameManager.setup(map_container, player)
	hud.set_player(player)
	building_menu.set_player(player)
	# Load home base
	var home_scene := load("res://scenes/maps/home_base.tscn") as PackedScene
	var home := home_scene.instantiate()
	map_container.add_child(home)
	# Building menu is visible on home base from the start
	building_menu.panel.visible = true

func _process(_delta: float) -> void:
	camera.global_position = player.global_position
