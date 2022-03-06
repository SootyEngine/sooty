extends FE_File

# strings
const S_FLOW := "=="
const S_FLOW_GOTO := ">>"
const S_FLOW_CALL := "::"
const S_COMMENT := "//"
const S_ACTION := "@"
const S_PROPERTY_TAG_START := "(("
const S_PROPERTY_TAG_END := "))"
const S_CONDITION_TAG_START := "{{"
const S_CONDITION_TAG_END := "}}"

func _parse(lines: PackedStringArray):
	for i in len(lines):
		if lines[i].begins_with(S_FLOW):
			var title := lines[i].substr(len(S_FLOW)).split("((")[0].strip_edges()
			_add_chapter(i, title, 0)
