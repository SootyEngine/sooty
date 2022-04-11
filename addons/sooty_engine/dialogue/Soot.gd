@tool
extends RefCounted
class_name Soot

const COMMENT := "# "
const COMMENT_LANG := "#id="
const COMMENT_FLAG := "#?"

# dialogue extension
const EXT_DIALOGUE := "soot"
# data extension
const EXT_DATA := "soda"
# language file extension
const EXT_LANG := "sola"
# markdown file extension
const EXT_TEXT := "soma" # for use with things like notes, creature databases...

const SEPERATOR := "---" # divides a single file into multiple

# flow control symbols
const LANG := "<->"
const LANG_GONE := "<?>" # translation that is currently missing. it's data will be kept around.
const FLOW := "==="
const FLOW_GOTO := "=>"
const FLOW_CALL := "=="
const FLOW_ENDD := "><"
const FLOW_PASS := "__"
const FLOW_CHECKPOINT := "<>"
const FLOW_BACK := "<|"
const FLOW_END_ALL := ">><<"
const FLOW_CHOICE := ">>>"
const FLOW_CHOICE_ADD := "+>>"

const TAB_SAME_LINE := "||"	# tabs whatever is after it below this line

# text related
const TEXT_INSERT := "&"
const TEXT_LIST_START := "<"
const TEXT_LIST_END := ">"

# StringAction 'do' symbol heads.
const DO_NODE := "@"
const DO_SELF := "~"
const DO_STATE := "$"
const DO_NODE_EVAL := "@:"	# expression on node
const DO_NODE_FUNC := "@)"	# call node function
const DO_SELF_EVAL := "~:"	# expression on self
const DO_SELF_FUNC := "~)"	# call self function
const DO_STATE_EVAL := "$:"	# expression on state
const DO_STATE_FUNC := "$)"	# call state function
const DO_VAR := "*"			# returns a var
const ALL_DOINGS := [
	DO_NODE, DO_NODE_EVAL, DO_NODE_FUNC,
	DO_SELF, DO_SELF_EVAL, DO_SELF_FUNC,
	DO_STATE, DO_STATE_EVAL, DO_STATE_FUNC, DO_VAR]

const FLOW_PATH_DIVIDER := "/"

static func is_path(path: String) -> bool:
	return FLOW_PATH_DIVIDER in str(path)

static func join_path(parts: Array) -> String:
	return FLOW_PATH_DIVIDER.join(parts)

static func split_path(path: String) -> PackedStringArray:
	return path.split(FLOW_PATH_DIVIDER)
