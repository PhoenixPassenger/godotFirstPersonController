# crouching_state.gd
extends State
class_name CrouchingState

func enter() -> void:
	actor.standing_collision.disabled = true
	actor.crouching_collision.disabled = false
	actor.target_head_height = actor.IDLE_HEIGHT + actor.CROUCH_DEPTH
	actor.target_speed = actor.CROUCH_SPEED
	actor.target_fov = actor.BASE_FOV * 0.95
	actor.head_bobbing_current_intensity = actor.HEAD_BOBBING_CROUCH_INTENSITY
	actor.head_bobbing_current_speed = actor.HEAD_BOBBING_CROUCH_SPEED

func physics_update(_delta: float) -> void:
	var move_direction = actor.player_movement.get_movement_direction()
	
	if not actor.is_on_floor():
		state_machine.change_state("AirState")
		return
	
	if not Input.is_action_pressed("crouch") and actor.can_stand_up():
		if move_direction.length() == 0:
			state_machine.change_state("StandingState")
		else:
			state_machine.change_state("WalkingState")
		return
	
	if move_direction.length() == 0:
		state_machine.change_state("CrouchIdleState")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and actor.can_stand_up():
		state_machine.change_state("AirState")
