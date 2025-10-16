# player.gd
extends CharacterBody3D

# Nodes
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera: Camera3D = $Head/Eyes/Camera3D
@onready var stand_up_check: RayCast3D = $StandUpCheck
@onready var controlabble_node_state_machine: ControllableNodeStateMachine = $ControlabbleNodeStateMachine

# Constants
const WALK_SPEED := 3.0
const SPRINT_SPEED := 5.0
const CROUCH_SPEED := 1.0
const CROUCH_DEPTH := -0.9
const JUMP_VELOCITY := 4.0
const BASE_FOV := 90.0
const MOUSE_SENSITIVITY := 0.2
const IDLE_HEIGHT := 1.8
const LERP_SPEED := 10.0
const AIR_CONTROL_MULTIPLIER := 0.5
const HEAD_BOBBING_SPRINT_SPEED := 22.0
const HEAD_BOBBING_WALK_SPEED := 14.0
const HEAD_BOBBING_CROUCH_SPEED := 10.0
const HEAD_BOBBING_SPRINT_INTENSITY := 0.2
const HEAD_BOBBING_WALK_INTENSITY := 0.1
const HEAD_BOBBING_CROUCH_INTENSITY := 0.05

# Movement variables
var current_speed: float = 0.0
var target_speed: float = 0.0
var target_head_height: float = IDLE_HEIGHT
var target_fov: float = BASE_FOV
var input_direction: Vector2 = Vector2.ZERO
var move_direction: Vector3 = Vector3.ZERO
var head_bobbing_current_intensity := 0.0
var head_bobbing_current_speed := 0.0
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index := 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_input(event)
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	# Forward input to state machine
	if controlabble_node_state_machine and controlabble_node_state_machine.current_state:
		controlabble_node_state_machine.current_state.handle_input(event)

func _physics_process(delta: float) -> void:
	current_speed = lerp(current_speed, target_speed, delta * 10.0)
	handle_movement(delta)
	handle_camera_animation(delta)
	move_and_slide()

func handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func handle_movement(delta: float) -> void:
	handle_gravity(delta)
	handle_horizontal_movement(delta)


func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_multiplier := 1.5 if velocity.y < 0 else 1.0
		velocity += get_gravity() * delta * gravity_multiplier

		
func get_movement_direction() -> Vector3:
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	if input_dir == Vector2.ZERO:
		return Vector3.ZERO
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


func handle_horizontal_movement(delta: float) -> void:
	input_direction = Input.get_vector("left", "right", "forward", "backwards")
	var target_direction = (transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	move_direction = move_direction.lerp(target_direction, delta * LERP_SPEED)
	
	if move_direction:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

func can_stand_up() -> bool:
	return not stand_up_check.is_colliding()

func handle_camera_animation(delta: float) -> void:
	# Handle head position and FOV
	head.position.y = lerp(head.position.y, target_head_height, delta * LERP_SPEED)
	camera.fov = lerp(camera.fov, target_fov, delta * LERP_SPEED)
	
	if head_bobbing_current_intensity > 0 and input_direction != Vector2.ZERO and is_on_floor():
		# Apply head bobbing when moving
		head_bobbing_index += head_bobbing_current_speed * delta
		
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2.0) + 0.5
		
		var target_bob_y = head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0)
		var target_bob_x = head_bobbing_vector.x * head_bobbing_current_intensity
		
		eyes.position.y = lerp(eyes.position.y, target_bob_y, delta * LERP_SPEED)
		eyes.position.x = lerp(eyes.position.x, target_bob_x, delta * LERP_SPEED)
	else:
		# Return to center position when not bobbing
		head_bobbing_index = 0.0  # Reset index when stopping
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * LERP_SPEED)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * LERP_SPEED)
