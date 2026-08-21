class_name Zombie
extends CharacterBody2D

signal needs_target(zombie_node: Zombie)
signal zombie_sacrificed()

enum State { IDLE, MOVE, DIG, REST, DRAGGED }

# Movement
var current_state: State = State.IDLE
var assigned_grave: Grave = null
var zombie_velocity: float = 100.0

# Stamina
const MAX_ZOMBIE_STAMINA: float = 3.0
var zombie_stamina: float = MAX_ZOMBIE_STAMINA

@onready var area_drag: Area2D = $Area2D_Drag
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var dig_timer: Timer = $Timer_Dig
@onready var rest_timer: Timer = $Timer_Rest


func _ready() -> void:
	area_drag.input_event.connect(_on_drag_pressed)
	dig_timer.timeout.connect(_on_dig_timer_finished)
	rest_timer.timeout.connect(_on_rest_finished)
	needs_target.emit(self)


func _physics_process(_delta: float) -> void:
	match current_state:
		State.DRAGGED:
			global_position = get_global_mouse_position()
		State.MOVE:
			process_navigation()


func _input(event: InputEvent) -> void:
	if current_state != State.DRAGGED:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_check_drop_on_pit()


## Llamado por GridManager para asignar la tumba más eficiente (call down).
func assign_target(grave: Grave) -> void:
	if current_state == State.DRAGGED:
		return
	if not is_instance_valid(grave):
		return

	# Cleanup previous assignment
	if assigned_grave and is_instance_valid(assigned_grave):
		assigned_grave.zombies_assigned -= 1

	assigned_grave = grave
	grave.zombies_assigned += 1

	# Start navigating toward the grave
	nav_agent.target_position = grave.global_position
	current_state = State.MOVE


func process_navigation() -> void:
	# If target grave was destroyed, find a new one
	if not is_instance_valid(assigned_grave):
		velocity = Vector2.ZERO
		current_state = State.IDLE
		needs_target.emit(self)
		return

	# Proximity check: once close enough to the grave (accounting for collision
	# shape radii ~16 px each), switch to digging.
	var distance_sq: float = global_position.distance_squared_to(assigned_grave.global_position)
	if distance_sq < 1600.0:  # 40 px threshold
		start_digging()
		return

	# Navigate via NavigationAgent2D; fallback to direct movement if no path
	if not nav_agent.is_navigation_finished():
		var next_position: Vector2 = nav_agent.get_next_path_position()
		var direction: Vector2 = global_position.direction_to(next_position)
		velocity = direction * zombie_velocity
	else:
		var direction: Vector2 = global_position.direction_to(assigned_grave.global_position)
		velocity = direction * zombie_velocity

	move_and_slide()


# ─── DIG STATE ───

func start_digging() -> void:
	current_state = State.DIG
	velocity = Vector2.ZERO
	zombie_stamina -= 1.0
	if is_instance_valid(assigned_grave):
		assigned_grave.take_damage(1.0)
	dig_timer.start(0.5)


func _on_dig_timer_finished() -> void:
	if not is_instance_valid(assigned_grave):
		velocity = Vector2.ZERO
		current_state = State.IDLE
		needs_target.emit(self)
		return

	if zombie_stamina > 0.0:
		start_digging()
	else:
		start_rest()


# ─── REST STATE ───

func start_rest() -> void:
	current_state = State.REST
	velocity = Vector2.ZERO
	rest_timer.start(3.0)


func _on_rest_finished() -> void:
	zombie_stamina = MAX_ZOMBIE_STAMINA
	needs_target.emit(self)


# ─── DRAGGED STATE ───

func _on_drag_pressed(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		current_state = State.DRAGGED
		dig_timer.stop()
		rest_timer.stop()


func _check_drop_on_pit() -> void:
	var overlapping: Array[Area2D] = []
	overlapping.assign(area_drag.get_overlapping_areas())
	for area: Area2D in overlapping:
		if area.is_in_group(&"Pit"):
			zombie_sacrificed.emit()
			queue_free()
			return
	# Dropped outside pit → return to idle and find new target
	current_state = State.IDLE
	needs_target.emit(self)


func _exit_tree() -> void:
	if assigned_grave and is_instance_valid(assigned_grave):
		assigned_grave.zombies_assigned -= 1
