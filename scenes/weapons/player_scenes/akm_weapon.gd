class_name AKM_Weapon
extends Weapon


func _ready() -> void:
	if muzzle:
		muzzle_flash_instance = muzzle.muzzle_flash
		muzzle.position = Vector3(0.002,0.605,-0.01)

func fire() -> void:
	_spawn_projectile()
	_spawn_muzzle_flash()
	_play_fire_sound()
	
func reload() -> void:
	if ammo_count > max_ammo:
		ammo_count = max_ammo

func on_equip() -> void:
	pass

func on_unequip() -> void:
	pass

func _spawn_projectile():
	pass
	
func _spawn_muzzle_flash():
	if muzzle_flash_instance:
		muzzle_flash_instance.animation_player.play("emit")
	
func _play_fire_sound():
	if fire_sound_player == null:
		return
	fire_sound_player.play()

	
