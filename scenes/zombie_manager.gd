extends Node

@onready var zombie_scene = preload("res://scenes/zombie_base.tscn")

var zombies : Node2D

func _ready() -> void:
	zombies = Node2D.new()
	zombies.name = "Zombies"
	get_tree().current_scene.add_child(zombies)
	_create_zombie()


func _create_zombie():
	var new_zombie = zombie_scene.instantiate()
	zombies.add_child(new_zombie)
	
