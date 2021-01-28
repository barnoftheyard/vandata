extends Spatial
tool

var text = ""
var compare_text = ""

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "text" in properties:
		text = properties["text"]
		compare_text != properties["text"]

func update():
	text = text.replace("\\", "")
	$Viewport/Label.text = text
	$Viewport.size = $Viewport/Label.rect_size
	$MeshInstance.mesh.size = $Viewport/Label.rect_size * 0.01
	
func _ready():
	update()
	update_properties()

func _process(_delta):
	if text != compare_text:
		compare_text = text
		update()
