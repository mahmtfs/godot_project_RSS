extends Control

func _ready():
	Global.connect("toggle_network_setup", self, "_toggle_network_setup")

func _on_IpAdress_text_changed(new_ip):
	Network.ip_adress = new_ip


func _on_Host_pressed():
	Network.create_server()
	hide()
	
	Global.emit_signal("instance_player", get_tree().get_network_unique_id())

func _on_Join_pressed():
	Network.join_server()
	hide()
	
	Global.emit_signal("instance_player", get_tree().get_network_unique_id())

func _toggle_network_setup(visible_toggle):
	visible = visible_toggle
