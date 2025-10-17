extends State
class_name CrouchIdleState

func enter() -> void:
	actor.standing_collision.disabled = true
	actor.crouching_collision.disabled = false
	actor.target_head_height = actor.IDLE_HEIGHT + actor.CROUCH_DEPTH
	actor.head_bobbing_current_intensity = 0.0
	actor.head_bobbing_current_speed = 0.0

func physics_update(_delta: float) -> void:
	var move_direction = actor.player_movement.get_movement_direction()
	
	if not actor.is_on_floor():
		state_machine.change_state("AirState")
		return
	
	if not Input.is_action_pressed("crouch") and move_direction.length() == 0 and actor.can_stand_up():
		state_machine.change_state("StandingState")
		return
		
	if move_direction.length() > 0:
			if not Input.is_action_pressed("crouch") and actor.can_stand_up():
				state_machine.change_state("WalkingState")
				return
			else:
				state_machine.change_state("CrouchingState")
				return


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and actor.can_stand_up():
		state_machine.change_state("AirState")
