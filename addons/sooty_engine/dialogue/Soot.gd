@tool
extends Resource
class_name Soot

const COMMENT := "//"

const FLOW := "==="
const FLOW_GOTO := "=>"
const FLOW_CALL := "=="
const FLOW_ENDD := "><"

const FLOW_PATH_DIVIDER := "/"

static func is_path(path: String) -> bool:
	return FLOW_PATH_DIVIDER in path

static func join_path(parts: Array) -> String:
	return FLOW_PATH_DIVIDER.join(parts)

static func split_path(path: String) -> PackedStringArray:
	return path.split(FLOW_PATH_DIVIDER)
