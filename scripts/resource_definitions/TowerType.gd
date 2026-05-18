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
@export var is_sniper: bool = false
@export var sweep_angle: float = 120.0
@export var capacity: int = 10
@export var upgrades: Array[TowerUpgrade] = []
@export var evolutions: Array[TowerType] = []

@export_group("Evolution")
@export var evolution_id: String = "" # Empty for base towers
@export var is_piercing: bool = false
@export var crit_chance: float = 0.0 # 0.0 to 1.0
@export var crit_multiplier: float = 2.0
@export var applies_bleed: bool = false
@export var applies_stun: bool = false
@export var kill_bonus_dmg: float = 0.0
@export var max_kill_bonus_dmg: float = 0.0

@export_group("Active Ability")
@export var has_active_ability: bool = false
@export var ability_name: String = ""
@export var ability_description: String = ""
@export var ability_cooldown_waves: int = 3
