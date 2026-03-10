extends Node
## Generates procedural obstacles and enemies for combat maps.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy_base.tscn")
const GRUNT_DATA := preload("res://resources/enemies/grunt.tres")
const BRUTE_DATA := preload("res://resources/enemies/brute.tres")

const MAP_SIZE := Vector2(1280, 720)
const MARGIN := 80.0
const OBSTACLE_MIN_SIZE := Vector2(32, 32)
const OBSTACLE_MAX_SIZE := Vector2(128, 128)

func generate_map(combat_map: Node2D, depth: int) -> void:
	_generate_obstacles(combat_map, depth)
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

func _spawn_enemies(combat_map: Node2D, depth: int) -> void:
	var enemies_node := combat_map.get_node("Enemies")
	var count := GameManager.get_enemy_count()
	var difficulty := GameManager.get_difficulty_multiplier()

	for i in count:
		var enemy := ENEMY_SCENE.instantiate()
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
		enemy.position = pos
		enemies_node.add_child(enemy)
		# Use brute for every 3rd enemy
		var data: EnemyData = BRUTE_DATA if (i % 3 == 2) else GRUNT_DATA
		enemy.setup(data, difficulty)
