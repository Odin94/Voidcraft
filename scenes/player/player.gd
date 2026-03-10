extends CharacterBody2D
## Player character — state machine, movement, input routing.
## Combat logic lives in PlayerCombat; building logic lives in PlayerBuilding.

enum State { IDLE, MOVING, ATTACKING, PLACING_BUILDING, DEAD }

const SPEED := 200.0

var state: State = State.IDLE
var nearby_teleporter: Node = null  # Set by Teleporter when player overlaps it

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Polygon2D = $Sprite
@onready var combat: PlayerCombat = $PlayerCombat
@onready var building: PlayerBuilding = $PlayerBuilding
@onready var health_bar: Node2D = $HealthBar

func _ready() -> void:
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	nav_agent.max_speed = SPEED
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	combat.setup(self, nav_agent, sprite)
	building.setup(self)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.return_to_home.connect(_on_return_to_home)
	# Player is the default selection
	EventBus.entity_selected.emit(self)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		State.MOVING:
			_handle_moving()
		State.ATTACKING:
			if not combat.process(delta):
				_set_state(State.IDLE)
		State.PLACING_BUILDING:
			building.process()
		State.DEAD:
			pass

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD:
		return

	if state == State.PLACING_BUILDING:
		if event.is_action_pressed("right_click") or event.is_action_pressed("left_click"):
			building.confirm()
			_set_state(State.IDLE)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cancel"):
			building.cancel()
			_set_state(State.IDLE)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("left_click"):
		_handle_left_click()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("right_click"):
		_handle_right_click()
		get_viewport().set_input_as_handled()


func _handle_left_click() -> void:
	# Buildings fire _input_event and mark handled before this runs.
	# If we reach here the click was on empty space — re-select the player.
	EventBus.entity_selected.emit(self)

func _handle_right_click() -> void:
	# Teleporter takes priority over movement
	if nearby_teleporter and GameManager.current_state == GameManager.GameState.HOME:
		nearby_teleporter.activate()
		return

	var click_pos := get_global_mouse_position()
	var enemy := combat.find_enemy_at(click_pos)
	if enemy:
		combat.set_target(enemy)
		_set_state(State.ATTACKING)
	else:
		combat.clear_target()
		nav_agent.target_position = click_pos
		_set_state(State.MOVING)

func start_placing_building(data: BuildingData) -> void:
	building.start_placing(data)
	_set_state(State.PLACING_BUILDING)

func face_direction(dir: Vector2) -> void:
	if dir.length() > 0.1:
		sprite.rotation = dir.angle() + PI / 2

func revive() -> void:
	health_component.reset()
	_set_state(State.IDLE)

func _handle_moving() -> void:
	if nav_agent.is_navigation_finished():
		_set_state(State.IDLE)
		return
	var next_pos := nav_agent.get_next_path_position()
	var dir := global_position.direction_to(next_pos)
	nav_agent.velocity = dir * SPEED
	face_direction(dir)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_health_changed(current: float, max_hp: float) -> void:
	health_bar.update_bar(current, max_hp)

func _on_map_entered(_type: String, _depth: int) -> void:
	health_bar.visible = true
	health_bar.update_bar(health_component.current_hp, health_component.max_hp)

func _on_return_to_home() -> void:
	health_bar.visible = false

func _on_died() -> void:
	_set_state(State.DEAD)
	EventBus.player_died.emit()

func _set_state(new_state: State) -> void:
	state = new_state
	EventBus.player_state_changed.emit(new_state)
