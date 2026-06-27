class_name GraveBase
extends Node2D

@export var zombies_amount : int = 1
@onready var health_component: Node2D = $HealthComponent

func _ready() -> void:
	health_component.entity_die.connect(_on_entity_die)

func _dig(dig_force : float):
	health_component.reduce_health(dig_force)

func _open_grave():
	GameEvents.grave_opened.emit(global_position, zombies_amount)
	queue_free()

func _on_entity_die():
	_open_grave()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_dig(1)
