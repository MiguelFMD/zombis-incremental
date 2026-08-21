📄 GDD Técnico: "Undead Excavator" (Incremental Idle Game)
Motor: Godot Engine 4.7 (Estricto)
Perspectiva: 2D Top-Down Point&Click (Grid-based)
Arte: Programmer Art (ColorRects, Polygon2D). No solicitar assets externos.
Estructura: Single-Scene Flow (Sin pantallas de carga, todo en Main.tscn).

1. Arquitectura Global (Autoloads y Gestores)
Autoload: GameManager.gd
Propósito: Gestionar la moneda (Zombies sacrificados) y los desbloqueos/mejoras.

Variables:

var sacrificed_zombies: int = 0 (Moneda actual).

var dig_power_multiplier: float = 1.0 (Mejora comprada).

Señales:

signal currency_updated(new_amount)

Nodo Gestor: GridManager.gd (Hijo de Main.tscn)
Propósito: Instanciar el mapa, manejar el AStarGrid2D y asignar objetivos a los zombies.

Lógica de Eficiencia (Fórmula): Cuando un Zombie emite la señal needs_target, el GridManager itera sobre el array de tumbas activas y calcula un "Peso" (weight) para cada una.

Fórmula: peso = tumba.current_hp + (tumba.zombies_assigned * 50)

Resultado: La tumba con el peso más bajo es el objetivo asignado al zombie.

2. Estructura de Escenas y Árboles de Nodos
2.1. Main.tscn (Root)
Main (Node2D) - Script: Main.gd

GridManager (Node) - Script: GridManager.gd (Contiene AStarGrid2D).

Environment (Node2D) - Contenedor para el mapa base.

Pit (Area2D) - Instancia de Pit.tscn.

GravesContainer (Node2D) - Instancias de Grave.tscn.

ZombiesContainer (Node2D) - Instancias de Zombie.tscn.

CanvasLayer_UI (CanvasLayer)

Control_HUD (Control) - Labels para mostrar moneda y botones de mejoras.

2.2. Grave.tscn (Tumba)
Grave (Area2D) - Script: Grave.gd. (Layer colisión: Graves)

CollisionShape2D (Forma rectangular ajustada al Grid).

ColorRect (Visual placeholder, color marrón).

Label_HP (Label centrado mostrando la vida restante).

Variables: current_hp: int, zombies_assigned: int, zombies_to_spawn: int.

Funciones: take_damage(amount). Si current_hp <= 0, emite grave_destroyed y hace queue_free().

Señales: signal grave_destroyed(spawn_count, grid_position)

2.3. Zombie.tscn (Entidad Zombie)
Zombie (CharacterBody2D) - Script: Zombie.gd. (Capa colisión: Zombies)

CollisionShape2D (Forma circular).

ColorRect (Visual placeholder, color verde).

Area2D_Drag (Area2D para detectar los clics del ratón) -> CollisionShape2D.

NavigationAgent2D (Para moverse a la tumba, guiado por el AStarGrid2D de Main).

Timer_Dig (Controla el tick de excavación y consumo de estamina).

Timer_Rest (Controla el tiempo de recuperación de estamina).

Máquina de Estados (Enum): IDLE, MOVE, DIG, REST, DRAGGED.

Lógica de Drag & Drop:

Conectar la señal input_event del Area2D_Drag.

Si se detecta MOUSE_BUTTON_LEFT presionado -> state = DRAGGED.

En _physics_process: Si state == DRAGGED, global_position = get_global_mouse_position().

Si se suelta el clic, verificar con Area2D_Drag.get_overlapping_areas() si está sobre el Pit. Si es así, emitir señal y queue_free(). Si no, volver al estado IDLE.

Señales:

signal needs_target(zombie_node)

signal zombie_sacrificed()

2.4. Pit.tscn (El Pozo de Sacrificio)
Pit (Area2D) - Script: Vacío (la detección la hace el zombie) o simple decorador. Layer de colisión: Pit.

CollisionShape2D (Rectángulo grande).

ColorRect (Placeholder visual, color negro/púrpura).

3. Flujo de Señales (Call down, signal up)
El jugador clica en una tumba: El _input_event de Grave.tscn lo detecta -> Llama a take_damage(1).

La tumba se destruye: Grave emite grave_destroyed(zombies_to_spawn, global_position) -> Main.gd escucha esto, instancia N Zombie.tscn y los añade a ZombiesContainer.

El zombie busca trabajo: Zombie emite needs_target(self) -> GridManager.gd lo escucha, calcula la fórmula de eficiencia y llama hacia abajo (Call down): zombie.assign_target(grave_node).

Sacrificio: Al soltar el drag sobre el pozo, Zombie emite zombie_sacrificed() y muere -> Main.gd escucha esto y llama a GameManager.sacrificed_zombies += 1.
