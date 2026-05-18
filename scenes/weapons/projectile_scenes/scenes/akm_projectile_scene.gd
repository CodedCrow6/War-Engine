class_name AKM_Projectile
extends Node3D

@onready var area: Area3D = $Area3D
@onready var ray_cast: RayCast3D = $RayCast3D

@export var damage: float = 15.0
@export var impact_scene: PackedScene
@export var max_lifetime: float = 10.0

signal impact(collider: PhysicsBody3D, hit_position: Vector3, hit_normal: Vector3)

var _lifetime_timer: float = 0.0
var _has_impacted: bool = false
var _suppression_triggered := false

const SPEED := 100.0
const SUPPRESSION_RADIUS := 6.0


func _ready() -> void:
	impact.connect(_on_impact)
	ray_cast.enabled = true

	if !area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)


func _physics_process(delta: float) -> void:
	var velocity = -transform.basis.z * SPEED
	global_position += velocity * delta

	_apply_near_miss_suppression()

	_lifetime_timer += delta
	if _lifetime_timer >= max_lifetime:
		queue_free()
		return

	ray_cast.target_position = velocity.normalized() * 2.0
	ray_cast.force_raycast_update()

	if ray_cast.is_colliding():
		if _has_impacted:
			return

		_has_impacted = true

		var collider = ray_cast.get_collider()
		var hit_position = ray_cast.get_collision_point()
		var hit_normal = ray_cast.get_collision_normal()

		emit_signal("impact", collider, hit_position, hit_normal)
		queue_free()


# ---------------------------------------------------
# SUPPRESSION SYSTEM (NOW CLEANLY ROUTED)
# ---------------------------------------------------
func _apply_near_miss_suppression():
	if _suppression_triggered:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var sup_manager = player.get_node_or_null("SuppressionManager")
	if sup_manager == null:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > SUPPRESSION_RADIUS:
		return

	var bullet_dir = -transform.basis.z
	var dir_to_player = to_player.normalized()

	var alignment = dir_to_player.dot(bullet_dir)

	if alignment < 0.5:
		return

	_suppression_triggered = true

	var strength = clamp(
		(1.0 - (distance / SUPPRESSION_RADIUS)) * (SPEED / 100.0),
		0.0,
		1.0
	)

	# 🔥 ROUTE THROUGH SUPPRESSION MANAGER (NOT PLAYER)
	sup_manager.add_suppression_spike(strength)


# ---------------------------------------------------
# AREA fallback (kept but simplified)
# ---------------------------------------------------
func _on_area_body_entered(body: PhysicsBody3D) -> void:
	if _has_impacted:
		return

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + (-transform.basis.z * 2.0)
	)

	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	if result:
		_has_impacted = true

		emit_signal(
			"impact",
			result.collider,
			result.position,
			result.normal
		)

		queue_free()


# ---------------------------------------------------
# IMPACT HANDLING (UNCHANGED LOGIC)
# ---------------------------------------------------
func _on_impact(collider: PhysicsBody3D, hit_pos: Vector3, normal_pos: Vector3) -> void:
	if impact_scene:
		var impact_instance = impact_scene.instantiate()
		get_parent().add_child(impact_instance)

		impact_instance.global_position = hit_pos
		impact_instance.look_at(hit_pos + normal_pos, Vector3.UP)

		if impact_instance is GPUParticles3D:
			impact_instance.emitting = true

	var target_node = collider

	while target_node:
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage, hit_pos)
			break
		target_node = target_node.get_parent()
