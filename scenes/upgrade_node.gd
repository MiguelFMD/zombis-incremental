class_name UpgradeNode
extends Button

signal node_clicked(upgrade_data: UpgradeData)

enum NodeState { HIDDEN, VISIBLE, AVAILABLE, UNLOCKED }

var data: UpgradeData
var current_state: NodeState = NodeState.HIDDEN




func _ready() -> void:
	pressed.connect(_on_pressed)
	GameManager.upgrades_updated.connect(_refresh_visual)
	_refresh_visual()


func setup(upgrade_data: UpgradeData) -> void:
	data = upgrade_data
	$Label_Name.text = data.upgrade_name
	$Label_Cost.text = str(data.cost)
	_refresh_visual()


func _on_pressed() -> void:
	if current_state == NodeState.HIDDEN:
		return
	node_clicked.emit(data)


func _refresh_visual() -> void:
	if not data:
		return

	if GameManager.unlocked_upgrades.has(data.id):
		current_state = NodeState.UNLOCKED
	elif GameManager.available_upgrades.has(data.id):
		current_state = NodeState.AVAILABLE
	elif GameManager.visible_upgrades.has(data.id):
		current_state = NodeState.VISIBLE
	else:
		current_state = NodeState.HIDDEN

	match current_state:
		NodeState.HIDDEN:
			visible = false
		NodeState.VISIBLE:
			visible = true
			$ColorRect_BG.color = Color(0.25, 0.25, 0.25, 1.0)
			disabled = true
		NodeState.AVAILABLE:
			visible = true
			$ColorRect_BG.color = Color(0.15, 0.35, 0.15, 1.0)
			disabled = false
		NodeState.UNLOCKED:
			visible = true
			$ColorRect_BG.color = Color(0.2, 0.5, 0.2, 1.0)
			disabled = true
