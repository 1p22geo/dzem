extends Node2D
class_name Base

var enemies: Array[Enemy] = []


func _ready() -> void:
	add_to_group("base")
