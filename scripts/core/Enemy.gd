extends Sprite2D

class_name Enemy

@export var type:EnemyType

var hp:float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = type.texture
	hp = type.health;


func _process(delta: float) -> void:
	# TODO: chodzenie
	# TODO: zadawanie damage'a
	# TODO: odbieranie damage'a
	# TODO: cała kurwa reszta
	
	pass
