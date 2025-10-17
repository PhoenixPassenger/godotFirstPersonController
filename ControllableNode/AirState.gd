# air_state.gd
extends State
class_name AirState

func enter() -> void:
	actor.target_fov = actor.BASE_FOV

func physics_update(_delta: float) -> void:
	if actor.is_on_floor():
		var move_direction = actor.player_movement.get_movement_direction()
		if move_direction.length() > 0:
			if Input.is_action_pressed("sprint"):
				state_machine.change_state("SprintingState")
			else:
				state_machine.change_state("WalkingState")
		else:
			state_machine.change_state("StandingState")

func handle_input(_event: InputEvent) -> void:
	# Optional: Allow jumping while in air (coyote time, double jump, etc.)
	pass
