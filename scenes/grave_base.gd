class_name GraveBase
extends Node2D

@export var zombies_amount : int = 1
@export var health_amount : float = 1

func _dig(dig_force : float):
	health_amount -= dig_force
	if health_amount <= 0:
		_open_grave()

func _open_grave():
	GameEvents.grave_opened(global_position, zombies_amount)
