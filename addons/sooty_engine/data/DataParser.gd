@tool
extends Resource
class_name DataParser

const S_COMMENT := "#"

func _init():
	pass

func parse(path: String):
	var lines := UFile.load_text(path).split("\n")
	var dict_lines := []
	var i := 0
	
	# convert text lines to info dicts
	var is_multiline := false
	var multiline_deep := 0
	var multiline_last := false
	var multiline_text := []
	var multiline_line_index := 0
	var had_comment := false
	
	while i < len(lines):
		var text := lines[i]
		var deep = UString.count_leading_tabs(text)
		var stripped := text.strip_edges()
		var line_index := i
		i += 1
		
		# strip comments.
		var comment_index := stripped.find(S_COMMENT)
		if comment_index != -1:
			had_comment = true
			stripped = stripped.substr(0, comment_index).strip_edges()
		else:
			had_comment = false
		
		# start or end multiline
		var mi := stripped.find('""""')
		if mi != -1:
			is_multiline = not is_multiline
			multiline_last = mi == 0
			
			stripped = stripped.substr(0, mi).strip_edges()
			if stripped != "":
				multiline_text.append(stripped)
			
			# start
			if is_multiline:
				multiline_line_index = line_index
				multiline_deep = deep
				continue
			# end
			else:
				# if starting on a new line, add self to last line.
				if multiline_last:
					var last: Dictionary = dict_lines[-1]
					multiline_text.push_front(last.text)
					last.text = "\n".join(multiline_text)
					continue
				# create new line with full message.
				else:
					line_index = multiline_line_index
					deep = multiline_deep
					stripped = "\n".join(multiline_text)
				
				multiline_text.clear()
		
		# collect multiline
		elif is_multiline:
			# don't add an empty line if it was a comment.
			if had_comment and not len(stripped):
				continue
			multiline_text.append(stripped)
			continue
		
		# skip empty lines.
		elif stripped == "":
			continue
		
		dict_lines.append({
			line=line_index,
			text=stripped,
			deep=deep,
			tabbed=[]
		})
	
	# collect tabbed lines
	i = 0
	var out := {}
	while i < len(dict_lines):
		var o = _collect_tabbed(dict_lines, i)
		i = o[0]
		var line: Dictionary = o[1]
#		UDict.dig(line, _fix)
		out[line.key] = line.value
	
#	UDict.log(out)
	return out

#func _fix(d: Dictionary):
#	if "value" in d and d.value is String:
#		d.value = "%s!%s" % [d.line, d.value]

func _collect_tabbed(dict_lines: Array, i: int) -> Array:
	var line = dict_lines[i]
	i += 1
	# collect tabbed
	while i < len(dict_lines) and dict_lines[i].deep > line.deep:
		var o = _collect_tabbed(dict_lines, i)
		line.tabbed.append(o[1])
		i = o[0]
	_finalize_line(line)
	return [i, line]

func _find_property_split(text: String) -> int:
	for i in len(text):
		match text[i]:
			"{", "[": break
			":":
				if (i == len(text)-1 or text[i+1] in " \n\t"):
					return i
	return -1
	
func _finalize_line(line: Dictionary):
	# starting with `-`?
	if _is_list_item(line.text):
		line.list_item = true
		line.text = line.text.substr(2).strip_edges()
	
	# check for a `:` followed by whitespace.
	var split := _find_property_split(line.text)
	if split != -1:
		line.key = line.text.substr(0, split).strip_edges()
#		line.key = _pack_line_index(line, line.key)
		line.text = line.text.substr(split+1).strip_edges()
		line.value = _str_to_value(line)
	
	# if there is none, this is just a value, not a dict element.
	else:
		line.value = _str_to_value(line)
	
	# list or dict?
	if len(line.tabbed):
		# list
		if "list_item" in line.tabbed[0]:
			var list := []
			for l in line.tabbed:
				if "list_item" in l:
					# add self as first element, unless empty (in the case of dict/list)
					list.append([l] if l.value else [])
				else:
					list[-1].append(l)
			line.value = list.map(_merge_list_items)
		# dict
		else:
			# not a dict, just a newline value
			if len(line.tabbed) == 1 and not "key" in line.tabbed[0]:
				line.value = line.tabbed[0].value
			else:
				if UType.is_equal(line.value, ""):
					line.value = {}
				for item in line.tabbed:
					if "key" in item:
						line.value[item.key] = item.value
					else:
						print("Bad dict item: %s." % item)
	
	else:
		if line.value is String and line.value:
			line.value = _pack_line_index(line, line.value)
	
func _merge_list_items(list: Array) -> Variant:
	var out = null
	for i in len(list):
		var item: Dictionary = list[i]
		if "key" in item:
			if i == 0:
				out = {}
			out[item.key] = item.value
		else:
			out = item.value
	return out

# add the line index to the front for error helping
func _pack_line_index(line: Dictionary, text: String) -> String:
#	return "X!%s" % text
	return "%s!%s!%s" % [0, line.line, text]

func _str_to_value(line: Dictionary) -> Variant:
	var s: String = line.text
	# list?
	if UString.is_wrapped(s, "[", "]"):
		var out := []
		for part in UString.unwrap(s, "[", "]").split(","):
			out.append(_pack_line_index(line, part.strip_edges()))
		return out
	# dict?
	elif UString.is_wrapped(s, "{", "}"):
		var out := {}
		for part in UString.unwrap(s, "{", "}").split(", "):
			var p: PackedStringArray = part.split(":", true, 1)
			var k := p[0].strip_edges()
			var v := "" if len(p) == 1 else p[1].strip_edges()
#			k = _pack_line_index(line, k)
			v = _pack_line_index(line, v)
			out[k] = v
		return out
	# leave alone
	else:
		return s

func _is_list_item(s: String) -> bool:
	return s.begins_with("- ") or s == "-"

# attempt to display data as a .soda file
func dict_to_str(dict: Dictionary) -> String:
	var out := []
	UDict.dig(dict, _strip)
	_to_str(out, "", dict, 0, -1)
	out.pop_front() # TODO: find out why first element is empty
	return "\n".join(out)

func _strip(x):
	for k in x:
		match typeof(x[k]):
			TYPE_ARRAY:
				for i in len(x[k]):
					if x[k][i] is String:
						x[k][i] = x[k][i].split("!", true, 2)[-1].c_escape()
				
			TYPE_STRING:
				x[k] = x[k].split("!", true, 2)[-1].c_escape()

func _to_str(out: Array, key: String, item: Variant, deep: int, parent: int):
	var head = "\t".repeat(max(0, deep-1))
	match typeof(item):
		TYPE_DICTIONARY:
			if parent == TYPE_ARRAY:
				var hline = _to_h_str(item)
#			if len(hline) < 40:
				out.append("%s%s%s" % [head, key, hline])
			else:
				out.append("%s%s" % [head, key])
				for k in item:
					_to_str(out, k+": ", item[k], deep+1, TYPE_DICTIONARY)
		
		TYPE_ARRAY:
			var hline = _to_h_str(item)
			if len(hline) < 40:
				out.append("%s%s%s" % [head, key, hline])
			else:
				out.append("%s%s" % [head, key])
				for i in item:
					_to_str(out, "- ", i, deep+1, TYPE_ARRAY)
		
		_:
			out.append("%s%s%s" % [head, key, item])

func _to_h_str(item: Variant) -> String:
	match typeof(item):
		TYPE_ARRAY:
			var out := []
			for i in item:
				out.append(_to_h_str(i))
			return "[%s]" % ", ".join(out)
		
		TYPE_DICTIONARY:
			var out := []
			for k in item:
				out.append("%s: %s" % [k, _to_h_str(item[k])])
			return "{%s}" % ", ".join(out)
		
		_:
			return str(item)
