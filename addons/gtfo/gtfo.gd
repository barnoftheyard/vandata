tool
extends EditorScript

var scr = """#hi this is a comment
6 2 ^ 3543 35435 "Hello world!" print
"""

var variables = {}
var stdout = ""

enum op {ADD, SUB, MUL, DIV, POW}

func operation(stack, op_to_do):
	var arg1 = stack.back()
	stack.pop_back()
	var arg2 = stack.back()
	stack.pop_back()
	
	if arg1 == null:
		print("Stack 1 operand empty!")
		return
	elif arg2 == null:
		print("Stack 2 operand empty!")
		return
	else:
		match op_to_do:
			op.ADD:
				stack.push_back(arg2 + arg1)
			op.SUB:
				stack.push_back(arg2 - arg1)
			op.MUL:
				stack.push_back(arg2 * arg1)
			op.DIV:
				stack.push_back(arg2 / arg1)
			op.POW:
				stack.push_back(pow(arg2, arg1))

func load_file(path):
	var file = File.new()
	file.open(path, file.READ)
	var content = file.get_as_text()
	file.close()
	return content

func lex(input):
	
	var ignore_til_newline = false
	var ignore_til_dquote = false
	var buffer = ""
	var tokens = []
	var delimiters = [' ', '\n', '\t', '#', '\"']

	for i in input:
		
		if i in delimiters and !ignore_til_dquote and !ignore_til_newline:
			if i == '\"':
				ignore_til_dquote = !ignore_til_dquote
				tokens.append(buffer)
				buffer = ""
			elif i == '#':
				ignore_til_newline = true
			elif i == '\n' and ignore_til_newline:
				ignore_til_newline = false
				tokens.append(buffer)
				buffer = ""
			else:
				tokens.append(buffer)
				buffer = ""
		else:
			buffer += i
					
	return tokens
	
func parse(input):
	
	#BIG FUCKING TODO: actual error reporting
	
	print(input)
	
	var stack = []
	var iterations = 0
	
	for i in input.size():
		match input[i]:
			'+':
				operation(stack, op.ADD)
			'-':
				operation(stack, op.SUB)
			'*':
				operation(stack, op.MUL)
			'/':
				operation(stack, op.DIV)
			'^':
				operation(stack, op.POW)
			"print":
				stdout += input[i - 1]
			_:
				if input[i].is_valid_integer():
					stack.push_back(int(input[i]))
	
	return stack

func _run():
	print("output: \n" + String(parse(lex(scr))))
	print("stdout: \n" + stdout)
