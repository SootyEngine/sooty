class_name Soot2

enum Type { None, Flow, Text }

static func parse(files: Array):
	var text_lines := _get_tab_tree(files)
	var state := {flows={}, lines={}}
	for i in len(text_lines):
		_process_line(text_lines[i], state)
	return state

static func _process_line(line: Dictionary, state: Dictionary):
	var raw: String = line.raw
	
	# check for lang comment
	var lang_comment := raw.find("#{")
	if lang_comment != -1:
		var lang_comment_end := raw.find("}", lang_comment+1)
		if lang_comment_end != -1:
			line.id = raw.substr(lang_comment+2, lang_comment_end-lang_comment)
			raw = raw.substr(0, lang_comment).strip_edges(false, true)
		else:
			push_error("Missing lang comment end. #{}")
	
	# #. meta
	if raw.begins_with("#."):
		line.type = "meta"
	
	# === flow
	elif raw.begins_with("==="):
		var id := raw.trim_prefix("===").strip_edges()
		line.type = "flow"
	# <-> lang
	elif raw.begins_with("<->"):
		var id := raw.trim_prefix("<->").strip_edges()
		line.type = "lang"
	
	# => goto
	elif raw.begins_with("=>"):
		_trim_head(line, "=>")
		_extract_condition(line)
		line.type = "goto"
		line.goto = line.text
	
	# == call
	elif raw.begins_with("=="):
		line.type = "call"
		_extract_condition(line)
	# __ pass
	elif raw.begins_with("__"):
		line.type == "pass"
		_extract_condition(line)
	# >< break
	elif raw.begins_with("><"):
		line.type == "break"
		_extract_condition(line)
	# >><< return
	elif raw.begins_with(">><<"):
		line.type == "return"
		_extract_condition(line)
	
	# {{}} conditions
	elif raw.begins_with("{{"):
		line.type = "cond"
		_extract_condition(line)
	# {()} cases
	elif raw.begins_with("{("):
		line.type = "case"
	# {[]} lists
	elif raw.begins_with("{["):
		line.type = "case"
		_extract_condition(line)
	
	# & insert
	elif raw.begins_with("&"):
		line.type = "insert"
	
	# --- choice
	elif raw.begins_with("---"):
		line.type = "choice"
		_trim_head(line, "---")
		_extract_condition(line)
	# -+- choice_pluse
	elif raw.begins_with("-+-"):
		line.type = "choice+"
		_trim_head(line, "-+-")
		_extract_condition(line)
	
	# ~$@^ actions
	elif UString.begins_with_any(raw, ["@", "$", "^", "~"]):
		_extract_condition(line)
		line.type = "do"
		line.do = line.raw
	
	# text lines
	else:
		_extract_condition(line)
		line.type = "text"
		line.text = line.raw
	
	# process child lines
	if "tabbed" in line:
		for i in len(line.tabbed):
			_process_line(line.tabbed[i], state)

static func _erase(line: Dictionary, keys: Array):
	for k in keys:
		line.erase(k)

static func _trim_head(line: Dictionary, head: String):
	line.raw = line.raw.trim_prefix(head).strip_edges(true, false)

static func _extract_condition(line: Dictionary):
	var p = UString.extract(line.raw, "{{", "}}")
	if p.inside:
		line.raw = p.outside
		line.cond = p.inside

static func _get_tab_tree(files: Array) -> Array:
	var lines := []
	
	for file_index in len(files):
		var text_lines := UFile.load_text(files[file_index]).split("\n")
		var line_index := 0
		var state := {}
		var is_multiline := false
		var last_line := {}
		
		while line_index < len(text_lines):
			var text := text_lines[line_index]
			var deep := UString.count_leading(text, "\t")
			text = text.substr(deep)
			
			# check for a comment
			var comment_index := text.find("# ")
			if comment_index != -1:
				text = text.substr(0, comment_index).strip_edges(false, true)
			
			# multiline start?
			if text.ends_with("<<"):
				text = text.trim_suffix("<<")
				is_multiline = true
			# multiline end?
			elif text.begins_with(">>"):
				text = text.trim_prefix(">>")
				is_multiline = false
				last_line.text += "\n" + text
				line_index += 1
				continue
			# if multiline, skip the rest
			elif is_multiline:
				last_line.text += "\n" + text
				line_index += 1
				continue
			
			# add line if it's not empty
			if is_multiline or text.strip_edges() != "":
				last_line = {
					id="",
					file=file_index,
					line=line_index,
					type="",
					raw=text,
					tabbed=[]
				}
				
				# flatten lines
				if "||" in text:
					var parts := text.split("||")
					last_line.text = parts[0]
					for tabbed_index in range(1, len(parts)):
						last_line.tabbed.append({
							id="",
							file=file_index,
							line=line_index,
							type="",
							raw=parts[tabbed_index],
							tabbed=[]
						})
				
				# add to state as parent of current depth
				state[deep] = last_line
				
				# add as a root line
				if deep == 0:
					lines.append(last_line)
				# add as a nested line
				else:
					state[deep-1].tabbed.append(last_line)
			
			line_index += 1
	
	return lines
