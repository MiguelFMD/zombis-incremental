extends Node

@onready var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")

## ZombieManager ahora actúa como utilidad. El spawn lo orquesta Main.gd.
## Útil para spawn manual desde tests/consola si se necesita.
