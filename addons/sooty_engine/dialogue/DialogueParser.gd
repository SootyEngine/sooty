@tool
extends Resource
class_name DialogueParser

const REWRITE := 6 # total times rewritten from scrath :{

var _dialogues := {}
var _all_lines := {}

var _last_id := ""
var _last_id_count := 0
var _last_speaker := ""

#var all_files := []
#var ignore_flags := false
#var d_id := ""
#var line_ids := {}

#func _init(dialogue_id: String, files: Array, langs := []):
#	d_id = dialogue_id 
#	all_files = files + langs

#func parse(file: String) -> Dictionary:
#	var out: Array[Dictionary] = []
#	var out_flows := {}
#	var out_lines := {}
#	var out_metas := {}
#	var out_raw := []
#
#	# load files
#	for i in len(all_files):
#		var file: String = all_files[i]
#		var original_text := UFile.load_text(file)
#		var text_lines := original_text.split("\n")
#		var blocks := _parse_file(text_lines, i)
#
#		# merge dialogue
#		if file.ends_with(Soot.EXT_DIALOGUE):
#			# keep track of raw unprocessed text lines
#			# for use with lang file generator
#			out_raw.append(text_lines)
#
#			for block in blocks:
#				# merge flows
#				for flow_id in block.flows:
#					if flow_id in out_flows:
#						push_error("hmm? %s" % flow_id)
#					out_flows[flow_id] = block.flows[flow_id]
#
#				# merge lines
#				for line_id in block.lines:
#					if line_id in out_lines:
#						push_error("hmm? %s" % line_id)
#					out_lines[line_id] = block.lines[line_id]
#
#		# merge languages
##		elif file.ends_with(Soot.EXT_LANG):
##			_merge_lang(f.flows, f.lines, out_flows, out_lines)
#
##	if len(generate_lang):
##		_generate_lang(generate_lang, out_flows, out_lines, out_raw)
#
#	return {
#		flows=out_flows,
#		lines=out_lines
#	}

# generate a language file (.sola) from the current dialogue.
#func _generate_lang(d_id: String, lang: String, flows: Dictionary, lines: Dictionary, raw: Array):
#	var out_path := "res://lang/%s-%s.%s" % [d_id, lang, Soot.EXT_LANG]
#	var text := []
#	var existing := {}
#
#	# has existing data?
#	if UFile.file_exists(out_path):
#		existing = _parse_file(out_path)
#
#	for id in lines:
#		if "!" in id:
#			continue
#
#		var line_info: Dictionary = lines[id]
#		if line_info.type in ["keyval"]:
#			var soot_path: String = all_files[line_info.M.file]
#			# are there multiple lines with this id?
#			if _has_lines_with_same_id(id, lines):
#				var multi_lines: Array = _get_lines_with_same_id(id, lines)[0]
#				var last_line:int = multi_lines[-1].M.line
#				# display header showing file and line indices
#				text.append("%s %s # %s @ %s - %s" % [Soot.LANG, id, soot_path, line_info.M.line, last_line])
#				# display comment of original text
#				for ml_info in multi_lines:
#					var raw_text: String = raw[ml_info.M.file][ml_info.M.line]
#					text.append("\t# %s" % [_clean_raw_line_for_lang(raw_text)])
#			else:
#				# header showing file and line index
#				text.append("%s %s # %s @ %s" % [Soot.LANG, id, soot_path, line_info.M.line])
#				# display a comment of original text
#				var raw_text: String = raw[line_info.M.file][line_info.M.line]
#				text.append("\t# %s" % [_clean_raw_line_for_lang(raw_text)])
#
#			# grab existing line
#			if existing and id in existing.flows:
#				for line_id in existing.flows[id].then:
#					var li = existing.lines[line_id]
#					text.append(existing.raw[li.M.line])
#
#			else:
#				text.append("\t")
#
#			text.append("")
#
#	# add removed lines, in case they come back
#	if existing:
#		for id in existing.flows:
#			if not id in lines:
#				var flow_info: Dictionary = existing.flows[id]
#				var flow_line: String = existing.raw[flow_info.M.line]
#				var last_info := flow_line.split("#", true, 1)[-1].strip_edges()
#				var old_file := last_info.split("@", true, 1)[0].strip_edges()
#				text.append("# %s doesn't exist in %s anymore." % [id, old_file])
#				var similar := UString.find_most_similar(id, lines.keys().filter(func(x): return not "!" in x))
#				if similar:
#					text.append("# Did you mean: %s?" % [", ".join(similar)])
#				text.append("# Sooty will keep this flow in case it comes back.")
#				text.append("# To remove it: Erase %s %s from %s." % [Soot.LANG, id, out_path])
#				text.append("%s %s # REMOVED: %s" % [Soot.LANG_GONE, id, last_info])
#				for line_id in flow_info.then:
#					var li = existing.lines[line_id]
#					text.append(existing.raw[li.M.line])
#				text.append("")
#
#	var out_text := "\n".join(text)
#	UFile.save_text(out_path, out_text)
#	if existing:
#		print("Updated lang file at: %s." % out_path)
#	else:
#		print("Created lang file at: %s." % out_path)

func _has_lines_with_same_id(id: StringName, lines: Dictionary) -> bool:
	return ("%s!0" % id) in lines

# returns list with lines, and list with ids
func _get_lines_with_same_id(id: StringName, lines: Dictionary) -> Array:
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

func _parse(file_path: StringName, dialogues: Dictionary, all_lines: Dictionary) -> Array:
	_dialogues = dialogues
	_all_lines = all_lines
	
	var original_text := UFile.load_text(file_path)
	var text_lines := original_text.split("\n")
	var blocks := []
	var current: Dictionary
	
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
		
		# start of document?
		if i == 0 or current_line.strip_edges() == "---":
			current = {
				meta = {
					# use file path as default id
					id=UFile.get_file_name(file_path),
					# file this block is from
					file=file_path,
					# line in file
					line=i,
					# block index
					block=len(blocks)
				},
				flows = [],
				lines = [],
				line_list = []
			}
			blocks.append(current)
			
			if not i == 0:
				i += 1
				continue
		
		# meta lines
		if current_line.begins_with("#."):
			var meta := current_line.trim_prefix("#.").split(":", true, 1)
			var k := meta[0].strip_edges()
			var v = meta[1].strip_edges() if len(meta) == 2 else true
			current.meta[k] = v
			i += 1
			continue
		
		# TODO: move down to step level
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
		elif not flags_pass:
			i += 1
			continue
		
		# get id for language files
#		var id := ""
		var uncommented := current_line
#		if Soot.COMMENT_LANG in uncommented:
#			var p := uncommented.split(Soot.COMMENT_LANG, true, 1)
#			uncommented = p[0]
#			id = p[1].strip_edges()
		
		# remove comment
		if Soot.COMMENT in uncommented:
			uncommented = uncommented.split(Soot.COMMENT, true, 1)[0]
		
		var stripped := uncommented.strip_edges()
		
		if '""""' in stripped:
			in_multiline = not in_multiline
			if not in_multiline:
#				id = multiline_id
				line = multiline_line
				stripped = multiline_head.replace("%TEXT_HERE%", "\n".join(multiline))
				multiline = []
			else:
#				multiline_id = id
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
#			if len(id):
#				# multiline
#				if id == "+":
#					id = "%s!%s" % [last_id, multi_id_index]
#					multi_id_index += 1
#				else:
#					last_id = id
			
			# create data for each line
			var lines: Array = current.line_list
			lines.append(_new_line(stripped, file_path, line, deep))
			# unflatten tabbed lines that may exist on the main line
			# seperated || by || double || bars
			var flat_lines := _extract_flat_lines_and_id(lines[-1])
			lines.append_array(flat_lines)
		
		i += 1
	
	for block in blocks:
		# collect tabs, recursively.
		var old_list: Array = block.line_list
		var new_list: Array = block.lines
		i = 0
		while i < len(old_list):
			var o = _collect_tabbed(old_list, i)
			i = o[0]
			new_list.append(o[1])
		
		# the meta flow collects untabbed lines
		var meta_flow := _new_line("", file_path, 0, 0)
		_line_as_flow(meta_flow)
		meta_flow.M.line = block.meta.line
		
		# collect flows
		for i in len(new_list):
			var flow: Dictionary = new_list[i]
			if flow.type in ["flow", "lang", "lang_gone"]:
				_check_flow(block, flow)
					
			else:
				meta_flow.then.append(flow)
		
		_check_flow(block, meta_flow)
#		if meta_flow.then:
#			_clean(meta_flow)
#			var id := Soot.join_path([block.meta.id, meta_flow.M.id])
#			if id in _all_lines:
#				push_error("Same flow more than once '%s'." % id)
#			_all_lines[id] = meta_flow
		
		block.erase("line_list")
	
	return blocks

func _check_flow(block: Dictionary, flow: Dictionary):
	# only keep flows with steps
	# ignore empty ones
	if flow.then:
		_clean(flow)
		var flow_id = Soot.join_path([block.meta.id, flow.M.id])
		if flow_id in _all_lines:
			push_error("Same flow more than once '%s'." % flow_id)
		_all_lines[flow_id] = flow
		block.flows.append(flow_id)
		
		var d_id: String = block.meta.id
		if not d_id in _dialogues:
			_dialogues[d_id] = { flows=[] }
		_dialogues[d_id].flows.append(flow_id)

#func _merge_lang(lang_flows: Dictionary, lang_lines: Dictionary, out_flows: Dictionary, out_lines: Dictionary):
#	for flow in lang_flows.values():
#		var replace_id: String = flow.id
#
#		# remove line
#		if not replace_id in out_lines:
#			if flow.type != "lang_gone":
#				print("Line %s wasn't there!?" % replace_id)
#			continue
#
#		# get old lines nad their ids
#		var old_lines_and_ids: Array
#		if _has_lines_with_same_id(replace_id, out_lines):
#			old_lines_and_ids = _get_lines_with_same_id(replace_id, out_lines)
#		else:
#			old_lines_and_ids = [out_lines[replace_id], [replace_id]]
#
#		# remove old lines
#		for id in old_lines_and_ids[1]:
#			out_lines.erase(id)
#
#		var old_lines = old_lines_and_ids[0]
#		var new_lines = []
#		# install as a flow call (== flow) if there is more than one line
#		if len(flow.then) > 1:
#			# the flow.id is same as line id from original file
#			var new_flow_id: String = "lang_%s" % flow.id
#			# add lang flow to main flow list
#			out_flows[new_flow_id] = flow
#
#			# install a call in it's place
#			out_lines[replace_id] = {
#				"type": "call",
#				"call": Soot.join_path([d_id, new_flow_id]),
#				"M": {
#					"d_id": flow.M.d_id,
#					"file": flow.M.file,
#					"line": flow.M.line,
#					"lang": true # this line came from a .sola file
#				}
#			}
#
#			# install flow lines
#			for line_id in flow.then:
#				if line_id in out_lines:
#					print("Line %s existed! Shouldn't happen!" % line_id)
#				out_lines[line_id] = lang_lines[line_id]
#				new_lines.append(lang_lines[line_id])
#
#		# install as a single line replace
#		else:
#			out_lines[replace_id] = lang_lines[flow.then[0]]
#			new_lines.append(lang_lines[flow.then[0]])
#
#		print("REPLACED ", old_lines[0], "<->", new_lines)

func _new_line_flat(parent: Dictionary, index: int, text := "") -> Dictionary:
	var out := _new_line_child(parent, text)
#	if "flat" in parent:
#		out.flat = "%s %s" % [parent.flat, index]
#	else:
#		out.flat = "%s" % index
	return out

func _new_line_child(parent: Dictionary, text := "") -> Dictionary:
	return _new_line(text, parent.M.file, parent.M.line, parent.M.deep+1)

func _new_line(text: String, file: StringName, line: int, deep: int) -> Dictionary:
	return {
		"M"={ # meta data
			"text"=text, # original text, stripped
			"id"="", # unique id, used for translations
			"deep"=deep, # how many tabs
			"tabbed"=[], # lines tabbed below this one
			"file"=file, # file index
			"line"=line # index of line in file
		},
		"type"="", # type of line
	}

func _clean_array(lines: Array):
	for i in len(lines):
		lines[i] = _clean(lines[i])

func _clean_nested_array(lines_list: Array):
	for i in len(lines_list):
		_clean_array(lines_list[i])

func _clean(line: Dictionary) -> String:
	match line.type:
		"flow", "lang", "lang_gone":
			_clean_array(line.then)
		"list":
			_clean_array(line.list)
		"option", "call":
			if "then" in line:
				_clean_array(line.then)
		"text":
			if "options" in line:
				_clean_array(line.options)
		"cond":
			match line.cond_type:
				"if": _clean_nested_array(line.cond_lines)
				"match": _clean_nested_array(line.case_lines)
			line.type = line.cond_type
		
		_: pass
	
	# generate id and add to line list
	if not line.type in ["flow", "lang", "lang_gone"]:
		if line.M.id:
			pass
		else:
			seed(hash(line.M.text))
			line.M.id = _get_uid(_all_lines)
		
		if line.M.id in _all_lines:
			push_error("Line id collision for %s." % line.M.id)
		
		_all_lines[line.M.id] = line
	
	# erase non essential keys from Meta.
	for k in line.M.keys():
		if not k in ["file", "line", "id", "block"]:
			line.M.erase(k)
	
	return line.M.id

func _collect_tabbed(dict_lines: Array, i: int) -> Array:
	var line = dict_lines[i]
	_extract_properties(line)
	i += 1
	# collect tabbed
	while i < len(dict_lines) and dict_lines[i].M.deep > line.M.deep:
		var o = _collect_tabbed(dict_lines, i)
		line.M.tabbed.append(o[1])
		i = o[0]
	
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
	# ===
	if t.begins_with(Soot.FLOW): return _line_as_flow(line)
	# <->
	if t.begins_with(Soot.LANG): return _line_as_lang(line)
	# <?>
	if t.begins_with(Soot.LANG_GONE): return _line_as_lang(line, true)
	# {{}}
	if t.begins_with("{{"): return _line_as_condition(line)
	_extract_conditional(line)
	# option
	if t.begins_with("|>"): return _line_as_option(line)
	if t.begins_with("+>"): return _line_as_option(line)
	# list
	if t.begins_with("{["): return _line_as_list(line)
	# actions
	if t.begins_with(">"): return _line_as_action(line)
	if t.begins_with("~"): return _line_as_action(line)
	if t.begins_with("$"): return _line_as_action(line)
	if t.begins_with("@"): return _line_as_action(line)
	if t.begins_with("*"): return _line_as_action(line)
	# flows
	if t.begins_with(Soot.FLOW_GOTO): return _line_as_flow_action(line, "goto", Soot.FLOW_GOTO)
	if t.begins_with(Soot.FLOW_CALL): return _line_as_flow_action(line, "call", Soot.FLOW_CALL)
	if t.begins_with(Soot.FLOW_PASS): return _line_as_flow_action(line, "pass", Soot.FLOW_PASS)
	if t.begins_with(Soot.FLOW_ENDD): return _line_as_flow_action(line, "end", Soot.FLOW_ENDD)
	if t.begins_with(Soot.FLOW_END_ALL): return _line_as_flow_action(line, "end_all", Soot.FLOW_END_ALL)
	if t.begins_with(Soot.FLOW_CHECKPOINT): return _line_as_flow_action(line, "check_point", Soot.FLOW_CHECKPOINT)
	if t.begins_with(Soot.FLOW_BACK): return _line_as_flow_action(line, "back", Soot.FLOW_BACK)
	# text insert
	if t.begins_with("&"): return _line_as_text_insert(line)
	# otherwise it is text
	return _line_as_text(line)

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
#	_extract_action(line)
	
	# extract flow lines
	var lines := []
	for li in line.M.tabbed:
		match li.type:
			_: lines.append(li)
	
	# extract => flow_goto
	if Soot.FLOW_GOTO in line.M.text:
		var p = line.M.text.split(Soot.FLOW_GOTO, true, 1)
		line.M.text = p[0].strip_edges()
		var fstep := _new_line_flat(line, 10_000)
		fstep.type = "goto"
		fstep.goto = p[1].strip_edges()
		lines.append(fstep)
	
	line.type = "option"
	line.text = line.M.text.substr(len("|>")).strip_edges()
	
	if lines:
		line.then = lines

func _line_as_list(line: Dictionary):
	var list_type = UString.unwrap(line.M.text, "{[", "]}").strip_edges()
	line.type = "list"
	line.list_type = list_type
	line.list = line.M.tabbed

func _line_as_flow_action(line: Dictionary, type: String, head: String):
	line.type = type
	line[type] = line.M.text.trim_prefix(head).strip_edges()
	
	# calls can be inline, for use with {[]} list pattern.
	if type == "call":
		if line.M.tabbed:
			line.then = line.M.tabbed

func _line_as_action(line: Dictionary):
	line.type = "action"
	line.action = line.M.text.strip_edges()

func _line_as_flow(line: Dictionary):
	_last_speaker = ""
	line.type = "flow"
	line.M.id = line.M.text.substr(len(Soot.FLOW)).strip_edges()
	line.then = line.M.tabbed

# creates a flow, that will then be 'called' like `== d8997d` instead of whatever line was there.
func _line_as_lang(line: Dictionary, gone := false):
	_last_speaker = ""
	line.type = "lang_gone" if gone else "lang"
	line.M.id = line.M.text.substr(len(Soot.LANG)).strip_edges()
	line.then = line.M.tabbed

func _line_as_text_insert(line: Dictionary):
	var text = line.M.text.trim_prefix("&").split("=")
	line.type = "insert"
	line.key = text[0].strip_edges()
	line.val = text[1].strip_edges()

func _line_as_text(line: Dictionary):
	var text: String = line.M.text
	var options := []
	var inserts := {}
	for tabbed_line in line.M.tabbed:
		match tabbed_line.type:
			"option": options.append(tabbed_line)
			"insert": inserts[tabbed_line.key] = tabbed_line.val
	
	# format the insert keys with eachother
	for key in inserts:
		inserts[key] = inserts[key].format(inserts, "&_")
	text = text.format(inserts, "&_")
	
	line.type = "text"
	line.text = text
	
	if options:
		line.options = options

func _extract_flat_lines_and_id(line: Dictionary) -> Array:
	var out := []
	var parts = Array(line.M.text.split("||")).map(func(x): return UString.extract(x.strip_edges(), "#{", "}"))
	var in_out: Dictionary = parts.pop_front()
	
	line.M.text = in_out.outside
	_set_line_id(line, in_out.inside)
	
	for i in len(parts):
		in_out = parts[i]
		var out_line := _new_line_flat(line, i, in_out.outside)
		_set_line_id(out_line, in_out.inside)
		out.append(out_line)
	return out

func _set_line_id(line: Dictionary, id: String):
	if id == "+":
		line.M.id = "%s!%s" % [_last_id, _last_id_count]
		_last_id_count += 1
	else:
		line.M.id = id
		_last_id = id
		_last_id_count = 0

func _extract_properties(line: Dictionary):
	var p := UString.extract(line.M.text, "((", "))")
	line.M.text = p.outside
	if p.inside:
		for item in UString.split_outside(p.inside, " "):#UString.split_on_spaces(p.inside):
			if ":" in item:
				var kv = item.split(":", true, 1)
				var k = kv[0].strip_edges()
				var v = kv[1].strip_edges()
				if "," in v:
					line[k] = v.split(",")
				else:
					line[k] = v
			else:
				UDict.append(line, "flags", item)

func _extract_conditional(line: Dictionary) -> bool:
	return _extract(line, "{{", "}}", "cond")

func _extract(line: Dictionary, head: String, tail: String, key: String) -> bool:
	var p := UString.extract(line.M.text, head, tail)
	line.M.text = p.outside
	if p.inside:
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

func _get_uid(line_ids: Dictionary) -> String:
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
	var out := ""
	for i in 5:
		out += dict[randi() % lenn]
	return out
