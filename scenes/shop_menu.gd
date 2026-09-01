extends Control

@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var graph_root: Node2D = $SubViewportContainer/SubViewport/GraphRoot
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
@onready var details_popup: Panel = $DetailsPopup
@onready var label_upgrade_name: Label = $DetailsPopup/Label_Name
@onready var label_description: Label = $DetailsPopup/Label_Description
@onready var label_cost: Label = $DetailsPopup/Label_Cost
@onready var button_buy: Button = $DetailsPopup/Button_Buy
@onready var button_close_shop: Button = $Button_Close

var upgrade_node_scene: PackedScene = preload("res://scenes/upgrade_node.tscn")
var is_panning: bool = false
var pan_start: Vector2 = Vector2.ZERO
var camera_start: Vector2 = Vector2.ZERO
var selected_upgrade_id: String = ""


func _ready() -> void:
	hide()
	details_popup.hide()
	button_buy.pressed.connect(_on_buy_pressed)
	button_close_shop.pressed.connect(_on_close_pressed)
	GameManager.upgrades_updated.connect(_refresh_lines)
	_generate_graph()


func _generate_graph() -> void:
	for child: Node in graph_root.get_children():
		child.queue_free()

	var layout: Dictionary = _generate_layout()
	var node_map: Dictionary = {}

	var all_ids: Array[String] = _collect_all_upgrade_ids()
	for id: String in all_ids:
		if not layout.has(id):
			continue
		var pos: Vector2 = layout[id]
		var data: UpgradeData = _load_upgrade(id)
		if not data:
			continue

		var node: UpgradeNode = upgrade_node_scene.instantiate()
		node.position = pos
		node.setup(data)
		node.node_clicked.connect(_on_node_clicked)
		graph_root.add_child(node)
		node_map[id] = node

	_draw_connections(node_map)


func _generate_layout() -> Dictionary:
	var layout: Dictionary = {}
	var all_ids: Array[String] = _collect_all_upgrade_ids()

	var positions: Dictionary = {
		"la_peste_1": Vector2(0, 0),
		"resistencia_zombie": Vector2(-130, 120),
		"deteccion_tumbas": Vector2(130, 120),
		"pico_afilado": Vector2(-130, 260),
		"velocidad_zombie": Vector2(130, 260),
	}

	for id: String in all_ids:
		if positions.has(id):
			layout[id] = positions[id]
		else:
			layout[id] = Vector2(0, all_ids.find(id) * 140.0)

	return layout


func _draw_connections(node_map: Dictionary) -> void:
	for id: String in node_map:
		var node: UpgradeNode = node_map[id]
		if not node.data:
			continue
		for target_id: String in node.data.connected_ids:
			if not node_map.has(target_id):
				continue
			var line: Line2D = Line2D.new()
			line.width = 3.0
			var from_node: UpgradeNode = node_map[target_id]
			line.add_point(from_node.position)
			line.add_point(node.position)
			line.default_color = Color(0.5, 0.5, 0.5, 0.8)
			line.z_index = -1
			graph_root.add_child(line)
			line.name = "line_" + target_id + "_" + id


func _refresh_lines() -> void:
	for child: Node in graph_root.get_children():
		if child is Line2D:
			var line: Line2D = child as Line2D
			var all_locked: bool = true
			for id: String in child.name.trim_prefix("line_").split("_"):
				if GameManager.unlocked_upgrades.has(id):
					all_locked = false
					break
			line.default_color = Color(0.2, 0.7, 0.2, 0.9) if not all_locked else Color(0.5, 0.5, 0.5, 0.8)


func _on_node_clicked(upgrade_data: UpgradeData) -> void:
	selected_upgrade_id = upgrade_data.id
	label_upgrade_name.text = upgrade_data.upgrade_name
	label_description.text = upgrade_data.description
	label_cost.text = "Coste: " + str(upgrade_data.cost) + " zombies (Tienes: " + str(GameManager.sacrificed_zombies) + ")"
	var can_afford: bool = GameManager.sacrificed_zombies >= upgrade_data.cost
	var is_available: bool = GameManager.available_upgrades.has(upgrade_data.id)
	button_buy.disabled = not (is_available and can_afford)
	details_popup.show()


func _on_buy_pressed() -> void:
	if selected_upgrade_id.is_empty():
		return
	GameManager.purchase_upgrade(selected_upgrade_id)
	details_popup.hide()


func _on_close_pressed() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom += Vector2(0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom - Vector2(0.1, 0.1)).clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start = get_global_mouse_position()
				camera_start = camera.position
			else:
				is_panning = false

	if event is InputEventMouseMotion and is_panning:
		var delta: Vector2 = get_global_mouse_position() - pan_start
		camera.position = camera_start - delta / camera.zoom


func _collect_all_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir: DirAccess = DirAccess.open("res://resources/upgrades/")
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				ids.append(file_name.trim_suffix(".tres"))
			file_name = dir.get_next()
		dir.list_dir_end()
	return ids


func _load_upgrade(upgrade_id: String) -> UpgradeData:
	var path: String = "res://resources/upgrades/" + upgrade_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as UpgradeData
