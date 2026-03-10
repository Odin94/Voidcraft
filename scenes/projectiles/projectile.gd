extends Area2D
## Projectile that moves in a straight line and damages on contact.

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 15.0
var source := "player"  # "player" or "enemy"
var lifetime := 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Set collision based on source
	if source == "player":
		collision_layer = 8   # Layer 4 (PlayerProj)
		collision_mask = 4    # Layer 3 (Enemy)
	else:
		collision_layer = 16  # Layer 5 (EnemyProj)
		collision_mask = 2    # Layer 2 (Player)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").take_damage(damage)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		# HurtboxComponent handles damage via its own hitbox detection
		pass

func on_hit() -> void:
	queue_free()
