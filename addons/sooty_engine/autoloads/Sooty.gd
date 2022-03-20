extends Node

const VERSION := "0.1_alpha"

const S_ACTION_EVAL := "~"
const S_ACTION_STATE := "$"
const S_ACTION_GROUP := "@"

func as_string(v: Variant) -> String:
	if v is Object and v.has_method("as_string"):
		return v.as_string()
	else:
		return str(v)
