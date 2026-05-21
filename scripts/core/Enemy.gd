extends Node2D

class_name Enemy

@export var type: EnemyType

signal reached_base(enemy: Enemy)
var hp: float
var health_multiplier: float = 1.0


var path: PackedVector2Array
var path_index: int = 0
var distance: float = 0.0
var damage: float
var prize: int = 0
var prize_granted: bool = false
const TILE_SIZE := 125.0
var slow_multiplier: float = 1.0
var slow_time_left: float = 0.0
var extra_armor: float = 0.0
var _aura_timer: float = 0.0
var _flash_time: float = 0.0
const FLASH_DURATION := 0.35
const FLASH_COLOR := Color(10.0, 1.0, 1.0, 1.0)

var _bleed_stacks: Array[Dictionary] = [] # { "duration": float, "damage_per_tick": float }
var _stun_timer: float = 0.0
var _initial_hp: float = 0.0

@onready var fish_prefab:PackedScene = load("res://scenes/entities/Enemy.tscn")
@onready var explosion_scene:PackedScene = load("res://scenes/effects/ExplosionEffect.tscn")

func _ready() -> void:
	add_to_group("enemies")
	if type != null:
		if type.name == "Halibut pacyficzny":
			add_to_group("halibuts")
		$Sprite2D.texture = type.texture
		$Sprite2D.apply_scale(Vector2(4,4))
		
		# Only flip old fish. New fish (nowe-ryby) face the correct way.
		var new_fish_names = ["Jesiotr biały", "Łosoś czerwony", "Halibut pacyficzny"]
		if not type.name in new_fish_names:
			$Sprite2D.flip_h = !$Sprite2D.flip_h
		
		hp = type.health * health_multiplier
		_initial_hp = hp
		damage = type.damage
		prize = type.prize


func _process(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0:
			_flash_time = 0.0
			_update_modulate()
		else:
			var t := _flash_time / FLASH_DURATION
			if t > 0.5:
				$Sprite2D.modulate = FLASH_COLOR
			else:
				var target_color := _get_target_color()
				$Sprite2D.modulate = FLASH_COLOR.lerp(target_color, 1.0 - (t * 2.0))

	if slow_time_left > 0.0:
		slow_time_left -= delta
		if slow_time_left <= 0.0:
			slow_time_left = 0.0
			slow_multiplier = 1.0
			_update_modulate()
		else:
			_update_modulate()
	
	_process_bleed(delta)
	
	if _stun_timer > 0.0:
		_stun_timer -= delta
		_update_modulate()
		if _stun_timer <= 0.0:
			_update_modulate()

	# Special Abilities
	_process_auras(delta)

	if hp <= 0:
		if not prize_granted:
			GameManager.add_scales(prize)
			prize_granted = true
			for fish_type in type.spawnedEnemies:
				var fish:Enemy = fish_prefab.instantiate()
				fish.type = fish_type
				fish.global_position = global_position
				fish.path = path
				fish.path_index = path_index
				fish.distance = distance
				var controller:EnemyController = get_parent().get_node("EnemyController")
				controller.register_enemy(fish)
				get_parent().add_child(fish)
		_spawn_explosion()
		queue_free()
		return

	if path.is_empty() or path_index >= path.size():
		reached_base.emit(self)
		GameManager.take_damage(int(round(damage)))
		queue_free()
		return

	if _stun_timer > 0.0:
		return

	var speed := 0.0
	if type != null:
		speed = type.speed
		# Łosoś czerwony: speed = 2.8 when HP < 50%
		if type.name == "Łosoś czerwony" and hp < _initial_hp * 0.5:
			speed = 2.8
		speed = speed * TILE_SIZE * slow_multiplier

	var target_pos := path[path_index]
	global_position = global_position.move_toward(
		target_pos, speed * delta
	)
	distance += speed * delta

	if global_position.distance_to(target_pos) <= 4.0:
		path_index += 1


func _process_auras(_delta: float) -> void:
	extra_armor = 0.0
	var aura_range := TILE_SIZE # 1 tile
	
	# Any fish near a Halibut gets +5 armor
	var halibuts = get_tree().get_nodes_in_group("halibuts")
	for h in halibuts:
		if h == self:
			continue
		if not is_instance_valid(h):
			continue
		if global_position.distance_to(h.global_position) <= aura_range:
			extra_armor = 5.0
			break


func get_total_armor() -> float:
	var base_armor := 0.0
	if type != null:
		base_armor = type.armor
	return base_armor + extra_armor


func _update_modulate() -> void:
	if _flash_time <= 0.0:
		$Sprite2D.modulate = _get_target_color()


func _get_target_color() -> Color:
	if _stun_timer > 0.0:
		return Color(1.0, 1.0, 0.5, 1.0) # Yellowish stun tint
	if slow_time_left > 0.0:
		return Color(0.6, 0.8, 1.0, 1.0) # Blueish slow tint
	if not _bleed_stacks.is_empty():
		return Color(1.0, 0.4, 0.4, 1.0) # Reddish bleed tint
	return Color.WHITE


func take_damage(amount: float) -> void:
	hp -= amount
	if hp > 0:
		_flash_time = FLASH_DURATION
		$Sprite2D.modulate = FLASH_COLOR


func _spawn_explosion() -> void:
	var fx := explosion_scene.instantiate()
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)


func apply_magic_slow(multiplier: float, duration: float) -> void:
	if multiplier <= 0.0:
		return

	if multiplier < slow_multiplier:
		slow_multiplier = multiplier

	if duration > slow_time_left:
		slow_time_left = duration


func apply_bleed(duration: float, damage_percent: float) -> void:
	var damage_per_sec = _initial_hp * (damage_percent / 100.0)
	_bleed_stacks.append({
		"duration": duration,
		"damage_per_sec": damage_per_sec
	})
	_update_modulate()


func apply_stun(duration: float) -> void:
	if duration > _stun_timer:
		_stun_timer = duration
	_update_modulate()


func _process_bleed(delta: float) -> void:
	if _bleed_stacks.is_empty():
		return
		
	var total_damage = 0.0
	var i = _bleed_stacks.size() - 1
	while i >= 0:
		var stack = _bleed_stacks[i]
		total_damage += stack.damage_per_sec * delta
		stack.duration -= delta
		if stack.duration <= 0:
			_bleed_stacks.remove_at(i)
		i -= 1
	
	if total_damage > 0:
		hp -= total_damage
		if _bleed_stacks.is_empty():
			_update_modulate()
