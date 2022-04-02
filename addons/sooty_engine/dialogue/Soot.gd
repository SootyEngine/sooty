@tool
extends Resource
class_name Soot

const COMMENT := "//"

const FLOW := "==="
const FLOW_GOTO := "=>"
const FLOW_CALL := "=="
const FLOW_ENDD := "><"

const FLOW_PATH_DIVIDER := "/"

# Called when the main game starts.
const M_START := "MAIN" + FLOW_PATH_DIVIDER + "START"
# Called when a flow ends.
const M_FLOW_END := "MAIN" + FLOW_PATH_DIVIDER + "FLOW_END"

static func is_path(path: String) -> bool:
	return FLOW_PATH_DIVIDER in path

static func join_path(parts: Array) -> String:
	return FLOW_PATH_DIVIDER.join(parts)

static func split_path(path: String) -> PackedStringArray:
	return path.split(FLOW_PATH_DIVIDER)
