extends CharacterBody2D
## Player character — state machine, movement, input routing.
## Combat logic lives in PlayerCombat; building logic lives in PlayerBuilding.

enum State { IDLE, MOVING, ATTACKING, PLACING_BUILDING, DEAD }

const SPEED := 200.0

var state: State = State.IDLE
var nearby_teleporter: Node = null  # Set by Teleporter when player overlaps it
var _selected_entity: Node2D = null  # Tracks current selection for input routing

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
	EventBus.entity_selected.connect(_on_entity_selected)
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
	if event is InputEventMouseButton and event.pressed:
		print("[Player] _unhandled_input received: button=%d at %s (state=%s, selected=%s)" % [
			event.button_index,
			str(get_global_mouse_position().snapped(Vector2.ONE)),
			State.keys()[state],
			_selected_entity.name if is_instance_valid(_selected_entity) else "none"
		])

	if state == State.DEAD:
		return

	if state == State.PLACING_BUILDING:
		if event.is_action_pressed("right_click") or event.is_action_pressed("left_click"):
			print("[Player] PLACING_BUILDING: confirm input received")
			building.confirm()
			_set_state(State.IDLE)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cancel"):
			print("[Player] PLACING_BUILDING: cancel input received")
			building.cancel()
			_set_state(State.IDLE)
			get_viewport().set_input_as_handled()
		return

	# When a building is selected, route input to it instead of the player.
	if is_instance_valid(_selected_entity) and _selected_entity != self:
		if event.is_action_pressed("cancel"):
			print("[Player] ESC with building selected — reselecting player")
			EventBus.entity_selected.emit(self)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("left_click"):
			# Building _input_event fires before _unhandled_input, so if we reach here
			# the click was on empty space or the player — reselect the player.
			print("[Player] left_click with building selected, no building hit — reselecting player")
			_handle_left_click()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("right_click"):
			print("[Player] right_click forwarded to building: %s" % _selected_entity.name)
			_selected_entity.handle_input(event)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("left_click"):
		_handle_left_click()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("right_click"):
		_handle_right_click()
		get_viewport().set_input_as_handled()


func _handle_left_click() -> void:
	var click_pos := get_global_mouse_position()
	var hit_building := _find_building_at(click_pos)
	if hit_building:
		print("[Player] left_click → selecting building: %s" % hit_building.name)
		EventBus.entity_selected.emit(hit_building)
	else:
		print("[Player] left_click on empty space — reselecting player")
		EventBus.entity_selected.emit(self)

func _find_building_at(pos: Vector2) -> Node2D:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 32  # Layer 6 (Building)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var results := space.intersect_point(query, 1)
	if results.size() > 0:
		return results[0].collider as Node2D
	return null

func _handle_right_click() -> void:
	# Teleporter takes priority over movement
	if nearby_teleporter and GameManager.current_state == GameManager.GameState.HOME:
		print("[Player] right_click → activating teleporter")
		nearby_teleporter.activate()
		return

	var click_pos := get_global_mouse_position()
	var enemy := combat.find_enemy_at(click_pos)
	if enemy:
		print("[Player] right_click → attacking enemy: %s" % enemy.name)
		combat.set_target(enemy)
		_set_state(State.ATTACKING)
	else:
		print("[Player] right_click → moving to %s" % str(click_pos.snapped(Vector2.ONE)))
		combat.clear_target()
		nav_agent.target_position = click_pos
		_set_state(State.MOVING)

func start_placing_building(data: BuildingData) -> void:
	print("[Player] entering PLACING_BUILDING for: %s" % data.display_name)
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

func _on_entity_selected(entity: Node2D) -> void:
	_selected_entity = entity
	print("[Player] Selection changed to: %s" % (entity.name if is_instance_valid(entity) else "none"))

func _set_state(new_state: State) -> void:
	print("[Player] state: %s → %s" % [State.keys()[state], State.keys()[new_state]])
	state = new_state
	EventBus.player_state_changed.emit(new_state)
