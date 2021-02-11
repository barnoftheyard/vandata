extends WindowDialog

var command_postfix = "_cmd";
var input_name = "ui_console";
var history_up = "ui_up";
var history_down = "ui_down";
var label = RichTextLabel.new();
var line = LineEdit.new();

var current = 0;
var history = [];
var commands = {};
var cmd_args_amount = {};

onready var console_theme = preload("res://resources/Theme.tres")

signal open_console
signal close_console

#This is based off of VolodyaKEK's one script command console
#Most of it doesn't have any sort of comments, but it should be self-explanitory

func tokenize(input):
	var tokens = []
	
	var append_to_buffer = false
	var buffer = ""
	
	for c in input:
		match c:
			"\"":
				#toggle our buffer latch
				append_to_buffer = !append_to_buffer
				
				#append the first quotation
				if append_to_buffer:
					tokens.append(c)
				#append what we have in the buffer, append the last quotation,
				#and clear the buffer
				else:
					tokens.append(buffer)
					tokens.append(c)
					buffer = ""
				
			" ":
				tokens.append(buffer)
				tokens.append(c)
				buffer = ""
			_:
				buffer += c
	
	#append if we have any remaining data in the buffer
	if buffer != "":
		tokens.append(buffer)
		buffer = ""
	
	return tokens
	
func lexer(tokens):
	var finished = []
	
	var append_to_buffer = false
	var buffer = ""
	
	for token in tokens:
		match token:
			"\"":
				append_to_buffer = !append_to_buffer
				
				#once we get to the last quotation token, append to the finished
				#array and clear buffer
				if !append_to_buffer:
					finished.append(buffer)
					buffer = ""
			" ":
				#if the space token is in a string append into one single token
				if append_to_buffer:
					buffer += token
			_:
				#if its in a string append all into one single token
				if append_to_buffer:
					buffer += token
				#else, let it be
				else:
					finished.append(token)
					
	if buffer != "":
		finished.append(buffer)
		buffer = ""
		
	return finished
		
func toggle():
	if visible:
		hide();
		Global.is_paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		popup();
		line.clear();
		line.grab_focus();
		Global.is_paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready():
	connect("open_console", self, "_on_open_console")
	connect("close_console", self, "_on_close_console")
	
	connect_node(self);
	window_title = "Console";
	popup_exclusive = true;
	resizable = true;
	rect_min_size = Vector2(200, 100);
	rect_size = Vector2(300, 200);
	
	var c = VBoxContainer.new();
	add_child(c);
	c.margin_bottom = 0;
	c.margin_left = 0;
	c.margin_top = 0;
	c.margin_right = 0;
	c.anchor_bottom = 1;
	c.anchor_left = 0;
	c.anchor_top = 0;
	c.anchor_right = 1;
	
	label.bbcode_enabled = true;
	label.size_flags_vertical = SIZE_EXPAND_FILL;
	label.scroll_following = true;
	c.add_child(label);
	
	line.connect("text_entered", self, "command");
	line.clear_button_enabled = true;
	c.add_child(line);
	
	theme = console_theme
	
	self.print("You are now playing Vandata. Version " + Global.version + ". Enjoy your stay.")
	
	var input = "add 2 2"
	
	self.print(tokenize(input))
	self.print(lexer(tokenize(input)))

func _process(_delta):
	if Input.is_action_just_pressed(input_name):
		toggle()
			
	if history.size() > 0 && get_focus_owner() == line:
		var add = 0;
		if Input.is_action_just_pressed(history_up):
			add += 1;
		if Input.is_action_just_pressed(history_down):
			add -= 1;
		if add != 0:
			current = clamp(current-add, 0, history.size()-1);
			line.text = history[current];
			line.caret_position = line.text.length();

func connect_node(node):
	for method in node.get_method_list():
		var n = method.name;
		if n.ends_with(command_postfix):
			n = n.substr(0, n.length()-command_postfix.length());
			commands[n] = node;
			cmd_args_amount[n] = method.args.size();
func disconnect_node(node):
	for key in commands.keys():
		if commands[key] == node:
			commands.erase(key);
			cmd_args_amount.erase(key);

func command(cmd):
	if cmd == "":
		return;
	line.clear();
	self.print(str("> ", cmd));
		
	#wrote custom tokenize function!
	var args = lexer(tokenize(cmd))
	
	var command = args.pop_front();
	
	var node = commands.get(command);
	if node:
		args.resize(cmd_args_amount[command]);
		node.callv(command + command_postfix, args);
	else:
		cmd_not_found(command);
	history.append(cmd);
	current = history.size();

func print(s):
	label.append_bbcode(str(s, "\n"));

func cmd_not_found(command):
	self.print(str("Command '", command, "' not found"));

const help_desc = "Use 'help [command]' to get command description";
const help_help = "Prints all available commands";
func help_cmd(command):
	if command != null && !commands.has(command):
		cmd_not_found(command);
		return;
	var keys = commands.keys();
	keys.sort();
	for cmd in [command] if command != null else keys:
		var h = commands[cmd].get(cmd + "_help");
		self.print(str("\t", cmd, "\t", h if h else ""));
	if command == null:
		self.print(help_desc);
	elif commands.has(command):
		var desc = commands[command].get(command + "_desc");
		if desc != null:
			self.print(desc);

const history_help = "Prints all previously entered commands";
func history_cmd():
	self.print("History is empty" if history.size() == 0 else PoolStringArray(history).join("\n"));

const clear_help = "Clears console output";
func clear_cmd():
	label.clear();
	
func _on_open_console():
	visible = false
	toggle()
	
func _on_close_console():
	visible = true
	toggle()
