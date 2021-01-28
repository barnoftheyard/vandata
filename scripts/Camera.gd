extends Camera

onready var fieldofvision = Global.game_config["fov"]

func _physics_process(delta):
	#has the game config changed since _ready()?
	if fieldofvision != Global.game_config["fov"]:
		fov = Global.game_config["fov"]
		fieldofvision = Global.game_config["fov"]
