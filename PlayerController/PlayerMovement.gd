extends Node
var player: CharacterBody3D

func _ready():
	InputManager.connect("move_input", Callable(self, "_on_move_input"))
	InputManager.connect("jump_pressed", Callable(self, "_on_jump_pressed"))
	InputManager.connect("interact_pressed", Callable(self, "_on_interact_pressed"))

func _on_move_input(vec, _delta):
	handle_gravity(_delta)
	var target_direction = (player.transform.basis * Vector3(vec.x, 0, vec.y)).normalized()
	handle_horizontal_movement(target_direction, _delta)

func _on_jump_pressed():
	if player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
		
func _on_interact_pressed():
	print("Interaction")
		
func _physics_process(delta):
	player.current_speed = lerp(player.current_speed, player.target_speed, delta * 10.0)
	player.move_and_slide()
	
func handle_gravity(delta: float) -> void:
	if not player.is_on_floor():
		var gravity_multiplier := 1.5 if player.velocity.y < 0 else 1.0
		player.velocity += player.get_gravity() * delta * gravity_multiplier

		
func get_movement_direction() -> Vector3:
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	if input_dir == Vector2.ZERO:
		return Vector3.ZERO
	return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


func handle_horizontal_movement(vec: Vector3, delta: float) -> void:	
	player.move_direction = player.move_direction.lerp(vec, delta * player.LERP_SPEED)
	
	if player.move_direction:
		player.velocity.x = player.move_direction.x * player.current_speed
		player.velocity.z = player.move_direction.z * player.current_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.current_speed)
		player.velocity.z = move_toward(player.velocity.z, 0, player.current_speed)
