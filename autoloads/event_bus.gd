extends Node
## Global signal hub for decoupled communication between systems.

# Combat signals
signal enemy_killed(enemy: Node2D, position: Vector2)
signal player_died
signal projectile_fired(projectile: Node2D)

# Map signals
signal map_cleared
signal map_entered(map_type: String, depth: int)
signal return_to_home

# Building signals
signal building_placed(building: Node2D, grid_pos: Vector2i)
signal building_removed(grid_pos: Vector2i)

# Resource signals
signal resources_changed(resource_name: String, new_amount: int)

# UI signals
signal combat_results_shown(rewards: Dictionary)
signal build_menu_toggled(is_open: bool)

# Player signals
signal player_state_changed(new_state: int)

# Selection signals
signal entity_selected(entity: Node2D)
signal entity_deselected()
