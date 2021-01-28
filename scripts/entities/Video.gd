extends Spatial

var stream = ""
var compare_stream = ""

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "stream" in properties:
		stream = properties["stream"]
		compare_stream != properties["stream"]

func update():
	if stream != "":
		$Viewport/VideoPlayer.stream = stream
	$Viewport.size = $Viewport/VideoPlayer.get_video_texture().get_size()
	$Viewport/VideoPlayer.rect_size = $Viewport.size
	$MeshInstance.mesh.size = $Viewport/VideoPlayer.rect_size * 0.01
	
func _ready():
	update()
	update_properties()

func _process(_delta):
	if stream != compare_stream:
		compare_stream = stream
		update()
