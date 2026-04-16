extends Resource


class_name TowerType

@export var texture:Texture
@export var projectile_texture:Texture
@export var projectile_speed:float
@export var damage: float
@export var name:String
@export var cost: int
@export var attackRange: int
@export var fire_delay: float
@export var max_projectiles: int
@export var is_melee: bool = false
@export var sweep_angle: float = 120.0
@export var capacity: int = 10
@export var upgrades: Array[TowerUpgrade] = []
