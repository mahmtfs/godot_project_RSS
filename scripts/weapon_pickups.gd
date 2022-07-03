extends RigidBody

export var weapon_name = ""
export var ammo = 10
onready var player_node
export(NodePath) onready var death_timer = get_node(death_timer) as Timer
export(NodePath) onready var transform_tween = get_node(transform_tween) as Tween
var exist = true
var puppet_transform = Transform()

func _ready():
	#print(Network.player_node)
	connect("sleeping_state_changed", self, "on_sleeping")

remote func server_delete_weapon_pickup():
	rpc("delete_weapon_pickup")

remotesync func delete_weapon_pickup():
	get_picked_up()

func get_picked_up():
	hide()
	set_physics_process(false)
	death_timer.start()

func get_thrown(player):
	player_node = player
	print(player_node)
	self.global_transform.origin = player_node.global_transform.origin
	self.global_transform.origin.y = player_node.global_transform.origin.y + 2
	self.global_transform.basis = player_node.global_transform.basis
	apply_central_impulse(-20*player_node.camera.global_transform.basis.z)

func _physics_process(delta):
	if Network.server or Network.client:
		if is_network_master():
			rpc_unreliable("update_state", self.global_transform)
		else:
			self.global_transform = puppet_transform
	if transform_tween.is_active():
		self.global_transform = puppet_transform

# When the rigidbody goes to sleeping state after being idle for sometime, it will be made static
func on_sleeping():
	mode = MODE_STATIC

puppet func update_state(p_transform):
	puppet_transform = p_transform
	#print(puppet_transform)
	transform_tween.interpolate_property(self, "global_transform", global_transform, Transform(p_transform.basis, p_transform.origin), 0.1)
	transform_tween.start()

func _on_DeathTimer_timeout():
	queue_free()
