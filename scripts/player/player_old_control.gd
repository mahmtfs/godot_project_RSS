extends KinematicBody

export var mouse_sensitivity = 0.1
export var player_skeleton : NodePath
export var body_target: NodePath

onready var camera = $Head/Camera
onready var head = $Head
onready var target_dir = -self.global_transform.basis.z

# Movement
var velocity = Vector3.ZERO
var current_vel = Vector3.ZERO
var dir = Vector3.ZERO

export var walk_speed = 10
export var run_speed = 20
export var acceleration = 15.0

# Jump
export var gravity = -40.0
export var jump_speed = 15
export var jump_counter = 0
export var air_acceleration = 9.0



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _process(delta):
	window_activity()



func _physics_process(delta):
	var player = get_node(player_skeleton)
	var target = get_node(body_target)
	var interpolation_speed = 10
	var back_pressed = false
	# Get the input directions
	dir = Vector3.ZERO
	if Input.is_action_pressed("game_forward"):
		dir -= self.global_transform.basis.z
	if Input.is_action_pressed("game_backward"):
		dir += self.global_transform.basis.z
		back_pressed = true
	else:
		back_pressed = false
	if Input.is_action_pressed("game_right"):
		dir += self.global_transform.basis.x
	if Input.is_action_pressed("game_left"):
		dir -= self.global_transform.basis.x
	# Normalizing the input directions
	if dir != Vector3.ZERO:
		target_dir = dir
		if back_pressed:
			target_dir *= -1
	dir = dir.normalized()
	
	if abs(rad2deg(self.global_transform.basis.z.signed_angle_to(player.global_transform.basis.z, self.global_transform.basis.y))) >= 100:
		target_dir = -self.global_transform.basis.z
	target_dir = target_dir.normalized()
	
	# Apply gravity
	var gravity_resistance = get_floor_normal() if is_on_floor() else Vector3.UP
	velocity += gravity_resistance * gravity * delta
	
	if is_on_floor():
		jump_counter = 0
	
	# Jump
	if Input.is_action_just_pressed("game_jump") and jump_counter < 1:
		jump_counter += 1
		velocity.y = jump_speed
	
	# Set speed and target velocity
	var speed = run_speed if Input.is_action_pressed("game_run") else walk_speed
	var target_vel = dir * speed
	
	# Smooth out the player's movement
	var acceleration = acceleration if is_on_floor() else air_acceleration
	current_vel = current_vel.linear_interpolate(target_vel, acceleration * delta)
	
	velocity.x = current_vel.x
	velocity.z = current_vel.z
	
	velocity = move_and_slide(velocity, Vector3.UP, true, 4, deg2rad(45))
	target.global_transform.origin = (self.get_transform().origin + target_dir)
	var target_position  = target.transform.origin
	var new_transform = player.transform.looking_at(target_position, Vector3.UP)
	player.transform  = player.transform.interpolate_with(new_transform, interpolation_speed * delta)
	#player.look_at(self.get_transform().origin + dir, Vector3.UP)
	print(rad2deg(self.global_transform.basis.z.signed_angle_to(player.global_transform.basis.z, self.global_transform.basis.y)))

func _input(event):
	if event is InputEventMouseMotion:
		# Rotates the view vertically
		head.rotate_x(deg2rad(event.relative.y * mouse_sensitivity * -1))
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -75, 75)
		# Rotates the view horizontally
		self.rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))


# To show/hide the cursor
func window_activity():
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
