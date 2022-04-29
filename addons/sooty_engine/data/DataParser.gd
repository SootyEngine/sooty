@tool
extends Resource
class_name DataParser

const S_COMMENT := "#"

static func parse(path: String, auto_type := false) -> Dictionary:
	var lines := UFile.load_text(path).split("\n")
	var dict_lines := []
	var shortcuts := {}
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
		var deep = UString.count_leading(text, "\t")
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
		
		# shortcut
		if text.begins_with("~~"):
			var p := text.substr(len("~~")).split(":", true, 1)
			var k := p[0].strip_edges()
			var v := p[1].strip_edges()
			shortcuts[k] = v
			continue
		
		# start or end multiline
		var mi := stripped.find('""""')
		if mi != -1:
			is_multiline = not is_multiline
			multiline_last = mi == 0
			
			stripped = stripped.substr(0, mi).strip_edges()
			# first line isn't empty?
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
					multiline_text = []
					continue
				# create new line with full message.
				else:
					line_index = multiline_line_index
					deep = multiline_deep
					stripped = "\n".join(multiline_text)
					multiline_text = []
		
		# collect multiline
		elif is_multiline:
			# don't add an empty line if it was a comment.
			if had_comment and not len(stripped):
				continue
			# preserver tabs in multiline
			var stripped_after := text.substr(multiline_deep).strip_edges(false, true)
			multiline_text.append(stripped_after)
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
	var out_data := {}
	while i < len(dict_lines):
		var o = _collect_tabbed(dict_lines, i)
		i = o[0]
		var line: Dictionary = o[1]
#		UDict.dig(line, _fix)
		out_data[line.key] = line.value
	
	# auto convert data
	if auto_type:
		out_data = patch_to_var(out_data, [path])
	
#	UDict.log(out)
	return {
		shortcuts=shortcuts,
		data=out_data
	}

static func _collect_tabbed(dict_lines: Array, i: int) -> Array:
	var line = dict_lines[i]
	i += 1
	# collect tabbed
	while i < len(dict_lines) and dict_lines[i].deep > line.deep:
		var o = _collect_tabbed(dict_lines, i)
		line.tabbed.append(o[1])
		i = o[0]
	_finalize_line(line)
	return [i, line]

static func _find_property_split(text: String) -> int:
	for i in len(text):
		match text[i]:
			"{", "[": break
			":":
				if (i == len(text)-1 or text[i+1] in " \n\t"):
					return i
	return -1
	
static func _finalize_line(line: Dictionary):
	# starting with `-`?
	if _is_list_item(line.text):
		line.list_item = true
		line.text = line.text.substr(2).strip_edges()
	
	# check for a `:` followed by whitespace.
	var split := _find_property_split(line.text)
	if split != -1:
		line.key = line.text.substr(0, split).strip_edges()
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
			line.value = list.map(func(x): return _merge_list_items(x))
		# dict
		else:
			# not a dict, just a newline value
			if len(line.tabbed) == 1 and not "key" in line.tabbed[0]:
				line.value = line.tabbed[0].value
			else:
				if UType.same_type_and_value(line.value, ""):
					line.value = {}
				for item in line.tabbed:
					if "key" in item:
						line.value[item.key] = item.value
					else:
						print("Bad dict item: %s." % item)
	
	else:
		if line.value is String and line.value:
			line.value = _pack_line_index(line, line.value)

static func _merge_list_items(list: Array) -> Variant:
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
static func _pack_line_index(line: Dictionary, text: String) -> String:
#	return "X!%s" % text
	return "%s!%s!%s" % [0, line.line, text]

static func _str_to_value(line: Dictionary) -> Variant:
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
			out[k] =  v
		return out
	# leave alone
	else:
		return s

static func _is_list_item(s: String) -> bool:
	return s.begins_with("- ") or s == "-"

# attempt to display data as a .soda file
static func dict_to_str(dict: Dictionary, with_type := false, strip := false, allow_flat := true) -> String:
	var out := []
	dict = dict.duplicate(true)
	if strip:
		UDict.dig(dict, func(x): _strip(x))
	_to_str(out, "", dict, with_type, allow_flat, 0, -1)
	out.pop_front() # TODO: find out why first element is empty
	return "\n".join(out)

static func _strip(x):
	for k in x:
		match typeof(x[k]):
			TYPE_ARRAY:
				for i in len(x[k]):
					if x[k][i] is String:
						x[k][i] = x[k][i].split("!", true, 2)[-1].c_escape()
				
			TYPE_STRING:
				x[k] = x[k].split("!", true, 2)[-1].c_escape()

static func _to_str(out: Array, key: String, value: Variant, with_type: bool, allow_flat: bool, deep: int, parent: int):
	var head = "\t".repeat(max(0, deep-1))
	var type := typeof(value)
	match type:
		TYPE_DICTIONARY:
			var hline = _to_h_str(value, with_type)
			if allow_flat and len(hline) <= deep * 40 or parent == TYPE_ARRAY:
				out.append("%s%s%s" % [head, key, hline])
			else:
				out.append("%s%s" % [head, key])
				for k in value:
					_to_str(out, k+": ", value[k], with_type, allow_flat, deep+1, TYPE_DICTIONARY)
		
		TYPE_ARRAY:
			var hline = _to_h_str(value, with_type)
			if allow_flat and len(hline) <= deep * 40 or UList.all_items_of_type(value, TYPE_STRING):
				out.append("%s%s%s" % [head, key, hline])
			else:
				out.append("%s%s" % [head, key])
				for item in value:
					_to_str(out, "- ", item, with_type, allow_flat, deep+1, TYPE_ARRAY)
		
		_:
			if type == TYPE_STRING and _has_special_char(value):
				value = "``%s``" % value
			
			if with_type:
				out.append("%s%s%s" % [head, key, "%s(%s)" % [value, UType.get_name_from_type(type) ]] )
			else:
				out.append("%s%s%s" % [head, key, value] )

static func _has_special_char(value: String) -> bool:
	for c in value:
		if c in "[]{}":
			return true
	return false

static func _to_h_str(value: Variant, with_type: bool) -> String:
	match typeof(value):
		TYPE_ARRAY:
			var out := []
			for i in value:
				out.append(_to_h_str(i, with_type))
			return "[%s]" % [", ".join(out)]
		
		TYPE_DICTIONARY:
			var out := []
			for k in value:
				out.append("%s: %s" % [k, _to_h_str(value[k], with_type)])
			return "{%s}" % [", ".join(out)]
		
		_:
			if with_type:
				return "%s(%s)" % [value, UType.get_name_from_type(typeof(value)) ]
			else:
				return str(value)

# patches contain file index and line index for debug purposes
# it keeps everything as a string until it's time to apply to an object
# this will clean it all and auto convert strings to variants
static func patch_to_var(patch: Variant, sources: Array, explicit_type := -1) -> Variant:
	match typeof(patch):
		TYPE_STRING:
			# reversing _pack_line_index
			var info = patch.split("!", true, 2)
			var file: String = sources[info[0].to_int()]
			var line: String = info[1]
			var data: String = info[2]
			if explicit_type != -1:
				return UStringConvert.to_type(data, explicit_type)
			else:
				return UStringConvert.to_var(data)
		TYPE_DICTIONARY:
			var out := {}
			for k in patch:
				out[k] = patch_to_var(patch[k], sources)
			return out
		TYPE_ARRAY:
			var out := []
			for item in patch:
				out.append(patch_to_var(item, sources))
			return out
		_:
			assert(false)
	return null

static func patch(target: Object, patch: Dictionary, sources: Array):
	if target == null:
		push_error("Huh?")
		return
	
	var target_properties := UObject.get_state_properties(target)
#	prints(UClass._to_string2(target), target_properties, patch.keys())
	
	for property in patch:
		var value = patch[property]
		var p = UString.get_key_var(property, "=")
		property = p[0]
		var type = p[1]
		
		if property in target_properties:
			var target_type = typeof(target[property])
			# recursively check sub objects.
			if target_type == TYPE_OBJECT:
				patch(target[property], value, sources)
			
			elif target_type == TYPE_DICTIONARY or target_type == TYPE_ARRAY:
				if target.has_method("_patch_property_deferred"):
					target._patch_property_deferred.call_deferred(property, patch_to_var(value, sources))
				
				elif target.has_method("_patch_property"):
					target._patch_property(property, patch_to_var(value, sources))
				
				else:
					_patch_property(target, target_type, property, value, sources)
			
			else:
				_patch_property(target, target_type, property, value, sources)
		
		elif target.has_method("_patch_property_object"):
			var obj = target._patch_property_object(property, type)
			patch(obj, value, sources)
		
		elif target.has_method("_patch_property_deferred"):
			target._patch_property_deferred.call_deferred(property, patch_to_var(value, sources))
		
		elif target.has_method("_patch_property"):
			target._patch_property(property, patch_to_var(value, sources))
		
		else:
			push_error("No '%s' or patch method in %s for %s." % [property, target, patch_to_var(value, sources)])

static func _patch_property(target: Variant, target_type: int, property: String, value: Variant, sources: Array):
	# auto set property
	var value_converted = patch_to_var(value, sources, target_type)
	if typeof(value_converted) == target_type:
		target[property] = value_converted
	else:
		push_error("Couldn't convert '%s' for property %s." % [value, property])
