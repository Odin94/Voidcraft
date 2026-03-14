extends Node
## Autoload: manages the player skill tree — definitions, current picks,
## skill instance lifecycle, and cooldown ticking.
##
## To swap an ability in the tree, just change the path strings in SKILL_TREE.
## Skills are loaded lazily at runtime (after class_name scanning completes).

# Preloading skill_base.gd registers the SkillBase class_name globally so that
# hud.gd and other scene scripts can use it as a type annotation.
const _SKILL_BASE = preload("res://scenes/skills/skill_base.gd")

# ── Tree definition ────────────────────────────────────────────────────────────
# Maps skill-tree depth level → [path_option_A, path_option_B]
# Swap abilities by changing the path strings here.
const SKILL_TREE: Dictionary = {
	1: [
		"res://scenes/skills/passive_damage_ignore.gd",  # A: Iron Will
		"res://scenes/skills/active_teleport.gd",         # B: Blink
	],
	2: [
		"res://scenes/skills/passive_double_damage.gd",   # A: Deadly Strike
		"res://scenes/skills/active_explosion_shot.gd",   # B: Arcane Blast
	],
}

var _player: Node = null
var _picks: Dictionary = {}           # level(int) → option_index(int), -1 = no pick yet
var _skill_instances: Dictionary = {} # level(int) → live skill instance
var _unlocked_levels: int = 0

func setup(player: Node) -> void:
	_player = player
	for level in SKILL_TREE:
		_picks[level] = -1
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	# Level 1 is always available from the start
	_unlock_level(1)
	print("[SkillTree] setup complete")

func _process(delta: float) -> void:
	# Tick active skill cooldowns
	for level in _skill_instances:
		var skill = _skill_instances[level]
		if skill != null and skill.has_method("tick"):
			skill.tick(delta)

# ── Public API ─────────────────────────────────────────────────────────────────

func is_level_unlocked(level: int) -> bool:
	return level <= _unlocked_levels

func get_current_pick(level: int) -> int:
	return _picks.get(level, -1)

## Returns a fresh temporary skill instance for display/info (not applied to player).
func get_skill_info(level: int, option: int) -> Object:
	return load(SKILL_TREE[level][option]).new()

## Returns the live instance of a currently-equipped skill, or null.
func get_active_instance(level: int) -> Object:
	return _skill_instances.get(level, null)

## Choose or swap the ability at the given skill-tree level.
func set_pick(level: int, option: int) -> void:
	if not is_level_unlocked(level):
		push_warning("SkillTree: level %d not unlocked" % level)
		return
	if option < 0 or option >= SKILL_TREE[level].size():
		return
	if _picks.get(level, -1) == option:
		return  # Already selected
	# Remove old skill
	var old_pick: int = _picks.get(level, -1)
	if old_pick >= 0 and _skill_instances.has(level):
		_skill_instances[level].remove_from_player(_player)
		_skill_instances.erase(level)
	# Create, store, and apply new skill
	_picks[level] = option
	var new_skill = load(SKILL_TREE[level][option]).new()
	_skill_instances[level] = new_skill
	new_skill.apply_to_player(_player)
	print("[SkillTree] level %d → option %d (%s)" % [level, option, new_skill.display_name])
	EventBus.skill_changed.emit(level, option)

## Re-applies all currently-equipped skills (e.g., after player revive/respawn).
func reapply_all() -> void:
	for level in _picks:
		var pick: int = _picks[level]
		if pick >= 0 and _skill_instances.has(level):
			_skill_instances[level].apply_to_player(_player)

## Returns live instances of non-passive (active) skills, sorted by level (ascending).
func get_active_skills() -> Array:
	var result: Array = []
	var levels: Array = _skill_instances.keys()
	levels.sort()
	for level in levels:
		var skill = _skill_instances[level]
		if skill != null and not skill.is_passive:
			result.append(skill)
	return result

## True if there is at least one unlocked level with no ability chosen yet.
func has_unpicked_levels() -> bool:
	for level in _picks:
		if is_level_unlocked(level) and _picks[level] < 0:
			return true
	return false

# ── Internal ───────────────────────────────────────────────────────────────────

func _unlock_level(level: int) -> void:
	if _unlocked_levels < level:
		_unlocked_levels = level
		print("[SkillTree] level %d unlocked" % level)
		EventBus.skill_level_unlocked.emit(level)

func _on_player_leveled_up(new_level: int) -> void:
	if new_level in SKILL_TREE:
		_unlock_level(new_level)
