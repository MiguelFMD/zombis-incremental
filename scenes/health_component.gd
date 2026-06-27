extends Node2D

signal entity_die()

@export var max_health : float = 5
@export var current_health : float = 5
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	progress_bar.max_value = max_health
	_update_health_bar()
	
func _update_health_bar():
	progress_bar.value = current_health

func reduce_health(amount : float):
	current_health -= amount
	_update_health_bar()
	if current_health <= 0:
		entity_die.emit()
