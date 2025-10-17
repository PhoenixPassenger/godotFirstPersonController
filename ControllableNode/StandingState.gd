extends State
class_name StandingState

func enter() -> void:
	actor.standing_collision.disabled = false
	actor.crouching_collision.disabled = true
	actor.target_head_height = actor.IDLE_HEIGHT
	actor.head_bobbing_current_intensity = 0.0
	actor.head_bobbing_current_speed = 0.0

func physics_update(_delta: float) -> void:
	var move_direction = actor.player_movement.get_movement_direction()
	
	if not actor.is_on_floor():
		state_machine.change_state("AirState")
		return
	
	if Input.is_action_pressed("crouch"):
		state_machine.change_state("CrouchingState")
		return
	
	if move_direction.length() > 0:
		if Input.is_action_pressed("sprint"):
			state_machine.change_state("SprintingState")
		else:
			state_machine.change_state("WalkingState")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		state_machine.change_state("AirState")
