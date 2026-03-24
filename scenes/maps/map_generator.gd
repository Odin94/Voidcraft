extends Node
## Generates procedural obstacles and enemies for combat maps.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy_base.tscn")
const TRIFURCATOR_SCENE := preload("res://scenes/enemies/trifurcator_enemy.tscn")
const BOMBER_SCENE := preload("res://scenes/enemies/bomber_enemy.tscn")
const GRUNT_DATA := preload("res://resources/enemies/grunt.tres")
const BRUTE_DATA := preload("res://resources/enemies/brute.tres")
const TRIFURCATOR_DATA := preload("res://resources/enemies/trifurcator.tres")
const BOMBER_DATA := preload("res://resources/enemies/bomber.tres")
const VISION_BLOCKER_SCRIPT := preload("res://scenes/maps/vision_blocker.gd")

const MAP_SIZE := Vector2(1280, 720)
const MARGIN := 80.0
const OBSTACLE_MIN_SIZE := Vector2(32, 32)
const OBSTACLE_MAX_SIZE := Vector2(128, 128)
const BLOCKER_MIN_SIZE := Vector2(80, 80)
const BLOCKER_MAX_SIZE := Vector2(150, 150)
const BLOCKER_COUNT := 4

func generate_map(combat_map: Node2D, depth: int) -> void:
	_generate_obstacles(combat_map, depth)
	_spawn_vision_blockers(combat_map)
	_spawn_enemies(combat_map, depth)
	# Rebake navigation after obstacles are placed
	var nav_region := combat_map.get_node("NavigationRegion2D") as NavigationRegion2D
	nav_region.bake_navigation_polygon()

func _generate_obstacles(combat_map: Node2D, depth: int) -> void:
	var obstacles_node := combat_map.get_node("Obstacles")
	var obstacle_count := 4 + depth * 2
	for i in obstacle_count:
		var obstacle := StaticBody2D.new()
		var size := Vector2(
			randf_range(OBSTACLE_MIN_SIZE.x, OBSTACLE_MAX_SIZE.x),
			randf_range(OBSTACLE_MIN_SIZE.y, OBSTACLE_MAX_SIZE.y)
		)
		var pos := Vector2(
			randf_range(MARGIN + size.x, MAP_SIZE.x - MARGIN - size.x),
			randf_range(MARGIN + size.y, MAP_SIZE.y - MARGIN - size.y)
		)
		# Don't place near center (player spawn)
		if pos.distance_to(MAP_SIZE / 2) < 100.0:
			continue
		obstacle.position = pos
		obstacle.collision_layer = 1  # Terrain
		obstacle.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = size
		shape.shape = rect_shape
		obstacle.add_child(shape)
		# Visual
		var visual := ColorRect.new()
		visual.size = size
		visual.position = -size / 2
		visual.color = Color(0.3, 0.3, 0.35, 1.0)
		obstacle.add_child(visual)
		obstacles_node.add_child(obstacle)

func _spawn_vision_blockers(combat_map: Node2D) -> void:
	var obstacles_node := combat_map.get_node("Obstacles")
	var placed := 0
	var attempts := 0
	while placed < BLOCKER_COUNT and attempts < BLOCKER_COUNT * 5:
		attempts += 1
		var size := Vector2(
			randf_range(BLOCKER_MIN_SIZE.x, BLOCKER_MAX_SIZE.x),
			randf_range(BLOCKER_MIN_SIZE.y, BLOCKER_MAX_SIZE.y)
		)
		var pos := Vector2(
			randf_range(MARGIN + size.x, MAP_SIZE.x - MARGIN - size.x),
			randf_range(MARGIN + size.y, MAP_SIZE.y - MARGIN - size.y)
		)
		if pos.distance_to(MAP_SIZE / 2) < 120.0:
			continue
		var blocker := Area2D.new()
		blocker.set_script(VISION_BLOCKER_SCRIPT)
		blocker.position = pos
		obstacles_node.add_child(blocker)
		blocker.setup(size)
		placed += 1
	print("[MapGenerator] placed %d vision blockers" % placed)

func _spawn_enemies(combat_map: Node2D, depth: int) -> void:
	var enemies_node := combat_map.get_node("Enemies")
	var count := GameManager.get_enemy_count()
	var difficulty := GameManager.get_difficulty_multiplier()

	for i in count:
		var pos := Vector2(
			randf_range(MARGIN, MAP_SIZE.x - MARGIN),
			randf_range(MARGIN, MAP_SIZE.y - MARGIN)
		)
		# Don't spawn near center
		while pos.distance_to(MAP_SIZE / 2) < 150.0:
			pos = Vector2(
				randf_range(MARGIN, MAP_SIZE.x - MARGIN),
				randf_range(MARGIN, MAP_SIZE.y - MARGIN)
			)
		# Pick enemy type: 40% grunt, 25% brute, 25% trifurcator, 10% bomber
		var roll := randi() % 10
		var scene: PackedScene
		var data: EnemyData
		if roll < 4:
			scene = ENEMY_SCENE
			data = GRUNT_DATA
		elif roll < 6:
			scene = ENEMY_SCENE
			data = BRUTE_DATA
		elif roll < 9:
			scene = TRIFURCATOR_SCENE
			data = TRIFURCATOR_DATA
		else:
			scene = BOMBER_SCENE
			data = BOMBER_DATA
		var enemy := scene.instantiate()
		enemy.position = pos
		enemies_node.add_child(enemy)
		enemy.setup(data, difficulty)
