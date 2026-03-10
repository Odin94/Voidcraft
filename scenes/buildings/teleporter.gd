extends Area2D
## Teleporter that triggers map travel when the player right-clicks while overlapping.
## Pushes a reference to itself onto the player so the player's input handler
## can give teleportation priority over movement.

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 64  # Layer 7 (Interactable)
	collision_mask = 2    # Layer 2 (Player)

func activate() -> void:
	if GameManager.current_state == GameManager.GameState.HOME:
		GameManager.enter_combat()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_teleporter = self

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.nearby_teleporter == self:
		body.nearby_teleporter = null
