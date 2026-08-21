extends Node

@export var cell_size: Vector2i = Vector2i(64, 64)
@export var grid_dimensions: Vector2i = Vector2i(40, 30)

var astar_grid: AStarGrid2D


func _ready() -> void:
    _setup_grid()


func _setup_grid() -> void:
    astar_grid = AStarGrid2D.new()
    astar_grid.region = Rect2i(Vector2i.ZERO, grid_dimensions)
    astar_grid.cell_size = cell_size
    astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    astar_grid.update()


## Recibe la señal needs_target de un zombie, aplica la fórmula de peso y le asigna la tumba óptima.
func _on_needs_target(zombie: Zombie) -> void:
    var graves: Array[Grave] = _get_active_graves()
    if graves.is_empty():
        return

    var best_grave: Grave = _find_best_grave(graves)
    if best_grave:
        zombie.assign_target(best_grave)


## Fórmula del GDD: peso = current_hp + (zombies_assigned * 50)
## La tumba con el peso más bajo es la más eficiente.
func _find_best_grave(graves: Array[Grave]) -> Grave:
    var best: Grave = graves[0]
    var lowest_weight: float = _calculate_weight(best)

    for grave: Grave in graves:
        var weight: float = _calculate_weight(grave)
        if weight < lowest_weight:
            lowest_weight = weight
            best = grave

    return best


func _calculate_weight(grave: Grave) -> float:
    return float(grave.current_hp) + (float(grave.zombies_assigned) * 50.0)


## Obtiene todas las tumbas activas desde GravesContainer, filtrando referencias inválidas.
func _get_active_graves() -> Array[Grave]:
    var result: Array[Grave] = []
    var container: Node = get_tree().current_scene.get_node_or_null("GravesContainer")
    if not container:
        return result

    for child: Node in container.get_children():
        if child is Grave and is_instance_valid(child) and not child.is_queued_for_deletion() and child.current_hp > 0:
            result.append(child)

    return result
