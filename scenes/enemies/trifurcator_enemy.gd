extends "res://scenes/enemies/enemy_base.gd"
## Ranged enemy that charges up a telegraphed trifurcated spread shot.
## Stops at range, shows three glowing aim lines, then fires all three at once.

const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")
const CHARGE_TIME := 1.5
const SPREAD_ANGLE := deg_to_rad(28.0)
const NUM_SHOTS := 3
const INDICATOR_LENGTH := 280.0

var _charge_timer: float = 0.0
var _is_charging: bool = false
var _indicators: Array = []

func _handle_attacking(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		state = State.RETURNING
		_clear_indicators()
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > enemy_data.attack_range * 1.2:
		_clear_indicators()
		_is_charging = false
		state = State.CHASING
		return
	velocity = Vector2.ZERO
	move_and_slide()
	var dir := global_position.direction_to(target.global_position)
	sprite.rotation = dir.angle() + PI / 2
	# During cooldown after firing, just wait
	if attack_timer > 0.0:
		_clear_indicators()
		return
	if not _is_charging:
		_is_charging = true
		_charge_timer = CHARGE_TIME
		_create_indicators(dir)
		print("[Trifurcator] charging shot")
	else:
		_charge_timer -= delta
		_update_indicators(dir)
		if _charge_timer <= 0.0:
			_fire(dir)
			_clear_indicators()
			_is_charging = false
			attack_timer = enemy_data.attack_cooldown

func _create_indicators(dir: Vector2) -> void:
	_clear_indicators()
	for i in NUM_SHOTS:
		var offset := (i - (NUM_SHOTS - 1) / 2.0) * SPREAD_ANGLE
		var shot_dir := dir.rotated(offset)
		var line := Line2D.new()
		line.width = 2.5
		line.default_color = Color(0.9, 0.3, 1.0, 0.2)
		line.add_point(Vector2.ZERO)
		line.add_point(shot_dir * INDICATOR_LENGTH)
		add_child(line)
		_indicators.append(line)

func _update_indicators(dir: Vector2) -> void:
	var progress := 1.0 - (_charge_timer / CHARGE_TIME)
	for i in _indicators.size():
		if not is_instance_valid(_indicators[i]):
			continue
		var offset := (i - (NUM_SHOTS - 1) / 2.0) * SPREAD_ANGLE
		var shot_dir := dir.rotated(offset)
		_indicators[i].set_point_position(1, shot_dir * INDICATOR_LENGTH)
		_indicators[i].default_color = Color(0.9, 0.3 + progress * 0.7, 1.0, 0.18 + progress * 0.32)
		_indicators[i].width = 2.0 + progress * 1.5

func _clear_indicators() -> void:
	for line in _indicators:
		if is_instance_valid(line):
			line.queue_free()
	_indicators.clear()

func _fire(dir: Vector2) -> void:
	print("[Trifurcator] firing spread at %s" % str(target.global_position.snapped(Vector2.ONE)))
	for i in NUM_SHOTS:
		var offset := (i - (NUM_SHOTS - 1) / 2.0) * SPREAD_ANGLE
		var shot_dir := dir.rotated(offset)
		var proj := PROJECTILE_SCENE.instantiate()
		proj.direction = shot_dir
		proj.speed = 320.0
		proj.damage = enemy_data.damage
		proj.source = "enemy"
		proj.position = global_position + shot_dir * 22.0
		get_tree().current_scene.add_child(proj)

func _on_died() -> void:
	_clear_indicators()
	super._on_died()
