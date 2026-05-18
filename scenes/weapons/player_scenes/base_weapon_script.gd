@abstract class_name Weapon
extends Node3D

@export_category("Configuration")
@export var animation_tree: AnimationTree
@export var sub_animation_player: AnimationPlayer
@export var caliber: GlobalEnums.WeaponCaliber
@export var max_ammo: int = 30.0

@export_category("Assets & Scenes")
@export_group("Sound FX") 
@export var fire_sound_array: Array[AudioStream]
@export var dry_fire_sound: AudioStream

@export_group("PackedScenes")
@export var projectile_scene: PackedScene
@export var muzzle_flash_scene: PackedScene	

@export_category("Node References")
@export var fire_sound_player: AudioStreamPlayer3D
@export var dry_fire_sound_player: AudioStreamPlayer3D
@export var reload_sound_player: AudioStreamPlayer3D
@export var muzzle: WeaponMuzzle

@export_category("Tuning")
@export var recoil_dampening_node: CopyTransformModifier3D
@export var recoil_dampening_factor: float = 0.2 ## recoil_dampening of 1.0 == no dampening

var owner_manager: Node = null
var ammo_count: int = max_ammo
var muzzle_flash_instance: Node3D

func _ready() -> void:
	if animation_tree == null:
		push_error(name + " has no AnimationTree assigned!")

# --- INTERFACE (must be overridden) ---

@abstract func fire() -> void

@abstract func reload() -> void

@abstract func on_equip() -> void

@abstract func on_unequip() -> void

func _set_owner(manager: Node) -> void:
	owner_manager = manager

func _process(delta: float) -> void:
	if recoil_dampening_node.amount != recoil_dampening_factor:
		recoil_dampening_node.amount = recoil_dampening_factor
