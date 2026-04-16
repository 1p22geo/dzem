extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play("explode")
	sprite.animation_finished.connect(_on_finished)


func _on_finished() -> void:
	queue_free()
