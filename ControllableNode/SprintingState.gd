# sprinting_state.gd
extends State
class_name SprintingState

func enter() -> void:
	actor.target_speed = actor.SPRINT_SPEED
	actor.target_fov = actor.BASE_FOV * 1.05
	actor.head_bobbing_current_intensity = actor.HEAD_BOBBING_SPRINT_INTENSITY
	actor.head_bobbing_current_speed = actor.HEAD_BOBBING_SPRINT_SPEED

func physics_update(_delta: float) -> void:
	var move_direction = actor.get_movement_direction()
	
	if not actor.is_on_floor():
		state_machine.change_state("AirState")
		return
	
	if Input.is_action_pressed("crouch"):
		state_machine.change_state("CrouchingState")
		return
	
	if move_direction.length() == 0:
		state_machine.change_state("StandingState")
		return
	
	if not Input.is_action_pressed("sprint"):
		state_machine.change_state("WalkingState")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		actor.velocity.y = actor.JUMP_VELOCITY
		state_machine.change_state("AirState")
