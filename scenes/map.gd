extends Spatial

var player = preload("res://scenes/player.tscn")

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	Global.connect("instance_player", self, "_instance_player")
	Global.connect("instance_object", self, "_instanciate_weapon_pickup")
	
	if get_tree().network_peer != null:
		Global.emit_signal("toggle_network_setup", false)

func _instance_player(id):
	var player_instance = player.instance()
	player_instance.set_network_master(id)
	player_instance.name = str(id)
	add_child(player_instance)
	player_instance.global_transform.origin = Vector3(0, 10, 0)

func _player_connected(id):
	print("Player %s has connected to the server." % str(id))
	_instance_player(id)
	#_delete_instance("Pistol_pickup")

func _player_disconnected(id):
	print("Player %s has disconnected from the server." % str(id))
	
	if has_node(str(id)):
		get_node(str(id)).free()

remote func _instanciate_weapon_pickup(weapon_name, weapon_pickup_name, player_name):
	var player_node = get_node(player_name)
	var weapon_pickup = load("res://scenes/weapons/%s_pickup.tscn" % weapon_name).instance()
	add_child(weapon_pickup)
	weapon_pickup.name = weapon_pickup_name
	weapon_pickup.get_thrown(player_node)
