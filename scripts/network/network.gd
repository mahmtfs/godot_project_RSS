extends Node

const DEFAULT_PORT = 8080
const MAX_CLIENTS = 2

var server = null
var client = null

var ip_adress = "127.0.0.1"

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("network_peer_connected", self, "_player_connected")

func create_server():
	print("Creating server...")
	
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)

func join_server():
	print("Joining server...")
	
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_adress, DEFAULT_PORT)
	get_tree().set_network_peer(client)
	
func _connected_to_server():
	print("Successfully connected to the server.")

func _server_disconnected():
	reset_network_connection()
	print("Disconnected from the server.")
	
func _connection_failed():
	reset_network_connection()
	print("Connection failed!")

func _player_connected(id):
	print("Player %s has connected to the server." % str(id))

func reset_network_connection():
	if get_tree().has_network_peer():
		get_tree().network_peer = null
