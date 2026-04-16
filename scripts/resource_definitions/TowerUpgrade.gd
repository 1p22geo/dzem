extends Resource
class_name TowerUpgrade

@export var name: String = "Upgrade"
@export var description: String = ""
@export var cost: int = 50
@export var sell_value_bonus: int = 25

@export_group("Stat Changes")
@export var damage_add: float = 0.0
@export var range_add: int = 0
@export var fire_delay_mult: float = 1.0
@export var projectile_speed_add: float = 0.0

@export_group("Prerequisites")
@export var prerequisites: Array[TowerUpgrade] = []
