# Projectile Pool - DISABLED
# Reverted to simple instantiate/queue_free

#extends Node
#
#const ObjectPoolScript = preload("res://scripts/core/ObjectPool.gd")
#
#var _pool: ObjectPoolScript
#
#@onready var projectile_scene: PackedScene = load("res://scenes/entities/Projectile.tscn")
#
#func _ready() -> void:
#	_pool = ObjectPoolScript.new(projectile_scene, 1, 50)
#
#func get_projectile() -> Projectile:
#	var proj := _pool.get_object() as Projectile
#	if proj == null:
#		proj = projectile_scene.instantiate()
#	return proj
#
#func return_projectile(projectile: Projectile) -> void:
#	if projectile == null:
#		return
#	if is_instance_valid(projectile.parent_tower):
#		var index := projectile.parent_tower.active_projectiles.find(projectile)
#		if index >= 0:
#			projectile.parent_tower.active_projectiles.remove_at(index)
#			
#	projectile.target = null
#	projectile.parent_tower = null
#	projectile.global_position = Vector2.ZERO
#	projectile.visible = false
#	
#	if projectile.get_parent() != null:
#		projectile.get_parent().remove_child(projectile)
#	_pool.return_object(projectile)
#
#func clear() -> void:
#	_pool.clear()
