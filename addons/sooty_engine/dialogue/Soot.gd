@tool
extends Resource
class_name Soot

const COMMENT := "# "
const COMMENT_LANG := "#id="
const COMMENT_FLAG := "#?"

# dialogue extension
const EXT_DIALOGUE := ".soot"
# data extension
const EXT_DATA := ".soda"
# language file extension
const EXT_LANG := ".sola"
# markdown file extension
const EXT_TEXT := ".soma" # for use with things like notes, creature databases...

# flow control symbols
const LANG := "<->"
const FLOW := "==="
const FLOW_GOTO := "=>"
const FLOW_CALL := "=="
const FLOW_ENDD := "><"

const FLOW_PATH_DIVIDER := "/"

# called when the main game starts.
const M_START := "MAIN" + FLOW_PATH_DIVIDER + "START"
# called when a flow ends.
const M_FLOW_END := "MAIN" + FLOW_PATH_DIVIDER + "FLOW_END"

static func is_path(path: String) -> bool:
	return FLOW_PATH_DIVIDER in path

static func join_path(parts: Array) -> String:
	return FLOW_PATH_DIVIDER.join(parts)

static func split_path(path: String) -> PackedStringArray:
	return path.split(FLOW_PATH_DIVIDER)
