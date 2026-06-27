extends Node

@onready var zombie_scene = preload("res://scenes/zombie_base.tscn")

var zombies : Node2D
var zombie_spawn_separation = 50 

func _ready() -> void:
	zombies = Node2D.new()
	zombies.name = "Zombies"
	get_tree().current_scene.add_child(zombies)
	GameEvents.grave_opened.connect(_on_grave_opened)

func _on_grave_opened(grave_position, amount):
	for n in amount:
		_create_zombie(grave_position)

func _create_zombie(zombie_position):
	var new_zombie = zombie_scene.instantiate()
	var rng = RandomNumberGenerator.new()
	new_zombie.global_position = Vector2(zombie_position.x + rng.randf_range(-zombie_spawn_separation, zombie_spawn_separation), zombie_position.y + rng.randf_range(-zombie_spawn_separation, zombie_spawn_separation))
	zombies.add_child(new_zombie)
