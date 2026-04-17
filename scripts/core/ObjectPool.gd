# Object Pool - DISABLED
# Reverted to simple instantiate/queue_free

#extends Node
#
#class_name ObjectPool
#
#var _scene: PackedScene
#var _pool: Array[Node] = []
#var _active: Array[Node] = []
#var _initial_size: int
#var _max_size: int
#
#func _init(scene: PackedScene, initial_size: int = 10, max_size: int = 100) -> void:
#	_scene = scene
#	_initial_size = initial_size
#	_max_size = max_size
#	_preload()
#
#func _preload() -> void:
#	for i in range(_initial_size):
#		var obj := _scene.instantiate()
#		obj.set_meta("pooled", true)
#		_pool.append(obj)
#	print("[ObjectPool] Preloaded ", _initial_size, " objects. Pool size: ", _pool.size())
#
#func get_object() -> Node:
#	var obj: Node
#	if _pool.size() > 0:
#		obj = _pool.pop_back()
#		print("[ObjectPool] Reusing from pool. Active: ", _active.size() + 1, " Pool: ", _pool.size())
#	else:
#		obj = _scene.instantiate()
#		obj.set_meta("pooled", true)
#		print("[ObjectPool] Created new (pool empty). Active: ", _active.size() + 1)
#	_active.append(obj)
#	return obj
#
#func return_object(obj: Node) -> void:
#	if not obj.get_meta("pooled", false):
#		return
#	if _active.has(obj):
#		_active.erase(obj)
#	if _pool.size() < _max_size:
#		_reset_object(obj)
#		_pool.append(obj)
#		print("[ObjectPool] Returned to pool. Active: ", _active.size(), " Pool: ", _pool.size())
#	else:
#		print("[ObjectPool] Pool full, freeing object. Active: ", _active.size())
#		obj.queue_free()
#
#func _reset_object(obj: Node) -> void:
#	if obj.has_method("reset"):
#		obj.reset()
#
#func clear() -> void:
#	for obj in _active:
#		if is_instance_valid(obj):
#			obj.queue_free()
#	_active.clear()
#	for obj in _pool:
#		if is_instance_valid(obj):
#			obj.queue_free()
#	_pool.clear()
#
#func get_active_count() -> int:
#	return _active.size()
#
#func get_pool_count() -> int:
#	return _pool.size()
