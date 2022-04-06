@tool
extends Resource
class_name DialogueParser

const DEBUG_KEEP_DICTS := false # don't clean useless info from steps?
const REWRITE := 6 # total times rewritten from scrath :{

const S_PROPERTY_HEAD := "|"

var _last_speaker := ""
var all_files := []
var ignore_flags := false
var has_IGNORE := false # if ignore flag exists, this dialogue won't be available.
var d_id := ""
var line_ids := {}

func _init(dialogue_id: String, files: Array, langs := []):
	d_id = dialogue_id 
	all_files = files + langs

func parse(generate_lang := "") -> Dictionary:
	var out_flows := {}
	var out_lines := {}
	var raw := []
	has_IGNORE = false
	
	# load files
	for i in len(all_files):
		var file: String = all_files[i]
		var f := _parse_file(file, i)
		
		if has_IGNORE:
			return {}
		
		# merge dialogue
		if file.ends_with(Soot.EXT_DIALOGUE):
			# keep track of raw unprocessed text lines
			# for use with lang file generator
			raw.append(f.raw)
			
			for k in f.flows:
				if k in out_flows:
					push_error("hmm? %s" % k)
				out_flows[k] = f.flows[k]
			
			for k in f.lines:
				if k in out_lines:
					push_error("hmm? %s" % k)
				out_lines[k] = f.lines[k]
		
		# merge languages
		elif file.ends_with(Soot.EXT_LANG):
			_merge_lang(f.flows, f.lines, out_flows, out_lines)
	
	if len(generate_lang):
		_generate_lang(generate_lang, out_flows, out_lines, raw)
	
	return {
		flows=out_flows,
		lines=out_lines
	}

# generate a language file (.sola) from the current dialogue.
func _generate_lang(lang: String, flows: Dictionary, lines: Dictionary, raw: Array):
	var out_path := "res://lang/%s-%s%s" % [d_id, lang, Soot.EXT_LANG]
	var text := []
	var existing := {}
	
	# has existing data?
	if UFile.file_exists(out_path):
		existing = _parse_file(out_path)
	
	for id in lines:
		if "!" in id:
			continue
		
		var line_info: Dictionary = lines[id]
		if line_info.type in ["text"]:
			var soot_path: String = all_files[line_info.M.file]
			# are there multiple lines with this id?
			if _has_lines_with_same_id(id, lines):
				var multi_lines: Array = _get_lines_with_same_id(id, lines)[0]
				var last_line:int = multi_lines[-1].M.line
				# display header showing file and line indices
				text.append("%s %s # %s @ %s - %s" % [Soot.LANG, id, soot_path, line_info.M.line, last_line])
				# display comment of original text
				for ml_info in multi_lines:
					var raw_text: String = raw[ml_info.M.file][ml_info.M.line]
					text.append("\t# %s" % [_clean_raw_line_for_lang(raw_text)])
			else:
				# header showing file and line index
				text.append("%s %s # %s @ %s" % [Soot.LANG, id, soot_path, line_info.M.line])
				# display a comment of original text
				var raw_text: String = raw[line_info.M.file][line_info.M.line]
				text.append("\t# %s" % [_clean_raw_line_for_lang(raw_text)])
			
			# grab existing line
			if existing and id in existing.flows:
				for line_id in existing.flows[id].then:
					var li = existing.lines[line_id]
					text.append(existing.raw[li.M.line])
			
			else:
				text.append("\t")
			
			text.append("")
	
	# add removed lines, in case they come back
	if existing:
		for id in existing.flows:
			if not id in lines:
				var flow_info: Dictionary = existing.flows[id]
				var flow_line: String = existing.raw[flow_info.M.line]
				var last_info := flow_line.split("#", true, 1)[-1].strip_edges()
				var old_file := last_info.split("@", true, 1)[0].strip_edges()
				text.append("# %s doesn't exist in %s anymore." % [id, old_file])
				var similar := UString.find_most_similar(id, lines.keys().filter(func(x): return not "!" in x))
				if similar:
					text.append("# Did you mean: %s?" % [", ".join(similar)])
				text.append("# Sooty will keep this flow in case it comes back.")
				text.append("# To remove it: Erase %s %s from %s." % [Soot.LANG, id, out_path])
				text.append("%s %s # REMOVED: %s" % [Soot.LANG_GONE, id, last_info])
				for line_id in flow_info.then:
					var li = existing.lines[line_id]
					text.append(existing.raw[li.M.line])
				text.append("")
	
	var out_text := "\n".join(text)
	UFile.save_text(out_path, out_text)
	if existing:
		print("Updated lang file at: %s." % out_path)
	else:
		print("Created lang file at: %s." % out_path)

func _has_lines_with_same_id(id: String, lines: Dictionary) -> bool:
	return ("%s!0" % id) in lines

# returns list with lines, and list with ids
func _get_lines_with_same_id(id: String, lines: Dictionary) -> Array:
	var out := [[lines[id]], [id]]
	var index := 0
	var safety := 1000
	while safety > 0:
		safety -= 1
		var k := "%s!%s" % [id, index]
		if k in lines:
			out[0].append(lines[k])
			out[1].append(k)
			index += 1
		else:
			break
	return out

func _clean_raw_line_for_lang(text: String) -> String:
	if Soot.COMMENT_LANG in text:
		text = text.split(Soot.COMMENT_LANG, true, 1)[0]
	if Soot.COMMENT in text:
		text = text.split(Soot.COMMENT, true, 1)[0]
	return text.strip_edges()

func _parse_file(file: String, file_index := 0) -> Dictionary:
	var out_flows := {}
	var out_lines := {}
	var original_text := UFile.load_text(file)
	var text_lines := original_text.split("\n")
	var dict_lines := []
	
	var in_multiline := false
	var multiline_id := ""
	var multiline_line := 0
	var multiline_head := ""
	var multiline_deep := 0
	var multiline := []
	
	var flags_pass := true
	var last_id := ""
	var multi_id_index := 0
	
	# Convert text lines to dict lines.
	var i := 0
	while i < len(text_lines):
		var current_line := text_lines[i]
		var line := i
		
		# ignore the file
		if current_line.begins_with("IGNORE"):
			has_IGNORE = true
			return {}
		
		# import time flags
		# these prevent certain lines, depending on flags
		if current_line.begins_with("\t#?"):
			flags_pass = true
			for flag in current_line.substr(3).strip_edges().split(" "):
				if len(flag) and not flag in Global.flags:
					flags_pass = false
					break
			i += 1
			continue
		
		# skip lines that didn't pass the flag.
		elif not ignore_flags and not flags_pass:
			i += 1
			continue
		
		# get id for language files
		var id := ""
		var uncommented := current_line
		if Soot.COMMENT_LANG in uncommented:
			var p := uncommented.split(Soot.COMMENT_LANG, true, 1)
			uncommented = p[0]
			id = p[1].strip_edges()
		
		# remove comment
		if Soot.COMMENT in uncommented:
			uncommented = uncommented.split(Soot.COMMENT, true, 1)[0]
		
		var stripped := uncommented.strip_edges()
		
		if '""""' in stripped:
			in_multiline = not in_multiline
			if not in_multiline:
				id = multiline_id
				line = multiline_line
				stripped = multiline_head.replace("%TEXT_HERE%", "\n".join(multiline))
				multiline = []
			else:
				multiline_id = id
				multiline_line = i
				multiline_head = uncommented.replace('""""', '%TEXT_HERE%').strip_edges()
				multiline_deep = UString.count_leading(text_lines[i], "\t")
				i += 1
				continue
		
		# if part of multline, just collect
		if in_multiline:
			multiline.append(uncommented.substr(multiline_deep))
		
		# ignore empty lines
		elif len(stripped):
			var deep := UString.count_leading(text_lines[i], "\t")
			if len(id):
				# multiline
				if id == "+":
					id = "%s!%s" % [last_id, multi_id_index]
					multi_id_index += 1
				else:
					last_id = id
				
				if id in line_ids:
					push_error("Two lines using the same id. %s" % id)
				else:
					# remember id, so we don't collide with it later
					line_ids[id] = true
			
			# create data for each line
			dict_lines.append(_new_line(stripped, d_id, file_index, id, line, deep))
			# unflatten tabbed lines that may exist on the main line ((wrapped in double brackets))
			var flat_lines := _extract_flat_lines(dict_lines[-1])
			dict_lines.append_array(flat_lines)
		
		i += 1
	
	# collect tabs, recursively.
	i = 0
	var new_list := []
	while i < len(dict_lines):
		var o = _collect_tabbed(dict_lines, i)
		i = o[0]
		new_list.append(o[1])
	
	for i in len(new_list):
		var item: Dictionary = new_list[i]
		if item.type in ["flow", "lang", "lang_gone"]:
			# only keep flows with steps
			# ignore empty ones
			if item.then:
				_clean(item, out_lines)
				out_flows[item.id] = item
	
	return {
		flows=out_flows,
		lines=out_lines,
		raw=text_lines
	}

func _merge_lang(lang_flows: Dictionary, lang_lines: Dictionary, out_flows: Dictionary, out_lines: Dictionary):
	for flow in lang_flows.values():
		var replace_id: String = flow.id
		
		# remove line
		if not replace_id in out_lines:
			if flow.type != "lang_gone":
				print("Line %s wasn't there!?" % replace_id)
			continue
		
		# get old lines nad their ids
		var old_lines_and_ids: Array
		if _has_lines_with_same_id(replace_id, out_lines):
			old_lines_and_ids = _get_lines_with_same_id(replace_id, out_lines)
		else:
			old_lines_and_ids = [out_lines[replace_id], [replace_id]]
		
		# remove old lines
		for id in old_lines_and_ids[1]:
			out_lines.erase(id)
		
		var old_lines = old_lines_and_ids[0]
		var new_lines = []
		# install as a flow call (== flow) if there is more than one line
		if len(flow.then) > 1:
			# the flow.id is same as line id from original file
			var new_flow_id: String = "lang_%s" % flow.id
			# add lang flow to main flow list
			out_flows[new_flow_id] = flow
			
			# install a call in it's place
			out_lines[replace_id] = {
				"type": "call",
				"call": Soot.join_path([d_id, new_flow_id]),
				"M": {
					"d_id": flow.M.d_id,
					"file": flow.M.file,
					"line": flow.M.line,
					"lang": true # this line came from a .sola file
				}
			}
			
			# install flow lines
			for line_id in flow.then:
				if line_id in out_lines:
					print("Line %s existed! Shouldn't happen!" % line_id)
				out_lines[line_id] = lang_lines[line_id]
				new_lines.append(lang_lines[line_id])
		
		# install as a single line replace
		else:
			out_lines[replace_id] = lang_lines[flow.then[0]]
			new_lines.append(lang_lines[flow.then[0]])
		
		print("REPLACED ", old_lines[0], "<->", new_lines)

func _new_line_flat(parent: Dictionary, index: int, text := "", id := "") -> Dictionary:
	var out := _new_line_child(parent, text, id)
	if "flat" in parent:
		out.flat = "%s %s" % [parent.flat, index]
	else:
		out.flat = "%s" % index
	return out

func _new_line_child(parent: Dictionary, text := "", id := "") -> Dictionary:
	return _new_line(text, parent.M.d_id, parent.M.file, id, parent.M.line, parent.M.deep+1)

func _new_line(text: String, d_id: String, file: int, id: String, line: int, deep: int) -> Dictionary:
	return {
		"M"={ # meta data
			"text"=text, # original text, stripped
			"id"=id, # unique id, used for translations
			"deep"=deep, # how many tabs
			"tabbed"=[], # lines tabbed below this one
			"d_id"=d_id, # dialogue
			"file"=file, # file index
			"line"=line # index of line in file
		},
		"type"="_", # type of line
	}

func _clean_array(lines: Array, out_lines: Dictionary):
	for i in len(lines):
		if DEBUG_KEEP_DICTS: # DEBUG SANITY
			_clean(lines[i], out_lines)
		else:
			lines[i] = _clean(lines[i], out_lines)

func _clean_nested_array(lines_list: Array, out_lines: Dictionary):
	for i in len(lines_list):
		_clean_array(lines_list[i], out_lines)

func _clean(line: Dictionary, out_lines: Dictionary) -> String:
	var id: String = line.M.id
	if not len(id):
		seed(hash(line.M.text))
		id = _get_uid()
		line_ids[id] = true # add to list so we don't collide
	
	if "flat" in line.M:
		id += "_%s" % [line.M.flat]
#		line.erase("flat")
	
	match line.type:
		"flow", "lang", "lang_gone":
			_clean_array(line.then, out_lines)
			return id

		"option":
			if "then" in line:
				_clean_array(line.then, out_lines)
#		"goto", "call":
#			_erase(line, ["text"])
		"text":
			if "options" in line:
				_clean_array(line.options, out_lines)
#		"action":
#			_erase(line, ["text"])
		"cond":
			match line.cond_type:
				"if": _clean_nested_array(line.cond_lines, out_lines)
				"match": _clean_nested_array(line.case_lines, out_lines)
			line.type = line.cond_type
		_: pass
	
	# erase non essential keys from Meta.
	for k in line.M.keys():
		if not k in ["d_id", "file", "line", "id"]:
			line.M.erase(k)
	
	if id in out_lines:
		var old = out_lines[id]
		push_error("%s Line at %s %s replaced with %s" % [all_files[line.file], id, old, line])
	out_lines[id] = line
	return id

func _collect_tabbed(dict_lines: Array, i: int) -> Array:
	var line = dict_lines[i]
#	_extract_properties(line)
	i += 1
	# collect tabbed
	while i < len(dict_lines) and dict_lines[i].M.deep > line.M.deep:
		var o = _collect_tabbed(dict_lines, i)
		line.M.tabbed.append(o[1])
		i = o[0]
		
	# get properties
	for j in range(len(line.M.tabbed)-1, -1, -1):
		if line.M.tabbed[j].type == "prop":
			var props: Dictionary = line.M.tabbed[j].prop
			if not "prop" in line:
				line.prop = props
			else:
				for k in props:
					line.prop[k] = props[k]
			line.M.tabbed.remove_at(j)

	# combine if-elif-else
	var new_tabbed := []
	for j in len(line.M.tabbed):
		var ln: Dictionary = line.M.tabbed[j]
		match ln.type:
			"cond":
				match ln.cond_type:
					"if", "match":
						new_tabbed.append(ln)
					"elif", "else":
						if j != 0:
							var prev: Dictionary = line.M.tabbed[j-1]
							if prev.type == "cond" and prev.cond_type == "if":
								prev.conds.append(ln.cond)
								prev.cond_lines.append(ln.M.tabbed)
						else:
							push_error("'%s' must follow an 'if'." % [ln.cond_type])
			_:
				new_tabbed.append(ln)
	line.M.tabbed = new_tabbed
	
	_process_line(line)
	return [i, line]

func _process_line(line: Dictionary):
	var t: String = line.M.text
	if t.begins_with(Soot.FLOW): return _line_as_flow(line)
	if t.begins_with(Soot.LANG): return _line_as_lang(line)
	if t.begins_with(Soot.LANG_GONE): return _line_as_lang(line, true)
	if t.begins_with("{{"): return _line_as_condition(line)
	_extract_conditional(line)
	# option
	if t.begins_with("- "): return _line_as_option(line)
	# actions
	if t.begins_with("~"): return _line_as_action(line)
	if t.begins_with("$"): return _line_as_action(line)
	if t.begins_with("#"): return _line_as_action(line)
	if t.begins_with("@"): return _line_as_action(line)
	# flows
	if t.begins_with(Soot.FLOW_GOTO): return _line_as_flow_goto(line)
	if t.begins_with(Soot.FLOW_CALL): return _line_as_flow_call(line)
	if t.begins_with(Soot.FLOW_PASS): return _line_as_flow_pass(line)
	if t.begins_with(Soot.FLOW_ENDD): return _line_as_flow_end(line)
	if t.begins_with(Soot.FLOW_END_ALL): return _line_as_flow_end_all(line)
	# property
	if t.begins_with(S_PROPERTY_HEAD): return _line_as_properties(line)
	return _line_as_dialogue(line)

func _line_as_condition(line: Dictionary):
	line.type = "cond"
	line.cond_type = "if"
	_extract_conditional(line)
	
	var cond: String = line.M.cond
	
	# if-elif-else condition
	if cond.begins_with("if "):
		line.cond_type = "if"
		line.cond = cond.substr(len("if ")).strip_edges()
	elif cond.begins_with("elif "):
		line.cond_type = "elif"
		line.cond = cond.substr(len("elif ")).strip_edges()
	elif cond == "else":
		line.cond_type = "else"
		line.cond = "true"
	
	# match condition
	elif cond.begins_with("match "):
		line.cond_type = "match"
		line.match = line.M.cond.trim_prefix("match ").strip_edges()
		line.cases = []
		line.case_lines = []
		for tabbed_line in line.M.tabbed:
			if tabbed_line.type == "cond":
				line.cases.append(tabbed_line.M.cond)
				line.case_lines.append(tabbed_line.M.tabbed)
				
				# treat leftover as an unprocessed line now.
				# and then add it to the front of it's list.
				if tabbed_line.M.text.strip_edges() != "":
					for k in ["cond", "cond_type", "conds", "cond_lines"]:
						tabbed_line.erase(k)
					tabbed_line.M.tabbed = []
					_process_line(tabbed_line)
					line.case_lines[-1].push_front(tabbed_line)
	
	if line.cond_type == "if":
		line.conds = [line.M.cond]
		line.cond_lines = [line.M.tabbed]

func _line_as_option(line: Dictionary):
	_extract_action(line)
	
	# extract flow lines
	var lines := []
	for li in line.M.tabbed:
		match li.type:
			_: lines.append(li)
	
	# extract => flow_goto
	if Soot.FLOW_GOTO in line.M.text:
		var p = line.M.text.split(Soot.FLOW_GOTO, true, 1)
		line.M.text = p[0].strip_edges()
		var i = 10_000
		var fstep := _new_line_flat(line, i)
		_add_flow_action(fstep, "goto", p[1].strip_edges())
		lines.append(fstep)
	
	line.type = "option"
	line.text = line.M.text.substr(1).strip_edges()
	
	if lines:
		line.then = lines

func _line_as_flow_goto(line: Dictionary):
	var p = line.M.text.rsplit(Soot.FLOW_GOTO, true, 1)
	_add_flow_action(line, "goto", p[1].strip_edges())

func _line_as_flow_call(line: Dictionary):
	var p = line.M.text.split(Soot.FLOW_CALL, true, 1)
	_add_flow_action(line, "call", p[1].strip_edges())

func _line_as_flow_pass(line: Dictionary):
	line.type = "pass"
	line.end = line.M.text.trim_prefix(Soot.FLOW_PASS).strip_edges()

func _line_as_flow_end(line: Dictionary):
	line.type = "end"
	line.end = line.M.text.trim_prefix(Soot.FLOW_ENDD).strip_edges()

func _line_as_flow_end_all(line: Dictionary):
	line.type = "end_all"
	line.end = line.M.text.trim_prefix(Soot.FLOW_END_ALL).strip_edges()

func _add_flow_action(line: Dictionary, type: String, f_action: String):
	line.type = type
	# if full path wasn't typed out, add file id as head.
	line[type] = f_action if Soot.is_path(f_action) else Soot.join_path([line.M.d_id, f_action])
	return line

func _line_as_action(line: Dictionary):
	line.type = "action"
	line.action = line.M.text.strip_edges()

func _line_as_properties(line: Dictionary):
	var properties := {}
	for prop in line.M.text.substr(len("|")).split(" "):
		var p = prop.split(":", true, 1)
		properties[p[0]] = p[1]
	line.type = "prop"
	line.prop = properties

func _line_as_flow(line: Dictionary):
	_last_speaker = ""
	line.type = "flow"
	line.id = line.M.text.substr(len(Soot.FLOW)).strip_edges()
	line.then = line.M.tabbed

# creates a flow, that will then be 'called' like `== d8997d` instead of whatever line was there.
func _line_as_lang(line: Dictionary, gone := false):
	_last_speaker = ""
	line.type = "lang_gone" if gone else "lang"
	line.id = line.M.text.substr(len(Soot.LANG)).strip_edges()
	line.then = line.M.tabbed

func _line_as_dialogue(line: Dictionary):
	var text: String = line.M.text
	line.type = "text"
	var i := _find_speaker_split(text, 0)
	if i != -1:
		var p := text.split(":", true, 1)
		line.from = text.substr(0, i).strip_edges().replace("\\:", ":")
		line.M.text = text.substr(i+1, len(text)-i).strip_edges()
		
		# get action
		if "(" in line.from:
			var a := UString.extract(line.from, "(", ")", true)
			line.from = a.outside
			var action := []
			for part in a.inside.split(";"):
				action.append("@%s.%s" % [line.from, part])
			line.action = action
		
		# remember last speaker
		if line.from.strip_edges() == "":
			line.from = _last_speaker
		else:
			_last_speaker = line.from
	
	line.text = line.M.text.replace("\\:", ":")
	
	var options := []
	var lines := []
	for tabbed_line in line.M.tabbed:
		match tabbed_line.type:
			"option": options.append(tabbed_line)
			_: lines.append(tabbed_line)
	
	if lines:
		line.lines = lines
	
	if options:
		line.options = options

func _find_speaker_split(text: String, from: int) -> int:
	var in_bbcode := false
	for i in range(from, len(text)):
		match text[i]:
			"[": in_bbcode = true
			"]": in_bbcode = false
			":":
				if not in_bbcode and (i==0 or text[i-1] != "\\"):
					return i
	return -1

func _extract_flat_lines(line: Dictionary) -> Array:
	var out := []
	if _extract(line, "((", "))", "flat_lines"):
		var p = line.M.flat_lines.split(";;")
		for i in len(p):
			var out_line := _new_line_flat(line, i, p[i].strip_edges(), "")
			# recursively check.
			out.append(out_line)
			out.append_array(_extract_flat_lines(out_line))
	return out

func _extract_action(line: Dictionary) -> bool:
	return _extract(line, "[[", "]]", "action")

func _extract_conditional(line: Dictionary) -> bool:
	return _extract(line, "{{", "}}", "cond")

func _extract(line: Dictionary, head: String, tail: String, key: String) -> bool:
	var p := UString.extract(line.M.text, head, tail)
	line.M.text = p.outside
	if p.inside != "":
		line.M[key] = p.inside
		return true
	return false

#func _trailing_tokens(s: String, splitters: Array) -> Array:
#	var f := UString.split_on_next(s, splitters)
#	var token: String = f[0]
#	var left_side: String = f[1]
#	var left_over: String = f[2]
#	if token == "":
#		return [s, []]
#	var tokens := [[token, left_over]]
#	while true:
#		f = UString.split_on_next(left_over, splitters)
#		if f[0] == "":
#			break
#		tokens[-1][1] = f[1]
#		left_over = f[2]
#		tokens.append([f[0], left_over])
#	return [left_side, tokens]

func _get_uid() -> String:
	var uid := _get_id()
	var safety := 100
	while uid in line_ids:
		uid = _get_id()
		safety -= 1
		if safety <= 0:
			push_error("Should never happen.")
			break
	return uid

func _get_id() -> String:
	var dict := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var lenn := len(dict)
	var out = ""
	for i in 5:
		out += dict[randi() % lenn]
	return out
