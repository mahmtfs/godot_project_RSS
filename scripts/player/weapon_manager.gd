extends Node

export var weapon_node: NodePath
export var aim_target_node: NodePath

onready var inventory = {"primary": null, "secondary": null}
onready var weapon_types = ["Pistol"]
onready var timer = get_node("Timer")
onready var reset = true
onready var player_node = get_parent()

#var ammo = 10
var animationlength = 0.0
var timer_once_reset = false
var prev_anim = ""
var cur_animation = ""
var fired = false
var weapon = null
var interpolation_speed = 5
var sway_threshold = 10
var sway_lerp = 3
var sway_hor = Vector3(0, -0.2, 0)
var sway_ver = Vector3(-0.2, 0, 0)
var vec_compensation = 0.3
var random_num = RandomNumberGenerator.new()
var x_range = 3.0
var recoil_vec = Vector2(random_num.randf_range(-x_range, x_range), 0)


func _ready():
	random_num.randomize()

func _back_to_hold():
	if weapon:
		var anim_ref = player_node.anim
		var state_machine = anim_ref.tree_root
		var playback = anim_ref[player_node.playback]
		var state = playback.get_current_node()
		var anim_to_change = state_machine.get_node("%s" % state).get_node("Weapon")
		var cur_animation = "%s_Hold" % weapon.weapon_name
		var hands = player_node.camera.get_child(0)
		if weapon.ammo:
			hands.get_node("AnimationPlayer").current_animation = "BasePose"
		else:
			hands.get_node("AnimationPlayer").current_animation = "Empty_Pose"
		anim_to_change.animation = cur_animation
		recoil_vec = Vector2(0, 0)
		var rot_vec = (Vector3(0, recoil_vec.x, 0) + Vector3(recoil_vec.y, 0, 0))
		hands.rotation = hands.rotation.linear_interpolate(rot_vec, 5 * get_process_delta_time())
		

func start_timer(animationlength):
	timer.set_wait_time(animationlength)
	timer.start()

func weapon_handle(weapon_node):
	weapon = weapon_node
	var anim_ref = player_node.anim
	var state_machine = anim_ref.tree_root
	var playback = anim_ref[player_node.playback]
	var state = playback.get_current_node()
	if weapon:
		var hands = player_node.camera.get_child(0)
		var from = player_node.camera.global_transform.origin
		var to = player_node.camera.global_transform.origin - player_node.camera.global_transform.basis.z.normalized() * 1000.0
		var space_state = player_node.space_state
		var collision = space_state.intersect_ray(from, to, [owner], 1)
		sway(hands)
		if collision:
			#hands.look_at(collision.position, hands.global_transform.basis.y)
			var original_scale = hands.transform.basis.get_scale()
			var target_position = collision.position
			var new_transform = hands.global_transform.looking_at(target_position, hands.global_transform.basis.y)
			#hands.looking_at(collision.position, Vector3.UP)
			hands.global_transform = hands.global_transform.interpolate_with(new_transform, interpolation_speed * get_physics_process_delta_time())
			hands.scale = original_scale
		else:
			var aim_target = get_node(aim_target_node)
			var original_scale = hands.transform.basis.get_scale()
			var target_position = aim_target.global_transform.origin
			var new_transform = hands.global_transform.looking_at(target_position, hands.global_transform.basis.y)
			#hands.looking_at(collision.position, Vector3.UP)
			hands.global_transform = hands.global_transform.interpolate_with(new_transform, interpolation_speed * get_physics_process_delta_time())
			hands.scale = original_scale
			"""
			var aim_target = get_node(aim_target_node)
			hands.look_at(aim_target.global_transform.origin, hands.global_transform.basis.y)
			"""
		
		var anim_to_change = state_machine.get_node("%s" % state).get_node("Weapon")
		if state != prev_anim:
			if not reset:
				anim_to_change.animation = cur_animation
				anim_ref.set("parameters/%s/Seek/seek_position" % state,  animationlength - timer.time_left)
				anim_ref.set("parameters/%s/Blend2/blend_amount" % state,  1)
		if Input.is_action_just_pressed("game_ctrl"):
			if weapon.ammo:
				weapon.ammo = 0
			else:
				weapon.ammo = 1
		if Input.is_action_just_pressed("game_fire") and timer.time_left < 0.3 and weapon.ammo:
			hands.get_node("AnimationPlayer").current_animation = "BasePose"
			recoil_vec = Vector2(random_num.randf_range(-x_range, x_range), 0)
			var rot_vec = (Vector3(0, recoil_vec.x, 0) + Vector3(recoil_vec.y, 0, 0))
			if weapon.ammo == 1:
				hands.get_node("AnimationPlayer").current_animation = "Last_Shot"
			else:
				hands.get_node("AnimationPlayer").current_animation = "Fire"
			reset = false
			cur_animation = "%s_Fire" % weapon.weapon_name
			anim_to_change.animation = cur_animation
			animationlength = get_node(anim_ref.anim_player).get_animation(cur_animation).length
			start_timer(animationlength)
			hands.rotation = hands.rotation.linear_interpolate(rot_vec, 1 * get_process_delta_time())
			weapon.ammo -= 1
		elif Input.is_action_just_pressed("game_reload") and reset and weapon.ammo < 10:	
			reset = false
			if weapon.ammo:	
				hands.get_node("AnimationPlayer").current_animation = "Swap_Mag"
				cur_animation = "%s_Swap_Mag" % weapon.weapon_name
				anim_to_change.animation = cur_animation
				animationlength = get_node(anim_ref.anim_player).get_animation(cur_animation).length
				start_timer(animationlength)
			else:
				hands.get_node("AnimationPlayer").current_animation = "Pull_Slide"
				cur_animation = "%s_Pull_Slide" % weapon.weapon_name
				anim_to_change.animation = cur_animation
				animationlength = get_node(anim_ref.anim_player).get_animation(cur_animation).length
				start_timer(animationlength)
			weapon.ammo = weapon.ammo_capacity
		elif timer_once_reset and reset:
			_back_to_hold()
		if reset:
			anim_ref.set("parameters/%s/Seek/seek_position" % state,  -1)
		else:
			anim_ref.set("parameters/%s/Seek/seek_position" % state,  animationlength - timer.time_left)
		anim_ref.set("parameters/%s/Blend2/blend_amount" % state,  1)
	else:
		anim_ref.set("parameters/%s/Blend2/blend_amount" % state,  0)
	prev_anim = state

func sway(hands):
	if player_node.m_move != null:
		if abs(player_node.m_move.x) > sway_threshold or abs(player_node.m_move.y) > sway_threshold:
			var rot_vec = -(Vector3(0, player_node.m_move.x, 0) + Vector3(player_node.m_move.y, 0, 0)).normalized()
			hands.rotation = hands.rotation.linear_interpolate(rot_vec * vec_compensation, sway_lerp * get_process_delta_time())
		#if abs(player_node.m_move.y) > sway_threshold:
		#	hands.rotation = hands.rotation.linear_interpolate(sway_ver * sign(player_node.m_move.y), sway_lerp * get_process_delta_time())
		
func timer_timeout():
	timer_once_reset = true
	reset = true
	timer.stop()
