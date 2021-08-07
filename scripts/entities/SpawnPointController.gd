extends Node

func getallnodes(node, spawn_points):
	
	for n in node.get_children():
		if n.get_child_count() > 0:
			getallnodes(n, spawn_points)
		if n is PlayerSpawn:
			spawn_points.append(n)
			
	return spawn_points

func choose_spawn():
	var spawn_points = getallnodes(get_tree().get_root(), [])
	
	#choose a spawn randomly
	if spawn_points.size() > 0:
		var target = spawn_points[Global.rng.randi_range(0, spawn_points.size() - 1)]
		if is_instance_valid(target):
			return target.transform
