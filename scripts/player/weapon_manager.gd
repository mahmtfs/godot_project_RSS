extends Spatial

export var weapon: NodePath

var armed : bool

func _physics_process(delta):
	if weapon:
		armed = true
	else:
		armed = false
	#print(armed)
