class_name PlayerInput
extends Node
## Routes mouse/keyboard input to player commands and selection events.
## Owns attack-move mode and selected-entity tracking for input routing.

var _player: CharacterBody2D
var _combat: PlayerCombat
var _building: PlayerBuilding

var _selected_entity: Node2D = null
var _attack_move_mode: bool = false

func setup(player: CharacterBody2D, cbt: PlayerCombat, bld: PlayerBuilding) -> void:
	_player = player
	_combat = cbt
	_building = bld
	EventBus.entity_selected.connect(_on_entity_selected)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[Player] input: button=%d pos=%s dead=%s placing=%s atkmove=%s queue=%d" % [
			event.button_index,
			str(_player.get_global_mouse_position().snapped(Vector2.ONE)),
			str(_player._dead), str(_player._placing_building), str(_attack_move_mode),
			_player._command_queue.size()
		])

	if _player._dead:
		return

	if _player._placing_building:
		if event.is_action_pressed("right_click") or event.is_action_pressed("left_click"):
			print("[Player] PLACING_BUILDING: confirm")
			_building.confirm()
			_player._exit_placing()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cancel"):
			print("[Player] PLACING_BUILDING: cancel")
			_building.cancel()
			_player._exit_placing()
			get_viewport().set_input_as_handled()
		return

	# Enter attack-move mouse state (only when player itself is selected)
	if event.is_action_pressed("attack_move") and _selected_entity == _player:
		print("[Player] entering attack-move mode")
		_attack_move_mode = true
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		get_viewport().set_input_as_handled()
		return

	# Hold position command (only when player is selected)
	if event.is_action_pressed("hold_position") and _selected_entity == _player:
		print("[Player] hold position")
		_player.queue_hold_position()
		get_viewport().set_input_as_handled()
		return

	if is_instance_valid(_selected_entity) and _selected_entity != _player:
		if event.is_action_pressed("cancel"):
			print("[Player] ESC with building selected — reselecting player")
			EventBus.entity_selected.emit(_player)
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
			var click_pos := _player.get_global_mouse_position()
			var enemy := _combat.find_enemy_at(click_pos)
			if enemy:
				print("[Player] attack-move mode: left_click on enemy → regular attack on %s" % enemy.name)
				_player.queue_attack(enemy)
			else:
				print("[Player] attack-move → %s" % str(click_pos.snapped(Vector2.ONE)))
				_player.queue_attack_move(click_pos)
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
	var click_pos := _player.get_global_mouse_position()
	var hit_building := _find_building_at(click_pos)
	if hit_building:
		print("[Player] left_click → selecting building: %s" % hit_building.name)
		EventBus.entity_selected.emit(hit_building)
	else:
		print("[Player] left_click on empty space — reselecting player")
		EventBus.entity_selected.emit(_player)

func _find_building_at(pos: Vector2) -> Node2D:
	var space := _player.get_world_2d().direct_space_state
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
	if _player.nearby_teleporter and GameManager.current_state == GameManager.GameState.HOME:
		print("[Player] right_click → activating teleporter")
		_player.nearby_teleporter.activate()
		return

	var click_pos := _player.get_global_mouse_position()
	var enemy := _combat.find_enemy_at(click_pos)
	if enemy:
		print("[Player] right_click → queuing attack on: %s" % enemy.name)
		_player.queue_attack(enemy)
	else:
		print("[Player] right_click → moving to %s" % str(click_pos.snapped(Vector2.ONE)))
		_player.queue_move_to(click_pos)

func _exit_attack_move_mode() -> void:
	_attack_move_mode = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_entity_selected(entity: Node2D) -> void:
	_selected_entity = entity
	print("[Player] Selection changed to: %s" % (entity.name if is_instance_valid(entity) else "none"))
