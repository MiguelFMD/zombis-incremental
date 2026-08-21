extends Node2D

@onready var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
@onready var graves_container: Node2D = $GravesContainer
@onready var zombies_container: Node2D = $ZombiesContainer
@onready var grid_manager: Node = $GridManager
@onready var label_zombies_vivos: Label = $CanvasLayer_UI/Control_HUD/Label_ZombiesVivos
@onready var label_sacrificados: Label = $CanvasLayer_UI/Control_HUD/Label_Sacrificados

var zombie_spawn_separation: float = 50.0
var zombie_count: int = 0


func _ready() -> void:
    get_viewport().physics_object_picking = true
    for grave: Grave in graves_container.get_children():
        _connect_grave(grave)
    GameManager.currency_updated.connect(_on_currency_updated)
    _update_ui()


func _connect_grave(grave: Grave) -> void:
    var callable: Callable = _on_grave_destroyed.bind(grave)
    if not grave.grave_destroyed.is_connected(callable):
        grave.grave_destroyed.connect(callable)


func _on_grave_destroyed(spawn_count: int, grave: Grave) -> void:
    for _i: int in spawn_count:
        _spawn_zombie(grave.global_position)


func _spawn_zombie(spawn_position: Vector2) -> void:
    var zombie: Zombie = zombie_scene.instantiate()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    zombie.global_position = Vector2(
        spawn_position.x + rng.randf_range(-zombie_spawn_separation, zombie_spawn_separation),
        spawn_position.y + rng.randf_range(-zombie_spawn_separation, zombie_spawn_separation)
    )
    zombie.needs_target.connect(grid_manager._on_needs_target)
    zombie.zombie_sacrificed.connect(_on_zombie_sacrificed)
    zombies_container.add_child(zombie)
    zombie_count += 1
    _update_ui()


func _on_zombie_sacrificed() -> void:
    GameManager.sacrificed_zombies += 1
    zombie_count -= 1
    GameManager.currency_updated.emit(GameManager.sacrificed_zombies)
    _update_ui()


func _on_currency_updated(_new_amount: int) -> void:
    _update_ui()


func _update_ui() -> void:
    label_zombies_vivos.text = "Zombies vivos: " + str(zombie_count)
    label_sacrificados.text = "Sacrificados: " + str(GameManager.sacrificed_zombies)
