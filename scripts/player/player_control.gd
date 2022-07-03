extends KinematicBody

export var mouse_sensitivity = 0.1
export var player_skeleton : NodePath
export var skeleton: NodePath
export var body_target: NodePath
export var animation_tree: NodePath
export var chest_pivot: NodePath

onready var anim = get_node(animation_tree)
onready var camera = $Head/Camera
onready var head = $Head
onready var target_dir = -self.global_transform.basis.z
onready var sneak = false
onready var back_pressed = false
onready var snap_vector = Vector3.ZERO
onready var x_pivot = get_node(chest_pivot)
onready var m_move

export(NodePath) onready var model = get_node(model) as MeshInstance
export(NodePath) onready var network_tick_rate = get_node(network_tick_rate) as Timer
export(NodePath) onready var movement_tween = get_node(movement_tween) as Tween
#onready var weapon_pos = get_node("PlayerSkeleton/Skeleton/Weapon")

# Weapon Manager
#onready var weapon_manager = get_node("Weapon_Manager")
onready var inventory = get_node("Inventory")
onready var space_state = get_world().direct_space_state

# Movement
var velocity = Vector3.ZERO
var current_vel = Vector3.ZERO
var dir = Vector3.ZERO
var move = false

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
const chest_bone_id = 2
const pistol_offset = 1
const spine_offset = 0.3 

onready var bones = get_node(skeleton)
onready var spine_transform = bones.get_bone_global_pose_no_override(spine_bone_id)
var spine_transform_x
var spine_transform_y

onready var player = get_node(player_skeleton)

var puppet_position = Vector3()
var puppet_velocity = Vector3()
var puppet_rotation = Vector2()
var puppet_spine_transform = Transform()
var puppet_player_transform = Transform()
var puppet_animation = ""
var puppet_camera_transform = Transform()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = is_network_master()
	model.visible = !is_network_master()
	

func _process(delta):
	window_activity()

func _physics_process(delta):
	# Apply gravity
	var gravity_resistance = get_floor_normal() if is_on_floor() else Vector3.UP
	velocity += gravity_resistance * gravity * delta
	
	if is_network_master():
		player = get_node(player_skeleton)
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
		
		#velocity += gravity_resistance * gravity * delta
		
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
		
		#velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, deg2rad(45))
		target.global_transform.origin = (self.get_transform().origin + target_dir)
		var target_position  = target.transform.origin
		var new_transform = player.transform.looking_at(target_position, Vector3.UP)
		player.transform  = player.transform.interpolate_with(new_transform, interpolation_speed * delta)
		
		spine_transform = bones.get_bone_global_pose_no_override(spine_bone_id)
		var spine_parent_id = bones.get_bone_parent(spine_bone_id)
		var spine_parent_transform = bones.get_bone_global_pose_no_override(spine_parent_id)
		spine_transform = spine_transform.rotated(Vector3.RIGHT, x_pivot.transform.basis.z.signed_angle_to(head.transform.basis.z, Vector3.RIGHT))
		spine_transform.origin = spine_parent_transform.origin
		spine_transform.origin.y += spine_offset
		#bones.set_bone_global_pose_override(spine_bone_id, spine_transform, 1.0, true)
		
		spine_transform = spine_transform.rotated(Vector3.UP, player.get_global_transform().basis.z.signed_angle_to(self.transform.basis.z, Vector3.UP))
		spine_transform.origin.x = spine_parent_transform.origin.x
		#bones.set_bone_global_pose_override(spine_bone_id, spine_transform, 1.0, true)
		
		#Weapon equip
		if Input.is_action_just_pressed("game_drop"):
			inventory.drop_weapon(name)
		
		process_weapon_pickup()
		
		inventory.inventory_handle()
	else:
		global_transform.origin = puppet_position
		
		velocity.x = puppet_velocity.x
		velocity.z = puppet_velocity.z
		camera.global_transform = puppet_camera_transform
		player.global_transform = puppet_player_transform
		#rotation.y = puppet_rotation.y
		head.rotation.x = puppet_rotation.x 
		bones.set_bone_global_pose_override(spine_bone_id, puppet_spine_transform, 1.0, true)
		#bones.set_bone_global_pose_override(spine_bone_id, puppet_spine_transform_y, 1.0, true)
		anim[playback].travel(puppet_animation)

	if !movement_tween.is_active():
		velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, deg2rad(45))
		
puppet func update_state(p_position, p_velocity, p_rotation, p_animation, p_spine_transform, p_player_transform, p_camera_transform):
	puppet_position = p_position
	puppet_velocity = p_velocity
	puppet_rotation = p_rotation
	puppet_animation = p_animation
	puppet_spine_transform = p_spine_transform
	puppet_player_transform = p_player_transform
	puppet_camera_transform = p_camera_transform
	#puppet_spine_transform_x = p_spine_transform_x
	#puppet_spine_transform_y = p_spine_transform_y
	movement_tween.interpolate_property(self, "global_transform", global_transform, Transform(global_transform.basis, p_position), 0.1)
	movement_tween.start()
	
func _input(event):
	if is_network_master():
		if event is InputEventMouseMotion:
			# Rotates the view vertically
			head.rotate_x(deg2rad(event.relative.y * mouse_sensitivity * -1))
			head.rotation_degrees.x = clamp(head.rotation_degrees.x, -75, 75)
			# Rotates the view horizontally
			self.rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))
			m_move = -event.relative

func process_weapon_pickup():
	var from = camera.global_transform.origin
	var to = camera.global_transform.origin - camera.global_transform.basis.z.normalized() * 5.0
	space_state = get_world().direct_space_state
	var collision = space_state.intersect_ray(from, to, [owner], 1)
	
	if collision:
		var body = collision["collider"]
		if body.has_method("get_picked_up"):
			if Input.is_action_just_pressed("game_interact"):
				if not inventory.is_full():
					inventory.add_weapon(body)


# To show/hide the cursor
func window_activity():
	if is_network_master():
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_NetworkTickRate_timeout():
	if is_network_master():
		rpc_unreliable("update_state",
		 global_transform.origin,
		 velocity,
		 Vector2(head.rotation.x, rotation.y),
		 anim[playback].get_current_node(),
		 spine_transform,
		 player.global_transform,
		 camera.global_transform)
	else:
		network_tick_rate.stop()
