class_name BuildingData
extends Resource
## Data definition for a building type.

@export var display_name: String = "Building"
@export var cost: Dictionary = { "crystal": 20 }
@export var size: Vector2i = Vector2i(2, 2)
@export var max_level: int = 3
@export var color: Color = Color.STEEL_BLUE
@export var description: String = ""
