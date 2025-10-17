extends Node
class_name ControllableNodeStateMachine

signal state_changed(old_state, new_state)

var states: Dictionary = {}
var current_state: State = null
var previous_state: State = null

@export var initial_state: State

func _ready() -> void:
	await owner.ready
	
	# Initialize all states
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
			child.actor = owner
			child._ready()
	
	if initial_state:
		change_state(initial_state.name)

func change_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("State '%s' doesn't exist!" % state_name)
		return
	
	var new_state: State = states[state_name]
	
	if current_state == new_state:
		return
	
	if current_state:
		current_state.exit()
		previous_state = current_state
	
	current_state = new_state
	current_state.enter()
	
	state_changed.emit(previous_state, current_state)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
