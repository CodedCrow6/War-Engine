class_name InventoryItem
extends Resource

@export_category("Configuration")

@export var item_name: StringName
@export var item_id: int
@export var is_weapon: bool
@export var is_stackable: bool

@export_category("Scenes & Assets")
@export var icon: Texture2D
@export var pickup_scene: PackedScene
@export var game_scene: PackedScene
