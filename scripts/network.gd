extends Node

# Port must be open in router settings
const MAX_PLAYERS = 32
const DEFAULT_PORT = 27015

var world_good = false

var server_map = null
var client_map = null

var player_list = {}

# To use a background server download the server export template without graphics and audio from:
# https://godotengine.org/download/server
# And choose it as a custom template upon export
export var background_server : bool = false

# Preload a character and controllers
# Character is a node which we control by the controller node
# This way we can extend the Controller class to create an AI controller
# Peer controller represents other players in the network
onready var player_scene = preload("res://scenes/Player.tscn")
onready var client_scene = preload("res://scenes/client.tscn")
onready var peer_scene = preload("res://scenes/peer.tscn")

func _ready():
	# If we are exporting this game as a server for running in the background
	if background_server:
		# Just create server
		create_server("res://scenes/empty.tscn", DEFAULT_PORT)
		# To keep it simple we are creating an uncontrollable server's character to prevent errors
		# TO-DO: Create players upon reading configuration from the server

# When Connect button is pressed
func join_server(ip, port):
	# Connect network events
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	
	# Set up an ENet instance
	var net = NetworkedMultiplayerENet.new()
	net.create_client(ip, port)
	get_tree().set_network_peer(net)
	
	# Upon successful connection get the unique network ID
	# This ID is used to name the character node so the network can distinguish the characters
	var id = get_tree().get_network_unique_id()
	
	#yield program until we get our map name from server
	#yield()
	
	#load our map
	var scene = load("res://scenes/Qodot.tscn")
	
	# Create a player
	if get_tree().change_scene_to(scene) == OK:
		# Create our player, 1 is a reference for a host/server
		print("We connected")
		call_deferred("create_player", id, false)

func _on_peer_connected(id):
	# When other players connect a character and a child player controller are created
	#rset_id(id, "client_map", server_map)
	#rpc_id(id, "resume")
	
	create_player(id, true)

func _on_peer_disconnected(id):
	# Remove unused nodes when player disconnects
	remove_player(id)

func _on_connected_to_server():
	print("Connected to server.")

func _on_connection_failed():
	# Upon failed connection reset the RPC system
	get_tree().set_network_peer(null)
	print("Connection failed")

func _on_server_disconnected():
	# If server disconnects just reload the game
	var _reloaded = get_tree().reload_current_scene()

func create_server(map, port):
	# Connect network events
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	# Set up an ENet instance
	var net = NetworkedMultiplayerENet.new()
	net.create_server(port, MAX_PLAYERS - 1)
	get_tree().set_network_peer(net)
	
	server_map = map
	var scene = load(server_map)
	if get_tree().change_scene_to(scene) == OK:
		# Create our player, 1 is a reference for a host/server
		create_player(1, false)
		
	print("Server created on port ", port,". Playing on ", server_map)

func create_player(id, is_peer):
	# Create a player with a client or a peer controller attached
	var controller : Controller
	# Check whether we are creating a client or a peer controller
	if is_peer:
		# Peer controller represents other connected players on the network
		controller = peer_scene.instance()
	else:
		# Client controller is our input which controls the player node
		controller = client_scene.instance()
	# Instantiate the character
	var player = player_scene.instance()
	# Attach the controller to the character
	player.add_child(controller)
	# Set the controller's name for easier reference by the player
	controller.name = "controller"
	# Set the character's name to a given network id for synchronization
	player.name = str(id)
	#Set authority over themselves
	player.set_network_master(id)
	
	
	#create a new node as a parent to our characters
	if get_node_or_null("/root/characters") == null:
		var char_node = Node.new()
		char_node.name = "characters"
		get_node("/root/").add_child(char_node)
		
	# Add the player to this (main) scene
	get_node("/root/characters").call_deferred("add_child", player)

remotesync func send_player_data(id, player_info):
	player_list[id] = player_info

func remove_player(id):
	print("Player ", get_node("/root/characters/" + str(id)).player_info["name"], " disconnected")
	# Remove unused characters
	get_node("/root/characters/" + str(id)).call_deferred("free")
