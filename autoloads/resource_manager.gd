extends Node
## Tracks player resources (crystals, metal, etc).

var _resources: Dictionary = {
	"crystal": 350,
	"metal": 330,
}

func get_amount(resource_name: String) -> int:
	return _resources.get(resource_name, 0)

func add_resource(resource_name: String, amount: int) -> void:
	if not _resources.has(resource_name):
		_resources[resource_name] = 0
	_resources[resource_name] += amount
	EventBus.resources_changed.emit(resource_name, _resources[resource_name])

func spend_resource(resource_name: String, amount: int) -> bool:
	if not can_afford(resource_name, amount):
		return false
	_resources[resource_name] -= amount
	EventBus.resources_changed.emit(resource_name, _resources[resource_name])
	return true

func can_afford(resource_name: String, amount: int) -> bool:
	return _resources.get(resource_name, 0) >= amount

func can_afford_dict(cost: Dictionary) -> bool:
	for key in cost:
		if not can_afford(key, cost[key]):
			return false
	return true

func spend_dict(cost: Dictionary) -> bool:
	if not can_afford_dict(cost):
		return false
	for key in cost:
		spend_resource(key, cost[key])
	return true

func get_all_resources() -> Dictionary:
	return _resources.duplicate()
