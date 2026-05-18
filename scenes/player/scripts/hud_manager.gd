class_name HudManager
extends Control

@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer4/PanelContainer/MarginContainer/VBoxContainer/ProgressBar
@onready var progress_bar_2: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer4/PanelContainer/MarginContainer/VBoxContainer/ProgressBar2

@export var parent: CharacterBody3D

func _ready() -> void:
	if parent == null:
		return
	progress_bar.value = 100.0
	progress_bar_2.value = 100.0
	parent.damage_taken.connect(_on_damage_taken)
	
func _on_damage_taken(damage: float, hit_pos: Vector3) -> void:
	progress_bar.value -= damage
