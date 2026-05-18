class_name InventoryManager
extends Control


@export var inventory_resource: InventoryResource

func _ready() -> void:
	if inventory_resource == null:
		return

func get_inventory_items() -> InventoryResource:
	return inventory_resource
