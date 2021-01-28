extends EditorImportPlugin
tool

func get_importer_name():
	return "mtl.loader"
	
func get_visible_name():
	return ".mtl loader"
	
func get_recognized_extensions():
	return ["mtl"]
	
func get_save_extension():
	return "material"
	
func get_resource_type():
	return "SpatialMaterial"
	
func get_option_visibility(option, options):
	return true
	

enum Presets { PRESET_DEFAULT }

func get_preset_count():
	return Presets.size()
	
func get_preset_name(preset):
	match preset:
		0:
			return "Default"
		_:
			return "Unknown"
	
func get_import_options(preset):			#our import options
	match preset:
		0:
			return [{
						"name": "generate_multiple_files",
						"default_value": true,
						"hint_string": """Whether to generate all instances
						of materials in the .mtl file, or just the first one."""
					}]
		_:
			return []

const mtl_dic = {
		"newmtl": null,		#material name
		"Ka": null,			#ambient
		"Kd": null,			#diffuse
		"Ks": null,			#specular
		"Ns": null,			#specular exponent
		"illum": null,		#illumination model
		"map_Ka": null, 	#material texture ambient map
		"map_Kd": null		#material texture diffuse map
}

func load_file(path):
	var file = File.new()
	file.open(path, file.READ)
	var content = file.get_as_text()
	file.close()
	return content

func lex_mtl(input):
	
	var ignore_til_newline = false
	var buffer = ""
	var tokens = []
	var delimiters = [' ', '\n', '\t', '#']

	for i in input:
		if i == '\n':
			ignore_til_newline = false
			tokens.append(buffer)
			buffer = ""
		elif !ignore_til_newline:
			if i in delimiters:
				tokens.append(buffer)
				buffer = ""
				
				if i == '#':
					ignore_til_newline = true
			else:
				buffer += i
					
	return tokens
	
func parse_mtl(input):
	
	#BIG FUCKING TODO: actual error reporting
	
	var dic_array = []
	var dic = mtl_dic.duplicate()
	var iterations = 0
	
	for i in input.size():
		match input[i]:
			"newmtl":
				if iterations > 0:			#if there's more than one material, put what we have already
					dic_array.append(dic)	#in the array, and then do a new one
					dic = mtl_dic.duplicate()
				iterations += 1
				
				dic[input[i]] = input[i + 1]			#get string
			"Ka":
				dic[input[i]] = Color8(float(input[i + 1]), 	#get the three tokens ahead of us and put it into a color
				float(input[i + 2]), float(input[i + 3]))
			"Kd":
				dic[input[i]] = Color8(float(input[i + 1]),
				float(input[i + 2]), float(input[i + 3]))
			"Ks":
				dic[input[i]] = Color8(float(input[i + 1]),
				float(input[i + 2]), float(input[i + 3]))
			"Ns":
				dic[input[i]] = int(input[i + 1])		#get integer
			"illum":
				dic[input[i]] = int(input[i + 1])
			"map_Ka":
				dic[input[i]] = input[i + 1]
			"map_Kd":
				dic[input[i]] = input[i + 1]
	
	dic_array.append(dic)
	
	return dic_array
	
func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var mtl_file = load_file(source_file)
	var materials = parse_mtl(lex_mtl(mtl_file))
	
	var how_many = 0
	if options.generate_multiple_files:
		how_many = materials.size()
	else:
		how_many = 1
	
	for i in range(0, how_many):				#for every material, import it
		var mat = SpatialMaterial.new()					#make a new material
		
		if materials[i]["map_Kd"] != null:				#if we don't have diffuse, don't set our albedo
			
			var path = source_file.get_base_dir() + "/" + str(materials[i]["map_Kd"])
			mat.albedo_texture = load(path)
			
		var next_pass_path = "%s%s.%s" % [source_file.get_base_dir() + "/", 		#get the base folder and save as our material name
		materials[i]["newmtl"], get_save_extension()]
		
		var err = ResourceSaver.save(next_pass_path, mat)		#save our shit
		if err != OK:			#if error, return it and whine to the editor
			return err
			
		print("Import of .mtl successful. Saved material %s to: %s" % [i, next_pass_path])
		r_gen_files.push_back(next_pass_path)				#this does something, I don't know what, but it does something
