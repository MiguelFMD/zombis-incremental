# 📄 GDD Técnico: "Undead Excavator" (Incremental Idle Game)
**Motor:** Godot Engine 4.7 (Estricto)
**Perspectiva:** 2D Top-Down Point&Click (Grid-based)
**Arte:** Programmer Art (ColorRects, Polygon2D). No solicitar assets externos.
**Estructura:** Single-Scene Flow (Sin pantallas de carga, todo en `Main.tscn`).

## 1. Arquitectura Global (Autoloads, Gestores y Datos)

### Autoload: `GameManager.gd`

* **Propósito:** Gestionar la moneda (Zombies sacrificados), los desbloqueos y las mejoras.
* **Variables:**
* `var sacrificed_zombies: int = 0` (Moneda actual).
* `var dig_power_multiplier: float = 1.0` (Mejora activa).
* `var unlocked_upgrades: Array[String]` (IDs de mejoras compradas).
* `var available_upgrades: Array[String]` (IDs de mejoras que se pueden comprar).
* `var visible_upgrades: Array[String]` (IDs de mejoras visibles en el grafo).


* **Funciones:** `purchase_upgrade(upgrade_id)`. Valida el coste, resta moneda y actualiza los arrays de estado.
* **Señales:**
* `signal currency_updated(new_amount)`
* `signal upgrades_updated()`



### Resource: `UpgradeData.gd`

* **Propósito:** Contenedor de datos puros para el diseño del grafo de la tienda.
* **Variables Exportadas (`@export`):** `id: String`, `upgrade_name: String`, `cost: int`, `connected_ids: Array[String]`.

### Nodo Gestor: `GridManager.gd` (Hijo de `Main.tscn`)

* **Propósito:** Instanciar el mapa, manejar el `AStarGrid2D` y asignar objetivos a los zombies.
* **Lógica de Eficiencia (Fórmula):** Cuando un Zombie emite la señal `needs_target`, el `GridManager` itera sobre el array de tumbas activas y calcula un "Peso" (`weight`) para cada una.
* *Fórmula:* `peso = tumba.current_hp + (tumba.zombies_assigned * 50)`
* *Resultado:* La tumba con el `peso` más bajo es el objetivo asignado al zombie.



---

## 2. Estructura de Escenas y Árboles de Nodos

### 2.1. `Main.tscn` (Root)

* **`Main`** (Node2D) - Script: `Main.gd`
* **`GridManager`** (Node) - Script: `GridManager.gd` (Contiene `AStarGrid2D`).
* **`Environment`** (Node2D) - Contenedor para el mapa base.
* **`Pit`** (Area2D) - Instancia de `Pit.tscn`.
* **`GravesContainer`** (Node2D) - Instancias de `Grave.tscn`.
* **`ZombiesContainer`** (Node2D) - Instancias de `Zombie.tscn`.
* **`CanvasLayer_UI`** (CanvasLayer)
* **`Control_HUD`** (Control) - Labels para mostrar moneda y botón para "Abrir Tienda".
* **`ShopMenu`** (Control) - Instancia de `ShopMenu.tscn` (Oculta por defecto).





### 2.2. `Grave.tscn` (Tumba)

* **`Grave`** (Area2D) - Script: `Grave.gd`. (Layer de colisión: `Graves`)
* **`CollisionShape2D`** (Forma rectangular ajustada al Grid).
* **`ColorRect`** (Visual placeholder, color marrón).
* **`Label_HP`** (Label centrado mostrando la vida restante).


* **Variables:** `current_hp: int`, `zombies_assigned: int`, `zombies_to_spawn: int`.
* **Funciones:** `take_damage(amount)`. Si `current_hp <= 0`, emite `grave_destroyed` y hace `queue_free()`.
* **Señales:** `signal grave_destroyed(spawn_count, grid_position)`

### 2.3. `Zombie.tscn` (Entidad Zombie)

* **`Zombie`** (CharacterBody2D) - Script: `Zombie.gd`. (Layer de colisión: `Zombies`)
* **`CollisionShape2D`** (Forma circular).
* **`ColorRect`** (Visual placeholder, color verde).
* **`Area2D_Drag`** (Area2D para detectar los clics del ratón) -> `CollisionShape2D`.
* **`NavigationAgent2D`** (Para moverse a la tumba, guiado por el `AStarGrid2D` de `Main`).
* **`Timer_Dig`** (Controla el tick de excavación y consumo de estamina).
* **`Timer_Rest`** (Controla el tiempo de recuperación de estamina).


* **Máquina de Estados (Enum):** `IDLE`, `MOVE`, `DIG`, `REST`, `DRAGGED`.
* **Lógica de Drag & Drop:**
* Conectar la señal `input_event` del `Area2D_Drag`.
* Si se detecta `MOUSE_BUTTON_LEFT` presionado -> `state = DRAGGED`.
* En `_physics_process`: Si `state == DRAGGED`, `global_position = get_global_mouse_position()`.
* Si se suelta el clic, verificar con `Area2D_Drag.get_overlapping_areas()` si está sobre el `Pit`. Si es así, emitir señal y `queue_free()`. Si no, volver al estado `IDLE`.


* **Señales:**
* `signal needs_target(zombie_node)`
* `signal zombie_sacrificed()`



### 2.4. `Pit.tscn` (El Pozo de Sacrificio)

* **`Pit`** (Area2D) - Script: Vacío (la detección la hace el zombie) o simple decorador. Layer de colisión: `Pit`.
* **`CollisionShape2D`** (Rectángulo grande).
* **`ColorRect`** (Placeholder visual, color negro/púrpura).



### 2.5. `ShopMenu.tscn` (Tienda de Mejoras)

* **`ShopMenu`** (Control) - Script: `ShopMenu.gd`.
* **`SubViewportContainer`**
* **`SubViewport`** (Crea un renderizado independiente para el grafo).
* **`GraphRoot`** (Node2D) - Contenedor para instanciar dinámicamente `Line2D` (conexiones) y `UpgradeNode.tscn`.
* **`Camera2D`** - Controlador de la vista.




* **`DetailsPopup`** (Panel) - Interfaz emergente (oculta por defecto). Contiene Labels informativos y `Button_Buy`.


* **Lógica de Cámara:** Modificar `zoom` con la rueda del ratón y modificar `position` al mantener pulsado el clic y arrastrar (paneo en 8 direcciones).
* **Lógica de Generación:** Al cargar, iterar sobre los archivos `Resource`, instanciar nodos basándose en un patrón `_generate_layout()` (inicialmente un Grid simple) y dibujar nodos `Line2D` entre ellos basándose en la variable `connected_ids` del recurso.

### 2.6. `UpgradeNode.tscn` (Nodo del Grafo)

* **`UpgradeNode`** (TextureButton) - Script: `UpgradeNode.gd`.
* **Variables:** `var data: UpgradeData`.
* **Lógica Visual:** Modifica su textura/color validando su ID contra los arrays del `GameManager` (Estado: Oculto, Visible, Disponible, Comprado).
* **Señales:** `signal node_clicked(upgrade_data)`

---

## 3. Flujo de Señales (Call down, signal up)

1. **El jugador clica en una tumba:** El `_input_event` de `Grave.tscn` lo detecta -> Llama a `take_damage(1)`.
2. **La tumba se destruye y Spawnea:** `Grave` emite `grave_destroyed(zombies_to_spawn, global_position)` -> `Main.gd` escucha esto, instancia N `Zombie.tscn` y los añade al `ZombiesContainer`.
3. **El zombie busca trabajo:** `Zombie` emite `needs_target(self)` -> `GridManager.gd` lo escucha, calcula la fórmula de eficiencia y llama hacia abajo (Call down): `zombie.assign_target(grave_node)`.
4. **Sacrificio de Zombies:** Al soltar el drag sobre el pozo, `Zombie` emite `zombie_sacrificed()` y muere -> `Main.gd` escucha esto y llama a `GameManager.sacrificed_zombies += 1`.
5. **Interacción con el Grafo:** El jugador clica en un `UpgradeNode` -> Emite `node_clicked(data)` -> `ShopMenu.gd` lo escucha, rellena los textos del `DetailsPopup` con la información de ese Resource y lo hace visible.
6. **Validación de Compra:** El jugador clica el botón comprar en el Popup -> `ShopMenu` llama a `GameManager.purchase_upgrade(id)`. Si es válido, se emite `upgrades_updated()` -> `ShopMenu` y sus instancias de `UpgradeNode` escuchan la señal global y refrescan sus colores de estado inmediatamente.