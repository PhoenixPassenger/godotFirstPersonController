# walking_state.gd
extends State
class_name WalkingState

func enter() -> void:
	actor.standing_collision.disabled = false
	actor.crouching_collision.disabled = true
	actor.target_speed = actor.WALK_SPEED
	actor.target_fov = actor.BASE_FOV
	actor.target_head_height = actor.IDLE_HEIGHT
	actor.head_bobbing_current_intensity = actor.HEAD_BOBBING_WALK_INTENSITY
	actor.head_bobbing_current_speed = actor.HEAD_BOBBING_WALK_SPEED

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
	
	if Input.is_action_pressed("sprint"):
		state_machine.change_state("SprintingState")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		actor.velocity.y = actor.JUMP_VELOCITY
		state_machine.change_state("AirState")
