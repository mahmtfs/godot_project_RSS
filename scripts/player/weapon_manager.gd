extends Node

export var weapon_node: NodePath

onready var inventory = {"primary": null, "secondary": null}
onready var weapon_types = ["Pistol"]
onready var timer = get_node("Timer")
onready var reset = true
onready var player_node = get_parent()


var ammo = 10
var elapsed = 0.0
var animationlength = 0.0
var timer_once_reset = false
var prev_anim = ""
var cur_animation = ""
var fired = false
var weapon = ""

func _back_to_hold():
	var anim_ref = player_node.anim
	var state_machine = anim_ref.tree_root
	var playback = anim_ref[player_node.playback]
	var state = playback.get_current_node()
	var anim_to_change = state_machine.get_node("%s" % state).get_node("Weapon")
	var cur_animation = "%s_Hold" % weapon
	var hands = player_node.camera.get_child(0)
	if ammo:
		hands.get_node("AnimationPlayer").current_animation = "BasePose"
	else:
		hands.get_node("AnimationPlayer").current_animation = "Empty_Pose"
	anim_to_change.animation = cur_animation

func start_timer(animationlength):
	timer.set_wait_time(animationlength)
	timer.start()

func weapon_handle(weapon_name):
	weapon = weapon_name
	var anim_ref = player_node.anim
	var state_machine = anim_ref.tree_root
	var playback = anim_ref[player_node.playback]
	var state = playback.get_current_node()
	if weapon:
		var hands = player_node.camera.get_child(0)
		var anim_to_change = state_machine.get_node("%s" % state).get_node("Weapon")
		if state != prev_anim:
			if not reset:
				anim_to_change.animation = cur_animation
				anim_ref.set("parameters/%s/Seek/seek_position" % state,  animationlength - timer.time_left)
				anim_ref.set("parameters/%s/Blend2/blend_amount" % state,  1)
		if Input.is_action_just_pressed("game_ctrl"):
			if ammo:
				ammo = 0
			else:
				ammo = 1
		if Input.is_action_just_pressed("game_fire") and timer.time_left < 0.3 and ammo:
			hands.get_node("AnimationPlayer").current_animation = "BasePose"
			if ammo == 1:
				hands.get_node("AnimationPlayer").current_animation = "Last_Shot"
			else:
				hands.get_node("AnimationPlayer").current_animation = "Fire"
			
			reset = false
			cur_animation = "%s_Fire" % weapon
			anim_to_change.animation = cur_animation
			animationlength = get_node(anim_ref.anim_player).get_animation(cur_animation).length
			start_timer(animationlength)
			ammo -= 1
		elif Input.is_action_just_pressed("game_reload") and reset and ammo < 10:	
			reset = false
			if ammo:	
				hands.get_node("AnimationPlayer").current_animation = "Swap_Mag"
				cur_animation = "%s_Swap_Mag" % weapon
				anim_to_change.animation = cur_animation
				animationlength = get_node(anim_ref.anim_player).get_animation(cur_animation).length
				start_timer(animationlength)
			else:
				hands.get_node("AnimationPlayer").current_animation = "Pull_Slide"
				cur_animation = "%s_Pull_Slide" % weapon
				anim_to_change.animation = cur_animation
				animationlength = get_node(anim_ref.anim_player).get_animation(cur_animation).length
				start_timer(animationlength)
			ammo = 10
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

func timer_timeout():
	timer_once_reset = true
	reset = true
	timer.stop()
