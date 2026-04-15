extends Tile

@export var tower:TowerType

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func tower_placed():
	$Tower/Sprite2D.texture = tower.texture
	$Tower.tower = tower

# Called when the node enters the scene tree for the first time.
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		# TODO: Tu ma być UI do wybierania wieży
		# TODO: po wybraniu wieży należy ustawić tower
		# TODO: oraz wywołać tower_placed
		pass
