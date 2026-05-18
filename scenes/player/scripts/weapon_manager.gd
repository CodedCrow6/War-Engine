class_name WeaponManager
extends Node3D

const ONESHOT = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

@onready var parent: CharacterBody3D
@onready var inventory_manager: InventoryManager = $"../InventoryManager"
@onready var animation_tree: AnimationTree
@onready var weapon_effects: Node3D = $WeaponEffects
@onready var weapon_mount: Node3D = $WeaponEffects/WeaponMount

# Reference to the pre-placed Arms scene
@onready var arms_node: Node3D = $WeaponEffects/Unarmed # ASSUMING 'Arms' is a child of WeaponEffects or WeaponMount

@onready var current_weapon: Node3D 
@onready var weapon_index: int = 0

@onready var weapons_array: Array[Node3D] 

@onready var anim_parameters: Dictionary = {
	"movement" : "parameters/Movement/blend_amount",
	"fire" : "parameters/Fire/request",
	"reload" : "parameters/Reload/request",
	"ready" : "parameters/Ready/blend_amount",
	"jump" : "parameters/Jump/blend_amount",
	"fire_variant" : "parameters/FireVariant/blend_amount",
	"hide" : "parameters/Hide/request",
	"show" : "parameters/Show/request"
}

@export var weapon_mount_base_position: Vector3 = Vector3(0.0,-1.80,0.0)
@export var aim_position: Vector3 = Vector3(0.058,-1.788,-0.035)
@export var aim_speed: float = 5.0

var is_ready: bool = false
var ready_blend: float = 0.0
var ready_speed: float = 8.0

var is_weapon_equiped: bool = false
var is_jumping: bool = false
var is_aiming: bool = false
var fire_variant: float = 0.0
var movement_blend: float = 0.0
var jump_blend: float = 0.0

func _ready() -> void:
	if weapon_mount == null or arms_node == null:
		push_error("WeaponManager: Missing WeaponMount or Arms node!")
		return
	
	parent = get_parent()
	
	if parent == null:
		return
	
	# 1. Initialize Arms State
	arms_node.visible = true
	arms_node.process_mode = Node.PROCESS_MODE_INHERIT
	
	# 2. Load Weapons from Inventory
	weapons_array = _get_weapons()
	
	# 3. Hide all instantiated weapons initially
	for weapon in weapons_array:
		weapon.visible = false
		
	# 4. Determine initial state
	# If we have weapons, equip the first one (index 0). 
	# If no weapons, keep Arms visible.
	if weapons_array.size() > 0:
		is_weapon_equiped = true
		weapon_index = 0
		_equip_weapon(weapons_array[weapon_index])
	else:
		is_weapon_equiped = false
		current_weapon = arms_node
		animation_tree = _find_animation_tree(current_weapon)

func _get_weapons() -> Array[Node3D]:
	var inventory_resource = inventory_manager.get_inventory_items()
	var array: Array[Node3D] = []
	
	for item in inventory_resource.items:
		if item == null:
			continue
		if item.is_weapon == true:
			if item.game_scene != null:
				var instance = item.game_scene.instantiate() as Node3D
				# Add to mount but keep hidden until equipped
				instance.visible = false 
				weapon_mount.add_child(instance)
				
				# Optional: Set position if needed, otherwise rely on scene root
				# instance.position = Vector3(-0.002,-0.05,0.035) 
				
				array.append(instance)
	return array

func _change_weapon_index(direction: int) -> void:
	if weapons_array.size() == 0:
		return # Cannot switch if no weapons

	weapon_index += direction
	
	# Wrap around logic
	if weapon_index >= weapons_array.size():
		weapon_index = 0
	elif weapon_index < 0:
		weapon_index = weapons_array.size() - 1
		
	is_weapon_equiped = true
	_equip_weapon(weapons_array[weapon_index])
	
func _equip_weapon(weapon_to_equip: Node3D) -> void:
	# 1. Hide previous weapon (if it was a weapon, not arms)
	if current_weapon and current_weapon != arms_node:
		current_weapon.visible = false
		
	# 2. Hide Arms
	arms_node.visible = false
	
	# 3. Show new weapon
	current_weapon = weapon_to_equip
	current_weapon.visible = true
	
	# 4. Update Animation Tree
	animation_tree = _find_animation_tree(current_weapon)
	
	if animation_tree == null:
		push_warning("Failed to find AnimationTree for weapon: " + current_weapon.name)

func _unequip_weapon() -> void:
	# 1. Hide current weapon
	if current_weapon and current_weapon != arms_node:
		current_weapon.visible = false
		
	# 2. Show Arms
	arms_node.visible = true
	current_weapon = arms_node
	
	# 3. Update Animation Tree to Arms' tree
	animation_tree = _find_animation_tree(current_weapon)
	is_weapon_equiped = false

func _change_weapon(weapon: Node3D) -> void:
	# This helper is mostly replaced by _equip_weapon now, 
	# but kept for compatibility if called elsewhere.
	if current_weapon != weapon:
		_set_anim_tree("hide", ONESHOT)
		_equip_weapon(weapon)
		_set_anim_tree("show", ONESHOT)

func _find_animation_tree(node: Node3D) -> AnimationTree:
	if node == null:
		return null
		
	var anim_tree = node.find_child("AnimationTree", true) as AnimationTree
	
	if anim_tree == null:
		# Fallback: Check if the node itself IS an AnimationPlayer or has a specific path
		# For now, push error as per original design
		push_error("No AnimationTree found on: " + node.name)
		return null
		
	return anim_tree
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("fire"):
		_handle_fire()
	is_aiming = Input.is_action_pressed("aim")
	if Input.is_action_just_pressed("ready"):
		is_ready = ! is_ready
	if Input.is_action_just_pressed("reload"):
		_reload()
	if Input.is_action_just_pressed("weapon_next"):
		_change_weapon_index(1)
	if Input.is_action_just_pressed("weapon_prev"):
		_change_weapon_index(-1)
	if Input.is_action_just_pressed("quick_action-unequip_weapon"):
		if is_weapon_equiped:
			_unequip_weapon()
		else:
			# If unarmed, maybe equip first weapon? Or do nothing.
			if weapons_array.size() > 0:
				_equip_weapon(weapons_array[0])
	if Input.is_action_just_pressed("adjust_recoil_dampening_up"):
		current_weapon.recoil_dampening_factor += 0.1
	if Input.is_action_just_pressed("adjust_recoil_dampening_down"):
		current_weapon.recoil_dampening_factor -= 0.1

func _process(delta: float) -> void:
	if animation_tree == null:
		# Try to recover animation tree if missing (e.g., after scene load)
		if current_weapon:
			animation_tree = _find_animation_tree(current_weapon)
		
		if animation_tree == null:
			return
		
	_handle_movement()
	_handle_aim(delta)
	_handle_ready(delta)

func _reload() -> void:
	if is_weapon_equiped and current_weapon and current_weapon.has_method("reload"):
		current_weapon.reload()

func _handle_movement() -> void:
	var vel = parent.velocity.length()
	var grounded = parent.is_on_floor()
	var speed = parent.get_normalized_speed()
	
	if vel >= 0.01 && grounded == true:
		movement_blend = 1.0 * speed
		_set_anim_tree("movement", movement_blend)
	elif vel < 0.1 && grounded == true:
		movement_blend = 0.0
		_set_anim_tree("movement", movement_blend)
	elif grounded == false:
		jump_blend = parent.get_jump_blend()
		_set_anim_tree("jump", jump_blend)
		
func _handle_aim(delta: float) -> void:
	if is_aiming == true:
		if weapon_mount.position != aim_position:
			weapon_mount.position = lerp(weapon_mount.position, aim_position, delta * aim_speed)
	elif is_aiming == false:
		if weapon_mount.position != weapon_mount_base_position:
			weapon_mount.position = lerp(weapon_mount.position, weapon_mount_base_position,  delta * aim_speed)

func _handle_ready(delta: float) -> void:
	if animation_tree == null:
		return

	var target = 1.0 if is_ready else 0.0
	ready_blend = lerp(ready_blend, target, ready_speed * delta)
	_set_anim_tree("ready", ready_blend)

func _handle_fire() -> void:
	if not is_weapon_equiped:
		return # Cannot fire if holding just arms
		
	fire_variant = !fire_variant
	_set_anim_tree("fire_variant" ,fire_variant)
	_set_anim_tree("fire", ONESHOT)
	
	# Call actual fire method on weapon script
	if current_weapon.has_method("fire"):
		current_weapon.fire()

func _set_anim_tree(anim_name: String, anim_value: Variant) -> void:
	if animation_tree == null:
		return
	
	if !anim_parameters.has(anim_name):
		push_warning("Invalid anim parameter: " + anim_name)
		return
	
	var anim_path = anim_parameters[anim_name]
	animation_tree.set(anim_path, anim_value) 
	
	if ready_blend != 0.0 and current_weapon and current_weapon != arms_node:
		if current_weapon.has_node("SubAnimationPlayer"):
			current_weapon.get_node("SubAnimationPlayer").play("Holster")
