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
@onready var player_movement: Node = $PlayerMovement

# Constants
const WALK_SPEED := 3.0
const SPRINT_SPEED := 5.0
const CROUCH_SPEED := 1.0
const CROUCH_DEPTH := -0.9
const JUMP_VELOCITY := 2.5
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
	player_movement.player = self
	if InputManager:
		InputManager.connect("move_input", Callable(self, "_on_move_input"))
		InputManager.connect("jump_pressed", Callable(self, "_on_jump_pressed"))
		InputManager.connect("interact_pressed", Callable(self, "_on_interact_pressed"))
	else:
		push_error("InputManager singleton not found!")
	if InputManager.has_signal("move_input"):
		print("InputManager is global and ready")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_input(event)
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	# Forward input to state machine
	if controlabble_node_state_machine and controlabble_node_state_machine.current_state:
		controlabble_node_state_machine.current_state.handle_input(event)

func _physics_process(delta: float) -> void:
	handle_camera_animation(delta)

func handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

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
