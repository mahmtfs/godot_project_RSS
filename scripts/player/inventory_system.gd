extends Node

onready var slots = [null, null]
onready var weapon_manager = get_node("/root/Main/player/Weapon_Manager")
onready var weapon_pos = get_node("/root/Main/player/PlayerSkeleton/Skeleton/Weapon")
onready var player_node = get_parent()

var current_slot_pos = 0


func inventory_handle():
		#print("ooga")
	if Input.is_action_just_pressed("game_slot_1"):
		current_slot_pos = 0
		if weapon_pos.get_children():
			var to_del = weapon_pos.get_child(0)
			weapon_pos.remove_child(to_del)
			to_del = player_node.camera.get_child(0)
			player_node.camera.remove_child(to_del)
		if slots[current_slot_pos]:
			var weapon = "Pistol"
			var weapon_node = load("res://scenes/%s.tscn" % weapon).instance()
			var fps_hands = load("res://scenes/%s_reload.tscn" % weapon).instance()
			weapon_pos.add_child(weapon_node)
			fps_hands.get_node("AnimationPlayer").current_animation = "BasePose"
			player_node.camera.add_child(fps_hands)
	if Input.is_action_just_pressed("game_slot_2"):
		current_slot_pos = 1
		if weapon_pos.get_children():
			var to_del = weapon_pos.get_child(0)
			weapon_pos.remove_child(to_del)
			to_del = player_node.camera.get_child(0)
			player_node.camera.remove_child(to_del)
		if slots[current_slot_pos]:
			var weapon = "Pistol"
			var weapon_node = load("res://scenes/%s.tscn" % weapon).instance()
			var fps_hands = load("res://scenes/%s_reload.tscn" % weapon).instance()
			weapon_pos.add_child(weapon_node)
			fps_hands.get_node("AnimationPlayer").current_animation = "BasePose"
			player_node.camera.add_child(fps_hands)
	var weapon = "Pistol" if slots[current_slot_pos] else ""
	weapon_manager.weapon_handle(weapon)

func add_weapon(weapon_instance):
	if not slots[current_slot_pos]:
		slots[current_slot_pos] = weapon_instance
		var weapon = "Pistol"
		var fps_hands = load("res://scenes/%s_reload.tscn" % weapon).instance()
		var weapon_node = load("res://scenes/%s.tscn" % weapon).instance()
		weapon_pos.add_child(weapon_node)
		fps_hands.get_node("AnimationPlayer").current_animation = "BasePose"
		player_node.camera.add_child(fps_hands)
		print(slots)
	elif not slots[(current_slot_pos + 1) % 2]:
		slots[(current_slot_pos + 1) % 2] = weapon_instance
		print(slots)
	"""
	for i in range(slots.size()):
		if not slots[i]:
			slots[i] = weapon_instance
			ind = i
			break
	
	if current_slot_pos == ind:
		var weapon = "Pistol"
		var weapon_node = load("res://scenes/%s.tscn" % weapon).instance()
		weapon_pos.add_child(weapon_node)
	"""

func drop_weapon():
	if slots[current_slot_pos]:
		var to_del = weapon_pos.get_child(0)
		weapon_pos.remove_child(to_del)
		to_del = player_node.camera.get_child(0)
		player_node.camera.remove_child(to_del)
		slots[current_slot_pos] = null
		print(slots)

