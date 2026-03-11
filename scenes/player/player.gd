extends CharacterBody2D
## Player character — command queue, movement, input routing.
## Combat logic lives in PlayerCombat; building logic lives in PlayerBuilding.

const SPEED := 200.0

# Instead of a state machine, the player executes commands from a queue.
# Each command's tick() returns true while running, false when done (auto-popped).
# DEAD and PLACING_BUILDING are modes that bypass the queue entirely.
var _dead: bool = false
var _placing_building: bool = false
var _attack_move_mode: bool = false
var _command_queue: Array = []

var nearby_teleporter: Node = null
var _selected_entity: Node2D = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Polygon2D = $Sprite
@onready var combat: PlayerCombat = $PlayerCombat
@onready var building: PlayerBuilding = $PlayerBuilding
@onready var health_bar: Node2D = $HealthBar

func _ready() -> void:
	# Do NOT connect velocity_computed — movement is driven directly in commands.
	nav_agent.max_speed = SPEED
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	combat.setup(self, sprite)
	building.setup(self)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.return_to_home.connect(_on_return_to_home)
	EventBus.entity_selected.connect(_on_entity_selected)
	EventBus.entity_selected.emit(self)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _placing_building:
		building.process()
		return
	if _command_queue.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if not _command_queue[0].tick(delta):
		_command_queue.pop_front()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[Player] input: button=%d pos=%s dead=%s placing=%s atkmove=%s queue=%d" % [
			event.button_index,
			str(get_global_mouse_position().snapped(Vector2.ONE)),
			str(_dead), str(_placing_building), str(_attack_move_mode), _command_queue.size()
		])

	if _dead:
		return

	if _placing_building:
		if event.is_action_pressed("right_click") or event.is_action_pressed("left_click"):
			print("[Player] PLACING_BUILDING: confirm")
			building.confirm()
			_exit_placing()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cancel"):
			print("[Player] PLACING_BUILDING: cancel")
			building.cancel()
			_exit_placing()
			get_viewport().set_input_as_handled()
		return

	# Enter attack-move mouse state (only when player itself is selected)
	if event.is_action_pressed("attack_move") and _selected_entity == self:
		print("[Player] entering attack-move mode")
		_attack_move_mode = true
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		get_viewport().set_input_as_handled()
		return

	if is_instance_valid(_selected_entity) and _selected_entity != self:
		if event.is_action_pressed("cancel"):
			print("[Player] ESC with building selected — reselecting player")
			EventBus.entity_selected.emit(self)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("left_click"):
			print("[Player] left_click with building selected — reselecting player")
			_handle_left_click()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("right_click"):
			print("[Player] right_click forwarded to building: %s" % _selected_entity.name)
			_selected_entity.handle_input(event)
			get_viewport().set_input_as_handled()
		return

	# Attack-move mouse state: left-click issues command, right-click cancels
	if _attack_move_mode:
		if event.is_action_pressed("right_click"):
			print("[Player] attack-move mode: cancelled")
			_exit_attack_move_mode()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("left_click"):
			var click_pos := get_global_mouse_position()
			var enemy := combat.find_enemy_at(click_pos)
			if enemy:
				print("[Player] attack-move mode: left_click on enemy → regular attack on %s" % enemy.name)
				_command_queue.clear()
				_command_queue.append(MoveToRangeCommand.new(self, nav_agent, sprite, enemy))
				_command_queue.append(AttackCommand.new(self, sprite, combat, enemy, _command_queue, _make_move_to_range_cmd))
			else:
				print("[Player] attack-move → %s" % str(click_pos.snapped(Vector2.ONE)))
				_command_queue.clear()
				_command_queue.append(AttackMoveCommand.new(self, nav_agent, sprite, combat, click_pos))
			_exit_attack_move_mode()
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
	if nearby_teleporter and GameManager.current_state == GameManager.GameState.HOME:
		print("[Player] right_click → activating teleporter")
		nearby_teleporter.activate()
		return

	var click_pos := get_global_mouse_position()
	var enemy := combat.find_enemy_at(click_pos)
	if enemy:
		print("[Player] right_click → queuing attack on: %s" % enemy.name)
		_command_queue.clear()
		_command_queue.append(MoveToRangeCommand.new(self, nav_agent, sprite, enemy))
		_command_queue.append(AttackCommand.new(self, sprite, combat, enemy, _command_queue, _make_move_to_range_cmd))
	else:
		print("[Player] right_click → moving to %s" % str(click_pos.snapped(Vector2.ONE)))
		_command_queue.clear()
		nav_agent.target_position = click_pos
		_command_queue.append(MoveToCommand.new(self, nav_agent, sprite))

## Factory passed to AttackCommand so it can re-queue an approach without
## needing a direct reference to the MoveToRangeCommand inner class.
func _make_move_to_range_cmd(target: Node2D) -> Object:
	return MoveToRangeCommand.new(self, nav_agent, sprite, target)

func start_placing_building(data: BuildingData) -> void:
	print("[Player] entering PLACING_BUILDING for: %s" % data.display_name)
	_command_queue.clear()
	building.start_placing(data)
	_placing_building = true
	# building_menu.gd listens for value 3 = PLACING_BUILDING
	EventBus.player_state_changed.emit(3)

func face_direction(dir: Vector2) -> void:
	if dir.length() > 0.1:
		sprite.rotation = dir.angle() + PI / 2

func revive() -> void:
	health_component.reset()
	_dead = false

func _exit_placing() -> void:
	_placing_building = false
	EventBus.player_state_changed.emit(0)

func _exit_attack_move_mode() -> void:
	_attack_move_mode = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_health_changed(current: float, max_hp: float) -> void:
	health_bar.update_bar(current, max_hp)

func _on_map_entered(_type: String, _depth: int) -> void:
	health_bar.visible = true
	health_bar.update_bar(health_component.current_hp, health_component.max_hp)

func _on_return_to_home() -> void:
	health_bar.visible = false

func _on_died() -> void:
	_dead = true
	_command_queue.clear()
	if _attack_move_mode:
		_exit_attack_move_mode()
	EventBus.player_died.emit()

func _on_entity_selected(entity: Node2D) -> void:
	_selected_entity = entity
	print("[Player] Selection changed to: %s" % (entity.name if is_instance_valid(entity) else "none"))


# ── Commands ──────────────────────────────────────────────────────────────────

class MoveToCommand:
	## Navigate to a pre-set nav_agent.target_position. Done when nav finishes.
	var _player: CharacterBody2D
	var _nav_agent: NavigationAgent2D
	var _sprite: Polygon2D

	func _init(p: CharacterBody2D, nav: NavigationAgent2D, spr: Polygon2D) -> void:
		_player = p
		_nav_agent = nav
		_sprite = spr

	func tick(_delta: float) -> bool:
		if _nav_agent.is_navigation_finished():
			_player.velocity = Vector2.ZERO
			_player.move_and_slide()
			return false
		var next_pos := _nav_agent.get_next_path_position()
		var dir := _player.global_position.direction_to(next_pos)
		_player.velocity = dir * 200.0
		_player.move_and_slide()
		if dir.length() > 0.1:
			_sprite.rotation = dir.angle() + PI / 2
		return true


class MoveToRangeCommand:
	## Chase a target entity until within attack range. Done when in range or target gone.
	var _player: CharacterBody2D
	var _nav_agent: NavigationAgent2D
	var _sprite: Polygon2D
	var _target: Node2D

	func _init(p: CharacterBody2D, nav: NavigationAgent2D, spr: Polygon2D, target: Node2D) -> void:
		_player = p
		_nav_agent = nav
		_sprite = spr
		_target = target

	func tick(_delta: float) -> bool:
		if not is_instance_valid(_target):
			return false
		var dist := _player.global_position.distance_to(_target.global_position)
		if dist <= PlayerCombat.ATTACK_RANGE:
			_player.velocity = Vector2.ZERO
			_player.move_and_slide()
			return false
		_nav_agent.target_position = _target.global_position
		var next_pos := _nav_agent.get_next_path_position()
		var dir := _player.global_position.direction_to(next_pos)
		_player.velocity = dir * 200.0
		_player.move_and_slide()
		if dir.length() > 0.1:
			_sprite.rotation = dir.angle() + PI / 2
		return true


class AttackCommand:
	## Stand still and attack target while in range.
	## If target walks out of range, inserts a fresh MoveToRangeCommand at front of queue.
	## Done only when target is dead/gone.
	var _player: CharacterBody2D
	var _sprite: Polygon2D
	var _combat: PlayerCombat
	var _target: Node2D
	var _queue: Array
	var _make_move_fn: Callable  # _player._make_move_to_range_cmd
	var _attack_timer: float = 0.0

	func _init(p: CharacterBody2D, spr: Polygon2D, cbt: PlayerCombat,
			target: Node2D, queue: Array, make_move_fn: Callable) -> void:
		_player = p
		_sprite = spr
		_combat = cbt
		_target = target
		_queue = queue
		_make_move_fn = make_move_fn

	func tick(delta: float) -> bool:
		_attack_timer = maxf(_attack_timer - delta, 0.0)

		if not is_instance_valid(_target):
			return false

		var dist := _player.global_position.distance_to(_target.global_position)
		if dist > PlayerCombat.ATTACK_RANGE:
			# Insert a fresh approach command in front of self (self shifts to index 1).
			# MoveToRangeCommand runs next frame; when it pops, self is front again.
			_queue.insert(0, _make_move_fn.call(_target))
			return true

		_player.velocity = Vector2.ZERO
		_player.move_and_slide()
		var dir := _player.global_position.direction_to(_target.global_position)
		if dir.length() > 0.1:
			_sprite.rotation = dir.angle() + PI / 2
		if _attack_timer <= 0.0:
			_combat.fire_at(_target)
			_attack_timer = PlayerCombat.ATTACK_COOLDOWN
		return true


class AttackMoveCommand:
	## Move toward destination; auto-attack any enemy that enters attack range.
	## When an engaged enemy dies or leaves range, resume moving to destination.
	var _player: CharacterBody2D
	var _nav_agent: NavigationAgent2D
	var _sprite: Polygon2D
	var _combat: PlayerCombat
	var _destination: Vector2
	var _current_target: Node2D = null
	var _attack_timer: float = 0.0

	func _init(p: CharacterBody2D, nav: NavigationAgent2D, spr: Polygon2D,
			cbt: PlayerCombat, dest: Vector2) -> void:
		_player = p
		_nav_agent = nav
		_sprite = spr
		_combat = cbt
		_destination = dest
		_nav_agent.target_position = dest

	func tick(delta: float) -> bool:
		_attack_timer = maxf(_attack_timer - delta, 0.0)

		# If we have a live target, stand and attack it
		if is_instance_valid(_current_target):
			var dist := _player.global_position.distance_to(_current_target.global_position)
			if dist > PlayerCombat.ATTACK_RANGE:
				# Enemy left range — clear target and resume moving to destination
				print("[AttackMove] target left range — resuming move")
				_current_target = null
				_nav_agent.target_position = _destination
			else:
				_player.velocity = Vector2.ZERO
				_player.move_and_slide()
				var dir := _player.global_position.direction_to(_current_target.global_position)
				if dir.length() > 0.1:
					_sprite.rotation = dir.angle() + PI / 2
				if _attack_timer <= 0.0:
					_combat.fire_at(_current_target)
					_attack_timer = PlayerCombat.ATTACK_COOLDOWN
				return true

		# No valid target — scan for nearest enemy in attack range
		_current_target = null
		var nearest := _combat.find_nearest_enemy_in_range(_player.global_position, PlayerCombat.ATTACK_RANGE)
		if nearest:
			print("[AttackMove] acquired target: %s" % nearest.name)
			_current_target = nearest
			_attack_timer = 0.0
			return true

		# No enemies nearby — continue toward destination
		if _nav_agent.is_navigation_finished():
			_player.velocity = Vector2.ZERO
			_player.move_and_slide()
			return false
		var next_pos := _nav_agent.get_next_path_position()
		var dir := _player.global_position.direction_to(next_pos)
		_player.velocity = dir * 200.0
		_player.move_and_slide()
		if dir.length() > 0.1:
			_sprite.rotation = dir.angle() + PI / 2
		return true
