extends CharacterBody2D
## Player character — command queue, movement, physics.
## Input routing lives in PlayerInput; move indicator lives in MoveIndicator.

const SPEED := 200.0

# Instead of a state machine, the player executes commands from a queue.
# Each command's tick() returns true while running, false when done (auto-popped).
# DEAD and PLACING_BUILDING are modes that bypass the queue entirely.
var _dead: bool = false
var _placing_building: bool = false
var _command_queue: Array = []

# Idle auto-attack scan throttle.
var _idle_scan_timer: float = 0.0

var nearby_teleporter: Node = null
var _move_indicator = null  # MoveIndicator

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Polygon2D = $Sprite
@onready var combat: PlayerCombat = $PlayerCombat
@onready var building: PlayerBuilding = $PlayerBuilding
@onready var health_bar: Node2D = $HealthBar
@onready var input_handler = $PlayerInput  # PlayerInput

func _ready() -> void:
	nav_agent.max_speed = SPEED
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	combat.setup(self, sprite)
	building.setup(self)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.return_to_home.connect(_on_return_to_home)
	_move_indicator = preload("res://scenes/ui/move_indicator.gd").new()
	_move_indicator.setup(self)
	get_tree().current_scene.add_child.call_deferred(_move_indicator)
	input_handler.setup(self, combat, building)
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
		_move_indicator.hide_indicator()
		# Idle auto-attack: scan for nearby enemies and chase/attack them.
		_idle_scan_timer -= delta
		if _idle_scan_timer <= 0.0:
			_idle_scan_timer = 0.15
			var auto_target := combat.find_nearest_enemy_in_range(global_position, PlayerCombat.ATTACK_RANGE)
			if auto_target:
				print("[Player] idle: auto-attacking %s" % auto_target.name)
				_idle_scan_timer = 0.0
				_command_queue.append(MoveToRangeCommand.new(self, nav_agent, sprite, auto_target))
				_command_queue.append(AttackCommand.new(self, sprite, combat, auto_target, _command_queue, _make_move_to_range_cmd))
		return
	if not _command_queue[0].tick(delta):
		_command_queue.pop_front()


# ── Public command-queue API (called by PlayerInput) ──────────────────────────

func queue_move_to(pos: Vector2) -> void:
	_command_queue.clear()
	nav_agent.target_position = pos
	_command_queue.append(MoveToCommand.new(self, nav_agent, sprite))
	_move_indicator.show_at(pos, false)

func queue_attack(target: Node2D) -> void:
	_command_queue.clear()
	_move_indicator.hide_indicator()
	_command_queue.append(MoveToRangeCommand.new(self, nav_agent, sprite, target))
	_command_queue.append(AttackCommand.new(self, sprite, combat, target, _command_queue, _make_move_to_range_cmd))

func queue_attack_move(pos: Vector2) -> void:
	_command_queue.clear()
	_command_queue.append(AttackMoveCommand.new(self, nav_agent, sprite, combat, pos))
	_move_indicator.show_at(pos, true)

func queue_hold_position() -> void:
	_command_queue.clear()
	_move_indicator.hide_indicator()
	_command_queue.append(HoldPositionCommand.new(self, sprite, combat))


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

func _on_health_changed(current: float, max_hp: float) -> void:
	health_bar.update_bar(current, max_hp)

func _on_map_entered(_type: String, _depth: int) -> void:
	health_bar.visible = true
	health_bar.update_bar(health_component.current_hp, health_component.max_hp)
	_move_indicator.hide_indicator()

func _on_return_to_home() -> void:
	health_bar.visible = false
	_move_indicator.hide_indicator()

func _on_died() -> void:
	_dead = true
	_command_queue.clear()
	_move_indicator.hide_indicator()
	EventBus.player_died.emit()


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


class HoldPositionCommand:
	## Stand still. Attack enemies in range. Never chases — if target leaves range, drops it.
	## Never self-terminates; cancelled only by a new command clearing the queue.
	var _player: CharacterBody2D
	var _sprite: Polygon2D
	var _combat: PlayerCombat
	var _current_target: Node2D = null
	var _attack_timer: float = 0.0
	var _scan_timer: float = 0.0

	func _init(p: CharacterBody2D, spr: Polygon2D, cbt: PlayerCombat) -> void:
		_player = p
		_sprite = spr
		_combat = cbt

	func tick(delta: float) -> bool:
		_attack_timer = maxf(_attack_timer - delta, 0.0)
		_scan_timer = maxf(_scan_timer - delta, 0.0)
		_player.velocity = Vector2.ZERO
		_player.move_and_slide()

		# Drop target if dead or left range — do NOT chase
		if is_instance_valid(_current_target):
			var dist := _player.global_position.distance_to(_current_target.global_position)
			if dist > PlayerCombat.ATTACK_RANGE:
				_current_target = null

		# Periodically scan for a new target
		if not is_instance_valid(_current_target) and _scan_timer <= 0.0:
			_scan_timer = 0.15
			_current_target = _combat.find_nearest_enemy_in_range(_player.global_position, PlayerCombat.ATTACK_RANGE)
			if is_instance_valid(_current_target):
				_attack_timer = 0.0

		# Attack current target
		if is_instance_valid(_current_target):
			var dir := _player.global_position.direction_to(_current_target.global_position)
			if dir.length() > 0.1:
				_sprite.rotation = dir.angle() + PI / 2
			if _attack_timer <= 0.0:
				_combat.fire_at(_current_target)
				_attack_timer = PlayerCombat.ATTACK_COOLDOWN

		return true  # Never self-terminates
