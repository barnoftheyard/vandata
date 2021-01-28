extends Node

#use the properties if you can - iFire
#getters and setters are closer to the metal and you want to be as high level- 
#as you can to avoid iteration times stopping you from shipping your game
#properties are higher level

var version = "0.1.0 Alpha"
var author = "barnoftheyard"

enum game_modes {SINGLEPLAYER, MULTIPLAYER}
var game_mode = null

onready var time_start = OS.get_unix_time()
export var time_elapsed = 0
var delta_time = 0
var is_paused = false

var file_name= "res://config.cfg" 
onready var config_file = ConfigFile.new()

var rng = RandomNumberGenerator.new()

var game_config = {					#default settings
	"crosshair": 0,
	"invert_x": false, 
	"invert_y": false, 
	"flip_guns": false,
	"fullscreen": false,
	"show_fps": false,
	"player_name": "player",
	"mouse_sensitivity": 0.2,
	"fov": 90
}

#Three dimensional distance formula
func distance(a, b):
	return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2) + pow(b.z - a.z, 2))
	
#get all files in a certain directory. Used by the functions that manage
#different sound variations
func files_in_dir(path, check_ext):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".wav"):
			files.append(path + file)

	dir.list_dir_end()

	return files
	
func play_rand(node, array):
	if array.size() > 0:			#If we have more than zero sound paths in our array
		node.stream = load(array[rng.randi_range(0, array.size() - 1)])
		node.set_pitch_scale(rng.randf_range(0.9, 1.1))
		node.play() #load()

func load_config():
	config_file.load(file_name)
	
	var game_list = game_config.keys()
	var i = 0
		
	for x in game_list:			#set every key with the config file's value of the same name
		if config_file.has_section_key("game", game_list[i]):
			game_config[x] = config_file.get_value("game", game_list[i])
		i += 1
		
	print("Config loaded: " + str(game_config))
	
	#just first-time settings loading at start-up
	OS.window_fullscreen = game_config["fullscreen"]

func _ready():
	rng.randomize()
	load_config()

func _process(delta):
	time_elapsed = (OS.get_unix_time() - time_start) % 60
	delta_time += delta
