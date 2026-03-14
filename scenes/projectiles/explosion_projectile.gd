extends Area2D
## Large projectile fired by Arcane Blast. Explodes on hitting an enemy or wall,
## or when it has traveled MAX_DISTANCE, damaging all enemies within EXPLOSION_RADIUS.

const MAX_DISTANCE := 500.0
const EXPLOSION_RADIUS := 100.0

var direction := Vector2.RIGHT
var speed := 300.0
var damage := 20.0

var _traveled := 0.0
var _exploded := false

func _ready() -> void:
	# Collision: on PlayerProj layer, detect Enemy (layer 3) and Terrain (layer 1)
	collision_layer = 8  # Layer 4 (PlayerProj)
	collision_mask = 5   # Layer 1 (Terrain) + Layer 3 (Enemy)
	# Collision shape for the projectile body
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	# Visual: bright orange circle
	var vis := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	vis.polygon = pts
	vis.color = Color(1.0, 0.55, 0.0, 1.0)
	add_child(vis)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _exploded:
		return
	var move := direction * speed * delta
	position += move
	_traveled += move.length()
	if _traveled >= MAX_DISTANCE:
		_explode()

func _on_body_entered(_body: Node2D) -> void:
	if not _exploded:
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	print("[ExplosionProjectile] exploding at %s radius=%d" % [
		str(global_position.snapped(Vector2.ONE)), int(EXPLOSION_RADIUS)
	])
	# Damage all enemies within explosion radius
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var blast_shape := CircleShape2D.new()
	blast_shape.radius = EXPLOSION_RADIUS
	query.shape = blast_shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 4  # Layer 3 (Enemy)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for r in space.intersect_shape(query):
		var body := r.collider as Node2D
		if is_instance_valid(body) and body.has_node("HealthComponent"):
			body.get_node("HealthComponent").take_damage(damage)
	_show_explosion_visual()
	await get_tree().create_timer(0.35).timeout
	queue_free()

func _show_explosion_visual() -> void:
	var circle := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		pts.append(Vector2(cos(a), sin(a)) * EXPLOSION_RADIUS)
	circle.polygon = pts
	circle.color = Color(1.0, 0.5, 0.0, 0.55)
	add_child(circle)
	# Inner bright flash
	var inner := Polygon2D.new()
	var ipts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		ipts.append(Vector2(cos(a), sin(a)) * EXPLOSION_RADIUS * 0.4)
	inner.polygon = ipts
	inner.color = Color(1.0, 1.0, 0.6, 0.8)
	add_child(inner)
	# Shrink and fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(circle, "scale", Vector2.ZERO, 0.3)
	tween.tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_property(inner, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(inner, "modulate:a", 0.0, 0.3)
