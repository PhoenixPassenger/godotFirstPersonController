extends CharacterBody3D

# Nodes
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera: Camera3D = $Head/Eyes/Camera3D
@onready var stand_up_check: RayCast3D = $StandUpCheck

# Constants
const WALK_SPEED := 3.0
const SPRINT_SPEED := 5.0
const CROUCH_SPEED := 1.0
const HEAD_BOBBING_SPRINT_SPEED := 22.0
const HEAD_BOBBING_WALK_SPEED := 14.0
const HEAD_BOBBING_CROUCH_SPEED := 10.0
const HEAD_BOBBING_SPRINT_INTENSITY := 0.2
const HEAD_BOBBING_WALK_INTENSITY := 0.1
const HEAD_BOBBING_CROUCH_INTENSITY := 0.05
const CROUCH_DEPTH := -0.9
const JUMP_VELOCITY := 4.0
const BASE_FOV := 90.0
const MOUSE_SENSITIVITY := 0.2
const IDLE_HEIGHT := 1.8
const LERP_SPEED := 10.0

# Player state
enum PlayerState {
	IDLE_STAND,
	IDLE_CROUCH,
	CROUCHING,
	WALKING,
	SPRINTING,
	AIR
}

var current_state: PlayerState = PlayerState.IDLE_STAND
var last_ground_state: PlayerState = PlayerState.IDLE_STAND

var input_direction: Vector2 = Vector2.ZERO
var move_direction: Vector3 = Vector3.ZERO
var head_bobbing_current_intensity := 0.0
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index := 0.0
# State configuration
var STATE_CONFIG := {
	PlayerState.IDLE_STAND: { 
		speed = 0.0, 
		height = 0.0, 
		fov_multiplier = 1.0, 
		head_bobbing_speed = 0.0, 
		head_bobbing_intensity = 0.0 },
	PlayerState.IDLE_CROUCH: { 
		speed = 0.0, 
		height = CROUCH_DEPTH, 
		fov_multiplier = 0.95,
		head_bobbing_speed = 0.0, 
		head_bobbing_intensity = 0.0 },
	PlayerState.WALKING: { 
		speed = WALK_SPEED, 
		height = 0.0, 
		fov_multiplier = 1.0,
		head_bobbing_speed = HEAD_BOBBING_WALK_SPEED, 
		head_bobbing_intensity = HEAD_BOBBING_WALK_INTENSITY },
	PlayerState.SPRINTING: { 
		speed = SPRINT_SPEED, 
		height = 0.0, 
		fov_multiplier = 1.05, 
		head_bobbing_speed = HEAD_BOBBING_SPRINT_SPEED, 
		head_bobbing_intensity = HEAD_BOBBING_SPRINT_INTENSITY },
	PlayerState.CROUCHING: { 
		speed = CROUCH_SPEED, 
		height = CROUCH_DEPTH, 
		fov_multiplier = 0.95,
		head_bobbing_speed = HEAD_BOBBING_CROUCH_SPEED, 
		head_bobbing_intensity = HEAD_BOBBING_CROUCH_INTENSITY },
	PlayerState.AIR: { 
		speed = WALK_SPEED, 
		height = 0.0, 
		fov_multiplier = 1.0,
		head_bobbing_speed = 0.0, 
		head_bobbing_intensity = 0.0 }
}


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	handle_input(event)


func _physics_process(delta: float) -> void:
	handle_state_transition()
	handle_movement(delta)
	handle_camera_animation(delta)
	
	move_and_slide()


func handle_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if event is InputEventMouseMotion:
		handle_mouse_input(event)


func handle_mouse_input(event: InputEventMouseMotion) -> void:
	rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
	head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))


func handle_state_transition() -> void:
	var was_moving := input_direction != Vector2.ZERO
	var wants_crouch := Input.is_action_pressed("crouch")
	var wants_sprint := Input.is_action_pressed("sprint")
	var can_stand_up := !stand_up_check.is_colliding()
	
	if is_on_floor():
		current_state = PlayerState.AIR
		if wants_crouch:
			current_state = PlayerState.CROUCHING if was_moving else PlayerState.IDLE_CROUCH
		elif can_stand_up:
			if was_moving:
				current_state = PlayerState.SPRINTING if wants_sprint else PlayerState.WALKING
			else:
				current_state = PlayerState.IDLE_STAND
		last_ground_state = current_state
	else:
		current_state = PlayerState.AIR
	update_collision_shapes()


func update_collision_shapes() -> void:
	var should_crouch := current_state in [PlayerState.IDLE_CROUCH, PlayerState.CROUCHING]
	standing_collision.disabled = should_crouch
	crouching_collision.disabled = !should_crouch


func handle_movement(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_horizontal_movement(delta)


func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_multiplier := 1.5 if velocity.y < 0 else 1.0
		velocity += get_gravity() * delta * gravity_multiplier


func handle_jump() -> void:
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY


func handle_horizontal_movement(delta: float) -> void:
	input_direction = Input.get_vector("left", "right", "forward", "backwards")
	var target_direction = (transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	move_direction = move_direction.lerp(target_direction, delta * LERP_SPEED)
	
	var config: Dictionary
	
	if current_state == PlayerState.AIR:
		config = STATE_CONFIG[last_ground_state]
	else:
		config = STATE_CONFIG[current_state]
	
	var current_speed: float = config.speed
	
	
	if move_direction:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)


func handle_camera_animation(delta: float) -> void:
	var config_state = last_ground_state if current_state == PlayerState.AIR else current_state
	var config: Dictionary = STATE_CONFIG[config_state]
	var target_height: float = IDLE_HEIGHT + config.height
	var target_fov: float = BASE_FOV * config.fov_multiplier
	
	# Handle head position and FOV
	head.position.y = lerp(head.position.y, target_height, delta * LERP_SPEED)
	camera.fov = lerp(camera.fov, target_fov, delta * LERP_SPEED)
	
	# Handle head bobbing
	head_bobbing_current_intensity = config.head_bobbing_intensity
	
	if head_bobbing_current_intensity > 0 and input_direction != Vector2.ZERO and is_on_floor():
		# Apply head bobbing when moving
		head_bobbing_index += config.head_bobbing_speed * delta
		
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
