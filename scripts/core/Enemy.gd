extends Sprite2D

@export var type:EnemyType

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = type.texture


func _process(delta: float) -> void:
	# TODO: chodzenie
	# TODO: zadawanie damage'a
	# TODO: odbieranie damage'a
	# TODO: cała kurwa reszta
	
	pass
