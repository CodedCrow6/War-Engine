class_name VFXManager
extends Node3D

@export var vfx_scenes: Array[VFXScene]
@export var start_all_when_ready: bool = true
@export var global_duration: float = 0.0 ## In Seconds, duration for all vfx scenes registered with vfx manager
@export var start_delay: float = 0.0 ## how long in seconds to delay starting all vfx
 
var enabled: bool = false
var time_since_start: float = 0.0

func enable() -> void:
	enabled = true
	if start_all_when_ready == true:
		for scene in vfx_scenes:
			if scene.trigger_with_prox == false:
				scene.set_type(scene.particle_type)

func _process(delta: float) -> void:
	if enabled:
		time_since_start += delta
	if global_duration != 0.0:
		if time_since_start > global_duration:
			for scene in vfx_scenes:
				scene.queue_free()
	if start_delay != 0.0:
		if time_since_start > start_delay:
			for scene in vfx_scenes:
				scene.set_type(scene.particle_type)
