class_name VFXScene
extends Node3D

enum VfxParticle {ONE, TWO, THREE}

@export var vfx_particle_1: GPUParticles3D
@export var vfx_particle_2: GPUParticles3D
@export var vfx_particle_3: GPUParticles3D
@export var debug_enabled: bool = true
@export var vfx_duration: float = 0.0 ## in Seconds
@export var kill_after_duration: bool = false

@export var particle_size: Vector2 = Vector2(2.0,3.0)

@export var trigger_with_prox: bool = true ## Start vfx when player enters area3D
@export var trigger_area: Area3D
@export var trigger_radius: float = 10.0 ## sphere around the scene
@export var particle_to_trigger: VfxParticle

var vfx_time: float = 0.0
var particle_type: VfxParticle

func _ready() -> void:
	if vfx_particle_1 == null || vfx_particle_2 == null || vfx_particle_3 == null:
		if debug_enabled:
			print("Fire VFX scene references not set")
		return
	if trigger_area == null:
		if debug_enabled:
			print("trigger area not assigned")
		return
	trigger_area.body_entered.connect(_on_body_entered)
	
	_set_invisible()

func _set_invisible() -> void:
	vfx_particle_1.visible = false
	vfx_particle_2.visible = false
	vfx_particle_3.visible = false

func set_type(particle_type: VfxParticle) -> void:
	match particle_type:
		VfxParticle.ONE:
			vfx_particle_1.visible = true
			particle_type = VfxParticle.ONE
		VfxParticle.TWO:
			vfx_particle_2.visible = true
			particle_type = VfxParticle.TWO
		VfxParticle.THREE:
			vfx_particle_2.visible = true
			vfx_particle_3.visible = true
			particle_type = VfxParticle.THREE

func _process(delta: float) -> void:
	vfx_time += delta
	if kill_after_duration == true:
		if vfx_time >= vfx_duration:
			queue_free()
	_set_size()

func _set_size() -> void:
	match particle_type:
		VfxParticle.ONE:
			vfx_particle_1.draw_pass_1.size = particle_size
		VfxParticle.TWO:
			vfx_particle_2.draw_pass_1.size = particle_size
		VfxParticle.THREE:
			vfx_particle_2.draw_pass_1.size = particle_size
			vfx_particle_3.draw_pass_1.size = particle_size
	
func stop_fire() -> void:
	vfx_particle_1.visible = false
	vfx_particle_2.visible = false
	vfx_particle_3.visible = false

func _on_body_entered(body) -> void:
	set_type(particle_to_trigger)
