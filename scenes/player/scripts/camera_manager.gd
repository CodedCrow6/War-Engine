class_name CameraManager
extends Node3D

@export var parent: CharacterBody3D
@export var camera_pivot: Node3D
@export var camera: Camera3D

@onready var camera_effects: Node3D = $CameraEffects

# Headbob
var bob_time: float = 0.0
var bob_amplitude: float = 0.05
var bob_frequency_walk: float = 6.0
var bob_frequency_sprint: float = 10.0

# Suppression Camera Shake
var shake_strength: float = 0.0
var shake_decay: float = 6.0
var shake_time: float = 0.0


func _process(delta: float) -> void:
	var speed = parent.get_normalized_speed()
	update_headbob(delta, speed)

	_update_camera_shake(delta)
	
func update_headbob(delta: float, speed_normalized: float) -> void:

	if speed_normalized <= 0.01:
		# reset when idle
		bob_time = 0.0
		camera.position.y = lerp(camera.position.y, 0.0, 0.1)
		return

	# speed-driven frequency
	var freq = lerp(bob_frequency_walk, bob_frequency_sprint, speed_normalized)

	bob_time += delta * freq

	# sine wave bob
	var bob_offset = sin(bob_time) * bob_amplitude

	camera.position.y = bob_offset
	
func _ready() -> void:
	if parent == null || camera_pivot == null:
		return
		
func handle_mouse_input(event: InputEventMouseMotion) -> void:
	parent.rotate_y(deg_to_rad(-event.relative.x * 0.1))
	camera_pivot.rotate_x(deg_to_rad(-event.relative.y * 0.1))

func update_fov(target_fov: float) -> void:
	camera.fov = lerp(camera.fov, target_fov, 0.1)

func add_camera_shake(amount: float) -> void:
	shake_strength = clamp(shake_strength + amount, 0.0, 1.0)

func _update_camera_shake(delta: float) -> void:
	if shake_strength <= 0.0:
		camera_effects.position = Vector3.ZERO
		return
		
	shake_time += delta * 25.0
	# decay
	shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	# noise-based shake (more natural than sine)
	var x = (sin(shake_time * 1.7) + sin(shake_time * 3.1)) * 0.5
	var y = (sin(shake_time * 2.3) + sin(shake_time * 4.7)) * 0.5
	
	var intensity = shake_strength * 0.05
	camera_effects.position = Vector3(x, y, 0.0) * intensity
