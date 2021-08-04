extends Node

# Port must be open in router settings
const MAX_PLAYERS = 32
const DEFAULT_PORT = 27015

var world_good = false

var server_map = null
var client_map = null

var world_state = null

var player_list = {}

var cheats = false

# To use a background server download the server export template without graphics and audio from:
# https://godotengine.org/download/server
# And choose it as a custom template upon export
export var background_server : bool = false

export var interp = true
export var interp_scale = 50
export var tick_rate = 128

# Preload a character and controllers
# Character is a node which we control by the controller node
# This way we can extend the Controller class to create an AI controller
# Peer controller represents other players in the network
var player_scene = preload("res://scenes/Player.tscn")
var client_scene = preload("res://scenes/client.tscn")
var peer_scene = preload("res://scenes/peer.tscn")
var bot_scene = preload("res://scenes/bot.tscn")

func _ready():
	Console.connect_node(self)
	player_scene.set_local_to_scene(true)
	client_scene.set_local_to_scene(true)
	peer_scene.set_local_to_scene(true)
	bot_scene.set_local_to_scene(true)
	
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _on_peer_connected(id):
	# When other players connect a character and a child player controller are created
	#rset_id(id, "client_map", server_map)
	#rpc_id(id, "resume")
	
	create_player(id, true)

func _on_peer_disconnected(id):
	# Remove unused nodes when player disconnects
	remove_player(id)

func _on_connected_to_server():
	console_msg("Connected to server.")

func _on_connection_failed():
	# Upon failed connection reset the RPC system
	get_tree().set_network_peer(null)
	print("Connection failed")

func _on_server_disconnected():
	get_tree().change_scene("res://scenes/Control/Menu.tscn")
	get_node("/root/characters").queue_free()
	
	Console.emit_signal("open_console")
	console_msg("Connection to the server ended.")

# When Connect button is pressed
func join_server(ip, port):
	# Set up an ENet instance
	var net = NetworkedMultiplayerENet.new()
	net.create_client(ip, port)
	get_tree().set_network_peer(net)
	
	# Upon successful connection get the sunique network ID
	# This ID is used to name the character node so the network can distinguish the characters
	var id = get_tree().get_network_unique_id()
	
	#yield program until we get our map name from server
	#yield()
	
	#load our map
	client_map = load("res://scenes/Qodot.tscn")
	
	# Create a player
	if get_tree().change_scene_to(client_map) == OK:
		# Create our player, 1 is a reference for a host/server
		call_deferred("create_player", id, false)

func create_server(map, server_name, port):
	# Connect network events
	
#	var command = ["-n", "1", "-w", "3", "127.0.0.1"]
#	if OS.execute("ping", command, true) != 1:
#		console_msg("Server already running!")
#		return
	
	# Set up an ENet instance
	var net = NetworkedMultiplayerENet.new()
	net.create_server(port, MAX_PLAYERS - 1)
	get_tree().set_network_peer(net)
	
	server_map = load(map)
	if get_tree().change_scene_to(server_map) == OK:
		# Create our player, 1 is a reference for a host/server
		call_deferred("create_player", 1, false)
		
		#collect world state on start up
		world_state = sync_world_server(get_tree().get_root(), {})
		
	print("Server ", server_name, " created on port ", port,". Playing on ", map)

# get world state from server
func sync_world_server(node, node_list):
	for n in node.get_children():
		if n.get_child_count() > 0:
			sync_world_server(n, node_list)
		if n is RigidBody:
			node_list[str(n.get_path())] = n.global_transform
			
	return node_list

# apply world state from server to client if it differs	
mastersync func sync_world_client(node_list, delta):
	for n in node_list.keys():
		var target = get_node_or_null(n)
		if target != null and target.global_transform != node_list[n]:
			target.translation = target.translation.linear_interpolate(node_list[n].origin, delta)
			target.rotation = target.rotation.linear_interpolate(node_list[n].basis.get_euler(), delta)

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
	#This is a call deferred to spawn in the player during idle time so that we 
	#can find spawn points in the map
	get_node("/root/characters").add_child(player)
	
remotesync func create_bot():
	var controller = bot_scene.instance()
	# Instantiate the character
	var player = player_scene.instance()
	# Attach the controller to the character
	player.add_child(controller)
	# Set the controller's name for easier reference by the player
	controller.name = "controller"
	
	if get_node_or_null("/root/characters") == null:
		var char_node = Node.new()
		char_node.name = "characters"
		get_node("/root/").add_child(char_node)
		
	player.name = "bot"
	get_node("/root/characters").add_child(player)
	
func remove_player(id):
	var player = str(id)
	
	print("Player ", player_list[player]["name"], " disconnected")
	# Remove unused characters
	get_node("/root/characters/" + player).call_deferred("free")
	#erase player from player list
	player_list.erase(player)
	

remotesync func send_player_data(id, player_info):
	player_list[id] = player_info
	
remotesync func console_msg(text):
	print(text)
	Console.print(text)
	
remotesync func change_cheats(status):
	if get_tree().get_rpc_sender_id() == 1:
		cheats = status
		console_msg("cheats set to " + str(cheats))
	else:
		print("You are not the server master.")
		Console.print("You are not the server master.")

remotesync func kick_player(player_name):
	for i in player_list:
		if player_list[i]["name"] == player_name:
			remove_player(i)
			return
		elif player_list[i]["name"] == player_list["1"]["name"]:
			print("Cannot kick server owner!")
			Console.print("Cannot kick server owner!")
		else:
			print("Player ", player_name, " not found.")
			Console.print("Player " + player_name + " not found.")
			return

remotesync func send_file(file_path):
	var file = File.new()
	file.open(file_path, File.READ)
	var content = file.get_as_text()
	
func _process(delta):
	if player_list.size() > 1:
		yield(get_tree().create_timer(1/tick_rate), "timeout")
		rpc("sync_world_client", sync_world_server(get_tree().get_root(), {}), delta * interp_scale)
	
const bot_add_desc = "Add a multiplayer bot"
const bot_add_help = "Add a multiplayer bot"
func bot_add_cmd():
	if cheats:
		create_bot()
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
	
const cheats_desc = "Allow/disalow cheats"
const cheats_help = "Allow/disalow cheats"
func cheats_cmd(command):
	if command != null and get_tree().is_network_server():
		rpc("change_cheats", bool(int(command)))
		
const kick_desc = "Kicks a player from the server"
const kick_help = "Kicks a player from the server"
func kick_cmd(command):
	if command != null:
		rpc("kick_player", command)
		
func host_cmd(port):
	call_deferred("create_server", "res://scenes/Qodot.tscn", "", int(port))
	
const interp_scale_help = "How much to scale the interpolation"
func interp_scale_cmd(command):
	if cheats and command != null:
		interp_scale = int(command)
		print("Interpolation scale is set to " + str(interp_scale))
		Console.print("Interpolation scale is set to " + str(interp_scale))
	elif command == null:
		print("No argument given!")
		Console.print("No argument given!")
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
		
const interp_help = "Whether to interpolate player movement for multiplayer"
func interp_cmd(command):
	if network.cheats and command != null:
		interp = bool(int(command))
		print("Interpolation is set to " + str(interp))
		Console.print("Interpolation is set to " + str(interp))
	elif command == null:
		print("No argument given!")
		Console.print("No argument given!")
	else:
		print("cheats is not set to true!")
		Console.print("cheats is not set to true!")
		
#const sync_desc = "Syncs clients from server"
#const sync_help = "syncs clients from server"
#func sync_cmd(command):
#	if get_tree().is_network_server():
#		rpc("sync_world_client", sync_world_server(get_tree().get_root(), {}, delta))
