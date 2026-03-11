extends CharacterBody2D
## Base enemy with aggro detection, navigation, and melee attack.

enum State { IDLE, CHASING, ATTACKING, RETURNING }

const MAP_BOUNDS := Rect2(0, 0, 1280, 720)
const OUT_OF_BOUNDS_KILL_TIME := 10.0

var state: State = State.IDLE
var enemy_data: EnemyData
var target: Node2D = null
var attack_timer: float = 0.0
var out_of_bounds_timer: float = 0.0
var spawn_position: Vector2

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var aggro_area: Area2D = $AggroArea
@onready var sprite: Polygon2D = $Sprite
@onready var health_bar: Node2D = $HealthBar

func _ready() -> void:
	spawn_position = global_position
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	aggro_area.body_entered.connect(_on_aggro_body_entered)
	aggro_area.body_exited.connect(_on_aggro_body_exited)

func setup(data: EnemyData, difficulty_mult: float = 1.0) -> void:
	enemy_data = data
	health_component.max_hp = data.hp * difficulty_mult
	health_component.current_hp = health_component.max_hp
	nav_agent.max_speed = data.speed
	sprite.color = data.color
	# Set aggro range
	var aggro_shape := aggro_area.get_node("CollisionShape2D") as CollisionShape2D
	if aggro_shape and aggro_shape.shape is CircleShape2D:
		(aggro_shape.shape as CircleShape2D).radius = data.aggro_range

func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		State.CHASING:
			_handle_chasing()
		State.ATTACKING:
			_handle_attacking(delta)
		State.RETURNING:
			_handle_returning()

	_check_bounds(delta)

func _handle_chasing() -> void:
	if not is_instance_valid(target):
		target = null
		state = State.RETURNING
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= enemy_data.attack_range:
		state = State.ATTACKING
		return
	nav_agent.target_position = target.global_position
	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	nav_agent.velocity = direction * enemy_data.speed
	sprite.rotation = direction.angle() + PI / 2

func _handle_attacking(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		state = State.RETURNING
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > enemy_data.attack_range * 1.2:
		state = State.CHASING
		return
	velocity = Vector2.ZERO
	move_and_slide()
	sprite.rotation = global_position.direction_to(target.global_position).angle() + PI / 2
	if attack_timer <= 0.0:
		_deal_damage()
		attack_timer = enemy_data.attack_cooldown

func _handle_returning() -> void:
	if global_position.distance_to(spawn_position) < 8.0:
		global_position = spawn_position
		velocity = Vector2.ZERO
		move_and_slide()
		state = State.IDLE
		return
	nav_agent.target_position = spawn_position
	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	nav_agent.velocity = direction * enemy_data.speed
	sprite.rotation = direction.angle() + PI / 2

func _check_bounds(delta: float) -> void:
	if not MAP_BOUNDS.has_point(global_position):
		out_of_bounds_timer += delta
		if out_of_bounds_timer >= OUT_OF_BOUNDS_KILL_TIME:
			push_warning("Enemy killed for being out of bounds for %.1fs" % OUT_OF_BOUNDS_KILL_TIME)
			health_component.take_damage(health_component.max_hp)
			return
		# Clamp back into bounds each frame so movement can't drift further out
		global_position = global_position.clamp(MAP_BOUNDS.position, MAP_BOUNDS.end)
	else:
		out_of_bounds_timer = 0.0

func _deal_damage() -> void:
	if is_instance_valid(target) and target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(enemy_data.damage)

func _on_aggro_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state in [State.IDLE, State.RETURNING]:
		target = body
		state = State.CHASING

func _on_aggro_body_exited(body: Node2D) -> void:
	if body == target and state == State.CHASING:
		target = null
		state = State.RETURNING

func _on_health_changed(current: float, max_hp: float) -> void:
	if health_bar:
		health_bar.update_bar(current, max_hp)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_died() -> void:
	EventBus.enemy_killed.emit(self, global_position)
	var rewards := {}
	if enemy_data:
		for key in enemy_data.rewards:
			rewards[key] = int(enemy_data.rewards[key] * GameManager.get_reward_multiplier())
	GameManager.add_pending_rewards(rewards)
	queue_free()
