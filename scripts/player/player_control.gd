extends KinematicBody

export var mouse_sensitivity = 0.1
export var player_skeleton : NodePath
export var skeleton: NodePath
export var body_target: NodePath
export var animation_tree: NodePath

onready var camera = $Head/Camera
onready var head = $Head
onready var target_dir = -self.global_transform.basis.z
onready var anim = get_node(animation_tree)
onready var sneak = false
onready var back_pressed = false
onready var snap_vector = Vector3.ZERO

# Movement
var velocity = Vector3.ZERO
var current_vel = Vector3.ZERO
var dir = Vector3.ZERO

export var walk_speed = 20
export var sneak_speed = 10
export var acceleration = 15.0

# Jump
export var gravity = -40.0
export var jump_speed = 15
export var jump_counter = 0
export var air_acceleration = 9.0

const playback = "parameters/playback"
const spine_bone_id = 1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _process(delta):
	window_activity()



func _physics_process(delta):
	var player = get_node(player_skeleton)
	"""
	target.global_transform.origin = (self.get_transform().origin + target_dir)
	var target_position  = target.transform.origin
	var new_transform = player.transform.looking_at(target_position, Vector3.UP)
	player.transform  = player.transform.interpolate_with(new_transform, interpolation_speed * delta)
	"""
	
	var target = get_node(body_target)
	var interpolation_speed = 10
	sneak = true if Input.is_action_pressed("game_shift") and is_on_floor() else false
	# Get the input directions
	dir = Vector3.ZERO
	if Input.is_action_pressed("game_forward"):
		dir -= self.global_transform.basis.z
		if sneak:
			anim[playback].travel("Sneaking")
		else:
			anim[playback].travel("Walking")
	if Input.is_action_pressed("game_backward"):
		dir += self.global_transform.basis.z
		if sneak:
			anim[playback].travel("Sneaking_Back")
		else:
			anim[playback].travel("Walking_Back")
		back_pressed = true
	else:
		back_pressed = false
	if Input.is_action_pressed("game_right"):
		dir += self.global_transform.basis.x
		if sneak and not back_pressed:
			anim[playback].travel("Sneaking")
		elif not back_pressed:
			anim[playback].travel("Walking")
	if Input.is_action_pressed("game_left"):
		dir -= self.global_transform.basis.x
		if sneak and not back_pressed:
			anim[playback].travel("Sneaking")
		elif not back_pressed:
			anim[playback].travel("Walking")
	# Normalizing the input directions
	if dir != Vector3.ZERO:
		target_dir = dir
		if back_pressed:
			target_dir *= -1
	else:
		anim[playback].travel("Idle")
	dir = dir.normalized()
	
	if abs(rad2deg(self.global_transform.basis.z.signed_angle_to(player.global_transform.basis.z, self.global_transform.basis.y))) >= 100:
		target_dir = -self.global_transform.basis.z
	target_dir = target_dir.normalized()
	
	# Apply gravity
	var gravity_resistance = get_floor_normal() if is_on_floor() else Vector3.UP
	velocity += gravity_resistance * gravity * delta
	
	if is_on_floor():
		jump_counter = 0
		snap_vector = -get_floor_normal()
		# Jump
		if Input.is_action_just_pressed("game_jump") and jump_counter < 1:
			snap_vector = Vector3.ZERO
			jump_counter += 1
			velocity.y = jump_speed
			anim[playback].travel("Hop")
	
	
	
	if not is_on_floor():
		anim[playback].travel("Mid_Air")
	
	# Set speed and target velocity
	var speed = sneak_speed if Input.is_action_pressed("game_shift") and is_on_floor() else walk_speed
	var target_vel = dir * speed
	
	# Smooth out the player's movement
	var acceleration = acceleration if is_on_floor() else air_acceleration
	current_vel = current_vel.linear_interpolate(target_vel, acceleration * delta)
	
	velocity.x = current_vel.x
	velocity.z = current_vel.z
	
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, deg2rad(45))
	target.global_transform.origin = (self.get_transform().origin + target_dir)
	var target_position  = target.transform.origin
	var new_transform = player.transform.looking_at(target_position, Vector3.UP)
	player.transform  = player.transform.interpolate_with(new_transform, interpolation_speed * delta)
	#player.look_at(self.get_transform().origin + dir, Vector3.UP)
	
	var bones = get_node(skeleton)
	var bone_transform = bones.get_bone_global_pose_no_override(spine_bone_id)
	var parent_id = bones.get_bone_parent(spine_bone_id)
	var parent_transform = bones.get_bone_global_pose_no_override(parent_id)
	#print(-camera.get_global_transform().basis.z)
	#print()
	bone_transform = bone_transform.rotated(Vector3.UP, player.get_global_transform().basis.z.signed_angle_to(self.transform.basis.z, Vector3.UP))
	#print(deg2rad(player.transform.basis.z.signed_angle_to(self.get_global_transform().basis.z, Vector3.UP)) / 180)
	#bone_transform = bone_transform.rotated(Vector3.UP, rad2deg(target_dir.angle_to(-camera.get_global_transform().basis.z)))
	bone_transform.origin.x = parent_transform.origin.x
	bones.set_bone_global_pose_override(spine_bone_id, bone_transform, 1.0, true)
	
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
