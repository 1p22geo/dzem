extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State



func _ready() -> void:
	for child in get_children():
		if child is State:
			child.Change.connect(_on_state_change)
	if initial_state:
		initial_state.Enter()
		current_state = initial_state


func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.Physics_Update(delta)


func _on_state_change(from_state: State, new_state_name: String) -> void:
	if from_state != current_state:
		return
	# Runtime-added states may not be owned by the scene, so search with owned=false.
	var new_state = find_child(new_state_name, true, false)
	if new_state == null or not new_state is State:
		push_warning("StateMachine: state '%s' not found" % new_state_name)
		return
	current_state.Exit()
	current_state = new_state
	current_state.Enter()
