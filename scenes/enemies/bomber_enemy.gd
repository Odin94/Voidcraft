extends "res://scenes/enemies/enemy_base.gd"
## Melee suicide bomber. Sprints into range, flashes a warning pulse, then
## explodes — dealing large AoE damage to the player and killing itself.

const EXPLOSION_RADIUS := 90.0
const FUSE_TIME := 0.8
const PULSE_SPEED := 8.0

var _fuse_timer: float = 0.0
var _is_fusing: bool = false
var _base_color: Color

func setup(data: EnemyData, difficulty_mult: float = 1.0) -> void:
	super.setup(data, difficulty_mult)
	_base_color = data.color

func _handle_attacking(delta: float) -> void:
	# Once fuse is lit the bomber is committed — it charges straight at the player
	# ignoring nav avoidance so nothing can stop the explosion.
	if _is_fusing:
		_fuse_timer -= delta
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := (sin(t * PULSE_SPEED) + 1.0) * 0.5
		sprite.color = _base_color.lerp(Color.WHITE, pulse * 0.85)
		if is_instance_valid(target):
			var dir := global_position.direction_to(target.global_position)
			velocity = dir * enemy_data.speed
			move_and_slide()
			sprite.rotation = dir.angle() + PI / 2
		if _fuse_timer <= 0.0:
			_explode()
		return

	if not is_instance_valid(target):
		target = null
		state = State.RETURNING
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > enemy_data.attack_range * 1.2:
		state = State.CHASING
		return
	# In range — light the fuse
	velocity = Vector2.ZERO
	move_and_slide()
	_is_fusing = true
	_fuse_timer = FUSE_TIME
	print("[Bomber] fuse lit!")

func _explode() -> void:
	print("[Bomber] exploding at %s" % str(global_position.snapped(Vector2.ONE)))
	_show_explosion_visual()
	# Damage player(s) in blast radius
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var blast := CircleShape2D.new()
	blast.radius = EXPLOSION_RADIUS
	query.shape = blast
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 2  # Layer 2: Player
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for r in space.intersect_shape(query):
		var body := r.collider as Node2D
		if is_instance_valid(body) and body.has_node("HealthComponent"):
			body.get_node("HealthComponent").take_damage(enemy_data.damage)
	# Detonate self
	health_component.take_damage(health_component.max_hp)

func _show_explosion_visual() -> void:
	var parent := get_parent()
	# Outer blast ring
	var circle := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		pts.append(Vector2(cos(a), sin(a)) * EXPLOSION_RADIUS)
	circle.polygon = pts
	circle.color = Color(1.0, 0.6, 0.1, 0.7)
	parent.add_child(circle)
	circle.global_position = global_position
	# Inner flash
	var inner := Polygon2D.new()
	var ipts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		ipts.append(Vector2(cos(a), sin(a)) * EXPLOSION_RADIUS * 0.45)
	inner.polygon = ipts
	inner.color = Color(1.0, 1.0, 0.6, 0.9)
	parent.add_child(inner)
	inner.global_position = global_position
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(circle, "scale", Vector2(1.3, 1.3), 0.3)
	tween.tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_property(inner, "scale", Vector2(1.8, 1.8), 0.3)
	tween.tween_property(inner, "modulate:a", 0.0, 0.3)
