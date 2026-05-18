class_name TestWorldMap
extends Node3D

@export var camp_fire: Node3D
@export var vfx_manager: VFXManager

var world_ready: bool = false

func _ready() -> void:
	if vfx_manager == null:
		return

func _process(delta: float) -> void:
	if world_ready:
		vfx_manager.enable()
	
	if is_node_ready():
		world_ready = true
