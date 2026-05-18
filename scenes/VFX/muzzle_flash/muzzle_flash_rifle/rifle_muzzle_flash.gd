class_name MuzzleFlash
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var flash: GPUParticles3D = $Flash

func emit() -> void:
	if animation_player == null:
		return
	flash.visible = true
	animation_player.play("emit")
	
