extends CanvasLayer
## Combat results screen with "Push Luck" / "Return Home" buttons.

@onready var panel: PanelContainer = $PanelContainer
@onready var rewards_label: Label = $PanelContainer/VBoxContainer/RewardsLabel
@onready var push_luck_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/PushLuckButton
@onready var return_home_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/ReturnHomeButton
@onready var depth_label: Label = $PanelContainer/VBoxContainer/DepthLabel

func _ready() -> void:
	EventBus.combat_results_shown.connect(_on_show_results)
	push_luck_btn.pressed.connect(_on_push_luck)
	return_home_btn.pressed.connect(_on_return_home)
	panel.visible = false

func _on_show_results(rewards: Dictionary) -> void:
	panel.visible = true
	depth_label.text = "Depth %d Cleared!" % GameManager.combat_depth
	var text := "Rewards:\n"
	for key in rewards:
		text += "  %s: +%d\n" % [key.capitalize(), rewards[key]]
	if rewards.is_empty():
		text += "  (none)\n"
	rewards_label.text = text

func _on_push_luck() -> void:
	panel.visible = false
	GameManager.push_luck()

func _on_return_home() -> void:
	panel.visible = false
	GameManager.collect_rewards()
	GameManager.return_home()
