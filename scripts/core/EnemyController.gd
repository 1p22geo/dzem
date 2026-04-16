extends Node

class_name EnemyController

@export var spawner: Spawner
@export var waveDefs: Waves

var wave_no: int = 0
var enemies_spawned: int = 0

var state: StateMachine

var activeEnemies:Array[Enemy] = []



func prepare_states() -> void:
	var sm = StateMachine.new()
	sm.name = "StateMachine"

	var prep = PreparationState.new()
	prep.name = "PreparationState"
	sm.add_child(prep)

	var waiting = WaitingForWaveState.new()
	waiting.name = "WaitingForWaveState"
	sm.add_child(waiting)

	var spawning = SpawningState.new()
	spawning.name = "SpawningState"
	sm.add_child(spawning)

	sm.initial_state = prep
	add_child(sm)
	state = sm


func _ready() -> void:
	if spawner == null:
		var scene_root := get_tree().current_scene
		if scene_root != null:
			spawner = scene_root.find_child("Spawner", true, false) as Spawner

	prepare_states()
	
	GameManager.scales = waveDefs.initial_coins
	if not GameManager.magic_burst_casted.is_connected(_on_magic_burst_casted):
		GameManager.magic_burst_casted.connect(_on_magic_burst_casted)
	GameManager.set_current_wave_index(wave_no)


func _process(_delta: float) -> void:
	GameManager.set_current_wave_index(wave_no)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			GameManager.cast_magic()
		elif event.keycode == KEY_R:
			GameManager.purify_magic()


func _on_magic_burst_casted(damage: float, slow_multiplier: float, slow_duration: float) -> void:
	for enemy in activeEnemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.hp <= 0:
			continue

		var enemy_armor: float = 0.0
		if enemy.type != null:
			enemy_armor = enemy.type.armor

		var final_damage: float = damage - enemy_armor
		if final_damage < 1.0:
			final_damage = 1.0

		enemy.take_damage(final_damage)
		if enemy.hp <= 0:
			enemy.hp = 1.0
		enemy.apply_magic_slow(slow_multiplier, slow_duration)


func register_enemy(enemy: Enemy) -> void:
	if enemy == null:
		return

	activeEnemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))


func _on_enemy_removed(enemy: Enemy) -> void:
	activeEnemies.erase(enemy)
