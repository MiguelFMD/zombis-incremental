class_name Grave
extends Area2D

signal grave_destroyed(spawn_count: int)

@export var max_hp: int = 5
@export var zombies_to_spawn: int = 1
@export var grid_position: Vector2 = Vector2.ZERO

var current_hp: int
var zombies_assigned: int = 0

@onready var label_hp: Label = $Label_HP


func _ready() -> void:
	current_hp = max_hp
	_update_label()
	input_pickable = true
	input_event.connect(_on_input_event)


func take_damage(amount: float) -> void:
	var final_damage: float = amount * GameManager.dig_power_multiplier
	current_hp -= int(final_damage)
	_update_label()
	if current_hp <= 0:
		grave_destroyed.emit(zombies_to_spawn)
		queue_free()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		take_damage(1.0)


func _update_label() -> void:
	label_hp.text = str(current_hp)
