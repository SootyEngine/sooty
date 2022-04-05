extends Resource
class_name DialogueLang

const S_LANG_ID := "#L:"
const EXT := ".sola"

func parse(path: String):
	var data := DialogueParser.new().parse(path)
	
	for line in data.lines:
		match line.type:
			"text":
				print(line)
	
	# generate unique ids
#	var GENERATE_TRANSLATIONS := false
#	if GENERATE_TRANSLATIONS:
#		var translations := []
#		for k in out_lines:
#			var step = out_lines[k]
#			match step.type:
#				"text", "option":
#					if step.id == "":
#						step.id = get_uid(out_lines)
#						set_line_uid(text_lines, step.line, step.id)
#					var f = step.get("from", "NONE")
#					var t := Array(step.text.split("\n"))
#					if len(t) != 1:
#						t.push_front('""""')
#						t.push_back('""""')
#					t[0] = "%s: %s" % [f, t[0]]
#					for i in len(t):
#						t[i] = "\t#" + t[i]
#					translations.append("#%s:\n%s\n\t%s: \n" % [step.id, "\n".join(t), f])
		
#		UFile.save_text(file, "\n".join(text_lines))
#		print(UFile.change_extension(file, "lsoot"))
#		UFile.save_text(UFile.change_extension(file, "lsoot"), "\n".join(translations))


func set_line_uid(lines: PackedStringArray, line: int, uid: String):
	if S_LANG_ID in lines[line]:
		var p := lines[line].split(S_LANG_ID, true, 1)
		lines[line] = p[0].strip_edges(false, true) + " #%s" % uid
	else:
		lines[line] = lines[line] + " #%s" % uid

func get_uid(lines: Dictionary, size := 8) -> String:
	var uid := get_id()
	var safety := 100
	while uid in lines:
		uid = get_id()
		safety -= 1
		if safety <= 0:
			push_error("Should never happen.")
			break
	return uid

func get_id(size := 8) -> String:
	var dict := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var lenn := len(dict)
	var out = ""
	for i in size:
		out += dict[randi() % lenn]
	return out

