class_name GraveBase
extends Node2D

signal grave_opened(grave_position : Vector2)

@export var zombies_amount : int = 1
@export var health_amount : float = 1

func _ready() -> void:
	grave_opened.connect(ZombieManager._create_zombie)

func _dig(dig_force : float):
	health_amount -= dig_force
	if health_amount <= 0:
		_open_grave()

func _open_grave():
	for n in zombies_amount:
		grave_opened.emit()
