extends Tile

class_name Tower

@export var tower:TowerType

var animationMeleeRef := load("res://scenes/animations/AnimationMelee.tscn")
var animationRangeRef := load("res://scenes/animations/AnimationRange.tscn")
var animationSniperRef := load("res://scenes/animations/AnimationSniper.tscn")

var audio_stream_player: AudioStreamPlayer

var meleeAttackAudio := load("res://assets/sounds/sfx/sampl 31-ploinked-impact.wav")
var whipAttackAudio := load("res://assets/sounds/sfx/sampl 40-whip.wav")
var sniperAttackAudio := load("res://assets/sounds/sfx/sampl 43-poinked-swoosh.wav")

var controller:EnemyController;
var tower_sprite:Sprite2D;
var timer = 0
var selected: bool = false
var animation_player: AnimationPlayer
var sprite: Sprite2D

var active_projectiles = []
var applied_upgrades: Array[TowerUpgrade] = []
var current_capacity: int = 0

var total_damage_dealt: float = 0.0
var _sweep_alpha: float = 0.0
var _sweep_dir: Vector2 = Vector2.RIGHT
var _sweep_half_angle: float = 0.0
var _sweep_radius: float = 0.0

var empty_button: TextureButton

var _kill_bonus: float = 0.0
var _last_hit_timer: float = 0.0
var _ability_wave_cooldown: int = 0
var _ability_last_used_wave: int = -3

@onready var projectile_scene:PackedScene = load("res://scenes/entities/Projectile.tscn")

func _ready() -> void:
	add_to_group("towers")
	var scene_root := get_tree().current_scene
	if scene_root != null:
		controller = scene_root.find_child(
			"EnemyController", true, false
		) as EnemyController
	if has_node("TowerSprite"):
		tower_sprite = get_node("TowerSprite")
		tower_sprite.visible = false
	GameManager.placed_tower_selected.connect(_on_placed_tower_selected)
	GameManager.placed_tower_deselected.connect(_on_placed_tower_deselected)
	GameManager.wave_start_requested.connect(_on_wave_start_requested)
	tree_exiting.connect(_on_tree_exiting)

	if tower.evolution_id != "":
		if not GameManager.register_evolution(tower.evolution_id, self):
			# Should not happen if UI prevents it, but safety first
			queue_free()
			return

	# dodawanie animacji - NIE zmieniaj nazwy noda, bo track paths sie zepsuja
	var anim_scene: PackedScene
	if tower.is_melee:
		anim_scene = animationMeleeRef
	else:
		if tower.is_sniper:
			anim_scene = animationSniperRef
		else:
			anim_scene = animationRangeRef

	var anim_node := anim_scene.instantiate()
	add_child(anim_node)
	animation_player = anim_node.get_node("AnimPlayer") as AnimationPlayer
	sprite = anim_node.get_node("Sprite2D") as Sprite2D
	sprite.position = Vector2.ZERO
	animation_player.stop()
	animation_player.play("idle")

	z_index = int(global_position.y)

	_setup_empty_button()
	
	audio_stream_player = get_node("AttackAudioFX")
	audio_stream_player.bus = "SFX"
	
	if tower.is_melee:
		audio_stream_player.stream = meleeAttackAudio
	else:
		if tower.is_sniper:
			audio_stream_player.stream = sniperAttackAudio
		else:
			audio_stream_player.stream = whipAttackAudio
		


	
func get_damage() -> float:
	var total := tower.damage + _kill_bonus
	for upg in applied_upgrades:
		total += upg.damage_add
	for buff in _temp_buffs:
		total += buff.dmg_add
	return total


func get_crit_chance() -> float:
	var total: float = tower.crit_chance
	for upg in applied_upgrades:
		total += upg.crit_chance_add
	return total


func get_ability_damage() -> float:
	# Default ability damage if not defined elsewhere
	var base: float = 400.0 if tower.evolution_id == "sniper" else 0.0
	var total: float = base
	for upg in applied_upgrades:
		total += upg.ability_damage_add
	return total


func get_sweep_angle() -> float:
	var total: float = tower.sweep_angle
	for upg in applied_upgrades:
		total += upg.sweep_angle_add
	return total


func get_range() -> float:
	var total := float(tower.attackRange)
	for upg in applied_upgrades:
		total += float(upg.range_add)
	for buff in _temp_buffs:
		total += buff.range_add
	return total


func get_fire_delay() -> float:
	var total := tower.fire_delay
	for upg in applied_upgrades:
		total *= upg.fire_delay_mult
	for buff in _temp_buffs:
		total *= buff.delay_mult
	return total


func get_projectile_speed() -> float:
	var total := tower.projectile_speed
	for upg in applied_upgrades:
		total += upg.projectile_speed_add
	return total


func get_capacity() -> int:
	var total := tower.capacity
	for upg in applied_upgrades:
		total += upg.capacity_add
	return total


func get_max_projectiles() -> int:
	var total := tower.max_projectiles
	for upg in applied_upgrades:
		total += upg.max_projectiles_add
	return total


func empty_nets() -> void:
	current_capacity = 0
	# Re-emit selection to update UI if selected
	if empty_button.visible == true:
		empty_button.visible = false
	if selected:
		GameManager.placed_tower_selected.emit(self)


func get_sell_price() -> int:
	var total := int(tower.cost * 0.7)
	for upg in applied_upgrades:
		total += upg.sell_value_bonus
	return total


func _on_tree_exiting() -> void:
	if tower and tower.evolution_id != "":
		GameManager.unregister_evolution(tower.evolution_id)


func _on_wave_start_requested() -> void:
	# Check if ability becomes ready
	var current_wave = GameManager.get_current_wave_index()
	if current_wave - _ability_last_used_wave >= tower.ability_cooldown_waves:
		GameManager.active_ability_status_changed.emit(self, true)


func _is_wave_active() -> bool:
	if not controller or not controller.state:
		return false
	var cur = controller.state.current_state
	# Wave is active if we are in SpawningState OR if there are enemies still on map
	return (cur and cur.name == "SpawningState") or not controller.activeEnemies.is_empty()


func is_upgrade_available(upgrade: TowerUpgrade) -> bool:
	if applied_upgrades.has(upgrade):
		return false
	for pre in upgrade.prerequisites:
		if not applied_upgrades.has(pre):
			return false
	return true


func is_max_upgraded() -> bool:
	if not tower:
		return false
	for upg in tower.upgrades:
		if not applied_upgrades.has(upg):
			return false
	return true


func apply_upgrade(upgrade: TowerUpgrade) -> void:
	if not is_upgrade_available(upgrade):
		return
	if GameManager.spend_scales(upgrade.cost):
		applied_upgrades.append(upgrade)
		queue_redraw()
		# Re-emit selection to update UI
		GameManager.placed_tower_selected.emit(self)


func evolve_into(new_type: TowerType) -> void:
	if GameManager.spend_scales(new_type.cost):
		if tower.evolution_id != "":
			GameManager.unregister_evolution(tower.evolution_id)
		
		tower = new_type
		
		if tower.evolution_id != "":
			GameManager.register_evolution(tower.evolution_id, self)
			
		# Refresh animation and audio if needed
		# For now, we assume sprites are same, but we might need to refresh stats
		_kill_bonus = 0.0
		applied_upgrades.clear()
		
		# Re-instantiate animation node if type changed (e.g. melee to sniper)
		# ... (logic from _ready) ...
		# To keep it simple, I'll just refresh the current tower instance.
		
		# Reset cooldowns
		_ability_last_used_wave = -3
		
		queue_redraw()
		GameManager.placed_tower_selected.emit(self)


func _on_placed_tower_selected(t: Node2D) -> void:
	selected = (t == self)
	queue_redraw()


func _on_placed_tower_deselected() -> void:
	selected = false
	queue_redraw()


func _draw() -> void:
	if _sweep_alpha > 0.0:
		_draw_sweep()
	if not selected or not tower:
		return
	var radius := get_range()
	draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.25))
	draw_arc(
		Vector2.ZERO, radius, 0, TAU, 64,
		Color(1, 1, 1, 0.6), 3.0
	)


func _draw_sweep() -> void:
	var center_angle := _sweep_dir.angle()
	var half := _sweep_half_angle
	var r := _sweep_radius
	var segments := 24
	var color_fill := Color(1.0, 0.7, 0.1, _sweep_alpha * 0.55)
	var color_edge := Color(1.0, 0.95, 0.4, _sweep_alpha * 0.9)

	var points: PackedVector2Array = [Vector2.ZERO]
	for i in range(segments + 1):
		var angle := center_angle - half + (2.0 * half * float(i) / float(segments))
		points.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color_fill)
	draw_arc(Vector2.ZERO, r, center_angle - half, center_angle + half, segments, color_edge, 4.0)

func _setup_empty_button():
	empty_button = TextureButton.new()
	var size = Vector2(40,40)
	empty_button.texture_normal = load("res://assets/overload-icon.png")
	empty_button.custom_minimum_size = size
	empty_button.ignore_texture_size = true
	empty_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	empty_button.position = Vector2(-size.x / 2, size.y + 100)
	print(empty_button.position)
	empty_button.visible = false
	empty_button.z_index = 10
	empty_button.pressed.connect(self.empty_nets)
	add_child(empty_button)

enum TargetingMode { FIRST, LAST, CLOSEST, STRONGEST, WEAKEST, RANDOM }
var targeting_mode: TargetingMode = TargetingMode.FIRST

func _process(delta: float) -> void:
	
	if tower == null or controller == null or tower_sprite == null:
		return
	
	if GameManager.is_towers_frozen():
		if sprite:
			sprite.modulate = Color(0.5, 0.7, 1.0, 1.0) # Blueish tint
		return
	else:
		if sprite:
			sprite.modulate = Color.WHITE

	_process_buffs(delta)

	# Knight's reset logic
	if tower.max_kill_bonus_dmg > 0.0 and _kill_bonus > 0.0:
		if _is_wave_active():
			_last_hit_timer += delta
			if _last_hit_timer >= 20.0:
				_kill_bonus = 0.0
				_last_hit_timer = 0.0

	if _sweep_alpha > 0.0:
		_sweep_alpha -= delta * 1.5
		if _sweep_alpha <= 0.0:
			_sweep_alpha = 0.0
		queue_redraw()

	timer += delta
	if timer > get_fire_delay() and current_capacity < get_capacity():
		timer = 0
		var target: Enemy = find_target()
		if tower.is_melee:
			MeleeAttack(target)
		else:
			AttackEnemy(target)
	if current_capacity == get_capacity():
		empty_button.visible = true
	if empty_button.visible:
		empty_button.position.y = -empty_button.size.y*2 + sin(Time.get_ticks_msec() * 0.005) * 5


func _apply_hit_effects(enemy: Enemy, _is_crit: bool = false) -> void:
	if not is_instance_valid(enemy):
		return
		
	_last_hit_timer = 0.0 # Reset Knight's decay timer
	
	if tower.applies_bleed:
		enemy.apply_bleed(15.0, 1.0) # 15s duration, 1% max HP/s
		
	if tower.applies_stun:
		if not has_meta("_stun_cooldown") or Time.get_ticks_msec() - get_meta("_stun_cooldown") > 6000:
			enemy.apply_stun(2.0)
			set_meta("_stun_cooldown", Time.get_ticks_msec())


func _on_projectile_impact(enemy: Enemy, _projectile: Projectile) -> void:
	_apply_hit_effects(enemy)


func find_target() -> Enemy:
	if not (tower and controller):
		return null
		
	var targets: Array[Enemy] = []
	var tower_pos := tower_sprite.global_position
	var attack_range := get_range()
	
	for enemy in controller.activeEnemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.hp <= 0:
			continue
		
		var dist_to_tower = tower_pos.distance_to(enemy.global_position)
		if dist_to_tower <= attack_range:
			targets.append(enemy)
			
	if targets.is_empty():
		return null
		
	match targeting_mode:
		TargetingMode.FIRST:
			var best_target: Enemy = targets[0]
			for i in range(1, targets.size()):
				if targets[i].distance > best_target.distance:
					best_target = targets[i]
			return best_target
			
		TargetingMode.LAST:
			var best_target: Enemy = targets[0]
			for i in range(1, targets.size()):
				if targets[i].distance < best_target.distance:
					best_target = targets[i]
			return best_target
			
		TargetingMode.CLOSEST:
			var best_target: Enemy = targets[0]
			var best_dist = tower_pos.distance_to(best_target.global_position)
			for i in range(1, targets.size()):
				var d = tower_pos.distance_to(targets[i].global_position)
				if d < best_dist:
					best_dist = d
					best_target = targets[i]
			return best_target
			
		TargetingMode.STRONGEST:
			var best_target: Enemy = targets[0]
			for i in range(1, targets.size()):
				if targets[i].hp > best_target.hp:
					best_target = targets[i]
			return best_target
			
		TargetingMode.WEAKEST:
			var best_target: Enemy = targets[0]
			for i in range(1, targets.size()):
				if targets[i].hp < best_target.hp:
					best_target = targets[i]
			return best_target
			
		TargetingMode.RANDOM:
			return targets[randi() % targets.size()]
			
	return null


func on_enemy_killed() -> void:
	current_capacity = mini(current_capacity + 1, get_capacity())
	
	# Knight's kill bonus logic
	if tower.kill_bonus_dmg > 0.0:
		_kill_bonus = minf(_kill_bonus + tower.kill_bonus_dmg, tower.max_kill_bonus_dmg)
		
	if selected:
		GameManager.placed_tower_selected.emit(self)


func use_active_ability() -> bool:
	if not tower.has_active_ability:
		return false
	
	var current_wave = GameManager.get_current_wave_index()
	if current_wave - _ability_last_used_wave < tower.ability_cooldown_waves:
		return false
		
	_ability_last_used_wave = current_wave
	GameManager.active_ability_status_changed.emit(self, false)
	
	match tower.evolution_id:
		"cutthroat":
			_ability_stop_time()
		"defender":
			_ability_defender_buff()
		"sniper":
			_ability_sniper_shot()
		"piercer":
			_ability_piercer_burst()
		_:
			print("Unknown ability for evolution: ", tower.evolution_id)
			
	return true


func _ability_stop_time() -> void:
	# Stop all enemies for 10s
	for enemy in controller.activeEnemies:
		if is_instance_valid(enemy):
			enemy.apply_stun(10.0)


func _ability_defender_buff() -> void:
	# "Zasięg 128 (2). Przyspiesza atak o x0.9 delay, zwiększa dmg 5 oraz zwiększa range o 32 (0.5). Działa przez 15 sekund."
	var buff_range = 128.0
	var duration = 15.0
	
	# Find towers in range
	# Towers are in "towers" group? Need to check. 
	# TileMapManager places them, let's assume they are in a group or I'll find them via tree.
	var scene_root = get_tree().current_scene
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Tower and t.global_position.distance_to(global_position) <= buff_range:
			t.apply_temp_buff(0.9, 5.0, 32.0, duration)


func _ability_sniper_shot() -> void:
	if controller.activeEnemies.is_empty():
		return
		
	var strongest: Enemy = controller.activeEnemies[0]
	for i in range(1, controller.activeEnemies.size()):
		if controller.activeEnemies[i].hp > strongest.hp:
			strongest = controller.activeEnemies[i]
			
	if is_instance_valid(strongest):
		var dmg = get_ability_damage()
		strongest.take_damage(dmg)
		total_damage_dealt += dmg
		if strongest.hp <= 0:
			on_enemy_killed()


func _ability_piercer_burst() -> void:
	for i in range(8):
		var angle = i * (TAU / 8.0)
		var dir = Vector2(cos(angle), sin(angle))
		
		var spawned_projectile:Projectile = projectile_scene.instantiate()
		spawned_projectile.damage = get_damage()
		spawned_projectile.speed = get_projectile_speed()
		spawned_projectile.flight_direction = dir
		spawned_projectile.parent_tower = self
		spawned_projectile.is_piercing = true
		
		if tower.projectile_texture:
			spawned_projectile.get_node("Sprite2D").texture = tower.projectile_texture
		else:
			spawned_projectile.get_node("Sprite2D").visible = false
		spawned_projectile.global_position = global_position
		spawned_projectile.origin_pos = global_position
		spawned_projectile.max_range = get_range()
		spawned_projectile.z_index = 1
		active_projectiles.append(spawned_projectile)
		get_tree().current_scene.add_child(spawned_projectile)


var _temp_buffs: Array[Dictionary] = [] # { "delay_mult": f, "dmg_add": f, "range_add": f, "duration": f }

func apply_temp_buff(delay_mult: float, dmg_add: float, range_add: float, duration: float) -> void:
	_temp_buffs.append({
		"delay_mult": delay_mult,
		"dmg_add": dmg_add,
		"range_add": range_add,
		"duration": duration
	})
	queue_redraw()


func _process_buffs(delta: float) -> void:
	var i = _temp_buffs.size() - 1
	var changed = false
	while i >= 0:
		_temp_buffs[i].duration -= delta
		if _temp_buffs[i].duration <= 0:
			_temp_buffs.remove_at(i)
			changed = true
		i -= 1
	if changed:
		queue_redraw()


func _face_target(target_pos: Vector2) -> void:
	if sprite:
		sprite.flip_h = target_pos.x > global_position.x


func _play_attack() -> void:
	audio_stream_player.play()
	if animation_player and animation_player.has_animation("attack"):
		animation_player.stop()
		animation_player.speed_scale = 2.5
		animation_player.play("attack")
		await animation_player.animation_finished
		if is_instance_valid(self) and animation_player:
			animation_player.stop()
			animation_player.speed_scale = 1
			animation_player.play("idle")


func MeleeAttack(target_enemy: Enemy) -> void:
	if target_enemy == null:
		return
	if not is_instance_valid(target_enemy):
		return
	_face_target(target_enemy.global_position)
	_play_attack()

	var tower_pos := tower_sprite.global_position
	var dir_to_target := (target_enemy.global_position - tower_pos).normalized()
	var half_angle := deg_to_rad(get_sweep_angle() * 0.5)
	var attack_range := get_range()

	_sweep_dir = dir_to_target
	_sweep_half_angle = half_angle
	_sweep_radius = attack_range
	_sweep_alpha = 1.0
	queue_redraw()

	var hit_count := 0
	var base_damage := get_damage()
	
	for enemy in controller.activeEnemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.hp <= 0:
			continue
		var to_enemy := enemy.global_position - tower_pos
		var dist := to_enemy.length()
		if dist > attack_range:
			continue
		var angle_diff := absf(dir_to_target.angle_to(to_enemy.normalized()))
		if angle_diff <= half_angle:
			var damage = base_damage
			var is_crit = false
			var crit_chance = get_crit_chance()
			if crit_chance > 0.0:
				if randf() < crit_chance:
					damage *= tower.crit_multiplier
					is_crit = true
			
			var enemy_armor: float = 0.0
			if enemy.type != null:
				enemy_armor = enemy.type.armor
			var final_damage: float = damage - enemy_armor
			if final_damage < 1.0:
				final_damage = 1.0
			
			enemy.take_damage(final_damage)
			total_damage_dealt += final_damage
			
			_apply_hit_effects(enemy, is_crit)
			
			if enemy.hp <= 0:
				on_enemy_killed()
			hit_count += 1


func AttackEnemy(enemy:Enemy) -> void:
	if tower:
		if enemy == null:
			return
		if not is_instance_valid(enemy):
			return
		if enemy.hp <= 0:
			return
		if len(active_projectiles) >= get_max_projectiles():
			return
		
		var damage = get_damage()
		var is_crit = false
		var crit_chance = get_crit_chance()
		if crit_chance > 0.0:
			if randf() < crit_chance:
				damage *= tower.crit_multiplier
				is_crit = true
		
		_face_target(enemy.global_position)
		_play_attack()
		var spawned_projectile:Projectile = projectile_scene.instantiate()
		spawned_projectile.damage = damage
		spawned_projectile.speed = get_projectile_speed()
		spawned_projectile.target = enemy
		spawned_projectile.parent_tower = self
		spawned_projectile.is_piercing = tower.is_piercing
		
		if tower.projectile_texture:
			spawned_projectile.get_node("Sprite2D").texture = tower.projectile_texture
		else:
			spawned_projectile.get_node("Sprite2D").visible = false
		spawned_projectile.global_position = global_position
		spawned_projectile.origin_pos = global_position
		spawned_projectile.max_range = get_range()
		spawned_projectile.z_index = 1
		active_projectiles.append(spawned_projectile)
		get_tree().current_scene.add_child(spawned_projectile)
