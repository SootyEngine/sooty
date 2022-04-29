@tool
extends RefCounted
class_name Soot

const COMMENT := "# "
const COMMENT_LANG := "#{}"
const COMMENT_FLAG := "#?"

# dialogue extension
const EXT_DIALOGUE := "soot"
# data extension
const EXT_DATA := "soda"
# language file extension
const EXT_LANG := "sola"
# markdown file extension
const EXT_TEXT := "soma" # for use with things like notes, creature databases...

const ALL_EXTENSIONS := [EXT_DIALOGUE, EXT_LANG, EXT_TEXT, EXT_DATA]

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

const CHOICE := "---"
const CHOICE_ADD := "-+-"

const TAB_SAME_LINE := "||" # tabs whatever is after it below this line

# text related
const TEXT_INSERT := "&"
const TEXT_LIST_START := "<"
const TEXT_LIST_END := ">"

# StringAction 'do' symbol heads.
const EVAL_NODE := "@"
const EVAL_STATE := "$"

const NODE_ACTION := "@"
const EVAL := "~"

const C_FLOW := Color.WHEAT

static func get_flow_color(deep: int) -> Color:
	var color := UColor.hue_shift(C_FLOW, .3 * deep)
	color.v -= .15 * deep
	return color
