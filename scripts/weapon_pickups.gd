extends RigidBody

export var weapon_name = ""
export var ammo = 10

onready var player_node = get_tree().get_root().get_node("Main/player")

func _ready():
	connect("sleeping_state_changed", self, "on_sleeping")

func get_picked_up():
	self.queue_free()

func get_thrown():
	#print(self.ammo)
	self.global_transform.origin = player_node.global_transform.origin
	self.global_transform.origin.y = player_node.global_transform.origin.y + 2
	self.global_transform.basis = player_node.global_transform.basis
	apply_central_impulse(-20*player_node.camera.global_transform.basis.z)

# When the rigidbody goes to sleeping state after being idle for sometime, it will be made static
func on_sleeping():
	mode = MODE_STATIC
