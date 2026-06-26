extends Node

@onready var zombie_scene = preload("res://scenes/zombie_base.tscn")

var zombies : Node2D

func _ready() -> void:
	zombies = Node2D.new()
	zombies.name = "Zombies"
	get_tree().current_scene.add_child(zombies)
	GameEvents.grave_opened.connect(_on_grave_opened)

func _on_grave_opened(grave_position, amount):
	print("ey")
	for n in amount:
		_create_zombie(grave_position)

func _create_zombie(zombie_position):
	print("eyeyyeyey")
	var new_zombie = zombie_scene.instantiate()
	new_zombie.global_position = zombie_position
	zombies.add_child(new_zombie)
	
