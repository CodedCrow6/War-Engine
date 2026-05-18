class_name SuppressionManager
extends Node3D

@onready var suppression_shader_surface: ColorRect = $"../HudManager/VFXMarginContainer/CanvasLayer/ColorRect"
@onready var suppression_vfx_container: MarginContainer = $"../HudManager/VFXMarginContainer"

# --- STATE ---
var suppression: float = 0.0
var decay_rate: float = 1.5

# optional tuning knobs
@export var max_suppression: float = 1.0
@export var pulse_strength: float = 0.4
@export var distortion_strength: float = 0.02


func _process(delta: float) -> void:
	# decay over time
	suppression = lerp(suppression, 0.0, decay_rate * delta)
	
	if suppression == 0.0:
		suppression_vfx_container.visible = false
	elif suppression > 0.0:
		suppression_vfx_container.visible = true
		
	_update_shader()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test_suppression"):
		_debug_trigger_suppression()
		
func add_suppression(amount: float) -> void:
	suppression += amount
	suppression = clamp(suppression, 0.0, max_suppression)

# --- OPTIONAL: directional spike (for near misses) ---
func add_suppression_spike(amount: float) -> void:
	suppression += amount * 1.5
	suppression = clamp(suppression, 0.0, max_suppression)

func _update_shader() -> void:
	var mat = suppression_shader_surface.material
	if mat == null:
		return

	var intensity = suppression

	mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
	mat.set_shader_parameter("alpha", intensity * 0.6)
	mat.set_shader_parameter("pulse_strength", intensity * 0.4)
	mat.set_shader_parameter("distortion_strength", intensity * 0.02)

	# 🎯 CAMERA SHAKE HOOK
	var camera_manager = get_parent().get_node_or_null("CameraManager")
	if camera_manager:
		camera_manager.add_camera_shake(intensity * 0.8)

func _debug_trigger_suppression() -> void:
	# instant spike
	add_suppression(0.6)

	# camera shake hook
	var camera_manager = get_parent().get_node_or_null("CameraManager")
	if camera_manager:
		camera_manager.add_camera_shake(0.8)
