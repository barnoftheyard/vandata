extends Node

var spawn_points = []

signal spawnready

func choose_spawn():
	#choose a spawn randomly
	if spawn_points.size() > 0:
		return spawn_points[get_parent().rng.randi_range(0, spawn_points.size() - 1)].transform
		
func getallnodes(node):
	for n in node.get_children():
		if n.get_child_count() > 0:
			getallnodes(n)
		if n is PlayerSpawn:
			spawn_points.append(n)
			
func _ready():
	#recursively look through the entire scenetree for spawnpoints
	#bad idea I know, but I don't care
	getallnodes(get_tree().get_root())
