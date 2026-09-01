extends Node

## Moneda actual (zombies sacrificados).
var sacrificed_zombies: int = 0

## Multiplicador de daño de excavación (mejora comprada).
var dig_power_multiplier: float = 1.0

## IDs de mejoras compradas.
var unlocked_upgrades: Array[String] = []

## IDs de mejoras disponibles para comprar (todos los prerequisitos cumplidos).
var available_upgrades: Array[String] = []

## IDs de mejoras visibles en el grafo (al menos un vecino desbloqueado o es la raíz).
var visible_upgrades: Array[String] = []

## Se emite cada vez que cambia la moneda.
signal currency_updated(new_amount: int)

## Se emite cuando el estado de las mejoras cambia (compra, visibilidad, etc).
signal upgrades_updated()

## Se emite cuando La Peste debe generar una tumba.
signal grave_spawn_requested()

var _peste_timer: Timer


func _ready() -> void:
    _refresh_upgrade_states()


func purchase_upgrade(upgrade_id: String) -> bool:
    var data: UpgradeData = _load_upgrade_data(upgrade_id)
    if not data:
        return false
    if unlocked_upgrades.has(upgrade_id):
        return false
    if not available_upgrades.has(upgrade_id):
        return false
    if sacrificed_zombies < data.cost:
        return false

    sacrificed_zombies -= data.cost
    unlocked_upgrades.append(upgrade_id)
    _apply_upgrade_effect(data)
    _refresh_upgrade_states()
    currency_updated.emit(sacrificed_zombies)
    upgrades_updated.emit()
    return true


func _apply_upgrade_effect(data: UpgradeData) -> void:
    match data.id:
        "la_peste_1":
            _start_peste_timer()


func _refresh_upgrade_states() -> void:
    available_upgrades.clear()
    visible_upgrades.clear()

    var all_ids: Array[String] = _collect_all_upgrade_ids()
    for id: String in all_ids:
        if unlocked_upgrades.has(id):
            continue
        var data: UpgradeData = _load_upgrade_data(id)
        if not data:
            continue

        var any_neighbor_unlocked: bool = false
        var all_prereqs_met: bool = true

        for connected_id: String in data.connected_ids:
            if unlocked_upgrades.has(connected_id):
                any_neighbor_unlocked = true
            else:
                all_prereqs_met = false

        if data.connected_ids.is_empty():
            visible_upgrades.append(id)
            available_upgrades.append(id)
            continue

        if any_neighbor_unlocked:
            visible_upgrades.append(id)

        if all_prereqs_met and any_neighbor_unlocked:
            available_upgrades.append(id)


func _collect_all_upgrade_ids() -> Array[String]:
    var ids: Array[String] = []
    var dir: DirAccess = DirAccess.open("res://resources/upgrades/")
    if dir:
        dir.list_dir_begin()
        var file_name: String = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tres"):
                ids.append(file_name.trim_suffix(".tres"))
            file_name = dir.get_next()
        dir.list_dir_end()
    return ids


func _load_upgrade_data(upgrade_id: String) -> UpgradeData:
    var path: String = "res://resources/upgrades/" + upgrade_id + ".tres"
    if not ResourceLoader.exists(path):
        return null
    return load(path) as UpgradeData


func _start_peste_timer() -> void:
    if _peste_timer:
        return
    _peste_timer = Timer.new()
    _peste_timer.wait_time = 60.0
    _peste_timer.one_shot = false
    _peste_timer.timeout.connect(_on_peste_tick)
    add_child(_peste_timer)
    _peste_timer.start()


func _on_peste_tick() -> void:
    grave_spawn_requested.emit()
