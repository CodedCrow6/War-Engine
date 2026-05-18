extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var sprint_speed: float = 7.0

@export var max_health: float = 100.00
@export var max_stamina: float = 100.0

@export var debug_enabled: bool = false

var speed: float = 0.0
var jump_velocity: float = 4.0

var is_sprinting: bool = false
var is_crouching: bool = false

var input_dir

var health: float = max_health
var stamina: float = max_stamina

@onready var camera_manager: Node3D = $CameraManager
@onready var inventory_manager: InventoryManager = $InventoryManager

signal damage_taken(value: float, pos: Vector3)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event: InputEvent) -> void:
	is_sprinting = Input.is_action_pressed("sprint")
	is_crouching = Input.is_action_pressed("crouch")
	
	if event is InputEventMouseMotion:
		camera_manager.handle_mouse_input(event)
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		if debug_enabled:
			print("Velocity_y: " + str(velocity.y))

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity := Vector3.ZERO

	if direction:
		target_velocity = direction * speed

	velocity.x = move_toward(velocity.x, target_velocity.x, walk_speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, walk_speed)
	
	_update_speed(velocity)
	_update_camera()
	move_and_slide()

func _update_speed(velocity: Vector3) -> void:
	if input_dir != Vector2.ZERO:
		if is_sprinting == true:
			speed = sprint_speed
		elif is_sprinting == false:
			speed = walk_speed
	else:
		speed = 0.0
			
func get_normalized_speed() -> float:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var t := horizontal_speed / sprint_speed
	if debug_enabled:
		print("Normalized speed :" + str(t))	
	return clamp(t, 0.0, 1.0)

func get_jump_blend() -> float:
	var t = 1.0 - (abs(velocity.y) / jump_velocity)
	var t_clamp = clamp(t, 0.0, 1.0)
	if debug_enabled:
		print("Jump Blend : " + str(t_clamp))
	return t_clamp

func _update_camera() -> void:
	if is_sprinting == true:
		camera_manager.update_fov(70.0)
	else:
		camera_manager.update_fov(75.0)

func die() -> void:
	pass
	
func take_damage(damage: float, hit_position: Vector3) -> void:
	if health - damage <= 0:
		die()
	health -= damage
	damage_taken.emit(damage, hit_position)
