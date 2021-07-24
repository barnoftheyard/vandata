class_name Text
extends Spatial
tool

signal change_text(new_text)

export var text = ""
var compare_text = ""

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if "text" in properties:
		text = properties["text"]
	if "color" in properties:
		$Viewport/Label.custom_colors.font_color = properties["color"]
		
func _on_change_text(new_text):
	new_text = new_text.replace("\\", "")
	$Viewport/Label.text = new_text
	$Viewport.size = $Viewport/Label.rect_size
	$MeshInstance.mesh.size = $Viewport/Label.rect_size * 0.01
	text = new_text
	
func _ready():
	connect("change_text", self, "_on_change_text")
	emit_signal("change_text", text)

func _process(_delta):
	if text != compare_text:
		compare_text = text
		emit_signal("change_text", text)
